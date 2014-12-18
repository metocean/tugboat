Ducke = require 'ducke'
yaml = require 'js-yaml'
fs = require 'fs'
path = require 'path'
parse_configuration = require './configuration'
groupdiff = require './groupdiff'

# Copy all of the properties on source to target, recurse if an object
copy = (source, target) ->
  for key, value of source
    if typeof value is 'object'
      target[key] = {} if !target[key]? or typeof target[key] isnt 'object'
      copy value, target[key]
    else
      target[key] = value

# Run things all at once - better for compute
parallel = (tasks, callback) ->
  count = tasks.length
  result = (cb) ->
    return cb() if count is 0
    for task in tasks
      task ->
        count--
        cb() if count is 0
  result(callback) if callback?
  result

module.exports = class Tugboat
  constructor: (options) ->
    @_options =
      groupsdir: process.cwd()
    copy options, @_options
    @ducke = new Ducke.API Ducke.Parameters options
  
  # Read and parse each .yml as the definition of a group
  _loadGroup: (item, cb) =>
    fs.readFile item, encoding: 'utf8', (err, content) =>
      return cb [err] if err?
      try
        content = yaml.safeLoad content
      catch e
        return cb [e] if e?
      
      name = path.basename item, '.yml'
      parse_configuration name, content, @_options.groupsdir, (errors, services) ->
        return cb errors if errors?
        cb null,
          name: name
          path: item
          services: services
  
  # Trall through the directory looking for .yml files
  # Errors are returned as a list
  init: (callback) =>
    try
      items = fs.readdirSync @_options.groupsdir
    catch e
      return callback [
        path: @_options.groupsdir
        errors: [e]
      ]
    
    @_groups = {} if !@_groups?
    tasks = []
    errors = []
    results = []
    for item in items
      continue if !item.match /\.yml$/
      do (item) =>
        tasks.push (cb) =>
          item = "#{@_options.groupsdir}/#{item}"
          @_loadGroup item, (errs, group) =>
            if errs?
              errors.push path: item, errors: errs
              return cb()
            @_groups[group.name] = group
            cb()
    
    # Async power
    parallel tasks, ->
      return callback errors if errors.length isnt 0
      callback null
  
  # Build an individual service within a group
  build: (group, servicename, usecache, run, callback) =>
    config = group.services[servicename]
    @ducke.build_image config.name, config.build, usecache, run, callback
  
  # Merge known groups with running containers
  ps: (callback) =>
    @ducke.ps (err, containers) =>
      return callback err if err?
      callback null, groupdiff @_groups, containers
  
  # Run a service
  up: (config, imagename, containername, callback) =>
    params = Image: imagename
    params.Cmd = config.command.split ' ' if config.command?
    params.User = config.user if config.user?
    params.Memory = config.mem_limit if config.mem_limit?
    params.Hostname = config.hostname if config.hostname?
    params.Domainname = config.domainname if config.domainname?
    params.Entrypoint = config.entrypoint if config.entrypoint?
    params.WorkingDir = config.working_dir if config.working_dir?
    params.Env = config.environment if config.environment?
    params.ExposedPorts = config.expose if config.expose?
    params.HostConfig = {}
    params.HostConfig.Binds = config.volumes if config.volumes?
    params.HostConfig.Links = config.links if config.links?
    params.HostConfig.Dns = config.dns if config.dns?
    params.HostConfig.NetworkMode = config.net if config.net?
    params.HostConfig.Privileged = config.privileged if config.privileged?
    params.HostConfig.PortBindings = config.ports if config.ports?
    
    @ducke.createContainer containername, params, (err, container) =>
      return callback err if err?
      id = container.Id
      container = @ducke.container id
      container.start (err) =>
        return callback err if err?
        callback null, id
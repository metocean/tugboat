Ducke = require 'ducke'
yaml = require 'js-yaml'
fs = require 'fs'
path = require 'path'
parse_configuration = require './configuration'
groupdiff = require './groupdiff'
servicediff = require './servicediff'
series = require './series'
parallel = require './parallel'

# Copy all of the properties on source to target, recurse if an object
copy = (source, target) ->
  for key, value of source
    if typeof value is 'object'
      target[key] = {} if !target[key]? or typeof target[key] isnt 'object'
      copy value, target[key]
    else
      target[key] = value

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
  build: (group, service, usecache, run, callback) =>
    @ducke.build_image service.name, service.build, usecache, run, callback
  
  # Merge known groups with running containers
  ps: (callback) =>
    @ducke.ps (err, containers) =>
      return callback err if err?
      callback null, groupdiff @_groups, containers
  
  # Calculate what has changed
  diff: (callback) =>
    @ducke.ps (err, containers) =>
      return callback err if err?
      @ducke.ls (err, imagerepo) =>
        return callback err if err?
        images = containers.map (c) -> c.inspect.Image
        # Pull in more details for images
        @ducke.lls images, (err, detailedimages) =>
          return callback err if err?
          for id, inspect of detailedimages
            imagerepo.ids[id].inspect = inspect
          groupsgrouped = groupdiff @_groups, containers
          servicesdiffed = servicediff imagerepo, groupsgrouped
          callback null, servicesdiffed
  
  groupcull: (groupdiff, callback) =>
    errors = []
    messages = []
    tasks = []
    for servicename, service of groupdiff.services
      outputname = servicename
      outputname += ' ' while outputname.length < 26
      for c in service.containers
        containername = c.container.Names[0].substr('1')
        do (containername, c, outputname, service) =>
          if c.inspect.State.Running
            tasks.push (cb) =>
              messages.push "#{outputname} Stopping #{containername}"
              @ducke
                .container c.container.Id
                .stop (err, result) ->
                  errors.push err if err?
                  cb()
          tasks.push (cb) =>
            messages.push "#{outputname} Deleting #{containername}"
            @ducke
              .container c.container.Id
              .rm (err, result) ->
                errors.push err if err?
                cb()
    
    series tasks, -> callback errors, messages
  
  groupup: (groupdiff, callback) =>
    errors = []
    messages = []
    tasks = []
    for servicename, service of groupdiff.services
      outputname = servicename
      outputname += ' ' while outputname.length < 26
      do (outputname, service) =>
        tasks.push (cb) =>
          if service.diff.iserror
            errors.push "#{outputname} #{m}" for m in service.diff.messages
          else
            messages.push "#{outputname} #{m}" for m in service.diff.messages
          cb()
        for c in service.diff.stop
          containername = c.container.Names[0].substr('1')
          do (containername, c) =>
            tasks.push (cb) =>
              messages.push "#{outputname} Stopping #{containername}"
              @ducke
                .container c.container.Id
                .stop (err, result) ->
                  errors.push err if err?
                  cb()
        for c in service.diff.rm
          containername = c.container.Names[0].substr('1')
          do (containername, c) =>
            tasks.push (cb) =>
              messages.push "#{outputname} Deleting #{containername}"
              @ducke
                .container c.container.Id
                .stop (err, result) ->
                  errors.push err if err?
                  cb()
        for c in service.diff.start
          containername = c.container.Names[0].substr('1')
          do (containername, c) =>
            tasks.push (cb) =>
              messages.push "#{outputname} Starting #{containername}"
              @ducke
                .container c.container.Id
                .stop (err, result) ->
                  errors.push err if err?
                  cb()
        
        if service.diff.create > 0
            for i in [1..service.diff.create]
              tasks.push (cb) =>
                newname = "#{groupdiff.name}_#{service.name}"
                newindex = 1
                newindex++ while service.containers
                  .filter (c) -> c.index is newindex.toString()
                  .length isnt 0
                newname += "_#{newindex}"
                messages.push "#{outputname} Creating #{newname} (#{service.service.params.Image}) "
                @up service.service, newname, (err) ->
                  errors.push err if err?
                  cb()
    
    series tasks, -> callback errors, messages
  
  # Run a service
  up: (group, service, containername, callback) =>
    @ducke.createContainer containername, service.service.params, (err, container) =>
      return callback err if err?
      id = container.Id
      container = @ducke.container id
      container.start (err) =>
        return callback err if err?
        callback null, id
  
  stop: (group, service, container, callback) =>
    @ducke
      .container container.container.Id
      .stop callback
  
  rm: (group, service, container, callback) =>
    @ducke
      .container container.container.Id
      .rm callback
  
  start: (group, service, container, callback) =>
    @ducke
      .container container.container.Id
      .start callback
  
  kill: (group, service, container, callback) =>
    @ducke
      .container container.container.Id
      .kill callback

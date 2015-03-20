resolve = require('path').resolve
template = require './template'
fs = require 'fs'
yaml = require 'js-yaml'

class TUGBOATFormatException extends Error
  constructor: (message) ->
    @name = 'TUGBOATFormatException'
    @message = message

# Helper functions to check types
isstring = (s) -> typeof s is 'string'
isnumber = (s) -> typeof s is 'number'
isboolean = (s) -> typeof s is 'boolean'
isstringarray = (s) ->
  return no if typeof s is 'array'
  for i in s
    return no if !isstring i
  yes
isobjectofstringsornull = (s) ->
  return no if typeof s isnt 'object'
  for _, i of s
    continue if i is null
    continue if isstring i
    return no
  yes
isrestartpolicy = (s) ->
  return yes if typeof s is 'boolean'
  return no if typeof s isnt 'string'
  return yes if s is 'yes'
  return yes if s is 'no'
  chunks = s.split ':'
  return no if chunks.length isnt 2
  return no if chunks[0] isnt 'on-failure'
  yes
isscripts = (s) ->
  return no if typeof s isnt 'object'
  allowed = ['create', 'cull', 'keep', 'kill', 'migrate', 'rm', 'start', 'stop']
  for k, v of s
    return no if k not in allowed
    return no if not isstring v
  yes

# The expecations
validation =
  build: isstring
  image: isstring
  command: isstring
  links: isstringarray
  ports: isstringarray
  add_hosts: isstringarray
  expose: isstringarray
  volumes: isstringarray
  environment: isobjectofstringsornull
  env_file: isstringarray
  net: isstring
  dns: isstringarray
  cap_add: isstringarray
  cap_drop: isstringarray
  working_dir: isstring
  entrypoint: isstring
  user: isstring
  hostname: isstring
  domainname: isstring
  mem_limit: isnumber
  privileged: isboolean
  notes: isstring
  restart: isrestartpolicy
  scripts: isscripts

globalvalidation =
  volumes: isstringarray
  dns: isstringarray
  cap_add: isstringarray
  cap_drop: isstringarray
  ports: isstringarray
  add_hosts: isstringarray
  environment: isobjectofstringsornull
  env_file: isstringarray
  restart: isrestartpolicy
  scripts: isscripts
  expose: isstringarray
  user: isstring
  domainname: isstring
  net: isstring
  privileged: isboolean
  notes: isstring
  links: isstringarray

parse_port = (port) ->
  udp = '/udp'
  tcp = '/tcp'
  
  if port.substr(port.length - udp.length) isnt udp and port.substr(port.length - tcp.length) isnt tcp
    port = "#{port}/tcp"
  port

preprocess = (config, path) ->
  if config.restart?
    if config.restart is no or config.restart is 'no'
      delete config.restart
    else if config.restart is yes or config.restart is 'always'
      config.restart =
        Name: 'always'
    else if config.restart.indexOf('on-failure') is 0
      chunks = config.restart.split ':'
      config.restart =
        Name: chunks[0]
        MaximumRetryCount: chunks[1]
  
  # Fig syntax allows a single value, let's convert that
  if config.dns? and typeof config.dns is 'string'
    config.dns = [config.dns]
  
  # Fig syntax allows strings of x=y let's convert that
  if config.environment? and config.environment instanceof Array
    result = {}
    for env in config.environment
      chunks = env.split '='
      key = chunks[0]
      value = chunks[1..].join '='
      result[key] = value
    config.environment = result

    # Add env from external files
    if config.env_file?
      if not config.environment?
        config.environment = {}

      for filename in config.env_file
        filepath = "#{path}/#{filename}"
        
        try
          content = fs.readFileSync filepath
        catch e
          if e.code is 'ENOENT'
            console.error "Could not read env_file #{filepath.cyan}"
            process.exit 1
          else
            throw e
        
        content = yaml.safeLoad content
        if not isobjectofstringsornull content
          console.error "Invalid format for env_file #{filepath.cyan}"
          process.exit 1

        for key, value of content
          config.environment[key] = value


module.exports = (groupname, services, path, cb) ->
  if typeof services isnt 'object'
    return cb [
      new TUGBOATFormatException 'This YAML file is in the wrong format. Tugboat expects names and definitions of services.'
    ]
  
  # Errors are reported as a list
  errors = []
  
  # We use underscore for separating, otherwise this is the same
  # as the allowed characters in a docker name
  if !groupname.match /^[a-zA-Z0-9-]+$/
    errors.push new TUGBOATFormatException "The YAML file #{groupname.cyan} is not a valid group name."
  
  # replace templates
  services = template services
  
  preprocess services, path
  globals = {}
  
  for key, value of globalvalidation
    if services[key]?
      if !validation[key] services[key]
        errors.push new TUGBOATFormatException "In the global configuration the value of #{key.cyan} was an unexpected format."
        continue
      globals[key] = services[key]
      delete services[key]
  
  for name, config of services
    if !name.match /^[a-zA-Z0-9-]+$/
      errors.push new TUGBOATFormatException "#{name.cyan} is not a valid service name."
    if typeof services isnt 'object' or services instanceof Array
      errors.push new TUGBOATFormatException "The value of #{name.cyan} is not an object of strings."
      continue
    
    preprocess config, path
    
    if globals.volumes?
      config.volumes = [] if !config.volumes?
      config.volumes = globals.volumes.concat config.volumes
    
    if globals.dns?
      config.dns = [] if !config.dns?
      config.dns = globals.dns.concat config.dns

    if globals.cap_add?
      config.cap_add = [] if !config.cap_add?
      config.cap_add = globals.cap_add.concat config.cap_add
    
    if globals.cap_drop?
      config.cap_drop = [] if !config.cap_drop?
      config.cap_drop = globals.cap_drop.concat config.cap_drop
    
    if globals.ports?
      config.ports = [] if !config.ports?
      config.ports = globals.ports.concat config.ports

    if globals.add_hosts?
      config.add_hosts = [] if !config.add_hosts?
      config.add_hosts = globals.add_hosts.concat config.add_hosts
    
    if globals.expose?
      config.expose = [] if !config.expose?
      config.expose = globals.expose.concat config.expose
    
    if globals.links?
      config.links = [] if !config.links?
      config.links = globals.links.concat config.links
    
    if globals.environment?
      config.environment = {} if !config.environment?
      for key, value of globals.environment
        continue if config.environment[key]?
        config.environment[key] = value
    
    if globals.scripts?
      config.scripts = {} if !config.scripts?
      for key, value of globals.scripts
        continue if config.scripts[key]?
        config.scripts[key] = value
    
    if globals.restart? and !config.restart?
      config.restart = globals.restart
    
    if globals.user? and !config.user?
      config.user = globals.user
    
    if globals.domainname? and !config.domainname?
      config.domainname = globals.domainname
    
    if globals.net? and !config.net?
      config.net = globals.net
    
    if globals.privileged? and !config.privileged?
      config.privileged = globals.privileged
    
    # Either build or image, not both but at least one
    count = 0
    count++ if config.build?
    count++ if config.image?
    if count isnt 1
      errors.push new TUGBOATFormatException "#{name.cyan} requires either a build or an image value."
    
    # Compare all values against expected
    for key, value of config
      if !validation[key]?
        errors.push new TUGBOATFormatException "In the service #{name.cyan} #{key.cyan} is not a known configuration option."
        continue
      if !validation[key] value
        errors.push new TUGBOATFormatException "In the service #{name.cyan} the value of #{key.cyan} was an unexpected format."
        continue
    
    # Make mount paths absolute
    if config.volumes
      config.volumes = config.volumes.map (v) ->
        chunks = v.split ':'
        chunks[0] = resolve path, chunks[0]
        chunks.join ':'
    
    if config.scripts?
      for trigger, filename of config.scripts
        config.scripts[trigger] = resolve path, filename
    
    # Fig - copy current environment variables into empty values
    if config.environment? and isobjectofstringsornull config.environment
      results = []
      for key, value of config.environment
        if value is '' or value is null and process.env[key]?
          results.push "#{key}=#{process.env[key]}"
        else
          results.push "#{key}=#{value}"
      config.environment = results
    
    if config.ports?
      results = {}
      for p in config.ports
        chunks = p.split ':'
        if chunks.length is 1
          results[parse_port chunks[0]] = [
            HostIp: '0.0.0.0'
            HostPort: chunks[0]
          ]
        else if chunks.length is 2
          results[parse_port chunks[1]] = [
            HostIp: '0.0.0.0'
            HostPort: chunks[0]
          ]
        else if chunks.length is 3
          results[parse_port chunks[2]] = [
            HostIp: chunks[0]
            HostPort: chunks[1]
          ]
        else
          errors.push new TUGBOATFormatException "In the service #{name.cyan} the port binding '#{p.cyan}'' was an unexpected format."
      config.ports = results
    
    if config.expose?
      results = {}
      config.expose = config.expose.map (e) ->
        results[parse_port e] = {}
      config.expose = results
    
    # Expose port mappings as well
    if config.ports?
      config.expose = {} if !config.expose?
      for port, _ of config.ports
        config.expose[port] = {}
    
    config.name = "#{groupname}_#{name}"
    config.command = config.command.split ' ' if config.command?
    config.image = config.name if !config.image?
  
  # Convert configuration into docker format
  for name, config of services
    pname = name
    pname += ' ' while pname.length < 32
    services[name] =
      name: config.name
      pname: pname
      build: config.build ? null
      scripts: config.scripts ? null
      params:
        Image: config.image
        Cmd: config.command ? null
        User: config.user ? ''
        Memory: config.mem_limit ? 0
        Hostname: config.hostname ? null
        Domainname: config.domainname ? null
        Entrypoint: config.entrypoint ? null
        WorkingDir: config.working_dir ? ''
        Env: config.environment
        ExposedPorts: config.expose ? null
        HostConfig:
          Binds: config.volumes ? null
          Links: config.links ? null
          Dns: config.dns ? null
          CapAdd: config.cap_add ? null
          CapDrop: config.cap_drop ? null
          NetworkMode: config.net ? ''
          Privileged: config.privileged ? no
          PortBindings: config.ports ? null
          ExtraHosts: config.add_hosts ? null
          RestartPolicy: config.restart ? Name: ''
  
  return cb errors if errors.length isnt 0
  cb null, services
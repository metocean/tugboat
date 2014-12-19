resolve = require('path').resolve

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

# The expecations
validation =
  build: isstring
  image: isstring
  command: isstring
  links: isstringarray
  ports: isstringarray
  expose: isstringarray
  volumes: isstringarray
  environment: isobjectofstringsornull
  net: isstring
  dns: isstringarray
  working_dir: isstring
  entrypoint: isstring
  user: isstring
  hostname: isstring
  domainname: isstring
  mem_limit: isnumber
  privileged: isboolean

parse_port = (port) ->
  udp = '/udp'
  tcp = '/tcp'
  
  if port.substr(port.length - udp.length) isnt udp and port.substr(port.length - tcp.length) isnt tcp
    port = "#{port}/tcp"
  port

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
  
  for name, config of services
    if !name.match /^[a-zA-Z0-9-]+$/
      errors.push new TUGBOATFormatException "#{name.cyan} is not a valid service name."
    if typeof services isnt 'object' or services instanceof Array
      errors.push new TUGBOATFormatException "The value of #{name.cyan} is not an object of strings."
      continue
    
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
    
    # Fig - copy current environment variables into empty values
    if config.environment? and isobjectofstringsornull config.environment
      results = []
      for key, value of config.environment
        if value is '' or value is null and process.env[key]?
          results.push "#{key}=#{process.env[key]}"
        else
          results.push "#{key}=#{value}"
      config.environment = results
    
    if config.expose?
      results = {}
      config.expose = config.expose.map (e) ->
      for e in config.expose
        results[parse_port e] = {}
      config.expose = results
    
    if config.ports?
      results = {}
      for p in config.ports
        chunks = p.split ':'
        if chunks.length is 1
          results[parse_port chunks[0]] = [
            HostPort: chunks[0]
          ]
        else if chunks.length is 2
          results[parse_port chunks[1]] = [
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
    
    config.name = "#{groupname}_#{name}"
    config.command = config.command.split ' ' if config.command?
    config.image = config.name if !config.image?
  
  # Convert configuration into docker format
  for name, config of services
    services[name] =
      name: config.name
      params:
        Image: config.image
        Cmd: config.command ? null
        User: config.user ? ''
        Memory: config.mem_limit ? 0
        Hostname: config.hostname ? null
        Domainname: config.domainname ? no
        Entrypoint: config.entrypoint ? null
        WorkingDir: config.working_dir ? ''
        Env: config.environment
        ExposedPorts: config.expose ? null
        HostConfig:
          Binds: config.volumes ? null
          Links: config.links ? null
          Dns: config.dns ? null
          NetworkMode: config.net ? ''
          Privileged: config.privileged ? no
          PortBindings: config.ports ? null
  
  return cb errors if errors.length isnt 0
  cb null, services
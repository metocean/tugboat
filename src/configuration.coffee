class TUGBOATFormatException extends Error
  constructor: (message) ->
    @name = 'TUGBOATFormatException'
    @message = message

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

module.exports = (groupname, containers, cb) ->
  if typeof containers isnt 'object'
    return cb [
      new TUGBOATFormatException 'This YAML file is in the wrong format. Tugboat expects names and definitions of docker containers.'
    ]
  
  errors = []
  
  if !groupname.match /^[a-zA-Z0-9-]+$/
    errors.push new TUGBOATFormatException "The YAML file #{groupname.cyan} is not a valid group name."
  
  for name, config of containers
    if !name.match /^[a-zA-Z0-9-]+$/
      errors.push new TUGBOATFormatException "#{name.cyan} is not a valid docker container name."
    if typeof containers isnt 'object' or containers instanceof Array
      errors.push new TUGBOATFormatException "The value of #{name.cyan} is not an object of strings."
      continue
    
    if config.dns? and typeof config.dns is 'string'
      config.dns = [config.dns]
    
    if config.environment? and typeof config.environment is 'array'
      result = {}
      for env in config.environment
        chunks = env.split '='
        key = chunks[0]
        value = chunks[1..].join '='
        result[key] = value
      config.environment = result
    
    count = 0
    count++ if config.build?
    count++ if config.image?
    
    if count isnt 1
      errors.push new TUGBOATFormatException "#{name.cyan} requires either a build or an image value."
    
    for key, value of config
      if !validation[key]?
        errors.push new TUGBOATFormatException "In the docker #{name.cyan} #{key.cyan} is not a known configuration option."
        continue
      if !validation[key] value
        errors.push new TUGBOATFormatException "In the docker #{name.cyan} the value of #{key.cyan} was an unexpected format."
        continue
    
    # copy current environment variables
    if config.environment? and isobjectofstringsornull config.environment
      for key, value of config.environment
        if value is '' or value is null and process.env[key]?
          config.environment[key] = process.env[key]
    
    config.name = "#{groupname}_#{name}"
  
  return cb errors if errors.length isnt 0
  cb null, containers
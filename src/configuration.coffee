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

module.exports = (dockers, cb) ->
  if typeof dockers isnt 'object'
    return cb [
      new TUGBOATFormatException 'This YML file is in the wrong format. Tugboat expects names and definitions of docker containers.'
    ]
  
  errors = []
  
  for name, config of dockers
    if !name.match /^[a-zA-Z0-9_-]+$/
      errors.push new TUGBOATFormatException "#{name.cyan} is not a valid docker container name."
    if typeof dockers isnt 'object' or dockers instanceof Array
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
  
  return cb errors if errors.length isnt 0
  cb null, dockers
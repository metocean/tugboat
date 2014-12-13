Docke = require 'docke'
yaml = require 'js-yaml'
fs = require 'fs'
path = require 'path'

class TUGBOATFormatException extends Error
  constructor: (message) ->
    @name = 'TUGBOATFormatException'
    @message = message

# Copy all of the properties on source to target, recurse if an object
copy = (source, target) ->
  for key, value of source
    if typeof value is 'object'
      target[key] = {} if !target[key]? or typeof target[key] isnt 'object'
      copy value, target[key]
    else
      target[key] = value

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
    
    @_docke = new Docke.API Docke.Parameters options
  
  _loadGroup: (item, cb) =>
    fs.readFile item, encoding: 'utf8', (err, content) =>
      return cb err if err?
      try
        content = yaml.safeLoad content
      catch e
        return cb e if e?
      
      if content instanceof Array
        return cb new TUGBOATFormatException 'Expecting names and definitions of docker containers.'
      
      cb null,
        name: path.basename item, '.yml'
        path: item
        dockers: content
  
  init: (callback) =>
    @_groups = {} if !@_groups?
    
    try
      items = fs.readdirSync @_options.groupsdir
    catch e
      return callback [
        path: @_options.groupsdir
        error: e
      ]
    
    tasks = []
    errors = []
    results = []
    for item in items
      continue if !item.match /\.yml$/
      do (item) =>
        tasks.push (cb) =>
          item = "#{process.cwd()}/#{item}"
          @_loadGroup item, (err, group) =>
            if err?
              errors.push
                path: item
                error: err
              return cb()
            @_groups[group.name] = group
            cb()
    parallel tasks, ->
      return callback errors if errors.length isnt 0
      callback null
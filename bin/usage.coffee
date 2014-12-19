require 'colors'
commands = require './commands'
Tugboat = require '../src/tugboat'

usage = """
👾

  Usage: #{'tug'.cyan} command parameters

  Common:
  
    ps          List all running and available groups
    up          Update and run services
    down        Stop services
    diff        Describe the changes needed to update
  
  Management:
  
    rm          Delete services
    build       Build services
    rebuild     Build services from scratch

"""

process.on 'uncaughtException', (err) ->
  console.log '  Caught exception: '.red
  console.log err

# General purpose printing an error and usage
usage_error = (message) =>
  console.error()
  console.error "  #{message}".magenta
  console.error()
  console.error usage
  process.exit 1

args = process.argv[2..]
tugboat = new Tugboat args

if args.length is 0
  console.error usage
  return commands.status tugboat


cmds =
  status: ->
    return commands.status tugboat if args.length is 0
    usage_error 'tug status requires no arguments'
  
  ps: ->
    commands.ps tugboat, args
  
  diff: ->
    return commands.diff tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug diff requires a group name'
  
  start: -> cmds.up()
  up: ->
    return commands.up tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug up requires a group name'
  
  stop: -> cmds.down()
  down: ->
    return commands.down tugboat, args[0], args[1..]
  
  rm: ->
    return commands.rm tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug rm requires a group name'
  
  build: ->
    commands.build tugboat, args
  
  rebuild: ->
    commands.rebuild tugboat, args

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known tug command"
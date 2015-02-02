require 'colors'
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
  
    cull        Terminate, stop and remove services
    recreate    Terminate, stop, remove and recreate services
    rm          Delete services
    kill        Gracefully terminate services
    build       Build services
    rebuild     Build services from scratch
    logs        Display group logs

"""
build = require './build'
commands =
  status: require './status'
  diff: require './diff'
  up: require './up'
  rm: require './rm'
  down: require './down'
  ps: require './ps'
  pull: require './pull'
  cull: require './cull'
  kill: require './kill'
  recreate: require './recreate'
  logs: require './logs'
  # Different cache options for the same build function
  build: (tugboat, names) -> build tugboat, names, yes
  rebuild: (tugboat, names) -> build tugboat, names, no

process.on 'uncaughtException', (err) ->
  console.error '  Caught exception: '.red
  console.error err.stack

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
  
  kill: ->
    return commands.kill tugboat, args[0], args[1..]
  
  nuke: -> cmds.cull()
  cull: ->
    return commands.cull tugboat, args[0], args[1..]
  
  restart: -> cmds.recreate()
  recreate: ->
    return commands.recreate tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug recreate requires a group name'
  
  rm: ->
    return commands.rm tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug rm requires a group name'
  
  build: ->
    commands.build tugboat, args
  
  rebuild: ->
    commands.rebuild tugboat, args
  
  pull: ->
    commands.pull tugboat, args
  
  logs: ->
    return commands.logs tugboat, args[0], args[1..] if args.length > 0
    usage_error 'tug logs requires a group name'

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known tug command"
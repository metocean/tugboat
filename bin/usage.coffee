require 'colors'

commands = require './commands'
Tugboat = require '../src/tugboat'

usage = """
👾

  Usage: #{'tug'.cyan} command parameters

  Commands:
  
    ps          List all running and available groups
  
  Group management:
  
    build       Build services
    rebuild     Build services from scratch

"""

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
  
  build: ->
    commands.build tugboat, args
  
  rebuild: ->
    commands.rebuild tugboat, args

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known tug command"
module.exports = (tugboat, ducke, seq, group, service, container, callback) ->
  return callback null if container.inspect.State.Running
  tugboat.start group, service, container, callback
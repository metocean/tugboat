module.exports = (tugboat, ducke, group, service, container, callback) ->
  return callback null if container.inspect.State.Running
  tugboat.start group, service, container, callback
module.exports = (tugboat, ducke, group, service, container, callback) ->
  if not container.inspect.State.Running
    return tugboat.rm group, service, container, (err) ->
      return callback err if err?
      tugboat.create group, service, callback
  tugboat.stop group, service, container, (err) ->
    return callback err if err?
    tugboat.rm group, service, container, (err) ->
      return callback err if err?
      tugboat.create group, service, callback
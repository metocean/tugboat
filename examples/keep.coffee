module.exports = (tugboat, ducke, seq, group, service, container, callback) ->
  console.log 'AWESOME NEWS'
  if not container.inspect.State.Running
    seq 'Starting', (cb) ->
      tugboat.start group, service, container, cb
  callback()
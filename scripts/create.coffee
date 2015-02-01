module.exports = (tugboat, ducke, group, service, callback) ->
  newname = "#{group.name}_#{service.name}_1"
  ducke.createContainer newname, service.service.params, (err, container) ->
    return callback err if err?
    ducke
      .container container.Id
      .start (err) ->
        return callback err if err?
        callback null, container
module.exports = (tugboat, ducke, seq, group, service, container, callback) ->
  ducke
    .container container.container.Id
    .stop callback
// Generated by CoffeeScript 1.8.0
module.exports = function(tugboat, ducke, seq, group, service, callback) {
  var newname;
  newname = "" + group.name + "_" + service.name + "_1";
  return ducke.createContainer(newname, service.service.params, function(err, container) {
    if (err != null) {
      return callback(err);
    }
    return ducke.container(container.Id).start(function(err) {
      if (err != null) {
        return callback(err);
      }
      return callback(null, newname);
    });
  });
};

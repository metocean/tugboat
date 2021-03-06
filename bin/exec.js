// Generated by CoffeeScript 1.8.0
var init_errors, seq;

seq = require('../src/seq');

init_errors = require('./errors');

module.exports = function(tugboat, groupname, servicename, cmd) {
  return tugboat.init(function(errors) {
    if (errors != null) {
      return init_errors(errors);
    }
    return tugboat.diff(function(err, groups) {
      var g, s;
      if (err != null) {
        console.error();
        console.error('  docker is down'.red);
        console.error();
        process.exit(1);
      }
      console.log();
      groupname = groupname.replace('.yml', '');
      if (groups[groupname] == null) {
        console.error(("  The group '" + groupname + "' is not available in this directory").red);
        console.error();
        process.exit(1);
      }
      g = groups[groupname];
      if (g.services[servicename] == null) {
        console.error(("  " + groupname + " " + servicename + " is not available").red);
        console.error();
        process.exit(1);
      }
      s = g.services[servicename];
      if (s.containers.length === 0) {
        console.error(("  " + groupname + " " + servicename + " is not running").red);
        console.error();
        process.exit(1);
      }
      if (s.containers.length > 1) {
        console.error(("  " + groupname + " " + servicename + " too many containers running").red);
        console.error();
        process.exit(1);
      }
      console.log("  " + 'exec'.green + " " + groupname + " " + servicename + " (" + s.containers[0].inspect.Config.Image + ")");
      console.log();
      if ((cmd == null) || cmd.length === 0) {
        cmd = ['bash'];
      }
      return tugboat.ducke.container(s.containers[0].container.Id).exec(cmd, process.stdin, process.stdout, process.stderr, function(err, code) {
        if (err != null) {
          return process.exit(1);
        }
        return process.exit(code);
      });
    });
  });
};

// Generated by CoffeeScript 1.8.0
var cull, seq, up;

seq = require('../src/seq');

cull = require('./cull');

up = require('./up');

module.exports = function(tugboat, groupname, servicenames, callback) {
  return tugboat.init(function(errors) {
    if (errors != null) {
      return init_errors(errors);
    }
    return tugboat.diff(function(err, groups) {
      var g, group, groupstoprocess, _fn, _i, _len;
      if (err != null) {
        console.error();
        console.error('  docker is down'.red);
        console.error();
        process.exit(1);
      }
      groupstoprocess = null;
      if (groupname != null) {
        groupname = groupname.replace('.yml', '');
        if (groups[groupname] == null) {
          console.error();
          console.error("  Cannot up " + groupname.red + ", " + groupname + ".yml not found in this directory");
          console.error();
          process.exit(1);
        }
        group = groups[groupname];
        if (!group.isknown) {
          console.error();
          console.error("  Cannot recreate " + groupname.red + ", " + groupname + ".yml not found in this directory");
          console.error();
          process.exit(1);
        }
        groupstoprocess = [group];
      } else {
        groupstoprocess = Object.keys(groups).filter(function(g) {
          g = groups[g];
          return Object.keys(g.services).filter(function(s) {
            s = g.services[s];
            if (s.service == null) {
              return false;
            }
            return s.containers.filter(function(c) {
              return c.inspect.State.Running;
            }).length !== 0;
          }).length !== 0;
        });
      }
      _fn = function(g) {
        return seq(function(cb) {
          cull(tugboat, g, [], function() {
            return up(tugboat, g, []);
          });
          return cb();
        });
      };
      for (_i = 0, _len = groupstoprocess.length; _i < _len; _i++) {
        g = groupstoprocess[_i];
        if (!g.isknown) {
          console.error();
          console.error("  Cannot up " + g.name.red + ", " + groupname + ".yml file not found in this directory");
          continue;
        }
        _fn(g);
      }
      return seq(function(cb) {
        cb();
        if (callback != null) {
          return callback();
        }
      });
    });
  });
};

// Generated by CoffeeScript 1.8.0
var init_errors, series;

series = require('../src/series');

init_errors = require('./errors');

module.exports = function(tugboat, groupnames) {
  return tugboat.init(function(errors) {
    var groupname, haderror, _i, _len;
    if (errors != null) {
      return init_errors(errors);
    }
    console.log();
    if (Object.keys(tugboat._groups).length === 0) {
      console.error('  There are no groups defined in this directory'.magenta);
      console.error();
      process.exit(1);
    }
    if (groupnames.length === 0) {
      groupnames = Object.keys(tugboat._groups);
    }
    haderror = false;
    for (_i = 0, _len = groupnames.length; _i < _len; _i++) {
      groupname = groupnames[_i];
      if (tugboat._groups[groupname] == null) {
        console.error(("  The group '" + groupname + "' is not available in this directory").red);
        console.error();
        haderror = true;
      }
    }
    if (haderror) {
      process.exit(1);
    }
    return tugboat.ducke.ls(function(err, images) {
      var group, tasks, _fn, _j, _len1;
      if (err != null) {
        console.error();
        console.error('  docker is down'.red);
        console.error();
        process.exit(1);
      }
      console.log(images.tags['phusion/baseimage:0.9.15']);
      tasks = [];
      _fn = function(groupname, group) {
        var config, servicename, _fn1, _ref;
        tasks.push(function(cb) {
          console.log("  Pulling images for " + groupname.blue + "...");
          console.log();
          return cb();
        });
        _ref = group.services;
        _fn1 = function(servicename, config) {
          return tasks.push(function(cb) {
            var output;
            output = servicename.cyan;
            while (output.length < 32) {
              output += ' ';
            }
            console.log("  " + output + " Pulling " + config.params.Image.cyan);
            return cb();
          });
        };
        for (servicename in _ref) {
          config = _ref[servicename];
          _fn1(servicename, config);
        }
        return tasks.push(function(cb) {
          console.log();
          return cb();
        });
      };
      for (_j = 0, _len1 = groupnames.length; _j < _len1; _j++) {
        groupname = groupnames[_j];
        group = tugboat._groups[groupname];
        _fn(groupname, group);
      }
      return series(tasks, function() {});
    });
  });
};

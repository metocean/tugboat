// Generated by CoffeeScript 1.8.0
var cname, init_errors, logs, output_error, seq;

seq = require('../src/seq');

init_errors = require('./errors');

output_error = require('./output_error');

logs = require('./logs');

cname = function(c) {
  return c.container.Names[0].substr('1');
};

module.exports = function(tugboat, groupname, servicenames) {
  return tugboat.init(function(errors) {
    if (errors != null) {
      return init_errors(errors);
    }
    return tugboat.diff(function(err, results) {
      var group, service, sname, _, _fn, _fn1, _ref, _ref1;
      if (err != null) {
        return output_error(err);
      }
      groupname = groupname.replace('.yml', '');
      console.log();
      console.log("  Updating " + groupname.blue + "...");
      console.log();
      group = results[groupname];
      sname = function(s) {
        var name;
        name = s.name;
        while (name.length < 32) {
          name += ' ';
        }
        name = name.cyan;
        if (s.service != null) {
          name = s.service.pname.cyan;
        }
        return name;
      };
      _ref = group.services;
      _fn = function(service) {
        var c, outputname, _i, _len, _ref1, _results;
        outputname = sname(service);
        seq(function(cb) {
          var m, _i, _len, _ref1;
          if (service.diff.iserror) {
            return cb(service.diff.messages);
          }
          _ref1 = service.diff.messages;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            m = _ref1[_i];
            console.log("  " + outputname + " " + m.magenta);
          }
          return cb();
        });
        _ref1 = service.diff.cull;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          c = _ref1[_i];
          _results.push((function(c) {
            return seq("" + outputname + " Culling " + (cname(c).cyan), function(cb) {
              return tugboat.cull(group, service, c, function(err, result) {
                if (err != null) {
                  return cb(err);
                }
                return cb();
              });
            });
          })(c));
        }
        return _results;
      };
      for (_ in _ref) {
        service = _ref[_];
        _fn(service);
      }
      _ref1 = group.services;
      _fn1 = function(service) {
        var c, i, outputname, _fn2, _fn3, _i, _j, _k, _len, _len1, _ref2, _ref3, _ref4, _results;
        outputname = sname(service);
        _ref2 = service.diff.migrate;
        _fn2 = function(c) {
          return seq("" + outputname + " Migrating " + (cname(c).cyan), function(cb) {
            return tugboat.migrate(group, service, c, function(err, result) {
              if (err != null) {
                return cb(err);
              }
              return cb();
            });
          });
        };
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          c = _ref2[_i];
          _fn2(c);
        }
        _ref3 = service.diff.keep;
        _fn3 = function(c) {
          return seq("" + outputname + " Keeping " + (cname(c).cyan), function(cb) {
            return tugboat.keep(group, service, c, function(err, result) {
              if (err != null) {
                return cb(err);
              }
              return cb();
            });
          });
        };
        for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
          c = _ref3[_j];
          _fn3(c);
        }
        if (service.diff.create > 0) {
          _results = [];
          for (i = _k = 1, _ref4 = service.diff.create; 1 <= _ref4 ? _k <= _ref4 : _k >= _ref4; i = 1 <= _ref4 ? ++_k : --_k) {
            _results.push(seq(function(cb) {
              return tugboat.create(group, service, function(err, name) {
                if (err != null) {
                  return cb(err);
                }
                console.log("  " + outputname + " Container " + name.cyan + " created from " + service.service.params.Image);
                return cb();
              });
            }));
          }
          return _results;
        }
      };
      for (_ in _ref1) {
        service = _ref1[_];
        _fn1(service);
      }
      return seq(function(cb) {
        logs(tugboat, groupname, servicenames);
        return cb();
      });
    });
  });
};

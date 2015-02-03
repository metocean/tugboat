// Generated by CoffeeScript 1.8.0
var init_errors;

init_errors = require('./errors');

module.exports = function(tugboat, groupname, servicenames, callback) {
  return tugboat.init(function(errors) {
    if (errors != null) {
      return init_errors(errors);
    }
    return tugboat.diff(function(err, results) {
      var c, cname, m, outputname, service, _, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
      if (err != null) {
        if (err.stack) {
          console.error(err.stack);
        } else {
          console.error(err);
        }
        return;
      }
      groupname = groupname.replace('.yml', '');
      console.log();
      console.log("  Diff of " + groupname.blue + ":");
      console.log();
      _ref = results[groupname].services;
      for (_ in _ref) {
        service = _ref[_];
        outputname = service.name;
        while (outputname.length < 32) {
          outputname += ' ';
        }
        outputname = outputname.cyan;
        if (service.service != null) {
          outputname = service.service.pname.cyan;
        }
        if (service.diff.iserror) {
          console.error("  " + outputname + " " + 'Error:'.red);
          _ref1 = service.diff.messages;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            m = _ref1[_i];
            console.log("  " + outputname + " " + m.red);
          }
          continue;
        }
        _ref2 = service.diff.messages;
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          m = _ref2[_j];
          console.log("  " + outputname + " " + m.magenta);
        }
        cname = function(c) {
          return c.container.Names[0].substr('1').cyan;
        };
        _ref3 = service.diff.cull;
        for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
          c = _ref3[_k];
          console.log("  " + outputname + " Culling " + (cname(c)));
        }
        _ref4 = service.diff.migrate;
        for (_l = 0, _len3 = _ref4.length; _l < _len3; _l++) {
          c = _ref4[_l];
          console.log("  " + outputname + " Migrating " + (cname(c)));
        }
        _ref5 = service.diff.keep;
        for (_m = 0, _len4 = _ref5.length; _m < _len4; _m++) {
          c = _ref5[_m];
          console.log("  " + outputname + " Keeping " + (cname(c)));
        }
        if (service.diff.create === 1) {
          console.log("  " + outputname + " Creating a new container from " + service.service.params.Image);
        } else if (service.diff.create > 1) {
          console.log("  " + outputname + " Creating " + (service.diff.create.toString().green) + " new containers");
        }
      }
      console.log();
      if (callback != null) {
        return callback();
      }
    });
  });
};

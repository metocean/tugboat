// Generated by CoffeeScript 1.9.1
var cname, containter_name_to_service_name, get_sorted_services, init_errors, logs, output_error, seq, toposort,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

seq = require('../src/seq');

init_errors = require('./errors');

output_error = require('./output_error');

logs = require('./logs');

toposort = require('toposort');

cname = function(c) {
  return c.container.Names[0].substr('1');
};

containter_name_to_service_name = function(container_name, groupname) {
  var re, service_name;
  re = RegExp('^' + groupname + '_');
  service_name = container_name.replace(re, '');
  service_name = service_name.replace(/_1$/, '');
  return service_name;
};

get_sorted_services = function(services, servicenames, groupname) {
  var container_name, edge, edges, error, j, k, len, len1, link, name, ref, service, service_name, sortednames, sortedservices;
  if (servicenames == null) {
    servicenames = Object.keys(services);
  }
  edges = [];
  for (name in services) {
    service = services[name];
    if (indexOf.call(servicenames, name) >= 0 && (service.service.params.HostConfig.Links != null)) {
      ref = service.service.params.HostConfig.Links;
      for (j = 0, len = ref.length; j < len; j++) {
        link = ref[j];
        container_name = link.split(':')[0];
        service_name = containter_name_to_service_name(container_name, groupname);
        if (indexOf.call(servicenames, service_name) >= 0) {
          edge = [name, service_name];
          edges.push(edge);
        }
      }
    }
  }
  try {
    sortednames = toposort.array(servicenames, edges).reverse();
  } catch (_error) {
    error = _error;
    console.error("Service link dependency could not be resolved (" + error + ")");
    process.exit(1);
  }
  sortedservices = [];
  for (k = 0, len1 = sortednames.length; k < len1; k++) {
    name = sortednames[k];
    sortedservices.push(services[name]);
  }
  return sortedservices;
};

module.exports = function(tugboat, groupname, servicenames) {
  return tugboat.init(function(errors) {
    if (errors != null) {
      return init_errors(errors);
    }
    return tugboat.diff(function(err, results) {
      var _, fn, fn1, group, haderror, j, k, l, len, len1, len2, name, service, servicestoprocess, sname;
      if (err != null) {
        return output_error(err);
      }
      groupname = groupname.replace('.yml', '');
      if (results[groupname] == null) {
        console.error();
        console.error("  Cannot up " + groupname.red + ", " + groupname + ".yml not found in this directory");
        console.error();
        process.exit(1);
      }
      group = results[groupname];
      if (!group.isknown) {
        console.error();
        console.error("  Cannot up " + groupname.red + ", " + groupname + ".yml not found in this directory");
        console.error();
        process.exit(1);
      }
      console.log();
      console.log("  Updating " + groupname.blue + "...");
      console.log();
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
      if (servicenames.length !== 0) {
        haderror = false;
        for (j = 0, len = servicenames.length; j < len; j++) {
          name = servicenames[j];
          if (group.services[name] == null) {
            console.error(("  The service '" + name + "' is not available in the group '" + group.name + "'").red);
            haderror = true;
          }
        }
        if (haderror) {
          process.exit(1);
        }
      } else {
        servicenames = (function() {
          var ref, results1;
          ref = group.services;
          results1 = [];
          for (name in ref) {
            _ = ref[name];
            results1.push(name);
          }
          return results1;
        })();
      }
      servicestoprocess = get_sorted_services(group.services, servicenames, groupname);
      if (servicestoprocess.length === 0) {
        seq(function(cb) {
          console.log("  No services to process".magenta);
          return cb();
        });
      }
      fn = function(service) {
        var c, l, len2, outputname, ref, results1;
        outputname = sname(service);
        seq(function(cb) {
          var l, len2, m, ref;
          if (service.diff.iserror) {
            return cb(service.diff.messages);
          }
          ref = service.diff.messages;
          for (l = 0, len2 = ref.length; l < len2; l++) {
            m = ref[l];
            console.log("  " + outputname + " " + m.magenta);
          }
          return cb();
        });
        ref = service.diff.cull;
        results1 = [];
        for (l = 0, len2 = ref.length; l < len2; l++) {
          c = ref[l];
          results1.push((function(c) {
            return seq(outputname + " Culling " + (cname(c).cyan), function(cb) {
              return tugboat.cull(group, service, c, function(err, result) {
                if (err != null) {
                  return cb(err);
                }
                return cb();
              });
            });
          })(c));
        }
        return results1;
      };
      for (k = 0, len1 = servicestoprocess.length; k < len1; k++) {
        service = servicestoprocess[k];
        fn(service);
      }
      fn1 = function(service) {
        var c, fn2, fn3, i, len3, len4, n, o, outputname, p, ref, ref1, ref2, results1;
        outputname = sname(service);
        ref = service.diff.migrate;
        fn2 = function(c) {
          return seq(outputname + " Migrating " + (cname(c).cyan), function(cb) {
            return tugboat.migrate(group, service, c, function(err, result) {
              if (err != null) {
                return cb(err);
              }
              return cb();
            });
          });
        };
        for (n = 0, len3 = ref.length; n < len3; n++) {
          c = ref[n];
          fn2(c);
        }
        ref1 = service.diff.keep;
        fn3 = function(c) {
          return seq(outputname + " Keeping " + (cname(c).cyan), function(cb) {
            return tugboat.keep(group, service, c, function(err, result) {
              if (err != null) {
                return cb(err);
              }
              return cb();
            });
          });
        };
        for (o = 0, len4 = ref1.length; o < len4; o++) {
          c = ref1[o];
          fn3(c);
        }
        if (service.diff.create > 0) {
          results1 = [];
          for (i = p = 1, ref2 = service.diff.create; 1 <= ref2 ? p <= ref2 : p >= ref2; i = 1 <= ref2 ? ++p : --p) {
            results1.push(seq(function(cb) {
              return tugboat.create(group, service, function(err, name) {
                if (err != null) {
                  return cb(err);
                }
                console.log("  " + outputname + " Container " + name.cyan + " created from " + service.service.params.Image);
                return cb();
              });
            }));
          }
          return results1;
        }
      };
      for (l = 0, len2 = servicestoprocess.length; l < len2; l++) {
        service = servicestoprocess[l];
        fn1(service);
      }
      return seq(function(cb) {
        console.log();
        return cb();
      });
    });
  });
};

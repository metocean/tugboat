// Generated by CoffeeScript 1.8.0
var TUGBOATFormatException, globalvalidation, isboolean, isnumber, isobjectofstringsornull, isrestartpolicy, isscripts, isstring, isstringarray, parse_port, preprocess, resolve, template, validation,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

resolve = require('path').resolve;

template = require('./template');

TUGBOATFormatException = (function(_super) {
  __extends(TUGBOATFormatException, _super);

  function TUGBOATFormatException(message) {
    this.name = 'TUGBOATFormatException';
    this.message = message;
  }

  return TUGBOATFormatException;

})(Error);

isstring = function(s) {
  return typeof s === 'string';
};

isnumber = function(s) {
  return typeof s === 'number';
};

isboolean = function(s) {
  return typeof s === 'boolean';
};

isstringarray = function(s) {
  var i, _i, _len;
  if (typeof s === 'array') {
    return false;
  }
  for (_i = 0, _len = s.length; _i < _len; _i++) {
    i = s[_i];
    if (!isstring(i)) {
      return false;
    }
  }
  return true;
};

isobjectofstringsornull = function(s) {
  var i, _;
  if (typeof s !== 'object') {
    return false;
  }
  for (_ in s) {
    i = s[_];
    if (i === null) {
      continue;
    }
    if (isstring(i)) {
      continue;
    }
    return false;
  }
  return true;
};

isrestartpolicy = function(s) {
  var chunks;
  if (typeof s === 'boolean') {
    return true;
  }
  if (typeof s !== 'string') {
    return false;
  }
  if (s === 'yes') {
    return true;
  }
  if (s === 'no') {
    return true;
  }
  chunks = s.split(':');
  if (chunks.length !== 2) {
    return false;
  }
  if (chunks[0] !== 'on-failure') {
    return false;
  }
  return true;
};

isscripts = function(s) {
  var allowed, k, v;
  if (typeof s !== 'object') {
    return false;
  }
  allowed = ['create', 'cull', 'keep', 'kill', 'migrate', 'rm', 'start', 'stop'];
  for (k in s) {
    v = s[k];
    if (__indexOf.call(allowed, k) < 0) {
      return false;
    }
    if (!isstring(v)) {
      return false;
    }
  }
  return true;
};

validation = {
  build: isstring,
  image: isstring,
  command: isstring,
  links: isstringarray,
  ports: isstringarray,
  expose: isstringarray,
  volumes: isstringarray,
  environment: isobjectofstringsornull,
  net: isstring,
  dns: isstringarray,
  working_dir: isstring,
  entrypoint: isstring,
  user: isstring,
  hostname: isstring,
  domainname: isstring,
  mem_limit: isnumber,
  privileged: isboolean,
  notes: isstring,
  restart: isrestartpolicy,
  scripts: isscripts
};

globalvalidation = {
  volumes: isstringarray,
  dns: isstringarray,
  ports: isstringarray,
  environment: isobjectofstringsornull,
  restart: isrestartpolicy,
  scripts: isscripts,
  expose: isstringarray,
  user: isstring,
  domainname: isstring,
  net: isstring,
  privileged: isboolean,
  notes: isstring,
  links: isstringarray
};

parse_port = function(port) {
  var tcp, udp;
  udp = '/udp';
  tcp = '/tcp';
  if (port.substr(port.length - udp.length) !== udp && port.substr(port.length - tcp.length) !== tcp) {
    port = "" + port + "/tcp";
  }
  return port;
};

preprocess = function(config) {
  var chunks, env, key, result, value, _i, _len, _ref;
  if (config.restart != null) {
    if (config.restart === false || config.restart === 'no') {
      delete config.restart;
    } else if (config.restart === true || config.restart === 'always') {
      config.restart = {
        Name: 'always'
      };
    } else if (config.restart.indexOf('on-failure') === 0) {
      chunks = config.restart.split(':');
      config.restart = {
        Name: chunks[0],
        MaximumRetryCount: chunks[1]
      };
    }
  }
  if ((config.dns != null) && typeof config.dns === 'string') {
    config.dns = [config.dns];
  }
  if ((config.environment != null) && config.environment instanceof Array) {
    result = {};
    _ref = config.environment;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      env = _ref[_i];
      chunks = env.split('=');
      key = chunks[0];
      value = chunks.slice(1).join('=');
      result[key] = value;
    }
    return config.environment = result;
  }
};

module.exports = function(groupname, services, path, cb) {
  var chunks, config, count, errors, filename, globals, key, name, p, pname, port, results, trigger, value, _, _i, _len, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
  if (typeof services !== 'object') {
    return cb([new TUGBOATFormatException('This YAML file is in the wrong format. Tugboat expects names and definitions of services.')]);
  }
  errors = [];
  if (!groupname.match(/^[a-zA-Z0-9-]+$/)) {
    errors.push(new TUGBOATFormatException("The YAML file " + groupname.cyan + " is not a valid group name."));
  }
  services = template(services);
  preprocess(services);
  globals = {};
  for (key in globalvalidation) {
    value = globalvalidation[key];
    if (services[key] != null) {
      if (!validation[key](services[key])) {
        errors.push(new TUGBOATFormatException("In the global configuration the value of " + key.cyan + " was an unexpected format."));
        continue;
      }
      globals[key] = services[key];
      delete services[key];
    }
  }
  for (name in services) {
    config = services[name];
    if (!name.match(/^[a-zA-Z0-9-]+$/)) {
      errors.push(new TUGBOATFormatException("" + name.cyan + " is not a valid service name."));
    }
    if (typeof services !== 'object' || services instanceof Array) {
      errors.push(new TUGBOATFormatException("The value of " + name.cyan + " is not an object of strings."));
      continue;
    }
    preprocess(config);
    if (globals.volumes != null) {
      if (config.volumes == null) {
        config.volumes = [];
      }
      config.volumes = globals.volumes.concat(config.volumes);
    }
    if (globals.dns != null) {
      if (config.dns == null) {
        config.dns = [];
      }
      config.dns = globals.dns.concat(config.dns);
    }
    if (globals.ports != null) {
      if (config.ports == null) {
        config.ports = [];
      }
      config.ports = globals.ports.concat(config.ports);
    }
    if (globals.expose != null) {
      if (config.expose == null) {
        config.expose = [];
      }
      config.expose = globals.expose.concat(config.expose);
    }
    if (globals.links != null) {
      if (config.links == null) {
        config.links = [];
      }
      config.links = globals.links.concat(config.links);
    }
    if (globals.environment != null) {
      if (config.environment == null) {
        config.environment = {};
      }
      _ref = globals.environment;
      for (key in _ref) {
        value = _ref[key];
        if (config.environment[key] != null) {
          continue;
        }
        config.environment[key] = value;
      }
    }
    if (globals.scripts != null) {
      if (config.scripts == null) {
        config.scripts = {};
      }
      _ref1 = globals.scripts;
      for (key in _ref1) {
        value = _ref1[key];
        if (config.scripts[key] != null) {
          continue;
        }
        config.scripts[key] = value;
      }
    }
    if ((globals.restart != null) && (config.restart == null)) {
      config.restart = globals.restart;
    }
    if ((globals.user != null) && (config.user == null)) {
      config.user = globals.user;
    }
    if ((globals.domainname != null) && (config.domainname == null)) {
      config.domainname = globals.domainname;
    }
    if ((globals.net != null) && (config.net == null)) {
      config.net = globals.net;
    }
    if ((globals.privileged != null) && (config.privileged == null)) {
      config.privileged = globals.privileged;
    }
    count = 0;
    if (config.build != null) {
      count++;
    }
    if (config.image != null) {
      count++;
    }
    if (count !== 1) {
      errors.push(new TUGBOATFormatException("" + name.cyan + " requires either a build or an image value."));
    }
    for (key in config) {
      value = config[key];
      if (validation[key] == null) {
        errors.push(new TUGBOATFormatException("In the service " + name.cyan + " " + key.cyan + " is not a known configuration option."));
        continue;
      }
      if (!validation[key](value)) {
        errors.push(new TUGBOATFormatException("In the service " + name.cyan + " the value of " + key.cyan + " was an unexpected format."));
        continue;
      }
    }
    if (config.volumes) {
      config.volumes = config.volumes.map(function(v) {
        var chunks;
        chunks = v.split(':');
        chunks[0] = resolve(path, chunks[0]);
        return chunks.join(':');
      });
    }
    if (config.scripts != null) {
      _ref2 = config.scripts;
      for (trigger in _ref2) {
        filename = _ref2[trigger];
        config.scripts[trigger] = resolve(path, filename);
      }
    }
    if ((config.environment != null) && isobjectofstringsornull(config.environment)) {
      results = [];
      _ref3 = config.environment;
      for (key in _ref3) {
        value = _ref3[key];
        if (value === '' || value === null && (process.env[key] != null)) {
          results.push("" + key + "=" + process.env[key]);
        } else {
          results.push("" + key + "=" + value);
        }
      }
      config.environment = results;
    }
    if (config.ports != null) {
      results = {};
      _ref4 = config.ports;
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        p = _ref4[_i];
        chunks = p.split(':');
        if (chunks.length === 1) {
          results[parse_port(chunks[0])] = [
            {
              HostIp: '0.0.0.0',
              HostPort: chunks[0]
            }
          ];
        } else if (chunks.length === 2) {
          results[parse_port(chunks[1])] = [
            {
              HostIp: '0.0.0.0',
              HostPort: chunks[0]
            }
          ];
        } else if (chunks.length === 3) {
          results[parse_port(chunks[2])] = [
            {
              HostIp: chunks[0],
              HostPort: chunks[1]
            }
          ];
        } else {
          errors.push(new TUGBOATFormatException("In the service " + name.cyan + " the port binding '" + p.cyan + "'' was an unexpected format."));
        }
      }
      config.ports = results;
    }
    if (config.expose != null) {
      results = {};
      config.expose = config.expose.map(function(e) {
        return results[parse_port(e)] = {};
      });
      config.expose = results;
    }
    if (config.ports != null) {
      if (config.expose == null) {
        config.expose = {};
      }
      _ref5 = config.ports;
      for (port in _ref5) {
        _ = _ref5[port];
        config.expose[port] = {};
      }
    }
    config.name = "" + groupname + "_" + name;
    if (config.command != null) {
      config.command = config.command.split(' ');
    }
    if (config.image == null) {
      config.image = config.name;
    }
  }
  for (name in services) {
    config = services[name];
    pname = name;
    while (pname.length < 32) {
      pname += ' ';
    }
    services[name] = {
      name: config.name,
      pname: pname,
      build: (_ref6 = config.build) != null ? _ref6 : null,
      scripts: (_ref7 = config.scripts) != null ? _ref7 : null,
      params: {
        Image: config.image,
        Cmd: (_ref8 = config.command) != null ? _ref8 : null,
        User: (_ref9 = config.user) != null ? _ref9 : '',
        Memory: (_ref10 = config.mem_limit) != null ? _ref10 : 0,
        Hostname: (_ref11 = config.hostname) != null ? _ref11 : null,
        Domainname: (_ref12 = config.domainname) != null ? _ref12 : null,
        Entrypoint: (_ref13 = config.entrypoint) != null ? _ref13 : null,
        WorkingDir: (_ref14 = config.working_dir) != null ? _ref14 : '',
        Env: config.environment,
        ExposedPorts: (_ref15 = config.expose) != null ? _ref15 : null,
        HostConfig: {
          Binds: (_ref16 = config.volumes) != null ? _ref16 : null,
          Links: (_ref17 = config.links) != null ? _ref17 : null,
          Dns: (_ref18 = config.dns) != null ? _ref18 : null,
          NetworkMode: (_ref19 = config.net) != null ? _ref19 : '',
          Privileged: (_ref20 = config.privileged) != null ? _ref20 : false,
          PortBindings: (_ref21 = config.ports) != null ? _ref21 : null,
          RestartPolicy: (_ref22 = config.restart) != null ? _ref22 : {
            Name: ''
          }
        }
      }
    };
  }
  if (errors.length !== 0) {
    return cb(errors);
  }
  return cb(null, services);
};

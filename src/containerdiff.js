// Generated by CoffeeScript 1.8.0
module.exports = function(container, service, image) {
  var additional, binding, binding2, count, e, found, item, name, output, port, source, sourceCmd, sourceout, target, targetCmd, targetout, term, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
  if (container.inspect.Image !== image.image.Id) {
    return 'Different image';
  }
  target = service.service.params;
  source = container.inspect;
  _ref = {
    Entrypoint: 'entrypoint',
    User: 'user',
    Memory: 'memory',
    WorkingDir: 'working_dir'
  };
  for (term = _i = 0, _len = _ref.length; _i < _len; term = ++_i) {
    name = _ref[term];
    if (source.Config[name] !== target[name]) {
      return "" + term + " different (" + source.Config[name] + " -> " + target[name] + ")";
    }
  }
  if (source.Config.Domainname === 'false' || source.Config.Domainname === '') {
    if (target.Domainname !== null) {
      return "domainname different (" + source.Config.Domainname + " -> " + target.domainname + ")";
    }
  } else if (source.Config.Domainname !== target.Domainname) {
    return "domainname different (" + source.Config.Domainname + " -> " + target.Domainname + ")";
  }
  if ((target.Hostname != null) && source.Config.Hostname !== target.Hostname) {
    return "hostname different (" + source.Config.Hostname + " -> " + target.Hostname + ")";
  }
  _ref1 = {
    Privileged: 'privileged',
    NetworkMode: 'net'
  };
  for (name in _ref1) {
    term = _ref1[name];
    if (source.HostConfig[name] !== target.HostConfig[name]) {
      return "" + term + " different (" + source.HostConfig[name] + " -> " + target.HostConfig[name] + ")";
    }
  }
  sourceCmd = source.Config.Cmd.join(' ');
  targetCmd = target.Cmd.join(' ');
  if (sourceCmd !== targetCmd) {
    return "command different (" + sourceCmd + " -> " + targetCmd + ")";
  }
  additional = 0;
  _ref2 = source.Config.Env;
  for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
    item = _ref2[_j];
    found = false;
    if (target.Env != null) {
      found = target.Env.filter(function(e) {
        return e === item;
      }).length !== 0;
    }
    if (!found) {
      if ((_ref3 = item.substr(0, 5)) !== 'PATH=' && _ref3 !== 'HOME=') {
        return "environment different (" + item + " -> no var provided)";
      }
      additional++;
    }
  }
  count = additional;
  output = "'not found'";
  if (target.Env != null) {
    count += target.Env.length;
    output = target.Env.join(', ');
  }
  if (source.Config.Env.length !== count) {
    return "environment different (" + (source.Config.Env.join(', ')) + " -> " + output + ")";
  }
  if (!((source.HostConfig.Dns == null) && (target.HostConfig.Dns == null))) {
    if ((source.HostConfig.Dns == null) || (target.HostConfig.Dns == null)) {
      return "dns different (" + source.HostConfig.Dns + " -> " + target.HostConfig.Dns + ")";
    }
    if (source.HostConfig.Dns.length !== target.HostConfig.Dns.length) {
      return "dns different (" + source.HostConfig.Dns.length + " items -> " + target.HostConfig.Dns.length + " items)";
    }
    _ref4 = source.HostConfig.Dns;
    for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
      e = _ref4[_k];
      if (target.HostConfig.Dns.indexOf(e === -1)) {
        return "dns different (" + e + " -> no dns provided)";
      }
    }
  }
  if (!((source.HostConfig.PortBindings == null) && (target.HostConfig.PortBindings == null))) {
    if ((source.HostConfig.PortBindings == null) || (target.HostConfig.PortBindings == null)) {
      sourceout = 'null';
      if (source.HostConfig.PortBindings != null) {
        sourceout = "" + (Object.keys(source.HostConfig.PortBindings).length) + " items";
      }
      targetout = 'null';
      if (target.HostConfig.PortBindings != null) {
        targetout = "" + (Object.keys(target.HostConfig.PortBindings).length) + " items";
      }
      return "ports different (" + sourceout + " -> " + targetout + ")";
    }
    if (Object.keys(source.HostConfig.PortBindings).length !== Object.keys(target.HostConfig.PortBindings).length) {
      return "ports different (" + (Object.keys(source.HostConfig.PortBindings).length) + " items -> " + (Object.keys(target.HostConfig.PortBindings).length) + " items)";
    }
    _ref5 = source.HostConfig.PortBindings;
    for (port in _ref5) {
      binding = _ref5[port];
      if (target.HostConfig.PortBindings[port] == null) {
        return "ports different (" + port + " not found in target)";
      }
      binding2 = target.HostConfig.PortBindings[port];
      if (binding.HostIp !== binding2.HostIp) {
        return "ports different (" + port + ", " + binding.HostIp + " -> " + binding2.HostIp + ")";
      }
      if (binding.HostPort !== binding2.HostPort) {
        return "ports different (" + port + ", " + binding.HostPort + " -> " + binding2.HostPort + ")";
      }
    }
  }
  if (!((source.Config.ExposedPorts == null) && (target.ExposedPorts == null))) {
    if ((source.Config.ExposedPorts == null) || (target.ExposedPorts == null)) {
      sourceout = 'null';
      if (source.Config.ExposedPorts != null) {
        sourceout = "" + (Object.keys(source.Config.ExposedPorts).length) + " items";
      }
      targetout = 'null';
      if (target.ExposedPorts != null) {
        targetout = "" + (Object.keys(target.ExposedPorts).length) + " items";
      }
      return "expose different (" + sourceout + " -> " + targetout + ")";
    }
    if (Object.keys(source.Config.ExposedPorts).length !== Object.keys(target.ExposedPorts).length) {
      return "expose different (" + (Object.keys(source.Config.ExposedPorts).length) + " items -> " + (Object.keys(target.ExposedPorts).length) + " items)";
    }
    _ref6 = source.Config.ExposedPorts;
    for (port in _ref6) {
      binding = _ref6[port];
      if (target.ExposedPorts[port] == null) {
        return "expose different (" + port + " not found in target)";
      }
      binding2 = target.ExposedPorts[port];
      if (binding.HostIp !== binding2.HostIp) {
        return "expose different (" + port + ", " + binding.HostIp + " -> " + binding2.HostIp + ")";
      }
      if (binding.HostPort !== binding2.HostPort) {
        return "expose different (" + port + ", " + binding.HostPort + " -> " + binding2.HostPort + ")";
      }
    }
  }
  if (!((source.HostConfig.Binds == null) && (target.HostConfig.Binds == null))) {
    if ((source.HostConfig.Binds == null) || (target.HostConfig.Binds == null)) {
      return "volumes different (" + source.HostConfig.Binds + " -> " + target.HostConfig.Binds + ")";
    }
    if (source.HostConfig.Binds.length !== target.HostConfig.Binds.length) {
      return "volumes different (" + source.HostConfig.Binds.length + " items -> " + target.HostConfig.Binds.length + " items)";
    }
    _ref7 = source.HostConfig.Binds;
    for (_l = 0, _len3 = _ref7.length; _l < _len3; _l++) {
      e = _ref7[_l];
      if (target.HostConfig.Binds.indexOf(e === -1)) {
        return "volumes different (" + e + " -> volume not bound)";
      }
    }
  }
  return null;
};

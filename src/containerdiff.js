// Generated by CoffeeScript 1.9.1
var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

module.exports = function(container, service, image) {
  var binding, binding2, currentKeys, e, env, envKey, i, index, item, j, k, l, len, len1, len2, len3, len4, len5, m, n, name, o, port, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, source, sourceCmd, sourceout, target, targetCmd, targetPorts, targetenv, targetout, term, v, value;
  if (container.inspect.Image !== image.image.Id) {
    return "Different image (" + (container.inspect.Image.substr(0, 12)) + " -> " + (image.image.Id.substr(0, 12)) + ")";
  }
  target = service.service.params;
  source = container.inspect;
  ref = {
    Entrypoint: 'entrypoint',
    User: 'user',
    Memory: 'memory',
    WorkingDir: 'working_dir'
  };
  for (term = i = 0, len = ref.length; i < len; term = ++i) {
    name = ref[term];
    if (source.Config[name] !== target[name]) {
      return term + " different (" + source.Config[name] + " -> " + target[name] + ")";
    }
  }
  if (source.Config.Domainname === 'false' || source.Config.Domainname === '') {
    if (target.Domainname !== null) {
      return "domainname different (" + source.Config.Domainname + " -> " + target.domainname + ")";
    }
  } else if ((target.Domainname != null) && source.Config.Domainname !== target.Domainname) {
    return "domainname different (" + source.Config.Domainname + " -> " + target.Domainname + ")";
  }
  if ((target.Hostname != null) && source.Config.Hostname !== target.Hostname) {
    return "hostname different (" + source.Config.Hostname + " -> " + target.Hostname + ")";
  }
  ref1 = {
    Privileged: 'privileged',
    NetworkMode: 'net'
  };
  for (name in ref1) {
    term = ref1[name];
    if (source.HostConfig[name] !== target.HostConfig[name]) {
      return term + " different (" + source.HostConfig[name] + " -> " + target.HostConfig[name] + ")";
    }
  }
  sourceCmd = source.Config.Cmd.join(' ');
  targetCmd = target.Cmd;
  if (targetCmd == null) {
    targetCmd = image.inspect.Config.Cmd;
  }
  if (targetCmd != null) {
    targetCmd = targetCmd.join(' ');
  }
  if (sourceCmd !== targetCmd) {
    return "command different (" + sourceCmd + " -> " + targetCmd + ")";
  }
  targetenv = [];
  if (image.inspect.ContainerConfig.Env != null) {
    targetenv = targetenv.concat(image.inspect.ContainerConfig.Env);
  }
  if (target.Env != null) {
    currentKeys = (function() {
      var j, len1, results;
      results = [];
      for (j = 0, len1 = targetenv.length; j < len1; j++) {
        e = targetenv[j];
        results.push(e.split('=')[0]);
      }
      return results;
    })();
    ref2 = target.Env;
    for (j = 0, len1 = ref2.length; j < len1; j++) {
      env = ref2[j];
      envKey = env.split('=')[0];
      if (indexOf.call(currentKeys, envKey) < 0) {
        targetenv.push(env);
      } else {
        for (index = l = 0, len2 = currentKeys.length; l < len2; index = ++l) {
          value = currentKeys[index];
          if (envKey === value) {
            targetenv[index] = env;
          }
        }
      }
    }
  }
  ref3 = source.Config.Env;
  for (m = 0, len3 = ref3.length; m < len3; m++) {
    item = ref3[m];
    if (targetenv.filter(function(e) {
      return e === item;
    }).length === 0) {
      return "environment different (" + item + ")";
    }
  }
  if (targetenv.length !== source.Config.Env.length) {
    return "environment different (" + (source.Config.Env.join(', ')) + " -> " + (targetenv.join(', ')) + ")";
  }
  if (!((source.HostConfig.Dns == null) && (target.HostConfig.Dns == null))) {
    if ((source.HostConfig.Dns == null) || (target.HostConfig.Dns == null)) {
      return "dns different (" + source.HostConfig.Dns + " -> " + target.HostConfig.Dns + ")";
    }
    if (source.HostConfig.Dns.length !== target.HostConfig.Dns.length) {
      return "dns different (" + source.HostConfig.Dns.length + " items -> " + target.HostConfig.Dns.length + " items)";
    }
    ref4 = source.HostConfig.Dns;
    for (n = 0, len4 = ref4.length; n < len4; n++) {
      e = ref4[n];
      if (target.HostConfig.Dns.indexOf(e) === -1) {
        return "dns different (" + e + " -> no dns provided)";
      }
    }
  }
  if (!((source.HostConfig.PortBindings == null) && (target.HostConfig.PortBindings == null))) {
    if ((source.HostConfig.PortBindings == null) || (target.HostConfig.PortBindings == null)) {
      sourceout = 'null';
      if (source.HostConfig.PortBindings != null) {
        sourceout = (Object.keys(source.HostConfig.PortBindings).length) + " items";
      }
      targetout = 'null';
      if (target.HostConfig.PortBindings != null) {
        targetout = (Object.keys(target.HostConfig.PortBindings).length) + " items";
      }
      return "ports different (" + sourceout + " -> " + targetout + ")";
    }
    if (Object.keys(source.HostConfig.PortBindings).length !== Object.keys(target.HostConfig.PortBindings).length) {
      return "ports different (" + (Object.keys(source.HostConfig.PortBindings).length) + " items -> " + (Object.keys(target.HostConfig.PortBindings).length) + " items)";
    }
    ref5 = source.HostConfig.PortBindings;
    for (port in ref5) {
      binding = ref5[port];
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
    targetPorts = target.ExposedPorts;
    if (image.inspect.ContainerConfig.ExposedPorts != null) {
      if (targetPorts == null) {
        targetPorts = {};
      }
      ref6 = image.inspect.ContainerConfig.ExposedPorts;
      for (k in ref6) {
        v = ref6[k];
        targetPorts[k] = v;
      }
    }
    if ((source.Config.ExposedPorts == null) || (targetPorts == null)) {
      sourceout = 'null';
      if (source.Config.ExposedPorts != null) {
        sourceout = (Object.keys(source.Config.ExposedPorts).length) + " items";
      }
      targetout = 'null';
      if (targetPorts != null) {
        targetout = (Object.keys(targetPorts).length) + " items";
      }
      return "expose different (" + sourceout + " -> " + targetout + ")";
    }
    if (Object.keys(source.Config.ExposedPorts).length !== Object.keys(targetPorts).length) {
      return "expose different (" + (Object.keys(source.Config.ExposedPorts).length) + " items -> " + (Object.keys(target.ExposedPorts).length) + " items)";
    }
    ref7 = source.Config.ExposedPorts;
    for (port in ref7) {
      binding = ref7[port];
      if (targetPorts[port] == null) {
        return "expose different (" + port + " not found in target)";
      }
      binding2 = targetPorts[port];
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
    ref8 = source.HostConfig.Binds;
    for (o = 0, len5 = ref8.length; o < len5; o++) {
      e = ref8[o];
      if (target.HostConfig.Binds.indexOf(e) === -1) {
        return "volumes different (" + e + " -> volume not bound)";
      }
    }
  }
  if (!((source.HostConfig.RestartPolicy == null) && (target.HostConfig.RestartPolicy == null))) {
    if ((source.HostConfig.RestartPolicy == null) || (target.HostConfig.RestartPolicy == null)) {
      return "restart policy different (" + source.HostConfig.RestartPolicy + " -> " + target.HostConfig.RestartPolicy + ")";
    }
    if (source.HostConfig.RestartPolicy.Name !== target.HostConfig.RestartPolicy.Name) {
      return "restart policy different (" + source.HostConfig.RestartPolicy.Name + " -> " + target.HostConfig.RestartPolicy.Name + ")";
    }
    if (source.HostConfig.RestartPolicy.Name === 'on-failure' && source.HostConfig.RestartPolicy.MaximumRetryCount !== target.HostConfig.RestartPolicy.MaximumRetryCount) {
      return "restart policy different (" + source.HostConfig.RestartPolicy.Name + " -> " + target.HostConfig.RestartPolicy.Name + ")";
    }
  }
  return null;
};

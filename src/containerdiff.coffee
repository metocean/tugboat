# Does not compare volumes from or links!
module.exports = (container, service, image) ->
  if container.inspect.Image isnt image.image.Id
    return "Different image (#{container.inspect.Image.substr 0, 12} -> #{image.image.Id.substr 0, 12})"
  
  target = service.service.params
  source = container.inspect
  
  # console.log 'Checking properties'
  for name, term in {
    Entrypoint: 'entrypoint'
    User: 'user'
    Memory: 'memory'
    WorkingDir: 'working_dir'
  }
    if source.Config[name] isnt target[name]
      return "#{term} different (#{source.Config[name]} -> #{target[name]})"
  
  # console.log 'Checking Domainname'
  if source.Config.Domainname is 'false' or source.Config.Domainname is ''
    if target.Domainname isnt null
      return "domainname different (#{source.Config.Domainname} -> #{target.domainname})"
  else if target.Domainname? and source.Config.Domainname isnt target.Domainname
    return "domainname different (#{source.Config.Domainname} -> #{target.Domainname})"
  
  # console.log 'Checking Hostname'
  if target.Hostname? and source.Config.Hostname isnt target.Hostname
    return "hostname different (#{source.Config.Hostname} -> #{target.Hostname})"
  
  # console.log 'Checking HostConfig'
  for name, term of {
    Privileged: 'privileged'
    NetworkMode: 'net'
  }
    if source.HostConfig[name] != target.HostConfig[name]
      return "#{term} different (#{source.HostConfig[name]} -> #{target.HostConfig[name]})"
  
  # console.log 'Checking Cmd'
  sourceCmd = source.Config.Cmd.join ' '
  targetCmd = target.Cmd
  if !targetCmd?
    targetCmd = image.inspect.Config.Cmd
  if targetCmd?
    targetCmd = targetCmd.join ' '
  if sourceCmd isnt targetCmd
    return "command different (#{sourceCmd} -> #{targetCmd})"
  
  targetenv = []
  if target.Env?
    targetenv = targetenv.concat target.Env
  if image.inspect.ContainerConfig.Env?
    targetenv = targetenv.concat image.inspect.ContainerConfig.Env
  
  # console.log 'Checking Env'
  for item in source.Config.Env
    if targetenv.filter((e) -> e is item).length is 0
      return "environment different (#{item})"
  
  if targetenv.length isnt source.Config.Env.length
    return "environment different (#{source.Config.Env.join(', ')} -> #{targetenv.join(', ')})"
  
  # console.log 'Checking Dns'
  unless !source.HostConfig.Dns? and !target.HostConfig.Dns?
    if !source.HostConfig.Dns? or !target.HostConfig.Dns?
      return "dns different (#{source.HostConfig.Dns} -> #{target.HostConfig.Dns})"
    
    if source.HostConfig.Dns.length isnt target.HostConfig.Dns.length
      return "dns different (#{source.HostConfig.Dns.length} items -> #{target.HostConfig.Dns.length} items)"
    
    for e in source.HostConfig.Dns
      if target.HostConfig.Dns.indexOf(e) is -1
        return "dns different (#{e} -> no dns provided)"
  
  # console.log 'Checking PortBindings'
  unless !source.HostConfig.PortBindings? and !target.HostConfig.PortBindings?
    if !source.HostConfig.PortBindings? or !target.HostConfig.PortBindings?
      sourceout = 'null'
      if source.HostConfig.PortBindings?
        sourceout = "#{Object.keys(source.HostConfig.PortBindings).length} items"
      targetout = 'null'
      if target.HostConfig.PortBindings?
        targetout = "#{Object.keys(target.HostConfig.PortBindings).length} items"
      return "ports different (#{sourceout} -> #{targetout})"
    
    if Object.keys(source.HostConfig.PortBindings).length isnt Object.keys(target.HostConfig.PortBindings).length
      return "ports different (#{Object.keys(source.HostConfig.PortBindings).length} items -> #{Object.keys(target.HostConfig.PortBindings).length} items)"
    
    for port, binding of source.HostConfig.PortBindings
      if !target.HostConfig.PortBindings[port]?
        return "ports different (#{port} not found in target)"
      
      binding2 = target.HostConfig.PortBindings[port]
      
      if binding.HostIp isnt binding2.HostIp
        return "ports different (#{port}, #{binding.HostIp} -> #{binding2.HostIp})"
        
      if binding.HostPort isnt binding2.HostPort
        return "ports different (#{port}, #{binding.HostPort} -> #{binding2.HostPort})"
  
  # console.log 'Checking ExposedPorts'
  unless !source.Config.ExposedPorts? and !target.ExposedPorts?
    if !source.Config.ExposedPorts? or !target.ExposedPorts?
      sourceout = 'null'
      if source.Config.ExposedPorts?
        sourceout = "#{Object.keys(source.Config.ExposedPorts).length} items"
      targetout = 'null'
      if target.ExposedPorts?
        targetout = "#{Object.keys(target.ExposedPorts).length} items"
      return "expose different (#{sourceout} -> #{targetout})"
    
    if Object.keys(source.Config.ExposedPorts).length isnt Object.keys(target.ExposedPorts).length
      return "expose different (#{Object.keys(source.Config.ExposedPorts).length} items -> #{Object.keys(target.ExposedPorts).length} items)"
    
    for port, binding of source.Config.ExposedPorts
      if !target.ExposedPorts[port]?
        return "expose different (#{port} not found in target)"
      
      binding2 = target.ExposedPorts[port]
      
      if binding.HostIp isnt binding2.HostIp
        return "expose different (#{port}, #{binding.HostIp} -> #{binding2.HostIp})"
        
      if binding.HostPort isnt binding2.HostPort
        return "expose different (#{port}, #{binding.HostPort} -> #{binding2.HostPort})"
  
  # console.log 'Checking Volumes'
  unless !source.HostConfig.Binds? and !target.HostConfig.Binds?
    if !source.HostConfig.Binds? or !target.HostConfig.Binds?
      return "volumes different (#{source.HostConfig.Binds} -> #{target.HostConfig.Binds})"
    
    if source.HostConfig.Binds.length isnt target.HostConfig.Binds.length
      return "volumes different (#{source.HostConfig.Binds.length} items -> #{target.HostConfig.Binds.length} items)"
    
    for e in source.HostConfig.Binds
      if target.HostConfig.Binds.indexOf(e) is -1
        return "volumes different (#{e} -> volume not bound)"
  
  unless !source.HostConfig.RestartPolicy? and !target.HostConfig.RestartPolicy?
    if !source.HostConfig.RestartPolicy? or !target.HostConfig.RestartPolicy?
      return "restart policy different (#{source.HostConfig.RestartPolicy} -> #{target.HostConfig.RestartPolicy})"
    
    if source.HostConfig.RestartPolicy.Name != target.HostConfig.RestartPolicy.Name
      return "restart policy different (#{source.HostConfig.RestartPolicy.Name} -> #{target.HostConfig.RestartPolicy.Name})"
    
    if source.HostConfig.RestartPolicy.Name is 'on-failure' and source.HostConfig.RestartPolicy.MaximumRetryCount != target.HostConfig.RestartPolicy.MaximumRetryCount
      return "restart policy different (#{source.HostConfig.RestartPolicy.Name} -> #{target.HostConfig.RestartPolicy.Name})"
  
  # console.log 'Not checking Links'
  # console.log 'Not checking VolumesFrom'
  
  null
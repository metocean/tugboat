diffcontainer = (container, service, image) ->
  if container.inspect.Image isnt image.image.Id
    return 'Different image'
  
  target = service.service.params
  source = container.inspect
  
  for name in [
    'Entrypoint'
    'User'
    'Memory'
    'WorkingDir'
  ]
    if source.Config[name] isnt target[name]
      return "#{name} different - #{source.Config[name]} -> #{target[name]}"
  
  if source.Config.Domainname is 'false'
    if target.Domainname isnt no
      return "Domainname different - #{source.Config.Domainname} -> target.Domainname"
  else if source.Config.Domainname isnt target.Domainname
    return "Domainname different - #{source.Config.Domainname} -> target.Domainname"
  
  if target.Hostname? and source.Config.Hostname isnt target.Hostname
    return "Domainname different - #{source.Config.Hostname} -> target.Hostname"
  
  for name in [
    'Privileged'
    'NetworkMode'
  ]
    if source.HostConfig[name] != target.HostConfig[name]
      return "#{name} different - #{source.HostConfig[name]} -> #{target.HostConfig[name]}"
  
  sourceCmd = source.Config.Cmd.join(' ')
  targetCmd = target.Cmd.join(' ')
  if sourceCmd isnt targetCmd
    return "Cmd different - #{sourceCmd} -> #{targetCmd}"
  
  additional = 0
  for item in source.Config.Env
    found = no
    if target.Env?
      found = target.Env
        .filter (e) -> e is item
        .length isnt 0
    if !found
      unless item.substr(0, 5) in ['PATH=', 'HOME=']
        return "Env different - item -> 'not found'"
      additional++
  
  count = additional
  output = "'not found'"
  if target.Env?
    count += target.Env.length
    output = target.Env.join ', '
  if source.Config.Env.length isnt count
    return "Env different - #{source.Config.Env.join(', ')} -> #{output}"
  
  
  null

identifyprimary = (service, imagerepo) ->
  if !service.isknown
    return {
      messages: ["Unknown service #{service.name}, restart everything"]
      keep: []
      discard: service.containers
      error: []
      iserror: yes
    }
  
  # Locate the image we should be using
  tagname = service.service.params.Image
  tagname += ':latest' if tagname.indexOf ':' is -1
  if !imagerepo.tags[tagname]?
    return {
      messages: ["Image '#{service.service.params.Image}' not found"]
      keep: []
      discard: []
      error: service.containers
      iserror: yes
    }
  image = imagerepo.tags[tagname]
  
  result = {
    messages: []
    keep: []
    discard: []
    error: []
    iserror: no
  }
  
  for c in service.containers
    if result.keep.length isnt 0
      result.discard.push c
      continue
    
    difference = diffcontainer c, service, image
    
    if !difference?
      result.keep.push c
    else
      console.log difference
      result.messages.push difference
      result.discard.push c
  
  result

servicediff = (group, service, imagerepo) ->
  result =
    messages: []
    stop: []
    rm: []
    start: []
    keep: []
    error: []
    create: 0
    iserror: no
  
  # If we don't know the service the best we can do is start anything that is stopped
  # TODO: Compare images and restart if newer image--- by coping all settings? Perhaps...
  if !service.isknown
    result.messages.push 'Unknown service, starting anything that is stopped.'
    result.start = service.containers.filter (c) ->
        !c.inspect.State.Running
    return result
  
  { messages, keep, discard, error, iserror } = identifyprimary service, imagerepo
  
  for k in keep
    result.start.push k if !k.inspect.State.Running
    result.keep.push k
  for d in discard
    result.stop.push d if d.inspect.State.Running
    result.rm.push d
  for e in error
    result.error.push e
  for m in messages
    result.messages.push m
  result.iserror = iserror
  
  if !result.iserror
    result.create++ while result.create + keep.length < 1
  
  console.log "#{group.name} #{service.name}"
  console.log "  messages:"
  for m in result.messages
    console.log "    #{m}"
  console.log "  stop: #{result.stop.length}"
  console.log "  rm: #{result.rm.length}"
  console.log "  start: #{result.start.length}"
  console.log "  keep: #{result.keep.length}"
  console.log "  error: #{result.error.length}"
  console.log "  create: #{result.create}"
  console.log "  iserror: #{result.iserror}"
  
  result

module.exports = (imagerepo, groups) ->
  for _, g of groups
    for _, s of g.services
      s.diff = servicediff g, s, imagerepo
  
  groups
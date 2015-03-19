getcorrectname = (names) ->
  # Given a list of names, will find the name with
  # only a single, leading slash, return it without the slash.
  # This is because ducke create multiple names for each container, 
  # and the one without middle slashes is most likely to be correct.
  for name in names
    name = name[1..]
    if '/' not in name
      return name
  return names[0][1..]


module.exports = (groups, statuses) ->
  # Start with all the known groups
  # So we can compare them to running containers
  results = {}
  for groupname, group of groups
    g =
      name: groupname
      group: group
      isknown: yes
      services: {}
    
    for name, service of group.services
      g.services[name] =
        name: name
        service: service
        isknown: yes
        containers: []
    results[groupname] = g
  
  # Merge information about running containers
  for status in statuses
    names = status.container.Names
    name = getcorrectname names
    chunks = name.split '_'
    continue if chunks.length isnt 3
    [groupname, name, index] = chunks
    
    # Create groups that we don't know about
    if !results[groupname]?
      results[groupname] =
        name: groupname
        group: null
        isknown: no
        services: {}
    group = results[groupname]
    
    # Create services that we don't know about
    if !group.services[name]?
      group.services[name] =
        name: name
        service: null
        isknown: no
        containers: []
    
    # Record multiple containers for each service
    group.services[name].containers.push
      index: index
      container: status.container
      inspect: status.inspect
  
  results
module.exports = (groups, statuses) ->
  # Start with all the known groups
  # So they are filled with matching containers
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
  
  # 
  for status in statuses
    name = status.container.Names[0].substr 1
    chunks = name.split '_'
    continue if chunks.length isnt 3
    [groupname, name, index] = chunks
    if !results[groupname]?
      results[groupname] =
        name: groupname
        group: null
        isknown: no
        services: {}
    group = results[groupname]
    
    if !group.services[name]?
      group.services[name] =
        name: name
        service: null
        isknown: no
        containers: []
    
    service = group.services[name]
    service.containers.push
      index: index
      container: status.container
      inspect: status.inspect
  
  results
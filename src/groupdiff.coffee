module.exports = (groups, containers) ->
  results = {}
  for groupname, group of groups
    
    g =
      name: groupname
      group: group
      isknown: yes
      containers: {}
    
    for name, container of group.containers
      g.containers[name] =
        name: name
        container: container
        isknown: yes
        indexes: []
    results[groupname] = g
  
  for c in containers
    name = c.container.Names[0].substr 1
    chunks = name.split '_'
    continue if chunks.length isnt 3
    [groupname, name, index] = chunks
    if !results[groupname]?
      results[groupname] =
        name: groupname
        group: null
        isknown: no
        containers: {}
    group = results[groupname]
    
    if !group.containers[name]?
      group.containers[name] =
        name: name
        container: null
        isknown: no
        indexes: []
    
    container = group.containers[name]
    container.indexes.push
      index: index
      container: c.container
      inspect: c.inspect
  
  results
containerdiff = require './containerdiff'

identifyprimary = (service, imagerepo) ->
  # Locate the image we should be using
  tagname = service.service.params.Image
  tagname += ':latest' if tagname.indexOf(':') is -1
  if !imagerepo.tags[tagname]?
    return {
      messages: ["Image '#{service.service.params.Image}' not found"]
      error: service.containers
      iserror: yes
      keep: []
      migrate: []
      cull: []
    }
  
  image = imagerepo.tags[tagname]
  
  result =
    messages: []
    error: []
    iserror: no
    keep: []
    migrate: []
    cull: []
  
  for c in service.containers
    if result.keep.length isnt 0
      result.cull.push c
      continue
    
    difference = containerdiff c, service, image
    
    if !difference?
      result.keep.push c
    else
      result.messages.push difference
      result.migrate.push c
  
  result

servicediff = (group, service, imagerepo) ->
  if !service.isknown
    return {
      messages: ['Unknown service.']
      error: []
      iserror: no
      keep: []
      migrate: []
      cull: []
      create: 0
    }
  
  result = identifyprimary service, imagerepo
  
  if !result.iserror
    result.create++ while result.create + result.keep.length + result.migrate.length < 1
  result

module.exports = (imagerepo, groups) ->
  for _, g of groups
    for _, s of g.services
      s.diff = servicediff g, s, imagerepo
  groups
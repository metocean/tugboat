# Replace template tags
template = (content) ->
  type = typeof content
  if type is 'object'
    for key, value of content
      content[key] = template value
    content
  else if type is 'string'
    content.replace /#\{([a-zA-Z0-9_]+?)\}/g, (match, token) ->
      if process.env[token]?
        process.env[token]
      else
        match
  else if type is 'array'
    content.map (i) -> template i
  else
    content

module.exports = template
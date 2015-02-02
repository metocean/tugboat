error = (err) ->
  if typeof err is 'Array'
    error m for m in err
  else if err.content?
    console.error err.content
  else if err.stack?
    console.error err.stack
  else
    console.error err

module.exports = error
delay = (f) -> setTimeout f, 1

class Seq
  constructor: ->
    @_frames = []

  _next: =>
    while @_frames.length isnt 0 and @_frames[0].length is 0
      @_frames.shift()
    return if @_frames.length is 0
    item = @_frames[0].shift()
    @_frames.unshift []
    if item.description?
      item.action (err) =>
        if err?
          console.log "  #{item.description} #{'X'.red}"
          return @_error err
        console.log "  #{item.description} #{'√'.green}"
        @_next()
    else
      item.action (err) =>
        return @_error err if err?
        @_next()

  _error: (err) =>
    if typeof err is 'Array'
      @error m for m in err
    else if err.content?
      console.error "  #{err.content.red}"
    else if err.stack?
      console.error err.stack
    else
      console.error err

  push: (description, action) =>
    if !action?
      action = description
      description = null
    if @_frames.length is 0
      @_frames.push []
      delay => @_next()
    @_frames[0].push
      description: description
      action: action

module.exports = new Seq().push
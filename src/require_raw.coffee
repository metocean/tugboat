module.exports = (module) ->
  delete require.cache[require.resolve module]
  require module
# General purpose error reporting
module.exports = (errors) ->
  for e in errors
    console.error()
    console.error "  #{e.path}".red
    for err, index in e.errors
      if !err.name?
        console.error err
        continue
      if err.name is 'YAMLException'
        console.error "  #{index + 1}) #{e.path}:#{err.mark.line + 1}"
        console.error err.message
      else if err.name is 'TUGBOATFormatException'
        console.error "  #{index + 1}) #{err.message}"
      else
        console.error "  #{index + 1}) Unknown error:"
        console.error err
  console.error()
  process.exit 1
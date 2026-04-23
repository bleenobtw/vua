local _, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

return function(fn)
  return newValidator("lazy", function(value, path)
    return fn():parse(value, path)
  end)
end
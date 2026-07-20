local base = require "main.base"
local _, newValidator = table.unpack(base)

return function(fn)
  return newValidator("lazy", function(value, path)
    return fn():parse(value, path)
  end)
end

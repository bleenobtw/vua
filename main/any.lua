local base = require "main.base"
local _, newValidator = table.unpack(base)

return function()
  local self = newValidator("any", function(value)
    return true, value
  end)
  self.__optional = true
  return self
end

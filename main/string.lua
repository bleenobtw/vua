local CBaseValidator, newValidator = table.unpack(require "main.base")

local StringValidator = setmetatable({}, { __index = CBaseValidator })
StringValidator.__index = StringValidator

function StringValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value < n then
      return false, message or ("[%s] string must be at least %d character(s), got %d"):format(path, n, #value)
    end
    return true, value
  end)
  return self
end

return function()
  return setmetatable(
    newValidator("string", function(value, path)
      if type(value) ~= "string" then
        return false, ("[%s] expected string, got %s"):format(path, type(value))
      end
      return true, value
    end)
  , StringValidator)
end
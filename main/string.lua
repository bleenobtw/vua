local CBaseValidator, newValidator = table.unpack(require "main.base")

local StringValidator = setmetatable({}, { __index = CBaseValidator })
StringValidator.__index = StringValidator

--- Ensures that the value is atleast n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function StringValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value < n then
      return false, message or ("[%s] string must be at least %d character(s), got %d"):format(path, n, #value)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value is at most n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function StringValidator:max(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value > n then
      return false, message or ("[%s] string must be at most %d character(s), got %d"):format(path, n, #value)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value is exactly n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function StringValidator:length(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value ~= n then
      return false, message or ("[%s] string must be exactly %d character(s), got %d"):format(path, n, #value)
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
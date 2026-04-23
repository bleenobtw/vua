local CBaseValidator, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

local CStringValidator = setmetatable({}, { __index = CBaseValidator })
CStringValidator.__index = CStringValidator

--- Ensures that the value is atleast n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value < n then
      return false, message or ("[%s] string must be at least %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value is at most n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:max(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value > n then
      return false, message or ("[%s] string must be at most %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

function CStringValidator:nonEmpty(message)
  return self:min(1, message)
end

--- Ensures that the value is exactly n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:length(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value ~= n then
      return false, message or ("[%s] string must be exactly %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value passes the provided pattern.
---@param pattern sting # The pattern that the string must pass.
---@param message string # The message to return if this validator fails.
function CStringValidator:pattern(pattern, message)
  table.insert(self.__refinements, function(value, path)
    return true, value:match("^%s*(.-)%s*$")
  end)
  return self
end

--- Uppercases the string.
function CStringValidator:upper()
  table.insert(self.__refinements, function(value, path)
    return true, value:upper()
  end)
  return self
end

--- Lowercases the string.
function CStringValidator:lower()
  table.insert(self.__refinements, function(value, path)
    return true, value:lower()
  end)
  return self
end

--- Ensures that the value passed starts with the provided prefix.
---@param prefix sting # The prefix that the string must start with.
---@param message string # The message to return if this validator fails.
function CStringValidator:startsWith(prefix, message)
  table.insert(self.__refinements, function(value, path)
    if value:sub(1, #prefix) ~= prefix then
      return false, message or ("[%s] string must start with '%s'"):format(helpers.pathToString(path), prefix)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value passed ends with the provided suffix.
---@param suffix sting # The suffix that the string must end with.
---@param message string # The message to return if this validator fails.
function CStringValidator:endsWith(suffix, message)
  table.insert(self.__refinements, function(value, path)
    if value:sub(-#suffix) ~= suffix then
      return false, message or ("[%s] string must end with '%s'"):format(helpers.pathToString(path), suffix)
    end
    return true, value
  end)
  return self
end

--- Ensures that the value passed inclues the provided sub string.
---@param subString sting # The sub string that the value must include.
---@param message string # The message to return if this validator fails.
function CStringValidator:includes(subString, message)
  table.insert(self.__refinements, function(value, path)
    if not value:find(subString, 1, true) then
      return false, ("[%s] string must include '%s'"):format(helpers.pathToString(path), subString)
    end
    return true, value
  end)
  return self
end

return function()
  return setmetatable(
    newValidator("string", function(value, path)
      if type(value) ~= "string" then
        return false, ("[%s] expected string, got %s"):format(helpers.pathToString(path), type(value))
      end
      return true, value
    end)
  , CStringValidator)
end
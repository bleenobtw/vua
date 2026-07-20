local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CStringValidator = setmetatable({}, { __index = CBaseValidator })
CStringValidator.__index = CStringValidator

--- Ensures that the value is atleast n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:min(n, message)
  return self:_addRefinement(function(value, path)
    if #value < n then
      return false, message or ("[%s] string must be at least %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

--- Ensures that the value is at most n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:max(n, message)
  return self:_addRefinement(function(value, path)
    if #value > n then
      return false, message or ("[%s] string must be at most %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

function CStringValidator:nonEmpty(message)
  return self:min(1, message)
end

--- Ensures that the value is exactly n characters long.
---@param n number
---@param message string # The message to return if this validator fails.
function CStringValidator:length(n, message)
  return self:_addRefinement(function(value, path)
    if #value ~= n then
      return false, message or ("[%s] string must be exactly %d character(s), got %d"):format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

--- Ensures that the value passes the provided pattern.
---@param pattern sting # The pattern that the string must pass.
---@param message string # The message to return if this validator fails.
function CStringValidator:pattern(pattern, message)
  return self:_addRefinement(function(value, path)
    if not value:match(pattern) then
      return false, message or ("[%s] string must match pattern '%s'"):format(helpers.pathToString(path), pattern)
    end
    return true, value
  end)
end

--- Uppercases the string.
function CStringValidator:upper()
  return self:_addRefinement(function(value, path)
    return true, value:upper()
  end)
end

--- Lowercases the string.
function CStringValidator:lower()
  return self:_addRefinement(function(value, path)
    return true, value:lower()
  end)
end

--- Ensures that the value passed starts with the provided prefix.
---@param prefix sting # The prefix that the string must start with.
---@param message string # The message to return if this validator fails.
function CStringValidator:startsWith(prefix, message)
  return self:_addRefinement(function(value, path)
    if value:sub(1, #prefix) ~= prefix then
      return false, message or ("[%s] string must start with '%s'"):format(helpers.pathToString(path), prefix)
    end
    return true, value
  end)
end

--- Ensures that the value passed ends with the provided suffix.
---@param suffix sting # The suffix that the string must end with.
---@param message string # The message to return if this validator fails.
function CStringValidator:endsWith(suffix, message)
  return self:_addRefinement(function(value, path)
    if value:sub(-#suffix) ~= suffix then
      return false, message or ("[%s] string must end with '%s'"):format(helpers.pathToString(path), suffix)
    end
    return true, value
  end)
end

--- Ensures that the value passed inclues the provided sub string.
---@param subString sting # The sub string that the value must include.
---@param message string # The message to return if this validator fails.
function CStringValidator:includes(subString, message)
  return self:_addRefinement(function(value, path)
    if not value:find(subString, 1, true) then
      return false, message or ("[%s] string must include '%s'"):format(helpers.pathToString(path), subString)
    end
    return true, value
  end)
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

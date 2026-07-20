local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CNumberValidator = setmetatable({}, { __index = CBaseValidator })
CNumberValidator.__index = CNumberValidator

function CNumberValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if value < n then
      return false, message or ("[%s] number must be >= %s, got %s"):format(helpers.pathToString(path), n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:max(n, message)
  table.insert(self.__refinements, function(value, path)
    if value > n then
      return false, message or ("[%s] number must be <= %s, got %s"):format(helpers.pathToString(path), n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:gt(n, message)
  table.insert(self.__refinements, function(value, path)
    if value <= n then
      return false, message or ("[%s] number must be > %s, got %s"):format(helpers.pathToString(path), n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:lt(n, message)
  table.insert(self.__refinements, function(value, path)
    if value >= n then
      return false, message or ("[%s] number must be < %s, got %s"):format(helpers.pathToString(path), n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:int(message)
  table.insert(self.__refinements, function(value, path)
    if value ~= math.floor(value) then
      return false, message or ("[%s] expected integer, got float %s"):format(helpers.pathToString(path), value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:positive(message)
  table.insert(self.__refinements, function(value, path)
    if value <= 0 then
      return false, message or ("[%s] number must be positive, got %s"):format(helpers.pathToString(path), value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:negative(message)
  table.insert(self.__refinements, function(value, path)
    if value >= 0 then
      return false, message or ("[%s] number must be negative, got %s"):format(helpers.pathToString(path), value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:between(lo, hi, message)
  return self:min(lo, message):max(hi, message)
end

function CNumberValidator:multipleOf(n, message)
  table.insert(self.__refinements, function(value, path)
    if value % n ~= 0 then
      return false, message or ("[%s] number must be a multiple of %s"):format(helpers.pathToString(path), n)
    end
    return true, value
  end)
  return self
end

return function()
  return setmetatable(
    newValidator("number", function(value, path)
      if type(value) ~= "number" then
        return false, ("[%s] expected number, got %s"):format(helpers.pathToString(path), type(value))
      end
      return true, value
    end)
  , CNumberValidator)
end

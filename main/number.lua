local CBaseValidator, newValidator = table.unpack(require "main.base")

local CNumberValidator = setmetatable({}, { __index = CBaseValidator })
CNumberValidator.__index = CNumberValidator

function CNumberValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if value < n then
      return false, message or ("[%s] number must be >= %s, got %s"):format(path, n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:max(n, message)
  table.insert(self.__refinements, function(value, path)
    if value > n then
      return false, message or ("[%s] number must be <= %s, got %s"):format(path, n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:gt(n, message)
  table.insert(self.__refinements, function(value, path)
    if value <= n then
      return false, message or ("[%s] number must be < %s, got %s"):format(path, n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:lt(n, message)
  table.insert(self.__refinements, function(value, path)
    if value >= n then
      return false, message or ("[%s] number must be < %s, got %s"):format(path, n, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:int(n, message)
  table.insert(self.__refinements, function(value, path)
    if value ~= math.floor(value) then
      return false, message or ("[%s] expected integer, got float %s"):format(path, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:positive(n, message)
  table.insert(self.__refinements, function(value, path)
    if value <= 0 then
      return false, message or ("[%s] number must be positive, got %s"):format(path, value)
    end
    return true, value
  end)
  return self
end

function CNumberValidator:negative(n, message)
  table.insert(self.__refinements, function(value, path)
    if value >= 0 then
      return false, message or ("[%s] number must be negative, got %s"):format(path, value)
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
      return false, message or ("[%s] number must be a multiple of %s"):format(path, n)
    end
    return true, value
  end)
  return self
end

return function()
  return setmetatable(
    newValidator("number", function(value, path)
      if type(value) ~= "number" then
        return false, ("[%s] expected number, got %s"):format(path, type(value))
      end
      return true, value
    end)
  , CNumberValidator)
end
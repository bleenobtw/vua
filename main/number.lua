local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CNumberValidator = setmetatable({}, { __index = CBaseValidator })
CNumberValidator.__index = CNumberValidator

function CNumberValidator:min(n, message)
  return self:_addRefinement(function(value, path)
    if value < n then
      return false, helpers.issue(path, "too_small", message or ("number must be >= %s, got %s"):format(n, value), n, value)
    end
    return true, value
  end)
end

function CNumberValidator:max(n, message)
  return self:_addRefinement(function(value, path)
    if value > n then
      return false, helpers.issue(path, "too_big", message or ("number must be <= %s, got %s"):format(n, value), n, value)
    end
    return true, value
  end)
end

function CNumberValidator:gt(n, message)
  return self:_addRefinement(function(value, path)
    if value <= n then
      return false, helpers.issue(path, "too_small", message or ("number must be > %s, got %s"):format(n, value), n, value)
    end
    return true, value
  end)
end

function CNumberValidator:lt(n, message)
  return self:_addRefinement(function(value, path)
    if value >= n then
      return false, helpers.issue(path, "too_big", message or ("number must be < %s, got %s"):format(n, value), n, value)
    end
    return true, value
  end)
end

function CNumberValidator:int(message)
  return self:_addRefinement(function(value, path)
    if value ~= math.floor(value) then
      return false, helpers.issue(path, "not_integer", message or ("expected integer, got float %s"):format(value), "integer", value)
    end
    return true, value
  end)
end

function CNumberValidator:positive(message)
  return self:_addRefinement(function(value, path)
    if value <= 0 then
      return false, helpers.issue(path, "not_positive", message or ("number must be positive, got %s"):format(value), "> 0", value)
    end
    return true, value
  end)
end

function CNumberValidator:negative(message)
  return self:_addRefinement(function(value, path)
    if value >= 0 then
      return false, helpers.issue(path, "not_negative", message or ("number must be negative, got %s"):format(value), "< 0", value)
    end
    return true, value
  end)
end

function CNumberValidator:between(lo, hi, message)
  return self:min(lo, message):max(hi, message)
end

function CNumberValidator:multipleOf(n, message)
  return self:_addRefinement(function(value, path)
    if value % n ~= 0 then
      return false, helpers.issue(path, "not_multiple_of", message or ("number must be a multiple of %s"):format(n), n, value)
    end
    return true, value
  end)
end

return function()
  return setmetatable(
    newValidator("number", function(value, path)
      if type(value) ~= "number" then
        return false, helpers.issue(path, "invalid_type", ("expected number, got %s"):format(type(value)), "number", type(value))
      end
      return true, value
    end)
  , CNumberValidator)
end

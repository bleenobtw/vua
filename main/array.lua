local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CArrayValidator = setmetatable({}, { __index = CBaseValidator })
CArrayValidator.__index = CArrayValidator

function CArrayValidator:min(n, message)
  return self:_addRefinement(function(value, path)
    if #value < n then
      return false, message or ("[%s] array must have at least %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

function CArrayValidator:max(n, message)
  return self:_addRefinement(function(value, path)
    if #value > n then
      return false, message or ("[%s] array must have at most %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

function CArrayValidator:length(n, message)
  return self:_addRefinement(function(value, path)
    if #value ~= n then
      return false, message or ("[%s] array must have exactly %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
end

function CArrayValidator:nonEmpty(message)
  return self:min(1, message)
end

return function(itemValidator)
  helpers.assertValidator(itemValidator, "array item")

  return setmetatable(
    newValidator("array", function(value, path)
      if type(value) ~= "table" then
        return false, ("[%s] expected array (table), got %s"):format(helpers.pathToString(path), type(value))
      end

      local length, reason = helpers.arrayLength(value)
      if reason == "key" then
        return false, ("[%s] expected array, got table with non-array keys"):format(helpers.pathToString(path))
      elseif reason == "sparse" then
        return false, ("[%s] array must not contain gaps"):format(helpers.pathToString(path))
      end

      local outResults = {}
      for j = 1, length do
        local item = value[j]
        local itemPath = helpers.extendPath(path, j)
        local ok, result = itemValidator:parse(item, itemPath)

        if not ok then return false, result end
        outResults[j] = result
      end

      return true, outResults
    end)
  , CArrayValidator)
end

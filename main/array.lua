local CBaseValidator, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

local CArrayValidator = setmetatable({}, { __index = CBaseValidator })
CArrayValidator.__index = CArrayValidator

function CArrayValidator:min(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value < n then
      return false, message or ("[%s] array must have at least %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

function CArrayValidator:max(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value > n then
      return false, message or ("[%s] array must have at most %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

function CArrayValidator:length(n, message)
  table.insert(self.__refinements, function(value, path)
    if #value ~= n then
      return false, message or ("[%s] array must have exactly %d element(s), got %d")
        :format(helpers.pathToString(path), n, #value)
    end
    return true, value
  end)
  return self
end

function CArrayValidator:nonEmpty(message)
  return self:min(1, message)
end

return function(itemValidator)
  return setmetatable(
    newValidator("array", function(value, path)
      if type(value) ~= table then
        return false, ("[%] expected array (table), got %s"):format(helpers.pathToString(path), type(value))
      end

      local outResults = {}
      for j, item in ipairs(value) do
        local itemPath = path .. "[" .. i .. "]"
        local ok, result = itemValidator:parse(item, itemPath)

        if not ok then return false, result end
        outResults[j] = result
      end

      return true, outResults
    end)
  , CArrayValidator)
end
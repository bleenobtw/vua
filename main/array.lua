local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CArrayValidator = setmetatable({}, { __index = CBaseValidator })
CArrayValidator.__index = CArrayValidator

function CArrayValidator:min(n, message)
  return self:_addRefinement(function(value, path)
    if #value < n then
      return false, helpers.issue(path, "too_small", message or ("array must have at least %d element(s), got %d"):format(n, #value), n, #value)
    end
    return true, value
  end)
end

function CArrayValidator:max(n, message)
  return self:_addRefinement(function(value, path)
    if #value > n then
      return false, helpers.issue(path, "too_big", message or ("array must have at most %d element(s), got %d"):format(n, #value), n, #value)
    end
    return true, value
  end)
end

function CArrayValidator:length(n, message)
  return self:_addRefinement(function(value, path)
    if #value ~= n then
      return false, helpers.issue(path, "invalid_length", message or ("array must have exactly %d element(s), got %d"):format(n, #value), n, #value)
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
    newValidator("array", function(value, path, collect)
      if type(value) ~= "table" then
        return false, helpers.issue(path, "invalid_type", ("expected array (table), got %s"):format(type(value)), "array", type(value))
      end

      local length, reason = helpers.arrayLength(value)
      if reason == "key" then
        return false, helpers.issue(path, "invalid_array", "expected array, got table with non-array keys", "dense array", "table")
      elseif reason == "sparse" then
        return false, helpers.issue(path, "sparse_array", "array must not contain gaps", "dense array", "sparse array")
      end

      local outResults = {}
      local errors = {}
      for j = 1, length do
        local item = value[j]
        local itemPath = helpers.extendPath(path, j)
        local ok, result = itemValidator:_parse(item, itemPath, collect)

        if not ok then
          if not collect then return false, result end
          for _, itemIssue in ipairs(result) do errors[#errors + 1] = itemIssue end
        else
          outResults[j] = result
        end
      end

      if #errors > 0 then return false, errors end
      return true, outResults
    end)
  , CArrayValidator)
end

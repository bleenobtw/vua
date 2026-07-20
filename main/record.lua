local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"
local newString = require "main.string"

local function sortedKeys(value)
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = key end
  table.sort(keys, function(a, b)
    local left = tostring(a)
    local right = tostring(b)
    if left == right then return type(a) < type(b) end
    return left < right
  end)
  return keys
end

return function(keyValidator, valueValidator)
  if valueValidator == nil then
    valueValidator = keyValidator
    keyValidator = newString()
  end

  helpers.assertValidator(keyValidator, "record key")
  helpers.assertValidator(valueValidator, "record value")

  return newValidator("record", function(value, path, collect)
    if type(value) ~= "table" then
      return false, helpers.issue(path, "invalid_type", ("expected record (table), got %s"):format(type(value)), "record", type(value))
    end

    local out = {}
    local errors = {}

    for _, key in ipairs(sortedKeys(value)) do
      local fieldPath = helpers.extendPath(path, key)
      local keyOk, parsedKey = keyValidator:_parse(key, fieldPath, collect)
      local valueOk, parsedValue = valueValidator:_parse(value[key], fieldPath, collect)

      if not keyOk then
        if not collect then return false, parsedKey end
        for _, keyIssue in ipairs(parsedKey) do errors[#errors + 1] = keyIssue end
      end

      if not valueOk then
        if not collect then return false, parsedValue end
        for _, valueIssue in ipairs(parsedValue) do errors[#errors + 1] = valueIssue end
      end

      if keyOk and valueOk then out[parsedKey] = parsedValue end
    end

    if #errors > 0 then return false, errors end
    return true, out
  end)
end

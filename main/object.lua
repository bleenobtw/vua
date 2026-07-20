local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CObjectValidator = setmetatable({}, { __index = CBaseValidator })
CObjectValidator.__index = CObjectValidator

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

local function objectCheck(schema, unknownKeys)
  return function(value, path, collect)
    if type(value) ~= "table" then
      return false, helpers.issue(path, "invalid_type", ("expected object (table), got %s"):format(type(value)), "object", type(value))
    end

    local length = helpers.arrayLength(value)
    if length and length > 0 then
      return false, helpers.issue(path, "invalid_type", "expected object, got array", "object", "array")
    end

    local errors = {}

    if unknownKeys == "strict" then
      for _, key in ipairs(sortedKeys(value)) do
        if schema[key] == nil then
          local fieldIssue = helpers.issue(path, "unrecognized_key", ("unknown key '%s' (strict mode)"):format(tostring(key)), "known key", key)
          if not collect then return false, fieldIssue end
          errors[#errors + 1] = fieldIssue
        end
      end
    end

    local out = {}
    for _, key in ipairs(sortedKeys(schema)) do
      local fieldPath = helpers.extendPath(path, key)
      local ok, result = schema[key]:_parse(value[key], fieldPath, collect)

      if not ok then
        if not collect then return false, result end
        for _, fieldIssue in ipairs(result) do errors[#errors + 1] = fieldIssue end
      elseif result ~= nil then
        out[key] = result
      end
    end

    if #errors > 0 then return false, errors end

    if unknownKeys == "passthrough" then
      for key, fieldValue in pairs(value) do
        if schema[key] == nil then out[key] = fieldValue end
      end
    end

    return true, out
  end
end

local function newObject(schema, opts)
  if type(schema) ~= "table" then error("object shape must be a table", 3) end

  for key, validator in pairs(schema) do
    if type(key) ~= "string" then error("object shape keys must be strings", 3) end
    helpers.assertValidator(validator, ("object field '%s'"):format(key))
  end

  opts = opts or {}
  local unknownKeys = opts.unknownKeys or "passthrough"
  local self = newValidator("object", objectCheck(schema, unknownKeys))
  self.__schema = schema
  self.__unknownKeys = unknownKeys
  return setmetatable(self, CObjectValidator)
end

function CObjectValidator:strict()
  local clone = self:_clone()
  clone.__unknownKeys = "strict"
  clone.__check = objectCheck(clone.__schema, "strict")
  return clone
end

function CObjectValidator:strip()
  local clone = self:_clone()
  clone.__unknownKeys = "strip"
  clone.__check = objectCheck(clone.__schema, "strip")
  return clone
end

function CObjectValidator:passthrough()
  local clone = self:_clone()
  clone.__unknownKeys = "passthrough"
  clone.__check = objectCheck(clone.__schema, "passthrough")
  return clone
end

function CObjectValidator:extend(extraSchema)
  local merged = {}
  for key, value in pairs(self.__schema) do merged[key] = value end
  for key, value in pairs(extraSchema) do merged[key] = value end
  return newObject(merged, { unknownKeys = self.__unknownKeys })
end

function CObjectValidator:pick(keys)
  local subKeys = {}
  for _, key in ipairs(keys) do
    if self.__schema[key] then subKeys[key] = self.__schema[key] end
  end
  return newObject(subKeys, { unknownKeys = self.__unknownKeys })
end

function CObjectValidator:omit(keys)
  local exclude = {}
  for _, key in ipairs(keys) do exclude[key] = true end

  local subKeys = {}
  for key, value in pairs(self.__schema) do
    if not exclude[key] then subKeys[key] = value end
  end
  return newObject(subKeys, { unknownKeys = self.__unknownKeys })
end

return newObject

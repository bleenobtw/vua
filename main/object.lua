local base = require "main.base"
local CBaseValidator, newValidator = table.unpack(base)
local helpers = require "main.helpers"

local CObjectValidator = setmetatable({}, { __index = CBaseValidator })
CObjectValidator.__index = CObjectValidator

local function newObject(schema, opts)
  opts = opts or {}
  local strict = opts.strict or false

  local self = newValidator("object", function(value, path)
    if type(value) ~= "table" then
      return false, ("[%s] expected object (table), got %s")
        :format(helpers.pathToString(path), type(value))
    end

    -- strict mode, reject unknown keys
    if strict then
      for key in pairs(value) do
        if schema[key] == nil then
          return false, ("[%s] unknown key '%s' (strict mode)"):format(helpers.pathToString(path), tostring(key))
        end
      end
    end

    local out = {}
    for key, validator in pairs(schema) do
      local fieldPath = helpers.extendPath(path, key)
      local ok, results = validator:parse(value[key], fieldPath)

      if not ok then return false, results end
      if results ~= nil then out[key] = results end
    end

    if not strict then
      for key, _value in pairs(value) do
        if schema[key] == nil then out[key] = _value end
      end
    end

    return true, out
  end)
  self.__schema = schema
  return setmetatable(self, CObjectValidator)
end

function CObjectValidator:strict()
  local previous = self.__check
  self.__check = function(value, path)
    if type(value) ~= "table" then
      return false, ("[%s] expected object (table), got %s"):format(helpers.pathToString(path), type(value))
    end

    for key in pairs(value) do
      if self.__schema[key] == nil then
        return false, ("[%s] unknown key '%s' (strict mode)"):format(helpers.pathToString(path), tostring(key))
      end
    end
    return previous(value, path)
  end
  return self
end

function CObjectValidator:extend(extraSchema)
  local merged = {}
  for key, value in pairs(self.__schema) do merged[key] = value end
  for key, value in pairs(extraSchema) do merged[key] = value end
  return newObject(merged)
end

function CObjectValidator:pick(keys)
  local subKeys = {}
  for _, key in ipairs(keys) do
    if self.__schema[key] then subKeys[key] = self.__schema[key] end
  end
  return newObject(subKeys)
end

function CObjectValidator:omit(keys)
  local exclude = {}
  for _, key in ipairs(keys) do exclude[key] = true end

  local subKeys = {}
  for key, value in pairs(self.__schema) do
    if not exclude[key] then
      subKeys[key] = value
    end
  end
  return newObject(subKeys)
end

return newObject

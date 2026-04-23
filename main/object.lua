local CBaseValidator, newValidator = table.unpack(require "main.base")

local CObjectValidator = setmetatable({}, { __index = CBaseValidator })
CObjectValidator.__index = CObjectValidator

return function(schema, opts)
  opts = opts or {}
  local strict = opts.strict or false

  local self = newValidator("object", function(value, path)
    if type(value) ~= "table" then
      return false, ("[%s] expected object (table), got %s", path, type(value))
    end

    -- strict mode, reject unknown keys
    if strict then
      for key in pairs(value) do
        if schema[key] == nil then
          return false, ("[%s] unknown key '%s' (struct mode)"):format(path, tostring(key))
        end
      end
    end

    local out = {}
    for key, validator in pairs(schema) do
      local fieldPath = path .. "." .. tostring(key)
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
local CBaseValidator = {}
CBaseValidator.__index = CBaseValidator

-- Generic parsing.
function CBaseValidator:parse(value, path)
  path = path or value

  -- handle nil
  if value == nil then
    if self.__hasDefault then
      value = self.__default
    end

    if value == nil and (self.__optional or self.__nullable) then
      return true, nil
    end

    if value == nil then
      return false, ("[%s] expected %s, got nil"):format(path, self.__label)
    end
  end

  -- nullable allows nil (handled above) or the base type
  if 
    value == nil 
    and self.__nullable
  then
    return true, nil
  end

  -- base type check.
  local ok, err = self.__check(value, path)
  if not ok then return false, err end

  -- handle refinements
  for _, ref in ipairs(self.__refinements) do
    local refOk, refErr = ref(value, path)
    if not refOk then return false, refErr end
  end

  return true, value
end

-- Safe parsing, returns { success: boolean, value|error }
function CBaseValidator:safeParse(value, path)
  local ok, result = self:parse(value, path)

  if ok then
    return { success = true, data = result }
  else
    return { success = false, error = result }
  end
end

function CBaseValidator:assert(value, path)
  local ok, result = self:parse(value, path)

  if not ok then
    error(result, 2)
  end
  return result
end

function CBaseValidator:optional()
  self.__optional = true
  return self
end

function CBaseValidator:nullable()
  self.__nullable = true
  return self
end

function CBaseValidator:default(value)
  self.__hasDefault = true
  self.__default = value
  return self
end

function CBaseValidator:label(label)
  self.__label = label
  return self
end

function CBaseValidator:refine(fn, message)
  table.insert(self.__refinements, function(value, path)
    local ok, customErr = fn(value)

    if not ok then
      return false, ("[%s] %s"):format(path, customErr or message or "custom validation failed")
    end
    return true, value
  end)
  return self
end

return CBaseValidator, function(baseType, checkFn)
  return setmetatable({
    __type = baseType,
    __check = checkFn,

    __refinements = {},

    __optional = false,
    __nullable = false,

    __default = nil,
    __hasDefault = false,
    __label = baseType
  }, CBaseValidator)
end
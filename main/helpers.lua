local function pathToString(path)
  if type(path) == "table" then
    if #path == 0 then return "<root>" end
    
    return table.concat(path, ".")
  end
  return tostring(path or "<root>")
end

local function extendPath(path, key)
  if type(path) ~= "table" then
    path = path and { path } or {}
  end

  local extended = {}
  for i = 1, #path do extended[i] = path[i] end
  extended[#extended + 1] = tostring(key)
  return extended
end

local function arrayLength(value)
  local count = 0
  local highest = 0

  for key in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return nil, "key"
    end

    count = count + 1
    if key > highest then highest = key end
  end

  if highest ~= count then return nil, "sparse" end
  return count
end

local function assertValidator(value, name)
  if type(value) ~= "table" or type(value.parse) ~= "function" then
    error(("%s must be a schema"):format(name), 3)
  end
end

return {
  pathToString = pathToString,
  extendPath = extendPath,
  arrayLength = arrayLength,
  assertValidator = assertValidator,
}

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

return {
  pathToString = pathToString,
  extendPath = extendPath,
}

local function pathToString(path)
  if type(path) == "table" then
    if #path == 0 then return "<root>" end
    
    return table.concat(path, ".")
  end
  return tostring(path or "<root>")
end


return {
  pathToString = pathToString,
}
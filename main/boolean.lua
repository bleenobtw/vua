return function()
  return newValidator("boolean", function(value, path)
    if type(value) ~= "boolean" then
      return false, ("[%s] expected boolean, got %s"):format(path, type(value))
    end
    return true, value
  end)
end
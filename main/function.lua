local _, newValidator = table.unpack(require "main.base")

return function()
  return newValidator("function", function(value, path)
    if type(value) ~= "function" then
      return false, ("[%s] expected function, got %s"):format(path, type(value))
    end
    return true, value
  end)
end
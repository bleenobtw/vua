local _, newValidator = table.unpack(require "main.base")

return function()
  return newValidator("table", function(value, path)
    if type(value) ~= "table" then
      return false, ("[%s] expected table, got %s"):format(path, type(value))
    end
    return true, value
  end)
end
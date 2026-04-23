local _, newValidator = table.unpack(require "main.base")

return function(expected)
  local label = tostring(expected)
  
  local self = newValidator(("literal(%s)"):format(label), function(value, path)
    if value ~= expected then
      return false, ("[%s] expected literal %s, got %s", path, label, tostring(value))
    end
    return true, value
  end)
  self.__label = label
  return self
end
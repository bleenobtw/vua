local base = require "main.base"
local _, newValidator = table.unpack(base)

return function(fn)
  if type(fn) ~= "function" then error("lazy requires a schema factory", 2) end

  return newValidator("lazy", function(value, path)
    local schema = fn()
    if type(schema) ~= "table" or type(schema.parse) ~= "function" then
      error("lazy factory must return a schema", 2)
    end
    return schema:parse(value, path)
  end)
end

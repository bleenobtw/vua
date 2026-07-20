local base = require "main.base"
local _, newValidator = table.unpack(base)

return function(fn)
  if type(fn) ~= "function" then error("lazy requires a schema factory", 2) end

  return newValidator("lazy", function(value, path, collect)
    local schema = fn()
    if type(schema) ~= "table" or type(schema.parse) ~= "function" or type(schema._parse) ~= "function" then
      error("lazy factory must return a schema", 2)
    end
    return schema:_parse(value, path, collect)
  end)
end

local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function()
  return newValidator("never", function(value, path)
    return false, helpers.issue(path, "invalid_type", ("expected never, got %s"):format(type(value)), "never", type(value))
  end)
end

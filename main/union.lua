local _, newValidator = table.unpack(require "main.base")
local helpers = require "main.helpers"

return function(validators)
  local labels = {}
  for _, validator in ipairs(validators) do table.insert(labels, v.__label or v.__type) end
  local joined = table.concat(labels, " | ")

  local self = newValidator(("union(%s)"):format(joined), function(value, path)
    local errors = {}

    for _, validator in ipairs(validators) do
      local ok, results = validator:parse(value, path)

      if ok then return true, results end
      table.insert(errors, results)
    end
    return false, ("[%s] value matched none of [%s]"):format(helpers.pathToString(path), joined)
  end)
  self.__label = joined
  return self
end
local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(validators)
  if type(validators) ~= "table" then
    error("union requires at least one schema", 2)
  end

  local length = helpers.arrayLength(validators)
  if not length or length == 0 then error("union options must be a dense array of schemas", 2) end

  local labels = {}
  for i = 1, length do
    local validator = validators[i]
    helpers.assertValidator(validator, ("union option %d"):format(i))
    table.insert(labels, validator.__label or validator.__type)
  end
  local joined = table.concat(labels, " | ")

  local self = newValidator(("union(%s)"):format(joined), function(value, path)
    for _, validator in ipairs(validators) do
      local ok, results = validator:parse(value, path)

      if ok then return true, results end
    end
    return false, ("[%s] value matched none of [%s]"):format(helpers.pathToString(path), joined)
  end)
  self.__label = joined
  return self
end

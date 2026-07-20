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
    local unionErrors = {}
    for _, validator in ipairs(validators) do
      local ok, results = validator:_parse(value, path, false)

      if ok then return true, results end
      unionErrors[#unionErrors + 1] = results
    end

    local unionIssue = helpers.issue(path, "invalid_union", ("value matched none of [%s]"):format(joined), joined, type(value))
    unionIssue.unionErrors = unionErrors
    return false, unionIssue
  end)
  self.__label = joined
  return self
end

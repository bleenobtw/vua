local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(items)
  if type(items) ~= "table" then error("tuple items must be a table", 2) end

  local itemCount = helpers.arrayLength(items)
  if not itemCount then error("tuple items must be a dense array of schemas", 2) end
  for i = 1, itemCount do helpers.assertValidator(items[i], ("tuple item %d"):format(i)) end

  return newValidator("tuple", function(value, path, collect)
    if type(value) ~= "table" then
      return false, helpers.issue(path, "invalid_type", ("expected tuple (table), got %s"):format(type(value)), "tuple", type(value))
    end

    local length, reason = helpers.arrayLength(value)
    if reason then
      return false, helpers.issue(path, "invalid_tuple", "tuple must be a dense array", "dense array", "table")
    elseif length ~= itemCount then
      return false, helpers.issue(path, "invalid_length", ("tuple must have exactly %d element(s), got %d"):format(itemCount, length), itemCount, length)
    end

    local out = {}
    local errors = {}
    for i = 1, itemCount do
      local itemPath = helpers.extendPath(path, i)
      local ok, result = items[i]:_parse(value[i], itemPath, collect)

      if not ok then
        if not collect then return false, result end
        for _, itemIssue in ipairs(result) do errors[#errors + 1] = itemIssue end
      else
        out[i] = result
      end
    end

    if #errors > 0 then return false, errors end
    return true, out
  end)
end

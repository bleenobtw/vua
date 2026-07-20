local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(key, options)
  if type(key) ~= "string" then error("discriminator must be a string", 2) end
  if type(options) ~= "table" then error("discriminated union options must be a table", 2) end

  local optionCount = helpers.arrayLength(options)
  if not optionCount or optionCount == 0 then
    error("discriminated union options must be a non-empty dense array", 2)
  end

  local lookup = {}
  local labels = {}

  local function register(value, option)
    if lookup[value] then error(("duplicate discriminator value '%s'"):format(tostring(value)), 2) end
    lookup[value] = option
    labels[#labels + 1] = tostring(value)
  end

  for i = 1, optionCount do
    local option = options[i]
    helpers.assertValidator(option, ("discriminated union option %d"):format(i))
    if option.__type ~= "object" then error("discriminated union options must be object schemas", 2) end

    local discriminator = option.__schema[key]
    if not discriminator then error(("option %d is missing discriminator '%s'"):format(i, key), 2) end

    if discriminator.__type:match("^literal") then
      register(discriminator.__value, option)
    elseif discriminator.__type:match("^enum") then
      for _, value in ipairs(discriminator.__values) do register(value, option) end
    else
      error(("option %d discriminator must be a literal or enum"):format(i), 2)
    end
  end

  local joined = table.concat(labels, " | ")
  return newValidator(("discriminatedUnion(%s)"):format(key), function(value, path, collect)
    if type(value) ~= "table" then
      return false, helpers.issue(path, "invalid_type", ("expected object (table), got %s"):format(type(value)), "object", type(value))
    end

    local option = lookup[value[key]]
    if not option then
      local fieldPath = helpers.extendPath(path, key)
      return false, helpers.issue(fieldPath, "invalid_discriminator", ("expected one of [%s], got '%s'"):format(joined, tostring(value[key])), joined, value[key])
    end

    return option:_parse(value, path, collect)
  end)
end

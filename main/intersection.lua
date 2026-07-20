local base = require "main.base"
local _, newValidator = table.unpack(base)
local helpers = require "main.helpers"

return function(a, b)
  helpers.assertValidator(a, "left intersection value")
  helpers.assertValidator(b, "right intersection value")

  return newValidator("intersection", function(value, path)
    local okA, resultsA = a:_parse(value, path, false)
    if not okA then return false, resultsA end

    local okB, resultsB = b:_parse(value, path, false)
    if not okB then return false, resultsB end

    if a.__type == "object" and b.__type == "object" then
      local mergedResults = {}
      for key, value in pairs(resultsA) do mergedResults[key] = value end
      for key, value in pairs(resultsB) do mergedResults[key] = value end
      return true, mergedResults
    end
    return true, resultsB
  end)
end

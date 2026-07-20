local base = require "main.base"
local _, newValidator = table.unpack(base)

return function(a, b)
  return newValidator("intersection", function(value, path)
    local okA, resultsA = a:parse(value, path)
    if not okA then return false, resultsA end

    local okB, resultsB = b:parse(value, path)
    if not okB then return false, resultsB end

    if type(resultsA) == "table" and type(resultsB) == "table" then
      local mergedResults = {}
      for key, value in pairs(resultsA) do mergedResults[key] = value end
      for key, value in pairs(resultsB) do mergedResults[key] = value end
      return true, mergedResults
    end
    return true, resultsB
  end)
end

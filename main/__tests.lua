local v = require "main.validate"

-- String Validation Tests Starts
local stringSchema = v.string():min(4)

local function stringTestCase(values)
  for i = 1, #values do
    local ok, results = stringSchema:parse(values[i])
    print("Test Case #" .. i, ok, results)
  end
end

stringTestCase({"", "asd", "Jogn", "Doe123", "Martin"})
-- String Validation Tests End
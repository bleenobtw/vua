local v = require "main.validate"

-- String Validation Tests Starts
local stringSchema = v
  .string()
  :min(4)
  :max(8)
  :startsWith("Doe", "String was must start with Doe")
  :endsWith("123", "String must end with 123")
  :includes("e123", "String must include e123")

local function stringTestCase(values)
  for i = 1, #values do
    local ok, results = stringSchema:parse(values[i])
    print("Test Case #" .. i, ok, results)
  end
end

stringTestCase({"", "asd", "Jogn", "Doe123", "Martin", "Doe321"})
-- String Validation Tests End
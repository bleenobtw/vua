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

-- Number Validation Tests Start

local numberSchema = v
  .number()
  :min(4)
  :max(16)
  :int()
  :gt(3)


local function numberTestCase(values)
  for i = 1, #values do
    local ok, results = numberSchema:parse(values[i])
    print("Test Case #" .. i, ok, results)
  end
end

numberTestCase({4, 2, 69, 5.5, 23, 43.2, 6, 7, 2.34})

-- Number Validation Tests End

-- Object Validation Tests Start

local characterSchema = v
  .object({ 
    firstName = v.string():includes("John"),
    age = v.number():min(6),
    alive = v.boolean()
   })

local ok, results = characterSchema:parse({ firstName = "John", age = 4, alive = true })
print(ok, results)
-- Object Validation Tests End
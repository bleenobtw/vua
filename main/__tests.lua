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

-- literals & enums

local trueOnly = v.literal(true)
local roleSchema = v.enum({"admin", "moderator", "user", "banned"})
local jobSchema = v.enum({"police", "medical", "mechanic", "civilian"})

print(roleSchema:parse("admin")) -- true admin
print(roleSchema:parse("hacker")) -- false [] expected one of [admin | moderator | user | banned]
print(jobSchema:parse("medical")) -- true ems

-- objects

local playerSchema = v
  .object({
    name = v.string():min(1):max(32),
    age = v.number():int():min(12):max(120):optional(),
    role = v.enum({"admin", "user", "moderator"}),
    isOnline = v.boolean():default(false)
  })

local ok, player = playerSchema:parse({
  name = "Martin",
  role = "user"
})

print(ok, json.encode(player))

-- nested objects
local vehicleSchema = v.object({
  model = v.string():nonempty(),
  plate = v.string():length(8):upper(),
  owner = v.object({
    id   = v.number():int():positive(),
    name = v.string():min(1),
  }),
  mods  = v.object({
    wheels = v.number():int():between(0, 5):optional(),
    tint   = v.number():int():between(0, 4):optional(),
  }):optional(),
})

-- pick() / omit() — derive sub-schemas
local publicPlayerSchema = playerSchema:pick({"name", "role"})
local noRoleSchema       = playerSchema:omit({"role"})
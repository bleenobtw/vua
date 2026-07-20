local v = require "main.validate"

local tests = {}

local function test(name, fn)
  tests[#tests + 1] = { name = name, run = fn }
end

local function equal(actual, expected, path)
  path = path or "value"

  if type(actual) ~= type(expected) then
    error(("%s: expected %s, got %s"):format(path, type(expected), type(actual)), 2)
  end

  if type(expected) ~= "table" then
    if actual ~= expected then
      error(("%s: expected %s, got %s"):format(path, tostring(expected), tostring(actual)), 2)
    end
    return
  end

  for key, value in pairs(expected) do
    equal(actual[key], value, path .. "." .. tostring(key))
  end

  for key in pairs(actual) do
    if expected[key] == nil then
      error(("%s: unexpected key %s"):format(path, tostring(key)), 2)
    end
  end
end

local function parses(schema, value, expected, path)
  local ok, result = schema:parse(value, path)
  if not ok then error(result, 2) end
  equal(result, expected)
end

local function rejects(schema, value, expected, path)
  local ok, result = schema:parse(value, path)
  if ok then error("expected parsing to fail", 2) end
  equal(result, expected)
end

test("primitive validators", function()
  parses(v.string(), "hello", "hello")
  parses(v.number(), 42, 42)
  parses(v.boolean(), false, false)
  parses(v.func(), print, print)
  parses(v.table(), { value = true }, { value = true })

  rejects(v.string(), 42, "[<root>] expected string, got number")
  rejects(v.number(), "42", "[<root>] expected number, got string")
  rejects(v.boolean(), 1, "[<root>] expected boolean, got number")
  rejects(v.func(), {}, "[<root>] expected function, got table")
  rejects(v.table(), false, "[<root>] expected table, got boolean")
end)

test("string refinements", function()
  local schema = v.string()
    :min(4)
    :max(8)
    :startsWith("vu")
    :endsWith("ua")
    :includes("vua")
    :pattern("^%l+$")

  parses(schema, "vuavua", "vuavua")
  rejects(v.string():nonEmpty(), "", "[<root>] string must be at least 1 character(s), got 0")
  rejects(v.string():length(3), "four", "[<root>] string must be exactly 3 character(s), got 4")
  rejects(v.string():includes("x", "missing x"), "vua", "missing x")
end)

test("string transforms run in chain order", function()
  parses(v.string():upper():startsWith("V"), "vua", "VUA")
  parses(v.string():lower():endsWith("a"), "VUA", "vua")
end)

test("number refinements", function()
  local schema = v.number():int():between(2, 10):multipleOf(2)
  parses(schema, 6, 6)
  rejects(schema, 3.5, "[<root>] expected integer, got float 3.5")
  rejects(v.number():gt(5), 5, "[<root>] number must be > 5, got 5")
  rejects(v.number():lt(5), 5, "[<root>] number must be < 5, got 5")
  rejects(v.number():positive(), 0, "[<root>] number must be positive, got 0")
  rejects(v.number():negative(), 0, "[<root>] number must be negative, got 0")
end)

test("optional nullable and default values", function()
  parses(v.string():optional(), nil, nil)
  parses(v.string():nullable(), nil, nil)
  parses(v.boolean():default(false), nil, false)
  parses(v.string():default("vua"):upper(), nil, "VUA")
  rejects(v.string(), nil, "[<root>] expected string, got nil")
end)

test("safeParse and assert", function()
  equal(v.number():safeParse(5), { success = true, data = 5 })
  equal(v.number():safeParse("5"), {
    success = false,
    error = "[<root>] expected number, got string",
  })

  equal(v.string():assert("vua"), "vua")
  local ok, message = pcall(function() v.string():assert(4) end)
  equal(ok, false)
  assert(message:find("[<root>] expected string, got number", 1, true))
end)

test("labels and custom refinements", function()
  rejects(v.string():label("username"), nil, "[<root>] expected username, got nil")
  rejects(v.number():refine(function(value)
    return value % 2 == 0
  end, "number must be even"), 3, "[<root>] number must be even")
end)

test("schema chains do not mutate their source", function()
  local baseString = v.string()
  local optionalString = baseString:optional()
  local upperString = baseString:upper()

  rejects(baseString, nil, "[<root>] expected string, got nil")
  parses(optionalString, nil, nil)
  parses(baseString, "vua", "vua")
  parses(upperString, "vua", "VUA")

  local player = v.object({ name = v.string() })
  local strictPlayer = player:strict()
  parses(player, { name = "Martin", extra = true }, { name = "Martin", extra = true })
  rejects(strictPlayer, { name = "Martin", extra = true }, "[<root>] unknown key 'extra' (strict mode)")
end)

test("literal and enum validators", function()
  parses(v.literal(true), true, true)
  rejects(v.literal(true), false, "[<root>] expected literal true, got false")
  parses(v.enum({"admin", "user"}), "admin", "admin")
  rejects(v.enum({"admin", "user"}), "guest", "[<root>] expected one of [admin | user], got 'guest'")
  parses(v.enum({true, false}), false, false)
end)

test("objects parse fields and preserve unknown keys", function()
  local schema = v.object({
    name = v.string():upper(),
    age = v.number():int():optional(),
    active = v.boolean():default(false),
  })

  parses(schema, { name = "martin", extra = true }, {
    name = "MARTIN",
    active = false,
    extra = true,
  })

  rejects(schema, { name = 5 }, "[name] expected string, got number")
end)

test("strict and derived objects", function()
  local player = v.object({
    name = v.string(),
    age = v.number(),
  })

  rejects(player:strict(), { name = "Martin", age = 20, extra = true }, "[<root>] unknown key 'extra' (strict mode)")
  parses(player:pick({"name"}), { name = "Martin" }, { name = "Martin" })
  parses(player:omit({"age"}), { name = "Martin" }, { name = "Martin" })
  parses(player:extend({ active = v.boolean() }), {
    name = "Martin",
    age = 20,
    active = true,
  }, {
    name = "Martin",
    age = 20,
    active = true,
  })
end)

test("nested object paths", function()
  local schema = v.object({
    player = v.object({
      profile = v.object({
        age = v.number(),
      }),
    }),
  })

  rejects(schema, { player = { profile = { age = "old" } } }, "[player.profile.age] expected number, got string")
end)

test("array validators", function()
  parses(v.array(v.string():upper()), {"one", "two"}, {"ONE", "TWO"})
  rejects(v.array(v.number()), {1, "two"}, "[2] expected number, got string")
  rejects(v.array(v.number()):nonEmpty(), {}, "[<root>] array must have at least 1 element(s), got 0")
  rejects(v.array(v.number()):length(2), {1}, "[<root>] array must have exactly 2 element(s), got 1")
end)

test("arrays must be dense and use integer keys", function()
  rejects(v.array(v.number()), { [1] = 1, [3] = 3 }, "[<root>] array must not contain gaps")
  rejects(v.array(v.number()), { value = 1 }, "[<root>] expected array, got table with non-array keys")
  rejects(v.array(v.number()), { [0] = 1 }, "[<root>] expected array, got table with non-array keys")
end)

test("objects and raw tables have distinct semantics", function()
  rejects(v.object({ value = v.number() }), {1}, "[<root>] expected object, got array")
  parses(v.object({ value = v.number() }), { value = 1 }, { value = 1 })
  parses(v.table(), {1, 2}, {1, 2})
end)

test("schema constructors reject invalid arguments", function()
  local invalid = {
    function() v.array("number") end,
    function() v.object("shape") end,
    function() v.object({ value = "number" }) end,
    function() v.object({ [1] = v.number() }) end,
    function() v.union({}) end,
    function() v.union({ [1] = v.string(), [3] = v.number() }) end,
    function() v.union({v.string(), "number"}) end,
    function() v.enum({}) end,
    function() v.enum({ [2] = "user" }) end,
    function() v.intersection(v.string(), "number") end,
    function() v.lazy("schema") end,
    function() v.lazy(function() return "schema" end):parse(1) end,
  }

  for _, fn in ipairs(invalid) do
    local ok = pcall(fn)
    equal(ok, false)
  end
end)

test("unions", function()
  local schema = v.union({v.string(), v.number()})
  parses(schema, "vua", "vua")
  parses(schema, 42, 42)
  rejects(schema, false, "[<root>] value matched none of [string | number]")
end)

test("intersections", function()
  local schema = v.intersection(
    v.object({ name = v.string() }),
    v.object({ age = v.number() })
  )

  parses(schema, { name = "Martin", age = 20 }, { name = "Martin", age = 20 })
  rejects(schema, { name = "Martin", age = "old" }, "[age] expected number, got string")
end)

test("lazy schemas", function()
  local node
  node = v.object({
    value = v.number(),
    child = v.lazy(function() return node end):optional(),
  })

  parses(node, {
    value = 1,
    child = { value = 2 },
  }, {
    value = 1,
    child = { value = 2 },
  })
end)

local passed = 0

for _, case in ipairs(tests) do
  local ok, message = xpcall(case.run, debug.traceback)

  if ok then
    passed = passed + 1
    print("ok - " .. case.name)
  else
    print("not ok - " .. case.name)
    print(message)
  end
end

print(("%d/%d tests passed"):format(passed, #tests))
if passed ~= #tests then os.exit(1) end

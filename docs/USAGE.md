# Usage Guide

This guide shows common ways to use Vua in FiveM resources. See the [API reference](API.md) for every constructor and method.

## Importing Vua

The consuming resource must initialize `ox_lib` and depend on both `ox_lib` and `vua` as shown in the [installation guide](../README.md#installation).

```lua
local v = require "@vua/main.validate"
```

Schemas can be declared once at module scope and reused. Chaining is immutable, so deriving another schema does not change the original.

## Validating A Server Event

Treat values sent by a client as untrusted. Parse the complete event payload before reading its fields.

```lua
local v = require "@vua/main.validate"

local purchaseSchema = v.object({
  item = v.string():nonEmpty():max(64),
  quantity = v.number():int():between(1, 20),
}):strip()

RegisterNetEvent("shop:purchase", function(payload)
  local playerId = source
  local result = purchaseSchema:safeParse(payload)

  if not result.success then
    print(("Rejected shop:purchase from %s: %s"):format(playerId, result.error))
    return
  end

  local purchase = result.data
  processPurchase(playerId, purchase.item, purchase.quantity)
end)
```

`strip` prevents extra client-supplied fields from reaching application code. Use `strict` instead when any unknown key should reject the request.

## Validating A NUI Callback

Run this example in a client script. Return structured issues when the UI needs to show field-level feedback.

```lua
local profileSchema = v.object({
  displayName = v.string():min(2):max(32),
  age = v.number():int():between(13, 120),
}):strip()

RegisterNUICallback("saveProfile", function(data, cb)
  local result = profileSchema:safeParse(data)

  if not result.success then
    cb({
      ok = false,
      error = result.error,
      issues = result.issues,
    })
    return
  end

  saveProfile(result.data)
  cb({ ok = true })
end)
```

Each issue path is an array, for example `{"address", "postcode"}`. This is easier for a UI to map to a field than parsing the formatted error string.

## Parsing Command Arguments

This example is for a server script. FiveM command arguments are strings, so a tuple and coercion make positional command input explicit. Server console and RCON invocations use `source == 0`.

```lua
local teleportArgs = v.tuple({
  v.coerce.number(),
  v.coerce.number(),
  v.coerce.number(),
})

RegisterCommand("teleport", function(source, args)
  if source == 0 then
    print("This command can only be used by a player")
    return
  end

  local ok, coords = teleportArgs:parse(args)

  if not ok then
    print(coords)
    return
  end

  teleportPlayer(source, coords[1], coords[2], coords[3])
end, true)
```

For variable-length commands, use `v.array(v.string())` and add `min`, `max`, or `length` constraints.

## Defaults And Optional Fields

Defaults are validated and transformed like supplied values.

```lua
local settingsSchema = v.object({
  locale = v.string():default("en"):lower(),
  notifications = v.boolean():default(true),
  nickname = v.string():min(2):optional(),
})

local ok, settings = settingsSchema:parse({})
-- true, { locale = "en", notifications = true }
```

An optional object field that parses to `nil` is omitted from the output table. Lua does not retain keys whose value is `nil`.

## Reusing And Deriving Schemas

Schema methods return new schemas.

```lua
local id = v.number():int():positive()

local requiredId = id
local optionalId = id:optional()

local playerSchema = v.object({
  id = requiredId,
  name = v.string():min(2),
  email = v.string():includes("@"),
  internalNote = v.string():optional(),
})

local publicPlayerSchema = playerSchema
  :pick({"id", "name"})
  :strip()

local storedPlayerSchema = playerSchema:extend({
  createdAt = v.number():int(),
})
```

`pick`, `omit`, and `extend` also preserve the object's current `passthrough`, `strip`, or `strict` mode.

## Choosing An Object Mode

Objects preserve unknown keys unless another mode is selected.

```lua
local shape = v.object({ name = v.string() })
local input = { name = "Martin", admin = true }

shape:passthrough():parse(input)
-- true, { name = "Martin", admin = true }

shape:strip():parse(input)
-- true, { name = "Martin" }

shape:strict():parse(input)
-- false, [<root>] unknown key 'admin' (strict mode)
```

Use `strip` at most network boundaries, `strict` for closed protocols or configuration, and `passthrough` when unrelated fields must survive parsing.

## Preprocessing And Transforming

Use `preprocess` to normalize input before type validation. Use `transform` to change a successfully validated value.

```lua
local tagSchema = v.string()
  :preprocess(function(value)
    if type(value) ~= "string" then return value end
    return value:match("^%s*(.-)%s*$")
  end)
  :nonEmpty()
  :lower()
  :transform(function(value) return "tag:" .. value end)

print(tagSchema:parse("  POLICE  "))
-- true, tag:police
```

Chain order matters after the base type check:

```lua
v.string():upper():startsWith("ID-")
```

Here `startsWith` checks the uppercase output. Reversing the methods checks the original string first.

## Coercing External Values

Use coercion only where the accepted conversion is intentional.

```lua
local querySchema = v.object({
  page = v.coerce.number():int():positive():default(1),
  enabled = v.coerce.boolean():default(true),
  search = v.coerce.string():optional(),
}):strip()
```

Boolean coercion is deliberately narrow:

| Input | Output |
| --- | --- |
| `"true"`, `1` | `true` |
| `"false"`, `0` | `false` |
| Other values | Passed to normal boolean validation |

An unconvertible number string is left unchanged and fails with an `invalid_type` issue.

## Custom Business Rules

Use `refine` when a value has the correct type but must satisfy a domain rule.

```lua
local accountId = v.string():refine(function(value)
  if value:sub(1, 4) ~= "acc_" then
    return false, "account id must start with acc_"
  end

  return true
end)
```

The method-level message is useful when the callback only returns a boolean:

```lua
local even = v.number():refine(function(value)
  return value % 2 == 0
end, "number must be even")
```

Use `transform` rather than `refine` when the callback should change the parsed output.

## Arrays, Records, And Tuples

Use each table schema for a different shape:

```lua
local players = v.array(v.object({
  id = v.number():int(),
  name = v.string(),
})):nonEmpty()

local balancesByAccount = v.record(
  v.string():startsWith("acc_"),
  v.number():min(0)
)

local position = v.tuple({
  v.number(),
  v.number(),
  v.number(),
})
```

- Arrays are dense, 1-based tables with one item schema.
- Records validate every key and value.
- Tuples are dense arrays with an exact length and a schema for each position.
- `table()` accepts any Lua table when shape does not matter.

## Unions

A standard union tries options in order and returns the first success.

```lua
local identifier = v.union({
  v.number():int():positive(),
  v.string():nonEmpty(),
})
```

For object variants with a stable type field, prefer a discriminated union:

```lua
local actionSchema = v.discriminatedUnion("action", {
  v.object({
    action = v.literal("deposit"),
    amount = v.number():positive(),
  }):strip(),
  v.object({
    action = v.literal("withdraw"),
    amount = v.number():positive(),
    reason = v.string():optional(),
  }):strip(),
  v.object({
    action = v.enum({"freeze", "unfreeze"}),
    accountId = v.string():nonEmpty(),
  }):strip(),
})
```

Discriminator values must be unique across every literal and enum option.

## Intersections

Intersections are useful when one input must satisfy two schemas.

```lua
local identity = v.object({
  id = v.number():int(),
})

local timestamps = v.object({
  createdAt = v.number():int(),
  updatedAt = v.number():int(),
})

local storedEntity = v.intersection(identity, timestamps)
```

When both sides are objects, the parsed tables are merged and right-side fields win on key conflicts. For non-object intersections, the right parsed result is returned.

## Recursive Data

Use `lazy` when a schema refers to itself.

```lua
local categorySchema

categorySchema = v.object({
  name = v.string():nonEmpty(),
  children = v.array(v.lazy(function()
    return categorySchema
  end)):default({}),
}):strip()
```

The factory runs while parsing, after `categorySchema` has been assigned.

## Handling Multiple Errors

`parse` is convenient when only the first error matters. `safeParse` collects child errors while directly traversing object, array, tuple, and record schemas. Union options and intersection sides stop at their first failure.

```lua
local result = v.object({
  name = v.string():min(2),
  age = v.number():int():positive(),
}):safeParse({
  name = "",
  age = 1.5,
})

if not result.success then
  for _, issue in ipairs(result.issues) do
    local path = #issue.path > 0 and table.concat(issue.path, ".") or "<root>"
    print(path, issue.code, issue.message)
  end
end
```

For a failed standard union, inspect `result.issues[1].unionErrors` to see the first failure from each option.

## Validating Startup Configuration

`assert` is concise when the resource cannot operate with invalid trusted configuration.

```lua
local configSchema = v.object({
  webhook = v.string():startsWith("https://"),
  retryCount = v.number():int():between(0, 10):default(3),
  debug = v.boolean():default(false),
}):strict()

local config = configSchema:assert(Config)
```

Do not use `assert` directly on untrusted event or NUI input unless raising and aborting that handler is the intended behavior.

## Lua Table Boundaries

Lua represents arrays and objects with the same `table` type, so Vua applies explicit rules:

- `array` and `tuple` require dense integer keys starting at `1`.
- `object` requires named shape fields and rejects non-empty dense arrays.
- `record` validates keys rather than assuming object or array shape.
- `table` performs no shape validation.
- Empty `{}` can represent an empty array, object, record, or raw table because Lua carries no shape metadata.

Choose the narrowest schema that matches the data contract.

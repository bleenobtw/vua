# API Reference

This reference describes the public API returned by:

```lua
local v = require "@vua/main.validate"
```

For installation and resource setup, see the [README](../README.md). For complete examples, see the [usage guide](USAGE.md).

## Contents

- [Schema behavior](#schema-behavior)
- [Parsing values](#parsing-values)
- [Common methods](#common-methods)
- [Primitive schemas](#primitive-schemas)
- [Value schemas](#value-schemas)
- [Composite schemas](#composite-schemas)
- [Logic schemas](#logic-schemas)
- [Coercion](#coercion)
- [Validation issues](#validation-issues)

## Schema Behavior

Every constructor returns a schema. Schema methods are immutable: each method returns a new schema and leaves the source unchanged.

```lua
local requiredName = v.string()
local optionalName = requiredName:optional()

print(requiredName:parse(nil)) -- false, [<root>] expected string, got nil
print(optionalName:parse(nil)) -- true, nil
```

Values pass through a schema in this order:

1. Preprocessors run in insertion order.
2. Defaults, optional values, and nullable values are resolved.
3. The schema checks its base type or shape.
4. Refinements and transforms run in chain order, with each successful output passed to the next method.

```lua
local schema = v.string()
  :preprocess(function(value) return tostring(value) end)
  :upper()
  :startsWith("ID-")

print(schema:parse("id-42")) -- true, ID-42
```

Invalid schema definitions, such as `v.array("string")` or an empty union, raise immediately. Invalid parsed values use the normal `parse`, `safeParse`, or `assert` result contract.

## Parsing Values

### `schema:parse(value[, path])`

Returns two values:

```lua
true, parsedValue
false, errorString
```

The returned value contains defaults, parsed child values, and transformations. Parsing stops at the first failure.

```lua
local ok, value = v.string():upper():parse("vua")
-- true, "VUA"

local valid, err = v.number():int():parse(2.5)
-- false, "[<root>] expected integer, got float 2.5"
```

`path` may be a string or an array of string path segments. It is useful when embedding a schema in another validation layer. Caller-supplied table segments are preserved as given, so use strings to keep formatting reliable.

```lua
local ok, err = v.string():parse(42, {"event", "name"})
-- false, "[event.name] expected string, got number"
```

### `schema:safeParse(value[, path])`

Returns one result table. It never raises for ordinary validation failures.

Successful result:

```lua
{
  success = true,
  data = parsedValue,
}
```

Failed result:

```lua
{
  success = false,
  error = "[player.age] expected number, got string",
  issues = {
    {
      path = {"player", "age"},
      code = "invalid_type",
      message = "expected number, got string",
      expected = "number",
      received = "string",
    },
  },
}
```

Object, array, tuple, and record schemas collect all child failures when directly traversed during `safeParse`. The `error` field is the formatted first issue. Union failures include failures grouped by option in `issue.unionErrors`, but each option stops at its first failure. Intersections also stop at the first failing side.

### `schema:assert(value[, path])`

Returns the parsed value or raises with the formatted validation error.

```lua
local port = v.number():int():positive():assert(config.port)
```

Use `assert` for trusted startup configuration or other cases where invalid input should stop execution. Prefer `parse` or `safeParse` for network and user input.

## Common Methods

These methods are available on every schema.

### `optional()`

Accepts `nil` and returns `nil` without running the base type check or refinements.

### `nullable()`

Accepts `nil` and returns `nil`. Lua has one `nil` value for both missing and explicit null-like data, so `optional` and `nullable` have the same runtime result.

### `default(value)`

Replaces `nil` with `value`, then validates and transforms the default normally.

```lua
local schema = v.string():default("user"):upper()
print(schema:parse(nil)) -- true, USER
```

### `label(label)`

Changes the expected label used when a required value is `nil`.

```lua
v.string():label("username")
-- [<root>] expected username, got nil
```

### `refine(fn[, message])`

Adds a custom predicate. The callback receives the current parsed value and returns `true` on success or `false[, customMessage]` on failure.

```lua
local even = v.number():refine(function(value)
  if value % 2 ~= 0 then return false, "number must be even" end
  return true
end)
```

The callback message takes priority over the method's `message`. If neither is provided, Vua uses `custom validation failed`. Failed refinements use issue code `custom`.

### `preprocess(fn)`

Runs `fn(value)` before defaults, optional handling, and the base type check.

```lua
local trimmed = v.string():preprocess(function(value)
  if type(value) ~= "string" then return value end
  return value:match("^%s*(.-)%s*$")
end)
```

### `transform(fn)`

Runs after the base check at its position in the refinement chain. Its return value becomes the input to later refinements and the final parsed value.

```lua
local doubled = v.number()
  :transform(function(value) return value * 2 end)
  :max(10)
```

Errors raised inside `preprocess`, `transform`, or `refine` callbacks are not converted into validation issues.

## Primitive Schemas

### `v.string()`

Accepts Lua strings.

| Method | Behavior |
| --- | --- |
| `min(n[, message])` | Requires at least `n` bytes. |
| `max(n[, message])` | Requires at most `n` bytes. |
| `length(n[, message])` | Requires exactly `n` bytes. |
| `nonEmpty([message])` | Alias for `min(1, message)`. |
| `pattern(pattern[, message])` | Requires a match for a Lua pattern. |
| `startsWith(prefix[, message])` | Requires the prefix. |
| `endsWith(suffix[, message])` | Requires the suffix. |
| `includes(substring[, message])` | Requires a plain-text substring. |
| `upper()` | Transforms the value to uppercase. |
| `lower()` | Transforms the value to lowercase. |

Length methods use Lua's `#` operator and therefore count bytes, not UTF-8 characters. `pattern` uses [Lua patterns](https://www.lua.org/manual/5.4/manual.html#6.4.1), not regular expressions. Add `^` and `$` when the whole string must match.

### `v.number()`

Accepts Lua numbers.

| Method | Behavior |
| --- | --- |
| `min(n[, message])` | Requires `value >= n`. |
| `max(n[, message])` | Requires `value <= n`. |
| `gt(n[, message])` | Requires `value > n`. |
| `lt(n[, message])` | Requires `value < n`. |
| `int([message])` | Requires an integer. |
| `positive([message])` | Requires `value > 0`. |
| `negative([message])` | Requires `value < 0`. |
| `between(low, high[, message])` | Applies inclusive `min(low)` and `max(high)`. |
| `multipleOf(n[, message])` | Requires `value % n == 0`. |

### `v.boolean()`

Accepts only Lua booleans. It does not coerce `0`, `1`, or strings; use `v.coerce.boolean()` when coercion is wanted.

### `v.func()`

Accepts Lua functions.

### `v.table()`

Accepts any Lua table without distinguishing arrays, objects, records, or sparse tables. Use this when table shape does not matter.

### `v.any()`

Accepts every value, including `nil`.

### `v.unknown()`

Accepts every value, including `nil`. It currently has the same runtime behavior as `any`; use it to communicate that callers should narrow or validate the value before using it.

### `v.never()`

Rejects every value.

## Value Schemas

### `v.literal(expected)`

Accepts only a value equal to `expected` with Lua's `~=` comparison.

```lua
local enabled = v.literal(true)
local eventType = v.literal("player:join")
```

Use `optional` or `nullable` for `nil`; `literal(nil)` is not a null schema because required `nil` values are handled before literal comparison.

### `v.enum(values)`

Accepts any value present in a non-empty, dense array of allowed values.

```lua
local role = v.enum({"admin", "moderator", "user"})
```

Enum lookup uses Lua table-key equality. Scalar string, number, and boolean values are the most predictable choices.

## Composite Schemas

### `v.object(shape)`

Validates a table with named fields. Shape keys must be strings and shape values must be schemas.

```lua
local player = v.object({
  name = v.string(),
  age = v.number():int():optional(),
})
```

Objects reject non-empty dense array-shaped tables. Unknown keys pass through by default.

| Method | Behavior |
| --- | --- |
| `passthrough()` | Preserves unknown keys in the parsed result. This is the default. |
| `strip()` | Removes unknown keys from the parsed result. |
| `strict()` | Rejects unknown keys. |
| `extend(extraShape)` | Returns an object with the current and extra fields; extra fields replace matching keys. |
| `pick(keys)` | Returns an object containing the selected known fields. |
| `omit(keys)` | Returns an object without the selected fields. |

`extend`, `pick`, and `omit` preserve the current unknown-key mode.

```lua
local publicPlayer = player:strip():pick({"name"})
local storedPlayer = player:extend({ id = v.number():int() })
```

### `v.array(itemSchema)`

Validates a dense, 1-based Lua table using the same schema for every item. Arrays reject gaps, keys below `1`, non-integer keys, and non-number keys.

| Method | Behavior |
| --- | --- |
| `min(n[, message])` | Requires at least `n` items. |
| `max(n[, message])` | Requires at most `n` items. |
| `length(n[, message])` | Requires exactly `n` items. |
| `nonEmpty([message])` | Alias for `min(1, message)`. |

Parsed item transformations are written into a new output array.

### `v.record(valueSchema)`

Validates a table whose keys must be strings and whose values all use `valueSchema`.

```lua
local balances = v.record(v.number():min(0))
```

### `v.record(keySchema, valueSchema)`

Validates both keys and values. Parsed or transformed keys and values are used in the output table.

```lua
local scores = v.record(
  v.string():upper(),
  v.number():int()
)
```

If key transformations produce the same output key, later entries overwrite earlier entries.

### `v.tuple(schemas)`

Validates a dense array with exactly one schema per position.

```lua
local coordinates = v.tuple({
  v.number(),
  v.number(),
  v.number(),
})
```

The input length must exactly match the number of tuple schemas.

## Logic Schemas

### `v.union(schemas)`

Tries each schema in order and returns the first successful parsed value. The options must be a non-empty dense array of schemas.

```lua
local id = v.union({v.number():int(), v.string():nonEmpty()})
```

A failed union produces one `invalid_union` issue. Its `unionErrors` field contains an issue array for each attempted option.

### `v.discriminatedUnion(key, objectSchemas)`

Selects an object schema from a discriminator field instead of trying every option. Each option must be an object whose discriminator schema is a `literal` or `enum`, and discriminator values must be unique.

```lua
local vehicle = v.discriminatedUnion("type", {
  v.object({
    type = v.literal("car"),
    doors = v.number():int(),
  }),
  v.object({
    type = v.enum({"bike", "motorcycle"}),
    wheels = v.number():int(),
  }),
})
```

### `v.intersection(left, right)`

Parses the original input with `left`, then with `right`.

- If either schema fails, its failure is returned.
- If both schemas are objects, their parsed outputs are merged and right-side fields replace matching left-side fields.
- For other schema types, the right parsed result is returned.

### `v.lazy(factory)`

Defers schema lookup until parsing. The factory is called during each parse and must return a schema. This supports recursive definitions.

```lua
local node
node = v.object({
  value = v.number(),
  children = v.array(v.lazy(function() return node end)):default({}),
})
```

## Coercion

Coercion schemas preprocess selected values and then use the corresponding primitive schema. Failed coercion still produces the primitive type error.

### `v.coerce.string()`

- Leaves `nil` unchanged.
- Converts every other value with `tostring`.

### `v.coerce.number()`

- Runs `tonumber` for string values.
- Keeps successfully converted numbers.
- Leaves unconvertible strings and non-string values unchanged for normal number validation.

### `v.coerce.boolean()`

- Converts `"true"` and `1` to `true`.
- Converts `"false"` and `0` to `false`.
- Leaves every other value unchanged for normal boolean validation.

Type-specific methods remain available:

```lua
local page = v.coerce.number():int():positive()
```

## Validation Issues

Every issue has these fields:

| Field | Description |
| --- | --- |
| `path` | Array of path segments. Vua-generated segments are strings and root failures use `{}`; caller-supplied path-table segments are preserved. |
| `code` | Stable category for programmatic handling. |
| `message` | Human-readable message without the bracketed path. |
| `expected` | Optional expected value, type, or constraint. |
| `received` | Optional received value or type. |
| `unionErrors` | Present on failed unions; contains failures grouped by option. |

Current issue codes:

| Code | Typical source |
| --- | --- |
| `invalid_type` | Primitive, object, array, tuple, record, or `never` type failures. |
| `too_small` | String, number, or array minimum checks. |
| `too_big` | String, number, or array maximum checks. |
| `invalid_length` | Exact string, array, or tuple length checks. |
| `invalid_string` | Pattern, prefix, suffix, or substring checks. |
| `not_integer` | `number:int()`. |
| `not_positive` | `number:positive()`. |
| `not_negative` | `number:negative()`. |
| `not_multiple_of` | `number:multipleOf()`. |
| `invalid_literal` | Literal mismatch. |
| `invalid_enum` | Enum mismatch. |
| `unrecognized_key` | Strict object unknown key. |
| `invalid_array` | Array with non-array keys. |
| `sparse_array` | Array containing gaps. |
| `invalid_tuple` | Tuple that is not a dense array. |
| `invalid_union` | No union option matched. |
| `invalid_discriminator` | Unknown discriminated-union value. |
| `custom` | Failed custom refinement. |

Formatted errors use dot-separated paths inside brackets. Array and tuple indexes are path segments, so a nested failure can look like `[players.2.name]`.

# Vua

A small, chainable runtime validation library for FiveM's Lua 5.4 runtime.

Vua is intended for values crossing a trust boundary, such as network events, commands, exports, and NUI callbacks. Schemas validate a value and return either the parsed result or a path-aware error.

## Installation

Vua uses the [`ox_lib`](https://github.com/overextended/ox_lib) module loader for cross-resource imports.

1. Place this repository in your server's resources directory as `vua`.
2. Start `ox_lib` and `vua` before resources that use it.

```cfg
ensure ox_lib
ensure vua
ensure my_resource
```

Add both dependencies and the `ox_lib` initializer to the consuming resource:

```lua
-- my_resource/fxmanifest.lua
fx_version "cerulean"
game "gta5"

shared_script "@ox_lib/init.lua"

dependencies {
  "ox_lib",
  "vua",
}
```

Import Vua from a client, server, or shared script:

```lua
local v = require "@vua/main.validate"
```

If the resource directory is renamed, use that name in both `dependencies` and the import path.

## Usage

```lua
local v = require "@vua/main.validate"

local playerSchema = v.object({
  name = v.string():min(2):max(32),
  age = v.number():int():min(12):max(120):optional(),
  role = v.enum({"admin", "moderator", "user"}),
  online = v.boolean():default(false),
})

local ok, player = playerSchema:parse({
  name = "Martin",
  role = "user",
})

if not ok then
  print(player)
  return
end

print(player.name, player.role, player.online)
```

`parse` returns `true, value` when validation succeeds and `false, error` when it fails. Transformations such as `upper` and `lower` are reflected in the returned value.

```lua
local ok, value = v.string():upper():parse("vua")
print(ok, value) -- true, VUA

local result = v.number():int():safeParse(4.5)
print(result.success, result.error)

local name = v.string():nonEmpty():assert("Martin")
```

Failed `safeParse` results also contain an `issues` array. Each issue includes `path`, `code`, and `message`, with `expected` and `received` values when they apply. Object and array schemas collect all child issues in this mode; `parse` still returns the first formatted error.

Nested failures include their field path:

```lua
local schema = v.object({
  player = v.object({
    age = v.number():min(18),
  }),
})

print(schema:parse({ player = { age = 16 } }))
-- false, [player.age] number must be >= 18, got 16
```

String patterns use [Lua patterns](https://www.lua.org/manual/5.4/manual.html#6.4.1), not regular expressions.

## Schemas

| Constructor | Refinements and helpers |
| --- | --- |
| `string()` | `min`, `max`, `length`, `nonEmpty`, `pattern`, `startsWith`, `endsWith`, `includes`, `upper`, `lower` |
| `number()` | `min`, `max`, `gt`, `lt`, `int`, `positive`, `negative`, `between`, `multipleOf` |
| `boolean()` | Base helpers |
| `func()` | Base helpers |
| `table()` | Base helpers |
| `literal(value)` | Base helpers |
| `enum(values)` | Base helpers |
| `object(shape)` | `strict`, `extend`, `pick`, `omit` |
| `array(schema)` | `min`, `max`, `length`, `nonEmpty` |
| `union(schemas)` | Base helpers |
| `intersection(left, right)` | Base helpers |
| `lazy(factory)` | Base helpers |

Every schema supports `optional`, `nullable`, `default`, `label`, and `refine`.

Objects preserve unknown keys by default. Call `strict` to reject them.
Schema methods return a new schema, so a base schema can be safely reused in multiple chains.

Arrays must be dense, 1-based tables with no non-integer keys. Objects reject non-empty array-shaped tables; use `table()` when either table shape is valid.

## Development

The test suite has no external Lua dependencies:

```sh
lua tests/run.lua
```

Tests run against Lua 5.4 in GitHub Actions. `examples/basic.lua` contains a standalone example using the repository-local module path.

## License

[MIT](LICENSE)

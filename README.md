# Vua
A lightweight, chainable, Zod-inspired runtime validation library for FiveM Lua resources.

### Why Vua?

> FiveM server events can't be trusted. Any client can send arbitrary data to your server. Without validation, you expose yourself to exploits, crashes and injection attacks. Vua gives you a clean and predictable API to guard every event handler with minimal overhead.

### Example(s)
```lua
-- Basic primitive validation examples.

local nameSchema = v.string():min(2):max(32)
local ageSchema = v.number():int():min(12):max(100)

-- :parse() -> returns (success: boolean, value|error: any)
local ok, results  = nameSchema:parse("John")
print(ok, results) -- true John

local ok2, _error = nameSchema:parse(42)
print(ok2, _error) -- false [42] expected string, got number
```
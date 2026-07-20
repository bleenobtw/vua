local v = require "main.validate"

local playerSchema = v.object({
  name = v.string():min(1):max(32),
  age = v.number():int():min(12):max(120):optional(),
  role = v.enum({"admin", "user", "moderator"}),
  isOnline = v.boolean():default(false),
})

local ok, player = playerSchema:parse({
  name = "Martin",
  role = "user",
})

if ok then
  print(player.name, player.role, player.isOnline)
else
  print(player)
end

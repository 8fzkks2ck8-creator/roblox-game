-- Run from the repository root with: lune run tools/convert_place.luau
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local input = fs.readFile("AnimeRift_Polished.rbxlx")
-- Lune detects XML from the <roblox tag, without an XML declaration.
input = input:gsub("^<%?xml.-%?>%s*", "")
local place = roblox.deserializePlace(input)
local binary = roblox.serializePlace(place)
assert(string.sub(binary, 1, 8) == "<roblox!", "Expected Roblox binary place header")
fs.writeFile("AnimeRift_Polished.rbxl", binary)
-- Decode the binary again to verify that conversion retained scripts and assets.
local restored = roblox.deserializePlace(binary)
local originalItems = place:GetDescendants()
local restoredItems = restored:GetDescendants()
assert(#originalItems == #restoredItems, "Conversion lost instances")
local originalSources, restoredSources = {}, {}
local function collect(items, result)
 for _, item in items do
  if item:IsA("LuaSourceContainer") then
   local key = item:GetFullName() .. "\0" .. item.ClassName .. "\0" .. item.Source
   result[key] = (result[key] or 0) + 1
  end
 end
end
collect(originalItems, originalSources)
collect(restoredItems, restoredSources)
local count = 0
for key, copies in originalSources do
 assert(restoredSources[key] == copies, "Conversion changed script source or duplicate count")
 count += copies
end
print("Created AnimeRift_Polished.rbxl; " .. #restoredItems .. " instances and " .. count .. " scripts verified")

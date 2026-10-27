# SALTY Player Hub v3.3.1 (Obsidian Edition)

A single-file Roblox Lua client hub based on VantaUI.

## Run the latest GitHub version

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyP1/main/main.lua"))()
```

The hub fetches VantaUI from [MrRos3/VantaUI](https://github.com/MrRos3/VantaUI). Your environment must support `loadstring` and `game:HttpGet`. This is an independent client script, not a Roblox Studio plugin.

## Fixed in v3.3.1

- Fixed the Luau compiler error `Out of local registers when trying to allocate profileNames: exceeded limit 200` by moving the Obsidian features and their UI into a dedicated function scope.
- Kept Fly, Infinite Jump, Air Walk, Dash, Spectate, Freecam, Anti-Void, Fling & Return, combat assistance, player ESP, teleport, skybox controls, server hop, profiles, and waypoints.
- Preserved existing cleanup hooks so running the script again can replace an older hub instance.

## Files

- [main.lua](main.lua): complete script, no ZIP files.

## Testing note

Static code review confirms the original overloaded scope is split. The Lua script has **not** yet been compiled in a live Luau runtime or tested in Roblox. Client-side movement and physics effects may vary by experience and server rules. If you encounter another error, save the entire error text and line number.

## Maintaining the hub

Edit `main.lua` on GitHub to publish future updates. The raw-content URL above will load the newest commit on the `main` branch.

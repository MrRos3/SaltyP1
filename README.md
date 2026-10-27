# SALTY Player Hub v3.4.1 (Obsidian Edition)

A single-file Roblox Lua client hub based on VantaUI.

## Run the latest GitHub version

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyP1/main/loader.lua?fresh=" .. tostring(DateTime.now().UnixTimestampMillis), true))()
```

**Use the loader above** instead of the old static `main.lua` URL. It cache-busts the GitHub source, verifies the Spectate and WalkFling controls are in the downloaded script, and reports Luau compilation and startup errors in the executor console. The window title should show `SALTY Player Hub v3.4.1`.

**Visibility check:** `Camera` tab → `Spectate Player` (nickname and @username dropdown) and `Fling` tab → `WalkFling (Touch Fling)` toggle. The two UI sections now initialize before other tabs' feature controls.

The hub fetches VantaUI from [MrRos3/VantaUI](https://github.com/MrRos3/VantaUI). Your environment must support `loadstring` and `game:HttpGet`. This is an independent client script, not a Roblox Studio plugin.

## Fixed in v3.4.1

- Fixed the Luau compiler error `Out of local registers when trying to allocate profileNames: exceeded limit 200` by moving the Obsidian features and their UI into a dedicated function scope.
- Kept Fly, Infinite Jump, Air Walk, Dash, Spectate, Freecam, Anti-Void, Fling & Return, combat assistance, player ESP, teleport, skybox controls, server hop, profiles, and waypoints.
- Added a dedicated Spectate dropdown in the Camera tab, independently tracking the target's nickname and username with live updates; changing the dropdown switches the live camera subject.
- Added **WalkFling (Touch Fling)** in the Fling tab. Inspired by Infinite Yield's [WalkFling](https://github.com/EdgeIY/infiniteyield): high-velocity pulses while walking, without continuous body spinning.
- Reworked **Fling & Return** to use no-spin velocity pulses while approaching the selected player, then restore your original position. Turn off WalkFling before triggering this separate targeted mode.
- Added **12 cinematic skybox looks**: Crimson Veil, Obsidian Eclipse, Lavender Dream, Rose Quartz, Glacial Dawn, Teal Nebula, Amber Haze, Coral Afterglow, Noir Violet, Neon Sakura, Moonlit Cabin, and Electric Dusk. These reuse existing six-face cubemaps with a **local reversible color grade**, which also affects the scene until another preset or Original is selected.
- Skybox choices remain available through the main selector, Random, Next, Previous, and Original. The custom six-face sky option clears cinematic color grading.

- Preserved existing cleanup hooks so running the script again can replace an older hub instance.

## Files

- [main.lua](main.lua): complete script, no ZIP files.
- [loader.lua](loader.lua): fresh-version checker and startup diagnostics.

## Testing note

Static code review confirms the original overloaded scope is split; the WalkFling integration and skybox variations have been reviewed in source. The Lua script has **not** yet been compiled in a live Luau runtime or tested in Roblox. Client-side movement and physics effects may vary by experience and server rules. If you encounter another error, save the entire error text and line number.

## Maintaining the hub

Edit `main.lua` on GitHub to publish future updates. The raw-content URL above will load the newest commit on the `main` branch.

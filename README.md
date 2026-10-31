# SALTY Player Hub v3.8.0 (Obsidian Edition)

A Roblox Lua client hub based on VantaUI. The core is in `main.lua`; the optional owl nameplate module loads only when enabled.

## Run the latest GitHub version

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyP1/main/loader.lua?fresh=" .. tostring(DateTime.now().UnixTimestampMillis), true))()
```

**Use the loader above** instead of the old static `main.lua` URL. It cache-busts the GitHub source, verifies the Spectate and WalkFling controls are in the downloaded script, and reports Luau compilation and startup errors in the executor console. The window title should show `SALTY Player Hub v3.8.0`.

**Visibility check:** `Player` tab → `Vanta Owl Nameplate` (OFF by default), `Camera` tab → `Spectate Player` (nickname and @username dropdown), and `Fling` tab → `WalkFling (Touch Fling)` toggle. The two UI sections now initialize before other tabs' feature controls.

The hub fetches VantaUI from [MrRos3/VantaUI](https://github.com/MrRos3/VantaUI). Your environment must support `loadstring` and `game:HttpGet`. This is an independent client script, not a Roblox Studio plugin.

## Long-session lag reduction and saved location (v3.8.0)

- **Fixed a likely lag source:** Anti-Fling previously added a `CanCollide` change listener to every body part of every other player. In games that continuously update collision properties, those callbacks can become extremely frequent as a session progresses.
- **New bounded protection:** The collision guard now scans nearby players (within about 28 studs, with 34-stud exit hysteresis) at approximately five checks per second, caches up to 96 parts per nearby character, and removes tracking when they leave, respawn or Anti-Fling is disabled. No per-part `CanCollide` signal connections remain.
- **Save Current Location:** In the Teleport tab, stores your present position and orientation as a single slot for the current `PlaceId`. If executor file APIs are supported, it's saved in the same `SALTY_Player_Hub/Obsidian_v3.3.json` store and reloaded the next time you run the hub in that place.
- **Return to Saved Location:** In the Teleport tab, teleports to that spot with a small +2 stud vertical offset. Both buttons replace the older session-only Save Position controls, with no Waypoints tab.
- The crimson animated particles and OFF-by-default Vanta Owl nameplate stay untouched, as do original Fling & Return, WalkFling, Spectate, ESP + Chams, and the skyboxes.

**Testing:** Source inspection identifies the unbounded collision-property callback workload as a plausible source of increasing lag, but real-world FPS impact hasn't been benchmarked. Try a clean Roblox rejoin to eliminate any leftover old listeners before measuring.

## Optional Vanta Owl nameplate (v3.8.0)

- New **Player → Vanta Owl Nameplate** toggle, **OFF by default**. It does not load any nameplate code or create any nameplate instances until you enable it.
- Uses the original self-only overhead nameplate from [VantaTest](https://github.com/MrRos3/VantaTest/blob/main/nameplate.lua): fully rounded obsidian capsule, twin owl icons, Michroma display name, crimson rotating border and a timed white name-shine sweep.
- The optional [nameplate.lua](nameplate.lua) is fetched from this repo only on first enable; toggling OFF destroys the controller, overhead GUI, animation tweens and connections. Reloading the hub cleans up an old controller.
- On executors without `getcustomasset` / `getsynasset` and file APIs, the module uses its owl emoji fallback instead of the PNG. This local nameplate is **visible only to you**, not other players.
- Separate from your VantaUI window's crimson particle effects, which stay enabled.

## GUI particles restored (v3.7.1)

The full crimson ambient effect is back, as requested. The performance changes to ESP/Spectate and the removal of Freecam/Waypoints remain. You do not need to enable any extra GUI option. Note that live particle animation can still carry a small GPU/CPU cost.

## Lean performance update (v3.7.1)

- **Removed entirely:** the Waypoints tab, related waypoint storage/management UI and code, Freecam controls and rendering, Freecam shortcut, and Freecam profile settings.
- **Crimson wallpaper and particle ambience restored**: the original petal, ember, mote and glint particles remain visible. VantaUI pools 50 particles and throttles motion to 30 FPS; the underlying animation has a rendering cost, but SALTY no longer suppresses it.
- **ESP + Chams** remains a single toggle. Native highlights follow characters smoothly; distance/name checks are staggered across 1-3 players each pass, with a lower budget under load.
- **Spectate** keeps its searchable player dropdown and native camera following, with background camera verification limited to about eight times per second.
- **Original Fling & Return**, separate WalkFling, Fly, Infinite Jump, Anti-Fling, skyboxes, Teleport, and profiles remain intact.
- Existing on-disk profile files are left alone. Older saved Freecam/Waypoint fields are no longer loaded into active controls.

These reduce script-side overhead but aren't a guarantee of zero lag. Roblox FPS depends on the game, player count, and device.

## ESP redesign (v3.7.1)

**ESP is now one switch with built-in Chams and player name tags.** The ESP tab contains `Enable ESP + Chams` and `Highlight Color`.

- **Fast and smooth:** Uses native `Highlight` and `BillboardGui` to follow moving players without per-frame Lua geometry redraws.
- **Quick initial appearance:** Initializes up to five player's ESP objects per frame when enabled to avoid a large first-frame hitch.
- **Light maintenance:** Checks range/respawn/color changes about four times a second; all rendering remains native.
- **Removed extras:** Chams toggle, Tracers, 3D Boxes, Health Labels, Distance Labels, Player Names toggle, See Through Walls toggle, team filters, and the manual distance slider.
- **Automatic cleanup:** Disabling ESP destroys only SALTY's own highlights and name labels.

The exact FPS improvement depends on the game and device. Live testing has not been completed.

## Performance overhaul (v3.7.1)

No performance menus or quality presets: SALTY automatically minimizes work.

- **Anti-Fling** is still ON by default but now uses nearby-only, timed collision checks without per-part property-change connections; it avoids scanning full characters every physics frame.
- **ESP** stays a simple Chams + name-tag switch, with adaptive time-sliced updates.
- **Camera** transparency caching scans the local avatar once per activation and follows new accessories through a lightweight event instead of rescanning every 0.7 seconds.
- **Combat** keeps its existing single-pass target ranking. Automatic tool checks and FOV indicator updates are time-sliced.
- No change to the original **Fling & Return** engine restored in v3.4.3, the independent WalkFling toggle, Spectate dropdown, or cinematic skyboxes.

These are source-level performance optimizations, **not measured FPS guarantees**. Live Roblox testing is still required.

## Fixed in v3.7.1

- Fixed the Luau compiler error `Out of local registers when trying to allocate profileNames: exceeded limit 200` by moving the Obsidian features and their UI into a dedicated function scope.
- Kept Fly, Infinite Jump, Air Walk, Dash, Spectate, Anti-Void, Fling & Return, combat assistance, player ESP, teleport, skybox controls, server hop and profiles. Freecam and Waypoints were removed in v3.7.0.
- Added a dedicated Spectate dropdown in the Camera tab, independently tracking the target's nickname and username with live updates; changing the dropdown switches the live camera subject.
- Reverted targeted **Fling & Return** to the ORIGINAL v3.3.2 engine (BodyAngularVelocity + BodyVelocity, target chase, save and return to original position). The newer bounded horizontal-only contact changes are gone, and the Contact Power slider was removed because it no longer applies. This also restores the original spin/upward-movement behavior.
- Added **WalkFling (Touch Fling)** in the Fling tab. Inspired by Infinite Yield's [WalkFling](https://github.com/EdgeIY/infiniteyield): high-velocity pulses while walking, without continuous body spinning.
- **Fling & Return** uses its original spinning-contact implementation again; the optional no-spin **WalkFling (Touch Fling)** remains a separate toggle. Disable it before targeted fling.
- Added **12 cinematic skybox looks**: Crimson Veil, Obsidian Eclipse, Lavender Dream, Rose Quartz, Glacial Dawn, Teal Nebula, Amber Haze, Coral Afterglow, Noir Violet, Neon Sakura, Moonlit Cabin, and Electric Dusk. These reuse existing six-face cubemaps with a **local reversible color grade**, which also affects the scene until another preset or Original is selected.
- Skybox choices remain available through the main selector, Random, Next, Previous, and Original. The custom six-face sky option clears cinematic color grading.

- Preserved existing cleanup hooks so running the script again can replace an older hub instance.

## Files

- [main.lua](main.lua): complete core script, no ZIP files.
- [nameplate.lua](nameplate.lua): optional Vanta Owl overhead nameplate, only loaded on toggle ON.
- [loader.lua](loader.lua): fresh-version checker and startup diagnostics.

## Testing note

Static code review confirms the original overloaded scope is split; the WalkFling integration and skybox variations have been reviewed in source. The Lua script has **not** yet been compiled in a live Luau runtime or tested in Roblox. Client-side movement and physics effects may vary by experience and server rules. If you encounter another error, save the entire error text and line number.

## Maintaining the hub

Edit `main.lua` on GitHub to publish future updates. The raw-content URL above will load the newest commit on the `main` branch.

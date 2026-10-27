-- SALTY Player Hub | Fresh GitHub loader v3.4.2
-- Keeps each run on the newest public main.lua rather than relying on a cached URL.
local REPO = "https://raw.githubusercontent.com/MrRos3/SaltyP1/main/"
local EXPECTED = "SALTY Player Hub v3.4.2"
local suffix = tostring(DateTime.now().UnixTimestampMillis) .. "-" .. tostring(math.random(100000, 999999))
local url = REPO .. "main.lua?fresh=" .. suffix

local ok, source = pcall(function()
    return game:HttpGet(url, true)
end)
if not ok or type(source) ~= "string" or #source < 10000 then
    warn("[SALTY Loader] GitHub download failed: " .. tostring(source))
    error("SALTY update not loaded: check executor HTTP access and GitHub availability")
end

if not string.find(source, EXPECTED, 1, true) then
    warn("[SALTY Loader] Incorrect/cached main.lua version; refusing to load stale code")
    error("Expected " .. EXPECTED .. "; got an outdated or unexpected GitHub response")
end

if not string.find(source, "SpectatePlayerDropdown = CameraTab:Dropdown", 1, true)
    or not string.find(source, "WalkFlingControl = FlingTab:Toggle", 1, true) then
    error("New Camera/Fling controls missing in fetched source; refusing stale script")
end

print(string.format("[SALTY Loader] Fetched %s | %d bytes | fresh=%s", EXPECTED, #source, suffix))
local compiled, compileError = loadstring(source)
if not compiled then
    warn("[SALTY Loader] Luau compilation failed: " .. tostring(compileError))
    error("SALTY main.lua could not compile: " .. tostring(compileError))
end

local worked, runError = xpcall(compiled, function(err)
    local message = tostring(err)
    if debug and type(debug.traceback) == "function" then
        local tracedOk, traced = pcall(debug.traceback, message)
        if tracedOk then return traced end
    end
    return message
end)
if not worked then
    warn("[SALTY Loader] Runtime UI error: " .. tostring(runError))
    error("SALTY v3.4.2 startup failed: " .. tostring(runError))
end
print("[SALTY Loader] Startup complete; check Camera > Spectate Player and Fling > WalkFling.")

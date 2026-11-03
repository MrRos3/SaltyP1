-- SALTY Player Hub | Obfuscated-only fresh loader v3.10.0
local REPO = "https://raw.githubusercontent.com/MrRos3/SaltyP1/main/"
local EXPECTED = "SALTY Player Hub v3.10.0"
local MARKER = "53414C545920506C61796572204875622076332E31302E30"
local DEPENDENCY_MARKER = "6E616D65706C6174652E6F6266757363617465642E6C75613F763D"
local DRIVING_MARKER = "68747470733A2F2F7261772E67697468756275736572636F6E74656E742E636F6D2F4D72526F73332F53616C747950312F6D61696E2F64726976696E672E6F6266757363617465642E6C75613F66726573683D"
local suffix = tostring(DateTime.now().UnixTimestampMillis) .. "-" .. tostring(math.random(100000, 999999))
local url = REPO .. "main.obfuscated.lua?fresh=" .. suffix
local ok, source = pcall(function() return game:HttpGet(url, true) end)
if not ok or type(source) ~= "string" or #source < 100000 then
    warn("[SALTY Loader] Obfuscated script download failed: " .. tostring(source))
    error("SALTY download failed: check executor HTTP access and GitHub availability")
end
if not string.find(source, "l_0xC0DEC0DE", 1, true)
    or not string.find(source, MARKER, 1, true)
    or not string.find(source, DEPENDENCY_MARKER, 1, true)
    or not string.find(source, DRIVING_MARKER, 1, true) then
    error("Obfuscated SALTY source is outdated or invalid; refusing to load")
end
print(string.format("[SALTY Loader] Fetched obfuscated %s | %d bytes", EXPECTED, #source))
local compiled, compileError = loadstring(source)
if not compiled then
    warn("[SALTY Loader] Luau compilation error: " .. tostring(compileError))
    error("SALTY obfuscated Lua failed to compile: " .. tostring(compileError))
end
local worked, runError = xpcall(compiled, function(err)
    local message = tostring(err)
    if debug and type(debug.traceback) == "function" then
        local good, trace = pcall(debug.traceback, message)
        if good then return trace end
    end
    return message
end)
if not worked then
    warn("[SALTY Loader] Runtime error: " .. tostring(runError))
    error("SALTY obfuscated startup failed: " .. tostring(runError))
end
print("[SALTY Loader] Loaded obfuscated-only SALTY Player Hub successfully.")

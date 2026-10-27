-- v2.8: Adaptive / Force Override third-person camera; original anti-fling ON, full bright OFF.
-- SALTY Player Hub v3.4.0 OBSIDIAN EDITION: Movement, Camera, Waypoints, Keybinds & Profiles.
-- Custom SALTY Full Bright (OFF), Anti-Fling (ON).
-- Optimized cached part tracking; preserves v2.5 movement and ESP improvements.
-- Untested in live Roblox. Collisions are governed by server and network ownership.
-- SALTY Player Hub v3.4.0 | OBSIDIAN EDITION
-- Universal player-only script:
-- Fly, infinite jump, movement, fling, combat assistance, player ESP, skyboxes and time.
if getgenv and getgenv().__SALTY_PLAYER_CLEANUP then
    pcall(getgenv().__SALTY_PLAYER_CLEANUP)
end
if getgenv and getgenv().__SALTY_PLAYER_WINDOW then
    pcall(function()
        local oldWindow = getgenv().__SALTY_PLAYER_WINDOW
        if oldWindow and not oldWindow.Destroyed then oldWindow:Destroy() end
    end)
    getgenv().__SALTY_PLAYER_WINDOW = nil
end
local ENV = getgenv and getgenv() or _G
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaUI/main/main.lua?v=" .. os.time()
))()
VantaUI:SetTheme("Salty Special")
local Window = VantaUI:CreateWindow({
    Title = "SALTY Player Hub v3.4.0 | OBSIDIAN",
    Icon = VantaUI.Brand.Image,
    Theme = "Salty Special",
    StartupTab = "Movement",
    HideSearchBar = true,
    ToggleKey = Enum.KeyCode.RightShift,
    Branding = {
        Name = "SALTY",
        Image = VantaUI.Brand.Image,
        Folder = "SALTY_Player_Hub",
        IconSize = 24,
        IconRadius = 7,
        OpenButtonIconRadius = 8,
        Intro = false,
    },
    OpenButton = {
        Title = "Open SALTY Obsidian Hub v3.3",
        Icon = VantaUI.Brand.Image,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        OnlyIcon = true,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        }),
    },
})
-- Keep a handle to this window for clean replacements on the next execution.
ENV.__SALTY_PLAYER_WINDOW = Window
local State = {
    Running = true,
    Fly = false,
    FlySpeed = 60,
    InfiniteJump = false, -- deliberate midair re-jumps; defaults OFF
    AirWalk = false,
    AirWalkSize = 11,
    DashPower = 90,
    DashCooldown = 1.4,
    DashLast = -1e9,
    AntiVoid = false,
    AntiVoidOffset = 35,
    Spectating = false,
    SpectateTarget = nil, -- independent username for Spectate (not Teleport/Fling)
    Freecam = false,
    FreecamSpeed = 35,
    FreecamFOV = 70,
    Speed = false,
    WalkSpeed = 32,
    ForceThirdPerson = false,
    ThirdPersonDistance = 10,
    ThirdPersonMode = "Adaptive", -- Adaptive / Force Override / Native Only
    UnlockMouse = false,
    NoClip = false,
    AntiAFK = true,
    AntiFling = true, -- locally disables collision on other players
    AntiFlingSuspended = false,
    FullBright = false, -- custom SALTY illumination; default OFF
    ClickTP = false,
    ServerHopBusy = false,
    SelectedPlayer = nil,
    SavedCFrame = nil,
    Flinging = false,
    CancelFling = false,
    FlingDuration = 2.2, -- quick contact; can increase for difficult moving players
    WalkFling = false, -- Infinite Yield-style no-spin contact pulses while walking
    SelectedSkybox = "Original",
    Time = Lighting.ClockTime,
    LockTime = false,
    Connections = {},
    Combat = {
        Aim = false,
        Aiming = false,
        LockHeld = false,
        LockedPlayer = nil,
        FOV = 180,
        Smoothness = 12,
        MaxDistance = 400,
        Part = "Head",
        Priority = "Closest to crosshair",
        TeamCheck = true,
        WallCheck = true,
        ShowFOV = false,
        AutoUseTool = false,
        UseRange = 18,
        LastAttack = 0,
    },
    ESP = {
        Enabled = false,
        Chams = false,
        Xray = true,
        Names = true,
        Distances = true,
        Health = false,
        Boxes = false,
        Tracers = false,
        TeamCheck = false,
        TeamColors = false,
        MaxDistance = 600,
        Quality = "Performance", -- Performance / Balanced / Fast
        Color = Color3.fromHex("#F18CA3"),
    },
}
local NotificationIcon = {
    Fling = "zap", Teleport = "map-pin", Fly = "wind", ["Infinite Jump"] = "arrow-up", Skybox = "image",
    Time = "clock", ["Anti-AFK"] = "coffee", Players = "users",
    ["Custom Skybox"] = "image-plus", Combat = "crosshair", ESP = "scan-eye",
    Protection = "shield", ["Full Bright"] = "sun", Server = "server",
    Movement = "footprints", Dash = "zap", Camera = "video", Waypoints = "map-pin",
    Profiles = "save", Keybinds = "keyboard", Obsidian = "gem",
}
local function notify(title, text)
    pcall(function()
        VantaUI:Notify({
            Title = tostring(title),
            Content = tostring(text),
            Duration = 3,
            Icon = NotificationIcon[title] or "info",
        })
    end)
end
local function bind(connection)
    table.insert(State.Connections, connection)
    return connection
end
local function character()
    return LocalPlayer.Character
end
local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end
local function rootPart()
    local char = character()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end
local function dropdownValue(value)
    if type(value) == "table" then
        return value.Title or value.Value or value[1]
    end
    return value
end
---------------------------------------------------------------------
-- ORIGINAL VISUAL STATE
---------------------------------------------------------------------
local OriginalClockTime = Lighting.ClockTime
local OriginalSky
local ExistingSky = Lighting:FindFirstChildOfClass("Sky")
if ExistingSky then
    OriginalSky = {
        SkyboxBk = ExistingSky.SkyboxBk,
        SkyboxDn = ExistingSky.SkyboxDn,
        SkyboxFt = ExistingSky.SkyboxFt,
        SkyboxLf = ExistingSky.SkyboxLf,
        SkyboxRt = ExistingSky.SkyboxRt,
        SkyboxUp = ExistingSky.SkyboxUp,
        CelestialBodiesShown = ExistingSky.CelestialBodiesShown,
        MoonAngularSize = ExistingSky.MoonAngularSize,
        MoonTextureId = ExistingSky.MoonTextureId,
        StarCount = ExistingSky.StarCount,
        SunAngularSize = ExistingSky.SunAngularSize,
        SunTextureId = ExistingSky.SunTextureId,
    }
end
local CreatedSky = nil
local function currentSky()
    local sky = Lighting:FindFirstChild("__SALTY_SKY")
    if sky and sky:IsA("Sky") then
        return sky
    end
    sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        return sky
    end
    sky = Instance.new("Sky")
    sky.Name = "__SALTY_SKY"
    sky.Parent = Lighting
    CreatedSky = sky
    return sky
end
-- Preserve the original six-face cubemaps; the cinematic variations below
-- intentionally reuse these known face IDs instead of guessing new assets.
local Skyboxes = {
    ["Galaxy"] = {
        Bk = "rbxassetid://159454299",
        Dn = "rbxassetid://159454296",
        Ft = "rbxassetid://159454293",
        Lf = "rbxassetid://159454286",
        Rt = "rbxassetid://159454300",
        Up = "rbxassetid://159454288",
    },
    ["Vaporwave Classic"] = {
        Bk = "rbxassetid://1417494030",
        Dn = "rbxassetid://1417494146",
        Ft = "rbxassetid://1417494253",
        Lf = "rbxassetid://1417494402",
        Rt = "rbxassetid://1417494499",
        Up = "rbxassetid://1417494643",
    },
    ["Vaporwave Neon"] = {
        Bk = "rbxassetid://8631780182",
        Dn = "rbxassetid://8631784904",
        Ft = "rbxassetid://8631769834",
        Lf = "rbxassetid://8631777199",
        Rt = "rbxassetid://8631735555",
        Up = "rbxassetid://8631782345",
    },
    ["Red Night"] = {
        Bk = "rbxassetid://401664839",
        Dn = "rbxassetid://401664862",
        Ft = "rbxassetid://401664960",
        Lf = "rbxassetid://401664881",
        Rt = "rbxassetid://401664901",
        Up = "rbxassetid://401664936",
    },
    ["Sunset"] = {
        Bk = "rbxassetid://323494035",
        Dn = "rbxassetid://323494368",
        Ft = "rbxassetid://323494130",
        Lf = "rbxassetid://323494252",
        Rt = "rbxassetid://323494067",
        Up = "rbxassetid://323493360",
    },
    ["Tropic"] = {
        Bk = "rbxassetid://169210090",
        Dn = "rbxassetid://169210108",
        Ft = "rbxassetid://169210121",
        Lf = "rbxassetid://169210133",
        Rt = "rbxassetid://169210143",
        Up = "rbxassetid://169210149",
    },
    ["Soft Blue"] = {
        Bk = "rbxassetid://196263721",
        Dn = "rbxassetid://196263643",
        Ft = "rbxassetid://196263721",
        Lf = "rbxassetid://196263721",
        Rt = "rbxassetid://196263721",
        Up = "rbxassetid://196263782",
    },
    ["Blue Horizon"] = {
        Bk = "rbxassetid://135483466",
        Dn = "rbxassetid://135483484",
        Ft = "rbxassetid://135483461",
        Lf = "rbxassetid://135483495",
        Rt = "rbxassetid://135483499",
        Up = "rbxassetid://135483475",
    },
    ["Pink Morning"] = {
        Bk = "rbxassetid://12635309703",
        Dn = "rbxassetid://12635311686",
        Ft = "rbxassetid://12635312870",
        Lf = "rbxassetid://12635313718",
        Rt = "rbxassetid://12635315817",
        Up = "rbxassetid://12635316856",
    },
    ["Purple Gradient"] = {
        Bk = "rbxassetid://8107841671",
        Dn = "rbxassetid://6444884785",
        Ft = "rbxassetid://8107841671",
        Lf = "rbxassetid://8107841671",
        Rt = "rbxassetid://8107841671",
        Up = "rbxassetid://8107849791",
    },
    ["Pink Gradient"] = {
        Bk = "rbxassetid://11427769401",
        Dn = "rbxassetid://11427770685",
        Ft = "rbxassetid://11427769401",
        Lf = "rbxassetid://11427769401",
        Rt = "rbxassetid://11427769401",
        Up = "rbxassetid://11427771954",
    },
    ["Neptune"] = {
        Bk = "rbxassetid://218955819",
        Dn = "rbxassetid://218953419",
        Ft = "rbxassetid://218954524",
        Lf = "rbxassetid://218958493",
        Rt = "rbxassetid://218957134",
        Up = "rbxassetid://218950090",
    },
    ["Aesthetic Night"] = {
        Bk = "rbxassetid://1045964490",
        Dn = "rbxassetid://1045964368",
        Ft = "rbxassetid://1045964655",
        Lf = "rbxassetid://1045964655",
        Rt = "rbxassetid://1045964655",
        Up = "rbxassetid://1045962969",
    },
    ["Cinematic Cabin Sky"] = {
        Bk = "rbxassetid://162001887",
        Dn = "rbxassetid://161998893",
        Ft = "rbxassetid://162001897",
        Lf = "rbxassetid://162001904",
        Rt = "rbxassetid://162001919",
        Up = "rbxassetid://162001926",
    },
    ["Classic Sky"] = {
        Bk = "rbxassetid://12064107",
        Dn = "rbxassetid://12064152",
        Ft = "rbxassetid://12064121",
        Lf = "rbxassetid://12063984",
        Rt = "rbxassetid://12064115",
        Up = "rbxassetid://12064131",
    },
    ["Purple Atmosphere"] = {
        Bk = "rbxassetid://7018684000",
        Dn = "rbxassetid://6334928194",
        Ft = "rbxassetid://7018684000",
        Lf = "rbxassetid://7018684000",
        Rt = "rbxassetid://7018684000",
        Up = "rbxassetid://7018689553",
    },
    ["Among Us"] = {
        Bk = "rbxassetid://5752463190",
        Dn = "rbxassetid://5752463190",
        Ft = "rbxassetid://5752463190",
        Lf = "rbxassetid://5752463190",
        Rt = "rbxassetid://5752463190",
        Up = "rbxassetid://5752463190",
    },
    ["Skeleton"] = {
        Bk = "rbxassetid://169585459",
        Dn = "rbxassetid://169585459",
        Ft = "rbxassetid://169585459",
        Lf = "rbxassetid://169585459",
        Rt = "rbxassetid://169585459",
        Up = "rbxassetid://169585459",
    },
    ["Dark Meme"] = {
        Bk = "rbxassetid://78391907",
        Dn = "rbxassetid://78391907",
        Ft = "rbxassetid://78391907",
        Lf = "rbxassetid://78391907",
        Rt = "rbxassetid://78391907",
        Up = "rbxassetid://78391907",
    },
}
-- Cinematic skybox variations: graded looks derived from the verified cubemaps
-- above. These apply a reversible local ColorCorrectionEffect to the scene.
local SkyboxTones = {
    ["Crimson Veil"]   = {Base = "Red Night", Color = Color3.fromRGB(255, 135, 164), Contrast = 0.18, Saturation = 0.12},
    ["Obsidian Eclipse"] = {Base = "Galaxy", Color = Color3.fromRGB(141, 109, 190), Contrast = 0.36, Saturation = -0.18, Brightness = -0.10},
    ["Lavender Dream"] = {Base = "Purple Gradient", Color = Color3.fromRGB(205, 173, 255), Contrast = -0.08, Saturation = 0.24},
    ["Rose Quartz"]    = {Base = "Pink Gradient", Color = Color3.fromRGB(255, 187, 218), Contrast = -0.08, Saturation = 0.22},
    ["Glacial Dawn"]   = {Base = "Soft Blue", Color = Color3.fromRGB(153, 230, 255), Contrast = 0.05, Saturation = -0.12},
    ["Teal Nebula"]    = {Base = "Neptune", Color = Color3.fromRGB(128, 255, 233), Contrast = 0.20, Saturation = 0.20},
    ["Amber Haze"]     = {Base = "Sunset", Color = Color3.fromRGB(255, 211, 149), Contrast = 0.08, Saturation = 0.16},
    ["Coral Afterglow"] = {Base = "Sunset", Color = Color3.fromRGB(255, 160, 186), Contrast = 0.12, Saturation = 0.25},
    ["Noir Violet"]    = {Base = "Aesthetic Night", Color = Color3.fromRGB(172, 145, 232), Contrast = 0.28, Saturation = -0.15, Brightness = -0.08},
    ["Neon Sakura"]    = {Base = "Vaporwave Neon", Color = Color3.fromRGB(255, 149, 219), Contrast = 0.18, Saturation = 0.35},
    ["Moonlit Cabin"]  = {Base = "Cinematic Cabin Sky", Color = Color3.fromRGB(179, 205, 255), Contrast = 0.15, Saturation = -0.16, Brightness = -0.06},
    ["Electric Dusk"]  = {Base = "Blue Horizon", Color = Color3.fromRGB(152, 186, 255), Contrast = 0.24, Saturation = 0.20},
}
local SkyToneEffect = nil
local function clearSkyTone()
    if SkyToneEffect then
        pcall(function() SkyToneEffect:Destroy() end)
        SkyToneEffect = nil
    end
end
local function applySkyTone(tone)
    clearSkyTone()
    if not tone then return end
    local effect = Instance.new("ColorCorrectionEffect")
    effect.Name = "__SALTY_SkyboxTone"
    effect.TintColor = tone.Color or Color3.new(1, 1, 1)
    effect.Contrast = tone.Contrast or 0
    effect.Saturation = tone.Saturation or 0
    effect.Brightness = tone.Brightness or 0
    effect.Parent = Lighting
    SkyToneEffect = effect
end

local function restoreOriginalSky()
    clearSkyTone()
    local saltySky = Lighting:FindFirstChild("__SALTY_SKY")
    if saltySky and saltySky:IsA("Sky") then
        saltySky:Destroy()
        CreatedSky = nil
    end
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if OriginalSky then
        if not sky then
            sky = Instance.new("Sky")
            sky.Name = "Sky"
            sky.Parent = Lighting
        end
        sky.SkyboxBk = OriginalSky.SkyboxBk
        sky.SkyboxDn = OriginalSky.SkyboxDn
        sky.SkyboxFt = OriginalSky.SkyboxFt
        sky.SkyboxLf = OriginalSky.SkyboxLf
        sky.SkyboxRt = OriginalSky.SkyboxRt
        sky.SkyboxUp = OriginalSky.SkyboxUp
        sky.CelestialBodiesShown = OriginalSky.CelestialBodiesShown
        sky.MoonAngularSize = OriginalSky.MoonAngularSize
        sky.MoonTextureId = OriginalSky.MoonTextureId
        sky.StarCount = OriginalSky.StarCount
        sky.SunAngularSize = OriginalSky.SunAngularSize
        sky.SunTextureId = OriginalSky.SunTextureId
    elseif sky and sky.Name == "__SALTY_SKY" then
        sky:Destroy()
    end
    State.SelectedSkybox = "Original"
end
local function applySkybox(name)
    name = tostring(name or "Original")
    if name == "Original" then
        restoreOriginalSky()
        notify("Skybox", "Restored original sky")
        return
    end
    local tone = SkyboxTones[name]
    local baseName = tone and tone.Base or name
    local preset = Skyboxes[baseName]
    if not preset then
        return notify("Skybox", "Unknown skybox preset")
    end
    local sky = currentSky()
    applySkyTone(tone)
    sky.SkyboxBk = preset.Bk
    sky.SkyboxDn = preset.Dn
    sky.SkyboxFt = preset.Ft
    sky.SkyboxLf = preset.Lf
    sky.SkyboxRt = preset.Rt
    sky.SkyboxUp = preset.Up
    sky.CelestialBodiesShown = not (
        baseName == "Vaporwave Neon"
        or baseName == "Purple Gradient"
        or baseName == "Pink Gradient"
        or baseName == "Among Us"
        or baseName == "Skeleton"
        or baseName == "Dark Meme"
    )
    if baseName == "Galaxy" or baseName == "Aesthetic Night" or baseName == "Neptune" then
        sky.StarCount = 3000
    elseif baseName == "Tropic" then
        sky.StarCount = 100
    else
        sky.StarCount = 1000
    end
    State.SelectedSkybox = name
    notify("Skybox", name .. " applied")
end
-- SALTY FULL BRIGHT: custom, reversible scene illumination (OFF by default).
-- Does not change ClockTime, so the Time Changer works independently.
-- No per-frame lighting loop: only react if the game overwrites a relevant value.
local SaltyBrightValues = {
    Brightness = 3,
    Ambient = Color3.fromRGB(190, 190, 200),
    OutdoorAmbient = Color3.fromRGB(200, 205, 215),
    ExposureCompensation = 0.25,
    FogEnd = 750000,
    GlobalShadows = false,
}
local BrightOriginal = nil
local BrightConnection = nil
local BrightWriting = false

local function applyFullBright()
    if not State.FullBright or BrightWriting then return end
    BrightWriting = true
    for prop, value in pairs(SaltyBrightValues) do
        pcall(function()
            if Lighting[prop] ~= value then
                Lighting[prop] = value
            end
        end)
    end
    BrightWriting = false
end

local function setFullBright(enabled)
    enabled = enabled == true
    if enabled then
        if not BrightOriginal then
            BrightOriginal = {}
            for prop in pairs(SaltyBrightValues) do
                pcall(function()
                    BrightOriginal[prop] = Lighting[prop]
                end)
            end
        end
        State.FullBright = true
        if not BrightConnection then
            BrightConnection = Lighting.Changed:Connect(function(prop)
                if SaltyBrightValues[prop] ~= nil and not BrightWriting then
                    applyFullBright()
                end
            end)
        end
        applyFullBright()
    else
        State.FullBright = false
        if BrightConnection then
            BrightConnection:Disconnect()
            BrightConnection = nil
        end
        if BrightOriginal then
            local previous = BrightOriginal
            BrightOriginal = nil
            BrightWriting = true
            for prop, value in pairs(previous) do
                pcall(function()
                    Lighting[prop] = value
                end)
            end
            BrightWriting = false
        end
    end
end

local function setTime(value)
    value = math.clamp(tonumber(value) or 12, 0, 24)
    State.Time = value
    Lighting.ClockTime = value
end
---------------------------------------------------------------------
-- FLY
---------------------------------------------------------------------
local FlyConnection, FlyBV, FlyBG
local FlyAnimateScript
local FlyAnimateWasDisabled = false
local function stopFlyAnimations()
    local char = character()
    local hum = humanoid()
    if not char or not hum then
        return
    end
    FlyAnimateScript = char:FindFirstChild("Animate")
    if FlyAnimateScript and FlyAnimateScript:IsA("LocalScript") then
        FlyAnimateWasDisabled = FlyAnimateScript.Disabled
        FlyAnimateScript.Disabled = true
    end
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function()
                track:Stop(0.1)
            end)
        end
    end
end
local function restoreFlyAnimations()
    if FlyAnimateScript and FlyAnimateScript.Parent then
        pcall(function()
            FlyAnimateScript.Disabled = FlyAnimateWasDisabled
        end)
    end
    FlyAnimateScript = nil
    FlyAnimateWasDisabled = false
end
local function clearFlyObjects()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyBV then
        FlyBV:Destroy()
        FlyBV = nil
    end
    if FlyBG then
        FlyBG:Destroy()
        FlyBG = nil
    end
end
local function setFly(enabled)
    enabled = enabled == true
    if State.Fly == enabled then
        return
    end
    State.Fly = enabled
    clearFlyObjects()
    local root = rootPart()
    local hum = humanoid()
    if not enabled then
        restoreFlyAnimations()
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
        notify("Fly", "Disabled")
        return
    end
    if not root or not hum then
        State.Fly = false
        return notify("Fly", "Character not ready")
    end
    hum.PlatformStand = true
    hum.AutoRotate = false
    stopFlyAnimations()
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.Name = "SALTY_FlyVelocity"
    FlyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    FlyBV.P = 1250
    FlyBV.Velocity = Vector3.zero
    FlyBV.Parent = root
    FlyBG = Instance.new("BodyGyro")
    FlyBG.Name = "SALTY_FlyGyro"
    FlyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    FlyBG.P = 90000
    FlyBG.CFrame = root.CFrame
    FlyBG.Parent = root
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not State.Running or not State.Fly then
            return
        end
        local currentRoot = rootPart()
        local currentHum = humanoid()
        local camera = Workspace.CurrentCamera
        if not currentRoot
            or not currentHum
            or not camera
            or not FlyBV
            or not FlyBG then
            return
        end
        pcall(function()
            currentHum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
        local direction = Vector3.zero
        local cf = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            direction -= Vector3.new(0, 1, 0)
        end
        if direction.Magnitude > 0 then
            direction = direction.Unit
        end
        FlyBV.Velocity = direction * State.FlySpeed
        -- Camera-follow body including pitch.
        FlyBG.CFrame = cf
    end)
    notify("Fly", "Enabled • no fall animation • camera-follow body")
end
bind(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.F then
        setFly(not State.Fly)
    end
end))
---------------------------------------------------------------------
-- INFINITE JUMP | keyboard, controller and mobile jump inputs.
-- Only changes the local humanoid's jump state when explicitly enabled.
-- One persistent connection, tracked in State.Connections for cleanup.
---------------------------------------------------------------------
local LastInfiniteJumpAt = 0
bind(UserInputService.JumpRequest:Connect(function()
    if not State.Running or not State.InfiniteJump or State.Fly or State.Flinging then
        return
    end

    local hum = humanoid()
    if not hum or hum.Health <= 0 or hum.Sit or hum.PlatformStand then
        return
    end

    -- Discard multiple input callbacks from the same physical press.
    local now = os.clock()
    if now - LastInfiniteJumpAt < 0.075 then
        return
    end
    LastInfiniteJumpAt = now

    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end))

---------------------------------------------------------------------
-- SALTY THIRD PERSON v2.8
-- Native Roblox zoom first; adaptively override cameras locked at the head.
-- "Force Override" can handle scripted first-person cameras that ignore zoom.
-- All changes are local and restored when disabled. No bypass guarantee.
---------------------------------------------------------------------
local CameraRenderName = "SALTY_Player_Camera_" .. tostring(LocalPlayer.UserId)
local SavedCameraState = nil
local SavedMouseState = nil
local CameraStepBound = false
local CameraCheckAt = 0
local CameraNearFrames = 0
local CameraOverrideFrames = 0
local CameraLastWritten = nil
local CameraOrbitForward = nil
local CameraRayParams = RaycastParams.new()
CameraRayParams.FilterType = Enum.RaycastFilterType.Exclude
CameraRayParams.IgnoreWater = true
local CameraRayCharacter = nil
local CameraLastAvatarScan = 0
local CameraVisibleCharacter = nil
local CameraVisibleParts = {}
local CameraOriginalTransparency = setmetatable({}, {__mode = "k"})

local function setZoomRange(minimum, maximum)
    minimum = math.max(0.5, tonumber(minimum) or 0.5)
    maximum = math.max(minimum, tonumber(maximum) or minimum)
    pcall(function()
        -- Raise the max before the min to avoid invalid intermediate ranges.
        LocalPlayer.CameraMaxZoomDistance = math.max(maximum, LocalPlayer.CameraMinZoomDistance)
        LocalPlayer.CameraMinZoomDistance = minimum
        LocalPlayer.CameraMaxZoomDistance = maximum
    end)
end

local function clearCameraVisibility()
    for part, old in pairs(CameraOriginalTransparency) do
        if part and part.Parent then
            pcall(function() part.LocalTransparencyModifier = old end)
        end
        CameraOriginalTransparency[part] = nil
    end
    table.clear(CameraVisibleParts)
    CameraVisibleCharacter = nil
    CameraLastAvatarScan = 0
end

local function exposeCharacterWhileOutside(char, now)
    if CameraVisibleCharacter ~= char then
        clearCameraVisibility()
        CameraVisibleCharacter = char
    end
    if now - CameraLastAvatarScan > 0.7 then
        CameraLastAvatarScan = now
        -- Scan at most every 0.7 s; render steps only visit cached body parts.
        for _, object in ipairs(char:GetDescendants()) do
            if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart"
                and object.Transparency < 0.99 and CameraOriginalTransparency[object] == nil then
                CameraOriginalTransparency[object] = object.LocalTransparencyModifier
                CameraVisibleParts[#CameraVisibleParts + 1] = object
            end
        end
    end
    for _, part in ipairs(CameraVisibleParts) do
        if part.Parent and part.Transparency < 0.99 and part.LocalTransparencyModifier ~= 0 then
            part.LocalTransparencyModifier = 0
        end
    end
end

local function restoreCameraSettings()
    clearCameraVisibility()
    CameraLastWritten = nil
    CameraOrbitForward = nil
    CameraNearFrames = 0
    CameraOverrideFrames = 0
    CameraRayCharacter = nil
    if not SavedCameraState then return end
    local saved = SavedCameraState
    SavedCameraState = nil
    pcall(function() LocalPlayer.CameraMode = saved.Mode end)
    setZoomRange(saved.MinZoom, saved.MaxZoom)
    local cam = Workspace.CurrentCamera
    if cam and cam == saved.Camera and saved.CameraType then
        pcall(function() cam.CameraType = saved.CameraType end)
        if saved.CameraSubject then
            pcall(function() cam.CameraSubject = saved.CameraSubject end)
        end
    end
end

local function applyNativeThirdPerson(now)
    if now < CameraCheckAt then return end
    CameraCheckAt = now + 0.22
    local distance = math.clamp(State.ThirdPersonDistance, 6, 25)
    pcall(function()
        if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end
    end)
    if LocalPlayer.CameraMinZoomDistance < distance - 0.05
        or LocalPlayer.CameraMaxZoomDistance < distance + 1 then
        setZoomRange(distance, math.max(30, distance + 5))
    end
end

local function lookWithMouse(direction, delta)
    local yaw = math.atan2(-direction.X, -direction.Z)
    local pitch = math.asin(math.clamp(direction.Y, -0.99, 0.99))
    yaw = yaw - delta.X * 0.0025
    pitch = math.clamp(pitch - delta.Y * 0.0025, -1.25, 1.25)
    return Vector3.new(-math.sin(yaw) * math.cos(pitch),
        math.sin(pitch), -math.cos(yaw) * math.cos(pitch)).Unit
end

local function overrideCameraPosition(camera, char, root, distance, now)
    local focus = root.Position + Vector3.new(0, 1.65, 0)
    local incoming = camera.CFrame
    local externalCameraUpdate = true
    if CameraLastWritten then
        local positionDifference = (incoming.Position - CameraLastWritten.Position).Magnitude
        local directionDifference = (incoming.LookVector - CameraLastWritten.LookVector).Magnitude
        externalCameraUpdate = positionDifference > 0.035 or directionDifference > 0.004
    end
    local forward = incoming.LookVector
    if externalCameraUpdate or not CameraOrbitForward then
        CameraOrbitForward = forward
    else
        -- Some Scriptable cameras stop updating when they are taken out of
        -- first person. Provide mouse orbit only if their camera is frozen.
        local dragging = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        if dragging and not UserInputService:GetFocusedTextBox() then
            local delta = UserInputService:GetMouseDelta()
            if delta.Magnitude > 0 then
                CameraOrbitForward = lookWithMouse(CameraOrbitForward, delta)
            end
        end
    end
    forward = CameraOrbitForward or forward
    if forward.Magnitude < 0.01 then
        forward = root.CFrame.LookVector
    end
    forward = forward.Unit
    local wanted = focus - forward * distance
    if CameraRayCharacter ~= char then
        CameraRayCharacter = char
        CameraRayParams.FilterDescendantsInstances = {char}
    end
    local hit = Workspace:Raycast(focus, wanted - focus, CameraRayParams)
    if hit then
        wanted = hit.Position + hit.Normal * 0.3
    end
    if (wanted - focus).Magnitude > 0.15 then
        local aimed = CFrame.lookAt(wanted, focus)
        camera.CFrame = aimed
        camera.Focus = CFrame.new(focus)
        CameraLastWritten = aimed
        exposeCharacterWhileOutside(char, now)
    end
end

local function enforceCameraAndMouse()
    if not State.Running then return end
    local now = os.clock()
    if State.ForceThirdPerson then
        applyNativeThirdPerson(now)
        local camera = Workspace.CurrentCamera
        local char = character()
        local root = rootPart()
        local hum = humanoid()
        if camera and char and root and hum and hum.Health > 0 then
            local distance = math.clamp(State.ThirdPersonDistance, 6, 25)
            local focus = root.Position + Vector3.new(0, 1.65, 0)
            local actualDistance = (camera.CFrame.Position - focus).Magnitude
            local method = State.ThirdPersonMode
            if method == "Native Only" then
                CameraNearFrames = 0
                CameraOverrideFrames = 0
                if CameraVisibleCharacter then clearCameraVisibility() end
            else
                if actualDistance < math.max(3.4, distance * 0.72) then
                    CameraNearFrames = math.min(CameraNearFrames + 1, 10)
                else
                    CameraNearFrames = math.max(CameraNearFrames - 1, 0)
                end
                if method == "Force Override" or CameraNearFrames >= 2 then
                    CameraOverrideFrames = 20 -- hold for stable render frames
                elseif CameraOverrideFrames > 0 then
                    CameraOverrideFrames = CameraOverrideFrames - 1
                end
                if method == "Force Override" or CameraOverrideFrames > 0 then
                    overrideCameraPosition(camera, char, root, distance, now)
                else
                    CameraLastWritten = nil
                    CameraOrbitForward = nil
                    if CameraVisibleCharacter then clearCameraVisibility() end
                end
            end
        else
            CameraLastWritten = nil
            CameraOrbitForward = nil
            if CameraVisibleCharacter then clearCameraVisibility() end
        end
    end
    if State.UnlockMouse then
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end
end

local function syncCameraStep()
    local shouldRun = State.Running and (State.ForceThirdPerson or State.UnlockMouse)
    if shouldRun and not CameraStepBound then
        CameraStepBound = true
        -- Very late update: after most experiences run their own camera code.
        RunService:BindToRenderStep(CameraRenderName,
            Enum.RenderPriority.Last.Value + 10, enforceCameraAndMouse)
    elseif not shouldRun and CameraStepBound then
        CameraStepBound = false
        pcall(function() RunService:UnbindFromRenderStep(CameraRenderName) end)
    end
end

local function setForceThirdPerson(enabled)
    enabled = enabled == true
    if State.ForceThirdPerson == enabled then return end
    if enabled then
        local camera = Workspace.CurrentCamera
        SavedCameraState = {
            Camera = camera,
            Mode = LocalPlayer.CameraMode,
            MinZoom = LocalPlayer.CameraMinZoomDistance,
            MaxZoom = LocalPlayer.CameraMaxZoomDistance,
            CameraType = camera and camera.CameraType or nil,
            CameraSubject = camera and camera.CameraSubject or nil,
        }
        CameraCheckAt = 0
        CameraNearFrames = 0
        CameraOverrideFrames = 0
    end
    State.ForceThirdPerson = enabled
    if enabled then
        applyNativeThirdPerson(os.clock())
        -- Do not replace Scriptable with Custom: that breaks some game cameras.
        syncCameraStep()
        enforceCameraAndMouse()
    else
        syncCameraStep()
        restoreCameraSettings()
    end
end

local function setUnlockMouse(enabled)
    enabled = enabled == true
    if State.UnlockMouse == enabled then return end
    if enabled then
        SavedMouseState = {
            Behavior = UserInputService.MouseBehavior,
            IconEnabled = UserInputService.MouseIconEnabled,
        }
    end
    State.UnlockMouse = enabled
    if enabled then
        syncCameraStep()
        enforceCameraAndMouse()
    elseif SavedMouseState then
        local saved = SavedMouseState
        SavedMouseState = nil
        pcall(function()
            UserInputService.MouseBehavior = saved.Behavior
            UserInputService.MouseIconEnabled = saved.IconEnabled
        end)
    end
    syncCameraStep()
end
---------------------------------------------------------------------
-- NOCLIP: RESTORE EACH PART'S ORIGINAL COLLISION WHEN DISABLED
---------------------------------------------------------------------
local OriginalCollision = setmetatable({}, { __mode = "k" })
local NoClipParts = setmetatable({}, { __mode = "k" })
local NoClipCharacter, NoClipChildConnection
local NoClipStepConnection

local function resetNoClipCache()
    if NoClipChildConnection then
        NoClipChildConnection:Disconnect()
        NoClipChildConnection = nil
    end
    table.clear(NoClipParts)
    NoClipCharacter = character()
    if not NoClipCharacter then return end

    -- GetDescendants is expensive. Traverse once, then watch new accessories/parts.
    for _, object in ipairs(NoClipCharacter:GetDescendants()) do
        if object:IsA("BasePart") then NoClipParts[object] = true end
    end
    NoClipChildConnection = NoClipCharacter.DescendantAdded:Connect(function(object)
        if object:IsA("BasePart") then NoClipParts[object] = true end
    end)
end

local function restoreCollision()
    for part, canCollide in pairs(OriginalCollision) do
        if part and part.Parent then
            pcall(function() part.CanCollide = canCollide end)
        end
        OriginalCollision[part] = nil
    end
end

local function applyNoClip()
    if not State.Running or not State.NoClip then return end
    if NoClipCharacter ~= character() then resetNoClipCache() end
    for part in pairs(NoClipParts) do
        if not part.Parent then
            NoClipParts[part] = nil
        elseif part.CanCollide then
            if OriginalCollision[part] == nil then OriginalCollision[part] = true end
            part.CanCollide = false
        end
    end
end

local function setNoClip(enabled)
    State.NoClip = enabled == true
    if State.NoClip then
        if NoClipCharacter ~= character() or not NoClipChildConnection then
            resetNoClipCache()
        end
        if not NoClipStepConnection then
            NoClipStepConnection = RunService.Stepped:Connect(applyNoClip)
        end
    else
        if NoClipStepConnection then
            NoClipStepConnection:Disconnect()
            NoClipStepConnection = nil
        end
        restoreCollision()
        if NoClipChildConnection then
            NoClipChildConnection:Disconnect()
            NoClipChildConnection = nil
        end
        table.clear(NoClipParts)
        NoClipCharacter = nil
    end
end
-- ANTI-FLING: local player-collision protection (ON by default).
-- Checks other characters every physics step, including new character parts.
-- Does not modify your own character. Saved changes restore when turned off.
---------------------------------------------------------------------
local AFChanged = setmetatable({}, {__mode = "k"})
local AFStepConnection = nil

local function afStop()
    if AFStepConnection then
        AFStepConnection:Disconnect()
        AFStepConnection = nil
    end
    for part in pairs(AFChanged) do
        if part.Parent and not part.CanCollide then
            pcall(function() part.CanCollide = true end)
        end
        AFChanged[part] = nil
    end
end

local function afStart()
    if AFStepConnection or not State.Running or not State.AntiFling
        or State.AntiFlingSuspended then return end
    AFStepConnection = RunService.Stepped:Connect(function()
        if not State.Running or not State.AntiFling or State.AntiFlingSuspended then
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        AFChanged[part] = true
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function setAntiFling(enabled)
    State.AntiFling = enabled == true
    if State.AntiFling then
        afStart()
    else
        afStop()
    end
end

local function suspendAntiFling(suspend)
    suspend = suspend == true
    if State.AntiFlingSuspended == suspend then return end
    State.AntiFlingSuspended = suspend
    if suspend then
        afStop()
    elseif State.AntiFling then
        afStart()
    end
end

---------------------------------------------------------------------
-- SPEED + TIME LOCK (poll only at low frequency and only write on change)
---------------------------------------------------------------------
local SavedWalkSpeeds = setmetatable({}, {__mode = "k"})
local function setSpeedEnabled(enabled)
    State.Speed = enabled == true
    local hum = humanoid()
    if State.Speed and hum and SavedWalkSpeeds[hum] == nil then
        SavedWalkSpeeds[hum] = hum.WalkSpeed
    elseif not State.Speed and hum and SavedWalkSpeeds[hum] ~= nil then
        pcall(function() hum.WalkSpeed = SavedWalkSpeeds[hum] end)
        SavedWalkSpeeds[hum] = nil
    end
end

task.spawn(function()
    while State.Running do
        if State.Speed then
            local hum = humanoid()
            if hum and hum.Health > 0 then
                if SavedWalkSpeeds[hum] == nil then SavedWalkSpeeds[hum] = hum.WalkSpeed end
                if math.abs(hum.WalkSpeed - State.WalkSpeed) > 0.5 then
                    hum.WalkSpeed = State.WalkSpeed
                end
            end
        end
        if State.LockTime
            and math.abs(Lighting.ClockTime - State.Time) > 0.05 then
            Lighting.ClockTime = State.Time
        end
        task.wait((State.Speed or State.LockTime) and 0.25 or 0.65)
    end
end)
---------------------------------------------------------------------
-- ANTI AFK
---------------------------------------------------------------------
bind(LocalPlayer.Idled:Connect(function()
    if not State.Running or not State.AntiAFK then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        local camera = Workspace.CurrentCamera
        local cf = camera and camera.CFrame or CFrame.new()
        VirtualUser:Button2Down(Vector2.new(0, 0), cf)
        task.wait(0.08)
        VirtualUser:Button2Up(Vector2.new(0, 0), cf)
    end)
    notify("Anti-AFK", "Idle prevented")
end))
---------------------------------------------------------------------
-- TELEPORT
---------------------------------------------------------------------
local function teleport(cf)
    if State.Flinging then
        notify("Teleport", "Finish the current fling first")
        return false
    end
    local root = rootPart()
    if not root or not cf then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = cf
    return true
end
local function getPlayer(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == name then
            return player
        end
    end
    return nil
end
local function teleportToPlayer(name)
    local player = getPlayer(name)
    local targetRoot = player
        and player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        return notify("Teleport", "Player not available")
    end
    teleport(targetRoot.CFrame * CFrame.new(0, 0, 3.5))
    notify("Teleport", "Teleported to " .. player.Name)
end
---------------------------------------------------------------------
-- SERVER HOP | PUBLIC SERVERS (manual actions only; no idle polling)
-- Roblox's public server list provides player counts, NOT creation times.
-- "Fresh" is therefore a quiet, unvisited-candidate heuristic, not an age claim.
-- Selection/teleport depends on executor HTTP support and Roblox availability.
---------------------------------------------------------------------
local HopVisited = {}
local HopGeneration = 0
local SERVER_PAGE_LIMIT = 100

local function serverListPage(cursor)
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=%d&excludeFullGames=true")
        :format(game.PlaceId, SERVER_PAGE_LIMIT)
    if type(cursor) == "string" and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local body, requestError
    -- Executors differ: try a request API, then the same HttpGet already used
    -- by this hub. No requests are made unless a server button is pressed.
    local requester = (syn and syn.request)
        or (http and http.request) or http_request or request
    if type(requester) == "function" then
        local ok, result = pcall(requester, {Url = url, Method = "GET", Headers = {Accept = "application/json"}})
        if ok and type(result) == "table" then
            local status = tonumber(result.StatusCode or result.Status or 200)
            if status == 429 then
                error("Roblox server list is rate-limited. Wait before retrying.")
            elseif status >= 400 then
                requestError = "Server list HTTP " .. tostring(status)
            else
                body = result.Body or result.body
            end
        elseif not ok then
            requestError = tostring(result)
        end
    end
    if type(body) ~= "string" or body == "" then
        local ok, result = pcall(function() return game:HttpGet(url) end)
        if ok then
            body = result
        else
            error(requestError or tostring(result))
        end
    end
    local data = HttpService:JSONDecode(body)
    if type(data) ~= "table" or type(data.data) ~= "table" then
        error("Server directory returned invalid data")
    end
    return data
end

local function chooseServer(kind, generation)
    local eligible = {}
    local bestCount = math.huge
    local quietFound = false
    local cursor, pages = nil, (kind == "Hop" and 2 or 5)
    local anyPage = false
    for page = 1, pages do
        if not State.Running or not State.ServerHopBusy or generation ~= HopGeneration then
            return nil, "Search cancelled"
        end
        local ok, result = pcall(serverListPage, cursor)
        if not ok then
            if #eligible == 0 then return nil, tostring(result) end
            break -- use valid results from earlier pages if Roblox throttles us
        end
        anyPage = true
        for _, entry in ipairs(result.data) do
            local count = tonumber(entry.playing)
            local capacity = tonumber(entry.maxPlayers)
            local id = entry.id
            if type(id) == "string" and id ~= "" and id ~= game.JobId
                and count and capacity and count >= 0 and count < capacity
                and not HopVisited[id] then
                if kind == "Hop" then
                    table.insert(eligible, {id = id, count = count, capacity = capacity})
                elseif kind == "Empty" then
                    if count < bestCount then
                        bestCount = count
                        table.clear(eligible)
                    end
                    if count == bestCount then
                        table.insert(eligible, {id = id, count = count, capacity = capacity})
                    end
                else -- "Fresh": pick a low-population candidate, never claim true age.
                    if count <= 3 then
                        if not quietFound then
                            table.clear(eligible) -- discard non-quiet fallback candidates
                            quietFound = true
                        end
                        table.insert(eligible, {id = id, count = count, capacity = capacity})
                    elseif not quietFound then
                        if count < bestCount then
                            bestCount = count
                            table.clear(eligible)
                        end
                        if count == bestCount then
                            table.insert(eligible, {id = id, count = count, capacity = capacity})
                        end
                    end
                end
            end
        end
        cursor = result.nextPageCursor
        if not cursor or cursor == "" then break end
        -- A near-empty server is already the best match; stop early for speed.
        if kind == "Empty" and bestCount <= 1 then break end
        if kind == "Fresh" and #eligible >= 12 then break end
        if page < pages then task.wait(0.12) end
    end
    if #eligible == 0 then
        return nil, anyPage and "No other joinable public server found" or "Server directory unavailable"
    end
    local choice = eligible[math.random(1, #eligible)]
    return choice
end

local function serverHop(kind)
    if not State.Running then return end
    if State.ServerHopBusy then
        notify("Server", "A server search or teleport is already in progress")
        return
    end
    if State.Flinging then
        notify("Server", "Cancel the active fling before switching servers")
        return
    end
    if game.PlaceId <= 0 then
        notify("Server", "Server hopping requires a published Roblox place")
        return
    end
    HopGeneration = HopGeneration + 1
    local generation = HopGeneration
    State.ServerHopBusy = true
    notify("Server", kind == "Hop" and "Finding a different public server..."
        or kind == "Empty" and "Searching for the emptiest public server..."
        or "Finding a quiet public server (age cannot be verified)...")

    task.spawn(function()
        local ok, choice, explanation = pcall(chooseServer, kind, generation)
        if not State.Running or generation ~= HopGeneration then return end
        if not ok or not choice then
            State.ServerHopBusy = false
            notify("Server", (not ok and tostring(choice)) or explanation or "No server found")
            return
        end
        HopVisited[choice.id] = true
        local caption = kind == "Fresh" and "Quiet candidate" or
            kind == "Empty" and "Emptiest found" or "Public server"
        notify("Server", string.format("%s: %d/%d players. Joining...", caption, choice.count, choice.capacity))
        -- TeleportAsync is server-side only. Client TeleportToPlaceInstance is
        -- the supported entry point available to a LocalPlayer for a JobId.
        local sent, failure = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, choice.id, LocalPlayer)
        end)
        if not State.Running or generation ~= HopGeneration then return end
        if not sent then
            State.ServerHopBusy = false
            notify("Server", "Teleport failed to start: " .. tostring(failure))
            return
        end
        -- The call can succeed but Roblox can still reject the teleport later.
        task.delay(15, function()
            if State.Running and generation == HopGeneration and State.ServerHopBusy then
                State.ServerHopBusy = false
                notify("Server", "Still here? Roblox may have rejected this server. Try again.")
            end
        end)
    end)
end

-- REJOIN | attempt the current JobId; never secretly hop to another instance.
-- When JobId is unavailable, Teleport to the same place (server not guaranteed).
local function rejoinServer()
    if not State.Running then return end
    if State.ServerHopBusy then
        return notify("Server", "A server search or teleport is already in progress")
    end
    if State.Flinging then
        return notify("Server", "Cancel the active fling before rejoining")
    end
    if game.PlaceId <= 0 then
        return notify("Server", "Rejoin requires a published Roblox place")
    end

    HopGeneration = HopGeneration + 1
    local generation = HopGeneration
    State.ServerHopBusy = true
    local jobId = game.JobId
    local sameInstance = type(jobId) == "string" and jobId ~= ""
    notify("Server", sameInstance and "Rejoining current server..." or "Rejoining this game (server ID unavailable)...")
    local started, failure = pcall(function()
        if sameInstance then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    if not State.Running or generation ~= HopGeneration then return end
    if not started then
        State.ServerHopBusy = false
        return notify("Server", "Rejoin failed to start: " .. tostring(failure))
    end
    -- A teleport request may be accepted initially but fail asynchronously.
    -- The shared TeleportInitFailed handler reports that outcome as well.
    task.delay(15, function()
        if State.Running and generation == HopGeneration and State.ServerHopBusy then
            State.ServerHopBusy = false
            notify("Server", "Still in this session? The rejoin may have been blocked. Try again.")
        end
    end)
end

bind(TeleportService.TeleportInitFailed:Connect(function(player, result, message, placeId)
    if player == LocalPlayer and placeId == game.PlaceId and State.ServerHopBusy then
        HopGeneration = HopGeneration + 1 -- invalidate current in-flight search
        State.ServerHopBusy = false
        notify("Server", "Teleport rejected: " .. tostring(message or result))
    end
end))

-- PLAYER LIST: always display nickname AND username, but store the
-- immutable Roblox username for Teleport/Fling targeting.
local PlayerDropdowns = {}
local SpectatePlayerDropdown = nil -- independently controlled camera target
local PlayerLabelToUsername = {}
local PlayerUsernameToLabel = {}
local PlayerDisplayConnections = {}
local CurrentPlayerLabels = {"No players"}

local function buildPlayerChoices(excludePlayer)
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= excludePlayer then
            table.insert(players, player)
        end
    end
    table.sort(players, function(a, b)
        local da, db = a.DisplayName:lower(), b.DisplayName:lower()
        if da == db then
            return a.Name:lower() < b.Name:lower()
        end
        return da < db
    end)
    local labels, labelToUsername, usernameToLabel = {}, {}, {}
    for _, player in ipairs(players) do
        -- Duplicate DisplayNames are safe because @Username is unique.
        local label = string.format("%s (@%s)", player.DisplayName, player.Name)
        table.insert(labels, label)
        labelToUsername[label] = player.Name
        usernameToLabel[player.Name] = label
    end
    if #labels == 0 then
        labels[1] = "No players"
    end
    return labels, labelToUsername, usernameToLabel
end

local function refreshPlayerDropdowns(excludePlayer)
    if not State.Running then return end
    local labels, labelToUsername, usernameToLabel = buildPlayerChoices(excludePlayer)
    CurrentPlayerLabels = labels
    PlayerLabelToUsername = labelToUsername
    PlayerUsernameToLabel = usernameToLabel

    -- Preserve the selected username on join/leave/nickname changes.
    -- If that user left, select the first available player instead.
    if not State.SelectedPlayer or not usernameToLabel[State.SelectedPlayer] then
        State.SelectedPlayer = labelToUsername[labels[1]]
    end
    local selectedLabel = PlayerUsernameToLabel[State.SelectedPlayer] or "No players"
    for _, dropdown in ipairs(PlayerDropdowns) do
        if dropdown then
            dropdown.Value = selectedLabel
            dropdown:Refresh(CurrentPlayerLabels)
        end
    end

    -- Spectate has its own username selection, but shares fresh player labels.
    -- Preserve its selection across nickname changes and player joins.
    if not State.SpectateTarget or not usernameToLabel[State.SpectateTarget] then
        State.SpectateTarget = labelToUsername[labels[1]]
    end
    if SpectatePlayerDropdown then
        SpectatePlayerDropdown.Value = usernameToLabel[State.SpectateTarget] or "No players"
        SpectatePlayerDropdown:Refresh(CurrentPlayerLabels)
    end
end

local function onPlayerDropdownSelected(value)
    local label = tostring(dropdownValue(value) or "")
    local username = PlayerLabelToUsername[label]
    -- Refresh() may invoke the callback; ignore stale/placeholder entries.
    if not username or username == State.SelectedPlayer then return end
    State.SelectedPlayer = username
    local selectedLabel = PlayerUsernameToLabel[username]
    -- Keep Teleport and Fling dropdowns showing the same target.
    for _, dropdown in ipairs(PlayerDropdowns) do
        if dropdown and dropdown.Value ~= selectedLabel then
            dropdown.Value = selectedLabel
            dropdown:Refresh(CurrentPlayerLabels)
        end
    end
end

local function trackPlayerDisplayName(player)
    if player == LocalPlayer or PlayerDisplayConnections[player] then return end
    PlayerDisplayConnections[player] = player:GetPropertyChangedSignal("DisplayName"):Connect(function()
        refreshPlayerDropdowns()
    end)
end

local function stopTrackingPlayerDisplayName(player)
    local connection = PlayerDisplayConnections[player]
    if connection then
        connection:Disconnect()
        PlayerDisplayConnections[player] = nil
    end
end

-- Initialize player data before constructing either dropdown.
refreshPlayerDropdowns()
---------------------------------------------------------------------
-- WALKFLING ENGINE | Based on IY's non-spinning velocity-pulse idea.
-- Walk around naturally: short high-velocity pulses are applied to YOUR root,
-- then cleared on the next frame. Physics replication/target hits vary by game.
-- This is an original integration, not a dependency on Infinite Yield.
---------------------------------------------------------------------
local WalkFlingControl = nil
local WalkFlingRestoreNoClip = false
local WalkFlingEpoch = 0
local function setWalkFling(enabled, quiet)
    enabled = enabled == true
    if enabled == State.WalkFling then return true end
    if enabled and (State.Flinging or State.Fly) then
        if not quiet then notify("Fling", "Disable Fly or finish Fling & Return first") end
        if WalkFlingControl then WalkFlingControl:Set(false, false) end
        return false
    end
    WalkFlingEpoch += 1
    local epoch = WalkFlingEpoch
    State.WalkFling = enabled
    if not enabled then
        -- Preserve a preexisting user-enabled NoClip.
        if not WalkFlingRestoreNoClip and State.NoClip then setNoClip(false) end
        suspendAntiFling(false)
        local root = rootPart()
        if root then
            pcall(function()
                root.AssemblyAngularVelocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
            end)
        end
        if WalkFlingControl then WalkFlingControl:Set(false, false) end
        if not quiet then notify("Fling", "WalkFling OFF; physics restored") end
        return true
    end
    local char = character()
    local root = rootPart()
    local hum = humanoid()
    if not char or not root or root.Anchored or not hum or hum.Health <= 0 then
        State.WalkFling = false
        if WalkFlingControl then WalkFlingControl:Set(false, false) end
        if not quiet then notify("Fling", "Your character must be alive and unanchored") end
        return false
    end
    WalkFlingRestoreNoClip = State.NoClip
    if not State.NoClip then setNoClip(true) end
    suspendAntiFling(true)
    if not quiet then notify("Fling", "WalkFling ON: walk into players; no visible spin") end
    task.spawn(function()
        local phase = 1
        local function live()
            return State.Running and State.WalkFling and WalkFlingEpoch == epoch
                and character() == char and root.Parent and not root.Anchored
                and hum.Parent and hum.Health > 0 and not State.Fly and not State.Flinging
        end
        while live() do
            RunService.Heartbeat:Wait()
            if not live() then break end
            local velocity = root.AssemblyLinearVelocity
            -- Infinite Yield's approach: a brief massive velocity, then restore.
            root.AssemblyLinearVelocity = velocity * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if not live() then break end
            root.AssemblyLinearVelocity = velocity
            RunService.Stepped:Wait()
            if not live() then break end
            phase = -phase
            root.AssemblyLinearVelocity = velocity + Vector3.new(0, phase * 0.1, 0)
        end
        if WalkFlingEpoch == epoch and State.WalkFling then
            setWalkFling(false, true)
        end
    end)
    return true
end

---------------------------------------------------------------------
-- FLING & RETURN v3.4 | WALKFLING-STYLE NO-SPIN CONTACT PULSES
-- Physical contact is client-initiated and game/server dependent.
-- The target position follows live replicated movement; spin is not success.
---------------------------------------------------------------------
local ActiveFlingRestore = nil

local function getFlingTarget(player)
    if not player or player.Parent ~= Players then return nil end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or hum.Health <= 0 or not root or not root.Parent then
        return nil
    end

    -- Keep aiming at the center mass. Find a physical body part, not a hat.
    -- A visible character with no collidable body still may be unflingable.
    local contact = nil
    for _, name in ipairs({"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"}) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") and not part.Anchored and part.CanCollide then
            contact = part
            break
        end
    end
    contact = contact or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
    return char, hum, root, contact
end

local function flingSelectedPlayer()
    if not State.Running or State.Flinging then
        return notify("Fling", "Another fling is active")
    end
    if State.WalkFling then
        return notify("Fling", "Turn off WalkFling before using Fling & Return")
    end
    local player = State.SelectedPlayer and getPlayer(State.SelectedPlayer)
    if not player or player == LocalPlayer then
        return notify("Fling", "Select an available player")
    end
    local originalChar, _, originalRoot = getFlingTarget(player)
    if not originalRoot then
        return notify("Fling", "Target character is not ready")
    end
    if originalRoot.Anchored then
        return notify("Fling", "Target is anchored: physics contact unavailable")
    end

    local mine = character()
    local myHum = humanoid()
    local myRoot = rootPart()
    if not mine or not myHum or myHum.Health <= 0 or not myRoot or myRoot.Anchored then
        return notify("Fling", "Your character is not ready")
    end

    local savedCF = myRoot.CFrame
    local savedPlatformStand = myHum.PlatformStand
    local savedAutoRotate = myHum.AutoRotate
    local savedRootAnchored = myRoot.Anchored
    local savedFlying, savedNoClip = State.Fly, State.NoClip
    local duration = math.clamp(tonumber(State.FlingDuration) or 2.2, 0.6, 6)

    State.Flinging = true
    State.CancelFling = false
    suspendAntiFling(true)
    if savedFlying then setFly(false) end
    -- WalkFling pulses work with the same short-lived NoClip used in IY.
    if not savedNoClip then setNoClip(true) end
    notify("Fling", string.format("WalkFling-style contact: %s | %.1fs max", player.Name, duration))

    task.spawn(function()
        local spinMover, moveMover
        local savedCollisions = {}
        local ended = false
        local result = "Contact attempt finished; server physics decides outcome"
        local closeFrames, contactSeen = 0, false
        local initialPosition = originalRoot.Position
        local startPosition = initialPosition
        local prevObserved = initialPosition
        local previousSample = os.clock()
        local motion = Vector3.zero
        local motionReacted = false
        local lastContact = nil

        local function restore()
            if ended then return end
            ended = true
            State.CancelFling = true
            if spinMover then pcall(function() spinMover:Destroy() end) end
            if moveMover then pcall(function() moveMover:Destroy() end) end
            spinMover, moveMover = nil, nil

            for part, original in pairs(savedCollisions) do
                if part and part.Parent then
                    pcall(function() part.CanCollide = original end)
                end
            end
            table.clear(savedCollisions)
            if character() == mine and mine.Parent and myRoot.Parent and myHum.Parent then
                pcall(function()
                    myRoot.Anchored = true
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                    mine:PivotTo(savedCF)
                    myHum.PlatformStand = savedPlatformStand
                    myHum.AutoRotate = savedAutoRotate
                    if not savedFlying and not savedPlatformStand and myHum.Health > 0 then
                        myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
                -- A brief settling pause prevents left-over momentum after return.
                task.wait(0.08)
                pcall(function()
                    if myRoot.Parent and character() == mine then
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        myRoot.CFrame = savedCF
                        myRoot.Anchored = savedRootAnchored
                    end
                end)
            end
            State.Flinging = false
            ActiveFlingRestore = nil
            suspendAntiFling(false)
            if State.Running and character() == mine then
                setNoClip(savedNoClip)
                if savedFlying then setFly(true) end
            end
        end
        ActiveFlingRestore = restore

        local function sampleMotion(root, now)
            local position = root.Position
            local dt = now - previousSample
            if dt >= 0.035 then
                local delta = position - prevObserved
                -- Reject large replication jumps; otherwise blend recent movement.
                if delta.Magnitude < 6 and dt < 0.25 then
                    local measured = delta / math.max(dt, 0.001)
                    if measured.Magnitude < 85 then
                        motion = motion:Lerp(measured, 0.65)
                    end
                else
                    motion = Vector3.zero
                end
                previousSample = now
                prevObserved = position
            end
            local replicated = root.AssemblyLinearVelocity
            if replicated.Magnitude > 90 then replicated = replicated.Unit * 90 end
            -- Give recently observed translation more weight than network velocity.
            local v = replicated:Lerp(motion, 0.75)
            return Vector3.new(v.X, math.clamp(v.Y, -16, 16), v.Z)
        end

        local ok, err = xpcall(function()
            if ended or not State.Running or State.CancelFling or character() ~= mine then return end

            myHum.PlatformStand = true
            myHum.AutoRotate = false
            myRoot.Anchored = false
            -- Only our physical body is modified. Never modify a target's character.
            for _, partName in ipairs({"HumanoidRootPart", "UpperTorso", "Torso"}) do
                local part = mine:FindFirstChild(partName)
                if part and part:IsA("BasePart") and savedCollisions[part] == nil then
                    savedCollisions[part] = part.CanCollide
                    part.CanCollide = true
                end
            end
            -- No BodyAngularVelocity and no spin: a momentary replicated
            -- velocity impulse is inserted and then cleared each physics cycle.
            myRoot.AssemblyAngularVelocity = Vector3.zero

            local started = os.clock()
            local frame, lastReaction = 0, 0
            local contactOffsets = {
                {along = -0.25, lateral = 0.0, height = -0.05},
                {along =  0.00, lateral = 0.0, height =  0.15},
                {along =  0.05, lateral = 0.35, height = -0.15},
                {along =  0.05, lateral = -0.35, height = -0.15},
                {along =  0.40, lateral = 0.0, height =  0.0},
                {along = -0.30, lateral = 0.25, height = -0.25},
                {along = -0.30, lateral = -0.25, height =  0.25},
            }
            while State.Running and not State.CancelFling and not ended do
                local now = os.clock()
                local elapsed = now - started
                if elapsed >= duration then break end
                if character() ~= mine or not myRoot.Parent or myHum.Health <= 0 then
                    result = "Stopped: your character changed or died"
                    break
                end
                local targetChar, _, theirRoot, contact = getFlingTarget(player)
                if not theirRoot or targetChar ~= originalChar then
                    result = "Stopped: target left, died, or respawned"
                    break
                end
                if theirRoot.Anchored then
                    result = "Stopped: target became anchored"
                    break
                end

                local velocity = sampleMotion(theirRoot, now)
                local flat = Vector3.new(velocity.X, 0, velocity.Z)
                local speed = flat.Magnitude
                local forward = speed > 2.5 and flat.Unit or theirRoot.CFrame.LookVector
                forward = Vector3.new(forward.X, 0, forward.Z)
                forward = forward.Magnitude > 0.02 and forward.Unit or Vector3.new(0, 0, -1)
                local side = Vector3.new(-forward.Z, 0, forward.X)

                -- Walking avatars are already interpolated by Roblox. Small lead
                -- (~0.4-0.8 studs when walking) keeps us in collision range.
                local leadTime = math.clamp(0.025 + speed * 0.0011, 0.025, 0.075)
                local lead = velocity * leadTime
                if lead.Magnitude > 1.4 then lead = lead.Unit * 1.4 end

                -- Keep each lane long enough for a physics-step contact instead
                -- of orbiting around the target with a different offset each frame.
                local lane = math.floor(elapsed / 0.115) % #contactOffsets + 1
                local offset = contactOffsets[lane]
                local body = contact and contact.Parent and contact:IsA("BasePart") and contact or theirRoot
                local center = body.Position
                if (center - theirRoot.Position).Magnitude > 3 then center = theirRoot.Position end
                local goal = center + lead
                    + forward * offset.along
                    + side * offset.lateral
                    + Vector3.new(0, offset.height, 0)
                if (goal - theirRoot.Position).Magnitude > 3.2 then
                    goal = theirRoot.Position + lead + side * offset.lateral
                end

                frame = frame + 1
                -- Keep contact centered on a torso while applying strong angular
                -- force. The old 330-stud/s sideways push threw US out of range.
                myRoot.CFrame = CFrame.new(goal) * savedCF.Rotation
                local frameVelocity = myRoot.AssemblyLinearVelocity
                myRoot.AssemblyAngularVelocity = Vector3.zero
                myRoot.AssemblyLinearVelocity =
                    frameVelocity * 10000 + Vector3.new(0, 10000, 0)
                -- Restore on the next rendering frame, then add a tiny
                -- alternating vertical velocity (IY WalkFling principle).
                RunService.RenderStepped:Wait()
                if ended or State.CancelFling or not State.Running
                    or character() ~= mine or not myRoot.Parent then break end
                myRoot.AssemblyLinearVelocity = frameVelocity
                RunService.Stepped:Wait()
                if ended or State.CancelFling or not State.Running
                    or character() ~= mine or not myRoot.Parent then break end
                myRoot.AssemblyLinearVelocity = frameVelocity
                    + Vector3.new(0, frame % 2 == 0 and 0.1 or -0.1, 0)
                if body.CanCollide then contactSeen = true end
                if (myRoot.Position - theirRoot.Position).Magnitude < 3 then
                    closeFrames = closeFrames + 1
                end

                -- Detect a large observed movement reaction, not server success.
                if elapsed > 0.18 and theirRoot.AssemblyLinearVelocity.Magnitude > 90 then
                    lastReaction = now
                end
                if lastReaction > 0 and now - lastReaction < 0.20
                    and (theirRoot.Position - startPosition).Magnitude > 10 then
                    motionReacted = true
                    result = "Large target movement observed; server outcome unconfirmed"
                    break
                end
                -- RenderStepped/Stepped waits above already pace the pulses.
            end
            if not motionReacted and closeFrames == 0 then
                result = "Could not sustain close contact; check the game's collision rules"
            elseif not motionReacted and not contactSeen then
                result = "Contact range reached, but no collidable target body found"
            end
        end, function(failure)
            return tostring(failure)
        end)
        if not ok then
            result = "Error: " .. tostring(err)
        elseif State.CancelFling and not ended then
            result = "Cancelled"
        end
        restore()
        if State.Running then notify("Fling", result .. " | returned") end
    end)
end

local Mouse = LocalPlayer:GetMouse()
bind(Mouse.Button1Down:Connect(function()
    if not State.ClickTP or State.Flinging then
        return
    end
    local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    if not ctrl then
        return
    end
    teleport(
        CFrame.new(
            Mouse.Hit.Position + Vector3.new(0, 3, 0)
        )
    )
end))
---------------------------------------------------------------------
-- COMBAT: CAMERA AIM ASSIST + OPTIONAL EQUIPPED-TOOL ACTIVATION
-- Only uses publicly visible player positions and standard tool activation.
-- Damage, hit registration and network authority remain game-controlled.
---------------------------------------------------------------------
local Combat = State.Combat
local ESP = State.ESP
local EspViews = {}
local EspGui, FovCircle
local AimRenderName = "SALTY_Combat_Aim_" .. tostring(LocalPlayer.UserId)
local AimBound = false
local EspTime = 0
local EspFrameDt = 1 / 60
local EspCursor = 1
local FovTime = 0
local AIM_SCAN_INTERVAL = 0.24 -- fewer candidate scans per second
local CachedAimPlayer, CachedAimPart
local LastAimScan = -math.huge
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true
-- The roster changes rarely; do not allocate Players:GetPlayers() every aim/ESP tick.
local PlayerRoster = {}
local function refreshPlayerRoster()
    table.clear(PlayerRoster)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            PlayerRoster[#PlayerRoster + 1] = player
        end
    end
end
refreshPlayerRoster()
bind(Players.PlayerAdded:Connect(refreshPlayerRoster))
bind(Players.PlayerRemoving:Connect(function(leaving)
    for index, player in ipairs(PlayerRoster) do
        if player == leaving then
            table.remove(PlayerRoster, index)
            break
        end
    end
end))

local function combatAlive(player)
    local char = player and player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

local function isTeammate(player)
    return LocalPlayer.Team ~= nil and player.Team ~= nil
        and not LocalPlayer.Neutral and not player.Neutral
        and LocalPlayer.Team == player.Team
end

local function makeEspGui()
    if EspGui and EspGui.Parent then return EspGui end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    EspGui = Instance.new("ScreenGui")
    EspGui.Name = "SALTY_CombatESP_v22"
    EspGui.IgnoreGuiInset = true
    EspGui.ResetOnSpawn = false
    EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EspGui.DisplayOrder = 120
    EspGui.Parent = playerGui
    return EspGui
end

local function makeFovCircle()
    if FovCircle and FovCircle.Parent then return FovCircle end
    local parent = makeEspGui()
    if not parent then return nil end
    FovCircle = Instance.new("Frame")
    FovCircle.Name = "AimFOV"
    FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    FovCircle.BackgroundTransparency = 1
    FovCircle.BorderSizePixel = 0
    FovCircle.ZIndex = 4
    FovCircle.Parent = parent
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(1, 0)
    radius.Parent = FovCircle
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromHex("#FFA78D")
    outline.Thickness = 1.5
    outline.Transparency = 0.22
    outline.Parent = FovCircle
    return FovCircle
end

local function updateFovCircle()
    -- Don't create/update a hidden GUI on every idle ESP tick.
    if not (State.Running and Combat.ShowFOV and Combat.Aim) then
        if FovCircle then FovCircle.Visible = false end
        return
    end
    local circle = makeFovCircle()
    local cam = Workspace.CurrentCamera
    if not circle or not cam then return end
    circle.Visible = true
    local width, height = cam.ViewportSize.X, cam.ViewportSize.Y
    local x, y = width * 0.5, height * 0.5
    local radius = Combat.FOV * 2
    if circle.Position.X.Offset ~= x or circle.Position.Y.Offset ~= y then
        circle.Position = UDim2.fromOffset(x, y)
    end
    if circle.Size.X.Offset ~= radius then
        circle.Size = UDim2.fromOffset(radius, radius)
    end
end

local function combatCanTarget(player, camera, checkFov, skipWalls)
    if player == LocalPlayer or not player or not player.Parent then return nil end
    if Combat.TeamCheck and isTeammate(player) then return nil end
    local char, hum, root = combatAlive(player)
    if not char or not hum or hum.Health <= 0 or not root then return nil end
    local myRoot = rootPart()
    if not myRoot or (root.Position - myRoot.Position).Magnitude > Combat.MaxDistance then return nil end
    local targetPart = char:FindFirstChild(Combat.Part) or char:FindFirstChild("Head") or root
    if not targetPart:IsA("BasePart") then return nil end
    local point = targetPart.Position
    local screenPoint, inFront = camera:WorldToViewportPoint(point)
    if not inFront or screenPoint.Z <= 0 then return nil end
    local center = camera.ViewportSize / 2
    local deviation = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
    if checkFov and deviation > Combat.FOV then return nil end
    if Combat.WallCheck and not skipWalls then
        RayParams.FilterDescendantsInstances = { character(), char }
        local offset = point - camera.CFrame.Position
        local hit = Workspace:Raycast(camera.CFrame.Position, offset, RayParams)
        if hit then return nil end
    end
    return targetPart, deviation, (root.Position - myRoot.Position).Magnitude, root
end

local function nearestCombatTarget(camera)
    if Combat.Priority == "Selected player" then
        local selected = State.SelectedPlayer and getPlayer(State.SelectedPlayer)
        local part = selected and combatCanTarget(selected, camera, false)
        return part and selected or nil, part
    end

    -- Project every candidate once, but only raycast the best candidates.
    -- Previously this ran a separate raycast for every player on EVERY frame.
    local candidates = {}
    for _, player in ipairs(PlayerRoster) do
        local part, delta, distance = combatCanTarget(player, camera, true, true)
        if part then
            candidates[#candidates + 1] = {
                Player = player,
                Score = Combat.Priority == "Closest to character" and distance or delta,
            }
        end
    end
    table.sort(candidates, function(a, b) return a.Score < b.Score end)
    for _, candidate in ipairs(candidates) do
        local part = combatCanTarget(candidate.Player, camera, true)
        if part then return candidate.Player, part end
    end
    return nil, nil
end

local function resetCombatTargetCache()
    CachedAimPlayer, CachedAimPart = nil, nil
    LastAimScan = -math.huge
end

local function updateCombat(dt)
    if not State.Running or not Combat.Aim or State.Flinging then return end
    local active = Combat.Aiming or Combat.LockHeld
    if not active then return end
    local camera = Workspace.CurrentCamera
    if not camera or camera.CameraType == Enum.CameraType.Scriptable then return end

    local now = os.clock()
    if now - LastAimScan >= AIM_SCAN_INTERVAL then
        LastAimScan = now
        if Combat.LockHeld then
            local locked = Combat.LockedPlayer
            local part = locked and combatCanTarget(locked, camera, false)
            CachedAimPlayer, CachedAimPart = part and locked or nil, part
            if not part then
                Combat.LockHeld = false
                Combat.LockedPlayer = nil
            end
        else
            CachedAimPlayer, CachedAimPart = nearestCombatTarget(camera)
        end
    end
    local targetPart = CachedAimPart
    if not (targetPart and targetPart.Parent) then return end
    local target = CachedAimPlayer
    local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local predicted = targetPart.Position
    if root and root:IsA("BasePart") then
        predicted = predicted + root.AssemblyLinearVelocity * 0.027
    end
    local cameraCf = camera.CFrame
    if (predicted - cameraCf.Position).Magnitude > 0.01 then
        local desired = CFrame.lookAt(cameraCf.Position, predicted)
        camera.CFrame = cameraCf:Lerp(desired, math.clamp(Combat.Smoothness * dt, 0, 1))
    end
end

local function setCombatAim(value)
    Combat.Aim = value == true
    resetCombatTargetCache()
    if not Combat.Aim then
        Combat.Aiming = false
        Combat.LockHeld = false
        Combat.LockedPlayer = nil
        if AimBound then
            RunService:UnbindFromRenderStep(AimRenderName)
            AimBound = false
        end
    elseif not AimBound then
        RunService:BindToRenderStep(AimRenderName, Enum.RenderPriority.Camera.Value + 10, updateCombat)
        AimBound = true
    end
    updateFovCircle()
end

local function toggleCombatLock()
    if not Combat.Aim then return end
    if Combat.LockHeld then
        Combat.LockHeld = false
        Combat.LockedPlayer = nil
        notify("Combat", "Target lock released")
        return
    end
    local camera = Workspace.CurrentCamera
    local player = camera and nearestCombatTarget(camera)
    if player then
        Combat.LockedPlayer = player
        Combat.LockHeld = true
        resetCombatTargetCache()
        notify("Combat", "Locked: " .. player.DisplayName .. " (@" .. player.Name .. ")")
    else
        notify("Combat", "No valid target in range / line of sight")
    end
end

bind(UserInputService.InputBegan:Connect(function(input, processed)
    if not State.Running or processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Combat.Aiming = true
    elseif input.KeyCode == Enum.KeyCode.Q then
        toggleCombatLock()
    end
end))
bind(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Combat.Aiming = false end
end))

-- The camera render callback is bound only while Aim Assist is enabled.

-- Equipped Tool:Activate() is the only cross-game attack API available.
-- Some experiences require game-specific server requests; those are not faked.
local function tickCombatTool()
    if not State.Running or not Combat.AutoUseTool or not Combat.Aim or State.Flinging then return end
    if not (Combat.Aiming or Combat.LockHeld) then return end
    if os.clock() - Combat.LastAttack < 0.22 then return end
    local target = Combat.LockHeld and Combat.LockedPlayer or CachedAimPlayer
    if not target or not target.Parent then return end
    local _, _, targetRoot = combatAlive(target)
    local ownRoot = rootPart()
    if not targetRoot or not ownRoot or (targetRoot.Position - ownRoot.Position).Magnitude > Combat.UseRange then return end
    local char = character()
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        Combat.LastAttack = os.clock()
        pcall(function() tool:Activate() end)
    end
end

---------------------------------------------------------------------
-- PLAYER ESP: CHAMS, NAME TAGS, HEALTH, DISTANCES, BOXES & TRACERS
-- Local visuals only. Never modifies other players' characters or damage.
---------------------------------------------------------------------
local function destroyEspView(player)
    local view = EspViews[player]
    if not view then return end
    -- Destroy ONLY our own visuals. Never destroy view.Character or player parts.
    for _, key in ipairs({ "Highlight", "Billboard", "Box", "Tracer" }) do
        local object = view[key]
        if object then pcall(function() object:Destroy() end) end
    end
    EspViews[player] = nil
end

local function clearEspViews()
    for player in pairs(EspViews) do destroyEspView(player) end
end

local function espColor(player)
    if ESP.TeamColors and player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return ESP.Color
end

local function getEspView(player, char, head, root)
    local view = EspViews[player]
    if view and view.Character ~= char then
        destroyEspView(player)
        view = nil
    end
    if not view then
        view = {Character = char}
        EspViews[player] = view
    end
    -- Allocate only the visuals in use. Highlights are costly on busy servers.
    if ESP.Chams then
        if not view.Highlight then
            local glow = Instance.new("Highlight")
            glow.Name = "SALTY_Chams_" .. player.UserId
            glow.Adornee = char
            glow.FillTransparency = 0.75
            glow.OutlineTransparency = 0.15
            glow.Parent = Workspace
            view.Highlight = glow
        end
    elseif view.Highlight then
        view.Highlight:Destroy()
        view.Highlight = nil
    end

    if ESP.Names or ESP.Distances or ESP.Health then
        if not view.Billboard then
            local gui = Instance.new("BillboardGui")
            gui.Name = "SALTY_Names_" .. player.UserId
            gui.Adornee = head or root
            gui.Size = UDim2.fromOffset(225, 46)
            gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.LightInfluence = 0
            gui.ResetOnSpawn = false
            gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            view.Billboard = gui
            local name = Instance.new("TextLabel")
            name.Name = "PlayerName"
            name.Size = UDim2.new(1, 0, 0, 23)
            name.BackgroundTransparency = 1
            name.TextSize = 14
            name.Font = Enum.Font.GothamBold
            name.TextStrokeColor3 = Color3.new(0, 0, 0)
            name.TextStrokeTransparency = 0.25
            name.Parent = gui
            view.NameLabel = name
            local stats = Instance.new("TextLabel")
            stats.Name = "PlayerStats"
            stats.Position = UDim2.new(0, 0, 0, 21)
            stats.Size = UDim2.new(1, 0, 0, 20)
            stats.BackgroundTransparency = 1
            stats.TextSize = 12
            stats.Font = Enum.Font.GothamMedium
            stats.TextColor3 = Color3.fromRGB(239, 239, 239)
            stats.TextStrokeColor3 = Color3.new(0, 0, 0)
            stats.TextStrokeTransparency = 0.35
            stats.Parent = gui
            view.StatLabel = stats
        end
    elseif view.Billboard then
        view.Billboard:Destroy()
        view.Billboard = nil
        view.NameLabel = nil
        view.StatLabel = nil
    end

    if ESP.Boxes then
        if not view.Box then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "SALTY_Box_" .. player.UserId
            box.Adornee = root
            box.Size = Vector3.new(4, 6, 2.7)
            box.CFrame = CFrame.new(0, 0.3, 0)
            box.AlwaysOnTop = true
            box.Transparency = 0.82
            box.Parent = Workspace
            view.Box = box
        end
    elseif view.Box then
        view.Box:Destroy()
        view.Box = nil
    end
    if ESP.Tracers then
        if not view.Tracer then
            local tracer = Instance.new("Frame")
            tracer.Name = "SALTY_Tracer_" .. player.UserId
            tracer.BorderSizePixel = 0
            tracer.AnchorPoint = Vector2.new(0.5, 0.5)
            tracer.BackgroundTransparency = 0.18
            tracer.ZIndex = 3
            tracer.Parent = makeEspGui()
            view.Tracer = tracer
        end
    elseif view.Tracer then
        view.Tracer:Destroy()
        view.Tracer = nil
    end
    return view
end

local function hideEspView(player)
    local view = EspViews[player]
    if not view then return end
    if view.Highlight then view.Highlight.Enabled = false end
    if view.Box then view.Box.Visible = false end
    if view.Billboard then view.Billboard.Enabled = false end
    if view.Tracer then view.Tracer.Visible = false end
end

local function updateEspView(player, camera, ownRoot)
    if player == LocalPlayer or not player.Parent then destroyEspView(player); return end
    if ESP.TeamCheck and isTeammate(player) then hideEspView(player); return end
    local char, hum, root = combatAlive(player)
    if not char or not root or not hum or hum.Health <= 0 then destroyEspView(player); return end
    if not ownRoot then hideEspView(player); return end
    local distance = (root.Position - ownRoot.Position).Magnitude
    if distance > ESP.MaxDistance then hideEspView(player); return end
    local view = getEspView(player, char, char:FindFirstChild("Head"), root)
    local color = espColor(player)
    if view.Highlight then
        if not view.Highlight.Enabled then view.Highlight.Enabled = true end
        if view.Highlight.FillColor ~= color then view.Highlight.FillColor = color end
        if view.Highlight.OutlineColor ~= color then view.Highlight.OutlineColor = color end
        local depth = ESP.Xray and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        if view.Highlight.DepthMode ~= depth then view.Highlight.DepthMode = depth end
    end
    if view.Box then
        if not view.Box.Visible then view.Box.Visible = true end
        if view.Box.Color3 ~= color then view.Box.Color3 = color end
    end
    if view.Billboard then
        if not view.Billboard.Enabled then view.Billboard.Enabled = true end
        if view.NameLabel.Visible ~= ESP.Names then view.NameLabel.Visible = ESP.Names end
        if ESP.Names then
            if view.NameLabel.TextColor3 ~= color then view.NameLabel.TextColor3 = color end
            local name = player.DisplayName .. " (@" .. player.Name .. ")"
            if view.NameLabel.Text ~= name then view.NameLabel.Text = name end
        end
        view.StatLabel.Visible = ESP.Distances or ESP.Health
        if ESP.Distances or ESP.Health then
            local details = ""
            if ESP.Distances then details = tostring(math.floor(distance + 0.5)) .. " studs" end
            if ESP.Health then
                local health = string.format("%d / %d HP", math.max(0, math.floor(hum.Health)), math.floor(hum.MaxHealth))
                details = details ~= "" and (details .. "  |  " .. health) or health
            end
            if view.StatLabel.Text ~= details then view.StatLabel.Text = details end
        end
    end
    if view.Tracer then
        view.Tracer.Visible = false
        if camera then
            local loc, visible = camera:WorldToViewportPoint(root.Position)
            if visible and loc.Z > 0 then
                local start = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y - 16)
                local target = Vector2.new(loc.X, loc.Y)
                local delta = target - start
                view.Tracer.Visible = true
                if view.Tracer.BackgroundColor3 ~= color then view.Tracer.BackgroundColor3 = color end
                view.Tracer.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
                view.Tracer.Position = UDim2.fromOffset((start.X + target.X) / 2, (start.Y + target.Y) / 2)
                view.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            end
        end
    end
end

local function setEspEnabled(value)
    ESP.Enabled = value == true
    if not ESP.Enabled then clearEspViews() end
end

bind(Players.PlayerRemoving:Connect(function(player)
    destroyEspView(player)
    if Combat.LockedPlayer == player then
        Combat.LockedPlayer = nil
        Combat.LockHeld = false
    end
end))

bind(RunService.Heartbeat:Connect(function(dt)
    if not State.Running then return end
    -- Slow EWMA; avoids one-off hitches causing the ESP scheduler to oscillate.
    EspFrameDt = EspFrameDt * 0.95 + math.min(dt, 0.10) * 0.05
    -- The expensive ESP scan is never run when disabled. Scale its cadence
    -- down on crowded servers; leave combat rendering independent.
    if Combat.AutoUseTool then tickCombatTool() end
    EspTime = EspTime + dt
    FovTime = FovTime + dt
    if FovTime >= 0.22 then
        FovTime = 0
        if Combat.ShowFOV and Combat.Aim then updateFovCircle() end
    end
    if not ESP.Enabled then return end
    local total = #PlayerRoster
    if total == 0 then return end
    -- Update at a fixed budget; low FPS and crowded servers automatically
    -- reduce work. Never update all labels or highlights in one frame.
    local mode = ESP.Quality
    local interval = mode == "Fast" and 0.10 or mode == "Balanced" and 0.18 or 0.30
    local batch = mode == "Fast" and 4 or mode == "Balanced" and 3 or 2
    if total > 16 then interval = interval * 1.4 end
    if total > 35 then interval = interval * 1.5 end
    if EspFrameDt > (1 / 42) then interval = interval * 1.55 end
    if EspTime < interval then return end
    EspTime = 0
    local camera = Workspace.CurrentCamera
    local ownRoot = rootPart()
    for _ = 1, math.min(batch, total) do
        if EspCursor > total then EspCursor = 1 end
        local player = PlayerRoster[EspCursor]
        EspCursor = EspCursor + 1
        if player then updateEspView(player, camera, ownRoot) end
    end
end))

---------------------------------------------------------------------
-- Compiler-safe scope: Obsidian features and all UI controls are initialized
-- inside a dedicated function. Luau's register limit is per function; the
-- former monolithic top-level scope exceeded 200 registers at profileNames.
-- Keeping the related UI and cleanup in this function preserves upvalues.
---------------------------------------------------------------------
local function initializeObsidian()
---------------------------------------------------------------------
-- OBSIDIAN v3.3 | MOVEMENT + CAMERA + SAFETY
-- Features are client-side, subject to the experience's physics rules.
-- No unverified server calls are made by these modules.
---------------------------------------------------------------------
local ProfileControls, uiSet -- shared by movement/camera callbacks and UI, defined later
local function characterReady()
    local root, hum = rootPart(), humanoid()
    if not root or not hum or hum.Health <= 0 or not root.Parent then return nil end
    return root, hum
end

-- Air Walk: one locally-created anchored collision plane; fixed initial Y.
local AirPlane, AirPlaneConnection, AirPlaneHeight
local function setAirWalk(enabled)
    enabled = enabled == true
    if not enabled then
        State.AirWalk = false
        if AirPlaneConnection then AirPlaneConnection:Disconnect(); AirPlaneConnection = nil end
        if AirPlane then AirPlane:Destroy(); AirPlane = nil end
        AirPlaneHeight = nil
        return
    end
    if State.Flinging or State.Fly then
        notify("Movement", "Turn off Fly / finish Fling to use Air Walk")
        return false
    end
    local root, hum = characterReady()
    if not root then notify("Movement", "Character isn't ready for Air Walk"); return false end
    if not AirPlane then
        AirPlane = Instance.new("Part")
        AirPlane.Name = "SALTY_Obsidian_AirWalk"
        AirPlane.Size = Vector3.new(State.AirWalkSize, 0.7, State.AirWalkSize)
        AirPlane.Transparency = 1
        AirPlane.Anchored = true
        AirPlane.CanCollide = true
        AirPlane.CanTouch = false
        AirPlane.CanQuery = false
        AirPlane.CastShadow = false
        AirPlane.Parent = Workspace
    end
    AirPlaneHeight = root.Position.Y - (hum.HipHeight + root.Size.Y/2 + AirPlane.Size.Y/2 + 0.12)
    AirPlane.CFrame = CFrame.new(root.Position.X, AirPlaneHeight, root.Position.Z)
    State.AirWalk = true
    if not AirPlaneConnection then
        AirPlaneConnection = RunService.Stepped:Connect(function()
            if not State.Running or not State.AirWalk then return end
            if State.Fly or State.Flinging then
                setAirWalk(false)
                if ProfileControls then uiSet("AirWalk", false, false) end
                return
            end
            local r = rootPart()
            if r and AirPlane and AirPlane.Parent then
                AirPlane.CFrame = CFrame.new(r.Position.X, AirPlaneHeight, r.Position.Z)
            end
        end)
    end
    return true
end

local function dash()
    if not State.Running or State.Flinging or State.Fly or State.Freecam or State.Spectating then
        return notify("Dash", "Dash is unavailable during Fly, Fling or camera modes")
    end
    local root, hum = characterReady()
    if not root or hum.PlatformStand or hum.Sit then return end
    local now = os.clock()
    local remaining = State.DashCooldown - (now - State.DashLast)
    if remaining > 0 then return end
    local dir = hum.MoveDirection
    if dir.Magnitude < 0.12 then
        local cam = Workspace.CurrentCamera
        dir = cam and cam.CFrame.LookVector or root.CFrame.LookVector
    end
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.001 then return end
    State.DashLast = now
    local current = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = dir.Unit * State.DashPower + Vector3.new(0, math.max(current.Y, 0), 0)
end

-- Anti-Void remembers a *grounded* location; never guesses a spawn point.
local SafeGroundCFrame, LastGroundSample, LastVoidRecovery = nil, 0, 0
bind(RunService.Heartbeat:Connect(function()
    if not State.Running or not State.AntiVoid or State.Flinging then return end
    local root, hum = characterReady()
    if not root then return end
    local now = os.clock()
    if now - LastGroundSample < 0.16 then return end
    LastGroundSample = now
    if not State.Fly and hum.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Y > -8 then
        SafeGroundCFrame = root.CFrame
        return
    end
    if State.Fly or not SafeGroundCFrame or now - LastVoidRecovery < 2 then return end
    local dangerous = Workspace.FallenPartsDestroyHeight + State.AntiVoidOffset
    if root.Position.Y <= dangerous and SafeGroundCFrame.Position.Y > dangerous + 10 then
        LastVoidRecovery = now
        local cf = SafeGroundCFrame + Vector3.new(0, 3, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local char = character()
        if char then char:PivotTo(cf) end
        notify("Protection", "Anti-Void returned to your last grounded position")
    end
end))

-- Spectate uses a real player's humanoid and restores the local camera.
local SpectateCamera, SpectateSaved, SpectatePlayer
local function stopSpectate(quiet)
    State.Spectating = false
    SpectatePlayer = nil
    if SpectateSaved and SpectateCamera and SpectateCamera.Parent then
        local saved, camera = SpectateSaved, SpectateCamera
        pcall(function()
            camera.CameraSubject = saved.Subject or humanoid()
            camera.CameraType = saved.Type
            camera.CFrame = saved.CFrame
        end)
    end
    SpectateSaved, SpectateCamera = nil, nil
    if ProfileControls then uiSet("Spectate", false, false) end
    if not quiet then notify("Camera", "Spectate stopped") end
end
local setFreecam -- forward declaration for camera mode exclusivity
local function startSpectate()
    if State.Flinging then return notify("Camera", "Wait until Fling has finished") end
    local player = State.SpectateTarget and getPlayer(State.SpectateTarget)
    local targetHum = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local camera = Workspace.CurrentCamera
    if not targetHum or targetHum.Health <= 0 or not camera then
        return notify("Camera", "Choose a player with a living character")
    end
    if State.Freecam and setFreecam then
        setFreecam(false)
        if ProfileControls then uiSet("Freecam", false, false) end
    end
    if State.ForceThirdPerson then
        setForceThirdPerson(false)
        if ProfileControls then uiSet("ThirdPerson", false, false) end
    end
    if State.Spectating then stopSpectate(true) end
    SpectateCamera = camera
    SpectateSaved = {Type = camera.CameraType, Subject = camera.CameraSubject, CFrame = camera.CFrame}
    SpectatePlayer = player
    State.Spectating = true
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = targetHum
    notify("Camera", "Spectating " .. player.DisplayName .. " (@" .. player.Name .. ")")
end

local function onSpectatePlayerSelected(value)
    local username = PlayerLabelToUsername[tostring(dropdownValue(value) or "")]
    -- Dropdown:Refresh() can invoke callbacks; ignore unchanged/placeholder values.
    if not username or username == State.SpectateTarget then return end
    State.SpectateTarget = username

    -- Switch the current camera subject without replacing the original saved view.
    if State.Spectating then
        local selected = getPlayer(username)
        local subject = selected and selected.Character and selected.Character:FindFirstChildOfClass("Humanoid")
        local camera = Workspace.CurrentCamera
        if not subject or subject.Health <= 0 or not camera then
            stopSpectate()
            return notify("Camera", "Selected player's character is unavailable")
        end
        if camera ~= SpectateCamera then
            SpectateSaved = {Type = camera.CameraType, Subject = camera.CameraSubject, CFrame = camera.CFrame}
            SpectateCamera = camera
        end
        SpectatePlayer = selected
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = subject
        notify("Camera", "Now spectating " .. selected.DisplayName .. " (@" .. selected.Name .. ")")
    end
end

bind(Players.PlayerRemoving:Connect(function(player)
    if State.Spectating and SpectatePlayer == player then stopSpectate() end
end))
bind(RunService.Heartbeat:Connect(function()
    if not State.Running or not State.Spectating then return end
    local p = SpectatePlayer
    if not p or p.Parent ~= Players then stopSpectate(); return end
    local currentHum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local cam = Workspace.CurrentCamera
    if not currentHum or currentHum.Health <= 0 or not cam then
        -- Players can respawn; wait briefly instead of binding to a dead humanoid.
        if not currentHum then return end
        stopSpectate(); return
    end
    if cam ~= SpectateCamera then
        SpectateSaved = {Type = cam.CameraType, Subject = cam.CameraSubject, CFrame = cam.CFrame}
        SpectateCamera = cam
    end
    if cam.CameraSubject ~= currentHum then cam.CameraSubject = currentHum end
    if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
end))

-- Freecam: inertial navigation (WASD/Space/Ctrl), RMB-look, Shift boost.
local FreecamRenderName = "SALTY_Obsidian_Freecam_" .. tostring(LocalPlayer.UserId)
local FreecamCamera, FreecamSaved, FreecamLocation, FreecamYaw, FreecamPitch
local FreecamVelocity = Vector3.zero
local FreecamBound = false
local function stopFreecam(quiet)
    State.Freecam = false
    if FreecamBound then
        RunService:UnbindFromRenderStep(FreecamRenderName)
        FreecamBound = false
    end
    if FreecamSaved and FreecamCamera and FreecamCamera.Parent then
        local saved, cam = FreecamSaved, FreecamCamera
        pcall(function()
            cam.CameraSubject = saved.Subject
            cam.CameraType = saved.Type
            cam.FieldOfView = saved.FOV
            cam.CFrame = saved.CFrame
            UserInputService.MouseBehavior = saved.MouseBehavior
            UserInputService.MouseIconEnabled = saved.MouseIconEnabled
        end)
    end
    FreecamSaved, FreecamCamera, FreecamLocation, FreecamYaw, FreecamPitch = nil, nil, nil, nil, nil
    FreecamVelocity = Vector3.zero
    if ProfileControls then uiSet("Freecam", false, false) end
    if not quiet then notify("Camera", "Freecam stopped and camera restored") end
end
setFreecam = function(enabled)
    enabled = enabled == true
    if not enabled then stopFreecam(); return true end
    if State.Flinging then
        notify("Camera", "Finish the current fling before Freecam")
        return false
    end
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    if State.Freecam then return true end
    if State.Spectating then
        stopSpectate(true)
        if ProfileControls then uiSet("Spectate", false, false) end
    end
    if State.ForceThirdPerson then
        setForceThirdPerson(false)
        if ProfileControls then uiSet("ThirdPerson", false, false) end
    end
    if Combat.Aim then
        setCombatAim(false)
        if ProfileControls then uiSet("AimAssist", false, false) end
    end
    if State.Fly then
        setFly(false)
        if ProfileControls then uiSet("Fly", false, false) end
    end
    FreecamCamera = cam
    FreecamSaved = {
        Type = cam.CameraType, Subject = cam.CameraSubject, CFrame = cam.CFrame,
        FOV = cam.FieldOfView, MouseBehavior = UserInputService.MouseBehavior,
        MouseIconEnabled = UserInputService.MouseIconEnabled,
    }
    FreecamLocation = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    FreecamPitch = math.asin(math.clamp(look.Y, -0.999, 0.999))
    FreecamYaw = math.atan2(-look.X, -look.Z)
    FreecamVelocity = Vector3.zero
    State.Freecam = true
    cam.CameraType = Enum.CameraType.Scriptable
    cam.FieldOfView = State.FreecamFOV
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    if not FreecamBound then
        FreecamBound = true
        RunService:BindToRenderStep(FreecamRenderName, Enum.RenderPriority.Last.Value + 20, function(dt)
            if not State.Running or not State.Freecam then return end
            local camera = Workspace.CurrentCamera
            if not camera then return end
            if camera ~= FreecamCamera then
                -- An experience can replace CurrentCamera while freecam is active.
                FreecamCamera = camera
            end
            if camera.CameraType ~= Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Scriptable
            end
            if UserInputService:GetFocusedTextBox() then return end
            dt = math.clamp(dt, 0.001, 0.05)
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local delta = UserInputService:GetMouseDelta()
                FreecamYaw = FreecamYaw - delta.X * 0.0026
                FreecamPitch = math.clamp(FreecamPitch - delta.Y * 0.0026, -1.51, 1.51)
            end
            local rot = CFrame.fromOrientation(FreecamPitch, FreecamYaw, 0)
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += rot.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= rot.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= rot.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += rot.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then direction -= Vector3.yAxis end
            if direction.Magnitude > 0 then direction = direction.Unit end
            local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
            local wanted = direction * State.FreecamSpeed * (boosting and 2.8 or 1)
            FreecamVelocity = FreecamVelocity:Lerp(wanted, math.clamp(dt * 9, 0, 1))
            FreecamLocation += FreecamVelocity * dt
            camera.FieldOfView = State.FreecamFOV
            camera.CFrame = CFrame.new(FreecamLocation) * rot
            camera.Focus = camera.CFrame + camera.CFrame.LookVector * 12
        end)
    end
    notify("Camera", "Freecam ON: WASD + Space/Ctrl, RMB look, Shift boost")
    return true
end

---------------------------------------------------------------------
-- OBSIDIAN SETTINGS STORE | graceful session-only mode if FS unavailable.
---------------------------------------------------------------------
local StorePath = "SALTY_Player_Hub/Obsidian_v3.3.json"
local Store = {version = 1, profiles = {}, waypoints = {}, bindings = {
    Dash = "X", Freecam = "V", ["Air Walk"] = "G", Spectate = "B", Panic = "BackSlash",
}}
local StoreWritable = type(writefile) == "function"
local function persistStore()
    if not StoreWritable then return false end
    local ok = pcall(function()
        if type(makefolder) == "function" then
            if type(isfolder) ~= "function" or not isfolder("SALTY_Player_Hub") then
                makefolder("SALTY_Player_Hub")
            end
        end
        writefile(StorePath, HttpService:JSONEncode(Store))
    end)
    return ok
end
if type(readfile) == "function" then
    pcall(function()
        if type(isfile) ~= "function" or isfile(StorePath) then
            local decoded = HttpService:JSONDecode(readfile(StorePath))
            if type(decoded) == "table" and decoded.version == 1 then
                if type(decoded.profiles) == "table" then Store.profiles = decoded.profiles end
                if type(decoded.waypoints) == "table" then Store.waypoints = decoded.waypoints end
                if type(decoded.bindings) == "table" then
                    for action in pairs(Store.bindings) do
                        local key = decoded.bindings[action]
                        if type(key) == "string" and (key == "None" or Enum.KeyCode[key] ~= nil) then
                            Store.bindings[action] = key
                        end
                    end
                end
            end
        end
    end)
end
ProfileControls = {}
local function trackSetting(name, control)
    ProfileControls[name] = control
    return control
end
uiSet = function(name, value, callback)
    local control = ProfileControls[name]
    if not control then return end
    pcall(function() control:Set(value, callback) end)
end
local function validLabel(label)
    label = tostring(label or ""):gsub("[%c/\\]", ""):sub(1, 32)
    label = label:match("^%s*(.-)%s*$")
    return label
end
local function cfFromNumbers(raw)
    if type(raw) ~= "table" or #raw ~= 12 then return nil end
    for _, n in ipairs(raw) do
        if type(n) ~= "number" or n ~= n or math.abs(n) > 1e9 then return nil end
    end
    local ok, cf = pcall(function() return CFrame.new(table.unpack(raw)) end)
    return ok and cf or nil
end
local function cfNumbers(cf)
    return {cf:GetComponents()}
end
local SelectedWaypoint, WaypointDropdown, WaypointName = nil, nil, ""
local function waypointNames()
    local values = {}
    for name, raw in pairs(Store.waypoints) do
        if type(name) == "string" and cfFromNumbers(raw) then
            table.insert(values, name)
        end
    end
    table.sort(values)
    if #values == 0 then values[1] = "No waypoints" end
    return values
end
local function refreshWaypoints()
    local names = waypointNames()
    if not Store.waypoints[SelectedWaypoint] then
        SelectedWaypoint = names[1] ~= "No waypoints" and names[1] or nil
    end
    if WaypointDropdown then
        WaypointDropdown.Value = SelectedWaypoint or "No waypoints"
        WaypointDropdown:Refresh(names)
    end
end
local function saveWaypoint()
    local root = rootPart()
    if not root then return notify("Waypoints", "Character not ready") end
    local label = validLabel(WaypointName)
    if label == "" then label = "Waypoint " .. tostring(#waypointNames()) end
    local count = 0
    for _ in pairs(Store.waypoints) do count += 1 end
    if not Store.waypoints[label] and count >= 40 then
        return notify("Waypoints", "Maximum 40 waypoints; delete one first")
    end
    Store.waypoints[label] = cfNumbers(root.CFrame)
    SelectedWaypoint = label
    refreshWaypoints()
    notify("Waypoints", "Saved " .. label .. (persistStore() and " • on disk" or " • this session"))
end
local function gotoWaypoint()
    local cf = SelectedWaypoint and cfFromNumbers(Store.waypoints[SelectedWaypoint])
    if not cf then return notify("Waypoints", "Select a saved waypoint") end
    if teleport(cf + Vector3.new(0, 2, 0)) then
        notify("Waypoints", "Teleported to " .. SelectedWaypoint)
    end
end
local function deleteWaypoint()
    if not SelectedWaypoint or not Store.waypoints[SelectedWaypoint] then return end
    local label = SelectedWaypoint
    Store.waypoints[label] = nil
    SelectedWaypoint = nil
    refreshWaypoints()
    persistStore()
    notify("Waypoints", "Deleted " .. label)
end

local BoundActions = {"Dash", "Freecam", "Air Walk", "Spectate", "Panic"}
local BindableKeys = {"None", "B", "G", "H", "J", "K", "L", "M", "N", "P", "T", "V", "X", "Y", "Z", "BackSlash"}
local BindAction, BindKey = "Dash", Store.bindings.Dash
local function panicStop()
    -- Stop active actions and restore camera / collisions in a safe order.
    State.CancelFling = true
    if State.WalkFling then setWalkFling(false, true) end
    if ActiveFlingRestore then pcall(ActiveFlingRestore) end
    if State.Freecam then stopFreecam(true) end
    if State.Spectating then stopSpectate(true) end
    setAirWalk(false)
    setFly(false)
    State.InfiniteJump = false
    setSpeedEnabled(false)
    setNoClip(false)
    setCombatAim(false)
    Combat.AutoUseTool = false
    Combat.LockHeld = false
    Combat.LockedPlayer = nil
    Combat.ShowFOV = false
    updateFovCircle()
    setEspEnabled(false)
    ESP.Enabled = false
    clearEspViews()
    setFullBright(false)
    State.AntiVoid = false
    setForceThirdPerson(false)
    setUnlockMouse(false)
    -- Update the controls users can see (no callback re-entry).
    for _, key in ipairs({"Fly", "InfiniteJump", "Speed", "NoClip", "AirWalk", "AntiVoid",
        "Spectate", "Freecam", "ThirdPerson", "UnlockMouse", "AimAssist", "FullBright",
        "ESP", "AutoUseTool", "ShowFOV"}) do
        uiSet(key, false, false)
    end
    notify("Obsidian", "Panic stop: movement, camera, aim and visuals restored")
end
local function activateBinding(action)
    if action == "Dash" then dash()
    elseif action == "Freecam" then
        setFreecam(not State.Freecam)
        uiSet("Freecam", State.Freecam, false)
    elseif action == "Air Walk" then
        local enabled = setAirWalk(not State.AirWalk)
        if enabled ~= false then uiSet("AirWalk", State.AirWalk, false) end
    elseif action == "Spectate" then
        if State.Spectating then stopSpectate() else startSpectate() end
        uiSet("Spectate", State.Spectating, false)
    elseif action == "Panic" then panicStop()
    end
end
bind(UserInputService.InputBegan:Connect(function(input, processed)
    if not State.Running or processed or UserInputService:GetFocusedTextBox() then return end
    for _, action in ipairs(BoundActions) do
        local key = Store.bindings[action]
        if key ~= "None" and Enum.KeyCode[key] and input.KeyCode == Enum.KeyCode[key] then
            activateBinding(action)
            break
        end
    end
end))
local function assignKeybind()
    if not Enum.KeyCode[BindKey] and BindKey ~= "None" then return end
    local old = Store.bindings[BindAction]
    if BindKey ~= "None" then
        for action, key in pairs(Store.bindings) do
            if action ~= BindAction and key == BindKey then
                return notify("Keybinds", BindKey .. " already belongs to " .. action)
            end
        end
    end
    Store.bindings[BindAction] = BindKey
    local disk = persistStore()
    notify("Keybinds", BindAction .. ": " .. old .. " → " .. BindKey .. (disk and " (saved)" or " (session)"))
end

local ProfileKeys = {"FlySpeed", "InfiniteJump", "Speed", "WalkSpeed", "NoClip", "AntiFling",
    "ThirdPersonDistance", "AirWalkSize", "DashPower", "DashCooldown", "AntiVoid", "AntiVoidOffset",
    "FreecamSpeed", "FreecamFOV", "FullBright"}
local function captureProfile()
    local snapshot = {}
    for _, key in ipairs(ProfileKeys) do snapshot[key] = State[key] end
    snapshot.bindings = table.clone(Store.bindings)
    return snapshot
end
local SelectedProfile, ProfileName, ProfileDropdown = nil, "", nil
local function profileNames()
    local names = {}
    for label, raw in pairs(Store.profiles) do
        if type(label) == "string" and type(raw) == "table" then table.insert(names, label) end
    end
    table.sort(names)
    if #names == 0 then names[1] = "No profiles" end
    return names
end
local function refreshProfiles()
    local names = profileNames()
    if not Store.profiles[SelectedProfile] then
        SelectedProfile = names[1] ~= "No profiles" and names[1] or nil
    end
    if ProfileDropdown then
        ProfileDropdown.Value = SelectedProfile or "No profiles"
        ProfileDropdown:Refresh(names)
    end
end
local function saveProfile()
    local label = validLabel(ProfileName)
    if label == "" then label = "My Obsidian" end
    local count = 0
    for _ in pairs(Store.profiles) do count += 1 end
    if not Store.profiles[label] and count >= 16 then
        return notify("Profiles", "Maximum 16 profiles; delete one first")
    end
    Store.profiles[label] = captureProfile()
    SelectedProfile = label
    refreshProfiles()
    notify("Profiles", "Saved " .. label .. (persistStore() and " • on disk" or " • this session"))
end
local function loadProfile()
    local snapshot = SelectedProfile and Store.profiles[SelectedProfile]
    if type(snapshot) ~= "table" then return notify("Profiles", "Choose a saved profile") end
    -- Schema-gate all numbers to keep bad JSON from driving extreme physics.
    local limits = {
        FlySpeed={10,300}, WalkSpeed={16,250}, ThirdPersonDistance={6,25},
        AirWalkSize={6,20}, DashPower={35,180}, DashCooldown={0.4,4},
        AntiVoidOffset={15,100}, FreecamSpeed={5,140}, FreecamFOV={40,100},
    }
    for _, key in ipairs(ProfileKeys) do
        local value = snapshot[key]
        local old = State[key]
        if type(old) == "number" and type(value) == "number" and value == value then
            local range = limits[key]
            value = range and math.clamp(value, range[1], range[2]) or value
            State[key] = value
            uiSet(key, value)
        elseif type(old) == "boolean" and type(value) == "boolean" then
            if key == "AntiFling" then setAntiFling(value)
            elseif key == "Speed" then setSpeedEnabled(value)
            elseif key == "NoClip" then setNoClip(value)
            elseif key == "FullBright" then setFullBright(value)
            elseif key == "AntiVoid" then
                if value and not State.AntiVoid then SafeGroundCFrame = nil end
                State.AntiVoid = value
            else State[key] = value end
            uiSet(key, value, false)
        end
    end
    if type(snapshot.bindings) == "table" then
        local used = {}
        for _, action in ipairs(BoundActions) do
            local key = snapshot.bindings[action]
            if type(key) == "string" and (key == "None" or Enum.KeyCode[key])
                and (key == "None" or not used[key]) then
                Store.bindings[action] = key
                if key ~= "None" then used[key] = true end
            end
        end
    end
    persistStore()
    notify("Profiles", "Loaded " .. SelectedProfile .. " (movement + appearance settings)")
end
local function deleteProfile()
    if not SelectedProfile or not Store.profiles[SelectedProfile] then return end
    local name = SelectedProfile
    Store.profiles[name] = nil
    SelectedProfile = nil
    refreshProfiles()
    persistStore()
    notify("Profiles", "Deleted " .. name)
end

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------
local MovementTab = Window:Tab({Title = "Movement", Icon = "footprints"})
local CameraTab = Window:Tab({Title = "Camera", Icon = "video"})
local WaypointsTab = Window:Tab({Title = "Waypoints", Icon = "map-pin"})
local ConfigTab = Window:Tab({Title = "Obsidian", Icon = "gem"})
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})
local ServerTab = Window:Tab({
    Title = "Server",
    Icon = "server",
})
local FlingTab = Window:Tab({
    Title = "Fling",
    Icon = "zap",
})
local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "crosshair",
})
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "scan-eye",
})
local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "sparkles",
})
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})
---------------------------------------------------------------------
-- PLAYER TAB
---------------------------------------------------------------------
PlayerTab:Section({Title = "Fly", Icon = "wind"})
ProfileControls.Fly = PlayerTab:Toggle({
    Title = "Fly",
    Desc = "F toggles fly anywhere.",
    Value = false,
    Callback = function(value)
        if value then
            if State.AirWalk then
                setAirWalk(false)
                uiSet("AirWalk", false, false)
            end
            if State.Freecam then stopFreecam(true) end
            if State.Spectating then stopSpectate(true) end
        end
        setFly(value)
    end,
})
ProfileControls.FlySpeed = PlayerTab:Slider({
    Title = "Fly Speed",
    Value = {
        Min = 10,
        Max = 300,
        Default = 60,
    },
    Step = 5,
    Callback = function(value)
        State.FlySpeed = tonumber(value) or 60
    end,
})
PlayerTab:Section({Title = "Jump", Icon = "arrow-up"})
ProfileControls.InfiniteJump = PlayerTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Press jump again while airborne. Supports Space, controller, and mobile. Pauses during Fly and Fling.",
    Value = false,
    Callback = function(value)
        State.InfiniteJump = value == true
        notify("Infinite Jump", State.InfiniteJump and "Enabled: jump again in midair" or "Disabled")
    end,
})

PlayerTab:Section({Title = "Speed", Icon = "gauge"})
ProfileControls.Speed = PlayerTab:Toggle({
    Title = "Speed",
    Value = false,
    Callback = setSpeedEnabled,
})
ProfileControls.WalkSpeed = PlayerTab:Slider({
    Title = "Walk Speed",
    Value = {
        Min = 16,
        Max = 250,
        Default = 32,
    },
    Step = 1,
    Callback = function(value)
        State.WalkSpeed = tonumber(value) or 32
    end,
})
PlayerTab:Section({Title = "Camera & Collision", Icon = "scan"})
ProfileControls.ThirdPerson = PlayerTab:Toggle({
    Title = "Force Third Person",
    Desc = "Adaptive camera fallback for games that lock first person. Try Force Override if needed.",
    Value = false,
    Callback = function(value)
        if value then
            if State.Freecam then stopFreecam(true) end
            if State.Spectating then stopSpectate(true) end
        end
        setForceThirdPerson(value)
    end,
})
ProfileControls.ThirdPersonDistance = PlayerTab:Slider({
    Title = "Third Person Distance",
    Desc = "Target camera distance for both native zoom and forced camera positioning.",
    Value = {Min = 6, Max = 25, Default = 10},
    Step = 1,
    Callback = function(value)
        State.ThirdPersonDistance = math.clamp(tonumber(value) or 10, 6, 25)
    end,
})
PlayerTab:Dropdown({
    Title = "Third Person Strategy",
    Desc = "Adaptive: detect first-person locks. Force Override: manually reposition the camera every frame. Native Only: zoom settings only.",
    Values = {"Adaptive", "Force Override", "Native Only"},
    Value = "Adaptive",
    Callback = function(value)
        local selected = dropdownValue(value)
        if selected == "Adaptive" or selected == "Force Override" or selected == "Native Only" then
            State.ThirdPersonMode = selected
            CameraNearFrames = 0
            CameraOverrideFrames = 0
            CameraLastWritten = nil
            CameraOrbitForward = nil
            if CameraVisibleCharacter then clearCameraVisibility() end
        end
    end,
})
ProfileControls.UnlockMouse = PlayerTab:Toggle({
    Title = "Unlock Mouse",
    Desc = "Free your cursor from mouse lock. Camera rotation may work differently.",
    Value = false,
    Callback = function(value)
        setUnlockMouse(value)
    end,
})
ProfileControls.NoClip = PlayerTab:Toggle({
    Title = "NoClip",
    Desc = "Move through collidable parts; restores original collisions when disabled.",
    Value = false,
    Callback = function(value)
        if value and State.AirWalk then
            setAirWalk(false)
            uiSet("AirWalk", false, false)
        end
        setNoClip(value)
    end,
})
PlayerTab:Section({Title = "Protection", Icon = "shield"})
ProfileControls.AntiFling = PlayerTab:Toggle({
    Title = "Anti-Fling",
    Desc = "ON by default. Checks other characters each physics step to prevent local fling collisions. Pauses during your own fling and restores modified parts when disabled.",
    Value = true,
    Callback = function(value)
        setAntiFling(value)
        notify("Protection", State.AntiFling and "Anti-Fling enabled" or "Anti-Fling disabled")
    end,
})
PlayerTab:Section({Title = "Idle", Icon = "coffee"})
PlayerTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevents Roblox idle disconnects. Enabled by default.",
    Value = true,
    Callback = function(value)
        State.AntiAFK = value == true
        notify(
            "Anti-AFK",
            State.AntiAFK and "Enabled" or "Disabled"
        )
    end,
})
---------------------------------------------------------------------
-- TELEPORT TAB
---------------------------------------------------------------------
TeleportTab:Section({Title = "Player Teleport", Icon = "map-pin"})
local TeleportPlayerDropdown = TeleportTab:Dropdown({
    Title = "Player (Nickname + Username)",
    Desc = "Auto-updates when players join or leave.",
    Values = CurrentPlayerLabels,
    Value = PlayerUsernameToLabel[State.SelectedPlayer] or "No players",
    MenuWidth = 310,
    SearchBarEnabled = true,
    Callback = onPlayerDropdownSelected,
})
table.insert(PlayerDropdowns, TeleportPlayerDropdown)
TeleportTab:Button({
    Title = "Teleport To Player",
    Icon = "send",
    Callback = function()
        if not State.SelectedPlayer then
            return notify(
                "Teleport",
                "No player selected"
            )
        end
        teleportToPlayer(State.SelectedPlayer)
    end,
})
TeleportTab:Section({Title = "Quick Teleport", Icon = "bookmark"})
TeleportTab:Toggle({
    Title = "Ctrl + Click Teleport",
    Desc = "Hold Ctrl and left-click anywhere.",
    Value = false,
    Callback = function(value)
        State.ClickTP = value == true
    end,
})
TeleportTab:Button({
    Title = "Save Position",
    Icon = "bookmark",
    Callback = function()
        local root = rootPart()
        if not root then
            return
        end
        State.SavedCFrame = root.CFrame
        notify("Teleport", "Position saved")
    end,
})
TeleportTab:Button({
    Title = "Return To Saved Position",
    Icon = "undo-2",
    Callback = function()
        if not State.SavedCFrame then
            return notify(
                "Teleport",
                "No saved position"
            )
        end
        teleport(State.SavedCFrame)
    end,
})
ServerTab:Section({Title = "Session Controls", Icon = "server"})
ServerTab:Button({
    Title = "Rejoin Current Server",
    Desc = "Try to reconnect to this exact Roblox server instance. If its ID is unavailable, rejoin the same game instead.",
    Icon = "refresh-cw",
    Callback = rejoinServer,
})
ServerTab:Section({Title = "Public Server Switch", Icon = "shuffle"})
ServerTab:Button({
    Title = "Server Hop",
    Desc = "Join a random different public server. Excludes this server and full instances.",
    Icon = "shuffle",
    Callback = function() serverHop("Hop") end,
})
ServerTab:Button({
    Title = "Find Empty / Emptiest Server",
    Desc = "Look for 0-1 player; otherwise choose the least populated available public instance.",
    Icon = "users-round",
    Callback = function() serverHop("Empty") end,
})
ServerTab:Button({
    Title = "Quiet / Fresh Candidate",
    Desc = "Pick a quiet public server (0-3 players preferred). Roblox does not publish server creation times.",
    Icon = "sparkles",
    Callback = function() serverHop("Fresh") end,
})
ServerTab:Paragraph({
    Title = "Server Availability",
    Desc = "These actions search only when clicked. A completely empty or brand-new public server cannot be guaranteed. Some games or executors may block directory requests or teleports.",
})

---------------------------------------------------------------------
-- FLING TAB v3.4: Infinite Yield-style WalkFling and targeted return.
---------------------------------------------------------------------
FlingTab:Paragraph({
    Title = "WalkFling • No-Spin Physics",
    Desc = "Inspired by Infinite Yield's WalkFling: velocity pulses while you walk into targets, with no visual spinning. Depends on server physics and network ownership. Toggle OFF to restore normal controls.",
})
WalkFlingControl = FlingTab:Toggle({
    Title = "WalkFling (Touch Fling)",
    Desc = "Walk into players while enabled. No-spin, separate from targeted Fling & Return.",
    Value = false,
    Callback = function(v) setWalkFling(v) end,
})
FlingTab:Section({Title = "Targeted WalkFling + Return", Icon = "target"})
local FlingPlayerDropdown = FlingTab:Dropdown({
    Title = "Target Player",
    Desc = "Nickname (@Username) • automatically updates",
    Values = CurrentPlayerLabels,
    Value = PlayerUsernameToLabel[State.SelectedPlayer] or "No players",
    MenuWidth = 310,
    SearchBarEnabled = true,
    Callback = onPlayerDropdownSelected,
})
table.insert(PlayerDropdowns, FlingPlayerDropdown)

-- Keep teleport and fling target lists synchronized without manual refresh buttons.
for _, player in ipairs(Players:GetPlayers()) do
    trackPlayerDisplayName(player)
end
bind(Players.PlayerAdded:Connect(function(player)
    trackPlayerDisplayName(player)
    refreshPlayerDropdowns()
end))
bind(Players.PlayerRemoving:Connect(function(player)
    stopTrackingPlayerDisplayName(player)
    refreshPlayerDropdowns(player)
end))
refreshPlayerDropdowns()

FlingTab:Slider({
    Title = "Fling Duration",
    Desc = "Quick by default (2.2s); raise only if server contact is delayed.",
    Value = {Min = 0.6, Max = 6, Default = 2.2},
    Step = 0.2,
    Callback = function(value)
        State.FlingDuration = math.clamp(tonumber(value) or 2.2, 0.6, 6)
    end,
})
FlingTab:Button({
    Title = "Fling & Return",
    Desc = "Teleport to selected target, run no-spin WalkFling-style velocity pulses, then return automatically.",
    Icon = "zap",
    Callback = flingSelectedPlayer,
})
FlingTab:Button({
    Title = "Cancel Fling",
    Desc = "Stop the active contact attempt and return immediately.",
    Icon = "x-circle",
    Callback = function()
        if not State.Flinging then
            return notify("Fling", "No active fling")
        end
        State.CancelFling = true
        notify("Fling", "Stopping and returning")
    end,
})
---------------------------------------------------------------------
-- COMBAT TAB
---------------------------------------------------------------------
CombatTab:Section({Title = "Aim Assistance", Icon = "crosshair"})
ProfileControls.AimAssist = CombatTab:Toggle({
    Title = "Aim Assist",
    Desc = "Hold right mouse button to smoothly aim. Press Q to lock/unlock a target.",
    Value = false,
    Callback = setCombatAim,
})
CombatTab:Dropdown({
    Title = "Target Priority",
    Values = { "Closest to crosshair", "Closest to character", "Selected player" },
    Value = Combat.Priority,
    Callback = function(value)
        Combat.Priority = tostring(dropdownValue(value) or "Closest to crosshair")
        resetCombatTargetCache()
        Combat.LockHeld = false
        Combat.LockedPlayer = nil
    end,
})
CombatTab:Dropdown({
    Title = "Aim At",
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Value = "Head",
    Callback = function(value)
        Combat.Part = tostring(dropdownValue(value) or "Head")
        resetCombatTargetCache()
    end,
})
CombatTab:Slider({
    Title = "Aim FOV",
    Desc = "Maximum distance from the crosshair, in screen pixels.",
    Value = {Min = 50, Max = 450, Default = 180}, Step = 10,
    Callback = function(value) Combat.FOV = tonumber(value) or 180; updateFovCircle() end,
})
CombatTab:Slider({
    Title = "Aim Smoothness",
    Desc = "Higher values track more quickly.",
    Value = {Min = 2, Max = 30, Default = 12}, Step = 1,
    Callback = function(value) Combat.Smoothness = tonumber(value) or 12 end,
})
CombatTab:Slider({
    Title = "Max Target Distance",
    Value = {Min = 50, Max = 1200, Default = 400}, Step = 25,
    Callback = function(value) Combat.MaxDistance = tonumber(value) or 400 end,
})
CombatTab:Toggle({
    Title = "Visible Targets Only",
    Desc = "Ignore targets obstructed by walls.",
    Value = true,
    Callback = function(value) Combat.WallCheck = value == true end,
})
CombatTab:Toggle({
    Title = "Ignore Teammates",
    Value = true,
    Callback = function(value) Combat.TeamCheck = value == true end,
})
ProfileControls.ShowFOV = CombatTab:Toggle({
    Title = "Show FOV Circle",
    Value = false,
    Callback = function(value) Combat.ShowFOV = value == true; updateFovCircle() end,
})
CombatTab:Section({Title = "Equipped Tool", Icon = "swords"})
ProfileControls.AutoUseTool = CombatTab:Toggle({
    Title = "Auto Use Equipped Tool",
    Desc = "While aiming at a nearby target, call Tool:Activate(). Depends on the game and equipped weapon.",
    Value = false,
    Callback = function(value) Combat.AutoUseTool = value == true end,
})
CombatTab:Slider({
    Title = "Tool Use Range",
    Desc = "Maximum distance for automatic Tool:Activate().",
    Value = {Min = 5, Max = 35, Default = 18}, Step = 1,
    Callback = function(value) Combat.UseRange = tonumber(value) or 18 end,
})
CombatTab:Paragraph({
    Title = "Combat Controls",
    Desc = "Hold RMB for Aim Assist, or press Q to lock a target. The 'Selected player' option uses your existing player selector. Weapon damage remains controlled by each experience.",
})

---------------------------------------------------------------------
-- ESP TAB
---------------------------------------------------------------------
ESPTab:Section({Title = "Player Highlights", Icon = "scan-eye"})
ESPTab:Dropdown({
    Title = "ESP Performance",
    Desc = "Performance reduces how frequently each player's overlay updates.",
    Values = {"Performance", "Balanced", "Fast"},
    Value = "Performance",
    Callback = function(value)
        ESP.Quality = tostring(dropdownValue(value) or "Performance")
    end,
})
ProfileControls.ESP = ESPTab:Toggle({
    Title = "Enable ESP",
    Desc = "Master switch for local-only player overlays.",
    Value = false,
    Callback = setEspEnabled,
})
ESPTab:Toggle({
    Title = "Chams",
    Desc = "GPU-heavy player outlines; disabled by default for FPS.",
    Value = false,
    Callback = function(value) ESP.Chams = value == true end,
})
ESPTab:Toggle({
    Title = "See Through Walls",
    Desc = "Draw chams even when a player is behind a wall.",
    Value = true,
    Callback = function(value) ESP.Xray = value == true end,
})
ESPTab:Toggle({
    Title = "Player Names",
    Desc = "Nickname and @Username above each player.",
    Value = true,
    Callback = function(value) ESP.Names = value == true end,
})
ESPTab:Toggle({
    Title = "Distance Labels",
    Value = true,
    Callback = function(value) ESP.Distances = value == true end,
})
ESPTab:Toggle({
    Title = "Health Labels",
    Value = false,
    Callback = function(value) ESP.Health = value == true end,
})
ESPTab:Toggle({
    Title = "3D Boxes",
    Desc = "Outline other characters with a thin 3D box.",
    Value = false,
    Callback = function(value) ESP.Boxes = value == true end,
})
ESPTab:Toggle({
    Title = "Tracers",
    Desc = "Lines from the bottom of the screen to onscreen players.",
    Value = false,
    Callback = function(value) ESP.Tracers = value == true end,
})
ESPTab:Section({Title = "ESP Filtering & Colors", Icon = "palette"})
ESPTab:Toggle({
    Title = "Ignore Teammates",
    Value = false,
    Callback = function(value) ESP.TeamCheck = value == true end,
})
ESPTab:Toggle({
    Title = "Use Team Colors",
    Value = false,
    Callback = function(value) ESP.TeamColors = value == true end,
})
ESPTab:Colorpicker({
    Title = "ESP Accent Color",
    Desc = "Customize chams, names, boxes, and tracers.",
    Default = Color3.fromHex("#F18CA3"),
    Callback = function(color)
        if typeof(color) == "Color3" then ESP.Color = color end
    end,
})
ESPTab:Slider({
    Title = "Max ESP Distance",
    Value = {Min = 100, Max = 2000, Default = 600}, Step = 50,
    Callback = function(value) ESP.MaxDistance = tonumber(value) or 600 end,
})
ESPTab:Paragraph({
    Title = "ESP Notes",
    Desc = "Optimized: only requested visuals are created; Performance updates fewer players per frame. Chams, health and tracers cost more GPU/CPU time. Try Performance before Fast.",
})

---------------------------------------------------------------------
-- VISUALS TAB
---------------------------------------------------------------------
local SkyboxOrder = {
    "Original",
    "Galaxy",
    "Vaporwave Classic",
    "Vaporwave Neon",
    "Red Night",
    "Sunset",
    "Tropic",
    "Soft Blue",
    "Blue Horizon",
    "Pink Morning",
    "Purple Gradient",
    "Pink Gradient",
    "Neptune",
    "Aesthetic Night",
    "Cinematic Cabin Sky",
    "Classic Sky",
    "Purple Atmosphere",
    "Among Us",
    "Skeleton",
    "Dark Meme",
    "Crimson Veil",
    "Obsidian Eclipse",
    "Lavender Dream",
    "Rose Quartz",
    "Glacial Dawn",
    "Teal Nebula",
    "Amber Haze",
    "Coral Afterglow",
    "Noir Violet",
    "Neon Sakura",
    "Moonlit Cabin",
    "Electric Dusk",
}
local function skyboxIndex(name)
    for index, item in ipairs(SkyboxOrder) do
        if item == name then
            return index
        end
    end
    return 1
end
local function cycleSkybox(direction)
    local index = skyboxIndex(State.SelectedSkybox)
    index += direction
    if index > #SkyboxOrder then
        index = 1
    elseif index < 1 then
        index = #SkyboxOrder
    end
    applySkybox(SkyboxOrder[index])
end
local function randomSkybox()
    if #SkyboxOrder <= 1 then
        return
    end
    local current = State.SelectedSkybox
    local chosen
    repeat
        chosen = SkyboxOrder[math.random(2, #SkyboxOrder)]
    until chosen ~= current or #SkyboxOrder <= 2
    applySkybox(chosen)
end
VisualsTab:Section({Title = "Skybox", Icon = "image"})
VisualsTab:Dropdown({
    Title = "Skybox Preset",
    Desc = "Client-side only. Original restores the game's sky.",
    Values = SkyboxOrder,
    Value = "Original",
    Callback = function(value)
        local selected = dropdownValue(value)
        applySkybox(selected)
    end,
})
VisualsTab:Button({
    Title = "Random Skybox",
    Icon = "shuffle",
    Callback = function()
        randomSkybox()
    end,
})
VisualsTab:Button({
    Title = "Next Skybox",
    Icon = "chevron-right",
    Callback = function()
        cycleSkybox(1)
    end,
})
VisualsTab:Button({
    Title = "Previous Skybox",
    Icon = "chevron-left",
    Callback = function()
        cycleSkybox(-1)
    end,
})
VisualsTab:Button({
    Title = "Restore Original Sky",
    Icon = "rotate-ccw",
    Callback = function()
        restoreOriginalSky()
        notify("Skybox", "Original sky restored")
    end,
})
VisualsTab:Section({Title = "Custom Skybox", Icon = "image-plus"})
local CustomSky = {
    Bk = "",
    Dn = "",
    Ft = "",
    Lf = "",
    Rt = "",
    Up = "",
}
local function normalizeAssetId(value)
    value = tostring(value or "")
    local id = value:match("(%d+)")
    if not id then
        return ""
    end
    return "rbxassetid://" .. id
end
VisualsTab:Input({
    Title = "Back ID",
    Placeholder = "SkyboxBk asset id",
    Callback = function(value)
        CustomSky.Bk = normalizeAssetId(value)
    end,
})
VisualsTab:Input({
    Title = "Down ID",
    Placeholder = "SkyboxDn asset id",
    Callback = function(value)
        CustomSky.Dn = normalizeAssetId(value)
    end,
})
VisualsTab:Input({
    Title = "Front ID",
    Placeholder = "SkyboxFt asset id",
    Callback = function(value)
        CustomSky.Ft = normalizeAssetId(value)
    end,
})
VisualsTab:Input({
    Title = "Left ID",
    Placeholder = "SkyboxLf asset id",
    Callback = function(value)
        CustomSky.Lf = normalizeAssetId(value)
    end,
})
VisualsTab:Input({
    Title = "Right ID",
    Placeholder = "SkyboxRt asset id",
    Callback = function(value)
        CustomSky.Rt = normalizeAssetId(value)
    end,
})
VisualsTab:Input({
    Title = "Up ID",
    Placeholder = "SkyboxUp asset id",
    Callback = function(value)
        CustomSky.Up = normalizeAssetId(value)
    end,
})
VisualsTab:Button({
    Title = "Apply Custom Skybox",
    Icon = "image",
    Callback = function()
        for _, face in ipairs({"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}) do
            if CustomSky[face] == "" then
                notify("Custom Skybox", "Fill all 6 face IDs first")
                return
            end
        end
        local sky = currentSky()
        clearSkyTone()
        sky.SkyboxBk = CustomSky.Bk
        sky.SkyboxDn = CustomSky.Dn
        sky.SkyboxFt = CustomSky.Ft
        sky.SkyboxLf = CustomSky.Lf
        sky.SkyboxRt = CustomSky.Rt
        sky.SkyboxUp = CustomSky.Up
        sky.CelestialBodiesShown = true
        sky.StarCount = 3000
        State.SelectedSkybox = "Custom"
        notify("Custom Skybox", "Custom 6-face sky applied")
    end,
})
VisualsTab:Section({Title = "Lighting", Icon = "sun"})
ProfileControls.FullBright = VisualsTab:Toggle({
    Title = "Full Bright",
    Desc = "OFF by default. Custom SALTY ambient illumination, reduced shadows, and clear distance. Leaves Time Changer untouched. Restores original lighting on disable.",
    Value = false,
    Callback = function(value)
        setFullBright(value)
        notify("Full Bright", State.FullBright and "Enabled" or "Restored original lighting")
    end,
})
VisualsTab:Section({Title = "Time Changer", Icon = "clock"})
VisualsTab:Slider({
    Title = "Time",
    Desc = "0 = midnight • 6 = sunrise • 12 = noon • 18 = sunset • 24 = midnight",
    Value = {
        Min = 0,
        Max = 24,
        Default = math.floor(OriginalClockTime * 10 + 0.5) / 10,
    },
    Step = 0.1,
    Callback = function(value)
        setTime(value)
    end,
})
VisualsTab:Toggle({
    Title = "Lock Time",
    Desc = "Keeps your selected time even if the game changes Lighting.",
    Value = false,
    Callback = function(value)
        State.LockTime = value == true
        if State.LockTime then
            setTime(State.Time)
        end
    end,
})
VisualsTab:Button({
    Title = "Morning • 8:00",
    Icon = "sunrise",
    Callback = function()
        setTime(8)
        notify("Time", "Morning • 08:00")
    end,
})
VisualsTab:Button({
    Title = "Noon • 12:00",
    Icon = "sun",
    Callback = function()
        setTime(12)
        notify("Time", "Noon • 12:00")
    end,
})
VisualsTab:Button({
    Title = "Sunset • 18:00",
    Icon = "sunset",
    Callback = function()
        setTime(18)
        notify("Time", "Sunset • 18:00")
    end,
})
VisualsTab:Button({
    Title = "Midnight • 00:00",
    Icon = "moon",
    Callback = function()
        setTime(0)
        notify("Time", "Midnight • 00:00")
    end,
})
VisualsTab:Button({
    Title = "Restore Original Time",
    Icon = "rotate-ccw",
    Callback = function()
        State.LockTime = false
        State.Time = OriginalClockTime
        Lighting.ClockTime = OriginalClockTime
        notify(
            "Time",
            string.format(
                "Restored original time • %.1f",
                OriginalClockTime
            )
        )
    end,
})
---------------------------------------------------------------------
-- OBSIDIAN | MOVEMENT, CAMERA, WAYPOINTS, KEYBINDS & PROFILES
---------------------------------------------------------------------
MovementTab:Paragraph({
    Title = "OBSIDIAN • Motion Laboratory",
    Desc = "Experimental client-side movement with reversible controls. Dash X • Air Walk G • Panic \\ by default.",
})
MovementTab:Section({Title = "Air Walk", Icon = "footprints"})
ProfileControls.AirWalk = MovementTab:Toggle({
    Title = "Air Walk",
    Desc = "Invisible local platform under your feet, following X/Z at a fixed altitude. May be restricted by game physics.",
    Value = false,
    Callback = function(value)
        if value and State.NoClip then
            setNoClip(false)
            uiSet("NoClip", false, false)
        end
        local enabled = setAirWalk(value)
        if enabled == false then uiSet("AirWalk", false, false) end
    end,
})
ProfileControls.AirWalkSize = MovementTab:Slider({
    Title = "Air Platform Width", Desc = "Applies on next activation.",
    Value = {Min = 6, Max = 20, Default = 11}, Step = 1,
    Callback = function(v)
        State.AirWalkSize = math.clamp(tonumber(v) or 11, 6, 20)
        if AirPlane then AirPlane.Size = Vector3.new(State.AirWalkSize, 0.7, State.AirWalkSize) end
    end,
})
MovementTab:Section({Title = "Dash", Icon = "zap"})
MovementTab:Button({
    Title = "Dash Now", Desc = "Horizontal burst along movement / camera direction. Default shortcut: X.",
    Icon = "wind", Callback = dash,
})
ProfileControls.DashPower = MovementTab:Slider({
    Title = "Dash Power", Value = {Min = 35, Max = 180, Default = 90}, Step = 5,
    Callback = function(v) State.DashPower = math.clamp(tonumber(v) or 90, 35, 180) end,
})
ProfileControls.DashCooldown = MovementTab:Slider({
    Title = "Dash Cooldown", Value = {Min = 0.4, Max = 4, Default = 1.4}, Step = 0.2,
    Callback = function(v) State.DashCooldown = math.clamp(tonumber(v) or 1.4, 0.4, 4) end,
})
MovementTab:Section({Title = "Safe Landing", Icon = "shield-check"})
ProfileControls.AntiVoid = MovementTab:Toggle({
    Title = "Anti-Void",
    Desc = "Track grounded locations and return if below FallenPartsDestroyHeight. Does not guarantee recovery from scripted hazards.",
    Value = false, Callback = function(v)
        State.AntiVoid = v == true
        if State.AntiVoid then
            SafeGroundCFrame = nil
            notify("Protection", "Anti-Void armed; stand on safe ground to set checkpoint")
        end
    end,
})
ProfileControls.AntiVoidOffset = MovementTab:Slider({
    Title = "Void Safety Margin", Desc = "Studs above the game's destroy height.",
    Value = {Min = 15, Max = 100, Default = 35}, Step = 5,
    Callback = function(v) State.AntiVoidOffset = math.clamp(tonumber(v) or 35, 15, 100) end,
})
MovementTab:Button({
    Title = "Mark Current Ground as Safe", Icon = "bookmark-check", Callback = function()
        local root, hum = characterReady()
        if not root or hum.FloorMaterial == Enum.Material.Air then
            return notify("Protection", "Stand on solid ground to mark a checkpoint")
        end
        SafeGroundCFrame = root.CFrame
        notify("Protection", "Safe checkpoint recorded")
    end,
})

CameraTab:Paragraph({
    Title = "OBSIDIAN • Camera Suite",
    Desc = "Spectate a player or use Freecam. Switching modes restores the previous camera first.",
})
CameraTab:Section({Title = "Spectate", Icon = "eye"})
SpectatePlayerDropdown = CameraTab:Dropdown({
    Title = "Spectate Player",
    Desc = "Nickname (@Username) • live player list • separate from Teleport/Fling",
    Values = CurrentPlayerLabels,
    Value = PlayerUsernameToLabel[State.SpectateTarget] or "No players",
    MenuWidth = 310,
    SearchBarEnabled = true,
    Callback = onSpectatePlayerSelected,
})
ProfileControls.Spectate = CameraTab:Toggle({
    Title = "Spectate Selected Player",
    Desc = "Spectates the player picked above. You can change targets while watching. Shortcut: B.",
    Value = false,
    Callback = function(v)
        if v then startSpectate() else stopSpectate() end
        if v and not State.Spectating then uiSet("Spectate", false, false) end
    end,
})
CameraTab:Button({Title = "Stop Spectating", Icon = "eye-off", Callback = function()
    stopSpectate()
    uiSet("Spectate", false, false)
end})
CameraTab:Section({Title = "Freecam", Icon = "video"})
ProfileControls.Freecam = CameraTab:Toggle({
    Title = "Freecam", Desc = "WASD move • Space/Ctrl vertical • RMB look • Shift boost. Default shortcut: V.",
    Value = false,
    Callback = function(v)
        local enabled = setFreecam(v)
        if v and enabled == false then uiSet("Freecam", false, false) end
    end,
})
ProfileControls.FreecamSpeed = CameraTab:Slider({
    Title = "Freecam Speed", Value = {Min = 5, Max = 140, Default = 35}, Step = 5,
    Callback = function(v) State.FreecamSpeed = math.clamp(tonumber(v) or 35, 5, 140) end,
})
ProfileControls.FreecamFOV = CameraTab:Slider({
    Title = "Freecam FOV", Value = {Min = 40, Max = 100, Default = 70}, Step = 2,
    Callback = function(v) State.FreecamFOV = math.clamp(tonumber(v) or 70, 40, 100) end,
})
CameraTab:Button({Title = "Restore My Camera", Icon = "rotate-ccw", Callback = function()
    if State.Freecam then stopFreecam(true) end
    if State.Spectating then stopSpectate(true) end
    uiSet("Freecam", false, false)
    uiSet("Spectate", false, false)
    notify("Camera", "Original camera restored")
end})

WaypointsTab:Paragraph({
    Title = "OBSIDIAN • Saved Places",
    Desc = "Name and save up to 40 map positions. Persists across sessions if readfile/writefile are available.",
})
WaypointsTab:Section({Title = "Your Locations", Icon = "map-pin"})
WaypointsTab:Input({Title = "Waypoint Name", Placeholder = "e.g. Rooftop / Spawn / Home", Callback = function(v)
    WaypointName = tostring(v or "")
end})
WaypointsTab:Button({Title = "Save Current Position", Icon = "bookmark-plus", Callback = saveWaypoint})
WaypointDropdown = WaypointsTab:Dropdown({
    Title = "Saved Waypoints", Values = waypointNames(),
    Value = SelectedWaypoint or "No waypoints", SearchBarEnabled = true, MenuWidth = 270,
    Callback = function(v)
        local chosen = tostring(dropdownValue(v) or "")
        if Store.waypoints[chosen] then SelectedWaypoint = chosen end
    end,
})
WaypointsTab:Button({Title = "Teleport to Waypoint", Icon = "navigation", Callback = gotoWaypoint})
WaypointsTab:Button({Title = "Delete Selected Waypoint", Icon = "trash-2", Callback = deleteWaypoint})
WaypointsTab:Button({Title = "Refresh Waypoints", Icon = "refresh-cw", Callback = refreshWaypoints})
refreshWaypoints()

ConfigTab:Paragraph({
    Title = "OBSIDIAN • Control Center",
    Desc = "Crimson controls, recoverable camera states, custom hotkeys and profiles. BackSlash is the emergency stop by default.",
})
ConfigTab:Section({Title = "Emergency", Icon = "shield-alert"})
ConfigTab:Button({
    Title = "PANIC • Stop Everything", Icon = "octagon-x",
    Desc = "Stop movement modes, camera, aim assist, anti-void and full bright; restore local camera/collisions.",
    Callback = panicStop,
})
ConfigTab:Section({Title = "Custom Keybinds", Icon = "keyboard"})
local KeySelectionDropdown
ConfigTab:Dropdown({
    Title = "Action", Values = BoundActions, Value = "Dash",
    Callback = function(v)
        local x = tostring(dropdownValue(v) or "")
        if Store.bindings[x] then
            BindAction = x
            BindKey = Store.bindings[x]
            if KeySelectionDropdown then KeySelectionDropdown:Select(BindKey) end
        end
    end,
})
KeySelectionDropdown = ConfigTab:Dropdown({
    Title = "Bind Key", Values = BindableKeys, Value = Store.bindings.Dash or "X",
    Callback = function(v)
        local x = tostring(dropdownValue(v) or "")
        if x == "None" or Enum.KeyCode[x] then BindKey = x end
    end,
})
ConfigTab:Button({Title = "Apply Keybind", Icon = "check-circle", Callback = assignKeybind})
ConfigTab:Button({Title = "Show Current Keybinds", Icon = "list", Callback = function()
    local lines = {}
    for _, action in ipairs(BoundActions) do
        table.insert(lines, action .. "=" .. tostring(Store.bindings[action]))
    end
    notify("Keybinds", table.concat(lines, " | "))
end})
ConfigTab:Section({Title = "Config Profiles", Icon = "save"})
ConfigTab:Input({Title = "Profile Name", Placeholder = "e.g. Chill / PvP / Travel", Callback = function(v)
    ProfileName = tostring(v or "")
end})
ConfigTab:Button({Title = "Save Current Profile", Icon = "save", Callback = saveProfile})
ProfileDropdown = ConfigTab:Dropdown({
    Title = "Saved Profiles", Values = profileNames(), Value = SelectedProfile or "No profiles",
    MenuWidth = 270, SearchBarEnabled = true,
    Callback = function(v)
        local label = tostring(dropdownValue(v) or "")
        if Store.profiles[label] then SelectedProfile = label end
    end,
})
ConfigTab:Button({Title = "Load Selected Profile", Icon = "download", Callback = loadProfile})
ConfigTab:Button({Title = "Delete Selected Profile", Icon = "trash-2", Callback = deleteProfile})
ConfigTab:Button({Title = "Refresh Profiles", Icon = "refresh-cw", Callback = refreshProfiles})
refreshProfiles()
ConfigTab:Paragraph({
    Title = "Storage Notice",
    Desc = "Profiles and waypoints use an executor-local JSON file where supported. Without file APIs, settings remain available only for the current hub session. Profiles do not auto-start Fly, Freecam, Fling or Spectate.",
})

---------------------------------------------------------------------
-- SETTINGS TAB
---------------------------------------------------------------------
SettingsTab:Paragraph({
    Title = "Controls",
    Desc = "F = Fly toggle\nX = Dash, V = Freecam, G = Air Walk, B = Spectate\nBackSlash = Panic\nWASD = Move\nSpace = Up during Fly\nInfinite Jump = press jump again midair (keyboard/touch/controller)\nCtrl = Down\nCtrl + Click = Teleport\nWalkFling (no-spin touch mode) and Fling & Return = Fling tab\nHold RMB = Aim Assist\nQ = Toggle Aim Lock\nCombat & ESP tabs = player assistance and overlays\nTeleport, Fling and Spectate player lists auto-refresh on join/leave/name changes\nRightShift = Open/close hub",
})
SettingsTab:Paragraph({
    Title = "Visuals",
    Desc = "Anti-Fling starts ON. SALTY Full Bright starts OFF, uses custom lighting values, and leaves the Time Changer alone. Server Hop, Rejoin, and quiet/empty server search are in the Server tab; fresh server age cannot be verified.",
})
---------------------------------------------------------------------
-- RESPAWN + CLEANUP
---------------------------------------------------------------------
bind(LocalPlayer.CharacterAdded:Connect(function()
    State.CancelFling = true
    if State.WalkFling then setWalkFling(false, true) end
    setAirWalk(false)
    uiSet("AirWalk", false, false)
    if State.Freecam then
        stopFreecam(true)
        uiSet("Freecam", false, false)
    end
    if State.Spectating then
        stopSpectate(true)
        uiSet("Spectate", false, false)
    end
    SafeGroundCFrame = nil
    Combat.LockHeld = false
    Combat.LockedPlayer = nil
    clearEspViews()
    if State.NoClip then resetNoClipCache() end
    -- Reset avatar transparency caches and camera look when characters respawn.
    if CameraVisibleCharacter then clearCameraVisibility() end
    CameraLastWritten = nil
    CameraOrbitForward = nil
    CameraNearFrames = 0
    CameraOverrideFrames = 0
    resetCombatTargetCache()
    task.wait(0.7)
    if State.Fly then
        State.Fly = false
        clearFlyObjects()
        restoreFlyAnimations()
    end
end))
local function cleanup()
    if not State.Running then
        return
    end
    State.Running = false
    State.ServerHopBusy = false
    HopGeneration = HopGeneration + 1
    State.CancelFling = true
    if State.WalkFling then setWalkFling(false, true) end
    if ActiveFlingRestore then
        pcall(ActiveFlingRestore)
    end
    setAirWalk(false)
    if State.Freecam then stopFreecam(true) end
    if State.Spectating then stopSpectate(true) end
    State.AntiVoid = false
    State.Fly = false
    State.InfiniteJump = false
    State.LockTime = false
    -- Disconnect protection/lighting listeners and restore affected properties.
    setAntiFling(false)
    setFullBright(false)
    Combat.Aim = false
    Combat.AutoUseTool = false
    Combat.LockHeld = false
    Combat.LockedPlayer = nil
    resetCombatTargetCache()
    ESP.Enabled = false
    if AimBound then
        pcall(function() RunService:UnbindFromRenderStep(AimRenderName) end)
        AimBound = false
    end
    clearEspViews()
    if EspGui then pcall(function() EspGui:Destroy() end); EspGui = nil end
    FovCircle = nil
    -- Restore camera, input mode, and part collision before disconnecting events.
    setForceThirdPerson(false)
    setUnlockMouse(false)
    setNoClip(false)
    syncCameraStep()
    clearFlyObjects()
    restoreFlyAnimations()
    local hum = humanoid()
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
        if SavedWalkSpeeds[hum] ~= nil then
            hum.WalkSpeed = SavedWalkSpeeds[hum]
            SavedWalkSpeeds[hum] = nil
        end
    end
    restoreOriginalSky()
    Lighting.ClockTime = OriginalClockTime
    for player, connection in pairs(PlayerDisplayConnections) do
        pcall(function() connection:Disconnect() end)
        PlayerDisplayConnections[player] = nil
    end
    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(State.Connections)
    table.clear(PlayerDropdowns)
    SpectatePlayerDropdown = nil
    ENV.__SALTY_PLAYER_CLEANUP = nil
    -- We deliberately leave Window destruction to the caller or VantaUI's X:
    -- destroying it inside OnDestroy can re-enter the callback.
end
ENV.__SALTY_PLAYER_CLEANUP = cleanup
-- Defaults: Anti-Fling ON; custom Full Bright OFF.
-- UI callbacks may run at creation; setters are safe to call again.
setFullBright(false)
setAntiFling(true)
pcall(function()
    Window:OnDestroy(function()
        task.defer(cleanup)
    end)
end)
notify(
    "SALTY Player Hub v3.4.0",
    "Obsidian ready • Air Walk • Dash • Spectate • Freecam • Anti-Void • Waypoints"
)
end -- initializeObsidian: compiler register boundary

initializeObsidian()

-- SALTY Player Hub | Smart Driving module (installer)
-- Returned value is install(Window, Hub). Window is the hub UI, Hub is the shared state table.
-- Features: Auto Swerve, Emergency Brake, No Vehicle Collisions (ghost), Auto Upright.
--
-- Performance: the driving loop only runs while you are actually SEATED in a vehicle.
-- On foot it is fully disconnected (zero per-frame cost) instead of polling every frame,
-- which is what made the old build lag the game when a toggle was left on.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local UserInput        = game:GetService("UserInputService")

local Me = Players.LocalPlayer

local Ray = RaycastParams.new()
Ray.FilterType = Enum.RaycastFilterType.Exclude
Ray.IgnoreWater = true
Ray.RespectCanCollide = true

return function(Window, Hub)
    local enabled = { Swerve = false, Brake = false, Ghost = false, Upright = false }
    local heartbeat, charConn, seatConn = nil, nil, nil
    local car, seat = nil, nil
    local ghostCar, added = nil, nil
    local saved   = setmetatable({}, { __mode = "k" })
    local tracked = setmetatable({}, { __mode = "k" })
    local count = 0
    local held, braking, fallback = 0, false, 0
    local accum = 0
    local elapsedS, elapsedG, elapsedU = 0, 0, 0
    local steerUntil, flipSince, lastFlip = 0, 0, -100
    local active = true

    ------------------------------------------------------------------ key / steer input
    local down, up, virtual = nil, nil, nil
    local keys = { [-1] = 65, [1] = 68, [2] = 83 }   -- A, D, S
    if type(keypress) == "function" and type(keyrelease) == "function" then
        down, up = keypress, keyrelease
    else
        pcall(function() virtual = game:GetService("VirtualInputManager") end)
    end
    local function key(code, on)
        if down then return pcall(on and down or up, code) end
        if virtual then
            local k = code == 65 and "A" or code == 68 and "D" or "S"
            return pcall(function() virtual:SendKeyEvent(on, Enum.KeyCode[k], false, game) end)
        end
        return false
    end
    local function steering(v)
        if (held ~= 0 and held == v) or (held == 0 and fallback == v) then return end
        if held ~= 0 then key(keys[held], false) end
        if fallback ~= 0 and seat then pcall(function() seat.SteerFloat = 0 end) end
        held, fallback = 0, 0
        if v ~= 0 then
            if key(keys[v], true) then held = v
            elseif seat then
                local ok = pcall(function() seat.SteerFloat = v end)
                if ok then fallback = v end
            end
        end
    end
    local function brakingSet(v)
        if v == braking then return end
        if braking then key(keys[2], false) end
        braking = v and key(keys[2], true) or false
    end
    local function release()
        if held ~= 0 then key(keys[held], false) end
        if braking then key(keys[2], false) end
        if fallback ~= 0 and seat then pcall(function() seat.SteerFloat = 0 end) end
        held, braking, fallback = 0, false, 0
    end

    ------------------------------------------------------------------ which car am I in
    local function occupied()
        local ch = Me.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local s = hum and hum.SeatPart
        if not s or not s:IsA("VehicleSeat") then return nil, nil end
        local cars = Workspace:FindFirstChild("Cars")
        if cars then
            local x = s
            while x and x.Parent and x.Parent ~= cars do x = x.Parent end
            if x and x.Parent == cars and x:IsA("Model") then return x, s end
        end
        local m = s:FindFirstAncestorOfClass("Model")
        if m and m ~= ch then return m, s end
        return nil, nil
    end

    ------------------------------------------------------------------ ghost (no vehicle collisions)
    local function ghostOff()
        if added then added:Disconnect(); added = nil end
        for part, old in pairs(saved) do
            if part.Parent then pcall(function() part.CanCollide = old end) end
            saved[part] = nil
        end
        table.clear(tracked)
        ghostCar, count = nil, 0
    end
    local function ghostAdd(part)
        if not ghostCar or not part:IsA("BasePart") or tracked[part] or count >= 300
            or part == seat or part.Name == "DriveSeat" or part.Name == "Seat" then return end
        local wheels = ghostCar:FindFirstChild("Wheels")
        if wheels and part:IsDescendantOf(wheels) then return end
        local name = part.Name:lower()
        if name == "wheel" or name == "tire" or name == "tyre" then return end
        tracked[part] = true
        count += 1
        if part.CanCollide then
            saved[part] = true
            part.CanCollide = false
        end
    end
    local function ghostOn(m)
        if ghostCar == m then return end
        ghostOff()
        if not m then return end
        ghostCar = m
        for _, part in ipairs(m:GetDescendants()) do
            ghostAdd(part)
            if count >= 300 then break end
        end
        added = m.DescendantAdded:Connect(ghostAdd)
    end
    local function ghostRefresh()
        for part in pairs(tracked) do
            if not part.Parent or not ghostCar or not part:IsDescendantOf(ghostCar) then
                tracked[part], saved[part] = nil, nil
                count = math.max(0, count - 1)
            elseif part.CanCollide then
                if saved[part] == nil then saved[part] = true end
                part.CanCollide = false
            end
        end
    end

    ------------------------------------------------------------------ swerve + brake
    local function rayLength(o, d, n)
        local hit = Workspace:Raycast(o, d * n, Ray)
        if hit and hit.Instance and hit.Instance.CanCollide then
            return (hit.Position - o).Magnitude, hit
        end
        return n, nil
    end
    local function avoid()
        if not car or not seat or UserInput:GetFocusedTextBox()
            or (UserInput:IsKeyDown(Enum.KeyCode.A) and held ~= -1)
            or (UserInput:IsKeyDown(Enum.KeyCode.D) and held ~= 1) then
            release()
            return
        end
        local f = seat.CFrame.LookVector
        local speed = seat.AssemblyLinearVelocity:Dot(f)
        if speed < 10 then release(); return end
        local right = seat.CFrame.RightVector
        local origin = seat.Position + Vector3.new(0, 2.25, 0) + f * 3
        local range = math.clamp(17 + speed * 0.52, 22, 75)
        Ray.FilterDescendantsInstances = { car, Me.Character }
        local front, hit = rayLength(origin, f, range)
        local left = rayLength(origin - right * 3.5, (f - right * 0.33).Unit, range)
        local rightClear = rayLength(origin + right * 3.5, (f + right * 0.33).Unit, range)
        local command = 0
        if hit and front < range * 0.78 then
            if rightClear > left + 4 then command = 1
            elseif left > rightClear + 4 then command = -1
            else command = (hit.Position - seat.Position):Dot(right) >= 0 and -1 or 1 end
            if left < 9 and rightClear < 9 then command = 0 end
        elseif left < 11 and rightClear > 17 then command = 1
        elseif rightClear < 11 and left > 17 then command = -1 end
        if command ~= 0 then
            steerUntil = os.clock() + 0.23
            steering(command)
        elseif os.clock() > steerUntil then
            steering(0)
        end
        if enabled.Brake then
            brakingSet(hit ~= nil and front < math.max(12, speed * 0.29) and left < 11 and rightClear < 11)
        else
            brakingSet(false)
        end
    end

    ------------------------------------------------------------------ auto upright
    local function upright()
        if not car or not seat then flipSince = 0; return end
        if seat.CFrame.UpVector.Y >= 0.1 or seat.AssemblyLinearVelocity.Magnitude > 13 then
            flipSince = 0
            return
        end
        local now = os.clock()
        if flipSince == 0 then flipSince = now; return end
        if now - flipSince < 1.6 or now - lastFlip < 9 then return end
        flipSince, lastFlip = 0, now
        local forward = seat.CFrame.LookVector
        local flat = Vector3.new(forward.X, 0, forward.Z)
        if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
        local point = car:GetPivot().Position + Vector3.new(0, 4, 0)
        pcall(function() car:PivotTo(CFrame.lookAt(point, point + flat.Unit)) end)
    end

    ------------------------------------------------------------------ per-frame loop (runs ONLY while seated)
    local function step(dt)
        if not active or not Hub.Running or Window.Destroyed then return end
        if not seat or not car then return end
        if fallback ~= 0 and enabled.Swerve then
            if UserInput:IsKeyDown(Enum.KeyCode.A) or UserInput:IsKeyDown(Enum.KeyCode.D) then
                release()
            else
                pcall(function() seat.SteerFloat = fallback end)
            end
        end
        accum += math.min(dt, 0.15)
        if accum < 0.10 then return end
        dt = accum
        accum = 0
        if enabled.Ghost then
            if ghostCar ~= car then ghostOn(car) end
            elapsedG += dt
            if elapsedG >= 0.65 then elapsedG = 0; ghostRefresh() end
        elseif ghostCar then
            ghostOff()
        end
        if enabled.Swerve then
            elapsedS += dt
            if elapsedS >= 0.12 then elapsedS = 0; avoid() end
        else
            release()
        end
        if enabled.Upright then
            elapsedU += dt
            if elapsedU >= 0.45 then elapsedU = 0; upright() end
        end
    end

    ------------------------------------------------------------------ connect/disconnect the loop by seat state
    local function anyOn() return enabled.Swerve or enabled.Ghost or enabled.Upright end
    local function stopLoop()
        if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
        release()
        ghostOff()
        car, seat = nil, nil
    end
    -- re-evaluate whether the heartbeat should be running. Only runs while seated in a car AND a tool is on.
    local function evaluate()
        if not active or not Hub.Running then stopLoop(); return end
        local m, s = occupied()
        if m ~= car or s ~= seat then
            release(); ghostOff()
            car, seat = m, s
            elapsedS, elapsedG, elapsedU, accum = 0, 0, 0, 0
            steerUntil, flipSince = 0, 0
        end
        local need = car ~= nil and anyOn()
        if need and not heartbeat then
            heartbeat = RunService.Heartbeat:Connect(step)
        elseif not need and heartbeat then
            stopLoop()
        end
    end

    -- watch the character's humanoid so we engage exactly when you sit in / leave a vehicle
    local function watchChar(ch)
        if seatConn then seatConn:Disconnect(); seatConn = nil end
        local hum = ch and ch:WaitForChild("Humanoid", 5)
        if hum then
            seatConn = hum.Seated:Connect(function() task.defer(evaluate) end)
        end
        evaluate()
    end
    charConn = Me.CharacterAdded:Connect(watchChar)
    if Me.Character then task.spawn(watchChar, Me.Character) end

    ------------------------------------------------------------------ cleanup
    local cleanup
    cleanup = function()
        if not active then return end
        active = false
        enabled.Swerve, enabled.Brake, enabled.Ghost, enabled.Upright = false, false, false, false
        if charConn then charConn:Disconnect(); charConn = nil end
        if seatConn then seatConn:Disconnect(); seatConn = nil end
        stopLoop()
        if type(getgenv) == "function" then
            pcall(function()
                if getgenv().__SALTY_DRIVING_CLEANUP == cleanup then
                    getgenv().__SALTY_DRIVING_CLEANUP = nil
                end
            end)
        end
    end

    ------------------------------------------------------------------ UI
    local tab = Window:Tab({ Title = "Driving", Icon = "car-front" })
    tab:Section({ Title = "SALTY | Smart Driving", Icon = "route" })
    tab:Paragraph({ Title = "A-Chassis Driving",
        Desc = "Only your occupied car. All tools OFF by default. Runs only while you are in a vehicle - no cost on foot." })
    tab:Toggle({ Title = "Auto Swerve",
        Desc = "Raycast ahead and steer toward a clearer lane. Key simulation depends on executor support.",
        Value = false, Callback = function(v)
            enabled.Swerve = v == true
            if not enabled.Swerve then release() end
            evaluate()
        end })
    tab:Toggle({ Title = "Emergency Brake",
        Desc = "While Auto Swerve is active, brake if both avoidance paths are blocked.",
        Value = false, Callback = function(v)
            enabled.Brake = v == true
            if not enabled.Brake then brakingSet(false) end
        end })
    tab:Section({ Title = "Vehicle Protection", Icon = "shield" })
    tab:Toggle({ Title = "No Vehicle Collisions",
        Desc = "Local-only car body and traffic hitbox ghosting. Wheels and seat keep traction.",
        Value = false, Callback = function(v)
            enabled.Ghost = v == true
            if not enabled.Ghost then ghostOff() end
            evaluate()
        end })
    tab:Toggle({ Title = "Auto Upright",
        Desc = "If stopped upside-down for 1.6 seconds, gently rotate upright.",
        Value = false, Callback = function(v)
            enabled.Upright = v == true
            if not enabled.Upright then flipSince = 0 end
            evaluate()
        end })

    if type(getgenv) == "function" then
        pcall(function() getgenv().__SALTY_DRIVING_CLEANUP = cleanup end)
    end
    return cleanup
end

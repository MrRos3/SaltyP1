local _0x92AACC=(function() local _0x1={} return function(_0x2) local _0x3=_0x1[_0x2] if _0x3 then return _0x3 end local _0x4={} for _0x5=1,#_0x2,2 do _0x4[#_0x4+1]=string.char(tonumber(string.sub(_0x2,_0x5,_0x5+1),16)) end _0x3=table.concat(_0x4) _0x1[_0x2]=_0x3 return _0x3 end end)()
local P=game:GetService(_0x92AACC("506C6179657273"))
local R=game:GetService(_0x92AACC("52756E53657276696365"))
local W=game:GetService(_0x92AACC("576F726B7370616365"))
local I=game:GetService(_0x92AACC("55736572496E70757453657276696365"))
local Me=P.LocalPlayer
local Ray=RaycastParams.new()
Ray.FilterType=Enum.RaycastFilterType.Exclude
Ray.IgnoreWater=true
return function(Window,Hub)
    local enabled={Swerve=false,Brake=false,Ghost=false,Upright=false}
    local heartbeat,car,seat=nil,nil,nil
    local ghostCar,added=nil,nil
    local saved=setmetatable({},{__mode=_0x92AACC("6B")})
    local tracked=setmetatable({},{__mode=_0x92AACC("6B")})
    local count=0
    local held,braking,fallback=0,false,0
    local checkClock=0
    local elapsedS,elapsedG,elapsedU=0,0,0
    local steerUntil,flipSince,lastFlip=0,0,-100
    local active=true
    local down,up,virtual=nil,nil,nil
    local keys={[-1]=65,[1]=68,[2]=83}
    if type(keypress)==_0x92AACC("66756E6374696F6E") and type(keyrelease)==_0x92AACC("66756E6374696F6E") then
        down,up=keypress,keyrelease
    else
        pcall(function() virtual=game:GetService(_0x92AACC("5669727475616C496E7075744D616E61676572")) end)
    end
    local function key(code,on)
        if down then return pcall(on and down or up,code) end
        if virtual then
            local k=code==65 and _0x92AACC("41") or code==68 and _0x92AACC("44") or _0x92AACC("53")
            return pcall(function()
                virtual:SendKeyEvent(on,Enum.KeyCode[k],false,game)
            end)
        end
        return false
    end
    local function steering(v)
        if (held~=0 and held==v) or (held==0 and fallback==v) then return end
        if held~=0 then key(keys[held],false) end
        if fallback~=0 and seat then pcall(function() seat.SteerFloat=0 end) end
        held,fallback=0,0
        if v~=0 then
            if key(keys[v],true) then held=v
            elseif seat then
                local ok=pcall(function() seat.SteerFloat=v end)
                if ok then fallback=v end
            end
        end
    end
    local function brakingSet(v)
        if v==braking then return end
        if braking then key(keys[2],false) end
        braking=v and key(keys[2],true) or false
    end
    local function release()
        if held~=0 then key(keys[held],false) end
        if braking then key(keys[2],false) end
        if fallback~=0 and seat then
            pcall(function() seat.SteerFloat=0 end)
        end
        held,braking,fallback=0,false,0
    end
    local function occupied()
        local ch=Me.Character
        local hum=ch and ch:FindFirstChildOfClass(_0x92AACC("48756D616E6F6964"))
        local s=hum and hum.SeatPart
        if not s or not s:IsA(_0x92AACC("56656869636C6553656174")) then return nil,nil end
        local cars=W:FindFirstChild(_0x92AACC("43617273"))
        if cars then
            local x=s
            while x and x.Parent and x.Parent~=cars do x=x.Parent end
            if x and x.Parent==cars and x:IsA(_0x92AACC("4D6F64656C")) then return x,s end
        end
        local m=s:FindFirstAncestorOfClass(_0x92AACC("4D6F64656C"))
        if m and m~=ch then return m,s end
        return nil,nil
    end
    local function ghostOff()
        if added then added:Disconnect();added=nil end
        for part,old in pairs(saved) do
            if part.Parent then pcall(function() part.CanCollide=old end) end
            saved[part]=nil
        end
        table.clear(tracked)
        ghostCar,count=nil,0
    end
    local function ghostAdd(part)
        if not ghostCar or not part:IsA(_0x92AACC("4261736550617274")) or tracked[part]
            or count>=300 or part==seat or part.Name==_0x92AACC("447269766553656174")
            or part.Name==_0x92AACC("53656174") then return end
        local wheels=ghostCar:FindFirstChild(_0x92AACC("576865656C73"))
        if wheels and part:IsDescendantOf(wheels) then return end
        local name=part.Name:lower()
        if name==_0x92AACC("776865656C") or name==_0x92AACC("74697265") or name==_0x92AACC("74797265") then return end
        tracked[part]=true
        count+=1
        if part.CanCollide then
            saved[part]=true
            part.CanCollide=false
        end
    end
    local function ghostOn(m)
        if ghostCar==m then return end
        ghostOff()
        if not m then return end
        ghostCar=m
        for _,part in ipairs(m:GetDescendants()) do
            ghostAdd(part)
            if count>=300 then break end
        end
        added=m.DescendantAdded:Connect(ghostAdd)
    end
    local function ghostRefresh()
        for part in pairs(tracked) do
            if not part.Parent or not ghostCar or not part:IsDescendantOf(ghostCar) then
                tracked[part],saved[part]=nil,nil
                count=math.max(0,count-1)
            elseif part.CanCollide then
                if saved[part]==nil then saved[part]=true end
                part.CanCollide=false
            end
        end
    end
    local function rayLength(o,d,n)
        local hit=W:Raycast(o,d*n,Ray)
        if hit and hit.Instance and hit.Instance.CanCollide then
            return (hit.Position-o).Magnitude,hit
        end
        return n,nil
    end
    local function avoid()
        if not car or not seat or I:GetFocusedTextBox()
            or (I:IsKeyDown(Enum.KeyCode.A) and held~=-1)
            or (I:IsKeyDown(Enum.KeyCode.D) and held~=1) then
            release()
            return
        end
        local f=seat.CFrame.LookVector
        local speed=seat.AssemblyLinearVelocity:Dot(f)
        if speed<10 then release();return end
        local right=seat.CFrame.RightVector
        local origin=seat.Position+Vector3.new(0,2.25,0)+f*3
        local range=math.clamp(17+speed*0.52,22,75)
        Ray.FilterDescendantsInstances={car,Me.Character}
        local front,hit=rayLength(origin,f,range)
        local left=rayLength(origin-right*3.5,(f-right*0.33).Unit,range)
        local rightClear=rayLength(origin+right*3.5,(f+right*0.33).Unit,range)
        local command=0
        if hit and front<range*0.78 then
            if rightClear>left+4 then command=1
            elseif left>rightClear+4 then command=-1
            else command=(hit.Position-seat.Position):Dot(right)>=0 and -1 or 1 end
            if left<9 and rightClear<9 then command=0 end
        elseif left<11 and rightClear>17 then command=1
        elseif rightClear<11 and left>17 then command=-1 end
        if command~=0 then
            steerUntil=os.clock()+0.23
            steering(command)
        elseif os.clock()>steerUntil then
            steering(0)
        end
        if enabled.Brake then
            brakingSet(hit~=nil and front<math.max(12,speed*0.29)
                and left<11 and rightClear<11)
        else brakingSet(false) end
    end
    local function upright()
        if not car or not seat then flipSince=0;return end
        if seat.CFrame.UpVector.Y>=0.1 or seat.AssemblyLinearVelocity.Magnitude>13 then
            flipSince=0
            return
        end
        local now=os.clock()
        if flipSince==0 then flipSince=now;return end
        if now-flipSince<1.6 or now-lastFlip<9 then return end
        flipSince,lastFlip=0,now
        local forward=seat.CFrame.LookVector
        local flat=Vector3.new(forward.X,0,forward.Z)
        if flat.Magnitude<0.01 then flat=Vector3.new(0,0,-1) end
        local point=car:GetPivot().Position+Vector3.new(0,4,0)
        pcall(function() car:PivotTo(CFrame.lookAt(point,point+flat.Unit)) end)
    end
    local cleanup
    cleanup=function()
        if not active then return end
        active=false
        enabled.Swerve,enabled.Brake,enabled.Ghost,enabled.Upright=false,false,false,false
        if heartbeat then heartbeat:Disconnect();heartbeat=nil end
        release()
        ghostOff()
        if type(getgenv)==_0x92AACC("66756E6374696F6E") then pcall(function()
            if getgenv().__SALTY_DRIVING_CLEANUP==cleanup then
                getgenv().__SALTY_DRIVING_CLEANUP=nil
            end
        end) end
    end
    local function step(dt)
        if not active or not Hub.Running or Window.Destroyed then cleanup();return end
        checkClock+=math.min(dt,0.15)
        if checkClock<0.10 then return end
        dt=checkClock
        checkClock=0
        local m,s=occupied()
        if m~=car or s~=seat then
            release()
            ghostOff()
            car,seat=m,s
            elapsedS,elapsedG,elapsedU=0,0,0
            steerUntil,flipSince=0,0
        end
        if not car then return end
        if enabled.Ghost then
            if ghostCar~=car then ghostOn(car) end
            elapsedG+=dt
            if elapsedG>=0.65 then elapsedG=0;ghostRefresh() end
        elseif ghostCar then ghostOff() end
        if enabled.Swerve then
            elapsedS+=dt
            if elapsedS>=0.12 then elapsedS=0;avoid() end
        else release() end
        if enabled.Upright then
            elapsedU+=dt
            if elapsedU>=0.45 then elapsedU=0;upright() end
        end
    end
    local function sync()
        local need=active and Hub.Running
            and (enabled.Swerve or enabled.Ghost or enabled.Upright)
        if need and not heartbeat then
            heartbeat=R.Heartbeat:Connect(step)
        elseif not need and heartbeat then
            heartbeat:Disconnect()
            heartbeat=nil
            release()
            ghostOff()
            car,seat=nil,nil
        end
    end
    local tab=Window:Tab({Title=_0x92AACC("44726976696E67"),Icon=_0x92AACC("6361722D66726F6E74")})
    tab:Section({Title=_0x92AACC("53414C5459207C20536D6172742044726976696E67"),Icon=_0x92AACC("726F757465")})
    tab:Paragraph({Title=_0x92AACC("412D436861737369732044726976696E67"),
        Desc=_0x92AACC("4F6E6C7920796F7572206F63637570696564206361722E20416C6C20746F6F6C73204F46462062792064656661756C742E204E6F20756E7665726966696564207365727665722072656D6F7465732E")})
    tab:Toggle({Title=_0x92AACC("4175746F20537765727665"),
        Desc=_0x92AACC("5261796361737420616865616420616E6420737465657220746F77617264206120636C6561726572206C616E652E204B65792073696D756C6174696F6E20646570656E6473206F6E206578656375746F7220737570706F72742E"),
        Value=false,Callback=function(v)
            enabled.Swerve=v==true
            if not enabled.Swerve then release() end
            sync()
        end})
    tab:Toggle({Title=_0x92AACC("456D657267656E6379204272616B65"),
        Desc=_0x92AACC("5768696C65204175746F20537765727665206973206163746976652C206272616B6520696620626F74682061766F6964616E63652070617468732061726520626C6F636B65642E"),
        Value=false,Callback=function(v)
            enabled.Brake=v==true
            if not enabled.Brake then brakingSet(false) end
        end})
    tab:Section({Title=_0x92AACC("56656869636C652050726F74656374696F6E"),Icon=_0x92AACC("736869656C64")})
    tab:Toggle({Title=_0x92AACC("4E6F2056656869636C6520436F6C6C6973696F6E73"),
        Desc=_0x92AACC("4C6F63616C2D6F6E6C792063617220626F647920616E64207472616666696320686974626F782067686F7374696E672E20576865656C7320616E642073656174206B656570207472616374696F6E2E"),
        Value=false,Callback=function(v)
            enabled.Ghost=v==true
            if not enabled.Ghost then ghostOff() end
            sync()
        end})
    tab:Toggle({Title=_0x92AACC("4175746F2055707269676874"),
        Desc=_0x92AACC("49662073746F70706564207570736964652D646F776E20666F7220312E36207365636F6E64732C2067656E746C7920726F7461746520757072696768742E"),
        Value=false,Callback=function(v)
            enabled.Upright=v==true
            if not enabled.Upright then flipSince=0 end
            sync()
        end})
    -- Hub lifecycle is watched by the optional active loop; avoid replacing VantaUI's existing OnDestroy callback.
    if type(getgenv)==_0x92AACC("66756E6374696F6E") then pcall(function()
        getgenv().__SALTY_DRIVING_CLEANUP=cleanup
    end) end
    return cleanup
end

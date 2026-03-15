if not game:IsLoaded() then game.Loaded:Wait() end
local P_Serv = game:GetService("Players")
local LP = P_Serv.LocalPlayer or P_Serv:GetPropertyChangedSignal("LocalPlayer"):Wait()

local S = {
    P = P_Serv, W = game:GetService("Workspace"),
    RS = game:GetService("RunService"), V = game:GetService("VirtualInputManager"),
    L = game:GetService("Lighting"), ST = game:GetService("Stats"),
    GS = game:GetService("GuiService"), TS = game:GetService("TeleportService"),
    HTTP = game:GetService("HttpService"), CG = game:GetService("CoreGui")
}

local t_wait, t_spawn = task.wait, task.spawn
local m_random, m_floor = math.random, math.floor
local v3_new, cf_new = Vector3.new, CFrame.new

getgenv().Setting = getgenv().Setting or {
    Hitbox = { Enabled = true, Size = 60, Transparency = 0.7 },
    DeleteMap = true
}

getgenv().LockedTarget = nil
getgenv().Retreating = false
getgenv().RetreatTracker = getgenv().RetreatTracker or {}
getgenv().LastTargetName = nil
local Blacklist = {}
local bLabel = nil
local lastUISearch = 0

local function getRealBounty()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty")
        if b then 
            local val = tostring(b.Value):upper()
            val = val:gsub(",", ""):gsub("%$", "")
            
            if val:match("M") then
                return (tonumber(val:gsub("M", "")) or 0) * 1000000
            elseif val:match("K") then
                return (tonumber(val:gsub("K", "")) or 0) * 1000
            end
            
            return tonumber(val) or 0
        end
    end
    return 0
end

local FileName = "SkibidiEarned_" .. LP.UserId .. ".txt"
local function SaveEarned(val)
    pcall(function() if writefile then writefile(FileName, tostring(val)) end end)
end

local function LoadEarned()
    local val = 0
    pcall(function()
        if isfile and readfile and isfile(FileName) then val = tonumber(readfile(FileName)) or 0 end
    end)
    return val
end

local TotalEarned = LoadEarned() 
local LastBounty = -1
local FrameCount, CurrentFPS = 0, 0

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIStroke = Instance.new("UIStroke")
local UICorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local TotalLabel = Instance.new("TextLabel")
local EarnLabel = Instance.new("TextLabel")
local BphLabel = Instance.new("TextLabel")
local StatLabel = Instance.new("TextLabel")
local ResetBtn = Instance.new("TextButton")
local ResetCorner = Instance.new("UICorner")

local ToggleBtn = Instance.new("TextButton")
local ToggleCorner = Instance.new("UICorner")
local ToggleStroke = Instance.new("UIStroke")

local TargetUI
pcall(function() TargetUI = type(gethui) == "function" and gethui() or S.CG end)
if not TargetUI then TargetUI = LP:WaitForChild("PlayerGui") end

ScreenGui.Parent = TargetUI
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Active = true
MainFrame.Draggable = false

UICorner.CornerRadius = UDim.new(0, 8); UICorner.Parent = MainFrame
UIStroke.Parent = MainFrame; UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(85, 170, 255); UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local function CreateLabel(obj, pos, size, color, text, textSize)
    obj.Parent = MainFrame; obj.BackgroundTransparency = 1; obj.Position = pos; obj.Size = size
    obj.Font = Enum.Font.GothamBold; obj.TextColor3 = color; obj.TextSize = textSize or 14
    obj.Text = text; obj.TextXAlignment = Enum.TextXAlignment.Left
end

CreateLabel(Title, UDim2.new(0.05, 0, 0.05, 0), UDim2.new(0, 280, 0, 20), Color3.fromRGB(85, 170, 255), "skibidi Vip Pro by khánh", 15)
CreateLabel(TotalLabel, UDim2.new(0.05, 0, 0.25, 0), UDim2.new(0, 280, 0, 20), Color3.fromRGB(255, 255, 255), "TOTAL: --")
CreateLabel(EarnLabel, UDim2.new(0.05, 0, 0.45, 0), UDim2.new(0, 280, 0, 20), Color3.fromRGB(0, 255, 120), "EARNED: 0")
CreateLabel(BphLabel, UDim2.new(0.05, 0, 0.65, 0), UDim2.new(0, 280, 0, 20), Color3.fromRGB(255, 200, 50), "BPH: 0/h")
CreateLabel(StatLabel, UDim2.new(0.05, 0, 0.85, 0), UDim2.new(0, 150, 0, 20), Color3.fromRGB(200, 200, 200), "FPS: -- | PING: --", 13)

ResetBtn.Parent = MainFrame; ResetBtn.Size = UDim2.new(0, 135, 0, 30)
ResetBtn.AnchorPoint = Vector2.new(1, 1); ResetBtn.Position = UDim2.new(1, -10, 1, -10)
ResetBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ResetBtn.Text = "Reset Bounty Skibidi"; ResetBtn.TextColor3 = Color3.new(1,1,1)
ResetBtn.Font = Enum.Font.GothamBold; ResetBtn.TextSize = 12
ResetCorner.CornerRadius = UDim.new(0, 6); ResetCorner.Parent = ResetBtn

ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 35, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.95, -160)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleBtn.Text = "VIP"
ToggleBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Active = true
ToggleBtn.Draggable = true

ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

ToggleStroke.Parent = ToggleBtn
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(85, 170, 255)
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local function formatNumber(n)
    local s = n < 0 and "-" or ""; n = math.abs(n)
    if n >= 1000000 then return s..string.format("%.2fM", n/1000000)
    elseif n >= 1000 then return s..string.format("%.1fK", n/1000)
    else return s..tostring(n) end
end

ResetBtn.MouseButton1Click:Connect(function()
    TotalEarned = 0; LastBounty = getRealBounty(); SaveEarned(TotalEarned)
    EarnLabel.Text = "EARNED: 0"; BphLabel.Text = "BPH: 0/h"
end)

S.RS.RenderStepped:Connect(function() FrameCount = FrameCount + 1 end)
t_spawn(function() while t_wait(1) do CurrentFPS = FrameCount; FrameCount = 0 end end)

t_spawn(function()
    while t_wait(1) do
        pcall(function()
            local current = getRealBounty()
            if LastBounty == -1 and current > 0 then LastBounty = current end
            if LastBounty ~= -1 and current < 30000000 then
                if current > LastBounty then
                    TotalEarned = TotalEarned + (current - LastBounty); SaveEarned(TotalEarned)
                end
            end
            LastBounty = current
            TotalLabel.Text = "TOTAL: " .. formatNumber(current)
            EarnLabel.Text = "EARNED: " .. (TotalEarned > 0 and "+" or "") .. formatNumber(TotalEarned)
            BphLabel.Text = "BPH: " .. formatNumber(TotalEarned) .. "/h"
            
            local ping = 0; pcall(function() ping = m_floor(LP:GetNetworkPing() * 1000) end)
            StatLabel.Text = string.format("FPS: %d | PING: %d ms", CurrentFPS, ping)
        end)
    end
end)

t_spawn(function()
    pcall(function()
        LP:WaitForChild("PlayerGui").DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                task.delay(0.2, function()
                    local current = getRealBounty()
                    if current >= 30000000 then
                        local txtLower = string.lower(obj.Text or "")
                        if (string.find(txtLower, "bounty") or string.find(txtLower, "honor")) and string.find(obj.Text, "%+") then
                            local numStr = string.match(obj.Text:gsub(",", ""), "%d+")
                            if numStr then
                                local val = tonumber(numStr)
                                if val and val > 0 and val < 50000 then
                                    TotalEarned = TotalEarned + val; SaveEarned(TotalEarned)
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)
end)

pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "kick" then return end
        return oldNamecall(self, ...)
    end)
end)

t_spawn(function()
    pcall(function()
        S.GS.ErrorMessageChanged:Connect(function()
            t_wait(2); S.TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
end)

local function applyAllSmoothGraphics(v)
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
        v.CastShadow = false
        for _, descendant in ipairs(v:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 1 
            end
        end
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1 
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Lifetime = NumberRange.new(0) 
    elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
        v.Enabled = false 
    elseif v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
        v.Enabled = false 
    elseif v:IsA("Explosion") then
        v.BlastPressure = 1
        v.BlastRadius = 1
    end
end

t_spawn(function()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
        S.L.GlobalShadows = false
        S.L.FogEnd = 9e9
        S.L.Brightness = 2 

        local Terrain = S.W:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end

        for _, v in ipairs(S.W:GetDescendants()) do
            pcall(applyAllSmoothGraphics, v)
        end

        S.W.DescendantAdded:Connect(function(v)
            pcall(applyAllSmoothGraphics, v)
        end)
    end)
end)

t_spawn(function()
    S.RS.RenderStepped:Connect(function()
        pcall(function()
            if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Health > 0 then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    LP.Character.Humanoid:Move(v3_new(0, 0, -1), true)
                end
            end
        end)
    end)
end)

local function SyncBananaTarget()
    if bLabel and bLabel.Parent and bLabel.Text then
        local n = string.match(bLabel.Text, "Target %([%s]*([%w_]+)")
        if n then local p = S.P:FindFirstChild(n); return p and p.Character or nil end
        return nil
    end
    if tick() - lastUISearch > 2 then
        lastUISearch = tick()
        for _, v in ipairs(S.CG:GetDescendants()) do 
            if v:IsA("TextLabel") and v.Text and string.find(v.Text, "Target %(") then bLabel = v; break end 
        end
        if not bLabel then
             local pGui = LP:FindFirstChild("PlayerGui")
             if pGui then
                 for _, v in ipairs(pGui:GetDescendants()) do 
                     if v:IsA("TextLabel") and v.Text and string.find(v.Text, "Target %(") then bLabel = v; break end 
                 end
             end
        end
    end
    return nil
end

local function SmartEquipFruit()
    if not LP.Character then return nil end
    local tip = "Blox Fruit"
    for _, v in ipairs(LP.Backpack:GetChildren()) do 
        if v:IsA("Tool") and (v.ToolTip == tip or v.Name:match(tip)) then return v end 
    end
    for _, v in ipairs(LP.Character:GetChildren()) do 
        if v:IsA("Tool") and (v.ToolTip == tip or v.Name:match(tip)) then return v end 
    end
    return nil
end

t_spawn(function()
    local tmr, last = {}, tick()
    while t_wait(0.1) do
        local now, dt = tick(), tick() - last; last = now
        pcall(function()
            local hp = LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Health or 0
            local t = SyncBananaTarget()
            
            if t then getgenv().LastTargetName = t.Name end
            if hp >= 7000 and getgenv().Retreating then getgenv().Retreating = false end

            if hp > 0 and hp < 4000 and not getgenv().Retreating then
                getgenv().Retreating = true
                local eName = getgenv().LastTargetName
                if eName then
                    getgenv().RetreatTracker[eName] = (getgenv().RetreatTracker[eName] or 0) + 1
                    if getgenv().RetreatTracker[eName] >= 3 then
                        Blacklist[eName] = tick()
                        local bGuy = S.P:FindFirstChild(eName)
                        if bGuy and bGuy.Character and bGuy.Character:FindFirstChild("HumanoidRootPart") then
                            pcall(function() bGuy.Character.HumanoidRootPart.CFrame = cf_new(0, 50000, 0) end)
                        end
                        getgenv().LockedTarget = nil
                        return
                    end
                end
            end

            if t and t:FindFirstChild("HumanoidRootPart") and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                if Blacklist[t.Name] and tick() - Blacklist[t.Name] < 300 then
                    getgenv().LockedTarget = nil; return
                end

                local d = (LP.Character.HumanoidRootPart.Position - t.HumanoidRootPart.Position).Magnitude
                getgenv().LockedTarget = (d <= 300 and not getgenv().Retreating) and t or nil

                if getgenv().LockedTarget == t then
                    tmr[t.Name] = (tmr[t.Name] or 0) + dt
                    
                    if getgenv().Setting and getgenv().Setting.Hitbox and getgenv().Setting.Hitbox.Enabled then
                        local sz = getgenv().Setting.Hitbox.Size or 60
                        if t.HumanoidRootPart.Size.X ~= sz then
                            t.HumanoidRootPart.Size = v3_new(sz, sz, sz)
                            t.HumanoidRootPart.Transparency = getgenv().Setting.Hitbox.Transparency or 0.7
                            t.HumanoidRootPart.CanCollide = false
                        end
                    end
                    
                    if tmr[t.Name] >= 25 then
                        Blacklist[t.Name] = tick()
                        pcall(function() t.HumanoidRootPart.CFrame = cf_new(0, 50000, 0) end)
                        getgenv().LockedTarget, tmr[t.Name] = nil, nil
                    end
                elseif not getgenv().Retreating then
                    tmr[t.Name] = 0
                end
            else
                getgenv().LockedTarget = nil
            end
        end)
        
        pcall(function()
            if getgenv().LockedTarget and LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Health > 0 then
                local eT = SmartEquipFruit()
                if eT and eT.Parent ~= LP.Character then LP.Character.Humanoid:EquipTool(eT) end
            end
        end)
    end
end)

local lastRandTick, rX, rY, rZ = 0, 0, 5, 5
S.RS.Heartbeat:Connect(function()
    pcall(function()
        local t = getgenv().LockedTarget
        if t and t:FindFirstChild("HumanoidRootPart") and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            local tHrp = t.HumanoidRootPart
            
            local d = (hrp.Position - tHrp.Position).Magnitude
            if d <= 50 then
                local now = tick()
                if now - lastRandTick > 0.1 then
                    rX = m_random(-10, 10)
                    rY = m_random(2, 10)
                    rZ = m_random(-10, 10)
                    lastRandTick = now
                end
                hrp.CFrame = tHrp.CFrame * cf_new(rX, rY, rZ)
                hrp.AssemblyLinearVelocity = v3_new(0, 0, 0)
                hrp.AssemblyAngularVelocity = v3_new(0, 0, 0)
            end
        end
    end)
end)

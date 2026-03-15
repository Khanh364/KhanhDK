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

getgenv().Setting = { Hitbox = { Enabled = true, Size = 60, Transparency = 0.7 } }
getgenv().LockedTarget = nil

-- === GIẢM LAG TỐI ĐA ===
local function applySmooth(v)
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1 
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0) 
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false 
        elseif v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
            v.Enabled = false 
        end
    end)
end

t_spawn(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 
    S.L.GlobalShadows = false
    S.L.FogEnd = 9e9
    local Terrain = S.W:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0
    end
    for _, v in ipairs(S.W:GetDescendants()) do applySmooth(v) end
    S.W.DescendantAdded:Connect(applySmooth)
end)

-- === LOGIC BOUNTY & KILLS ===
local function getRealBounty()
    local ls = LP:FindFirstChild("leaderstats")
    local b = ls and (ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor") or ls:FindFirstChild("Bounty/Honor"))
    if b then 
        local val = tostring(b.Value):upper():gsub(",", ""):gsub("%$", "")
        if val:match("M") then return (tonumber(val:gsub("M", "")) or 0) * 1000000
        elseif val:match("K") then return (tonumber(val:gsub("K", "")) or 0) * 1000 end
        return tonumber(val) or 0
    end
    return 0
end

local FileName = "SkibidiStats_" .. LP.UserId .. ".txt"
local function SaveStats(e, k) pcall(function() if writefile then writefile(FileName, e .. "|" .. k) end end) end
local function LoadStats()
    local e, k = 0, 0
    pcall(function()
        if isfile and readfile and isfile(FileName) then 
            local d = readfile(FileName):split("|")
            e, k = tonumber(d[1]) or 0, tonumber(d[2]) or 0
        end 
    end)
    return e, k
end

local TotalEarned, TotalKills = LoadStats()
local LastBounty, FrameCount, CurrentFPS = -1, 0, 0

-- === GIAO DIỆN CHÍNH ===
local ScreenGui = Instance.new("ScreenGui", type(gethui) == "function" and gethui() or S.CG)
local MainFrame = Instance.new("Frame", ScreenGui)
local ToggleBtn = Instance.new("TextButton", ScreenGui)

MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 190)
MainFrame.Active = true
MainFrame.Draggable = false

-- NÚT VIP HÌNH VUÔNG BÉ
ToggleBtn.Size = UDim2.new(0, 35, 0, 35)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleBtn.Text = "VIP"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Gotham
ToggleBtn.TextSize = 11
ToggleBtn.Active = true
ToggleBtn.Draggable = true 

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(85, 170, 255)

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Thickness = 1
ToggleStroke.Color = Color3.fromRGB(85, 170, 255)

local function CreateLabel(pos, color, text, size)
    local l = Instance.new("TextLabel", MainFrame)
    l.BackgroundTransparency = 1; l.Position = pos; l.Size = UDim2.new(0, 330, 0, 20)
    l.Font = Enum.Font.GothamBold; l.TextColor3 = color; l.TextSize = size or 15
    l.Text = text; l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local Tl = CreateLabel(UDim2.new(0.05,0,0.05,0), Color3.fromRGB(85,170,255), "SKIBIDI VIP PRO", 18)
local L1 = CreateLabel(UDim2.new(0.05,0,0.22,0), Color3.fromRGB(255,255,255), "TOTAL: --")
local L2 = CreateLabel(UDim2.new(0.05,0,0.38,0), Color3.fromRGB(0,255,120), "EARNED: 0")
local L3 = CreateLabel(UDim2.new(0.05,0,0.54,0), Color3.fromRGB(255,200,50), "BPH: 0/h")
local L4 = CreateLabel(UDim2.new(0.05,0,0.70,0), Color3.fromRGB(255,85,85), "KILLS: 0")
local L5 = CreateLabel(UDim2.new(0.05,0,0.86,0), Color3.fromRGB(200,200,200), "FPS: --", 12)

-- === NÚT RESET XANH ĐẬM + VIỀN CHỮ ===
local ResetBtn = Instance.new("TextButton", MainFrame)
ResetBtn.Size = UDim2.new(0, 160, 0, 35)
ResetBtn.Position = UDim2.new(1, -170, 1, -40)
ResetBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 150)
ResetBtn.Text = "Reset bounty Skibidi"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.TextSize = 12

-- ĐƯỜNG VIỀN CHỮ (Text Stroke)
ResetBtn.TextStrokeTransparency = 0 -- Hiện rõ viền
ResetBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Viền đen cho nổi chữ trắng

Instance.new("UICorner", ResetBtn)

ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
ResetBtn.MouseButton1Click:Connect(function()
    TotalEarned, TotalKills = 0, 0; LastBounty = getRealBounty(); SaveStats(0, 0)
    L2.Text = "EARNED: 0"; L4.Text = "KILLS: 0"
end)

-- === CẬP NHẬT CHỈ SỐ ===
S.RS.RenderStepped:Connect(function() FrameCount = FrameCount + 1 end)
t_spawn(function() while t_wait(1) do CurrentFPS = FrameCount; FrameCount = 0 end end)

t_spawn(function()
    while t_wait(1) do
        pcall(function()
            local cur = getRealBounty()
            if LastBounty == -1 then LastBounty = cur end
            if cur > LastBounty and cur < 30000000 then
                TotalEarned = TotalEarned + (cur - LastBounty); TotalKills = TotalKills + 1; SaveStats(TotalEarned, TotalKills)
            end
            LastBounty = cur
            L1.Text = "TOTAL: " .. (cur >= 1000000 and string.format("%.2fM", cur/1000000) or cur)
            L2.Text = "EARNED: +" .. (TotalEarned >= 1000 and string.format("%.1fK", TotalEarned/1000) or TotalEarned)
            L3.Text = "BPH: " .. TotalEarned .. "/h"
            L4.Text = "KILLS: " .. TotalKills
            L5.Text = string.format("FPS: %d | PING: %d ms", CurrentFPS, m_floor(LP:GetNetworkPing()*1000))
        end)
    end
end)

-- Anti-AFK & Chống ngồi
t_spawn(function()
    S.RS.RenderStepped:Connect(function()
        pcall(function()
            if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                LP.Character.Humanoid:Move(v3_new(0, 0, -1), true)
                if LP.Character.Humanoid.Sit then LP.Character.Humanoid.Sit = false end
            end
        end)
    end)
end)

function SyncTarget()
    for _, v in ipairs(S.CG:GetDescendants()) do 
        if v:IsA("TextLabel") and v.Text and v.Text:find("Target %(") then 
            local n = v.Text:match("Target %([%s]*([%w_]+)")
            local p = n and S.P:FindFirstChild(n)
            return p and p.Character
        end 
    end
    return nil
end

t_spawn(function()
    while t_wait(0.1) do
        pcall(function()
            local t = SyncTarget()
            if t and t:FindFirstChild("HumanoidRootPart") and t.Humanoid.Health > 0 then
                getgenv().LockedTarget = t
                t.HumanoidRootPart.Size = v3_new(60,60,60)
                t.HumanoidRootPart.Transparency = 0.7
                t.HumanoidRootPart.CanCollide = false
            else getgenv().LockedTarget = nil end
        end)
    end
end)

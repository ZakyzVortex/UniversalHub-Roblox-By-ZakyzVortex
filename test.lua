-- ================== UNIVERSAL HUB - ORGANIZED VERSION (FIXED) ==================
-- Universal Hub Rayfield By ZakyzVortex (Mobile Optimized & Organized)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================== CHARACTER REFS ==================
local Character, Humanoid, HRP
local function BindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid.UseJumpPower = true
end

if LP.Character then
    BindCharacter(LP.Character)
else
    LP.CharacterAdded:Wait()
    BindCharacter(LP.Character)
end

LP.CharacterAdded:Connect(BindCharacter)

-- ================== FUNÇÃO PARA ESCONDER OBJETOS 3D DO JOGO ==================
local function resetVisuals()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local hiddenCount = 0
    
    local function hide(obj)
        if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then 
            return 
        end
        
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            hiddenCount = hiddenCount + 1
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
            hiddenCount = hiddenCount + 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
            hiddenCount = hiddenCount + 1
        elseif obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
            hiddenCount = hiddenCount + 1
        end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        hide(obj)
    end
    
    workspace.DescendantAdded:Connect(hide)
    
    print("✅ " .. hiddenCount .. " objetos 3D escondidos!")
    print("✅ FPS otimizado para AFK farm!")
end

-- ================== TEAM DETECTION SYSTEM ==================
local function getPlayerTeam(player)
    if not player then return nil end
    return player.Team
end

local function isPlayerOnSameTeam(player)
    if not player or player == LP then return false end
    local myTeam = getPlayerTeam(LP)
    local theirTeam = getPlayerTeam(player)
    
    if not myTeam or not theirTeam then return false end
    
    return myTeam == theirTeam
end

local function shouldShowPlayer(player, filterMode)
    if not player or player == LP then return false end
    
    if filterMode == "All" then
        return true
    elseif filterMode == "MyTeam" or filterMode == "Team" then
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        if not myTeam or not theirTeam then return false end
        return myTeam == theirTeam
    elseif filterMode == "EnemyTeam" or filterMode == "Enemy" then
        local myTeam = getPlayerTeam(LP)
        local theirTeam = getPlayerTeam(player)
        
        if not myTeam or not theirTeam then return true end
        
        return myTeam ~= theirTeam
    end
    
    return true
end

-- ================== WINDOW ==================
local Window = WindUI:CreateWindow({
    Title = "Universal Hub",
    SubTitle = "By ZakyzVortex",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = true,
    Theme = "Dark",
})

-- ================== CREATE TABS ==================
local TabMove = Window:Tab({Title = "Movement", Icon = "person-walking"})
local TabCombat = Window:Tab({Title = "Auto Farm", Icon = "swords"})
local TabESP = Window:Tab({Title = "ESP", Icon = "eye"})
local TabHighlight = Window:Tab({Title = "Highlight ESP", Icon = "highlighter"})
local TabAim = Window:Tab({Title = "Aim Assist", Icon = "crosshair"})
local TabPlayerAim = Window:Tab({Title = "Player Aim", Icon = "target"})
local TabProt = Window:Tab({Title = "Protection", Icon = "shield"})
local TabPlayers = Window:Tab({Title = "Players", Icon = "users"})
local TabWaypoints = Window:Tab({Title = "Waypoints", Icon = "map-pin"})
local TabVisuals = Window:Tab({Title = "Visuals", Icon = "palette"})
local TabWorld = Window:Tab({Title = "World", Icon = "globe"})
local TabFPS = Window:Tab({Title = "FPS/Stats", Icon = "activity"})
local TabConfig = Window:Tab({Title = "Config", Icon = "settings"})
local TabUtil = Window:Tab({Title = "Utility", Icon = "wrench"})

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:Section({Title = "Velocidade e Pulo"})

-- Estados
local infJump, antiFall = false, false

-- Velocidade
TabMove:Slider({
    Title = "Velocidade de Caminhada",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(v)
        if Humanoid then
            Humanoid.WalkSpeed = v
        end
    end
})

-- Pulo
TabMove:Slider({
    Title = "Poder de Pulo",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:Section({Title = "Fly System"})

-- ================== FLY SYSTEM ==================
local flyEnabled = false
local flySpeed = 1
local tpwalking = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}
local flyUpImpulse = 0

local function toggleFly(enabled)
    flyEnabled = enabled
    local speaker = LP
    local chr = speaker.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    
    if not chr or not hum then return end
    
    if enabled then
        chr.Animate.Disabled = true
        local AnimController = chr:FindFirstChildWhichIsA("Humanoid") or chr:FindFirstChildOfClass("AnimationController")
        for i,v in next, AnimController:GetPlayingAnimationTracks() do
            v:AdjustSpeed(0)
        end
        
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        
        for i = 1, flySpeed do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat
                tpwalking = true
                local chr = LP.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
    else
        tpwalking = false
        chr.Animate.Disabled = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        
        if HRP:FindFirstChild("FlyVel") then HRP.FlyVel:Destroy() end
        if HRP:FindFirstChild("FlyGyro") then HRP.FlyGyro:Destroy() end
    end
end

TabMove:Slider({
    Title = "Velocidade de Fly",
    Min = 1,
    Max = 10,
    Default = 1,
    Callback = function(v)
        flySpeed = v
    end
})

TabMove:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(v)
        toggleFly(v)
    end
})

TabMove:Section({Title = "Outros"})

TabMove:Toggle({
    Title = "Pulo Infinito",
    Value = false,
    Callback = function(v)
        infJump = v
    end
})

TabMove:Toggle({
    Title = "Anti Queda",
    Value = false,
    Callback = function(v)
        antiFall = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================================================================================
-- ============================== AUTO FARM TAB =====================================
-- ==================================================================================

TabCombat:Section({Title = "Auto Click"})

local autoClickEnabled = false
local autoClickSpeed = 0.1

TabCombat:Slider({
    Title = "Velocidade (s)",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Callback = function(v)
        autoClickSpeed = v
    end
})

TabCombat:Toggle({
    Title = "Auto Click",
    Value = false,
    Callback = function(v)
        autoClickEnabled = v
        if v then
            spawn(function()
                while autoClickEnabled do
                    mouse1click()
                    task.wait(autoClickSpeed)
                end
            end)
        end
    end
})

TabCombat:Section({Title = "Kill Aura"})

local killAuraEnabled = false
local killAuraRange = 20
local killAuraTeamMode = "All"

TabCombat:Slider({
    Title = "Alcance",
    Min = 5,
    Max = 100,
    Default = 20,
    Callback = function(v)
        killAuraRange = v
    end
})

TabCombat:Dropdown({
    Title = "Filtro de Time",
    List = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        killAuraTeamMode = v
    end
})

local function getNearestPlayer()
    local nearest, nearestDist = nil, math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and shouldShowPlayer(p, killAuraTeamMode) then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local dist = (HRP.Position - hrp.Position).Magnitude
                if dist < killAuraRange and dist < nearestDist then
                    nearest = p
                    nearestDist = dist
                end
            end
        end
    end
    
    return nearest
end

TabCombat:Toggle({
    Title = "Kill Aura",
    Value = false,
    Callback = function(v)
        killAuraEnabled = v
        if v then
            spawn(function()
                while killAuraEnabled do
                    local target = getNearestPlayer()
                    if target and target.Character then
                        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            local tool = LP.Character:FindFirstChildOfClass("Tool")
                            if tool and tool:FindFirstChild("Handle") then
                                tool:Activate()
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ==================================================================================
-- ============================== ESP TAB ===========================================
-- ==================================================================================

TabESP:Section({Title = "ESP Configurações"})

local espEnabled = false
local espTeamMode = "All"
local espDistance = 1000
local espBoxes, espNames, espHealth, espTracers = true, true, true, false
local espConnections = {}

local function clearAllESP()
    for _, conn in pairs(espConnections) do
        if conn.Disconnect then conn:Disconnect() end
    end
    espConnections = {}
    
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            for _, obj in pairs(p.Character:GetDescendants()) do
                if obj.Name == "ESPBox" or obj.Name == "ESPName" or obj.Name == "ESPHealth" or obj.Name == "ESPTracer" then
                    obj:Destroy()
                end
            end
        end
    end
end

local function createESP(player)
    if not player or player == LP then return end
    if not shouldShowPlayer(player, espTeamMode) then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    -- Box
    if espBoxes then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.new(1, 1, 1)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false
        
        local conn = RunService.RenderStepped:Connect(function()
            if not char or not hrp or not hum or hum.Health <= 0 or not espEnabled then
                box:Remove()
                conn:Disconnect()
                return
            end
            
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist > espDistance then
                box.Visible = false
                return
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local size = (Camera.CFrame.Position - hrp.Position).Magnitude
                local factor = 1 / (size * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
                box.Size = Vector2.new(math.floor(40 * factor), math.floor(60 * factor))
                box.Position = Vector2.new(math.floor(vector.X - box.Size.X / 2), math.floor(vector.Y - box.Size.Y / 2))
                box.Visible = true
            else
                box.Visible = false
            end
        end)
        
        table.insert(espConnections, conn)
    end
    
    -- Name
    if espNames then
        local text = Drawing.new("Text")
        text.Text = player.Name
        text.Size = 16
        text.Center = true
        text.Outline = true
        text.Color = Color3.new(1, 1, 1)
        text.Visible = false
        
        local conn = RunService.RenderStepped:Connect(function()
            if not char or not hrp or not hum or hum.Health <= 0 or not espEnabled then
                text:Remove()
                conn:Disconnect()
                return
            end
            
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist > espDistance then
                text.Visible = false
                return
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
            if onScreen then
                text.Position = Vector2.new(vector.X, vector.Y)
                text.Visible = true
            else
                text.Visible = false
            end
        end)
        
        table.insert(espConnections, conn)
    end
    
    -- Health
    if espHealth then
        local healthText = Drawing.new("Text")
        healthText.Size = 14
        healthText.Center = true
        healthText.Outline = true
        healthText.Color = Color3.new(0, 1, 0)
        healthText.Visible = false
        
        local conn = RunService.RenderStepped:Connect(function()
            if not char or not hrp or not hum or hum.Health <= 0 or not espEnabled then
                healthText:Remove()
                conn:Disconnect()
                return
            end
            
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist > espDistance then
                healthText.Visible = false
                return
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            if onScreen then
                local health = math.floor(hum.Health)
                local maxHealth = math.floor(hum.MaxHealth)
                healthText.Text = health .. "/" .. maxHealth
                healthText.Position = Vector2.new(vector.X, vector.Y)
                
                local healthPercent = health / maxHealth
                healthText.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                healthText.Visible = true
            else
                healthText.Visible = false
            end
        end)
        
        table.insert(espConnections, conn)
    end
    
    -- Tracers
    if espTracers then
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.new(1, 1, 1)
        line.Transparency = 1
        line.Visible = false
        
        local conn = RunService.RenderStepped:Connect(function()
            if not char or not hrp or not hum or hum.Health <= 0 or not espEnabled then
                line:Remove()
                conn:Disconnect()
                return
            end
            
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist > espDistance then
                line.Visible = false
                return
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(vector.X, vector.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end)
        
        table.insert(espConnections, conn)
    end
end

local function updateESP()
    clearAllESP()
    if not espEnabled then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            createESP(p)
        end
    end
end

TabESP:Dropdown({
    Title = "Filtro de Time",
    List = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        espTeamMode = v
        updateESP()
    end
})

TabESP:Slider({
    Title = "Distância Máxima",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Callback = function(v)
        espDistance = v
    end
})

TabESP:Toggle({
    Title = "Boxes",
    Value = true,
    Callback = function(v)
        espBoxes = v
        updateESP()
    end
})

TabESP:Toggle({
    Title = "Names",
    Value = true,
    Callback = function(v)
        espNames = v
        updateESP()
    end
})

TabESP:Toggle({
    Title = "Health",
    Value = true,
    Callback = function(v)
        espHealth = v
        updateESP()
    end
})

TabESP:Toggle({
    Title = "Tracers",
    Value = false,
    Callback = function(v)
        espTracers = v
        updateESP()
    end
})

TabESP:Toggle({
    Title = "Ativar ESP",
    Value = false,
    Callback = function(v)
        espEnabled = v
        updateESP()
    end
})

-- ==================================================================================
-- ============================== HIGHLIGHT ESP TAB =================================
-- ==================================================================================

TabHighlight:Section({Title = "Highlight ESP"})

local highlightEnabled = false
local highlightTeamMode = "All"
local highlightFillColor = Color3.new(1, 0, 0)
local highlightOutlineColor = Color3.new(1, 1, 1)
local highlightTransparency = 0.5
local activeHighlights = {}

local function removeAllHighlights()
    for player, highlight in pairs(activeHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    activeHighlights = {}
end

local function createHighlight(player)
    if not player or player == LP then return end
    if not shouldShowPlayer(player, highlightTeamMode) then return end
    
    local char = player.Character
    if not char then return end
    
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.FillColor = highlightFillColor
    highlight.OutlineColor = highlightOutlineColor
    highlight.FillTransparency = highlightTransparency
    highlight.OutlineTransparency = 0
    highlight.Parent = char
    
    activeHighlights[player] = highlight
end

local function updateHighlights()
    removeAllHighlights()
    if not highlightEnabled then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            createHighlight(p)
        end
    end
end

TabHighlight:Dropdown({
    Title = "Filtro de Time",
    List = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        highlightTeamMode = v
        updateHighlights()
    end
})

TabHighlight:Slider({
    Title = "Transparência",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Callback = function(v)
        highlightTransparency = v
        for _, highlight in pairs(activeHighlights) do
            if highlight then
                highlight.FillTransparency = v
            end
        end
    end
})

TabHighlight:Toggle({
    Title = "Ativar Highlight",
    Value = false,
    Callback = function(v)
        highlightEnabled = v
        updateHighlights()
    end
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if highlightEnabled then
            createHighlight(player)
        end
    end)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LP then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if highlightEnabled then
                createHighlight(player)
            end
        end)
    end
end

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

TabAim:Section({Title = "Aim Assist"})

local aimAssistEnabled = false
local aimAssistSmoothing = 0.5
local aimAssistTeamMode = "All"
local aimPart = "Head"
local wallCheckEnabled = true

local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    local myPos = Camera.CFrame.Position
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and shouldShowPlayer(p, aimAssistTeamMode) then
            local char = p.Character
            local part = char:FindFirstChild(aimPart) or char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if part and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    if wallCheckEnabled then
                        local ray = Ray.new(myPos, (part.Position - myPos).Unit * (part.Position - myPos).Magnitude)
                        local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, char})
                        
                        if hitPart then
                            continue
                        end
                    end
                    
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if dist < closestDist then
                        closest = part
                        closestDist = dist
                    end
                end
            end
        end
    end
    
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimAssistEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayer()
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mousePos = UserInputService:GetMouseLocation()
            
            local moveX = (targetPos.X - mousePos.X) * aimAssistSmoothing
            local moveY = (targetPos.Y - mousePos.Y) * aimAssistSmoothing
            
            mousemoverel(moveX, moveY)
        end
    end
end)

TabAim:Slider({
    Title = "Suavização",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Callback = function(v)
        aimAssistSmoothing = v
    end
})

TabAim:Dropdown({
    Title = "Parte do Corpo",
    List = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(v)
        aimPart = v
    end
})

TabAim:Dropdown({
    Title = "Filtro de Time",
    List = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        aimAssistTeamMode = v
    end
})

TabAim:Toggle({
    Title = "Wall Check",
    Value = true,
    Callback = function(v)
        wallCheckEnabled = v
    end
})

TabAim:Toggle({
    Title = "Ativar Aim Assist",
    Value = false,
    Callback = function(v)
        aimAssistEnabled = v
    end
})

-- ==================================================================================
-- ============================== PLAYER AIM TAB ====================================
-- ==================================================================================

TabPlayerAim:Section({Title = "Aim em Jogador Específico"})

local playerAimEnabled = false
local targetPlayerName = ""
local playerAimSmoothing = 0.5
local playerAimPart = "Head"

local function getTargetPlayer()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == targetPlayerName and p.Character then
            local part = p.Character:FindFirstChild(playerAimPart) or p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if part and hum and hum.Health > 0 then
                local _, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    return part
                end
            end
        end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    if playerAimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getTargetPlayer()
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mousePos = UserInputService:GetMouseLocation()
            
            local moveX = (targetPos.X - mousePos.X) * playerAimSmoothing
            local moveY = (targetPos.Y - mousePos.Y) * playerAimSmoothing
            
            mousemoverel(moveX, moveY)
        end
    end
end)

local playerList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        table.insert(playerList, p.Name)
    end
end

TabPlayerAim:Dropdown({
    Title = "Jogador Alvo",
    List = playerList,
    Default = playerList[1] or "",
    Callback = function(v)
        targetPlayerName = v
    end
})

TabPlayerAim:Slider({
    Title = "Suavização",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Callback = function(v)
        playerAimSmoothing = v
    end
})

TabPlayerAim:Dropdown({
    Title = "Parte do Corpo",
    List = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(v)
        playerAimPart = v
    end
})

TabPlayerAim:Toggle({
    Title = "Ativar Player Aim",
    Value = false,
    Callback = function(v)
        playerAimEnabled = v
    end
})

TabPlayerAim:Button({
    Title = "Atualizar Lista de Jogadores",
    Callback = function()
        playerList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                table.insert(playerList, p.Name)
            end
        end
    end
})

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:Section({Title = "Proteção"})

local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:Toggle({
    Title = "God Mode",
    Value = false,
    Callback = function(v)
        godMode = v
    end
})

TabProt:Toggle({
    Title = "Lock HP",
    Value = false,
    Callback = function(v)
        lockHP = v
    end
})

TabProt:Toggle({
    Title = "Anti Void",
    Value = false,
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:Toggle({
    Title = "Anti Knockback",
    Value = false,
    Callback = function(v)
        antiKB = v
    end
})

TabProt:Section({Title = "Remoção de Dano"})

TabProt:Button({
    Title = "Remover FF (ForceField)",
    Callback = function()
        if Character then
            for _, ff in pairs(Character:GetChildren()) do
                if ff:IsA("ForceField") then
                    ff:Destroy()
                end
            end
        end
    end
})

-- ==================================================================================
-- ============================== PLAYERS TAB =======================================
-- ==================================================================================

TabPlayers:Section({Title = "Ações de Jogadores"})

local selectedPlayer = ""

local function getPlayersList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(list, p.Name)
        end
    end
    return list
end

TabPlayers:Dropdown({
    Title = "Selecionar Jogador",
    List = getPlayersList(),
    Default = getPlayersList()[1] or "",
    Callback = function(v)
        selectedPlayer = v
    end
})

TabPlayers:Button({
    Title = "Teleportar para Jogador",
    Callback = function()
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if targetPlayer and targetPlayer.Character and HRP then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame
            end
        end
    end
})

TabPlayers:Button({
    Title = "Ver Jogador (Spectate)",
    Callback = function()
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if targetPlayer and targetPlayer.Character then
            Camera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TabPlayers:Button({
    Title = "Voltar para Si Mesmo",
    Callback = function()
        if Character then
            Camera.CameraSubject = Humanoid
        end
    end
})

TabPlayers:Button({
    Title = "Atualizar Lista",
    Callback = function()
        -- A lista será atualizada automaticamente
    end
})

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

TabWaypoints:Section({Title = "Waypoints"})

local waypoints = {}

TabWaypoints:Button({
    Title = "Salvar Posição Atual",
    Callback = function()
        if HRP then
            local pos = HRP.Position
            table.insert(waypoints, {name = "Waypoint " .. #waypoints + 1, position = pos})
        end
    end
})

TabWaypoints:Button({
    Title = "Teleportar para Último Waypoint",
    Callback = function()
        if #waypoints > 0 and HRP then
            HRP.CFrame = CFrame.new(waypoints[#waypoints].position)
        end
    end
})

TabWaypoints:Button({
    Title = "Limpar Waypoints",
    Callback = function()
        waypoints = {}
    end
})

-- ==================================================================================
-- ============================== VISUALS TAB =======================================
-- ==================================================================================

TabVisuals:Section({Title = "Visual"})

local fullbrightEnabled = false
local ambientOriginal = Lighting.Ambient
local brightnessOriginal = Lighting.Brightness
local colorShiftBOriginal = Lighting.ColorShift_Bottom
local colorShiftTOriginal = Lighting.ColorShift_Top
local outdoorAmbientOriginal = Lighting.OutdoorAmbient

local function toggleFullbright(enabled)
    if enabled then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = ambientOriginal
        Lighting.Brightness = brightnessOriginal
        Lighting.ColorShift_Bottom = colorShiftBOriginal
        Lighting.ColorShift_Top = colorShiftTOriginal
        Lighting.OutdoorAmbient = outdoorAmbientOriginal
        Lighting.GlobalShadows = true
    end
end

TabVisuals:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v)
        fullbrightEnabled = v
        toggleFullbright(v)
    end
})

TabVisuals:Section({Title = "FOV"})

TabVisuals:Slider({
    Title = "Campo de Visão (FOV)",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

-- ==================================================================================
-- ============================== WORLD TAB =========================================
-- ==================================================================================

TabWorld:Section({Title = "Mundo"})

TabWorld:Slider({
    Title = "Gravidade",
    Min = 0,
    Max = 196.2,
    Default = 196.2,
    Callback = function(v)
        Workspace.Gravity = v
    end
})

TabWorld:Slider({
    Title = "Horário do Dia",
    Min = 0,
    Max = 24,
    Default = 14,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:Button({
    Title = "Remover Fog (Neblina)",
    Callback = function()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end
})

TabWorld:Button({
    Title = "Esconder Objetos 3D (FPS Boost)",
    Callback = function()
        resetVisuals()
    end
})

-- ==================================================================================
-- ============================== FPS/STATS TAB =====================================
-- ==================================================================================

TabFPS:Section({Title = "FPS e Performance"})

local fpsLabel = TabFPS:Label({Title = "FPS: Calculando..."})
local pingLabel = TabFPS:Label({Title = "Ping: Calculando..."})
local memLabel = TabFPS:Label({Title = "Memória: Calculando..."})

spawn(function()
    while task.wait(1) do
        local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        local mem = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
        
        -- WindUI não tem método Update para labels, então vamos recriar
        -- Nota: Isso pode causar problemas, idealmente WindUI deveria ter um Update
    end
end)

TabFPS:Section({Title = "Otimização"})

TabFPS:Button({
    Title = "Reduzir Lag (Remover Efeitos)",
    Callback = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj:Destroy()
            end
        end
    end
})

-- ==================================================================================
-- ============================== CONFIG TAB ========================================
-- ==================================================================================

TabConfig:Section({Title = "Keybinds"})

local keybindESP = Enum.KeyCode.E
local keybindHighlight = Enum.KeyCode.H
local keybindAim = Enum.KeyCode.R
local keybindPlayerAim = Enum.KeyCode.T
local keybindFly = Enum.KeyCode.F
local keybindNoclip = Enum.KeyCode.N
local keybindInfJump = Enum.KeyCode.J
local keybindAutoClick = Enum.KeyCode.C
local keybindGodMode = Enum.KeyCode.G
local keybindFullbright = Enum.KeyCode.B
local keybindGUI = Enum.KeyCode.RightControl

local noclip = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == keybindESP then
        espEnabled = not espEnabled
        updateESP()
        
    elseif input.KeyCode == keybindHighlight then
        highlightEnabled = not highlightEnabled
        updateHighlights()
        
    elseif input.KeyCode == keybindAim then
        aimAssistEnabled = not aimAssistEnabled
        
    elseif input.KeyCode == keybindPlayerAim then
        playerAimEnabled = not playerAimEnabled
        
    elseif input.KeyCode == keybindFly then
        toggleFly(not flyEnabled)
        
    elseif input.KeyCode == keybindNoclip then
        noclip = not noclip
        
    elseif input.KeyCode == keybindInfJump then
        infJump = not infJump
        
    elseif input.KeyCode == keybindAutoClick then
        autoClickEnabled = not autoClickEnabled
        if autoClickEnabled then
            spawn(function()
                while autoClickEnabled do
                    mouse1click()
                    task.wait(autoClickSpeed)
                end
            end)
        end
        
    elseif input.KeyCode == keybindGodMode then
        godMode = not godMode
        
    elseif input.KeyCode == keybindFullbright then
        fullbrightEnabled = not fullbrightEnabled
        toggleFullbright(fullbrightEnabled)
        
    elseif input.KeyCode == keybindGUI then
        -- Toggle GUI visibility
        game:GetService("CoreGui"):FindFirstChild("WindUI"):Enabled = not game:GetService("CoreGui"):FindFirstChild("WindUI").Enabled
    end
end)

TabConfig:Section({Title = "Informações"})

TabConfig:Label({Title = "ESP: E | Highlight: H"})
TabConfig:Label({Title = "Aim: R | Player Aim: T"})
TabConfig:Label({Title = "Fly: F | Noclip: N"})
TabConfig:Label({Title = "Inf Jump: J | Auto Click: C"})
TabConfig:Label({Title = "God Mode: G | Fullbright: B"})
TabConfig:Label({Title = "Toggle GUI: RightControl"})

-- ==================================================================================
-- ============================== UTILITY TAB =======================================
-- ==================================================================================

TabUtil:Section({Title = "Noclip"})

TabUtil:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(v)
        noclip = v
    end
})

-- ================== SHIFT LOCK SYSTEM ==================
local shiftLockEnabled = false
local shiftLockRotConnection
local oldAutoRotate

local function lockMouse(enabled)
    if UserInputService.MouseEnabled then
        UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    end
end

local function faceCameraDirection(humanoid, rootPart, enabled)
    if shiftLockRotConnection then
        shiftLockRotConnection:Disconnect()
        shiftLockRotConnection = nil
    end
    
    if enabled then
        oldAutoRotate = humanoid.AutoRotate
        humanoid.AutoRotate = false
        
        shiftLockRotConnection = RunService.RenderStepped:Connect(function()
            local camera = Workspace.CurrentCamera
            if not rootPart or not camera then return end
            
            local lookVector = camera.CFrame.LookVector
            local flatVector = Vector3.new(lookVector.X, 0, lookVector.Z)
            
            if flatVector.Magnitude > 0.0001 then
                rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatVector.Unit, Vector3.yAxis)
            end
        end)
    else
        if oldAutoRotate ~= nil then
            humanoid.AutoRotate = oldAutoRotate
        end
    end
end

local function applyShiftLock(enabled)
    if not Character or not Humanoid or not HRP then 
        task.wait(0.5)
        if LP.Character then
            BindCharacter(LP.Character)
        end
        return 
    end
    
    shiftLockEnabled = enabled
    lockMouse(enabled)
    faceCameraDirection(Humanoid, HRP, enabled)
end

LP.CharacterAdded:Connect(function()
    task.defer(function()
        task.wait(0.5)
        if shiftLockEnabled then
            applyShiftLock(true)
        end
    end)
end)

local lastCamera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local currentCamera = Workspace.CurrentCamera
    if currentCamera ~= lastCamera then
        lastCamera = currentCamera
        if shiftLockEnabled then
            task.defer(function()
                applyShiftLock(true)
            end)
        end
    end
end)

TabUtil:Toggle({
    Title = "Shift Lock",
    Value = false,
    Callback = function(v)
        applyShiftLock(v)
    end
})

TabUtil:Toggle({
    Title = "Insta Interact",
    Value = false,
    Callback = function(v)
        _G.InstaInteract = v
        if _G.InstaInteract then
            _G.InstaInteractConnection = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
                fireproximityprompt(prompt)
            end)
        else
            if _G.InstaInteractConnection then
                _G.InstaInteractConnection:Disconnect()
            end
        end
    end
})

TabUtil:Section({Title = "Server"})

TabUtil:Button({
    Title = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

TabUtil:Button({
    Title = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(servers.data) do
            if s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                break
            end
        end
    end
})

-- ==================================================================================
-- ============================== RUNTIME LOOP ======================================
-- ==================================================================================

local lastRuntimeUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    if not Character or not HRP or not Humanoid then return end

    local now = tick()
    if now - lastRuntimeUpdate < 0.033 then return end
    lastRuntimeUpdate = now

    if flyUpImpulse > 0 then
        flyUpImpulse = flyUpImpulse - dt
    end

    if flyEnabled then
        if not HRP:FindFirstChild("FlyVel") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.Name = "FlyVel"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            local bg = Instance.new("BodyGyro", HRP)
            bg.Name = "FlyGyro"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        end
        local dir = Humanoid.MoveDirection
        local vel = Vector3.new(dir.X, 0, dir.Z) * flySpeed
        if flyUpImpulse > 0 then
            vel = vel + Vector3.new(0, flySpeed, 0)
        end
        HRP.FlyVel.Velocity = vel
        HRP.FlyGyro.CFrame = Camera.CFrame
    end

    if noclip then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end

    if godMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = Humanoid.MaxHealth
    elseif lockHP then
        Humanoid.Health = Humanoid.MaxHealth
    end

    if antiVoid and HRP.Position.Y < -80 then
        HRP.CFrame = HRP.CFrame + Vector3.new(0, 200, 0)
    end

    if antiKB then
        HRP.Velocity = HRP.Velocity * Vector3.new(0.8, 0.9, 0.8)
    end
end)

print("✅ Universal Hub - WindUI Complete Version!")
print("📊 ESP: Sistema completo com filtros de time")
print("✨ Highlight ESP: Sistema completo com cores e filtros")
print("🎯 Aim Assist: Wallcheck + Filtros de time")
print("🚀 Todas as funcionalidades convertidas para WindUI!")
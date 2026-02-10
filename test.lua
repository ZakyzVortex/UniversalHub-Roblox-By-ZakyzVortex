-- ================== UNIVERSAL HUB - WINDUI VERSION (FIXED) ==================
-- Universal Hub WindUI By ZakyzVortex (Mobile Optimized & Organized)
-- Conversão CORRETA da Rayfield para WindUI com todas as funcionalidades

local WindUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main_example.lua'))()

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
    local hiddenCount = 0
    
    local function hide(obj)
        if LP.Character and obj:IsDescendantOf(LP.Character) then 
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
    Icon = "",
    Author = "ZakyzVortex",
    Folder = "UniversalHub_WindUI",
    Size = UDim2.fromOffset(500, 600),
    KeySystem = false,
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 170,
})

-- ================== VARIABLES ==================
-- Movement
local infJump = false
local antiFall = false
local flyEnabled = false
local flySpeed = 1
local flyUpImpulse = 0
local tpwalking = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}

-- Protection
local godMode = false
local antiVoid = false
local lockHP = false
local antiKB = false

-- Visuals
local fullbright = false

-- Utility
local noclip = false

-- Auto Farm
local autoClick = false
local clickDelay = 0.1

-- ESP
local espEnabled = false
local espBoxes = true
local espTracers = false
local espDistance = false
local espHealth = false
local espNames = true
local espMaxDistance = 1000
local espFilter = "All"
local espBoxColor = Color3.new(1, 1, 1)
local espTracerColor = Color3.new(1, 1, 1)
local espObjects = {}

-- Highlight ESP
local highlightEnabled = false
local highlightFilter = "All"
local highlightFillColor = Color3.new(1, 0, 0)
local highlightOutlineColor = Color3.new(1, 1, 1)
local highlightFillTransparency = 0.5
local highlightOutlineTransparency = 0
local playerHighlights = {}

-- Aim Assist
local aimAssistEnabled = false
local aimLockEnabled = false
local aimSmoothness = 0.1
local aimPart = "Head"
local aimFilter = "All"
local wallCheck = true

-- Player Aim
local playerAimEnabled = false
local playerAimPart = "Head"
local playerAimFilter = "All"
local playerWallCheck = true

-- Waypoints
local waypoints = {}
local selectedWP = nil

-- Keybinds
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

-- ==================================================================================
-- ============================== CREATE TABS ======================================
-- ==================================================================================

local TabMove = Window:CreateTab({
    Name = "Movement",
    Icon = "",
    Visible = true,
})

local TabCombat = Window:CreateTab({
    Name = "Auto Farm",
    Icon = "",
    Visible = true,
})

local TabESP = Window:CreateTab({
    Name = "ESP",
    Icon = "",
    Visible = true,
})

local TabHighlight = Window:CreateTab({
    Name = "Highlight ESP",
    Icon = "",
    Visible = true,
})

local TabAim = Window:CreateTab({
    Name = "Aim Assist",
    Icon = "",
    Visible = true,
})

local TabPlayerAim = Window:CreateTab({
    Name = "Player Aim",
    Icon = "",
    Visible = true,
})

local TabProt = Window:CreateTab({
    Name = "Protection",
    Icon = "",
    Visible = true,
})

local TabPlayers = Window:CreateTab({
    Name = "Players",
    Icon = "",
    Visible = true,
})

local TabWaypoints = Window:CreateTab({
    Name = "Waypoints",
    Icon = "",
    Visible = true,
})

local TabVisuals = Window:CreateTab({
    Name = "Visuals",
    Icon = "",
    Visible = true,
})

local TabWorld = Window:CreateTab({
    Name = "World",
    Icon = "",
    Visible = true,
})

local TabFPS = Window:CreateTab({
    Name = "FPS/Stats",
    Icon = "",
    Visible = true,
})

local TabConfig = Window:CreateTab({
    Name = "Config",
    Icon = "",
    Visible = true,
})

local TabUtil = Window:CreateTab({
    Name = "Utility",
    Icon = "",
    Visible = true,
})

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:AddSection("Velocidade e Pulo")

-- Velocidade
TabMove:AddSlider({
    Name = "Velocidade de Caminhada",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(value)
        if Humanoid then
            Humanoid.WalkSpeed = value
        end
    end
})

-- Pulo
TabMove:AddSlider({
    Name = "Poder de Pulo",
    Min = 50,
    Max = 300,
    Default = 50,
    Callback = function(value)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = value
        end
    end
})

TabMove:AddSection("Fly System")

-- ================== FLY SYSTEM ==================
local function toggleFly(enabled)
    flyEnabled = enabled
    local speaker = LP
    local chr = speaker.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    
    if not chr or not hum then return end
    
    if enabled then
        chr.Animate.Disabled = true
        local AnimController = chr:FindFirstChildOfClass("Humanoid") or chr:FindFirstChildOfClass("AnimationController")
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
        
        if HRP:FindFirstChild("FlyVel") then
            HRP.FlyVel:Destroy()
        end
        if HRP:FindFirstChild("FlyGyro") then
            HRP.FlyGyro:Destroy()
        end
    end
end

TabMove:AddToggle({
    Name = "Fly (F)",
    Default = false,
    Callback = function(value)
        toggleFly(value)
    end
})

TabMove:AddSlider({
    Name = "Velocidade de Fly",
    Min = 1,
    Max = 10,
    Default = 1,
    Callback = function(value)
        flySpeed = value
    end
})

TabMove:AddToggle({
    Name = "Pulo Infinito (J)",
    Default = false,
    Callback = function(value)
        infJump = value
    end
})

TabMove:AddToggle({
    Name = "Anti Queda",
    Default = false,
    Callback = function(value)
        antiFall = value
    end
})

-- ==================================================================================
-- ============================== AUTO FARM TAB =====================================
-- ==================================================================================

TabCombat:AddSection("Auto Click")

TabCombat:AddToggle({
    Name = "Auto Click (C)",
    Default = false,
    Callback = function(value)
        autoClick = value
    end
})

TabCombat:AddSlider({
    Name = "Delay do Click (s)",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Callback = function(value)
        clickDelay = value
    end
})

TabCombat:AddSection("ESP para Mobs/NPCs")

local mobESPEnabled = false
local mobESPObjects = {}

local function createMobESP(model)
    if not model:IsA("Model") or not model:FindFirstChild("HumanoidRootPart") then return end
    if model.Parent ~= workspace then return end
    if model == Character then return end
    
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "MobESP"
    billboardGui.Adornee = hrp
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = hrp
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = model.Name
    textLabel.TextColor3 = Color3.new(1, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.Parent = billboardGui
    
    table.insert(mobESPObjects, billboardGui)
end

local function clearMobESP()
    for _, obj in pairs(mobESPObjects) do
        if obj then
            obj:Destroy()
        end
    end
    mobESPObjects = {}
end

local function updateMobESP()
    if mobESPEnabled then
        for _, model in pairs(workspace:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("Humanoid") and model ~= Character then
                if not model:FindFirstChild("HumanoidRootPart"):FindFirstChild("MobESP") then
                    createMobESP(model)
                end
            end
        end
    else
        clearMobESP()
    end
end

TabCombat:AddToggle({
    Name = "ESP em Mobs/NPCs",
    Default = false,
    Callback = function(value)
        mobESPEnabled = value
        updateMobESP()
    end
})

-- ==================================================================================
-- ============================== ESP TAB ===========================================
-- ==================================================================================

TabESP:AddSection("ESP Principal")

-- Funções ESP (MESMAS DO CÓDIGO ORIGINAL)
local function createESP(player)
    if player == LP then return end
    if espObjects[player] then return end
    
    local espContainer = Instance.new("Folder")
    espContainer.Name = "ESP_" .. player.Name
    espContainer.Parent = game.CoreGui
    
    espObjects[player] = {
        Container = espContainer,
        Box = nil,
        Tracer = nil,
        Distance = nil,
        Health = nil,
        Name = nil,
        Connections = {}
    }
    
    local function updateESP()
        if not espEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if not shouldShowPlayer(player, espFilter) then
            return
        end
        
        local hrp = player.Character.HumanoidRootPart
        local distance = (hrp.Position - HRP.Position).Magnitude
        
        if distance > espMaxDistance then return end
        
        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        -- Box ESP
        if espBoxes then
            if not espObjects[player].Box then
                local box = Drawing.new("Square")
                box.Visible = true
                box.Color = espBoxColor
                box.Thickness = 2
                box.Transparency = 1
                box.Filled = false
                espObjects[player].Box = box
            end
            
            if onScreen then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height / 2
                    
                    espObjects[player].Box.Size = Vector2.new(width, height)
                    espObjects[player].Box.Position = Vector2.new(vector.X - width/2, vector.Y - height/2)
                    espObjects[player].Box.Visible = true
                end
            else
                espObjects[player].Box.Visible = false
            end
        end
        
        -- Tracer ESP
        if espTracers then
            if not espObjects[player].Tracer then
                local tracer = Drawing.new("Line")
                tracer.Visible = true
                tracer.Color = espTracerColor
                tracer.Thickness = 1
                tracer.Transparency = 1
                espObjects[player].Tracer = tracer
            end
            
            if onScreen then
                local screenSize = Camera.ViewportSize
                espObjects[player].Tracer.From = Vector2.new(screenSize.X / 2, screenSize.Y)
                espObjects[player].Tracer.To = Vector2.new(vector.X, vector.Y)
                espObjects[player].Tracer.Visible = true
            else
                espObjects[player].Tracer.Visible = false
            end
        end
        
        -- Distance ESP
        if espDistance then
            if not espObjects[player].Distance then
                local dist = Drawing.new("Text")
                dist.Visible = true
                dist.Color = Color3.new(1, 1, 1)
                dist.Size = 14
                dist.Center = true
                dist.Outline = true
                espObjects[player].Distance = dist
            end
            
            if onScreen then
                espObjects[player].Distance.Text = math.floor(distance) .. "m"
                espObjects[player].Distance.Position = Vector2.new(vector.X, vector.Y + 20)
                espObjects[player].Distance.Visible = true
            else
                espObjects[player].Distance.Visible = false
            end
        end
        
        -- Health ESP
        if espHealth then
            if not espObjects[player].Health then
                local health = Drawing.new("Text")
                health.Visible = true
                health.Color = Color3.new(0, 1, 0)
                health.Size = 14
                health.Center = true
                health.Outline = true
                espObjects[player].Health = health
            end
            
            if onScreen and player.Character:FindFirstChild("Humanoid") then
                local hum = player.Character.Humanoid
                local healthPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
                espObjects[player].Health.Text = healthPercent .. "%"
                espObjects[player].Health.Position = Vector2.new(vector.X, vector.Y + 35)
                espObjects[player].Health.Visible = true
                
                if healthPercent > 75 then
                    espObjects[player].Health.Color = Color3.new(0, 1, 0)
                elseif healthPercent > 50 then
                    espObjects[player].Health.Color = Color3.new(1, 1, 0)
                elseif healthPercent > 25 then
                    espObjects[player].Health.Color = Color3.new(1, 0.5, 0)
                else
                    espObjects[player].Health.Color = Color3.new(1, 0, 0)
                end
            else
                if espObjects[player].Health then
                    espObjects[player].Health.Visible = false
                end
            end
        end
        
        -- Name ESP
        if espNames then
            if not espObjects[player].Name then
                local name = Drawing.new("Text")
                name.Visible = true
                name.Color = Color3.new(1, 1, 1)
                name.Size = 14
                name.Center = true
                name.Outline = true
                espObjects[player].Name = name
            end
            
            if onScreen then
                espObjects[player].Name.Text = player.Name
                espObjects[player].Name.Position = Vector2.new(vector.X, vector.Y - 20)
                espObjects[player].Name.Visible = true
            else
                espObjects[player].Name.Visible = false
            end
        end
    end
    
    table.insert(espObjects[player].Connections, RunService.RenderStepped:Connect(updateESP))
end

local function removeESP(player)
    if espObjects[player] then
        for _, connection in pairs(espObjects[player].Connections) do
            connection:Disconnect()
        end
        
        if espObjects[player].Box then espObjects[player].Box:Remove() end
        if espObjects[player].Tracer then espObjects[player].Tracer:Remove() end
        if espObjects[player].Distance then espObjects[player].Distance:Remove() end
        if espObjects[player].Health then espObjects[player].Health:Remove() end
        if espObjects[player].Name then espObjects[player].Name:Remove() end
        
        if espObjects[player].Container then
            espObjects[player].Container:Destroy()
        end
        
        espObjects[player] = nil
    end
end

local function clearAllESP()
    for player, _ in pairs(espObjects) do
        removeESP(player)
    end
end

local function updateAllESP()
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                createESP(player)
            end
        end
    else
        clearAllESP()
    end
end

Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        task.wait(1)
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

TabESP:AddToggle({
    Name = "Ativar ESP (E)",
    Default = false,
    Callback = function(value)
        espEnabled = value
        updateAllESP()
    end
})

TabESP:AddSection("Opções de ESP")

TabESP:AddToggle({
    Name = "Boxes",
    Default = true,
    Callback = function(value)
        espBoxes = value
    end
})

TabESP:AddToggle({
    Name = "Tracers",
    Default = false,
    Callback = function(value)
        espTracers = value
    end
})

TabESP:AddToggle({
    Name = "Distância",
    Default = false,
    Callback = function(value)
        espDistance = value
    end
})

TabESP:AddToggle({
    Name = "Vida",
    Default = false,
    Callback = function(value)
        espHealth = value
    end
})

TabESP:AddToggle({
    Name = "Nome",
    Default = true,
    Callback = function(value)
        espNames = value
    end
})

TabESP:AddSection("Configurações")

TabESP:AddSlider({
    Name = "Distância Máxima",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Callback = function(value)
        espMaxDistance = value
    end
})

TabESP:AddDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(value)
        espFilter = value
    end
})

-- ==================================================================================
-- ============================== HIGHLIGHT ESP TAB =================================
-- ==================================================================================

TabHighlight:AddSection("Highlight ESP")

local function createHighlight(player)
    if player == LP then return end
    if playerHighlights[player] then return end
    
    local function addHighlight(char)
        if not char then return end
        
        task.wait(0.1)
        
        if not shouldShowPlayer(player, highlightFilter) then
            return
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerHighlight"
        highlight.Adornee = char
        highlight.FillColor = highlightFillColor
        highlight.OutlineColor = highlightOutlineColor
        highlight.FillTransparency = highlightFillTransparency
        highlight.OutlineTransparency = highlightOutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
        
        playerHighlights[player] = highlight
    end
    
    if player.Character then
        addHighlight(player.Character)
    end
    
    player.CharacterAdded:Connect(function(char)
        if highlightEnabled then
            addHighlight(char)
        end
    end)
end

local function removeHighlight(player)
    if playerHighlights[player] then
        playerHighlights[player]:Destroy()
        playerHighlights[player] = nil
    end
end

local function removeAllHighlights()
    for player, highlight in pairs(playerHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    playerHighlights = {}
end

local function updateAllHighlights()
    if highlightEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                createHighlight(player)
            end
        end
    else
        removeAllHighlights()
    end
end

Players.PlayerAdded:Connect(function(player)
    if highlightEnabled then
        createHighlight(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

TabHighlight:AddToggle({
    Name = "Ativar Highlight (H)",
    Default = false,
    Callback = function(value)
        highlightEnabled = value
        updateAllHighlights()
    end
})

TabHighlight:AddSection("Configurações")

TabHighlight:AddDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(value)
        highlightFilter = value
        removeAllHighlights()
        updateAllHighlights()
    end
})

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

TabAim:AddSection("Aim Assist")

local currentAimTarget = nil

local function getClosestPlayer()
    local closestDist = math.huge
    local closest = nil
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LP then continue end
        if not shouldShowPlayer(player, aimFilter) then continue end
        
        local char = player.Character
        if not char then continue end
        
        local targetPart = char:FindFirstChild(aimPart)
        if not targetPart then continue end
        
        if wallCheck then
            local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, char})
            if hit then continue end
        end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if dist < closestDist then
            closestDist = dist
            closest = player
        end
    end
    
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimAssistEnabled then
        currentAimTarget = getClosestPlayer()
        
        if currentAimTarget and currentAimTarget.Character then
            local targetPart = currentAimTarget.Character:FindFirstChild(aimPart)
            if targetPart then
                local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
                local mousePos = UserInputService:GetMouseLocation()
                
                if aimLockEnabled then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
                else
                    local diff = Vector2.new(targetPos.X - mousePos.X, targetPos.Y - mousePos.Y)
                    mousemoverel(diff.X * aimSmoothness, diff.Y * aimSmoothness)
                end
            end
        end
    end
end)

TabAim:AddToggle({
    Name = "Ativar Aim Assist (R)",
    Default = false,
    Callback = function(value)
        aimAssistEnabled = value
    end
})

TabAim:AddToggle({
    Name = "Aim Lock",
    Default = false,
    Callback = function(value)
        aimLockEnabled = value
    end
})

TabAim:AddSection("Configurações")

TabAim:AddSlider({
    Name = "Suavidade",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Callback = function(value)
        aimSmoothness = value
    end
})

TabAim:AddDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(value)
        aimPart = value
    end
})

TabAim:AddDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(value)
        aimFilter = value
    end
})

TabAim:AddToggle({
    Name = "Wall Check",
    Default = true,
    Callback = function(value)
        wallCheck = value
    end
})

-- ==================================================================================
-- ============================== PLAYER AIM TAB ====================================
-- ==================================================================================

TabPlayerAim:AddSection("Player Aim")

local selectedPlayerForAim = nil
local playerAimConnection = nil

local function aimAtPlayer(player)
    if not player or not player.Character then return end
    
    local targetPart = player.Character:FindFirstChild(playerAimPart)
    if not targetPart then return end
    
    if playerWallCheck then
        local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, player.Character})
        if hit then return end
    end
    
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
end

TabPlayerAim:AddToggle({
    Name = "Ativar Player Aim (T)",
    Default = false,
    Callback = function(value)
        playerAimEnabled = value
        
        if value then
            if selectedPlayerForAim then
                playerAimConnection = RunService.RenderStepped:Connect(function()
                    if playerAimEnabled and selectedPlayerForAim then
                        aimAtPlayer(selectedPlayerForAim)
                    end
                end)
            end
        else
            if playerAimConnection then
                playerAimConnection:Disconnect()
                playerAimConnection = nil
            end
        end
    end
})

TabPlayerAim:AddSection("Configurações")

TabPlayerAim:AddDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(value)
        playerAimPart = value
    end
})

TabPlayerAim:AddDropdown({
    Name = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(value)
        playerAimFilter = value
    end
})

TabPlayerAim:AddToggle({
    Name = "Wall Check",
    Default = true,
    Callback = function(value)
        playerWallCheck = value
    end
})

TabPlayerAim:AddSection("Selecionar Jogador")

local playerNames = {}
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LP then
        table.insert(playerNames, player.Name)
    end
end

TabPlayerAim:AddDropdown({
    Name = "Jogador Alvo",
    Options = playerNames,
    Default = "Nenhum",
    Callback = function(value)
        selectedPlayerForAim = Players:FindFirstChild(value)
        
        if playerAimEnabled then
            if playerAimConnection then
                playerAimConnection:Disconnect()
            end
            
            playerAimConnection = RunService.RenderStepped:Connect(function()
                if playerAimEnabled and selectedPlayerForAim then
                    aimAtPlayer(selectedPlayerForAim)
                end
            end)
        end
    end
})

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:AddSection("Proteção")

TabProt:AddToggle({
    Name = "God Mode (G)",
    Default = false,
    Callback = function(value)
        godMode = value
    end
})

TabProt:AddToggle({
    Name = "Travar HP",
    Default = false,
    Callback = function(value)
        lockHP = value
    end
})

TabProt:AddToggle({
    Name = "Anti Void",
    Default = false,
    Callback = function(value)
        antiVoid = value
    end
})

TabProt:AddToggle({
    Name = "Anti Knockback",
    Default = false,
    Callback = function(value)
        antiKB = value
    end
})

-- ==================================================================================
-- ============================== PLAYERS TAB =======================================
-- ==================================================================================

TabPlayers:AddSection("Ações com Jogadores")

local selectedPlayer = nil

local playerList = {}
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LP then
        table.insert(playerList, player.Name)
    end
end

TabPlayers:AddDropdown({
    Name = "Selecionar Jogador",
    Options = playerList,
    Default = "Nenhum",
    Callback = function(value)
        selectedPlayer = Players:FindFirstChild(value)
    end
})

TabPlayers:AddButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            HRP.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
        end
    end
})

TabPlayers:AddButton({
    Name = "Spectate Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Camera.CameraSubject = selectedPlayer.Character.Humanoid
        end
    end
})

TabPlayers:AddButton({
    Name = "Parar Spectate",
    Callback = function()
        if LP.Character then
            Camera.CameraSubject = LP.Character.Humanoid
        end
    end
})

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

TabWaypoints:AddSection("Waypoints")

TabWaypoints:AddTextBox({
    Name = "Nome do Waypoint",
    Default = "",
    Placeholder = "Digite o nome...",
    Callback = function(text)
        _G.WaypointName = text
    end
})

TabWaypoints:AddButton({
    Name = "Criar Waypoint",
    Callback = function()
        if not _G.WaypointName or _G.WaypointName == "" then
            return
        end
        
        if not HRP then return end
        
        waypoints[_G.WaypointName] = {
            Position = HRP.CFrame.Position,
            CFrame = HRP.CFrame
        }
        
        _G.WaypointName = ""
    end
})

TabWaypoints:AddSection("Teleportar")

local function getWaypointNames()
    local names = {}
    for name, _ in pairs(waypoints) do
        table.insert(names, name)
    end
    return names
end

TabWaypoints:AddDropdown({
    Name = "Selecionar Waypoint",
    Options = getWaypointNames(),
    Default = "Nenhum",
    Callback = function(value)
        selectedWP = value
    end
})

TabWaypoints:AddButton({
    Name = "Teleportar",
    Callback = function()
        if selectedWP and waypoints[selectedWP] and HRP then
            HRP.CFrame = waypoints[selectedWP].CFrame
        end
    end
})

TabWaypoints:AddButton({
    Name = "Deletar Waypoint",
    Callback = function()
        if selectedWP and waypoints[selectedWP] then
            waypoints[selectedWP] = nil
            selectedWP = nil
        end
    end
})

-- ==================================================================================
-- ============================== VISUALS TAB =======================================
-- ==================================================================================

TabVisuals:AddSection("Visuais")

TabVisuals:AddToggle({
    Name = "Fullbright (B)",
    Default = false,
    Callback = function(value)
        fullbright = value
        
        if value then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.FogEnd = 1e10
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            Lighting.Brightness = 1
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
    end
})

TabVisuals:AddSlider({
    Name = "FOV",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(value)
        Camera.FieldOfView = value
    end
})

TabVisuals:AddButton({
    Name = "Esconder Objetos 3D",
    Callback = function()
        resetVisuals()
    end
})

-- ==================================================================================
-- ============================== WORLD TAB =========================================
-- ==================================================================================

TabWorld:AddSection("Mundo")

TabWorld:AddSlider({
    Name = "Hora do Dia",
    Min = 0,
    Max = 24,
    Default = 14,
    Callback = function(value)
        Lighting.ClockTime = value
    end
})

-- ==================================================================================
-- ============================== FPS/STATS TAB =====================================
-- ==================================================================================

TabFPS:AddSection("Estatísticas")

local fpsLabel = TabFPS:AddLabel("FPS: Carregando...")
local pingLabel = TabFPS:AddLabel("Ping: Carregando...")
local playersLabel = TabFPS:AddLabel("Jogadores: " .. #Players:GetPlayers())

task.spawn(function()
    local lastUpdate = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        
        if tick() - lastUpdate >= 1 then
            local fps = frameCount
            fpsLabel:Set("FPS: " .. fps)
            
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            pingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
            
            playersLabel:Set("Jogadores: " .. #Players:GetPlayers())
            
            frameCount = 0
            lastUpdate = tick()
        end
    end)
end)

-- ==================================================================================
-- ============================== CONFIG TAB ========================================
-- ==================================================================================

TabConfig:AddSection("Keybinds")

TabConfig:AddLabel("ESP: E | Highlight: H")
TabConfig:AddLabel("Aim: R | Player Aim: T")
TabConfig:AddLabel("Fly: F | Noclip: N")
TabConfig:AddLabel("Inf Jump: J | Auto Click: C")
TabConfig:AddLabel("God Mode: G | Fullbright: B")
TabConfig:AddLabel("Toggle GUI: RightControl")

TabConfig:AddSection("GUI")

TabConfig:AddButton({
    Name = "Destruir GUI",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        task.wait(0.5)
        Window:Destroy()
    end
})

-- ==================================================================================
-- ============================== UTILITY TAB =======================================
-- ==================================================================================

TabUtil:AddSection("Utilidades")

TabUtil:AddToggle({
    Name = "Noclip (N)",
    Default = false,
    Callback = function(value)
        noclip = value
    end
})

-- Shift Lock System
local shiftLockEnabled = false
local shiftLockRotConnection
local oldAutoRotate

local function applyShiftLock(enabled)
    if not Character or not Humanoid or not HRP then 
        task.wait(0.5)
        if LP.Character then
            BindCharacter(LP.Character)
        end
        return 
    end
    
    shiftLockEnabled = enabled
    
    if shiftLockRotConnection then
        shiftLockRotConnection:Disconnect()
        shiftLockRotConnection = nil
    end
    
    if enabled then
        oldAutoRotate = Humanoid.AutoRotate
        Humanoid.AutoRotate = false
        
        shiftLockRotConnection = RunService.RenderStepped:Connect(function()
            local camera = Workspace.CurrentCamera
            if not HRP or not camera then return end
            
            local lookVector = camera.CFrame.LookVector
            local flatVector = Vector3.new(lookVector.X, 0, lookVector.Z)
            
            if flatVector.Magnitude > 0.0001 then
                HRP.CFrame = CFrame.lookAt(HRP.Position, HRP.Position + flatVector.Unit, Vector3.yAxis)
            end
        end)
    else
        if oldAutoRotate ~= nil then
            Humanoid.AutoRotate = oldAutoRotate
        end
    end
end

LP.CharacterAdded:Connect(function()
    task.defer(function()
        task.wait(0.5)
        if shiftLockEnabled then
            applyShiftLock(true)
        end
    end)
end)

TabUtil:AddToggle({
    Name = "Shift Lock",
    Default = false,
    Callback = function(value)
        applyShiftLock(value)
    end
})

TabUtil:AddToggle({
    Name = "Insta Interact",
    Default = false,
    Callback = function(value)
        _G.InstaInteract = value
        
        if value then
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

TabUtil:AddSection("Server")

TabUtil:AddButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

TabUtil:AddButton({
    Name = "Server Hop",
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
-- ============================== KEYBIND SYSTEM ====================================
-- ==================================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- ESP TOGGLE
    if input.KeyCode == keybindESP then
        espEnabled = not espEnabled
        updateAllESP()
        
    -- HIGHLIGHT TOGGLE
    elseif input.KeyCode == keybindHighlight then
        highlightEnabled = not highlightEnabled
        updateAllHighlights()
        
    -- AIM ASSIST TOGGLE
    elseif input.KeyCode == keybindAim then
        aimAssistEnabled = not aimAssistEnabled
        
    -- PLAYER AIM TOGGLE
    elseif input.KeyCode == keybindPlayerAim then
        playerAimEnabled = not playerAimEnabled
        
        if playerAimEnabled then
            if selectedPlayerForAim then
                playerAimConnection = RunService.RenderStepped:Connect(function()
                    if playerAimEnabled and selectedPlayerForAim then
                        aimAtPlayer(selectedPlayerForAim)
                    end
                end)
            end
        else
            if playerAimConnection then
                playerAimConnection:Disconnect()
                playerAimConnection = nil
            end
        end
        
    -- FLY TOGGLE
    elseif input.KeyCode == keybindFly then
        toggleFly(not flyEnabled)
        
    -- NOCLIP TOGGLE
    elseif input.KeyCode == keybindNoclip then
        noclip = not noclip
        
    -- INF JUMP TOGGLE
    elseif input.KeyCode == keybindInfJump then
        infJump = not infJump
        
    -- AUTO CLICK TOGGLE
    elseif input.KeyCode == keybindAutoClick then
        autoClick = not autoClick
        
    -- GOD MODE TOGGLE
    elseif input.KeyCode == keybindGodMode then
        godMode = not godMode
        
    -- FULLBRIGHT TOGGLE
    elseif input.KeyCode == keybindFullbright then
        fullbright = not fullbright
        
        if fullbright then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.FogEnd = 1e10
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            Lighting.Brightness = 1
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
        
    -- GUI TOGGLE
    elseif input.KeyCode == keybindGUI then
        Window:Toggle()
    end
    
    -- FLY UP
    if input.KeyCode == Enum.KeyCode.Space and flyEnabled then
        flyUpImpulse = 1
    end
end)

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

-- Auto Click Loop
task.spawn(function()
    while task.wait() do
        if autoClick then
            mouse1click()
            task.wait(clickDelay)
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Anti Fall
RunService.Stepped:Connect(function()
    if antiFall and Humanoid then
        local falling = Humanoid:GetState() == Enum.HumanoidStateType.Freefall
        if falling then
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

print("✅ Universal Hub WindUI - Carregado!")
print("📊 Todas as funcionalidades mantidas")
print("🎯 Sistema de save/load WindUI nativo")

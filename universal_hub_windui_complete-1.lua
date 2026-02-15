-- ================== UNIVERSAL HUB - WINDUI VERSION (SINTAXE CORRETA) ==================
-- Universal Hub WindUI By ZakyzVortex (Mobile Optimized & Organized)
-- Converted from Rayfield v13 to WindUI

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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
    Icon = "zap",
    Author = "ZakyzVortex",
    Folder = "UniversalHub",
    Size = UDim2.fromOffset(920, 620),
    Transparent = true,
    Theme = "Dark",
})

-- ================== CREATE TABS ==================
local TabMove = Window:Tab({ Title = "Movement", Icon = "rocket" })
local TabCombat = Window:Tab({ Title = "Auto Farm", Icon = "crosshairs" })
local TabESP = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabHighlight = Window:Tab({ Title = "Highlight ESP", Icon = "highlight" })
local TabAim = Window:Tab({ Title = "Aim Assist", Icon = "target" })
local TabPlayerAim = Window:Tab({ Title = "Player Aim", Icon = "user-target" })
local TabProt = Window:Tab({ Title = "Protection", Icon = "shield" })
local TabPlayers = Window:Tab({ Title = "Players", Icon = "users" })
local TabWaypoints = Window:Tab({ Title = "Waypoints", Icon = "map-pin" })
local TabVisuals = Window:Tab({ Title = "Visuals", Icon = "eye-2" })
local TabWorld = Window:Tab({ Title = "World", Icon = "globe" })
local TabFPS = Window:Tab({ Title = "FPS/Stats", Icon = "speedometer" })
local TabConfig = Window:Tab({ Title = "Config", Icon = "cog" })
local TabUtil = Window:Tab({ Title = "Utility", Icon = "tool" })

-- ==================================================================================
-- ============================== MOVEMENT TAB ======================================
-- ==================================================================================

TabMove:Section({ Title = "Velocidade e Pulo" })

-- Estados
local infJump, antiFall = false, false

-- Velocidade
TabMove:Slider({
    Title = "Velocidade de Caminhada",
    Min = 16,
    Max = 300,
    Default = 16,
    Increment = 5,
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
    Increment = 10,
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:Section({ Title = "Fly System" })

-- ================== FLY SYSTEM ==================
local flyEnabled = false
local flySpeed = 1
local tpwalking = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}

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
                        if ctrl.f == 1 then
                            chr:TranslateBy(Workspace.CurrentCamera.CFrame.lookVector * 0.7)
                        end
                        if ctrl.b == 1 then
                            chr:TranslateBy(Workspace.CurrentCamera.CFrame.lookVector * -0.7)
                        end
                        if ctrl.l == 1 then
                            chr:TranslateBy(Workspace.CurrentCamera.CFrame.rightVector * -0.7)
                        end
                        if ctrl.r == 1 then
                            chr:TranslateBy(Workspace.CurrentCamera.CFrame.rightVector * 0.7)
                        end
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
        hum:ChangeState(Enum.HumanoidStateType.Running)
        
        if HRP:FindFirstChild("FlyVel") then HRP.FlyVel:Destroy() end
        if HRP:FindFirstChild("FlyGyro") then HRP.FlyGyro:Destroy() end
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if flyEnabled then
        if input.KeyCode == Enum.KeyCode.W then
            ctrl.f = 1
        elseif input.KeyCode == Enum.KeyCode.S then
            ctrl.b = 1
        elseif input.KeyCode == Enum.KeyCode.A then
            ctrl.l = 1
        elseif input.KeyCode == Enum.KeyCode.D then
            ctrl.r = 1
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then
        ctrl.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then
        ctrl.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then
        ctrl.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then
        ctrl.r = 0
    end
end)

local flyUpImpulse = 0

TabMove:Toggle({
    Title = "Ativar Fly (F)",
    Default = false,
    Callback = function(v)
        toggleFly(v)
    end
})

TabMove:Slider({
    Title = "Velocidade de Voo",
    Min = 1,
    Max = 50,
    Default = 1,
    Increment = 1,
    Callback = function(v)
        flySpeed = v
    end
})

TabMove:Section({ Title = "Infinite Jump" })

TabMove:Toggle({
    Title = "Pulo Infinito (J)",
    Default = false,
    Callback = function(v)
        infJump = v
    end
})

TabMove:Toggle({
    Title = "Anti Queda",
    Default = false,
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

TabCombat:Section({ Title = "Auto Farm NPCs" })

local autoFarmNPC = false
local autoFarmNPCMethod = "Closest"
local autoFarmNPCTarget = nil

local function getClosestNPC()
    local closest = nil
    local closestDist = math.huge
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v ~= Character and v.Humanoid.Health > 0 then
                local dist = (HRP.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = v
                end
            end
        end
    end
    
    return closest
end

TabCombat:Toggle({
    Title = "Auto Farm NPCs",
    Default = false,
    Callback = function(v)
        autoFarmNPC = v
        spawn(function()
            while autoFarmNPC and task.wait(0.1) do
                local npc = autoFarmNPCMethod == "Closest" and getClosestNPC() or autoFarmNPCTarget
                if npc and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                    if HRP then
                        HRP.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 3, 5)
                    end
                end
            end
        end)
    end
})

TabCombat:Dropdown({
    Title = "Método de Farm",
    Options = {"Closest", "Manual Select"},
    Default = "Closest",
    Callback = function(v)
        autoFarmNPCMethod = typeof(v) == "table" and v[1] or v
    end
})

TabCombat:Section({ Title = "Auto Farm Players" })

local autoFarmPlayer = false
local autoFarmPlayerFilter = "All"

TabCombat:Toggle({
    Title = "Auto Farm Players",
    Default = false,
    Callback = function(v)
        autoFarmPlayer = v
        spawn(function()
            while autoFarmPlayer and task.wait(0.1) do
                for _, player in pairs(Players:GetPlayers()) do
                    if shouldShowPlayer(player, autoFarmPlayerFilter) then
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                            if HRP then
                                HRP.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 3, 5)
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
})

TabCombat:Dropdown({
    Title = "Filtro de Players",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        autoFarmPlayerFilter = typeof(v) == "table" and v[1] or v
    end
})

TabCombat:Section({ Title = "Auto Click" })

local autoClick = false
local autoClickSpeed = 50

TabCombat:Toggle({
    Title = "Auto Click (C)",
    Default = false,
    Callback = function(v)
        autoClick = v
        spawn(function()
            while autoClick and task.wait(1 / autoClickSpeed) do
                mouse1click()
            end
        end)
    end
})

TabCombat:Slider({
    Title = "Velocidade de Click (CPS)",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(v)
        autoClickSpeed = v
    end
})

-- ==================================================================================
-- ================================= ESP TAB ========================================
-- ==================================================================================

TabESP:Section({ Title = "ESP Visual" })

local espEnabled = false
local espDistance = true
local espHealth = true
local espName = true
local espBox = true
local espTeamCheck = "All"
local espMaxDistance = 1000

local espObjects = {}

local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if obj then obj:Destroy() end
        end
        espObjects[player] = nil
    end
end

local function clearAllESP()
    for player, _ in pairs(espObjects) do
        removeESP(player)
    end
end

local function createESP(player)
    if player == LP then return end
    if not shouldShowPlayer(player, espTeamCheck) then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    removeESP(player)
    
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    
    espObjects[player] = {}
    
    if espBox then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 2
        box.Filled = false
        espObjects[player].Box = box
    end
    
    if espName then
        local nameLabel = Drawing.new("Text")
        nameLabel.Text = player.Name
        nameLabel.Color = Color3.fromRGB(255, 255, 255)
        nameLabel.Size = 18
        nameLabel.Center = true
        nameLabel.Outline = true
        espObjects[player].Name = nameLabel
    end
    
    if espDistance then
        local distLabel = Drawing.new("Text")
        distLabel.Color = Color3.fromRGB(255, 255, 255)
        distLabel.Size = 16
        distLabel.Center = true
        distLabel.Outline = true
        espObjects[player].Distance = distLabel
    end
    
    if espHealth and hum then
        local healthLabel = Drawing.new("Text")
        healthLabel.Color = Color3.fromRGB(0, 255, 0)
        healthLabel.Size = 16
        healthLabel.Center = true
        healthLabel.Outline = true
        espObjects[player].Health = healthLabel
    end
end

local function updateESP()
    for player, objects in pairs(espObjects) do
        if not player or not player.Parent or player == LP then
            removeESP(player)
            continue
        end
        
        if not shouldShowPlayer(player, espTeamCheck) then
            removeESP(player)
            continue
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            removeESP(player)
            continue
        end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local dist = (HRP.Position - hrp.Position).Magnitude
        
        if dist > espMaxDistance then
            for _, obj in pairs(objects) do
                if obj then obj.Visible = false end
            end
            continue
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        if not onScreen then
            for _, obj in pairs(objects) do
                if obj then obj.Visible = false end
            end
            continue
        end
        
        if objects.Box then
            local headPos = Camera:WorldToViewportPoint((char:FindFirstChild("Head") or hrp).Position + Vector3.new(0, 1, 0))
            local legPos = Camera:WorldToViewportPoint((char:FindFirstChild("LeftFoot") or hrp).Position - Vector3.new(0, 3, 0))
            
            objects.Box.Size = Vector2.new(2000 / pos.Z, headPos.Y - legPos.Y)
            objects.Box.Position = Vector2.new(pos.X - objects.Box.Size.X / 2, legPos.Y)
            objects.Box.Visible = true
        end
        
        if objects.Name then
            objects.Name.Position = Vector2.new(pos.X, pos.Y - 40)
            objects.Name.Visible = true
        end
        
        if objects.Distance then
            objects.Distance.Text = string.format("%.0f studs", dist)
            objects.Distance.Position = Vector2.new(pos.X, pos.Y - 20)
            objects.Distance.Visible = true
        end
        
        if objects.Health then
            objects.Health.Text = string.format("HP: %.0f/%.0f", hum.Health, hum.MaxHealth)
            objects.Health.Color = Color3.fromRGB(
                math.clamp(255 - (hum.Health / hum.MaxHealth) * 255, 0, 255),
                math.clamp((hum.Health / hum.MaxHealth) * 255, 0, 255),
                0
            )
            objects.Health.Position = Vector2.new(pos.X, pos.Y)
            objects.Health.Visible = true
        end
    end
end

TabESP:Toggle({
    Title = "ESP Ativado (E)",
    Default = false,
    Callback = function(v)
        espEnabled = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    createESP(player)
                end
            end
            
            Players.PlayerAdded:Connect(function(player)
                if espEnabled then
                    player.CharacterAdded:Wait()
                    task.wait(0.5)
                    createESP(player)
                end
            end)
            
            Players.PlayerRemoving:Connect(function(player)
                removeESP(player)
            end)
            
            RunService.RenderStepped:Connect(function()
                if espEnabled then
                    updateESP()
                end
            end)
        else
            clearAllESP()
        end
    end
})

TabESP:Toggle({
    Title = "Mostrar Nome",
    Default = true,
    Callback = function(v)
        espName = v
        clearAllESP()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        end
    end
})

TabESP:Toggle({
    Title = "Mostrar Distância",
    Default = true,
    Callback = function(v)
        espDistance = v
        clearAllESP()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        end
    end
})

TabESP:Toggle({
    Title = "Mostrar HP",
    Default = true,
    Callback = function(v)
        espHealth = v
        clearAllESP()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        end
    end
})

TabESP:Toggle({
    Title = "Mostrar Box",
    Default = true,
    Callback = function(v)
        espBox = v
        clearAllESP()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        end
    end
})

TabESP:Dropdown({
    Title = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        espTeamCheck = typeof(v) == "table" and v[1] or v
        clearAllESP()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        end
    end
})

TabESP:Slider({
    Title = "Distância Máxima",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Increment = 100,
    Callback = function(v)
        espMaxDistance = v
    end
})

-- ==================================================================================
-- ============================ HIGHLIGHT ESP TAB ===================================
-- ==================================================================================

TabHighlight:Section({ Title = "Highlight ESP" })

local highlightEnabled = false
local highlightTeamCheck = "All"
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightObjects = {}

local function removeHighlight(player)
    if highlightObjects[player] then
        highlightObjects[player]:Destroy()
        highlightObjects[player] = nil
    end
end

local function removeAllHighlights()
    for player, _ in pairs(highlightObjects) do
        removeHighlight(player)
    end
end

local function createHighlight(player)
    if player == LP then return end
    if not shouldShowPlayer(player, highlightTeamCheck) then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    removeHighlight(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = highlightColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = char
    
    highlightObjects[player] = highlight
end

TabHighlight:Toggle({
    Title = "Highlight ESP (H)",
    Default = false,
    Callback = function(v)
        highlightEnabled = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    createHighlight(player)
                end
            end
            
            Players.PlayerAdded:Connect(function(player)
                if highlightEnabled then
                    player.CharacterAdded:Connect(function()
                        task.wait(0.5)
                        createHighlight(player)
                    end)
                end
            end)
            
            Players.PlayerRemoving:Connect(function(player)
                removeHighlight(player)
            end)
        else
            removeAllHighlights()
        end
    end
})

TabHighlight:ColorPicker({
    Title = "Cor do Highlight",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        highlightColor = color
        for player, highlight in pairs(highlightObjects) do
            if highlight then
                highlight.FillColor = color
            end
        end
    end
})

TabHighlight:Dropdown({
    Title = "Filtro de Time",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        highlightTeamCheck = typeof(v) == "table" and v[1] or v
        removeAllHighlights()
        if highlightEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createHighlight(player) end
            end
        end
    end
})

TabHighlight:Slider({
    Title = "Transparência do Preenchimento",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Increment = 0.05,
    Callback = function(v)
        for _, h in pairs(highlightObjects) do
            if h then h.FillTransparency = v end
        end
    end
})

TabHighlight:Slider({
    Title = "Transparência do Contorno",
    Min = 0,
    Max = 1,
    Default = 0,
    Increment = 0.05,
    Callback = function(v)
        for _, h in pairs(highlightObjects) do
            if h then h.OutlineTransparency = v end
        end
    end
})

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

TabAim:Section({ Title = "Aim Assist" })

local aimAssistEnabled = false
local aimAssistTeamCheck = "EnemyTeam"
local aimAssistSmoothness = 5
local aimAssistWallCheck = true

local function getClosestPlayerToMouse()
    local closest = nil
    local closestDist = math.huge
    local mouse = LP:GetMouse()
    
    for _, player in pairs(Players:GetPlayers()) do
        if shouldShowPlayer(player, aimAssistTeamCheck) then
            local char = player.Character
            if char and char:FindFirstChild("Head") then
                local head = char.Head
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    
                    if aimAssistWallCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {Character, Camera})
                        if hit and hit:IsDescendantOf(char) then
                            if dist < closestDist then
                                closestDist = dist
                                closest = player
                            end
                        end
                    else
                        if dist < closestDist then
                            closestDist = dist
                            closest = player
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

TabAim:Toggle({
    Title = "Ativar Aim Assist (R)",
    Default = false,
    Callback = function(v)
        aimAssistEnabled = v
        spawn(function()
            while aimAssistEnabled and task.wait() do
                local target = getClosestPlayerToMouse()
                if target and target.Character and target.Character:FindFirstChild("Head") then
                    local head = target.Character.Head
                    local targetPos = Camera:WorldToViewportPoint(head.Position)
                    local mouse = LP:GetMouse()
                    local moveX = (targetPos.X - mouse.X) / aimAssistSmoothness
                    local moveY = (targetPos.Y - mouse.Y) / aimAssistSmoothness
                    
                    mousemoverel(moveX, moveY)
                end
            end
        end)
    end
})

TabAim:Slider({
    Title = "Suavidade",
    Min = 1,
    Max = 20,
    Default = 5,
    Increment = 1,
    Callback = function(v)
        aimAssistSmoothness = v
    end
})

TabAim:Toggle({
    Title = "Wall Check",
    Default = true,
    Callback = function(v)
        aimAssistWallCheck = v
    end
})

TabAim:Dropdown({
    Title = "Filtro de Time",
    Options = {"All", "EnemyTeam", "MyTeam"},
    Default = "EnemyTeam",
    Callback = function(v)
        aimAssistTeamCheck = typeof(v) == "table" and v[1] or v
    end
})

-- ==================================================================================
-- ============================ PLAYER AIM TAB ======================================
-- ==================================================================================

TabPlayerAim:Section({ Title = "Player Aim" })

local playerAimEnabled = false
local selectedPlayer = nil

local function getPlayerList()
    local list = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(list, player.Name)
        end
    end
    return list
end

TabPlayerAim:Label({ Text = "Selecione um jogador específico para mirar" })

local PlayerAimDropdown = TabPlayerAim:Dropdown({
    Title = "Escolher Jogador Alvo",
    Options = getPlayerList(),
    Default = "",
    Callback = function(option)
        selectedPlayer = typeof(option) == "table" and option[1] or option
        WindUI:Notify("Alvo Selecionado", tostring(selectedPlayer), 2)
    end
})

TabPlayerAim:Button({
    Title = "🔄 Atualizar Lista de Jogadores",
    Callback = function()
        PlayerAimDropdown:Refresh(getPlayerList())
        WindUI:Notify("✅ Lista Atualizada", tostring(#getPlayerList()) .. " jogadores", 2)
    end
})

TabPlayerAim:Toggle({
    Title = "Ativar Aim no Jogador (T)",
    Default = false,
    Callback = function(v)
        if v and not selectedPlayer then
            WindUI:Notify("⚠️ Aviso", "Selecione um jogador primeiro!", 2)
            playerAimEnabled = false
            return
        end
        playerAimEnabled = v
        WindUI:Notify(
            v and "✅ Aim Ativado" or "⭕ Aim Desativado",
            v and ("Mirando em: " .. tostring(selectedPlayer)) or "Desativado",
            1.5
        )
        
        spawn(function()
            while playerAimEnabled and task.wait() do
                if selectedPlayer then
                    local player = Players:FindFirstChild(selectedPlayer)
                    if player and player.Character and player.Character:FindFirstChild("Head") then
                        local head = player.Character.Head
                        local targetPos = Camera:WorldToViewportPoint(head.Position)
                        local mouse = LP:GetMouse()
                        local moveX = (targetPos.X - mouse.X) / 5
                        local moveY = (targetPos.Y - mouse.Y) / 5
                        
                        mousemoverel(moveX, moveY)
                    end
                end
            end
        end)
    end
})

-- ==================================================================================
-- ============================ PROTECTION TAB ======================================
-- ==================================================================================

TabProt:Section({ Title = "God Mode" })

local godMode = false
local lockHP = false

TabProt:Toggle({
    Title = "God Mode (G)",
    Default = false,
    Callback = function(v)
        godMode = v
    end
})

TabProt:Toggle({
    Title = "Lock HP",
    Default = false,
    Callback = function(v)
        lockHP = v
    end
})

TabProt:Section({ Title = "Protection Features" })

local antiVoid = false
local antiKB = false
local antiRagdoll = false

TabProt:Toggle({
    Title = "Anti Void",
    Default = false,
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:Toggle({
    Title = "Anti Knockback",
    Default = false,
    Callback = function(v)
        antiKB = v
    end
})

TabProt:Toggle({
    Title = "Anti Ragdoll",
    Default = false,
    Callback = function(v)
        antiRagdoll = v
        if v and Humanoid then
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        else
            if Humanoid then
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end
    end
})

-- ==================================================================================
-- ============================= PLAYERS TAB ========================================
-- ==================================================================================

TabPlayers:Section({ Title = "Player List" })

local function getPlayerNames()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(names, player.Name)
        end
    end
    return names
end

local selectedPlayerTP = nil

TabPlayers:Dropdown({
    Title = "Selecionar Player",
    Options = getPlayerNames(),
    Default = "",
    Callback = function(v)
        selectedPlayerTP = typeof(v) == "table" and v[1] or v
    end
})

TabPlayers:Button({
    Title = "Atualizar Lista",
    Callback = function()
        WindUI:Notify("Lista Atualizada", "Players atualizados!", 2)
    end
})

TabPlayers:Button({
    Title = "TP para Player",
    Callback = function()
        if selectedPlayerTP then
            local player = Players:FindFirstChild(selectedPlayerTP)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                HRP.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                WindUI:Notify("Teleportado", "TP para " .. selectedPlayerTP, 2)
            end
        end
    end
})

TabPlayers:Button({
    Title = "Spectate",
    Callback = function()
        if selectedPlayerTP then
            local player = Players:FindFirstChild(selectedPlayerTP)
            if player and player.Character then
                Camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
                WindUI:Notify("Spectate", "Observando " .. selectedPlayerTP, 2)
            end
        end
    end
})

TabPlayers:Button({
    Title = "Voltar Camera",
    Callback = function()
        Camera.CameraSubject = Humanoid
        WindUI:Notify("Camera", "Camera restaurada", 2)
    end
})

-- ==================================================================================
-- ============================ WAYPOINTS TAB =======================================
-- ==================================================================================

TabWaypoints:Section({ Title = "Waypoints" })

local waypoints = {}
local waypointNameInput = ""
local waypointSelected = ""

local function getWaypointList()
    local list = {}
    for name, _ in pairs(waypoints) do
        table.insert(list, name)
    end
    if #list == 0 then
        return {"Nenhum waypoint salvo"}
    end
    return list
end

local function saveWaypoint(name)
    if not HRP then return false end
    waypoints[name] = HRP.CFrame
    return true
end

local function teleportToWaypoint(name)
    if not waypoints[name] or not HRP then return false end
    HRP.CFrame = waypoints[name]
    return true
end

local function deleteWaypoint(name)
    waypoints[name] = nil
end

TabWaypoints:Input({
    Title = "Nome do Waypoint",
    Placeholder = "Digite o nome...",
    Default = "",
    Callback = function(text)
        waypointNameInput = text
    end
})

local waypointDropdown = TabWaypoints:Dropdown({
    Title = "Selecionar Waypoint",
    Options = getWaypointList(),
    Default = getWaypointList()[1],
    Callback = function(opt)
        waypointSelected = typeof(opt) == "table" and opt[1] or tostring(opt)
    end
})

TabWaypoints:Button({
    Title = "Salvar Posição Atual",
    Callback = function()
        if waypointNameInput == "" or not waypointNameInput then
            WindUI:Notify("Erro", "Digite um nome para o waypoint!", 3)
            return
        end
        if saveWaypoint(tostring(waypointNameInput)) then
            waypointDropdown:Refresh(getWaypointList())
            WindUI:Notify("Waypoint Salvo", "'" .. waypointNameInput .. "' foi salvo!", 3)
        else
            WindUI:Notify("Erro", "Falha ao salvar waypoint!", 3)
        end
    end
})

TabWaypoints:Button({
    Title = "Teleportar para Waypoint",
    Callback = function()
        local targetName = waypointSelected
        if type(targetName) == "table" then
            targetName = targetName[1] or tostring(targetName)
        end
        if not targetName or targetName == "" or targetName == "Nenhum waypoint salvo" then
            WindUI:Notify("Erro", "Selecione um waypoint válido!", 3)
            return
        end
        if teleportToWaypoint(targetName) then
            WindUI:Notify("Teleportado", "Chegou em '" .. targetName .. "'", 2)
        else
            WindUI:Notify("Erro", "Falha ao teleportar.", 3)
        end
    end
})

TabWaypoints:Button({
    Title = "Deletar Waypoint",
    Callback = function()
        local targetName = waypointSelected
        if type(targetName) == "table" then
            targetName = targetName[1] or tostring(targetName)
        end
        if not targetName or targetName == "" or targetName == "Nenhum waypoint salvo" then
            WindUI:Notify("Erro", "Selecione um waypoint válido!", 3)
            return
        end
        deleteWaypoint(targetName)
        waypointDropdown:Refresh(getWaypointList())
        WindUI:Notify("Waypoint Deletado", "Waypoint removido!", 2)
    end
})

TabWaypoints:Button({
    Title = "Atualizar Lista",
    Callback = function()
        waypointDropdown:Refresh(getWaypointList())
    end
})

TabWaypoints:Button({
    Title = "TP para Spawn",
    Callback = function()
        if not HRP then return end
        local spawnLocation = workspace:FindFirstChild("SpawnLocation") or
            workspace:FindFirstChildOfClass("SpawnLocation") or
            workspace:FindFirstChild("Spawn")
        
        if not spawnLocation then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    spawnLocation = obj
                    break
                end
            end
        end
        
        if spawnLocation then
            HRP.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
            WindUI:Notify("Teleportado", "Chegou no Spawn!", 2)
        else
            HRP.CFrame = CFrame.new(Vector3.new(0, 5, 0))
            WindUI:Notify("Spawn não encontrado", "Foi para a origem (0,5,0).", 3)
        end
    end
})

-- ==================================================================================
-- ============================= VISUALS TAB ========================================
-- ==================================================================================

TabVisuals:Section({ Title = "Lighting" })

local fullbright = false
local originalAmbient, originalBrightness, originalFogEnd

local function toggleFullbright(enabled)
    if enabled then
        originalAmbient = Lighting.Ambient
        originalBrightness = Lighting.Brightness
        originalFogEnd = Lighting.FogEnd
        
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
    else
        if originalAmbient then Lighting.Ambient = originalAmbient end
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalFogEnd then Lighting.FogEnd = originalFogEnd end
    end
end

TabVisuals:Toggle({
    Title = "Fullbright (B)",
    Default = false,
    Callback = function(v)
        fullbright = v
        toggleFullbright(v)
    end
})

TabVisuals:Toggle({
    Title = "Remover Fog",
    Default = false,
    Callback = function(v)
        if v then
            Lighting.FogEnd = 100000
        else
            if originalFogEnd then
                Lighting.FogEnd = originalFogEnd
            else
                Lighting.FogEnd = 1000
            end
        end
    end
})

TabVisuals:Section({ Title = "Camera" })

local DEFAULT_FOV = 70

TabVisuals:Slider({
    Title = "FOV",
    Min = 70,
    Max = 180,
    Default = Camera.FieldOfView,
    Increment = 1,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

TabVisuals:Button({
    Title = "Resetar FOV",
    Callback = function()
        Camera.FieldOfView = DEFAULT_FOV
    end
})

-- ==================================================================================
-- ============================== WORLD TAB =========================================
-- ==================================================================================

TabWorld:Section({ Title = "Time Control" })

local timeControlEnabled = false
local timeValue = 12

TabWorld:Toggle({
    Title = "Controlar Tempo",
    Default = false,
    Callback = function(v)
        timeControlEnabled = v
        if v then
            Lighting.ClockTime = timeValue
        end
    end
})

TabWorld:Slider({
    Title = "Hora do Dia",
    Min = 0,
    Max = 24,
    Default = Lighting.ClockTime or 14,
    Increment = 0.5,
    Callback = function(v)
        timeValue = v
        if timeControlEnabled then
            Lighting.ClockTime = v
        end
    end
})

TabWorld:Section({ Title = "Game Speed" })

TabWorld:Slider({
    Title = "Gravidade",
    Min = 60,
    Max = 500,
    Default = workspace.Gravity or 196,
    Increment = 10,
    Callback = function(v)
        workspace.Gravity = v
    end
})

TabWorld:Button({
    Title = "Remover Fog",
    Callback = function()
        Lighting.FogEnd = 1e6
    end
})

-- ==================================================================================
-- ============================ FPS/STATS TAB =======================================
-- ==================================================================================

TabFPS:Section({ Title = "Performance" })

local showFPS = false
local fpsLabel

TabFPS:Toggle({
    Title = "Mostrar FPS",
    Default = false,
    Callback = function(v)
        showFPS = v
        if v then
            fpsLabel = Drawing.new("Text")
            fpsLabel.Text = "FPS: 0"
            fpsLabel.Size = 20
            fpsLabel.Color = Color3.fromRGB(0, 255, 0)
            fpsLabel.Position = Vector2.new(10, 10)
            fpsLabel.Visible = true
            
            local lastUpdate = tick()
            local frameCount = 0
            
            RunService.RenderStepped:Connect(function()
                if showFPS then
                    frameCount = frameCount + 1
                    if tick() - lastUpdate >= 1 then
                        fpsLabel.Text = "FPS: " .. frameCount
                        frameCount = 0
                        lastUpdate = tick()
                    end
                else
                    if fpsLabel then fpsLabel.Visible = false end
                end
            end)
        else
            if fpsLabel then fpsLabel:Remove() end
        end
    end
})

TabFPS:Toggle({
    Title = "3D Delete (Hide World)",
    Default = false,
    Callback = function(v)
        if v then
            resetVisuals()
            WindUI:Notify("3D Delete Ativado", "Mundo escondido! FPS otimizado.", 2)
        else
            WindUI:Notify("3D Delete Desativado", "Recarregue o jogo.", 3)
        end
    end
})

TabFPS:Slider({
    Title = "FPS Cap",
    Min = 60,
    Max = 240,
    Default = 60,
    Increment = 10,
    Callback = function(v)
        setfpscap(v)
    end
})

TabFPS:Section({ Title = "Stats" })

local statsLabel = TabFPS:Label({ Text = "Carregando..." })
local fpsLabelStat = TabFPS:Label({ Text = "FPS: 0" })
local pingLabel = TabFPS:Label({ Text = "Ping: 0ms" })
local playersLabel = TabFPS:Label({ Text = "Players: 0" })

spawn(function()
    while task.wait(1) do
        local stats = game:GetService("Stats")
        local ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local playerCount = #Players:GetPlayers()
        
        if statsLabel then
            statsLabel:Set("Estatísticas do Servidor")
        end
        if pingLabel then
            pingLabel:Set("Ping: " .. ping .. "ms")
        end
        if playersLabel then
            playersLabel:Set("Players: " .. playerCount)
        end
    end
end)

-- ==================================================================================
-- ============================= CONFIG TAB =========================================
-- ==================================================================================

TabConfig:Section({ Title = "Anti AFK" })

TabConfig:Toggle({
    Title = "Anti AFK",
    Default = false,
    Callback = function(v)
        if v then
            WindUI:Notify("Anti AFK Ativado", "Você não será kickado", 2)
            local vu = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:connect(function()
                vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
})

TabConfig:Section({ Title = "Keybinds" })

TabConfig:Label({ Text = "ESP: E | Highlight: H" })
TabConfig:Label({ Text = "Aim: R | Player Aim: T" })
TabConfig:Label({ Text = "Fly: F | Noclip: N" })
TabConfig:Label({ Text = "Inf Jump: J | Auto Click: C" })
TabConfig:Label({ Text = "God Mode: G | Fullbright: B" })
TabConfig:Label({ Text = "Toggle GUI: RightControl" })

TabConfig:Section({ Title = "GUI" })

TabConfig:Button({
    Title = "Destruir GUI (Irreversível)",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        WindUI:Notify("⚠️ GUI Destruída", "Recarregue o script", 3)
        task.wait(1)
        WindUI:Destroy()
    end
})

-- ==================================================================================
-- =============================== UTILITY TAB ======================================
-- ==================================================================================

TabUtil:Section({ Title = "Noclip" })

local noclip = false

TabUtil:Toggle({
    Title = "Noclip (N)",
    Default = false,
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
    Default = false,
    Callback = function(v)
        applyShiftLock(v)
    end
})

TabUtil:Toggle({
    Title = "Insta Interact",
    Default = false,
    Callback = function(v)
        _G.InstaInteract = v
        if v then
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

TabUtil:Section({ Title = "Server" })

TabUtil:Button({
    Title = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

TabUtil:Button({
    Title = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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

-- Keybinds globais
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

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- ESP TOGGLE
    if input.KeyCode == keybindESP then
        espEnabled = not espEnabled
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createESP(player) end
            end
        else
            clearAllESP()
        end
        
    -- HIGHLIGHT TOGGLE
    elseif input.KeyCode == keybindHighlight then
        highlightEnabled = not highlightEnabled
        if highlightEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then createHighlight(player) end
            end
        else
            removeAllHighlights()
        end
        
    -- AIM TOGGLE
    elseif input.KeyCode == keybindAim then
        aimAssistEnabled = not aimAssistEnabled
        
    -- PLAYER AIM TOGGLE
    elseif input.KeyCode == keybindPlayerAim then
        playerAimEnabled = not playerAimEnabled
        
    -- FLY TOGGLE
    elseif input.KeyCode == keybindFly then
        flyEnabled = not flyEnabled
        toggleFly(flyEnabled)
        
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
        toggleFullbright(fullbright)
        
    -- GUI TOGGLE
    elseif input.KeyCode == keybindGUI then
        Window:Toggle()
    end
end)

print("✅ Universal Hub - WindUI Version (SINTAXE CORRETA)")
print("📊 ESP: Sistema completo com filtros de time")
print("✨ Highlight ESP: Sistema de destaque funcional")
print("🎯 Aim Assist: Mira automática com wallcheck")
print("🔧 Todas as funcionalidades da v13 Rayfield convertidas!")
print("💎 Baseado no exemplo oficial do WindUI")
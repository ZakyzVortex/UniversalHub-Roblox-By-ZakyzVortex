-- ================== UNIVERSAL HUB - TEAM SYSTEM FIXED ==================
-- By ZakyzVortex - Sistema de Times Funcionando

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Character References
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

-- ================== TEAM DETECTION ==================
local function isPlayerOnSameTeam(player)
    if not LP.Team or not player.Team then return false end
    return player.Team == LP.Team
end

local function shouldShowPlayer(player, filterMode)
    if filterMode == "All" then
        return true
    elseif filterMode == "Team" then
        return isPlayerOnSameTeam(player)
    elseif filterMode == "Enemy" then
        return not isPlayerOnSameTeam(player)
    end
    return true
end

-- Window
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub - Team System",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "By ZakyzVortex",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "Config"
    }
})

-- Tabs
local TabMove = Window:CreateTab("Movement")
local TabCombat = Window:CreateTab("Combat")
local TabESP = Window:CreateTab("ESP")
local TabHighlight = Window:CreateTab("Highlight ESP")
local TabAim = Window:CreateTab("Aim Assist")
local TabProt = Window:CreateTab("Protection")
local TabPlayers = Window:CreateTab("Players")
local TabWaypoints = Window:CreateTab("Waypoints")
local TabVisuals = Window:CreateTab("Visuals")
local TabWorld = Window:CreateTab("World")
local TabFPS = Window:CreateTab("FPS/Stats")
local TabConfig = Window:CreateTab("Config")
local TabUtil = Window:CreateTab("Utility")

-- ==================== MOVEMENT ====================
TabMove:CreateSection("Velocidade e Pulo")

local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump = false

TabMove:CreateSlider({
    Name = "Velocidade de Caminhada",
    Range = {16, 300},
    Increment = 5,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        if Humanoid then Humanoid.WalkSpeed = v end
    end
})

TabMove:CreateSlider({
    Name = "Poder de Pulo",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v
        end
    end
})

TabMove:CreateSection("Fly System")

TabMove:CreateSlider({
    Name = "Velocidade de Voo",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 100,
    Flag = "FlySpeed",
    Callback = function(v)
        flySpeed = v
    end
})

TabMove:CreateToggle({
    Name = "Ativar Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(v)
        fly = v
        if not v and HRP then
            for _, i in pairs({"FlyVel", "FlyGyro"}) do
                local o = HRP:FindFirstChild(i)
                if o then o:Destroy() end
            end
        end
    end
})

TabMove:CreateSection("Outros")

TabMove:CreateToggle({
    Name = "Pulo Infinito",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v)
        infJump = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if fly then flyUpImpulse = 0.18 end
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== COMBAT ====================
TabCombat:CreateSection("Auto Clicker")

local AUTO_CLICKER_ENABLED = false
local AUTO_CLICKER_CPS = 10
local lastClick = 0

TabCombat:CreateToggle({
    Name = "Ativar Auto Clicker",
    CurrentValue = false,
    Flag = "AutoClicker",
    Callback = function(v)
        AUTO_CLICKER_ENABLED = v
    end
})

TabCombat:CreateSlider({
    Name = "CPS",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "AutoClickerCPS",
    Callback = function(v)
        AUTO_CLICKER_CPS = v
    end
})

RunService.RenderStepped:Connect(function()
    if not AUTO_CLICKER_ENABLED then return end
    local now = tick()
    if now - lastClick >= 1 / AUTO_CLICKER_CPS then
        mouse1click()
        lastClick = now
    end
end)

TabCombat:CreateSection("Hit Range")

local HIT_RANGE_ENABLED = false
local HIT_RANGE_SIZE = 10
local originalSizes = {}

local function extendHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not originalSizes[player] then
                    originalSizes[player] = hrp.Size
                end
                if HIT_RANGE_ENABLED then
                    hrp.Size = Vector3.new(HIT_RANGE_SIZE, HIT_RANGE_SIZE, HIT_RANGE_SIZE)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    hrp.Size = originalSizes[player]
                    hrp.Transparency = 1
                end
            end
        end
    end
end

TabCombat:CreateToggle({
    Name = "Hit Range Extender",
    CurrentValue = false,
    Flag = "HitRange",
    Callback = function(v)
        HIT_RANGE_ENABLED = v
        extendHitboxes()
    end
})

TabCombat:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(v)
        HIT_RANGE_SIZE = v
        extendHitboxes()
    end
})

RunService.Heartbeat:Connect(function()
    if HIT_RANGE_ENABLED then extendHitboxes() end
end)

-- ==================== ESP COM SISTEMA DE TIMES ====================
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true
local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local LINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS = {}
local ESP_TEAM_FILTER = "All"  -- All, Team, Enemy

local function removeESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData then return end
    espData.active = false
    if espData.nameLabel then espData.nameLabel:Remove() end
    if espData.distLabel then espData.distLabel:Remove() end
    if espData.healthLabel then espData.healthLabel:Remove() end
    if espData.tracerLine then espData.tracerLine:Remove() end
    if espData.boxOutline then espData.boxOutline:Remove() end
    ESP_OBJECTS[player] = nil
end

local function createESP(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowPlayer(player, ESP_TEAM_FILTER) then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local head = player.Character:FindFirstChild("Head")
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hrp or not head then return end
    
    local espData = { active = true, player = player }
    
    if NAME_ENABLED then
        local nameLabel = Drawing.new("Text")
        nameLabel.Visible = true
        nameLabel.Center = true
        nameLabel.Outline = true
        nameLabel.Color = ESP_COLOR
        nameLabel.Size = 16
        nameLabel.Text = player.Name
        espData.nameLabel = nameLabel
    end
    
    if DISTANCE_ENABLED then
        local distLabel = Drawing.new("Text")
        distLabel.Visible = true
        distLabel.Center = true
        distLabel.Outline = true
        distLabel.Color = Color3.fromRGB(255, 255, 255)
        distLabel.Size = 14
        espData.distLabel = distLabel
    end
    
    if HEALTH_ENABLED and hum then
        local healthLabel = Drawing.new("Text")
        healthLabel.Visible = true
        healthLabel.Center = true
        healthLabel.Outline = true
        healthLabel.Color = Color3.fromRGB(0, 255, 0)
        healthLabel.Size = 14
        espData.healthLabel = healthLabel
    end
    
    if LINE_ENABLED then
        local tracerLine = Drawing.new("Line")
        tracerLine.Visible = true
        tracerLine.Color = LINE_COLOR
        tracerLine.Thickness = 1
        espData.tracerLine = tracerLine
    end
    
    if OUTLINE_ENABLED then
        local boxOutline = Drawing.new("Square")
        boxOutline.Visible = true
        boxOutline.Color = ESP_COLOR
        boxOutline.Thickness = 2
        boxOutline.Filled = false
        espData.boxOutline = boxOutline
    end
    
    ESP_OBJECTS[player] = espData
end

local function updateESP(player)
    local espData = ESP_OBJECTS[player]
    if not espData or not espData.active or not player.Character then return end
    if not shouldShowPlayer(player, ESP_TEAM_FILTER) then
        removeESP(player)
        return
    end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local head = player.Character:FindFirstChild("Head")
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hrp or not head then
        removeESP(player)
        return
    end
    
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    local hrpPos = Camera:WorldToViewportPoint(hrp.Position)
    
    if not onScreen then
        if espData.nameLabel then espData.nameLabel.Visible = false end
        if espData.distLabel then espData.distLabel.Visible = false end
        if espData.healthLabel then espData.healthLabel.Visible = false end
        if espData.tracerLine then espData.tracerLine.Visible = false end
        if espData.boxOutline then espData.boxOutline.Visible = false end
        return
    end
    
    local distance = (HRP.Position - hrp.Position).Magnitude
    
    if espData.nameLabel then
        espData.nameLabel.Position = Vector2.new(headPos.X, headPos.Y - 30)
        espData.nameLabel.Visible = true
    end
    
    if espData.distLabel then
        espData.distLabel.Position = Vector2.new(headPos.X, headPos.Y - 15)
        espData.distLabel.Text = math.floor(distance) .. "m"
        espData.distLabel.Visible = true
    end
    
    if espData.healthLabel and hum then
        espData.healthLabel.Position = Vector2.new(headPos.X, headPos.Y)
        espData.healthLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
        espData.healthLabel.Visible = true
    end
    
    if espData.tracerLine then
        espData.tracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        espData.tracerLine.To = Vector2.new(hrpPos.X, hrpPos.Y)
        espData.tracerLine.Visible = true
    end
    
    if espData.boxOutline then
        local size = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0)).Y)
        espData.boxOutline.Size = Vector2.new(size * 1.5, size)
        espData.boxOutline.Position = Vector2.new(hrpPos.X - size * 0.75, hrpPos.Y - size * 0.5)
        espData.boxOutline.Visible = true
    end
end

local function clearAllESP()
    for player, _ in pairs(ESP_OBJECTS) do
        removeESP(player)
    end
    ESP_OBJECTS = {}
end

local function refreshESP()
    clearAllESP()
    if not ESP_ENABLED then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then createESP(player) end
    end
end

RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    for player, _ in pairs(ESP_OBJECTS) do
        if player and player.Parent and player.Character then
            updateESP(player)
        else
            removeESP(player)
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if ESP_ENABLED and player ~= LP then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ESP UI
TabESP:CreateSection("ESP Configuration")

TabESP:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v)
        ESP_ENABLED = v
        refreshESP()
    end
})

-- DROPDOWN DE FILTRO DE TIME
TabESP:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = {"All"},
    MultipleOptions = false,
    Flag = "ESPTeamFilter",
    Callback = function(option)
        ESP_TEAM_FILTER = typeof(option) == "table" and option[1] or option
        refreshESP()
    end
})

TabESP:CreateSection("Elementos")

TabESP:CreateToggle({
    Name = "Nome",
    CurrentValue = true,
    Flag = "ESPName",
    Callback = function(v)
        NAME_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Distância",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v)
        DISTANCE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Health",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v)
        HEALTH_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Linha",
    CurrentValue = true,
    Flag = "ESPLine",
    Callback = function(v)
        LINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateToggle({
    Name = "Box",
    CurrentValue = true,
    Flag = "ESPBox",
    Callback = function(v)
        OUTLINE_ENABLED = v
        refreshESP()
    end
})

TabESP:CreateSection("Cores")

TabESP:CreateColorPicker({
    Name = "Cor ESP",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        ESP_COLOR = color
        refreshESP()
    end
})

TabESP:CreateColorPicker({
    Name = "Cor Linha",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPLineColor",
    Callback = function(color)
        LINE_COLOR = color
        refreshESP()
    end
})

-- ==================== HIGHLIGHT ESP COM SISTEMA DE TIMES ====================
local HIGHLIGHT_ENABLED = false
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 0, 0)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.5
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local HIGHLIGHT_TEAM_FILTER = "All"
local HIGHLIGHT_OBJECTS = {}

local function removeHighlight(player)
    if HIGHLIGHT_OBJECTS[player] then
        HIGHLIGHT_OBJECTS[player]:Destroy()
        HIGHLIGHT_OBJECTS[player] = nil
    end
end

local function createHighlight(player)
    if player == LP then return end
    if not player.Character then return end
    if not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then return end
    
    removeHighlight(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = HIGHLIGHT_FILL_COLOR
    highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
    highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
    highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    
    HIGHLIGHT_OBJECTS[player] = highlight
end

local function updateHighlightColors()
    for _, highlight in pairs(HIGHLIGHT_OBJECTS) do
        if highlight and highlight.Parent then
            highlight.FillColor = HIGHLIGHT_FILL_COLOR
            highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
            highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
            highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
        end
    end
end

local function removeAllHighlights()
    for player, _ in pairs(HIGHLIGHT_OBJECTS) do
        removeHighlight(player)
    end
    HIGHLIGHT_OBJECTS = {}
end

local function refreshHighlights()
    removeAllHighlights()
    if not HIGHLIGHT_ENABLED then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then createHighlight(player) end
    end
end

Players.PlayerAdded:Connect(function(player)
    if HIGHLIGHT_ENABLED and player ~= LP then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createHighlight(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

RunService.Heartbeat:Connect(function()
    if not HIGHLIGHT_ENABLED then return end
    for player, highlight in pairs(HIGHLIGHT_OBJECTS) do
        if not player or not player.Parent or not player.Character or not shouldShowPlayer(player, HIGHLIGHT_TEAM_FILTER) then
            removeHighlight(player)
        elseif not highlight or not highlight.Parent then
            createHighlight(player)
        end
    end
end)

-- Highlight UI
TabHighlight:CreateSection("Highlight ESP")

TabHighlight:CreateToggle({
    Name = "Ativar Highlight",
    CurrentValue = false,
    Flag = "HighlightEnabled",
    Callback = function(v)
        HIGHLIGHT_ENABLED = v
        refreshHighlights()
    end
})

-- DROPDOWN DE FILTRO DE TIME HIGHLIGHT
TabHighlight:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = {"All"},
    MultipleOptions = false,
    Flag = "HighlightTeamFilter",
    Callback = function(option)
        HIGHLIGHT_TEAM_FILTER = typeof(option) == "table" and option[1] or option
        refreshHighlights()
    end
})

TabHighlight:CreateSection("Cores")

TabHighlight:CreateColorPicker({
    Name = "Cor Preenchimento",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HighlightFill",
    Callback = function(color)
        HIGHLIGHT_FILL_COLOR = color
        updateHighlightColors()
    end
})

TabHighlight:CreateColorPicker({
    Name = "Cor Contorno",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "HighlightOutline",
    Callback = function(color)
        HIGHLIGHT_OUTLINE_COLOR = color
        updateHighlightColors()
    end
})

TabHighlight:CreateSection("Transparência")

TabHighlight:CreateSlider({
    Name = "Transparência Preenchimento",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "HighlightFillTrans",
    Callback = function(v)
        HIGHLIGHT_FILL_TRANSPARENCY = v
        updateHighlightColors()
    end
})

TabHighlight:CreateSlider({
    Name = "Transparência Contorno",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0,
    Flag = "HighlightOutlineTrans",
    Callback = function(v)
        HIGHLIGHT_OUTLINE_TRANSPARENCY = v
        updateHighlightColors()
    end
})

-- ==================== AIM ASSIST COM SISTEMA DE TIMES ====================
local AIM_ENABLED = false
local AIM_SMOOTHNESS = 0.15
local AIM_FOV = 150
local AIM_SHOW_FOV = true
local AIM_PART = "Head"
local AIM_TEAM_FILTER = "All"
local fovCircle

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = AIM_FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and shouldShowPlayer(player, AIM_TEAM_FILTER) then
            local targetPart = player.Character:FindFirstChild(AIM_PART)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function aimAtPlayer(player)
    if not player or not player.Character then return end
    local targetPart = player.Character:FindFirstChild(AIM_PART)
    if not targetPart then return end
    
    local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
    local mousePos = UserInputService:GetMouseLocation()
    
    local deltaX = (targetPos.X - mousePos.X) * AIM_SMOOTHNESS
    local deltaY = (targetPos.Y - mousePos.Y) * AIM_SMOOTHNESS
    
    mousemoverel(deltaX, deltaY)
end

local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 50
    fovCircle.Radius = AIM_FOV
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 1
    fovCircle.Visible = AIM_SHOW_FOV
end

createFOVCircle()

RunService.RenderStepped:Connect(function()
    if fovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = AIM_FOV
        fovCircle.Visible = AIM_SHOW_FOV and AIM_ENABLED
    end
    
    if not AIM_ENABLED then return end
    local target = getClosestPlayerInFOV()
    if target then aimAtPlayer(target) end
end)

-- Aim UI
TabAim:CreateSection("Aim Assist")

TabAim:CreateToggle({
    Name = "Ativar Aim",
    CurrentValue = false,
    Flag = "AimEnabled",
    Callback = function(v)
        AIM_ENABLED = v
    end
})

-- DROPDOWN DE FILTRO DE TIME AIM
TabAim:CreateDropdown({
    Name = "Filtro de Time",
    Options = {"All", "Team", "Enemy"},
    CurrentOption = {"All"},
    MultipleOptions = false,
    Flag = "AimTeamFilter",
    Callback = function(option)
        AIM_TEAM_FILTER = typeof(option) == "table" and option[1] or option
    end
})

TabAim:CreateSection("Configurações")

TabAim:CreateSlider({
    Name = "Suavidade",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = 0.15,
    Flag = "AimSmooth",
    Callback = function(v)
        AIM_SMOOTHNESS = v
    end
})

TabAim:CreateSlider({
    Name = "FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "AimFOV",
    Callback = function(v)
        AIM_FOV = v
    end
})

TabAim:CreateToggle({
    Name = "Mostrar FOV",
    CurrentValue = true,
    Flag = "AimShowFOV",
    Callback = function(v)
        AIM_SHOW_FOV = v
    end
})

TabAim:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "AimPart",
    Callback = function(option)
        AIM_PART = typeof(option) == "table" and option[1] or option
    end
})

-- ==================== PROTECTION ====================
local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:CreateSection("Health Protection")

TabProt:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        godMode = v
    end
})

TabProt:CreateToggle({
    Name = "Lock HP",
    CurrentValue = false,
    Flag = "LockHP",
    Callback = function(v)
        lockHP = v
    end
})

TabProt:CreateSection("Movement Protection")

TabProt:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:CreateToggle({
    Name = "Anti Knockback",
    CurrentValue = false,
    Flag = "AntiKB",
    Callback = function(v)
        antiKB = v
    end
})

-- ==================== PLAYERS ====================
TabPlayers:CreateSection("Player List")

local selectedPlayer = nil

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(names, p.Name)
        end
    end
    return #names > 0 and names or {"No players"}
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = getPlayerNames(),
    CurrentOption = {getPlayerNames()[1]},
    MultipleOptions = false,
    Flag = "SelectedPlayer",
    Callback = function(option)
        local name = typeof(option) == "table" and option[1] or option
        selectedPlayer = Players:FindFirstChild(name)
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    playerDropdown:Refresh(getPlayerNames())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    playerDropdown:Refresh(getPlayerNames())
end)

TabPlayers:CreateSection("Actions")

TabPlayers:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Espiar Jogador",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Camera.CameraSubject = selectedPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TabPlayers:CreateButton({
    Name = "Voltar Camera",
    Callback = function()
        if Humanoid then
            Camera.CameraSubject = Humanoid
        end
    end
})

-- ==================== WAYPOINTS ====================
local savedWaypoints = {}

TabWaypoints:CreateSection("Waypoint Management")

local waypointName = "Waypoint1"

TabWaypoints:CreateInput({
    Name = "Nome do Waypoint",
    PlaceholderText = "Waypoint1",
    RemoveTextAfterFocusLost = false,
    Flag = "WaypointName",
    Callback = function(text)
        waypointName = text
    end
})

TabWaypoints:CreateButton({
    Name = "Salvar Posição",
    Callback = function()
        if HRP then
            savedWaypoints[waypointName] = HRP.CFrame
            Rayfield:Notify({
                Title = "Waypoint Salvo",
                Content = waypointName .. " foi salvo!",
                Duration = 2
            })
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Teleportar",
    Callback = function()
        if savedWaypoints[waypointName] and HRP then
            HRP.CFrame = savedWaypoints[waypointName]
        end
    end
})

TabWaypoints:CreateButton({
    Name = "Deletar",
    Callback = function()
        savedWaypoints[waypointName] = nil
    end
})

-- ==================== VISUALS ====================
TabVisuals:CreateSection("Lighting")

TabVisuals:CreateSlider({
    Name = "Brightness",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "Brightness",
    Callback = function(v)
        Lighting.Brightness = v
    end
})

TabVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
    end
})

TabVisuals:CreateSection("FOV")

TabVisuals:CreateSlider({
    Name = "Field of View",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

-- ==================== WORLD ====================
TabWorld:CreateSection("Time")

TabWorld:CreateSlider({
    Name = "Hora do Dia",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Flag = "TimeOfDay",
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:CreateSection("Weather")

TabWorld:CreateButton({
    Name = "Remover Névoa",
    Callback = function()
        Lighting.FogEnd = 100000
    end
})

-- ==================== FPS/STATS ====================
local ANTI_LAG_ENABLED = false
local noclip = false

TabFPS:CreateSection("Performance")

local function applyAntiLag()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        end
    end
end

TabFPS:CreateToggle({
    Name = "Anti-Lag",
    CurrentValue = false,
    Flag = "AntiLag",
    Callback = function(v)
        ANTI_LAG_ENABLED = v
        if v then applyAntiLag() end
    end
})

TabFPS:CreateSlider({
    Name = "FPS Cap",
    Range = {60, 240},
    Increment = 10,
    CurrentValue = 60,
    Flag = "FPSCap",
    Callback = function(v)
        setfpscap(v)
    end
})

TabFPS:CreateSection("Stats")

local statsLabel = TabFPS:CreateLabel("HP: 0/0 | Speed: 0 | Jump: 0")
local fpsLabel = TabFPS:CreateLabel("FPS: 0")
local pingLabel = TabFPS:CreateLabel("Ping: 0ms")

task.spawn(function()
    while task.wait(0.5) do
        if Character and Humanoid and HRP then
            statsLabel:Set(string.format("HP: %d/%d | Speed: %d | Jump: %d",
                math.floor(Humanoid.Health),
                math.floor(Humanoid.MaxHealth),
                math.floor(Humanoid.WalkSpeed),
                math.floor(Humanoid.JumpPower)
            ))
        end
    end
end)

local fpsCounter = 0
local lastFPSUpdate = tick()

RunService.RenderStepped:Connect(function()
    fpsCounter = fpsCounter + 1
    if tick() - lastFPSUpdate >= 1 then
        fpsLabel:Set("FPS: " .. fpsCounter)
        fpsCounter = 0
        lastFPSUpdate = tick()
    end
end)

task.spawn(function()
    while task.wait(2) do
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        pingLabel:Set(string.format("Ping: %.0f ms", ping))
    end
end)

-- ==================== CONFIG ====================
TabConfig:CreateSection("Anti AFK")

local ANTI_AFK_ENABLED = false

local VirtualUser = game:GetService("VirtualUser")
LP.Idled:Connect(function()
    if ANTI_AFK_ENABLED then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

TabConfig:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        ANTI_AFK_ENABLED = v
    end
})

TabConfig:CreateSection("GUI")

TabConfig:CreateButton({
    Name = "Destruir GUI",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        Rayfield:Destroy()
    end
})

-- ==================== UTILITY ====================
TabUtil:CreateSection("Noclip")

TabUtil:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        noclip = v
    end
})

TabUtil:CreateSection("Server")

TabUtil:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

TabUtil:CreateButton({
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

-- ==================== RUNTIME LOOP ====================
local lastRuntimeUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    if not Character or not HRP or not Humanoid then return end

    local now = tick()
    if now - lastRuntimeUpdate < 0.033 then return end
    lastRuntimeUpdate = now

    if flyUpImpulse > 0 then
        flyUpImpulse = flyUpImpulse - dt
    end

    if fly then
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

print("✅ Universal Hub - Sistema de Times Funcionando!")

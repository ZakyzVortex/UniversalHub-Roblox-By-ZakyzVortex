-- ================== UNIVERSAL HUB - WINDUI VERSION COMPLETA ==================
-- Universal Hub WindUI By ZakyzVortex (Mobile Optimized & Organized)
-- Convertido da v13 Rayfield para WindUI - TODAS AS FUNÇÕES MANTIDAS

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
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then
        ctrl.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then
        ctrl.b = 1
    elseif input.KeyCode == Enum.KeyCode.A then
        ctrl.l = 1
    elseif input.KeyCode == Enum.KeyCode.D then
        ctrl.r = 1
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

TabMove:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(v)
        toggleFly(v)
    end
})

TabMove:Slider({
    Title = "Velocidade do Fly",
    Min = 1,
    Max = 10,
    Default = 1,
    Increment = 1,
    Callback = function(v)
        flySpeed = v
    end
})

TabMove:Section({ Title = "Pulos" })

TabMove:Toggle({
    Title = "Pulo Infinito",
    Default = false,
    Callback = function(v)
        infJump = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

TabMove:Toggle({
    Title = "Anti-Queda (Hold Space)",
    Default = false,
    Callback = function(v)
        antiFall = v
    end
})

local flyUpImpulse = 0
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if antiFall and input.KeyCode == Enum.KeyCode.Space then
        flyUpImpulse = 0.5
    end
end)

-- ==================================================================================
-- ============================== AUTO FARM TAB =====================================
-- ==================================================================================

TabCombat:Section({ Title = "Auto Click" })

local autoClick = false
local autoClickDelay = 0.1

TabCombat:Toggle({
    Title = "Auto Click",
    Default = false,
    Callback = function(v)
        autoClick = v
    end
})

TabCombat:Slider({
    Title = "Click Delay (segundos)",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Increment = 0.01,
    Callback = function(v)
        autoClickDelay = v
    end
})

spawn(function()
    while true do
        if autoClick then
            mouse1click()
        end
        task.wait(autoClickDelay)
    end
end)

TabCombat:Section({ Title = "Auto Farm" })

local autoFarm = false
local farmTarget = nil

TabCombat:Toggle({
    Title = "Auto Farm (Experimental)",
    Default = false,
    Callback = function(v)
        autoFarm = v
    end
})

-- ==================================================================================
-- ============================== ESP TAB ===========================================
-- ==================================================================================

TabESP:Section({ Title = "ESP Settings" })

local espEnabled = false
local espDistance = 1000
local espTeamFilter = "All"
local espBoxes = {}

local function clearAllESP()
    for _, box in pairs(espBoxes) do
        if box then
            box:Remove()
        end
    end
    espBoxes = {}
end

local function createESP(player)
    if not player or player == LP then return end
    
    local function addESP(character)
        if not character then return end
        
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        
        if espBoxes[player.UserId] then
            espBoxes[player.UserId]:Remove()
        end
        
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false
        
        espBoxes[player.UserId] = box
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not espEnabled or not player or not player.Parent or not character or not character.Parent then
                box:Remove()
                if connection then connection:Disconnect() end
                return
            end
            
            if not shouldShowPlayer(player, espTeamFilter) then
                box.Visible = false
                return
            end
            
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            
            if onScreen and distance <= espDistance then
                local scale = 1000 / (Camera.CFrame.Position - hrp.Position).Magnitude
                local size = Vector2.new(scale * 4, scale * 6)
                
                box.Size = size
                box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                box.Visible = true
                
                if player.Team then
                    box.Color = player.Team.TeamColor.Color
                else
                    box.Color = Color3.fromRGB(255, 255, 255)
                end
            else
                box.Visible = false
            end
        end)
    end
    
    if player.Character then
        addESP(player.Character)
    end
    
    player.CharacterAdded:Connect(addESP)
end

TabESP:Toggle({
    Title = "Enable ESP",
    Default = false,
    Callback = function(v)
        espEnabled = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    createESP(player)
                end
            end
        else
            clearAllESP()
        end
    end
})

TabESP:Slider({
    Title = "Max Distance",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Increment = 100,
    Callback = function(v)
        espDistance = v
    end
})

TabESP:Dropdown({
    Title = "Team Filter",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        espTeamFilter = v
    end
})

Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= LP then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espBoxes[player.UserId] then
        espBoxes[player.UserId]:Remove()
        espBoxes[player.UserId] = nil
    end
end)

-- ==================================================================================
-- ============================== HIGHLIGHT ESP TAB =================================
-- ==================================================================================

TabHighlight:Section({ Title = "Highlight ESP Settings" })

local highlightEnabled = false
local highlightFillColor = Color3.fromRGB(255, 0, 0)
local highlightOutlineColor = Color3.fromRGB(255, 255, 255)
local highlightTransparency = 0.5
local highlightTeamFilter = "All"
local highlights = {}

local function removeAllHighlights()
    for _, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    highlights = {}
end

local function createHighlight(player)
    if not player or player == LP then return end
    
    local function addHighlight(character)
        if not character then return end
        
        if highlights[player.UserId] then
            highlights[player.UserId]:Destroy()
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Adornee = character
        highlight.FillColor = highlightFillColor
        highlight.OutlineColor = highlightOutlineColor
        highlight.FillTransparency = highlightTransparency
        highlight.OutlineTransparency = 0
        highlight.Parent = character
        
        highlights[player.UserId] = highlight
        
        RunService.RenderStepped:Connect(function()
            if not highlightEnabled or not player or not player.Parent or not character or not character.Parent then
                if highlight then
                    highlight:Destroy()
                end
                return
            end
            
            highlight.Enabled = shouldShowPlayer(player, highlightTeamFilter)
            
            if player.Team and highlight.Enabled then
                highlight.FillColor = player.Team.TeamColor.Color
            else
                highlight.FillColor = highlightFillColor
            end
        end)
    end
    
    if player.Character then
        addHighlight(player.Character)
    end
    
    player.CharacterAdded:Connect(addHighlight)
end

TabHighlight:Toggle({
    Title = "Enable Highlight ESP",
    Default = false,
    Callback = function(v)
        highlightEnabled = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    createHighlight(player)
                end
            end
        else
            removeAllHighlights()
        end
    end
})

TabHighlight:Slider({
    Title = "Fill Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Increment = 0.1,
    Callback = function(v)
        highlightTransparency = v
        for _, highlight in pairs(highlights) do
            if highlight then
                highlight.FillTransparency = v
            end
        end
    end
})

TabHighlight:Dropdown({
    Title = "Team Filter",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "All",
    Callback = function(v)
        highlightTeamFilter = v
    end
})

Players.PlayerAdded:Connect(function(player)
    if highlightEnabled and player ~= LP then
        createHighlight(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if highlights[player.UserId] then
        highlights[player.UserId]:Destroy()
        highlights[player.UserId] = nil
    end
end)

-- ==================================================================================
-- ============================== AIM ASSIST TAB ====================================
-- ==================================================================================

TabAim:Section({ Title = "Aim Assist Settings" })

local aimAssistEnabled = false
local aimAssistSmoothness = 0.5
local aimAssistFOV = 200
local aimAssistWallcheck = true
local aimAssistTeamFilter = "EnemyTeam"

local function getClosestPlayerInFOV()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and shouldShowPlayer(player, aimAssistTeamFilter) then
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        
                        if distance < aimAssistFOV and distance < shortestDistance then
                            if aimAssistWallcheck then
                                local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000)
                                local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character})
                                
                                if hit and hit:IsDescendantOf(character) then
                                    closest = head
                                    shortestDistance = distance
                                end
                            else
                                closest = head
                                shortestDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimAssistEnabled then
        local target = getClosestPlayerInFOV()
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local diff = Vector2.new(targetPos.X - mousePos.X, targetPos.Y - mousePos.Y)
            
            mousemoverel(diff.X * aimAssistSmoothness, diff.Y * aimAssistSmoothness)
        end
    end
end)

TabAim:Toggle({
    Title = "Enable Aim Assist",
    Default = false,
    Callback = function(v)
        aimAssistEnabled = v
    end
})

TabAim:Slider({
    Title = "Smoothness",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Increment = 0.1,
    Callback = function(v)
        aimAssistSmoothness = v
    end
})

TabAim:Slider({
    Title = "FOV (pixels)",
    Min = 50,
    Max = 500,
    Default = 200,
    Increment = 10,
    Callback = function(v)
        aimAssistFOV = v
    end
})

TabAim:Toggle({
    Title = "Wall Check",
    Default = true,
    Callback = function(v)
        aimAssistWallcheck = v
    end
})

TabAim:Dropdown({
    Title = "Team Filter",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "EnemyTeam",
    Callback = function(v)
        aimAssistTeamFilter = v
    end
})

-- ==================================================================================
-- ============================== PLAYER AIM TAB ====================================
-- ==================================================================================

TabPlayerAim:Section({ Title = "Player Aim Settings" })

local playerAimEnabled = false
local playerAimTarget = nil
local playerAimTeamFilter = "EnemyTeam"

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and shouldShowPlayer(player, playerAimTeamFilter) then
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    local distance = (head.Position - Camera.CFrame.Position).Magnitude
                    if distance < shortestDistance then
                        closest = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closest
end

RunService.RenderStepped:Connect(function()
    if playerAimEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

TabPlayerAim:Toggle({
    Title = "Enable Player Aim",
    Default = false,
    Callback = function(v)
        playerAimEnabled = v
    end
})

TabPlayerAim:Dropdown({
    Title = "Team Filter",
    Options = {"All", "MyTeam", "EnemyTeam"},
    Default = "EnemyTeam",
    Callback = function(v)
        playerAimTeamFilter = v
    end
})

-- ==================================================================================
-- ============================== PROTECTION TAB ====================================
-- ==================================================================================

TabProt:Section({ Title = "Health Protection" })

local godMode = false
local lockHP = false
local antiVoid = false
local antiKB = false

TabProt:Toggle({
    Title = "God Mode",
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

TabProt:Toggle({
    Title = "Anti-Void",
    Default = false,
    Callback = function(v)
        antiVoid = v
    end
})

TabProt:Toggle({
    Title = "Anti-Knockback",
    Default = false,
    Callback = function(v)
        antiKB = v
    end
})

TabProt:Section({ Title = "Anti-Fling" })

local antiFling = false

TabProt:Toggle({
    Title = "Anti-Fling",
    Default = false,
    Callback = function(v)
        antiFling = v
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if v then
                    part.CanCollide = false
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.CustomPhysicalProperties = PhysicalProperties.new(9e99, 9e99, 9e99, 9e99, 9e99)
                else
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                end
            end
        end
    end
})

-- ==================================================================================
-- ============================== PLAYERS TAB =======================================
-- ==================================================================================

TabPlayers:Section({ Title = "Player List" })

local selectedPlayer = nil
local playerNames = {}

local function updatePlayerList()
    playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(playerNames, player.Name)
        end
    end
    return playerNames
end

local playerDropdown = TabPlayers:Dropdown({
    Title = "Select Player",
    Options = updatePlayerList(),
    Default = "",
    Callback = function(v)
        selectedPlayer = Players:FindFirstChild(v)
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    playerDropdown:Update(updatePlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    playerDropdown:Update(updatePlayerList())
end)

TabPlayers:Section({ Title = "Player Actions" })

TabPlayers:Button({
    Title = "Teleport to Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and HRP then
            local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame
            end
        end
    end
})

TabPlayers:Button({
    Title = "View Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetHumanoid = selectedPlayer.Character:FindFirstChild("Humanoid")
            if targetHumanoid then
                Camera.CameraSubject = targetHumanoid
            end
        end
    end
})

TabPlayers:Button({
    Title = "Reset View",
    Callback = function()
        if Humanoid then
            Camera.CameraSubject = Humanoid
        end
    end
})

TabPlayers:Section({ Title = "Spectate" })

local spectateEnabled = false

TabPlayers:Toggle({
    Title = "Spectate Selected Player",
    Default = false,
    Callback = function(v)
        spectateEnabled = v
        if v and selectedPlayer and selectedPlayer.Character then
            local targetHumanoid = selectedPlayer.Character:FindFirstChild("Humanoid")
            if targetHumanoid then
                Camera.CameraSubject = targetHumanoid
            end
        else
            if Humanoid then
                Camera.CameraSubject = Humanoid
            end
        end
    end
})

-- ==================================================================================
-- ============================== WAYPOINTS TAB =====================================
-- ==================================================================================

TabWaypoints:Section({ Title = "Waypoints" })

local waypoints = {}

TabWaypoints:Button({
    Title = "Add Current Position",
    Callback = function()
        if HRP then
            local waypointName = "Waypoint " .. (#waypoints + 1)
            table.insert(waypoints, {
                name = waypointName,
                position = HRP.Position
            })
            print("✅ Waypoint salvo: " .. waypointName)
        end
    end
})

TabWaypoints:Button({
    Title = "Clear All Waypoints",
    Callback = function()
        waypoints = {}
        print("✅ Waypoints limpos")
    end
})

TabWaypoints:Section({ Title = "Teleport to Waypoint" })

local function getWaypointNames()
    local names = {}
    for _, wp in pairs(waypoints) do
        table.insert(names, wp.name)
    end
    return names
end

local selectedWaypoint = nil

local waypointDropdown = TabWaypoints:Dropdown({
    Title = "Select Waypoint",
    Options = getWaypointNames(),
    Default = "",
    Callback = function(v)
        for _, wp in pairs(waypoints) do
            if wp.name == v then
                selectedWaypoint = wp
                break
            end
        end
    end
})

TabWaypoints:Button({
    Title = "Teleport to Waypoint",
    Callback = function()
        if selectedWaypoint and HRP then
            HRP.CFrame = CFrame.new(selectedWaypoint.position)
        end
    end
})

-- ==================================================================================
-- ============================== VISUALS TAB =======================================
-- ==================================================================================

TabVisuals:Section({ Title = "Lighting" })

local fullbright = false
local oldAmbient, oldBrightness, oldClockTime

local function toggleFullbright(enabled)
    if enabled then
        oldAmbient = Lighting.Ambient
        oldBrightness = Lighting.Brightness
        oldClockTime = Lighting.ClockTime
        
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        if oldAmbient then
            Lighting.Ambient = oldAmbient
            Lighting.Brightness = oldBrightness
            Lighting.ClockTime = oldClockTime
        end
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end

TabVisuals:Toggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(v)
        fullbright = v
        toggleFullbright(v)
    end
})

TabVisuals:Section({ Title = "FOV" })

local defaultFOV = Camera.FieldOfView

TabVisuals:Slider({
    Title = "Field of View",
    Min = 70,
    Max = 120,
    Default = defaultFOV,
    Increment = 1,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

TabVisuals:Button({
    Title = "Reset FOV",
    Callback = function()
        Camera.FieldOfView = defaultFOV
    end
})

TabVisuals:Section({ Title = "Remove Effects" })

TabVisuals:Button({
    Title = "Remove Blur",
    Callback = function()
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") then
                effect:Destroy()
            end
        end
    end
})

TabVisuals:Button({
    Title = "Remove Fog",
    Callback = function()
        Lighting.FogEnd = 1e10
    end
})

TabVisuals:Button({
    Title = "Remove All Effects",
    Callback = function()
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                effect:Destroy()
            end
        end
        Lighting.FogEnd = 1e10
    end
})

-- ==================================================================================
-- ============================== WORLD TAB =========================================
-- ==================================================================================

TabWorld:Section({ Title = "Time" })

TabWorld:Slider({
    Title = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 12,
    Increment = 1,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

TabWorld:Toggle({
    Title = "Freeze Time",
    Default = false,
    Callback = function(v)
        if v then
            Lighting:SetAttribute("ClockTime", Lighting.ClockTime)
            Lighting.Changed:Connect(function()
                if Lighting:GetAttribute("ClockTime") then
                    Lighting.ClockTime = Lighting:GetAttribute("ClockTime")
                end
            end)
        else
            Lighting:SetAttribute("ClockTime", nil)
        end
    end
})

TabWorld:Section({ Title = "Gravity" })

TabWorld:Slider({
    Title = "Gravity",
    Min = 0,
    Max = 196.2,
    Default = 196.2,
    Increment = 10,
    Callback = function(v)
        workspace.Gravity = v
    end
})

TabWorld:Button({
    Title = "Reset Gravity",
    Callback = function()
        workspace.Gravity = 196.2
    end
})

-- ==================================================================================
-- ============================== FPS/STATS TAB =====================================
-- ==================================================================================

TabFPS:Section({ Title = "FPS Counter" })

local fpsLabel = TabFPS:Label({ Title = "FPS: 0" })
local pingLabel = TabFPS:Label({ Title = "Ping: 0ms" })

local function updateStats()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    
    fpsLabel:Update({ Title = "FPS: " .. fps })
    pingLabel:Update({ Title = "Ping: " .. ping .. "ms" })
end

spawn(function()
    while true do
        updateStats()
        task.wait(1)
    end
end)

TabFPS:Section({ Title = "Performance" })

local fpsBoost = false

TabFPS:Toggle({
    Title = "FPS Boost",
    Default = false,
    Callback = function(v)
        fpsBoost = v
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end
    end
})

TabFPS:Button({
    Title = "Hide 3D Objects (Extreme FPS Boost)",
    Callback = function()
        resetVisuals()
    end
})

TabFPS:Section({ Title = "Memory" })

TabFPS:Button({
    Title = "Collect Garbage",
    Callback = function()
        collectgarbage("collect")
        print("✅ Garbage collected")
    end
})

-- ==================================================================================
-- ============================== CONFIG TAB ========================================
-- ==================================================================================

TabConfig:Section({ Title = "Keybinds" })

TabConfig:Label({ Title = "ESP: E | Highlight: H" })
TabConfig:Label({ Title = "Aim: R | Player Aim: T" })
TabConfig:Label({ Title = "Fly: F | Noclip: N" })
TabConfig:Label({ Title = "Inf Jump: J | Auto Click: C" })
TabConfig:Label({ Title = "God Mode: G | Fullbright: B" })
TabConfig:Label({ Title = "Toggle GUI: RightControl" })

TabConfig:Section({ Title = "GUI" })

TabConfig:Button({
    Title = "Destruir GUI (Irreversível)",
    Callback = function()
        clearAllESP()
        removeAllHighlights()
        print("⚠️ GUI Destruída - Recarregue o script")
        task.wait(1)
        Window:Destroy()
    end
})

-- ==================================================================================
-- ============================== UTILITY TAB =======================================
-- ==================================================================================

TabUtil:Section({ Title = "Noclip" })

local noclip = false

TabUtil:Toggle({
    Title = "Noclip",
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

print("✅ Universal Hub - WindUI Version COMPLETA")
print("📊 ESP: Sistema completo com filtros de time")
print("✨ Highlight ESP: Sistema de destaque funcional")
print("🎯 Aim Assist: Mira automática com wallcheck")
print("👥 Player Aim: Sistema de lock em jogadores")
print("🛡️ Protection: God Mode, Anti-Void, Anti-KB")
print("🎮 Movement: Fly, Noclip, Velocidade, Pulo")
print("🌍 World: Controle de tempo e gravidade")
print("📍 Waypoints: Sistema de salvamento de posições")
print("🔧 Todas as funcionalidades da v13 Rayfield convertidas!")
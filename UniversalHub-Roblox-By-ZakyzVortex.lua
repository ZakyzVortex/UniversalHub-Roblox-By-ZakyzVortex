-- Universal Hub Rayfield By ZakyzVortex
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Character refs
local Character, Humanoid, HRP
local function BindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid.UseJumpPower = true
end
BindCharacter(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(BindCharacter)

-- UI
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "By ZakyzVortex",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "Config"
    }
})

local TabMove = Window:CreateTab("Player / Movement")
local TabProt = Window:CreateTab("Protection")
local TabPlayers = Window:CreateTab("Players")
local TabWorld = Window:CreateTab("World")
local TabUtil = Window:CreateTab("Utility")

-- ================== ESP ==================
local TabESP = Window:CreateTab("ESP")

-- Estados
local ESP_ENABLED = false
local NAME_ENABLED = true
local DISTANCE_ENABLED = true
local LINE_ENABLED = true -- linha única
local HEALTH_ENABLED = true
local OUTLINE_ENABLED = true -- quadrado contorno

local ESP_COLOR = Color3.fromRGB(255,0,0)
local LINE_COLOR = Color3.fromRGB(255,255,255)

local ESP_OBJECTS = {}
local DRAWINGS = {}

local TEAM_FILTER = "All"

local function getPlayerTeam(player)
    if player.Team and player.Team.Name then
        return player.Team.Name
    elseif player.TeamColor then
        return tostring(player.TeamColor)
    else
        return "NoTeam"
    end
end

local function createESP(player)
    if player == LP then return end
    if not player.Character then return end

    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if TEAM_FILTER ~= "All" then
        local myTeam = LP.Team and LP.Team.Name or (LP.TeamColor and tostring(LP.TeamColor)) or "NoTeam"
        local playerTeam = getPlayerTeam(player)
        if TEAM_FILTER == "MyTeam" and playerTeam ~= myTeam then return end
        if TEAM_FILTER == "EnemyTeam" and playerTeam == myTeam then return end
    end

    -- Nome / Distância / Vida
    local billboard
    if NAME_ENABLED or DISTANCE_ENABLED or HEALTH_ENABLED then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPName"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0,150,0,50)
        billboard.StudsOffset = Vector3.new(0,3,0)
        billboard.AlwaysOnTop = true

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = ESP_COLOR
        txt.TextStrokeTransparency = 0
        txt.TextScaled = true
        txt.TextWrapped = true
        txt.Parent = billboard
        billboard.Parent = hrp

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not txt.Parent or not hum or hum.Health <= 0 then conn:Disconnect() return end
            local dist = math.floor((hrp.Position - HRP.Position).Magnitude)
            local parts = {}
            if NAME_ENABLED then table.insert(parts, player.Name) end
            if DISTANCE_ENABLED then table.insert(parts, "["..dist.."m]") end
            if HEALTH_ENABLED then table.insert(parts, "HP:"..math.floor(hum.Health)) end
            txt.Text = table.concat(parts," | ")
        end)
    end

    -- Linha única
    local line
    if LINE_ENABLED then
        line = Drawing.new("Line")
        line.Color = LINE_COLOR
        line.Thickness = 1
        line.Transparency = 1
        line.Visible = true
        table.insert(DRAWINGS, line)

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not line or not hrp or not hrp.Parent or hum.Health <= 0 or not ESP_ENABLED then
                line:Remove()
                conn:Disconnect()
                return
            end
            local rootPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y)
                line.To = Vector2.new(rootPos.X, rootPos.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end)
    end

    -- Contorno 4 linhas sempre de frente para a câmera
    local outline
    if OUTLINE_ENABLED then
        outline = {}
        for i=1,4 do
            local l = Drawing.new("Line")
            l.Color = ESP_COLOR
            l.Thickness = 2
            l.Transparency = 1
            l.Visible = true
            table.insert(outline, l)
            table.insert(DRAWINGS, l)
        end

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not hrp or not hrp.Parent or hum.Health <= 0 or not ESP_ENABLED then
                for _,l in ipairs(outline) do l:Remove() end
                conn:Disconnect()
                return
            end

            local cam = workspace.CurrentCamera
            local height = 3
            local width = 2

            local corners = {
                hrp.Position + cam.CFrame.RightVector * width + Vector3.new(0,height,0),
                hrp.Position - cam.CFrame.RightVector * width + Vector3.new(0,height,0),
                hrp.Position - cam.CFrame.RightVector * width + Vector3.new(0,-height,0),
                hrp.Position + cam.CFrame.RightVector * width + Vector3.new(0,-height,0)
            }

            local screen = {}
            for i,corner in ipairs(corners) do
                local pos,_ = cam:WorldToViewportPoint(corner)
                screen[i] = Vector2.new(pos.X,pos.Y)
            end

            for i=1,4 do
                outline[i].From = screen[i]
                outline[i].To = screen[i%4+1]
                outline[i].Visible = true
            end
        end)
    end

    ESP_OBJECTS[player] = {billboard=billboard, line=line, outline=outline}

    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESP_ENABLED then createESP(player) end
    end)
end

local function clearESP()
    for _,v in pairs(ESP_OBJECTS) do
        if v.billboard then v.billboard:Destroy() end
        if v.line then v.line:Remove() end
        if v.outline then for _,l in ipairs(v.outline) do l:Remove() end end
    end
    ESP_OBJECTS = {}
    for _,d in ipairs(DRAWINGS) do if d then d:Remove() end end
    DRAWINGS = {}
end

local function refreshESP()
    clearESP()
    if ESP_ENABLED then
        for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
    end
end

-- UI toggles
TabESP:CreateToggle({Name="Ativar ESP", CurrentValue=false, Callback=function(v) ESP_ENABLED=v refreshESP() end})
TabESP:CreateToggle({Name="Mostrar Nome", CurrentValue=true, Callback=function(v) NAME_ENABLED=v refreshESP() end})
TabESP:CreateToggle({Name="Mostrar Distância", CurrentValue=true, Callback=function(v) DISTANCE_ENABLED=v refreshESP() end})
TabESP:CreateToggle({Name="Mostrar Vida", CurrentValue=true, Callback=function(v) HEALTH_ENABLED=v refreshESP() end})
TabESP:CreateToggle({Name="Linha Única", CurrentValue=true, Callback=function(v) LINE_ENABLED=v refreshESP() end})
TabESP:CreateToggle({Name="Contorno 4 Linhas", CurrentValue=true, Callback=function(v) OUTLINE_ENABLED=v refreshESP() end})

-- ================== AIM ASSIST MOBILE ==================
local TabAim = Window:CreateTab("Aim Assist Mobile")

local AIM_ENABLED = false
local AIM_FOV = 100 -- distância máxima em studs para mirar
local AIM_SMOOTH = 0.2 -- suavidade do movimento da câmera
local AIM_TARGET_PART = "Head" -- padrão: mira na cabeça
local currentTarget = nil -- mantém alvo fixo até morrer ou sair do FOV

-- Função para checar se há linha de visão
local function isVisible(targetPart)
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LP.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
    end
    return true
end

-- UI
TabAim:CreateToggle({
    Name = "Ativar Aim Assist",
    CurrentValue = false,
    Callback = function(v) AIM_ENABLED = v end
})

TabAim:CreateSlider({
    Name = "FOV (distância para mirar)",
    Range = {10,500},
    Increment = 1,
    CurrentValue = AIM_FOV,
    Callback = function(v) AIM_FOV = v end
})

TabAim:CreateSlider({
    Name = "Suavidade da mira",
    Range = {0.05,1},
    Increment = 0.01,
    CurrentValue = AIM_SMOOTH,
    Callback = function(v) AIM_SMOOTH = v end
})

TabAim:CreateDropdown({
    Name = "Parte do corpo",
    Options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption = "Head",
    Callback = function(opt) AIM_TARGET_PART = opt end
})

-- Runtime: mira automática
RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then currentTarget = nil return end
    if not Character or not Humanoid or not HRP then return end

    -- valida currentTarget
    if currentTarget then
        if not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") or currentTarget.Parent.Humanoid.Health <= 0 then
            currentTarget = nil
        elseif (currentTarget.Position - HRP.Position).Magnitude > AIM_FOV or not isVisible(currentTarget) then
            currentTarget = nil
        end
    end

    -- busca novo alvo apenas se não tiver alvo atual
    if not currentTarget then
        local closestDist = AIM_FOV
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild(AIM_TARGET_PART) and p.Character:FindFirstChildOfClass("Humanoid") then
                local part = p.Character[AIM_TARGET_PART]
                local dist = (part.Position - HRP.Position).Magnitude
                if dist <= closestDist and isVisible(part) then
                    closestDist = dist
                    currentTarget = part
                end
            end
        end
    end

    -- mira no alvo atual
    if currentTarget then
        local cam = workspace.CurrentCamera
        local direction = (currentTarget.Position - cam.CFrame.Position).Unit
        local newCFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + direction)
        cam.CFrame = cam.CFrame:Lerp(newCFrame, AIM_SMOOTH)
    end
end)

-- STATES
local fly, flySpeed, flyUpImpulse = false, 100, 0
local infJump, antiFall, lockHP, noclip = false, false, false, false
local antiVoid, antiKB, godMode = false, false, false

-- HELPERS
local function safeSetWalk(v)
    if Humanoid then Humanoid.WalkSpeed = v end
end
local function safeSetJumpPower(v)
    if Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = v
    end
end

-- ================= PLAYER =================
TabMove:CreateSlider({
    Name = "Velocidade",
    Range = {16,300},
    Increment = 1,
    CurrentValue = 16,
    Callback = safeSetWalk
})

TabMove:CreateSlider({
    Name = "Pulo",
    Range = {50,300},
    Increment = 1,
    CurrentValue = 50,
    Callback = safeSetJumpPower
})

TabMove:CreateSlider({
    Name = "Fly Speed",
    Range = {50,500},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v) flySpeed = v end
})

TabMove:CreateToggle({
    Name = "Fly (analógico)",
    Callback = function(v)
        fly = v
        if not v and HRP then
            for _,i in pairs({"FlyVel","FlyGyro"}) do
                local o = HRP:FindFirstChild(i)
                if o then o:Destroy() end
            end
        end
    end
})

TabMove:CreateToggle({ Name="Infinite Jump", Callback=function(v) infJump=v end })
TabMove:CreateToggle({ Name="Anti Fall", Callback=function(v) antiFall=v end })

UserInputService.JumpRequest:Connect(function()
    if fly then flyUpImpulse = 0.18 end
    if infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ================= PROTECTION =================
TabProt:CreateToggle({ Name="God Mode", Callback=function(v) godMode=v end })
TabProt:CreateToggle({ Name="Lock HP", Callback=function(v) lockHP=v end })
TabProt:CreateToggle({ Name="Anti Knockback", Callback=function(v) antiKB=v end })
TabProt:CreateToggle({ Name="Anti Void", Callback=function(v) antiVoid=v end })

-- ================= PLAYERS (TP / SPECTATE) =================
local selectedName = nil

local function getPlayerNames()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end

local playerDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Player",
    Options = getPlayerNames(),
    Callback = function(v)
        selectedName = typeof(v)=="table" and v[1] or v
    end
})

TabPlayers:CreateButton({
    Name = "Atualizar Lista",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
    end
})

TabPlayers:CreateButton({
    Name = "TP Player",
    Callback = function()
        local t = Players:FindFirstChild(selectedName)
        if t and t.Character and HRP then
            HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
        end
    end
})

TabPlayers:CreateButton({
    Name = "Spectate",
    Callback = function()
        local t = Players:FindFirstChild(selectedName)
        if t and t.Character then
            Camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
        end
    end
})

TabPlayers:CreateButton({
    Name = "Voltar Camera",
    Callback = function()
        Camera.CameraSubject = Humanoid
    end
})

-- ================= WORLD =================
TabWorld:CreateSlider({
    Name="Hora",
    Range={0,24},
    Increment=0.1,
    CurrentValue=Lighting.ClockTime,
    Callback=function(v) Lighting.ClockTime=v end
})

TabWorld:CreateSlider({
    Name="Gravidade",
    Range={60,500},
    Increment=1,
    CurrentValue=workspace.Gravity,
    Callback=function(v) workspace.Gravity=math.clamp(v,60,500) end
})

TabWorld:CreateButton({ Name="Remover Fog", Callback=function() Lighting.FogEnd=1e6 end })

-- ================= UTILITY =================
TabUtil:CreateToggle({ Name="Noclip", Callback=function(v) noclip=v end })

TabUtil:CreateButton({
    Name="Rejoin",
    Callback=function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

-- ✅ SERVER HOP REAL
TabUtil:CreateButton({
    Name="Server Hop",
    Callback=function()
        local servers = HttpService:JSONDecode(
            game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
        )
        for _,s in pairs(servers.data) do
            if s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                break
            end
        end
    end
})

-- ================= RUNTIME =================
RunService.RenderStepped:Connect(function(dt)
    if not Character or not HRP or not Humanoid then return end

    if flyUpImpulse > 0 then flyUpImpulse -= dt end

    if fly then
        if not HRP:FindFirstChild("FlyVel") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.Name="FlyVel"
            bv.MaxForce=Vector3.new(9e9,9e9,9e9)
            local bg = Instance.new("BodyGyro", HRP)
            bg.Name="FlyGyro"
            bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
        end

        local dir = Humanoid.MoveDirection
        local vel = Vector3.new(dir.X,0,dir.Z)*flySpeed
        if flyUpImpulse>0 then vel+=Vector3.new(0,flySpeed,0) end

        HRP.FlyVel.Velocity = vel
        HRP.FlyGyro.CFrame = Camera.CFrame
    end

    if noclip then
        for _,p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end

    if godMode then
        Humanoid.MaxHealth=math.huge
        Humanoid.Health=Humanoid.MaxHealth
    elseif lockHP then
        Humanoid.Health=Humanoid.MaxHealth
    end

    if antiVoid and HRP.Position.Y < -80 then
        HRP.CFrame += Vector3.new(0,200,0)
    end

    if antiKB then
        HRP.Velocity *= Vector3.new(0.8,0.9,0.8)
    end
end)

print("✅ Universal Hub carregado sem bugs.")



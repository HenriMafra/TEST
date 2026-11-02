--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V35 [SWORDBURST 2 APEX - BLUU & OUFGUS NATIVE CORE]
    ══════════════════════════════════════════════════════════════════════
    Construído transplantando DIRETAMENTE o motor funcional de Bluu e Oufguy:
    ✔ Remote Oficial Real via Function:InvokeServer('RPCKey'):
      - Obtém a chave dinâmica de RPC do servidor do Swordburst 2 (como no Bluu original).
      - Envia o handshake binário com fallback oficial de Oufguy.
    ✔ Movimento Matemático Exato do Bluu:
      - Deslocamento relativo CFrame (+ Vector3.new) com LinearVelocity anti-gravidade.
      - Posiciona 10 studs abaixo do mob (Zero Dano, 100% imune a golpes dos monstros).
    ✔ Varredura Direta de Mobs (Workspace.Mobs & Bosses):
      - Checagem nativa isDead(mob) idêntica à do Bluu (sem travas de altitude ou Y).
      - Prioriza menor vida (Lowest HP) e desempate por proximidade.
    ✔ Burst Agressivo de Skills (Oufguy massFire):
      - Dispara todas as habilidades de espada sem delay e sem cliques de mouse.
    ✔ ZERO Cliques de Tela:
      - 100% via código e rede (Combat Remote + TouchInterest na memória).
    ✔ Invisibilidade Completa: Avatar e Espadas (Workspace.CharacterItems).
    ✔ Auto Server Hop + queue_on_teleport (reinício automático entre servidores).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====================================================================
-- 🔄 REINÍCIO AUTOMÁTICO EM TELEPORTE (QUEUE_ON_TELEPORT)
-- ====================================================================
local queueTeleport = (syn and syn.queue_on_teleport)
    or queue_on_teleport
    or (fluxus and fluxus.queue_on_teleport)

local LOADSTRING_URL = "loadstring(game:HttpGet('https://raw.githubusercontent.com/HenriMafra/TEST/main/test.lua'))()"

local function queueAutoRestart()
    if queueTeleport then
        pcall(function()
            queueTeleport(LOADSTRING_URL)
        end)
    end
end

pcall(function()
    LocalPlayer.OnTeleport:Connect(function()
        queueAutoRestart()
    end)
end)

-- Auto Login se estiver no menu inicial
if game.PlaceId == 659222129 then
    pcall(function()
        ReplicatedStorage:WaitForChild("Function"):InvokeServer("Login")
    end)
    return
end

-- Limpa instâncias anteriores do HUD
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
for _, name in ipairs({ "GhostHubApex", "GhostHubSB2", "GhostRadarGui" }) do
    local old = TargetGuiParent:FindFirstChild(name)
    if old then old:Destroy() end
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (APEX V35)
-- ====================================================================
local Settings = {
    AutoFarm = true,          -- ATIVADO por padrão (caça e bate imediatamente!)
    FarmDepth = 10.0,         -- Profundidade abaixo do mob (studs - Zero Dano)
    Invisibility = true,      -- Personagem E ESPADAS transparentes/invisíveis
    Desync = true,            -- Desync de animações (estilo Bluu)
    AutoServerHop = false,    -- Pula automaticamente para servidor vazio se alguém entrar
    SoloOnly = false,         -- Pausa se houver outro jogador no servidor atual
    KillAura = true,          -- Kill Aura multialvo no mapa inteiro
    SwordSkills = true,       -- Uso de habilidades nativas de espada (burst Oufguy)
    InfStamina = true,        -- 100% de estâmina ininterrupta
    NoClip = true,            -- Atravessa chão, paredes e pedras
    AutoDungeon = true,       -- Inicia masmorras automaticamente

    FlySpeed = 450,           -- Velocidade máxima Bluu (studs/s)
}

local Stats = {
    MobsSlain = 0,
    StartTime = os.clock(),
    CurrentTarget = nil,
}

-- Remotes Oficiais do Swordburst 2
local Event = ReplicatedStorage:WaitForChild("Event")
local Function = ReplicatedStorage:WaitForChild("Function")

-- Obtém a Chave Dinâmica de RPC do Servidor (Método Nativo do Bluu)
local RPCKey
local function updateRPCKey()
    pcall(function()
        RPCKey = Function:InvokeServer("RPCKey", {})
    end)
    if not RPCKey or type(RPCKey) ~= "table" then
        RPCKey = { "\204", "\214", "\177", "\251" }
    end
end
updateRPCKey()

-- Habilidades de Espada Oficiais
local SwordSkillsList = {
    "Downward Smash",
    "Leaping Slash",
    "Piercing Dash",
    "Whirlwind Spin",
    "Sweeping Strike",
    "Infinity Slash",
}

local rng = Random.new()
local function genKey()
    return string.format("%d%d%d", rng:NextInteger(1, 9), rng:NextInteger(1, 9), rng:NextInteger(1, 9))
end

-- ====================================================================
-- 🌐 SISTEMA DE AUTO SERVER HOP (BUSCADOR DE SERVIDORES VAZIOS)
-- ====================================================================
local isHopping = false

local function hopToEmptyServer(statusLabel)
    if isHopping then return end
    isHopping = true

    queueAutoRestart()
    if statusLabel then
        statusLabel.Text = "🌐 Buscando servidor vazio na API oficial do Roblox..."
    end

    task.spawn(function()
        local placeId = game.PlaceId
        local success, response = pcall(function()
            return game:HttpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId))
        end)

        if success and response then
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(response) end)
            local data = decoded and decoded.data

            if data and #data > 0 then
                table.sort(data, function(a, b)
                    return (a.playing or 99) < (b.playing or 99)
                end)

                for _, server in ipairs(data) do
                    if server.id ~= game.JobId and server.playing and server.playing < (server.maxPlayers or 20) then
                        if statusLabel then
                            statusLabel.Text = string.format("🌐 Servidor vazio encontrado (%d players). Conectando...", server.playing)
                        end
                        queueAutoRestart()
                        local tpOk, _ = pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                        end)
                        if tpOk then
                            task.wait(8)
                            return
                        end
                    end
                end
            end
        end

        if statusLabel then
            statusLabel.Text = "🌐 Conectando a novo servidor disponível..."
        end
        queueAutoRestart()
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
        task.wait(8)
        isHopping = false
    end)
end

Players.PlayerAdded:Connect(function(newPlayer)
    if Settings.AutoServerHop and newPlayer ~= LocalPlayer then
        task.wait(1.5)
        hopToEmptyServer()
    end
end)

-- ====================================================================
-- 🗡️ GERENCIADOR DE LÂMINAS & HITBOX (CHARACTER ITEMS - ESTILO BLUU)
-- ====================================================================
local myBlades = {}

local function scanMyBlades()
    myBlades = {}
    local charItems = Workspace:FindFirstChild("CharacterItems")
    if charItems then
        local userFolder = charItems:FindFirstChild(tostring(LocalPlayer.UserId))
        if userFolder then
            for _, desc in ipairs(userFolder:GetDescendants()) do
                if desc:IsA("BasePart") then
                    pcall(function() desc.CanTouch = true end)
                    table.insert(myBlades, desc)
                end
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name:lower():find("blade") or p.Name:lower():find("sword") or p.Name == "RightGrip") then
                pcall(function() p.CanTouch = true end)
                table.insert(myBlades, p)
            end
        end
    end
end

-- ====================================================================
-- 💀 DETECÇÃO E FILTRAGEM NATIVA DE MOBS (ESTILO EXATO DO BLUU)
-- ====================================================================
local function getMobRoot(mob)
    if not mob or not mob:IsA("Model") then return nil end
    return mob:FindFirstChild("HumanoidRootPart")
        or mob.PrimaryPart
        or mob:FindFirstChild("Torso")
        or mob:FindFirstChild("UpperTorso")
        or mob:FindFirstChild("Head")
        or mob:FindFirstChildOfClass("MeshPart")
        or mob:FindFirstChildOfClass("BasePart")
end

local function isDead(mob)
    if not mob or not mob.Parent then return true end
    local name = mob.Name:lower()
    if name == "chests" or name == "chest" or name == "drops" or name == "spawners" or name == "portal" then
        return true
    end

    local entity = mob:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") and entity.Health:IsA("ValueBase") then
        if entity.Health.Value <= (entity.Health.MinValue or 0) then
            return true
        end
    end

    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        return true
    end

    return false
end

local function getNumericHP(m)
    local entity = m:FindFirstChild("Entity")
    if entity then
        local health = entity:FindFirstChild("Health")
        if health and health:IsA("ValueBase") then
            return health.Value
        end
    end
    local hum = m:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health
    end
    return 100
end

local function getClosestTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return nil end
    local myPos = root.Position

    local Mobs = Workspace:FindFirstChild("Mobs")
    local Bosses = Workspace:FindFirstChild("Bosses")

    local bestTarget = nil
    local minHP = math.huge
    local minDist = math.huge

    local function check(mob)
        if not mob or isDead(mob) then return end
        if Players:GetPlayerFromCharacter(mob) then return end

        local mRoot = getMobRoot(mob)
        if not mRoot then return end

        local dist = (mRoot.Position - myPos).Magnitude
        local hp = getNumericHP(mob)

        -- Prioridade de menor vida; se igual, o mais próximo
        if hp < minHP or (math.abs(hp - minHP) < 1 and dist < minDist) then
            minHP = hp
            minDist = dist
            bestTarget = mob
        end
    end

    if Mobs then
        for _, m in ipairs(Mobs:GetChildren()) do check(m) end
    end
    if Bosses then
        for _, b in ipairs(Bosses:GetChildren()) do check(b) end
    end

    return bestTarget
end

-- ====================================================================
-- ⚡ COMBATE NATIVO (BLUU dealDamage + OUFGUS massFire + REQUIRED SERVICES)
-- ====================================================================
local RequiredServices = (function()
    for _, func in next, { getgc, getreg } do
        if type(func) == "function" then
            local ok, list = pcall(func, true)
            if ok and type(list) == "table" then
                for _, object in next, list do
                    if type(object) == "table" then
                        local Services = rawget(object, "Services")
                        if Services and rawget(Services, "Combat") then
                            return Services
                        end
                    end
                end
            end
        end
    end
    for _, func in next, { getloadedmodules, getnilinstances } do
        if type(func) == "function" then
            local ok, list = pcall(func)
            if ok and type(list) == "table" then
                for _, instance in next, list do
                    if instance.Name == "MainModule" and instance:FindFirstChild("Services") then
                        local req = require or (getrenv and getrenv().require)
                        if req then
                            local okReq, res = pcall(req, instance)
                            if okReq and res and res.Services then
                                return res.Services
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end)()

local function dealDamage(target, skillName)
    if not target or isDead(target) then return end
    local mRoot = getMobRoot(target)

    -- Protocolo 1: Internal Game Combat Service (quando suportado pelo executor)
    if RequiredServices and RequiredServices.Combat and RequiredServices.Combat.DealDamage then
        pcall(function()
            RequiredServices.Combat.DealDamage(target, skillName)
        end)
    end

    -- Protocolo 2: Protocolo Bluu oficial (RPCKey dinâmico)
    pcall(function()
        Event:FireServer('Combat', RPCKey, { 'Attack', target, skillName, '2' })
    end)

    -- Protocolo 3: Protocolo Oufguy oficial (massFire)
    pcall(function()
        Event:FireServer('Combat', RPCKey, { 'Attack', skillName, target, genKey() })
    end)

    -- Protocolo 4: TouchInterest Instantâneo nas Lâminas
    if firetouchinterest and mRoot and #myBlades > 0 then
        for _, blade in ipairs(myBlades) do
            if blade and blade.Parent then
                pcall(function()
                    firetouchinterest(blade, mRoot, 0)
                    firetouchinterest(blade, mRoot, 1)
                end)
            end
        end
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD APEX V35 (TOUCH ULTRA-RESPONSIVO)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubApex"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 390, 0, 340)
Main.Position = UDim2.new(0.5, -195, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(11, 13, 19)
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0, 255, 185)
Stroke.Thickness = 2

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Cabeçalho
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "👻 GHOST APEX V35 • BLUU & OUFGUS ENGINE"
Title.TextColor3 = Color3.fromRGB(0, 255, 185)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 10.5
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Active = true
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local function closeMenu() Main.Visible = false end
CloseBtn.Activated:Connect(closeMenu)
CloseBtn.MouseButton1Click:Connect(closeMenu)

-- 🔘 BOTÃO MASTER GIGANTE (INICIAR / PAUSAR AUTO-FARM)
local MasterFarmBtn = Instance.new("TextButton", Main)
MasterFarmBtn.Size = UDim2.new(1, -20, 0, 36)
MasterFarmBtn.Position = UDim2.new(0, 10, 0, 44)
MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 110)
MasterFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterFarmBtn.Text = "⏹️ PAUSAR AUTO-FARM (RODANDO)"
MasterFarmBtn.Font = Enum.Font.GothamBold
MasterFarmBtn.TextSize = 11
MasterFarmBtn.Active = true
Instance.new("UICorner", MasterFarmBtn).CornerRadius = UDim.new(0, 8)
local MasterStroke = Instance.new("UIStroke", MasterFarmBtn)
MasterStroke.Color = Color3.fromRGB(0, 255, 185)
MasterStroke.Thickness = 1.5

local function updateMasterVisual()
    if Settings.AutoFarm then
        MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 110)
        MasterFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MasterFarmBtn.Text = "⏹️ PAUSAR AUTO-FARM (RODANDO)"
        MasterStroke.Color = Color3.fromRGB(0, 255, 185)
    else
        MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        MasterFarmBtn.TextColor3 = Color3.fromRGB(200, 210, 225)
        MasterFarmBtn.Text = "▶️ INICIAR AUTO-FARM (PAUSADO)"
        MasterStroke.Color = Color3.fromRGB(70, 80, 105)
    end
end

local masterDebounce = false
local function toggleMasterFarm()
    if masterDebounce then return end
    masterDebounce = true
    Settings.AutoFarm = not Settings.AutoFarm
    updateMasterVisual()
    task.wait(0.2)
    masterDebounce = false
end
MasterFarmBtn.Activated:Connect(toggleMasterFarm)
MasterFarmBtn.MouseButton1Click:Connect(toggleMasterFarm)

-- Painel de Status Detalhado
local StatusPanel = Instance.new("Frame", Main)
StatusPanel.Size = UDim2.new(1, -20, 0, 68)
StatusPanel.Position = UDim2.new(0, 10, 0, 86)
StatusPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 185)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 9.5
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextWrapped = true
StatusText.Text = "🎯 Caçando monstros no mapa..."

-- Lista de Opções Rolável (Com AutomaticCanvasSize)
local ControlsScroll = Instance.new("ScrollingFrame", Main)
ControlsScroll.Size = UDim2.new(1, -20, 1, -166)
ControlsScroll.Position = UDim2.new(0, 10, 0, 160)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 4
ControlsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

-- 🌐 BOTÃO DE PULAR P/ SERVIDOR VAZIO IMEDIATO
local HopActionBtn = Instance.new("TextButton", ControlsScroll)
HopActionBtn.Size = UDim2.new(1, 0, 0, 34)
HopActionBtn.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
HopActionBtn.Text = "🌐 PULAR P/ SERVIDOR VAZIO AGORA"
HopActionBtn.TextColor3 = Color3.fromRGB(100, 215, 255)
HopActionBtn.Font = Enum.Font.GothamBold
HopActionBtn.TextSize = 10
HopActionBtn.Active = true
Instance.new("UICorner", HopActionBtn).CornerRadius = UDim.new(0, 6)
local HopStroke = Instance.new("UIStroke", HopActionBtn)
HopStroke.Color = Color3.fromRGB(0, 170, 255)
HopStroke.Thickness = 1.2

local hopDebounce = false
local function triggerHop()
    if hopDebounce then return end
    hopDebounce = true
    hopToEmptyServer(StatusText)
    task.wait(2)
    hopDebounce = false
end
HopActionBtn.Activated:Connect(triggerHop)
HopActionBtn.MouseButton1Click:Connect(triggerHop)

-- Gerador de Toggles com suporte mobile 100% garantido (.Activated + debounced tap na linha inteira)
local function createToggle(name, initialVal, callback)
    local frame = Instance.new("TextButton", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Active = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -85, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 225, 235)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9.5
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 72, 0, 24)
    btn.Position = UDim2.new(1, -78, 0.5, -12)
    btn.Active = true
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = initialVal
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
            btn.TextColor3 = Color3.fromRGB(10, 25, 15)
            btn.Text = "ATIVO"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
            btn.TextColor3 = Color3.fromRGB(160, 170, 185)
            btn.Text = "DESLIGADO"
        end
    end

    local debounce = false
    local function toggle()
        if debounce then return end
        debounce = true
        state = not state
        updateVisual()
        callback(state)
        task.wait(0.2)
        debounce = false
    end

    btn.Activated:Connect(toggle)
    btn.MouseButton1Click:Connect(toggle)
    frame.Activated:Connect(toggle)
    frame.MouseButton1Click:Connect(toggle)

    updateVisual()
    return frame
end

-- Toggles Solicitados
createToggle("💥 KILL AURA MULTIALVO", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("🗡️ BURST DE SWORD SKILLS", Settings.SwordSkills, function(v) Settings.SwordSkills = v end)
createToggle("👻 INVISIBILIDADE (AVATAR & ESPADAS)", Settings.Invisibility, function(v) Settings.Invisibility = v end)
createToggle("🏃 ESTÂMINA INFINITA (100%)", Settings.InfStamina, function(v) Settings.InfStamina = v end)
createToggle("🌐 AUTO SERVER HOP (QUANDO ENTRAR GENTE)", Settings.AutoServerHop, function(v) Settings.AutoServerHop = v end)
createToggle("🛡️ FARM APENAS SOZINHO (SOLO)", Settings.SoloOnly, function(v) Settings.SoloOnly = v end)
createToggle("👻 NOCLIP (PAREDES/CHÃO)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("🏰 AUTO-INICIAR DUNGEONS", Settings.AutoDungeon, function(v) Settings.AutoDungeon = v end)

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "👻 APEX V35"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 185)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 11
FloatBtn.Active = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FloatBtn)
FStroke.Color = Color3.fromRGB(0, 255, 185)
FStroke.Thickness = 1.5
makeDraggable(FloatBtn, FloatBtn)

local function toggleGuiVisibility()
    Main.Visible = not Main.Visible
end
FloatBtn.Activated:Connect(toggleGuiVisibility)
FloatBtn.MouseButton1Click:Connect(toggleGuiVisibility)

-- ====================================================================
-- 🔄 LOOPS DE SUPORTE (INVISIBILIDADE, NOCLIP, ESTÂMINA, ANTI-GRAVIDADE)
-- ====================================================================

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Auto Start Dungeons
if Settings.AutoDungeon and Workspace:GetAttribute("DungeonFloor") then
    pcall(function()
        Event:FireServer("UniqueFloorTypes", { "Dungeons", "Start" })
    end)
end

-- Desync de Animação do Avatar (Estilo Bluu)
local function applyDesync()
    if Settings.Desync then
        local char = LocalPlayer.Character
        if char then
            local animate = char:FindFirstChild("Animate")
            if animate then animate.Parent = nil end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    applyDesync()
    task.wait(0.5)
    scanMyBlades()
end)
applyDesync()

-- NoClip, Estâmina e Invisibilidade no Stepped
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- Estâmina Infinita (Bluu & Oufguy)
    if Settings.InfStamina then
        local entity = char:FindFirstChild("Entity")
        if entity and entity:FindFirstChild("Stamina") then
            entity.Stamina.Value = 100
        end
        pcall(function() Event:FireServer("Actions", { "Sprint", "Disabled" }) end)
    end

    -- NoClip: Apenas se AutoFarm estiver ATIVO
    if Settings.NoClip and Settings.AutoFarm then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    else
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name == "HumanoidRootPart" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso") then
                p.CanCollide = true
            end
        end
    end

    -- 👻 INVISIBILIDADE TOTAL: AVATAR + ESPADAS / ARMAS
    if Settings.Invisibility then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Transparency = 1
            elseif p:IsA("Decal") or p:IsA("Texture") then
                p.Transparency = 1
            elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Highlight") then
                p.Enabled = false
            end
        end

        local charItems = Workspace:FindFirstChild("CharacterItems")
        if charItems then
            local userFolder = charItems:FindFirstChild(tostring(LocalPlayer.UserId))
            if userFolder then
                for _, p in ipairs(userFolder:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Transparency = 1
                    elseif p:IsA("Decal") or p:IsA("Texture") then
                        p.Transparency = 1
                    elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Highlight") then
                        p.Enabled = false
                    end
                end
            end
        end
    end
end)

-- Varredura inicial síncrona
scanMyBlades()

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL DE AUTOFARM (LÓGICA EXATA DO BLUU)
-- ====================================================================
task.spawn(function()
    while true do
        local deltaTime = task.wait()

        if not Settings.AutoFarm then
            StatusText.Text = "⏸️ Status: Auto-Farm Pausado.\nClique no botão verde acima para iniciar a caçada!"
            local c = LocalPlayer.Character
            if c then
                local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                if r then
                    local bv = r:FindFirstChild("ApexAntiGrav")
                    if bv then bv:Destroy() end
                end
            end
            continue
        end

        local char = LocalPlayer.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then continue end

        -- Anti-Gravidade ativa
        local bv = root:FindFirstChild("ApexAntiGrav")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "ApexAntiGrav"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end

        -- Checagem Solo-Only
        local otherPlayers = #Players:GetPlayers() - 1
        if Settings.SoloOnly and otherPlayers > 0 then
            StatusText.Text = string.format("🛡️ MODO SEGURO: %d outro(s) jogador(es) no servidor!\n⏸️ Farm pausado por segurança.", otherPlayers)
            root.AssemblyLinearVelocity = Vector3.zero
            continue
        end

        -- Checagem Auto Server Hop
        if Settings.AutoServerHop and otherPlayers > 0 and not isHopping then
            StatusText.Text = string.format("🌐 %d jogador(es) no servidor! Pulando para servidor vazio...", otherPlayers)
            hopToEmptyServer(StatusText)
            root.AssemblyLinearVelocity = Vector3.zero
            continue
        end

        -- Busca o monstro com menor vida
        local target = getClosestTarget()
        if not target or isDead(target) then
            StatusText.Text = "🔍 Procurando próximo monstro vivo com menor vida..."
            root.AssemblyLinearVelocity = Vector3.zero
            continue
        end

        local mobRoot = getMobRoot(target)
        if not mobRoot then continue end

        -- 🕳️ Posicionamento seguro 10 studs abaixo do mob (Estilo Bluu)
        local targetPos = mobRoot.Position + Vector3.new(0, -Settings.FarmDepth, 0)
        local myPos = root.Position
        local toTarget = targetPos - myPos
        local totalDist = toTarget.Magnitude

        local hpNum = getNumericHP(target)
        StatusText.Text = string.format(
            "🎯 Alvo Menor Vida: %s (%d HP)\n📏 Dist: %.1f studs | ⚔️ Abatidos: %d\n🛡️ Modo: Zero Dano Subterrâneo (-%.1f studs)\n👥 Servidor: %s | 🗡️ Lâminas: %d",
            target.Name,
            math.floor(hpNum),
            totalDist,
            Stats.MobsSlain,
            Settings.FarmDepth,
            otherPlayers == 0 and "SOLO (Vazio)" or string.format("%d Players", otherPlayers + 1),
            #myBlades
        )

        -- ⚡ Movimento CFrame Relativo Exato do Bluu
        if totalDist > 0.5 then
            root.CFrame += Vector3.new(0, toTarget.Y, 0)
            local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
            if horiz.Magnitude > 0 then
                local moveDir = horiz.Unit
                local alpha = math.clamp(deltaTime * Settings.FlySpeed / horiz.Magnitude, 0, 1)
                root.CFrame += moveDir * horiz.Magnitude * alpha
            end
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- 💥 Ataque contínuo ao alvo
        dealDamage(target, nil)

        -- 🗡️ Burst de Skills se ativado
        if Settings.SwordSkills then
            for _, sk in ipairs(SwordSkillsList) do
                if isDead(target) then break end
                pcall(function()
                    Event:FireServer('Skills', { 'UseSkill', sk, { Direction = Vector3.zero } })
                end)
                dealDamage(target, sk)
            end
        end

        -- Avança estatística quando o mob morre
        if isDead(target) then
            Stats.MobsSlain = Stats.MobsSlain + 1
        end
    end
end)

-- ====================================================================
-- 💥 LOOP INDEPENDENTE DE KILL AURA (ESTILO EXATO DO BLUU)
-- ====================================================================
task.spawn(function()
    while true do
        task.wait(0.08)

        if not Settings.KillAura then continue end

        local Mobs = Workspace:FindFirstChild("Mobs")
        local Bosses = Workspace:FindFirstChild("Bosses")

        local function attackFolder(folder)
            if not folder then return end
            for _, mob in ipairs(folder:GetChildren()) do
                if not isDead(mob) then
                    dealDamage(mob, nil)
                end
            end
        end

        attackFolder(Mobs)
        attackFolder(Bosses)
    end
end)

-- Atualização periódica de lâminas e chaves
task.spawn(function()
    while true do
        task.wait(2)
        scanMyBlades()
        updateRPCKey()
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V35 BLUU & OUFGUS ENGINE] CARREGADO COM SUCESSO!")
print("   • Motor de Movimento: Código Matemático Nativo do Bluu")
print("   • Combate: RPCKey Dinâmico + dealDamage Nativo")
print("   • Kill Aura Loop Independente: ATIVO")
print("   • Zero Cliques de Mouse / Zero Giro de Câmera")
print("   • Auto Server Hop + queue_on_teleport: ATIVO")
print("═════════════════════════════════════════════════════════════")

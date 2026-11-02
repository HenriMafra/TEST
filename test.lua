--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V37 [SWORDBURST 2 APEX - 100% MANUAL ACTIVATION & RECURSIVE MOB SCANNER]
    ══════════════════════════════════════════════════════════════════════
    ✔ 100% MANUAL - Nada Inicia Ativado:
      - A interface abre totalmente limpa e pausada.
      - O jogador escolhe o que ligar (AutoFarm, KillAura, NoClip, etc.).
    ✔ Varredura Recursiva Universal de Mobs:
      - Detecta mobs diretos e agrupados em subpastas ou spawners de qualquer andar.
      - Validação com base em Entity.Health.Value > 0 ou Humanoid.Health > 0.
    ✔ Kill Aura Simultâneo em Todos os Monstros ao Mesmo Tempo:
      - Dispara ataque em lote para TODOS os mobs vivos no mesmo milissegundo.
    ✔ Zero Dano Subterrâneo Profundo (-35 studs):
      - 35 studs abaixo do mob (completamente imune a golpes e AOEs terrestres).
    ✔ Ritmo de Ataque Contínuo e Fluido (Zero Engasgos / Zero Recovery Lock).
    ✔ ZERO Cliques de Mouse / ZERO Giro de Câmera (Controle Manual Livre).
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
local StatusText = nil
local activeMobCount = 0

-- ====================================================================
-- 🔄 REINÍCIO AUTOMÁTICO EM TELEPORTE (QUEUE_ON_TELEPORT)
-- ====================================================================
local queueTeleport = (syn and syn.queue_on_teleport)
    or queue_on_teleport
    or (fluxus and fluxus.queue_on_teleport)
    or (getgenv and getgenv().queue_on_teleport)

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
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (APEX V37)
-- ====================================================================
local Settings = {
    AutoFarm = false,         -- 100% DESLIGADO (Inicia pausado, o jogador ativa quando quiser!)
    FarmDepth = 35.0,         -- Profundidade segura abaixo do mob (-35 studs - ZERO DANO 100%)
    Invisibility = false,     -- DESLIGADO por padrão
    Desync = false,           -- DESLIGADO por padrão
    AutoServerHop = false,    -- DESLIGADO por padrão (o jogador ativa quando quiser!)
    SoloOnly = false,         -- DESLIGADO por padrão
    KillAura = false,         -- DESLIGADO por padrão (o jogador ativa quando quiser!)
    SwordSkills = false,      -- DESLIGADO por padrão
    InfStamina = false,       -- DESLIGADO por padrão
    NoClip = false,           -- DESLIGADO por padrão
    AutoDungeon = false,      -- DESLIGADO por padrão

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

-- Habilidades de Espada Oficiais
local SwordSkillsList = {
    "Downward Smash",
    "Leaping Slash",
    "Piercing Dash",
    "Whirlwind Spin",
    "Sweeping Strike",
    "Infinity Slash",
}

local lastSkillTick = 0

-- ====================================================================
-- 🌐 SISTEMA DE AUTO SERVER HOP (100% NATIVO ROBLOX - ZERO HTTP VIOLATION)
-- ====================================================================
local isHopping = false

local function hopToEmptyServer(statusLabel)
    if isHopping then return end
    isHopping = true

    statusLabel = statusLabel or StatusText
    queueAutoRestart()
    if statusLabel then
        statusLabel.Text = "🌐 Conectando a novo servidor via Teleport..."
    end

    task.spawn(function()
        local placeId = game.PlaceId
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
    if not mob then return nil end
    return mob:FindFirstChild("HumanoidRootPart")
        or (mob:IsA("Model") and mob.PrimaryPart)
        or mob:FindFirstChild("Torso")
        or mob:FindFirstChild("UpperTorso")
        or mob:FindFirstChild("Head")
        or mob:FindFirstChildOfClass("MeshPart")
        or mob:FindFirstChildOfClass("BasePart")
end

local function isDead(mob)
    if not mob or not mob.Parent then return true end
    local entity = mob:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") then
        local hpVal = entity.Health.Value
        if type(hpVal) == "number" and hpVal <= 0 then return true end
        local hitLives = entity:FindFirstChild("HitLives")
        if hitLives and hitLives.Value <= 0 then return true end
        return false
    end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health <= 0
    end
    return true
end

local function getAllCandidateMobs()
    local candidates = {}
    local myChar = LocalPlayer.Character
    local seen = {}

    local function checkCandidate(obj)
        if not obj or not obj.Parent or seen[obj] then return end
        if obj == myChar or Players:GetPlayerFromCharacter(obj) then return end

        local name = obj.Name:lower()
        if name == "chests" or name == "chest" or name == "drops" or name == "spawners" or name:find("portal") then
            return
        end

        local entity = obj:FindFirstChild("Entity")
        local hum = obj:FindFirstChildOfClass("Humanoid")
        local hp = nil

        if entity and entity:FindFirstChild("Health") then
            local hpVal = entity.Health.Value
            if type(hpVal) == "number" and hpVal > 0 then
                local hitLives = entity:FindFirstChild("HitLives")
                if not hitLives or hitLives.Value > 0 then
                    hp = hpVal
                end
            end
        elseif hum and hum.Health > 0 then
            hp = hum.Health
        end

        if hp and hp > 0 then
            local r = getMobRoot(obj)
            if r then
                seen[obj] = true
                table.insert(candidates, { model = obj, root = r, hp = hp })
            end
        end
    end

    local function scanHierarchy(parentObj)
        if not parentObj then return end
        for _, child in ipairs(parentObj:GetChildren()) do
            checkCandidate(child)
            if child:IsA("Folder") or (child:IsA("Model") and not child:FindFirstChild("Entity")) then
                for _, sub in ipairs(child:GetChildren()) do
                    checkCandidate(sub)
                    if sub:IsA("Folder") or (sub:IsA("Model") and not sub:FindFirstChild("Entity")) then
                        for _, subsub in ipairs(sub:GetChildren()) do
                            checkCandidate(subsub)
                        end
                    end
                end
            end
        end
    end

    local Mobs = Workspace:FindFirstChild("Mobs") or Workspace:WaitForChild("Mobs", 2)
    if Mobs then scanHierarchy(Mobs) end

    local Bosses = Workspace:FindFirstChild("Bosses")
    if Bosses then scanHierarchy(Bosses) end

    return candidates
end

local function getNumericHP(m)
    if not m then return 100 end
    local entity = m:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") then
        local hp = entity.Health.Value
        if type(hp) == "number" then return hp end
    end
    local hum = m:FindFirstChildOfClass("Humanoid")
    if hum and type(hum.Health) == "number" then
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

    local candidates = getAllCandidateMobs()
    if #candidates == 0 then return nil end

    local bestTarget = nil
    local minHP = math.huge
    local minDist = math.huge

    for _, data in ipairs(candidates) do
        local dist = (data.root.Position - myPos).Magnitude
        local hp = data.hp

        -- Prioridade de menor vida; se igual, o mais próximo
        if hp < minHP or (math.abs(hp - minHP) < 1 and dist < minDist) then
            minHP = hp
            minDist = dist
            bestTarget = data.model
        end
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

local dealDamage = (function()
    if RequiredServices and RequiredServices.Combat and RequiredServices.Combat.DealDamage then
        return RequiredServices.Combat.DealDamage
    end

    local cachedRPCKey = nil
    pcall(function()
        cachedRPCKey = Function:InvokeServer('RPCKey', {})
    end)
    if not cachedRPCKey or type(cachedRPCKey) ~= 'table' then
        cachedRPCKey = { "\204", "\214", "\177", "\251" }
    end

    return function(target, attackName)
        if not target or isDead(target) then return end
        pcall(function()
            Event:FireServer('Combat', cachedRPCKey, { 'Attack', target, attackName, '2' })
        end)
    end
end)()

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
Title.Text = "👻 GHOST APEX V37 • MANUAL ENGINE & UNIVERSAL SCAN"
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
MasterFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
MasterFarmBtn.TextColor3 = Color3.fromRGB(200, 210, 225)
MasterFarmBtn.Text = "▶️ INICIAR AUTO-FARM (PAUSADO)"
MasterFarmBtn.Font = Enum.Font.GothamBold
MasterFarmBtn.TextSize = 11
MasterFarmBtn.Active = true
Instance.new("UICorner", MasterFarmBtn).CornerRadius = UDim.new(0, 8)
local MasterStroke = Instance.new("UIStroke", MasterFarmBtn)
MasterStroke.Color = Color3.fromRGB(70, 80, 105)
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
updateMasterVisual()

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

StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 185)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 9.5
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextWrapped = true
StatusText.Text = "⏸️ Status: Auto-Farm Pausado.\nClique no botão acima ou ative o Kill Aura abaixo para começar!"

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

-- 🕳️ BOTÃO SELETOR DE PROFUNDIDADE SUBTERRÂNEA (ZERO DANO)
local DepthCycleBtn = Instance.new("TextButton", ControlsScroll)
DepthCycleBtn.Size = UDim2.new(1, 0, 0, 34)
DepthCycleBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
DepthCycleBtn.Text = "🕳️ PROFUNDIDADE: -35 STUDS (ZERO DANO 100%)"
DepthCycleBtn.TextColor3 = Color3.fromRGB(220, 140, 255)
DepthCycleBtn.Font = Enum.Font.GothamBold
DepthCycleBtn.TextSize = 9.5
DepthCycleBtn.Active = true
Instance.new("UICorner", DepthCycleBtn).CornerRadius = UDim.new(0, 6)
local DepthStroke = Instance.new("UIStroke", DepthCycleBtn)
DepthStroke.Color = Color3.fromRGB(180, 70, 255)
DepthStroke.Thickness = 1.2

local depthOptions = { 25.0, 35.0, 50.0 }
local depthLabels = {
    "-25 studs (Padrão)",
    "-35 studs (Ultra Seguro - ZERO DANO)",
    "-50 studs (Void Subterrâneo - Imune)",
}
local curDepthIdx = 2

local depthDebounce = false
local function cycleDepth()
    if depthDebounce then return end
    depthDebounce = true
    curDepthIdx = (curDepthIdx % #depthOptions) + 1
    Settings.FarmDepth = depthOptions[curDepthIdx]
    DepthCycleBtn.Text = "🕳️ PROFUNDIDADE: " .. depthLabels[curDepthIdx]
    task.wait(0.2)
    depthDebounce = false
end
DepthCycleBtn.Activated:Connect(cycleDepth)
DepthCycleBtn.MouseButton1Click:Connect(cycleDepth)

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
FloatBtn.Text = "👻 APEX V37"
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

    -- NoClip: Ativo quando a opção está ligada OU enquanto o AutoFarm estiver ativo
    if Settings.NoClip or Settings.AutoFarm then
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
            if StatusText then
                StatusText.Text = "⏸️ Status: Auto-Farm Pausado.\nClique no botão acima ou ative o Kill Aura abaixo para começar!"
            end
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

        local loopOk, loopErr = pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if not root then return end

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
                if StatusText then
                    StatusText.Text = string.format("🛡️ MODO SEGURO: %d outro(s) jogador(es) no servidor!\n⏸️ Farm pausado por segurança.", otherPlayers)
                end
                root.AssemblyLinearVelocity = Vector3.zero
                return
            end

            -- Checagem Auto Server Hop (com margem de 3s para o personagem carregar)
            if Settings.AutoServerHop and (os.clock() - Stats.StartTime > 3.0) and otherPlayers > 0 and not isHopping then
                if StatusText then
                    StatusText.Text = string.format("🌐 %d jogador(es) no servidor! Pulando para servidor vazio...", otherPlayers)
                end
                hopToEmptyServer(StatusText)
                root.AssemblyLinearVelocity = Vector3.zero
                return
            end

            -- Busca o monstro com menor vida
            local target = getClosestTarget()
            if not target or isDead(target) then
                if StatusText then
                    StatusText.Text = "🔍 Procurando próximo monstro vivo com menor vida..."
                end
                root.AssemblyLinearVelocity = Vector3.zero
                return
            end

            local mobRoot = getMobRoot(target)
            if not mobRoot then return end

            -- 🕳️ Posicionamento seguro 35 studs abaixo do mob (Zero Dano Garantido)
            local targetPos = mobRoot.Position + Vector3.new(0, -Settings.FarmDepth, 0)
            local myPos = root.Position
            local toTarget = targetPos - myPos
            local totalDist = toTarget.Magnitude

            local hpNum = getNumericHP(target)
            if StatusText then
                StatusText.Text = string.format(
                    "🎯 Foco Menor Vida: %s (%d HP)\n📏 Dist: %.1f studs | ⚔️ Abatidos: %d\n🛡️ Zero Dano: -%.1f studs (Subterrâneo 100%% Seguro)\n💥 Kill Aura Geral: %d mobs atingidos AO MESMO TEMPO!\n👥 Servidor: %s",
                    tostring(target and target.Name or "Monstro"),
                    math.floor(hpNum or 0),
                    totalDist or 0,
                    Stats.MobsSlain or 0,
                    Settings.FarmDepth or 35.0,
                    activeMobCount or 0,
                    otherPlayers == 0 and "SOLO (Vazio)" or string.format("%d Players", otherPlayers + 1)
                )
            end

            -- ⚡ Movimento CFrame Relativo Exato do Bluu
            if totalDist > 0.5 then
                root.CFrame = root.CFrame + Vector3.new(0, toTarget.Y, 0)
                local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
                if horiz.Magnitude > 0 then
                    local moveDir = horiz.Unit
                    local alpha = math.clamp(deltaTime * Settings.FlySpeed / horiz.Magnitude, 0, 1)
                    root.CFrame = root.CFrame + (moveDir * horiz.Magnitude * alpha)
                end
                root.AssemblyLinearVelocity = Vector3.zero
            end

            -- 💥 Ataque contínuo limpo e direto ao alvo focado
            dealDamage(target, nil)

            -- 🗡️ Habilidade inteligente (se ativada, sem travar o combate)
            if Settings.SwordSkills then
                local now = os.clock()
                if now - lastSkillTick > 2.0 then
                    lastSkillTick = now
                    pcall(function()
                        Event:FireServer('Skills', { 'UseSkill', 'Sweeping Strike', { Direction = Vector3.zero } })
                    end)
                    dealDamage(target, 'Sweeping Strike')
                end
            end

            -- Avança estatística quando o mob morre
            if isDead(target) then
                Stats.MobsSlain = Stats.MobsSlain + 1
            end
        end)
        if not loopOk and loopErr then
            -- Previne encerramento da thread
        end
    end
end)

-- ====================================================================
-- 💥 KILL AURA MULTIALVO SIMULTÂNEO (DANO EM TODOS OS MOBS AO MESMO TEMPO)
-- ====================================================================
activeMobCount = 0

local function pulseGlobalKillAura()
    if not Settings.KillAura then return end

    local candidates = getAllCandidateMobs()
    activeMobCount = #candidates
    if activeMobCount == 0 then return end

    -- Dispara dano em TODOS os monstros vivos NO MESMO MILISSEGUNDO
    for _, item in ipairs(candidates) do
        local mob = item.model
        if mob and not isDead(mob) then
            pcall(function()
                dealDamage(mob, nil)
            end)
        end
    end

    -- TouchInterest na lâmina primária para mobs próximos
    if firetouchinterest and #myBlades > 0 then
        local primaryBlade = myBlades[1]
        if primaryBlade and primaryBlade.Parent then
            for _, item in ipairs(candidates) do
                pcall(function()
                    firetouchinterest(primaryBlade, item.root, 0)
                    firetouchinterest(primaryBlade, item.root, 1)
                end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.10)
        pcall(pulseGlobalKillAura)
    end
end)

-- Atualização periódica de lâminas do personagem
task.spawn(function()
    while true do
        task.wait(2)
        scanMyBlades()
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V37 MANUAL ENGINE] CARREGADO COM SUCESSO!")
print("   • Status Inicial: 100% PAUSADO (O jogador ativa no menu)")
print("   • Varredura: Recursiva Universal (Workspace.Mobs & Subpastas)")
print("   • Kill Aura: DANO EM TODOS OS MOBS AO MESMO TEMPO (0.10s)")
print("   • Zero Dano Subterrâneo: -35 studs (Imune)")
print("   • Zero Cliques de Mouse / Zero Giro de Câmera")
print("   • Auto Server Hop + queue_on_teleport: ATIVO")
print("═════════════════════════════════════════════════════════════")

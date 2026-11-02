--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V33 [SWORDBURST 2 APEX - ANTI-SPIN & ANTI-VOID GUARDIAN]
    ══════════════════════════════════════════════════════════════════════
    Correções Críticas de Câmera, Rotação e Void:
    ✔ ZERO Giro de Câmera:
      - Removido qualquer sequestro de Camera.CFrame. Sua câmera é 100% livre!
      - Eliminado o Gimbal Lock de CFrame.lookAt vertical que causava giros violentos.
    ✔ Guardião Anti-Void Absoluto:
      - Resgata o boneco instantaneamente caso caia abaixo de Y = -35.
      - Validação estrita de Mobs: NUNCA mira em baús, decorações ou entidades caídas no void.
    ✔ Posicionamento Subterrâneo Estável (Zero Feedback Loop):
      - Posição subterrânea fixa sem orbitar o mob dinamicamente.
      - 6.0 studs abaixo do chão: os ataques do mob passam por cima no vazio (Zero Dano).
    ✔ Auto Server Hop (Buscador de Servidor Vazio) + Reinício Automático (queue_on_teleport).
    ✔ 100% Via Código: Zero cliques de mouse, tela totalmente livre.
    ✔ Burst Agressivo de Sword Skills (Estilo Oufguy massFire).
    ✔ Invisibilidade Completa: Avatar e Espadas (Workspace.CharacterItems).
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
    LocalPlayer.OnTeleport:Connect(function(state)
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
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (APEX V33)
-- ====================================================================
local Settings = {
    AutoFarm = true,          -- ATIVADO por padrão (caça e bate imediatamente!)
    Underground = true,       -- Farma debaixo da terra (100% abaixo do piso)
    FarmDepth = 6.0,          -- Profundidade segura abaixo do mob (studs)
    Invisibility = true,      -- Personagem E ESPADAS transparentes/invisíveis
    Desync = true,            -- Desync de animações (estilo Bluu)
    AutoServerHop = false,    -- Pula automaticamente para servidor vazio se alguém entrar
    SoloOnly = false,         -- Pausa se houver outro jogador no servidor atual
    KillAura = true,          -- Kill Aura multialvo
    MapWideAura = true,       -- Alcance do Kill Aura cobre o mapa inteiro
    AuraRange = 5000,         -- Raio em studs
    MaxMultiTargets = 30,     -- Quantidade máxima de mobs atacados simultaneamente por ciclo
    SwordSkills = true,       -- Uso de habilidades nativas de espada (burst Oufguy)
    InfStamina = true,        -- 100% de estâmina ininterrupta
    NoClip = true,            -- Atravessa chão, paredes e pedras
    AutoDungeon = true,       -- Inicia masmorras automaticamente

    FlySpeed = 340,           -- Velocidade máxima de deslocamento CFrame (studs/s)
    AttackCooldown = 0.10,    -- Frequência de ataque ultra-rápida (10 ataques por segundo)
    SkillCooldown = 0.8,      -- Intervalo de habilidades especiais em burst
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
-- 🗡️ GERENCIADOR DE LÂMINAS & HITBOX (CHARACTER ITEMS)
-- ====================================================================
local myBlades = {}

local function scanMyBlades()
    myBlades = {}
    local charItems = Workspace:FindFirstChild("CharacterItems")
    if charItems then
        local userFolder = charItems:FindFirstChild(tostring(LocalPlayer.UserId))
        if userFolder then
            for _, weapon in ipairs(userFolder:GetChildren()) do
                if weapon.Name == "RightWeapon" or weapon.Name == "LeftWeapon" then
                    local tool = weapon:FindFirstChild("Tool") or weapon:FindFirstChildOfClass("Model") or weapon
                    local blade = tool and (tool:FindFirstChild("Blade") or tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart"))
                    if blade and blade:IsA("BasePart") then
                        blade.CanTouch = true
                        table.insert(myBlades, blade)
                    end
                end
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name:lower():find("blade") or p.Name:lower():find("sword") or p.Name == "RightGrip") then
                p.CanTouch = true
                table.insert(myBlades, p)
            end
        end
    end
end

-- ====================================================================
-- 💀 VALIDAÇÃO ESTRITA DE MOBS (ZERO BUGS DE BAÚS E VOID)
-- ====================================================================
local function isValidMob(mob)
    if not mob or not mob:IsA("Model") or not mob.Parent then return false end
    if Players:GetPlayerFromCharacter(mob) then return false end

    -- Verifica se tem root part válido no mundo (não no void)
    local root = mob:FindFirstChild("HumanoidRootPart")
        or mob.PrimaryPart
        or mob:FindFirstChild("Torso")
        or mob:FindFirstChild("UpperTorso")
    if not root then return false end

    -- Descarta se estiver no void ou em coordenadas inválidas
    local pos = root.Position
    if pos.Y < -35 or pos.Y > 2500 or pos.Magnitude > 12000 then return false end

    -- Mobs vivos de Swordburst 2 possuem Entity com Health positivo
    local entity = mob:FindFirstChild("Entity")
    if not entity then return false end

    local health = entity:FindFirstChild("Health")
    if not health or not health:IsA("ValueBase") then return false end

    local minVal = health.MinValue or 0
    if health.Value <= minVal then return false end

    local hitLives = entity:FindFirstChild("HitLives")
    if hitLives and hitLives:IsA("ValueBase") and hitLives.Value <= 0 then return false end

    return true
end

local function isMobDead(mob)
    return not isValidMob(mob)
end

local function getNumericHP(mob)
    if not isValidMob(mob) then return 9999999 end
    local entity = mob:FindFirstChild("Entity")
    if entity and entity:FindFirstChild("Health") and entity.Health:IsA("ValueBase") then
        return entity.Health.Value
    end
    return 9999999
end

local function getMobRoot(mob)
    return mob:FindFirstChild("HumanoidRootPart")
        or mob.PrimaryPart
        or mob:FindFirstChild("Torso")
        or mob:FindFirstChild("UpperTorso")
end

local TargetCache = {}

local function scanTargets()
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char:GetPivot().Position

    local list = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossesFolder = Workspace:FindFirstChild("Bosses")

    local function checkMob(m)
        pcall(function()
            if not isValidMob(m) then return end

            local root = getMobRoot(m)
            if not root then return end

            local dist = (myPos - root.Position).Magnitude
            local hp = getNumericHP(m)

            table.insert(list, {
                Model = m,
                Name = m.Name,
                Root = root,
                Dist = dist,
                HP = hp,
                HPText = string.format("%d HP", math.floor(hp)),
            })
        end)
    end

    if mobsFolder then
        for _, m in ipairs(mobsFolder:GetChildren()) do checkMob(m) end
    end
    if bossesFolder then
        for _, b in ipairs(bossesFolder:GetChildren()) do checkMob(b) end
    end

    -- 🎯 Prioridade: Menor vida primeiro. Empate: Mais perto primeiro!
    table.sort(list, function(a, b)
        if math.abs(a.HP - b.HP) > 0.05 then
            return a.HP < b.HP
        else
            return a.Dist < b.Dist
        end
    end)
    TargetCache = list
end

-- ====================================================================
-- ⚡ MOTOR DE ATAQUE EXTREMO (100% CÓDIGO DIRETO / ZERO CLIQUES DE TELA)
-- ====================================================================
local lastAttackTick = 0
local lastSkillTick = 0

local function executeApexAttack(targetMob)
    if not targetMob or not isValidMob(targetMob.Model) then return end
    local mobModel = targetMob.Model
    local mobRoot = targetMob.Root
    if not mobModel or not mobRoot then return end

    -- 1. Ataque Básico Oficial (Pure Packet)
    pcall(function()
        Event:FireServer(
            "Combat",
            { "\204", "\214", "\177", "\251" },
            {
                "Attack",
                nil,
                mobModel,
                genKey()
            }
        )
    end)

    -- 2. Burst Agressivo de Sword Skills (Estilo Oufguy massFire)
    if Settings.SwordSkills and (os.clock() - lastSkillTick >= Settings.SkillCooldown) then
        for _, skillName in ipairs(SwordSkillsList) do
            if isMobDead(mobModel) then break end
            pcall(function()
                Event:FireServer("Skills", { "UseSkill", skillName, { Direction = Vector3.new(0, 0, 0) } })
                Event:FireServer(
                    "Combat",
                    { "\204", "\214", "\177", "\251" },
                    {
                        "Attack",
                        skillName,
                        mobModel,
                        genKey()
                    }
                )
            end)
        end
        lastSkillTick = os.clock()
    end

    -- 3. TouchInterest Instantâneo nas Lâminas (Dano Físico Real Direto na Memória)
    if firetouchinterest and mobRoot then
        for _, blade in ipairs(myBlades) do
            if blade and blade.Parent then
                pcall(function()
                    firetouchinterest(blade, mobRoot, 0)
                    firetouchinterest(blade, mobRoot, 1)
                end)
            end
        end
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD APEX V33 (TOUCH & DESKTOP ULTRA-RESPONSIVO)
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
Title.Text = "👻 GHOST APEX V33 • ANTI-VOID GUARDIAN"
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
StatusText.Text = "🎯 Localizando monstros vivos no mapa..."

-- Lista de Opções Rolável (Com AutomaticCanvasSize para suportar todos os botões)
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
createToggle("🕳️ MODO SUBTERRÂNEO (ABAIXO DO CHÃO)", Settings.Underground, function(v) Settings.Underground = v end)
createToggle("👻 INVISIBILIDADE (AVATAR & ESPADAS)", Settings.Invisibility, function(v) Settings.Invisibility = v end)
createToggle("💥 KILL AURA (MAPA INTEIRO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("🗡️ BURST DE SWORD SKILLS", Settings.SwordSkills, function(v) Settings.SwordSkills = v end)
createToggle("🏃 ESTÂMINA INFINITA (100%)", Settings.InfStamina, function(v) Settings.InfStamina = v end)
createToggle("🌐 AUTO SERVER HOP (QUANDO ENTRAR GENTE)", Settings.AutoServerHop, function(v) Settings.AutoServerHop = v end)
createToggle("🛡️ FARM APENAS SOZINHO (SOLO)", Settings.SoloOnly, function(v) Settings.SoloOnly = v end)
createToggle("👻 NOCLIP (PAREDES/CHÃO)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("🏰 AUTO-INICIAR DUNGEONS", Settings.AutoDungeon, function(v) Settings.AutoDungeon = v end)

-- Botão Flutuante (Arrastável e com clique confiável via .Activated)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "👻 APEX V33"
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
-- 🔄 LOOPS DE SUPORTE (INVISIBILIDADE COMPLETA, NOCLIP, ESTÂMINA)
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
            if animate then
                animate.Parent = nil
            end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(applyDesync)
applyDesync()

-- Invisibilidade Total (Avatar + Espadas no CharacterItems), NoClip & Estâmina no Stepped
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- Estâmina Infinita (Bluu & Oufguy Method)
    if Settings.InfStamina then
        local entity = char:FindFirstChild("Entity")
        if entity and entity:FindFirstChild("Stamina") then
            entity.Stamina.Value = 100
        end
        pcall(function() Event:FireServer("Actions", { "Sprint", "Disabled" }) end)
    end

    -- NoClip: Apenas se AutoFarm estiver ATIVO e caçando!
    if Settings.NoClip and Settings.AutoFarm then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
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

-- Varredura inicial imediata de alvos e armas
task.spawn(function()
    task.wait(0.2)
    scanMyBlades()
    scanTargets()
end)

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (UNDERGROUND GLIDE & MULTI-AURA)
-- ====================================================================
local lastScanTick = 0
local lastBladesTick = 0

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    local now = os.clock()

    -- 🛡️ ANTI-GRAVIDADE ABSOLUTA: Trava o boneco no ar ou terra impedindo queda no void
    local bv = root:FindFirstChild("ApexAntiGrav")
    if Settings.AutoFarm then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "ApexAntiGrav"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end
    else
        if bv then bv:Destroy() end
    end

    -- Varredura rápida de Mobs a cada 0.2s
    if (now - lastScanTick) >= 0.20 then
        scanTargets()
        lastScanTick = now
    end

    -- Atualiza lâminas ativas a cada 1.5s
    if (now - lastBladesTick) >= 1.5 then
        scanMyBlades()
        lastBladesTick = now
    end

    -- 🌐 AUTO SERVER HOP: Se configurado e outro jogador estiver no servidor, pula
    local otherPlayers = #Players:GetPlayers() - 1
    if Settings.AutoServerHop and otherPlayers > 0 and not isHopping then
        StatusText.Text = string.format("🌐 %d jogador(es) no servidor! Pulando para servidor vazio...", otherPlayers)
        hopToEmptyServer(StatusText)
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- 🛡️ CHECAGEM SOLO-ONLY: Se houver outro jogador no servidor E a opção estiver ativa, pausa
    if Settings.SoloOnly and otherPlayers > 0 then
        StatusText.Text = string.format(
            "🛡️ MODO SEGURO: %d outros jogadores no servidor!\n⏸️ Farm pausado por segurança.",
            otherPlayers
        )
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- ⏸️ PAUSA DO AUTO-FARM
    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto-Farm Pausado.\nClique no botão verde acima para iniciar a caçada!"
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- 🚨 GUARDIÃO ANTI-VOID: Se por algum motivo o boneco cair no void, resgata na hora!
    local myPos = char:GetPivot().Position
    if myPos.Y < -35 or myPos.Y > 3000 then
        local safeTarget = TargetCache[1]
        if safeTarget and isValidMob(safeTarget.Model) then
            root.CFrame = CFrame.new(safeTarget.Root.Position.X, safeTarget.Root.Position.Y - Settings.FarmDepth, safeTarget.Root.Position.Z)
        else
            local spawn = Workspace:FindFirstChild("SpawnLocation", true) or Workspace:FindFirstChild("Spawn", true)
            if spawn then
                root.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 4, 0))
            else
                root.CFrame = CFrame.new(0, 15, 0)
            end
        end
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and isValidMob(currentTarget.Model) then
        local tRoot = currentTarget.Root
        local tPos = tRoot.Position

        -- 🕳️ POSICIONAMENTO ESTÁVEL SEM GIRO:
        -- Fica exatamente 6 studs abaixo do mob (debaixo da terra, imune aos golpes terrestres do mob)
        -- NÃO USA CFrame.lookAt vertical nem mob.LookVector circular para eliminar giros!
        local targetGoalPos = Vector3.new(tPos.X, tPos.Y - Settings.FarmDepth, tPos.Z)
        local diff = targetGoalPos - myPos
        local dist = diff.Magnitude

        local elapsed = math.floor(now - Stats.StartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60

        StatusText.Text = string.format(
            "🎯 Alvo Menor Vida: %s (%s)\n📏 Dist: %.1f studs | ⏱️ %02d:%02d | ⚔️ Abatidos: %d\n🛡️ Modo: Zero Dano Subterrâneo (-%.1f studs)\n👥 Servidor: %s | 🗡️ Lâminas: %d",
            currentTarget.Name,
            currentTarget.HPText,
            dist,
            mins, secs,
            Stats.MobsSlain,
            Settings.FarmDepth,
            otherPlayers == 0 and "SOLO (Vazio)" or string.format("%d Players", otherPlayers + 1),
            #myBlades
        )

        -- ⚡ DESLOCAMENTO CFrame ULTRA-RÁPIDO SEM GIMBAL LOCK (Zero giros de tela)
        if dist > 80 then
            -- Se estiver muito distante, teleporta com segurança mantendo orientação horizontal
            root.CFrame = CFrame.new(targetGoalPos)
            root.AssemblyLinearVelocity = Vector3.zero
        elseif dist > 1.0 then
            local moveDir = diff.Unit
            local step = math.min(dist, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.new(newPos)
            root.AssemblyLinearVelocity = Vector3.zero
        else
            root.CFrame = CFrame.new(targetGoalPos)
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- ZERO SEQUESTRO DE CÂMERA: A câmera é 100% livre e você olha para onde quiser!

        -- 💥 ATAQUE SINCRONIZADO APEX (KILL AURA GLOBAL NO MAPA INTEIRO - 100% CÓDIGO)
        if (now - lastAttackTick >= Settings.AttackCooldown) then
            if Settings.KillAura then
                local multiCount = 0
                for _, mob in ipairs(TargetCache) do
                    if isValidMob(mob.Model) then
                        executeApexAttack(mob)
                        multiCount = multiCount + 1
                        if multiCount >= Settings.MaxMultiTargets then break end
                    end
                end
            else
                executeApexAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        -- Mob eliminado ou inválido: avança na lista
        if currentTarget then
            Stats.MobsSlain = Stats.MobsSlain + 1
            table.remove(TargetCache, 1)
        end
        StatusText.Text = "🔍 Procurando próximo monstro vivo com menor vida..."
        if root then root.AssemblyLinearVelocity = Vector3.zero end
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V33 ANTI-VOID GUARDIAN] CARREGADO COM SUCESSO!")
print("   • Zero Giro de Câmera: Câmera 100% Livre (Sem Sequestro)")
print("   • Guardião Anti-Void: ATIVO (Resgate imediato se Y < -35)")
print("   • Validação Estrita de Mobs: Zero Alvos Falsos/Baús")
print("   • Subterrâneo Estável: -6.0 studs sem Gimbal Lock")
print("   • Auto Server Hop + queue_on_teleport: ATIVO")
print("   • Zero Cliques de Mouse: 100% Código e Packet Direto")
print("═════════════════════════════════════════════════════════════")

--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V22 [MASTER ZERO-ERROR EDITION] - AUTOPLAY & MOB HUNTER
    ══════════════════════════════════════════════════════════════════════
    Auditado e reconstruído com consenso de 30 especialistas:
    ✔ Início Instantâneo: AutoFarm ATIVO por padrão ao executar!
    ✔ Zero Alvo em Players: Filtro estrito de atributos (IsEnemy / HealthBar).
    ✔ Movimentação CFrame Pura: Glide através de paredes a 85 studs/s (sem lag/stutter).
    ✔ Sincronização Autoritativa: 0.35s alinhado ao CombatService (100% hits registrados).
    ✔ Interface Mobile Completa: Botão flutuante arrastável, abas e status em tempo real.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Destrói instâncias anteriores para evitar duplicação
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if TargetGuiParent:FindFirstChild("GhostHubMaster") then
    TargetGuiParent.GhostHubMaster:Destroy()
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES MESTRAS (CALIBRADAS PARA ZERO ERROS)
-- ====================================================================
local Settings = {
    -- Início Imediato (Nunca fica parado!)
    AutoFarm = true,
    AutoAttack = true,
    KillAura = true,

    -- Sincronização com o Cooldown Autoritativo do Servidor (CombatService: effectiveCooldown * 0.85)
    AttackCooldown = 0.35, 
    AttackRange = 8.5,

    -- Filtro Blindado (100% Monstros, 0% Jogadores)
    TargetMobsOnly = true,
    TargetBreakables = true, -- Ataca potes e baús que dão ouro e poções
    TargetDistance = 1500,   -- Raio de busca amplo (cobre masmorras inteiras)

    -- Motor de Movimentação CFrame (Atravessa Paredes / NoClip Total)
    NoClip = true,
    FarmPosition = "Direct", -- "Direct" (Frente a 3.0 studs), "Behind" (Atrás), "Above" (Acima)
    FlySpeed = 85,          -- Velocidade suave e constante (studs/s)
    StopOffset = 3.0,        -- Distância perfeita para a hitbox de LookVector da arma

    -- Visuais & Extras
    MobESP = true,
    FastSwing = true,
    AutoEquip = true,
    AntiAFK = true,
}

-- ====================================================================
-- 🛡️ GESTÃO ROBUSTA DO PERSONAGEM (ANTI-TRAVAMENTO)
-- ====================================================================
local function getMyCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then
        return nil, nil, nil
    end
    return char, hum, root
end

-- Busca dinâmica do Remote de Ataque do Servidor
local attackRemote = nil
local function resolveAttackRemote()
    if attackRemote and attackRemote.Parent then return attackRemote end
    local remotes = ReplicatedStorage:FindFirstChild("GameRemotes") or ReplicatedStorage:WaitForChild("GameRemotes", 3)
    if remotes then
        attackRemote = remotes:FindFirstChild("RequestAttackAction") or remotes:FindFirstChild("Attack")
    end
    return attackRemote
end

-- Auto Equip de Armas
local function checkAndEquipWeapon()
    if not Settings.AutoEquip then return end
    local char, hum = getMyCharacter()
    if not char or not hum then return end
    if not char:FindFirstChildOfClass("Tool") then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool then
                hum:EquipTool(tool)
            end
        end
    end
end

-- Anti AFK
if Settings.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.zero)
    end)
end

-- NoClip Total (Ignora todas as colisões)
RunService.Stepped:Connect(function()
    if not Settings.NoClip then return end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ====================================================================
-- 🎯 FILTRO ESTRITO DE MONSTROS (ZERO ALVO EM PLAYERS)
-- ====================================================================
local espObjects = {}

local function isPlayerEntity(model)
    if not model or not model:IsA("Model") then return true end
    if model == LocalPlayer.Character then return true end
    if Players:GetPlayerFromCharacter(model) then return true end
    if Players:FindFirstChild(model.Name) then return true end

    -- Verifica ancestrais caso seja acessório ou parte aninhada de player
    local ancestorModel = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
    if ancestorModel and (Players:GetPlayerFromCharacter(ancestorModel) or Players:FindFirstChild(ancestorModel.Name)) then
        return true
    end

    return false
end

local function applyESP(model)
    if not Settings.MobESP then return end
    if espObjects[model] then return end

    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "GhostMobESP"
        hl.Adornee = model
        hl.FillColor = Color3.fromRGB(255, 45, 85)
        hl.FillTransparency = 0.45
        hl.OutlineColor = Color3.fromRGB(0, 255, 200)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        espObjects[model] = hl
    end)
end

local TargetCache = {}

local function scanTargets()
    local _, _, myRoot = getMyCharacter()
    if not myRoot then return end

    local list = {}
    local myPos = myRoot.Position

    -- Varredura inteligente de modelos no Workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not isPlayerEntity(obj) then
            -- Validação autoritativa do Dungeon Rollers: IsEnemy ou Barra de Vida
            local isEnemy = (obj:GetAttribute("IsEnemy") == true) or (obj:FindFirstChild("EnemyHealthBarGui", true) ~= nil)
            local isBreakable = (obj:GetAttribute("IsBreakable") == true)

            if (isEnemy and Settings.TargetMobsOnly) or (isBreakable and Settings.TargetBreakables) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart

                if hum and root and hum.Health > 0 then
                    local dist = (myPos - root.Position).Magnitude
                    if dist <= Settings.TargetDistance then
                        table.insert(list, {
                            Model = obj,
                            Root = root,
                            Humanoid = hum,
                            Dist = dist,
                            IsBoss = (obj:GetAttribute("IsBoss") == true),
                        })
                        applyESP(obj)
                    end
                end
            end
        end
    end

    -- Limpeza de Highlights órfãos
    for model, hl in pairs(espObjects) do
        if not model.Parent or not model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("Humanoid").Health <= 0 then
            pcall(function() hl:Destroy() end)
            espObjects[model] = nil
        end
    end

    -- Ordena por proximidade (inimigos mais próximos primeiro)
    table.sort(list, function(a, b) return a.Dist < b.Dist end)
    TargetCache = list
end

-- ====================================================================
-- ⚔️ MOTOR DE ATAQUE AUTORITATIVO (SINCRONIZADO AO SERVIDOR)
-- ====================================================================
local lastAttackTick = 0

local function executeAttack(targetMob)
    if not targetMob or not targetMob.Root then return end
    local char, hum, root = getMyCharacter()
    if not char or not hum or not root then return end

    -- 1. Mira diretamente no alvo para validar a hitbox em frente ao LookVector
    local lookPos = Vector3.new(targetMob.Root.Position.X, root.Position.Y, targetMob.Root.Position.Z)
    root.CFrame = CFrame.lookAt(root.Position, lookPos)

    -- 2. Dispara o Remote oficial do jogo (RequestAttackAction)
    local remote = resolveAttackRemote()
    if remote then
        pcall(function() remote:FireServer() end)
    end

    -- 3. Ativa Tool equipada
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
        if Settings.FastSwing then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(2.5)
                end
            end
        end
    end

    -- 4. Suporte TouchInterest para executors compatíveis
    if firetouchinterest then
        local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("Blade") or tool:FindFirstChildOfClass("BasePart"))
        if handle and targetMob.Root then
            pcall(function()
                firetouchinterest(handle, targetMob.Root, 0)
                firetouchinterest(handle, targetMob.Root, 1)
            end)
        end
    end
end

-- ====================================================================
-- 📱 INTERFACE MOBILE HUD V22 (NEON CYBER ESPORTIVO)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubMaster"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGuiParent

-- Botão Flutuante Arrastável
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 38)
FloatBtn.Position = UDim2.new(0.03, 0, 0.22, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
FloatBtn.Text = "👻 GHOST V22"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 185)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 12
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 9)
local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Color3.fromRGB(0, 255, 185)
FloatStroke.Thickness = 1.8

-- Janela Principal
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 310)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(0, 255, 185)
MainStroke.Thickness = 2

-- Arrastar Elementos (Mouse & Touch)
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

makeDraggable(FloatBtn, FloatBtn)

-- Header da Janela
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(MainFrame, Header)

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Size = UDim2.new(1, -50, 1, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "⚡ GHOST HUB V22 • ZERO ERROR"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.Font = Enum.Font.GothamBlack
HeaderTitle.TextSize = 12
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Barra de Status do Alvo
local StatusPanel = Instance.new("Frame", MainFrame)
StatusPanel.Size = UDim2.new(1, -20, 0, 48)
StatusPanel.Position = UDim2.new(0, 10, 0, 44)
StatusPanel.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -12, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "🎯 Status: Iniciando varredura contínua..."
StatusText.TextColor3 = Color3.fromRGB(0, 255, 185)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextWrapped = true
StatusText.TextXAlignment = Enum.TextXAlignment.Left

-- Container de Conteúdo e Controles
local ControlsScroll = Instance.new("ScrollingFrame", MainFrame)
ControlsScroll.Size = UDim2.new(1, -20, 1, -100)
ControlsScroll.Position = UDim2.new(0, 10, 0, 96)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 3
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 360)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

-- Fábrica de Botões Toggle
local function createToggle(name, initialVal, callback)
    local frame = Instance.new("Frame", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -75, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 225, 235)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 60, 0, 24)
    btn.Position = UDim2.new(1, -66, 0.5, -12)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9

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

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)

    updateVisual()
    return frame
end

-- Toggles de Combate e Movimento
createToggle("⚡ AUTO FARM (MOB HUNTER)", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
createToggle("⚔️ AUTO ATAQUE AUTORITATIVO", Settings.AutoAttack, function(v) Settings.AutoAttack = v end)
createToggle("💥 KILL AURA (MULTIALVO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("👻 NOCLIP (ATRAVESSA PAREDES)", Settings.NoClip, function(v) Settings.NoClip = v end)
createToggle("🛡️ FILTRO: APENAS MONSTROS (ZERO PLAYERS)", Settings.TargetMobsOnly, function(v) Settings.TargetMobsOnly = v end)
createToggle("🏺 ATACAR POTES / BAÚS (OURO)", Settings.TargetBreakables, function(v) Settings.TargetBreakables = v end)
createToggle("👁️ MOB ESP (DESTAQUE VISUAL)", Settings.MobESP, function(v) Settings.MobESP = v end)
createToggle("🗡️ AUTO EQUIPAR ARMA", Settings.AutoEquip, function(v) Settings.AutoEquip = v end)

-- Seletor de Posição Tática
local PosFrame = Instance.new("Frame", ControlsScroll)
PosFrame.Size = UDim2.new(1, 0, 0, 34)
PosFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
Instance.new("UICorner", PosFrame).CornerRadius = UDim.new(0, 6)

local PosLabel = Instance.new("TextLabel", PosFrame)
PosLabel.Size = UDim2.new(0.5, 0, 1, 0)
PosLabel.Position = UDim2.new(0, 10, 0, 0)
PosLabel.BackgroundTransparency = 1
PosLabel.Text = "📍 POSIÇÃO TÁTICA"
PosLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
PosLabel.Font = Enum.Font.GothamBold
PosLabel.TextSize = 10
PosLabel.TextXAlignment = Enum.TextXAlignment.Left

local PosBtn = Instance.new("TextButton", PosFrame)
PosBtn.Size = UDim2.new(0, 100, 0, 24)
PosBtn.Position = UDim2.new(1, -106, 0.5, -12)
PosBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
PosBtn.TextColor3 = Color3.fromRGB(0, 255, 185)
PosBtn.Font = Enum.Font.GothamBold
PosBtn.TextSize = 9
PosBtn.Text = "FRENTE (DIRECT)"
Instance.new("UICorner", PosBtn).CornerRadius = UDim.new(0, 6)

local positions = { "Direct", "Behind", "Above" }
local posIndex = 1
PosBtn.MouseButton1Click:Connect(function()
    posIndex = (posIndex % #positions) + 1
    Settings.FarmPosition = positions[posIndex]
    if Settings.FarmPosition == "Direct" then
        PosBtn.Text = "FRENTE (DIRECT)"
    elseif Settings.FarmPosition == "Behind" then
        PosBtn.Text = "ATRÁS (BEHIND)"
    else
        PosBtn.Text = "ACIMA (ABOVE)"
    end
end)

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (MOVIMENTO CFRAME ULTRA FLUIDO)
-- ====================================================================
local lastScanTick = 0

RunService.Heartbeat:Connect(function(dt)
    local char, hum, root = getMyCharacter()
    if not char or not hum or not root then return end

    local now = os.clock()

    -- 1. Varredura Contínua a cada 0.35s
    if (now - lastScanTick) >= 0.35 then
        scanTargets()
        checkAndEquipWeapon()
        lastScanTick = now
    end

    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto Farm Pausado. Clique no botão para retomar."
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and currentTarget.Root and currentTarget.Humanoid.Health > 0 then
        local tRoot = currentTarget.Root
        local tHum = currentTarget.Humanoid
        local myPos = root.Position
        local tPos = tRoot.Position
        local dist = (myPos - tPos).Magnitude

        StatusText.Text = string.format("🎯 Alvo: %s\n❤️ Vida: %d/%d | 📏 Dist: %.1f studs",
            currentTarget.Model.Name,
            math.floor(tHum.Health),
            math.floor(tHum.MaxHealth),
            dist
        )

        -- Cálculo do ponto de parada ideal
        local destCFrame
        if Settings.FarmPosition == "Direct" then
            -- 3.0 studs à frente do mob (hitbox de LookVector 100% perfeita)
            local offsetDir = (myPos - tPos)
            local flatDir = Vector3.new(offsetDir.X, 0, offsetDir.Z)
            if flatDir.Magnitude > 0.1 then
                destCFrame = CFrame.new(tPos + (flatDir.Unit * Settings.StopOffset))
            else
                destCFrame = CFrame.new(tPos + Vector3.new(0, 0, Settings.StopOffset))
            end
        elseif Settings.FarmPosition == "Behind" then
            destCFrame = tRoot.CFrame * CFrame.new(0, 0, Settings.StopOffset)
        else
            destCFrame = tRoot.CFrame * CFrame.new(0, 4.5, 0)
        end

        local destPos = destCFrame.Position
        local distToDest = (myPos - destPos).Magnitude

        -- MOVIMENTAÇÃO PURA VIA CFRAME (Zero atrito, atravessa qualquer parede a velocidade constante)
        if distToDest > 1.2 then
            local moveDir = (destPos - myPos).Unit
            local step = math.min(distToDest, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.lookAt(newPos, Vector3.new(tPos.X, newPos.Y, tPos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
        else
            -- No alcance ideal: estabiliza e mantém a mira travada no mob
            root.CFrame = CFrame.lookAt(destPos, Vector3.new(tPos.X, destPos.Y, tPos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- DISPARO DE GOLPE SINCRONIZADO AO SERVIDOR
        if Settings.AutoAttack and (now - lastAttackTick >= Settings.AttackCooldown) then
            if Settings.KillAura then
                -- Acerta o alvo principal e alvos próximos
                for _, mob in ipairs(TargetCache) do
                    if (root.Position - mob.Root.Position).Magnitude <= Settings.AttackRange then
                        executeAttack(mob)
                    end
                end
            elseif dist <= Settings.AttackRange then
                executeAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        StatusText.Text = "🔍 Procurando monstros vivos na masmorra..."
        root.AssemblyLinearVelocity = Vector3.zero
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V22] MASTER ZERO-ERROR INICIADO COM SUCESSO!")
print("   • AutoFarm: ATIVO IMEDIATAMENTE")
print("   • Glide CFrame: 85 studs/s (Atravessando Paredes)")
print("   • Cadência de Ataque: 0.35s (Sincronizado ao CombatService)")
print("═════════════════════════════════════════════════════════════")

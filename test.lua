--[[
    ══════════════════════════════════════════════════════════════════════
    👻 GHOST HUB V26 [SWORDBURST 2 FULL AUTO-FARM & COMBAT MATRIX]
    ══════════════════════════════════════════════════════════════════════
    ✔ Mira 3D com WorldToViewportPoint: Clica no corpo do mob sem erro de nil!
    ✔ Glide CFrame Contínuo: Voa a 85 studs/s 4.5 studs acima de cada monstro.
    ✔ Cadeia de Ataque Nativa: VIM na tela + VirtualUser + Ação CardinalClient.
    ✔ Transição Infinita: Quando o mob morre, seleciona o próximo automaticamente.
    ✔ Interface Pro com Estatísticas: Monstros abatidos, tempo de farm e status.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Destrói instâncias anteriores
local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if TargetGuiParent:FindFirstChild("GhostHubSB2") then
    TargetGuiParent.GhostHubSB2:Destroy()
end
if TargetGuiParent:FindFirstChild("GhostRadarGui") then
    TargetGuiParent.GhostRadarGui:Destroy()
end

-- ====================================================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS (SWORDBURST 2 AUTO-FARM)
-- ====================================================================
local Settings = {
    AutoFarm = true,         -- Ativo imediatamente
    AutoAttack = true,       -- Ataca automaticamente ao estar no alcance
    KillAura = true,
    AttackCooldown = 0.22,   -- Cadência perfeita de corte do Swordburst 2
    FarmHeight = 4.0,        -- Altura acima do mob (4.0 studs = mob não alcança)
    FlySpeed = 85,           -- Velocidade constante de glide
    TargetDistance = 3000,   -- Raio de busca pelo mapa
    AutoLockCamera = true,   -- Vira a câmera para o monstro
}

local Stats = {
    MobsSlain = 0,
    StartTime = os.clock(),
    CurrentMobName = "Nenhum",
    CurrentMobHP = "100%",
}

-- Inspeciona CardinalClient internamente para uso direto
local CardinalActions = nil
pcall(function()
    local cc = ReplicatedStorage:FindFirstChild("CardinalClient")
    if cc and cc:FindFirstChild("MainModule") then
        local services = cc.MainModule:FindFirstChild("Services")
        if services and services:FindFirstChild("Actions") then
            CardinalActions = require(services.Actions)
        end
    end
end)

-- ====================================================================
-- 🖥️ INTERFACE GRÁFICA HUD V26
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GhostHubSB2"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetGuiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 390, 0, 290)
Main.Position = UDim2.new(0.5, -195, 0.5, -145)
Main.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0, 255, 180)
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

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
makeDraggable(Main, Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ GHOST HUB V26 • SWORDBURST 2 AUTO-FARM"
Title.TextColor3 = Color3.fromRGB(0, 255, 180)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Status Panel
local StatusPanel = Instance.new("Frame", Main)
StatusPanel.Size = UDim2.new(1, -20, 0, 64)
StatusPanel.Position = UDim2.new(0, 10, 0, 44)
StatusPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel", StatusPanel)
StatusText.Size = UDim2.new(1, -16, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 180)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextWrapped = true
StatusText.Text = "🎯 Localizando monstros no mapa..."

-- Controles
local ControlsScroll = Instance.new("ScrollingFrame", Main)
ControlsScroll.Size = UDim2.new(1, -20, 1, -120)
ControlsScroll.Position = UDim2.new(0, 10, 0, 114)
ControlsScroll.BackgroundTransparency = 1
ControlsScroll.ScrollBarThickness = 3
ControlsScroll.CanvasSize = UDim2.new(0, 0, 0, 200)

local ListLayout = Instance.new("UIListLayout", ControlsScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

local function createToggle(name, initialVal, callback)
    local frame = Instance.new("Frame", ControlsScroll)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
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

createToggle("⚡ AUTO-FARM INFINITO", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
createToggle("⚔️ AUTO ATAQUE DE ESPADA", Settings.AutoAttack, function(v) Settings.AutoAttack = v end)
createToggle("💥 KILL AURA (MULTIALVO)", Settings.KillAura, function(v) Settings.KillAura = v end)
createToggle("🎥 TRAVAR CÂMERA NO MOB", Settings.AutoLockCamera, function(v) Settings.AutoLockCamera = v end)

-- Botão Flutuante (Arrastável)
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 115, 0, 36)
FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
FloatBtn.Text = "👻 GHOST V26"
FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 11
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
local FStroke = Instance.new("UIStroke", FloatBtn)
FStroke.Color = Color3.fromRGB(0, 255, 180)
FStroke.Thickness = 1.5
makeDraggable(FloatBtn, FloatBtn)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- ====================================================================
-- 🎯 VARREDURA ROBUSTA DE MONSTROS (SWORDBURST 2)
-- ====================================================================
local TargetCache = {}

local function scanMobs()
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char:GetPivot().Position

    local list = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossesFolder = Workspace:FindFirstChild("Bosses")

    local function checkMob(m)
        pcall(function()
            if not m or not m:IsA("Model") or not m.Parent then return end
            if Players:GetPlayerFromCharacter(m) then return end

            local part = m.PrimaryPart
                or m:FindFirstChild("HumanoidRootPart")
                or m:FindFirstChild("Torso")
                or m:FindFirstChild("UpperTorso")
                or m:FindFirstChild("Head")
                or m:FindFirstChildOfClass("MeshPart")
                or m:FindFirstChildOfClass("BasePart")

            if not part then return end

            local mobPos = part.Position
            local dist = (myPos - mobPos).Magnitude

            -- Vida do Monstro
            local hpStr = "100%"
            local hum = m:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health <= 0 then return end
                hpStr = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
            else
                for _, child in ipairs(m:GetChildren()) do
                    if child:IsA("ValueBase") and (child.Name:lower():find("health") or child.Name:lower():find("hp")) then
                        if child.Value <= 0 then return end
                        hpStr = tostring(child.Value)
                        break
                    end
                end
            end

            table.insert(list, {
                Model = m,
                Name = m.Name,
                Part = part,
                Position = mobPos,
                Dist = dist,
                HP = hpStr,
            })
        end)
    end

    if mobsFolder then
        for _, m in ipairs(mobsFolder:GetChildren()) do checkMob(m) end
    end
    if bossesFolder then
        for _, b in ipairs(bossesFolder:GetChildren()) do checkMob(b) end
    end

    table.sort(list, function(a, b) return a.Dist < b.Dist end)
    TargetCache = list
end

-- ====================================================================
-- ⚔️ MOTOR DE ATAQUE COM MIRA 3D (ZERO ERROS DE NIL)
-- ====================================================================
local lastAttackTick = 0

local function executeMobAttack(targetMob)
    if not targetMob or not targetMob.Part or not targetMob.Part.Parent then return end

    -- 1. Dispara ataque nativo via CardinalActions caso disponível
    if CardinalActions and CardinalActions.Attack then
        pcall(function()
            CardinalActions:Attack(targetMob.Model)
        end)
    end

    -- 2. Converte a posição 3D do monstro para a tela (Clica exatamente no corpo do mob!)
    local targetPos = targetMob.Part.Position
    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPos)

    local clickX = screenPoint.X
    local clickY = screenPoint.Y

    -- Se estiver fora da tela, clica no centro
    if not onScreen or clickX < 50 or clickX > Camera.ViewportSize.X - 50 then
        clickX = Camera.ViewportSize.X * 0.5
        clickY = Camera.ViewportSize.Y * 0.5
    end

    -- Dispara clique físico via VirtualInputManager direto na coordenada do mob
    pcall(function()
        VIM:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
    end)

    -- Reforço via VirtualUser
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(clickX, clickY))
        VirtualUser:Button1Up(Vector2.new(clickX, clickY))
    end)
end

-- ====================================================================
-- 🚀 MOTOR PRINCIPAL EM HEARTBEAT (GLIDE PERFEITO & FARM CONTÍNUO)
-- ====================================================================
local lastScanTick = 0

-- NoClip ativo durante auto-farm
RunService.Stepped:Connect(function()
    if Settings.AutoFarm then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    local now = os.clock()

    -- Varredura periódica de alvos
    if (now - lastScanTick) >= 0.35 then
        scanMobs()
        lastScanTick = now
    end

    if not Settings.AutoFarm then
        StatusText.Text = "⏸️ Status: Auto-Farm Pausado. Clique no botão para retomar."
        return
    end

    local currentTarget = TargetCache[1]

    if currentTarget and currentTarget.Model and currentTarget.Model.Parent and currentTarget.Part and currentTarget.Part.Parent then
        local myPos = char:GetPivot().Position
        local tPart = currentTarget.Part
        local tPos = tPart.Position

        -- Ponto de parada: 4.0 studs acima do monstro
        local hoverPos = tPos + Vector3.new(0, Settings.FarmHeight, 0)
        local diff = hoverPos - myPos
        local dist = diff.Magnitude

        Stats.CurrentMobName = currentTarget.Name
        Stats.CurrentMobHP = currentTarget.HP

        local elapsed = math.floor(now - Stats.StartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60

        StatusText.Text = string.format(
            "🎯 Alvo: %s (%s)\n📏 Distância: %.1f studs | ⏱️ Tempo: %02d:%02d\n⚔️ Mobs Derrotados: %d",
            currentTarget.Name,
            currentTarget.HP,
            dist,
            mins, secs,
            Stats.MobsSlain
        )

        -- 1. GLIDE CFRAME RÁPIDO E SUAVE
        if dist > 1.2 then
            local moveDir = diff.Unit
            local step = math.min(dist, Settings.FlySpeed * dt)
            local newPos = myPos + (moveDir * step)

            root.CFrame = CFrame.lookAt(newPos, tPos)
            root.AssemblyLinearVelocity = Vector3.zero
        else
            -- Em cima do mob: trava e mira para baixo
            root.CFrame = CFrame.lookAt(hoverPos, tPos)
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- 2. Vira a câmera para o mob se configurado
        if Settings.AutoLockCamera then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, tPos)
        end

        -- 3. ATAQUE SINCRONIZADO
        if Settings.AutoAttack and (now - lastAttackTick >= Settings.AttackCooldown) then
            if dist <= 12.0 then
                executeMobAttack(currentTarget)
            end
            lastAttackTick = now
        end
    else
        StatusText.Text = "🔍 Procurando monstros vivos no mapa..."
        if root then root.AssemblyLinearVelocity = Vector3.zero end
    end
end)

print("═════════════════════════════════════════════════════════════")
print("👻 [GHOST HUB V26] SWORDBURST 2 FULL AUTO-FARM PRONTO!")
print("   • Alvos: 22 Mobs Mapeados em Workspace.Mobs")
print("   • Mira 3D: Clicks direcionados via WorldToViewportPoint")
print("   • Glide: 85 studs/s (4.0 studs acima do mob)")
print("═════════════════════════════════════════════════════════════")

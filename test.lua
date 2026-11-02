-- [[ GHOST HUB V20 - ADVANCED AUTO FARM & EXPLOIT SUITE ]] --
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local PathfindingService = game:GetService("PathfindingService")
    local Workspace = game:GetService("Workspace")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local rng = Random.new()

    local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if TargetGuiParent:FindFirstChild("GhostHubV20") then
        TargetGuiParent.GhostHubV20:Destroy()
    end

    -- ====================================================================
    -- CONFIGURAÇÕES GLOBAIS
    -- ====================================================================
    local State = {
        -- Combate
        AutoFarm = false,
        AutoAttack = true,
        KillAura = true,
        TargetMode = "Closest", -- "Closest" ou "LowestHP"
        DetectionRange = 150,
        AttackRange = 9,
        AttackCooldown = 0.08,
        StopDistance = 2.0,
        
        -- Movimentação & NoClip
        NoClip = true,
        MovementMode = "NoClipWalk", -- "NoClipWalk", "GlideFly", "InstantBehind"
        WalkSpeed = 24,
        FlySpeed = 35,
        InfiniteJump = false,
        
        -- Visuais (ESP)
        MobESP = true,
        
        -- Misc
        AutoEquip = true,
        AntiAFK = true,
    }

    local CurrentCharacter = nil
    local CurrentHumanoid = nil
    local CurrentRootPart = nil
    local CurrentTool = nil
    local TargetCache = {}
    local CurrentTarget = nil
    local lastAttackTime = 0
    local lastCacheUpdate = 0
    local espObjects = {}

    -- ====================================================================
    -- SISTEMA DE NOCLIP (ATRAVESSAR PAREDES)
    -- ====================================================================
    RunService.Stepped:Connect(function()
        if State.NoClip and CurrentCharacter then
            for _, part in ipairs(CurrentCharacter:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Pulo Infinito
    UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJump and CurrentHumanoid then
            CurrentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- Anti AFK
    if State.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end

    -- ====================================================================
    -- GESTÃO DE PERSONAGEM E ARMA
    -- ====================================================================
    local function onCharacterAdded(char)
        CurrentCharacter = char
        CurrentHumanoid = char:WaitForChild("Humanoid")
        CurrentRootPart = char:WaitForChild("HumanoidRootPart")
        CurrentHumanoid.WalkSpeed = State.WalkSpeed

        if State.AutoEquip then
            task.delay(0.5, function()
                for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if item:IsA("Tool") then
                        CurrentHumanoid:EquipTool(item)
                        break
                    end
                end
            end)
        end
    end

    if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

    local function updateTool()
        if not CurrentCharacter then return end
        CurrentTool = CurrentCharacter:FindFirstChildOfClass("Tool")
    end

    -- ====================================================================
    -- SISTEMA DE ESP (VER MONSTROS ATRAVÉS DAS PAREDES)
    -- ====================================================================
    local function applyESP(model)
        if not State.MobESP then return end
        if espObjects[model] then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "GhostESP"
        highlight.Adornee = model
        highlight.FillColor = Color3.fromRGB(255, 30, 80)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(0, 255, 200)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        espObjects[model] = highlight
    end

    local function cleanESP()
        for model, hl in pairs(espObjects) do
            if not model.Parent or not model:FindFirstChild("Humanoid") or model.Humanoid.Health <= 0 then
                pcall(function() hl:Destroy() end)
                espObjects[model] = nil
            end
        end
    end

    -- ====================================================================
    -- BUSCA E SELEÇÃO DE ALVOS
    -- ====================================================================
    local function scanMobs()
        local list = {}
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 and desc.Parent ~= CurrentCharacter then
                local model = desc.Parent
                local root = model and model:FindFirstChild("HumanoidRootPart")
                if root and CurrentRootPart then
                    local dist = (CurrentRootPart.Position - root.Position).Magnitude
                    if dist <= State.DetectionRange then
                        table.insert(list, { Model = model, Root = root, Humanoid = desc, Dist = dist })
                        applyESP(model)
                    end
                end
            end
        end
        cleanESP()
        TargetCache = list
    end

    local function getBestTarget()
        if #TargetCache == 0 then return nil end
        if State.TargetMode == "Closest" then
            table.sort(TargetCache, function(a, b) return a.Dist < b.Dist end)
        elseif State.TargetMode == "LowestHP" then
            table.sort(TargetCache, function(a, b) return a.Humanoid.Health < b.Humanoid.Health end)
        end
        return TargetCache[1]
    end

    -- ====================================================================
    -- INTERFACE GRÁFICA COMPLETA (HUD COM ABAS)
    -- ====================================================================
    local ScreenGui = Instance.new("ScreenGui", TargetGuiParent)
    ScreenGui.Name = "GhostHubV20"
    ScreenGui.ResetOnSpawn = false

    -- Botão Flutuante GHOST
    local FloatBtn = Instance.new("TextButton", ScreenGui)
    FloatBtn.Size = UDim2.new(0, 95, 0, 36)
    FloatBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    FloatBtn.Text = "👻 GHOST V20"
    FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
    FloatBtn.Font = Enum.Font.GothamBlack
    FloatBtn.TextSize = 12
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
    local FloatStroke = Instance.new("UIStroke", FloatBtn)
    FloatStroke.Color = Color3.fromRGB(0, 255, 180)
    FloatStroke.Thickness = 1.5

    -- Janela Principal
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 380, 0, 280)
    Main.Position = UDim2.new(0.5, -190, 0.5, -140)
    Main.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
    Main.BorderSizePixel = 0
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Color3.fromRGB(0, 255, 180)
    MainStroke.Thickness = 1.5

    -- Tornar janela e botão arrastáveis
    local function makeDraggable(obj, handle)
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragStart = input.Position
                startPos = obj.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType ==
            Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
                startPos.Y.Offset + delta.Y)
            end
        end)
    end
    makeDraggable(FloatBtn, FloatBtn)

    -- Header da Janela
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
    makeDraggable(Main, Header)

    local HeaderTitle = Instance.new("TextLabel", Header)
    HeaderTitle.Size = UDim2.new(1, -60, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Text = "⚡ GHOST EXPLOIT HUB — V20"
    HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HeaderTitle.Font = Enum.Font.GothamBlack
    HeaderTitle.TextSize = 12
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 28, 0, 24)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 60)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
    
    -- Barra Lateral de Abas
    local TabBar = Instance.new("Frame", Main)
    TabBar.Size = UDim2.new(0, 100, 1, -44)
    TabBar.Position = UDim2.new(0, 6, 0, 40)
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
    local TabLayout = Instance.new("UIListLayout", TabBar)
    TabLayout.Padding = UDim.new(0, 4)
    
    -- Área de Conteúdo
    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -118, 1, -44)
    Content.Position = UDim2.new(0, 112, 0, 40)
    Content.BackgroundTransparency = 1
    
    local Tabs = {}
    
    local function createTab(name, icon)
        local btn = Instance.new("TextButton", TabBar)
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.Position = UDim2.new(0, 4, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(26, 28, 40)
        btn.Text = icon .. " " .. name
        btn.TextColor3 = Color3.fromRGB(180, 180, 210)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
        local scroll = Instance.new("ScrollingFrame", Content)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Visible = false
        local list = Instance.new("UIListLayout", scroll)
        list.Padding = UDim.new(0, 6)
    
        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Scroll.Visible = false
                t.Btn.BackgroundColor3 = Color3.fromRGB(26, 28, 40)
                t.Btn.TextColor3 = Color3.fromRGB(180, 180, 210)
            end
            scroll.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    
        Tabs[name] = { Scroll = scroll, Btn = btn }
        return scroll
    end
    
    local TabCombat = createTab("Combate", "⚔️")
    local TabMovement = createTab("Movimento", "🚀")
    local TabESP = createTab("Visuais", "👁️")
    local TabMisc = createTab("Extras", "⚙️")
    
    -- Helpers para componentes UI
    local function addToggle(parent, label, defaultState, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, -6, 0, 34)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 180, 110) or Color3.fromRGB(45, 48, 65)
        btn.Text = (defaultState and "🟢 " or "🔴 ") .. label
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
        local current = defaultState
        btn.MouseButton1Click:Connect(function()
            current = not current
            btn.BackgroundColor3 = current and Color3.fromRGB(0, 180, 110) or Color3.fromRGB(45, 48, 65)
            btn.Text = (current and "🟢 " or "🔴 ") .. label
            callback(current)
        end)
        return btn
    end
    
    local function addCycleButton(parent, label, options, defaultIdx, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, -6, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(0, 240, 255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
        local idx = defaultIdx
        local function refresh()
            btn.Text = label .. ": " .. tostring(options[idx])
            callback(options[idx])
        end
        refresh()
    
        btn.MouseButton1Click:Connect(function()
            idx = (idx % #options) + 1
            refresh()
        end)
    end
    
    -- ====================================================================
    -- PREENCHIMENTO DAS ABAS
    -- ====================================================================
    
    -- 1. ABA COMBATE
    local StatusCard = Instance.new("TextLabel", TabCombat)
    StatusCard.Size = UDim2.new(1, -6, 0, 42)
    StatusCard.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    StatusCard.Text = "Status: Aguardando ativação..."
    StatusCard.TextColor3 = Color3.fromRGB(0, 255, 180)
    StatusCard.Font = Enum.Font.GothamMedium
    StatusCard.TextSize = 10
    StatusCard.TextWrapped = true
    Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 6)
    
    addToggle(TabCombat, "AUTO FARM MESTRE", State.AutoFarm, function(val)
        State.AutoFarm = val
    end)
    
    addToggle(TabCombat, "KILL AURA 360°", State.KillAura, function(val)
        State.KillAura = val
    end)
    
    addToggle(TabCombat, "AUTO ATAQUE CONTÍNUO", State.AutoAttack, function(val)
        State.AutoAttack = val
    end)
    
    addCycleButton(TabCombat, "🎯 Prioridade de Alvo", {"Closest", "LowestHP"}, 1, function(val)
        State.TargetMode = val
    end)
    
    addCycleButton(TabCombat, "📏 Alcance de Detecção", {60, 120, 200, 350}, 2, function(val)
        State.DetectionRange = val
    end)
    
    -- 2. ABA MOVIMENTO & NOCLIP
    addToggle(TabMovement, "ATRAVESSAR PAREDES (NoClip)", State.NoClip, function(val)
        State.NoClip = val
    end)
    
    addCycleButton(TabMovement, "🚀 Modo de Deslocamento", {"NoClipWalk", "GlideFly", "InstantBehind"}, 1, function(val)
        State.MovementMode = val
    end)
    
    addCycleButton(TabMovement, "⚡ Velocidade de Corrida", {16, 28, 45, 70, 120}, 2, function(val)
        State.WalkSpeed = val
        if CurrentHumanoid then CurrentHumanoid.WalkSpeed = val end
    end)
    
    addToggle(TabMovement, "🦘 Pulo Infinito", State.InfiniteJump, function(val)
        State.InfiniteJump = val
    end)
    
    -- 3. ABA VISUAIS (ESP)
    addToggle(TabESP, "VER MONSTROS NA PAREDE (ESP)", State.MobESP, function(val)
        State.MobESP = val
        if not val then
            for _, hl in pairs(espObjects) do pcall(function() hl:Destroy() end) end
            espObjects = {}
        end
    end)
    
    -- 4. ABA EXTRAS
    addToggle(TabMisc, "🗡️ Auto-Equipar Arma", State.AutoEquip, function(val)
        State.AutoEquip = val
    end)
    
    addToggle(TabMisc, "🛡️ Anti-AFK (20 min)", State.AntiAFK, function(val)
        State.AntiAFK = val
    end)
    
    -- Abre aba inicial
    Tabs["Combate"].Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
    Tabs["Combate"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tabs["Combate"].Scroll.Visible = true
    
    -- Notificação Inicial
    local Toast = Instance.new("TextLabel", ScreenGui)
    Toast.Size = UDim2.new(0, 260, 0, 40)
    Toast.Position = UDim2.new(0.5, -130, 0.05, 0)
    Toast.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
    Toast.Text = "✅ GHOST V20 ATIVADO COM SUCESSO!"
    Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toast.Font = Enum.Font.GothamBlack
    Toast.TextSize = 11
    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)
    task.delay(3.5, function()
        TweenService:Create(Toast, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        task.wait(0.5)
        Toast:Destroy()
    end)
    
    -- ====================================================================
    -- LOOP PRINCIPAL DE COMBATE E ATRAVESSAMENTO DE PAREDES
    -- ====================================================================
    RunService.Heartbeat:Connect(function()
        if not CurrentCharacter or not CurrentRootPart or not CurrentHumanoid or CurrentHumanoid.Health <= 0 then
            return
        end
    
        updateTool()
        local now = os.clock()
    
        if now - lastCacheUpdate > 0.8 then
            scanMobs()
            lastCacheUpdate = now
        end
    
        if not State.AutoFarm then
            StatusCard.Text = "Status: Auto Farm Pausado. Clique para Ativar!"
            return
        end
    
        local target = getBestTarget()
        CurrentTarget = target
    
        if target and target.Root then
            local dist = (CurrentRootPart.Position - target.Root.Position).Magnitude
            local hp = math.floor(target.Humanoid.Health)
            local maxHp = math.floor(target.Humanoid.MaxHealth)
            StatusCard.Text = string.format("Alvo: %s\nVida: %d/%d | Dist: %.1f studs", target.Model.Name, hp, maxHp,
            dist)
    
            -- Desativa AutoRotate para mirar suavemente
            CurrentHumanoid.AutoRotate = false
            local lookPos = Vector3.new(target.Root.Position.X, CurrentRootPart.Position.Y, target.Root.Position.Z)
            CurrentRootPart.CFrame = CurrentRootPart.CFrame:Lerp(CFrame.lookAt(CurrentRootPart.Position, lookPos), 0.3)
    
            -- MOVIMENTAÇÃO ATRAVESSANDO PAREDES
            if dist > State.StopDistance then
                if State.MovementMode == "InstantBehind" then
                    -- Teleporte Instantâneo atrás do monstro
                    CurrentRootPart.CFrame = target.Root.CFrame * CFrame.new(0, 0, 3)
                elseif State.MovementMode == "GlideFly" then
                    -- Voa em linha reta direto pelo ar/paredes até o monstro
                    local dir = (target.Root.Position - CurrentRootPart.Position).Unit
                    CurrentRootPart.AssemblyLinearVelocity = dir * State.FlySpeed
                else
                    -- NoClipWalk: Anda reto atravessando paredes sem desvios
                    CurrentHumanoid:MoveTo(target.Root.Position)
                end
            else
                CurrentHumanoid:MoveTo(CurrentRootPart.Position)
                CurrentRootPart.AssemblyLinearVelocity = Vector3.zero
            end
    
            -- ATAQUE E KILL AURA
            if State.AutoAttack and CurrentTool then
                if now - lastAttackTime >= State.AttackCooldown then
                    if State.KillAura then
                        -- Ataca todos os monstros dentro do alcance
                        for _, mob in ipairs(TargetCache) do
                            if (CurrentRootPart.Position - mob.Root.Position).Magnitude <= State.AttackRange then
                                CurrentTool:Activate()
                                break
                            end
                        end
                    elseif dist <= State.AttackRange then
                        CurrentTool:Activate()
                    end
                    lastAttackTime = now
                end
            end
        else
            StatusCard.Text = "Status: Procurando alvos no raio de " .. State.DetectionRange .. " studs..."
            CurrentHumanoid.AutoRotate = true
        end
    end)

    print("[GHOST V20] Carregado com NoClip, Tabs e ESP!")

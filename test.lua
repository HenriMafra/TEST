    -- [[ GHOST HUB V21 - ULTRA FAST AUTO FARM & MOB HUNTER ]] --
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local rng = Random.new()

    local TargetGuiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if TargetGuiParent:FindFirstChild("GhostHubV21") then
        TargetGuiParent.GhostHubV21:Destroy()
    end

    -- ====================================================================
    -- CONFIGURAÇÕES PRINCIPAIS (ALTA VELOCIDADE)
    -- ====================================================================
    local Settings = {
        AutoFarm = false,
        AutoAttack = true,
        KillAura = true,
        AttackCooldown = 0.02, -- Ataque ultra-rápido (50 CPS)
        AttackRange = 12,
        
        -- Filtros de Alvo
        TargetMobsOnly = true, -- NUNCA ataca jogadores reais!
        TargetDistance = 350,  -- Raio de busca em studs
        
        -- Movimentação & NoClip
        NoClip = true,
        FarmPosition = "Behind", -- "Behind" (Atrás do Mob), "Above" (Flutuando), "Direct" (Frente)
        TravelMethod = "Glide",  -- "Glide" (Deslize Ultra Rápido), "Instant" (Teleporte)
        FlySpeed = 75,          -- Velocidade rápida e natural (ajustável até 150)
        StopOffset = 3.5,        -- Distância segura para golpear
        
        -- Visuais & Extras
        MobESP = true,
        FastSwing = true,
        AutoEquip = true,
        AntiAFK = true,
    }

    local CurrentChar = nil
    local CurrentHum = nil
    local CurrentRoot = nil
    local CurrentTool = nil
    local CurrentToolHandle = nil

    local TargetCache = {}
    local CurrentTarget = nil
    local lastAttackTime = 0
    local lastScanTime = 0
    local espObjects = {}

    -- Localização do Remote de Ataque do Servidor (Suporte Nativo Dungeon Rollers)
    local attackRemote = nil
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 3)
        if remotes then
            attackRemote = remotes:FindFirstChild("RequestAttackAction") or remotes:FindFirstChild("Attack")
        end
    end)

    -- ====================================================================
    -- NOCLIP ATIVO E ININTERRUPTO (ATRAVESSA PAREDES 100%)
    -- ====================================================================
    RunService.Stepped:Connect(function()
        if Settings.NoClip and CurrentChar then
            for _, part in ipairs(CurrentChar:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Anti AFK
    if Settings.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.zero)
        end)
    end

    -- ====================================================================
    -- GESTÃO DE PERSONAGEM E ARMAS
    -- ====================================================================
    local function onCharacterAdded(char)
        CurrentChar = char
        CurrentHum = char:WaitForChild("Humanoid")
        CurrentRoot = char:WaitForChild("HumanoidRootPart")

        if Settings.AutoEquip then
            task.delay(0.3, function()
                for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if item:IsA("Tool") then
                        CurrentHum:EquipTool(item)
                        break
                    end
                end
            end)
        end
    end

    if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

    local function updateTool()
        if not CurrentChar then return end
        local tool = CurrentChar:FindFirstChildOfClass("Tool")
        if tool ~= CurrentTool then
            CurrentTool = tool
            CurrentToolHandle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("Blade") or
            tool:FindFirstChildOfClass("BasePart"))
        end
    end

    -- ====================================================================
    -- IDENTIFICAÇÃO E FILTRO ESTRITO DE MONSTROS (ZERO PLAYERS)
    -- ====================================================================
    local function isRealPlayer(model)
        if not model then return true end
        if model == CurrentChar then return true end
        if Players:GetPlayerFromCharacter(model) then return true end
        if Players:FindFirstChild(model.Name) then return true end
        return false
    end

    local function applyESP(model)
        if not Settings.MobESP then return end
        if espObjects[model] then return end

        local hl = Instance.new("Highlight")
        hl.Name = "GhostMobESP"
        hl.Adornee = model
        hl.FillColor = Color3.fromRGB(255, 40, 70)
        hl.FillTransparency = 0.4
        hl.OutlineColor = Color3.fromRGB(0, 255, 200)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        espObjects[model] = hl
    end

    local function scanTargets()
        local list = {}
        if not CurrentRoot then return end

        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 then
                local model = desc.Parent
                -- FILTRO BLINDADO: IGNORA PLAYERS
                if model and not isRealPlayer(model) then
                    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or
                    model.PrimaryPart
                    if root then
                        local dist = (CurrentRoot.Position - root.Position).Magnitude
                        if dist <= Settings.TargetDistance then
                            table.insert(list, { Model = model, Root = root, Humanoid = desc, Dist = dist })
                            applyESP(model)
                        end
                    end
                end
            end
        end

        -- Limpa destaques mortos
        for model, hl in pairs(espObjects) do
            if not model.Parent or not model:FindFirstChild("Humanoid") or model.Humanoid.Health <= 0 then
                pcall(function() hl:Destroy() end)
                espObjects[model] = nil
            end
        end

        table.sort(list, function(a, b) return a.Dist < b.Dist end)
        TargetCache = list
    end

    -- ====================================================================
    -- MOTOR DE ATAQUE ULTRA-RÁPIDO (BYPASS DE ANIMAÇÕES & REMOTES)
    -- ====================================================================
    local function executeFastAttack(targetMob)
        if not targetMob or not targetMob.Root then return end

        -- 1. Dispara o Remote oficial do jogo (Dungeon Rollers)
        if attackRemote then
            pcall(function() attackRemote:FireServer() end)
        end

        -- 2. Ativação direta da Tool com cancelamento de animação travada
        if CurrentTool then
            CurrentTool:Activate()
            if Settings.FastSwing and CurrentChar then
                local anim = CurrentChar:FindFirstChildOfClass("Humanoid")
                local animator = anim and anim:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Name:lower():find("slash") or track.Name:lower():find("attack") or
                        track.Name:lower():find("swing") then
                            track:AdjustSpeed(3.0) -- Triplica velocidade de corte
                        end
                    end
                end
            end
        end

        -- 3. TouchInterest Instantâneo (se o executor suportar)
        if firetouchinterest and CurrentToolHandle and targetMob.Root then
            pcall(function()
                firetouchinterest(CurrentToolHandle, targetMob.Root, 0)
                firetouchinterest(CurrentToolHandle, targetMob.Root, 1)
            end)
        end
    end

    -- ====================================================================
    -- INTERFACE GRÁFICA HUD V21 (DESIGN PROFISSIONAL MOBILE/PC)
    -- ====================================================================
    local ScreenGui = Instance.new("ScreenGui", TargetGuiParent)
    ScreenGui.Name = "GhostHubV21"
    ScreenGui.ResetOnSpawn = false

    -- Botão Flutuante (Arrastável)
    local FloatBtn = Instance.new("TextButton", ScreenGui)
    FloatBtn.Size = UDim2.new(0, 105, 0, 36)
    FloatBtn.Position = UDim2.new(0.02, 0, 0.20, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    FloatBtn.Text = "⚡ GHOST V21"
    FloatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
    FloatBtn.Font = Enum.Font.GothamBlack
    FloatBtn.TextSize = 12
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
    local FloatStroke = Instance.new("UIStroke", FloatBtn)
    FloatStroke.Color = Color3.fromRGB(0, 255, 180)
    FloatStroke.Thickness = 1.5

    -- Janela Principal
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 390, 0, 290)
    Main.Position = UDim2.new(0.5, -195, 0.5, -145)
    Main.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Color3.fromRGB(0, 255, 180)
    MainStroke.Thickness = 1.8

    -- Arrastar Janela
    local function enableDrag(frame, dragHandle)
        local dragging, dragStart, startPos
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType ==
            Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
                startPos.Y.Offset + delta.Y)
            end
        end)
    end
    enableDrag(FloatBtn, FloatBtn)

    -- Header
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundColor3 = Color3.fromRGB(19, 21, 28)
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
    enableDrag(Main, Header)

    local HeaderTitle = Instance.new("TextLabel", Header)
    HeaderTitle.Size = UDim2.new(1, -60, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Text = "⚡ GHOST AUTO-FARM V21 [ULTRA SPEED]"
    HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HeaderTitle.Font = Enum.Font.GothamBlack
    HeaderTitle.TextSize = 11
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 28, 0, 24)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 45, 65)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    FloatBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

    -- Painel Lateral de Abas
    local TabContainer = Instance.new("Frame", Main)
    TabContainer.Size = UDim2.new(0, 105, 1, -44)
    TabContainer.Position = UDim2.new(0, 6, 0, 40)
    TabContainer.BackgroundColor3 = Color3.fromRGB(17, 19, 25)
    Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 8)
    local TabLayout = Instance.new("UIListLayout", TabContainer)
    TabLayout.Padding = UDim.new(0, 4)

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, -123, 1, -44)
    ContentArea.Position = UDim2.new(0, 117, 0, 40)
    ContentArea.BackgroundTransparency = 1

    local Tabs = {}
    local function makeTab(name, icon)
        local btn = Instance.new("TextButton", TabContainer)
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.Position = UDim2.new(0, 4, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
        btn.Text = icon .. " " .. name
        btn.TextColor3 = Color3.fromRGB(170, 175, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local scroll = Instance.new("ScrollingFrame", ContentArea)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Visible = false
        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Scroll.Visible = false
                t.Btn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
                t.Btn.TextColor3 = Color3.fromRGB(170, 175, 200)
            end
            scroll.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    
        Tabs[name] = { Scroll = scroll, Btn = btn }
        return scroll
    end
    
    local TabCombat = makeTab("Combate", "⚔️")
    local TabMovement = makeTab("Velocidade", "🚀")
    local TabESP = makeTab("Visuais", "👁️")
    local TabMisc = makeTab("Extras", "⚙️")
    
    -- Helpers de UI
    local function addToggle(parent, text, default, cb)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, -6, 0, 34)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 110) or Color3.fromRGB(40, 44, 58)
        btn.Text = (default and "🟢 " or "🔴 ") .. text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 110) or Color3.fromRGB(40, 44, 58)
            btn.Text = (state and "🟢 " or "🔴 ") .. text
            cb(state)
        end)
    end
    
    local function addCycle(parent, label, options, defaultIdx, cb)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, -6, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(28, 31, 44)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(0, 240, 255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local idx = defaultIdx
        local function update()
            btn.Text = label .. ": " .. tostring(options[idx])
            cb(options[idx])
        end
        update()
        btn.MouseButton1Click:Connect(function()
            idx = (idx % #options) + 1
            update()
        end)
    end
    
    -- ====================================================================
    -- CONSTRUÇÃO DAS OPÇÕES NO HUD
    -- ====================================================================
    
    -- Aba Combate
    local StatusLabel = Instance.new("TextLabel", TabCombat)
    StatusLabel.Size = UDim2.new(1, -6, 0, 44)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    StatusLabel.Text = "Status: Farm desligado. Ative abaixo!"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextSize = 10
    StatusLabel.TextWrapped = true
    Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)
    
    addToggle(TabCombat, "AUTO FARM RÁPIDO", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
    addToggle(TabCombat, "KILL AURA 360°", Settings.KillAura, function(v) Settings.KillAura = v end)
    addToggle(TabCombat, "FILTRO: APENAS MONSTROS", Settings.TargetMobsOnly, function(v) Settings.TargetMobsOnly = v end)
    addCycle(TabCombat, "Posição de Combate", {"Behind", "Above", "Direct"}, 1, function(v) Settings.FarmPosition = v end)
    addCycle(TabCombat, "Cadência de Ataque", {0.02, 0.05, 0.08, 0.15}, 1, function(v) Settings.AttackCooldown = v end)
    
    -- Aba Movimento
    addToggle(TabMovement, "ATRAVESSAR PAREDES (NoClip)", Settings.NoClip, function(v) Settings.NoClip = v end)
    addCycle(TabMovement, "Método de Deslocamento", {"Glide", "Instant"}, 1, function(v) Settings.TravelMethod = v end)
    addCycle(TabMovement, "Velocidade de Glide", {45, 75, 110, 160}, 2, function(v) Settings.FlySpeed = v end)
    
    -- Aba Visuais
    addToggle(TabESP, "VER MONSTROS NA PAREDE (ESP)", Settings.MobESP, function(v)
        Settings.MobESP = v
        if not v then
            for _, hl in pairs(espObjects) do pcall(function() hl:Destroy() end) end
            espObjects = {}
        end
    end)
    
    -- Aba Extras
    addToggle(TabMisc, "FAST SWING (Anti-Lentidão)", Settings.FastSwing, function(v) Settings.FastSwing = v end)
    addToggle(TabMisc, "Auto-Equipar Espada", Settings.AutoEquip, function(v) Settings.AutoEquip = v end)
    addToggle(TabMisc, "Anti-Desconexão (Anti-AFK)", Settings.AntiAFK, function(v) Settings.AntiAFK = v end)
    
    -- Inicializa aba Combate
    Tabs["Combate"].Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
    Tabs["Combate"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tabs["Combate"].Scroll.Visible = true
    
    -- ====================================================================
    -- LOOP PRINCIPAL DE ULTRA VELOCIDADE
    -- ====================================================================
    RunService.Heartbeat:Connect(function()
        if not CurrentChar or not CurrentRoot or not CurrentHum or CurrentHum.Health <= 0 then
            return
        end
    
        updateTool()
        local now = os.clock()
    
        -- Varre alvos a cada 0.6s
        if now - lastScanTime > 0.6 then
            scanTargets()
            lastScanTime = now
        end
    
        if not Settings.AutoFarm then
            StatusLabel.Text = "Status: Auto Farm Pausado."
            return
        end
    
        CurrentTarget = TargetCache[1]
        if CurrentTarget and CurrentTarget.Root and CurrentTarget.Humanoid.Health > 0 then
            local targetRoot = CurrentTarget.Root
            local dist = (CurrentRoot.Position - targetRoot.Position).Magnitude
            local hp = math.floor(CurrentTarget.Humanoid.Health)
            local maxHp = math.floor(CurrentTarget.Humanoid.MaxHealth)
    
            StatusLabel.Text = string.format("🎯 Alvo: %s (MOB)\n❤️ Vida: %d/%d | 📏 Dist: %.1f studs",
            CurrentTarget.Model.Name, hp, maxHp, dist)
    
            -- 1. PONTO DE DESTINO TÁTICO
            local destinationCFrame
            if Settings.FarmPosition == "Behind" then
                -- Fica 3.5 studs ATRÁS do mob (não toma dano de frente)
                destinationCFrame = targetRoot.CFrame * CFrame.new(0, 0, Settings.StopOffset)
            elseif Settings.FarmPosition == "Above" then
                -- Flutua 5 studs acima da cabeça do mob
                destinationCFrame = targetRoot.CFrame * CFrame.new(0, 5, 0)
            else
                destinationCFrame = targetRoot.CFrame * CFrame.new(0, 0, -Settings.StopOffset)
            end
    
            local destPos = destinationCFrame.Position
    
            -- 2. MOVIMENTAÇÃO RÁPIDA (SEM ENGASGOS DE MOVETO)
            if (CurrentRoot.Position - destPos).Magnitude > 2.0 then
                if Settings.TravelMethod == "Instant" then
                    -- Teleporte Instantâneo atrás do monstro
                    CurrentRoot.CFrame = CFrame.lookAt(destPos, targetRoot.Position)
                else
                    -- Glide suave e ultra-rápido atravessando paredes
                    local moveDir = (destPos - CurrentRoot.Position).Unit
                    CurrentRoot.AssemblyLinearVelocity = moveDir * Settings.FlySpeed
                    CurrentRoot.CFrame = CFrame.lookAt(CurrentRoot.Position, targetRoot.Position)
                end
            else
                -- No alcance ideal: trava o movimento e mira no monstro
                CurrentRoot.AssemblyLinearVelocity = Vector3.zero
                CurrentRoot.CFrame = CFrame.lookAt(CurrentRoot.Position, targetRoot.Position)
            end
    
            -- 3. GOLPES DE ALTA FREQUÊNCIA (SEM ANIMAÇÃO LENTA)
            if Settings.AutoAttack and (now - lastAttackTime >= Settings.AttackCooldown) then
                if Settings.KillAura then
                    -- Ataca todos os monstros próximos de uma vez
                    for _, mob in ipairs(TargetCache) do
                        if (CurrentRoot.Position - mob.Root.Position).Magnitude <= Settings.AttackRange then
                            executeFastAttack(mob)
                        end
                    end
                elseif dist <= Settings.AttackRange then
                    executeFastAttack(CurrentTarget)
                end
                lastAttackTime = now
            end
        else
            StatusLabel.Text = "Status: Procurando monstros no raio de " .. Settings.TargetDistance .. " studs..."
            CurrentRoot.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    print("[GHOST V21] Auto-Farm Ultra Rápido Ativado!")

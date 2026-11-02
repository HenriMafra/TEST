--[[

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES DE ALTA PRECISÃO
local Config = {
	DetectionRange = 15, 
	AttackRange = 6,     
	BaseStopDistance = 1.5, 
	WeaponLengthOffset = 2.0, 
	CacheRefreshRate = 1.0, 
	HideAnimations = true, 
	PathRecalcThreshold = 4.0, 
	FarmSpeed = 0.1, 
	Variation = 0.05, 
}

-- ESTADO DO JOGADOR
local CurrentCharacter = nil
local CurrentHumanoid = nil
local CurrentRootPart = nil
local CurrentAnimator = nil
local CurrentTool = nil
local CurrentToolHandle = nil

-- ESTADO DO SCRIPT
local isFarming = true
local targetCharacter = nil
local targetRootPart = nil
local currentPathId = nil
local pathWaypoints = {}
local currentWaypointIndex = 0

-- CRONÔMETROS INDEPENDENTES
local lastCacheUpdate = 0
local lastMoveUpdate = 0 
local lastIdleUpdate = 0 

-- VARIÁVEIS DE CONTROLE
local lastAttackTime = 0
local lastTargetPos = Vector3.new(0, 0, 0)

-- CACHE DE ALVOS
local TargetCache = {} 

-- FUNÇÃO DE INICIALIZAÇÃO SEGURA
local function onCharacterAdded(character)
	CurrentCharacter = character
	
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	local animator = Instance.new("Animator")
	animator.Parent = humanoid
	
	CurrentHumanoid = humanoid
	CurrentRootPart = rootPart
	CurrentAnimator = animator
	
	humanoid.WalkSpeed = 16
	
	pcall(function()
		for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				humanoid:EquipTool(tool)
				break
			end
		end
	end)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ATUALIZA REFERÊNCIAS DA TOOL
local function updateToolReference()
	if not CurrentCharacter then return end
	
	local newTool = CurrentCharacter:FindFirstChildOfClass("Tool")
	if newTool ~= CurrentTool then
		CurrentTool = newTool
		if CurrentTool and CurrentTool:IsA("Tool") then
			CurrentToolHandle = CurrentTool:FindFirstChild("Handle") or CurrentTool
		else
			CurrentToolHandle = nil
		end
		
		if Config.HideAnimations and CurrentAnimator then
			CurrentAnimator:ClearAllTracks()
		end
	end
end

-- HEURÍSTICA OTIMIZADA (Tree Traversal Clássica)
local function getAllModels(folder, list)
	if not folder or not list then return end
	
	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(list, child)
		elseif child:IsA("Folder") then
			getAllModels(child, list)
		end
	end
end

-- CONSTRUÇÃO DE CACHE OTIMIZADA
local function buildTargetCache()
	TargetCache = {}
	
	-- 1. Adiciona Players
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character.Parent == Workspace then
			table.insert(TargetCache, player.Character)
		end
	end
	
	-- 2. Adiciona Mobs/NPCs
	for _, folder in pairs(Workspace:GetChildren()) do
		if folder:IsA("Folder") then
			-- Ignora pastas óbvias de sistema
			local ignoredNames = {"Map", "Assets", "Lighting"}
			local isIgnored = false
			for _, name in pairs(ignoredNames) do
				if folder.Name:lower() == name:lower() then
					isIgnored = true
					break
				end
			end
			
			if not isIgnored then
				local models = {}
				getAllModels(folder, models)
				
				for _, obj in pairs(models) do
					local hum = obj:FindFirstChild("Humanoid")
					local root = obj:FindFirstChild("HumanoidRootPart")
					
					if hum and root and hum.Health > 0 then
						local size = obj:GetExtentsSize()
						-- Filtra ruído de partículas
						if size.Magnitude > 1 and size.Magnitude < 50 then
							table.insert(TargetCache, obj)
						end
					end
				end
			end
		end
	end
end

-- ENCONTRA MELHOR ALVO NO CACHE (COM FILTRO DE VIDA)
local function findBestTarget()
	local bestTarget = nil
	local bestDistance = math.huge
	
	for _, obj in pairs(TargetCache) do
		local root = obj:FindFirstChild("HumanoidRootPart")
		local hum = obj:FindFirstChild("Humanoid")
		
		-- CORREÇÃO A: Verifica se está vivo
		if root and hum and hum.Health > 0 then
			local dist = (CurrentRootPart.Position - root.Position).Magnitude
			if dist < Config.DetectionRange and dist < bestDistance then
				bestDistance = dist
				bestTarget = { Character = obj, Root = root }
			end
		end
	end
	
	return bestTarget
end

-- LOOP PRINCIPAL OTIMIZADO
RunService.Heartbeat:Connect(function(dt)
	if not isFarming or not CurrentRootPart or not CurrentHumanoid then return end
	
	updateToolReference()
	
	-- Atualiza o cache periodicamente
	if tick() - lastCacheUpdate > Config.CacheRefreshRate then
		buildTargetCache()
		lastCacheUpdate = tick()
	end
	
	-- 1. Encontra o alvo
	local targetData = findBestTarget()
	targetCharacter = targetData and targetData.Character
	targetRootPart = targetData and targetData.Root
	
	-- 2. Lógica de Movimento e Rotação
	if targetRootPart then
		-- Mantém AutoRotate desligado enquanto combate
		if CurrentHumanoid.AutoRotate then
			CurrentHumanoid.AutoRotate = false
		end
		
		local distance = (CurrentRootPart.Position - targetRootPart.Position).Magnitude
		
		-- Calcula a distância ideal de parada
		local stopDistance = Config.BaseStopDistance + Config.WeaponLengthOffset
		
		-- Matemática Anti-NaN Impecável
		local flatTargetPosition = Vector3.new(targetRootPart.Position.X, CurrentRootPart.Position.Y, targetRootPart.Position.Z)
		local directionVector = flatTargetPosition - CurrentRootPart.Position
		local lookDirection
		
		if directionVector.Magnitude > 0.001 then
			lookDirection = directionVector.Unit
		else
			lookDirection = CurrentRootPart.CFrame.LookVector
		end

		-- Rotação Suave
		local targetCFrame = CFrame.new(CurrentRootPart.Position, CurrentRootPart.Position + lookDirection)
		CurrentRootPart.CFrame = CurrentRootPart.CFrame:Lerp(targetCFrame, 0.2)

		if distance > stopDistance then
			-- Lógica de Pathfinding Híbrido REAL
			if distance > 10 then
				
				local now = tick()
				
				-- VERIFICA SE É NECESSÁRIO RECALCULAR
				local targetMoved = (targetRootPart.Position - lastTargetPos).Magnitude > Config.PathRecalcThreshold
				local pathFinished = currentWaypointIndex >= #pathWaypoints
				local timeExpired = (now - lastMoveUpdate) > 2.0
				
				if targetMoved or pathFinished or timeExpired then
					
					local success, pathResult = pcall(function()
						local path = PathfindingService:CreatePath()
						path:ComputeAsync(CurrentRootPart.Position, targetRootPart.Position)
						return path
					end)
					
					if success and pathResult.Status == Enum.PathStatus.Success then
						local waypoints = pathResult:GetWaypoints()
						if #waypoints > 0 then
							currentPathId = tostring(targetRootPart)
							pathWaypoints = waypoints
							
							-- CORREÇÃO B: Reset direto e limpo!
							currentWaypointIndex = 1
							
							-- Move para o primeiro waypoint disponível
							-- PROTEÇÃO CONTRA NIL
							if pathWaypoints[currentWaypointIndex] then
								if pathWaypoints[currentWaypointIndex].Action ~= Enum.PathWaypointAction.Jump then
									CurrentHumanoid:MoveTo(pathWaypoints[currentWaypointIndex].Position)
								else
									CurrentHumanoid.Jump = true
									CurrentHumanoid:MoveTo(pathWaypoints[currentWaypointIndex].Position)
								end
							end
						end
					else
						CurrentHumanoid:MoveTo(targetRootPart.Position)
					end
					lastMoveUpdate = now 
					
					-- Salva posição do alvo para comparação futura
					lastTargetPos = targetRootPart.Position
				else
					-- Continua seguindo o caminho existente SEM resetar
					if currentWaypointIndex <= #pathWaypoints then
						local nextWaypoint = pathWaypoints[currentWaypointIndex]
						CurrentHumanoid:MoveTo(nextWaypoint.Position)
						
						-- Avança SOmente se chegou perto
						if (CurrentRootPart.Position - nextWaypoint.Position).Magnitude < 2 then
							currentWaypointIndex = currentWaypointIndex + 1
						end
					else
						CurrentHumanoid:MoveTo(targetRootPart.Position)
					end
				end
			else
				-- Curta distância: Vai reto
				CurrentHumanoid:MoveTo(targetRootPart.Position)
			end
		else
			-- Dentro do alcance: Para e mira
			CurrentHumanoid:MoveTo(CurrentRootPart.Position)
		end
		
		-- 3. Lógica de Ataque (USANDO CONFIGURAÇÕES REAIS)
		if CurrentTool and CurrentToolHandle then
			local now = tick()
			local attackInterval = Config.FarmSpeed + math.random(-Config.Variation, Config.Variation)
			
			if distance <= Config.AttackRange then
				if now - lastAttackTime >= attackInterval then
					CurrentTool:Activate()
					lastAttackTime = now
				end
			end
		end
	else
		-- Sem alvo: Modo Ocioso + Restaura AutoRotate
		if not CurrentHumanoid.AutoRotate then
			CurrentHumanoid.AutoRotate = true
		end
		
		-- Movimento ocioso independente
		if tick() - lastIdleUpdate > 1.0 then
			local randomOffset = Vector3.new(math.random(-3,3), 0, math.random(-3,3))
			CurrentHumanoid:MoveTo(CurrentRootPart.Position + randomOffset)
			lastIdleUpdate = tick()
		end
	end
end)

-- LIMPEZA AO SAIR
LocalPlayer.PlayerRemoving:Connect(function()
	isFarming = false
end)

print("[GHOST V17] Phantom Edit corrigido. Reset de waypoint aplicado.")

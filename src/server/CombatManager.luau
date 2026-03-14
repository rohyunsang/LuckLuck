--[[
	CombatManager
	- 모든 영웅들이 몬스터를 탐색하고 스탯에 따라 공격
	- 단일, 범위(Splash), 스턴(Stun) 구현
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HeroConfig = require(ReplicatedStorage.Shared.HeroConfig)
local MonsterMovement = require(script.Parent.MonsterMovement)

local CombatManager = {}
local _lastProcessTime = 0

-- 거리가 기준치 이내인지 확인 (간단한 거리 비교)
local function getDistance(pos1: Vector3, pos2: Vector3): number
	return (pos1 - pos2).Magnitude
end

-- 가장 가까운 몬스터 찾기
local function findClosestMonster(heroPos: Vector3, range: number)
	local activeMonsters = MonsterMovement._activeMonsters
	local closestDist = range
	local closestTarget = nil

	for _, entry in activeMonsters do
		local monster = entry.Monster
		if monster and monster.Parent then
			local dist = getDistance(heroPos, monster.Position)
			if dist <= closestDist then
				-- 체력이 남은 녀석만 타겟
				local health = monster:GetAttribute("Health") or 0
				if health > 0 then
					closestDist = dist
					closestTarget = monster
				end
			end
		end
	end

	return closestTarget
end

-- 범위 내 몬스터 모두 찾기 (Splash용)
local function findMonstersInRange(centerPos: Vector3, radius: number)
	local activeMonsters = MonsterMovement._activeMonsters
	local targets = {}

	for _, entry in activeMonsters do
		local monster = entry.Monster
		if monster and monster.Parent then
			local dist = getDistance(centerPos, monster.Position)
			if dist <= radius then
				local health = monster:GetAttribute("Health") or 0
				if health > 0 then
					table.insert(targets, monster)
				end
			end
		end
	end

	return targets
end

-- 이펙트 생성 (TweenService를 이용한 횡베기 추가)
local function createAttackEffect(hero: Instance, target: Instance, attackType: string)
	local heroPos = hero:GetPivot().Position
	local targetPos = target.Position

	if attackType == "MeleeSingle" then
		-- 횡베기 이펙트 (검기)
		local slash = Instance.new("Part")
		slash.Anchored = true
		slash.CanCollide = false
		slash.Material = Enum.Material.Neon
		slash.Color = Color3.fromRGB(200, 255, 255) -- 살짝 더 진한 하늘색
		slash.Size = Vector3.new(1, 1, 1)
		slash.Transparency = 0.05 -- 처음엔 선명하게

		-- 방향: 영웅 -> 타겟 (수평)
		local dir = (targetPos - heroPos)
		if dir.Magnitude > 0.1 then
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
		else
			dir = Vector3.new(0, 0, 1)
		end
		
		-- 타겟의 중앙 살짝 위에서 스폰되어 방향을 바라봄
		local center = targetPos + Vector3.new(0, 1.5, 0)
		slash.CFrame = CFrame.lookAt(center, center + dir)
		
		-- SpecialMesh로 타원형 구체 생성 (Y축을 납작하게)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(10, 0.2, 5) -- 시작 크기 대폭 확장 (가로, 두께, 넓이)
		mesh.Parent = slash
		slash.Parent = workspace
		
		-- 순식간에 가로로 쫙 퍼지며 앞으로 전진하고 사라짐
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out) -- 연출을 0.3초로 살짝 늘림
		local tweenMesh = TweenService:Create(mesh, tweenInfo, {
			Scale = Vector3.new(30, 0.05, 12) -- 터질 때 가로 30스터드까지 거대하게 확 넓어짐
		})
		local tweenPart = TweenService:Create(slash, tweenInfo, {
			Transparency = 1,
			CFrame = slash.CFrame * CFrame.new(0, 0, -6) -- 앞으로 6스터드 길게 베고 지나감
		})
		
		tweenMesh:Play()
		tweenPart:Play()
		
		task.spawn(function()
			task.wait(0.25)
			slash:Destroy()
		end)
		
		return -- 횡베기 완료
	end

	-- 기타 공격은 기본 파티클 유지
	local isAoE = string.match(attackType, "Splash") ~= nil
	local effectPart = Instance.new("Part")
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.Transparency = 1 -- 파트 자체는 보이지 않게
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.Position = target.Position
	effectPart.Parent = workspace

	-- 파티클 에미터 생성
	local particle = Instance.new("ParticleEmitter")
	-- Texture 안 쓰면 로블록스 기본 입자(부드러운 빛무리)가 나옴
	particle.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 50))
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	particle.Lifetime = NumberRange.new(0.3, 0.5)
	particle.Speed = NumberRange.new(10, 25)
	particle.SpreadAngle = Vector2.new(180, 180) -- 사방으로 흩어짐
	
	-- 서버 생성 직후 Emit() 호출 시 클라이언트 복제 지연으로 인해 스킵될 수 있으므로,
	-- Emit() 대신 잠시 켜두었다가 끄는 방식을 사용합니다.
	particle.Rate = isAoE and 200 or 50
	particle.Enabled = true
	particle.Parent = effectPart
	
	-- 이펙트 파트 유지 후 삭제 (파티클이 다 사라질 시간 고려)
	task.spawn(function()
		task.wait(0.1)
		if particle then particle.Enabled = false end
		task.wait(0.5)
		if effectPart then effectPart:Destroy() end
	end)
end

function CombatManager.start()
	local gameState = ReplicatedStorage:WaitForChild("GameState")

	RunService.Heartbeat:Connect(function(dt)
		local isRunning = gameState:GetAttribute("IsRunning")
		if not isRunning then return end

		local timeScale = gameState:GetAttribute("TimeScale") or 1.0
		local scaledDt = dt * timeScale

		local currentTime = tick()
		
		-- 플레이어들의 맵에 소환된 영웅 파트들 순회
		local map = workspace:FindFirstChild("Map")
		if not map then return end

		for _, zone in map:GetChildren() do
			if not string.match(zone.Name, "GridZone") then continue end
			
			for _, heroModel in zone:GetChildren() do
				local ownerName = heroModel:GetAttribute("Owner")
				local rarity = heroModel:GetAttribute("Rarity")
				local subIndex = heroModel:GetAttribute("SubIndex")

				if not ownerName or not rarity or not subIndex then continue end

				local player = Players:FindFirstChild(ownerName)
				if not player then continue end

				-- 능력치 및 설정 가져오기
				local stats = HeroConfig.CombatStats[subIndex]
				local multiplier = HeroConfig.RarityMultiplier[rarity] or 1

				if not stats then continue end

				-- 쿨타임 체크 (timeScale이 클수록 쿨타임이 빨리 줄어드는 효과를 위해 실제 경과 시간을 늘림)
				local lastAttack = heroModel:GetAttribute("LastAttackTime") or 0
				if currentTime - lastAttack < (stats.Cooldown / timeScale) then
					continue
				end

				local heroPos = heroModel:GetPivot().Position

				-- 타겟 탐색
				local target = findClosestMonster(heroPos, stats.Range)

				if target then
					-- 공격 실행
					heroModel:SetAttribute("LastAttackTime", currentTime)
					local damage = stats.BaseDamage * multiplier

					if stats.Type == "MeleeSplash" or stats.Type == "RangedSplash" then
						-- 범위 공격
						local targets = findMonstersInRange(target.Position, stats.SplashRadius)
						for _, t in targets do
							local hp = t:GetAttribute("Health") or 0
							t:SetAttribute("Health", hp - damage)
						end
						createAttackEffect(heroModel, target, stats.Type)
						
					elseif stats.Type == "StunAttack" then
						-- 스턴 공격
						local hp = target:GetAttribute("Health") or 0
						target:SetAttribute("Health", hp - damage)
						
						local currentStun = target:GetAttribute("StunRemaining") or 0
						target:SetAttribute("StunRemaining", math.max(currentStun, stats.StunDuration))
						createAttackEffect(heroModel, target, stats.Type)
						
					else
						-- 단일 공격
						local hp = target:GetAttribute("Health") or 0
						target:SetAttribute("Health", hp - damage)
						createAttackEffect(heroModel, target, false)
					end
				end
			end
		end
	end)

	print("[CombatManager] 전투 루프 시작됨")
end

return CombatManager

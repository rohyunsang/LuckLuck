--[[
	CombatManager
	- 모든 영웅들이 몬스터를 탐색하고 스탯에 따라 공격
	- 단일, 범위(Splash), 스턴(Stun) 구현
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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

-- 이펙트 생성 (서버에서 Part를 만들어 클라이언트에 리플리케이트, 혹은 클라이언트에서 그리도록 RPC 가능하지만 임시로 Part 생성)
local function createAttackEffect(hero: Instance, target: Instance, isAoE: boolean)
	local effect = Instance.new("Part")
	effect.Anchored = true
	effect.CanCollide = false
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.new(1, 0, 0)
	
	if isAoE then
		effect.Shape = Enum.PartType.Ball
		effect.Size = Vector3.new(1, 1, 1)
		effect.Position = target.Position
	else
		effect.Shape = Enum.PartType.Block
		effect.Size = Vector3.new(0.5, 0.5, (hero:GetPivot().Position - target.Position).Magnitude)
		effect.CFrame = CFrame.lookAt(hero:GetPivot().Position, target.Position) * CFrame.new(0, 0, -effect.Size.Z/2)
	end

	effect.Parent = workspace
	
	task.spawn(function()
		task.wait(0.1)
		if effect then effect:Destroy() end
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
						createAttackEffect(heroModel, target, true)
						
					elseif stats.Type == "StunAttack" then
						-- 스턴 공격
						local hp = target:GetAttribute("Health") or 0
						target:SetAttribute("Health", hp - damage)
						
						local currentStun = target:GetAttribute("StunRemaining") or 0
						target:SetAttribute("StunRemaining", math.max(currentStun, stats.StunDuration))
						createAttackEffect(heroModel, target, false)
						
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

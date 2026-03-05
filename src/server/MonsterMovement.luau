--[[
	MonsterMovement
	- Waypoint 기반 경로 이동
	- Heartbeat로 매 프레임 Position 보간 이동
	- 마지막 웨이포인트 도달 시 몬스터 제거
	- Health <= 0 처리
]]

local RunService = game:GetService("RunService")

local MonsterMovement = {}
MonsterMovement._activeMonsters = {} -- { monster: Part, waypointIndex: number }

-- 웨이포인트 목록을 정렬해서 가져온다
function MonsterMovement._getWaypoints(): { BasePart }
	local pathFolder = workspace:FindFirstChild("Map")
		and workspace.Map:FindFirstChild("Path")

	if not pathFolder then
		warn("[MonsterMovement] Workspace.Map.Path 폴더를 찾을 수 없습니다!")
		return {}
	end

	local waypoints = {}
	for _, child in pathFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(waypoints, child)
		end
	end

	-- 이름 기준 정렬 (Waypoint1, Waypoint2, ...)
	table.sort(waypoints, function(a, b)
		local numA = tonumber(a.Name:match("%d+")) or 0
		local numB = tonumber(b.Name:match("%d+")) or 0
		return numA < numB
	end)

	return waypoints
end

-- 몬스터를 경로 이동 대상에 등록
function MonsterMovement.register(monster: BasePart)
	table.insert(MonsterMovement._activeMonsters, {
		Monster = monster,
		WaypointIndex = 1,
	})
end

-- 몬스터 제거
function MonsterMovement._removeEntry(index: number)
	local entry = MonsterMovement._activeMonsters[index]
	if entry and entry.Monster and entry.Monster.Parent then
		entry.Monster:Destroy()
	end
	table.remove(MonsterMovement._activeMonsters, index)
end

-- Heartbeat 연결 (메인 이동 루프)
function MonsterMovement.start()
	local waypoints = MonsterMovement._getWaypoints()

	if #waypoints == 0 then
		warn("[MonsterMovement] 웨이포인트가 없습니다. 이동 로직을 시작할 수 없습니다.")
		return
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local gameState = ReplicatedStorage:WaitForChild("GameState")

	RunService.Heartbeat:Connect(function(dt)
		local timeScale = gameState:GetAttribute("TimeScale") or 1.0
		dt = dt * timeScale

		-- 웨이포인트가 변경되었을 수 있으므로 매번 다시 가져오지 않고 캐싱
		-- (런타임 중 경로가 바뀌는 경우 여기서 갱신하면 됨)

		local i = #MonsterMovement._activeMonsters
		while i >= 1 do
			local entry = MonsterMovement._activeMonsters[i]
			local monster = entry.Monster

			-- 몬스터가 이미 제거되었는지 확인
			if not monster or not monster.Parent then
				table.remove(MonsterMovement._activeMonsters, i)
				i -= 1
				continue
			end

			-- 체력 확인
			local health = monster:GetAttribute("Health") or 0
			if health <= 0 then
				print("[MonsterMovement] 몬스터 처치: " .. monster.Name)

				-- 보상 지급 (모든 플레이어에게 지급 - 싱글/협동 테스트용)
				local reward = monster:GetAttribute("Reward") or 0
				if reward > 0 then
					local HeroManager = require(game:GetService("ServerScriptService").Server.HeroManager)
					for _, player in game:GetService("Players"):GetPlayers() do
						HeroManager.addGold(player, reward)
					end
				end

				monster:Destroy()
				table.remove(MonsterMovement._activeMonsters, i)
				i -= 1
				continue
			end

			-- 스턴 버프 확인
			local stunRemaining = monster:GetAttribute("StunRemaining") or 0
			if stunRemaining > 0 then
				monster:SetAttribute("StunRemaining", stunRemaining - dt)
				
				-- 스턴 시각 효과 (색상 변경 등, 임시 처리)
				if monster:IsA("BasePart") then
					monster.Color = Color3.fromRGB(255, 255, 0)
				end
				
				i -= 1
				continue
			else
				-- 스턴 풀리면 원래 색상으로 (원래 색상을 따로 저장해야하지만 단순 빨간색으로 롤백)
				if monster:IsA("BasePart") then
					monster.Color = Color3.fromRGB(200, 50, 50)
				end
			end

			-- 현재 목표 웨이포인트 (순환)
			local wpIndex = ((entry.WaypointIndex - 1) % #waypoints) + 1
			local targetWP = waypoints[wpIndex]

			-- 이동
			local speed = monster:GetAttribute("Speed") or 12
			local direction = (targetWP.Position - monster.Position)
			local distance = direction.Magnitude

			if distance < 1 then
				-- 웨이포인트 도달 → 다음으로 (자동 순환)
				entry.WaypointIndex += 1
			else
				-- 보간 이동
				local moveStep = direction.Unit * speed * dt
				if moveStep.Magnitude > distance then
					monster.Position = targetWP.Position
				else
					monster.Position = monster.Position + moveStep
				end
			end

			i -= 1
		end
	end)

	print("[MonsterMovement] 이동 시스템 시작됨 (웨이포인트 " .. #waypoints .. "개)")
end

-- 현재 활성 몬스터 수 반환
function MonsterMovement.getActiveCount(): number
	return #MonsterMovement._activeMonsters
end

-- 모든 활성 몬스터 제거 (보스 실패 시 등)
function MonsterMovement.clearAll()
	for i = #MonsterMovement._activeMonsters, 1, -1 do
		local entry = MonsterMovement._activeMonsters[i]
		if entry.Monster and entry.Monster.Parent then
			entry.Monster:Destroy()
		end
	end
	MonsterMovement._activeMonsters = {}
	print("[MonsterMovement] 모든 몬스터 제거됨")
end

return MonsterMovement

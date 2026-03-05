--[[
	HeroManager
	- 플레이어 초기화 (Gold, ProbLevel)
	- 영웅 소환 추첨 로직
	- 확률 증가 로직
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HeroConfig = require(ReplicatedStorage.Shared.HeroConfig)
local HeroGrid = require(script.Parent.HeroGrid)

local HeroManager = {}

-- 초기화
function HeroManager.initPlayer(player: Player)
	if not player:GetAttribute("Gold") then
		player:SetAttribute("Gold", 1000000) -- 시작 테스트용 골드
		player:SetAttribute("ProbLevel", 1)
	end

	-- Grid 초기화
	HeroGrid.initPlayerGrid(player)

	-- 소환된 영웅 정보 저장 폴더
	local heroesFolder = player:FindFirstChild("HeroesFolder")
	if not heroesFolder then
		heroesFolder = Instance.new("Folder")
		heroesFolder.Name = "HeroesFolder"
		heroesFolder.Parent = player
	end
end

-- 골드 보상 부여 (몬스터, 스테이지 등에서 호출)
function HeroManager.addGold(player: Player, amount: number)
	local current = player:GetAttribute("Gold") or 0
	player:SetAttribute("Gold", current + amount)
end

-- 등급 추첨 알고리즘 (백분율 기반)
function HeroManager._rollRarity(level: number): string
	local probs = HeroConfig.Probabilities[level]
	if not probs then probs = HeroConfig.Probabilities[1] end

	-- 1 ~ 10000 (소수점 1자리까지 지원하므로 비율 계산)
	local roll = math.random() * 100

	if roll <= probs.Legend then
		return "Legend"
	elseif roll <= (probs.Legend + probs.Epic) then
		return "Epic"
	elseif roll <= (probs.Legend + probs.Epic + probs.Rare) then
		return "Rare"
	else
		return "Common"
	end
end

-- 영웅 소환
function HeroManager.summonHero(player: Player)
	-- 최대 소환 수(25마리) 체크
	local totalCount = HeroGrid.getTotalHeroCount(player)
	if totalCount >= 25 then
		return false, "Max Hero Limit Reached (25/25)"
	end

	local gold = player:GetAttribute("Gold") or 0
	local cost = HeroConfig.SummonCost

	if gold < cost then
		-- 골드 부족
		return false, "Not enough gold"
	end

	-- 등급 추첨
	local level = player:GetAttribute("ProbLevel") or 1
	local rarity = HeroManager._rollRarity(level)
	local subIndex = math.random(1, 5)

	-- 격자 빈칸 확인
	local gridIndex = HeroGrid.findAvailableGrid(player, rarity, subIndex)
	if not gridIndex then
		return false, "No available grid slots"
	end

	-- 골드 차감
	player:SetAttribute("Gold", gold - cost)

	-- 격자에 기록 및 해당 칸 안에서의 순번
	local countInGrid = HeroGrid.addHeroToGrid(player, gridIndex, rarity, subIndex)

	-- 임시로 폴더에 기록
	local heroData = Instance.new("Configuration")
	heroData.Name = "Hero_" .. rarity .. "_" .. subIndex
	heroData:SetAttribute("Rarity", rarity)
	heroData:SetAttribute("SubIndex", subIndex)
	heroData.Parent = player:FindFirstChild("HeroesFolder")

	-- 실제 맵(3D 파트) 스폰 처리
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. gridIndex)
	if gridZone then
		local zonePos = gridZone.Position
		
		-- 한 칸 안에서 최대 3마리 배치. 
		-- 중앙(2), 좌측(-offset), 우측(+offset) 형태로 배치
		local offsetX = 0
		if countInGrid == 2 then offsetX = -4
		elseif countInGrid == 3 then offsetX = 4 
		end
		
		local visualData = HeroConfig.Visuals[rarity][subIndex]
		
		local heroPart
		if visualData.Composite then
			-- 네모 + 동그라미 결합형
			heroPart = Instance.new("Model")
			
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(4, 2, 4)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true
			basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon
			basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(3, 3, 3)
			topPart.Position = basePart.Position + Vector3.new(0, 2.5, 0)
			topPart.Anchored = true
			topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon
			topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(4, 4, 4)
			heroPart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (heroPart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			heroPart.Anchored = true
			heroPart.CanCollide = false
			heroPart.Material = Enum.Material.Neon
			heroPart.Color = visualData.Color
			
			if typeof(visualData.Shape) == "EnumItem" then
				heroPart.Shape = visualData.Shape
			elseif visualData.Shape == "Wedge" then
				local wedge = Instance.new("WedgePart")
				wedge.Size = heroPart.Size
				wedge.Position = heroPart.Position
				wedge.Anchored = true
				wedge.CanCollide = false
				wedge.Material = Enum.Material.Neon
				wedge.Color = visualData.Color
				heroPart = wedge
			end
		end

		heroPart.Name = "Hero_" .. rarity .. "_" .. subIndex

		-- 오너쉽 및 파트 식별용
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", rarity)
		heroPart:SetAttribute("SubIndex", subIndex)
		heroPart.Parent = gridZone
	end

	print("[HeroManager] " .. player.Name .. " 영웅 소환: " .. rarity .. "-" .. subIndex .. " (배치 구역: " .. gridIndex .. " / 현재 총 " .. (totalCount+1) .. "마리)")
	
	-- 전체 마릿수 변경을 클라이언트가 알 수 있도록 (UI에서 사용)
	player:SetAttribute("HeroCount", totalCount + 1)

	return true, rarity .. " " .. subIndex
end

-- 소환 확률 증가
function HeroManager.upgradeProb(player: Player)
	local gold = player:GetAttribute("Gold") or 0
	local level = player:GetAttribute("ProbLevel") or 1
	local cost = HeroConfig.UpgradeCost

	if level >= HeroConfig.MaxProbLevel then
		return false, "Max level reached"
	end

	if gold < cost then
		return false, "Not enough gold"
	end

	-- 골드 차감 및 레벨 증가
	player:SetAttribute("Gold", gold - cost)
	player:SetAttribute("ProbLevel", level + 1)

	print("[HeroManager] " .. player.Name .. " 확률 업그레이드! 현재 Lv. " .. (level + 1))

	return true, level + 1
end

-- 영웅 합성
function HeroManager.mergeHero(player: Player, gridIndex: number)
	local mergeables = HeroGrid.getMergeableGrids(player)
	
	-- 유효성 검사
	local targetMergeInfo = nil
	for _, info in mergeables do
		if info.GridIndex == gridIndex then
			targetMergeInfo = info
			break
		end
	end

	if not targetMergeInfo then
		return false, "Invalid merge target"
	end

	local rarity = targetMergeInfo.Rarity
	local subIndex = targetMergeInfo.SubIndex
	
	local nextRarity = "Legend"
	if rarity == "Common" then nextRarity = "Rare"
	elseif rarity == "Rare" then nextRarity = "Epic"
	elseif rarity == "Epic" then nextRarity = "Legend"
	else
		return false, "Cannot merge Legend"
	end

	-- 1. 격자 모델 제거
	local success = HeroGrid.removeHeroesFromGrid(player, gridIndex, 3)
	if not success then return false, "Failed to remove heroes from grid data" end

	-- 2. 3D 파트/모델 제거
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. gridIndex)
	if gridZone then
		local removedCount = 0
		-- GridZone의 자식들 중, 오너와 등급과 SubIndex가 일치하는 것을 3개 찾아서 파괴
		for _, child in gridZone:GetChildren() do
			if removedCount >= 3 then break end
			
			if child:GetAttribute("Owner") == player.Name and 
			   child:GetAttribute("Rarity") == rarity and 
			   child:GetAttribute("SubIndex") == subIndex then
				
				child:Destroy()
				removedCount += 1
			end
		end
	end

	-- 3. 임시 폴더에서 3개 제거
	local heroesFolder = player:FindFirstChild("HeroesFolder")
	if heroesFolder then
		local removedCount = 0
		for _, child in heroesFolder:GetChildren() do
			if removedCount >= 3 then break end
			if child.Name == "Hero_" .. rarity .. "_" .. subIndex then
				child:Destroy()
				removedCount += 1
			end
		end
	end

	-- 총 마릿수 감소 (-3 +1 될 예정이므로, 일단 -3 시킴)
	local totalCount = player:GetAttribute("HeroCount") or 0
	player:SetAttribute("HeroCount", totalCount - 3)

	-- 4. 다음 등급의 영웅 1개 소환
	-- (summonHero 함수를 재사용하되, 소환 비용 차감/확률 추첨 과정을 건너뛰는 내부 함수로 분리할 필요가 있음)
	-- 구조를 변경하는 것보다 직접 여기서 배치 스폰 로직을 타는 것이 빠름
	local nextSubIndex = math.random(1, 5)
	local nextGridIndex = HeroGrid.findAvailableGrid(player, nextRarity, nextSubIndex)
	if not nextGridIndex then
		-- 격자가 꽉 찬 경우 (이론상 3개가 빠졌으니 항상 빈자리는 존재함)
		warn("[HeroManager] 합성 후 남은 빈 자리가 없습니다!")
		return false, "No available slots for merged hero"
	end

	local countInGrid = HeroGrid.addHeroToGrid(player, nextGridIndex, nextRarity, nextSubIndex)

	-- 새로 획득한 영웅 폴더 저장
	local newHeroData = Instance.new("Configuration")
	newHeroData.Name = "Hero_" .. nextRarity .. "_" .. nextSubIndex
	newHeroData:SetAttribute("Rarity", nextRarity)
	newHeroData:SetAttribute("SubIndex", nextSubIndex)
	newHeroData.Parent = player:FindFirstChild("HeroesFolder")

	-- 실제 맵 소환
	local nextGridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. nextGridIndex)
	if nextGridZone then
		local zonePos = nextGridZone.Position
		local offsetX = 0
		if countInGrid == 2 then offsetX = -4
		elseif countInGrid == 3 then offsetX = 4 
		end
		
		local visualData = HeroConfig.Visuals[nextRarity][nextSubIndex]
		local heroPart
		
		if visualData.Composite then
			heroPart = Instance.new("Model")
			
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(4, 2, 4)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (nextGridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true
			basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon
			basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(3, 3, 3)
			topPart.Position = basePart.Position + Vector3.new(0, 2.5, 0)
			topPart.Anchored = true
			topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon
			topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(4, 4, 4)
			heroPart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (heroPart.Size.Y / 2) + (nextGridZone.Size.Y / 2), zonePos.Z)
			heroPart.Anchored = true
			heroPart.CanCollide = false
			heroPart.Material = Enum.Material.Neon
			heroPart.Color = visualData.Color
			
			if typeof(visualData.Shape) == "EnumItem" then
				heroPart.Shape = visualData.Shape
			elseif visualData.Shape == "Wedge" then
				local wedge = Instance.new("WedgePart")
				wedge.Size = heroPart.Size
				wedge.Position = heroPart.Position
				wedge.Anchored = true
				wedge.CanCollide = false
				wedge.Material = Enum.Material.Neon
				wedge.Color = visualData.Color
				heroPart = wedge
			end
		end

		heroPart.Name = "Hero_" .. nextRarity .. "_" .. nextSubIndex
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", nextRarity)
		heroPart:SetAttribute("SubIndex", nextSubIndex)
		heroPart.Parent = nextGridZone
	end

	-- 마릿수 +1 갱신 (위에서 -3 했으므로 결과적으로 -2됨)
	local prevHeroCount = player:GetAttribute("HeroCount") or 0
	player:SetAttribute("HeroCount", prevHeroCount + 1)

	print("[HeroManager] " .. player.Name .. " 합성 완료! " .. rarity .. "x3 -> " .. nextRarity .. "-" .. nextSubIndex)

	return true, nextRarity .. " " .. nextSubIndex
end

return HeroManager

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

	-- 격자 칸 내리기 상호작용 프롬프트 셋업 (서버 통제)
	HeroManager._setupGridPrompts(player)

	-- 소환 횟수 초기화 (비용 증가용)
	if not player:GetAttribute("SummonCount") then
		player:SetAttribute("SummonCount", 0)
	end
end

-- 동적 소환 비용 계산
function HeroManager.getSummonCost(player: Player)
	local count = player:GetAttribute("SummonCount") or 0
	-- 기본 20골드 시작, 뽑을 때마다 5골드씩 증가
	return 20 + (count * 5)
end

-- 한 칸 안의 영웅들을 예쁘게 정렬
function HeroManager._repositionHeroesInGrid(player: Player, gridIndex: number)
	local map = workspace:FindFirstChild("Map")
	local gridZone = map and map:FindFirstChild("GridZone_" .. gridIndex)
	if not gridZone then return end

	local heroes = {}
	for _, child in gridZone:GetChildren() do
		if child:GetAttribute("Owner") == player.Name and child.Name:match("^Hero_") then
			table.insert(heroes, child)
		end
	end

	local count = #heroes
	if count == 0 then return end

	local zonePos = gridZone.Position
	for i, heroPart in ipairs(heroes) do
		local offsetX = 0
		if count == 2 then
			offsetX = (i == 1) and -2 or 2
		elseif count >= 3 then
			if i == 1 then offsetX = -2.5
			elseif i == 2 then offsetX = 0
			elseif i == 3 then offsetX = 2.5
			end
		end

		local currentPos = heroPart:GetPivot().Position
		local newPos = Vector3.new(zonePos.X + offsetX, currentPos.Y, currentPos.Z)

		if heroPart:IsA("Model") then
			heroPart:PivotTo(heroPart:GetPivot().Rotation + newPos)
		else
			heroPart.CFrame = CFrame.new(newPos) * (heroPart.CFrame - heroPart.CFrame.Position)
		end
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
	local cost = HeroManager.getSummonCost(player)

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

	-- 실제 맵(3D 파트) 스폰 처리
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. gridIndex)
	if gridZone then
		local zonePos = gridZone.Position
		local offsetX = 0 -- _repositionHeroesInGrid에서 재정렬됨
		
		local visualData = HeroConfig.Visuals[rarity][subIndex]
		
		local heroPart
		if visualData.Composite then
			-- 네모 + 동그라미 결합형
			heroPart = Instance.new("Model")
			
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(2, 1, 2)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true
			basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon
			basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(1.5, 1.5, 1.5)
			topPart.Position = basePart.Position + Vector3.new(0, 1.25, 0)
			topPart.Anchored = true
			topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon
			topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(2, 2, 2)
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
		
		-- 정렬 업데이트
		HeroManager._repositionHeroesInGrid(player, gridIndex)

		-- 상호작용 프롬프트 부착 (들기, 판매)
		HeroManager._attachHeroPrompts(player, gridIndex, heroPart, rarity, subIndex)
	end

	print("[HeroManager] " .. player.Name .. " 영웅 소환: " .. rarity .. "-" .. subIndex .. " (배치 구역: " .. gridIndex .. " / 현재 총 " .. (totalCount+1) .. "마리)")
	
	-- 전체 마릿수 변경을 클라이언트가 알 수 있도록 (UI에서 사용)
	player:SetAttribute("HeroCount", totalCount + 1)
	
	-- 소환 횟수 증가 (다음 소환 비용 증가)
	local summonCount = player:GetAttribute("SummonCount") or 0
	player:SetAttribute("SummonCount", summonCount + 1)

	HeroManager.updateSynergies(player)
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

-- 디버그 전용: 지정 영웅 소환 (골드 소모 없음, 제약조건 무시 가능)
function HeroManager.debugSummonHero(player: Player, rarity: string, subIndex: number)
	-- 최대 소환 수 체크 (편의상 제한은 유지)
	local totalCount = HeroGrid.getTotalHeroCount(player)
	if totalCount >= 25 then
		return false, "Max Hero Limit Reached (25/25)"
	end

	-- 격자 빈칸 확인
	local gridIndex = HeroGrid.findAvailableGrid(player, rarity, subIndex)
	if not gridIndex then
		return false, "No available grid slots"
	end

	-- 격자에 기록 및 해당 칸 안에서의 순번
	local countInGrid = HeroGrid.addHeroToGrid(player, gridIndex, rarity, subIndex)

	-- 실제 맵(3D 파트) 스폰 처리
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. gridIndex)
	if gridZone then
		local zonePos = gridZone.Position
		local offsetX = 0
		
		local visualData = HeroConfig.Visuals[rarity][subIndex]
		local heroPart
		
		if visualData.Composite then
			heroPart = Instance.new("Model")
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(2, 1, 2)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true; basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon; basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(1.5, 1.5, 1.5)
			topPart.Position = basePart.Position + Vector3.new(0, 1.25, 0)
			topPart.Anchored = true; topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon; topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(2, 2, 2)
			heroPart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (heroPart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			heroPart.Anchored = true; heroPart.CanCollide = false
			heroPart.Material = Enum.Material.Neon; heroPart.Color = visualData.Color
			
			if typeof(visualData.Shape) == "EnumItem" then heroPart.Shape = visualData.Shape
			elseif visualData.Shape == "Wedge" then
				local wedge = Instance.new("WedgePart")
				wedge.Size = heroPart.Size; wedge.Position = heroPart.Position
				wedge.Anchored = true; wedge.CanCollide = false
				wedge.Material = Enum.Material.Neon; wedge.Color = visualData.Color
				heroPart = wedge
			end
		end

		heroPart.Name = "Hero_" .. rarity .. "_" .. subIndex
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", rarity)
		heroPart:SetAttribute("SubIndex", subIndex)
		heroPart.Parent = gridZone
		
		-- 정렬 업데이트
		HeroManager._repositionHeroesInGrid(player, gridIndex)

		-- 상호작용 프롬프트 부착 (들기, 판매)
		HeroManager._attachHeroPrompts(player, gridIndex, heroPart, rarity, subIndex)
	end

	print("[DEBUG] " .. player.Name .. " 디버그 소환: " .. rarity .. "-" .. subIndex)
	
	player:SetAttribute("HeroCount", totalCount + 1)
	return true, rarity .. " " .. subIndex
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

	-- 실제 맵 소환
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. nextGridIndex)
	if gridZone then
		local zonePos = gridZone.Position
		local offsetX = 0
		-- 병합 후 1마리가 됨
		
		local visualData = HeroConfig.Visuals[nextRarity][nextSubIndex]
		local heroPart
		if visualData.Composite then
			heroPart = Instance.new("Model")
			
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(2, 1, 2)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true
			basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon
			basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(1.5, 1.5, 1.5)
			topPart.Position = basePart.Position + Vector3.new(0, 1.25, 0)
			topPart.Anchored = true
			topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon
			topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(2, 2, 2)
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
		
		heroPart.Name = "Hero_" .. nextRarity .. "_" .. nextSubIndex
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", nextRarity)
		heroPart:SetAttribute("SubIndex", nextSubIndex)
		heroPart.Parent = gridZone
		
		-- 정렬 업데이트
		HeroManager._repositionHeroesInGrid(player, nextGridIndex)

		-- 상호작용 프롬프트 부착 (들기, 판매)
		HeroManager._attachHeroPrompts(player, nextGridIndex, heroPart, nextRarity, nextSubIndex)
	end

	print("[HeroManager] " .. player.Name .. " 영웅 합성 성공: " .. nextRarity .. " " .. nextSubIndex .. " (배치 구역: " .. nextGridIndex .. ")")
	-- 마릿수 +1 갱신 (위에서 -3 했으므로 결과적으로 -2됨)
	local prevHeroCount = player:GetAttribute("HeroCount") or 0
	player:SetAttribute("HeroCount", prevHeroCount + 1)

	print("[HeroManager] " .. player.Name .. " 합성 완료! " .. rarity .. "x3 -> " .. nextRarity .. "-" .. nextSubIndex)

	HeroManager.updateSynergies(player)
	return true, nextRarity .. " " .. nextSubIndex
end

--------------------------------------------------------------------------------
-- 들기 / 내리기 (Drag & Drop) 연동 구현
--------------------------------------------------------------------------------

-- 플레이어 초기화 시 각 격자에 '내리기' 프롬프트를 보이지 않도록 준비
function HeroManager._setupGridPrompts(player: Player)
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	-- 기존에 이 플레이어용으로 만든 내리기 프롬프트가 있다면 리셋(재접속 처리)
	local holder = map:FindFirstChild("PutDownPrompts_" .. player.Name)
	if not holder then
		holder = Instance.new("Folder")
		holder.Name = "PutDownPrompts_" .. player.Name
		holder.Parent = map
	end
	holder:ClearAllChildren()

	for i = 1, 15 do
		local gridZone = map:FindFirstChild("GridZone_" .. i)
		if gridZone then
			-- 보이지 않는 프롬프트 파트 생성
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 1
			part.Size = gridZone.Size
			part.Position = gridZone.Position
			part.Parent = holder

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Place" -- 나중에 자동 번역기 대응
			prompt.ObjectText = "Grid " .. i
			-- 초기엔 비활성화
			prompt.Enabled = false 
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 15
			prompt.Parent = part
			prompt.Triggered:Connect(function(promptPlayer)
				if promptPlayer == player then
					HeroManager.placeHero(player, i)
				end
			end)
			
			part.Name = "Prompt_" .. i
		end
	end
end

-- 영웅 들기
function HeroManager.pickupHero(player: Player, gridIndex: number, heroPart: Instance)
	-- 이미 들고 있는 영웅이 있는지 확인
	if player:GetAttribute("HoldingHero_Rarity") then
		return false, "Already holding a hero"
	end

	local rarity = heroPart:GetAttribute("Rarity")
	local subIndex = heroPart:GetAttribute("SubIndex")

	-- 데이터에서 빼기
	local extracted = HeroGrid.takeOutHeroFromGrid(player, gridIndex)
	if not extracted then return false, "Cannot pickup from grid data" end

	-- 3D 모델 파괴 (또는 숨김) 대신 위치 이동 및 웰드로 들기 시도
	if heroPart and heroPart.Parent then
		-- 기존 영웅 모델을 캐릭터에 부착하기 위해 복제본 생성
		local character = player.Character
		if character and character.Parent then
			local head = character:FindFirstChild("Head")
			if head then
				local heldModel = heroPart:Clone()
				heldModel.Name = "HeldHeroModel"
				
				-- 프롬프트 제거
				for _, inst in heldModel:GetDescendants() do
					if inst:IsA("ProximityPrompt") then inst:Destroy() end
				end
				local p = heldModel:FindFirstChildOfClass("ProximityPrompt")
				if p then p:Destroy() end
				
				-- 물리 속성 제거
				for _, inst in heldModel:GetDescendants() do
					if inst:IsA("BasePart") then
						inst.Anchored = false
						inst.CanCollide = false
						inst.Massless = true
					end
				end
				if heldModel:IsA("BasePart") then
					heldModel.Anchored = false
					heldModel.CanCollide = false
					heldModel.Massless = true
				end

				-- 머리 위로 이동
				local offset = Vector3.new(0, 1.5, 0)
				if heldModel:IsA("Model") then
					heldModel:PivotTo(head.CFrame * CFrame.new(offset))
				else
					heldModel.CFrame = head.CFrame * CFrame.new(offset)
				end
				
				-- Weld 생성
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = heldModel:IsA("Model") and heldModel.PrimaryPart or heldModel
				weld.Parent = heldModel

				heldModel.Parent = character
			end
		end

		heroPart:Destroy()
	end
	
	-- 남은 영웅들 재정렬
	HeroManager._repositionHeroesInGrid(player, gridIndex)

	-- 플레이어 속성에 들고 있음 기록
	player:SetAttribute("HoldingHero_Rarity", rarity)
	player:SetAttribute("HoldingHero_SubIndex", subIndex)
	
	HeroManager._togglePutDownPrompts(player, true)
	HeroManager._toggleOtherPickupPrompts(player, false)

	print("[HeroManager] " .. player.Name .. " 영웅 줍기: " .. rarity .. "-" .. subIndex)
	HeroManager.updateSynergies(player)
	return true
end

-- 영웅 내리기
function HeroManager.placeHero(player: Player, gridIndex: number)
	local rarity = player:GetAttribute("HoldingHero_Rarity")
	local subIndex = player:GetAttribute("HoldingHero_SubIndex")

	if not rarity or not subIndex then
		return false, "Not holding any hero"
	end
	
	subIndex = tonumber(subIndex)

	-- 배치 가능 여부 확인
	if not HeroGrid.canPlaceHero(player, gridIndex, rarity, subIndex) then
		return false, "Cannot place here (Mismatched type or full)"
	end

	-- 격자에 기록
	local countInGrid = HeroGrid.addHeroToGrid(player, gridIndex, rarity, subIndex)

	-- 3D 다시 스폰 (간단히 하기 위해 기존 로직과 동일)
	local gridZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("GridZone_" .. gridIndex)
	if gridZone then
		local zonePos = gridZone.Position
		local offsetX = 0
		
		local visualData = HeroConfig.Visuals[rarity][subIndex]
		local heroPart
		
		-- (summonHero의 3D 생성 코드를 함수로 빼는게 좋지만, 일단 여기 직접 생성)
		if visualData.Composite then
			heroPart = Instance.new("Model")
			local basePart = Instance.new("Part")
			basePart.Size = Vector3.new(2, 1, 2)
			basePart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (basePart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			basePart.Anchored = true; basePart.CanCollide = false
			basePart.Material = Enum.Material.Neon; basePart.Color = visualData.Color
			basePart.Parent = heroPart

			local topPart = Instance.new("Part")
			topPart.Shape = Enum.PartType.Ball
			topPart.Size = Vector3.new(1.5, 1.5, 1.5)
			topPart.Position = basePart.Position + Vector3.new(0, 1.25, 0)
			topPart.Anchored = true; topPart.CanCollide = false
			topPart.Material = Enum.Material.Neon; topPart.Color = visualData.Color
			topPart.Parent = heroPart

			heroPart.PrimaryPart = basePart
		else
			heroPart = Instance.new("Part")
			heroPart.Size = Vector3.new(2, 2, 2)
			heroPart.Position = Vector3.new(zonePos.X + offsetX, zonePos.Y + (heroPart.Size.Y / 2) + (gridZone.Size.Y / 2), zonePos.Z)
			heroPart.Anchored = true; heroPart.CanCollide = false
			heroPart.Material = Enum.Material.Neon; heroPart.Color = visualData.Color
			
			if typeof(visualData.Shape) == "EnumItem" then heroPart.Shape = visualData.Shape
			elseif visualData.Shape == "Wedge" then
				local wedge = Instance.new("WedgePart")
				wedge.Size = heroPart.Size; wedge.Position = heroPart.Position
				wedge.Anchored = true; wedge.CanCollide = false
				wedge.Material = Enum.Material.Neon; wedge.Color = visualData.Color
				heroPart = wedge
			end
		end
		
		heroPart.Name = "Hero_" .. rarity .. "_" .. subIndex
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", rarity)
		heroPart:SetAttribute("SubIndex", subIndex)
		heroPart.Parent = gridZone
		
		-- 정렬 업데이트
		HeroManager._repositionHeroesInGrid(player, gridIndex)

		-- 상호작용 프롬프트 부착 (들기, 판매)
		HeroManager._attachHeroPrompts(player, gridIndex, heroPart, rarity, subIndex)
	end

	-- 들고 있던 시각적 모델 파괴
	local character = player.Character
	if character then
		local heldModel = character:FindFirstChild("HeldHeroModel")
		if heldModel then heldModel:Destroy() end
	end

	-- 속성 제거
	player:SetAttribute("HoldingHero_Rarity", nil)
	player:SetAttribute("HoldingHero_SubIndex", nil)
	
	HeroManager._togglePutDownPrompts(player, false)
	HeroManager._toggleOtherPickupPrompts(player, true)

	print("[HeroManager] " .. player.Name .. " 영웅 배치: " .. rarity .. "-" .. subIndex .. " (배치 구역: " .. gridIndex .. ")")
	HeroManager.updateSynergies(player)
	return true
end

-- '내리기' 프롬프트 일괄 켜고 끄기 (활성화 시엔 배치 가능한 칸만 켭니다)
function HeroManager._togglePutDownPrompts(player: Player, state: boolean)
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	local holder = map:FindFirstChild("PutDownPrompts_" .. player.Name)
	if not holder then return end

	local rarity = player:GetAttribute("HoldingHero_Rarity")
	local subIndex = player:GetAttribute("HoldingHero_SubIndex")

	for i, part in holder:GetChildren() do
		local prompt = part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			if state then
				-- 켤 때는 해당 격자에 놓을 수 있는지 확인
				-- part.Name이 "Prompt_1", "Prompt_2" 형식이므로 번호 추출
				local gridIdx = tonumber(string.match(part.Name, "%d+"))
				if gridIdx and rarity and subIndex and HeroGrid.canPlaceHero(player, gridIdx, rarity, tonumber(subIndex)) then
					prompt.Enabled = true
				else
					prompt.Enabled = false
				end
			else
				-- 끌 때는 무조건 끄기
				prompt.Enabled = false
			end
		end
	end
end

-- 다른 영웅들의 프롬프트를 처리 (상태에 따라 들기/판매 등 조절)
function HeroManager._toggleOtherPickupPrompts(player: Player, state: boolean)
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	for _, zone in map:GetChildren() do
		if string.match(zone.Name, "GridZone") then
			for _, child in zone:GetChildren() do
				if child:GetAttribute("Owner") == player.Name and child.Name:match("^Hero_") then
					-- 모든 프롬프트 찾아서 상태 조절
					for _, desc in child:GetDescendants() do
						if desc:IsA("ProximityPrompt") then
							-- 판매는 들고 있을 때 숨기고 들기가 활성화될 땐 켠다
							desc.Enabled = state
						end
					end
				end
			end
		end
	end
end

-- 영웅에게 프롬프트 일괄 부착 (들기, 판매)
function HeroManager._attachHeroPrompts(player: Player, gridIndex: number, heroPart: Instance, rarity: string, subIndex: number)
	local attachmentPart = heroPart:IsA("Model") and heroPart.PrimaryPart or heroPart
	
	-- 기존 프롬프트가 있다면 깔끔하게 제거
	for _, inst in attachmentPart:GetChildren() do
		if inst:IsA("ProximityPrompt") then
			inst:Destroy()
		end
	end

	-- 들기 프롬프트
	local pickupPrompt = Instance.new("ProximityPrompt")
	pickupPrompt.ActionText = "Pick up" -- 나중에 자동 번역기 대응
	pickupPrompt.ObjectText = rarity .. " " .. subIndex
	pickupPrompt.RequiresLineOfSight = false
	pickupPrompt.HoldDuration = 0
	pickupPrompt.MaxActivationDistance = 15
	pickupPrompt.UIOffset = Vector2.new(0, 40) -- 위로 더 띄움
	pickupPrompt.Triggered:Connect(function(promptPlayer)
		if promptPlayer == player then
			HeroManager.pickupHero(player, gridIndex, heroPart)
		end
	end)
	pickupPrompt.Parent = attachmentPart

	-- 판매 프롬프트
	local sellPrice = HeroConfig.SellPrices[rarity] or 5
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.ActionText = "Sell (+" .. sellPrice .. "G)" -- 나중에 자동 번역기 대응
	sellPrompt.ObjectText = rarity .. " " .. subIndex
	sellPrompt.RequiresLineOfSight = false
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.R -- R키로 할당
	sellPrompt.HoldDuration = 0.5 -- 강제로 0.5초 꾹 눌러야 팔리도록
	sellPrompt.MaxActivationDistance = 15
	sellPrompt.UIOffset = Vector2.new(0, -40) -- 아래로 더 내림
	sellPrompt.Triggered:Connect(function(promptPlayer)
		if promptPlayer == player then
			HeroManager.sellHero(player, gridIndex, heroPart)
		end
	end)
	sellPrompt.Parent = attachmentPart
end

-- 영웅 판매
function HeroManager.sellHero(player: Player, gridIndex: number, heroPart: Instance)
	local rarity = heroPart:GetAttribute("Rarity")
	local subIndex = heroPart:GetAttribute("SubIndex")
	if not rarity or not subIndex then return false, "Invalid Hero Data" end

	-- 1. 격자에서 꺼내기 (삭제)
	local extracted = HeroGrid.takeOutHeroFromGrid(player, gridIndex)
	if not extracted then return false, "Cannot sell from grid data" end

	-- 2. 실제 3D 모델 파괴
	if heroPart and heroPart.Parent then
		heroPart:Destroy()
	end

	-- 3. 남은 영웅들 재정렬
	HeroManager._repositionHeroesInGrid(player, gridIndex)
	
	-- 4. 총 마릿수 감소
	local prevHeroCount = player:GetAttribute("HeroCount") or 0
	if prevHeroCount > 0 then
		player:SetAttribute("HeroCount", prevHeroCount - 1)
	end
	
	-- 5. 골드 지급
	local sellPrice = HeroConfig.SellPrices[rarity] or 5
	HeroManager.addGold(player, sellPrice)
	
	print("[HeroManager] " .. player.Name .. " 영웅 판매: " .. rarity .. " " .. subIndex .. " (+" .. sellPrice .. " 골드)")
	
	HeroManager.updateSynergies(player)
	return true
end

-- 시너지 업데이트 로직
function HeroManager.updateSynergies(player: Player)
	local activeCounts = {
		Types = {}, -- { ["Melee"] = 5, ... }
		Rarities = {} -- { ["Rare"] = 3, ... }
	}

	-- 1. 모든 격자 순회하며 배치된 영웅 카운트
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	for _, zone in map:GetChildren() do
		if string.match(zone.Name, "GridZone") then
			for _, child in zone:GetChildren() do
				if child:GetAttribute("Owner") == player.Name and child.Name:match("^Hero_") then
					local rarity = child:GetAttribute("Rarity")
					local subIndex = child:GetAttribute("SubIndex")
					local stats = HeroConfig.CombatStats[subIndex]

					if rarity then
						activeCounts.Rarities[rarity] = (activeCounts.Rarities[rarity] or 0) + 1
					end

					if stats then
						-- MeleeSingle, MeleeSplash -> Melee
						local typePrefix = string.match(stats.Type, "^(%a+)%a+")
						if stats.Type == "StunAttack" then
							typePrefix = "Stun"
						end
						
						if typePrefix then
							activeCounts.Types[typePrefix] = (activeCounts.Types[typePrefix] or 0) + 1
						end
					end
				end
			end
		end
	end

	-- 2. 시너지 조건 체크
	local activeSynergies = {} -- { {Name = "...", Desc = "...", Type = "..."}, ... }
	
	for key, config in HeroConfig.Synergies.Types do
		local count = activeCounts.Types[key] or 0
		if count >= config.Requirement then
			table.insert(activeSynergies, {
				Name = config.Name,
				Desc = config.Desc,
				Type = "Type"
			})
		end
	end

	for key, config in HeroConfig.Synergies.Rarities do
		local count = activeCounts.Rarities[key] or 0
		if count >= config.Requirement then
			table.insert(activeSynergies, {
				Name = config.Name,
				Desc = config.Desc,
				Type = "Rarity"
			})
		end
	end

	-- 3. 클라이언트에 알림 (Attribute 사용)
	local HttpService = game:GetService("HttpService")
	player:SetAttribute("ActiveSynergies", HttpService:JSONEncode(activeSynergies))
end

return HeroManager

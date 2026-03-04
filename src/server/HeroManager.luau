--[[
	HeroManager
	- 플레이어 초기화 (Gold, ProbLevel)
	- 영웅 소환 추첨 로직
	- 확률 증가 로직
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HeroConfig = require(ReplicatedStorage.Shared.HeroConfig)

local HeroManager = {}

-- 초기화
function HeroManager.initPlayer(player: Player)
	if not player:GetAttribute("Gold") then
		player:SetAttribute("Gold", 200) -- 시작 테스트용 골드
		player:SetAttribute("ProbLevel", 1)
	end

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
	local gold = player:GetAttribute("Gold") or 0
	local cost = HeroConfig.SummonCost

	if gold < cost then
		-- 골드 부족
		return false, "Not enough gold"
	end

	-- 골드 차감
	player:SetAttribute("Gold", gold - cost)

	-- 등급 추첨
	local level = player:GetAttribute("ProbLevel") or 1
	local rarity = HeroManager._rollRarity(level)

	-- 임시로 폴더에 기록
	local heroData = Instance.new("Configuration")
	heroData.Name = "Hero_" .. rarity
	heroData:SetAttribute("Rarity", rarity)
	heroData.Parent = player:FindFirstChild("HeroesFolder")

	-- 실제 맵(3D 파트) 스폰 처리
	local heroZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("HeroZone")
	if heroZone then
		-- Zone 크기 기반 랜던 스페이싱
		local zoneSize = heroZone.Size
		local zonePos = heroZone.Position
		
		local rx = (math.random() - 0.5) * (zoneSize.X - 4) -- 가장자리 여백
		local rz = (math.random() - 0.5) * (zoneSize.Z - 4)
		
		local heroPart = Instance.new("Part")
		heroPart.Name = "Hero_" .. rarity
		heroPart.Size = Vector3.new(4, 4, 4)
		heroPart.Position = Vector3.new(zonePos.X + rx, zonePos.Y + (heroPart.Size.Y / 2) + (heroZone.Size.Y / 2), zonePos.Z + rz)
		heroPart.Anchored = true
		heroPart.CanCollide = false
		heroPart.Material = Enum.Material.Neon
		
		-- 설정해둔 비주얼 컬러 적용
		if HeroConfig.Visuals and HeroConfig.Visuals[rarity] then
			heroPart.Color = HeroConfig.Visuals[rarity].Color
		end

		-- 오너쉽 및 파트 식별용
		heroPart:SetAttribute("Owner", player.Name)
		heroPart:SetAttribute("Rarity", rarity)
		heroPart.Parent = heroZone
	end

	print("[HeroManager] " .. player.Name .. " 소환 결과: " .. rarity)

	return true, rarity
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

return HeroManager

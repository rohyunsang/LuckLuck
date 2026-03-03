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

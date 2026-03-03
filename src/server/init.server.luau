--[[
	서버 진입점
	- GameState 오브젝트 생성 (클라이언트에 게임 상태 공유)
	- RemoteEvent 생성 (웨이브 시작, 소환, 확률업)
	- 클라이언트의 요청 처리
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WaveManager = require(script.WaveManager)
local HeroManager = require(script.HeroManager)

--------------------------------------------------------------------------------
-- 1. GameState 초기화
--------------------------------------------------------------------------------
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState:SetAttribute("CurrentWave", 0)
gameState:SetAttribute("TotalWaves", 50)
gameState:SetAttribute("MonsterCount", 0)
gameState:SetAttribute("RemainingTime", 0)
gameState:SetAttribute("IsBossStage", false)
gameState:SetAttribute("IsGameOver", false)
gameState:SetAttribute("IsRunning", false)
gameState:SetAttribute("StageCleared", false)
gameState.Parent = ReplicatedStorage

--------------------------------------------------------------------------------
-- 2. RemoteEvents 생성
--------------------------------------------------------------------------------
local startWaveEvent = Instance.new("RemoteEvent")
startWaveEvent.Name = "StartWaveEvent"
startWaveEvent.Parent = ReplicatedStorage

local summonHeroEvent = Instance.new("RemoteFunction")
summonHeroEvent.Name = "SummonHeroEvent"
summonHeroEvent.Parent = ReplicatedStorage

local upgradeProbEvent = Instance.new("RemoteFunction")
upgradeProbEvent.Name = "UpgradeProbEvent"
upgradeProbEvent.Parent = ReplicatedStorage

--------------------------------------------------------------------------------
-- 3. 이벤트 핸들러
--------------------------------------------------------------------------------

-- 플레이어 접속 시 초기화
Players.PlayerAdded:Connect(function(player)
	HeroManager.initPlayer(player)
end)

-- 기존에 접속해 있는 플레이어 (Studio 테스트용)
for _, player in ipairs(Players:GetPlayers()) do
	HeroManager.initPlayer(player)
end

-- 클라이언트의 웨이브 시작 요청
startWaveEvent.OnServerEvent:Connect(function(player)
	if WaveManager.isRunning() then return end

	gameState:SetAttribute("IsGameOver", false)
	gameState:SetAttribute("StageCleared", false)

	task.spawn(function()
		WaveManager.start(gameState)
	end)
end)

-- 영웅 소환 요청
summonHeroEvent.OnServerInvoke = function(player)
	local success, result = HeroManager.summonHero(player)
	return { success = success, result = result }
end

-- 확률 강화 요청
upgradeProbEvent.OnServerInvoke = function(player)
	local success, result = HeroManager.upgradeProb(player)
	return { success = success, result = result }
end

print("[Server] LuckLuck 시스템 준비 완료!")
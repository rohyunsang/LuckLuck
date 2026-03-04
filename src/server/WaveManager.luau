--[[
	WaveManager
	- 50스테이지 웨이브 진행 관리
	- 보스 스테이지: 30초 제한시간 내 처치 필요
	- GameState Attributes를 통해 클라이언트에 실시간 상태 공유
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local MonsterSpawner = require(script.Parent.MonsterSpawner)
local MonsterMovement = require(script.Parent.MonsterMovement)

local WaveManager = {}
WaveManager._isRunning = false
WaveManager._currentWave = 0
WaveManager._movementStarted = false
WaveManager._jumpRequestedTo = nil -- 점프할 스테이지 번호 저장 변수

local TOTAL_WAVES = 50

function WaveManager.start(gameState: Folder)
	if WaveManager._isRunning then
		warn("[WaveManager] 이미 진행 중입니다!")
		return
	end

	WaveManager._isRunning = true
	WaveManager._currentWave = 0

	-- GameState 업데이트
	gameState:SetAttribute("IsRunning", true)
	gameState:SetAttribute("IsGameOver", false)
	gameState:SetAttribute("StageCleared", false)

	-- 이동 시스템은 한 번만 시작
	if not WaveManager._movementStarted then
		MonsterMovement.start()
		WaveManager._movementStarted = true
	end

	-- 몬스터 수 실시간 갱신 루프
	local monsterCountTask = task.spawn(function()
		while WaveManager._isRunning do
			gameState:SetAttribute("MonsterCount", MonsterMovement.getActiveCount())
			task.wait(0.2)
		end
	end)

	-- 웨이브 순차 진행 (for 루프 대신 while 루프로 변경하여 점프 대처)
	local waveNum = 1
	while waveNum <= TOTAL_WAVES and WaveManager._isRunning do
		WaveManager._currentWave = waveNum
		local waveData = WaveConfig[waveNum]

		if not waveData then
			warn("[WaveManager] 웨이브 " .. waveNum .. " 데이터 없음, 종료")
			break
		end

		waveData.WaveNum = waveNum
		
		-- GameState 업데이트
		gameState:SetAttribute("CurrentWave", waveNum)
		gameState:SetAttribute("IsBossStage", waveData.IsBoss)
		gameState:SetAttribute("RemainingTime", 0)

		local NORMAL_STAGE_TIME = 20
		local BOSS_STAGE_TIME = 30

		if waveData.IsBoss then
			-- ========== 보스 스테이지 ==========
			print("[WaveManager] ===== 🔥 보스 스테이지 " .. waveNum .. " =====")

			-- 보스 스폰
			MonsterSpawner.spawnWave(waveData)

			-- 보스 제한시간 타이머
			local timeLimit = BOSS_STAGE_TIME
			local elapsed = 0
			local bossDefeated = false

			gameState:SetAttribute("RemainingTime", timeLimit)
			print("[WaveManager] 보스 처치 제한시간: " .. timeLimit .. "초")

			while elapsed < timeLimit do
				task.wait(0.5)
				local timeScale = gameState:GetAttribute("TimeScale") or 1.0
				elapsed += (0.5 * timeScale)

				-- 점프 요청이 들어왔는지 체크
				if WaveManager._jumpRequestedTo then
					break
				end

				-- 남은 시간 갱신
				gameState:SetAttribute("RemainingTime", math.ceil(timeLimit - elapsed))

				if MonsterMovement.getActiveCount() == 0 then
					bossDefeated = true
					break
				end
			end

			-- 점프 처리
			if WaveManager._jumpRequestedTo then
				print("[WaveManager] ⏭ 점프 요청으로 보스 스테이지 중단.")
				MonsterMovement.clearAll()
				waveNum = WaveManager._jumpRequestedTo
				WaveManager._jumpRequestedTo = nil
				continue
			end

			gameState:SetAttribute("RemainingTime", 0)

			if bossDefeated then
				print("[WaveManager] ✅ 보스 스테이지 " .. waveNum .. " 클리어!")
			else
				-- 보스 처치 실패 → 게임 오버
				print("[WaveManager] ❌ 보스 처치 실패! 스테이지 " .. waveNum .. " 실패!")
				MonsterMovement.clearAll()

				gameState:SetAttribute("IsGameOver", true)
				gameState:SetAttribute("IsRunning", false)
				gameState:SetAttribute("MonsterCount", 0)

				WaveManager._isRunning = false
				return
			end
		else
			-- ========== 일반 스테이지 (20초 제한) ==========
			print("[WaveManager] ===== 웨이브 " .. waveNum .. " 시작 (제한시간 " .. NORMAL_STAGE_TIME .. "초) =====")

			local timeLimit = NORMAL_STAGE_TIME
			gameState:SetAttribute("RemainingTime", timeLimit)

			-- 스폰 완료 플래그
			local spawnComplete = false

			-- 몬스터 스폰 (별도 스레드에서 진행 — 타이머와 동시 실행)
			task.spawn(function()
				MonsterSpawner.spawnWave(waveData)
				spawnComplete = true
			end)

			-- 타이머 카운트다운
			local elapsed = 0
			local allCleared = false

			while elapsed < timeLimit do
				task.wait(0.5)
				local timeScale = gameState:GetAttribute("TimeScale") or 1.0
				elapsed += (0.5 * timeScale)

				-- 점프 요청 체크
				if WaveManager._jumpRequestedTo then
					break
				end

				gameState:SetAttribute("RemainingTime", math.ceil(timeLimit - elapsed))

				-- 스폰이 끝난 후에만 조기 클리어 체크
				if spawnComplete and MonsterMovement.getActiveCount() == 0 then
					allCleared = true
					break
				end
			end

			-- 점프 처리
			if WaveManager._jumpRequestedTo then
				print("[WaveManager] ⏭ 점프 요청으로 일반 스테이지 중단.")
				MonsterMovement.clearAll()
				waveNum = WaveManager._jumpRequestedTo
				WaveManager._jumpRequestedTo = nil
				continue
			end

			gameState:SetAttribute("RemainingTime", 0)

			if allCleared then
				print("[WaveManager] ✅ 웨이브 " .. waveNum .. " 조기 클리어!")
			else
				-- 시간 초과 → 남은 몬스터는 필드에 유지 (누적 압박)
				local remaining = MonsterMovement.getActiveCount()
				print("[WaveManager] ⏱ 웨이브 " .. waveNum .. " 시간 종료! (남은 몬스터: " .. remaining .. "마리)")
			end
			
			-- 스테이지 클리어 보상 (100 골드)
			local HeroManager = require(game:GetService("ServerScriptService").Server.HeroManager)
			for _, player in game:GetService("Players"):GetPlayers() do
				HeroManager.addGold(player, 100)
			end
		end

		-- 마지막 웨이브가 아니면 대기
		if waveNum < TOTAL_WAVES then
			print("[WaveManager] 다음 웨이브까지 " .. waveData.RestTime .. "초 대기")

			-- 대기 시간도 카운트다운으로 표시
			local restTime = waveData.RestTime
			gameState:SetAttribute("RemainingTime", restTime)
			local restElapsed = 0
			while restElapsed < restTime do
				task.wait(0.5)
				local timeScale = gameState:GetAttribute("TimeScale") or 1.0
				restElapsed += (0.5 * timeScale)

				-- 점프 요청 체크
				if WaveManager._jumpRequestedTo then
					break
				end

				gameState:SetAttribute("RemainingTime", math.ceil(restTime - restElapsed))
			end

			if WaveManager._jumpRequestedTo then
				print("[WaveManager] ⏭ 휴식 시간 중 점프 요청")
				MonsterMovement.clearAll()
				waveNum = WaveManager._jumpRequestedTo
				WaveManager._jumpRequestedTo = nil
				continue
			end

			gameState:SetAttribute("RemainingTime", 0)
		end
		
		waveNum += 1
	end

	-- 정상적으로 루프가 끝난 경우 (점프 없이 모든 스테이지 클리어)
	if WaveManager._isRunning and not WaveManager._jumpRequestedTo then
		print("[WaveManager] ===== 🎉 모든 50스테이지 클리어! =====")
		gameState:SetAttribute("StageCleared", true)
		gameState:SetAttribute("IsRunning", false)
		gameState:SetAttribute("MonsterCount", 0)
		WaveManager._isRunning = false
	end
end

function WaveManager.jumpToStage(stageNum: number)
	if not WaveManager._isRunning then
		warn("[WaveManager] 게임 진행 중이 아닙니다. 점프할 수 없습니다.")
		return
	end
	stageNum = math.clamp(stageNum, 1, 50)
	WaveManager._jumpRequestedTo = stageNum
end

function WaveManager.getCurrentWave(): number
	return WaveManager._currentWave
end

function WaveManager.isRunning(): boolean
	return WaveManager._isRunning
end

return WaveManager

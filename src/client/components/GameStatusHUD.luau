--[[
	GameStatusHUD — 게임 상태 표시 UI
	React 컴포넌트
	- 현재 스테이지
	- 남은 시간 (보스 타이머 / 대기 시간)
	- 남은 몬스터 수
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

-- GameState Attribute를 React state로 바인딩하는 커스텀 훅
local function useGameState(attributeName: string, default: any)
	local value, setValue = React.useState(default)

	React.useEffect(function()
		local gameState = ReplicatedStorage:WaitForChild("GameState")
		-- 초기값 설정
		local initial = gameState:GetAttribute(attributeName)
		if initial ~= nil then
			setValue(initial)
		end

		-- 변경 감지
		local connection = gameState:GetAttributeChangedSignal(attributeName):Connect(function()
			setValue(gameState:GetAttribute(attributeName))
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return value
end

local function GameStatusHUD()
	local currentWave = useGameState("CurrentWave", 0)
	local totalWaves = useGameState("TotalWaves", 50)
	local monsterCount = useGameState("MonsterCount", 0)
	local remainingTime = useGameState("RemainingTime", 0)
	local isBossStage = useGameState("IsBossStage", false)
	local isGameOver = useGameState("IsGameOver", false)
	local isRunning = useGameState("IsRunning", false)
	local stageCleared = useGameState("StageCleared", false)

	-- 게임 시작 전이면 표시 안함
	if not isRunning and currentWave == 0 and not isGameOver and not stageCleared then
		return nil
	end

	-- 상태 텍스트 결정
	local stageText
	if isGameOver then
		stageText = "💀 Game Over"
	elseif stageCleared then
		stageText = "🎉 All Clear!"
	elseif isBossStage then
		stageText = "🔥 BOSS  " .. currentWave .. " / " .. totalWaves
	else
		stageText = "⚔ STAGE  " .. currentWave .. " / " .. totalWaves
	end

	-- 타이머 색상 (일반/보스 모두 표시)
	local timerColor
	if remainingTime > 0 then
		if isBossStage then
			-- 보스: 더 긴박한 색상
			if remainingTime <= 10 then
				timerColor = Color3.fromRGB(255, 60, 60)
			elseif remainingTime <= 20 then
				timerColor = Color3.fromRGB(255, 200, 50)
			else
				timerColor = Color3.fromRGB(255, 255, 255)
			end
		else
			-- 일반: 단계별 색상
			if remainingTime <= 5 then
				timerColor = Color3.fromRGB(255, 60, 60)
			elseif remainingTime <= 10 then
				timerColor = Color3.fromRGB(255, 200, 50)
			else
				timerColor = Color3.fromRGB(255, 255, 255)
			end
		end
	else
		timerColor = Color3.fromRGB(180, 180, 180)
	end

	-- 타이머 텍스트
	local timerText
	if isGameOver or stageCleared then
		timerText = ""
	elseif remainingTime > 0 then
		timerText = "⏱ " .. remainingTime .. "초"
	else
		timerText = ""
	end

	return e("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 10,
	}, {
		-- 메인 패널
		Panel = e("Frame", {
			Size = UDim2.new(0, 280, 0, 110),
			Position = UDim2.new(0.5, 0, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(20, 20, 30),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),
			Stroke = e("UIStroke", {
				Color = if isBossStage and isRunning
					then Color3.fromRGB(255, 80, 80)
					else Color3.fromRGB(100, 100, 140),
				Thickness = 2,
				Transparency = 0.3,
			}),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			Layout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			-- 스테이지 표시
			StageLabel = e("TextLabel", {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Text = stageText,
				TextColor3 = if isGameOver
					then Color3.fromRGB(255, 80, 80)
					elseif stageCleared then Color3.fromRGB(80, 255, 80)
					elseif isBossStage then Color3.fromRGB(255, 200, 50)
					else Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 22,
				TextStrokeTransparency = 0.5,
			}),

			-- 타이머 표시
			TimerLabel = e("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = timerText,
				TextColor3 = timerColor,
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextStrokeTransparency = 0.6,
			}),

			-- 몬스터 수 표시
			MonsterLabel = e("TextLabel", {
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = if isGameOver or stageCleared
					then ""
					else "👾 Remaining Monsters: " .. monsterCount,
				TextColor3 = Color3.fromRGB(180, 220, 255),
				Font = Enum.Font.GothamMedium,
				TextSize = 16,
				TextStrokeTransparency = 0.7,
			}),
		}),
	})
end

return GameStatusHUD

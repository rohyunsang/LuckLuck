--[[
	HeroSummonUI.luau
	- 영웅 소환 및 확률 증가 UI (React)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local HeroConfig = require(ReplicatedStorage.Shared.HeroConfig)

local e = React.createElement
local localPlayer = Players.LocalPlayer

-- LocalPlayer의 Attribute를 구독하는 훅
local function usePlayerAttribute(attributeName: string, default: any)
	local value, setValue = React.useState(default)

	React.useEffect(function()
		local initial = localPlayer:GetAttribute(attributeName)
		if initial ~= nil then setValue(initial) end

		local connection = localPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
			setValue(localPlayer:GetAttribute(attributeName))
		end)

		return function() connection:Disconnect() end
	end, {})

	return value
end

local function HeroSummonUI()
	local gold = usePlayerAttribute("Gold", 0)
	local probLevel = usePlayerAttribute("ProbLevel", 1)
	
	local lastSummon, setLastSummon = React.useState(nil)
	local isSummoning, setIsSummoning = React.useState(false)

	local probs = HeroConfig.Probabilities[probLevel] or HeroConfig.Probabilities[1]

	local function onSummon()
		if gold < HeroConfig.SummonCost or isSummoning then return end
		setIsSummoning(true)

		local summonEvent = ReplicatedStorage:WaitForChild("SummonHeroEvent")
		local response = summonEvent:InvokeServer()
		
		if response.success then
			setLastSummon(response.result) -- "Common", "Rare" 등
		else
			warn("소환 실패: ", response.result)
		end
		
		setIsSummoning(false)
	end

	local function onUpgrade()
		if gold < HeroConfig.UpgradeCost or probLevel >= HeroConfig.MaxProbLevel then return end
		local upgradeEvent = ReplicatedStorage:WaitForChild("UpgradeProbEvent")
		upgradeEvent:InvokeServer()
	end

	return e("ScreenGui", { ResetOnSpawn = false }, {
		
		-- 메인 컨테이너 (우측 하단 배치)
		Container = e("Frame", {
			Size = UDim2.new(0, 320, 0, 240),
			Position = UDim2.new(1, -20, 1, -20),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = Color3.fromRGB(25, 25, 35),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
			Stroke = e("UIStroke", { Color = Color3.fromRGB(100, 100, 150), Thickness = 2 }),
			Padding = e("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingBottom= UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight= UDim.new(0, 15) }),

			-- 골드 표시
			GoldLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = "💰 골드: " .. gold,
				TextColor3 = Color3.fromRGB(255, 215, 0),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- 소환 결과 표시
			ResultLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, 35),
				BackgroundTransparency = 1,
				Text = lastSummon and ("✅ 획득: " .. lastSummon) or "영웅을 소환하세요!",
				TextColor3 = if lastSummon == "Legend" then Color3.fromRGB(255, 100, 100)
							 elseif lastSummon == "Epic" then Color3.fromRGB(200, 100, 255)
							 elseif lastSummon == "Rare" then Color3.fromRGB(100, 150, 255)
							 else Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),

			-- 소환 버튼
			SummonBtn = e("TextButton", {
				Size = UDim2.new(1, 0, 0, 50),
				Position = UDim2.new(0, 0, 0, 75),
				BackgroundColor3 = (gold >= HeroConfig.SummonCost) and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(80, 80, 80),
				Text = "✨ 영웅 소환 (" .. HeroConfig.SummonCost .. "G)",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				AutoButtonColor = true,
				[React.Event.Activated] = onSummon,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),

			-- 확률 업 버튼
			UpgradeBtn = e("TextButton", {
				Size = UDim2.new(1, 0, 0, 40),
				Position = UDim2.new(0, 0, 0, 135),
				BackgroundColor3 = (probLevel < HeroConfig.MaxProbLevel and gold >= HeroConfig.UpgradeCost) 
								   and Color3.fromRGB(200, 100, 50) or Color3.fromRGB(80, 80, 80),
				Text = "⬆ 확률 업 Lv." .. probLevel .. " (" .. HeroConfig.UpgradeCost .. "G)",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				AutoButtonColor = true,
				[React.Event.Activated] = onUpgrade,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) }),

			-- 현재 확률 표시
			ProbInfo = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 0, 185),
				BackgroundTransparency = 1,
				Text = string.format("일반 %.1f%% | 희귀 %.1f%% | 영웅 %.1f%% | 전설 %.1f%%", 
					probs.Common, probs.Rare, probs.Epic, probs.Legend),
				TextColor3 = Color3.fromRGB(180, 180, 180),
				Font = Enum.Font.Gotham,
				TextSize = 12,
			}),
		}),
	})
end

return HeroSummonUI

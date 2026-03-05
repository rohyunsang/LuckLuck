--[[
	HeroMergeUI.luau
	- 같은 등급/형태 3마리가 모였을 때 합성을 띄워주는 UI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local localPlayer = Players.LocalPlayer

local getMergeablesEvent = ReplicatedStorage:WaitForChild("GetMergeablesEvent")
local mergeHeroEvent = ReplicatedStorage:WaitForChild("MergeHeroEvent")

-- LocalPlayer의 Attribute를 구독하는 훅 (HeroCount 변경 시마다 체크하기 위함)
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

local function HeroMergeUI()
	local heroCount = usePlayerAttribute("HeroCount", 0)
	local mergeables, setMergeables = React.useState({})
	local isMerging, setIsMerging = React.useState(false)

	-- HeroCount가 변할 때마다(소환/합성 시마다) 서버에 합성 가능한 목록을 요청
	React.useEffect(function()
		local active = true
		task.spawn(function()
			local result = getMergeablesEvent:InvokeServer()
			if active then
				setMergeables(result or {})
			end
		end)
		return function() active = false end
	end, {heroCount})

	local function onMerge(gridIndex)
		if isMerging then return end
		setIsMerging(true)

		task.spawn(function()
			local response = mergeHeroEvent:InvokeServer(gridIndex)
			if not response.success then
				warn("합성 실패: ", response.result)
			end
			-- 성공이든 실패든 다시 갱신
			local result = getMergeablesEvent:InvokeServer()
			setMergeables(result or {})
			setIsMerging(false)
		end)
	end

	if #mergeables == 0 then
		return nil
	end

	-- 리스트 컴포넌트 생성
	local mergeChildren = {}
	mergeChildren.Layout = e("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	for i, info in ipairs(mergeables) do
		local rText
		if info.Rarity == "Common" then rText = "Common"
		elseif info.Rarity == "Rare" then rText = "Rare"
		elseif info.Rarity == "Epic" then rText = "Epic"
		else rText = info.Rarity end

		local btnText = "⬆ Merge " .. rText .. "-" .. info.SubIndex

		mergeChildren["MergeBtn_" .. i] = e("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 45),
			BackgroundColor3 = Color3.fromRGB(50, 200, 100),
			Text = btnText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			[React.Event.Activated] = function()
				onMerge(info.GridIndex)
			end,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	end

	return e("ScreenGui", { ResetOnSpawn = false }, {
		Container = e("Frame", {
			Size = UDim2.new(0, 200, 0, 0), -- AutomaticSize로 높이 자동 조절
			Position = UDim2.new(1, -360, 1, -20), -- HeroSummonUI의 왼쪽에 배치
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, mergeChildren)
	})
end

return HeroMergeUI

--[[
	DebugMenu — 배속 제어, 스테이지 이동, 영웅 소환 등을 하나로 통합한 디버그 메뉴
	React 컴포넌트
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local rarities = {"Common", "Rare", "Epic", "Legend"}

local function DebugMenu()
	local isMenuOpen, setIsMenuOpen = React.useState(false)
	local activeTab, setActiveTab = React.useState("Control") -- "Control" or "Spawner"
	
	-- Spawner State
	local selectedRarity, setSelectedRarity = React.useState("Common")
	local selectedSubIndex, setSelectedSubIndex = React.useState(1)
	
	-- Control State
	local stageInput, setStageInput = React.useState("")

	local function onSummon()
		local debugSummonEvent = ReplicatedStorage:WaitForChild("DebugSummonEvent")
		local response = debugSummonEvent:InvokeServer(selectedRarity, selectedSubIndex)
		if not response.success then
			warn("[DebugMenu] 소환 실패:", response.result)
		end
	end

	-- 토글 버튼만 표시되는 상태
	if not isMenuOpen then
		return e("ScreenGui", { ResetOnSpawn = false, DisplayOrder = 100 }, {
			OpenBtn = e("TextButton", {
				Size = UDim2.new(0, 100, 0, 30),
				Position = UDim2.new(0, 10, 0, 10),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BackgroundTransparency = 0.2,
				Text = "🛠 Debug",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				[React.Event.Activated] = function() setIsMenuOpen(true) end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = e("UIStroke", { Color = Color3.fromRGB(100, 100, 100), Thickness = 1 })
			})
		})
	end

	-- 메인 메뉴 프레임
	return e("ScreenGui", { ResetOnSpawn = false, DisplayOrder = 100 }, {
		MainFrame = e("Frame", {
			Size = UDim2.new(0, 240, 0, 250),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundColor3 = Color3.fromRGB(30, 30, 35),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Shadow = e("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.5, Thickness = 2 }),
			
			-- Header
			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, 35),
				BackgroundTransparency = 1,
			}, {
				Title = e("TextLabel", {
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = "🛠 LuckLuck Debug",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				CloseBtn = e("TextButton", {
					Size = UDim2.new(0, 30, 0, 30),
					Position = UDim2.new(1, -35, 0, 2.5),
					BackgroundTransparency = 1,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 100, 100),
					Font = Enum.Font.GothamBold,
					TextSize = 18,
					[React.Event.Activated] = function() setIsMenuOpen(false) end,
				})
			}),

			-- Tab Navigation
			Tabs = e("Frame", {
				Size = UDim2.new(1, -20, 0, 30),
				Position = UDim2.new(0, 10, 0, 40),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }),
				ControlTab = e("TextButton", {
					Size = UDim2.new(0.5, -2.5, 1, 0),
					Text = "Game Control",
					BackgroundColor3 = if activeTab == "Control" then Color3.fromRGB(60, 60, 80) else Color3.fromRGB(40, 40, 45),
					TextColor3 = Color3.new(1,1,1),
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					[React.Event.Activated] = function() setActiveTab("Control") end,
				}, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
				SpawnerTab = e("TextButton", {
					Size = UDim2.new(0.5, -2.5, 1, 0),
					Text = "Hero Spawner",
					BackgroundColor3 = if activeTab == "Spawner" then Color3.fromRGB(60, 60, 80) else Color3.fromRGB(40, 40, 45),
					TextColor3 = Color3.new(1,1,1),
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					[React.Event.Activated] = function() setActiveTab("Spawner") end,
				}, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
			}),

			-- Content Area
			Content = e("Frame", {
				Size = UDim2.new(1, -20, 1, -85),
				Position = UDim2.new(0, 10, 0, 75),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
				
				-- Control 탭 내용
				ControlPanel = activeTab == "Control" and e(React.Fragment, nil, {
					SpeedLabel = e("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = "Game Speed", TextColor3 = Color3.new(0.8,0.8,0.8), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }),
					SpeedBtns = e("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 2 }, {
						Layout = e("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }),
						B1 = e("TextButton", { Size = UDim2.new(0, 45, 1, 0), Text = "1x", BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.new(1,1,1), [React.Event.Activated] = function() ReplicatedStorage.DebugSetTimeScale:FireServer(1.0) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						B2 = e("TextButton", { Size = UDim2.new(0, 45, 1, 0), Text = "2x", BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.new(1,1,1), [React.Event.Activated] = function() ReplicatedStorage.DebugSetTimeScale:FireServer(2.0) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						B5 = e("TextButton", { Size = UDim2.new(0, 45, 1, 0), Text = "5x", BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.new(1,1,1), [React.Event.Activated] = function() ReplicatedStorage.DebugSetTimeScale:FireServer(5.0) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
					}),
					
					JumpLabel = e("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = "Stage Jump", TextColor3 = Color3.new(0.8,0.8,0.8), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3 }),
					JumpRow = e("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 4 }, {
						Layout = e("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }),
						Input = e("TextBox", {
							Size = UDim2.new(0, 80, 1, 0),
							Text = stageInput,
							PlaceholderText = "Stage #",
							BackgroundColor3 = Color3.fromRGB(20, 20, 20),
							TextColor3 = Color3.new(1,1,1),
							ClearTextOnFocus = false,
							[React.Change.Text] = function(rbx) setStageInput(rbx.Text) end
						}, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						GoBtn = e("TextButton", {
							Size = UDim2.new(0, 60, 1, 0),
							Text = "Jump",
							BackgroundColor3 = Color3.fromRGB(150, 40, 40),
							TextColor3 = Color3.new(1,1,1),
							Font = Enum.Font.GothamBold,
							[React.Event.Activated] = function()
								local num = tonumber(stageInput)
								if num then ReplicatedStorage.DebugJumpStage:FireServer(num) end
							end
						}, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) })
					})
				}) or nil,

				-- Spawner 탭 내용
				SpawnerPanel = activeTab == "Spawner" and e(React.Fragment, nil, {
					RarityLabel = e("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = "Rarity: " .. selectedRarity, TextColor3 = Color3.new(0.8,0.8,0.8), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }),
					RarityBtns = e("Frame", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, LayoutOrder = 2 }, {
						Layout = e("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }),
						e("TextButton", { Size = UDim2.new(0, 40, 1, 0), Text = "C", BackgroundColor3 = selectedRarity == "Common" and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedRarity("Common") end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0, 40, 1, 0), Text = "R", BackgroundColor3 = selectedRarity == "Rare" and Color3.new(0.2,0.4,1) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedRarity("Rare") end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0, 40, 1, 0), Text = "E", BackgroundColor3 = selectedRarity == "Epic" and Color3.new(0.6,0.2,1) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedRarity("Epic") end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0, 40, 1, 0), Text = "L", BackgroundColor3 = selectedRarity == "Legend" and Color3.new(1,0.8,0.2) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedRarity("Legend") end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
					}),

					IndexLabel = e("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = "Type: " .. selectedSubIndex, TextColor3 = Color3.new(0.8,0.8,0.8), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3 }),
					IndexBtns = e("Frame", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, LayoutOrder = 4 }, {
						Layout = e("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }),
						e("TextButton", { Size = UDim2.new(0.2, -3, 1, 0), Text = "1", BackgroundColor3 = selectedSubIndex == 1 and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedSubIndex(1) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0.2, -3, 1, 0), Text = "2", BackgroundColor3 = selectedSubIndex == 2 and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedSubIndex(2) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0.2, -3, 1, 0), Text = "3", BackgroundColor3 = selectedSubIndex == 3 and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedSubIndex(3) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0.2, -3, 1, 0), Text = "4", BackgroundColor3 = selectedSubIndex == 4 and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedSubIndex(4) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						e("TextButton", { Size = UDim2.new(0.2, -3, 1, 0), Text = "5", BackgroundColor3 = selectedSubIndex == 5 and Color3.new(0.5,0.5,0.5) or Color3.new(0.2,0.2,0.2), [React.Event.Activated] = function() setSelectedSubIndex(5) end }, { e("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
					}),

					SpawnBtn = e("TextButton", {
						Size = UDim2.new(1, 0, 0, 30),
						Text = "Spawn Hero",
						BackgroundColor3 = Color3.fromRGB(60, 160, 60),
						TextColor3 = Color3.new(1,1,1),
						Font = Enum.Font.GothamBold,
						LayoutOrder = 5,
						[React.Event.Activated] = onSummon
					}, { e("UICorner", { CornerRadius = UDim.new(0, 6) }) })
				}) or nil,
			})
		})
	})
end

return DebugMenu

--[[
	디버그 UI (속도/스테이지 제어)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local debugSetTimeScale = ReplicatedStorage:WaitForChild("DebugSetTimeScale")
local debugJumpStage = ReplicatedStorage:WaitForChild("DebugJumpStage")

local e = React.createElement

local function DebugUI()
	local stageInput, setStageInput = React.useState("")

	return e("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 100,
	}, {
		MainFrame = e("Frame", {
			Size = UDim2.new(0, 200, 0, 120),
			Position = UDim2.new(0, 10, 0.5, -60),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			UIListLayout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			Title = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "[Debug Control]",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				LayoutOrder = 1,
			}),

			SpeedControls = e("Frame", {
				Size = UDim2.new(1, -20, 0, 30),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),

				Btn1x = e("TextButton", {
					Size = UDim2.new(0, 40, 1, 0),
					Text = "1x",
					BackgroundColor3 = Color3.fromRGB(70, 70, 70),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					LayoutOrder = 1,
					[React.Event.Activated] = function()
						debugSetTimeScale:FireServer(1.0)
					end,
				}),
				
				Btn2x = e("TextButton", {
					Size = UDim2.new(0, 40, 1, 0),
					Text = "2x",
					BackgroundColor3 = Color3.fromRGB(70, 70, 70),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						debugSetTimeScale:FireServer(2.0)
					end,
				}),

				Btn5x = e("TextButton", {
					Size = UDim2.new(0, 40, 1, 0),
					Text = "5x",
					BackgroundColor3 = Color3.fromRGB(70, 70, 70),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					LayoutOrder = 3,
					[React.Event.Activated] = function()
						debugSetTimeScale:FireServer(5.0)
					end,
				}),
			}),

			JumpControls = e("Frame", {
				Size = UDim2.new(1, -20, 0, 30),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),

				InputBox = e("TextBox", {
					Size = UDim2.new(0, 60, 1, 0),
					Text = stageInput,
					PlaceholderText = "Stage",
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					LayoutOrder = 1,
					ClearTextOnFocus = false,
					[React.Change.Text] = function(rbx)
						setStageInput(rbx.Text)
					end,
				}),

				JumpBtn = e("TextButton", {
					Size = UDim2.new(0, 60, 1, 0),
					Text = "Jump",
					BackgroundColor3 = Color3.fromRGB(200, 50, 50),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						local num = tonumber(stageInput)
						if num then
							debugJumpStage:FireServer(num)
						end
					end,
				}),
			}),
		}),
	})
end

return DebugUI

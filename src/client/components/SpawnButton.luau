--[[
	SpawnButton - 몬스터 웨이브 시작 버튼
	React 함수형 컴포넌트
	클릭 시 서버에 RemoteEvent 발사
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function SpawnButton()
	local isHovered, setIsHovered = React.useState(false)
	local isDisabled, setIsDisabled = React.useState(false)

	local function onActivated()
		if isDisabled then
			return
		end

		local startWaveEvent = ReplicatedStorage:FindFirstChild("StartWaveEvent")
		if startWaveEvent then
			startWaveEvent:FireServer()
			setIsDisabled(true)

			-- 3초 후 버튼 다시 활성화
			task.spawn(function()
				task.wait(3)
				setIsDisabled(false)
			end)
		else
			warn("[SpawnButton] StartWaveEvent를 찾을 수 없습니다!")
		end
	end

	local buttonColor
	if isDisabled then
		buttonColor = Color3.fromRGB(80, 80, 80)
	elseif isHovered then
		buttonColor = Color3.fromRGB(255, 80, 80)
	else
		buttonColor = Color3.fromRGB(220, 50, 50)
	end

	return e("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		Button = e("TextButton", {
			Text = if isDisabled then "In Progress..." else "⚔ Start Wave",
			Size = UDim2.new(0, 240, 0, 64),
			Position = UDim2.new(0.5, 0, 0.9, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = buttonColor,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 22,
			BorderSizePixel = 0,
			AutoButtonColor = false,

			[React.Event.Activated] = onActivated,

			[React.Event.MouseEnter] = function()
				if not isDisabled then
					setIsHovered(true)
				end
			end,

			[React.Event.MouseLeave] = function()
				setIsHovered(false)
			end,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 2,
				Transparency = 0.6,
			}),
		}),
	})
end

return SpawnButton

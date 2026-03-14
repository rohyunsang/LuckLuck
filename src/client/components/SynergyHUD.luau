--[[
	SynergyHUD — 활성화된 시너지를 화면 왼쪽에 표시하는 UI
	React 컴포넌트
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function SynergyHUD()
	local activeSynergies, setActiveSynergies = React.useState({})

	React.useEffect(function()
		local player = Players.LocalPlayer
		
		local function update()
			local data = player:GetAttribute("ActiveSynergies")
			if data then
				local success, decoded = pcall(function()
					return HttpService:JSONDecode(data)
				end)
				if success then
					setActiveSynergies(decoded)
				end
			else
				setActiveSynergies({})
			end
		end

		update()
		local connection = player:GetAttributeChangedSignal("ActiveSynergies"):Connect(update)

		return function()
			connection:Disconnect()
		end
	end, {})

	if #activeSynergies == 0 then
		return nil
	end

	local children = {
		Layout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		})
	}

	for i, synergy in ipairs(activeSynergies) do
		children["Synergy_" .. i] = e("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(0, 200, 0, 50),
			BackgroundColor3 = if synergy.Type == "Rarity" then Color3.fromRGB(60, 40, 80) else Color3.fromRGB(40, 60, 40),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Stroke = e("UIStroke", {
				Color = if synergy.Type == "Rarity" then Color3.fromRGB(200, 100, 255) else Color3.fromRGB(100, 255, 100),
				Thickness = 1.5,
			}),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Title = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = synergy.Name,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = e("TextLabel", {
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = synergy.Desc,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		})
	end

	return e("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 5,
	}, {
		Container = e("Frame", {
			Size = UDim2.new(0, 220, 0, 0),
			Position = UDim2.new(0, 20, 0.4, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, children)
	})
end

return SynergyHUD

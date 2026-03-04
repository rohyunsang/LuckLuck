--[[
	클라이언트 진입점
	- React + ReactRoblox로 UI 마운트
	- SpawnButton + GameStatusHUD 렌더
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local SpawnButton = require(script.components.SpawnButton)
local GameStatusHUD = require(script.components.GameStatusHUD)
local HeroSummonUI = require(script.components.HeroSummonUI)
local DebugUI = require(script.components.DebugUI)

local e = React.createElement

-- 전체 UI를 하나의 Fragment로 묶음
local function App()
	return e(React.Fragment, nil, {
		StatusHUD = e(GameStatusHUD),
		SpawnBtn = e(SpawnButton),
		SummonUI = e(HeroSummonUI),
		DebugPanel = e(DebugUI),
	})
end

-- PlayerGui에 React 트리 마운트
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(Instance.new("Folder"))
root:render(ReactRoblox.createPortal(
	e(App),
	playerGui
))

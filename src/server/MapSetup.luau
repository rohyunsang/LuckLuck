--[[
	MapSetup
	- 서버 시작 시 맵 구조를 초기화하거나 자동 생성하는 스크립트
	- HeroZone(영웅 스폰 구역) 생성
]]

local MapSetup = {}

function MapSetup.init()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = workspace
	end

	-- 영웅 배치 영역 (HeroZone) 파트 생성
	local heroZone = mapFolder:FindFirstChild("HeroZone")
	if not heroZone then
		heroZone = Instance.new("Part")
		heroZone.Name = "HeroZone"
		-- 크기 (가로 100, 두께 1, 세로 100)
		heroZone.Size = Vector3.new(100, 1, 100)
		heroZone.Position = Vector3.new(0, 0, 0)
		heroZone.Anchored = true
		heroZone.CanCollide = true
		heroZone.Material = Enum.Material.Grass
		heroZone.Color = Color3.fromRGB(50, 100, 50)
		heroZone.Parent = mapFolder

		-- Zone이라는 것을 눈에 띄게 하기 위해 테두리 선이나 투명도 조정 가능
		-- heroZone.Transparency = 0.5
	end

	print("[MapSetup] HeroZone 영역 준비 완료.")
end

return MapSetup

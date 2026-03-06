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

	-- 15칸 영웅 배치 영역 생성 (가로 5줄, 세로 3줄 형태)
	-- 기존 단일 HeroZone 대신 GridZone_1 부터 GridZone_15 가 생성됨
	local originX = -20 -- 시작 X좌표 (맵 형태에 맞춰 조정 가능)
	local originZ = 0   -- 시작 Z좌표
	local spacingX = 10 -- 각 칸의 X 간격 (크기 9 + 여백 1)
	local spacingZ = 10 -- 각 칸의 Z 간격

	local function getGridName(index: number) return "GridZone_" .. index end

	for i = 1, 15 do
		local gridName = getGridName(i)
		local gridPart = mapFolder:FindFirstChild(gridName)
		
		if not gridPart then
			gridPart = Instance.new("Part")
			gridPart.Name = gridName
			gridPart.Size = Vector3.new(9, 0.5, 9) -- 한 칸의 물리적 크기
			
			-- 5x3 배치 로직 (1~5번은 1열, 6~10번은 2열, ...)
			-- 1번 칸이 제일 왼쪽 상단이 되도록 계산
			local col = (i - 1) % 5
			local row = math.floor((i - 1) / 5)
			
			gridPart.Position = Vector3.new(originX + (col * spacingX), 0, originZ + (row * spacingZ))
			gridPart.Anchored = true
			gridPart.CanCollide = true
			gridPart.Material = Enum.Material.Grass
			
			-- 시각적 효과 (바둑판 형태)
			if (row + col) % 2 == 0 then
				gridPart.Color = Color3.fromRGB(50, 120, 50)
			else
				gridPart.Color = Color3.fromRGB(40, 100, 40)
			end
			
			gridPart.Parent = mapFolder
		end
	end

	print("[MapSetup] 15칸 HeroGrid. 격자 영역 준비 완료.")
end

return MapSetup

--[[
	MonsterSpawner
	- MonsterConfig 기반으로 몬스터 Part 생성
	- 필드 최대 100마리 상한
	- 스폰 위치: Workspace.Map.SpawnPoint
	- 생성 후 MonsterMovement에 등록
	- 체력바 BillboardGui 생성
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonsterConfig = require(ReplicatedStorage.Shared.MonsterConfig)
local MonsterMovement = require(script.Parent.MonsterMovement)

local MonsterSpawner = {}

local MAX_FIELD_MONSTERS = 100

-- 몬스터 컨테이너 폴더 (런타임에 생성)
local monstersFolder: Folder = nil

function MonsterSpawner._getMonstersFolder(): Folder
	if not monstersFolder or not monstersFolder.Parent then
		monstersFolder = Instance.new("Folder")
		monstersFolder.Name = "Monsters"
		monstersFolder.Parent = workspace
	end
	return monstersFolder
end

-- 현재 필드 몬스터 수
function MonsterSpawner.getFieldCount(): number
	local folder = MonsterSpawner._getMonstersFolder()
	return #folder:GetChildren()
end

-- 스폰 포인트 위치 가져오기
function MonsterSpawner._getSpawnPosition(): Vector3
	local map = workspace:FindFirstChild("Map")
	local spawnPoint = map and map:FindFirstChild("SpawnPoint")

	if spawnPoint and spawnPoint:IsA("BasePart") then
		return spawnPoint.Position
	end

	warn("[MonsterSpawner] SpawnPoint를 찾을 수 없습니다. 기본 위치 사용")
	return Vector3.new(0, 5, -50)
end

-- 체력바 BillboardGui 생성
function MonsterSpawner._createHealthBar(monster: BasePart, config: any)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 60, 0, 10)
	billboard.StudsOffset = Vector3.new(0, config.Size.Y / 2 + 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	billboard.Parent = monster

	-- 배경 (어두운 바)
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = bg

	-- 체력 바 (채움)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0) -- 100%에서 시작
	fill.BackgroundColor3 = if config.IsBoss
		then Color3.fromRGB(255, 50, 50) -- 보스: 빨간색
		else Color3.fromRGB(50, 220, 50) -- 일반: 초록색
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	-- 보스는 체력바 크게
	if config.IsBoss then
		billboard.Size = UDim2.new(0, 120, 0, 16)
		billboard.StudsOffset = Vector3.new(0, config.Size.Y / 2 + 3, 0)

		-- 보스 이름 표시
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "BossName"
		nameLabel.Size = UDim2.new(1, 0, 0, 18)
		nameLabel.Position = UDim2.new(0, 0, -2, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = config.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextStrokeTransparency = 0.3
		nameLabel.Parent = billboard
	end

	-- Health 변경 시 바 업데이트 (서버에서 직접 갱신)
	monster:GetAttributeChangedSignal("Health"):Connect(function()
		local health = monster:GetAttribute("Health") or 0
		local maxHealth = monster:GetAttribute("MaxHealth") or 1
		local ratio = math.clamp(health / maxHealth, 0, 1)

		fill.Size = UDim2.new(ratio, 0, 1, 0)

		-- 체력에 따라 색 변경 (일반 몬스터만)
		if not (monster:GetAttribute("IsBoss")) then
			if ratio > 0.5 then
				fill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
			elseif ratio > 0.25 then
				fill.BackgroundColor3 = Color3.fromRGB(220, 220, 50)
			else
				fill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
			end
		end
	end)
end

-- 단일 몬스터 생성
function MonsterSpawner.spawnMonster(monsterType: string): BasePart?
	-- 필드 상한 체크
	if MonsterSpawner.getFieldCount() >= MAX_FIELD_MONSTERS then
		warn("[MonsterSpawner] 필드 상한 " .. MAX_FIELD_MONSTERS .. "마리 도달! 스폰 대기")
		-- 공간이 나올 때까지 대기
		while MonsterSpawner.getFieldCount() >= MAX_FIELD_MONSTERS do
			task.wait(0.5)
		end
	end

	local config = MonsterConfig[monsterType]
	if not config then
		warn("[MonsterSpawner] 알 수 없는 몬스터 타입: " .. monsterType)
		return nil
	end

	local monster = Instance.new("Part")
	monster.Name = config.Name
	monster.Size = config.Size
	monster.Color = config.Color
	monster.Position = MonsterSpawner._getSpawnPosition()
	monster.Anchored = true
	monster.CanCollide = false

	-- 스탯 Attribute 설정
	monster:SetAttribute("Health", config.Health)
	monster:SetAttribute("MaxHealth", config.Health)
	monster:SetAttribute("Speed", config.Speed)
	monster:SetAttribute("Reward", config.Reward)
	monster:SetAttribute("MonsterType", monsterType)
	monster:SetAttribute("IsBoss", config.IsBoss)

	-- 체력바 추가
	MonsterSpawner._createHealthBar(monster, config)

	monster.Parent = MonsterSpawner._getMonstersFolder()

	-- 이동 시스템에 등록
	MonsterMovement.register(monster)

	return monster
end

-- 웨이브 데이터 기반 몬스터 스폰
function MonsterSpawner.spawnWave(waveData)
	local spawnList = {}

	-- 스폰 리스트 펼치기
	for _, entry in waveData.Monsters do
		for _ = 1, entry.Count do
			table.insert(spawnList, entry.Type)
		end
	end

	-- SpawnInterval 간격으로 스폰
	for i, monsterType in spawnList do
		MonsterSpawner.spawnMonster(monsterType)
		print("[MonsterSpawner] 스폰: " .. monsterType .. " (" .. i .. "/" .. #spawnList .. ")")

		if i < #spawnList and waveData.SpawnInterval > 0 then
			task.wait(waveData.SpawnInterval)
		end
	end
end

return MonsterSpawner

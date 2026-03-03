--[[
	몬스터 종류별 기본 스탯 정의
	Health: 체력
	Speed: 이동 속도 (studs/sec)
	Reward: 처치 보상
	Size: 몬스터 Part 크기
	Color: 몬스터 Part 색상
	IsBoss: 보스 여부
]]

local MonsterConfig = {
	-- 일반 몬스터
	Slime = {
		Name = "슬라임",
		Health = 100,
		Speed = 12,
		Reward = 2,
		Size = Vector3.new(3, 3, 3),
		Color = Color3.fromRGB(80, 200, 80),
		IsBoss = false,
	},

	Goblin = {
		Name = "고블린",
		Health = 200,
		Speed = 16,
		Reward = 2,
		Size = Vector3.new(3, 4, 3),
		Color = Color3.fromRGB(180, 100, 50),
		IsBoss = false,
	},

	Golem = {
		Name = "골렘",
		Health = 500,
		Speed = 8,
		Reward = 2,
		Size = Vector3.new(5, 6, 5),
		Color = Color3.fromRGB(120, 120, 140),
		IsBoss = false,
	},

	Skeleton = {
		Name = "스켈레톤",
		Health = 300,
		Speed = 14,
		Reward = 2,
		Size = Vector3.new(3, 5, 3),
		Color = Color3.fromRGB(220, 220, 200),
		IsBoss = false,
	},

	DarkKnight = {
		Name = "다크 나이트",
		Health = 600,
		Speed = 10,
		Reward = 2,
		Size = Vector3.new(4, 5, 4),
		Color = Color3.fromRGB(40, 40, 60),
		IsBoss = false,
	},

	-- 보스 몬스터
	BossOgre = {
		Name = "👑 오우거 킹",
		Health = 3000,
		Speed = 6,
		Reward = 200,
		Size = Vector3.new(8, 10, 8),
		Color = Color3.fromRGB(100, 60, 30),
		IsBoss = true,
	},

	BossDragon = {
		Name = "👑 드래곤",
		Health = 8000,
		Speed = 5,
		Reward = 500,
		Size = Vector3.new(10, 12, 10),
		Color = Color3.fromRGB(180, 30, 30),
		IsBoss = true,
	},

	BossLich = {
		Name = "👑 리치",
		Health = 15000,
		Speed = 4,
		Reward = 800,
		Size = Vector3.new(8, 14, 8),
		Color = Color3.fromRGB(80, 0, 120),
		IsBoss = true,
	},

	BossDemonLord = {
		Name = "👑 데몬 로드",
		Health = 25000,
		Speed = 5,
		Reward = 1200,
		Size = Vector3.new(12, 16, 12),
		Color = Color3.fromRGB(150, 10, 10),
		IsBoss = true,
	},

	BossFinalGod = {
		Name = "👑 파멸의 신",
		Health = 50000,
		Speed = 6,
		Reward = 3000,
		Size = Vector3.new(14, 20, 14),
		Color = Color3.fromRGB(20, 20, 20),
		IsBoss = true,
	},
}

return MonsterConfig

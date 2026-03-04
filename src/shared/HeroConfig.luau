--[[
	영웅 소환 설정 데이터
]]

local HeroConfig = {
	SummonCost = 10,       -- 영웅 소환 비용
	UpgradeCost = 10,      -- 영웅 소환 확률 증가 비용 (임시 고정값)
	MaxProbLevel = 10,     -- 최대 확률 레벨
}

-- 확률표 (단위: 백분율 %)
-- Common(일반), Rare(희귀), Epic(영웅), Legend(전설)
HeroConfig.Probabilities = {
	[1]  = { Common = 90.0, Rare = 9.0, Epic = 0.9, Legend = 0.1 },
	[2]  = { Common = 87.0, Rare = 10.5, Epic = 2.0, Legend = 0.5 },
	[3]  = { Common = 84.0, Rare = 12.0, Epic = 3.2, Legend = 0.8 },
	[4]  = { Common = 81.0, Rare = 13.5, Epic = 4.4, Legend = 1.1 },
	[5]  = { Common = 77.0, Rare = 15.0, Epic = 6.0, Legend = 2.0 },
	[6]  = { Common = 74.0, Rare = 16.0, Epic = 7.0, Legend = 3.0 },
	[7]  = { Common = 72.0, Rare = 17.5, Epic = 7.5, Legend = 3.0 },
	[8]  = { Common = 71.0, Rare = 18.5, Epic = 8.0, Legend = 2.5 }, -- 9/10레벨 보간
	[9]  = { Common = 70.5, Rare = 19.5, Epic = 8.5, Legend = 1.5 },
	[10] = { Common = 70.0, Rare = 20.0, Epic = 9.0, Legend = 1.0 },
}

-- 렌더링용 외형 (색상)
HeroConfig.Visuals = {
	Common = { Color = Color3.fromRGB(150, 150, 150) },     -- 회색
	Rare   = { Color = Color3.fromRGB(50, 100, 255) },      -- 파란색
	Epic   = { Color = Color3.fromRGB(150, 50, 255) },      -- 보라색
	Legend = { Color = Color3.fromRGB(255, 200, 50) },      -- 노란색(금색)
}

return HeroConfig

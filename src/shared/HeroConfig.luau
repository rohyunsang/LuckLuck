--[[
	영웅 소환 설정 데이터
]]

local HeroConfig = {
	SummonCost = 10,       -- 영웅 소환 비용
	UpgradeCost = 10,      -- 영웅 소환 확률 증가 비용 (임시 고정값)
	MaxProbLevel = 10,     -- 최대 확률 레벨
}

-- 영웅 매각 시 반환하는 골드
HeroConfig.SellPrices = {
	Common = 5,
	Rare = 15,
	Epic = 50,
	Legend = 150,
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

-- 렌더링용 외형 (색상 및 모양 패턴)
-- 패턴 1: 직사각형(Block)
-- 패턴 2: 동그라미(Ball)
-- 패턴 3: 원기둥(Cylinder)
-- 패턴 4: 세모(Wedge)
-- 패턴 5: 네모+동그라미 (Composite)
HeroConfig.Visuals = {
	Common = {
		[1] = { Color = Color3.fromRGB(150, 150, 150), Shape = Enum.PartType.Block },
		[2] = { Color = Color3.fromRGB(150, 150, 150), Shape = Enum.PartType.Ball },
		[3] = { Color = Color3.fromRGB(150, 150, 150), Shape = Enum.PartType.Cylinder },
		[4] = { Color = Color3.fromRGB(150, 150, 150), Shape = "Wedge" },
		[5] = { Color = Color3.fromRGB(150, 150, 150), Composite = true },
	},
	Rare = {
		[1] = { Color = Color3.fromRGB(50, 100, 255), Shape = Enum.PartType.Block },
		[2] = { Color = Color3.fromRGB(50, 100, 255), Shape = Enum.PartType.Ball },
		[3] = { Color = Color3.fromRGB(50, 100, 255), Shape = Enum.PartType.Cylinder },
		[4] = { Color = Color3.fromRGB(50, 100, 255), Shape = "Wedge" },
		[5] = { Color = Color3.fromRGB(50, 100, 255), Composite = true },
	},
	Epic = {
		[1] = { Color = Color3.fromRGB(150, 50, 255), Shape = Enum.PartType.Block },
		[2] = { Color = Color3.fromRGB(150, 50, 255), Shape = Enum.PartType.Ball },
		[3] = { Color = Color3.fromRGB(150, 50, 255), Shape = Enum.PartType.Cylinder },
		[4] = { Color = Color3.fromRGB(150, 50, 255), Shape = "Wedge" },
		[5] = { Color = Color3.fromRGB(150, 50, 255), Composite = true },
	},
	Legend = {
		[1] = { Color = Color3.fromRGB(255, 200, 50), Shape = Enum.PartType.Block },
		[2] = { Color = Color3.fromRGB(255, 200, 50), Shape = Enum.PartType.Ball },
		[3] = { Color = Color3.fromRGB(255, 200, 50), Shape = Enum.PartType.Cylinder },
		[4] = { Color = Color3.fromRGB(255, 200, 50), Shape = "Wedge" },
		[5] = { Color = Color3.fromRGB(255, 200, 50), Composite = true },
	},
}

-- 등급별 데미지 배수
HeroConfig.RarityMultiplier = {
	Common = 1,
	Rare = 3,
	Epic = 10,
	Legend = 30,
}

-- 공격 타입별 전투 스탯
-- 1: 근접 단일 (Block)
-- 2: 근접 범위 (Ball)
-- 3: 원거리 단일 (Cylinder)
-- 4: 원거리 범위 (Wedge)
-- 5: 스턴 (Composite)
HeroConfig.CombatStats = {
	[1] = { Type = "MeleeSingle",   Range = 15, Cooldown = 1.0, BaseDamage = 20, SplashRadius = 0, StunDuration = 0 },
	[2] = { Type = "MeleeSplash",   Range = 15, Cooldown = 1.5, BaseDamage = 15, SplashRadius = 8, StunDuration = 0 },
	[3] = { Type = "RangedSingle",  Range = 40, Cooldown = 1.0, BaseDamage = 15, SplashRadius = 0, StunDuration = 0 },
	[4] = { Type = "RangedSplash",  Range = 40, Cooldown = 2.0, BaseDamage = 10, SplashRadius = 10, StunDuration = 0 },
	[5] = { Type = "StunAttack",    Range = 25, Cooldown = 3.0, BaseDamage = 5,  SplashRadius = 0, StunDuration = 1.5 },
}

-- 시너지 시스템 설정
HeroConfig.Synergies = {
	-- 공격 타입별 시너지 (동일 타입 N마리 배치 시)
	Types = {
		["Melee"] = {
			Name = "Melee Warriors",
			Desc = "20% increased damage for melee heroes.",
			Requirement = 3, -- 3마리 이상
			TargetTypes = { "MeleeSingle", "MeleeSplash" },
			Buff = { DamageMultiplier = 1.2 }
		},
		["Ranged"] = {
			Name = "Ranged Archers",
			Desc = "15% increased range for ranged heroes.",
			Requirement = 3,
			TargetTypes = { "RangedSingle", "RangedSplash" },
			Buff = { RangeMultiplier = 1.15 }
		},
		["Stun"] = {
			Name = "CC Experts",
			Desc = "20% reduced cooldown for stun heroes.",
			Requirement = 2,
			TargetTypes = { "StunAttack" },
			Buff = { CooldownMultiplier = 0.8 }
		},
	},
	-- 등급별 시너지 (동일 등급 N마리 배치 시)
	Rarities = {
		["Rare"] = {
			Name = "Rare Collection",
			Desc = "10% increased damage for all Rare heroes.",
			Requirement = 5,
			Buff = { DamageMultiplier = 1.1 }
		},
		["Epic"] = {
			Name = "Epic Party",
			Desc = "15% increased damage for all Epic heroes.",
			Requirement = 3,
			Buff = { DamageMultiplier = 1.15 }
		}
	}
}

return HeroConfig

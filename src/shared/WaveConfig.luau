--[[
	웨이브(스테이지) 구성 데이터 — 50스테이지 자동 생성

	규칙:
	- 일반 스테이지: 몬스터 20마리
	- 보스 스테이지 (10, 20, 30, 40, 50): 보스 1마리만 등장
	- 보스는 30초 안에 처치해야 클리어
	- 스테이지가 올라갈수록 더 강한 몬스터 등장
	- 필드 최대 몬스터 수: 100마리 (MonsterSpawner에서 관리)
]]

-- 스테이지 구간별 일반 몬스터 풀
local NORMAL_POOLS = {
	-- 1~9: 슬라임 위주
	{ From = 1,  To = 9,  Pool = { "Slime", "Slime", "Slime", "Goblin" } },
	-- 11~19: 고블린, 슬라임
	{ From = 11, To = 19, Pool = { "Slime", "Goblin", "Goblin", "Skeleton" } },
	-- 21~29: 스켈레톤 합류
	{ From = 21, To = 29, Pool = { "Goblin", "Skeleton", "Skeleton", "Golem" } },
	-- 31~39: 골렘 합류
	{ From = 31, To = 39, Pool = { "Skeleton", "Golem", "Golem", "DarkKnight" } },
	-- 41~49: 다크나이트 위주
	{ From = 41, To = 49, Pool = { "Golem", "DarkKnight", "DarkKnight", "DarkKnight" } },
}

-- 보스 스테이지 매핑
local BOSS_MAP = {
	[10] = "BossOgre",
	[20] = "BossDragon",
	[30] = "BossLich",
	[40] = "BossDemonLord",
	[50] = "BossFinalGod",
}

-- 스테이지에 맞는 일반 몬스터 풀 가져오기
local function getPoolForStage(stage: number): { string }
	for _, entry in NORMAL_POOLS do
		if stage >= entry.From and stage <= entry.To then
			return entry.Pool
		end
	end
	-- fallback
	return { "Slime" }
end

-- 스테이지에 맞는 단일 몬스터 타입 결정
local function getSingleMonsterForStage(stage: number): string
	local pool = getPoolForStage(stage)
	return pool[((stage - 1) % #pool) + 1]
end

---------------------------------------------
-- 50스테이지 데이터 생성
---------------------------------------------
local WaveConfig = {}

local MONSTERS_PER_NORMAL_STAGE = 20
local BOSS_TIME_LIMIT = 30 -- 보스 제한 시간 (초)

for stage = 1, 50 do
	local isBoss = BOSS_MAP[stage] ~= nil

	if isBoss then
		-- 보스 스테이지
		WaveConfig[stage] = {
			IsBoss = true,
			BossTimeLimit = BOSS_TIME_LIMIT,
			Monsters = {
				{ Type = BOSS_MAP[stage], Count = 1 },
			},
			SpawnInterval = 0,
			RestTime = 8,
		}
	else
		-- 일반 스테이지
		local chosenType = getSingleMonsterForStage(stage)
		-- 스테이지가 올라갈수록 스폰 간격 줄어듦 (기존 대비 2배 속도)
		local spawnInterval = math.max(0.15, 0.75 - (stage * 0.01))

		WaveConfig[stage] = {
			IsBoss = false,
			BossTimeLimit = 0,
			Monsters = {
				{ Type = chosenType, Count = MONSTERS_PER_NORMAL_STAGE }
			},
			SpawnInterval = spawnInterval,
			RestTime = 5,
		}
	end
end

return WaveConfig

--[[
	DataManager
	- HttpService를 통해 스프레드시트 CSV 데이터를 가져와 WaveConfig에 덮어씀
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CSVParser = require(script.Parent.CSVParser)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)

local DataManager = {}

-- 구글 시트 게시 URL (CSV 출력)
local SHEET_URL = "https://docs.google.com/spreadsheets/d/1BSVtEQKjORT2MWn6fAKAVbpfMZwYanygFWZOrTN5JV4/gviz/tq?tqx=out:csv"

function DataManager.loadSheetData()
	print("[DataManager] 스프레드시트 데이터 다운로드 요청...")

	local success, result = pcall(function()
		return HttpService:GetAsync(SHEET_URL)
	end)

	if not success then
		warn("[DataManager] 스프레드시트 데이터 가져오기 실패: " .. tostring(result))
		warn("[DataManager] 스튜디오 속성(Game Settings -> Security)에서 'Allow HTTP Requests'가 켜져 있는지 확인해주세요.")
		return false
	end

	-- 파싱
	local rows = CSVParser.parse(result)
	print("[DataManager] 성공적으로 " .. #rows .. "행의 데이터를 가져왔습니다. 적용을 시작합니다.")

	-- WaveConfig 초기화 (기존 1~50 스테이지를 날리고 새로 그림)
	table.clear(WaveConfig)

	for _, row in rows do
		local stageStr = row["Stage"]
		if not stageStr or stageStr == "" then continue end

		local stageNum = tonumber(stageStr)
		if not stageNum then continue end

		local isBoss = row["StageType"] == "Boss"
		
		-- 몬스터 풀 설정
		local monsters = {}
		
		if isBoss then
			local bossId = row["BossId"] or ""
			if bossId == "ogre_king" then bossId = "BossOgre"
			elseif bossId == "dragon" then bossId = "BossDragon"
			elseif bossId == "lich" then bossId = "BossLich"
			elseif bossId == "demon_lord" then bossId = "BossDemonLord"
			elseif bossId == "final_god" then bossId = "BossFinalGod"
			else bossId = "BossOgre" -- fallback
			end
			
			local countStr = row["SpawnCount"]
			local c = tonumber(countStr) or 1
			table.insert(monsters, { Type = bossId, Count = c })
		else
			-- 일반 타입들
			local function addM(typeKey: string, countStr: string)
				local c = tonumber(countStr) or 0
				if c > 0 then
					table.insert(monsters, { Type = typeKey, Count = c })
				end
			end
			
			addM("Slime", row["Slime"])
			addM("Goblin", row["Goblin"])
			addM("Skeleton", row["Skeleton"])
			addM("Golem", row["Golem"])
			addM("DarkKnight", row["DarkKnight"])
		end

		local timeLimitStr = row["TimeLimit"]
		WaveConfig[stageNum] = {
			IsBoss = isBoss,
			BossTimeLimit = isBoss and (tonumber(timeLimitStr) or 30) or 0,
			Monsters = monsters,
			SpawnInterval = isBoss and 0 or (math.max(0.15, 0.75 - (stageNum * 0.01))),
			RestTime = 5,
		}
	end

	print("[DataManager] WaveConfig.luau 를 구글 시트 데이터로 완전히 덮어썼습니다!")
	return true
end

return DataManager

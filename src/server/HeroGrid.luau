--[[
	HeroGrid
	- 플레이어별 15칸 영웅 배치 상태 추적 (어느 칸에 어떤 영웅이 몇 마리 있는지)
]]

local HeroGrid = {}

-- 구조: grids[player][index] = { Rarity = "Legend", Count = 2 }
local grids = {}

-- 특정 플레이어의 격자 데이터 초기화
function HeroGrid.initPlayerGrid(player: Player)
	grids[player] = {}
	for i = 1, 15 do
		grids[player][i] = nil -- 처음엔 모두 빈 칸
	end
end

-- 해당 플레이어의 총 영웅 마릿수 계산
function HeroGrid.getTotalHeroCount(player: Player): number
	if not grids[player] then return 0 end
	
	local total = 0
	for i = 1, 15 do
		if grids[player][i] then
			total += grids[player][i].Count
		end
	end
	return total
end

-- 빈 칸 찾기 (규칙: 제일 왼쪽 1번부터 탐색, 같은 등급이고 3마리 미만인 칸 또는 아예 비어있는 칸)
function HeroGrid.findAvailableGrid(player: Player, rarity: string): number?
	if not grids[player] then return nil end

	-- 1. 먼저 배치할 수 있는 기존 그룹 탐색
	for i = 1, 15 do
		local cell = grids[player][i]
		if cell and cell.Rarity == rarity and cell.Count < 3 then
			return i
		end
	end

	-- 2. 그룹에 넣을 수 없으면 완전히 비어있는 제일 왼쪽 칸 탐색
	for i = 1, 15 do
		if grids[player][i] == nil then
			return i
		end
	end

	-- 15칸이 모두 다른 종류로 꽉 차서 하나도 더 스폰될 수 없는 상태
	return nil
end

-- 격자에 영웅 기록 (추가 성공 시 현재 칸의 마릿수 반환)
function HeroGrid.addHeroToGrid(player: Player, index: number, rarity: string): number
	if not grids[player] then
		HeroGrid.initPlayerGrid(player)
	end

	local cell = grids[player][index]
	if not cell then
		grids[player][index] = { Rarity = rarity, Count = 1 }
		return 1
	end

	if cell.Rarity == rarity then
		cell.Count += 1
		return cell.Count
	end

	-- 로직 상 여기 오면 에러
	warn("[HeroGrid] 잘못된 등급이 들어가 있습니다!")
	return -1
end

-- 접속 종료 시 정리
game:GetService("Players").PlayerRemoving:Connect(function(player)
	grids[player] = nil
end)

return HeroGrid

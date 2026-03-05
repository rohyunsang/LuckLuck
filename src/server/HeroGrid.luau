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
function HeroGrid.findAvailableGrid(player: Player, rarity: string, subIndex: number): number?
	if not grids[player] then return nil end

	-- 1. 먼저 배치할 수 있는 기존 그룹 탐색 (Rarity와 SubIndex가 모두 같아야 함)
	for i = 1, 15 do
		local cell = grids[player][i]
		if cell and cell.Rarity == rarity and tonumber(cell.SubIndex) == tonumber(subIndex) and cell.Count < 3 then
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
function HeroGrid.addHeroToGrid(player: Player, index: number, rarity: string, subIndex: number): number
	if not grids[player] then
		HeroGrid.initPlayerGrid(player)
	end

	local cell = grids[player][index]
	if not cell then
		grids[player][index] = { Rarity = rarity, SubIndex = subIndex, Count = 1 }
		return 1
	end

	if cell.Rarity == rarity and tonumber(cell.SubIndex) == tonumber(subIndex) then
		cell.Count += 1
		return cell.Count
	end

	-- 로직 상 여기 오면 에러
	warn("[HeroGrid] 잘못된 등급 또는 SubIndex가 들어가 있습니다!")
	return -1
end

-- 합성 가능한 영웅 목록 반환 (같은 Rarity, 같은 SubIndex가 3마리 모인 GridIndex 목록)
function HeroGrid.getMergeableGrids(player: Player)
	local mergeables = {}
	if not grids[player] then return mergeables end

	for i = 1, 15 do
		local cell = grids[player][i]
		-- Legend는 합성 불가
		if cell and cell.Count >= 3 and cell.Rarity ~= "Legend" then
			table.insert(mergeables, {
				GridIndex = i,
				Rarity = cell.Rarity,
				SubIndex = cell.SubIndex
			})
		end
	end

	return mergeables
end

-- 격자에서 영웅 삭제 (합성 등에 사용)
function HeroGrid.removeHeroesFromGrid(player: Player, index: number, removeCount: number)
	if not grids[player] then return false end
	
	local cell = grids[player][index]
	if not cell then return false end

	if cell.Count >= removeCount then
		cell.Count -= removeCount
		if cell.Count <= 0 then
			grids[player][index] = nil
		end
		return true
	end
	
	return false
end

-- 격자에 영웅을 놓을 수 있는지 확인 (빈 칸이거나, 같은 등급/종류이면서 3마리 미만)
function HeroGrid.canPlaceHero(player: Player, index: number, rarity: string, subIndex: number): boolean
	if not grids[player] then return false end

	local cell = grids[player][index]
	-- 빈 칸이면 항상 허용
	if not cell then return true end

	-- 완전히 동일한 모델이면서 3마리 미만이면 허용
	if cell.Rarity == rarity and tonumber(cell.SubIndex) == tonumber(subIndex) and cell.Count < 3 then
		return true
	end

	return false
end

-- 격자에서 영웅 하나 꺼내기 (들기에 사용)
function HeroGrid.takeOutHeroFromGrid(player: Player, index: number)
	if not grids[player] then return nil end

	local cell = grids[player][index]
	if not cell then return nil end

	local currentRarity = cell.Rarity
	local currentSubIndex = cell.SubIndex

	-- 하나 빼오고, 0마리면 지우기
	cell.Count -= 1
	if cell.Count <= 0 then
		grids[player][index] = nil
	end

	return { Rarity = currentRarity, SubIndex = currentSubIndex }
end

-- 접속 종료 시 정리
game:GetService("Players").PlayerRemoving:Connect(function(player)
	grids[player] = nil
end)

return HeroGrid

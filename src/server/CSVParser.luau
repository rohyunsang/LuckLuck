--[[
	CSVParser
	- 간단한 CSV 파서 (문자열 -> 2차원 테이블/딕셔너리 변환)
]]

local CSVParser = {}

-- 한 줄의 CSV 라인을 콤마(,) 기준으로 분리하되, 따옴표("")로 감싸진 내부는 무시
local function splitCSVLine(line: string): {string}
	local result = {}
	local current = ""
	local inQuotes = false

	for i = 1, #line do
		local c = string.sub(line, i, i)
		if c == '"' then
			inQuotes = not inQuotes
		elseif c == ',' and not inQuotes then
			table.insert(result, current)
			current = ""
		else
			current = current .. c
		end
	end
	table.insert(result, current)
	return result
end

-- CSV 전체 텍스트를 파싱 (첫 줄은 Header로 간주)
function CSVParser.parse(csvText: string): { [number]: {[string]: string} }
	local rows = {}
	local lines = csvText:split("\n")

	if #lines == 0 then return {} end

	-- Header 추출
	local headers = splitCSVLine(lines[1])
	for i, header in headers do
		-- 양끝 따옴표나 불필요한 공백 제거
		headers[i] = header:gsub('^%s*"?', ''):gsub('"?%s*$', '')
	end

	-- 데이터 추출
	for i = 2, #lines do
		local line = lines[i]:gsub("\r", "") -- 개행 최적화
		if line == "" then continue end

		local cols = splitCSVLine(line)
		local rowData = {}

		for j, val in cols do
			-- 데이터 포맷 클리닝 (따옴표 등 제거)
			local cleanVal = val:gsub('^%s*"?', ''):gsub('"?%s*$', '')
			local h = headers[j]
			if h then
				rowData[h] = cleanVal
			end
		end

		table.insert(rows, rowData)
	end

	return rows
end

return CSVParser

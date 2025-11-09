--!strict
-- Pure-Luau Prettifier Skeleton
-- Features:
-- 1. Proper indentation for blocks (if, for, while, function, do, repeat, etc.)
-- 2. Align 'end', 'else', 'elseif', 'until'
-- 3. Space around operators
-- 4. Space after commas
-- 5. Remove trailing whitespace
-- 6. Table literal pretty-printing
-- 7. Multi-line function call formatting
-- 8. Comment formatting (indented correctly)
-- 9. Handle Luau-specific keywords (typeof, task.wait, local function, etc.)

local Prettifier = {}

-- Configurable options
Prettifier.config = {
	indent = 1,
	spacesAroundOperators = true,
	alignAssignments = false,
	removeTrailingWhitespace = true,
}

-- Keywords for blocks
local blockStartKeywords = {"if", "for", "while", "function", "repeat", "do"}
local blockEndKeywords = {"end", "until", "else", "elseif"}

-- Utilities
local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function startsWithAny(str, keywords)
	for _, kw:string in ipairs(keywords) do
		if str:match("^" .. kw .. "%f[%s%(]") then
			return true
		end
	end
	return false
end

local function endsWithAny(str, keywords)
	for _, kw:string in ipairs(keywords) do
		if str:match("^" .. kw .. "%f[%s]") then
			return true
		end
	end
	return false
end

local function spaceOperators(line)
	if true then return line end
	if not Prettifier.config.spacesAroundOperators then return line end
	local ops = {"+", "*",",", "/", "%%", "^", "==", "~=", "<=", ">=", "<", ">", "="}
	for _, op in ipairs(ops) do
		-- Escape % in replacement string
		local safeOp = op:gsub("%%", "%%%%")
		line = line:gsub("%s*" .. op:gsub("([^%w])","%%%1") .. "%s*", " " .. safeOp .. " ")
	end
	return line
end


-- Space after commas
local function spaceAfterCommas(line)
	return line:gsub(",%s*", ", ")
end

-- Table formatting (simple indentation)
local function formatTables(line, indentLevel:number)
	-- Very simple: add newline + indent after '{' and before '}'
	line = line:gsub("{", "{\n" .. string.rep(" ", Prettifier.config.indent * (indentLevel + 1)))
	line = line:gsub("}", "\n" .. string.rep(" ", Prettifier.config.indent * indentLevel) .. "}")
	return line
end

-- Format function calls over multiple lines if needed
local function formatFunctionCalls(line, indentLevel:number)
	-- naive: if a '(' has ',' after it, break args into multiple lines
	line = line:gsub("%(([^)]-,[^)]-)%)", function(args)
		local parts = {}
		for part in args:gmatch("[^,]+") do
			table.insert(parts, string.rep(" ", Prettifier.config.indent * (indentLevel + 1)) .. trim(part))
		end
		return "(\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep(" ", Prettifier.config.indent * indentLevel) .. ")"
	end)
	return line
end

-- Format comments
local function formatComments(line, indentLevel)
	line = line:gsub("(%-%-.*)", function(comment)
		return string.rep(" ", Prettifier.config.indent * indentLevel) .. comment
	end)
	return line
end

local function fixMethodCalls(line: string): string
		-- obj.method(obj, ...)
		line = line:gsub("([%w_]+)%.([%w_]+)%s*%(%s*%1%s*,", "%1:%2(")
		-- obj["method"](obj, ...)
		line = line:gsub("([%w_]+)%[%s*\"([%w_]+)\"%s*%]%s*%(%s*%1%s*,", "%1:%2(")
		-- obj.method(obj)
		line = line:gsub("([%w_]+)%.([%w_]+)%s*%(%s*%1%s*%)", "%1:%2()")
		-- obj["method"](obj)
		line = line:gsub("([%w_]+)%[%s*\"([%w_]+)\"%s*%]%s*%(%s*%1%s*%)", "%1:%2()")
	return line
end

-- Main formatting function
function Prettifier.format(code: string): string
	local result = {}
	local indentLevel = 0

	for line in code:gmatch("[^\n]*") do
		line = trim(line)

		-- Handle block ends first (so 'end' aligns correctly)
		if startsWithAny(line, {"end", "until", "else", "elseif"}) then
			indentLevel = math.max(0, indentLevel - 1)
		end
	line = fixMethodCalls(line)
		-- Format comments first
		line = formatComments(line, indentLevel)

		-- Space operators and commas
		line = spaceOperators(line)
		line = spaceAfterCommas(line)

		-- Table formatting
		line = formatTables(line, indentLevel)

		-- Function call formatting
		line = formatFunctionCalls(line, indentLevel)
	
		-- Apply indentation (unless it's a comment line, which was already handled)
		if not line:match("^%s*%-%-") then
			line = string.rep(" ", Prettifier.config.indent * indentLevel) .. line
		end

		-- Add line to result
		table.insert(result, line)

		-- Adjust indent for block start keywords
		--[[if startsWithAny(line, blockStartKeywords) then
			indentLevel = indentLevel + 1
		end]]
		
	end
	local function roundlower(x:number)
		if math.round(x) > x then
			return math.round(x)-1
		else
			return math.round(x)
		end
	end
	local function roundupper(x:number)
		if math.round(x) < x then
			return math.round(x)+1
		else
			return math.round(x)
		end
	end
	local function iseven(x:number)
		return x % 2 == 0
	end
	-- Remove trailing whitespace
	local formatted = table.concat(result,"\n")

	local asfd = 0
	for i,v in ipairs(string.split(formatted, "\n")) do
		if asfd == 0 then
			formatted = ""
		end
		if v == "" or v == "\n" then
			else
			formatted = formatted .. v .. "\n"
		end
		asfd +=1
	end
	if Prettifier.config.removeTrailingWhitespace then
		formatted = formatted:gsub("%s+$", "")
	end
	return formatted
end

return Prettifier

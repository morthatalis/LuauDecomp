
--!optimize 2
--!nolint
local module = {}
--[[
// NOP: noop
        NOP,

        // BREAK: debugger break
        BREAK,

        // LOADNIL: sets register to nil
        // A: target register
        LOADNIL,

        // LOADB: sets register to boolean and jumps to a given short offset (used to compile comparison results into a boolean)
        // A: target register
        // B: value (0/1)
        // C: jump offset
        LOADB,

        // LOADN: sets register to a number literal
        // A: target register
        // D: value (-32768..32767)
        LOADN,

        // LOADK: sets register to an entry from the constant table from the proto (number/vector/string)
        // A: target register
        // D: constant table index (0..32767)
        LOADK,

        // MOVE: move (copy) value from one register to another

        // A: target register
        // B: source register
        MOVE,


        // GETGLOBAL: load value from global table using constant string as a key
        // A: target register
        // C: predicted slot index (based on hash)
        // AUX: constant table index
        GETGLOBAL,

        // SETGLOBAL: set value in global table using constant string as a key
        // A: source register
        // C: predicted slot index (based on hash)
        // AUX: constant table index
        SETGLOBAL,

        // GETUPVAL: load upvalue from the upvalue table for the current function
        // A: target register
        // B: upvalue index
        GETUPVAL,

        // SETUPVAL: store value into the upvalue table for the current function
        // A: target register
        // B: upvalue index
        SETUPVAL,

        // CLOSEUPVALS: close (migrate to heap) all upvalues that were captured for registers >= target
        // A: target register
        CLOSEUPVALS,

        // GETIMPORT: load imported global table global from the constant table
        // A: target register
        // D: constant table index (0..32767); we assume that imports are loaded into the constant table
        // AUX: 3 10-bit indices of constant strings that, combined, constitute an import path; length of the path is set by the top 2 bits (1,2,3)
        GETIMPORT,

        // GETTABLE: load value from table into target register using key from register
        // A: target register
        // B: table register
        // C: index register
        GETTABLE,

        // SETTABLE: store source register into table using key from register
        // A: source register
        // B: table register
        // C: index register
        SETTABLE,

        // GETTABLEKS: load value from table into target register using constant string as a key
        // A: target register
        // B: table register
        // C: predicted slot index (based on hash)
        // AUX: constant table index
        GETTABLEKS,

        // SETTABLEKS: store source register into table using constant string as a key
        // A: source register
        // B: table register
        // C: predicted slot index (based on hash)
        // AUX: constant table index
        SETTABLEKS,

        // GETTABLEN: load value from table into target register using small integer index as a key
        // A: target register
        // B: table register
        // C: index-1 (index is 1..256)
        GETTABLEN,

        // SETTABLEN: store source register into table using small integer index as a key
        // A: source register
        // B: table register
        // C: index-1 (index is 1..256)
        SETTABLEN,

        // NEWCLOSURE: create closure from a child proto; followed by a CAPTURE instruction for each upvalue
        // A: target register
        // D: child proto index (0..32767)
        NEWCLOSURE,

        // NAMECALL: prepare to call specified method by name by loading function from source register using constant index into target register and copying source register into target register + 1
        // A: target register
        // B: source register
        // C: predicted slot index (based on hash)
        // AUX: constant table index
        // Note that this instruction must be followed directly by CALL; it prepares the arguments
        // This instruction is roughly equivalent to GETTABLEKS + MOVE pair, but we need a special instruction to support custom __namecall metamethod

        NAMECALL,

        // CALL: call specified function
        // A: register where the function object lives, followed by arguments; results are placed starting from the same register
        // B: argument count + 1, or 0 to preserve all arguments up to top (MULTRET)
        // C: result count + 1, or 0 to preserve all values and adjust top (MULTRET)
        CALL,

        // RETURN: returns specified values from the function
        // A: register where the returned values start
        // B: number of returned values + 1, or 0 to return all values up to top (MULTRET)
        RETURN,

        // JUMP: jumps to target offset
        // D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
        JUMP,

        // JUMPBACK: jumps to target offset; this is equivalent to JUMP but is used as a safepoint to be able to interrupt while/repeat loops
        // D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
        JUMPBACK,

        // JUMPIF: jumps to target offset if register is not nil/false
        // A: source register
        // D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
        JUMPIF,

        // JUMPIFNOT: jumps to target offset if register is nil/false
        // A: source register
        // D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
        JUMPIFNOT,

        // JUMPIFEQ, JUMPIFLE, JUMPIFLT, JUMPIFNOTEQ, JUMPIFNOTLE, JUMPIFNOTLT: jumps to target offset if the comparison is true (or false, for NOT variants)
        // A: source register 1
        // D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
        // AUX: source register 2
        JUMPIFEQ,
        JUMPIFLE,
        JUMPIFLT,
        JUMPIFNOTEQ,
        JUMPIFNOTLE,
        JUMPIFNOTLT,

        // ADD, SUB, MUL, DIV, MOD, POW: compute arithmetic operation between two source registers and put the result into target register
        // A: target register
        // B: source register 1
        // C: source register 2
        ADD,
        SUB,
        MUL,
        DIV,
        MOD,
        POW,

        // ADDK, SUBK, MULK, DIVK, MODK, POWK: compute arithmetic operation between the source register and a constant and put the result into target register
        // A: target register
        // B: source register
        // C: constant table index (0..255)
        ADDK,
        SUBK,
        MULK,
        DIVK,
        MODK,
        POWK,

        // AND, OR: perform `and` or `or` operation (selecting first or second register based on whether the first one is truthy) and put the result into target register
        // A: target register
        // B: source register 1
        // C: source register 2
        AND,
        OR,

        // ANDK, ORK: perform `and` or `or` operation (selecting source register or constant based on whether the source register is truthy) and put the result into target register
        // A: target register
        // B: source register
        // C: constant table index (0..255)
        ANDK,
        ORK,

        // CONCAT: concatenate all strings between B and C (inclusive) and put the result into A
        // A: target register
        // B: source register start
        // C: source register end
        CONCAT,

        // NOT, MINUS, LENGTH: compute unary operation for source register and put the result into target register
        // A: target register
        // B: source register
        NOT,
        MINUS,
        LENGTH,

        // NEWTABLE: create table in target register
        // A: target register
        // B: table size, stored as 0 for v=0 and ceil(log2(v))+1 for v!=0
        // AUX: array size
        NEWTABLE,

        // DUPTABLE: duplicate table using the constant table template to target register
        // A: target register
        // D: constant table index (0..32767)
        DUPTABLE,

        // SETLIST: set a list of values to table in target register
        // A: target register
        // B: source register start
        // C: value count + 1, or 0 to use all values up to top (MULTRET)
        // AUX: table index to start from
        SETLIST,

        // FORNPREP: prepare a numeric for loop, jump over the loop if first iteration doesn't need to run
        // A: target register; numeric for loops assume a register layout [limit, step, index, variable]
        // D: jump offset (-32768..32767)
        // limit/step are immutable, index isn't visible to user code since it's copied into variable
        FORNPREP,

        // FORNLOOP: adjust loop variables for one iteration, jump back to the loop header if loop needs to continue
        // A: target register; see FORNPREP for register layout
        // D: jump offset (-32768..32767)
        FORNLOOP,

        // FORGLOOP: adjust loop variables for one iteration of a generic for loop, jump back to the loop header if loop needs to continue
        // A: target register; generic for loops assume a register layout [generator, state, index, variables...]
        // D: jump offset (-32768..32767)
        // AUX: variable count (1..255) in the low 8 bits, high bit indicates whether to use ipairs-style traversal in the fast path
        // loop variables are adjusted by calling generator(state, index) and expecting it to return a tuple that's copied to the user variables
        // the first variable is then copied into index; generator/state are immutable, index isn't visible to user code
        FORGLOOP,

        // FORGPREP_INEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_inext, and jump to FORGLOOP
        // A: target register (see FORGLOOP for register layout)
        FORGPREP_INEXT,

        // FASTCALL3: perform a fast call of a built-in function using 3 register arguments
        // A: builtin function id (see LuauBuiltinFunction)
        // B: source argument register
        // C: jump offset to get to following CALL
        // AUX: source register 2 in least-significant byte
        // AUX: source register 3 in second least-significant byte
        FASTCALL3,

        // FORGPREP_NEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_next, and jump to FORGLOOP
        // A: target register (see FORGLOOP for register layout)
        FORGPREP_NEXT,

        // NATIVECALL: start executing new function in native code
        // this is a pseudo-instruction that is never emitted by bytecode compiler, but can be constructed at runtime to accelerate native code dispatch
        NATIVECALL,

        // GETVARARGS: copy variables into the target register from vararg storage for current function
        // A: target register
        // B: variable count + 1, or 0 to copy all variables and adjust top (MULTRET)
        GETVARARGS,

        // DUPCLOSURE: create closure from a pre-created function object (reusing it unless environments diverge)
        // A: target register
        // D: constant table index (0..32767)
        DUPCLOSURE,

        // PREPVARARGS: prepare stack for variadic functions so that GETVARARGS works correctly
        // A: number of fixed arguments
        PREPVARARGS,

        // LOADKX: sets register to an entry from the constant table from the proto (number/string)
        // A: target register
        // AUX: constant table index
        LOADKX,

        // JUMPX: jumps to the target offset; like JUMPBACK, supports interruption
        // E: jump offset (-2^23..2^23; 0 means "next instruction" aka "don't jump")
        JUMPX,

        // FASTCALL: perform a fast call of a built-in function
        // A: builtin function id (see LuauBuiltinFunction)
        // C: jump offset to get to following CALL
        // FASTCALL is followed by one of (GETIMPORT, MOVE, GETUPVAL) instructions and by CALL instruction
        // This is necessary so that if FASTCALL can't perform the call inline, it can continue normal execution
        // If FASTCALL *can* perform the call, it jumps over the instructions *and* over the next CALL
        // Note that FASTCALL will read the actual call arguments, such as argument/result registers and counts, from the CALL instruction
        FASTCALL,

        // COVERAGE: update coverage information stored in the instruction
        // E: hit count for the instruction (0..2^23-1)
        // The hit count is incremented by VM every time the instruction is executed, and saturates at 2^23-1
        COVERAGE,

        // CAPTURE: capture a local or an upvalue as an upvalue into a newly created closure; only valid after NEWCLOSURE
        // A: capture type, see LuauCaptureType
        // B: source register (for VAL/REF) or upvalue index (for UPVAL/UPREF)
        CAPTURE,

        // SUBRK, DIVRK: compute arithmetic operation between the constant and a source register and put the result into target register
        // A: target register
        // B: source register
        // C: constant table index (0..255); must refer to a number
        SUBRK,
        DIVRK,

        // FASTCALL1: perform a fast call of a built-in function using 1 register argument
        // A: builtin function id (see LuauBuiltinFunction)
        // B: source argument register
        // C: jump offset to get to following CALL
        FASTCALL1,

        // FASTCALL2: perform a fast call of a built-in function using 2 register arguments
        // A: builtin function id (see LuauBuiltinFunction)
        // B: source argument register
        // C: jump offset to get to following CALL
        // AUX: source register 2 in least-significant byte
        FASTCALL2,

        // FASTCALL2K: perform a fast call of a built-in function using 1 register argument and 1 constant argument
        // A: builtin function id (see LuauBuiltinFunction)
        // B: source argument register
        // C: jump offset to get to following CALL
        // AUX: constant index
        FASTCALL2K,

        // FORGPREP: prepare loop variables for a generic for loop, jump to the loop backedge unconditionally
        // A: target register; generic for loops assume a register layout [generator, state, index, variables...]
        // D: jump offset (-32768..32767)
        FORGPREP,

        // JUMPXEQKNIL, JUMPXEQKB: jumps to target offset if the comparison with constant is true (or false, see AUX)
        // A: source register 1
        // D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
        // AUX: constant value (for boolean) in low bit, NOT flag (that flips comparison result) in high bit
        JUMPXEQKNIL,
        JUMPXEQKB,

        // JUMPXEQKN, JUMPXEQKS: jumps to target offset if the comparison with constant is true (or false, see AUX)
        // A: source register 1
        // D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
        // AUX: constant table index in low 24 bits, NOT flag (that flips comparison result) in high bit
        JUMPXEQKN,
        JUMPXEQKS,

        // IDIV: compute floor division between two source registers and put the result into target register
       	
        // A: target register
        // B: source register 1
        // C: source register 2
        IDIV,

        // IDIVK compute floor division between the source register and a constant and put the result into target register
        // A: target register
        // B: source register
        // C: constant table index (0..255)
        IDIVK,
]]
--[[

GETUPVAL R0 0
  JUMPIFNOT R0 [+5]
  GETUPVAL R1 1
  GETTABLEKS R0 R1 K0 ["unmount"]
  GETUPVAL R1 0
  CALL R0 1 0
  GETUPVAL R0 2
  LOADB R1 0
  SETTABLEKS R1 R0 K1 ["Enabled"]
  RETURN R0 0
  
 ]]



local test = [[
MAIN:
  PREPVARARGS 0
  GETIMPORT R2 K1 [script]
  GETTABLEKS R1 R2 K2 ["Parent"]
  GETTABLEKS R0 R1 K3 ["_Index"]
  GETIMPORT R1 K5 [require]
  GETTABLEKS R3 R0 K6 ["Cryo"]
  GETTABLEKS R2 R3 K6 ["Cryo"]
  CALL R1 1 1
  RETURN R1 1]]

test = [[
PROTO_0:
  GETIMPORT R0 K1 [game]
  LOADK R2 K2 ["PublishPlaceFixRenderThrash"]
  NAMECALL R0 R0 K3 ["GetFastFlag"]
  CALL R0 2 -1
  RETURN R0 -1

MAIN:
  PREPVARARGS 0
  GETIMPORT R0 K1 [game]
  LOADK R2 K2 ["PublishPlaceFixRenderThrash"]
  LOADB R3 0
  NAMECALL R0 R0 K3 ["DefineFastFlag"]
  CALL R0 3 0
  DUPCLOSURE R0 K4 [PROTO_0]
  RETURN R0 1]]
--r2="PublishPlaceFixRenderThrash"?
--[[
--Created by ToastedSoup's tool "rctluauconv" 
--tool version 0.0.1
]]

--decompiles predeserialized and preformatted bytecode
@native --to make this fast as c++ :D idk actually
function module.decompileluac(bytecode)
	--//INITS//
	bytecode = string.gsub(bytecode,"  ", "")
	local lines = string.split(bytecode,"\n")
	local reg = {}
	local creg = {} --cleaned reg without extra information
	--//UPVALUES// a very basic and bad implementation of upvalues.
	local upvalindex = 0 --handling upvals differently compared to how the compiler does it, aka dont clear this value. 
	local dubindex = 0 
	local funcindex = 0
	local funcvarsamt = 0
	local initindex = 0
	local biggestindex = 0
	local ups = {}
	local totalupscount = 0
	--constants wont be needed because the bytecode itself already contains them. aka word[constant+1] (not how my code handles it)
	local funcsattribute = {} --change attributes, "funcname", {"parameters":number}, "line"
	local curfunc = 0
	local funcend = false --just for functions/protos
	local namecallstr = "" --namecall.. name
	local namecall = false --is next func call actually an extention of namecall?
	local showninscript = {} --variables shown in the script itself
	--//MISC//
	local jumpindexes = {} --for ifstatements :D
	local currentjumpindex = {}
	local skipline = false --no next line :D
	local noline = false --dont do newline, because this line doesnt contain anything
	local iselse = false
	local iselseif = false
	local requirecall = "" --my code doesnt work good with require for somereason and cuz doing it like this makes requires look cleaner
	local requirebool = false --is require being used? (only really needed for CALL)
	local importname = ""
	local returnstatement = ""
	local ismain = false
	local forloopindent = 0 --not really an indent, just figures out how many forloops has passed in the current function, and does -1 when a for loop is done
	local tretval = {}
	local varnames = {}
	local amtvarnameused = {}
	local forreg = {}
	--//INITS/FUNCTIONS//
	print("lines:",#lines)
	for i, line in ipairs(lines) do
		local word = string.split(line, " ")
		local op = word[1]
		if op == "CAPTURE" then
			totalupscount += 1
		end
		
	end
	local lastline = lines[#lines]
	for i, line in ipairs(lines) do
		--Table to string converter
		local nextline = lines[i+1]

		local function t2s(_t) --this was made in my "look cool because i made this unreadable" phase lmfao
			local _l = "{}"
			for i = 1, #_t, 1 do
				_l = string.sub(_l, 1, #_l - 1)
				if type(_t[i]) == "string" then
					if i == 1 then
						_l = _l .. '"' ..  _t[i] .. '"'
					else
						_l = _l .. ", " .. '"' ..  _t[i] .. '"'
					end
				else
					if i == 1 then
						_l = _l .. tostring(_t[i])
					else
						_l = _l .. ", " .. tostring(_t[i])
					end
				end
				_l = _l .. "}"
			end
			return _l
		end
		local function twithvalue(tbl,value)
			local rettbl = {}
			for i, v in ipairs(tbl) do
				if v == value then
					table.insert(rettbl,i)
				end
			end
			return rettbl
		end
		local function setvarname(regi,name)
			if not amtvarnameused[name] then
				amtvarnameused[name] = 1
				varnames[regi] = name .. "_1"
			else
				amtvarnameused[name] += 1
				varnames[regi] = name .. "_" .. amtvarnameused[name]
			end
		end
		local function strtotype(str:string)
			if tonumber(str) then
				return tonumber(str)
			end
			if str == "nil" or str == nil then
				return nil
			end
			if str == "true"  or str == true then
				return true
			end
			if str == "false"  or str == false then
				return false
			end
			return str
		end
		local function isstr(x)
			return (typeof(x) == string)
		end
		local function isnum(x)
			return (typeof(x) == typeof(upvalindex))
		end
		local function isnil(x)
			return (typeof(x) == nil)
		end
		local function isbool(x)
			return (typeof(x) == typeof(ismain))
		end
		local function tcontains(t, value)
			for _, v in ipairs(t) do
				if v == value then
					return true
				end
			end
			return false
		end

		local function returnvalue(regi)

			if creg[regi] ~= nil then
				if string.sub(tostring(creg[regi]),1,4) ~= "nil[" then
					return tostring(creg[regi])
				else
					return "nil --[[nil since attempts to get an index of nil]]"
				end
			elseif reg[regi] ~= nil then
				if string.sub(tostring(reg[regi]),1,4) ~= "nil[" then
					return tostring(reg[regi])
				else
					return "nil"
				end
			else
				return "nil"
			end
		end

		local function specialreturnvalue(regi)

			if creg[regi] ~= nil then
				if string.sub(tostring(creg[regi]),1,4) ~= "nil[" then
					return tostring(creg[regi])
				else
					return regi
				end
			elseif reg[regi] ~= nil then
				if string.sub(tostring(reg[regi]),1,4) ~= "nil[" then
					return tostring(reg[regi])
				else
					return  regi
				end
			else
				return  regi
			end
		end
		local function addlocal(valuetocheck:string)
			--warn(valuetocheck, reg[valuetocheck])
			if specialreturnvalue(valuetocheck) ~= valuetocheck and ismain == false and forreg[valuetocheck] == nil then
				return "local "
			else
				print( curfunc, ismain, t2s(jumpindexes))
				return ""
			end
		end

		local function gettotallines()
			local retv = 0
			local concattrv = table.concat(tretval)
			local splittrv = string.split(concattrv, "\n")
			for i, v in splittrv do
				retv = retv + 1
			end
			return retv + 3 + totalupscount
		end
		local function getvarname(regi)
			if varnames[regi] then
				return varnames[regi]
			else
				return regi
			end
		end
		local function checkend(i)
			local nextline = lines[i+1]
			local c
			if nextline and string.match(nextline," ") then
				c = string.split(nextline," ")
			end
			for ix, v in jumpindexes do
				print(v, ix)
				if jumpindexes[ix] == 1 then

					if c and (nextline:split(" ")[1]:sub(1,6) == "JUMPIF" )then
						iselseif = true
						jumpindexes[ix] = 0
					elseif c and (nextline:split(" ")[1] == "JUMP" )then
						iselse = true
						jumpindexes[ix] = 0
					else 
						jumpindexes[ix] = 0
						tretval[i] = tretval[i] .. "end\n"
					end
				end
				if jumpindexes[ix] > 0 then
					jumpindexes[ix] = jumpindexes[ix] - 1
				else
					jumpindexes[ix] = nil
				end
				if i+1 == #lines and ismain == true then
					jumpindexes[ix] = 0
					table.insert(tretval,"end")
				end
			end
		end
		local regcpy = reg
		local cregcpy = creg
		tretval[i] = ""
		local word = string.split(line, " ")
		local op = word[1]
		checkend(i)
		if skipline == false then
			if op == "JUMPIFNOT" then
				--aka if arg1 then
				local arg1 = word[2]
				local arg2 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " then"
						-- = "if " .. returnvalue(arg1) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1

					end
				end

			elseif op == "NOP" then
				tretval[i] = tretval[i] .. "--NOP"
				-- = "--NOP"
			elseif op == "JUMPIF" then
				local arg1 = word[2]
				local arg2 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if not " .. specialreturnvalue(arg1) .. " then"
						-- = "if not " .. returnvalue(arg1) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						print(tonumber(string.sub(arg2,3,#arg2-1)) + 1)
					else
						tretval[i] = tretval[i] .. "elseif not " .. specialreturnvalue(arg1) .. " then"
						-- = "elseif not " .. returnvalue(arg1) .. " then"
					end
				end

			elseif op == "RETURN" then
				local arg1 = word[2]
				local arg2 = word[3]
				local a = arg1
				local b = tonumber((string.gsub(arg2,"%D", "")))
				local function mainthing()
					if b > 1 then
						for i=1, b do
							a = a .. ", R" .. tostring(i)
						end
					end
					local regs = string.split(a, ", ")
					local hiArray = {}
					for _, v in pairs(regs) do
						table.insert(hiArray, tostring(v))
					end

					a = table.concat(hiArray, ", ")
					print(a)
					if ismain == false then
						if a == "R0" then
							if arg2 == "0" then
								if nextline ~= "" and lastline ~= nextline then
									print('"'..nextline..'"')
									returnstatement =  "return --register 0"
								end
							else
								returnstatement =  "return " .. a
							end
						else
							returnstatement =  "return " .. a
						end
					else
						if a == "R0" then
							if arg2 == "0" then
								if nextline ~= "" and lastline ~= nextline then
								tretval[i] = tretval[i] ..  "return --register 0"
									-- = "return --register 0"
								end
							else
								tretval[i] = tretval[i] ..   "return " .. a
								-- = "return " .. a
							end
						else
							tretval[i] = tretval[i] .. "return " .. a
							-- = "return " .. a
						end
					end
				end
				if jumpindexes == {} then
					mainthing()
				elseif lines[i+2] == not nil and not lines[i+2]:sub(#lines[i+1]-1) == ":" then
					mainthing()
				elseif i == #lines then
					mainthing()
				elseif lines[i+1] == "" then
					mainthing()
				elseif a == "R0" then
					mainthing()
				elseif jumpindexes ~= {} then
					local b = false
					for i, v in ipairs(jumpindexes) do
						if i == 1 then
							mainthing()
							b = true
						end
					end
					if b == false and nextline ~= "" and lastline ~= nextline then
						tretval[i] = tretval[i] .. "--this is a random return (from what i know)"
					end
					-- = "--this is a random return (from what i know)"
				elseif lastline ~= nextline then
					tretval[i] = tretval[i] .. "--this is a random return (from what i know)"
				end

			elseif op == "LOADNIL" then
				local arg1 = word[2]

				tretval[i] = tretval[i] ..addlocal(arg1) ..  arg1 .. " = nil"
				-- = addlocal(arg1) ..  arg1 .. " = nil"
				reg[arg1] = "nil" -- cuz nil will break my code lol
				creg[arg1] = "nil"
			elseif op == "LOADN" then
				local arg1 = word[2]
				local arg2 = word[3]

				tretval[i] = tretval[i] .. addlocal(arg1)  ..  arg1 .. " = " .. arg2
				-- = addlocal(arg1)  ..  arg1 .. " = " .. arg2
				reg[arg1] = arg2
				creg[arg1] = arg2
			elseif op == "LOADB" then
				local arg1 = word[2]
				local arg2 = word[3]
				local bool = (arg2 == "1")


				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. tostring(bool)
				-- = addlocal(arg1) ..  arg1 .. " = " .. tostring(bool)
				reg[arg1] = bool
				creg[arg1] = bool
			elseif op == "SETTABLEKS" then
				local arg1 = word[2]
				local arg2 = tostring(word[3])
				local arg3 = '["'.. string.sub(line,line:find('%["')+2,#line-2)  .. '"]'
				local convregarg2 = tostring(reg[arg2])
				print(convregarg2)
				if string.sub(convregarg2, 1,2) == "RT" or  string.sub(convregarg2, 1,2) == "IM" then --weird fix but ok
					reg[arg1] =  "RT"..string.sub(reg[arg2], 3, #reg[arg2]) .. arg3
					creg[arg1] =  string.sub(reg[arg2], 3, #reg[arg2]) .. arg3
				elseif string.sub(convregarg2, 1,1) == "{" then
					reg[arg1] = string.sub(arg3, 2, #arg3-1)
					creg[arg1] = string.sub(arg3, 2, #arg3-1)
				elseif convregarg2 == "nil" then
					reg[arg1] = string.sub(arg3,2,#arg3-1)
					creg[arg1] = string.sub(arg3,2,#arg3-1)
				else
					reg[arg1] =  "RT"..tostring(reg[arg2]) ..tostring(arg3)
				end
				tretval[i] = tretval[i] .. arg1 .. " = "  .. arg2 .. arg3
				-- = arg1 .. " = "  .. arg2 .. arg3
			elseif op == "GETIMPORT" then
				local arg1 = word[2]
				local arg2 = word[4]
				--if string.sub(arg2,2,#arg2 - 1) ~= "require" then
				--	reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1) 
				--	tretval[i] = tretval[i] ..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
				--else
				local val = string.sub(arg2, 2, #arg2 - 1)

				local blacklist = {
					require = true,
					print = true,
					error = true,
					warn = true,
				}
				--importregistry[]
				--print(string.sub(arg2,2,#arg2 - 1) == ("Enum" or "game" or "plugin" or "shared" or "script" or "workspace"), string.sub(arg2,2,#arg2 - 1))
				if blacklist[val] then
					reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1)
					creg[arg1] = string.sub(arg2,2,#arg2-1)
					requirebool = true
					requirecall = ""
					importname = string.sub(arg2,2,#arg2 - 1)
					noline = true
				else
					reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1) 
					creg[arg1] = string.sub(arg2,2,#arg2-1)
					--tretval[i] = tretval[i] ..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
					requirebool = false
					requirecall = ""
					--noline = true
					--tretval[i] = tretval[i] .. addlocal(arg1)..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
					-- = addlocal(arg1)..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
				end
				
			elseif op == "GETTABLEKS" then
				local arg1 = word[2]
				local arg2 = tostring(word[3])
				local rawarg3 = string.sub(line,line:find('%["')+2,#line-2)
				local arg3 = '["'..  rawarg3 .. '"]'
				local prtstr = ""--[[
				local whitelist = {
					-- Core Instance properties
					Archivable = true,
					ClassName = true,
					Name = true,
					Parent = true,
					RobloxLocked = true,

					-- Less common or internal properties still exposed to Luau
					SourceAssetId = true,
					DefinesCapabilities = true,
					Capabilities = true,
					HistoryId = true,
					UniqueId = true,
					DataCost = true,
					Sandboxed = true,
				}]]

				if requirebool == false then
					print(arg2, i, line)
					--prtstr = addlocal(arg1) ..  arg1 .. " = " .. returnvalue(arg2) .. arg3
					if true then
						reg[arg1] = "RT"..arg2  .. "." .. rawarg3
						creg[arg1] = specialreturnvalue(arg2) .. "." .. rawarg3
					end
				else
						if creg[arg2]:sub(1,8) ~= "require" then
							reg[arg1] =  "RT"..arg2 ..arg3 
							creg[arg1] =  creg[arg2] ..arg3
							--prtstr = addlocal(arg1) ..  arg1 .. " = " .. creg[arg2] .. arg3
						else
							reg[arg1] =  "RT"..arg2 ..arg3 
							creg[arg1] =  arg2 ..arg3
							--prtstr = addlocal(arg1) ..  arg1 .. " = " .. arg2 .. arg3
						end
				end
				--doesnt really matter if we do the check here
				if lines[i+1]:split(" ")[1] ~= "GETTABLEKS" or lines[i+1]:split(" ")[3] ~= arg1 then
					tretval[i] = tretval[i] .. prtstr
					-- = prtstr
				else
					noline = true
				end
				if requirecall == "" then
					if creg[arg2] ~= nil then
						requirecall = requirecall .. creg[arg2] .. "." .. rawarg3
					elseif reg[arg2] ~= nil  then
						requirecall = requirecall .. reg[arg2] .. "." .. rawarg3
					else
						requirecall = requirecall .. arg2 .. "." .. rawarg3
					end
				else
					requirecall = requirecall .. "." .. rawarg3
				end
			elseif op == "NAMECALL" then
				-- A: target register, B: source register, AUX: constant table index (method name)
				local target = word[2]:match("%d+")  -- strip R and get digits
				local source = word[3]:match("%d+")
				local methodName = string.sub(word[5],3,#word[5]-2) or "UNKNOWN"
				local asdf =specialreturnvalue("R" .. source)
				if asdf == nil then asdf = ("R" .. source) end
				namecall = true
				namecallstr =  asdf .. ":" .. methodName

				noline = true

			elseif op == "CALL" then
				local rawA = word[2]:gsub("R",""):match("%d+")
				local A = tonumber(rawA)
				local B = tonumber(word[3]:match("%-?%d")) -- arguments count + 1
				local C = tonumber(word[4]:match("%-?%d+")) -- results count + 1

				-- build arguments (normal/namecall only)
				local args = {}
				local cregargs = {}
				if B >= 0 then
					for i = 1, B do
						if i == 1 and reg[ "R" .. tostring(A + i)] == nil and B ~= 2 then
							
								continue
							
						end
						local a =  "R" .. tostring(A + i)
						local regen = specialreturnvalue(tostring(a))
						print(regen,reg[ "R" .. tostring(A + i)], a, reg[a])
						if reg[a] ~= nil and reg[a] ~= "nil" and reg[a] ~= "{}" then
							if not string.match(regen,"RT") and not string.match(regen,"IM") then
								table.insert(args, specialreturnvalue("R" .. tostring(A + i))) 
							else
								table.insert(args, regen:sub(3,#regen))
							end
						else
							table.insert(args, "R" .. tostring(A + i))
						end
					end
				elseif B == -1 then
					table.insert(args, "") -- MULTRET
				end
				for i, v in args do
					if creg[v] ~= nil then
						table.insert(cregargs, creg[v])
					elseif reg[v] ~= nil then
						table.insert(cregargs, reg[v])
					else
						table.insert(cregargs, v)
					end
				end
				-- base call string
				local callStr
				local regcallStr
				if requirebool then
					-- Special handling for require/print/warn/error
					requirebool = false
					if true --[[creg[args[1]]--[[ == nil]] then -- not doing extra checks for every other arguments
						callStr = importname .."(" .. requirecall .. ")" --fallback if my code is acting weird
						regcallStr = importname .."(" .. requirecall .. ")" --fallback if my code is acting weird
					else
						callStr = importname .."(" .. table.concat(cregargs, ", ") .. ")" -- this is weird
						regcallStr = importname .."(" .. table.concat(cregargs, ", ") .. ")" -- this is weird
					end
					print(table.concat(args, ", "))
				elseif namecall then
					-- Method call
					
					callStr = namecallstr .. "(" .. table.concat(args, ", ",2) .. ")"
					regcallStr = namecallstr .. "(" .. table.concat(args, ", ",2) .. ")"
					
				else
					-- Normal call
						--if tostring(reg["R" .. A]) ~= "IMrequire" and string.sub(reg["R" .. A], 1, 6) ~= "script" then
							print("R" .. A, i, line)
						callStr =specialreturnvalue("R" .. A).. "(" .. table.concat(args, ", ") .. ")"
						regcallStr = specialreturnvalue("R" .. A).. "(" .. table.concat(args, ", ") .. ")"
						--[[else
							callStr = "R" .. A.. "(" .. table.concat(args, ", ") .. ")"
							regcallStr = "R" .. A.. "(" .. table.concat(args, ", ") .. ")"
						end]]
				end
				local rvstr = ""
				-- Handle return values
				if C == 1 then
					if namecall == true and namecallstr ~= nil and string.find(namecallstr,':') and string.sub(namecallstr,string.find(namecallstr,':')+1,#namecallstr) == "GetService" then
						rvstr =  "R" .. A .. " = " .. callStr .." -- MULTRET"
						setvarname("R" .. A,string.sub(args[2],2,#args[2]-1))
					else
						rvstr =  "R" .. A .. " = " .. callStr .." -- MULTRET"
					end
					--print(string.sub(namecallstr,string.find(namecallstr,':')+1,#namecallstr))
					creg["R" .. A] = callStr
				elseif C == 2 then
					if namecall == true and namecallstr ~= nil and string.sub(namecallstr,string.find(namecallstr,':')+2,#namecallstr-1) == "GetService" then
						setvarname("R" .. A,string.sub(args[2],2,#args[2]-1))
					else
						rvstr =  "R" .. A .. " = " .. callStr
					end
					print(string.sub(namecallstr,string.find(namecallstr,':')+2,#namecallstr-1))
					creg["R" .. A] = callStr
					
				elseif C > 2 then
					local rets = {}
					for i = 0, C - 2 do
						table.insert(rets, "R" .. tostring(A + i))
					end
					rvstr =  table.concat(rets, ", ") .. " = " .. callStr
					if specialreturnvalue("R" .. A) == "ipairs" then
						creg["FORGLOOPINEXT"] = callStr
						reg["FORGLOOPINEXT"] = callStr
					end
					-- = table.concat(rets, ", ") .. " = " .. callStr
					--not this one since it's a table/tuple
				elseif C == 0 then
					rvstr = callStr
					creg["R" .. A] = callStr
					-- = callStr
				else
					rvstr =  callStr
					creg["R" .. A] = callStr
				end
				--tretval[i] = tretval[i] .. "\n --" .. line
				if lines[i+1]:match(" ") and string.sub(lines[i+1]:split(" ")[1],1,6) == "JUMPIF" and lines[i+1]:split(" ")[2] == "R"..A then
					else
					tretval[i] = tretval[i] .. rvstr
				end
				namecall = false
			elseif line == "" then
				if funcend == true then
					initindex += funcvarsamt
					funcvarsamt = 0
					biggestindex = 0

					for _ in pairs(jumpindexes) do
						tretval[i] = tretval[i] .. "end\n"
					end
					jumpindexes = {}
					tretval[i] = tretval[i] .. returnstatement
					tretval[i] = tretval[i] .. "\n end --FUNCEND?"
					funcend = false
				end
			elseif line == "MAIN:" then
				skipline = true
				noline = true
				ismain = true
				reg = {}
				creg = {}
				varnames = {}
				forloopindent = 0
			elseif line:match":" and line:match"PROTO_" then
				if funcend == false then
					local funcname = string.sub(line,1,#line-1)
					local func = tonumber(string.sub(line,7,#line-1))
					tretval[i] = tretval[i] .. "function " .. funcname .. "()"
					reg = {}
					creg = {}
					curfunc = func
					funcsattribute[func] = {funcname,{},i}
					forloopindent = 0
					varnames = {}
				end
				funcend = true
			elseif op == "DUPCLOSURE" then
				local arg1 = word[2]
				local arg2 = word[4]    
				arg2 = string.sub(arg2,2,#arg2 - 1)
				tretval[i] = tretval[i] .. addlocal(arg1).. tostring(arg1) .. " = " .. arg2 .. "()"
				creg[arg1] = arg2 .. "()"
				setvarname(arg1,"dupfunc")
			elseif op == "DUPTABLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local garb = #("DUPTABLE  "..arg1.. " [" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb + 1,#line - 1)

				tretval[i] = tretval[i] .. addlocal(arg1)..  arg1 .. " = " .. tablea
				reg[arg1] = tablea
				setvarname(arg1,"tbl")
				--CONCAT
			elseif op == "CONCAT" then
				local arg1 = word[2]
				local arg2 = word[3]  
				local arg3 = word[4]  

				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. ' = ' .. arg2 .. " .. " .. arg3
				reg[arg1] =  arg2 .. " .. " .. arg3
			elseif op == "LOADK" then
				local arg1 = word[2]
				local arg2 = word[4]
				if arg2 == '["' then
					arg2 = "\n"
					skipline = true
				end
				local garb = #("LOADK "..arg1.. " as[" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb,#line - 1)
				reg[arg1] =  tablea --i can finally detect what type (this is supposed to be) this is now :D using my own custom functions
				creg[arg1] =  tablea
				if requirebool == false then
					tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. tablea
				else
					requirecall = requirecall .. tablea
				end

				--local arg1 = word[2]
				--local arg2 = string.sub(word[4],2,#word[4]-1)
				--tretval[i] = tretval[i] ..  arg1 .. " = " .. arg2
			elseif op == "SETGLOBAL" then
				local arg1 = word[2]
				local arg2 = word[4]

				local garb = #("SETGLOBAL "..arg1.. " as[" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb,#line - 1)

				tretval[i] = tretval[i] .. '_G["'.. arg1 .. '"] = ' .. tablea
				reg[arg1] =  tablea --cant see type, if you try type() on it, it'd just return as string
			elseif op == "JUMPIFLT" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " >= " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " >= " .. specialreturnvalue(arg3) .. " then"
					end

				end
			elseif op == "JUMPIFLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " > " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " > " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFEQ" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then

						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " ~= " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " ~= " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFNOTEQ" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " == " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " == " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFNOTLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " <= " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " <= " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFNOTLT" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " < " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " < " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFNOTEQKS" then
				local arg1 = word[2]
				local arg2 = word[5]
				local arg3 = string.sub(word[4],2,#word[4]-1) 
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " == " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " == " .. specialreturnvalue(arg3) .. " then"
					end
				end
			elseif op == "JUMPIFEQKS" then
				local arg1 = word[2]
				local arg2 = word[5]
				local arg3 = string.sub(word[4],2,#word[4]-1) 
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						tretval[i] = tretval[i] .. "if " .. specialreturnvalue(arg1) .. " == not " .. specialreturnvalue(arg3) .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						tretval[i] = tretval[i] .. "elseif " .. specialreturnvalue(arg1) .. " == not " .. specialreturnvalue(arg3) .. " then"
					end
				end

			elseif op == "ADD" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " + " .. arg3
				reg[arg1] = arg2.. " + "..arg3
			elseif op == "SUB" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " - " .. arg3
				reg[arg1] = arg2.. " - "..arg3
			elseif op == "MUL" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " * " .. arg3
				reg[arg1] = arg2.. " * "..arg3
			elseif op == "DIV" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " / " .. arg3
				reg[arg1] = arg2.. " / "..arg3
			elseif op == "MOD" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " % " .. arg3
				reg[arg1] = arg2.. " % "..arg3
			elseif op == "POW" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " ^ " .. arg3
				reg[arg1] = arg2.. " ^ "..arg3
			elseif op == "ADDK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " + " .. arg3
				reg[arg1] = arg2.. " + "..arg3
			elseif op == "SUBK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " - " .. arg3
				reg[arg1] = arg2.. " - "..arg3
			elseif op == "MULK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " * " .. arg3
				reg[arg1] = arg2.. " * "..arg3
			elseif op == "DIVK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " / " .. arg3
				reg[arg1] = arg2.. " / "..arg3
			elseif op == "MODK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " % " .. arg3
				reg[arg1] = arg2.. " % "..arg3
			elseif op == "POWK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. arg2 .. " ^ " .. arg3
				reg[arg1] = arg2.. " ^ "..arg3
			elseif op == "MOVE" then
				local arg1 = word[2]
				local arg2 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1)..  arg1 .. " = " .. arg2 --simple as that :D
				if creg[arg2] ~= nil then
					arg2 = creg[arg2]
				end
				reg[arg1] = arg2
				creg[arg1] = arg2
			elseif op == "NOT" then
				local arg1 = word[2]
				local arg2 = word[3]
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = not " .. arg2 --simple as that :D
				reg[arg1] = not arg2
			elseif op == "GETUPVAL" then
				--here we go :D
				local arg1 = word[2]
				local arg2 = word[3]
				if tonumber(arg2) > biggestindex then
					funcvarsamt += 1
					biggestindex = tonumber(arg2)
				end
				reg[arg1] = "UP" .. tonumber(arg2) + initindex
				creg[arg1] = "UP" .. tonumber(arg2) + initindex
				tretval[i] = tretval[i] .. addlocal(arg1) ..  arg1 .. " = " .. "UP" .. tonumber(arg2) + initindex
			elseif op == "CAPTURE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local re
				re= tostring(reg[arg2])
				local comment = "--captured on line: " .. gettotallines()
				local rem = ""
				--if re and string.sub(re, 1, 2) == "RT" then
				--	re = string.sub(reg[arg2], 2, #reg[arg2])
				--	local item = re
				--	local pos = string.find(item, "%[")
				--	re = string.sub(re, pos, #re)
				--	re = string.sub(tostring(reg[string.sub(item,1,pos-1)]),pos,#tostring(reg[string.sub(item,1,pos-1)])) .. re
				--	rem = "RT"
				--elseif re and string.sub(re, 1, 2) == "IM" then
				--	re = string.sub(reg[arg2], 3, #reg[arg2])
				--	-- no extra processing needed
				--	rem = "IM"
				--else
				--	re = tostring(reg[arg2])
				--	-- i dont wanna do this :sob:
				--end
				--if string.sub(re, 1, 1) == "[" then
				--	local b = string.find(reg[arg2],"%[")
				--	re = string.sub(reg[arg2], b+1, #reg[arg2]-1)
				--end
				if arg1 == "UPVAL" then
					re = "UP" .. string.sub(arg2, 2, #arg2)
				elseif creg[arg2] == nil then
					re = tostring(reg[arg2])
				else
					re = tostring(creg[arg2])
				end
				print(re,string.sub(string.sub(arg2, 2, #arg2),3))
				--print(tonumber(string.sub(re,3)))
				if string.sub(arg2, 2, #arg2) ~= "" and string.sub(arg2, 2, #arg2) ~= nil and not string.match(re,"nil") and string.sub(re,1,2) == "UP"  then
					if tonumber(string.sub(arg2, 2, #arg2)) >= upvalindex then
						comment = comment .. ", compiled wrong. returning nil"
						re = "nil"
					end
				else
					--re= "nil"
				end

				print(upvalindex, reg[arg2], arg2, re)
				tretval[i] = tretval[i] .. "--OPCODE CAPTURE UP".. upvalindex .. " reg " .. arg2 .. " type " .. arg1
				--here we go 2.0 :D
				ups[upvalindex+1] = "local UP".. upvalindex
					.. " = "
					..re.. ";" .. comment


				upvalindex += 1
				--[[
				// GETUPVAL: load upvalue from the upvalue table for the current function
        		// A: target register
        		// B: upvalue index
        		]]
			elseif op == "NEWCLOSURE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local funcname = "PROTO_"..string.sub(arg2,2)
				--NEWCLOSURE R2 P0

				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = " .. funcname
				reg[arg1] = "PROTO_"..string.sub(arg2,2)
			elseif op == "CLOSEUPVALS" then
				noline = true
			elseif op == "GETGLOBAL" then
				local arg1 = word[2]
				local arg2 = word[4]
				arg2 = string.sub(arg2, 2, #arg2-1)
				tretval[i] = tretval[i] ..  arg1 .. " = " .. arg2
			elseif op == "IDIV" then --doesnt explain anything, basically floor division.
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = " .. arg2 .. " // " .. arg3
			elseif op == "IDIVK" then -- same above, but arg3 is a constant.
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = " .. arg2 .. " // " .. arg3
			elseif op == "SUBRK" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = " .. arg2 .. " - " .. arg3
			elseif op == "DIVRK" then --rk means register-constant
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = " .. arg2 .. " / " .. arg3
			elseif op == "NEWTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				print(arg2)
				tretval[i] = tretval[i] .. addlocal(arg1)..  arg1 .. " = {}" -- yeah idc cuz it's not like luau uses this anyway. (the size part)
				reg[arg1] = "{}"	
				creg[arg1] = "{}"	
				print(arg1)
				setvarname(arg1, "tbl")
			elseif op == "JUMP" then
				local arg1 = word[2]
				local number = string.sub(arg1, 3, #arg1-1) -- 3 instead of 2 because of of the + character
				if iselse == true then
					tretval[i] = tretval[i] .. "else --proven to be 'else'"
				else
					tretval[i] = tretval[i] .. "--break maybe?? " .. line
				end
				--jumpindexes[i] = number + 1 --because this line will also remove 1 from this index

			elseif op == "SETTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				--i suspect that arg2 or arg3 will be the table and other one is the value and the table and arg1 will be the updated table
				--reg[arg2][reg[arg3]] = reg[arg1]

				tretval[i] = tretval[i] ..  arg2 .. "[" .. arg3  .. "] = " .. arg1
				--reg[arg2] = "{" .. reg[arg1] or arg1 .. "}"
			elseif op == "SETLIST" then
				-- A: table register
				-- B: starting register of values
				-- C: number of values (+1), or 0 for MULTRET
				-- AUX: starting array index
				--print("hi")
				local A = tonumber(word[2]:match("%d+")) -- table register
				local B = tonumber(word[3]:match("%d+")) -- first value register
				local C = tonumber(word[4]:match("%-?%d+")) -- count+1
				local AUX = tonumber(word[5]:match("%d+"))
				noline = true
				-- handle MULTRET (C == 0 → all values from B..top)
				local count = (C == 0) and "" or (C - 1)

				if C == 0 then
					noline = false
					tretval[i] = tretval[i] .. ("-- SETLIST: R%d from R%d to top starting at %d"):format(A, B, AUX)
				else
					noline = false
					for i = 0, count - 1 do
						tretval[i] = tretval[i] --.. ("R%d[%d] = R%d"):format(A, AUX + i, B + i)
					end
				end
				--tretval[i] = tretval[i] .. "--" .. line
			elseif op == "LENGTH" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = #arg2
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .." = #" .. arg2
			elseif op == "FASTCALL1" then
				noline = true
				reg[word[3]] = word[2]:lower():gsub("_",".") .. "(" .. word[3] .. ")"
				--noline since our code already handles these calls
				--[[example:
 FASTCALL1 MATH_ABS R5 [+2] <-- +2 shows that this call will be called in 2 instructions
  GETIMPORT R4 K3 [math.abs] <-- this is the import that call uses
  CALL R4 1 1 <-- r4 is the same register as the one in the imported call
]]
			elseif op == "FASTCALL" then
				noline = true
			elseif op == "FASTCALL2" then
				noline = true
			elseif op == "FASTCALL2K" then
				noline = true
			elseif op == "FASTCALL3" then
				noline = true
			elseif op == "FORNPREP" then
				local arg1 = word[2]
				local regnumarg1 = string.sub(arg1,2,#arg1)
				local arg2 = "R" .. regnumarg1+1
				local arg3 = "R" .. regnumarg1+2
				tretval[i] = tretval[i] .. "for " .. arg1 .." = ".. reg[arg1] ..", ".. arg2 ..", ".. arg3 .. " do"
				forloopindent += 1
				forreg[arg1] = true
				forreg[arg2] = true
				forreg[arg3] = true
			elseif op == "MINUS" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = arg2
				tretval[i] = tretval[i] .. addlocal(arg1) .. arg1 .. " = -" .. arg2
			elseif op == "SETUPVAL" then
				local arg1 = word[2]
				local arg2 = word[3]
				tretval[i] = tretval[i] .."UP" .. tonumber(arg2) + initindex + 1 .. " = " ..  arg1
			elseif op == "FORNLOOP" then
				local arg1 = word[2]
				local regnumarg1 = string.sub(arg1,2,#arg1)
				local arg2 = "R" .. regnumarg1+1
				local arg3 = "R" .. regnumarg1+2
				forreg[arg1] = nil
				forreg[arg2] = nil
				forreg[arg3] = nil
				tretval[i] = tretval[i] .. "end" --basically lol
				forloopindent -= 1
			elseif op == "GETTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				tretval[i] = tretval[i] .. addlocal(arg1).. arg1.. " = " .. arg2 .. "[" .. arg3 .. "]"
				print(line,i,reg[arg2], reg[arg3])
				reg[arg1] = returnvalue(arg2) .. "[" .. returnvalue(arg3) .. "]"
			elseif op == "BREAK" then
				noline = true --breakpoint?
			elseif op == "GETGLOBAL" then
				local arg1 = word[2]
				local arg2 = string.sub(word[4],2, #word[4]-1)
				tretval[i] = tretval[i] .. addlocal(arg1).. arg1 .." = _G[" .. arg2 .. "]"
			elseif op == "GETVARARGS" then
				noline = true
			elseif op == "PREPVARARGS" then
				--noline = true
				local count = tonumber(word[2]) + 1
				local params = {}
				for i = 1, count do
					table.insert(params, "R".. i-1)
				end
				funcsattribute[curfunc][2] = params
			elseif op == "FORGLOOP" then
				tretval[i] = tretval[i] .. "end\n"
				forloopindent -= 1
			elseif op == "FORGPREP_INEXT" then
				local arg1 = word[2]
				local rawa1 = tonumber(string.sub(arg1,2,#arg1)) + 6
				local psarg1 = "R".. tostring(rawa1) 
				local apsa2 = tonumber(string.sub(arg1,2,#arg1)) + 4
				local psarg2 = "R".. tostring(apsa2) 
				tretval[i] = tretval[i] .. "for ".. psarg1 ..", " .. psarg2 .. " in ".. creg["FORGLOOPINEXT"] .. " do"
				forreg[psarg1] = true
				forreg[psarg2] = true
				forloopindent += 1
			else
				tretval[i] = tretval[i] .. "--" .. line
			end
			print(1,table.concat(varnames,", "))
			for v, name in pairs(varnames) do
				if reg[v] ~= regcpy[v] or creg[v] ~= cregcpy[v] then
					varnames[v] = nil
					print("cleared varname", v,name,gettotallines())
				else
					if tretval[i] then
						tretval[i] = string.gsub(tretval[i], v, name)
					end
					
				end
				print(1)
			end

			
			if noline == false then
				tretval[i] = tretval[i] .. "\n"
			else
				noline = false
			end
			
			--local newestif = 0
			--[[for ix, v in currentjumpindex do
				if ix > newestif then
					newestif = ix
				end
			end]]
			iselseif = false
		else
			skipline = false
		end
	end
	local funcpos = {}
	for i, v in ipairs(funcsattribute) do
		
		local name = v[1]
		local params = v[2]
		local line = v[3]
		funcpos[i] = line
		tretval[line] = "function " .. name .. "(" .. table.concat(params, ", ") .. ")\n"
	end
	for i, v in ipairs(tretval) do
		for ix, vx in ipairs(funcpos) do
			if i ~= vx then
				for ixx, vxx in ipairs(funcsattribute) do
					local name = vxx[1]
					local params = vxx[2]
					local line = vxx[3]
					tretval[i] = string.gsub(tretval[i],"PROTO_"..ixx,name)
				end
			end
		end
		
	end
	retval = table.concat(ups,"\n") .. "\n" .. table.concat(tretval,"\n")
	retval = [[
--Created by ToastedSoup's tool "luaudecomp" 
--tool version 0.3.0
--made with love <3
]]..retval
	return retval
end
return module

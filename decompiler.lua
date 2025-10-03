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
	--//UPVALUES// a very basic and bad implementation of upvalues.
	local upvalindex = 0 --handling upvals differently compared to how the compiler does it, aka dont clear this value. 
	local dubindex = 0 
	local funcindex = 0
	local funcvarsamt = 0
	local initindex = 0
	local biggestindex = 0

	--constants wont be needed because the bytecode itself already contains them. aka word[constant+1] (not how my code handles it)
	--//MISC//
	local jumpindexes = {} --for ifstatements :D
	local currentjumpindex = {}
	local namecallstr = "" --namecall.. name
	local namecall = false --is next func call actually an extention of namecall?
	local skipline = false --no next line :D
	local noline = false --dont do newline, because this line doesnt contain anything
	local funcend = false --just for functions/protos
	local iselse = false
	local iselseif = false
	local requirecall = "" --my code doesnt work good with require for somereason and cuz doing it like this makes requires look cleaner
	local requirebool = false --is require being used? (only really needed for CALL)
	local importname = ""
	local retval = [[
]]
	print("lines:",#lines)
	for i, line in ipairs(lines) do
		local word = string.split(line, " ")
		local op = word[1]
		
		for ix, v in jumpindexes do
			if jumpindexes[ix] == 1 then
				local nextline = line
				local c = nextline.match(nextline," ")
				if c and (nextline:split(" ")[1]:sub(1,6) == "JUMPIF" )then
					iselseif = true
					jumpindexes[ix] = 0
				end
			end
		end
		
		if skipline == false then
			if op == "JUMPIFNOT" then
				--aka if arg1 then
				local arg1 = word[2]
				local arg2 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if " .. arg1 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
					
					end
				end

			elseif op == "NOP" then
				retval = retval .. "--NOP"
			elseif op == "JUMPIF" then
				local arg1 = word[2]
				local arg2 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if not " .. arg1 .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
					else
						retval = retval .. "elseif not " .. arg1 .. " then"
					end
				end

			elseif op == "RETURN" then
				local arg1 = word[2]
				local arg2 = word[3]
				local a = arg1
				if arg2 ~= "0" then
					for i=1, tonumber(arg2) do
						a = a .. ", R" .. tostring(i)
					end
				end
				if a == "R0" then
					retval = retval .. "--no return probably, but register 0"
				else
					retval = retval .. "return " .. a
				end
			elseif op == "LOADNIL" then
				local arg1 = word[2]
				reg[arg1] = "nil" -- cuz nil will break my code lol
				retval = retval ..  arg1 .. " = nil"
			elseif op == "LOADN" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = arg2
				retval = retval ..  arg1 .. " = " .. arg2
			elseif op == "LOADB" then
				local arg1 = word[2]
				local arg2 = word[3]
				local bool = (arg2 == "1")
				reg[arg1] = bool
				retval = retval ..  arg1 .. " = " .. tostring(bool)
		
			elseif op == "SETTABLEKS" then
				local arg1 = word[2]
				local arg2 = tostring(word[3])
				local arg3 = word[5]
				local convregarg2 = tostring(reg[arg2])
				print(convregarg2)
				if string.sub(convregarg2, 1,2) == "RT" or  string.sub(convregarg2, 1,2) == "IM" then --weird fix but ok
					reg[arg1] =  "RT"..string.sub(reg[arg2], 3, #reg[arg2]) .. arg3
					
				elseif string.sub(convregarg2, 1,1) == "{" then
					
					reg[arg1] = string.sub(arg3, 2, #arg3-1)
				elseif convregarg2 == "nil" then
					reg[arg1] = string.sub(arg3,2,#arg3-1)
					
				else
					reg[arg1] =  "RT"..tostring(reg[arg2]) ..tostring(arg3)
				end
				retval = retval .. arg2 .. arg3 .. " = "  .. arg1 

			elseif op == "GETIMPORT" then
				local arg1 = word[2]
				local arg2 = word[4]
				--if string.sub(arg2,2,#arg2 - 1) ~= "require" then
				--	reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1) 
				--	retval = retval ..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
				--else
				local val = string.sub(arg2, 2, #arg2 - 1)

				local blacklist = {
					require = true,
					print = true,
					error = true,
					warn = true,
					
				}
				
				--print(string.sub(arg2,2,#arg2 - 1) == ("Enum" or "game" or "plugin" or "shared" or "script" or "workspace"), string.sub(arg2,2,#arg2 - 1))
				if blacklist[val] then
					reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1)
					requirebool = true
				requirecall = ""
				importname = string.sub(arg2,2,#arg2 - 1)
						noline = true
				else
					reg[arg1] =  "IM"..string.sub(arg2,2,#arg2-1) 
					retval = retval ..  arg1 .. " = " .. string.sub(arg2,2,#arg2 - 1)
					requirebool = false
					requirecall = ""
				end
				
			elseif op == "GETTABLEKS" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[5]
				if requirebool ~= true then
				
					reg[arg1] =  "RT"..arg2 ..arg3 
					retval = retval ..  arg1 .. " = " .. arg2 .. arg3
				else
					noline = true
				end
				--doesnt really matter if we do the check here
				
				if requirecall == "" then
					requirecall = requirecall .. arg2 .. arg3
				else
					requirecall = requirecall .. arg3
				end
			elseif op == "NAMECALL" then
				-- A: target register, B: source register, AUX: constant table index (method name)
				local target = word[2]:match("%d+")  -- strip R and get digits
				local source = word[3]:match("%d+")
				local methodName = string.sub(word[5],3,#word[5]-2) or "UNKNOWN"
				namecall = true
				namecallstr = "R" .. source .. ":" .. methodName
				noline = true

			elseif op == "CALL" then
				local rawA = word[2]:gsub("R",""):match("%d+")
				local A = tonumber(rawA)
				local B = tonumber(word[3]:match("%-?%d+")) -- arguments count + 1
				local C = tonumber(word[4]:match("%-?%d+")) -- results count + 1

				-- build arguments (normal/namecall only)
				local args = {}
				if B >= 1 then
					for i = 1, B do
						table.insert(args, "R" .. tostring(A + i))
					end
				elseif B == 0 then
					table.insert(args, "") -- MULTRET
				end

				-- base call string
				local callStr
				if requirebool then
					-- Special handling for require
					requirebool = false
					callStr = importname .."(" .. requirecall .. ")"
				elseif namecall then
					-- Method call
					namecall = false
					callStr = namecallstr .. "(" .. table.concat(args, ", ") .. ")"
				else
					-- Normal call
					callStr = "R" .. A .. "(" .. table.concat(args, ", ") .. ")"
				end

				-- Handle return values
				if C == 1 then
					retval = retval .. callStr
				elseif C == 2 then
					retval = retval .. "R" .. A .. " = " .. callStr
				elseif C > 2 then
					local rets = {}
					for i = 0, C - 2 do
						table.insert(rets, "R" .. tostring(A + i))
					end
					retval = retval .. table.concat(rets, ", ") .. " = " .. callStr
				elseif C == 0 then
					retval = retval .. callStr
				else
					retval = retval .. callStr
				end
			


			elseif line == "" then
				if funcend == true then
					initindex += funcvarsamt
					funcvarsamt = 0
					biggestindex = 0
				retval = retval .. "end --FUNCEND?"
				funcend = false
				end
			elseif line == "MAIN:" then
				skipline = true
				noline = true
				reg = {}
			elseif line:match":" and line:match"PROTO_" then
				if funcend == false then
				local funcname = string.sub(line,1,#line-1)
					local func = tonumber(string.sub(line,7,#line-1))
					retval = retval .. "function " .. funcname .. "()"
					reg = {}
				end
				funcend = true
			elseif op == "DUPCLOSURE" then
				local arg1 = word[2]
				local arg2 = word[4]    
				arg2 = string.sub(arg2,2,#arg2 - 1)
				retval = retval .. tostring(arg1) .. " = " .. arg2
			elseif op == "DUPTABLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local garb = #("DUPTABLE  "..arg1.. " [" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb + 1,#line - 1)
				reg[arg1] = tablea
				retval = retval ..  arg1 .. " = " .. tablea
				--CONCAT
			elseif op == "CONCAT" then
				local arg1 = word[2]
				local arg2 = word[3]  
				local arg3 = word[4]  
				reg[arg1] =  arg2 .. arg3
				retval = retval ..  arg1 .. ' = ' .. arg2 .. ".." .. arg3
			elseif op == "LOADK" then
				local arg1 = word[2]
				local arg2 = word[4]
				
				local garb = #("LOADK "..arg1.. " as[" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb,#line - 1)
				reg[arg1] =  tablea --cant see type, if you try type() on it, it'd just return as string
				if requirebool == false then
				retval = retval ..  arg1 .. " = " .. tablea
				else
					requirecall = requirecall .. tablea
				end
				
				--local arg1 = word[2]
				--local arg2 = string.sub(word[4],2,#word[4]-1)
				--retval = retval ..  arg1 .. " = " .. arg2
			elseif op == "SETGLOBAL" then
				local arg1 = word[2]
				local arg2 = word[4]

				local garb = #("SETGLOBAL "..arg1.. " as[" .. word[3])
				--DUPTABLE R1 K4 [{"getTheme", "isDarkerTheme", "themeChanged"}]
				local tablea = string.sub(line,garb,#line - 1)
				reg[arg1] =  tablea --cant see type, if you try type() on it, it'd just return as string
				retval = retval .. '_G["'.. arg1 .. '"] = ' .. tablea
			elseif op == "JUMPIFLT" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						retval = retval .. "if " .. arg1 .. " >= " .. arg3 .. " then"
						jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " >= " .. arg3 .. " then"
					end
					
				end
			elseif op == "JUMPIFLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
						retval = retval .. "if " .. arg1 .. " > " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " > " .. arg3 .. " then"
					end
				end
			elseif op == "JUMPIFEQ" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					
					retval = retval .. "if " .. arg1 .. " ~= " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " ~= " .. arg3 .. " then"
					end
				end
			elseif op == "JUMPIFNOTEQ" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if " .. arg1 .. " == " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " == " .. arg3 .. " then"
					end
				end
			elseif op == "JUMPIFNOTLE" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if " .. arg1 .. " <= " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
					currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " <= " .. arg3 .. " then"
					end
				end
			elseif op == "JUMPIFNOTLT" then
				local arg1 = word[2]
				local arg2 = word[4]
				local arg3 = word[3]
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if " .. arg1 .. " < " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
						currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " then"
					end
				end
			elseif op == "JUMPIFNOTEQKS" then
				local arg1 = word[2]
				local arg2 = word[5]
				local arg3 = string.sub(word[4],2,#word[4]-1) 
				if string.match(arg2,"%[") and arg2 ~= nil then
					if iselseif == false then
					retval = retval .. "if " .. arg1 .. " == " .. arg3 .. " then"
					jumpindexes[i] = tonumber(string.sub(arg2,3,#arg2-1)) + 1
					currentjumpindex[i] = i
					else
						retval = retval .. "elseif " .. arg1 .. " == " .. arg3 .. " then"
					end
				end
			
			elseif op == "ADD" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 + arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " + " .. arg3
			elseif op == "SUB" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 - arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " - " .. arg3
			elseif op == "MUL" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 * arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " * " .. arg3
			elseif op == "DIV" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 / arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " / " .. arg3
			elseif op == "MOD" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 % arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " % " .. arg3
			elseif op == "POW" then
				local arg1 = word[2]
				local arg2 = tonumber(reg[word[4]])
				local arg3 = tonumber(reg[word[3]])
				reg[arg1] = arg2 ^ arg3
				retval = retval ..  arg1 .. " = " .. arg2 .. " ^ " .. arg3
			elseif op == "ADDK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = word[3]
				
				print(arg2, arg3, reg[arg3], line)
				--reg[arg1] =  arg2 + tonumber(reg[arg3])
				retval = retval ..  arg1 .. " = " .. arg2 .. " + " .. arg3
			elseif op == "SUBK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = tonumber(reg[word[3]])
				--reg[arg1] =  arg2 - reg[arg3]
				retval = retval ..  arg1 .. " = " .. arg2 .. " - " .. arg3
			elseif op == "MULK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = tonumber(reg[word[3]])
				--reg[arg1] =  arg2 * reg[arg3]
				retval = retval ..  arg1 .. " = " .. arg2 .. " * " .. arg3
			elseif op == "DIVK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = tonumber(reg[word[3]])
				--reg[arg1] =  arg2 / reg[arg3]
				retval = retval ..  arg1 .. " = " .. arg2 .. " / " .. arg3
			elseif op == "MODK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = tonumber(reg[word[3]])
				--reg[arg1] =  arg2 % reg[arg3]
				retval = retval ..  arg1 .. " = " .. arg2 .. " % " .. arg3
			elseif op == "POWK" then
				local arg1 = word[2]
				local arg2 = tonumber(string.sub(word[5],2,#word[5]-1))
				local arg3 = tonumber(reg[word[3]])
				--reg[arg1] = arg2 ^ reg[arg3]
				retval = retval ..  arg1 .. " = " .. arg2 .. " ^ " .. arg3
			elseif op == "MOVE" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = reg[arg2]
				retval = retval ..  arg1 .. " = " .. arg2 --simple as that :D
			elseif op == "NOT" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = not arg2
				retval = retval ..  arg1 .. " = not " .. arg2 --simple as that :D
			elseif op == "GETUPVAL" then
				--here we go :D
				local arg1 = word[2]
				local arg2 = word[3]
				if tonumber(arg2) > biggestindex then
					funcvarsamt += 1
					biggestindex = tonumber(arg2)
				end
				retval = retval ..  arg1 .. " = " .. "UP" .. tonumber(arg2) + initindex + 1
			elseif op == "CAPTURE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local re = tostring(reg[arg2])
				local rem = ""
				if re and string.sub(re, 1, 2) == "RT" then
					re = string.sub(reg[arg2], 2, #reg[arg2])
					local item = re
					local pos = string.find(item, "%[")
					re = string.sub(re, pos, #re)
					re = string.sub(tostring(reg[string.sub(item,1,pos-1)]),pos,#tostring(reg[string.sub(item,1,pos-1)])) .. re
					rem = "RT"
				elseif re and string.sub(re, 1, 2) == "IM" then
					re = string.sub(reg[arg2], 3, #reg[arg2])
					-- no extra processing needed
					rem = "IM"
				else
					re = tostring(reg[arg2])
					-- i dont wanna do this :sob:
				end
				if string.sub(re, 1, 1) == "[" then
					local b = string.find(reg[arg2],"%[")
					re = string.sub(reg[arg2], b+1, #reg[arg2]-1)
				end
				
				print(upvalindex, reg[arg2], arg2, re)
				retval = retval .. "--OPCODE CAPTURE UP".. upvalindex .. " reg " .. arg2 .. " type " .. arg1
				--here we go 2.0 :D
				retval = "local UP".. upvalindex
					.. " = "
					..re.. "; \n" 
					.. retval -- retval after variables
				
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
				reg[arg1] = "PROTO_"..string.sub(arg2,2)
				retval = retval .. arg1 .. " = " .. funcname
			elseif op == "CLOSEUPVALS" then
				noline = true
			elseif op == "GETGLOBAL" then
				local arg1 = word[2]
				local arg2 = word[4]
				arg2 = string.sub(arg2, 2, #arg2-1)
				retval = retval ..  arg1 .. " = " .. arg2
			elseif op == "IDIV" then --doesnt explain anything, basically floor division.
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				retval = retval .. "local ".. arg1 .. " = " .. arg2 .. " // " .. arg3
			elseif op == "IDIVK" then -- same above, but arg3 is a constant.
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				retval = retval .. "local ".. arg1 .. " = " .. arg2 .. " // " .. arg3
			elseif op == "SUBRK" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				retval = retval .. "local ".. arg1 .. " = " .. arg2 .. " - " .. arg3
			elseif op == "DIVRK" then --rk means register-constant
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = string.sub(word[5], 2,#word[5]-1) 
				retval = retval .. "local ".. arg1 .. " = " .. arg2 .. " / " .. arg3
			elseif op == "NEWTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				print(arg2)
				reg[arg1] = "{}"
				retval = retval ..  arg1 .. " = {}" -- yeah idc cuz it's not like luau uses this anyway. (the size part)
			elseif op == "JUMP" then
				local arg1 = word[2]
				local number = string.sub(arg1, 3, #arg1-1) -- 3 instead of 2 because of of the + character
				if iselse == true then
					retval = retval .. "else --proven to be else"
				else
					retval = retval .. "break --could also be anything else"
				end
				--jumpindexes[i] = number + 1 --because this line will also remove 1 from this index
				
			elseif op == "SETTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				--i suspect that arg2 or arg3 will be the table and other one is the value and the table and arg1 will be the updated table
				--reg[arg2][reg[arg3]] = reg[arg1]
				reg[arg2] = "{}"
				retval = retval ..  arg2 .. " = {}"
			
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

				-- handle MULTRET (C == 0 → all values from B..top)
				local count = (C == 0) and "..." or (C - 1)

				if C == 0 then
					retval = retval .. ("-- SETLIST: R%d from R%d to top starting at %d"):format(A, B, AUX)
				else
					for i = 0, count - 1 do
						retval = retval .. ("R%d[%d] = R%d"):format(A, AUX + i, B + i)
					end
				end
				retval = retval .. "--" .. line
			elseif op == "LENGTH" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = #arg2
				retval = retval .. "local ".. arg1 .." = #" .. arg2
			elseif op == "FASTCALL1" then
				noline = true
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
				retval = retval .. "for " .. arg1 .." = ".. reg[arg1] ..", ".. arg2 ..", ".. arg3 .. " do"
			elseif op == "MINUS" then
				local arg1 = word[2]
				local arg2 = word[3]
				reg[arg1] = arg2
				retval = retval .. arg1 .. " = -" .. arg2
			elseif op == "SETUPVAL" then
				local arg1 = word[2]
				local arg2 = word[3]
				retval = retval .."UP" .. tonumber(arg2) + initindex + 1 .. " = " ..  arg1
			elseif op == "FORNLOOP" then
				retval = retval .. "end" --basically lol
			
			elseif op == "GETTABLE" then
				local arg1 = word[2]
				local arg2 = word[3]
				local arg3 = word[4]
				reg[arg1] = reg[arg2][arg3]
				retval = retval .. "local ".. arg1.. " = " .. arg2 .. "[" .. arg3 .. "]"
			elseif op == "BREAK" then
				noline = true
			elseif op == "GETGLOBAL" then
				local arg1 = word[2]
				local arg2 = string.sub(word[4],2, #word[4]-1)
				retval = retval .. "local ".. arg1 .." = _G[" .. arg2 .. "]"
			else
				retval = retval .. "--" .. line
			end
			if noline == false then
				retval = retval .. "\n"
			else
				noline = false
			end
			--local newestif = 0
			--[[for ix, v in currentjumpindex do
				if ix > newestif then
					newestif = ix
				end
			end]]
			for ix, v in jumpindexes do
				if jumpindexes[ix] == 1 then
					local nextline = lines[i+1]
					local c = nextline.match(nextline," ")
					if c and (nextline:split(" ")[1] == "JUMP" )then -- check if the next line has a space and then if so, check if the next line is a jump, and nothing else. so that normal ifstatements dont get caught up
						iselse = true
						jumpindexes[ix] = 0
					else
						--if newestif == ix then
							jumpindexes[ix] = 0
							retval = retval .. "end\n"
						--end
					end
					
				end
				if jumpindexes[ix] > 0 then
					jumpindexes[ix] = jumpindexes[ix] - 1
				end
			end
			iselseif = false
		else
			skipline = false
		end
	end
	retval = [[--!nonstrict
--Created by ToastedSoup's tool "luaudecomp" 
--tool version 0.1.0
--made with love <3
]]..retval
	return retval
end
return module

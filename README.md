# LuauDecomp
A Luau decompiler inside of luau (not based on any other decompilers) that only accepts preserialized and preformatted bytecode.  
# About
This decompiler isnt really meant for any production uses,  
since this decompiler is really not the best and doesnt create normal lua code,  
aka there's no way someone would think the code that was created by this would be mistaken as code from human.  
there's like a 90% chance your code works off the bat without modifying the code (around 200 lines of code is this estimate),  
but the less functions the higher of the chance, and the less those functions use upvalues the better.
this decompiler is meant to return functional, but not pretty lua code(use your own lua prettifier?).  
this decompiler was original meant for [RobloxClientTracker](https://github.com/MaximumADHD/Roblox-Client-Tracker/tree/roblox)'s preformatted code.
# How To Use
put the code in a modulescript and require() it using a localscript  
or dont, idc

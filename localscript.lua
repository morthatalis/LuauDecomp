local path = [SET PATH TO A STRINGVALUE/TEXTBOX OBJECT HERE]

local a = require(script.decompiler)
local c = require(script.prettifier)
local b =  c.format(a.decompileluac(path)) 
script.Parent.Text = b

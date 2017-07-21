
local tlogFileName = "tUpdater.log"
function tlog(data,filename,byDate)
	--if type(data) ~= "table" and type(data) ~= "string" then data = tostring(data) end
	if type(data) ~= "string" then data = tostring(data) end
	if byDate then 
		filename = filename and "_" .. filename or ".lua"
		filename = os.date("%Y_%m_%d" .. filename)
	end
	
	--[[
	local text = "\n\t"
	if type(data) == "table" then
		for k , v in pairs(data) do
			text = text .. tostring(k) .. " : " .. tostring(v) .. "\n\t"
		end
		data = text
	end
	--]]
	
	local  Path = "mods/logs/"
	local  Name = filename and Path .. filename or Path .. tlogFileName
	local  file = io.open(Name, "a+")
	if not file then 
		log("LogERROR by Tast's Utils")
		return nil
	end
	
	local Time = byDate and os.date("%H:%M:%S: ") or os.date("%Y/%m/%d %H:%M:%S: ")
	local Text = Time .. data .. "\n"
	file:write(Text)
	file:close()
	--log(data)
	return Text
end

function tlogArray(table,Separator)
	if type(table) ~= "table" then return end
	local text = ""
	for i , v in pairs(table) do
		if type(i) ~= "number" then 
			--tPrintTableNameList(table)
			return
		end
		text = text .. ( Separator or " " ) .. tostring(v)
	end
	tlog(text:sub(2))
    return text:sub(2)
end

-- https://www.lua.org/pil/5.2.html
-- Variable Number of Arguments
function tlogArgSyntax(...)
    local Syntax = {" " , " "}
    local text = ""
    for i,v in ipairs(arg) do
        --tlog(type(v) .. " " .. tostring(v) )
        if type(v) == "number" then Syntax = {"[" ,"]" }  end
        if type(v) == "string" then Syntax = {"\"","\""}  end
        if type(v) == "table"  then Syntax = {"{" ,"}" }  end
        if type(v) == "boolean"then Syntax = {"(" ,")" }  end
        text = text .. Syntax[1] .. tostring(v) .. Syntax[2]
    end
    tlog(text)
    return text , #arg , arg
end

function tPrintTableNameList(table)
    if type(table) ~= "table" then return end
    local i     = 0
    local text  = ""
	for k , v in pairs(table or {}) do i = i + 1
        text = text ..  "\n\t/ " .. tostring(k) .. " / " .. tostring(v)
    end
    tlog("Table Items: " .. tostring(i) .. text)
end

function tPrintTable( tbl, cmp )
	cmp = cmp or {}
	if type(tbl) == "table" then
		for k, v in pairs (tbl) do
			if type(v) == "table" and not cmp[v] then
				cmp[v] = true
				tlog( string.format("[\"%s\"] = table", tostring(k)) );
				tPrintTable (v, cmp)
			else
				tlog( string.format("\"%s\" = %s", tostring(k), tostring(v)) )
			end
		end
	else tlog(tbl) end
end

function tMakeDir(dir) dir = "./" .. dir .. "/"
    if SystemFS:exists(dir) then return true , {} end
	while dir:find("//") ~= nil do dir = dir:gsub("//","/") end
	-- https://www.lua.org/pil/20.1.html
	local t = {} 
    while true do
        local i = dir:find("/", i + 1)
        if i == nil then break end
        table.insert(t, { i , SystemFS:make_dir(dir:sub(1,v)) , dir:sub(1,i)})
    end
	--tPrintTable(t)
    return #t > 0 and t[#t][2] , t
end

function tReadFile(path,jsonType)
    local  file = io.open(path, "r")
	if not file   then return nil , "can't read file" end
	local  fileT= file:read("*all")
		   file : close()
    if jsonType then
           fileT= fileT:gsub("%[%]","{}") 
        if fileT== "{}" or fileT == "" then return false , "none data" end
        local  psuccess,    perror =  pcall(function() return json.decode(fileT) end)
        return psuccess and perror or false , perror or fileT
        --return psuccess and perror or false , perror or "json error"
    end
    return fileT
end

function tSaveJson(path,table)
    local  	file = io.open( path, "w" )
	if not 	file then return nil , "can't write file" end
	file:write( json.encode( table ):gsub("%[%]","{}") )
	file:close()
    return true
end

function tGetGameVersion()
	local  file = io.open("game.ver", "r")
	if not file then 
		tlog("GetGameVersion: Error:Can't read game.ver file.")
		return nil , "Can't read game.ver file."
	end
	local ver = file:read("*all")
	file:close()
	return ver
end

--[[
local jsonText = tReadFile("mods/ccc.json")
local validJson = require "mods/tUpdater/validJson.lua"
tlog(validJson(jsonText))
--]]
--[[
function FakeRequire(path) return assert(loadstring(tReadFile(path)))() end

local jsonText = tReadFile("mods/tUpdater/mod.txt")
local validJson2 = FakeRequire("mods/tUpdater/validJson.lua")
tlog(validJson2(jsonText))
tlog(validJson(jsonText))
tlog(validJson2(jsonText))
--]]
--[[
dofile("mods/tUpdater/validJson.lua")

local  file = io.open("mods/ccc.json", "r")
if not file   then return end
local  fileT= file:read("*all")
       file : close()
       
tlog(validJson(fileT))

local psuccess, perror = pcall(function()
    --local json = json.decode(fileT)
    tlog(json)
end)
--]]
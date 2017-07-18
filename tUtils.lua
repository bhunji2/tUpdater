
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
	local  Name = filename and Path .. filename or Path .. "logs.lua"
	local  file = io.open(Name, "a+")
	if not file then 
		log("LogERROR by Tast's Utils")
		return nil
	end
	
	local Time = os.date("%Y/%m/%d %H:%M:%S: ")
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
end

function tPrintTableNameList(table)
	for k , v in pairs(table) do
		tlog("/ " .. tostring(k) .. " / " .. tostring(v) )
	end
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
	else
		tlog(tbl)
	end
end
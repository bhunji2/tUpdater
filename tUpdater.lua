dofile("mods/tUpdater/tUtils.lua")

tlog("/ tUpdater")
tUpdater = tUpdater or 
{
	 mods 		= { }
	,path_mod	= ModPath
	,path_save	= SavePath
	,theard 	= 4
	,counter	= 0
    ,updating   = { }
}

--------------------------------------------------------------------------------------------------------------------
-- Load All mod.txt then start check
function tUpdater:LoadingAll() tlog("/ tUpdater:LoadingAll")
	for i, file in ipairs( SystemFS:list("mods/",true) ) do self:LoadMod( file ) end
	self:UpdateCheck()
end
-- Load mod.txt
function tUpdater:LoadMod( fileName ) --tlog("/ tUpdater:LoadMod " .. fileName)
	local  file = io.open("mods/" .. fileName .. "/mod.txt", "r")
	if not file   then return end
	local  fileT= file:read("*all"):gsub("%[%]","{}") 
		   file : close()
	
	if fileT == "[]" or fileT == "" then return end
	
	local json = json.decode(fileT)
	if json["tUpdates"] ~= nil then 
		tlog("/ tUpdater:LoadMod " .. json.name)
		table.insert(self.mods,json)
		self.mods[#self.mods].dir_mod 	= fileName
		self.mods[#self.mods].index 	= #self.mods
	end
end
-- Start multi checking
function tUpdater:UpdateCheck(counter)
	if counter == nil then
		for i = 1 , self.theard , 1 do self:UpdateCheck(i) end
		return
	elseif not self.mods[counter] then return end
    if counter > self.counter then self.counter = counter end
    
	for i, mod in ipairs( self.mods[counter]["tUpdates"] or {} ) do 
        local http_id = dohttpreq( mod.url_ck, tUpdater.DownloadFinished, tUpdater.Downloading )
        self.updating[http_id] = { i = i , id = counter , http_id = http_id , state = "checking" }
        tlog("/[tUpdates] Started http download: " .. tostring(i) .. " - " .. tostring(http_id) .. " - " .. mod.url_ck)
    end
end

function tUpdater.Downloading( http_id, bytes, total_bytes )
    tlog("/[tUpdates] Downloading: " .. tostring(id))
    tPrintTable({ http_id=http_id, bytes=bytes, total_bytes=total_bytes })
end

function tUpdater.DownloadFinished( data, http_id )
    local psuccess, perror = pcall(function()
        if data:is_nil_or_empty() then
            tlog("/[tUpdates] Update failed, no data received!") 
            tUpdater.updating[http_id].state    = "error"
            tUpdater.updating[http_id].msg      = "is_nil_or_empty"
            return
        end
        
        tlog("/[tUpdates] Finished http download: " .. tostring(http_id))
        --tlog("/[tUpdates] " .. tostring(data))
        
        if tUpdater.updating[http_id].state == "checking" then
            tUpdater:CheckingVersion(http_id,data)
        end
    end)
    
	if not psuccess then
		tlog("/[tUpdates] Error: " .. perror)
        self.updating[http_id].state    = "perror"
        self.updating[http_id].msg      =  perror
	end
end

function tUpdater:CheckingVersion( http_id , data ) tlog("/[tUpdates] CheckingVersion: " .. tostring(http_id))
    local json  = json.decode(tostring(data))
    local mod   = self.mods     [self.updating[http_id].id]
    local tUpd  = mod.tUpdates  [self.updating[http_id].i ]
    
    tlog("/revision    / " .. tostring(tUpd.revision))
    tlog("/jsonVersion / " .. tostring(json.version))
    tlog("/modVersion  / " .. tostring(mod.version))
    
    if tUpd.revision == "self" and tonumber(json.version) > tonumber(mod.version) then
        tlog("/[tUpdates] CheckingVersion: need update: " .. tostring(http_id))
    elseif tonumber(json.revision) > tonumber(tUpd.revision)
    end
end
-- Only start updater once or manually launch
if not PackageManager:loaded("core/packages/base") then
	DelayedCalls:Add( "OnlineCheckVersion_tUpdater", 1, tUpdater:LoadingAll())
end

--------------------------------------------------------------------------------------------------------------------
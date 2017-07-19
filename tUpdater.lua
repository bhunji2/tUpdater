dofile("mods/tUpdater/tUtils.lua")
tUpdater = tUpdater or 
{
	 mods 		= { }
	,path_mod	= ModPath
	,path_save	= SavePath
	,theard 	= 2
	,counter	= 0
    ,delay      = 5
    ,updating   = { }
	,updFullList= { }
    ,enabled    = true --to use
    ,state      =
    {
         modLoaded  = false
        ,menuInit   = false
		,menuOpen	= false
    }
}

--------------------------------------------------------------------------------------------------------------
function tUpdater:State(http_id , state , msg)
   -- tlog("[" .. tostring(http_id) .. "] " .. tostring(state) .. " - " .. tostring(msg) .. " <> " .. tostring(self.updating[http_id].state or "none"))
    --if copyData then self.updating[http_id] = copyData end
    if state ~= nil then self.updating[http_id].state = state end
    if msg   ~= nil then self.updating[http_id].msg   = msg   end
    return self.updating[http_id].state
end

function tUpdater:GetModIdByHttp_id(Http_id)
	return self.updating[http_id].mod_id
end

function tUpdater:GetUpdatesByIdentifier(id , name , mod_Data)
    mod_Data = mod_Data.tUpdates or self.mods[id] and self.mods[id].tUpdates or {}
    for i, data in ipairs( mod_Data ) do 
        if data.identifier == name then return data end
    end
    return nil
end
--------------------------------------------------------------------------------------------------------------
-- Load All mod.txt
function tUpdater:LoadingAll() tlog("/ tUpdater:LoadingAll")
	for i, file in ipairs( SystemFS:list("mods/",true) ) do self:LoadMod( file ) end
    self.state.modLoaded = true
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
function tUpdater:UpdateCheckList()
	self.updFullList = {}
	for i, mod in ipairs( self.mods or {} ) do 
		for i2, data in ipairs( mod["tUpdates"] or {} ) do 
			data.mod_id = i
			data.i 		= i2
			data.full	= #mod["tUpdates"]
			data.index	= #self.updFullList + 1
			table.insert(self.updFullList,data)
		end
	end
	SaveTable(self.updFullList,"updFullList.lua")
end

function tUpdater:UpdateCheck(counter)
	if counter == nil then
		self:UpdateCheckList()
		for i = 1 , self.theard , 1 do self:UpdateCheck(i) end
		return
	elseif not self.updFullList[counter] or counter > #self.updFullList then return end
    if counter > self.counter then self.counter = counter end
	
	local data = self.updFullList[counter]
	local http_id = dohttpreq( data.url_ck, tUpdater.DownloadFinished, tUpdater.Downloading )
    self.updating[http_id] = 
	{ 	 
		 i = counter
		,update_id 	= data.identifier 
		,mod_id 	= data.mod_id
        ,full       = data.full
		,http_id 	= http_id
		,state 		= "checking" 
	}
    tlog("/[tUpdates] Started http download: " .. tostring(i) .. " - " .. tostring(http_id) .. " - " .. data.url_ck)
end

function tUpdater.Downloading( http_id, bytes, total_bytes )
    if tUpdater:State(http_id) == "checking" then return end
	--tPrintTable({ http_id=http_id, bytes=bytes, total_bytes=total_bytes })
	--tlog(math.floor(bytes / total_bytes * 100))
	--tlogArray({"[",http_id,"]",bytes,"/",total_bytes,percent})
	
	local mod_id        = tUpdater.updating[http_id].mod_id
    local percent_new   = math.floor(bytes / total_bytes * 100)
    local percent_old   = tUpdater.updating[http_id].percent or 0
    local range         = percent_new - percent_old
    
    tUpdater.mods[mod_id].percent = ( tUpdater.mods[mod_id].percent or 0 ) + range
    tUpdater.updating[http_id].percent = percent_new
    
    local percent_total = math.floor(tUpdater.mods[mod_id].percent / tUpdater.updating[http_id].full)
    if percent_total < 10 then percent_total = "0" .. tostring( percent_total ) end
	tUpdater:SetModItemTitle(mod_id,  tostring( percent_total ))
	
    --tlog("/[tUpdates] Downloading: " .. tostring(http_id) .. tostring(percent_total))
    --if range > 0 then tlogArray({"/[tUpdates] Downloading:",http_id,percent_total,range}) end
end

function tUpdater.DownloadFinished( data, http_id )
    local psuccess, perror = pcall(function()
        if data:is_nil_or_empty() then
            tlog("/[tUpdates] Update failed, no data received!") 
            tUpdater:State(http_id,"error","is_nil_or_empty")
            return
        end
        
        tlog("/[tUpdates] Finished http download: " .. tostring(http_id) .. " - " .. tostring(tUpdater:State(http_id)))
        --tlog("/[tUpdates] " .. tostring(data))
        
        if 		tUpdater:State(http_id) == "checking" 
        then	tUpdater:CheckingVersion(http_id,data)
                tUpdater:SetModItemTitle(tUpdater.updating[http_id].mod_id," v")
		elseif 	tUpdater:State(http_id) == "updating" 
		then	tlog("/ updating complete")
				tUpdater:SetModItemTitle(tUpdater.updating[http_id].mod_id,"vv")
        end
    end)
    
	if not psuccess then
		tlog("/[tUpdates] Error: " .. perror)
        tUpdater:State(http_id,"perror",perror)
	end
end

function tUpdater:CheckingVersion( http_id , data ) tlog("/[tUpdates] CheckingVersion: " .. tostring(http_id))
    local json  = json.decode(tostring(data))
    local mod   = self.mods     	[self.updating[http_id].mod_id]
    local tUpd  = self.updFullList  [self.updating[http_id].i 	  ]
    --[[
    tlog("/revision    / " .. tostring(tUpd.revision))
    tlog("/jsonVersion / " .. tostring(json.version))
    tlog("/modVersion  / " .. tostring(mod.version))
    --]]
    if tUpd.revision == "self" and tonumber(json.version ) > tonumber(mod.version  )
    or tUpd.revision ~= "self" and tonumber(json.revision) > tonumber(tUpd.revision) then
        tlog("/[tUpdates] CheckingVersion: need update: " .. tostring(http_id))
        --
        local UpdateFileURL = self:GetUpdatesByIdentifier( nil , "tUpdater_self_Update" , json)["url_dl"]
        local http_id_DL = dohttpreq( UpdateFileURL, tUpdater.DownloadFinished, tUpdater.Downloading )
        self.updating[http_id_DL] = self.updating[http_id]
        self:State(http_id_DL , "updating" , "")
		tlog(UpdateFileURL)
        --]]
    end
end

-- Only start updater once or launch manually 
if not PackageManager:loaded("core/packages/base") then
	tlog("/ tUpdater start in " .. tostring(tUpdater.delay))
    tUpdater:LoadingAll()
	DelayedCalls:Add( "OnlineCheckVersion_tUpdater", tUpdater.delay, function() 
		tUpdater:UpdateCheck() 
		managers.menu:open_node( "tUpdater_MainMenu" )
	end)
end

--------------------------------------------------------------------------------------------------------------

function tUpdater:ModQuickMenu(mod_id)
	local title 	= tUpdater.mods[mod_id].name
	local message 	= tUpdater.mods[mod_id].description
	local options 	= {}
	options[1] = { text = "Exit" , is_cancel_button = true }
	options[2] = { text = "Check Version" }
	--options[2] = { text = "Disable Auto Check" }
	
	QuickMenu:new(title, message, options, true)
end

function tUpdater:SetModItemTitle(mod_id,title)
	if not tUpdater.state.menuInit then return nil end
	local item = self.mods[mod_id].menuItem
	if not item then return nil end
	local text_id_old = item:parameter("text_id")
	local text_id_new = self.mods[mod_id].name .. "[ " ..  title .. " ]"
	if text_id_old ~= text_id_new then
		item:set_parameter("text_id", text_id_new)
		if self.state.menuOpen then item:dirty() end
	end
	--tlogArray({ self.state.menuOpen , text_id_old , text_id_new })
	return item
end

Hooks:Add("MenuManagerInitialize", "",        function(menu_manager)
	MenuCallbackHandler.tUpd_Close_Options  = function(self) end
	MenuCallbackHandler.tUpd_Open_Options   = function(self, is_opening)
		tUpdater.state.menuOpen = is_opening
		--tlog("/ tUpd_Open_Options " .. tostring(is_opening))
		if not is_opening then return end
	end
    MenuCallbackHandler.tUpd_mod 		    = function(self, item)
        local mod_id = tonumber(item:name():sub(14))
		--tlog(item:name() .. tostring(mod_id))
		tUpdater:ModQuickMenu(mod_id)
	end
end)

Hooks:Add("MenuManagerSetupCustomMenus", "", function( menu_manager, nodes )
    MenuHelper:NewMenu( "tUpdater_MainMenu" )
end)

Hooks:Add("MenuManagerBuildCustomMenus", "", function( menu_manager, nodes )
    for k , v in pairs( tUpdater.mods ) do 
        MenuHelper:AddButton({
		--id 			= "tUpdater_" .. v.dir_mod,
		id 			= "tUpdater_mod_" .. tostring(v.index),
		title 		= v.name,
		desc 		= v.name,
		callback 	= "tUpd_mod",
		menu_id 	= "tUpdater_MainMenu",
		--priority 	= 100,
		localized	= false
        })
    end
	
	nodes["tUpdater_MainMenu"] = --nodes.main
		MenuHelper:BuildMenu	( "tUpdater_MainMenu", { area_bg = "none" , 
			focus_changed_callback = "tUpd_Open_Options" } )  
		
		MenuHelper:AddMenuItem	( nodes.lua_mod_options_menu, "tUpdater_MainMenu", "veritas_menuTitle", "veritas_menuDesc")
    
	local menu = MenuHelper:GetMenu( "tUpdater_MainMenu" )
	for k , v in pairs( tUpdater.mods ) do 
		tUpdater.mods[k].menuItem = menu:item("tUpdater_mod_" .. tostring(k))
	end
	
    tUpdater.state.menuInit = true
	
	--managers.menu:open_node( "tUpdater_MainMenu" )
end)

-- http://www.lua.org/manual/5.1/manual.html#5.7
--os.rename("mods/ccc", "mods/ccc2")
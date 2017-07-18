dofile("mods/tUpdater/tUtils.lua")

if tUpdaterTesting == true then return end
tUpdater = nil
tUpdaterTesting = true

dofile("mods/tUpdater/tUpdater.lua")

tUpdater:LoadingAll()

DelayedCalls:Add( "Test_tUpdater", 3, function()
    tUpdaterTesting = false
end)
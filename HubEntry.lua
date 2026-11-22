-- Nagas of Azeroth by DinX: its line in the "Addons of Azeroth" minimap list (Hub.lua).
local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	C_Timer.After(0, function()
		local hub = _G.AddonsOfAzerothHub
		if not hub then return end
		local NoA = ns.NoA
		hub:Register({
			key = "nagas", addon = ADDON,
			click = function() NoA.Map:Toggle() end,
			right = function() NoA:OpenSettings() end,
			shift = function() NoA.Naga:ToggleTest() end,
			tip = function(tt)
				local L = NoA.L
				tt:AddLine(L["Click: Naga map"], 1, 1, 1)
				tt:AddLine(L["Right-click: settings"], 1, 1, 1)
				tt:AddLine(L["Shift-click: test screen"], 1, 1, 1)
			end,
		})
	end)
end)

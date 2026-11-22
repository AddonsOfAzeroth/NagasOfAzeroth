-- Nagas of Azeroth by DinX: Razer Naga support for the "of Azeroth" family.
-- A bar laid out like your side plate, Shift/Ctrl/Alt pages, a test screen, the
-- Naga map (what every key does) and its export for the website. Your own key
-- presses only: one press is one cast, the add-on never casts by itself.
local ADDON, ns = ...

local NoA = CreateFrame("Frame", "NagasOfAzerothCore")
ns.NoA = NoA
_G.NagasOfAzeroth = NoA

NoA.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or "?"
NoA.modules = {}

local accountDefaults = {
	language = "auto",   -- "auto" follows Casters of Azeroth, else the game
	font = "roboto",
	fontOutline = false,
}
local charDefaults = {
	plate = "none",      -- "none", "12" (3 wide x 4 high), "6" (2 x 3) or "2" (mouse 4 above 5)
	bar = true,          -- a bar laid out like the plate, with the plate's keys bound to it
	layers = true,       -- Shift, Ctrl and Alt switch the bar to pages 2, 3 and 4
	rotationKey = true,  -- the Naga key of the spell Casters' rotation helper suggests, and its button glows
	blockPaging = true,  -- Shift + a plate key does not switch Blizzard's action bar page
	syncHealers = true,  -- Healers of Azeroth's hover keys use the same plate
	locked = true,       -- the bar can be dragged when unlocked (follows Casters when it is loaded)
	points = {},
	-- map = { ... }     -- the Naga map for the website (Map.lua), rewritten out of combat
}

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			merge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

function NoA:Print(...)
	print("|cff69ccf0Nagas of Azeroth|r:", ...)
end

local handlers = {}
function NoA:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		local ok = pcall(self.RegisterEvent, self, event)
		if not ok then handlers[event] = nil return end
	end
	table.insert(handlers[event], fn)
end

NoA:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if list then
		for i = 1, #list do list[i](event, ...) end
	end
end)

function NoA:NewModule(name)
	local m = { name = name }
	self.modules[#self.modules + 1] = m
	self[name] = m
	return m
end

local callbacks = {}
function NoA:Listen(msg, fn)
	callbacks[msg] = callbacks[msg] or {}
	table.insert(callbacks[msg], fn)
end
function NoA:Fire(msg, ...)
	for _, fn in ipairs(callbacks[msg] or {}) do fn(...) end
end

local issecret = issecretvalue or function() return false end
NoA.IsSecret = issecret

-- Run fn now, or as soon as combat ends (secure frames can't change in combat).
local afterCombat = {}
function NoA:OutOfCombat(key, fn)
	if not InCombatLockdown() then fn() else afterCombat[key] = fn end
end
NoA:On("PLAYER_REGEN_ENABLED", function()
	for k, fn in pairs(afterCombat) do
		afterCombat[k] = nil
		fn()
	end
end)

---------------------------------------------------------------------------
-- The other add-ons of the family (all optional)
---------------------------------------------------------------------------
function NoA:Casters()
	local c = _G.CastersOfAzeroth or _G.CasterKit
	if type(c) == "table" and type(c.char) == "table" then return c end
end

-- Healers of Azeroth and its Bindings module, when it is loaded and ready
function NoA:Healers()
	local h = _G.HealersOfAzeroth
	if type(h) ~= "table" or type(h.char) ~= "table" then return end
	local B = h.Bindings
	if type(B) ~= "table" or type(B.Plate) ~= "function" or type(B.SetPlate) ~= "function" then return end
	return h, B
end

function NoA:FramesLocked()
	local c = self:Casters()
	if c and type(c.char.bars) == "table" then return c.char.bars.locked ~= false end
	return self.char.locked ~= false
end

function NoA:SetFramesLocked(locked)
	self.char.locked = locked
	local c = self:Casters()
	if c and type(c.char.bars) == "table" then
		c.char.bars.locked = locked
		if c.Fire then c:Fire("SETTINGS", "bars") end
	end
	self:Fire("SETTINGS", "bars")
end

-- choose a plate: "none", "12", "6" or "2" (the bar follows out of combat)
function NoA:SetPlate(plate)
	if not (self.Naga and self.Naga.PLATES[plate]) and plate ~= "none" then return end
	self.char.plate = plate
	self:Fire("SETTINGS", "naga")
end

---------------------------------------------------------------------------
-- Public API for the family (Casters' rotation hint)
---------------------------------------------------------------------------
-- "7" or "Shift 7" for a spell on the Naga bar, plus its button and page; nil when it is not there
function NoA:KeyFor(name)
	if self.Naga then return self.Naga:KeyFor(name) end
end

-- glow the Naga button that holds this spell (nil: no glow); returns its key text
function NoA:Glow(name)
	if self.Naga then return self.Naga:Suggest(name) end
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
-- the plate and bar settings Casters of Azeroth kept before (once, for a new character)
local function migrate(char)
	local old = type(CasterKitCharDB) == "table" and CasterKitCharDB.naga
	if type(old) ~= "table" then return end
	for _, k in ipairs({ "plate", "bar", "layers", "rotationKey" }) do
		if old[k] ~= nil then char[k] = old[k] end
	end
	local pts = type(CasterKitCharDB.points) == "table" and CasterKitCharDB.points.naga
	if type(pts) == "table" then
		char.points = char.points or {}
		char.points.bar = pts
	end
end

NoA:On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	local fresh = type(NagasOfAzerothCharDB) ~= "table"
	NagasOfAzerothDB = type(NagasOfAzerothDB) == "table" and NagasOfAzerothDB or {}
	NagasOfAzerothCharDB = type(NagasOfAzerothCharDB) == "table" and NagasOfAzerothCharDB or {}
	if fresh then migrate(NagasOfAzerothCharDB) end
	merge(NagasOfAzerothDB, accountDefaults)
	merge(NagasOfAzerothCharDB, charDefaults)
	NoA.db = NagasOfAzerothDB
	NoA.char = NagasOfAzerothCharDB
	NoA.charDefaults = charDefaults
	local c = NoA:Casters()
	NoA.Style:LoadFont(c and c.db or NoA.db)
	for _, m in ipairs(NoA.modules) do
		if m.OnInit then pcall(m.OnInit, m) end
	end
end)

NoA:On("PLAYER_LOGIN", function()
	for _, m in ipairs(NoA.modules) do
		if m.OnEnable then
			local ok, err = pcall(m.OnEnable, m)
			if not ok then NoA:Print("|cffff5555" .. m.name .. ":|r " .. tostring(err)) end
		end
	end
	local c = NoA:Casters()
	if c and c.Listen then
		c:Listen("SETTINGS", function(group)
			if group == "bars" and NoA.Style then NoA.Style:UpdateMovers() end
		end)
	end
	if NoA.Style then NoA.Style:UpdateMovers() end
end)

---------------------------------------------------------------------------
-- Slash commands: /naga and /noa (Casters forwards /coa naga here)
---------------------------------------------------------------------------
SLASH_NAGASOFAZEROTH1 = "/naga"
SLASH_NAGASOFAZEROTH2 = "/noa"
SLASH_NAGASOFAZEROTH3 = "/nagasofazeroth"
SlashCmdList.NAGASOFAZEROTH = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	local L = NoA.L
	if msg == "" or msg == "config" or msg == "settings" then
		NoA:OpenSettings()
	elseif msg == "map" or msg == "kaart" then
		NoA.Map:Toggle()
	elseif msg == "test" then
		NoA.Naga:ToggleTest()
	elseif msg == "lock" or msg == "unlock" then
		NoA:SetFramesLocked(msg == "lock")
		NoA:Print(msg == "lock" and L["Frames locked."] or L["Frames unlocked: drag the Naga bar, type /naga lock when done."])
	else
		NoA:Print(L["/naga: settings. /naga map: the Naga map. /naga test: the test screen. /naga unlock: move the bar."])
	end
end

do
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_ACTION_BLOCKED")
	f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	f:SetScript("OnEvent", function(_, _, addon, func)
		if addon ~= ADDON then return end
		C_Timer.After(3, function() NoA:Print("|cffff5555blocked:|r " .. tostring(func)) end)
	end)
end

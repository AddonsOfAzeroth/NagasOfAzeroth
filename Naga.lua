-- Nagas of Azeroth by DinX: the Naga bar. A bar laid out like the side plate you
-- use (12, 6 or 2 buttons) with the plate's keys bound to it, Shift, Ctrl and Alt
-- as extra pages (Synapse's Hypershift), the Naga key of a spell for Casters'
-- rotation hint, a guard against Blizzard's bar paging on Shift + plate key, and
-- a test screen (/naga test) that shows which key arrives and what it does.
-- Your own key presses only: one press is one cast.
-- The Naga map and its export (NagasOfAzerothCharDB.map) live in Map.lua; the
-- export format is described at the top of that file and in NAGA.md.
local _, ns = ...
local NoA = ns.NoA
local L = NoA.L
local S = NoA.Style

local N = NoA:NewModule("Naga")
local LAB = LibStub("LibActionButton-1.0", true)
local LBG = LibStub("LibButtonGlow-1.0", true)

-- the plates as the thumb sees them: keys row by row, as Synapse sends them by
-- default. 12: 3 wide, 4 high (1 2 3 / 4 5 6 / 7 8 9 / 0 - =); 6: 2 x 3
-- (1 2 / 3 4 / 5 6); 2: mouse button 4 above 5. Healers of Azeroth's click
-- editor uses the same shapes and order.
local PLATES = {
	["12"] = { rows = 4, cols = 3, keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" } },
	["6"] = { rows = 3, cols = 2, keys = { "5", "1", "6", "2", "7", "3" } }, -- Synapse: left column 5 6 7, right column 1 2 3
	["2"] = { rows = 2, cols = 1, keys = { "BUTTON4", "BUTTON5" } },
}
N.PLATES = PLATES
N.PLATE_ORDER = { "none", "12", "6", "2" }

-- pages: no modifier, then Shift, Ctrl and Alt (Synapse's Hypershift sends these)
local LAYERS = {
	{ mod = "", short = "", key = "", label = "Plain" },
	{ mod = "SHIFT-", short = "S", key = "shift", label = "Shift" },
	{ mod = "CTRL-", short = "C", key = "ctrl", label = "Ctrl" },
	{ mod = "ALT-", short = "A", key = "alt", label = "Alt" },
}
N.LAYERS = LAYERS
N.DRIVER = "[mod:shift] 2; [mod:ctrl] 3; [mod:alt] 4; 1"
-- first action slot of each page: Right Bar 2 (37-48), then the slots of bars 5, 6 and 7
N.SLOTS = { 37, 145, 157, 169 }

local MAX = 12
local SIZE, GAP = 36, 4

N.bound = {}     -- full key ("SHIFT-7") -> { index, layer } while the Naga bar holds it
N.conflicts = {} -- full key -> Blizzard binding the Naga bar overrides
N.paging = {}    -- full key -> Blizzard's bar paging action on a modifier + plate key
N.blocked = {}   -- full key -> true while Nagas keeps it from paging

local function cfg() return NoA.char end

function N:Plate() return PLATES[cfg().plate] end

-- row and column of button i on a plate
function N:Position(i, plate)
	plate = plate or self:Plate()
	return math.floor((i - 1) / plate.cols) + 1, (i - 1) % plate.cols + 1
end

---------------------------------------------------------------------------
-- Key names
---------------------------------------------------------------------------
local MODNAME = { ALT = "Alt", CTRL = "Ctrl", SHIFT = "Shift" }

-- "SHIFT--" -> "-", "SHIFT-"; "ALT-CTRL-1" -> "1", "ALT-CTRL-"
local function splitKey(full)
	local base = full
	while true do
		local m = base:match("^(%u+)%-.")
		if not MODNAME[m] then break end
		base = base:sub(#m + 2)
	end
	return base, full:sub(1, #full - #base)
end
N.SplitKey = splitKey

local function keyText(key)
	local n = key:match("^BUTTON(%d+)$")
	if n then return "M" .. n end
	return key
end
N.KeyText = keyText

-- "SHIFT-7" -> "Shift 7", "BUTTON4" -> "M4" (sep "+": "Shift+7")
local function prettyKey(full, sep)
	local base, mods = splitKey(full)
	local out = {}
	for m in mods:gmatch("(%u+)%-") do out[#out + 1] = MODNAME[m] end
	out[#out + 1] = keyText(base)
	return table.concat(out, sep or " ")
end
N.PrettyKey = prettyKey

local LAYER_OF = { [""] = 1, ["SHIFT-"] = 2, ["CTRL-"] = 3, ["ALT-"] = 4 }
N.LAYER_OF = LAYER_OF

function N.BindingName(action)
	if not action or action == "" then return end
	local click = action:match("^CLICK ([^:]+)")
	if click then return L["click %s"]:format(click) end
	local n = _G["BINDING_NAME_" .. action]
	if not n and GetBindingName then n = GetBindingName(action) end
	return n or action
end
local bindingName = N.BindingName

-- Blizzard's bar paging: ACTIONPAGE1-6, NEXTACTIONPAGE, PREVIOUSACTIONPAGE
function N.IsPaging(action)
	if type(action) ~= "string" then return false end
	return action:match("^ACTIONPAGE%d+$") ~= nil or action == "NEXTACTIONPAGE" or action == "PREVIOUSACTIONPAGE"
end
local isPaging = N.IsPaging

local function blizzBinding(full)
	local a = GetBindingAction(full)
	if a == "" then return nil end
	return a
end
N.BlizzBinding = blizzBinding

---------------------------------------------------------------------------
-- What sits in an action slot (spell, item or macro) and its icon
---------------------------------------------------------------------------
local function spellName(id)
	if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
	return GetSpellInfo and (GetSpellInfo(id))
end

local function itemName(id)
	if C_Item and C_Item.GetItemNameByID then return C_Item.GetItemNameByID(id) end
	return GetItemInfo and (GetItemInfo(id))
end

local function clean(v)
	if type(v) == "string" and v ~= "" and not NoA.IsSecret(v) then return v end
end

function N.SlotName(slot)
	if not slot or not HasAction or not HasAction(slot) then return end
	local ok, kind, id, sub = pcall(GetActionInfo, slot)
	if not ok then return end
	local n
	if kind == "spell" then
		n = spellName(id)
	elseif kind == "item" then
		n = itemName(id)
	elseif kind == "macro" then
		if sub == "spell" then
			n = spellName(id)
		else
			local sid = GetMacroSpell and GetMacroSpell(id)
			if sid then n = spellName(sid) end
			if not n and GetMacroItem then n = GetMacroItem(id) end
			if not n and GetMacroInfo then n = GetMacroInfo(id) end
			if not n and GetActionText then n = GetActionText(slot) end
		end
	end
	return clean(n)
end
local slotName = N.SlotName

function N.SlotIcon(slot)
	if not slot or not HasAction or not HasAction(slot) then return end
	local tex = GetActionTexture and GetActionTexture(slot)
	return type(tex) == "number" and tex or nil
end

---------------------------------------------------------------------------
-- The bar
---------------------------------------------------------------------------
local function buttonConfig()
	return {
		outOfRangeColoring = "button",
		showGrid = true,
		hideElements = { macro = true, hotkey = true }, -- our own label shows the Naga key
		keyBoundClickButton = "Keybind",
		text = {
			count = {
				font = { font = S.font, size = 12, flags = "OUTLINE" },
				position = { anchor = "BOTTOMRIGHT", relAnchor = "BOTTOMRIGHT", offsetX = -1, offsetY = 2 },
			},
		},
	}
end

function N:Build()
	local bar = CreateFrame("Frame", "NagasOfAzerothBar", UIParent)
	bar:SetSize(SIZE, SIZE)
	bar:SetFrameStrata("LOW")
	bar:Hide()
	local header = CreateFrame("Frame", "NagasOfAzerothHeader", bar, "SecureHandlerStateTemplate")
	header:SetAllPoints()
	header:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])
	bar.header = header
	bar.buttons = {}
	for i = 1, MAX do
		local btn = LAB:CreateButton(950 + i, "NagasOfAzerothButton" .. i, header, buttonConfig())
		for layer, first in ipairs(self.SLOTS) do
			btn:SetState(layer, "action", first + i - 1)
		end
		S:SkinButton(btn)
		btn.nagaIndex = i
		btn.label = S:Font(btn, 12)
		S:ApplyFont(btn.label, 12, "OUTLINE")
		btn.label:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -3)
		bar.buttons[i] = btn
	end
	S:RegisterMover(bar, "bar", L["Naga bar"], function(fr)
		fr:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -320, 260)
	end)
	self.bar = bar
end

-- the owner of the paging guard, and a plain button a blocked key clicks (it does nothing)
function N:BuildBlocker()
	self.blocker = CreateFrame("Frame", "NagasOfAzerothBlocker", UIParent)
	self.noop = CreateFrame("Button", "NagasOfAzerothNoop", UIParent)
	self.noop:Hide()
end

-- plate, bar, pages and key bindings: secure, so out of combat only
function N:Apply()
	if InCombatLockdown() then return end
	local bar = self.bar
	local c = cfg()
	local plate = self:Plate()
	wipe(self.bound)
	if bar then
		local on = plate ~= nil and c.bar and true or false
		local layers = on and c.layers and #LAYERS or 1
		ClearOverrideBindings(bar)
		RegisterStateDriver(bar.header, "page", (on and c.layers) and self.DRIVER or "1")
		local n = on and #plate.keys or 0
		for i, btn in ipairs(bar.buttons) do
			btn:ClearAllPoints()
			if i <= n then
				local row, col = self:Position(i, plate)
				btn:SetSize(SIZE, SIZE)
				btn:SetPoint("TOPLEFT", bar, "TOPLEFT", (col - 1) * (SIZE + GAP), -(row - 1) * (SIZE + GAP))
				btn:SetAttribute("statehidden", nil)
				btn:Show()
				-- the plate's key (and Shift / Ctrl / Alt + key) clicks this button; it wins
				-- over a Blizzard binding of the same key only while the Naga bar is on
				local key = plate.keys[i]
				for layer = 1, layers do
					local full = LAYERS[layer].mod .. key
					SetOverrideBindingClick(bar, true, full, btn:GetName(), "Keybind")
					self.bound[full] = { index = i, layer = layer }
				end
			else
				btn:SetPoint("CENTER", bar, "CENTER")
				btn:SetAttribute("statehidden", true)
				btn:Hide()
			end
		end
		if plate then
			bar:SetSize(plate.cols * (SIZE + GAP) - GAP, plate.rows * (SIZE + GAP) - GAP)
		end
		bar:SetShown(on)
		local m = S.movers and S.movers.bar
		if m then
			m.hidden = not on
			S:ApplyPoint(m.frame, "bar")
		end
		S:UpdateMovers()
	end
	self.blockSig = nil
	self:ApplyBlock()
	self:RefreshConflicts(true)
	self:UpdateLabels()
	if self.testFrame and self.testFrame:IsShown() then self:PaintTest() end
	NoA:Fire("NAGA_CHANGED")
end

-- Shift / Ctrl / Alt + a plate key bound to Blizzard's bar paging: while the
-- option is on, that key clicks a button that does nothing (the Naga bar's own
-- pages already hold the keys it binds). Only keys on the chosen plate.
function N:ApplyBlock()
	if InCombatLockdown() or not self.blocker then return end
	local c, plate = cfg(), self:Plate()
	local want = {}
	if plate and c.blockPaging then
		for _, key in ipairs(plate.keys) do
			for layer = 2, #LAYERS do
				local full = LAYERS[layer].mod .. key
				if not self.bound[full] and isPaging(blizzBinding(full)) then want[#want + 1] = full end
			end
		end
	end
	table.sort(want)
	local sig = table.concat(want, " ")
	if sig == self.blockSig then return end -- nothing changed (our own bindings fire UPDATE_BINDINGS too)
	self.blockSig = sig
	ClearOverrideBindings(self.blocker)
	wipe(self.blocked)
	for _, full in ipairs(want) do
		SetOverrideBindingClick(self.blocker, true, full, self.noop:GetName())
		self.blocked[full] = true
	end
end

-- keys bound twice: the Naga bar over a Blizzard binding, and modifier + plate
-- keys that switch Blizzard's bar page (told once per change)
function N:RefreshConflicts(tell)
	wipe(self.conflicts)
	wipe(self.paging)
	local list = {}
	for full in pairs(self.bound) do
		local a = blizzBinding(full)
		if a then
			self.conflicts[full] = a
			list[#list + 1] = full
		end
	end
	local pages = {}
	local plate = self:Plate()
	if plate then
		for _, key in ipairs(plate.keys) do
			for layer = 2, #LAYERS do
				local full = LAYERS[layer].mod .. key
				local a = blizzBinding(full)
				if isPaging(a) then
					self.paging[full] = a
					if not (self.bound[full] or self.blocked[full]) then pages[#pages + 1] = full end
				end
			end
		end
	end
	table.sort(list)
	table.sort(pages)
	local sig = table.concat(list, " ") .. "|" .. table.concat(pages, " ")
	if tell and sig ~= self.told then
		if #list > 0 then
			NoA:Print(L["Razer Naga: %d keys also have a Blizzard key binding; the Naga bar wins while it is on. /naga test shows which."]:format(#list))
		end
		if #pages > 0 then
			NoA:Print(L["Razer Naga: %s switch your action bar page. Turn on \"Block bar-page switching on plate keys\" (/naga)."]:format(table.concat((function()
				local t = {}
				for i, k in ipairs(pages) do t[i] = prettyKey(k, "+") end
				return t
			end)(), ", ")))
		end
	end
	if tell then self.told = sig end
	return list
end

-- the hint for a key that pages Blizzard's bar: "Shift+1 switches your action bar page"
function N:PagingHint(full)
	if not self.paging[full] then return end
	local t = L["%s switches your action bar page"]:format(prettyKey(full, "+"))
	if self.blocked[full] or self.bound[full] then t = t .. " " .. L["(blocked on the plate)"] end
	return t
end

-- the page you see now, as the state driver picks it
function N:CurrentLayer()
	if not cfg().layers then return 1 end
	if IsShiftKeyDown() then return 2 end
	if IsControlKeyDown() then return 3 end
	if IsAltKeyDown() then return 4 end
	return 1
end

function N:UpdateLabels()
	local bar = self.bar
	if not bar then return end
	local plate = self:Plate()
	local layer = self:CurrentLayer()
	for i, btn in ipairs(bar.buttons) do
		local key = plate and plate.keys[i]
		btn.label:SetText(key and (LAYERS[layer].short .. keyText(key)) or "")
	end
end

---------------------------------------------------------------------------
-- Rotation hint (Casters of Azeroth): the Naga key of a spell, its button glows
---------------------------------------------------------------------------
-- "7" or "Shift 7" for a spell on the Naga bar (and its button and page); nil when it is not there
function N:KeyFor(name)
	local c = cfg()
	local plate = self:Plate()
	if not (name and plate and c.bar and self.bar and self.bar:IsShown()) then return end
	for layer = 1, c.layers and #LAYERS or 1 do
		for i, key in ipairs(plate.keys) do
			if slotName(self.SLOTS[layer] + i - 1) == name then
				return prettyKey(LAYERS[layer].mod .. key), self.bar.buttons[i], layer
			end
		end
	end
end

-- the suggested spell (nil: none); its button glows, returns the key text to show
function N:Suggest(name)
	local text, btn
	if cfg().rotationKey and name then
		text, btn = self:KeyFor(name)
	end
	if self.glowBtn and self.glowBtn ~= btn then
		if LBG then LBG.HideOverlayGlow(self.glowBtn) end
		self.glowBtn = nil
	end
	if btn and self.glowBtn ~= btn then
		if LBG then LBG.ShowOverlayGlow(btn) end
		self.glowBtn = btn
	end
	self.suggestKey = text
	return text
end

---------------------------------------------------------------------------
-- Test screen: which key arrives and what it does. Never casts anything.
---------------------------------------------------------------------------
local IGNORE = {
	LSHIFT = true, RSHIFT = true, LALT = true, RALT = true,
	LCTRL = true, RCTRL = true, LMETA = true, RMETA = true, UNKNOWN = true,
}
-- mouse buttons over the window (left and right drag the window)
local MOUSE = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function withModifiers(key)
	local p = ""
	if IsAltKeyDown() then p = p .. "ALT-" end
	if IsControlKeyDown() then p = p .. "CTRL-" end
	if IsShiftKeyDown() then p = p .. "SHIFT-" end
	return p .. key
end
N.WithModifiers = withModifiers

-- what a key does right now: { key, label, index (cell on the plate or nil), what, conflict }
function N:Describe(full)
	local base, mods = splitKey(full)
	local plate = self:Plate()
	local index
	if plate then
		for i, k in ipairs(plate.keys) do if k == base then index = i end end
	end
	local blizz = blizzBinding(full)
	local b = self.bound[full]
	local what, conflict
	if b then
		local n = slotName(self.SLOTS[b.layer] + b.index - 1)
		what = L["Naga bar"] .. ": " .. (n or L["empty slot"])
		if blizz then
			conflict = true
			what = what .. "  |  " .. L["also %s (the Naga bar wins while it is on)"]:format(bindingName(blizz))
		end
	elseif self.blocked[full] then
		what = L["nothing (bar paging blocked)"]
	else
		local a = blizz or GetBindingAction(full, true)
		what = bindingName(a) or L["nothing"]
	end
	if index and self.paging[full] then
		conflict = true
		what = what .. "  |  " .. self:PagingHint(full)
	end
	return { key = full, label = prettyKey(full), base = base, layer = LAYER_OF[mods], index = index,
		what = what, conflict = conflict }
end

-- a cell turns red when one of its keys is bound twice or pages Blizzard's bar
function N:CellConflict(i)
	local plate = self:Plate()
	local key = plate and plate.keys[i]
	if not key then return false end
	for _, l in ipairs(LAYERS) do
		if self.conflicts[l.mod .. key] or self.paging[l.mod .. key] then return true end
	end
	return false
end

local CELL_W, CELL_H, CELL_GAP = 110, 52, 6

function N:CreateTest()
	local f = S:Window("NagasOfAzerothTest", 440, 300)
	f.close:SetScript("OnClick", function() N:CloseTest() end)

	f.body = S:Font(f, 11)
	f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -6)
	f.body:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	f.body:SetJustifyH("LEFT")
	f.body:SetTextColor(unpack(S.colors.muted))

	f.grid = CreateFrame("Frame", nil, f)
	f.cells = {}

	f.last = S:Font(f, 12)
	f.last:SetJustifyH("LEFT")
	f.off = S:Font(f, 11)
	f.off:SetJustifyH("LEFT")
	f.off:SetTextColor(unpack(S.colors.muted))

	f.mapBtn = S:Button(f, L["Naga map"], 120, function() NoA.Map:Open() end)
	f.mapBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)

	-- keys pass on to the game: the test screen only watches
	f:EnableKeyboard(true)
	f:SetPropagateKeyboardInput(true)
	f:SetScript("OnKeyDown", function(fr, key) N:OnTestKey(fr, key) end)
	f:SetScript("OnMouseDown", function(_, button)
		local k = MOUSE[button]
		if k then N:Arrive(withModifiers(k)) end
	end)
	self.testFrame = f
end

function N:Cell(i)
	local f = self.testFrame
	local cell = f.cells[i]
	if cell then return cell end
	cell = CreateFrame("Frame", nil, f.grid, "BackdropTemplate")
	cell:SetSize(CELL_W, CELL_H)
	S:Backdrop(cell, 1)
	cell.key = S:Font(cell, 16)
	cell.key:SetPoint("TOP", cell, "TOP", 0, -5)
	cell.what = S:Font(cell, 10)
	cell.what:SetPoint("TOPLEFT", cell, "TOPLEFT", 4, -26)
	cell.what:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -4, 3)
	cell.what:SetJustifyH("CENTER")
	cell.what:SetJustifyV("TOP")
	cell.what:SetTextColor(unpack(S.colors.muted))
	f.cells[i] = cell
	return cell
end

function N.PlateName(key)
	if key == "12" then return L["12 buttons (3 wide, 4 high)"] end
	if key == "6" then return L["6 buttons (2 wide, 3 high)"] end
	if key == "2" then return L["2 buttons (mouse 4 above 5)"] end
	return L["None"]
end
local plateName = N.PlateName

function N:LayoutTest()
	local f = self.testFrame
	local plate = self:Plate()
	f.title:SetText(L["Razer Naga test"] .. "  |cff999999" .. plateName(cfg().plate) .. "|r")
	f.body:SetText(L["Press your Naga buttons (with Shift, Ctrl or Alt for the other pages). Keys keep working while this is open; nothing is cast from here. Click mouse buttons 4 and 5 over this window. Red = bound twice. Esc closes."])
	local top = 20 + 14 + 6 + math.max(f.body:GetStringHeight() or 0, 28) + 12
	local cols, rows = plate and plate.cols or 0, plate and plate.rows or 0
	f.grid:ClearAllPoints()
	f.grid:SetPoint("TOP", f, "TOP", 0, -top)
	f.grid:SetSize(math.max(1, cols * (CELL_W + CELL_GAP) - CELL_GAP), math.max(1, rows * (CELL_H + CELL_GAP) - CELL_GAP))
	local n = plate and #plate.keys or 0
	for i = 1, math.max(n, #f.cells) do
		local cell = self:Cell(i)
		if i <= n then
			local row, col = self:Position(i, plate)
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", f.grid, "TOPLEFT", (col - 1) * (CELL_W + CELL_GAP), -(row - 1) * (CELL_H + CELL_GAP))
			cell:Show()
		else
			cell:Hide()
		end
	end
	local gridH = rows > 0 and (rows * (CELL_H + CELL_GAP)) or 0
	f.last:ClearAllPoints()
	f.last:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -top - gridH - 8)
	f.last:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	f.off:ClearAllPoints()
	f.off:SetPoint("TOPLEFT", f.last, "BOTTOMLEFT", 0, -6)
	f.off:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	f:SetSize(math.max(440, cols * (CELL_W + CELL_GAP) + 24), top + gridH + 140)
end

function N:PaintTest()
	local f = self.testFrame
	if not f then return end
	local t = self.test
	local plate = self:Plate()
	local a, w = S.colors.accent, S.colors.warn
	for i, cell in ipairs(f.cells) do
		local key = plate and plate.keys[i]
		if key and cell:IsShown() then
			local seen = t.lit[i]
			local d = seen or self:Describe(key)
			cell.key:SetText(seen and d.label or keyText(key))
			cell.what:SetText(d.what)
			cell.red = self:CellConflict(i)
			cell.lit = t.last ~= nil and t.last.index == i
			if cell.lit then
				cell:SetBackdropColor(a[1], a[2], a[3], 0.45)
			elseif seen then
				cell:SetBackdropColor(a[1], a[2], a[3], 0.15)
			else
				local bg = S.colors.bg
				cell:SetBackdropColor(bg[1], bg[2], bg[3], 1)
			end
			if cell.red then
				cell:SetBackdropBorderColor(w[1], w[2], w[3], 1)
			elseif cell.lit then
				cell:SetBackdropBorderColor(a[1], a[2], a[3], 1)
			else
				cell:SetBackdropBorderColor(0, 0, 0, 1)
			end
		end
	end
	if t.last then
		local d = t.last
		local c = d.conflict and w or (d.index and a or S.colors.text)
		f.last:SetText(L["Arrived: %s"]:format(d.label) .. "  >  " .. d.what)
		f.last:SetTextColor(c[1], c[2], c[3])
	else
		f.last:SetText(plate and L["Press a Naga button."] or L["No side plate chosen: pick one in the Razer Naga settings (/naga)."])
		f.last:SetTextColor(unpack(S.colors.muted))
	end
	local lines = {}
	-- the paging keys of the plate, so you see them before you press one
	if plate then
		local list = {}
		for full in pairs(self.paging) do list[#list + 1] = full end
		table.sort(list)
		for _, full in ipairs(list) do lines[#lines + 1] = "|cffff4d4d" .. self:PagingHint(full) .. "|r" end
	end
	if #t.offPlate > 0 then
		lines[#lines + 1] = L["Not on the plate:"]
		for _, d in ipairs(t.offPlate) do lines[#lines + 1] = d.label .. " > " .. d.what end
	end
	f.off:SetText(table.concat(lines, "\n"))
end

-- a key or mouse button arrived (with its modifiers)
function N:Arrive(full)
	local d = self:Describe(full)
	local t = self.test
	t.last = d
	if d.index then
		t.lit[d.index] = d
	else
		for k = #t.offPlate, 1, -1 do
			if t.offPlate[k].key == full then table.remove(t.offPlate, k) end
		end
		table.insert(t.offPlate, 1, d)
		while #t.offPlate > 5 do table.remove(t.offPlate) end
	end
	self:PaintTest()
	return d
end

function N:OnTestKey(frame, key)
	if key == "ESCAPE" then
		-- Escape closes the test screen and goes no further
		if not InCombatLockdown() then frame:SetPropagateKeyboardInput(false) end
		self:CloseTest()
		return
	end
	if IGNORE[key] then return end
	self:Arrive(withModifiers(key))
end

-- out of combat only: SetPropagateKeyboardInput is protected in combat
function N:OpenTest()
	if InCombatLockdown() then
		NoA:Print(L["The Naga test screen opens out of combat."])
		return
	end
	if not self.testFrame then self:CreateTest() end
	self.test = { lit = {}, offPlate = {} }
	self:RefreshConflicts()
	self.testFrame:SetPropagateKeyboardInput(true)
	self:LayoutTest()
	self.testFrame:Show()
	self:PaintTest()
end

function N:CloseTest()
	if self.testFrame then self.testFrame:Hide() end
end

function N:ToggleTest()
	if self.testFrame and self.testFrame:IsShown() then self:CloseTest() else self:OpenTest() end
end

---------------------------------------------------------------------------
-- Healers of Azeroth: the same plate for its hover keys (when the check is on)
---------------------------------------------------------------------------
function N:SyncHealers()
	local c = cfg()
	local _, B = NoA:Healers()
	if not (B and c.syncHealers) then return end
	if B:Plate() == c.plate then return end
	-- Healers applies its secure attributes out of combat; we ask out of combat too
	NoA:OutOfCombat("noa-healers", function()
		if B:Plate() ~= cfg().plate then
			self.healersPlate = cfg().plate
			B:SetPlate(cfg().plate)
		end
	end)
end

-- Healers' plate changed in its own settings: follow it when the check is on
function N:HealersChanged()
	local _, B = NoA:Healers()
	if not B then return end
	local p = B:Plate()
	if p == self.healersPlate then return end
	self.healersPlate = p
	if cfg().syncHealers and p ~= cfg().plate and (p == "none" or PLATES[p]) then NoA:SetPlate(p) end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
function N:OnEnable()
	local c = cfg()
	if not PLATES[c.plate] then c.plate = "none" end
	self.test = { lit = {}, offPlate = {} }
	self:BuildBlocker()
	NoA:OutOfCombat("noa-build", function()
		if LAB and not self.bar then self:Build() end
		self:Apply()
	end)
	NoA:Listen("SETTINGS", function(group)
		if group ~= "naga" then return end
		self:SyncHealers()
		NoA:OutOfCombat("noa-apply", function() self:Apply() end)
	end)
	local H, B = NoA:Healers()
	if B then
		self.healersPlate = B:Plate()
		if H.Listen then H:Listen("BINDINGS", function() self:HealersChanged() NoA:Fire("NAGA_CHANGED") end) end
	end
	NoA:On("MODIFIER_STATE_CHANGED", function() self:UpdateLabels() end)
	-- your Blizzard bindings changed: which keys are bound twice, and the paging guard
	NoA:On("UPDATE_BINDINGS", function()
		NoA:OutOfCombat("noa-block", function() self:ApplyBlock() end)
		self:RefreshConflicts()
		if self.testFrame and self.testFrame:IsShown() then self:PaintTest() end
		NoA:Fire("NAGA_CHANGED")
	end)
	NoA:On("ACTIONBAR_SLOT_CHANGED", function()
		if self.testFrame and self.testFrame:IsShown() then self:PaintTest() end
		NoA:Fire("NAGA_CHANGED")
	end)
end

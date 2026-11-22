-- Nagas of Azeroth by DinX: the Naga map. One look at what every key of your
-- side plate does, per layer (plain, Shift, Ctrl, Alt): the Naga bar slot, the
-- Healers of Azeroth hover spell, or else Blizzard's own key binding. Red = a
-- clash. Display only: this window never casts and is not a secure frame.
--
-- Export for the website and printing, written to the per-character saved
-- variables (WTF\Account\<account>\<realm>\<character>\SavedVariables\
-- NagasOfAzeroth.lua) out of combat when the bar, the bindings or the plate
-- change, and at logout:
--
--   NagasOfAzerothCharDB.map = {
--     plate = "12",              -- "none", "12", "6" or "2"
--     updated = 1763820000,      -- time() of the last refresh
--     class = "SHAMAN",          -- class token
--     layers = {                 -- only layers with at least one cell
--       [""] = {                 -- plain; then shift, ctrl, alt
--         ["1"] = {              -- the plate key: "1".."9", "0", "-", "=", "BUTTON4", "BUTTON5"
--           bar = "Healing Wave", barIcon = 136052,       -- Naga bar slot (spell, item or macro)
--           hover = "Lesser Healing Wave", hoverIcon = 136043, -- Healers of Azeroth hover key
--           bind = "ACTIONBUTTON1",                        -- Blizzard's own binding of the key
--           clash = true,                                  -- only when there is a clash
--           note = "Shift+1 switches your action bar page", -- only with a paging clash
--         },
--       },
--       shift = { ... }, ctrl = { ... }, alt = { ... },
--     },
--   }
--
-- Every field is optional except plate, updated, class and layers; cells with
-- nothing in them are left out; icons are fileIDs (numbers). The cells are in
-- plate order when you walk the plate's keys (see NAGA.md for the grid).
local _, ns = ...
local NoA = ns.NoA
local L = NoA.L
local S = NoA.Style

local M = NoA:NewModule("Map")

local function N() return NoA.Naga end

local function spellIcon(name)
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, tex = pcall(C_Spell.GetSpellTexture, name)
		if ok and type(tex) == "number" then return tex end
	end
	if GetSpellTexture then
		local ok, tex = pcall(GetSpellTexture, name)
		if ok and type(tex) == "number" then return tex end
	end
end

---------------------------------------------------------------------------
-- Data
---------------------------------------------------------------------------
-- Healers of Azeroth's hover keys as they are bound now: full key ("SHIFT-1")
-- -> { name, icon }. Empty when Healers is not loaded or its hover keys are off.
function M:Hover()
	local out = {}
	local H, B = NoA:Healers()
	if not (B and H.char.hoverKeys and type(B.BoundSlots) == "function" and type(B.Resolve) == "function") then return out end
	local ok, slots = pcall(B.BoundSlots, B)
	if not ok or type(slots) ~= "table" then return out end
	for _, s in ipairs(slots) do
		local okR, kind, spell = pcall(B.Resolve, B, s.name)
		if okR and kind then
			local name, icon
			if kind == "spell" then
				name, icon = spell, spellIcon(spell)
			elseif type(B.Label) == "function" then
				local okL, label = pcall(B.Label, B, s.name)
				name = okL and label or kind
			else
				name = kind
			end
			if type(s.key) == "string" and type(name) == "string" then out[s.key] = { name = name, icon = icon } end
		end
	end
	return out
end

-- one cell: the key on one layer. hover: from M:Hover() (pass it in to read Healers once)
function M:Cell(layer, i, hover)
	local Nm = N()
	local plate = Nm:Plate()
	local key = plate and plate.keys[i]
	if not key then return end
	local full = Nm.LAYERS[layer].mod .. key
	local cell = { key = key, full = full, label = Nm.PrettyKey(full) }
	local b = Nm.bound[full]
	if b then
		local slot = Nm.SLOTS[b.layer] + b.index - 1
		cell.onBar = true
		cell.bar = Nm.SlotName(slot)
		cell.barIcon = Nm.SlotIcon(slot)
	end
	local h = (hover or self:Hover())[full]
	if h then cell.hover, cell.hoverIcon = h.name, h.icon end
	cell.bind = Nm.BlizzBinding(full)
	cell.bindName = Nm.BindingName(cell.bind)
	cell.blocked = Nm.blocked[full] or nil
	-- a clash: the Naga bar over a Blizzard binding, or a modifier key that pages Blizzard's bar
	if cell.onBar and cell.bind then cell.clash = true end
	if layer > 1 and Nm.IsPaging(cell.bind) then
		cell.clash = true
		cell.note = L["%s switches your action bar page"]:format(Nm.PrettyKey(full, "+"))
	end
	return cell
end

-- the whole map: { plate, updated, class, layers = { [""|shift|ctrl|alt] = { [key] = cell } } }
function M:Build()
	local Nm = N()
	local c = NoA.char
	local map = { plate = c.plate or "none", updated = time(), class = select(2, UnitClass("player")), layers = {} }
	local plate = Nm:Plate()
	if not plate then return map end
	local hover = self:Hover()
	for layer, l in ipairs(Nm.LAYERS) do
		local cells = {}
		for i in ipairs(plate.keys) do
			local cell = self:Cell(layer, i, hover)
			local out = {}
			if cell.bar then out.bar, out.barIcon = cell.bar, cell.barIcon end
			if cell.hover then out.hover, out.hoverIcon = cell.hover, cell.hoverIcon end
			if cell.bind then out.bind = cell.bind end
			if cell.clash then out.clash = true end
			if cell.note then out.note = cell.note end
			if next(out) then cells[cell.key] = out end
		end
		if next(cells) then map.layers[l.key] = cells end
	end
	return map
end

-- write the map to the saved variables (out of combat; at logout always)
function M:Export(now)
	if not NoA.char then return end
	if now then
		NoA.char.map = self:Build()
		return
	end
	NoA:OutOfCombat("noa-export", function() NoA.char.map = self:Build() end)
end

-- many events come in a burst (a bar full of slots): one export a second later
function M:Changed()
	if self.frame and self.frame:IsShown() then self:Paint() end
	if self.pending then return end
	self.pending = true
	C_Timer.After(1, function()
		self.pending = nil
		self:Export()
	end)
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local CW, CH, GAP = 170, 64, 6

function M:Create()
	local f = S:Window("NagasOfAzerothMap", 560, 400)
	f.layer = 1
	f.tabs = {}
	for i, l in ipairs(N().LAYERS) do
		local b = S:Button(f, L[l.label], 70, function() f.layer = i M:Paint() end)
		b:SetPoint("TOPLEFT", f, "TOPLEFT", 12 + (i - 1) * 76, -34)
		f.tabs[i] = b
	end
	f.grid = CreateFrame("Frame", nil, f)
	f.grid:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -64)
	f.cells = {}
	f.status = S:Font(f, 11)
	f.status:SetJustifyH("LEFT")
	f.status:SetTextColor(unpack(S.colors.muted))
	f.legend = S:Font(f, 10)
	f.legend:SetJustifyH("LEFT")
	f.legend:SetTextColor(unpack(S.colors.muted))
	f.legend:SetText(L["Blue: Naga bar. Green: Healers hover key (mouse over a frame). Grey: Blizzard key binding. Red: clash."])
	f.testBtn = S:Button(f, L["Test screen"], 120, function() N():OpenTest() end)
	f.testBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
	self.frame = f
end

function M:MapCell(i)
	local f = self.frame
	local c = f.cells[i]
	if c then return c end
	c = CreateFrame("Frame", nil, f.grid, "BackdropTemplate")
	c:SetSize(CW, CH)
	S:Backdrop(c, 1)
	c.key = S:Font(c, 14)
	c.key:SetPoint("TOPLEFT", 5, -4)
	c.icon = c:CreateTexture(nil, "ARTWORK")
	c.icon:SetSize(26, 26)
	c.icon:SetPoint("TOPLEFT", 5, -22)
	c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	c.lines = S:Font(c, 10)
	c.lines:SetPoint("TOPLEFT", c, "TOPLEFT", 36, -20)
	c.lines:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -4, 3)
	c.lines:SetJustifyH("LEFT")
	c.lines:SetJustifyV("TOP")
	f.cells[i] = c
	return c
end

local function hex(col)
	local function b(v) return math.floor(v * 255 + 0.5) end
	return ("|cff%02x%02x%02x"):format(b(col[1]), b(col[2]), b(col[3]))
end

-- the text lines of one cell (also used by the tests)
function M:Lines(cell)
	local out = {}
	if cell.onBar then out[#out + 1] = hex(S.colors.accent) .. (cell.bar or L["empty slot"]) .. "|r" end
	if cell.hover then out[#out + 1] = hex(S.colors.heal) .. cell.hover .. "|r" end
	if not cell.onBar and not cell.hover then
		if cell.blocked then
			out[#out + 1] = hex(S.colors.muted) .. L["nothing (bar paging blocked)"] .. "|r"
		else
			out[#out + 1] = hex(S.colors.muted) .. (cell.bindName or L["nothing"]) .. "|r"
		end
	end
	if cell.note then
		out[#out + 1] = hex(S.colors.warn) .. cell.note .. "|r"
	elseif cell.clash then
		out[#out + 1] = hex(S.colors.warn) .. L["also %s"]:format(cell.bindName or cell.bind) .. "|r"
	end
	return out
end

function M:Paint()
	local f = self.frame
	if not f then return end
	local Nm = N()
	local plate = Nm:Plate()
	f.title:SetText(L["Naga map"] .. "  |cff999999" .. Nm.PlateName(NoA.char.plate) .. "|r")
	for i, b in ipairs(f.tabs) do
		b.selected = i == f.layer
		b:SetBackdropBorderColor(unpack(b.selected and S.colors.accent or { 0, 0, 0, 1 }))
	end
	local cols, rows = plate and plate.cols or 0, plate and plate.rows or 0
	local n = plate and #plate.keys or 0
	local hover = self:Hover()
	local w = S.colors.warn
	f.shown = {}
	for i = 1, math.max(n, #f.cells) do
		local c = self:MapCell(i)
		if i <= n then
			local row, col = Nm:Position(i, plate)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", f.grid, "TOPLEFT", (col - 1) * (CW + GAP), -(row - 1) * (CH + GAP))
			local cell = self:Cell(f.layer, i, hover)
			f.shown[i] = cell
			c.key:SetText(cell.label)
			c.lines:SetText(table.concat(self:Lines(cell), "\n"))
			local icon = cell.barIcon or cell.hoverIcon
			c.icon:SetTexture(icon)
			c.icon:SetShown(icon ~= nil)
			c.red = cell.clash or false
			if c.red then c:SetBackdropBorderColor(w[1], w[2], w[3], 1) else c:SetBackdropBorderColor(0, 0, 0, 1) end
			c:Show()
		else
			c:Hide()
		end
	end
	local gridW = math.max(1, cols * (CW + GAP) - GAP)
	local gridH = rows > 0 and rows * (CH + GAP) or 0
	f.grid:SetSize(gridW, math.max(1, gridH))
	local status = {}
	if not plate then status[#status + 1] = L["No side plate chosen: pick one in the Razer Naga settings (/naga)."] end
	local H = NoA:Healers()
	if not H then
		status[#status + 1] = L["Healers of Azeroth is not loaded: only the Naga bar and Blizzard's bindings show."]
	elseif not H.char.hoverKeys then
		status[#status + 1] = L["Healers of Azeroth's hover keys are off."]
	end
	f.status:SetText(table.concat(status, "\n"))
	f.status:ClearAllPoints()
	f.status:SetPoint("TOPLEFT", f.grid, "BOTTOMLEFT", 0, -6)
	f.status:SetWidth(math.max(400, gridW))
	f.legend:ClearAllPoints()
	f.legend:SetPoint("TOPLEFT", f.status, "BOTTOMLEFT", 0, -6)
	f.legend:SetWidth(math.max(400, gridW))
	f:SetSize(math.max(440, gridW + 24), 64 + gridH + 110)
end

function M:Open()
	if not self.frame then self:Create() end
	self.frame:Show()
	self:Paint()
end

function M:Toggle()
	if self.frame and self.frame:IsShown() then self.frame:Hide() else self:Open() end
end

function M:OnEnable()
	NoA:Listen("NAGA_CHANGED", function() self:Changed() end)
	NoA:On("PLAYER_LOGOUT", function() self:Export(true) end)
	self:Export()
end

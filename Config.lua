-- Nagas of Azeroth by DinX: the "Razer Naga" panel in Blizzard's settings
-- (Esc > Options > AddOns > Razer Naga, or /naga). When Casters of Azeroth is
-- loaded, its settings window gets a short page with a button to this panel.
local _, ns = ...
local NoA = ns.NoA
local L = NoA.L
local S = NoA.Style

local C = NoA:NewModule("Config")

---------------------------------------------------------------------------
-- A small page: Header, Note, Check, Choice, Button (refreshed on show)
---------------------------------------------------------------------------
local Page = {}
Page.__index = Page

function Page:Header(text)
	local t = S:Font(self.frame, 14)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetText(text)
	t:SetTextColor(unpack(S.colors.accent))
	self.y = self.y - 26
	return t
end

function Page:Note(text)
	local t = S:Font(self.frame, 11)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetWidth(430)
	t:SetJustifyH("LEFT")
	t:SetTextColor(unpack(S.colors.muted))
	t:SetText(text)
	self.y = self.y - math.max(18, (t:GetStringHeight() or 0) + 8)
	return t
end

function Page:Gap(h) self.y = self.y - (h or 8) end

function Page:Check(label, tip, get, set)
	local b = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
	b:SetPoint("TOPLEFT", 12, self.y)
	b:SetScript("OnClick", function(btn) set(btn:GetChecked() and true or false) C:Refresh() end)
	local t = S:Font(self.frame, 12)
	t:SetPoint("LEFT", b, "RIGHT", 4, 0)
	t:SetText(label)
	if tip then
		b:SetScript("OnEnter", function(btn)
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	b.refresh = function() b:SetChecked(get() and true or false) end
	self.widgets[#self.widgets + 1] = b
	self.y = self.y - 28
	return b
end

function Page:Button(label, onClick, width, x)
	local b = S:Button(self.frame, label, width, onClick)
	b:SetPoint("TOPLEFT", x or 16, self.y)
	self.y = self.y - 30
	return b
end

-- a button that steps through the options
function Page:Choice(label, opts, get, set)
	local t = S:Font(self.frame, 12)
	t:SetPoint("TOPLEFT", 16, self.y - 4)
	t:SetText(label)
	local b
	b = self:Button("", function()
		local cur, i = get(), 1
		for k, o in ipairs(opts) do if o[1] == cur then i = k end end
		set(opts[i % #opts + 1][1])
		C:Refresh()
	end, 220, 220)
	b.refresh = function()
		local cur = get()
		b.text:SetText("-")
		for _, o in ipairs(opts) do if o[1] == cur then b.text:SetText(o[2] .. "  >") end end
	end
	self.widgets[#self.widgets + 1] = b
	return b
end

---------------------------------------------------------------------------
-- The panel
---------------------------------------------------------------------------
local function opt(key)
	return function() return NoA.char[key] end,
		function(v) NoA.char[key] = v NoA:Fire("SETTINGS", "naga") end
end

local function plates()
	local Nm = NoA.Naga
	local out = {}
	for _, p in ipairs(Nm.PLATE_ORDER) do out[#out + 1] = { p, Nm.PlateName(p) } end
	return out
end

-- the plate as a small grid with its key labels
function C:BuildPicture(p)
	local holder = CreateFrame("Frame", nil, p.frame)
	holder:SetPoint("TOPLEFT", 470, -50)
	holder:SetSize(120, 160)
	holder.cells = {}
	local title = S:Font(holder, 11)
	title:SetPoint("BOTTOMLEFT", holder, "TOPLEFT", 0, 4)
	title:SetTextColor(unpack(S.colors.muted))
	holder.title = title
	self.picture = holder
end

local PIC, PGAP = 26, 3
function C:PaintPicture()
	local h = self.picture
	if not h then return end
	local Nm = NoA.Naga
	local plate = Nm:Plate()
	h.title:SetText(Nm.PlateName(NoA.char.plate))
	local n = plate and #plate.keys or 0
	for i = 1, math.max(n, #h.cells) do
		local c = h.cells[i]
		if not c then
			c = CreateFrame("Frame", nil, h, "BackdropTemplate")
			c:SetSize(PIC, PIC)
			S:Backdrop(c, 1)
			c.text = S:Font(c, 11)
			c.text:SetPoint("CENTER")
			h.cells[i] = c
		end
		if i <= n then
			local row, col = Nm:Position(i, plate)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", h, "TOPLEFT", (col - 1) * (PIC + PGAP), -(row - 1) * (PIC + PGAP))
			c.text:SetText(Nm.KeyText(plate.keys[i]))
			c.red = Nm:CellConflict(i)
			local w = S.colors.warn
			if c.red then c:SetBackdropBorderColor(w[1], w[2], w[3], 1) else c:SetBackdropBorderColor(0, 0, 0, 1) end
			c:Show()
		else
			c:Hide()
		end
	end
end

function C:Build(p)
	p:Header("Razer Naga")
	p:Note(L["Pick the side plate on your Naga. The bar, its key bindings and the pages follow at once (after combat when you are fighting)."])
	p:Choice(L["Side plate"], plates(), function() return NoA.char.plate end, function(v) NoA:SetPlate(v) end)
	p:Gap(4)
	p:Check(L["Naga bar"], L["A bar laid out like the plate: drag spells on it. The plate's keys press its buttons; a Blizzard binding of the same key waits while the Naga bar is on."], opt("bar"))
	p:Check("   " .. L["Shift, Ctrl and Alt: extra pages"], L["Set Synapse's Hypershift to send Shift, Ctrl or Alt with the same key: each gives the bar another page of spells."], opt("layers"))
	p:Check(L["Naga key in the rotation hint"], L["Casters of Azeroth: when the suggested spell is on the Naga bar, its key shows big under the hint (e.g. 7 or Shift 7) and that button glows."], opt("rotationKey"))
	p:Check(L["Block bar-page switching on plate keys"], L["Blizzard binds Shift + 1 to 6 to its action bar pages. On the plate keys those go to the Naga bar's own pages, or do nothing; the rest of your keyboard keeps them."], opt("blockPaging"))
	p:Note(L["The Naga bar uses action slots 37-48 (Blizzard's Right Bar 2) and, for Shift, Ctrl and Alt, the slots of Blizzard's bars 5, 6 and 7. /naga unlock to drag it."])

	-- Healers of Azeroth: its hover keys, with the same plate when you like
	p:Header("Healers of Azeroth")
	local H, B = NoA:Healers()
	if B then
		p:Note(L["Healers of Azeroth's hover keys (mouse over a frame + a plate key) follow its own plate. Set here, saved in Healers of Azeroth."])
		p:Check(L["Same plate for Healers"], L["Your plate choice here also sets Healers of Azeroth's hover plate, and the other way round."], opt("syncHealers"))
		p:Choice(L["Healers hover plate"], plates(), function() return B:Plate() end, function(v)
			if InCombatLockdown() then NoA:Print(L["Not in combat: try again after the fight."]) return end
			B:SetPlate(v)
			if NoA.char.syncHealers and v ~= NoA.char.plate then NoA:SetPlate(v) end
		end)
		p:Check("   " .. L["Healers: also Shift, Ctrl and Alt + each plate key"], nil,
			function() return not (type(H.char.naga) == "table" and H.char.naga.mods == false) end,
			function(v)
				if InCombatLockdown() then NoA:Print(L["Not in combat: try again after the fight."]) return end
				H.char.naga = type(H.char.naga) == "table" and H.char.naga or {}
				H.char.naga.mods = v
				H:Fire("BINDINGS") -- the way Healers' own settings tell its frames (they apply out of combat)
			end)
	else
		p:Note(L["Healers of Azeroth is not loaded. With it, the plate keys also cast heals while your mouse is on a group frame."])
	end

	p:Gap(6)
	p:Button(L["Naga map"], function() NoA.Map:Open() end, 160)
	p.y = p.y + 30
	p:Button(L["Test screen"], function()
		if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel and not InCombatLockdown() then HideUIPanel(SettingsPanel) end
		NoA.Naga:OpenTest()
	end, 160, 184)
	p:Note(L["Also /naga map and /naga test. The map shows every key per layer; the test screen shows which key arrives."])
	self:BuildPicture(p)
end

function C:Refresh()
	local p = self.page
	if not p then return end
	for _, w in ipairs(p.widgets) do if w.refresh then w.refresh() end end
	self:PaintPicture()
end

function C:Register()
	local panel = CreateFrame("Frame")
	panel:Hide()
	panel.name = "Razer Naga"
	local p = setmetatable({ frame = panel, y = -16, widgets = {} }, Page)
	self.page = p
	self:Build(p)
	panel:SetScript("OnShow", function() C:Refresh() end)
	self.panel = panel
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Razer Naga")
		if ok and cat then
			pcall(Settings.RegisterAddOnCategory, cat)
			self.category = cat
		end
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end

function NoA:OpenSettings()
	if C.category and Settings and Settings.OpenToCategory then
		local id = C.category.GetID and C.category:GetID() or C.category.ID
		Settings.OpenToCategory(id)
	elseif C.panel and InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(C.panel)
		InterfaceOptionsFrame_OpenToCategory(C.panel)
	end
end

-- Casters of Azeroth's settings window: a short page with a button to this panel
function C:CastersPage()
	local c = NoA:Casters()
	if not c then return end
	c.configPages = type(c.configPages) == "table" and c.configPages or {}
	for _, d in ipairs(c.configPages) do if d.key == "noa" then return end end
	table.insert(c.configPages, { key = "noa", label = "Razer Naga", group = "Nagas of Azeroth", build = function(p)
		p:Header("Razer Naga")
		p:Note(L["The Razer Naga settings have their own panel now: Esc > Options > AddOns > Razer Naga, or /naga."])
		p:Button(L["Open the Razer Naga panel"], function()
			if c.Config and c.Config.frame then c.Config.frame:Hide() end
			NoA:OpenSettings()
		end, 220)
	end })
end

function C:OnEnable()
	self:Register()
	self:CastersPage()
	NoA:Listen("NAGA_CHANGED", function() if self.panel and self.panel:IsShown() then self:Refresh() end end)
	NoA:Listen("SETTINGS", function(group) if group == "naga" and self.panel and self.panel:IsShown() then self:Refresh() end end)
end

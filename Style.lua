-- Nagas of Azeroth by DinX: the shared flat look of the "of Azeroth" add-ons
local ADDON, ns = ...
local NoA = ns.NoA

local S = {}
NoA.Style = S

S.flat = "Interface\\Buttons\\WHITE8x8"
-- Roboto (Apache License 2.0, see media\LICENSE-Roboto.txt) reads better than the
-- game font at small sizes; "wow" in the settings brings the game font back.
S.ROBOTO = "Interface\\AddOns\\" .. ADDON .. "\\media\\Roboto-Regular.ttf"

-- A font file added while the game runs is only found after a restart; until
-- then (or if it is missing) fall back to the game font so no text disappears.
local probe
local function usable(path)
	probe = probe or UIParent:CreateFontString(nil, "OVERLAY")
	local ok = pcall(probe.SetFont, probe, path, 12, "")
	local font = ok and probe:GetFont()
	return type(font) == "string" and font:lower():find("roboto", 1, true) ~= nil
end
S.font = usable(S.ROBOTO) and S.ROBOTO or STANDARD_TEXT_FONT
S.flags = ""

function S:LoadFont(db)
	self.font = (db and db.font == "wow" or not usable(self.ROBOTO)) and STANDARD_TEXT_FONT or self.ROBOTO
	self.flags = (db and db.fontOutline) and "OUTLINE" or ""
end

-- Font, flags and a soft shadow in one go (flags: nil = the chosen style).
function S:ApplyFont(fs, size, flags)
	fs:SetFont(self.font, size or 12, flags or self.flags)
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
end

S.colors = {
	bg = { 0.04, 0.05, 0.08, 0.85 },
	accent = { 0.41, 0.80, 0.94 },
	text = { 0.91, 0.93, 0.95 },
	muted = { 0.60, 0.65, 0.71 },
	warn = { 0.95, 0.30, 0.30 },
	hint = { 1.00, 0.82, 0.25 },
	heal = { 0.45, 0.90, 0.45 },
}

-- 1px black border plus dark fill
function S:Backdrop(frame, alpha)
	if not frame.SetBackdrop and BackdropTemplateMixin then Mixin(frame, BackdropTemplateMixin) end
	frame:SetBackdrop({ bgFile = self.flat, edgeFile = self.flat, edgeSize = 1 })
	local c = self.colors.bg
	frame:SetBackdropColor(c[1], c[2], c[3], alpha or c[4])
	frame:SetBackdropBorderColor(0, 0, 0, 1)
end

function S:Font(parent, size, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	self:ApplyFont(fs, size)
	fs:SetTextColor(unpack(self.colors.text))
	return fs
end

-- the accent line on top of a window
function S:TopLine(frame)
	local line = frame:CreateTexture(nil, "ARTWORK")
	line:SetTexture(self.flat)
	line:SetVertexColor(unpack(self.colors.accent))
	line:SetPoint("TOPLEFT", 1, -1)
	line:SetPoint("TOPRIGHT", -1, -1)
	line:SetHeight(2)
	return line
end

-- a flat text button
function S:Button(parent, label, width, onClick)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(width or 160, 22)
	self:Backdrop(b, 1)
	b.text = self:Font(b, 12)
	b.text:SetPoint("CENTER")
	b.text:SetText(label)
	b:SetScript("OnEnter", function() b:SetBackdropBorderColor(unpack(S.colors.accent)) end)
	b:SetScript("OnLeave", function() if not b.selected then b:SetBackdropBorderColor(0, 0, 0, 1) end end)
	b:SetScript("OnClick", onClick)
	return b
end

-- a small window: movable, Esc closes it, title and X
function S:Window(name, w, h)
	local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	f:SetSize(w, h)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	self:Backdrop(f, 0.95)
	f:Hide()
	if UISpecialFrames then tinsert(UISpecialFrames, name) end
	self:TopLine(f)
	f.title = self:Font(f, 14)
	f.title:SetPoint("TOPLEFT", 12, -10)
	f.title:SetTextColor(unpack(self.colors.accent))
	local close = CreateFrame("Button", nil, f)
	close:SetSize(24, 24)
	close:SetPoint("TOPRIGHT", -2, -2)
	close.text = self:Font(close, 14)
	close.text:SetPoint("CENTER")
	close.text:SetText("X")
	close:SetScript("OnClick", function() f:Hide() end)
	f.close = close
	return f
end

---------------------------------------------------------------------------
-- Movers: the Naga bar can be dragged while the frames are unlocked.
-- Position is saved in NoA.char.points[key]; defaultFn(frame) places it otherwise.
---------------------------------------------------------------------------
S.movers = {}

function S:ApplyPoint(frame, key)
	local m = self.movers[key]
	if InCombatLockdown() and frame:IsProtected() then return end
	frame:ClearAllPoints()
	local pt = NoA.char.points[key]
	if type(pt) == "table" and pt[1] then
		frame:SetPoint(pt[1], UIParent, pt[3], pt[4], pt[5])
	elseif m and m.defaultFn then
		m.defaultFn(frame)
	end
end

function S:RegisterMover(frame, key, label, defaultFn)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	local o = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	o:SetAllPoints()
	o:SetFrameStrata("DIALOG")
	o:EnableMouse(true)
	o:RegisterForDrag("LeftButton")
	o:SetBackdrop({ bgFile = self.flat, edgeFile = self.flat, edgeSize = 1 })
	o:SetBackdropColor(0.41, 0.80, 0.94, 0.25)
	o:SetBackdropBorderColor(0.41, 0.80, 0.94, 1)
	local t = self:Font(o, 11)
	t:SetPoint("CENTER")
	t:SetText(label)
	o:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		frame:StartMoving()
	end)
	o:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		local p, _, rp, x, y = frame:GetPoint()
		NoA.char.points[key] = { p, "UIParent", rp, math.floor(x + 0.5), math.floor(y + 0.5) }
	end)
	o:Hide()
	self.movers[key] = { frame = frame, overlay = o, defaultFn = defaultFn }
	self:ApplyPoint(frame, key)
end

function S:UpdateMovers()
	local show = not NoA:FramesLocked() and not InCombatLockdown()
	for _, m in pairs(self.movers) do m.overlay:SetShown(show and not m.hidden) end
end

NoA:Listen("SETTINGS", function(group) if group == "bars" then S:UpdateMovers() end end)
NoA:On("PLAYER_REGEN_DISABLED", function() for _, m in pairs(S.movers) do m.overlay:Hide() end end)
NoA:On("PLAYER_REGEN_ENABLED", function() S:UpdateMovers() end)

local function kill(region)
	if region then
		region:SetAlpha(0)
		if region.Hide then region:Hide() end
	end
end

-- Flatten a LibActionButton / ActionButtonTemplate button.
function S:SkinButton(btn)
	if btn.__noaSkinned then return end
	btn.__noaSkinned = true

	local icon = btn.icon or btn.Icon
	if btn.IconMask and icon then
		icon:RemoveMaskTexture(btn.IconMask)
		btn.IconMask:Hide()
	end
	kill(btn:GetNormalTexture())
	hooksecurefunc(btn, "SetNormalTexture", function(b)
		local nt = b:GetNormalTexture()
		if nt then nt:SetAlpha(0) end
	end)
	if btn.SetNormalAtlas then
		hooksecurefunc(btn, "SetNormalAtlas", function(b)
			local nt = b:GetNormalTexture()
			if nt then nt:SetAlpha(0) end
		end)
	end
	kill(btn.NormalTexture)
	kill(btn.SlotArt)
	kill(btn.SlotBackground)
	kill(btn.Border)
	kill(btn.FloatingBG)
	if btn.RightDivider then kill(btn.RightDivider) end
	if btn.BottomDivider then kill(btn.BottomDivider) end

	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", -1, 1)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 1)
	local inner = btn:CreateTexture(nil, "BACKGROUND", nil, -7)
	inner:SetPoint("TOPLEFT", 1, -1)
	inner:SetPoint("BOTTOMRIGHT", -1, 1)
	inner:SetColorTexture(0.10, 0.12, 0.17, 1)

	if btn.cooldown then
		btn.cooldown:ClearAllPoints()
		btn.cooldown:SetPoint("TOPLEFT", 1, -1)
		btn.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
		btn.cooldown:SetSwipeColor(0, 0, 0, 0.75)
	end

	local hl = btn:GetHighlightTexture()
	if hl then
		hl:SetColorTexture(1, 1, 1, 0.15)
		hl:SetPoint("TOPLEFT", 1, -1)
		hl:SetPoint("BOTTOMRIGHT", -1, 1)
	end
	local pushed = btn:GetPushedTexture()
	if pushed then
		pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
		pushed:SetPoint("TOPLEFT", 1, -1)
		pushed:SetPoint("BOTTOMRIGHT", -1, 1)
	end
	if btn.GetCheckedTexture and btn:GetCheckedTexture() then
		local ch = btn:GetCheckedTexture()
		ch:SetColorTexture(0.41, 0.80, 0.94, 0.25)
		ch:SetPoint("TOPLEFT", 1, -1)
		ch:SetPoint("BOTTOMRIGHT", -1, 1)
	end
end

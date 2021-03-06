local Layout = {}
local mediaRequired, anchoringQueued
local backdropTbl = {insets = {}}
local _G = getfenv(0)
local SML = LibStub:GetLibrary("LibSharedMedia-3.0")

LunaUF.Layout = Layout

local defaultMedia = {
	[SML.MediaType.STATUSBAR] = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\Minimalist",
	[SML.MediaType.FONT] = "Interface\\AddOns\\LunaUnitFrames\\media\\fonts\\Myriad Condensed Web.ttf",
	[SML.MediaType.BACKGROUND] = "Interface\\ChatFrame\\ChatFrameBackground",
	[SML.MediaType.BORDER] = "Interface\\None",
}

-- Someone is using another mod that is forcing a media type for all mods using SML
function Layout:MediaForced(mediaType)
	self:CheckMedia()
	self:Reload()
end

function Layout:LoadMedia(type, unitType)
	local mediaName = LunaUF.db.profile.units[unitType][type] or LunaUF.db.profile[type]
	if( not mediaName ) then return defaultMedia[type] end

	local media = SML:Fetch(type, mediaName, true)
	if( not media ) then
		mediaRequired = mediaRequired or {}
		mediaRequired[type] = mediaName
		return defaultMedia[type]
	end
	
	return media
end

-- Updates the background table
local function updateBackdrop()
	-- Update the backdrop table
	local backdrop = {
		tileSize = 1,
		edgeSize = 5,
		clip = 1,
		inset = 3,
		backgroundTexture = "Chat Frame",
		backgroundColor = {r = 0, g = 0, b = 0, a = 0.80},
		borderTexture = "None",
		borderColor = {r = 0.30, g = 0.30, b = 0.50, a = 1},
	}
	backdropTbl.bgFile = LunaUF.Layout:LoadMedia(SML.MediaType.BACKGROUND, "player")
	if( LunaUF.Layout:LoadMedia(SML.MediaType.BORDER, "player") ~= "Interface\\None" ) then backdropTbl.edgeFile = LunaUF.Layout:LoadMedia(SML.MediaType.BORDER, "player") end
	backdropTbl.tile = backdrop.tileSize > 0 and true or false
	backdropTbl.edgeSize = backdrop.edgeSize
	backdropTbl.tileSize = backdrop.tileSize
	backdropTbl.insets.left = backdrop.inset
	backdropTbl.insets.right = backdrop.inset
	backdropTbl.insets.top = backdrop.inset
	backdropTbl.insets.bottom = backdrop.inset
end

-- Tries to load media, if it fails it will default to whatever I set
function Layout:CheckMedia()
	updateBackdrop()
end

-- We might not have had a media we required at initial load, wait for it to load and then update everything when it does
function Layout:MediaRegistered(event, mediaType, key)
	if( mediaRequired and mediaRequired[mediaType] and mediaRequired[mediaType] == key ) then
		mediaRequired[mediaType] = nil
		
		self:Reload()
	end
end

-- Helper functions
function Layout:ToggleVisibility(frame, visible)
	if not frame then return end
	if( visible ) then
		frame:Show()
	else
		frame:Hide()
	end
end	

function Layout:SetBarVisibility(frame, key, status)

	if( frame.secureLocked ) then return end

	-- Show the bar if it wasn't already
	if( status and not frame[key]:IsVisible() ) then
		--LunaUF.Tags:FastRegister(frame, frame[key])

		frame[key].visibilityManaged = true
		frame[key]:Show()
		if frame.fontstrings[key] then
			for _, fstring in pairs(frame.fontstrings[key]) do
				fstring:Show()
			end
		end
		LunaUF.Layout:PositionWidgets(frame, LunaUF.db.profile.units[frame.unitType])

	-- Hide the bar if it wasn't already
	elseif( not status and frame[key]:IsVisible() ) then
		--LunaUF.Tags:FastUnregister(frame, frame[key])

		frame[key].visibilityManaged = nil
		frame[key]:Hide()
		if frame.fontstrings[key] then
			for _, fstring in pairs(frame.fontstrings[key]) do
				fstring:Hide()
			end
		end
		LunaUF.Layout:PositionWidgets(frame, LunaUF.db.profile.units[frame.unitType])
	end
end

-- Frame changed somehow between when we first set it all up and now
function Layout:Reload(unit)
	updateBackdrop()

	-- Now update them
	for frame in pairs(LunaUF.Units.frameList) do
		if( frame.unit and ( not unit or frame.unitType == unit ) and not frame.isHeaderFrame ) then
			--frame:SetVisibility()
			self:Load(frame)
			frame:FullUpdate()
		end
	end

	for header in pairs(LunaUF.Units.headerFrames) do
		if( header.unitType and ( not unit or header.unitType == unit ) ) then
			local config = LunaUF.db.profile.units[header.unitType]
			header:SetAttribute("style-height", config.height)
			header:SetAttribute("style-width", config.width)
			header:SetAttribute("style-scale", config.scale)
		end
	end

	LunaUF:FireModuleEvent("OnLayoutReload", unit)
end

-- Do a full update
function Layout:Load(frame)
	local unitConfig = LunaUF.db.profile.units[frame.unitType]

	-- About to set layout
	LunaUF:FireModuleEvent("OnPreLayoutApply", frame, unitConfig)

	-- Figure out if we're secure locking
--	frame.secureLocked = nil
--	for _, module in pairs(LunaUF.moduleOrder) do
--		if( frame.visibility[module.moduleKey] and ShadowUF.db.profile.units[frame.unitType][module.moduleKey] and
--			ShadowUF.db.profile.units[frame.unitType][module.moduleKey].secure and module:SecureLockable() ) then
--			frame.secureLocked = true
--			break
--		end
--	end
	
	-- Load all of the layout things
	self:SetupFrame(frame, unitConfig)
	self:SetupBars(frame, unitConfig)
	self:PositionWidgets(frame, unitConfig)
	LunaUF.Tags:SetupText(frame, unitConfig)

	-- Layouts been fully set
	LunaUF:FireModuleEvent("OnLayoutApplied", frame, unitConfig)
end

-- Register it on file load because authors seem to do a bad job at registering the callbacks
SML:Register(SML.MediaType.FONT, "Myriad Condensed Web", "Interface\\AddOns\\LunaUnitFrames\\media\\fonts\\Myriad Condensed Web.ttf")
SML:Register(SML.MediaType.BORDER, "Square Clean", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\ABFBorder")
SML:Register(SML.MediaType.BACKGROUND, "Chat Frame", "Interface\\ChatFrame\\ChatFrameBackground")
SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\banto")
SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\smooth")
SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\perl")
SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\glaze")
SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\Charcoal")
SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\otravi")
SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\striped")
SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\LiteStep")
SML:Register(SML.MediaType.STATUSBAR, "Aluminium", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\Aluminium")
SML:Register(SML.MediaType.STATUSBAR, "Minimalist", "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\Minimalist")

function Layout:LoadSML()
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "MediaRegistered")
	SML.RegisterCallback(self, "LibSharedMedia_SetGlobal", "MediaForced")
	self:CheckMedia()
end

function Layout:AnchorFrame(frame, config)

	local anchorTo = config.anchorTo or "UIParent"
	local point = config.point or "TOPLEFT"
	local relativePoint = config.relativePoint or "TOPLEFT"

	if( anchorTo ~= "UIParent" ) then
		-- The frame we wanted to anchor to doesn't exist yet, so will queue and wait for it to exist
		if( not _G[anchorTo] ) then
			frame.queuedConfig = config
			frame.queuedName = anchorTo

			anchoringQueued = anchoringQueued or {}
			anchoringQueued[frame] = true
			
			-- For the time being, will take over the frame we wanted to anchor to's position.
--			local unit = string.match(anchorTo, "LUFUnit(%w+)") or string.match(anchorTo, "LUFHeader(%w+)")
--			if( unit and LunaUF.db.profile.units[unit] ) then
--				self:AnchorFrame(frame, LunaUF.db.profile.positions[unit])
--			end
			return
		end
	end

	local scale = 1
	if( anchorTo == "UIParent" and not self.isHeaderFrame ) then
		scale = frame:GetScale() * UIParent:GetScale()
	end
	
	frame:ClearAllPoints()
	frame:SetPoint(point, _G[anchorTo], relativePoint, (config.x / scale), (config.y / scale))
end

-- Setup the main frame
function Layout:SetupFrame(frame, config)
	local backdrop = {
		tileSize = 1,
		edgeSize = 5,
		clip = 1,
		inset = 3,
		backgroundTexture = "Chat Frame",
		backgroundColor = {r = 0, g = 0, b = 0, a = 0.80},
		borderTexture = "None",
		borderColor = {r = 0.30, g = 0.30, b = 0.50, a = 1},
	}
	--local backdrop = ShadowUF.db.profile.backdrop
	frame:SetBackdrop(backdropTbl)
	frame:SetBackdropColor(backdrop.backgroundColor.r, backdrop.backgroundColor.g, backdrop.backgroundColor.b, backdrop.backgroundColor.a)
	frame:SetBackdropBorderColor(backdrop.borderColor.r, backdrop.borderColor.g, backdrop.borderColor.b, backdrop.borderColor.a)
	
	-- Prevent these from updating while in combat to prevent tainting
	if( not InCombatLockdown() ) then
		frame:SetHeight(config.height)
		frame:SetWidth(config.width)
		frame:SetScale(config.scale)

		-- Let the frame clip closer to the edge, not using inset + clip as that lets you move it too far in
		local clamp = backdrop.inset + 0.20
		frame:SetClampRectInsets(clamp, -clamp, -clamp, clamp)
		frame:SetClampedToScreen(true)

		-- This is wrong technically, I need to redo the backdrop stuff so it will accept insets and that will fit hitbox issues
		-- for the time being, this is a temporary fix to it
		local hit = backdrop.borderTexture == "None" and backdrop.inset or 0
		frame:SetHitRectInsets(hit, hit, hit, hit)
		
		if( not frame.ignoreAnchor ) then
			self:AnchorFrame(frame, LunaUF.db.profile.units[frame.unitType])
		end
	end

	-- Check if we had anything parented to us
	if( anchoringQueued ) then
		for queued in pairs(anchoringQueued) do
			if( queued.queuedName == frame:GetName() ) then
				self:AnchorFrame(queued, queued.queuedConfig)

				queued.queuedConfig = nil
				queued.queuedName = nil
				anchoringQueued[queued] = nil
			end
		end
	end
end

-- Setup bars
function Layout:SetupBars(frame, config)
	for _, module in pairs(LunaUF.modules) do
		local key = module.moduleKey
		local widget = frame[key]
		if( widget and ( module.moduleHasBar or config[key] and config[key].isBar ) ) then
			if( frame.visibility[key] and not frame[key].visibilityManaged and module.defaultVisibility == false ) then
				self:ToggleVisibility(widget, false)
			else
				self:ToggleVisibility(widget, frame.visibility[key])
			end
			
			if( ( widget:IsShown() or ( not frame[key].visibilityManaged and module.defaultVisibility == false ) ) and widget.SetStatusBarTexture ) then
				widget:SetStatusBarTexture(LunaUF.Layout:LoadMedia(SML.MediaType.STATUSBAR, frame.unitType))
				widget:GetStatusBarTexture():SetHorizTile(false)

				widget:SetOrientation(config[key].vertical and "VERTICAL" or "HORIZONTAL")
				widget:SetReverseFill(config[key].reverse and true or false)
			end

			if( widget.background ) then
				if( config[key].background or config[key].invert ) then
					widget.background:SetTexture(LunaUF.Layout:LoadMedia(SML.MediaType.STATUSBAR, frame.unitType))
					widget.background:SetHorizTile(false)
					widget.background:Show()

					widget.background.overrideColor = {r = 0, g = 0, b = 0, a = 0.80} --LunaUF.db.profile.bars.backgroundColor or config[key].backgroundColor

					if( widget.background.overrideColor ) then
						widget.background:SetVertexColor(widget.background.overrideColor.r, widget.background.overrideColor.g, widget.background.overrideColor.b, 0.20)
					end
				else
					widget.background:Hide()
				end
			end
		end
	end
end

-- Setup the bar barOrder/info
local currentConfig
local function sortOrder(a, b)
	return currentConfig[a].order < currentConfig[b].order
end

local barOrder = {}
function Layout:PositionWidgets(frame, config)
	-- Deal with setting all of the bar heights
	local totalWeight, totalBars, hasFullSize = 0, -1

	-- Figure out total weighting as well as what bars are full sized
	for i=#(barOrder), 1, -1 do table.remove(barOrder, i) end
	for key, module in pairs(LunaUF.modules) do
		if( config[key] and not config[key].height ) then config[key].height = 0.50 end

		if( ( module.moduleHasBar or config[key] and config[key].isBar ) and frame[key] and frame[key]:IsShown() and config[key].height > 0 ) then
			totalWeight = totalWeight + config[key].height
			totalBars = totalBars + 1

			table.insert(barOrder, key)

			config[key].order = config[key].order or 99
			
			-- Decide whats full sized
			if( not frame.visibility.portrait or config.portrait.isBar or config[key].order < config.portrait.fullBefore or config[key].order > config.portrait.fullAfter ) then
				hasFullSize = true
				frame[key].fullSize = true
			else
				frame[key].fullSize = nil
			end
		end
	end

	-- Sort the barOrder so it's all nice and orderly (:>)
	currentConfig = config
	table.sort(barOrder, sortOrder)

	-- Now deal with setting the heights and figure out how large the portrait should be.
	local clip = 4 --ShadowUF.db.profile.backdrop.inset + ShadowUF.db.profile.backdrop.clip
	local clipDoubled = clip * 2
	
	local portraitOffset, portraitAlignment, portraitAnchor, portraitWidth

	if( not config.portrait.isBar ) then
		self:ToggleVisibility(frame.portrait, frame.visibility.portrait)
		
		if( frame.visibility.portrait ) then
			-- Figure out portrait alignment
			portraitAlignment = config.portrait.alignment
			
			-- Set the portrait width so we can figure out the offset to use on bars, will do height and position later
			portraitWidth = math.floor(frame:GetWidth() * config.portrait.width) - 3--ShadowUF.db.profile.backdrop.inset
			frame.portrait:SetWidth(portraitWidth - (portraitAlignment == "RIGHT" and 1 or 0.5))
			
			-- Disable portrait if there isn't enough room
			if( portraitWidth <= 0 ) then
				frame.portrait:Hide()
			end

			-- As well as how much to offset bars by (if it's using a left alignment) to keep them all fancy looking
			portraitOffset = clip
			if( portraitAlignment == "LEFT" ) then
				portraitOffset = portraitOffset + portraitWidth
			end
		end
	end

	-- Position and size everything
	local portraitHeight, xOffset = 0, -clip
	local availableHeight = frame:GetHeight() - clipDoubled - (1.25 * totalBars)
	for id, key in pairs(barOrder) do
		local bar = frame[key]
		-- Position the actual bar based on it's type
		if( bar.fullSize ) then
			bar:SetWidth(frame:GetWidth() - clipDoubled)
			bar:SetHeight(availableHeight * (config[key].height / totalWeight))

			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", frame, "TOPLEFT", clip, xOffset)
		else
			bar:SetWidth(frame:GetWidth() - portraitWidth - clipDoubled)
			bar:SetHeight(availableHeight * (config[key].height / totalWeight))

			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", frame, "TOPLEFT", portraitOffset, xOffset)

			portraitHeight = portraitHeight + bar:GetHeight() + 1
		end
		
		-- Figure out where the portrait is going to be anchored to
		if( not portraitAnchor and config[key].order >= config.portrait.fullBefore ) then
			portraitAnchor = bar
		end

		xOffset = xOffset - bar:GetHeight() + (-1.25)
	end

	-- Now position the portrait and set the height
	if( frame.portrait and frame.portrait:IsShown() and portraitAnchor and portraitHeight > 0 ) then
		if( portraitAlignment == "LEFT" ) then
			frame.portrait:ClearAllPoints()
			frame.portrait:SetPoint("TOPLEFT", portraitAnchor, "TOPLEFT", -frame.portrait:GetWidth() - 0.5, 0)
		elseif( portraitAlignment == "RIGHT" ) then
			frame.portrait:ClearAllPoints()
			frame.portrait:SetPoint("TOPRIGHT", portraitAnchor, "TOPRIGHT", frame.portrait:GetWidth() + 1, 0)
		end
			
		if( hasFullSize ) then
			frame.portrait:SetHeight(portraitHeight - 1)
		else
			frame.portrait:SetHeight(frame:GetHeight() - clipDoubled)
		end
	end

	LunaUF:FireModuleEvent("OnLayoutWidgets", frame, config)
end
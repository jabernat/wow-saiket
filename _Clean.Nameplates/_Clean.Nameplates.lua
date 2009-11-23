--[[****************************************************************************
  * _Clean.Nameplates by Saiket                                                *
  * _Units.Nameplates.lua - Skins nameplate frames.                            *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local L = _CleanLocalization.Nameplates;
local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, WorldFrame );
_Clean.Nameplates = me;
me.Version = GetAddOnMetadata( "_Clean.Nameplates", "Version" ):match( "^([%d.]+)" );

me.OptionsCharacter = {
	Version = me.Version;
};
me.OptionsCharacterDefault = {
	Version = me.Version;
	TankMode = false;
};

local Plates = {};
me.Plates = Plates;
me.PlatesVisible = {};
me.TargetOutline = CreateFrame( "Frame" );

me.NameFont = CreateFont( "_CleanNameplatesNameFont" );
me.LevelFont = CreateFont( "_CleanNameplatesLevelFont" );
me.CastFont = CreateFont( "_CleanNameplatesCastFont" );

local Colors = _Clean.Colors;

me.ClassificationUpdateRate = 1;

local TextDimAlpha = 0.6;
local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, "_Clean" );

local PlateWidth =  128;
local PlateHeight = 16;
local PlateBorder = 2;
local CastHeight = 24;

local HealthIsGhost = 20; -- Health values below this are assumed to be ghosts

local InCombat = false;
local HasTarget = false;




--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateOnShow                                    *
  * Description: Reposition elements when a nameplate gets reused.             *
  ****************************************************************************]]
function me:PlateOnShow ()
	me.PlatesVisible[ self ] = true;
	if ( HasTarget ) then
		self:GetParent():SetScript( "OnUpdate", me.PlateOnUpdate );
	end
	self:RegisterEvent( "UNIT_THREAT_LIST_UPDATE" );
	self:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	self:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	if ( not InCombat ) then
		local Plate = self:GetParent();
		Plate:SetWidth( PlateWidth );
		Plate:SetHeight( PlateHeight );
	end

	if ( not MouseIsOver( self:GetParent() ) ) then -- Note: Fix for bug where highlights get stuck in default UI
		self.Highlight:Hide();
	end
	self.Highlight:SetPoint( "TOPLEFT", self, -PlateBorder, PlateBorder );
	self.Highlight:SetPoint( "BOTTOMRIGHT", self, PlateBorder, -PlateBorder );
	self.Level:ClearAllPoints();
	self.Level:SetPoint( "CENTER", self.StatusBackground, 0, 1 );
	self.Name:ClearAllPoints();
	self.Name:SetPoint( "TOPRIGHT", self.Health.Right );
	self.Name:SetPoint( "BOTTOMLEFT", self.Health.Left, 2, 2 );
	self.ThreatBorder:Hide();

	self.Cast:Hide(); -- Note: Fix for cast bars occasionally being shown without any spellcast

	me.PlateUpdateClassification( self, true ); -- Force
	me.PlateOnThreatChanged( self );
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateOnHide                                    *
  ****************************************************************************]]
function me:PlateOnHide ()
	me.PlatesVisible[ self ] = nil;
	if ( HasTarget ) then
		self:GetParent():SetScript( "OnUpdate", nil );
		-- Hide target outline if shown
		if ( self == Plates[ me.TargetOutline:GetParent() ] ) then
			me.TargetOutline:Hide();
		end
	end
	self:UnregisterEvent( "UNIT_THREAT_LIST_UPDATE" );
	self:UnregisterEvent( "PLAYER_REGEN_DISABLED" );
	self:UnregisterEvent( "PLAYER_REGEN_ENABLED" );
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateOnUpdate                                  *
  * Description: Keeps the nameplate's alpha set properly.                     *
  ****************************************************************************]]
do
	local TargetOutline = me.TargetOutline;
	function me:PlateOnUpdate ()
		if ( self:GetAlpha() == 1 ) then -- Current target
			-- Position outline
			TargetOutline:SetParent( self );
			TargetOutline:SetPoint( "TOP" );
			TargetOutline:Show();
		else
			self:SetAlpha( 1 );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateOnHealthChanged                           *
  ****************************************************************************]]
do
	local modf = math.modf;
	local function GetHealthColor ( Percent ) -- Shade bar based on health
		local C = Colors.HealthSmooth;
		if ( Percent == 1 ) then
			return C[ #C - 2 ], C[ #C - 1 ], C[ #C ], 1;
		elseif ( Percent == 0 ) then
			return C[ 1 ], C[ 2 ], C[ 3 ], 1;
		end

		local Segment, Percent = modf( Percent * ( #C / 3 - 1 ) );
		local Index, Inverse = Segment * 3 + 1, 1 - Percent;

		return C[ Index + 3 ] * Percent + C[ Index ] * Inverse,
			C[ Index + 4 ] * Percent + C[ Index + 1 ] * Inverse,
			C[ Index + 5 ] * Percent + C[ Index + 2 ] * Inverse, 1;
	end
	function me:PlateOnHealthChanged ( Health )
		local _, HealthMax = self:GetMinMaxValues();
		local Percent = Health / HealthMax;
		self.Left:SetWidth( Percent * ( PlateWidth - PlateHeight ) );
		if ( self.IsHealerMode ) then
			if ( Health <= HealthIsGhost ) then -- Ghost or close to it
				local C = Colors.disconnected;
				self.Right:SetVertexColor( C[ 1 ], C[ 2 ], C[ 3 ], 1 );
			else
				self.Right:SetVertexColor( GetHealthColor( Percent ) );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateOnThreatChanged                           *
  * Description: Updates threat textures when UNIT_THREAT_LIST_UPDATE fires.   *
  ****************************************************************************]]
do
	local function GetThreat ( self )
		if ( self.ThreatGlow:IsShown() ) then
			return self.ThreatGlow:GetVertexColor() > 0.99 and 2 or 1;
		else
			return 0;
		end
	end
	local unpack = unpack;
	local function UpdateThreat ( self ) -- Color threat borders after one frame's delay
		self:SetScript( "OnUpdate", nil );

		if ( InCombat and self.Reaction <= 4 ) then -- Not friendly
			local Threat = GetThreat( self );
			if ( me.OptionsCharacter.TankMode ) then
				Threat = 2 - Threat;
			end
			if ( Threat > 0 ) then
				if ( Threat == 1 ) then -- Medium
					Threat = Colors.reaction[ 4 ]; -- Neutral
					self.ThreatBorder:SetTexCoord( 0, 1, 0, 0.5 );
				else -- High
					Threat = Colors.reaction[ 1 ]; -- Hostile
					self.ThreatBorder:SetTexCoord( 0, 1, 0.5, 1 );
				end
				self.ThreatBorder:SetVertexColor( unpack( Threat ) );
				self.ThreatBorder:Show();
				return;
			end
		end
		-- Low
		self.ThreatBorder:Hide();
	end
	function me:PlateOnThreatChanged ()
		self:SetScript( "OnUpdate", UpdateThreat );
	end
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PlateUpdateClassification                      *
  * Description: Periodically interprets the status bar color for info.        *
  ****************************************************************************]]
do
	local GetCVarBool = GetCVarBool;
	local floor = floor;
	local R, G, B;
	local function GetClassification ()
		if ( GetCVarBool( "ShowClassColorInNameplate" ) ) then
			-- Round values to match precision in colors tables
			R, G, B = floor( R * 100 + 0.5 ) / 100, floor( G * 100 + 0.5 ) / 100, floor( B * 100 + 0.5 ) / 100;
			for Class, Color in pairs( RAID_CLASS_COLORS ) do
				if ( Color.r == R and Color.g == G and Color.b == B ) then
					return 1, true, Class; -- Hostile player
				end
			end
		end

		if ( R < 0.01 and G > 0.99 and B < 0.01 ) then
			return 8; -- Friendly NPC
		elseif ( R < 0.01 and G < 0.01 and B > 0.99 ) then
			return 8, true; -- Friendly player
		elseif ( R > 0.99 and G > 0.99 and B < 0.01 ) then
			return 4; -- Neutral NPC
		else
			return 1; -- Hostile NPC
		end
	end
	local unpack = unpack;
	local UnitLevel = UnitLevel;
	local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL;
	function me:PlateUpdateClassification ( Force )
		local Health = self.Health;
		R, G, B = Health:GetStatusBarColor();
		if ( Force or Health.R ~= R or Health.G ~= G or Health.B ~= B ) then -- Reaction/classification changed
			Health.R, Health.G, Health.B = R, G, B; -- Save for future comparison

			self.Reaction, self.IsPlayer, self.Class = GetClassification();
			Health.IsHealerMode = self.Reaction > 4 and self.IsPlayer; -- Friendly player

			-- Health bar color
			if ( Health.IsHealerMode ) then
				-- Color fades based on health
				Health.Left:SetBlendMode( "MOD" );
				Health.Left:SetVertexColor( 1, 1, 1, 0.5 );
				Health.Right:SetBlendMode( "ADD" );
				me.PlateOnHealthChanged( Health, Health:GetValue() );
			else
				Health.Left:SetBlendMode( "ADD" );
				Health.Left:SetVertexColor( unpack( Colors.reaction[ self.Reaction ] ) );
				Health.Left:SetAlpha( 1 );
				Health.Right:SetBlendMode( "ADD" );
				Health.Right:SetVertexColor( 1, 1, 1, 0.1 );
			end

			-- Level text/boss icon
			local LevelText, BossIcon = self.Level, self.BossIcon;
			local Level, LevelPlayer = ( LevelText:GetText() or math.huge ) + 0, UnitLevel( "player" );
			if ( LevelPlayer == MAX_PLAYER_LEVEL
				and Level == MAX_PLAYER_LEVEL
				and not self.StatusBorder:IsShown()
			) then -- Hide level text
				LevelText:SetAlpha( 0 );
				BossIcon:SetAlpha( 0 );
			else
				if ( self.Reaction > 4 ) then -- Dim friendly levels
					LevelText:SetAlpha( 0.5 );
					BossIcon:SetAlpha( 0.5 );
					BossIcon:SetTexCoord( 0, 1, 0, 1 );
				else -- Hostile
					LevelText:SetAlpha( 1 );
					BossIcon:SetAlpha( 1 );
					if ( self.Class ) then -- Shrink skull so class icon can be seen
						BossIcon:SetTexCoord( -0.3, 1.3, -0.3, 1.3 );
					else
						BossIcon:SetTexCoord( 0, 1, 0, 1 );
					end
				end
			end

			-- Status background
			local StatusBackground = self.StatusBackground;
			if ( self.Class ) then -- Use class icon
				self.ClassIcon:Show();
				self.ClassIcon:SetTexCoord( unpack( CLASS_ICON_TCOORDS[ self.Class ] ) );
				StatusBackground:SetVertexColor( unpack( Colors.class[ self.Class ] ) );
				StatusBackground:SetAlpha( 1 );
			else
				self.ClassIcon:Hide();

				if ( self.Reaction <= 4 and Level > LevelPlayer ) then -- Use difficulty color
					R, G, B = LevelText:GetTextColor();
					StatusBackground:SetVertexColor( R, G, B, 1 );
				else
					if ( Health.IsHealerMode ) then
						StatusBackground:SetVertexColor( 1, 1, 1 );
					else -- Use reaction color
						StatusBackground:SetVertexColor( Health.Left:GetVertexColor() );
					end
					StatusBackground:SetAlpha( 0.3 );
				end
			end

			return true;
		end
	end
end

--[[****************************************************************************
  * Function: _Clean.Nameplates:CastOnShow                                     *
  * Description: Reposition elements when a castbar is shown.                  *
  ****************************************************************************]]
function me:CastOnShow ()
	self:RegisterEvent( "UNIT_SPELLCAST_INTERRUPTIBLE" );
	self:RegisterEvent( "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" );

	local Name, _, _, _, _, _, _, _, Uninterruptible = UnitCastingInfo( "target" );
	if ( not Name ) then
		Name, _, _, _, _, _, _, Uninterruptible = UnitChannelInfo( "target" );
	end
	self.Name:SetText( Name );

	self:ClearAllPoints();
	self:SetPoint( "TOPLEFT", self.Icon, "TOPRIGHT" );
	self:SetPoint( "BOTTOM", self.Icon, "BOTTOM" );
	self:SetPoint( "RIGHT", self:GetParent(), CastHeight - PlateHeight, 0 );
	self:SetStatusBarColor( unpack( Colors.Cast ) );

	self.NoInterrupt:ClearAllPoints();
	self.NoInterrupt:SetPoint( "CENTER", self.Icon, -1, -2 );
	self.NoInterrupt:SetWidth( CastHeight * 3 );
	self.NoInterrupt:SetHeight( CastHeight * 3 );
	me.CastOnInterruptibleChanged( self, nil, Uninterruptible );
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:CastOnHide                                     *
  ****************************************************************************]]
function me:CastOnHide ()
	self:UnregisterEvent( "UNIT_SPELLCAST_INTERRUPTIBLE" );
	self:UnregisterEvent( "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" );
	self.Uninterruptible = nil;
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:CastOnInterruptibleChanged                     *
  ****************************************************************************]]
do
	local function UpdateAnimation ( self )
		-- Note: Plays the flash animation after the rendering engine has moved the
		--   texture in place for certain.  Otherwise, the animation would play at
		--   the texture's previous location.
		self:SetScript( "OnUpdate", nil );
		me.Flash.Animation:Play();
	end
	local UninterruptibleEvents = {
		UNIT_SPELLCAST_INTERRUPTIBLE = false;
		UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true;
	};
	function me:CastOnInterruptibleChanged ( Event, Value )
		local Uninterruptible;
		if ( Event ) then
			if ( Value == "target" ) then
				Uninterruptible = UninterruptibleEvents[ Event ];
			end
		else -- Called directly
			Uninterruptible = Value;
		end
		if ( Uninterruptible ~= nil and self.Uninterruptible ~= Uninterruptible ) then
			self.Uninterruptible = Uninterruptible;

			-- Gray out bar if uninterruptable
			for _, Texture in ipairs( self ) do
				-- Don't use vertex color if shader isn't supported
				Texture:SetDesaturated( Uninterruptible );
			end
			if ( Uninterruptible ) then -- Use color when grayed out for contrast
				self.Name:SetTextColor( unpack( Colors.Normal ) );
			else
				self.Name:SetTextColor( 1, 1, 1, 1 ); -- Plain white
			end

			local Flash = me.Flash;
			Flash:StopAnimating();
			if ( not Uninterruptible and self:GetParent().Reaction <= 4 ) then -- Not friendly and spell just became interruptible
				Flash:SetParent( self );
				Flash:Show();
				Flash:SetPoint( "CENTER", -CastHeight / 2, 0 ); -- Account for spell icon on left
				self:SetScript( "OnUpdate", UpdateAnimation );
			else
				Flash:Hide();
				self:SetScript( "OnUpdate", nil ); -- Cancel pending flash
			end
		end
	end
end




--[[****************************************************************************
  * Function: local PlateAdd                                                   *
  * Description: Adds and skins a new nameplate.                               *
  ****************************************************************************]]
local function PlateAdd ( Plate )
	local Visual = CreateFrame( "Frame", nil, Plate );
	Plates[ Plate ] = Visual;

	local Health, Cast = Plate:GetChildren();
	Visual.Health, Visual.Cast = Health, Cast;
	local Border, BossIcon, RaidIcon, CastBorder;
	Visual.ThreatGlow, Border,
		CastBorder, Cast.NoInterrupt, Cast.Icon,
		Visual.Highlight, Visual.Name, Visual.Level,
		Visual.BossIcon, RaidIcon, Visual.StatusBorder = Plate:GetRegions();


	Visual:SetScript( "OnEvent", me.PlateOnThreatChanged );
	Visual:SetWidth( PlateWidth );
	Visual:SetHeight( PlateHeight );
	Visual:SetPoint( "TOP" );


	-- Border
	-- Leave parented to original nameplate for layering
	Border:SetTexture( [[Interface\Buttons\WHITE8X8]] );
	Border:SetVertexColor( 0, 0, 0, 0.75 );
	Border:SetPoint( "TOPLEFT", Visual, -PlateBorder, PlateBorder );
	Border:SetPoint( "BOTTOMRIGHT", Visual, PlateBorder, -PlateBorder );
	Visual.Highlight:SetTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]] );


	-- Indicator section
	-- Create a background for the status
	Visual.StatusBackground = Visual:CreateTexture( nil, "BORDER" );
	Visual.StatusBackground:SetPoint( "TOPLEFT" );
	Visual.StatusBackground:SetPoint( "BOTTOMRIGHT", Visual, "BOTTOMLEFT", PlateHeight, 0 );
	Visual.StatusBackground:SetTexture( BarTexture );
	Visual.StatusBackground:SetBlendMode( "ADD" );

	-- Border for status section
	Visual.StatusBorder:SetParent( Visual );
	Visual.StatusBorder:SetDrawLayer( "OVERLAY" );
	Visual.StatusBorder:SetTexture( [[Interface\AchievementFrame\UI-Achievement-IconFrame]] );
	Visual.StatusBorder:SetTexCoord( 0, 0.5625, 0, 0.5625 );
	Visual.StatusBorder:SetAlpha( 0.8 );
	local Padding = PlateHeight * 0.35;
	Visual.StatusBorder:ClearAllPoints();
	Visual.StatusBorder:SetPoint( "TOPRIGHT", Visual.StatusBackground, Padding, Padding );
	Visual.StatusBorder:SetPoint( "BOTTOMLEFT", Visual.StatusBackground, -Padding, -Padding );

	-- Put boss icon inside status border
	Visual.BossIcon:SetParent( Visual );
	Visual.BossIcon:SetAllPoints( Visual.StatusBackground );
	Visual.BossIcon:SetDrawLayer( "ARTWORK" );
	Visual.BossIcon:SetBlendMode( "ADD" );

	-- Level text
	Visual.Level:SetParent( Visual );
	Visual.Level:SetFontObject( me.LevelFont );

	-- Class icon
	Visual.ClassIcon = Visual:CreateTexture( nil, "ARTWORK" );
	Visual.ClassIcon:SetAllPoints( Visual.StatusBackground );
	Visual.ClassIcon:SetTexture( [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]] );
	Visual.ClassIcon:SetBlendMode( "ADD" );
	Visual.ClassIcon:SetAlpha( 0.5 );
	SetDesaturation( Visual.ClassIcon, true );


	-- Health bar
	Health:SetParent( Visual );
	Health:SetFrameLevel( Visual:GetFrameLevel() );
	Health:GetStatusBarTexture():Hide();
	Health:SetAlpha( TextDimAlpha ); -- To fade out the health text parented to it
	-- Separate filled and empty halves of the statusbar
	Health.Left = Visual:CreateTexture( nil, "ARTWORK" );
	Health.Left:SetPoint( "TOPLEFT", Visual.StatusBackground, "TOPRIGHT" );
	Health.Left:SetPoint( "BOTTOM" );
	Health.Left:SetTexture( BarTexture );
	Health.Right = Visual:CreateTexture( nil, "ARTWORK" );
	Health.Right:SetPoint( "TOPRIGHT" );
	Health.Right:SetPoint( "BOTTOMLEFT", Health.Left, "BOTTOMRIGHT" );
	Health.Right:SetTexture( BarTexture );
	Health:HookScript( "OnValueChanged", me.PlateOnHealthChanged );
	me.PlateOnHealthChanged( Health, Health:GetValue() );

	-- Name text
	Visual.Name:SetParent( Health );
	Visual.Name:SetFontObject( me.NameFont );


	-- Cast bar
	Cast:SetParent( Visual );
	Cast:HookScript( "OnShow", me.CastOnShow );
	Cast:HookScript( "OnHide", me.CastOnHide );
	Cast:HookScript( "OnEvent", me.CastOnInterruptibleChanged );
	Cast:SetStatusBarTexture( BarTexture );
	local BarTexture = Cast:GetStatusBarTexture();
	BarTexture:SetDrawLayer( "BORDER" );
	Cast[ #Cast + 1 ] = BarTexture; -- Register for desaturation on uninterruptible
	-- Icon/icon border
	Cast.Icon:SetParent( Cast );
	Cast.Icon:ClearAllPoints();
	Cast.Icon:SetPoint( "BOTTOMRIGHT", Visual.StatusBackground, "TOPRIGHT", 0, 2 );
	Cast.Icon:SetWidth( CastHeight );
	Cast.Icon:SetHeight( CastHeight );
	_Clean.RemoveIconBorder( Cast.Icon );
	CastBorder:SetTexture(); -- Seems to cause crashes when attempting to anchor
	local IconBorder = Cast:CreateTexture( nil, "OVERLAY" );
	IconBorder:SetTexture( [[Interface\AchievementFrame\UI-Achievement-IconFrame]] );
	IconBorder:SetTexCoord( 0, 0.5625, 0, 0.5625 );
	local Padding = CastHeight * 0.35;
	IconBorder:SetPoint( "TOPRIGHT", Cast.Icon, Padding, Padding );
	IconBorder:SetPoint( "BOTTOMLEFT", Cast.Icon, -Padding, -Padding );
	Cast[ #Cast + 1 ] = IconBorder;
	-- Bar border/background
	local Background = Cast:CreateTexture( nil, "BACKGROUND" );
	Background:SetAllPoints();
	Background:SetTexture( BarTexture );
	Background:SetBlendMode( "MOD" );
	Background:SetAlpha( 0.5 );
	local BarBorder = Cast:CreateTexture( nil, "ARTWORK" );
	BarBorder:SetPoint( "TOPRIGHT", 4, 8 );
	BarBorder:SetPoint( "BOTTOMLEFT", -4, -8 );
	BarBorder:SetTexture( [[Interface\AchievementFrame\UI-Achievement-ProgressBar-Border]] );
	BarBorder:SetTexCoord( 0, 0.875, 0, 0.75 );
	BarBorder:SetVertexColor( 1, 0.9, 0.4 ); -- Matches color of icon border
	Cast[ #Cast + 1 ] = BarBorder;
	-- Interrupt icon
	Cast.NoInterrupt:SetParent( Cast );
	Cast.NoInterrupt:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Shields]] );
	Cast.NoInterrupt:SetDrawLayer( "BACKGROUND" );
	Cast.NoInterrupt:SetTexCoord( 1, 0.5, 0, 1 );
	-- Spell name
	Cast.Name = Cast:CreateFontString( nil, "ARTWORK", me.CastFont:GetName() );
	Cast.Name:SetPoint( "TOPLEFT", 8, -4 );
	Cast.Name:SetPoint( "BOTTOMRIGHT", -4, 4 );


	-- Misc
	-- Put raid icon above nameplate
	RaidIcon:SetWidth( 32 );
	RaidIcon:SetHeight( 32 );
	RaidIcon:ClearAllPoints();
	RaidIcon:SetPoint( "BOTTOM", Visual, "TOP" );

	-- Threat
	Visual.ThreatGlow:SetTexture();
	Visual.ThreatBorder = Visual:CreateTexture( nil, "BACKGROUND" );
	Visual.ThreatBorder:SetPoint( "CENTER" );
	Visual.ThreatBorder:SetWidth( ( PlateWidth + 2 * PlateBorder ) * 256 / 128 );
	Visual.ThreatBorder:SetHeight( ( PlateHeight + 2 * PlateBorder ) * 32 / 12 );
	Visual.ThreatBorder:SetTexture( [[Interface\AddOns\_Clean.Nameplates\Skin\ThreatBorders]] );


	Visual:SetScript( "OnShow", me.PlateOnShow );
	Visual:SetScript( "OnHide", me.PlateOnHide );
	if ( Plate:IsVisible() ) then
		me.PlateOnShow( Visual );
	end
end
--[[****************************************************************************
  * Function: local PlatesScan                                                 *
  * Description: Scans children of WorldFrame and handles new nameplates.      *
  ****************************************************************************]]
local PlatesScan;
do
	local select = select;
	local Frame, Region;
	function PlatesScan ( ... )
		for Index = 1, select( "#", ... ) do
			Frame = select( Index, ... );
			if ( not Plates[ Frame ] ) then
				Region = Frame:GetRegions();
				if ( Region and Region:GetObjectType() == "Texture" and Region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]] ) then
					PlateAdd( Frame );
				end
			end
		end
	end
end




--[[****************************************************************************
  * Function: _Clean.Nameplates:VARIABLES_LOADED                               *
  ****************************************************************************]]
function me:VARIABLES_LOADED ()
	me.VARIABLES_LOADED = nil;

	SetCVar( "ThreatWarning", 3 );
	SetCVar( "ShowClassColorInNameplate", 1 );
	-- Don't throw an error if the client doesn't have this CVar yet
	pcall( SetCVar, "NameplateAllowOverlap", 1 );
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PLAYER_REGEN_ENABLED                           *
  * Description: Resize any new nameplates that couldn't be resized in combat. *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	InCombat = false;

	for Plate in pairs( Plates ) do
		Plate:SetWidth( PlateWidth );
		Plate:SetHeight( PlateHeight );
	end
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PLAYER_REGEN_DISABLED                          *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	InCombat = true;
end
--[[****************************************************************************
  * Function: _Clean.Nameplates:PLAYER_TARGET_CHANGED                          *
  ****************************************************************************]]
function me:PLAYER_TARGET_CHANGED ()
	HasTarget = UnitExists( "target" );

	-- Reset target indicator
	me.TargetOutline:Hide();

	-- Set or clear individual plate update handlers
	local UpdateScript = HasTarget and me.PlateOnUpdate or nil;
	for Visual in pairs( me.PlatesVisible ) do
		Visual:GetParent():SetScript( "OnUpdate", UpdateScript );
	end
end

--[[****************************************************************************
  * Function: _Clean.Nameplates:OnUpdate                                       *
  ****************************************************************************]]
do
	local ChildCount, NewChildCount = 0;
	local NextUpdate = 0;
	local pairs = pairs;
	function me:OnUpdate ( Elapsed )
		-- Check for new nameplates
		NewChildCount = WorldFrame:GetNumChildren();
		if ( ChildCount ~= NewChildCount ) then
			ChildCount = NewChildCount;

			PlatesScan( WorldFrame:GetChildren( WorldFrame ) );
		end

		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = me.ClassificationUpdateRate;

			for Visual in pairs( me.PlatesVisible ) do
				me.PlateUpdateClassification( Visual );
			end
		end
	end
end




--[[****************************************************************************
  * Function: _Clean.Nameplates.SetTankMode                                    *
  * Description: Inverts threat display mode for tanks.                        *
  ****************************************************************************]]
function me.SetTankMode ( Enable )
	if ( me.OptionsCharacter.TankMode ~= Enable ) then
		me.OptionsCharacter.TankMode = Enable;

		-- Immediately update visible plates
		for Visual in pairs( me.PlatesVisible ) do
			me.PlateOnThreatChanged( Visual );
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _Clean.Nameplates.SlashCommand                                   *
  * Description: Slash command to set tank threat mode.                        *
  ****************************************************************************]]
function me.SlashCommand ( Input )
	local Enable = tonumber( SecureCmdOptionParse( Input ) ); -- 1 to enable, 0 to disable
	if ( Enable ) then
		Enable = Enable == 1;
	else
		Enable = not me.OptionsCharacter.TankMode;
	end

	local Color = Enable and GREEN_FONT_COLOR or NORMAL_FONT_COLOR;
	DEFAULT_CHAT_FRAME:AddMessage( L.TANKMODE_FORMAT:format( L[ Enable and "ENABLED" or "DISABLED" ] ),
		Color.r, Color.g, Color.b );
	me.SetTankMode( Enable )
end




--[[****************************************************************************
  * Function: _Clean.Nameplates.Synchronize                                    *
  * Description: Loads an options table, or the defaults.                      *
  ****************************************************************************]]
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if ( not OptionsCharacter ) then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	me.SetTankMode( OptionsCharacter.TankMode );
end
--[[****************************************************************************
  * Function: _Clean.Nameplates.OnLoad                                         *
  * Description: Loads defaults and validates settings.                        *
  ****************************************************************************]]
function me.OnLoad ()
	me.OnLoad = nil;

	local OptionsCharacter = _CleanNameplatesOptionsCharacter;
	_CleanNameplatesOptionsCharacter = me.OptionsCharacter;

	if ( OptionsCharacter ) then
		OptionsCharacter.Version = me.Version;
	end

	me.Synchronize( OptionsCharacter ); -- Loads defaults if nil
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", _Clean.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "VARIABLES_LOADED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	me:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	_Clean.RegisterAddOnInitializer( "_Clean.Nameplates", me.OnLoad );


	-- Fonts
	me.NameFont:SetFont( [[Fonts\ARIALN.TTF]], 11, "OUTLINE" );
	me.NameFont:SetShadowColor( 0, 0, 0, 0 ); -- Hide shadow
	me.NameFont:SetJustifyV( "MIDDLE" );
	me.NameFont:SetJustifyH( "LEFT" );

	me.LevelFont:SetFont( [[Fonts\ARIALN.TTF]], 9, "OUTLINE" );
	me.LevelFont:SetShadowColor( 0, 0, 0, 1 );
	me.LevelFont:SetShadowOffset( 1.5, -1.5 );

	me.CastFont:SetFont( [[Fonts\ARIALN.TTF]], 14, "OUTLINE" );
	me.CastFont:SetJustifyV( "MIDDLE" );
	me.CastFont:SetJustifyH( "LEFT" );


	-- Target outline
	me.TargetOutline:SetWidth( PlateWidth );
	me.TargetOutline:SetHeight( PlateHeight );
	local Outline = me.TargetOutline:CreateTexture( nil, "BACKGROUND" );
	Outline:SetTexture( 1, 1, 1 );
	Outline:SetPoint( "TOPRIGHT", PlateBorder, PlateBorder );
	Outline:SetPoint( "BOTTOMLEFT", -PlateBorder, -PlateBorder );
	local Mask = me.TargetOutline:CreateTexture( nil, "BORDER" );
	Mask:SetTexture( 0, 0, 0 );
	Mask:SetAllPoints();


	-- Interrupt flash
	local Flash = me:CreateTexture( nil, "OVERLAY" );
	Flash:SetWidth( 400 / 300 * ( PlateWidth + 2 * ( CastHeight - PlateHeight ) ) );
	Flash:SetHeight( 171 / 70 * CastHeight );
	Flash:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]] );
	Flash:SetBlendMode( "ADD" );
	Flash:SetTexCoord( 0, 0.78125, 0, 0.66796875 );
	Flash:SetAlpha( 0 );
	Flash:Hide();
	me.Flash = Flash;
	Flash.Animation = Flash:CreateAnimationGroup();
	local FadeIn = Flash.Animation:CreateAnimation( "Alpha" );
	FadeIn:SetChange( 1.0 );
	FadeIn:SetDuration( 0.1 );
	local FadeOut = Flash.Animation:CreateAnimation( "Alpha" );
	FadeOut:SetOrder( 2 );
	FadeOut:SetChange( -1.0 );
	FadeOut:SetDuration( 0.3 );


	SlashCmdList[ "_CLEAN_NAMEPLATES" ] = me.SlashCommand;
end

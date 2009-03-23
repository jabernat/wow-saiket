--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.oUF.lua - Adds custom skinned unit frames using oUF.                *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local L = _UnitsLocalization;
local _Units = _Units;
local me = {};
_Units.oUF = me;

me.BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, "_Clean" );

me.FontNormal = "_UnitsOUFFontNormal";
me.FontTiny = "_UnitsOUFFontTiny";
me.FontMicro = "_UnitsOUFFontMicro";

local Colors = setmetatable( {
	pet =  { 0.1, 0.5, 0.1 };
	smooth = {
		1.0, 0.0, 0.0, --   0%
		0.6, 0.6, 0.0, --  50%
		0.0, 0.4, 0.0  -- 100%
	};
	power = setmetatable( {
		MANA   = { 0.2, 0.4, 0.7 };
		RAGE   = { 0.6, 0.2, 0.3 };
		ENERGY = { 0.6, 0.6, 0.3 };
	}, { __index = oUF.colors.power; } );

	cast = { 0.6, 0.6, 0.3 };
	experience = oUF.colors.reaction[ 5 ]; -- Friendly
	experience_rested = { 0.2, 0.4, 0.7, 0.6 };
}, { __index = oUF.colors; } );
me.Colors = Colors;
Colors.power.RUNIC_POWER = Colors.power.RAGE;
Colors.power.FUEL = Colors.power.ENERGY;

me.StyleMeta = {
	__index = { -- Defaults
		PortraitSide = "RIGHT"; -- "LEFT"/"RIGHT"/false
		HealthLength = "Small"; -- "Full"/"Small"/"Tiny"
		PowerLength  = "Full"; -- Same as Health
		NameFont = me.FontNormal;
		BarValueFont = me.FontTiny;
		CastTime = true;
		AuraSize = 15;
		DebuffHighlightFilter = true;
	};
};




--[[****************************************************************************
  * Function: _Units.oUF:SetStatusBarColor                                     *
  * Description: Colors bar text to match bars.                                *
  ****************************************************************************]]
function me:SetStatusBarColor ( R, G, B, A )
	self.Texture:SetVertexColor( R, G, B, A );
	self.Value:SetTextColor( R, G, B, A );
end

--[[****************************************************************************
  * Function: _Units.oUF:CreateBarBackground                                   *
  ****************************************************************************]]
function me:CreateBarBackground ( Brightness )
	local Background = self:CreateTexture( nil, "BACKGROUND" );
	Background:SetAllPoints( self );
	Background:SetVertexColor( Brightness, Brightness, Brightness );
	Background:SetTexture( me.BarTexture );

	return Background;
end
--[[****************************************************************************
  * Function: _Units.oUF:CreateBar                                             *
  ****************************************************************************]]
function me:CreateBar ()
	local Bar = CreateFrame( "StatusBar", nil, self );
	Bar:SetStatusBarTexture( me.BarTexture );
	Bar.Texture = Bar:GetStatusBarTexture();
	return Bar;
end
--[[****************************************************************************
  * Function: _Units.oUF:CreateBarReverse                                      *
  * Description: Creates a status bar that fills in reverse.                   *
  ****************************************************************************]]
do
	local function SetStatusBarTexture ( self, Path )
		self.Texture:SetTexture( Path );
	end
	local function GetStatusBarTexture ( self )
		return self.Texture;
	end
	local function OnSizeChanged ( self, Width )
		Width = ( 1 - self:GetValue() / select( 2, self:GetMinMaxValues() ) ) * Width;
		if ( Width > 0 ) then
			self.Texture:SetWidth( Width );
			self.Texture:Show();
		else -- Full health
			self.Texture:Hide();
		end
	end
	local function OnValueChanged ( self )
		OnSizeChanged( self, self:GetWidth() );
	end
	function me:CreateBarReverse ()
		local Bar = CreateFrame( "StatusBar", nil, self );
		Bar.Texture = Bar:CreateTexture( nil, "BORDER" );
		Bar.Texture:SetPoint( "TOPRIGHT" );
		Bar.Texture:SetPoint( "BOTTOM" );
		Bar.Texture:SetTexture( me.BarTexture );

		Bar.SetStatusBarTexture = SetStatusBarTexture;
		Bar.GetStatusBarTexture = GetStatusBarTexture;
		Bar:SetScript( "OnValueChanged", OnValueChanged );
		Bar:SetScript( "OnSizeChanged", OnSizeChanged );

		return Bar;
	end
end




--[[****************************************************************************
  * Function: _Units.oUF.BarFormatValue                                        *
  * Description: Formats bar text depending on the bar's style.                *
  ****************************************************************************]]
do
	local NumberFormats = {
		[ "Full" ] = function ( Value )
			return Value;
		end;
		[ "Small" ] = function ( Value )
			if ( Value >= 1e6 ) then
				return ( "%.1fm" ):format( Value / 1e6 );
			elseif ( Value >= 1e3 ) then
				return ( "%.1fk" ):format( Value / 1e3 );
			else
				return Value;
			end
		end;
		[ "Tiny" ] = function ( Value )
			if ( Value >= 1e6 ) then
				return ( "%.0fm" ):format( Value / 1e6 );
			elseif ( Value >= 1e3 ) then
				return ( "%.0fk" ):format( Value / 1e3 );
			else
				return Value;
			end
		end;
	};
	function me:BarFormatValue ( Value, ValueMax )
		local Format = NumberFormats[ self.ValueLength ];
		self.Value:SetFormattedText( "%s/%s", Format( Value ), Format( ValueMax ) );
	end
end

--[[****************************************************************************
  * Function: _Units.oUF:PostUpdateHealth                                      *
  ****************************************************************************]]
do
	local function ColorDead ( Health, Label )
		Health.Value:SetText( L[ Label ] );
		Health.Texture:SetVertexColor( 0.2, 0.2, 0.2 );
		Health.Value:SetTextColor( unpack( Colors.disconnected ) );
	end
	function me:PostUpdateHealth ( Event, UnitID, Bar, Health, HealthMax )
		if ( UnitIsGhost( UnitID ) ) then
			Bar:SetValue( 0 );
			ColorDead( Bar, "GHOST" );
		elseif ( UnitIsDead( UnitID ) and not UnitIsFeignDeath( UnitID ) ) then
			Bar:SetValue( 0 );
			ColorDead( Bar, "DEAD" );
		elseif ( not UnitIsConnected( UnitID ) ) then
			ColorDead( Bar, "OFFLINE" );
		else
			me.BarFormatValue( Bar, Health, HealthMax );
		end
	end
end

--[[****************************************************************************
  * Function: _Units.oUF:PostUpdatePower                                       *
  ****************************************************************************]]
function me:PostUpdatePower ( Event, UnitID, Bar, Power, PowerMax )
	if ( UnitIsDeadOrGhost( UnitID ) ) then
		Bar:SetValue( 0 );
		Bar.Value:SetText();
	elseif ( select( 2, UnitPowerType( UnitID ) ) ~= "MANA" ) then
		Bar.Value:SetText();
	else
		me.BarFormatValue( Bar, Power, PowerMax );
	end
end




--[[****************************************************************************
  * Function: _Units.oUF:PostCreateAuraIcon                                    *
  ****************************************************************************]]
function me:PostCreateAuraIcon ( Frame )
	_Clean.RemoveButtonIconBorder( Frame.icon );
	Frame.UpdateTooltip = me.AuraUpdateTooltip;
end
--[[****************************************************************************
  * Function: _Units.oUF:PostCreateAuraIconPlayer                              *
  ****************************************************************************]]
do
	local function CancelPlayerBuff ( self, Button )
		if ( Button == "RightButton" ) then
			CancelUnitBuff( "player", self:GetID(), self.filter );
		end
	end
	function me:PostCreateAuraIconPlayer ( Frame, _, _, IsDebuff )
		if ( not IsDebuff ) then
			Frame:SetScript( "OnMouseUp", CancelPlayerBuff );
		end
		me.PostCreateAuraIcon( self, Frame )
	end
end
--[[****************************************************************************
  * Function: _Units.oUF:PostUpdateAura                                        *
  * Description: Resizes the buffs frame so debuffs anchor correctly.          *
  ****************************************************************************]]
function me:PostUpdateAura ()
	local Frame = self.Buffs;
	local BuffsPerRow = max( 1, floor( Frame:GetWidth() / Frame.size ) );
	Frame:SetHeight( max( 1, Frame.size * ceil( Frame.visibleBuffs / BuffsPerRow ) ) );
end
--[[****************************************************************************
  * Function: _Units.oUF:AuraUpdateTooltip                                     *
  * Description: Updates aura tooltips while they're moused over.              *
  ****************************************************************************]]
function me:AuraUpdateTooltip ()
	GameTooltip:SetUnitAura( self.frame.unit, self:GetID(), self.filter );
end


--[[****************************************************************************
  * Function: _Units.oUF:DebuffHighlightSetVertexColor                         *
  * Description: Sets the vertex color of all border textures.                 *
  ****************************************************************************]]
function me:DebuffHighlightSetVertexColor ( R, G, B, A )
end
--[[****************************************************************************
  * Function: _Units.oUF:DebuffHighlightGetVertexColor                         *
  ****************************************************************************]]
me.DebuffHighlightGetVertexColor = _Clean.NilFunction;
--[[****************************************************************************
  * Function: _Units.oUF:CreateDebuffHighlight                                 *
  * Description: Creates a border frame that behaves like a texture for the    *
  *   oUF_DebuffHighlight element.                                             *
  ****************************************************************************]]
do
	local function SetVertexColorRegions ( R, G, B, A, ... )
		for Index = 1, select( "#", ... ) do
			select( Index, ... ):SetVertexColor( R, G, B, A );
		end
	end
	local function SetVertexColor ( self, R, G, B, A )
		if ( R ) then
			SetVertexColorRegions( R, G, B, A, self:GetRegions() );
			self:Show();
		else
			self:Hide();
		end
	end
	local function CreateTexture( self, Point1, Point1Frame, Point2, Point2Frame, Point2Rel )
		local Texture = self:CreateTexture( nil, "OVERLAY" );
		Texture:SetTexture( "Interface\\Buttons\\WHITE8X8" );
		Texture:SetPoint( Point1, Point1Frame );
		Texture:SetPoint( Point2, Point2Frame, Point2Rel );
	end
	function me:CreateDebuffHighlight ( Backdrop )
		local Frame = CreateFrame( "Frame", nil, self.Health );
		Frame.GetVertexColor = _Clean.NilFunction;
		Frame.SetVertexColor = SetVertexColor;
		-- Four separate outline textures so faded frames blend correctly
		CreateTexture( Frame, "TOPLEFT", Backdrop, "BOTTOMRIGHT", self, "TOPRIGHT" );
		CreateTexture( Frame, "TOPRIGHT", Backdrop, "BOTTOMLEFT", self, "BOTTOMRIGHT" );
		CreateTexture( Frame, "BOTTOMRIGHT", Backdrop, "TOPLEFT", self, "BOTTOMLEFT" );
		CreateTexture( Frame, "BOTTOMLEFT", Backdrop, "TOPRIGHT", self, "TOPLEFT" );
		return Frame;
	end
end




--[[****************************************************************************
  * Function: _Units.oUF:ReputationPostUpdate                                  *
  * Description: Recolors the reputation bar on update.                        *
  ****************************************************************************]]
function me:ReputationPostUpdate ( _, _, Bar, _, _, _, _, StandingID )
	Bar:SetStatusBarColor( unpack( Colors.reaction[ StandingID ] ) );
end

--[[****************************************************************************
  * Function: _Units.oUF:ExperiencePostUpdate                                  *
  * Description: Adjusts the rested experience bar segment.                    *
  ****************************************************************************]]
function me:ExperiencePostUpdate ( _, UnitID, Bar, Value, ValueMax )
	if ( self.unit == "player" ) then
		local RestedExperience = GetXPExhaustion();
		local Texture = Bar.RestTexture;
		if ( RestedExperience ) then
			local Width = Bar:GetParent():GetWidth(); -- Bar's width not calculated by PLAYER_ENTERING_WORLD, but parent's width is
			Texture:Show();
			Texture:SetPoint( "LEFT", Value / ValueMax * Width, 0 );
			Texture:SetPoint( "RIGHT", Bar, "LEFT", min( 1, ( Value + RestedExperience ) / ValueMax ) * Width, 0 );
		else -- Not resting
			Texture:Hide();
		end
	end
end




--[[****************************************************************************
  * Function: _Units.oUF:ClassificationUpdate                                  *
  * Description: Shows the rare/elite border for appropriate mobs.             *
  ****************************************************************************]]
do
	local Classifications = {
		elite = "elite"; worldboss = "elite";
		rare = "rare"; rareelite = "rare";
	};
	function me:ClassificationUpdate ( Event, UnitID )
		if ( not Event or UnitIsUnit( UnitID, self.unit ) ) then
			local Type = Classifications[ UnitClassification( self.unit ) ];
			local Texture = self.Classification;
			if ( Type ) then
				Texture:Show();
				SetDesaturation( Texture, Type == "rare" );
			else
				Texture:Hide();
			end
		end
	end
end




--[[****************************************************************************
  * Function: _Units.oUF.TagClassification                                     *
  * Description: Tag that displays level/classification or group # in raid.    *
  ****************************************************************************]]
do
	local Plus = { worldboss = true; elite = true; rareelite = true; };
	function me.TagClassification ( UnitID )
		if ( UnitID == "player" and GetNumRaidMembers() > 0 ) then
			return ( "(G%d)" ):format( select( 3, GetRaidRosterInfo( GetNumRaidMembers() ) ) );
		else
			local Level = UnitLevel( UnitID );
			if ( Plus[ UnitClassification( UnitID ) ] or Level ~= MAX_PLAYER_LEVEL or UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL ) then
				local Color = Level < 0 and QuestDifficultyColor[ "impossible" ] or GetDifficultyColor( Level );
				return L.OUF_CLASSIFICATION_FORMAT:format( Color.r * 255, Color.g * 255, Color.b * 255,
					oUF.Tags[ "[smartlevel]" ]( UnitID ) );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Units.oUF.TagName                                               *
  * Description: Colored name with server name if different from player's.     *
  ****************************************************************************]]
do
	local Name, Server, Color, R, G, B;
	function me.TagName ( UnitID, Override )
		Name, Server = UnitName( Override or UnitID );

		if ( UnitIsPlayer( UnitID ) ) then
			Color = Colors.class[ select( 2, UnitClass( UnitID ) ) ];
		elseif ( UnitPlayerControlled( UnitID ) or UnitPlayerOrPetInRaid( UnitID ) ) then -- Pet
			Color = Colors.pet;
		else -- NPC
			Color = Colors.reaction[ UnitReaction( UnitID, "player" ) or 5 ];
		end

		R, G, B = unpack( Color );
		return L.OUF_NAME_FORMAT:format( R * 255, G * 255, B * 255,
			Server and L.OUF_SERVER_DELIMITER:join( Name, Server ) or Name );
	end
end




--[[****************************************************************************
  * Function: _Units.oUF.StyleMeta.__call                                      *
  * Description: Creates a generic solo unit frame.                            *
  ****************************************************************************]]
function me.StyleMeta.__call ( Style, self, UnitID )
	self.menu = _Units.ShowGenericMenu;
	self.colors = Colors;
	self.disallowVehicleSwap = true;

	self[ IsAddOnLoaded( "oUF_SpellRange" ) and "SpellRange" or "Range" ] = true;
	self.inRangeAlpha = 1.0;
	self.outsideRangeAlpha = 0.4;

	self:SetScript( "OnEnter", UnitFrame_OnEnter );
	self:SetScript( "OnLeave", UnitFrame_OnLeave );

	local Backdrop = _Clean.Backdrop.Add( self, _Clean.Backdrop.Padding );
	self:SetHighlightTexture( "Interface\\QuestFrame\\UI-QuestTitleHighlight" );
	self:GetHighlightTexture():SetAllPoints( Backdrop );
	local Background = self:CreateTexture( nil, "BACKGROUND" );
	Background:SetAllPoints();
	Background:SetTexture( 0, 0, 0 );

	local Bars = CreateFrame( "Frame", nil, self );
	self.Bars = Bars;
	-- Portrait and overlapped elements
	if ( Style.PortraitSide ) then
		local Portrait = CreateFrame( "PlayerModel", nil, self );
		self.Portrait = Portrait;
		local Side = Style.PortraitSide;
		local Opposite = Side == "RIGHT" and "LEFT" or "RIGHT";
		Portrait:SetPoint( "TOP" );
		Portrait:SetPoint( "BOTTOM" );
		Portrait:SetPoint( Side );
		Portrait:SetWidth( Style[ "initial-height" ] );

		local Classification = Portrait:CreateTexture( nil, "OVERLAY" );
		local Size = Style[ "initial-height" ] * 1.35;
		self.Classification = Classification;
		Classification:SetPoint( "CENTER" );
		Classification:SetWidth( Size );
		Classification:SetHeight( Size );
		Classification:SetTexture( "Interface\\AchievementFrame\\UI-Achievement-IconFrame" );
		Classification:SetTexCoord( 0, 0.5625, 0, 0.5625 );
		Classification:SetAlpha( 0.8 );
		tinsert( self.__elements, me.ClassificationUpdate );
		self:RegisterEvent( "UNIT_CLASSIFICATION_CHANGED", me.ClassificationUpdate );

		local RaidIcon = Portrait:CreateTexture( nil, "OVERLAY" );
		Size = Style[ "initial-height" ] / 2;
		self.RaidIcon = RaidIcon;
		RaidIcon:SetPoint( "CENTER" );
		RaidIcon:SetWidth( Size );
		RaidIcon:SetHeight( Size );

		if ( IsAddOnLoaded( "oUF_CombatFeedback" ) ) then
			local FeedbackText = Portrait:CreateFontString( nil, "OVERLAY", "NumberFontNormalLarge" );
			self.CombatFeedbackText = FeedbackText;
			FeedbackText:SetPoint( "CENTER" );
			FeedbackText.ignoreEnergize = true;
			FeedbackText.ignoreOther = true;
		end

		Bars:SetPoint( "TOP" );
		Bars:SetPoint( "BOTTOM" );
		Bars:SetPoint( Side, Portrait, Opposite );
		Bars:SetPoint( Opposite );
	else
		Bars:SetAllPoints();
	end


	-- Health bar
	local Health = me.CreateBarReverse( self );
	self.Health = Health;
	Health:SetPoint( "TOPLEFT", Bars );
	Health:SetPoint( "RIGHT", Bars );
	Health:SetHeight( Style[ "initial-height" ] * 0.65 );
	Health.SetStatusBarColor = me.SetStatusBarColor;
	me.CreateBarBackground( Health, 0.07 );
	Health.frequentUpdates = true;
	Health.colorDisconnected = true;
	Health.colorTapping = true;
	Health.colorSmooth = true;
	Health.ValueLength = Style.HealthLength;

	local HealthValue = Health:CreateFontString( nil, "OVERLAY", Style.BarValueFont );
	Health.Value = HealthValue;
	HealthValue:SetPoint( "TOPRIGHT", -2, 0 );
	HealthValue:SetPoint( "BOTTOM" );
	HealthValue:SetJustifyV( "MIDDLE" );
	HealthValue:SetAlpha( 0.75 );

	self.PostUpdateHealth = me.PostUpdateHealth;


	-- Power bar
	local Power = me.CreateBar( self );
	self.Power = Power;
	Power:SetPoint( "TOPLEFT", Health, "BOTTOMLEFT" );
	Power:SetPoint( "RIGHT", Bars );
	Power:SetHeight( Style[ "initial-height" ] * 0.25 );
	Power.SetStatusBarColor = me.SetStatusBarColor;
	me.CreateBarBackground( Power, 0.14 );
	Power.frequentUpdates = true;
	Power.colorPower = true;
	Power.ValueLength = Style.PowerLength;

	local PowerValue = Power:CreateFontString( nil, "OVERLAY", Style.BarValueFont );
	Power.Value = PowerValue;
	PowerValue:SetPoint( "TOPRIGHT", -2, 0 );
	PowerValue:SetPoint( "BOTTOM" );
	PowerValue:SetJustifyV( "MIDDLE" );
	PowerValue:SetAlpha( 0.75 );

	self.PostUpdatePower = me.PostUpdatePower;


	-- Casting/rep/exp bar
	local Progress = me.CreateBar( self );
	Progress:SetStatusBarTexture( me.BarTexture );
	Progress:SetPoint( "BOTTOMLEFT", Bars );
	Progress:SetPoint( "TOPRIGHT", Power, "BOTTOMRIGHT" );
	Progress:SetAlpha( 0.8 );
	me.CreateBarBackground( Progress, 0.07 ):SetParent( Bars ); -- Show background while hidden
	if ( UnitID == "player" ) then
		if ( IsAddOnLoaded( "oUF_Experience" ) and UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL ) then
			self.Experience = Progress;
			Progress:SetStatusBarColor( unpack( Colors.experience ) );
			Progress.PostUpdate = me.ExperiencePostUpdate;
			local Rest = Progress:CreateTexture( nil, "ARTWORK" );
			Progress.RestTexture = Rest;
			Rest:SetTexture( me.BarTexture );
			Rest:SetVertexColor( unpack( Colors.experience_rested ) );
			Rest:SetPoint( "TOP" );
			Rest:SetPoint( "BOTTOM" );
			Rest:Hide();
		elseif ( IsAddOnLoaded( "oUF_Reputation" ) ) then
			self.Reputation = Progress;
			Progress.PostUpdate = me.ReputationPostUpdate;
		end
	else -- Castbar
		self.Castbar = Progress;
		Progress:SetStatusBarColor( unpack( Colors.cast ) );

		local Time;
		if ( Style.CastTime ) then
			Time = Progress:CreateFontString( nil, "OVERLAY", me.FontMicro );
			Progress.Time = Time;
			Time:SetPoint( "BOTTOMRIGHT", -6, 0 );
		end

		local Text = Progress:CreateFontString( nil, "OVERLAY", me.FontMicro );
		Progress.Text = Text;
		Text:SetPoint( "BOTTOMLEFT", 2, 0 );
		if ( Time ) then
			Text:SetPoint( "RIGHT", Time, "LEFT" );
		else
			Text:SetPoint( "RIGHT", -2, 0 );
		end
		Text:SetJustifyH( "LEFT" );
	end


	-- Name
	local Name = Health:CreateFontString( nil, "OVERLAY", Style.NameFont );
	self.Name = Name;
	Name:SetPoint( "LEFT", 2, 0 );
	Name:SetPoint( "RIGHT", HealthValue, "LEFT" );
	Name:SetJustifyH( "LEFT" );
	self:Tag( Name, "[_UnitsName]" );


	-- Info string
	local Info = Health:CreateFontString( nil, "OVERLAY", me.FontTiny );
	self.Info = Info;
	Info:SetPoint( "BOTTOM", 0, 2 );
	Info:SetPoint( "TOPLEFT", Name, "BOTTOMLEFT" );
	Info:SetJustifyV( "BOTTOM" );
	Info:SetAlpha( 0.8 );
	self:Tag( Info, "[_UnitsClassification]" );


	-- Buffs
	local Buffs = CreateFrame( "Frame", nil, self );
	self.Buffs = Buffs;
	Buffs:SetPoint( "TOPLEFT", Backdrop, "BOTTOMLEFT" );
	Buffs:SetPoint( "RIGHT", Backdrop );
	Buffs:SetHeight( 1 );
	Buffs.initialAnchor = "TOPLEFT";
	Buffs[ "growth-y" ] = "DOWN";
	Buffs.size = Style.AuraSize;

	-- Debuffs
	local Debuffs = CreateFrame( "Frame", nil, self );
	self.Debuffs = Debuffs;
	Debuffs:SetPoint( "TOPLEFT", Buffs, "BOTTOMLEFT" );
	Debuffs:SetPoint( "RIGHT", Backdrop );
	Debuffs:SetHeight( 1 );
	Debuffs.initialAnchor = "TOPLEFT";
	Debuffs[ "growth-y" ] = "DOWN";
	Debuffs.showDebuffType = true;
	Debuffs.size = Style.AuraSize;

	self.PostCreateAuraIcon = me[ UnitID == "player" and "PostCreateAuraIconPlayer" or "PostCreateAuraIcon" ];
	self.PostUpdateAura = me.PostUpdateAura;

	-- Debuff highlight
	if ( IsAddOnLoaded( "oUF_DebuffHighlight" ) ) then
		self.DebuffHighlight = me.CreateDebuffHighlight( self, Backdrop );
		self.DebuffHighlightAlpha = 1;
		self.DebuffHighlightFilter = Style.DebuffHighlightFilter;
	end


	-- Icons
	local function IconResize ( self )
		self:SetWidth( self:IsShown() and 16 or 1 );
	end
	local LastIcon;
	local function AddIcon ( Key )
		local Icon = Health:CreateTexture( nil, "ARTWORK" );
		hooksecurefunc( Icon, "Show", IconResize );
		hooksecurefunc( Icon, "Hide", IconResize );
		self[ Key ] = Icon;
		Icon:Hide();
		Icon:SetHeight( 16 );
		if ( LastIcon ) then
			Icon:SetPoint( "LEFT", LastIcon, "RIGHT" );
		else
			Icon:SetPoint( "TOPLEFT", 1, -1 );
		end
		LastIcon = Icon;
	end
	AddIcon( "Leader" );
	AddIcon( "MasterLooter" );
	if ( UnitID == "player" ) then
		AddIcon( "Resting" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	CreateFont( "_UnitsOUFFontNormal" ):SetFont( "Fonts\\ARIALN.TTF", 10, "OUTLINE" );
	CreateFont( "_UnitsOUFFontTiny" ):SetFont( "Fonts\\ARIALN.TTF", 8, "OUTLINE" );
	CreateFont( "_UnitsOUFFontMicro" ):SetFont( "Fonts\\ARIALN.TTF", 6 );


	-- Hide default buff frame
	BuffFrame:Hide();
	TemporaryEnchantFrame:Hide();
	BuffFrame:UnregisterAllEvents();


	-- Custom tags
	oUF.Tags[ "[_UnitsClassification]" ] = me.TagClassification;
	oUF.TagEvents[ "[_UnitsClassification]" ] = "UNIT_LEVEL PLAYER_LEVEL_UP RAID_ROSTER_UPDATE "..( oUF.TagEvents[ "[shortclassification]" ] or "" );

	oUF.Tags[ "[_UnitsName]" ] = me.TagName;
	oUF.TagEvents[ "[_UnitsName]" ] = "UNIT_NAME_UPDATE UNIT_FACTION";




	oUF:RegisterStyle( "_Units", setmetatable( {
		[ "initial-width" ] = 160;
		[ "initial-height" ] = 50;
	}, me.StyleMeta ) );
	oUF:RegisterStyle( "_UnitsSelf", setmetatable( {
		[ "initial-width" ] = 130;
		[ "initial-height" ] = 50;
		PortraitSide = false;
		HealthLength = "Small";
		PowerLength  = "Full";
		CastTime = false;
		DebuffHighlightFilter = false; -- Show all
	}, me.StyleMeta ) );
	oUF:RegisterStyle( "_UnitsSmall", setmetatable( {
		[ "initial-width" ] = 130;
		[ "initial-height" ] = 50;
		PortraitSide = "LEFT";
		HealthLength = "Tiny";
		PowerLength  = "Small";
		NameFont = me.FontTiny;
		CastTime = false;
		AuraSize = 10;
	}, me.StyleMeta ) );


	-- Top row
	oUF:SetActiveStyle( "_UnitsSelf" );
	me.Player = oUF:Spawn( "player", "_UnitsPlayer" );
	me.Player:SetPoint( "LEFT" );
	me.Player:SetPoint( "TOP", MinimapCluster );

	oUF:SetActiveStyle( "_Units" );
	me.Target = oUF:Spawn( "target", "_UnitsTarget" );
	me.Target:SetPoint( "TOPLEFT", me.Player, "TOPRIGHT", 28, 0 );

	oUF:SetActiveStyle( "_UnitsSmall" );
	me.TargetTarget = oUF:Spawn( "targettarget", "_UnitsTargetTarget" );
	me.TargetTarget:SetPoint( "TOPLEFT", me.Target, "TOPRIGHT", 2 * _Clean.Backdrop.Padding, 0 );


	-- Bottom row
	oUF:SetActiveStyle( "_UnitsSmall" );
	me.Pet = oUF:Spawn( "pet", "_UnitsPet" );
	me.Pet:SetPoint( "TOPLEFT", me.Player, "BOTTOMLEFT", 0, -56 );

	oUF:SetActiveStyle( "_Units" );
	me.Focus = oUF:Spawn( "focus", "_UnitsFocus" );
	me.Focus:SetPoint( "LEFT", me.Target );
	me.Focus:SetPoint( "TOP", me.Pet );

	oUF:SetActiveStyle( "_UnitsSmall" );
	me.FocusTarget = oUF:Spawn( "focustarget", "_UnitsFocusTarget" );
	me.FocusTarget:SetPoint( "LEFT", me.TargetTarget );
	me.FocusTarget:SetPoint( "TOP", me.Pet );
end

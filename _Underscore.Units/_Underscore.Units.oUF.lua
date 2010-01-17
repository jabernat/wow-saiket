--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * _Underscore.Units.oUF.lua - Adds custom skinned unit frames using oUF.     *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local L = _UnderscoreLocalization.Units;
local _Underscore = _Underscore;
local me = {};
_Underscore.Units.oUF = me;

me.FontNormal = CreateFont( "_UnderscoreUnitsOUFFontNormal" );
me.FontTiny = CreateFont( "_UnderscoreUnitsOUFFontTiny" );
me.FontMicro = CreateFont( "_UnderscoreUnitsOUFFontMicro" );

me.StyleMeta = {};

local Colors = _Underscore.Colors;
setmetatable( Colors, { __index = oUF.colors; } );
setmetatable( Colors.power, { __index = oUF.colors.power; } );
Colors.class = oUF.colors.class;




--[[****************************************************************************
  * Function: _Underscore.Units.oUF:SetStatusBarTextColor                      *
  * Description: Colors bar text to match bars.                                *
  ****************************************************************************]]
function me:SetStatusBarTextColor ( R, G, B, A )
	self.Text:SetTextColor( R, G, B, A );
end
--[[****************************************************************************
  * Function: _Underscore.Units.oUF.BarFormatText                              *
  * Description: Formats bar text depending on the bar's style.                *
  ****************************************************************************]]
function me:BarFormatText ( Value, ValueMax )
	self.Text:SetFormattedText( L.NumberFormats[ self.TextLength ]( Value, ValueMax ) );
end




--[[****************************************************************************
  * Function: _Underscore.Units.oUF:PostUpdateHealth                           *
  ****************************************************************************]]
do
	local function ColorDead ( Bar, Label )
		Bar:SetStatusBarColor( 0.2, 0.2, 0.2 );
		if ( Bar.Text ) then
			Bar.Text:SetText( L[ Label ] );
			Bar.Text:SetTextColor( unpack( Colors.disconnected ) );
		end
	end
	local UnitIsGhost = UnitIsGhost;
	local UnitIsDead = UnitIsDead;
	local UnitIsConnected = UnitIsConnected;
	function me:PostUpdateHealth ( Event, UnitID, Bar, Health, HealthMax )
		if ( UnitIsGhost( UnitID ) ) then
			Bar:SetValue( 0 );
			ColorDead( Bar, "GHOST" );
		elseif ( UnitIsDead( UnitID ) and not self.IsFeignDeath ) then
			Bar:SetValue( 0 );
			ColorDead( Bar, "DEAD" );
		elseif ( not UnitIsConnected( UnitID ) ) then
			ColorDead( Bar, "OFFLINE" );
		elseif ( Bar.Text ) then
			me.BarFormatText( Bar, Health, HealthMax );
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.Units.oUF:PostUpdatePower                            *
  ****************************************************************************]]
function me:PostUpdatePower ( Event, UnitID, Bar, Power, PowerMax )
	local Dead = UnitIsDeadOrGhost( UnitID );
	if ( Dead ) then
		Bar:SetValue( 0 );
	end
	if ( Bar.Text ) then
		if ( Dead or select( 2, UnitPowerType( UnitID ) ) ~= "MANA" ) then
			Bar.Text:SetText();
		else
			me.BarFormatText( Bar, Power, PowerMax );
		end
	end
end


--[[****************************************************************************
  * Function: _Underscore.Units.oUF:PostCreateAuraIcon                         *
  ****************************************************************************]]
function me:PostCreateAuraIcon ( Frame )
	_Underscore.SkinButtonIcon( Frame.icon );
	Frame.UpdateTooltip = me.AuraUpdateTooltip;
	Frame.cd:SetReverse( true );
	Frame:SetFrameLevel( self:GetFrameLevel() - 1 ); -- Don't allow auras to overlap other units

	Frame.count:ClearAllPoints();
	Frame.count:SetPoint( "BOTTOMLEFT" );
end
--[[****************************************************************************
  * Function: _Underscore.Units.oUF:PostUpdateAura                             *
  * Description: Resizes the buffs frame so debuffs anchor correctly.          *
  ****************************************************************************]]
do
	local FeignDeath = GetSpellInfo( 28728 );
	function me:PostUpdateAura ( Event, UnitID )
		local Frame = self.Buffs;
		local BuffsPerRow = max( 1, floor( Frame:GetWidth() / Frame.size ) );
		Frame:SetHeight( max( 1, Frame.size * ceil( Frame.visibleBuffs / BuffsPerRow ) ) );

		-- Check for feign death
		local IsFeignDeath = UnitAura( UnitID, FeignDeath ) and true or false;
		if ( self.IsFeignDeath ~= IsFeignDeath ) then
			self.IsFeignDeath = IsFeignDeath;
			self:PostUpdateHealth( Event, UnitID, self.Health, UnitHealth( UnitID ), UnitHealthMax( UnitID ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.Units.oUF:AuraUpdateTooltip                          *
  * Description: Updates aura tooltips while they're moused over.              *
  ****************************************************************************]]
function me:AuraUpdateTooltip ()
	GameTooltip:SetUnitAura( self.frame.unit, self:GetID(), self.filter );
end


--[[****************************************************************************
  * Function: _Underscore.Units.oUF:ReputationPostUpdate                       *
  * Description: Recolors the reputation bar on update.                        *
  ****************************************************************************]]
function me:ReputationPostUpdate ( _, _, Bar, _, _, _, _, StandingID )
	Bar:SetStatusBarColor( unpack( Colors.reaction[ StandingID ] ) );
end

--[[****************************************************************************
  * Function: _Underscore.Units.oUF:ExperiencePostUpdate                       *
  * Description: Adjusts the rested experience bar segment.                    *
  ****************************************************************************]]
function me:ExperiencePostUpdate ( _, UnitID, Bar, Value, ValueMax )
	if ( UnitID == "player" ) then
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
  * Function: _Underscore.Units.oUF:ClassificationUpdate                       *
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
  * Function: _Underscore.Units.oUF.TagClassification                          *
  * Description: Tag that displays level/classification or group # in raid.    *
  ****************************************************************************]]
do
	local Plus = { worldboss = true; elite = true; rareelite = true; };
	function me.TagClassification ( UnitID )
		if ( UnitID == "player" and GetNumRaidMembers() > 0 ) then
			return L.OUF_GROUP_FORMAT:format( select( 3, GetRaidRosterInfo( GetNumRaidMembers() ) ) );
		else
			local Level = UnitLevel( UnitID );
			if ( Plus[ UnitClassification( UnitID ) ] or Level ~= MAX_PLAYER_LEVEL or UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL ) then
				local Color = Level < 0 and QuestDifficultyColors[ "impossible" ] or GetQuestDifficultyColor( Level );
				return L.OUF_CLASSIFICATION_FORMAT:format( Color.r * 255, Color.g * 255, Color.b * 255,
					oUF.Tags[ "[smartlevel]" ]( UnitID ) );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.Units.oUF.TagName                                    *
  * Description: Colored name with server name if different from player's.     *
  ****************************************************************************]]
do
	local Name, Server, Color, R, G, B;
	function me.TagName ( UnitID, Override )
		Name, Server = UnitName( Override or UnitID );

		if ( UnitIsPlayer( UnitID ) ) then
			Color = Colors.class[ select( 2, UnitClass( UnitID ) ) ];
		elseif ( UnitPlayerControlled( UnitID ) or UnitPlayerOrPetInRaid( UnitID ) ) then -- Pet
			Color = Colors.Pet;
		else -- NPC
			Color = Colors.reaction[ UnitReaction( UnitID, "player" ) or 5 ];
		end

		R, G, B = unpack( Color );
		return L.OUF_NAME_FORMAT:format( R * 255, G * 255, B * 255,
			( Server and Server ~= "" ) and L.OUF_SERVER_DELIMITER:join( Name, Server ) or Name );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.FontNormal:SetFont( [[Fonts\ARIALN.TTF]], 10, "OUTLINE" );
	me.FontTiny:SetFont( [[Fonts\ARIALN.TTF]], 8, "OUTLINE" );
	me.FontMicro:SetFont( [[Fonts\ARIALN.TTF]], 6 );


	-- Hide default buff frame
	BuffFrame:Hide();
	TemporaryEnchantFrame:Hide();
	BuffFrame:UnregisterAllEvents();


	-- Custom tags
	oUF.Tags[ "[_UnderscoreUnitsClassification]" ] = me.TagClassification;
	oUF.TagEvents[ "[_UnderscoreUnitsClassification]" ] = "UNIT_LEVEL PLAYER_LEVEL_UP RAID_ROSTER_UPDATE "..( oUF.TagEvents[ "[shortclassification]" ] or "" );

	oUF.Tags[ "[_UnderscoreUnitsName]" ] = me.TagName;
	oUF.TagEvents[ "[_UnderscoreUnitsName]" ] = "UNIT_NAME_UPDATE UNIT_FACTION";




	local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, _Underscore.MediaBar );
	local function CreateBarBackground ( self, Brightness )
		local Background = self:CreateTexture( nil, "BACKGROUND" );
		Background:SetAllPoints( self );
		Background:SetVertexColor( Brightness, Brightness, Brightness );
		Background:SetTexture( BarTexture );
		return Background;
	end
	local function CreateBar ( self, TextFont )
		local Bar = CreateFrame( "StatusBar", nil, self );
		Bar:SetStatusBarTexture( BarTexture );
		if ( TextFont ) then
			Bar.Text = Bar:CreateFontString( nil, "OVERLAY", TextFont:GetName() );
			Bar.Text:SetJustifyV( "MIDDLE" );
			hooksecurefunc( Bar, "SetStatusBarColor", me.SetStatusBarTextColor );
		end
		return Bar;
	end
	local CreateBarReverse; -- Creates a status bar that fills in reverse.
	do
		local function SetValue ( self, Value, ValueMax, Width )
			self:GetStatusBarTexture():SetPoint( "LEFT", self, "RIGHT",
				( ( Value or self:GetValue() ) / ( MaxValue or select( 2, self:GetMinMaxValues() ) ) - 1 ) * ( Width or self:GetWidth() ), 0 );
		end
		local function OnSizeChanged ( self, Width )
			SetValue( self, nil, nil, Width );
		end
		local function OnValueChanged ( self, Value )
			SetValue( self, Value );
		end
		local function OnMinMaxChanged ( self, ValueMin, ValueMax )
			SetValue( self, nil, ValueMax );
		end
		function CreateBarReverse ( self, ... )
			local Bar = CreateBar( self, ... );
			local Texture = Bar:GetStatusBarTexture();
			Texture:ClearAllPoints();
			Texture:SetPoint( "TOPRIGHT" );
			Texture:SetPoint( "BOTTOM" );
			Texture:SetTexCoordModifiesRect( false ); -- Keep the usual texcoord animation from showing (Texture must be horizontally uniform)

			Bar:SetScript( "OnSizeChanged", OnSizeChanged );
			Bar:SetScript( "OnValueChanged", OnValueChanged );
			Bar:SetScript( "OnMinMaxChanged", OnMinMaxChanged );

			return Bar;
		end
	end


	local CreateDebuffHighlight; -- Creates a border frame that behaves like a texture for the oUF_DebuffHighlight element.
	if ( IsAddOnLoaded( "oUF_DebuffHighlight" ) ) then
		local function SetVertexColor ( self, ... )
			for Index = 1, #self do
				self[ Index ]:SetVertexColor( ... );
			end
		end
		local function GetVertexColor ( self )
			return self[ 1 ]:GetVertexColor();
		end
		local function CreateTexture( self, Point1, Point1Frame, Point2, Point2Frame, Point2Rel )
			local Texture = self:CreateTexture( nil, "OVERLAY" );
			tinsert( self, Texture );
			Texture:SetTexture( [[Interface\Buttons\WHITE8X8]] );
			Texture:SetPoint( Point1, Point1Frame );
			Texture:SetPoint( Point2, Point2Frame, Point2Rel );
		end
		function CreateDebuffHighlight ( self, Backdrop )
			local Frame = CreateFrame( "Frame", nil, self.Health );
			-- Four separate outline textures so faded frames blend correctly
			CreateTexture( Frame, "TOPLEFT", Backdrop, "BOTTOMRIGHT", self, "TOPRIGHT" );
			CreateTexture( Frame, "TOPRIGHT", Backdrop, "BOTTOMLEFT", self, "BOTTOMRIGHT" );
			CreateTexture( Frame, "BOTTOMRIGHT", Backdrop, "TOPLEFT", self, "BOTTOMLEFT" );
			CreateTexture( Frame, "BOTTOMLEFT", Backdrop, "TOPRIGHT", self, "TOPLEFT" );

			Frame.GetVertexColor = GetVertexColor;
			Frame.SetVertexColor = SetVertexColor;
			Frame:SetVertexColor( 0, 0, 0, 0 ); -- Hide when not debuffed
			return Frame;
		end
	end


	local function Initialize ( Style, self, UnitID ) -- Sets up a unit frame based on its style table.
		-- Enable the right-click menu
		SecureUnitButton_OnLoad( self, UnitID, _Underscore.Units.ShowGenericMenu );
		self:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );

		self.colors = Colors;
		self.disallowVehicleSwap = true;

		self[ IsAddOnLoaded( "oUF_SpellRange" ) and "SpellRange" or "Range" ] = true;
		self.inRangeAlpha = 1.0;
		self.outsideRangeAlpha = 0.4;

		self:SetScript( "OnEnter", UnitFrame_OnEnter );
		self:SetScript( "OnLeave", UnitFrame_OnLeave );

		local Backdrop = _Underscore.Backdrop.Create( self );
		self:SetHighlightTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]] );
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
			Classification:SetSize( Size, Size );
			Classification:SetTexture( [[Interface\AchievementFrame\UI-Achievement-IconFrame]] );
			Classification:SetTexCoord( 0, 0.5625, 0, 0.5625 );
			Classification:SetAlpha( 0.8 );
			tinsert( self.__elements, me.ClassificationUpdate );
			self:RegisterEvent( "UNIT_CLASSIFICATION_CHANGED", me.ClassificationUpdate );

			local RaidIcon = Portrait:CreateTexture( nil, "OVERLAY" );
			Size = Style[ "initial-height" ] / 2;
			self.RaidIcon = RaidIcon;
			RaidIcon:SetPoint( "CENTER" );
			RaidIcon:SetSize( Size, Size );

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
		local Health = CreateBarReverse( self, Style.HealthText and Style.BarTextFont );
		self.Health = Health;
		Health:SetPoint( "TOPLEFT", Bars );
		Health:SetPoint( "RIGHT", Bars );
		Health:SetHeight( Style[ "initial-height" ] * ( 1 - Style.PowerHeight - Style.ProgressHeight ) );
		CreateBarBackground( Health, 0.07 );
		Health.frequentUpdates = true;
		Health.colorDisconnected = true;
		Health.colorTapping = true;
		Health.colorSmooth = true;
		Health.smoothGradient = Colors.HealthSmooth;

		if ( Health.Text ) then
			Health.Text:SetPoint( "TOPRIGHT", -2, 0 );
			Health.Text:SetPoint( "BOTTOM" );
			Health.Text:SetAlpha( 0.75 );
			Health.TextLength = Style.HealthText;
		end
		if ( IsAddOnLoaded( "oUF_Smooth" ) ) then
			Health.Smooth = true;
		end
		if ( IsAddOnLoaded( "oUF_HealComm4" ) ) then
			local HealCommBar = CreateFrame( "StatusBar", nil, Health );
			self.HealCommBar = HealCommBar;
			self.allowHealCommOverflow = true;
			HealCommBar:SetStatusBarTexture( BarTexture );
			local R, G, B = unpack( Colors.reaction[ 8 ] );
			HealCommBar:SetStatusBarColor( R, G, B, 0.5 );
		end

		self.PostUpdateHealth = me.PostUpdateHealth;


		-- Power bar
		local Power = CreateBar( self, Style.PowerText and Style.BarTextFont );
		self.Power = Power;
		Power:SetPoint( "TOPLEFT", Health, "BOTTOMLEFT" );
		Power:SetPoint( "RIGHT", Bars );
		Power:SetHeight( Style[ "initial-height" ] * Style.PowerHeight );
		CreateBarBackground( Power, 0.14 );
		Power.frequentUpdates = true;
		Power.colorPower = true;

		if ( Power.Text ) then
			Power.Text:SetPoint( "TOPRIGHT", -2, 0 );
			Power.Text:SetPoint( "BOTTOM" );
			Power.Text:SetAlpha( 0.75 );
			Power.TextLength = Style.PowerText;
		end

		self.PostUpdatePower = me.PostUpdatePower;


		-- Casting/rep/exp bar
		local Progress = CreateBar( self );
		Progress:SetStatusBarTexture( BarTexture );
		Progress:SetPoint( "BOTTOMLEFT", Bars );
		Progress:SetPoint( "TOPRIGHT", Power, "BOTTOMRIGHT" );
		Progress:SetAlpha( 0.8 );
		Progress:Hide();
		CreateBarBackground( Progress, 0.07 ):SetParent( Bars ); -- Show background while hidden
		if ( UnitID == "player" ) then
			if ( IsAddOnLoaded( "oUF_Experience" ) and UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL and not IsXPUserDisabled() ) then
				self.Experience = Progress;
				Progress:SetStatusBarColor( unpack( Colors.Experience ) );
				Progress.PostUpdate = me.ExperiencePostUpdate;
				Progress:Show();
				local Rest = Progress:CreateTexture( nil, "ARTWORK" );
				Progress.RestTexture = Rest;
				Rest:SetTexture( BarTexture );
				Rest:SetVertexColor( unpack( Colors.ExperienceRested ) );
				Rest:SetPoint( "TOP" );
				Rest:SetPoint( "BOTTOM" );
				Rest:Hide();
			elseif ( IsAddOnLoaded( "oUF_Reputation" ) ) then
				self.Reputation = Progress;
				Progress.PostUpdate = me.ReputationPostUpdate;
			end
		elseif ( UnitID == "pet" ) then
			if ( IsAddOnLoaded( "oUF_Experience" ) and select( 2, UnitClass( "player" ) ) == "HUNTER" ) then
				self.Experience = Progress;
				Progress:SetStatusBarColor( unpack( Colors.Experience ) );
				Progress:Show();
			end
		else -- Castbar
			self.Castbar = Progress;
			Progress:SetStatusBarColor( unpack( Colors.Cast ) );

			local Time;
			if ( Style.CastTime ) then
				Time = Progress:CreateFontString( nil, "OVERLAY", me.FontMicro:GetName() );
				Progress.Time = Time;
				Time:SetPoint( "BOTTOMRIGHT", -6, 0 );
			end

			local Text = Progress:CreateFontString( nil, "OVERLAY", me.FontMicro:GetName() );
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
		local Name = Health:CreateFontString( nil, "OVERLAY", Style.NameFont:GetName() );
		self.Name = Name;
		Name:SetPoint( "LEFT", 2, 0 );
		if ( Health.Text ) then
			Name:SetPoint( "RIGHT", Health.Text, "LEFT" );
		else
			Name:SetPoint( "RIGHT", -2, 0 );
		end
		Name:SetJustifyH( "LEFT" );
		self:Tag( Name, "[_UnderscoreUnitsName]" );


		-- Info string
		local Info = Health:CreateFontString( nil, "OVERLAY", me.FontTiny:GetName() );
		self.Info = Info;
		Info:SetPoint( "BOTTOM", 0, 2 );
		Info:SetPoint( "TOPLEFT", Name, "BOTTOMLEFT" );
		Info:SetJustifyV( "BOTTOM" );
		Info:SetAlpha( 0.8 );
		self:Tag( Info, "[_UnderscoreUnitsClassification]" );


		if ( Style.Auras ) then
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

			self.PostCreateAuraIcon = me.PostCreateAuraIcon;
			self.PostUpdateAura = me.PostUpdateAura;
		end

		-- Debuff highlight
		if ( CreateDebuffHighlight and Style.DebuffHighlight ) then
			self.DebuffHighlight = CreateDebuffHighlight( self, Backdrop );
			self.DebuffHighlightAlpha = 1;
			self.DebuffHighlightFilter = Style.DebuffHighlight ~= "ALL";
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




	-- Defaults
	me.StyleMeta.__call = Initialize;
	me.StyleMeta.__index = {
		[ "initial-width" ] = 130;
		[ "initial-height" ] = 50;

		PortraitSide = "RIGHT"; -- "LEFT"/"RIGHT"/false
		HealthText = "Small"; -- "Full"/"Small"/"Tiny"
		PowerText  = "Small"; -- Same as Health
		NameFont = me.FontNormal;
		BarTextFont = me.FontTiny;
		CastTime = true;
		Auras = true;
		AuraSize = 15;
		DebuffHighlight = true;

		PowerHeight = 0.25;
		ProgressHeight = 0.1;
	};

	oUF:RegisterStyle( "_UnderscoreUnits", setmetatable( {
		[ "initial-width" ] = 160;
	}, me.StyleMeta ) );
	oUF:RegisterStyle( "_UnderscoreUnitsSelf", setmetatable( {
		PortraitSide = false;
		HealthText = "Full";
		PowerText  = "Full";
		CastTime = false;
		DebuffHighlight = "ALL";
	}, me.StyleMeta ) );
	oUF:RegisterStyle( "_UnderscoreUnitsSmall", setmetatable( {
		PortraitSide = "LEFT";
		HealthText = "Tiny";
		NameFont = me.FontTiny;
		CastTime = false;
		AuraSize = 10;
	}, me.StyleMeta ) );


	-- Top row
	oUF:SetActiveStyle( "_UnderscoreUnitsSelf" );
	me.Player = oUF:Spawn( "player", "_UnderscoreUnitsPlayer" );
	me.Player:SetPoint( "TOPLEFT", _Underscore.TopMargin, "BOTTOMLEFT" );

	oUF:SetActiveStyle( "_UnderscoreUnits" );
	me.Target = oUF:Spawn( "target", "_UnderscoreUnitsTarget" );
	me.Target:SetPoint( "TOPLEFT", me.Player, "TOPRIGHT", 28, 0 );

	oUF:SetActiveStyle( "_UnderscoreUnitsSmall" );
	me.TargetTarget = oUF:Spawn( "targettarget", "_UnderscoreUnitsTargetTarget" );
	me.TargetTarget:SetPoint( "TOPLEFT", me.Target, "TOPRIGHT", 2 * _Underscore.Backdrop.Padding, 0 );


	-- Bottom row
	oUF:SetActiveStyle( "_UnderscoreUnitsSmall" );
	me.Pet = oUF:Spawn( "pet", "_UnderscoreUnitsPet" );
	me.Pet:SetPoint( "TOPLEFT", me.Player, "BOTTOMLEFT", 0, -56 );

	oUF:SetActiveStyle( "_UnderscoreUnits" );
	me.Focus = oUF:Spawn( "focus", "_UnderscoreUnitsFocus" );
	me.Focus:SetPoint( "LEFT", me.Target );
	me.Focus:SetPoint( "TOP", me.Pet );

	oUF:SetActiveStyle( "_UnderscoreUnitsSmall" );
	me.FocusTarget = oUF:Spawn( "focustarget", "_UnderscoreUnitsFocusTarget" );
	me.FocusTarget:SetPoint( "LEFT", me.TargetTarget );
	me.FocusTarget:SetPoint( "TOP", me.Pet );


	if ( not _Underscore.IsAddOnLoadable( "_Underscore.Units.Arena" ) ) then
		-- Garbage collect initialization code
		me.StyleMeta.__call = nil;
	end
end

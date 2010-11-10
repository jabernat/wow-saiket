--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * _Underscore.Units.oUF.lua - Adds custom skinned unit frames using oUF.     *
  ****************************************************************************]]


local Units = select( 2, ... );
local L = Units.L;
local me = {};
Units.oUF = me;

me.FontNormal = CreateFont( "_UnderscoreUnitsOUFFontNormal" );
me.FontTiny = CreateFont( "_UnderscoreUnitsOUFFontTiny" );
me.FontMicro = CreateFont( "_UnderscoreUnitsOUFFontMicro" );

me.StyleMeta = {};

local Colors = _Underscore.Colors;
setmetatable( Colors, { __index = oUF.colors; } );
setmetatable( Colors.power, { __index = oUF.colors.power; } );
Colors.class = oUF.colors.class;

--- Common range alpha properties shared by Range/SpellRange elements.
me.Range = {
	insideAlpha = 1.0;
	outsideAlpha = 0.4;
};




--- Raises and shows all auras when moused over.
function me:OnEnter ()
	if ( self.AuraMouseover ) then
		self.AuraMouseover:Show(); -- Show unfiltered auras
	end
	UnitFrame_OnEnter( self );
end




do
	--- Colors and sets text for a bar representing a dead player.
	-- @param Label  New bar text.
	local function SetDead ( self, Label )
		self:SetStatusBarColor( 0.2, 0.2, 0.2 );
		if ( self.Text ) then
			self.Text:SetText( Label );
			self.Text:SetTextColor( unpack( Colors.disconnected ) );
		end
	end
	local FeignDeath = GetSpellInfo( 28728 );
	--- Sets health bar text and color when health changes.
	function me:HealthPostUpdate ( UnitID, Health, HealthMax )
		if ( UnitIsGhost( UnitID ) ) then
			self:SetValue( 0 );
			SetDead( self, L.GHOST );
		elseif ( UnitIsDead( UnitID ) and not UnitAura( UnitID, FeignDeath ) ) then
			self:SetValue( 0 );
			SetDead( self, L.DEAD );
		elseif ( not UnitIsConnected( UnitID ) ) then
			SetDead( self, L.OFFLINE );
		elseif ( self.Text ) then
			self.Text:SetFormattedText( L.NumberFormats[ self.TextLength ]( Health, HealthMax ) );
		end
	end
end
--- Sets power bar text and color when power changes.
function me:PowerPostUpdate ( UnitID, Power, PowerMax )
	local IsDead = UnitIsDeadOrGhost( UnitID );
	if ( IsDead ) then
		self:SetValue( 0 );
	end
	if ( self.Text ) then
		local _, PowerType = UnitPowerType( UnitID );
		if ( IsDead or PowerType ~= "MANA" ) then
			self.Text:SetText();
		else
			self.Text:SetFormattedText( L.NumberFormats[ self.TextLength ]( Power, PowerMax ) );
		end
	end
end


--- Replaces the golden "?" model used for unknown units with a gray "?".
function me:PortraitPostUpdate ()
	local Model = self:GetModel();
	if ( type( Model ) == "string" and Model:lower() == [[interface\buttons\talktomequestionmark.m2]] ) then
		self:SetModel( [[Interface\Buttons\TalkToMeQuestion_Grey.mdx]] );
	end
end


do
	--- Starts or stops showing all auras for an Aura icon frame.
	local function AuraShowAll ( Icons, ShowAll )
		if ( Icons ) then
			Icons.ShowAll = ShowAll;
			Icons:SetFrameStrata( ShowAll and Icons:GetParent():GetFrameStrata() or "LOW" );
		end
	end
	--- Keeps all auras visible while mousing over the unit and its auras.
	function me:AuraMouseoverOnUpdate ()
		if ( not self:IsMouseOver() ) then
			self:Hide();
		end
	end
	--- Shows all auras when mousing over buff area.
	function me:AuraMouseoverOnShow ()
		local Frame = self:GetParent();
		AuraShowAll( Frame.Buffs, true );
		AuraShowAll( Frame.Debuffs, true );
		Frame.Buffs:ForceUpdate(); -- Refilter buffs and debuffs
	end
	--- Refilters auras once mouse leaves buff area.
	function me:AuraMouseoverOnHide ()
		local Frame = self:GetParent();
		AuraShowAll( Frame.Buffs, nil );
		AuraShowAll( Frame.Debuffs, nil );
		Frame.Buffs:ForceUpdate();
	end
end

--- Adjusts buff/debuff icons when they're created.
function me:AuraPostCreateIcon ( Frame )
	_Underscore.SkinButtonIcon( Frame.icon );
	Frame.cd:SetReverse( true );
	Frame.cd:SetDrawEdge( true ); -- Adds a line along the cooldown's edge

	-- Keep count from going off left side of screen for units on the edge
	Frame.count:ClearAllPoints();
	Frame.count:SetPoint( "BOTTOMLEFT" );
end
--- Resizes the buffs frame to fit all icons.
function me:AuraPreSetPosition ()
	local Visible = self.visibleBuffs or self.visibleDebuffs;
	local IconsPerRow = max( 1, floor( self:GetWidth() / self.size + 0.5 ) );
	local Height = self.size * ceil( Visible / IconsPerRow );
	self:SetHeight( Height < 1e-3 and 1e-3 or Height );
end
do
	local GetCVarBool = GetCVarBool;
	local UnitCanAttack = UnitCanAttack;
	--- Switches buff filter based on unit hostility.
	function me:BuffPreUpdate ( UnitID )
		self.BuffConsolidate = GetCVarBool( "consolidateBuffs" );
		self.Hostile = UnitCanAttack( "player", UnitID );

		if ( self.ShowAll
			or self.Hostile -- Show all hostile buffs
			or not GetCVarBool( "showCastableBuffs" ) -- Not limited to player's buffs
		) then
			self.filter = "HELPFUL";
		else
			self.filter = "HELPFUL|PLAYER"; -- Show player's buffs cast on friendlies
		end
	end
	--- Switches debuff filter based on unit hostility.
	function me:DebuffPreUpdate ( UnitID )
		if ( self.ShowAll ) then
			self.filter = "HARMFUL";
		elseif ( GetCVarBool( "showCastableDebuffs" ) and ( UnitCanAttack( "player", UnitID ) or UnitCanAttack( "pet", UnitID ) ) ) then
			self.filter = "HARMFUL|PLAYER"; -- Show only your debuffs on hostiles
		elseif ( GetCVarBool( "showDispelDebuffs" ) ) then
			self.filter = "HARMFUL|RAID"; -- Show cleansable debuffs
		else
			self.filter = "HARMFUL"; -- Show all debuffs on friendlies
		end
	end
end
do
	local select = select;
	--- Hides consolidated buffs unless moused-over.
	function me:BuffCustomFilter ( UnitID, _, ... )
		if ( not self.Hostile and self.BuffConsolidate and not self.ShowAll ) then
			local Caster, _, ShouldConsolidate = select( 8, ... );
			local IsMine = Caster == "player" or Caster == "pet" or Caster == "vehicle";
			return not ShouldConsolidate or IsMine; -- Hide consolidated auras cast by others
		else
			return true;
		end
	end
end


--- Recolors the reputation bar on update.
function me:ReputationPostUpdate ( _, _, StandingID )
	self:SetStatusBarColor( unpack( Colors.reaction[ StandingID ] ) );
end

--- Adjusts the rested experience bar segment.
function me:ExperiencePostUpdate ( UnitID, Value, ValueMax )
	local RestedExperience = GetXPExhaustion();
	if ( RestedExperience ) then
		self.RestTexture:SetPoint( "RIGHT", self, "LEFT", self:GetWidth() * min( 1, ( Value + RestedExperience ) / ValueMax ), 0 );
		self.RestTexture:Show();
	else -- Not resting
		self.RestTexture:Hide();
	end
end
--- Updates the rested experience segment's size with the bar.
function me:ExperienceOnSizeChanged ()
	me.ExperiencePostUpdate( self, self.__owner.unit, self:GetValue(), ( select( 2, self:GetMinMaxValues() ) ) );
end


do
	local Classifications = {
		elite = "elite"; worldboss = "elite";
		rare = "rare"; rareelite = "rare";
	};
	--- Shows the rare/elite border for appropriate mobs.
	function me:ClassificationUpdate ( Event, UnitID )
		if ( not Event or UnitIsUnit( UnitID, self.unit ) ) then
			local Type = Classifications[ UnitClassification( self.unit ) ];
			local Texture = self.Classification;
			if ( Type ) then
				Texture:Show();
				Texture:SetDesaturated( Type == "rare" );
			else
				Texture:Hide();
			end
		end
	end
end




-- Custom tags
do
	local Plus = { worldboss = true; elite = true; rareelite = true; };
	--- Tag that displays level/classification or group # in raid.
	function me.TagClassification ( UnitID )
		local RaidID = GetNumRaidMembers();
		if ( UnitID == "player" and RaidID > 0 ) then
			return L.OUF_GROUP_FORMAT:format( ( select( 3, GetRaidRosterInfo( RaidID ) ) ) );
		else
			local Level = UnitLevel( UnitID );
			if ( Plus[ UnitClassification( UnitID ) ] or Level ~= MAX_PLAYER_LEVEL or UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL ) then
				local Color = Level < 0 and QuestDifficultyColors[ "impossible" ] or GetQuestDifficultyColor( Level );
				return L.OUF_CLASSIFICATION_FORMAT:format( Hex( Color ), _TAGS[ "smartlevel" ]( UnitID ) );
			end
		end
	end
end
--- Colored name with server name if different from player's.
function me.TagName ( UnitID, Override )
	local Name, Server = UnitName( Override or UnitID );

	local Color;
	if ( UnitIsPlayer( UnitID ) ) then
		Color = _COLORS.class[ select( 2, UnitClass( UnitID ) ) ];
	elseif ( UnitPlayerControlled( UnitID ) or UnitPlayerOrPetInRaid( UnitID ) ) then -- Pet
		Color = Colors.Pet;
	else -- NPC
		Color = _COLORS.reaction[ UnitReaction( UnitID, "player" ) or 5 ];
	end

	return L.OUF_NAME_FORMAT:format( Hex( Color ), ( Server and Server ~= "" ) and Name.."-"..Server or Name );
end

oUF.Tags[ "_UnderscoreUnitsClassification" ] = me.TagClassification;
oUF.TagEvents[ "_UnderscoreUnitsClassification" ] = "RAID_ROSTER_UPDATE "..oUF.TagEvents[ "smartlevel" ];

oUF.Tags[ "_UnderscoreUnitsName" ] = me.TagName;
oUF.TagEvents[ "_UnderscoreUnitsName" ] = "UNIT_NAME_UPDATE UNIT_FACTION";




local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, _Underscore.MediaBar );

--- Creates a common bar background.
-- @param Brightness  Shade of gray between 0 and 1 to color texture.
-- @return Background texture.
local function CreateBarBackground ( self, Brightness )
	local Background = self:CreateTexture( nil, "BACKGROUND" );
	Background:SetAllPoints( self );
	Background:SetVertexColor( Brightness, Brightness, Brightness );
	Background:SetTexture( BarTexture );
	return Background;
end
local CreateBar;
do
	local SetStatusBarColorBackup;
	--- Hook that sets bar text color along with actual bar color.
	local function SetStatusBarColor ( self, ... )
		self.Text:SetTextColor( ... );
		return SetStatusBarColorBackup( self, ... );
	end
	--- Creates a common status bar.
	-- @param Parent  Parent frame.
	-- @param TextFont  Font object to use for bar text, or nil for no text label.
	-- @return StatusBar frame.
	function CreateBar ( Parent, TextFont )
		local Bar = CreateFrame( "StatusBar", nil, Parent );
		Bar:SetStatusBarTexture( BarTexture );
		if ( TextFont ) then
			Bar.Text = Bar:CreateFontString( nil, "OVERLAY", TextFont:GetName() );
			Bar.Text:SetJustifyV( "MIDDLE" );

			if ( not SetStatusBarColorBackup ) then
				SetStatusBarColorBackup = Bar.SetStatusBarColor;
			end
			Bar.SetStatusBarColor = SetStatusBarColor;
		end
		return Bar;
	end
end
local CreateBarReverse;
do
	--- Repositions the status bar texture to fill from the right at most once per frame.
	local function UpdaterOnUpdate ( Updater )
		Updater:Hide();

		local Bar = Updater:GetParent();
		local Texture = Bar:GetStatusBarTexture();
		Texture:ClearAllPoints();
		Texture:SetPoint( "BOTTOMRIGHT" );
		Texture:SetPoint( "TOPLEFT", Bar, "TOPRIGHT",
			( Bar:GetValue() / select( 2, Bar:GetMinMaxValues() ) - 1 ) * Bar:GetWidth(), 0 );
	end
	--- Requests that the status bar texture be updated before the next frame.
	local function OnChanged ( Bar )
		Bar.Updater:Show();
	end
	--- Creates a status bar that fills in reverse.
	-- @see CreateBar
	function CreateBarReverse ( ... )
		local Bar = CreateBar( ... );
		-- Use a separate frame for OnUpdates, since the bar's OnUpdate handler is used by oUF.
		Bar.Updater = CreateFrame( "Frame", nil, Bar );
		Bar.Updater:Hide();
		Bar.Updater:SetScript( "OnUpdate", UpdaterOnUpdate );

		Bar:SetScript( "OnSizeChanged", OnChanged );
		Bar:SetScript( "OnValueChanged", OnChanged );
		Bar:SetScript( "OnMinMaxChanged", OnChanged );

		return Bar;
	end
end


--- Creates a common aura frame shared by buffs and debuffs.
local function CreateAuras ( Frame, Style )
	local Auras = CreateFrame( "Frame", nil, Frame );
	Auras:SetHeight( 1 );
	Auras:SetFrameStrata( "LOW" ); -- Don't allow auras to overlap other units
	Auras.initialAnchor = "TOPLEFT";
	Auras[ "growth-y" ] = "DOWN";
	Auras.size = Style.AuraSize;
	Auras.PostCreateIcon = me.AuraPostCreateIcon;
	Auras.PreSetPosition = me.AuraPreSetPosition;
	return Auras;
end


local CreateIcon;
do
	--- Updates icon anchors when one is shown or hidden at most once per frame.
	local function OnUpdate ( Icons )
		Icons:SetScript( "OnUpdate", nil );

		local Count, IconLast = 0;
		for _, Icon in ipairs( Icons ) do
			if ( Icon:IsShown() ) then
				Icon:ClearAllPoints();
				if ( IconLast ) then
					Icon:SetPoint( "LEFT", IconLast, "RIGHT" );
				else
					Icon:SetPoint( "TOPLEFT" );
				end
				Count, IconLast = Count + 1, Icon;
			end
		end
		Icons:SetWidth( max( 1e-3, Icons:GetHeight() * Count ) );
	end
	local ShowBackup, HideBackup;
	--- Hook to resize the icons list when one is shown.
	local function Show ( Icon, ... )
		Icon:GetParent():SetScript( "OnUpdate", OnUpdate );
		return ShowBackup( Icon, ... );
	end
	--- Hook to resize the icons list when one is hidden.
	local function Hide ( Icon, ... )
		Icon:GetParent():SetScript( "OnUpdate", OnUpdate );
		return HideBackup( Icon, ... );
	end
	--- Adds an icon texture to the expanding icons frame.
	function CreateIcon ( Icons )
		local Icon = Icons:CreateTexture( nil, "ARTWORK" );
		Icon:Hide();
		local Size = Icons:GetHeight();
		Icon:SetSize( Size, Size );
		Icons[ #Icons + 1 ] = Icon;

		-- Hooks to trigger resizing the icon list
		if ( not ShowBackup ) then
			ShowBackup, HideBackup = Icon.Show, Icon.Hide;
		end
		Icon.Show, Icon.Hide = Show, Hide;

		return Icon;
	end
end


local CreateDebuffHighlight; -- Creates a border frame that behaves like a texture for the oUF_DebuffHighlight element.
if ( IsAddOnLoaded( "oUF_DebuffHighlight" ) ) then
	--- Mimics the Texture:SetVertexColor method to color all border textures.
	local function SetVertexColor ( self, ... )
		for Index = 1, #self do
			self[ Index ]:SetVertexColor( ... );
		end
	end
	--- Mimics the Texture:GetVertexColor method to get the color of the debuff textures.
	local function GetVertexColor ( self )
		return self[ 1 ]:GetVertexColor();
	end
	--- Creates a texture for one side of the debuff outline.
	-- @param Parent  Frame to parent new texture to.
	-- @param Point1  First anchor point.
	-- @param PointFrame  First anchor point frame.
	-- @param ...  Arguments for second anchor.
	-- @return New Texture object.
	local function CreateTexture( Parent, Point1, Point1Frame, ... )
		local Texture = Parent:CreateTexture( nil, "OVERLAY" );
		Texture:SetTexture( [[Interface\Buttons\WHITE8X8]] );
		Texture:SetPoint( Point1, Point1Frame );
		Texture:SetPoint( ... );
		return Texture;
	end
	--- Creates a border for oUF_DebuffHighlight between Parent and a containing frame Outer.
	-- @param Parent  Frame to outline and parent textures to.
	-- @param Outer  Containing region to anchor textures to.
	-- @return Table that implements Texture methods used by oUF_DebuffHighlight.
	function CreateDebuffHighlight ( Parent, Outer )
		local DebuffHighlight = {
			GetVertexColor = GetVertexColor;
			SetVertexColor = SetVertexColor;
			-- Four separate outline textures so faded frames blend correctly
			CreateTexture( Parent, "TOPLEFT", Outer,     "BOTTOMRIGHT", Parent, "TOPRIGHT" ), -- Top
			CreateTexture( Parent, "TOPRIGHT", Outer,    "BOTTOMLEFT", Parent, "BOTTOMRIGHT" ), -- Right
			CreateTexture( Parent, "BOTTOMRIGHT", Outer, "TOPLEFT", Parent, "BOTTOMLEFT" ), -- Bottom
			CreateTexture( Parent, "BOTTOMLEFT", Outer,  "TOPRIGHT", Parent, "TOPLEFT" ) -- Left
		};
		DebuffHighlight:SetVertexColor( 0, 0, 0, 0 ); -- Default color used when not debuffed
		return DebuffHighlight;
	end
end




--- Sets up a unit frame based on its style table.
-- @param Style  Properties table.
-- @param Frame  Unit frame to add to.
-- @param UnitID  Unit this frame represents.
function me.StyleMeta.__call ( Style, Frame, UnitID )
	Frame.colors = Colors;
	Frame:SetAttribute( "toggleForVehicle", false );

	Frame:SetSize( Style.Width, Style.Height );
	Frame:SetScript( "OnEnter", me.OnEnter );
	Frame:SetScript( "OnLeave", UnitFrame_OnLeave );

	-- Enable the right-click menu
	SecureUnitButton_OnLoad( Frame, UnitID, _Underscore.Units.ShowGenericMenu );
	Frame:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );

	local Backdrop = _Underscore.Backdrop.Create( Frame );
	Frame:SetHighlightTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]] );
	Frame:GetHighlightTexture():SetAllPoints( Backdrop );
	local Background = Frame:CreateTexture( nil, "BACKGROUND" );
	Background:SetAllPoints();
	Background:SetTexture( 0, 0, 0 );

	local BarWidth = Style.Width;
	local Bars = CreateFrame( "Frame", nil, Frame );
	Frame.Bars = Bars;
	-- Portrait and overlapped elements
	if ( Style.PortraitSide ) then
		local Portrait = CreateFrame( "PlayerModel", nil, Frame );
		Frame.Portrait = Portrait;
		local Side = Style.PortraitSide;
		local Opposite = Side == "RIGHT" and "LEFT" or "RIGHT";
		Portrait:SetPoint( "TOP" );
		Portrait:SetPoint( "BOTTOM" );
		Portrait:SetPoint( Side );
		Portrait:SetWidth( Style.Height );
		Portrait.PostUpdate = me.PortraitPostUpdate;
		BarWidth = BarWidth - Style.Height;

		local Classification = Portrait:CreateTexture( nil, "OVERLAY" );
		local Size = Style.Height * 1.35;
		Frame.Classification = Classification;
		Classification:SetPoint( "CENTER" );
		Classification:SetSize( Size, Size );
		Classification:SetTexture( [[Interface\AchievementFrame\UI-Achievement-IconFrame]] );
		Classification:SetTexCoord( 0, 0.5625, 0, 0.5625 );
		Classification:SetAlpha( 0.8 );
		tinsert( Frame.__elements, me.ClassificationUpdate );
		Frame:RegisterEvent( "UNIT_CLASSIFICATION_CHANGED", me.ClassificationUpdate );

		local RaidIcon = Portrait:CreateTexture( nil, "OVERLAY" );
		local Size = Style.Height / 2;
		Frame.RaidIcon = RaidIcon;
		RaidIcon:SetPoint( "CENTER" );
		RaidIcon:SetSize( Size, Size );

		if ( IsAddOnLoaded( "oUF_CombatFeedback" ) ) then
			local FeedbackText = Portrait:CreateFontString( nil, "OVERLAY", "NumberFontNormalLarge" );
			Frame.CombatFeedbackText = FeedbackText;
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
	local Health = CreateBarReverse( Frame, Style.HealthText and Style.BarTextFont );
	Frame.Health = Health;
	Health:SetPoint( "TOPLEFT", Bars );
	Health:SetPoint( "RIGHT", Bars );
	Health:SetHeight( Style.Height * ( 1 - Style.PowerHeight - Style.ProgressHeight ) );
	CreateBarBackground( Health, 0.07 );
	Health.frequentUpdates = true;
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

	-- Healing prediction
	local MyBar = CreateBar( Health );
	MyBar:SetPoint( "TOPLEFT", Health:GetStatusBarTexture() );
	MyBar:SetPoint( "BOTTOM", Health:GetStatusBarTexture() );
	MyBar:SetWidth( BarWidth );
	MyBar:SetAlpha( 0.75 );
	MyBar:SetStatusBarColor( unpack( Colors.reaction[ 8 ] ) );
	local OtherBar = CreateBar( Health );
	OtherBar:SetPoint( "TOPLEFT", MyBar:GetStatusBarTexture(), "TOPRIGHT" );
	OtherBar:SetPoint( "BOTTOM", MyBar:GetStatusBarTexture() );
	OtherBar:SetWidth( BarWidth );
	OtherBar:SetAlpha( 0.5 );
	OtherBar:SetStatusBarColor( unpack( Colors.reaction[ 8 ] ) );
	Frame.HealPrediction = {
		myBar = MyBar;
		otherBar = OtherBar;
		maxOverflow = math.huge;
	};

	Health.PostUpdate = me.HealthPostUpdate;


	-- Power bar
	local Power = CreateBar( Frame, Style.PowerText and Style.BarTextFont );
	Frame.Power = Power;
	Power:SetPoint( "TOPLEFT", Health, "BOTTOMLEFT" );
	Power:SetPoint( "RIGHT", Bars );
	Power:SetHeight( Style.Height * Style.PowerHeight );
	CreateBarBackground( Power, 0.14 );
	Power.frequentUpdates = true;
	Power.colorPower = true;

	if ( Power.Text ) then
		Power.Text:SetPoint( "TOPRIGHT", -2, 0 );
		Power.Text:SetPoint( "BOTTOM" );
		Power.Text:SetAlpha( 0.75 );
		Power.TextLength = Style.PowerText;
	end

	Power.PostUpdate = me.PowerPostUpdate;


	-- Casting/rep/exp bar
	local Progress = CreateBar( Frame );
	Progress:SetPoint( "BOTTOMLEFT", Bars );
	Progress:SetPoint( "TOPRIGHT", Power, "BOTTOMRIGHT" );
	Progress:SetAlpha( 0.8 );
	Progress:Hide();
	CreateBarBackground( Progress, 0.07 ):SetParent( Bars ); -- Show background while hidden
	if ( UnitID == "player" ) then
		if ( IsAddOnLoaded( "oUF_Experience" ) and UnitLevel( "player" ) ~= MAX_PLAYER_LEVEL and not IsXPUserDisabled() ) then
			Frame.Experience = Progress;
			Progress:SetStatusBarColor( unpack( Colors.Experience ) );
			Progress.PostUpdate = me.ExperiencePostUpdate;
			Progress:SetScript( "OnSizeChanged", me.ExperienceOnSizeChanged );
			Progress:Show();
			local Rest = Progress:CreateTexture( nil, "ARTWORK" );
			Progress.RestTexture = Rest;
			Rest:SetTexture( BarTexture );
			Rest:SetVertexColor( unpack( Colors.ExperienceRested ) );
			Rest:SetPoint( "TOPLEFT", Progress:GetStatusBarTexture(), "TOPRIGHT" );
			Rest:SetPoint( "BOTTOM" );
			Rest:Hide();
		elseif ( IsAddOnLoaded( "oUF_Reputation" ) ) then
			Frame.Reputation = Progress;
			Progress.PostUpdate = me.ReputationPostUpdate;
		end
	elseif ( UnitID == "pet" ) then
		if ( IsAddOnLoaded( "oUF_Experience" ) and select( 2, UnitClass( "player" ) ) == "HUNTER" ) then
			Frame.Experience = Progress;
			Progress:SetStatusBarColor( unpack( Colors.Experience ) );
			Progress:Show();
		end
	else -- Castbar
		Frame.Castbar = Progress;
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
	Frame.Name = Name;
	Name:SetPoint( "LEFT", 2, 0 );
	if ( Health.Text ) then
		Name:SetPoint( "RIGHT", Health.Text, "LEFT" );
	else
		Name:SetPoint( "RIGHT", -2, 0 );
	end
	Name:SetJustifyH( "LEFT" );
	Frame:Tag( Name, "[_UnderscoreUnitsName]" );


	-- Info string
	local Info = Health:CreateFontString( nil, "OVERLAY", me.FontTiny:GetName() );
	Frame.Info = Info;
	Info:SetPoint( "BOTTOM", 0, 2 );
	Info:SetPoint( "TOPLEFT", Name, "BOTTOMLEFT" );
	Info:SetJustifyV( "BOTTOM" );
	Info:SetAlpha( 0.8 );
	Frame:Tag( Info, "[_UnderscoreUnitsClassification]" );


	if ( Style.Auras ) then
		local Buffs, Debuffs = CreateAuras( Frame, Style ), CreateAuras( Frame, Style );
		Frame.Buffs, Frame.Debuffs = Buffs, Debuffs;
	
		-- Buffs
		Buffs:SetPoint( "TOPLEFT", Backdrop, "BOTTOMLEFT" );
		Buffs:SetPoint( "RIGHT", Backdrop );
		Buffs.PreUpdate = me.BuffPreUpdate;
		Buffs.CustomFilter = me.BuffCustomFilter;

		-- Debuffs
		Debuffs:SetPoint( "TOPLEFT", Buffs, "BOTTOMLEFT" );
		Debuffs:SetPoint( "RIGHT", Backdrop );
		Debuffs.showDebuffType = true;
		Debuffs.PreUpdate = me.DebuffPreUpdate;

		-- Mouseover handler
		local AuraMouseover = CreateFrame( "Frame", nil, Frame );
		Frame.AuraMouseover = AuraMouseover;
		AuraMouseover:Hide();
		AuraMouseover:SetPoint( "TOPLEFT", -8, 0 ); -- Allow some leeway on the sides and bottom
		AuraMouseover:SetPoint( "BOTTOMRIGHT", Debuffs, "BOTTOMRIGHT", 8, -8 );
		AuraMouseover:SetScript( "OnUpdate", me.AuraMouseoverOnUpdate );
		AuraMouseover:SetScript( "OnShow", me.AuraMouseoverOnShow );
		AuraMouseover:SetScript( "OnHide", me.AuraMouseoverOnHide );
	end

	-- Debuff highlight
	if ( CreateDebuffHighlight and Style.DebuffHighlight ) then
		Frame.DebuffHighlight = CreateDebuffHighlight( Frame, Backdrop );
		Frame.DebuffHighlightAlpha = 1;
		Frame.DebuffHighlightFilter = Style.DebuffHighlight ~= "ALL";
	end

	-- Range fading
	Frame[ IsAddOnLoaded( "oUF_SpellRange" ) and "SpellRange" or "Range" ] = me.Range;


	-- Icons
	local Icons = CreateFrame( "Frame", nil, Health );
	Frame.Icons = Icons;
	Icons:SetHeight( 16 );
	Icons:SetPoint( "TOPLEFT", 1, -1 );

	Frame.Leader = CreateIcon( Icons );
	Frame.MasterLooter = CreateIcon( Icons );
	if ( UnitID == "player" ) then
		Frame.Resting = CreateIcon( Icons );
	end
	Frame.LFDRole = CreateIcon( Icons );
end




me.FontNormal:SetFont( [[Fonts\ARIALN.TTF]], 10, "OUTLINE" );
me.FontTiny:SetFont( [[Fonts\ARIALN.TTF]], 8, "OUTLINE" );
me.FontMicro:SetFont( [[Fonts\ARIALN.TTF]], 6 );

-- Defaults
me.StyleMeta.__index = {
	Width = 130;
	Height = 50;

	PortraitSide = "RIGHT"; -- "LEFT"/"RIGHT"/false
	HealthText = "Small"; -- "Full"/"Small"/"Tiny"
	PowerText  = "Small"; -- Same as Health
	NameFont = me.FontNormal;
	BarTextFont = me.FontTiny;
	CastTime = true;
	AuraSize = 15;
	Auras = true;
	DebuffHighlight = true; -- "ALL" for all, true for cleansable debuffs only, or false for none

	PowerHeight = 0.25;
	ProgressHeight = 0.1;
};

oUF:RegisterStyle( "_UnderscoreUnits", setmetatable( {
	Width = 160;
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
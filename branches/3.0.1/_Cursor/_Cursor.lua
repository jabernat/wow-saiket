--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * _Cursor.lua - Adds custom effects to your cursor.                          *
  ****************************************************************************]]


local Version = GetAddOnMetadata( "_Cursor", "Version" ):match( "^([%d.]+)" );
_CursorOptions = nil;
_CursorOptionsCharacter = {
	Models = {};
	Version = Version;
};


local L = _CursorLocalization;
local me = CreateFrame( "Frame", "_Cursor" );

local ModelsUnused = {};
me.ModelsUnused = ModelsUnused;
local ModelsUsed = {};
me.ModelsUsed = ModelsUsed;

me.ScaleDefault = 0.01; -- Baseline scaling factor applied before presets and custom scales


-- Set strings formatted as follows:
-- "Name|Enabled(1/0)|Strata|Type|Value[|Scale][|Facing][|X][|Y]"
me.DefaultSets = {
	[ L.SETS[ "ENERGY" ] ] = { -- Energy/lightning trail
		"LAYER1|1|TOOLTIP|TRAIL|1",
		"LAYER2|1|FULLSCREEN_DIALOG|PARTICLE|1",
		"LAYER3|0|FULLSCREEN_DIALOG|CUSTOM|"
	};
	[ L.SETS[ "SHADOW" ] ] = { -- Cloudy shadow trail
		"LAYER1|1|TOOLTIP|TRAIL|2|0.5",
		"LAYER2|1|FULLSCREEN_DIALOG|PARTICLE|4",
		"LAYER3|0|FULLSCREEN_DIALOG|CUSTOM|",
	};
	[ L.SETS[ "MELTER" ] ] = { -- Large red blowtorch
		"Laser|1|LOW|CUSTOM|spells\\cthuneeyeattack|1.5|.4|32|13",
		"Heat|1|BACKGROUND|CUSTOM|spells\\deathanddecay_area_base",
		"Smoke|1|BACKGROUND|CUSTOM|spells\\sandvortex_state_base",
		"Nova|0|LOW|CUSTOM|spells\\aimedshot_impact_chest",
	};
};
me.DefaultModelSet = "ENERGY";
-- Preset strings formatted as follows:
-- "Name|Path|Scale|Facing|X|Y"
me.Presets = {
	[ "GLOW" ] = {
		"Burning cloud, blue|spells\\manafunnel_impact_chest|1|0|4|-6",
		"Burning cloud, green|spells\\lifetap_state_chest|1|0|4|-6",
		"Burning cloud, purple|spells\\soulfunnel_impact_chest|1|0|4|-6",
		"Burning cloud, red|spells\\healrag_state_chest|1|0|4|-6",
		"Cloud, black & blue|spells\\enchantments\\soulfrostglow_high|4|0|8|-7",
		"Cloud, blue|spells\\enchantments\\spellsurgeglow_high|6|0|10|-8",
		"Cloud, bright purple|spells\\gouge_precast_state_hand|2.4|0|11|-9",
		"Cloud, corruption|spells\\seedofcorruption_state|.9|0|9|-8",
		"Cloud, dark blue|spells\\summon_precast_hand|2.7|0|9|-8",
		"Cloud, executioner|spells\\enchantments\\disintigrateglow_high|4|0|8|-7",
		"Cloud, fire|spells\\enchantments\\sunfireglow_high|5|0|10|-8",
		"Cloud, frost|spells\\icyenchant_high|8|0|8|-8",
		"Ring, bloodlust|spells\\bloodlust_state_hand|2.6|0|9|-8",
		"Ring, pulse blue|spells\\brillianceaura|.8|0|8|-8",
		"Ring, frost|spells\\ice_precast_high_hand|1.9|0|11|-9",
		"Ring, swirl|particles\\stunswirl_state_head|1|0|9|-8",
		"Ring, vengeance|spells\\vengeance_state_hand|2|0|9|-8",
		"Simple, black|spells\\shadowmissile|2|0|5|-6",
		"Simple, white|spells\\enchantments\\whiteflame_low|4|5.3|10|-8",
		"Weather, lightning|spells\\goblin_weather_machine_lightning|1.3|0|10|-11",
		"Weather, sun|spells\\goblin_weather_machine_sunny|1.5|2.1|11|-9",
		"Weather, snow|spells\\goblin_weather_machine_snow|1.5|2.1|11|-9",
		"Weather, cloudy|spells\\goblin_weather_machine_cloudy|1.5|2.1|11|-9",
	};
	[ "INDICATOR" ] = {
		"Blood cloud|spells\\beastwithin_state_base|.5|0|0|0",
		"Light blue pulse|spells\\stoneform_state_base|1|0|9|-8",
		"Periodic glint|spells\\enchantments\\sparkle_a|4|0|0|0",
		"Shockwave red|spells\\lacerate_impact|1.3|0|0|0",
		"Snowball hit|spells\\snowball_impact_chest|1|0|5|-6",
	};
	[ "PARTICLE" ] = {
		"Dust, arcane|spells\\arcane_form_precast|1.1|.7|9|-11",
		"Dust, embers|spells\\fire_form_precast|1.1|.7|9|-11",
		"Dust, holy|spells\\holy_form_precast|1.1|.7|9|-11",
		"Dust, ice shards|spells\\frost_form_precast|1.1|.7|9|-11",
		"Dust, shadow|spells\\shadow_form_precast|1.1|.7|9|-11",
		"Fire, blue|spells\\fire_blue_precast_uber_hand|1|0|6|-8",
		"Fire, fel|spells\\fel_fire_precast_hand|1|0|6|-8",
		"Fire, orange|spells\\fire_precast_uber_hand|1.5|0|4|-6",
		"Fire, periodic red & blue|spells\\incinerate_impact_base|.8|0|11|-10",
		"Fire, wavy purple|spells\\incinerateblue_low_base|.25|2.3|11|-10",
		"Frost|spells\\ice_precast_low_hand|2.5|0|8|-7",
		"Leaves|spells\\nature_form_precast|2.5|1|13|-11",
		"Shadow cloud|spells\\cripple_state_chest|.5|0|8|-8",
		"Spark, small white|spells\\dispel_low_recursive|4|0|0|0",
		"Spark, small blue|spells\\detectmagic_recursive|4|0|0|0",
		"Sparks, periodic healing|spells\\lifebloom_state|1|0|8|-8",
		"Sparks, red|spells\\immolationtrap_recursive|4|0|0|0",
	};
	[ "TRAIL" ] = {
		"Electric, blue long|spells\\lightningboltivus_missile|.1|0|4|-6",
		"Electric, blue|spells\\lightning_precast_low_hand|1|0|4|-6",
		"Electric, green|spells\\lightning_fel_precast_low_hand|1|0|4|-6",
		"Electric, yellow|spells\\wrath_precast_hand|1.5|0|4|-6",
		"First-aid|spells\\firstaid_hand|2|0|4|-6",
		"Freedom|spells\\blessingoffreedom_state|.4|0|8|-8",
		"Ghost|spells\\zig_missile|.7|1|8|-5",
		"Holy bright|spells\\holy_missile_uber|.9|0|11|-9",
		"Long blue & holy glow|spells\\alliancectfflag_spell|.9|2.3|1|-2",
		"Shadow|spells\\shadow_precast_uber_hand|1|0|4|-6",
		"Souls, small|spells\\soulshatter_missile|1.7|0|5|-6",
		"Souls|spells\\wellofsouls_base|.5|0|9|-8",
		"Sparkling, blue|spells\\intervenetrail|1|2.4|7|-7",
		"Sparkling, light green|spells\\sprint_impact_chest|1.3|.8|3|-4",
		"Sparkling, red|spells\\chargetrail|1|2.4|0|0",
		"Sparkling, white|spells\\ribbontrail|1|0|0|0",
		"Swirling, black|spells\\shadow_impactdd_med_base|.5|0|5|-6",
		"Swirling, blood|spells\\bloodbolt_chest|.5|0|5|-6",
		"Swirling, blue|spells\\banish_chest_blue|.5|0|11|-9",
		"Swirling, holy|spells\\holy_precast_uber_hand|1|0|5|-6",
		"Swirling, nature|spells\\rejuvenation_impact_base|.35|0|5|-6",
		"Swirling, poison|spells\\banish_chest|.5|0|11|-9",
		"Swirling, purple|spells\\banish_chest_purple|.5|0|11|-9",
		"Swirling, shadow|spells\\banish_chest_dark|.5|0|11|-9",
		"Swirling, white|spells\\banish_chest_white|.5|0|11|-9",
		"Swirling, yellow|spells\\banish_chest_yellow|.5|0|11|-9",
	};
};


me.IsCameraMoving = false;
me.IsMouselooking = false;




--[[****************************************************************************
  * Function: _Cursor.GetModel                                                 *
  * Description: Creates a new model frame or returns an unused one.           *
  ****************************************************************************]]
function me.GetModel ()
	local Model = next( ModelsUnused );
	if ( not Model ) then
		Model = CreateFrame( "Model", nil, me );
		Model:SetAllPoints( nil ); -- Fullscreen
		Model:Hide();
		Model:SetLight( 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ); -- Allows trails like warriors' intervene to work
	end

	ModelsUnused[ Model ] = true;
	return Model;
end
--[[****************************************************************************
  * Function: _Cursor:ModelEnable                                              *
  * Description: Ties a model to a settings table.                             *
  ****************************************************************************]]
function me:ModelEnable ( Settings )
	if ( ModelsUsed[ self ] ) then
		me.ModelDisable( self );
	end

	ModelsUnused[ self ] = nil;
	ModelsUsed[ self ] = Settings;

	me.ModelUpdate( self );
	self:Show();
end
--[[****************************************************************************
  * Function: _Cursor:ModelDisable                                             *
  * Description: Frees up a model.                                             *
  ****************************************************************************]]
function me:ModelDisable ()
	if ( ModelsUsed[ self ] ) then
		self.X = nil;
		self.Y = nil;

		ModelsUsed[ self ] = nil;
		ModelsUnused[ self ] = true;

		self:Hide();
		self:ClearModel();
	end
end


--[[****************************************************************************
  * Function: _Cursor:ModelUpdate                                              *
  * Description: Synchronizes a model with its settings table.                 *
  ****************************************************************************]]
do
	local Settings, ScaleCustom, FacingCustom;
	local Name, Path, Scale, Facing, X, Y;

	function me:ModelUpdate ()
		Settings = ModelsUsed[ self ];

		self.X = Settings.X or 0;
		self.Y = Settings.Y or 0;
		ScaleCustom = ( Settings.Scale or 1.0 ) * me.ScaleDefault;
		FacingCustom = Settings.Facing or 0;

		if ( Settings.Type == "CUSTOM" ) then
			self:SetModel( Settings.Value..".mdx" );
		else
			Name, Path, Scale, Facing, X, Y = ( "|" ):split( me.Presets[ Settings.Type ][ Settings.Value ] );
			self:SetModel( Path..".mdx" );
			self.X = self.X + X;
			self.Y = self.Y + Y;
			ScaleCustom = ScaleCustom * Scale;
			FacingCustom = FacingCustom + Facing;
		end

		self:SetModelScale( ScaleCustom );
		self:SetFacing( FacingCustom );
		self:SetFrameStrata( Settings.Strata );
	end
end






--[[****************************************************************************
  * Function: _Cursor.LoadSet                                                  *
  * Description: Unpacks a set into the current settings.                      *
  ****************************************************************************]]
do
	local Tables = {};
	local function ParseData ( Name, Enabled, Strata, Type, ... )
		return Name, Enabled, Strata, Type, ( "|" ):join( ... ); -- Repacks paths with pipes (if even possible)
	end
	local tonumber = tonumber;
	function me.LoadSet ( Set )
		local Models = _CursorOptionsCharacter.Models;

		-- Unload tables
		for Index, Settings in ipairs( Models ) do
			Models[ Index ] = nil;
			Tables[ Settings ] = true;
		end
		-- Unpack new data
		for Index, ModelData in ipairs( Set ) do
			local Settings = next( Tables ) or {};
			Tables[ Settings ] = nil;

			Settings.Name, Settings.Enabled, Settings.Strata, Settings.Type, Settings.Value,
				Settings.Scale, Settings.Facing, Settings.X, Settings.Y = ( "|" ):split( ModelData );
			Settings.Enabled = Settings.Enabled ~= "0" and true or false;
			Settings.Value = tonumber( Settings.Value ) or Settings.Value;
			Settings.Scale = tonumber( Settings.Scale );
			Settings.Facing = tonumber( Settings.Facing );
			Settings.X = tonumber( Settings.X );
			Settings.Y = tonumber( Settings.Y );
			Models[ Index ] = Settings;
		end

		me.Update();
		if ( me.Options ) then
			me.Options.Update();
		end
	end
end
--[[****************************************************************************
  * Function: _Cursor.SaveSet                                                  *
  * Description: Packs a set from the current settings.                        *
  ****************************************************************************]]
function me.SaveSet ( Set )
	-- Clear set table
	for Index in ipairs( Set ) do
		Set[ Index ] = nil;
	end
	-- Pack data
	for Index, Settings in ipairs( _CursorOptionsCharacter.Models ) do
		Set[ Index ] = ( "|" ):join( Settings.Name, Settings.Enabled and 1 or 0,
			Settings.Strata, Settings.Type, Settings.Value, Settings.Scale or "",
			Settings.Facing or "", Settings.X or "", Settings.Y or "" ):gsub( "||+$", "|" );
	end
end

--[[****************************************************************************
  * Function: _Cursor.Update                                                   *
  * Description: Resynchronizes _Cursor with its settings table.               *
  ****************************************************************************]]
do
	local StrataLevels = {
		BACKGROUND = false; LOW = false; MEDIUM = false; HIGH = false;
		DIALOG = false; FULLSCREEN = false; FULLSCREEN_DIALOG = false; TOOLTIP = false;
	};
	local Model, Level;
	function me.Update ()
		for Model in pairs( ModelsUsed ) do
			me.ModelDisable( Model );
		end

		for Strata in pairs( StrataLevels ) do
			StrataLevels[ Strata ] = 0;
		end
		for _, Settings in ipairs( _CursorOptionsCharacter.Models ) do
			if ( Settings.Enabled ) then
				Model = me.GetModel();
				me.ModelEnable( Model, Settings );

				Level = StrataLevels[ Settings.Strata ] + 1;
				StrataLevels[ Settings.Strata ] = Level;
				Model:SetFrameLevel( Level );
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Cursor:ADDON_LOADED                                             *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	if ( AddOn == "_Cursor" ) then
		me:UnregisterEvent( "ADDON_LOADED" );
		me.ADDON_LOADED = nil;

		if ( not _CursorOptions ) then
			_CursorOptions = { Sets = CopyTable( me.DefaultSets ) };
		end
		if ( not _CursorOptionsCharacter.Models[ 1 ] ) then
			me.LoadSet( me.DefaultSets[ L.SETS[ me.DefaultModelSet ] ] );
		else
			me.Update();
			if ( me.Options ) then
				me.Options.Update();
			end
		end

		_CursorOptions.Version = Version;
		_CursorOptionsCharacter.Version = Version;
	end
end
--[[****************************************************************************
  * Function: _Cursor:OnEvent                                                  *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( self[ Event ] ) == "function" ) then
			self[ Event ]( self, Event, ... );
		end
	end
end


--[[****************************************************************************
  * Function: _Cursor:OnShow                                                   *
  * Description: Resets model animations when shown, to clear old trails.      *
  ****************************************************************************]]
function me:OnShow ()
	for Model in pairs( ModelsUsed ) do
		local Path = Model:GetModel();
		if ( type( Path ) == "string" ) then
			Model:SetModel( Path );
		end
	end
end
--[[****************************************************************************
  * Function: _Cursor:OnUpdate                                                 *
  * Description: Positions all active models.                                  *
  ****************************************************************************]]
do
	local GetCursorPosition = GetCursorPosition;

	local Hypotenuse = ( GetScreenWidth() ^ 2 + GetScreenHeight() ^ 2 ) ^ 0.5 * UIParent:GetEffectiveScale();
	local Scale, X, Y;

	function me:OnUpdate ( Elapsed )
		X, Y = GetCursorPosition();
		for Model in pairs( ModelsUsed ) do
			Model:SetPosition( ( X + Model.X ) / Hypotenuse, ( Y + Model.Y ) / Hypotenuse, 0 );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnShow", me.OnShow );
	me:RegisterEvent( "ADDON_LOADED" );

	-- Hook camera movement to hide cursor effects
	hooksecurefunc( "CameraOrSelectOrMoveStart", function ()
		me.IsCameraMoving = true;
		me:Hide();
	end );
	hooksecurefunc( "CameraOrSelectOrMoveStop", function ()
		me.IsCameraMoving = false;
		if ( not me.IsMouselooking ) then
			me:Show();
		end
	end );
	do
		local IsMouselooking = IsMouselooking;
		local Mouselooking;
		CreateFrame( "Frame" ):SetScript( "OnUpdate", function ()
			Mouselooking = IsMouselooking();
			if ( Mouselooking ) then
				if ( not me.IsMouselooking ) then
					me.IsMouselooking = true;
					me:Hide();
				end
			elseif ( me.IsMouselooking ) then
				me.IsMouselooking = false;
				if ( not me.IsCameraMoving ) then
					me:Show();
				end
			end
		end );
	end
end

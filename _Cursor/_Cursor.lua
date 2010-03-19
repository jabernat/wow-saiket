--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * _Cursor.lua - Adds custom effects to your cursor.                          *
  ****************************************************************************]]


local AddOnName = ...;
local Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );
_CursorOptions = nil;
_CursorOptionsCharacter = {
	Cursors = {};
	Version = Version;
};


local L = _CursorLocalization;
local me = CreateFrame( "Frame", "_Cursor" );

local ModelsUnused = {};
me.ModelsUnused = ModelsUnused;
local ModelsUsed = {};
me.ModelsUsed = ModelsUsed;

me.ScaleDefault = 0.01; -- Baseline scaling factor applied before presets and custom scales


me.DefaultType, me.DefaultValue = "", "spells\\errorcube"; -- Used when cursor preset not found
-- Set strings formatted as follows:
-- "Name|[Enabled]|Strata|[Type]|Value[|Scale][|Facing][|X][|Y]"
me.DefaultSets = {
	[ L.SETS[ "Energy beam" ] ] = { -- Energy/lightning trail
		L.CURSORS[ "Layer 1" ].."|1|TOOLTIP|Trail|Electric, blue",
		L.CURSORS[ "Layer 2" ].."|1|FULLSCREEN_DIALOG|Particle|Fire, blue",
		L.CURSORS[ "Layer 3" ].."||FULLSCREEN_DIALOG"
	};
	[ L.SETS[ "Shadow trail" ] ] = { -- Cloudy shadow trail
		L.CURSORS[ "Layer 1" ].."|1|TOOLTIP|Trail|Shadow|0.5",
		L.CURSORS[ "Layer 2" ].."|1|FULLSCREEN_DIALOG|Particle|Shadow cloud",
		L.CURSORS[ "Layer 3" ].."||FULLSCREEN_DIALOG",
	};
	[ L.SETS[ "Face Melter (Warning, bright!)" ] ] = { -- Large red blowtorch
		L.CURSORS[ "Laser" ].."|1|LOW||spells\\cthuneeyeattack|1.5|.4|32|13",
		L.CURSORS[ "Heat" ].."|1|BACKGROUND||spells\\deathanddecay_area_base",
		L.CURSORS[ "Smoke" ].."|1|BACKGROUND||spells\\sandvortex_state_base",
	};
};
me.DefaultModelSet = L.SETS[ "Energy beam" ];


-- Preset strings formatted as follows:
-- "Path[|Scale][|Facing][|X][|Y]"
me.Presets = {
	[ "Glow" ] = {
		[ "Burning cloud, blue" ] = "spells\\manafunnel_impact_chest|||4|-6";
		[ "Burning cloud, green" ] = "spells\\lifetap_state_chest|||4|-6";
		[ "Burning cloud, purple" ] = "spells\\soulfunnel_impact_chest|1|0|4|-6";
		[ "Burning cloud, red" ] = "spells\\healrag_state_chest|||4|-6";
		[ "Cloud, black & blue" ] = "spells\\enchantments\\soulfrostglow_high|4||8|-7";
		[ "Cloud, blue" ] = "spells\\enchantments\\spellsurgeglow_high|6||10|-8";
		[ "Cloud, bright purple" ] = "spells\\gouge_precast_state_hand|2.4||11|-9";
		[ "Cloud, corruption" ] = "spells\\seedofcorruption_state|.9||9|-8";
		[ "Cloud, dark blue" ] = "spells\\summon_precast_hand|2.7||9|-8";
		[ "Cloud, executioner" ] = "spells\\enchantments\\disintigrateglow_high|4||8|-7";
		[ "Cloud, fire" ] = "spells\\enchantments\\sunfireglow_high|5||10|-8";
		[ "Cloud, frost" ] = "spells\\icyenchant_high|8||8|-8";
		[ "Ring, bloodlust" ] = "spells\\bloodlust_state_hand|2.6||9|-8";
		[ "Ring, bones" ] = "spells\\bonearmor_state_chest|.8||12|-9";
		[ "Ring, holy" ] = "spells\\holy_precast_high_base|.8||9|-9";
		[ "Ring, pulse blue" ] = "spells\\brillianceaura|.8||8|-8";
		[ "Ring, frost" ] = "spells\\ice_precast_high_hand|1.9||11|-9";
		[ "Ring, vengeance" ] = "spells\\vengeance_state_hand|2||9|-8";
		[ "Simple, black" ] = "spells\\shadowmissile|2||5|-6";
		[ "Simple, green" ] = "spells\\nature_precast_chest|||8|-8";
		[ "Simple, white" ] = "spells\\enchantments\\whiteflame_low|4|5.3|10|-8";
		[ "Weather, lightning" ] = "spells\\goblin_weather_machine_lightning|1.3||10|-11";
		[ "Weather, sun" ] = "spells\\goblin_weather_machine_sunny|1.5|2.1|11|-9";
		[ "Weather, snow" ] = "spells\\goblin_weather_machine_snow|1.5|2.1|11|-9";
		[ "Weather, cloudy" ] = "spells\\goblin_weather_machine_cloudy|1.5|2.1|11|-9";
	};
	[ "Particle" ] = {
		[ "Dust, arcane" ] = "spells\\arcane_form_precast|1.1|.7|9|-11";
		[ "Dust, embers" ] = "spells\\fire_form_precast|1.1|.7|9|-11";
		[ "Dust, holy" ] = "spells\\holy_form_precast|1.1|.7|9|-11";
		[ "Dust, ice shards" ] = "spells\\frost_form_precast|1.1|.7|9|-11";
		[ "Dust, shadow" ] = "spells\\shadow_form_precast|1.1|.7|9|-11";
		[ "Fire" ] = "spells\\demolisher_missile||2.2|11|-11";
		[ "Fire, blue" ] = "spells\\fire_blue_precast_uber_hand|||6|-8";
		[ "Fire, fel" ] = "spells\\fel_fire_precast_hand|||6|-8";
		[ "Fire, orange" ] = "spells\\fire_precast_uber_hand|1.5||4|-6";
		[ "Fire, periodic red & blue" ] = "spells\\incinerate_impact_base|.8||11|-10";
		[ "Fire, wavy purple" ] = "spells\\incinerateblue_low_base|.25|2.3|11|-10";
		[ "Frost" ] = "spells\\ice_precast_low_hand|2.5||8|-7";
		[ "Lava burst" ] = "spells\\shaman_lavaburst_missile|.8||9|-7";
		[ "Leaves" ] = "spells\\nature_form_precast|2.5|1|13|-11";
		[ "Periodic glint" ] = "spells\\enchantments\\sparkle_a|4";
		[ "Plague cloud" ] = "spells\\forsakencatapult_missile|1.5|2.3|10|-10";
		[ "Shadow cloud" ] = "spells\\cripple_state_chest|.5||8|-8";
		[ "Spark, small white" ] = "spells\\dispel_low_recursive|4";
		[ "Spark, small blue" ] = "spells\\detectmagic_recursive|4";
		[ "Sparks, periodic healing" ] = "spells\\lifebloom_state|||8|-8";
		[ "Sparks, red" ] = "spells\\immolationtrap_recursive|4";
	};
	[ "Trail" ] = {
		[ "Blue" ] = "spells\\beartrap|.9||5|-6";
		[ "Electric, blue long" ] = "spells\\lightningboltivus_missile|.1||4|-6";
		[ "Electric, blue" ] = "spells\\lightning_precast_low_hand|||4|-6";
		[ "Electric, green" ] = "spells\\lightning_fel_precast_low_hand|||4|-6";
		[ "Electric, yellow" ] = "spells\\wrath_precast_hand|1.5||4|-6";
		[ "First-aid" ] = "spells\\firstaid_hand|2||4|-6";
		[ "Freedom" ] = "spells\\blessingoffreedom_state|.4||8|-8";
		[ "Ghost" ] = "spells\\zig_missile|.7|1|8|-5";
		[ "Holy bright" ] = "spells\\holy_missile_uber|.9||11|-9";
		[ "Long blue & holy glow" ] = "spells\\alliancectfflag_spell|.9|2.3|1|-2";
		[ "Shadow" ] = "spells\\shadow_precast_uber_hand|||4|-6";
		[ "Souls, small" ] = "spells\\soulshatter_missile|1.7||5|-6";
		[ "Souls" ] = "spells\\wellofsouls_base|.5||9|-8";
		[ "Sparkling, blue" ] = "spells\\intervenetrail||2.4|7|-7";
		[ "Sparkling, light green" ] = "spells\\sprint_impact_chest|1.3|.8|3|-4";
		[ "Sparkling, red" ] = "spells\\chargetrail||2.4";
		[ "Sparkling, white" ] = "spells\\ribbontrail";
		[ "Swirling, black" ] = "spells\\shadow_impactdd_med_base|.5||5|-6";
		[ "Swirling, blood" ] = "spells\\bloodbolt_chest|.5||5|-6";
		[ "Swirling, blue" ] = "spells\\banish_chest_blue|.5||11|-9";
		[ "Swirling, holy" ] = "spells\\holy_precast_uber_hand|||5|-6";
		[ "Swirling, nature" ] = "spells\\rejuvenation_impact_base|.35||5|-6";
		[ "Swirling, poison" ] = "spells\\banish_chest|.5||11|-9";
		[ "Swirling, purple" ] = "spells\\banish_chest_purple|.5||11|-9";
		[ "Swirling, shadow" ] = "spells\\banish_chest_dark|.5||11|-9";
		[ "Swirling, white" ] = "spells\\banish_chest_white|.5||11|-9";
		[ "Swirling, yellow" ] = "spells\\banish_chest_yellow|.5||11|-9";
	};
	[ "Breath" ] = {
		[ "Arcane" ] = "spells\\dragonbreath_arcane|.25|5.4";
		[ "Fire. blue" ] = "spells\\dragonbreath_frost|.25|5.4";
		[ "Fire, fel" ] = "spells\\fel_flamebreath|.5|5.5";
		[ "Fire, purple" ] = "spells\\dragonbreath_shadow|.25|5.4";
		[ "Fire, red" ] = "spells\\dragonbreath_fire|.25|5.4";
		[ "Frost" ] = "spells\\flamebreath_blue|.5|5.5";
		[ "Frostfire" ] = "spells\\flamebreathmff|.5|5.5";
		[ "Smoke" ] = "spells\\corrosivesandbreath|.5|5.5";
	};
};


me.IsCameraMoving = false;
me.IsMouselooking = false;
me.IsCinematicPlaying = false;
me.IsScreenshotSaving = false;




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
		ModelsUnused[ Model ] = true;
	end

	return Model;
end
--[[****************************************************************************
  * Function: _Cursor:ModelEnable                                              *
  * Description: Ties a model to a settings table.                             *
  ****************************************************************************]]
function me:ModelEnable ( Cursor )
	if ( ModelsUsed[ self ] ) then
		me.ModelDisable( self );
	end

	ModelsUnused[ self ] = nil;
	ModelsUsed[ self ] = Cursor;

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
	local Cursor, Scale, Facing, PresetType;
	local Path, ScalePreset, FacingPreset, X, Y;

	function me:ModelUpdate ()
		Cursor = ModelsUsed[ self ];

		self.X = Cursor.X or 0;
		self.Y = Cursor.Y or 0;
		Scale = ( Cursor.Scale or 1.0 ) * me.ScaleDefault;
		Facing = Cursor.Facing or 0;

		-- Validate presets
		if ( #Cursor.Type ~= 0 ) then
			PresetType = me.Presets[ Cursor.Type ];
			if ( not PresetType or not PresetType[ Cursor.Value ] ) then
				Cursor.Type = me.DefaultType;
				Cursor.Value = me.DefaultValue;
				PresetType = me.Presets[ Cursor.Type ];
			end
		end

		if ( #Cursor.Type == 0 ) then -- Custom
			self:SetModel( Cursor.Value..".mdx" );
		else
			Path, ScalePreset, FacingPreset, X, Y = ( "|" ):split( PresetType[ Cursor.Value ] );
			self:SetModel( Path..".mdx" );
			self.X = self.X + ( tonumber( X ) or 0 );
			self.Y = self.Y + ( tonumber( Y ) or 0 );
			Scale = Scale * ( tonumber( ScalePreset ) or 1.0 );
			Facing = Facing + ( tonumber( FacingPreset ) or 0 );
		end

		self:SetModelScale( Scale );
		self:SetFacing( Facing );
		self:SetFrameStrata( Cursor.Strata );
	end
end






--[[****************************************************************************
  * Function: _Cursor.LoadSet                                                  *
  * Description: Unpacks a set into the current settings.                      *
  ****************************************************************************]]
do
	local Tables = {};
	function me.LoadSet ( Set )
		local Cursors = _CursorOptionsCharacter.Cursors;

		-- Unload tables
		for Index, Cursor in ipairs( Cursors ) do
			Cursors[ Index ] = nil;
			Tables[ Cursor ] = true;
		end
		-- Unpack new data
		for Index, CursorData in ipairs( Set ) do
			local Cursor = next( Tables ) or {};
			Tables[ Cursor ] = nil;

			Cursor.Name, Cursor.Enabled, Cursor.Strata, Cursor.Type, Cursor.Value,
				Cursor.Scale, Cursor.Facing, Cursor.X, Cursor.Y = ( "|" ):split( CursorData );
			Cursor.Enabled = #Cursor.Enabled > 0;
			Cursor.Type = Cursor.Type or "";
			Cursor.Value = Cursor.Value or "";
			Cursor.Scale = tonumber( Cursor.Scale );
			Cursor.Facing = tonumber( Cursor.Facing );
			Cursor.X = tonumber( Cursor.X );
			Cursor.Y = tonumber( Cursor.Y );
			Cursors[ Index ] = Cursor;
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
	wipe( Set );
	-- Pack data
	for Index, Cursor in ipairs( _CursorOptionsCharacter.Cursors ) do
		Set[ Index ] = ( "|" ):join( Cursor.Name, Cursor.Enabled and 1 or "",
			Cursor.Strata, Cursor.Type, Cursor.Value, Cursor.Scale or "",
			Cursor.Facing or "", Cursor.X or "", Cursor.Y or "" ):gsub( "|+$", "" );
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
		for _, Cursor in ipairs( _CursorOptionsCharacter.Cursors ) do
			if ( Cursor.Enabled ) then
				Model = me.GetModel();
				me.ModelEnable( Model, Cursor );

				Level = StrataLevels[ Cursor.Strata ] + 1;
				StrataLevels[ Cursor.Strata ] = Level;
				Model:SetFrameLevel( Level );
			end
		end
	end
end


do
	local Blocks = {};
--[[****************************************************************************
  * Function: _Cursor.BlockAdd                                                 *
  * Description: Adds a condition for hiding the cursor.                       *
  ****************************************************************************]]
	function me.BlockAdd ( Name )
		if ( not Blocks[ Name ] ) then
			Blocks[ Name ] = true;
			me:Hide();
		end
	end
--[[****************************************************************************
  * Function: _Cursor.BlockRemove                                              *
  * Description: Removes a condition for hiding the cursor.                    *
  ****************************************************************************]]
	local next = next;
	function me.BlockRemove ( Name )
		if ( Blocks[ Name ] ) then
			Blocks[ Name ] = nil;
			if ( next( Blocks ) == nil ) then -- No more active blocks
				me:Show();
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Cursor.ScreenshotStart                                          *
  ****************************************************************************]]
function me.ScreenshotStart ()
	me.BlockAdd( "Screenshot" );
end
--[[****************************************************************************
  * Function: _Cursor:SCREENSHOT_SUCCEEDED                                     *
  ****************************************************************************]]
function me:SCREENSHOT_SUCCEEDED ()
	me.BlockRemove( "Screenshot" );
end
--[[****************************************************************************
  * Function: _Cursor:SCREENSHOT_FAILED                                        *
  ****************************************************************************]]
me.SCREENSHOT_FAILED = me.SCREENSHOT_SUCCEEDED;
--[[****************************************************************************
  * Function: _Cursor:CINEMATIC_START                                          *
  ****************************************************************************]]
function me:CINEMATIC_START ()
	me.BlockAdd( "Cinematic" ); -- In-game-engine cinematic, like the new character introduction
end
--[[****************************************************************************
  * Function: _Cursor:CINEMATIC_STOP                                           *
  ****************************************************************************]]
function me:CINEMATIC_STOP ()
	me.BlockRemove( "Cinematic" );
end
--[[****************************************************************************
  * Function: _Cursor.MovieStart                                               *
  ****************************************************************************]]
function me.MovieStart ()
	me.BlockAdd( "Movie" ); -- FMV movie sequence, like the Wrathgate cinematic
end
--[[****************************************************************************
  * Function: _Cursor.MovieStop                                                *
  ****************************************************************************]]
function me.MovieStop ()
	me.BlockRemove( "Movie" );
end
--[[****************************************************************************
  * Function: _Cursor.CameraMoveStart                                          *
  ****************************************************************************]]
function me.CameraMoveStart ()
	me.BlockAdd( "Camera" );
end
--[[****************************************************************************
  * Function: _Cursor.CameraMoveStop                                           *
  ****************************************************************************]]
function me.CameraMoveStop ()
	me.BlockRemove( "Camera" );
end
--[[****************************************************************************
  * Function: _Cursor:MouselookOnUpdate                                        *
  * Description: Checks the mouselook status in realtime to hide the cursor    *
  *   when in mouselook mode.                                                  *
  ****************************************************************************]]
do
	local IsMouselooking = IsMouselooking;
	function me:MouselookOnUpdate ()
		if ( IsMouselooking() ) then
			me.BlockAdd( "Mouselook" );
		else
			me.BlockRemove( "Mouselook" );
		end
	end
end


--[[****************************************************************************
  * Function: _Cursor:ADDON_LOADED                                             *
  ****************************************************************************]]
do
	local function VersionCompare ( Version1, Version2 ) -- Compares delimited version strings
		if ( Version1 == Version2 ) then
			return 0;
		end
		Version1, Version2 = { ( "." ):split( Version1 or "" ) }, { ( "." ):split( Version2 or "" ) };
		for Index, Sub1 in ipairs( Version1 ) do
			local Sub2 = Version2[ Index ];
			if ( not Sub2 or Sub1 > Sub2 ) then
				return 1;
			elseif ( Sub1 < Sub2 ) then
				return -1;
			end
		end
		return #Version1 - #Version2;
	end
	function me:ADDON_LOADED ( _, AddOn )
		if ( AddOn:lower() == AddOnName:lower() ) then
			me:UnregisterEvent( "ADDON_LOADED" );
			me.ADDON_LOADED = nil;
	
			if ( not _CursorOptions ) then
				_CursorOptions = { Sets = CopyTable( me.DefaultSets ) };
			end

			if ( _CursorOptions.Version ~= Version ) then
				if ( VersionCompare( _CursorOptions.Version, "3.1.0.2" ) < 0 ) then -- 3.1.0.2: Updated the Face Melter preset
					local Name = L.SETS[ "Face Melter (Warning, bright!)" ];
					if ( _CursorOptions.Sets[ Name ] ) then
						_CursorOptions.Sets[ Name ] = CopyTable( me.DefaultSets[ Name ] );
					end
				end
				_CursorOptions.Version = Version;
			end
			_CursorOptionsCharacter.Version = Version;

			if ( not _CursorOptionsCharacter.Cursors[ 1 ] ) then
				me.LoadSet( me.DefaultSets[ me.DefaultModelSet ] );
			else
				me.Update();
				if ( me.Options ) then
					me.Options.Update();
				end
			end
		end
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
		local Path = Model:GetModel(); -- Returns model table if unset
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
	local pairs = pairs;

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
	me:RegisterEvent( "SCREENSHOT_SUCCEEDED" );
	me:RegisterEvent( "SCREENSHOT_FAILED" );
	me:RegisterEvent( "CINEMATIC_START" );
	me:RegisterEvent( "CINEMATIC_STOP" );

	-- Hide during screenshots
	hooksecurefunc( "Screenshot", me.ScreenshotStart );
	-- Hide while FMV movies play
	MovieFrame:HookScript( "OnShow", me.MovieStart );
	MovieFrame:HookScript( "OnHide", me.MovieStop );
	-- Hook camera movement to hide cursor effects
	hooksecurefunc( "CameraOrSelectOrMoveStart", me.CameraMoveStart );
	hooksecurefunc( "CameraOrSelectOrMoveStop", me.CameraMoveStop );
	CreateFrame( "Frame" ):SetScript( "OnUpdate", me.MouselookOnUpdate );
end

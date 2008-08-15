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
		"LAYER1|1|TOOLTIP|CUSTOM|Spells\\Cthuneeyeattack|1.5|.4|32|13",
		"LAYER2|1|FULLSCREEN_DIALOG|CUSTOM|Spells\\Deathanddecay_area_base",
	};
};
me.DefaultModelSet = "ENERGY";
-- Preset strings formatted as follows:
-- "Name|Path|Scale|Facing|X|Y"
me.Presets = {
	[ "TRAIL" ] = {
		"Lightning trail|Spells\\Lightning_precast_low_hand|1|0|4|-6",
		"Shadow trail|Spells\\Shadow_precast_uber_hand|1|0|4|-6",
		"Nature trail|Spells\\Wrath_precast_hand|1|0|0|0",
		"First-aid trail|Spells\\Firstaid_hand|2|0|4|-6",
		--[[ Fading trails disappear on half the screen :(
		"Long white trail|Spells\\Chargetrail|1|2.4|0|0",
		"Short white trail|Spells\\Ribbontrail|1|0|0|0",
		"Short sparkling trail|Spells\\Intervenetrail|1|2.4|0|0",
		]]
	};
	[ "GLOW" ] = {
		"Frost cloud|Spells\\Enchantments\\battlemasterglow_high|6|0|8|-8",
		"Snowflake cloud|Spells\\Icyenchant_high|8|0|8|-8",
		"Burning cloud|Spells\\Healrag_state_chest|1|0|4|-6",
	};
	[ "PARTICLE" ] = {
		"Blue fire|Spells\\Fire_blue_precast_hand|1|0|6|-8",
		"Orange Fire|Spells\\Fire_precast_hand|1.5|0|4|-6",
		"Fel fire|Spells\\Fel_fire_precast_hand|1|0|6|-8",
		"Shadow cloud|Spells\\Cripple_state_chest|.5|0|8|-8",
		"Healing sparks|Spells\\Lifebloom_state|1|0|8|-8",
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
function me.Update ()
	for Model in pairs( ModelsUsed ) do
		me.ModelDisable( Model );
	end

	for _, Settings in ipairs( _CursorOptionsCharacter.Models ) do
		if ( Settings.Enabled ) then
			me.ModelEnable( me.GetModel(), Settings );
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

--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * _Cursor.lua - Adds custom effects to your cursor.                          *
  ****************************************************************************]]


local _CursorOptionsCharacterOriginal = {
	Models = {
		{
			Name = "MODEL_OVER"; Enabled = true;
			Type = "TRAIL"; Value = 1;
			Strata = "TOOLTIP";
		},
		{
			Name = "MODEL_UNDER"; Enabled = true;
			Type = "PARTICLE"; Value = 1;
			Strata = "FULLSCREEN_DIALOG";
		}
	};

	Version = select( 3, GetAddOnMetadata( "_Cursor", "Version" ):find( "^([%d.]+)" ) );
};
_CursorOptionsCharacter = _CursorOptionsCharacterOriginal;


local L = _CursorLocalization;
local me = CreateFrame( "Frame", "_Cursor" );

local ModelsUnused = {};
me.ModelsUnused = ModelsUnused;
local ModelsUsed = {};
me.ModelsUsed = ModelsUsed;

local ModelSettings = {};
me.ModelSettings = ModelSettings;


-- Preset strings formatted as follows:
-- "Name|Path|Scale|Facing|OffsetX|OffsetY"
local Presets = {
	[ "TRAIL" ] = {
		"Lightning trail|Spells\\Lightning_precast_low_hand|.01|0|4|-6",
		"Shadow trail|Spells\\Shadow_precast_uber_hand|.01|0|4|-6",
		"Nature trail|Spells\\Wrath_precast_hand|.01|0|0|0",
		"First-aid trail|Spells\\Firstaid_hand|.020|0|4|-6",
		--[[ Fading trails disappear on half the screen :(
		"Long white trail|Spells\\Chargetrail|.01|2.4|0|0",
		"Short white trail|Spells\\Ribbontrail|.01|0|0|0",
		"Short sparkling trail|Spells\\Intervenetrail|.01|2.4|0|0",
		]]
	};
	[ "GLOW" ] = {
		"Frost cloud|Spells\\Enchantments\\battlemasterglow_high|.06|0|8|-8",
		"Snowflake cloud|Spells\\Icyenchant_high|.08|0|8|-8",
		"Burning cloud|Spells\\Healrag_state_chest|.01|0|4|-6",
	};
	[ "PARTICLE" ] = {
		"Blue fire|Spells\\Fire_blue_precast_hand|.01|0|6|-8",
		"Orange Fire|Spells\\Fire_precast_hand|.015|0|4|-6",
		"Fel fire|Spells\\Fel_fire_precast_hand|.01|0|6|-8",
		"Shadow cloud|Spells\\Cripple_state_chest|.005|0|8|-8",
		"Healing sparks|Spells\\Lifebloom_state|.01|0|8|-8",
	};
	[ "MISC" ] = {
		"UI Melter|Spells\\Deathanddecay_area_base|.01|0|0|0",
	};
};
me.Presets = Presets;


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
	ModelSettings[ Settings ] = self;

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

		ModelSettings[ ModelsUsed[ self ] ] = nil;
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
	local Name, Path, Scale, Facing, OffsetX, OffsetY;

	function me:ModelUpdate ()
		Settings = ModelsUsed[ self ];

		self.X = Settings.X or 0;
		self.Y = Settings.Y or 0;
		ScaleCustom = Settings.Scale or 1.0;
		FacingCustom = Settings.Facing or 0;

		if ( Settings.Type == "CUSTOM" ) then
			self:SetModel( Settings.Value..".mdx" );
		else
			Name, Path, Scale, Facing, OffsetX, OffsetY = ( "|" ):split( Presets[ Settings.Type ][ Settings.Value ] );
			self:SetModel( Path..".mdx" );
			self.X = self.X + OffsetX;
			self.Y = self.Y + OffsetY;
			ScaleCustom = ScaleCustom * Scale;
			FacingCustom = FacingCustom + Facing;
		end

		self:SetModelScale( ScaleCustom );
		self:SetFacing( FacingCustom );
		self:SetFrameStrata( Settings.Strata );
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

		if ( _CursorOptionsCharacter ~= _CursorOptionsCharacterOriginal ) then
			-- Validate settings
			for Index, Settings in ipairs( _CursorOptionsCharacter.Models ) do
				if ( Settings.Type ~= "CUSTOM" ) then
					local Type = Presets[ Settings.Type ];
					if ( not Type or not Type[ Settings.Value ] ) then
						-- Reset all models if one is not found
						_CursorOptionsCharacter.Models = _CursorOptionsCharacterOriginal.Models;
						break;
					end
				end
			end
			_CursorOptionsCharacter.Version = _CursorOptionsCharacterOriginal.Version;
		end

		me.Update();
		me.Options.Update();
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

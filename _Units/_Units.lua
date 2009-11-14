--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.lua - Common functions.                                             *
  ****************************************************************************]]


local me = CreateFrame( "Frame" );
_Units = me;
me.Version = GetAddOnMetadata( "_Units", "Version" ):match( "^([%d.]+)" );

me.OptionsCharacter = {
	Version = me.Version;
};
me.OptionsCharacterDefault = {
	Version = me.Version;
	NameplatesTankMode = false;
};

me.AddOnInitializers = {};

me.DropDown = CreateFrame( "Frame", "_UnitsDropDown", UIParent, "UIDropDownMenuTemplate" );

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




--[[****************************************************************************
  * Function: _Units.InitializeAddOn                                           *
  * Description: Runs the initializer for an addon if one is present, and then *
  *   removes it from the initializer list.                                    *
  ****************************************************************************]]
function me.InitializeAddOn ( Name )
	Name = Name:upper(); -- For case insensitive file systems (Windows')
	if ( me.AddOnInitializers[ Name ] and IsAddOnLoaded( Name ) ) then
		me.AddOnInitializers[ Name ]();
		me.AddOnInitializers[ Name ] = nil;
		return true;
	end
end
--[[****************************************************************************
  * Function: _Units.RegisterAddOnInitializer                                  *
  * Description: Adds an addon's initializer function to the initializer list. *
  ****************************************************************************]]
function me.RegisterAddOnInitializer ( Name, Initializer )
	if ( select( 2, IsAddOnLoaded( Name ) ) ) then
		Initializer();
		return true;
	else
		me.AddOnInitializers[ Name:upper() ] = Initializer;
	end
end


--[[****************************************************************************
  * Function: _Units:InitializeGenericMenu                                     *
  * Description: Constructs the unit popup menu.                               *
  ****************************************************************************]]
function me:InitializeGenericMenu ()
	local UnitID = self.unit or "player";
	local Which, Name, ID;

	if ( UnitIsUnit( UnitID, "player" ) ) then
		Which = "SELF";
	elseif ( UnitIsUnit( UnitID, "pet" ) ) then
		Which = "PET";
	elseif ( UnitIsPlayer( UnitID ) ) then
		ID = UnitInRaid( UnitID );
		if ( ID ) then
			Which = "RAID_PLAYER";
		elseif ( UnitInParty( UnitID ) ) then
			Which = "PARTY";
		else
			Which = "PLAYER";
		end
	else
		Which = "RAID_TARGET_ICON";
		Name = RAID_TARGET_ICON;
	end
	if ( Which ) then
		UnitPopup_ShowMenu( self, Which, UnitID, Name, ID );
	end
end
--[[****************************************************************************
  * Function: _Units:ShowGenericMenu                                           *
  * Description: Adds a unit popup based on the unit.                          *
  ****************************************************************************]]
function me:ShowGenericMenu ( UnitID )
	HideDropDownMenu( 1 );

	me.DropDown.unit = UnitID or SecureButton_GetUnit( self );

	if ( me.DropDown.unit ) then
		ToggleDropDownMenu( 1, nil, me.DropDown, "cursor" );
	end
end


--[[****************************************************************************
  * Function: _Units:BlizzardFrameDisable                                      *
  * Description: Effectively removes a default Blizzard unit frame.  Copied    *
  *   from XPerl.                                                              *
  ****************************************************************************]]
function me:BlizzardFrameDisable ()
	self.Show = _Clean.NilFunction;
	self:Hide();

	UnregisterUnitWatch( self );
	self:UnregisterAllEvents();
	if ( self.healthbar ) then
		self.healthbar:UnregisterAllEvents();
	end
	if ( self.manabar ) then
		self.manabar:UnregisterAllEvents();
	end
end


--[[****************************************************************************
  * Function: _Units:PLAYER_TARGET_CHANGED                                     *
  ****************************************************************************]]
function me:PLAYER_TARGET_CHANGED ( Event )
	PlaySound( UnitExists( Event == "PLAYER_FOCUS_CHANGED" and "focus" or "target" ) and "igCharacterSelect" or "igCharacterDeselect" );
end
me.PLAYER_FOCUS_CHANGED = me.PLAYER_TARGET_CHANGED;
--[[****************************************************************************
  * Function: _Units:ADDON_LOADED                                              *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	self.InitializeAddOn( AddOn );
end

--[[****************************************************************************
  * Function: _Units:OnEvent                                                   *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
function me:OnEvent ( Event, ... )
	if ( type( self[ Event ] ) == "function" ) then
		self[ Event ]( self, Event, ... );
	end
end




--[[****************************************************************************
  * Function: _Units.Synchronize                                               *
  * Description: Loads an options table, or the defaults.                      *
  ****************************************************************************]]
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if ( not OptionsCharacter ) then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	me.Nameplates.SetTankMode( OptionsCharacter.NameplatesTankMode );
end
--[[****************************************************************************
  * Function: _Units.OnLoad                                                    *
  * Description: Loads defaults and validates settings.                        *
  ****************************************************************************]]
function me.OnLoad ()
	me.OnLoad = nil;

	local OptionsCharacter = _UnitsOptionsCharacter;
	_UnitsOptionsCharacter = me.OptionsCharacter;

	if ( OptionsCharacter ) then
		OptionsCharacter.Version = me.Version;
	end

	me.Synchronize( OptionsCharacter ); -- Loads defaults if nil
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
	me.RegisterAddOnInitializer( "_Units", me.OnLoad );

	me:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	me:RegisterEvent( "PLAYER_FOCUS_CHANGED" );

	tinsert( UnitPopupFrames, me.DropDown:GetName() );
	UIDropDownMenu_Initialize( me.DropDown, me.InitializeGenericMenu, "MENU" );


	for Index = 1, MAX_PARTY_MEMBERS do
		me.BlizzardFrameDisable( _G[ "PartyMemberFrame"..Index ] );
	end
end

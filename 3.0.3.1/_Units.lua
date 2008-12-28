--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.lua - Common functions.                                             *
  *                                                                            *
  * + Adds a mouseover target tooltip.                                         *
  * + Disables the default Blizzard unit frames.                               *
  ****************************************************************************]]


_UnitsOptions = {};


local me = CreateFrame( "Frame" );
_Units = me;

local AddOnInitializers = {};
me.AddOnInitializers = AddOnInitializers;

me.DropDown = CreateFrame( "Frame", "_UnitsDropDown", UIParent, "UIDropDownMenuTemplate" );




--[[****************************************************************************
  * Function: _Units.InitializeAddOn                                           *
  * Description: Runs the initializer for an addon if one is present, and then *
  *   removes it from the initializer list.                                    *
  ****************************************************************************]]
function me.InitializeAddOn ( Name )
	Name = Name:upper(); -- For case insensitive file systems (Windows')
	if ( AddOnInitializers[ Name ] and IsAddOnLoaded( Name ) ) then
		AddOnInitializers[ Name ]();
		AddOnInitializers[ Name ] = nil;
		return true;
	end
end
--[[****************************************************************************
  * Function: _Units.RegisterAddOnInitializer                                  *
  * Description: Adds an addon's initializer function to the initializer list. *
  ****************************************************************************]]
function me.RegisterAddOnInitializer ( Name, Initializer )
	if ( IsAddOnLoaded( Name ) ) then
		Initializer();
		return true;
	else
		AddOnInitializers[ Name:upper() ] = Initializer;
	end
end


--[[****************************************************************************
  * Function: _Units.InitializeGenericMenu                                     *
  * Description: Constructs the unit popup menu.                               *
  ****************************************************************************]]
function me.InitializeGenericMenu ()
	local UnitID = me.DropDown.unit or "player";
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
		UnitPopup_ShowMenu( me.DropDown, Which, UnitID, Name, ID );
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
--[[function me:BlizzardFrameDisable ()
	UnregisterUnitWatch( self );
	self:UnregisterAllEvents();
	self:Hide();

	-- Drag off screen so Show operations won't reveal it
	self:ClearAllPoints();
	self:SetPoint( "BOTTOMRIGHT", UIParent, "TOPLEFT", -512, 512 );

	if ( self.healthbar ) then
		self.healthbar:UnregisterAllEvents();
	end
	if ( self.manabar ) then
		self.manabar:UnregisterAllEvents();
	end
end]]


--[[****************************************************************************
  * Function: _Units:ADDON_LOADED                                              *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	self.InitializeAddOn( AddOn );
end
--[[****************************************************************************
  * Function: _Units:PLAYER_LOGIN                                              *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	-- Initialize any addons that were loaded before _Units
	for Name in pairs( AddOnInitializers ) do
		self.InitializeAddOn( Name );
	end
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "PLAYER_LOGIN" );
	me:RegisterEvent( "ADDON_LOADED" );

	tinsert( UnitPopupFrames, me.DropDown:GetName() );
	UIDropDownMenu_Initialize( me.DropDown, me.InitializeGenericMenu, "MENU" );

	--[[for Index = 1, MAX_PARTY_MEMBERS do
		me.BlizzardFrameDisable( _G[ "PartyMemberFrame"..Index ] );
	end]]
end

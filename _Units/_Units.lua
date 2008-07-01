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




--[[****************************************************************************
  * Function: _Units.InitializeAddOn                                           *
  * Description: Runs the initializer for an addon if one is present, and then *
  *   removes it from the initializer list.                                    *
  ****************************************************************************]]
function me.InitializeAddOn ( Name )
	Name = strupper( Name ); -- For case insensitive file systems (Windows')
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
	AddOnInitializers[ strupper( Name ) ] = Initializer;
end


--[[****************************************************************************
  * Function: _Units:MouseoverTargetFrameOnUpdate                              *
  * Description: Updates the mouseover target's tooltip.                       *
  ****************************************************************************]]
function me:MouseoverTargetFrameOnUpdate ( Elapsed )
	local Tooltip = _G[ self:GetName().."Tooltip" ];
	if ( GameTooltip:IsUnit( "mouseover" ) and UnitExists( "mouseovertarget" ) ) then
		Tooltip:SetOwner( GameTooltip, "ANCHOR_BOTTOMRIGHT" );
		Tooltip:SetUnit( "mouseovertarget" );
		Tooltip:Show();
		Tooltip:ClearAllPoints();
		Tooltip:SetPoint( "BOTTOMLEFT", this );
		Tooltip:SetScale( 0.8 );
		_G[ Tooltip:GetName().."TextLeft1" ]:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
	else
		Tooltip:Hide();
	end
end
--[[****************************************************************************
  * Function: _Units:MouseoverTargetFrameOnLoad                                *
  * Description: Formats the guild title if _Misc is running.                  *
  ****************************************************************************]]
function me:MouseoverTargetFrameOnLoad ()
	if ( IsAddOnLoaded( "_Misc" ) ) then
		_Misc.HookScript( _G[ self:GetName().."Tooltip" ], "OnTooltipSetUnit", _Misc.GameTooltip.UpdateUnitGuild );
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

	--[[for Index = 1, MAX_PARTY_MEMBERS do
		me.BlizzardFrameDisable( _G[ "PartyMemberFrame"..Index ] );
	end]]
end

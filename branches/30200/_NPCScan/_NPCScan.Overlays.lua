--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * _NPCScan.Overlays.lua - Integration with NPC map overlay mods.             *
  ****************************************************************************]]


local L = _NPCScanLocalization;
local _NPCScan = _NPCScan;
local me = CreateFrame( "Frame" );
_NPCScan.Overlays = me;

me.Debug = false; -- Set to true so incompatible hooks will throw real errors

local Loaded = {};
me.Loaded = Loaded;
local Methods = {};
me.Methods = {};

local pairs = pairs;




--[[****************************************************************************
  * Function: _NPCScan.Overlays.SafeCall                                       *
  * Description: Runs potentially bugged code, and prints a friendly error     *
  *   message when incompatible.  Returns true if no error occurs.             *
  ****************************************************************************]]
do
	local function HandleOutput ( Name, Success, ... )
		if ( Success ) then
			return Success, ...;
		else
			local Version = Loaded[ Name:upper() ];
			Loaded[ Name:upper() ] = nil;
			Methods[ Name:upper() ] = nil;
			_NPCScan.Message( L.OVERLAY_INCOMPATIBLE:format( Name, Version and tostring( Version ) or L.OVERLAY_VERSION_UNKNOWN, _NPCScan.Version ), RED_FONT_COLOR );
		end
	end
	local pcall = pcall;
	function me.SafeCall ( Name, Func, ... )
		if ( me.Debug ) then
			return true, Func( ... );
		else
			return HandleOutput( Name, pcall( Func, ... ) );
		end
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlays.Load                                           *
  ****************************************************************************]]
function me.Load ( Name )
	local Data = Methods[ Name:upper() ];
	local Success, Version = me.SafeCall( Name, Data.Initializer );
	Data.Initializer = nil;
	if ( Success ) then
		Loaded[ Name:upper() ] = Version;

		for ID in pairs( _NPCScan.ScanIDs ) do
			if ( not me.SafeCall( Name, Data.Add, ID ) ) then
				break;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlays.Register                                       *
  ****************************************************************************]]
function me.Register ( Name, Initializer, Add, Remove )
	if ( select( 6, GetAddOnInfo( Name ) ) ~= "MISSING" ) then
		Methods[ Name:upper() ] = { Initializer = Initializer; Add = Add; Remove = Remove; };
		if ( IsAddOnLoaded( Name ) ) then
			me.Load( Name );
		end
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlays.Add                                            *
  * Description: Enables overlay maps for a given NPC ID.                      *
  ****************************************************************************]]
function me.Add ( ID )
	for Name in pairs( Loaded ) do
		me.SafeCall( Name, Methods[ Name ].Add, ID );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlays.Remove                                         *
  * Description: Disables overlay maps for a given NPC ID.                     *
  ****************************************************************************]]
function me.Remove ( ID )
	for Name in pairs( Loaded ) do
		me.SafeCall( Name, Methods[ Name ].Remove, ID );
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlays:PLAYER_ENTERING_WORLD                          *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	me.PLAYER_ENTERING_WORLD = nil;

	me.Register( "_NPCScan.Overlay",
		function ()
			return assert( _NPCScan.Overlay.Version );
		end,
		_NPCScan.Overlay.NPCEnable,
		_NPCScan.Overlay.NPCDisable );


	me.Register( "RareSpawnOverlay",
		function ()
			return assert( RareSpawnOverlay.API:GetVersion() );
		end,
		function ( ID )
			RareSpawnOverlay.API:ShowNPC( ID );
		end,
		function ( ID )
			RareSpawnOverlay.API:HideNPC( ID );
		end );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlays:ADDON_LOADED                                   *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	if ( Methods[ AddOn:upper() ] and not Loaded[ AddOn:upper() ] ) then
		me.Load( AddOn );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlays:OnEvent                                        *
  ****************************************************************************]]
me.OnEvent = _NPCScan.OnEvent;




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	me:RegisterEvent( "ADDON_LOADED" );
end

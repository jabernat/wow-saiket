--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.BattlefieldMinimap.lua - Canvas for the                   *
  *   Blizzard_BattlefieldMinimap addon.                                       *
  ****************************************************************************]]


local Overlay = _NPCScan.Overlay;
local me = CreateFrame( "Frame" );
Overlay.BattlefieldMinimap = me;

me.Label = _NPCScanLocalization.OVERLAY.MODULE_BATTLEFIELDMINIMAP;




--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap.Setup                        *
  ****************************************************************************]]
function me.Setup ()
	me.Setup = nil;

	me:SetParent( BattlefieldMinimap );

	-- Inherit standard map update code from WorldMap module
	local WorldMap = Overlay.WorldMap;
	me.Enable = WorldMap.Enable;
	me.Disable = WorldMap.Disable;
	me.Update = WorldMap.Update;
	WorldMap.OnLoad( me );

	me:ClearAllPoints();
	me:SetPoint( "TOPLEFT" );
	local Tile = _G[ "BattlefieldMinimap"..NUM_WORLDMAP_DETAIL_TILES ];
	me:SetPoint( "BOTTOMRIGHT", Tile, -22 / 256 * Tile:GetWidth(), 100 / 256 * Tile:GetHeight() );

	me:Enable();
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:Repaint                      *
  ****************************************************************************]]
do
	local function PaintPath ( NpcID, R, G, B )
		Overlay.PathAdd( me, NpcID, "OVERLAY", R, G, B, 0.8 );
	end
	function me:Repaint ( Map )
		Overlay.ApplyZone( Map, PaintPath );
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:Update                       *
  ****************************************************************************]]
function me:Update ()
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:Disable                      *
  ****************************************************************************]]
function me:Disable ()
	me:UnregisterEvent( "ADDON_LOADED" );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:Enable                       *
  ****************************************************************************]]
do
	local function ADDON_LOADED ( self, Event, AddOn )
		if ( AddOn:lower() == "blizzard_battlefieldminimap" ) then
			me:UnregisterEvent( "ADDON_LOADED" );
			me.Setup();
		end
	end
	function me:Enable ()
		if ( IsAddOnLoaded( "Blizzard_BattlefieldMinimap" ) ) then
			me.Setup();
		else -- Register to wait until it loads
			me:SetScript( "OnEvent", ADDON_LOADED );
			me:RegisterEvent( "ADDON_LOADED" );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	Overlay.ModuleRegister( "BattlefieldMinimap", me );
end

--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.BattlefieldMinimap.lua - Canvas for the                   *
  *   Blizzard_BattlefieldMinimap addon.                                       *
  ****************************************************************************]]


local Overlay = _NPCScan.Overlay;
local me = CreateFrame( "Frame" );
Overlay.BattlefieldMinimap = me;

me.Label = _NPCScanLocalization.OVERLAY.MODULE_BATTLEFIELDMINIMAP;
me.AlphaDefault = 0.8;




--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:Repaint                      *
  ****************************************************************************]]
do
	local function PaintPath ( PathData, FoundX, FoundY, R, G, B, NpcID )
		Overlay.DrawPath( me, PathData, "ARTWORK", R, G, B );
		if ( FoundX ) then
			Overlay.DrawFound( me, FoundX, FoundY, Overlay.DetectionRadius / Overlay.GetZoneSize( Overlay.NPCMaps[ NpcID ] ), "OVERLAY", R, G, B );
		end
	end
	function me:Repaint ( Map )
		Overlay.ApplyZone( Map, PaintPath );
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.BattlefieldMinimap:OnLoad                       *
  ****************************************************************************]]
function me:OnLoad ()
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

	if ( Overlay.Options.Modules[ "BattlefieldMinimap" ] == true ) then
		me:Enable();
		me:Update();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	Overlay.ModuleRegister( "BattlefieldMinimap", me, "Blizzard_BattlefieldMinimap" );
end

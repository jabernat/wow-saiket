--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.Carbonite.lua - Modifies the WorldMap and Minimap modules *
  *   to work with Carbonite.                                                  *
  ****************************************************************************]]


if ( not IsAddOnLoaded( "Carbonite" ) ) then
	return;
end

local Overlay = _NPCScan.Overlay;
local CarboniteMap = NxMap1.NxM1;
local WorldMap = Overlay.WorldMap;
local me = CreateFrame( "Frame", nil, CarboniteMap.Frm );
Overlay.Carbonite = me;




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Carbonite:OnUpdate                              *
  * Description: Repositions the module as the Carbonite map moves.            *
  ****************************************************************************]]
function me:OnUpdate ()
	CarboniteMap:CZF( CarboniteMap.Con, CarboniteMap.Zon, WorldMap, 1 );

	-- Fade the key frame out on mouseover with the rest of the map's buttons
	WorldMap.Key:SetAlpha( NxMap1.NxW.BaF );
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Carbonite:WorldMapFrameOnShow                   *
  * Description: Set up the module to paint to the WorldMapFrame.              *
  ****************************************************************************]]
do
	local KeyPointBackup = "BOTTOMLEFT";
	function me:WorldMapFrameOnShow ()
		me:SetScript( "OnUpdate", nil );

		WorldMap:SetScale( 1 );
		WorldMap:SetParent( WorldMapDetailFrame );
		WorldMap:SetAllPoints();

		local Key = WorldMap.Key;
		Key:SetParent( WorldMap );
		Key:ClearAllPoints();
		Key:SetPoint( KeyPointBackup );
		Key:EnableMouse( true );
		Key:SetAlpha( 1 );

		WorldMap:Update();
	end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Carbonite:WorldMapFrameOnHide                   *
  * Description: Set up the module to paint to Carbonite's map.                *
  ****************************************************************************]]
	function me:WorldMapFrameOnHide ()
		me:SetScript( "OnUpdate", me.OnUpdate );

		WorldMap:SetParent( CarboniteMap.TeF ); -- ScrollChild
		WorldMap:SetAllPoints();

		local Key = WorldMap.Key;
		KeyPointBackup = Key:GetPoint();
		Key:SetParent( CarboniteMap.TeF );
		Key:ClearAllPoints();
		Key:SetPoint( "BOTTOMLEFT", CarboniteMap.Frm );
		Key:EnableMouse( false );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	if ( NxData.NXGOpts.MapMMOwn ) then -- Minimap docked into WorldMap
		Overlay.ModuleUnregister( "Minimap" );
	end


	WorldMap:SetWidth( WorldMapDetailFrame:GetWidth() );
	WorldMap:SetHeight( WorldMapDetailFrame:GetHeight() );

	-- Hooks to swap between Carbonite's map mode and the default UI map mode
	WorldMapFrame:HookScript( "OnShow", me.WorldMapFrameOnShow );
	WorldMapFrame:HookScript( "OnHide", me.WorldMapFrameOnHide );
	me[ WorldMapFrame:IsVisible() and "WorldMapFrameOnShow" or "WorldMapFrameOnHide" ]( me );
end

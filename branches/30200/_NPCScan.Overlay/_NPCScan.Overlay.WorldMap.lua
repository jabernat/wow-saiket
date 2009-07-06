--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.WorldMap.lua - Canvas for the WorldMap.                   *
  ****************************************************************************]]


local Overlay = _NPCScan.Overlay;
local me = CreateFrame( "Frame", nil, WorldMapDetailFrame );
Overlay.WorldMap = me;

me.Label = _NPCScanLocalization.OVERLAY.MODULE_WORLDMAP;
me.Layer = "OVERLAY";




--[[****************************************************************************
  * Function: local MapUpdate                                                  *
  ****************************************************************************]]
local MapUpdate;
do
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );

		local Map = GetMapInfo();
		if ( Map ~= self.MapLast ) then
			self.MapLast = Map;

			Overlay.PolygonSetZone( self, Map, self.Layer );
		end
	end
	function MapUpdate ( self, Force )
		if ( Force ) then
			self.MapLast = nil;
		end
		self:SetScript( "OnUpdate", OnUpdate );
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:OnShow                                 *
  ****************************************************************************]]
function me:OnShow ()
	MapUpdate( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:OnEvent                                *
  ****************************************************************************]]
function me:OnEvent ()
	MapUpdate( self ); -- WORLD_MAP_UPDATE
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:OnLoad                                 *
  ****************************************************************************]]
function me:OnLoad ()
	self:Hide();
	self:SetAllPoints();
	self:SetScript( "OnShow", me.OnShow );
	self:SetScript( "OnEvent", me.OnEvent );
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:Update                                 *
  ****************************************************************************]]
function me:Update ( Map )
	if ( not Map or Map == self.MapLast ) then
		MapUpdate( self, true );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:Disable                                *
  ****************************************************************************]]
function me:Disable ()
	self:UnregisterEvent( "WORLD_MAP_UPDATE" );
	self:Hide();
	Overlay.PolygonRemoveAll( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.WorldMap:Enable                                 *
  ****************************************************************************]]
function me:Enable ()
	self:RegisterEvent( "WORLD_MAP_UPDATE" );
	self:Show();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:OnLoad();
	Overlay.ModuleRegister( "WorldMap", me );
end

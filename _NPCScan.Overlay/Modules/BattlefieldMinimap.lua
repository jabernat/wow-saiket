--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Modules/BattlefieldMinimap.lua - Canvas for Blizzard_BattlefieldMinimap.   *
  ****************************************************************************]]


local Overlay = select( 2, ... );
local me = Overlay.Modules.WorldMapTemplate.Embed( CreateFrame( "Frame" ) );

me.AlphaDefault = 0.8;




--- Attaches the canvas to the zone map when it loads.
function me:OnLoad ( ... )
	self:SetParent( BattlefieldMinimap );

	return self.super.OnLoad( self, ... );
end




Overlay.Modules.Register( "BattlefieldMinimap", me,
	Overlay.L.MODULE_BATTLEFIELDMINIMAP,
	"Blizzard_BattlefieldMinimap" );
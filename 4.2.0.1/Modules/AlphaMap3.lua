--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Modules/AlphaMap3.lua - Canvas for the AlphaMap3 addon.                    *
  ****************************************************************************]]


local Overlay = select( 2, ... );
local me = Overlay.Modules.WorldMapTemplate.Embed( CreateFrame( "Frame" ) );

me.AlphaDefault = 0.8;




--- Attaches the canvas to AlphaMap's custom frame when it loads.
function me:OnLoad ( ... )
	self:SetParent( AlphaMapDetailFrame );

	return self.super.OnLoad( self, ... );
end




Overlay.Modules.Register( "AlphaMap3", me,
	Overlay.L.MODULE_ALPHAMAP3,
	"AlphaMap3" );
--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.Mapster.lua - Adjusts WorldMap module with Mapster.       *
  ****************************************************************************]]


--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

if ( IsAddOnLoaded( "Mapster" ) ) then
	hooksecurefunc( LibStub( "AceAddon-3.0" ):GetAddon( "Mapster" ), "SetupMapButton", function ()
		local Toggle = _NPCScan.Overlay.WorldMap.Toggle;

		Toggle:ClearAllPoints();
		Toggle:SetPoint( "LEFT", MapsterOptionsButton, "RIGHT", 8, 0 );
	end );
end

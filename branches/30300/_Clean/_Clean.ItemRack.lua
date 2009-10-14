--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.ItemRack.lua - Modifies the ItemRack addon's minimap icon.          *
  ****************************************************************************]]




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

if ( select( 6, GetAddOnInfo( "ItemRack" ) ) ~= "MISSING"
	and not IsAddOnLoaded( "Carbonite" )
) then
	_Clean.RegisterAddOnInitializer( "ItemRack", function ()
		ItemRackMinimapFrame:RegisterForDrag();
		ItemRackMinimapFrame:DisableDrawLayer( "ARTWORK" );
		ItemRackMinimapFrame:DisableDrawLayer( "OVERLAY" );
		ItemRackMinimapFrame:ClearAllPoints();
		ItemRackMinimapFrame:SetPoint( "TOPLEFT", Minimap, "TOPLEFT" );
		ItemRackMinimapFrame:SetWidth( 14 );
		ItemRackMinimapFrame:SetHeight( 14 );
		ItemRackMinimapIcon:SetAllPoints( ItemRackMinimapFrame );
		_Clean.RemoveButtonIconBorder( ItemRackMinimapIcon );
		ItemRackMinimapIcon.SetTexCoord = _Clean.NilFunction;
		ItemRackMinimapFrame.SetPoint = _Clean.NilFunction;

		local Background = _Clean.Colors.Background;
		local Highlight = _Clean.Colors.Highlight;
		ItemRackMinimapIcon:SetGradientAlpha( "VERTICAL", Highlight.r, Highlight.g, Highlight.b, Highlight.a, Background.r, Background.g, Background.b, Background.a );
	end );
end

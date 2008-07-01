--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.ItemRack.lua - Modifies the ItemRack addon.                         *
  *                                                                            *
  * + Repositions the minimap icon.                                            *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {
	SetTitles = {
		[ "1.Heal" ]  = 36; -- Champion of the Naaru
		[ "2.Shock" ] = 39; -- Hand of A'dal
		[ "3.Tank" ]  =  6; -- Knight
	};
};
_Clean.ItemRack = me;




--[[****************************************************************************
  * Function: _Clean.ItemRack.EquipSet                                         *
  * Description: Changes the player's title when swapping sets.  Unspecified   *
  *   sets will clear the title.                                               *
  ****************************************************************************]]
function me.EquipSet ( SetName )
	SetCurrentTitle( me.SetTitles[ SetName ] or -1 );
end


--[[****************************************************************************
  * Function: _Clean.ItemRack.OnLoad                                           *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	ItemRackMinimapFrame:RegisterForDrag();
	ItemRackMinimapFrame:DisableDrawLayer( "OVERLAY" );
	_Clean.ClearAllPoints( ItemRackMinimapFrame );
	_Clean.SetPoint( ItemRackMinimapFrame, "TOPLEFT", Minimap, "TOPLEFT", 1, -1 );
	ItemRackMinimapFrame:SetWidth( 14 );
	ItemRackMinimapFrame:SetHeight( 14 );
	ItemRackMinimapFrame:SetAlpha( 0.6 );
	_Clean.SetAllPoints( ItemRackMinimapIcon, ItemRackMinimapFrame );
	_Clean.RemoveButtonIconBorder( ItemRackMinimapIcon );
	ItemRackMinimapIcon.SetTexCoord = _Clean.NilFunction;
	ItemRackMinimapFrame.SetPoint = _Clean.NilFunction;

	hooksecurefunc( ItemRack, "EquipSet", me.EquipSet );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "ItemRack", me.OnLoad );
end

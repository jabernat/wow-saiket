--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.ItemRack.lua - Modifies the ItemRack addon.                          *
  *                                                                            *
  * + Changes your character's title based on the set you wear.                *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {
	SetTitles = {
		[ "1.Heal" ]  = 98; -- Ambassador
		[ "2.Shock" ] = 39; -- Hand of A'dal
		[ "3.Tank" ]  =  6; -- Knight
		[ "Ashbringer" ] = 6; -- Knight
	};
};
_Misc.ItemRack = me;




--[[****************************************************************************
  * Function: _Misc.ItemRack.EquipSet                                          *
  * Description: Changes the player's title when swapping sets.  Unspecified   *
  *   sets will clear the title.                                               *
  ****************************************************************************]]
function me.EquipSet ( SetName )
	SetCurrentTitle( me.SetTitles[ SetName ] or -1 );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "ItemRack", function ()
		hooksecurefunc( ItemRack, "EquipSet", me.EquipSet );
	end );
end

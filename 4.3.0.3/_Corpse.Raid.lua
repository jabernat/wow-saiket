--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Raid.lua - Uses raid member data to get corpse info.               *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local NS = {};
_Corpse.Raid = NS;




--- Returns an iterator for all raid UnitIDs.
function NS:IterateUnitIDs ()
	-- Last ID is always player, so skip it
	return _Corpse.NextUnitID, "raid", GetNumRaidMembers() - 1;
end
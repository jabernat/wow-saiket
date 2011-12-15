--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Party.lua - Uses party member data to get corpse info.             *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local NS = {};
_Corpse.Party = NS;




--- Returns an iterator for all party UnitIDs.
function NS:IterateUnitIDs ()
	return _Corpse.NextUnitID, "party", GetNumPartyMembers();
end
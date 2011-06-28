--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Dungeons.lua - Uses party member data to get corpse info.          *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local me = {};
_Corpse.Dungeons = me;




--- Populates the corpse tooltip for the given player using party member data.
function me:Update ( Name )
	for Index = 1, GetNumPartyMembers() do
		local UnitID = "party"..Index;

		if ( Name == UnitName( UnitID ) ) then
			_Corpse.BuildCorpseTooltip( false, Name,
				UnitLevel( UnitID ), UnitClass( UnitID ), GetRealZoneText(), UnitIsConnected( UnitID ),
				( UnitIsAFK( UnitID ) and CHAT_FLAG_AFK ) or ( UnitIsDND( UnitID ) and CHAT_FLAG_DND ) );
			return;
		end
	end
end
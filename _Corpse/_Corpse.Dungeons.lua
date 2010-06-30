--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Dungeons.lua - Uses party member data to get corpse info.          *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local L = _Corpse.L;
local me = {};
_Corpse.Dungeons = me;




--- Populates the corpse tooltip for the given player using party member data.
function me:Update ( Name, Server )
	for Index = 1, GetNumPartyMembers() do
		local UnitID = "party"..Index;
		local NameParty, ServerParty = UnitName( UnitID );

		if ( Name == NameParty and ( not Server or Server == ServerParty ) ) then
			_Corpse.BuildCorpseTooltip( false, GetUnitName( UnitID, true ), -- Includes server name
				UnitLevel( UnitID ), UnitClass( UnitID ), GetRealZoneText(), UnitIsConnected( UnitID ),
				( UnitIsAFK( UnitID ) and CHAT_FLAG_AFK ) or ( UnitIsDND( UnitID ) and CHAT_FLAG_DND ) );
			return;
		end
	end
end
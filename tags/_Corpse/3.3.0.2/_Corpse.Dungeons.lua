--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Dungeons.lua - Uses party member data to get corpse info.          *
  ****************************************************************************]]


local L = _CorpseLocalization;
local _Corpse = _Corpse;
local me = {};
_Corpse.Dungeons = me;




--[[****************************************************************************
  * Function: _Corpse.Dungeons:Update                                          *
  ****************************************************************************]]
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

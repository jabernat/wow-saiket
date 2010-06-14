--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battlegrounds.lua - Uses the BG scoreboard to get corpse info.     *
  ****************************************************************************]]


local L = _CorpseLocalization;
local _Corpse = _Corpse;
local me = CreateFrame( "Frame", nil, _Corpse );
_Corpse.Battlegrounds = me;

me.RequestBattlefieldScoreDataLast = 0;

me.UpdateInterval = 5; -- Seconds




--[[****************************************************************************
  * Function: _Corpse.Battlegrounds.RequestBattlefieldScoreData                *
  * Description: Hook to keep track of when score was last updated.            *
  ****************************************************************************]]
function me.RequestBattlefieldScoreData ()
	me.RequestBattlefieldScoreDataLast = GetTime();
end
--[[****************************************************************************
  * Function: _Corpse.Battlegrounds.GetBattlefieldInfo                         *
  * Description: Scans the scoreboard for a given player.                      *
  ****************************************************************************]]
function me.GetBattlefieldInfo ( Name, Server )
	local NameServerBG, NameBG, ServerBG, Faction, Race, Class, _;
	for Index = 1, GetNumBattlefieldScores() do
		NameServerBG, _, _, _, _, Faction, _, Race, Class = GetBattlefieldScore( Index );
		NameBG, ServerBG = L.SERVER_DELIMITER:split( NameServerBG );

		if ( Name == NameBG and ( not Server or Server == ServerBG ) ) then
			-- Score can be 0 = Horde, 1 = Alliance
			local FactionPlayer = UnitFactionGroup( "player" ) == "Alliance" and 1 or 0;
			return Faction ~= FactionPlayer, NameServerBG, nil, Class, nil, 1;
		end
	end
end




--[[****************************************************************************
  * Function: _Corpse.Battlegrounds:UPDATE_BATTLEFIELD_SCORE                   *
  * Description: Called when cached score data is updated.                     *
  ****************************************************************************]]
function me:UPDATE_BATTLEFIELD_SCORE ()
	local Name, Server = _Corpse.GetCorpseName();
	if ( Name and Name ~= UnitName( "player" ) ) then -- Found corpse tooltip
		_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name, Server ) );
	end
end




--[[****************************************************************************
  * Function: _Corpse.Battlegrounds:Update                                     *
  ****************************************************************************]]
function me:Update ( Name, Server )
	local PlayerName = UnitName( "player" );
	if ( Name == PlayerName ) then -- Our own corpse
		_Corpse.BuildCorpseTooltip( false, PlayerName,
			UnitLevel( "player" ), UnitClass( "player" ), GetRealZoneText(), 1,
			( UnitIsAFK( "player" ) and CHAT_FLAG_AFK ) or ( UnitIsDND( "player" ) and CHAT_FLAG_DND ) );
	else
		if ( GetTime() - self.RequestBattlefieldScoreDataLast > self.UpdateInterval ) then
			RequestBattlefieldScoreData();
		end
		_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name, Server ) );
	end
end
--[[****************************************************************************
  * Function: _Corpse.Battlegrounds:Enable                                     *
  ****************************************************************************]]
function me:Enable ()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end
--[[****************************************************************************
  * Function: _Corpse.Battlegrounds:Disable                                    *
  ****************************************************************************]]
function me:Disable ()
	self:UnregisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end




me:SetScript( "OnEvent", _Corpse.OnEvent );

hooksecurefunc( "RequestBattlefieldScoreData", me.RequestBattlefieldScoreData );
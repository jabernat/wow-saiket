--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battlegrounds.lua - Uses the BG scoreboard to get corpse info.     *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local L = _Corpse.L;
local me = CreateFrame( "Frame" );
_Corpse.Battlegrounds = me;

me.RequestBattlefieldScoreDataLast = 0;

me.UpdateInterval = 5; -- Seconds




--- Hook to keep track of when score was last updated.
function me.RequestBattlefieldScoreData ()
	me.RequestBattlefieldScoreDataLast = GetTime();
end
--- Scans the scoreboard for a given player.
-- @return Arguments for BuildCorpseTooltip, similar to GetFriendInfo.
-- @see _Corpse.BuildCorpseTooltip
function me.GetBattlefieldInfo ( Name, Server )
	local NameServerBG, NameBG, ServerBG, Faction, Race, Class, _;
	for Index = 1, GetNumBattlefieldScores() do
		NameServerBG, _, _, _, _, Faction, _, Race, Class = GetBattlefieldScore( Index );
		NameBG, ServerBG = ( "-" ):split( NameServerBG );

		if ( Name == NameBG and ( not Server or Server == ServerBG ) ) then
			-- Score can be 0 = Horde, 1 = Alliance
			local FactionPlayer = UnitFactionGroup( "player" ) == "Alliance" and 1 or 0;
			return Faction ~= FactionPlayer, NameServerBG, nil, Class, nil, 1;
		end
	end
end


--- Called when cached score data is updated.
function me:UPDATE_BATTLEFIELD_SCORE ()
	local Name, Server = _Corpse.GetCorpseName();
	if ( Name and Name ~= UnitName( "player" ) ) then -- Found corpse tooltip
		_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name, Server ) );
	end
end


--- Populates the corpse tooltip for the given player using BG scoreboard data.
function me:Update ( Name, Server )
	if ( GetTime() - self.RequestBattlefieldScoreDataLast > self.UpdateInterval ) then
		RequestBattlefieldScoreData();
	end
	_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name, Server ) );
end
--- Initialize the module when activated.
function me:Enable ()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end
--- Uninitialize the module when deactivated.
function me:Disable ()
	self:UnregisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end




me:SetScript( "OnEvent", _Corpse.Frame.OnEvent );

hooksecurefunc( "RequestBattlefieldScoreData", me.RequestBattlefieldScoreData );
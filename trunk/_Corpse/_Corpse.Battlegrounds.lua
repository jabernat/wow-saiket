--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battlegrounds.lua - Uses the BG scoreboard to get corpse info.     *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
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
function me.GetBattlefieldInfo ( Name )
	for Index = 1, GetNumBattlefieldScores() do
		local NameBG, _, _, _, _, Faction, _, Race, Class = GetBattlefieldScore( Index );
		NameBG = NameBG:match( "^[^-]+" ); -- Discard server name

		if ( Name == NameBG ) then
			-- Score can be 0 = Horde, 1 = Alliance
			local FactionPlayer = UnitFactionGroup( "player" ) == "Alliance" and 1 or 0;
			return Faction ~= FactionPlayer, Name, nil, Class, nil, 1;
		end
	end
end


--- Called when cached score data is updated.
function me:UPDATE_BATTLEFIELD_SCORE ()
	local Name = _Corpse.GetCorpseName();
	if ( Name and Name ~= UnitName( "player" ) ) then -- Found corpse tooltip
		_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name ) );
	end
end


--- Populates the corpse tooltip for the given player using BG scoreboard data.
function me:Update ( Name )
	if ( GetTime() - self.RequestBattlefieldScoreDataLast > self.UpdateInterval ) then
		RequestBattlefieldScoreData();
	end
	_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name ) );
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
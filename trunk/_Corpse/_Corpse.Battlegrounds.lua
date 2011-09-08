--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battlegrounds.lua - Uses the BG scoreboard to get corpse info.     *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local NS = CreateFrame( "Frame" );
_Corpse.Battlegrounds = NS;

NS.RequestBattlefieldScoreDataLast = 0;

NS.UpdateInterval = 5; -- Seconds




--- Hook to keep track of when score was last updated.
function NS.RequestBattlefieldScoreData ()
	NS.RequestBattlefieldScoreDataLast = GetTime();
end
--- Scans the scoreboard for a given player.
-- @return Arguments for BuildCorpseTooltip, similar to GetFriendInfo.
-- @see _Corpse.BuildCorpseTooltip
function NS.GetBattlefieldInfo ( Name )
	for Index = 1, GetNumBattlefieldScores() do
		local NameBG, _, _, _, _, Faction, _, Class = GetBattlefieldScore( Index );
		NameBG = NameBG:match( "^[^-]+" ); -- Discard server name

		if ( Name == NameBG ) then
			-- Score can be 0 = Horde, 1 = Alliance
			local FactionPlayer = UnitFactionGroup( "player" ) == "Alliance" and 1 or 0;
			return Faction ~= FactionPlayer, Name, nil, Class, nil, 1;
		end
	end
end


--- Called when cached score data is updated.
function NS:UPDATE_BATTLEFIELD_SCORE ()
	local Name = _Corpse.GetCorpseName();
	if ( Name and Name ~= UnitName( "player" ) ) then -- Found corpse tooltip
		_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name ) );
	end
end


--- Populates the corpse tooltip for the given player using BG scoreboard data.
function NS:Update ( Name )
	if ( GetTime() - self.RequestBattlefieldScoreDataLast > self.UpdateInterval ) then
		RequestBattlefieldScoreData();
	end
	_Corpse.BuildCorpseTooltip( self.GetBattlefieldInfo( Name ) );
end
--- Initialize the module when activated.
function NS:Enable ()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end
--- Uninitialize the module when deactivated.
function NS:Disable ()
	self:UnregisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end




NS:SetScript( "OnEvent", _Corpse.Frame.OnEvent );

hooksecurefunc( "RequestBattlefieldScoreData", NS.RequestBattlefieldScoreData );
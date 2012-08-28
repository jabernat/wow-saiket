--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battleground.lua - Uses the BG scoreboard to get corpse info.      *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local NS = CreateFrame( "Frame" );
_Corpse.Battleground = NS;

local MIN_REQUEST_INTERVAL = 5; -- Seconds to keep cached scoreboard data




--- Scans the scoreboard for a given player.
-- @return Arguments for BuildTooltip, similar to GetFriendInfo.
-- @see _Corpse:BuildTooltip
function NS:GetBattlefieldInfo ( Name )
	local FactionPlayer = GetBattlefieldArenaFaction();
	for Index = 1, GetNumBattlefieldScores() do
		local NameServer, _, _, _, _, Faction, _, Class = GetBattlefieldScore( Index );
		local NameBG = NameServer:match( "^[^-]+" ); -- Discard server name

		if ( Name == NameBG ) then
			local Hostile = Faction ~= FactionPlayer;
			if ( Hostile or _Corpse:UnitHasCorpse( NameServer ) ) then -- Ignore name matches for living allies
				local Connected, Level, Status = 1;
				if ( not Hostile ) then -- Get extra details for allies in raid
					Level, Connected = UnitLevel( NameServer ), UnitIsConnected( NameServer ) and 1 or 0;
					Status = PlayerIsPVPInactive( NameServer ) and CHAT_FLAG_AFK;
				end
				return Hostile, Name, Level, Class, GetRealZoneText(), Connected, Status;
			end
		end
	end
end


--- Called when cached score data is updated.
function NS:UPDATE_BATTLEFIELD_SCORE ()
	local Name = _Corpse:GetCorpseName();
	if ( Name and Name ~= UnitName( "player" ) ) then -- Found corpse tooltip
		_Corpse:BuildTooltip( self:GetBattlefieldInfo( Name ) );
	end
end


do
	local LastRequest = 0;
	--- Hook to keep track of when score was last updated.
	hooksecurefunc( "RequestBattlefieldScoreData", function ()
		LastRequest = GetTime();
	end );
	--- Populates the corpse tooltip for the given player using BG scoreboard data.
	function NS:Update ( Name )
		if ( GetTime() - LastRequest > MIN_REQUEST_INTERVAL ) then
			RequestBattlefieldScoreData();
		end
		_Corpse:BuildTooltip( self:GetBattlefieldInfo( Name ) );
	end
end
--- Initialize the module when activated.
function NS:OnEnable ()
	SetBattlefieldScoreFaction( nil ); -- Clear faction filter
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end
--- Uninitialize the module when deactivated.
function NS:OnDisable ()
	self:UnregisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end




NS:SetScript( "OnEvent", _Corpse.Frame.OnEvent );
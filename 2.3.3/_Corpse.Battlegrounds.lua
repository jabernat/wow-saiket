--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Battlegrounds.lua - Update handler for battlegrounds that reads    *
  *   information directly from the scoreboard.                                *
  ****************************************************************************]]


local _Corpse = _Corpse;
local L = _CorpseLocalization;
local me = {};
_Corpse.Battlegrounds = me;

me.Enabled = false;
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
		_Corpse.BuildCorpseTooltip( me.GetBattlefieldInfo( Name, Server ) );
	end
end


--[[****************************************************************************
  * Function: _Corpse.Battlegrounds:OnUpdate                                   *
  * Description: Global update handler for battlegrounds.                      *
  ****************************************************************************]]
function me:OnUpdate ()
	local Name, Server = _Corpse.GetCorpseName();
	if ( Name ) then -- Found corpse tooltip

		local PlayerName = UnitName( "player" );
		if ( Name == PlayerName ) then -- Our own corpse
			_Corpse.BuildCorpseTooltip( false, PlayerName,
				UnitLevel( "player" ), UnitClass( "player" ), GetRealZoneText(), 1,
				( UnitIsAFK( "player" ) and L.AFK ) or ( UnitIsDND( "player" ) and L.DND ) );
		else
			if ( GetTime() - me.RequestBattlefieldScoreDataLast > me.UpdateInterval ) then
				RequestBattlefieldScoreData();
			end
			_Corpse.BuildCorpseTooltip( me.GetBattlefieldInfo( Name, Server ) );
		end
	end

	_Corpse:Hide();
end




--[[****************************************************************************
  * Function: _Corpse.Battlegrounds.Enable                                     *
  * Description: Enables events and hooks.                                     *
  ****************************************************************************]]
function me.Enable ()
	if ( not me.Enabled ) then
		me.Enabled = true;

		_Corpse.Disable();
		_Corpse:Hide();
		_Corpse:SetScript( "OnUpdate", me.OnUpdate );

		_Corpse:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );

		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.Battlegrounds.Disable                                    *
  * Description: Disables events and hooks.                                    *
  ****************************************************************************]]
function me.Disable ()
	if ( me.Enabled ) then
		me.Enabled = false;

		_Corpse:Hide();
		_Corpse:SetScript( "OnUpdate", nil );

		_Corpse:UnregisterEvent( "UPDATE_BATTLEFIELD_SCORE" );

		return true;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Corpse.UPDATE_BATTLEFIELD_SCORE = me.UPDATE_BATTLEFIELD_SCORE;

	hooksecurefunc( "RequestBattlefieldScoreData", me.RequestBattlefieldScoreData );
end

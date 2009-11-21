--[[****************************************************************************
  * _Clean.Chat by Saiket                                                      *
  * _Clean.Chat.RaidWarning.lua - Adds author names to raid warnings.          *
  ****************************************************************************]]


local L = _CleanLocalization.Chat;
local _Clean = _Clean;
local me = {};
_Clean.Chat.RaidWarning = me;




--[[****************************************************************************
  * Function: _Clean.Chat.RaidWarning:OnEvent                                  *
  ****************************************************************************]]
do
	local Backup = RaidWarningFrame:GetScript( "OnEvent" );
	function me:OnEvent ( Event, Message, Author, ... )
		if ( Author ) then
			local Color = RAID_CLASS_COLORS[ select( 2, GetPlayerInfoByGUID( select( 10, ... ) ) ) ];

			Message = L.RAIDWARNING_FORMAT:format( Color.r * 255, Color.g * 255, Color.b * 255, Author, Message );
		end
		return Backup( self, Event, Message, Author, ... );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	RaidWarningFrame:SetScript( "OnEvent", me.OnEvent );
end

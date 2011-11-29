--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.RaidWarning.lua - Adds author names to raid warnings.     *
  ****************************************************************************]]


local L = select( 2, ... ).L;


local Backup = RaidWarningFrame:GetScript( "OnEvent" );
--- Adds a class-colored author name to raid warning messages.
local function OnEvent ( self, Event, Message, Author, ... )
	if ( Author ) then
		local Color = RAID_CLASS_COLORS[ select( 2, GetPlayerInfoByGUID( select( 10, ... ) ) ) ];
		Message = L.RAIDWARNING_FORMAT:format( Color.r * 255, Color.g * 255, Color.b * 255, Author, Message );
	end
	return Backup( self, Event, Message, Author, ... );
end

RaidWarningFrame:SetScript( "OnEvent", OnEvent );
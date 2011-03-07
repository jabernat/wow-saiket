--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.CombatLogDisable.lua - Doesn't load the default UI's      *
  *   combat log if _Underscore.Chat.CombatLog is explicitly disabled.         *
  ****************************************************************************]]


local Reason = select( 6, GetAddOnInfo( "_Underscore.Chat.CombatLog" ) );
if ( Reason == "DISABLED" ) then
	CombatLog_LoadUI = _Underscore.NilFunction;

	-- Prevent the chat config window from breaking because combat log settings are missing
	ChatConfigFrame:SetScript( "OnShow", nil );
end
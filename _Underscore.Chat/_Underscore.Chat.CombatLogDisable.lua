--[[****************************************************************************
  * _Underscore.Chat by Saiket                                                 *
  * _Underscore.Chat.CombatLogDisable.lua - Doesn't load the default UI's      *
  *   combat log if _Underscore.Chat.CombatLog is explicitly disabled.         *
  ****************************************************************************]]


local Loadable, Reason = select( 5, GetAddOnInfo( "_Underscore.Chat.CombatLog" ) );
if ( Reason == "DISABLED" ) then
	-- Prevents Blizzard_CombatLog from loading
	UIParent:UnregisterEvent( "PLAYER_LOGIN" );

	-- Prevent the chat config window from breaking because combat log settings are missing
	ChatConfigFrame:SetScript( "OnShow", nil );
elseif ( not Loadable ) then
	-- Hook to keep the combat log chat frame in place
	hooksecurefunc( "FCF_DockUpdate", function ()
		if ( IsAddOnLoaded( "Blizzard_CombatLog" ) ) then
			_G[ COMBATLOG:GetName().."Background" ]:SetPoint( "TOPLEFT", -2, 3 );
		end
	end );
end
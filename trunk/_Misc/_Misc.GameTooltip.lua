--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.GameTooltip.lua - Modifies the main tooltip frame.                   *
  *                                                                            *
  * + Adds players' guild names to their unit tooltips.                        *
  ****************************************************************************]]


local _Misc = _Misc;
local L = _MiscLocalization;
local me = {};
_Misc.GameTooltip = me;




--[[****************************************************************************
  * Function: _Misc.GameTooltip.UpdateUnitGuild                                *
  * Description: Add guild names to the right of the character's name.         *
  ****************************************************************************]]
function me:UpdateUnitGuild ()
	local Unit = select( 2, self:GetUnit() );
	if ( Unit and UnitExists( Unit ) and UnitIsPlayer( Unit ) ) then
		local GuildName = GetGuildInfo( Unit );
		if ( GuildName ) then
			local Text = _G[ self:GetName().."TextLeft2" ];
			Text:SetFormattedText( L.GAMETOOLTIP_GUILD_FORMAT, GuildName );
			Text:SetTextColor( GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b );
			_Misc.RunProtectedMethod( self, "Show" ); -- Automatically resize
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.HookScript( GameTooltip, "OnTooltipSetUnit", me.UpdateUnitGuild );
	_Misc.HookScript( ItemRefTooltip, "OnTooltipSetUnit", me.UpdateUnitGuild );
end

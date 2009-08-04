--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.GameTooltip.lua - Modifies the tooltip frames.                       *
  *                                                                            *
  * + Adds players' guild names to their unit tooltips.                        *
  * + Adds the icon of items and spells to the left of ItemRefTooltip.         *
  ****************************************************************************]]


local _Misc = _Misc;
local L = _MiscLocalization;
local me = {
	ItemRefTooltip = {
		Icon = ItemRefTooltip:CreateTexture( nil, "ARTWORK" );
	};
};
_Misc.GameTooltip = me;




--[[****************************************************************************
  * Function: _Misc.GameTooltip.UpdateUnitGuild                                *
  * Description: Add guild names to the right of the character's name.         *
  ****************************************************************************]]
function me:UpdateUnitGuild ( UnitID )
	if ( UnitExists( UnitID ) and UnitIsPlayer( UnitID ) ) then
		local GuildName = GetGuildInfo( UnitID );
		if ( GuildName ) then
			local Text = _G[ self:GetName().."TextLeft2" ];
			Text:SetFormattedText( L.GAMETOOLTIP_GUILD_FORMAT, GuildName );
			Text:SetTextColor( GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b );
			self:AppendText( "" ); -- Automatically resize
		end
	end
end

--[[****************************************************************************
  * Function: _Misc.GameTooltip:OnTooltipSetUnit                               *
  * Description: Hooks a tooltip to update its contents when set.              *
  ****************************************************************************]]
function me:OnTooltipSetUnit ()
	local UnitID = select( 2, self:GetUnit() );
	if ( UnitID ) then
		me.UpdateUnitGuild( self, UnitID );
	end
end
--[[****************************************************************************
  * Function: _Misc.GameTooltip:SetUnit                                        *
  * Description: Updates the tooltip's guild info if the unit isn't IDed.      *
  ****************************************************************************]]
function me:SetUnit ( ActualUnitID )
	local UnitID = select( 2, self:GetUnit() );
	if ( not UnitID ) then
		me.UpdateUnitGuild( self, ActualUnitID );
	end
end
--[[****************************************************************************
  * Function: _Misc.GameTooltip:RegisterTooltip                                *
  * Description: Hooks a tooltip to update its contents when set.              *
  ****************************************************************************]]
function me:RegisterTooltip ()
	self:HookScript( "OnTooltipSetUnit", me.OnTooltipSetUnit );
	hooksecurefunc( self, "SetUnit", me.SetUnit );
end




--[[****************************************************************************
  * Function: _Misc.GameTooltip.ItemRefTooltip.SetHyperlink                    *
  * Description: Updates the new item icon texture to match the tooltip.       *
  ****************************************************************************]]
function me.ItemRefTooltip:SetHyperlink ( Link )
	local Texture = nil;
	if ( self:IsShown() ) then
		if ( Link:match( "^item:" ) ) then
			Texture = GetItemIcon( Link );
		else
			local ID = Link:match( "^spell:(%d+)" );
			if ( ID ) then
				Texture = select( 3, GetSpellInfo( ID ) );
			else
				ID = Link:match( "^achievement:(%d+)" );
				if ( ID ) then
					Texture = select( 10, GetAchievementInfo( ID ) );
				end
			end
		end
	end
	me.ItemRefTooltip.Icon:SetTexture( Texture );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.RegisterTooltip( GameTooltip );
	me.RegisterTooltip( ItemRefTooltip );

	-- Generate the new ItemRefTooltip icon texture
	me.ItemRefTooltip.Icon:SetWidth( 36 );
	me.ItemRefTooltip.Icon:SetHeight( 36 );
	me.ItemRefTooltip.Icon:SetPoint( "TOPRIGHT", ItemRefTooltip, "TOPLEFT", 2, -2 );

	hooksecurefunc( ItemRefTooltip, "SetHyperlink", me.ItemRefTooltip.SetHyperlink );
end

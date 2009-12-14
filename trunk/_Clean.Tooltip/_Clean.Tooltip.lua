--[[****************************************************************************
  * _Clean.Tooltip by Saiket                                                   *
  * _Clean.Tooltip.lua - Modifies the tooltip frames.                          *
  ****************************************************************************]]


-- NOTE(Add class icons to the main gametooltip, and then skin tooltip frames.)
local L = _CleanLocalization.Tooltip;
local _Clean = _Clean;
local me = {};
_Clean.Tooltip = me;

local IconSize = 32;




--[[****************************************************************************
  * Function: _Clean.Tooltip:SetDefaultAnchor                                  *
  * Description: Moves the default tooltip position to the top center.         *
  ****************************************************************************]]
function me:SetDefaultAnchor ()
	self:ClearAllPoints();
	self:SetPoint( "TOP", _Clean.TopMargin, "BOTTOM", 0, 4 );
end




--[[****************************************************************************
  * Function: _Clean.Tooltip.UpdateUnitGuild                                   *
  * Description: Add guild names to the right of the character's name.         *
  ****************************************************************************]]
function me:UpdateUnitGuild ( UnitID )
	if ( UnitExists( UnitID ) and UnitIsPlayer( UnitID ) ) then
		local GuildName = GetGuildInfo( UnitID );
		if ( GuildName ) then
			local Text = _G[ self:GetName().."TextLeft2" ];
			Text:SetFormattedText( L.GUILD_FORMAT, GuildName );
			Text:SetTextColor( GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b );
			self:AppendText( "" ); -- Automatically resize
		end
	end
end

--[[****************************************************************************
  * Function: _Clean.Tooltip:OnTooltipSetUnit                                  *
  * Description: Hooks a tooltip to update its contents when set.              *
  ****************************************************************************]]
function me:OnTooltipSetUnit ()
	local UnitID = select( 2, self:GetUnit() );
	if ( UnitID ) then
		me.UpdateUnitGuild( self, UnitID );
	end
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:SetUnit                                           *
  * Description: Updates the tooltip's guild info if the unit isn't IDed.      *
  ****************************************************************************]]
function me:SetUnit ( ActualUnitID )
	local UnitID = select( 2, self:GetUnit() );
	if ( not UnitID ) then -- OnTooltipSetUnit can't handle this case
		me.UpdateUnitGuild( self, ActualUnitID );
	end
end


--[[****************************************************************************
  * Function: _Clean.Tooltip:RegisterGuild                                     *
  ****************************************************************************]]
function me:RegisterGuild ()
	self:HookScript( "OnTooltipSetUnit", me.OnTooltipSetUnit );
	hooksecurefunc( self, "SetUnit", me.SetUnit );
end




--[[****************************************************************************
  * Function: _Clean.Tooltip:SetHyperlink                                      *
  * Description: Updates the new item icon texture to match the tooltip.       *
  ****************************************************************************]]
function me:SetHyperlink ( Link )
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
	self.Icon:SetTexture( Texture );
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:RegisterIcon                                      *
  ****************************************************************************]]
function me:RegisterIcon ()
	self.Icon = self:CreateTexture( nil, "ARTWORK" );
	self.Icon:SetWidth( IconSize );
	self.Icon:SetHeight( IconSize );
	self.Icon:SetPoint( "TOPRIGHT", self, "TOPLEFT", 2, -2 );

	hooksecurefunc( self, "SetHyperlink", me.SetHyperlink );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.SetDefaultAnchor );

	me.RegisterGuild( GameTooltip );
	me.RegisterGuild( ItemRefTooltip );
	me.RegisterIcon( ItemRefTooltip );
end

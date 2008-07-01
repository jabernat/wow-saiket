--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.ItemRefTooltip.lua - This alters the item tooltip that appears when  *
  *   a link is clicked in a chat window.                                      *
  *                                                                            *
  * + Adds the icon of the item to the left of the tooltip.                    *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {
	Icon = ItemRefTooltip:CreateTexture( nil, "ARTWORK" );
};
_Misc.ItemRefTooltip = me;




--[[****************************************************************************
  * Function: _Misc.ItemRefTooltip.SetHyperlink                                *
  * Description: Updates the new item icon texture to match the tooltip.       *
  ****************************************************************************]]
function me:SetHyperlink ( Link )
	local Texture = nil;
	if ( self:IsShown() ) then
		if ( Link:find( "^item:" ) ) then
			Texture = GetItemIcon( Link );
		else
			local ID = select( 3, Link:find( "^spell:(%d+)" ) );
			if ( ID ) then
				Texture = select( 3, GetSpellInfo( ID ) );
			end
		end
	end
	me.Icon:SetTexture( Texture );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Generate the new icon texture
	me.Icon:SetWidth( 36 );
	me.Icon:SetHeight( 36 );
	me.Icon:SetPoint( "TOPRIGHT", ItemRefTooltip, "TOPLEFT", 2, -2 );

	hooksecurefunc( ItemRefTooltip, "SetHyperlink", me.SetHyperlink );
end

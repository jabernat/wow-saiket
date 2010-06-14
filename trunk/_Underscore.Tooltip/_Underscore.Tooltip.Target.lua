--[[****************************************************************************
  * _Underscore.Tooltip by Saiket                                              *
  * _Underscore.Tooltip.Target.lua - Adds a mouseover target tooltip.          *
  ****************************************************************************]]


local me = CreateFrame( "GameTooltip", "_UnderscoreTooltipTarget", GameTooltip, "GameTooltipTemplate" );
_Underscore.Tooltip.Target = me;

me.UpdateRate = 0.5;




--[[****************************************************************************
  * Function: _Underscore.Tooltip.Target:OnTooltipSetUnit                      *
  ****************************************************************************]]
function me:OnTooltipSetUnit ()
	me.Text:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
end


do
	local NextUpdate = 0;
--[[****************************************************************************
  * Function: _Underscore.Tooltip.Target:OnTooltipCleared                      *
  ****************************************************************************]]
	function me:OnTooltipCleared ()
		NextUpdate = 0;
	end
--[[****************************************************************************
  * Function: _Underscore.Tooltip.Target:OnUpdate                              *
  * Description: Shows and hides the mouseover target.                         *
  ****************************************************************************]]
	local UnitExists = UnitExists;
	function me:OnUpdate ( Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = me.UpdateRate;

			if ( self:IsUnit( "mouseover" ) and UnitExists( "mouseovertarget" ) ) then
				me:SetOwner( self, "ANCHOR_PRESERVE" );
				me:SetUnit( "mouseovertarget" ); -- Shows the tooltip
			else
				me:Hide();
			end
		end
	end
end




GameTooltip:HookScript( "OnTooltipCleared", me.OnTooltipCleared );
GameTooltip:HookScript( "OnUpdate", me.OnUpdate );
me:SetScript( "OnTooltipSetUnit", me.OnTooltipSetUnit );

me:SetPoint( "TOPLEFT", GameTooltip, "TOPRIGHT" );
me:SetScale( 0.8 );
me.Text = _G[ me:GetName().."TextLeft1" ];

_Underscore.Tooltip.UnitRegister( me );
_Underscore.Tooltip.Skin( me );
me.Icon:ClearAllPoints();
me.Icon:SetPoint( "TOPLEFT", me, "TOPRIGHT", -2, -2 );
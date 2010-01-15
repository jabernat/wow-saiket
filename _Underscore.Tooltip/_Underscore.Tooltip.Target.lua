--[[****************************************************************************
  * _Underscore.Tooltip by Saiket                                              *
  * _Underscore.Tooltip.Target.lua - Adds a mouseover target tooltip.          *
  ****************************************************************************]]


local me = CreateFrame( "GameTooltip", "_UnderscoreTooltipTarget", GameTooltip, "GameTooltipTemplate" );
_Underscore.Tooltip.Target = me;




--[[****************************************************************************
  * Function: _Underscore.Tooltip.Target:OnUpdate                              *
  * Description: Shows and hides the mouseover target.                         *
  ****************************************************************************]]
function me:OnUpdate ()
	if ( self:IsUnit( "mouseover" ) and UnitExists( "mouseovertarget" ) ) then
		if ( not me:IsShown() ) then
			me:SetOwner( self, "ANCHOR_PRESERVE" );
			me:SetUnit( "mouseovertarget" ); -- Shows the tooltip
			me.Text:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
		end
	else
		me:Hide();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	GameTooltip:HookScript( "OnUpdate", me.OnUpdate );

	me:SetPoint( "TOPLEFT", GameTooltip, "TOPRIGHT" );
	me:SetScale( 0.8 );
	me.Text = _G[ me:GetName().."TextLeft1" ];

	_Underscore.Tooltip.UnitRegister( me );
	_Underscore.Tooltip.Skin( me );
	me.Icon:ClearAllPoints();
	me.Icon:SetPoint( "TOPLEFT", me, "TOPRIGHT", -2, -2 );
end

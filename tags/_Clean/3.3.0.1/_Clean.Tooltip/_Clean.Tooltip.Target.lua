--[[****************************************************************************
  * _Clean.Tooltip by Saiket                                                   *
  * _Clean.Tooltip.Target.lua - Adds a mouseover target tooltip.               *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "GameTooltip", "_CleanTooltipTarget", GameTooltip, "GameTooltipTemplate" );
_Clean.Tooltip.Target = me;




--[[****************************************************************************
  * Function: _Clean.Tooltip.Target:OnUpdate                                   *
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

	me:SetPoint( "BOTTOMLEFT", GameTooltip, "BOTTOMRIGHT" );
	me:SetScale( 0.8 );
	me.Text = _G[ me:GetName().."TextLeft1" ];

	_Clean.Tooltip.RegisterGuild( me );
end

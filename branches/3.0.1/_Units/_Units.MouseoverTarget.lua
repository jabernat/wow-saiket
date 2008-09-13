--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.MouseoverTarget.lua - Adds a mouseover target tooltip.              *
  ****************************************************************************]]


local _Units = _Units;
local me = CreateFrame( "Frame", nil, GameTooltip );
_Units.MouseoverTarget = me;

local Tooltip = CreateFrame( "GameTooltip", "_UnitsMouseoverTargetTooltip", me, "GameTooltipTemplate" );
me.Tooltip = Tooltip;




--[[****************************************************************************
  * Function: _Units.MouseoverTarget:OnUpdate                                  *
  * Description: Shows and hides the mouseover target.                         *
  ****************************************************************************]]
function me:OnUpdate ()
	if ( GameTooltip:IsUnit( "mouseover" ) and UnitExists( "mouseovertarget" ) ) then
		if ( not Tooltip:IsShown() ) then
			Tooltip:SetOwner( GameTooltip, "ANCHOR_PRESERVE" );
			Tooltip:SetUnit( "mouseovertarget" ); -- Shows the tooltip
			Tooltip.Text:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
		end
	else
		Tooltip:Hide();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );

	Tooltip:SetPoint( "BOTTOMLEFT", GameTooltip, "BOTTOMRIGHT" );
	Tooltip:SetScale( 0.8 );
	Tooltip:SetClampedToScreen( false );
	Tooltip.Text = _G[ Tooltip:GetName().."TextLeft1" ];

	if ( IsAddOnLoaded( "_Misc" ) ) then
		_Misc.GameTooltip.RegisterTooltip( Tooltip );
	end
end

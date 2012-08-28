--[[****************************************************************************
  * _Underscore.Tooltip by Saiket                                              *
  * _Underscore.Tooltip.Target.lua - Adds a mouseover target tooltip.          *
  ****************************************************************************]]


local NS = CreateFrame( "GameTooltip", "_UnderscoreTooltipTarget", GameTooltip, "GameTooltipTemplate" );
select( 2, ... ).Target = NS;

NS.UpdateRate = 0.5;




--- Updates the unit name color like the default GameTooltip.
function NS:OnTooltipSetUnit ()
	NS.Text:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
end


do
	local NextUpdate = 0;
	--- Resets the update timer when the tooltip gets cleared.
	function NS:OnTooltipCleared ()
		NextUpdate = 0;
	end

	local UnitExists = UnitExists;
	--- Shows and hides the mouseover target, updating it on a timer.
	function NS:OnUpdate ( Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = NS.UpdateRate;

			if ( self:IsUnit( "mouseover" ) and UnitExists( "mouseovertarget" ) ) then
				NS:SetOwner( self, "ANCHOR_PRESERVE" );
				NS:SetUnit( "mouseovertarget" ); -- Shows the tooltip
			else
				NS:Hide();
			end
		end
	end
end




GameTooltip:HookScript( "OnTooltipCleared", NS.OnTooltipCleared );
GameTooltip:HookScript( "OnUpdate", NS.OnUpdate );
NS:SetScript( "OnTooltipSetUnit", NS.OnTooltipSetUnit );

NS:SetPoint( "TOPLEFT", GameTooltip, "TOPRIGHT" );
NS:SetScale( 0.8 );
NS.Text = _G[ NS:GetName().."TextLeft1" ];

local Tooltip = select( 2, ... );
Tooltip.RegisterUnit( NS );
Tooltip.Skin( NS );
NS.Icon:ClearAllPoints();
NS.Icon:SetPoint( "TOPLEFT", NS, "TOPRIGHT", -2, -2 );
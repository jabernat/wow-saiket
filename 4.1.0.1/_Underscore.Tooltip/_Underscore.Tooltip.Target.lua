--[[****************************************************************************
  * _Underscore.Tooltip by Saiket                                              *
  * _Underscore.Tooltip.Target.lua - Adds a mouseover target tooltip.          *
  ****************************************************************************]]


local me = CreateFrame( "GameTooltip", "_UnderscoreTooltipTarget", GameTooltip, "GameTooltipTemplate" );
select( 2, ... ).Target = me;

me.UpdateRate = 0.5;




--- Updates the unit name color like the default GameTooltip.
function me:OnTooltipSetUnit ()
	me.Text:SetTextColor( GameTooltip_UnitColor( "mouseovertarget" ) );
end


do
	local NextUpdate = 0;
	--- Resets the update timer when the tooltip gets cleared.
	function me:OnTooltipCleared ()
		NextUpdate = 0;
	end

	local UnitExists = UnitExists;
	--- Shows and hides the mouseover target, updating it on a timer.
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

local Tooltip = select( 2, ... );
Tooltip.RegisterUnit( me );
Tooltip.Skin( me );
me.Icon:ClearAllPoints();
me.Icon:SetPoint( "TOPLEFT", me, "TOPRIGHT", -2, -2 );
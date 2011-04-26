--[[****************************************************************************
  * _Underscore.Bags by Saiket                                                 *
  * _Underscore.Bags.lua - Moves default bags to fit _Underscore.ActionBars.   *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.Bags = me;

me.Frame = CreateFrame( "Frame", nil, UIParent );

me.ContainerEnv = setmetatable( { -- Global variable overrides without taint
	CONTAINER_OFFSET_X = 0;
	CONTAINER_OFFSET_Y = 0;
}, { __index = _G } );

local BagScale = 0.8;
local BagPadding = 10 / BagScale; -- Distance between action bars and bags




--- Allows scaled bags to fill the entire _Underscore.Bags frame.
function me.ContainerEnv.GetScreenHeight ()
	return me.Frame:GetHeight();
end


do
	local Backup = updateContainerFrameAnchors;
	--- Reparents bags before positioning them for scaling.
	function me.Update ( ... )
		for Index, Name in ipairs( ContainerFrame1.bags ) do
			_G[ Name ]:SetParent( me.Frame );
		end
		return Backup( ... );
	end
end




--- Scrolls the stack amount using the scrollwheel.
function me:StackOnMouseWheel ( Delta )
	if ( IsModifiedClick( "_UNDERSCORE_BAGS_SCROLLALL" ) ) then
		self.split = Delta > 0 and self.maxStack or 1;
		StackSplitText:SetText( self.split );
		UpdateStackSplitFrame( self.maxStack );
	else
		( Delta > 0 and StackSplitRightButton or StackSplitLeftButton ):Click();
	end
end




me.Frame:SetPoint( "TOPLEFT", _Underscore.TopMargin, "BOTTOMLEFT", BagPadding, -BagPadding );
me.Frame:SetPoint( "BOTTOMRIGHT", _Underscore.ActionBars.BackdropRight, "BOTTOMLEFT", -BagPadding, BagPadding );
me.Frame:SetScale( BagScale );

setfenv( updateContainerFrameAnchors, me.ContainerEnv );
updateContainerFrameAnchors = me.Update;


-- Enable scrolling the stack split dialog
StackSplitFrame:EnableMouseWheel( true );
StackSplitFrame:SetScript( "OnMouseWheel", me.StackOnMouseWheel );
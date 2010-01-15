--[[****************************************************************************
  * _Underscore.Bags by Saiket                                                 *
  * _Underscore.Bags.lua - Moves default bags to fit _Underscore.ActionBars.   *
  ****************************************************************************]]


local me = CreateFrame( "Frame", nil, UIParent );
_Underscore.Bags = me;

me.ContainerEnv = setmetatable( { -- Global variable overrides without taint
	CONTAINER_OFFSET_X = 0;
	CONTAINER_OFFSET_Y = 0;
}, { __index = _G } );

local BagScale = 0.8;
local BagPadding = 10 / BagScale; -- Distance between action bars and bags




--[[****************************************************************************
  * Function: _Underscore.Bags.ContainerEnv.GetScreenHeight                    *
  * Description: Allows scaled bags to fill the entire _Underscore.Bags frame. *
  ****************************************************************************]]
function me.ContainerEnv.GetScreenHeight ()
	return me:GetHeight();
end


--[[****************************************************************************
  * Function: _Underscore.Bags.Update                                          *
  * Description: Reparents bags before positioning them for scaling.           *
  ****************************************************************************]]
do
	local Backup = updateContainerFrameAnchors;
	function me.Update ( ... )
		for Index, Name in ipairs( ContainerFrame1.bags ) do
			_G[ Name ]:SetParent( me );
		end
		return Backup( ... );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetPoint( "TOPLEFT", _Underscore.TopMargin, "BOTTOMLEFT", BagPadding, -BagPadding );
	me:SetPoint( "BOTTOMRIGHT", _Underscore.ActionBars.BackdropRight, "BOTTOMLEFT", -BagPadding, BagPadding );
	me:SetScale( BagScale );

	setfenv( updateContainerFrameAnchors, me.ContainerEnv );
	updateContainerFrameAnchors = me.Update;
end

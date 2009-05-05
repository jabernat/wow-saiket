--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Watch.lua - Modifies the quest/achievement watch frame.             *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.Watch = me;




--[[****************************************************************************
  * Function: _Clean.Watch:CollapseButtonEnable                                *
  * Description: Completely disables the collapse button when "hidden".        *
  ****************************************************************************]]
function me:CollapseButtonEnable ()
	self:EnableMouse( self:IsEnabled() == 1 )
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( WatchFrameCollapseExpandButton, "Enable", me.CollapseButtonEnable );
	hooksecurefunc( WatchFrameCollapseExpandButton, "Disable", me.CollapseButtonEnable );
end

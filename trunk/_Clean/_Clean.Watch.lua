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
	self:EnableMouse( self:IsEnabled() == 1 );
end


--[[****************************************************************************
  * Function: _Clean.Watch:WatchHeaderOnLeftClick                              *
  * Description: Stops tracking if shift is held.                              *
  ****************************************************************************]]
do
	local Backup = WatchFrameLinkButtonTemplate_OnLeftClick;
	function me:WatchHeaderOnLeftClick ( ... )
		if ( IsShiftKeyDown() ) then -- Stop tracking
			CloseDropDownMenus();
			if ( self.type == "QUEST" ) then
				RemoveQuestWatch( self.index );
				WatchFrame_Update();
				if ( QuestLogFrame:IsVisible() ) then
					QuestLog_Update();
				end
			elseif ( self.type == "ACHIEVEMENT" ) then
				( AchievementButton_ToggleTracking or RemoveTrackedAchievement )( self.index );
			end

		else
			return Backup( self, ... );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Watch.WatchHeaderHookFrame                                *
  ****************************************************************************]]
function me.WatchHeaderHookFrame ( Frame )
	_Clean.AddLockedButton( Frame );
	Frame:RegisterForClicks( "LeftButtonUp" );
end
--[[****************************************************************************
  * Function: _Clean.Watch:WatchHeaderGetFrame                                 *
  * Description: Hooks newly made header buttons.                              *
  ****************************************************************************]]
do
	local Backup = WatchFrame.buttonCache.GetFrame;
	function me:WatchHeaderGetFrame ( ... )
		local NumFrames = self.numFrames;
		local Frame = Backup( self, ... );

		if ( NumFrames ~= self.numFrames ) then -- Created new frame
			me.WatchHeaderHookFrame( Frame )
		end

		return Frame;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( WatchFrameCollapseExpandButton, "Enable", me.CollapseButtonEnable );
	hooksecurefunc( WatchFrameCollapseExpandButton, "Disable", me.CollapseButtonEnable );

	WatchFrameLinkButtonTemplate_OnLeftClick = me.WatchHeaderOnLeftClick;

	WatchFrame.buttonCache.GetFrame = me.WatchHeaderGetFrame;
	for _, Frame in ipairs( WatchFrame.buttonCache.frames ) do
		me.WatchHeaderHookFrame( Frame );
	end
	for _, Frame in ipairs( WatchFrame.buttonCache.usedFrames ) do
		me.WatchHeaderHookFrame( Frame );
	end
end

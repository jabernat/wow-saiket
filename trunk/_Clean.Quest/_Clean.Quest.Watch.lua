--[[****************************************************************************
  * _Clean.Quest by Saiket                                                     *
  * _Clean.Quest.Watch.lua - Modifies the quest/achievement watch frame.       *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local _Clean = _Clean;
local me = {};
_Clean.Quest.Watch = me;




--[[****************************************************************************
  * Function: _Clean.Quest.Watch:UpdateMouseover                               *
  * Description: Completely disables the collapse button when "hidden".        *
  ****************************************************************************]]
function me:UpdateMouseover ()
	local Enable = self:IsEnabled() == 1;
	self:EnableMouse( Enable );
	WatchFrameTitleButton:EnableMouse( Enable );
end


--[[****************************************************************************
  * Function: _Clean.Quest.Watch:OnLeftClick                                   *
  * Description: Stops tracking if shift is held.                              *
  ****************************************************************************]]
do
	local Backup = WatchFrameLinkButtonTemplate_OnLeftClick;
	function me:OnLeftClick ( ... )
		if ( IsShiftKeyDown() ) then -- Stop tracking
			CloseDropDownMenus();
			if ( self.type == "QUEST" ) then
				RemoveQuestWatch( GetQuestIndexForWatch( self.index ) );
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
  * Function: _Clean.Quest.Watch:Hook                                          *
  ****************************************************************************]]
function me:Hook ()
	_Clean.AddLockedButton( self );
	self:RegisterForClicks( "LeftButtonUp" );
end
--[[****************************************************************************
  * Function: _Clean.Quest.Watch:GetFrame                                      *
  * Description: Hooks newly made buttons.                                     *
  ****************************************************************************]]
do
	local Backup = WatchFrame.buttonCache.GetFrame;
	function me:GetFrame ( ... )
		local NumFrames = self.numFrames;
		local Frame = Backup( self, ... );

		if ( NumFrames ~= self.numFrames ) then -- Created new frame
			me.Hook( Frame );
		end

		return Frame;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( WatchFrameCollapseExpandButton, "Enable", me.UpdateMouseover );
	hooksecurefunc( WatchFrameCollapseExpandButton, "Disable", me.UpdateMouseover );

	WatchFrameLinkButtonTemplate_OnLeftClick = me.OnLeftClick;

	WatchFrame.buttonCache.GetFrame = me.GetFrame;
	for _, Frame in ipairs( WatchFrame.buttonCache.frames ) do
		me.Hook( Frame );
	end
	for _, Frame in ipairs( WatchFrame.buttonCache.usedFrames ) do
		me.Hook( Frame );
	end
end

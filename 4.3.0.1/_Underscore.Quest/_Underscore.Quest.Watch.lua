--[[****************************************************************************
  * _Underscore.Quest by Saiket                                                *
  * _Underscore.Quest.Watch.lua - Modifies the quest/achievement watch frame.  *
  ****************************************************************************]]


if ( not _Underscore.Quest ) then -- Wasn't loaded because Carbonite is enabled
	return;
end
local NS = {};
select( 2, ... ).Watch = NS;




do
	local Backup = WatchFrameLinkButtonTemplate_OnLeftClick;
	--- Stops tracking quests/achievements if shift is held when clicked.
	function NS:OnLeftClick ( ... )
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
do
	local Backup = WatchFrame.buttonCache.GetFrame;
	--- Hook to lock newly made buttons.
	function NS:GetFrame ( ... )
		local NumFrames = self.numFrames;
		local Frame = Backup( self, ... );

		if ( NumFrames ~= self.numFrames ) then -- Created new frame
			_Underscore.AddLockedButton( Frame );
		end

		return Frame;
	end
end


do
	local NumButtons = 0;
	--- Skins and repositions quest item buttons along the right of the list.
	function NS.UpdateQuests ()
		-- Skin new buttons
		if ( NumButtons ~= WATCHFRAME_NUM_ITEMS ) then -- New button created
			for Index = NumButtons + 1, WATCHFRAME_NUM_ITEMS do
				local Button = _G[ "WatchFrameItem"..Index ];
				_Underscore.SkinButton( Button, _G[ Button:GetName().."IconTexture" ] );
				Button:GetNormalTexture():SetTexCoord( 1, 0, 0, 0, 1, 1, 0, 1 ); -- Rotate 90 degrees CCW
			end
			NumButtons = WATCHFRAME_NUM_ITEMS;
		end

		-- Reposition buttons
		for Index = 1, WATCHFRAME_NUM_ITEMS do
			local Button = _G[ "WatchFrameItem"..Index ];
			if ( Button:IsShown() ) then
				Button:SetPoint( "TOPRIGHT", ( select( 2, Button:GetPoint( 1 ) ) ) );
			else
				break;
			end
		end
	end
end
--- Repositions the list under the minimap.
function NS.Manage ()
	WatchFrame:ClearAllPoints();
	WatchFrame:SetPoint( "TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -8 );
	WatchFrame:SetPoint( "BOTTOM", Dominos.Frame:Get( 3 ), "TOP" );
end




if ( IsAddOnLoaded( "_Underscore.ActionBars" ) ) then
	-- Reposition list
	WatchFrameLines:SetPoint( "BOTTOMRIGHT" );
	_Underscore.RegisterPositionManager( NS.Manage );

	-- Reposition quest item buttons
	WatchFrame_RemoveObjectiveHandler( WatchFrame_DisplayTrackedQuests );
	hooksecurefunc( "WatchFrame_DisplayTrackedQuests", NS.UpdateQuests );
	WatchFrame_AddObjectiveHandler( WatchFrame_DisplayTrackedQuests );
end


WatchFrame:SetScale( 0.75 );
-- Right-align the header text
WatchFrameTitle:SetPoint( "RIGHT", WatchFrameCollapseExpandButton, "LEFT", -8, 0 );
WatchFrameTitle:SetJustifyH( "RIGHT" );

WatchFrameLinkButtonTemplate_OnLeftClick = NS.OnLeftClick;

WatchFrame.buttonCache.GetFrame = NS.GetFrame;
for _, Frame in ipairs( WatchFrame.buttonCache.frames ) do
	_Underscore.AddLockedButton( Frame );
end
for _, Frame in ipairs( WatchFrame.buttonCache.usedFrames ) do
	_Underscore.AddLockedButton( Frame );
end
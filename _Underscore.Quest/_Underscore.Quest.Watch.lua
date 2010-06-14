--[[****************************************************************************
  * _Underscore.Quest by Saiket                                                *
  * _Underscore.Quest.Watch.lua - Modifies the quest/achievement watch frame.  *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local _Underscore = _Underscore;
local me = {};
_Underscore.Quest.Watch = me;




--[[****************************************************************************
  * Function: _Underscore.Quest.Watch:OnLeftClick                              *
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
  * Function: _Underscore.Quest.Watch:GetFrame                                 *
  * Description: Hooks newly made buttons.                                     *
  ****************************************************************************]]
do
	local Backup = WatchFrame.buttonCache.GetFrame;
	function me:GetFrame ( ... )
		local NumFrames = self.numFrames;
		local Frame = Backup( self, ... );

		if ( NumFrames ~= self.numFrames ) then -- Created new frame
			_Underscore.AddLockedButton( Frame );
		end

		return Frame;
	end
end


--[[****************************************************************************
  * Function: _Underscore.Quest.Watch.UpdateQuests                             *
  * Description: Repositions quest item buttons.                               *
  ****************************************************************************]]
do
	local NumButtons = 0;
	function me.UpdateQuests ()
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
--[[****************************************************************************
  * Function: _Underscore.Quest.Watch.Manage                                   *
  ****************************************************************************]]
function me.Manage ()
	WatchFrame:ClearAllPoints();
	WatchFrame:SetPoint( "TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -8 );
	WatchFrame:SetPoint( "BOTTOM", Dominos.Frame:Get( 3 ), "TOP" );
end




if ( IsAddOnLoaded( "_Underscore.ActionBars" ) ) then
	-- Reposition list
	WatchFrameLines:SetPoint( "BOTTOMRIGHT" );
	_Underscore.RegisterPositionManager( function ()
		WatchFrame:ClearAllPoints();
		WatchFrame:SetPoint( "TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -8 );
		WatchFrame:SetPoint( "BOTTOM", Dominos.Frame:Get( 3 ), "TOP" );
	end );

	-- Reposition quest item buttons
	local Backup = WatchFrame_DisplayTrackedQuests;
	hooksecurefunc( "WatchFrame_DisplayTrackedQuests", me.UpdateQuests );
	if ( WatchFrame_RemoveObjectiveHandler( Backup ) ) then
		WatchFrame_AddObjectiveHandler( WatchFrame_DisplayTrackedQuests );
	end
end


WatchFrame:SetScale( 0.75 );
-- Right-align the header text
WatchFrameTitle:SetPoint( "RIGHT", WatchFrameCollapseExpandButton, "LEFT", -8, 0 );
WatchFrameTitle:SetJustifyH( "RIGHT" );

WatchFrameLinkButtonTemplate_OnLeftClick = me.OnLeftClick;

WatchFrame.buttonCache.GetFrame = me.GetFrame;
for _, Frame in ipairs( WatchFrame.buttonCache.frames ) do
	_Underscore.AddLockedButton( Frame );
end
for _, Frame in ipairs( WatchFrame.buttonCache.usedFrames ) do
	_Underscore.AddLockedButton( Frame );
end
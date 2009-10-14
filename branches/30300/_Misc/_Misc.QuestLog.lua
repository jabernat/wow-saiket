--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.QuestLog.lua - Modifies the quest log frame.                         *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end

local _Misc = _Misc;
local L = _MiscLocalization;
local me = {};
_Misc.QuestLog = me;




--[[****************************************************************************
  * Function: _Misc.QuestLog.QuestLogUpdate                                    *
  * Description: Add level information and quest type data to the titles of    *
  *   quests for when they're linked, and remove the default quest type text.  *
  ****************************************************************************]]
do
	local GetQuestLogTitle = GetQuestLogTitle;
	function me.QuestLogUpdate ()
		for _, Button in ipairs( QuestLogScrollFrame.buttons ) do
			if ( not Button:IsShown() ) then
				break;
			end
			local Index = Button:GetID();

			local Title, Level, Tag, _, IsHeader, _, Completed, IsDaily = GetQuestLogTitle( Index );
			if ( not IsHeader ) then
				if ( Tag ) then
					Tag = L.QUESTLOG_QUESTTAGS[ Tag:match( L.QUESTLOG_DAILY_PATTERN ) or Tag ] or Tag;
				end
				if ( IsDaily ) then
					Tag = L.QUESTLOG_DAILY_FORMAT:format( Tag or "" );
				end
				Button.normalText:SetFormattedText( L.QUESTLOG_TITLETEXT_FORMAT, Level, Tag or "", Title );
				Button.tag:SetText( L.QUESTLOG_ISCOMPLETETAGS[ Completed ] );
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Make titles expand when no tag is present
	for Index, Button in ipairs( QuestLogScrollFrame.buttons ) do
		Button.tag:SetWidth( 0 ); -- Cause width to scale to text contents
		Button.normalText:SetPoint( "RIGHT", Button.tag, "LEFT" );
		Button.groupMates:ClearAllPoints();
		Button.groupMates:SetPoint( "RIGHT", Button.normalText, "LEFT" );
		Button.check:ClearAllPoints();
		Button.check:SetPoint( "RIGHT", Button.normalText, "LEFT" );
	end
	QuestLogTitleButton_Resize = _Misc.NilFunction;

	hooksecurefunc( "QuestLog_Update", me.QuestLogUpdate );
	QuestLogScrollFrame.update = QuestLog_Update;
end

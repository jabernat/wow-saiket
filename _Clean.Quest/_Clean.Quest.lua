--[[****************************************************************************
  * _Clean.Quest by Saiket                                                     *
  * _Clean.Quest.lua - Modifies the quest log.                                 *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local L = _CleanLocalization.Quest;
local _Clean = _Clean;
local me = {};
_Clean.Quest = me;




--[[****************************************************************************
  * Function: _Clean.Quest.QuestLogUpdate                                      *
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
					Tag = L.Types[ Tag:match( L.DAILY_PATTERN ) or Tag ];
				end
				if ( IsDaily ) then
					Tag = L.DAILY_FORMAT:format( Tag or "" );
				end
				Button.normalText:SetFormattedText( L.TITLE_FORMAT, Level, Tag or "", Title );
				Button.tag:SetText( L.Completed[ Completed ] );
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
	QuestLogTitleButton_Resize = _Clean.NilFunction;

	hooksecurefunc( "QuestLog_Update", me.QuestLogUpdate );
	QuestLogScrollFrame.update = QuestLog_Update;
end

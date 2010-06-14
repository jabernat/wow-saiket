--[[****************************************************************************
  * _Underscore.Quest by Saiket                                                *
  * _Underscore.Quest.lua - Modifies the quest log.                            *
  ****************************************************************************]]


if ( IsAddOnLoaded( "Carbonite" ) ) then
	return;
end
local L = _UnderscoreLocalization.Quest;
local me = {};
_Underscore.Quest = me;




--[[****************************************************************************
  * Function: _Underscore.Quest.QuestLogUpdate                                 *
  * Description: Add level information and quest type data to the titles of    *
  *   quests for when they're linked, and remove the default quest type text.  *
  ****************************************************************************]]
do
	local GetQuestLogTitle = GetQuestLogTitle;
	function me.QuestLogUpdate ()
		if ( not QuestLogFrame:IsShown() ) then
			return;
		end

		for _, Button in ipairs( QuestLogScrollFrame.buttons ) do
			if ( not Button:IsShown() ) then
				break;
			end

			if ( not Button.isHeader ) then
				local Index = Button:GetID();

				local Title, Level, Tag, _, _, _, Completed, IsDaily = GetQuestLogTitle( Index );
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




-- Make titles expand when no tag is present
for Index, Button in ipairs( QuestLogScrollFrame.buttons ) do
	Button.tag:SetWidth( 0 ); -- Cause width to scale to text contents
	Button.normalText:SetPoint( "RIGHT", Button.tag, "LEFT" );
	Button.groupMates:ClearAllPoints();
	Button.groupMates:SetPoint( "RIGHT", Button.normalText, "LEFT" );
	Button.check:ClearAllPoints();
	Button.check:SetPoint( "RIGHT", Button.normalText, "LEFT" );
end
QuestLogTitleButton_Resize = _Underscore.NilFunction;

hooksecurefunc( "QuestLog_Update", me.QuestLogUpdate );
QuestLogScrollFrame.update = QuestLog_Update;
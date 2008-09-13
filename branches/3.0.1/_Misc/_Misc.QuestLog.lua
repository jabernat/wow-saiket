--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.QuestLog.lua - Modifies the quest log frame.                         *
  *                                                                            *
  * + Adds the levels of quests to the quest log and quests linked to chat.    *
  *   The type of quest is also represented by a one letter abbreviation, such *
  *   as "r" for raidable quests.                                              *
  * + Allows for more of the quest title text to be visible in the log.        *
  ****************************************************************************]]


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
	local IsQuestWatched = IsQuestWatched;
	function me.QuestLogUpdate ()
		local NumEntries = GetNumQuestLogEntries();
		local QuestIndex = FauxScrollFrame_GetOffset( QuestLogListScrollFrame );
	
		for DisplayOffset = 1, QUESTS_DISPLAYED do
			QuestIndex = QuestIndex + 1;
			if ( QuestIndex > NumEntries ) then
				break;
			end
	
			local TitleTextName = "QuestLogTitle"..DisplayOffset;
			local TitleText = _G[ TitleTextName ];
			local Title, Level, Tag, _, IsHeader, _, Completed, IsDaily = GetQuestLogTitle( QuestIndex );
			if ( not IsHeader ) then
				if ( IsDaily ) then
					Tag = L.QUESTLOG_DAILY_FORMAT:format( Tag and L.QUESTLOG_QUESTTAGS[ Tag:match( L.QUESTLOG_DAILY_PATTERN ) ] or "" );
				else
					Tag = L.QUESTLOG_QUESTTAGS[ Tag ] or "";
				end
				TitleText:SetFormattedText( L.QUESTLOG_TITLETEXT_FORMAT, Level, Tag, Title );
			end
			if ( IsQuestWatched( QuestIndex ) ) then
				_Misc.SetPoint( _G[ TitleTextName.."Check" ], "LEFT", TitleText, "LEFT", 6, 0 );
			end
			-- Only set tag text when quest is complete or failed
			_G[ TitleTextName.."Tag" ]:SetText( L.QUESTLOG_ISCOMPLETETAGS[ Completed ] );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Make titles expand when no tag is present
	for TitleIndex = 1, QUESTS_DISPLAYED do
		local ButtonName = "QuestLogTitle"..TitleIndex;
		local ButtonTag = _G[ ButtonName.."Tag" ];

		ButtonTag:SetWidth( 0 ); -- Cause width to scale to text contents
		_G[ ButtonName.."NormalText" ]:SetPoint( "RIGHT", ButtonTag, "LEFT" );
	end

	hooksecurefunc( "QuestLog_Update", me.QuestLogUpdate );
end

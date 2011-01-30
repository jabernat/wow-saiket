--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	COPY_OBJECTNAME_FORMAT = "Copy of “%s”",
	DELETE = [=[Delete this script or folder.
|cff808080(Hold shift to skip confirmation)|r]=],
	DELETE_CONFIRM_FORMAT = "Delete script or folder named |cff808080“%s”|r?",
	FOLDER_NEW = "Create a new folder.",
	FONT_CYCLE = "Cycle through available fonts.",
	FONT_DECREASE = "Decrease font size.",
	FONT_INCREASE = "Increase font size.",
	GOTO_FORMAT = "Go to line number (between 1 and %d):",
	LIST_TITLE = "_|cffcccc88DevPad|r",
	LUA_TOGGLE = "Toggle Lua syntax highlighting for this script.",
	RECEIVE_CONFIRM_SCRIPT_FORMAT = [=[%s has sent you a script called |cff808080“%s”|r.  Add it to your _|cffcccc88DevPad|r?
|cffff1111WARNING: Inspect all untrustworthy scripts before you run them!|r]=],
	RECEIVE_CONFIRM_FOLDER_FORMAT = [=[%s has sent you a folder called |cff808080“%s”|r.  Add it and its contents to your _|cffcccc88DevPad|r?
|cffff1111WARNING: Inspect all untrustworthy scripts before you run them!|r]=],
	RECEIVE_OBJECTNAME_FORMAT = "“%s” from %s",
	REVERT = "Undo all changes made this session.",
	SCRIPT_NEW = "Create a new script.",
	SCRIPT_AUTORUN_DESC = "Auto-run at startup.",
	SCRIPT_RUN = "Run this script.",
	SEARCH_DESC = [=[Search scripts' text by Lua pattern.  Escape newlines and backslashes!
|cff808080(Hold shift for reverse)|r]=],
	SEND = [=[Send this script or folder to other _|cffcccc88DevPad|r users.
|cff808080(Send to yourself to copy)|r]=],
	SEND_COMPLETE_FORMAT = "Finished sending |cff808080“%s”|r to |cffffffff%s|r.",
	SEND_LARGE_FORMAT = "Please wait while |cff808080“%s”|r (%.2fkb) is sent to |cffffffff%s|r…",
	SEND_PLAYER_NAME = "Please enter a character name to send to:";
}, getmetatable( _DevPad.L ) );
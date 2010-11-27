--[[****************************************************************************
  * _DevPad by Saiket                                                          *
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
	IMPORTERS = "Importers",
	LIST_TITLE = "_|cffcccc88DevPad|r",
	LUA_TOGGLE = "Toggle Lua syntax highlighting for this script.",
	PRINT_FORMAT = "_|cffcccc88DevPad|r: %s",
	README = "Instruction Manual",
	README_TEXT = [=[--- A short guide to _DevPad's features.

    Many thanks to Mud's wonderful Hack mod for inspiration!



_DevPad lets you write notes, scripts, and mini addons in-game.  The following sections describe key features of the mod:


General:
  * Windows can be snapped together by dragging one near another.


List Window:
  * _DevPad organizes scripts into nestable folders, shown in the list.  You can organize them and their scripts by dragging and dropping.
  * The arrow to the right of each script toggles auto-running it when you log in or reload UI.  Use it to turn a script into a mini addon.
  * Double click any entry to rename it.
  * Multiple entries can have the same name, even within the same folder.
  * New folders and scripts are created by clicking their respective bag and note icons at the top-right of the list.
  * Delete entries by selecting them and using the red cross-out icon in the top-right corner.
  * Send scripts and entire folders to friends by selecting them and clicking the trumped icon in the top-right corner.
  * Copy an entry by sending it to yourself!
  * A LuaDoc comment (triple dash) at the start of a script will appear as that script's tooltip.  This readme includes one as an example.
  * Search entry titles and script contents using the search bar at the bottom of the list.


Editor Window:
  * Line numbering is an approximation and can be wrong for wrapped lines!
  * Optional syntax highlighting courtesy of krka's ForAllIndentsAndPurposes can be turned on per script using the icon at the top-right of the editor.  This also automatically indents code as you type.
  * Font and font size controls are also at the top-right of the window.
  * Click a line number to select that entire line (even if the line numbers appear out of alignment).
  * Text is saved as you type.  You can revert to the script's original text (since the start of the session) using the back arrow icon at the top-right.
  * Limited keyboard shortcuts are available:
    + <Ctrl+G>: Go to line number dialog.
    + <Ctrl+F>: Focus the list's Find text edit box.


Scripts and the _DevPad API:
  * Scripts receive the following arguments: (ScriptName, StateTable, ...), where ... are custom parameters from the caller.
  * The StateTable parameter can be used for anything, like the addon table passed to addons.  It is static to its script, so the same one gets passed each call.
  * Optional returns from the script's main chunk propagate out to the caller.
  * Run other scripts like this: _DevPad.FindScript( "NamePattern" )( ... );
  * See <_DevPad/_DevPad.lua> for documentation on manipulating scripts and folders programatically.
]=],
	RECEIVE_CONFIRM_SCRIPT_FORMAT = [=[%s has sent you a script called |cff808080“%s”|r.  Add it to your _|cffcccc88DevPad|r?
|cffff1111WARNING: Inspect all untrustworthy scripts before you run them!|r]=],
	RECEIVE_CONFIRM_FOLDER_FORMAT = [=[%s has sent you a folder called |cff808080“%s”|r.  Add it and its contents to your _|cffcccc88DevPad|r?
|cffff1111WARNING: Inspect all untrustworthy scripts before you run them!|r]=],
	RECEIVE_OBJECTNAME_FORMAT = "“%s” from %s",
	RECEIVE_MESSAGE_FORMAT = "You have received a script or folder from |cffffffff%s|r called |cff808080“%s”|r.",
	RECEIVE_MESSAGE_REOPEN = "Reopen your _|cffcccc88DevPad|r to view a save confirmation.",
	REVERT = "Undo all changes made this session.",
	SCRIPT_NEW = "Create a new script.",
	SCRIPT_AUTORUN_DESC = "Auto-run at startup.",
	SCRIPT_RUN = "Run this script.",
	SEND = "Send this script or folder to other _|cffcccc88DevPad|r users.",
	SEND_COMPLETE_FORMAT = "Finished sending |cff808080“%s”|r to |cffffffff%s|r.",
	SEND_LARGE_FORMAT = "Please wait while |cff808080“%s”|r (%.2fkb) is sent to |cffffffff%s|r…",
	SEND_PLAYER_NAME = "Please enter a character name to send to:";
	SLASH_NOTFOUND_FORMAT = "Couldn't find script named |cff808080“%s”|r.",
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );


SLASH__DEVPAD1 = "/devpad";
SLASH__DEVPAD2 = "/pad";

-- Bindings
BINDING_HEADER__DEVPAD = "_|cffcccc88DevPad|r";
BINDING_NAME__DEVPAD_SHOW = "Toggle Pad List";
--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


-- See http://wow.curseforge.com/addons/devpad/localization/enUS/
select( 2, ... ).L = setmetatable( {
	EXAMPLE = "Example Script",
	IMPORTERS = "Importers",
	PRINT_FORMAT = "_|cffcccc88DevPad|r: %s",
	README = "Instruction Manual",
	README_TEXT = [=[--- A short guide to _DevPad's features.

  *Many thanks to Mud's wonderful Hack mod for inspiration!*



_DevPad lets you write notes, scripts, and mini addons in-game.  The following sections describe key features of the mod:


# Windows:
  * Windows can be snapped together by dragging one near another.

## List Window:
  * _DevPad organizes scripts into nestable folders, shown in the list.  You can organize them and their scripts by dragging and dropping.
  * The arrow to the right of each script toggles auto-running it when you log in or reload UI.  Use it to turn a script into a mini addon.
  * Double click any entry to rename it.
  * Multiple entries can have the same name, even within the same folder.
  * New folders and scripts are created by clicking their respective bag and page icons at the top-right of the list.
  * Delete entries by selecting them and using the red cross-out icon in the top-right corner.
  * Send scripts and entire folders to friends by selecting them and clicking the trumpet icon in the top-right corner.
  * Copy an entry by sending it to yourself!
  * A LuaDoc comment (triple dash) at the very start of a script will appear as that script's tooltip.  This readme includes one as an example.
  * Search script contents using the search bar at the bottom of the list.

## Editor Window:
  * Line numbering is an approximation and can be wrong for wrapped lines!
  * Optional raw text mode, and syntax highlighting courtesy of krka's ForAllIndentsAndPurposes, can be turned on per script using the keyboard icon at the top-right of the editor.  This also automatically indents code as you type.
  * When not in Lua/raw text mode, you can click hyperlinks in the editor to interact with them.
  * Font and font size controls are also at the top-right of the window.
  * Click a line number to select that entire line (even if the line numbers appear out of alignment).
  * Text is saved as you type.  You can revert to the script's original text (since the start of the session) using the back arrow icon at the top-right.
  * Limited keyboard shortcuts are available:
    + `Ctrl+G`: Go to line number dialog.
    + `Ctrl+F`: Focus the list's search edit box.
    + `F3`/`Shift+F3`: Jump to next/previous search result.


# Scripts and the _DevPad API:
  * Scripts receive the following arguments: `(ScriptObject, ...)`, where `...` are custom parameters from the caller.
  * Optional returns from the script's main chunk propagate out to the caller.
  * Run other scripts like this: `_DevPad:FindScripts( "NamePattern" )( ... );` or `_DevPad( "Path", "to", "script" )( ... );`
  * See `_DevPad.lua` for documentation on manipulating scripts and folders programatically.
]=],
	RECEIVE_MESSAGE_FORMAT = "You have received a script or folder from |cffffffff%s|r called |cff808080“%s”|r.",
	RECEIVE_MESSAGE_REOPEN = "Open your _|cffcccc88DevPad|r to save or discard it.",
	SLASH_GUIERROR_FORMAT = "Couldn't load |cff808080“_DevPad.GUI”|r: %s.",
	SLASH_RUN_AMBIGUOUS_FORMAT = "Multiple matches found for |cff808080“%s”|r; Running script |cff808080“%s”|r.",
	SLASH_RUN_MISSING_FORMAT = "Couldn't find script named |cff808080“%s”|r.",
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
BINDING_NAME__DEVPAD_TOGGLE = "Toggle Pad List";
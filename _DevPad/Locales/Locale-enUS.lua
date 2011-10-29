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
  * _DevPad organizes pages into nestable folders, shown in the list.  You can organize them by dragging and dropping.
  * The arrow to the right of each page toggles auto-running it when you log in or reload UI.  Use it to turn a page of code into a mini addon.
  * Double click any entry to rename it.
  * Multiple entries can have the same name, even within the same folder.
  * Create new folders and pages by clicking their respective bag and page icons at the top-right of the list.
  * Delete entries by selecting them and using the red cross-out icon in the top-right corner.
  * Send pages and entire folders to friends by selecting them and clicking the trumpet icon in the top-right corner.
  * Copy an entry by sending it to yourself!
  * A LuaDoc comment (triple dash) at the very start of a page will appear as that page's tooltip.  This readme includes one as an example.
  * Search page contents using the search bar at the bottom of the list.

## Editor Window:
  * Line numbering is an approximation and can be wrong for wrapped lines!
  * Optional Lua mode, with syntax highlighting courtesy of krka's ForAllIndentsAndPurposes, can be turned on per page using the keyboard icon at the top-right of the editor.  This also automatically indents code as you type.
  * When not in Lua mode, you can click hyperlinks in the editor to interact with them.  You can also color text like in a rich text editor.
  * Font and font size controls are also at the top-right of the window.
  * Click a line number to select that entire line (even if the line numbers appear out of alignment).
  * Text is saved as you type.
  * Undo and redo changes with the left and right arrow buttons at the top right, or with the keyboard shortcuts below.  Each page remembers its last 128 edits, although this limit can be changed or removed from within `_DevPad.GUI/_DevPad.GUI.Editor.History.lua`.
  * Limited keyboard shortcuts are available:
    + `Ctrl+Z`/`Ctrl+Shift+Z`: Undo/redo one change.
    + `Ctrl+G`: Go to line number dialog.
    + `Ctrl+F`: Focus the list's search edit box.
    + `F3`/`Shift+F3`: Jump to next/previous search result.


# Script pages and the _DevPad API:
  * Pages receive the following arguments when run: `(ScriptObject, ...)`, where `...` are custom parameters from the caller.
  * Optional returns from the page's main chunk propagate out to the caller.
  * Run other pages like this: `_DevPad:FindScripts( "NamePattern" )( ... );` or `_DevPad( "Path", "to", "script" )( ... );`
  * See `_DevPad/_DevPad.lua` for documentation on manipulating pages and folders programatically.
]=],
	RECEIVE_MESSAGE_FORMAT = "You have received a page or folder from |cffffffff%s|r called |cff808080“%s”|r.",
	RECEIVE_MESSAGE_REOPEN = "Open your _|cffcccc88DevPad|r to save or discard it.",
	SLASH_GUIERROR_FORMAT = "Couldn't load |cff808080“_DevPad.GUI”|r: %s.",
	SLASH_RUN_AMBIGUOUS_FORMAT = "Multiple matches found for |cff808080“%s”|r; Running page |cff808080“%s”|r.",
	SLASH_RUN_MISSING_FORMAT = "Couldn't find page named |cff808080“%s”|r.",
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
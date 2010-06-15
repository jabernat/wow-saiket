--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local Metatable = {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
};


-- See http://wow.curseforge.com/addons/cursor/localization/enUS/
_CursorLocalization = setmetatable( {
	OPTIONS_DESC = "These options let you change the cursor models that follow your mouse.  You can choose from presets or specify your own.",
	OPTIONS_TITLE = "_|cffcccc88Cursor|r",
	RESET_ALL = "Sets & Cursor",
	RESET_CHARACTER = "Only Cursor",
	RESET_CONFIRM = "_|cffcccc88Cursor|r: Reset sets for all characters and this character's cursor, or only the cursor?",
	TYPE_CUSTOM = "Custom",

	-- Phrases localized by default UI
	RESET_CANCEL = CANCEL;


	OPTIONS = setmetatable( {
		APPLY = "Apply",
		CURSORS = "Cursor",
		DELETE = "Delete",
		DELETE_DESC = "Removes this set for all characters.",
		ENABLED = "Model Enabled",
		ENABLED_DESC = "Toggles whether this cursor layer is shown.",
		FACING = "Facing",
		FACING_DESC = "Rotates the model.",
		FACING_HIGH = "2π",
		FACING_LOW = "0",
		LOAD = "Load",
		PATH = "File Path",
		PATH_DESC = "The location of the model file to use, excluding any file extension.",
		PREVIEW_DESC = [=[A preview of the chosen cursor layer.
|cffffffffClick to cycle animation speeds.]=],
		SAVE = "Save",
		SCALE = "Scale",
		SCALE_DESC = "Draws the model larger or smaller.",
		SET_DESC = "The name of the cursor set to save or load.  Use the dropdown button to select saved sets.",
		SETS = "Sets",
		TYPE = "Preset Type",
		TYPE_DESC = "Groups of preset cursor layers to chose from, or pick “Custom” to give a custom model path.",
		VALUE = "Preset Name",
		VALUE_DESC = "Possible presets to choose from in the selected type category.",
		X_DESC = "X-offset: Moves the model left and right.",
		Y_DESC = "Y-offset: Moves the model up and down.",
	}, Metatable );
	SETS = setmetatable( { -- All DefaultSets names
	}, Metatable );
	CURSORS = setmetatable( { -- All names of cursor layers
	}, Metatable );
	TYPES = setmetatable( { -- All type names
	}, Metatable );
	VALUES = setmetatable( { -- All names of presets
	}, Metatable );
}, Metatable );


SLASH__CURSOR_OPTIONS1 = "/cursor";
SLASH__CURSOR_OPTIONS2 = "/cursoroptions";
SLASH__CURSOR_OPTIONS3 = "/cursor";
SLASH__CURSOR_OPTIONS4 = "/cursoroptions";
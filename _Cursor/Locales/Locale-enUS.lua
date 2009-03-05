--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Metatable = {
		__index = function ( self, Key )
			rawset( self, Key, Key );
			return Key;
		end;
	};
	local LDQuo, RDQuo = "\226\128\156", "\226\128\157";
	local Title = "_|cffcccc88Cursor|r";


	_CursorLocalization = setmetatable( {
		SETS = setmetatable( {}, Metatable ); -- All DefaultSets names
		CURSORS = setmetatable( {}, Metatable ); -- All names of cursor layers
		TYPES = setmetatable( { -- All type names
			[ "" ] = "Custom"; -- Custom type; not an actual type
		}, Metatable );
		VALUES = setmetatable( {}, Metatable ); -- All names of presets

		-- Options
		OPTIONS_TITLE = Title;
		OPTIONS_DESC = "These options let you change the cursor models that follow your mouse.  You can choose from presets or specify your own.";
		OPTIONS = setmetatable( {
			SETS = "Sets";
			SET_DESC = "The name of the cursor set to save or load.  Use the dropdown button to select saved sets.";
			SAVE = "Save"; -- Save set
			LOAD = "Load"; -- Load set
			DELETE = "Delete"; -- Delete set
			DELETE_DESC = "Removes this set for all characters.";
			CURSORS = "Cursor";
			APPLY = "Apply"; -- Apply current options to cursor
			ENABLED = "Model Enabled";
			ENABLED_DESC = "Toggles whether this cursor layer is shown.";
			PREVIEW_DESC = "A preview of the chosen cursor layer.\n"..HIGHLIGHT_FONT_COLOR_CODE.."Click to cycle animation speeds.";
			X_DESC = "X-offset: Moves the model left and right.";
			Y_DESC = "Y-offset: Moves the model up and down.";
			SCALE = "Scale";
			SCALE_DESC = "Draws the model larger or smaller.";
			FACING = "Facing";
			FACING_DESC = "Rotates the model.";
			FACING_LOW = "0";
			FACING_HIGH = "2\207\128"; -- 2pi
			TYPE = "Preset Type";
			TYPE_DESC = "Groups of preset cursor layers to chose from, or pick "..LDQuo.."Custom"..RDQuo.." to give a custom model path.";
			VALUE = "Preset Name";
			VALUE_DESC = "Possible presets to choose from in the selected type category.";
			PATH = "File Path";
			PATH_DESC = "The location of the model file to use, excluding any file extension.";
		}, Metatable );

		RESET_CONFIRM = Title..": Reset sets for all characters and this character's cursor, or only the cursor?";
		RESET_ALL = "Sets & Cursor";
		RESET_CHARACTER = "Only Cursor";
		RESET_CANCEL = CANCEL;
	}, Metatable );




--------------------------------------------------------------------------------
-- Globals
----------

	SLASH__CURSOR_OPTIONS1 = "/cursor";
	SLASH__CURSOR_OPTIONS2 = "/cursoroptions";
end

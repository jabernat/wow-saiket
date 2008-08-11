--[[****************************************************************************
  * _Cursor by Saiket                                                          *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local LDQuo, RDQuo = "\226\128\156", "\226\128\157";

	local Title = "_|cffcccc88Cursor"..FONT_COLOR_CODE_CLOSE;


	_CursorLocalization = setmetatable(
		{
			MODEL_OVER = "Over"; -- Name of overlay model
			MODEL_UNDER = "Under"; -- Name of underlay model

			TYPES = {
				[ "TRAIL" ] = "Trail";
				[ "PARTICLE" ] = "Particle trail";
				[ "GLOW" ] = "Glow";
				[ "MISC" ] = "Miscellaneous";
			};

			-- Options
			OPTIONS_TITLE = Title;
			OPTIONS_DESC = "These options let you change the cursor models that follow your mouse.  You can choose from presets or specify your own.";
			OPTIONS = setmetatable(
				{
					SETS = "Sets";
					APPLY = "Apply";
					ENABLED = "Model Enabled";
					ENABLED_DESC = "Toggles whether this model is shown.";
					PREVIEW_DESC = "A preview of the chosen model.\n"..HIGHLIGHT_FONT_COLOR_CODE.."Click to cycle animation speeds.";
					X_DESC = "X-offset: Moves the model left and right.";
					Y_DESC = "Y-offset: Moves the model up and down.";
					SCALE = "Scale";
					SCALE_DESC = "Draws the model larger or smaller.";
					FACING = "Facing";
					FACING_DESC = "Rotates the model.";
					FACING_LOW = "0";
					FACING_HIGH = "2\207\128"; -- 2pi
					TYPE = "Preset Type";
					TYPE_DESC = "Groups of preset models to chose from, or pick "..LDQuo.."Custom"..RDQuo.." to give a custom model path.";
					CUSTOM = "Custom"; -- Custom type
					VALUE = "Preset Name";
					VALUE_DESC = "Possible presets to choose from in the selected type category.";
					PATH = "File Path";
					PATH_DESC = "The location of the model file to use, excluding any file extension.";
				}, {
					__index = function ( self, Key )
						rawset( self, Key, "OPTIONS."..Key );
						return "OPTIONS."..Key;
					end;
				} );
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );
end

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

			-- Options
			OPTIONS_TITLE = Title;
			OPTIONS_DESC = "These options let you change the cursor models that follow your mouse.  You can choose from presets or specify your own.";
			OPTIONS = setmetatable(
				{
					SETS = "Sets";
					PREVIEW_DESC = "A preview of the chosen model.  Click to cycle animation speeds.";
					X_DESC = "X-offset: Moves the model left and right.";
					Y_DESC = "Y-offset: Moves the model up and down.";
					SCALE = "Scale";
					SCALE_DESC = "Draws the model larger or smaller.";
					FACING = "Facing";
					FACING_DESC = "Rotates the model.";
					FACING_LOW = "0";
					FACING_HIGH = "2\207\128"; -- 2pi
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

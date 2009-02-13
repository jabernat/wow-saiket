--[[****************************************************************************
  * _Units by Saiket                                                           *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local Title = "_|cffcccc88Units"..FONT_COLOR_CODE_CLOSE;

	_UnitsLocalization = setmetatable(
		{
			STATUSMONITOR_MANA_NOT_AVAILABLE = "N/A";
			STATUSMONITOR_CONDITION_LABELS = {
				[ "CORPSE" ] = "Slain";
				[ "GHOST" ]  = "Ghost";
				[ "ABSENT" ] = "Absent";
				[ "FEIGN" ] = "Feign Death";
			};

			GRID_LAYOUT_GROUP = Title..": Groups";
			GRID_LAYOUT_CLASS = Title..": Classes";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );
end

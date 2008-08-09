--[[****************************************************************************
  * _Units by Saiket                                                           *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	_UnitsLocalization = setmetatable(
		{
			STATUSMONITOR_MANA_NOT_AVAILABLE = "N/A";
			STATUSMONITOR_CONDITION_LABELS = {
				[ "CORPSE" ] = "Slain";
				[ "GHOST" ]  = "Ghost";
				[ "ABSENT" ] = "Absent";
				[ "FEIGN" ] = "Feign Death";
				[ 1 ] = "CRITICAL";
				[ 2 ] = "Poor";
				[ 3 ] = "Fair";
				[ 4 ] = ""; -- "Good";
				[ 5 ] = ""; -- "Excellent";
			};
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );
end

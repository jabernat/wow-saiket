--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	GridStatusHealthFadeLocalization = setmetatable( {
		TITLE = "Health Fade";
		COLOR_HIGH = "Color High";
		COLOR_HIGH_DESC = "Color to blend for units at max health";
		COLOR_LOW = "Color Low";
		COLOR_LOW_DESC = "Color to blend for units at no health";
		LABEL_FORMAT = "%d%%"; -- Format for health percentage labels
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );
end

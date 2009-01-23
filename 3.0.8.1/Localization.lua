--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local L = AceLibrary( "AceLocale-2.2" ):new( "GridStatusHealthFade" );

	L:RegisterTranslations( "enUS", function()
		return {
			[ "Health Fade" ] = true;
			[ "Color High" ] = true;
			[ "Color to blend for units at max health" ] = true;
			[ "Color Low" ] = true;
			[ "Color to blend for units at no health" ] = true;
			[ "%.f%%" ] = true; -- Format for health percentage labels
		};
	end );
end

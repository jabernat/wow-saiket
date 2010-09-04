--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local L = AceLibrary( "AceLocale-2.2" ):new( "GridStatusHealthFade" );
L:RegisterTranslations( "enUS", function() return {
	COLOR_HIGH = "Color High";
	COLOR_HIGH_DESC = "Color to blend for units at max health";
	COLOR_LOW = "Color Low";
	COLOR_LOW_DESC = "Color to blend for units at no health";
	LABEL_FORMAT = "%d%%"; -- Format for health percentage labels
	TITLE = "Health Fade";
}; end );
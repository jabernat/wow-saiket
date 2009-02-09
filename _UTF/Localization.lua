--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88UTF|r";

	_UTFLocalization = setmetatable(
		{
			BROWSE_TITLE = "Browse";
			BROWSE_CODEPOINT = "Codepoint:";
			BROWSE_GLYPH_NOTAVAILABLE = "N/A";

			CUSTOMIZE_TITLE = "Custom Replacements";
			CUSTOMIZE_DESC = "Add custom filters for _UTF to replace in outbound chat and macros.";
			CUSTOMIZE_ADD    = "+";
			CUSTOMIZE_REMOVE = "-";
			CUSTOMIZE_ENTITIES_TITLE = "Entities";
			CUSTOMIZE_ENTITIES_NAME = "Reference Name:";
			CUSTOMIZE_ENTITIES_VALUE = "Codepoint:";
			CUSTOMIZE_TEXTREPLACE_TITLE = "Text Replace";
			CUSTOMIZE_TEXTREPLACE_FIND = "Find:";
			CUSTOMIZE_TEXTREPLACE_REPLACE = "Replace:";

			OPTIONS_TITLE = Title;
			OPTIONS_DESC = "These options control the general text-replacement behaviors of _UTF.  The character browsing dialog can be brought up with \226\128\156/utf\226\128\157 or by keybinding.";
			OPTIONS_ENTITYREPLACE = "Replace Entity References";
			OPTIONS_ENTITYREPLACE_DESC = "Replace XML entity references in the chat edit box when you press tab, and also when found in any non-secure macro commands.";
			OPTIONS_TEXTREPLACE = "Text Replacement";
			OPTIONS_TEXTREPLACE_DESC = "Replace certain customizable parts of chat messages with UTF equivalents.  Can also be used to correct common spelling errors.";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	SLASH__UTFTOGGLE1 = "/utf";

	-- Bindings
	BINDING_HEADER__UTF = Title;
	BINDING_NAME__UTF_TOGGLE = "Toggle Window";
end

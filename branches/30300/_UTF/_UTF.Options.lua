--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Options.lua - Frame for setting general _UTF settings.                *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame" );
_UTF.Options = me;




--[[****************************************************************************
  * Function: _UTF.Options.Update                                              *
  * Description: Syncs the checkboxes to actual saved settings.                *
  ****************************************************************************]]
function me.Update ()
	me.EntityReplaceButton:SetChecked( _UTFOptions.Chat.EntityReferenceReplace );
	me.TextReplaceButton:SetChecked( _UTFOptions.Chat.TextReplace );
end
--[[****************************************************************************
  * Function: _UTF.Options:OnEvent                                             *
  * Description: Updates configuration options on load.                        *
  ****************************************************************************]]
function me:OnEvent ( _, AddOn )
	if ( AddOn:upper() == "_UTF" ) then
		self:UnregisterEvent( "ADDON_LOADED" );
		self.Update();
	end
end


--[[****************************************************************************
  * Function: _UTF.Options.EntityReplaceSetFunc                                *
  * Description: Toggles entity reference replacements.                        *
  ****************************************************************************]]
function me.EntityReplaceSetFunc ( Value )
	_UTFOptions.Chat.EntityReferenceReplace = Value == "1";
end
--[[****************************************************************************
  * Function: _UTF.Options.TextReplaceSetFunc                                  *
  * Description: Toggles text replacements.                                    *
  ****************************************************************************]]
function me.TextReplaceSetFunc ( Value )
	_UTFOptions.Chat.TextReplace = Value == "1";
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.OPTIONS_TITLE;

	me:RegisterEvent( "ADDON_LOADED" );
	me:SetScript( "OnEvent", me.OnEvent );

	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.OPTIONS_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.OPTIONS_DESC );


	-- Entity replace option button
	local EntityReplaceButton = CreateFrame( "CheckButton",
		"_UTFOptionsEntityReplaceButton", me, "InterfaceOptionsCheckButtonTemplate" );
	me.EntityReplaceButton = EntityReplaceButton;
	EntityReplaceButton:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );
	EntityReplaceButton.setFunc = me.EntityReplaceSetFunc;
	EntityReplaceButton.tooltipText = L.OPTIONS_ENTITYREPLACE_DESC;
	_G[ EntityReplaceButton:GetName().."Text" ]:SetText( L.OPTIONS_ENTITYREPLACE );

	-- Text replace option button
	local TextReplaceButton = CreateFrame( "CheckButton",
		"_UTFOptionsTextReplaceButton",  me, "InterfaceOptionsCheckButtonTemplate" );
	me.TextReplaceButton = TextReplaceButton;
	TextReplaceButton:SetPoint( "TOPLEFT", EntityReplaceButton, "BOTTOMLEFT", 0, -8 );
	TextReplaceButton.setFunc = me.TextReplaceSetFunc;
	TextReplaceButton.tooltipText = L.OPTIONS_TEXTREPLACE_DESC;
	_G[ TextReplaceButton:GetName().."Text" ]:SetText( L.OPTIONS_TEXTREPLACE );


	InterfaceOptions_AddCategory( me );
end

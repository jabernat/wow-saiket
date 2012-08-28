--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Options.lua - Frame for setting general _UTF settings.                *
  ****************************************************************************]]


local AddOnName, _UTF = ...;
local L = _UTF.L;
local NS = CreateFrame( "Frame" );
_UTF.Options = NS;

NS.EntityReplaceButton = CreateFrame( "CheckButton", "_UTFOptionsEntityReplaceButton", NS, "InterfaceOptionsCheckButtonTemplate" );
NS.TextReplaceButton = CreateFrame( "CheckButton", "_UTFOptionsTextReplaceButton",  NS, "InterfaceOptionsCheckButtonTemplate" );




--- Syncs checkboxes on this pane to actual saved settings.
function NS.Update ()
	NS.EntityReplaceButton:SetChecked( _UTFOptions.Chat.EntityReferenceReplace );
	NS.TextReplaceButton:SetChecked( _UTFOptions.Chat.TextReplace );
end
--- Updates configuration options on load.
function NS:OnEvent ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self.Update();
	end
end


--- Toggles entity reference replacements.
-- @param Value  String "0" to disable or "1" to enable.
function NS.EntityReplaceButton.setFunc ( Value )
	_UTFOptions.Chat.EntityReferenceReplace = Value == "1";
end
--- Toggles text replacements.
-- @param Value  String "0" to disable or "1" to enable.
function NS.TextReplaceButton.setFunc ( Value )
	_UTFOptions.Chat.TextReplace = Value == "1";
end




NS.name = L.OPTIONS_TITLE;

NS:RegisterEvent( "ADDON_LOADED" );
NS:SetScript( "OnEvent", NS.OnEvent );

-- Pane title
local Title = NS:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.OPTIONS_TITLE );
local SubText = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText = SubText;
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.OPTIONS_DESC );


-- Entity replace option button
local EntityReplaceButton = NS.EntityReplaceButton;
EntityReplaceButton:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );
EntityReplaceButton.tooltipText = L.OPTIONS_ENTITYREPLACE_DESC;
_G[ EntityReplaceButton:GetName().."Text" ]:SetText( L.OPTIONS_ENTITYREPLACE );

-- Text replace option button
local TextReplaceButton = NS.TextReplaceButton;
TextReplaceButton:SetPoint( "TOPLEFT", EntityReplaceButton, "BOTTOMLEFT", 0, -8 );
TextReplaceButton.tooltipText = L.OPTIONS_TEXTREPLACE_DESC;
_G[ TextReplaceButton:GetName().."Text" ]:SetText( L.OPTIONS_TEXTREPLACE );


InterfaceOptions_AddCategory( NS );
--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.lua - Frame for adding to replacement lookup tables.        *
  ****************************************************************************]]


local _UTF = select( 2, ... );
local L = _UTF.L;
local NS = CreateFrame( "Frame" );
_UTF.Customize = NS;

NS.TableContainer = CreateFrame( "Frame", nil, NS );

NS.Key = CreateFrame( "EditBox", "_UTFCustomizeKey", NS, "InputBoxTemplate" );
NS.Value = CreateFrame( "EditBox", "_UTFCustomizeValue", NS, "InputBoxTemplate" );

NS.Add = CreateFrame( "Button", nil, NS, "UIPanelButtonTemplate" );
NS.Remove = CreateFrame( "Button", nil, NS, "UIPanelButtonTemplate" );

NS.Panes = {};




--- Sets the visible tab pane in the window.
function NS.SetPane ( Pane )
	local OldPane = NS.Pane;
	if ( Pane ~= OldPane ) then
		-- Hide the old pane
		if ( OldPane ) then
			OldPane:Hide();
			PanelTemplates_DeselectTab( OldPane.Tab );
		end
		-- Show the new pane
		NS.Pane = Pane;
		PanelTemplates_SelectTab( Pane.Tab );

		NS.KeyLabel:SetText( Pane.Key );
		NS.ValueLabel:SetText( Pane.Value );
		NS.Value:SetPoint( "LEFT", NS.KeyLabel:GetStringWidth() > NS.ValueLabel:GetStringWidth() and NS.KeyLabel or NS.ValueLabel, "RIGHT", 8, 0 );

		NS.SetKeyValue();
		NS.ValidateButtons();
		Pane:Show();
		Pane.Update();
	end
end
--- Adds a tab for a given table of options.
-- @param Pane  Frame with handlers to display table data.
-- @param Title  Title text for the pane's tab.
function NS.AddPane ( Pane, Title )
	local ID = #NS.Panes + 1;
	local Tab = CreateFrame( "Button", "_UTFCustomizeTab"..ID, NS.TableContainer, "TabButtonTemplate" );
	NS.Panes[ ID ] = Pane;
	Pane.Tab = Tab;
	Pane:Hide();
	Pane:SetParent( NS );

	Tab.Pane = Pane;
	Tab:SetText( Title );
	Tab:SetHitRectInsets( 6, 6, 6, 0 );
	Tab:SetScript( "OnClick", NS.TabOnClick );
	PanelTemplates_TabResize( Tab, 0 );
	PanelTemplates_DeselectTab( Tab );

	if ( ID == 1 ) then
		Tab:SetPoint( "BOTTOMLEFT", NS.TableContainer, "TOPLEFT" );
	else
		Tab:SetPoint( "LEFT", NS.Panes[ ID - 1 ].Tab, "RIGHT", -4, 0 );
	end
end


--- Sets both edit boxes' text.
function NS.SetKeyValue ( Key, Value )
	NS.Key:SetText( Key or "" );
	NS.Value:SetText( Value or "" );
end
--- Validates ability to use add and remove buttons based on edit box contents.
function NS.ValidateButtons ()
	local Pane = NS.Pane;
	local KeyText = NS.Key:GetText();

	local CanAdd = Pane and Pane.CanAdd( KeyText, NS.Value:GetText() );
	local CanRemove = Pane and Pane.CanRemove( KeyText );
	if ( NS.Table ) then
		NS.Table:SetSelectionByKey( CanRemove or nil );
	end

	NS.Add[ CanAdd and "Enable" or "Disable" ]( NS.Add );
	NS.Remove[ CanRemove and "Enable" or "Disable" ]( NS.Remove );
end
--- Allows tabbing through editboxes in a cycle.
function NS:EditBoxOnTabPressed ()
	self.NextEditBox:SetFocus();
end
--- Allows enter in any editbox to add the key/value pair.
function NS:EditBoxOnEnterPressed ()
	NS.Add:Click();
end

--- Handler for all table tabs to select the corresponding pane.
function NS:TabOnClick ()
	PlaySound( "igCharacterInfoTab" );
	NS.SetPane( self.Pane );
end

--- Adds a list element from the edit boxes.
function NS.Add:OnClick ()
	if ( NS.Pane and NS.Pane.Add( NS.Key:GetText(), NS.Value:GetText() ) ) then
		NS.SetKeyValue();
		NS.Pane.Update();
	end
end
--- Removes the list element matching the Key editbox.
function NS.Remove:OnClick ()
	if ( NS.Pane and NS.Pane.Remove( NS.Key:GetText() ) ) then
		NS.SetKeyValue();
		NS.Pane.Update();
	end
end
--- Updates the edit boxes when a table row is selected.
-- @param Key  Unique identifier that the current pane used to construct the table row.
function NS:TableOnSelect ( Key )
	if ( Key ~= nil and NS.Pane and NS.Pane.OnSelect ) then
		NS.SetKeyValue( NS.Pane.OnSelect( Key ) );
	end
end

--- Creates the table and sets the current pane when first shown.
function NS:OnShow ()
	self:SetScript( "OnShow", nil );
	NS.OnShow = nil;

	NS.Table = LibStub( "LibTextTable-1.1" ).New( nil, NS.TableContainer, nil, "ChatFontNormal" );
	NS.Table.OnSelect = NS.TableOnSelect;
	NS.Table:SetAllPoints( NS.TableContainer );

	if ( #NS.Panes > 0 ) then
		NS.SetPane( NS.Panes[ 1 ] );
	end
end




NS.name = L.CUSTOMIZE_TITLE;
NS.parent = L.OPTIONS_TITLE;
NS:SetScript( "OnShow", NS.OnShow );

-- Pane title
local Title = NS:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.CUSTOMIZE_TITLE );
local SubText = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.CUSTOMIZE_DESC );


-- Create add and remove buttons
local Remove = NS.Remove;
Remove:SetSize( 16, 20 );
Remove:SetPoint( "BOTTOMRIGHT", -16, 16 );
Remove:SetText( L.CUSTOMIZE_REMOVE );
Remove:SetScript( "OnClick", Remove.OnClick );

local Add = NS.Add;
Add:SetSize( 16, 20 );
Add:SetPoint( "BOTTOMRIGHT", Remove, "TOPRIGHT", 0, 4 );
Add:SetText( L.CUSTOMIZE_ADD );
Add:SetScript( "OnClick", Add.OnClick );


-- Create edit boxes
NS.ValueLabel = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
NS.ValueLabel:SetPoint( "BOTTOMLEFT", 16, 16 );
NS.ValueLabel:SetPoint( "TOP", Remove );

NS.KeyLabel = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
NS.KeyLabel:SetPoint( "BOTTOMLEFT", NS.ValueLabel, "TOPLEFT", 0, 4 );
NS.KeyLabel:SetPoint( "TOP", Add );

local Key = NS.Key;
local Value = NS.Value;

Value:SetPoint( "TOP", NS.ValueLabel );
Value:SetPoint( "BOTTOMRIGHT", Remove, "BOTTOMLEFT", -4, 0 );
Value:SetAutoFocus( false );
Value:SetScript( "OnTabPressed", NS.EditBoxOnTabPressed );
Value:SetScript( "OnEnterPressed", NS.EditBoxOnEnterPressed );
Value:SetScript( "OnTextChanged", NS.ValidateButtons );
Value.NextEditBox = Key;

Key:SetPoint( "TOP", NS.KeyLabel );
Key:SetPoint( "LEFT", Value );
Key:SetPoint( "BOTTOMRIGHT", Value, "TOPRIGHT" );
Key:SetAutoFocus( false );
Key:SetScript( "OnTabPressed", NS.EditBoxOnTabPressed );
Key:SetScript( "OnEnterPressed", NS.EditBoxOnEnterPressed );
Key:SetScript( "OnTextChanged", NS.ValidateButtons );
Key.NextEditBox = Value;

NS.TableContainer:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -32 );
NS.TableContainer:SetPoint( "RIGHT", -16, 0 );
NS.TableContainer:SetPoint( "BOTTOM", Add, "TOP", 0, 4 );
NS.TableContainer:SetBackdrop( { bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]; } );


InterfaceOptions_AddCategory( NS );
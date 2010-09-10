--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.lua - Frame for adding to replacement lookup tables.        *
  ****************************************************************************]]


local _UTF = select( 2, ... );
local L = _UTF.L;
local me = CreateFrame( "Frame" );
_UTF.Customize = me;

me.TableContainer = CreateFrame( "Frame", nil, me );

me.Key = CreateFrame( "EditBox", "_UTFCustomizeKey", me, "InputBoxTemplate" );
me.Value = CreateFrame( "EditBox", "_UTFCustomizeValue", me, "InputBoxTemplate" );

me.Add = CreateFrame( "Button", nil, me, "UIPanelButtonTemplate" );
me.Remove = CreateFrame( "Button", nil, me, "UIPanelButtonTemplate" );

me.Panes = {};




--- Sets the visible tab pane in the window.
function me.SetPane ( Pane )
	local OldPane = me.Pane;
	if ( Pane ~= OldPane ) then
		-- Hide the old pane
		if ( OldPane ) then
			OldPane:Hide();
			PanelTemplates_DeselectTab( OldPane.Tab );
		end
		-- Show the new pane
		me.Pane = Pane;
		PanelTemplates_SelectTab( Pane.Tab );

		me.KeyLabel:SetText( Pane.Key );
		me.ValueLabel:SetText( Pane.Value );
		me.Value:SetPoint( "LEFT", me.KeyLabel:GetStringWidth() > me.ValueLabel:GetStringWidth() and me.KeyLabel or me.ValueLabel, "RIGHT", 8, 0 );

		me.SetKeyValue();
		me.ValidateButtons();
		Pane:Show();
		Pane.Update();
	end
end
--- Adds a tab for a given table of options.
-- @param Pane  Frame with handlers to display table data.
-- @param Title  Title text for the pane's tab.
function me.AddPane ( Pane, Title )
	local ID = #me.Panes + 1;
	local Tab = CreateFrame( "Button", "_UTFCustomizeTab"..ID, me.TableContainer, "TabButtonTemplate" );
	me.Panes[ ID ] = Pane;
	Pane.Tab = Tab;
	Pane:Hide();
	Pane:SetParent( me );

	Tab.Pane = Pane;
	Tab:SetText( Title );
	Tab:SetHitRectInsets( 6, 6, 6, 0 );
	Tab:SetScript( "OnClick", me.TabOnClick );
	PanelTemplates_TabResize( Tab, 0 );
	PanelTemplates_DeselectTab( Tab );

	if ( ID == 1 ) then
		Tab:SetPoint( "BOTTOMLEFT", me.TableContainer, "TOPLEFT" );
	else
		Tab:SetPoint( "LEFT", me.Panes[ ID - 1 ].Tab, "RIGHT", -4, 0 );
	end
end


--- Sets both edit boxes' text.
function me.SetKeyValue ( Key, Value )
	me.Key:SetText( Key or "" );
	me.Value:SetText( Value or "" );
end
--- Validates ability to use add and remove buttons based on edit box contents.
function me.ValidateButtons ()
	local Pane = me.Pane;
	local KeyText = me.Key:GetText();

	local CanAdd = Pane and Pane.CanAdd( KeyText, me.Value:GetText() );
	local CanRemove = Pane and Pane.CanRemove( KeyText );
	if ( me.Table ) then
		me.Table:SetSelectionByKey( CanRemove or nil );
	end

	me.Add[ CanAdd and "Enable" or "Disable" ]( me.Add );
	me.Remove[ CanRemove and "Enable" or "Disable" ]( me.Remove );
end
--- Allows tabbing through editboxes in a cycle.
function me:EditBoxOnTabPressed ()
	self.NextEditBox:SetFocus();
end
--- Allows enter in any editbox to add the key/value pair.
function me:EditBoxOnEnterPressed ()
	me.Add:Click();
end

--- Handler for all table tabs to select the corresponding pane.
function me:TabOnClick ()
	PlaySound( "igCharacterInfoTab" );
	me.SetPane( self.Pane );
end

--- Adds a list element from the edit boxes.
function me.Add:OnClick ()
	if ( me.Pane and me.Pane.Add( me.Key:GetText(), me.Value:GetText() ) ) then
		me.SetKeyValue();
		me.Pane.Update();
	end
end
--- Removes the list element matching the Key editbox.
function me.Remove:OnClick ()
	if ( me.Pane and me.Pane.Remove( me.Key:GetText() ) ) then
		me.SetKeyValue();
		me.Pane.Update();
	end
end
--- Updates the edit boxes when a table row is selected.
-- @param Key  Unique identifier that the current pane used to construct the table row.
function me:TableOnSelect ( Key )
	if ( Key ~= nil and me.Pane and me.Pane.OnSelect ) then
		me.SetKeyValue( me.Pane.OnSelect( Key ) );
	end
end

--- Creates the table and sets the current pane when first shown.
function me:OnShow ()
	self:SetScript( "OnShow", nil );
	me.OnShow = nil;

	me.Table = LibStub( "LibTextTable-1.1" ).New( nil, me.TableContainer, nil, "ChatFontNormal" );
	me.Table.OnSelect = me.TableOnSelect;
	me.Table:SetAllPoints( me.TableContainer );

	if ( #me.Panes > 0 ) then
		me.SetPane( me.Panes[ 1 ] );
	end
end




me.name = L.CUSTOMIZE_TITLE;
me.parent = L.OPTIONS_TITLE;
me:SetScript( "OnShow", me.OnShow );

-- Pane title
local Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.CUSTOMIZE_TITLE );
local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.CUSTOMIZE_DESC );


-- Create add and remove buttons
local Remove = me.Remove;
Remove:SetSize( 16, 20 );
Remove:SetPoint( "BOTTOMRIGHT", -16, 16 );
Remove:SetText( L.CUSTOMIZE_REMOVE );
Remove:SetScript( "OnClick", Remove.OnClick );

local Add = me.Add;
Add:SetSize( 16, 20 );
Add:SetPoint( "BOTTOMRIGHT", Remove, "TOPRIGHT", 0, 4 );
Add:SetText( L.CUSTOMIZE_ADD );
Add:SetScript( "OnClick", Add.OnClick );


-- Create edit boxes
me.ValueLabel = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
me.ValueLabel:SetPoint( "BOTTOMLEFT", 16, 16 );
me.ValueLabel:SetPoint( "TOP", Remove );

me.KeyLabel = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
me.KeyLabel:SetPoint( "BOTTOMLEFT", me.ValueLabel, "TOPLEFT", 0, 4 );
me.KeyLabel:SetPoint( "TOP", Add );

local Key = me.Key;
local Value = me.Value;

Value:SetPoint( "TOP", me.ValueLabel );
Value:SetPoint( "BOTTOMRIGHT", Remove, "BOTTOMLEFT", -4, 0 );
Value:SetAutoFocus( false );
Value:SetScript( "OnTabPressed", me.EditBoxOnTabPressed );
Value:SetScript( "OnEnterPressed", me.EditBoxOnEnterPressed );
Value:SetScript( "OnTextChanged", me.ValidateButtons );
Value.NextEditBox = Key;

Key:SetPoint( "TOP", me.KeyLabel );
Key:SetPoint( "LEFT", Value );
Key:SetPoint( "BOTTOMRIGHT", Value, "TOPRIGHT" );
Key:SetAutoFocus( false );
Key:SetScript( "OnTabPressed", me.EditBoxOnTabPressed );
Key:SetScript( "OnEnterPressed", me.EditBoxOnEnterPressed );
Key:SetScript( "OnTextChanged", me.ValidateButtons );
Key.NextEditBox = Value;

me.TableContainer:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -32 );
me.TableContainer:SetPoint( "RIGHT", -16, 0 );
me.TableContainer:SetPoint( "BOTTOM", Add, "TOP", 0, 4 );
me.TableContainer:SetBackdrop( { bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]; } );


InterfaceOptions_AddCategory( me );
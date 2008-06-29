--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.lua - Frame for adding to replacement lookup tables.        *
NOTE(Table test macro:
/run local t,c=_UTF.Customize,function(s)alert("Clicked "..s:GetID())end;_UTF.Window.Toggle(true,2)t.SetHeader{"ColA",c,"ColB",c}t.SetData{{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9},{0,0},{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8}}
)
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame" );
_UTF.Customize = me;

local Panes = {};
me.Panes = Panes;
local Tabs = {};
me.Tabs = Tabs;

me.PaneID = nil;
me.Header = nil; -- Contains header display data
me.Data = nil; -- Contains table display data
me.SelectedRow = nil;
local Columns = {};
me.Columns = Columns;
local Rows = {};
me.Rows = Rows;

me.RowCount = 10; -- Number of row buttons to allocate
me.RowHeight = nil; -- Calculated when frame size known




--[[****************************************************************************
  * Function: _UTF.Customize.SetPane                                           *
  * Description: Sets the visible pane in the window.                          *
  ****************************************************************************]]
function me.SetPane ( ID )
	local NewPane = Panes[ ID ];
	if ( NewPane ) then
		-- Hide the old pane
		if ( Panes[ me.PaneID ] ) then
			Panes[ me.PaneID ]:Hide();
			PanelTemplates_DeselectTab( Tabs[ me.PaneID ] );
		end
		-- Show the new pane
		me.PaneID = ID;
		me.UpdateEditBoxLabels( NewPane.Label1, NewPane.Label2 );
		me.Clear();
		me.ValidateButtons();
		NewPane:Show();
		PanelTemplates_SelectTab( Tabs[ ID ] );
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.AddPane                                           *
  * Description: Adds a tab for a given table of options.                      *
  ****************************************************************************]]
function me.AddPane ( Pane, Title )
	local ID = #Panes + 1;
	local Tab = CreateFrame( "Button", "_UTFCustomizeTab"..ID, me, "TabButtonTemplate" );
	tinsert( Panes, Pane );
	tinsert( Tabs, Tab );

	Pane:SetID( ID );
	Pane:SetParent( me );
	Pane:SetAllPoints( me.ScrollFrame );

	Tab:SetID( ID );
	Tab:SetText( Title );
	Tab:SetHitRectInsets( 6, 6, 6, 0 );
	Tab:SetScript( "OnClick", me.TabOnClick );
	Tab:SetScript( "OnShow", Tab:GetScript( "OnLoad" ) );

	if ( ID == 1 ) then
		Tab:SetPoint( "BOTTOMLEFT", me.ScrollFrame, "TOPLEFT" );
		me.SetPane( ID );
	else
		Pane:Hide();
		PanelTemplates_DeselectTab( Tab );
		Tab:SetPoint( "LEFT", Tabs[ ID - 1 ], "RIGHT", -4, 0 );
	end
end


--[[****************************************************************************
  * Function: _UTF.Customize.UpdateEditBoxLabels                               *
  * Description: Updates the label text on the two edit boxes.                 *
  ****************************************************************************]]
function me.UpdateEditBoxLabels ( Label1, Label2 )
	me.Label1:SetText( Label1 );
	me.Label2:SetText( Label2 );
	me.EditBox2:SetPoint( "LEFT",
		me.Label1:GetStringWidth() > me.Label2:GetStringWidth()
			and me.Label1 or me.Label2,
		"RIGHT", 8, 0 );
end
--[[****************************************************************************
  * Function: _UTF.Customize.Clear                                             *
  * Description: Clears the edit boxes.                                        *
  ****************************************************************************]]
function me.Clear ()
	me.EditBox1:SetText( "" );
	me.EditBox2:SetText( "" );
end
--[[****************************************************************************
  * Function: _UTF.Customize.ValidateButtons                                   *
  * Description: Validates ability to use add and remove buttons.              *
  ****************************************************************************]]
function me.ValidateButtons ()
	local Pane = Panes[ me.PaneID ];

	me.AddButton[ ( Pane and Pane.CanAdd( me.EditBox1:GetText(), me.EditBox2 ) )
		and "Enable" or "Disable" ]( me.AddButton );
	me.RemoveButton[ ( Pane and Pane.CanRemove( me.EditBox1:GetText() ) )
		and "Enable" or "Disable" ]( me.RemoveButton );
end
--[[****************************************************************************
  * Function: _UTF.Customize.Add                                               *
  * Description: Adds a list element.                                          *
  ****************************************************************************]]
function me.Add ()
	local Pane = Panes[ me.PaneID ];
	if ( Pane ) then
		if ( Pane.Add( me.EditBox1:GetText(), me.EditBox2 ) ) then
			me.Clear();
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.Remove                                            *
  * Description: Removes a list element.                                       *
  ****************************************************************************]]
function me.Remove ()
	local Pane = Panes[ me.PaneID ];
	if ( Pane ) then
		if ( Pane.Remove( me.EditBox1:GetText() ) ) then
			me.Clear();
		end
	end
end


--[[****************************************************************************
  * Function: _UTF.Customize.RowOnClick                                        *
  * Description: Selects a row element when the row is clicked.                *
  ****************************************************************************]]
function me:RowOnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	me.SelectRow( self:GetID() + FauxScrollFrame_GetOffset( me.ScrollFrame ) );
end
--[[****************************************************************************
  * Function: _UTF.Customize:RowAddElements                                    *
  * Description: Adds and anchors missing element strings.                     *
  ****************************************************************************]]
function me:RowAddElements ()
	for Index = #self + 1, #Columns do
		local FontString = self:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
		self[ Index ] = FontString;
		FontString:SetPoint( "TOP" );
		FontString:SetPoint( "LEFT", Columns[ Index ] );
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.ColumnCreate                                      *
  * Description: Creates a new column tab for the scrollframe.                 *
  ****************************************************************************]]
function me.ColumnCreate ()
	local ID = #Columns + 1;
	local Column = CreateFrame( "Button", nil, me.ScrollFrame );
	Column:SetID( ID );
	Column:SetHeight( me.RowHeight );
	Column:SetFontString(
		Column:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" ) );

	Column:RegisterForClicks( "LeftButtonUp" );

	tinsert( Columns, Column );
	return Column;
end
--[[****************************************************************************
  * Function: _UTF.Customize.RowCreate                                         *
  * Description: Creates a new row button for the scrollframe.                 *
  ****************************************************************************]]
function me.RowCreate ()
	local ID = #Rows + 1;
	local Row = CreateFrame( "Button", nil, me.ScrollFrame );
	Row:SetID( ID );
	Row:SetHeight( me.RowHeight );
	Row:SetPoint( "LEFT" );
	Row:SetPoint( "RIGHT" );
	if ( ID == 1 ) then
		Row:SetPoint( "TOP", 0, -me.RowHeight );
	else
		Row:SetPoint( "TOP", Rows[ ID - 1 ], "BOTTOM" );
	end

	me.RowAddElements( Row );
	Row:SetScript( "OnClick", me.RowOnClick );
	Row:RegisterForClicks( "LeftButtonUp" );

	tinsert( Rows, Row );
	return Row;
end
--[[****************************************************************************
  * Function: _UTF.Customize.SetHeader                                         *
  * Description: Sets the header configuration for the data table.  Accepts a  *
  *   table with pairs of column names and corresponding tab click callbacks.  *
  *   Any nil callback value will simply disable that column's tab.            *
  ****************************************************************************]]
function me.SetHeader ( Header )
	local DataColumnCount = Header and #Header / 2 or 0;
	me.Header = Header;

	-- Create necessary column buttons
	if ( #Columns < DataColumnCount ) then
		for Index = #Columns + 1, DataColumnCount do
			me.ColumnCreate();
		end
		-- Add new elements to rows
		for _, Row in ipairs( Rows ) do
			me.RowAddElements( Row );
		end
	end

	-- Fill out buttons
	for Index, Column in ipairs( Columns ) do
		if ( Index > DataColumnCount ) then
			Column:Hide();
		else -- Show the button
			Column:Show();
			Column:ClearAllPoints();
			Column:SetPoint( "TOP" );
			if ( Index == 1 ) then
				Column:SetPoint( "LEFT" );
			else
				Column:SetPoint( "LEFT", Columns[ Index - 1 ], "RIGHT" );
			end
			-- Customize
			local Script = Header[ Index * 2 ];
			Column:SetText( Header[ Index * 2 - 1 ] );
			Column:SetScript( "OnClick", Script );
			Column[ Script and "Enable" or "Disable" ]( Column );
		end
	end
	if ( DataColumnCount > 0 ) then
		Columns[ DataColumnCount ]:SetPoint( "RIGHT" );
	end

	-- Clear data view
	return me.SetData( nil );
end
--[[****************************************************************************
  * Function: _UTF.Customize.SetData                                           *
  * Description: Updates the data set displayed in the table.  Data table is   *
  *   assumed to be as wide as the headers list.                               *
  ****************************************************************************]]
function me.SetData ( Data )
	me.Data = Data;

	-- NOTE(Size columns.)
	for _, Column in ipairs( Columns ) do
		Column:SetWidth( 50 );
	end

	-- Clear selection and update view
	return me.SelectRow( nil );
end
--[[****************************************************************************
  * Function: _UTF.Customize.SelectRow                                         *
  * Description: Selects the given row from the dataset, and updates the view. *
  ****************************************************************************]]
function me.SelectRow ( Index )
	if ( not me.Data ) then
		Index = nil; -- Clear selection
	elseif ( Index and ( Index < 1 or Index > #me.Data ) ) then -- Out of range
		return;
	end

	-- Selection always cleared when data updated
	if ( not Index or me.SelectedRow ~= Index ) then
		me.SelectedRow = Index;
		me.UpdateView();
		return true;
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.UpdateView                                        *
  * Description: Updates the viewable scrollframe area.                        *
  ****************************************************************************]]
function me.UpdateView ()
	local Offset = FauxScrollFrame_GetOffset( me.ScrollFrame );
	local DataRowCount = me.Data and #me.Data or 0;
	local Index, Row;

	for RowIndex, Row in ipairs( Rows ) do
		Index = RowIndex + Offset;

		if ( Index > DataRowCount ) then
			Row:Hide();
		else
			Row:Show();
			for Index, Value in ipairs( me.Data[ Index ] ) do
				Row[ Index ]:SetText( Value );
			end
			if ( me.SelectedRow == Index ) then
				Row:LockHighlight();
			else
				Row:UnlockHighlight();
			end
		end
	end

	FauxScrollFrame_Update( me.ScrollFrame, DataRowCount, me.RowCount,
		me.RowHeight, nil, nil, nil, nil, nil, nil, true );
end


--[[****************************************************************************
  * Function: _UTF.Customize:TabOnClick                                        *
  * Description: Called when a pane's tab is clicked to select the pane.       *
  ****************************************************************************]]
function me:TabOnClick ()
	PlaySound( "igCharacterInfoTab" );
	me.SetPane( self:GetID() );
end
--[[****************************************************************************
  * Function: _UTF.Customize:OnVerticalScroll                                  *
  * Description: Updates the visible list elements.                            *
  ****************************************************************************]]
function me:OnVerticalScroll ()
	FauxScrollFrame_OnVerticalScroll( me.RowHeight, me.UpdateView );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.CUSTOMIZE_TITLE;
	me.parent = L.OPTIONS_TITLE;

	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.CUSTOMIZE_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.CUSTOMIZE_DESC );


	-- Create add and remove buttons
	local RemoveButton = CreateFrame( "Button", nil, me, "GameMenuButtonTemplate" );
	me.RemoveButton = RemoveButton;
	RemoveButton:SetWidth( 16 );
	RemoveButton:SetHeight( 20 );
	RemoveButton:SetPoint( "BOTTOMRIGHT", -16, 16 );
	RemoveButton:SetText( L.CUSTOMIZE_REMOVE );
	RemoveButton:SetScript( "OnClick", me.Remove );
	local AddButton = CreateFrame( "Button", nil, me, "GameMenuButtonTemplate" );
	me.AddButton = AddButton;
	AddButton:SetWidth( 16 );
	AddButton:SetHeight( 20 );
	AddButton:SetPoint( "BOTTOMRIGHT", RemoveButton, "TOPRIGHT", 0, 4 );
	AddButton:SetText( L.CUSTOMIZE_ADD );
	AddButton:SetScript( "OnClick", me.Add );


	-- Create edit boxes
	local Label2 = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.Label2 = Label2;
	Label2:SetPoint( "BOTTOMLEFT", 16, 16 );
	Label2:SetPoint( "TOP", RemoveButton );
	local Label1 = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.Label1 = Label1;
	Label1:SetPoint( "BOTTOMLEFT", Label2, "TOPLEFT", 0, 4 );
	Label1:SetPoint( "TOP", AddButton );

	local EditBox1 = CreateFrame( "EditBox", "_UTFCustomizeEditBox1", me, "InputBoxTemplate" );
	me.EditBox1 = EditBox1;
	local EditBox2 = CreateFrame( "EditBox", "_UTFCustomizeEditBox2", me, "InputBoxTemplate" );
	me.EditBox2 = EditBox2;

	EditBox2:SetPoint( "TOP", Label2 );
	EditBox2:SetPoint( "BOTTOMRIGHT", RemoveButton, "BOTTOMLEFT", -4, 0 );
	EditBox2:SetAutoFocus( false );
	EditBox2:SetScript( "OnTabPressed", function () EditBox1:SetFocus(); end );
	EditBox2:SetScript( "OnEnterPressed", me.Add );
	EditBox2:SetScript( "OnTextChanged", me.ValidateButtons );

	EditBox1:SetPoint( "TOP", Label1 );
	EditBox1:SetPoint( "LEFT", EditBox2 );
	EditBox1:SetPoint( "BOTTOMRIGHT", EditBox2, "TOPRIGHT" );
	EditBox1:SetAutoFocus( false );
	EditBox1:SetScript( "OnTabPressed", function () EditBox2:SetFocus(); end );
	EditBox1:SetScript( "OnEnterPressed", me.Add );
	EditBox1:SetScript( "OnTextChanged", me.ValidateButtons );

	me.UpdateEditBoxLabels();


	-- Add scroll frame
	local ScrollFrame = CreateFrame( "ScrollFrame", "_UTFCustomizeScrollFrame", me, "FauxScrollFrameTemplate" );
	me.ScrollFrame = ScrollFrame;
	ScrollFrame:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -32 );
	ScrollFrame:SetPoint( "BOTTOMRIGHT", AddButton, "TOPRIGHT", -22, 4 );
	ScrollFrame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background";
		tile = true; tileSize = 32;
		insets = { left = 0; right = -24; top = 0; bottom = 0; };
	} );
	ScrollFrame:SetScript( "OnVerticalScroll", me.OnVerticalScroll );
	me.RowHeight = ScrollFrame:GetHeight() / ( me.RowCount + 1 );

	-- Add row buttons
	for Index = 1, me.RowCount do
		me.RowCreate();
	end
	me.SetHeader();
	InterfaceOptions_AddCategory( me );
end

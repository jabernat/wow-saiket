--[[****************************************************************************
  * LibTextTable-1.0 by Saiket                                                 *
  * LibTextTable-1.0.lua - Creates table controls for tabular text data.       *
  ****************************************************************************]]


local MAJOR, MINOR = "LibTextTable-1.0", 3;

local lib = LibStub:NewLibrary( MAJOR, MINOR );
if ( not lib ) then
	return;
end

lib.RowMeta = { __index = {}; };
local RowMethods = lib.RowMeta.__index;
lib.TableMeta = { __index = {}; };
local TableMethods = lib.TableMeta.__index;

local RowHeight = 14;
local ColumnPadding = 6;




--[[****************************************************************************
  * Function: local RowOnClick                                                 *
  * Description: Selects a row element when the row is clicked.                *
  ****************************************************************************]]
local function RowOnClick ( self )
	self:GetParent().Table:SetSelection( self );
end
--[[****************************************************************************
  * Function: local RowInsert                                                  *
  * Description: Creates a new row button for the table.                       *
  ****************************************************************************]]
local function RowInsert ( self, Index )
	local Rows = self.Rows;
	Index = Index or #Rows + 1;

	local Row = next( self.UnusedRows );
	if ( Row ) then
		self.UnusedRows[ Row ] = nil;
		Row:Show();
	else
		Row = CreateFrame( "Button", nil, Rows );
		Row:SetScript( "OnClick", RowOnClick );
		Row:RegisterForClicks( "LeftButtonUp" );
		Row:SetHeight( RowHeight );
		Row:SetPoint( "LEFT" );
		Row:SetPoint( "RIGHT" );
		Row:SetHighlightTexture( [[Interface\FriendsFrame\UI-FriendsFrame-HighlightBar]], "ADD" );
		-- Apply row methods
		if ( not getmetatable( RowMethods ) ) then
			setmetatable( RowMethods, getmetatable( Row ) );
		end
		setmetatable( Row, lib.RowMeta );
	end

	if ( Rows[ Index ] ) then -- Move old row below new one
		Rows[ Index ]:SetPoint( "TOP", Row, "BOTTOM" );
	end
	if ( Index == 1 ) then
		Row:SetPoint( "TOP", Rows );
	else
		Row:SetPoint( "TOP", Rows[ Index - 1 ], "BOTTOM" );
	end

	tinsert( Rows, Index, Row );
	return Row;
end
--[[****************************************************************************
  * Function: local RowRemove                                                  *
  * Description: Hides a row button and allows it to be recycled.              *
  ****************************************************************************]]
local RowRemove;
do
	local function ClearElements ( Count, ... )
		for Index = 1, Count do
			local Element = select( Index, ... );
			Element:Hide();
			Element:SetText();
		end
	end
	function RowRemove ( self, Index )
		local Rows = self.Rows;
		local Row = Rows[ Index ];

		tremove( Rows, Index );
		self.UnusedRows[ Row ] = true;
		Row:Hide();
		Row.Key = nil;
		ClearElements( self.NumColumns, Row:GetRegions() );
		for Column = 1, self.NumColumns do -- Remove values
			Row[ Column ] = nil;
		end
		-- Reanchor next row
		if ( Rows[ Index ] ) then
			if ( Index == 1 ) then
				Row:SetPoint( "TOP", Rows );
			else
				Row:SetPoint( "TOP", Rows[ Index - 1 ], "BOTTOM" );
			end
		end
	end
end




--[[****************************************************************************
  * Function: RowObject:GetNumRegions                                          *
  ****************************************************************************]]
do
	local RowMethodsOriginal = getmetatable( BasicScriptErrorsButton ).__index; -- Generic button metatable
	function RowMethods:GetNumRegions ()
		return RowMethodsOriginal.GetNumRegions( self ) - 1; -- Skip highlight region
	end
--[[****************************************************************************
  * Function: RowObject:GetRegions                                             *
  ****************************************************************************]]
	function RowMethods:GetRegions ()
		return select( 2, RowMethodsOriginal.GetRegions( self ) ); -- Skip highlight region
	end
end
--[[****************************************************************************
  * Function: RowObject:GetData                                                *
  * Description: Returns the row's key and all original element data.          *
  ****************************************************************************]]
function RowMethods:GetData ()
	return self.Key, unpack( self );
end




--[[****************************************************************************
  * Function: TableObject:Clear                                                *
  * Description: Empties the table of all rows.                                *
  ****************************************************************************]]
function TableMethods:Clear ()
	local Rows = self.Rows;
	if ( #Rows > 0 ) then
		if ( self.View.YScroll ) then -- Force correct view resize
			self.View.YScroll:SetValue( 0 );
		end
		self:SetSelection();
		wipe( self.Keys );
		for Index = #Rows, 1, -1 do -- Remove in reverse so rows don't move mid-loop
			RowRemove( self, Index );
		end
		self:Resize();
		return true;
	end
end
--[[****************************************************************************
  * Function: TableObject:SetHeader                                            *
  * Description: Sets the headers for the data table to the list of header     *
  *   labels provided.  Labels with value nil will have no label text.         *
  ****************************************************************************]]
do
	local function ColumnCreate ( self ) -- Creates a new column header for the table
		local Columns = self.Header;
		local Index = #Columns + 1;

		local Column = CreateFrame( "Button", nil, Columns );
		Column:SetID( Index );
		Column:SetFontString( Column:CreateFontString( nil, "ARTWORK", self.HeaderFont or "GameFontHighlightSmall" ) );
		Column:Disable();
		Column:SetPoint( "TOP" );
		Column:SetPoint( "BOTTOM" );
		if ( Index == 1 ) then
			Column:SetPoint( "LEFT" );
		else
			Column:SetPoint( "LEFT", Columns[ Index - 1 ], "RIGHT" );
		end

		-- Artwork
		local Left = Column:CreateTexture( nil, "BACKGROUND" );
		Left:SetPoint( "TOPLEFT" );
		Left:SetPoint( "BOTTOM" );
		Left:SetWidth( 5 );
		Left:SetTexture( [[Interface\FriendsFrame\WhoFrame-ColumnTabs]] );
		Left:SetTexCoord( 0, 0.078125, 0, 0.75 );
		local Right = Column:CreateTexture( nil, "BACKGROUND" );
		Right:SetPoint( "TOPRIGHT" );
		Right:SetPoint( "BOTTOM" );
		Right:SetWidth( 4 );
		Right:SetTexture( [[Interface\FriendsFrame\WhoFrame-ColumnTabs]] );
		Right:SetTexCoord( 0.90625, 0.96875, 0, 0.75 );
		local Middle = Column:CreateTexture( nil, "BACKGROUND" );
		Middle:SetPoint( "TOPLEFT", Left, "TOPRIGHT" );
		Middle:SetPoint( "BOTTOMRIGHT", Right, "BOTTOMLEFT" );
		Middle:SetTexture( [[Interface\FriendsFrame\WhoFrame-ColumnTabs]] );
		Middle:SetTexCoord( 0.078125, 0.90625, 0, 0.75 );

		Columns[ Index ] = Column;
		return Column;
	end
	function TableMethods:SetHeader ( ... )
		local Columns = self.Header;
		local NumColumns = select( "#", ... );
		if ( self.View.XScroll ) then -- Force correct view resize
			self.View.XScroll:SetValue( 0 );
		end

		-- Create necessary column buttons
		if ( #Columns < NumColumns ) then
			for Index = #Columns + 1, NumColumns do
				ColumnCreate( self );
			end
		end

		-- Fill out buttons
		for Index = 1, NumColumns do
			local Column = Columns[ Index ];
			local Value = select( Index, ... );
			Column:SetText( Value ~= nil and tostring( Value ) or nil );
			Column:Show();
		end
		for Index = NumColumns + 1, #Columns do -- Hide unused
			local Column = Columns[ Index ];
			Column:Hide();
			Column:SetText();
		end

		if ( not self:Clear() ) then
			self:Resize(); -- Fit to only headers
		end
		self.NumColumns = NumColumns;
	end
end
--[[****************************************************************************
  * Function: TableObject:AddRow                                               *
  * Description: Adds a row of strings to the table with the current header.   *
  ****************************************************************************]]
do
	local function RowAddElements ( self, Row ) -- Adds and anchors missing element strings
		local Columns = self.Header;
		for Index = Row:GetNumRegions() + 1, self.NumColumns do
			local Element = Row:CreateFontString( nil, "ARTWORK", self.ElementFont or "GameFontNormalSmall" );
			Element:SetPoint( "TOP" );
			Element:SetPoint( "BOTTOM" );
			Element:SetPoint( "LEFT", Columns[ Index ], ColumnPadding, 0 );
			Element:SetPoint( "RIGHT", Columns[ Index ], -ColumnPadding, 0 );
		end
	end
	local function UpdateElements ( self, Row, ... ) -- Shows, hides, and sets the values of elements
		for Index = 1, self.NumColumns do
			local Element = select( Index, ... );
			local Value = Row[ Index ];
			Element:SetText( Value ~= nil and tostring( Value ) or nil );
			Element:Show();
			Element:SetJustifyH( type( Value ) == "number" and "RIGHT" or "LEFT" );
		end
		for Index = self.NumColumns + 1, select( "#", ... ) do
			select( Index, ... ):Hide();
		end
	end
	function TableMethods:AddRow ( Key, ... )
		assert( Key == nil or self.Keys[ Key ] == nil, "Index key must be unique." );
		local Row = RowInsert( self ); -- Appended
		if ( Key ~= nil ) then
			self.Keys[ Key ] = Row;
			Row.Key = Key;
		end
		for Index = 1, self.NumColumns do
			Row[ Index ] = select( Index, ... );
		end

		RowAddElements( self, Row );
		UpdateElements( self, Row, Row:GetRegions() );

		self:Resize();
		return Row;
	end
end
--[[****************************************************************************
  * Function: TableObject:Resize                                               *
  * Description: Requests that the table be resized on the next update.        *
  ****************************************************************************]]
do
	local function Resize ( self ) -- Resizes all table headers and elements
		local Rows = self.Rows;
		local Width = 0;
		for Index = 1, self.NumColumns do
			local Column = self.Header[ Index ];
			local ColumnWidth = Column:GetTextWidth();
			for _, Row in ipairs( Rows ) do
				ColumnWidth = max( ColumnWidth, select( Index, Row:GetRegions() ):GetStringWidth() );
			end
			ColumnWidth = ColumnWidth + ColumnPadding * 2;
			Column:SetWidth( ColumnWidth );
			Width = Width + ColumnWidth;
		end
		self.Body:SetSize( Width > 0 and Width or 1, ( 1 + #Rows ) * RowHeight );
	end
	local function OnUpdate ( self ) -- Handler for tables that limits resizes to once per frame
		self:SetScript( "OnUpdate", nil );
		Resize( self );
	end
	function TableMethods:Resize ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end
--[[****************************************************************************
  * Function: TableObject:GetSelectionData                                     *
  * Description: Returns the data contained in the selected row.               *
  ****************************************************************************]]
function TableMethods:GetSelectionData ()
	if ( self.Selection ) then
		return self.Selection:GetData();
	end
end
--[[****************************************************************************
  * Function: TableObject:SetSelection                                         *
  * Description: Sets the selection to a given row.                            *
  ****************************************************************************]]
function TableMethods:SetSelection ( Row )
	assert( Row == nil or type( Row ) == "table", "Row must be an existing table row." );
	if ( Row ~= self.Selection ) then
		if ( self.Selection ) then -- Remove old selection
			self.Selection:UnlockHighlight();
		end

		self.Selection = Row;
		if ( Row ) then
			Row:LockHighlight();
		end
		if ( self.OnSelect ) then
			self:OnSelect( self:GetSelectionData() );
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: TableObject:SetSelection                                         *
  * Description: Sets the selection to a row indexed by the given key.         *
  ****************************************************************************]]
function TableMethods:SetSelectionByKey ( Key )
	return self:SetSelection( self.Keys[ Key ] );
end




--[[****************************************************************************
  * Function: lib.New                                                          *
  * Description: Creates a new table.                                          *
  ****************************************************************************]]
do
	local ViewOnSizeChanged, HeaderOnSizeChanged; -- Resizes when viewing area/table data width changes
	do
		local function RowsResize ( self ) -- Adjusts row widths to fill the table without breaking the scrollframe
			self.Rows:SetWidth( max( 1, max( self.View:GetWidth(), self.Header:GetWidth() ) - 1 ) );
		end
		function ViewOnSizeChanged ( self ) -- Viewing area width changes
			RowsResize( self:GetParent() );
		end
		function HeaderOnSizeChanged ( self ) -- Table data width changes
			RowsResize( self.Table );
		end
	end

	-- Handlers for scrollwheel and scrollbar increment/decrement
	local function ScrollHorizontal ( View, Delta ) 
		local XScroll = View.XScroll;
		XScroll:SetValue( XScroll:GetValue() + Delta * XScroll:GetWidth() / 2 )
	end
	local function ScrollVertical ( View, Delta )
		local YScroll = View.YScroll;
		YScroll:SetValue( YScroll:GetValue() + Delta * YScroll:GetHeight() / 2 )
	end

	local function OnMouseWheel ( self, Delta ) -- Scrolls with the mousewheel vertically, or horizontally if shift is held
		local View = self.View;
		if ( View:GetHorizontalScrollRange() > 0 and ( View:GetVerticalScrollRange() == 0 or IsShiftKeyDown() ) ) then
			ScrollHorizontal( View, -Delta );
		else
			ScrollVertical( View, -Delta );
		end
	end

	local function OnValueChangedHorizontal ( self, HorizontalScroll ) -- Horizontal scrollbar updates
		local View = self:GetParent();
		View:SetHorizontalScroll( HorizontalScroll );

		local Min, Max = self:GetMinMaxValues();
		View.Left[ HorizontalScroll == Min and "Disable" or "Enable" ]( View.Left );
		View.Right[ HorizontalScroll == Max and "Disable" or "Enable" ]( View.Right );
	end
	local function OnValueChangedVertical ( self, VerticalScroll ) -- Vertical scrollbar updates
		local View = self:GetParent();
		View:SetVerticalScroll( VerticalScroll );

		local Min, Max = self:GetMinMaxValues();
		View.Up[ VerticalScroll == Min and "Disable" or "Enable" ]( View.Up );
		View.Down[ VerticalScroll == Max and "Disable" or "Enable" ]( View.Down );
	end

	local OnScrollRangeChanged; -- Adds and adjusts scrollbars when necessary
	do
		local function CreateScrollBar ( View, ScrollScript ) -- Creates a scrollbar, decrement button, and increment button
			local Scroll = CreateFrame( "Slider", nil, View );
			Scroll:Hide();
			Scroll:SetThumbTexture( [[Interface\Buttons\UI-ScrollBar-Knob]] );
			local Dec = CreateFrame( "Button", nil, Scroll, "UIPanelScrollUpButtonTemplate" );
			local Inc = CreateFrame( "Button", nil, Scroll, "UIPanelScrollDownButtonTemplate" );
			Dec:SetScript( "OnClick", function ()
				PlaySound( "UChatScrollButton" );
				ScrollScript( View, -1 );
			end );
			Inc:SetScript( "OnClick", function ()
				PlaySound( "UChatScrollButton" );
				ScrollScript( View, 1 );
			end );
			local Thumb = Scroll:GetThumbTexture();
			Thumb:SetSize( Dec:GetSize() );
			Thumb:SetTexCoord( 0.25, 0.75, 0.25, 0.75 ); -- Remove transparent border
			local Background = Scroll:CreateTexture( nil, "BACKGROUND" );
			Background:SetTexture( 0, 0, 0, 0.5 );
			Background:SetAllPoints();
			return Scroll, Dec, Inc;
		end
		local function RotateTextures ( ... ) -- Rotates all regions 90 degrees CCW
			for Index = 1, select( "#", ... ) do
				select( Index, ... ):SetTexCoord( 0.75, 0.25, 0.25, 0.25, 0.75, 0.75, 0.25, 0.75 );
			end
		end
		function OnScrollRangeChanged ( View, XRange, YRange )
			local Table = View:GetParent();
			local XScroll, YScroll = View.XScroll, View.YScroll;
			Table:EnableMouseWheel( XRange > 0 or YRange > 0 ); -- Enable only if scrollable

			-- Horizontal scrolling
			if ( XRange > 0 ) then
				if ( not XScroll ) then -- Create scrollbar
					XScroll, View.Left, View.Right = CreateScrollBar( View, ScrollHorizontal );
					View.XScroll = XScroll;
					View.Left:SetPoint( "BOTTOMLEFT", Table );
					XScroll:SetPoint( "BOTTOMLEFT", View.Left, "BOTTOMRIGHT" );
					XScroll:SetPoint( "TOPRIGHT", View.Right, "TOPLEFT" );
					XScroll:SetOrientation( "HORIZONTAL" );
					XScroll:SetScript( "OnValueChanged", OnValueChangedHorizontal );
					RotateTextures( View.Left:GetRegions() );
					RotateTextures( View.Right:GetRegions() );
				end
				if ( not XScroll:IsShown() ) then -- Show and position scrollbar
					XScroll:Show();
					View:SetPoint( "BOTTOM", XScroll, "TOP" );
				end
				-- Setup scrollbar's range
				View.Right:SetPoint( "BOTTOMRIGHT", Table, YRange > 0 and -View.Right:GetWidth() or 0, 0 );
				XScroll:SetMinMaxValues( 0, XRange );
				XScroll:SetValue( min( XScroll:GetValue(), XRange ) );
			elseif ( XScroll and XScroll:IsShown() ) then -- Hide scrollbar
				XScroll:SetValue( 0 ); -- Return to origin
				XScroll:Hide();
				View:SetPoint( "BOTTOM", Table );
			end

			-- Vertical scrolling
			if ( YRange > 0 ) then
				if ( not YScroll ) then -- Create scrollbar
					YScroll, View.Up, View.Down = CreateScrollBar( View, ScrollVertical );
					View.YScroll = YScroll;
					View.Up:SetPoint( "TOPRIGHT", Table );
					YScroll:SetPoint( "TOPRIGHT", View.Up, "BOTTOMRIGHT" );
					YScroll:SetPoint( "BOTTOMLEFT", View.Down, "TOPLEFT" );
					YScroll:SetScript( "OnValueChanged", OnValueChangedVertical );
				end
				if ( not YScroll:IsShown() ) then -- Show and position scrollbar
					YScroll:Show();
					View:SetPoint( "RIGHT", YScroll, "LEFT" );
				end
				-- Setup scrollbar's range
				View.Down:SetPoint( "BOTTOMRIGHT", Table, 0, XRange > 0 and View.Down:GetHeight() or 0 );
				YScroll:SetMinMaxValues( 0, YRange );
				YScroll:SetValue( min( YScroll:GetValue(), YRange ) );
			elseif ( YScroll and YScroll:IsShown() ) then -- Hide scrollbar
				YScroll:SetValue( 0 ); -- Return to origin
				YScroll:Hide();
				View:SetPoint( "RIGHT", Table );
			end
		end
	end

	function lib.New ( Name, Parent, HeaderFont, ElementFont )
		local Table = CreateFrame( "Frame", Name, Parent );
		if ( not getmetatable( TableMethods ) ) then
			setmetatable( TableMethods, getmetatable( Table ) );
		end
		setmetatable( Table, lib.TableMeta );

		local Body = CreateFrame( "Frame" );
		Table.Body = Body;

		-- Rows frame expands its width to fill the table
		local Rows = CreateFrame( "Frame", nil, Body ); -- Note: Created before header so header always overlaps
		Table.Rows = Rows;
		Rows.Table = Table;
		Rows:SetPoint( "TOPLEFT", 0, -RowHeight ); -- Leave room for header to overlay
		Rows:SetPoint( "BOTTOM" );

		local Header = CreateFrame( "Frame", nil, Body );
		Table.Header = Header;
		Header.Table = Table;
		Header:SetPoint( "TOP", Table, 0, 1 ); -- Make sure rows don't show in the crack above the header
		Header:SetPoint( "LEFT" );
		Header:SetPoint( "RIGHT" );
		Header:SetHeight( RowHeight );
		Header:SetScript( "OnSizeChanged", HeaderOnSizeChanged );
		local Background = Header:CreateTexture( nil, "BACKGROUND" );
		Background:SetTexture( 0, 0, 0 );
		Background:SetPoint( "BOTTOMLEFT" );
		Background:SetPoint( "TOP" );
		Background:SetPoint( "RIGHT", Rows ); -- Expand with table

		local View = CreateFrame( "ScrollFrame", nil, Table );
		Table.View = View;
		View:SetPoint( "TOPLEFT" );
		View:SetPoint( "BOTTOM" );
		View:SetPoint( "RIGHT" );
		View:SetScrollChild( Body );
		View:SetScript( "OnScrollRangeChanged", OnScrollRangeChanged );
		View:SetScript( "OnSizeChanged", ViewOnSizeChanged );

		Table.Keys = {};
		Table.UnusedRows = {};
		Table.HeaderFont = HeaderFont;
		Table.ElementFont = ElementFont;

		Table:SetScript( "OnMouseWheel", OnMouseWheel );
		Table:SetHeader(); -- Clear all and resize
		return Table;
	end
end

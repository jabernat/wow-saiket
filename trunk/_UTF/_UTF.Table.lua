--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Table.lua - Simple string table control.                              *
  ****************************************************************************]]


local _UTF = _UTF;
local me = {};
_UTF.Table = me;

me.RowMeta = { __index = {}; };
local RowMethods = me.RowMeta.__index;
me.TableMeta = { __index = {}; };
local TableMethods = me.TableMeta.__index;

local RowHeight = 14;
local ColumnPadding = 6;




--[[****************************************************************************
  * Function: local RowOnClick                                                 *
  * Description: Selects a row element when the row is clicked.                *
  ****************************************************************************]]
local function RowOnClick ( self )
	self:GetParent():SetSelection( self );
end
--[[****************************************************************************
  * Function: local RowAddElements                                             *
  * Description: Adds and anchors missing element strings.                     *
  ****************************************************************************]]
local function RowAddElements ( self, Row )
	local Columns = self.Header;
	for Index = Row:GetNumRegions() + 1, self.NumColumns do
		local Element = Row:CreateFontString( nil, "ARTWORK", self.ElementFont or "GameFontNormalSmall" );
		Element:SetPoint( "TOP" );
		Element:SetPoint( "BOTTOM" );
		Element:SetPoint( "LEFT", Columns[ Index ], ColumnPadding, 0 );
		Element:SetPoint( "RIGHT", Columns[ Index ], -ColumnPadding, 0 );
	end
end
--[[****************************************************************************
  * Function: local RowInsert                                                  *
  * Description: Creates a new row button for the table.                       *
  ****************************************************************************]]
local function RowInsert ( self, Index )
	Index = Index or #self + 1;
	local Row = next( self.UnusedRows );
	if ( Row ) then
		self.UnusedRows[ Row ] = nil;
		Row:Show();
	else
		Row = CreateFrame( "Button", nil, self );
		Row:SetScript( "OnClick", RowOnClick );
		Row:RegisterForClicks( "LeftButtonUp" );
		Row:SetHeight( RowHeight );
		Row:SetPoint( "LEFT" );
		Row:SetPoint( "RIGHT" );
		Row:SetHighlightTexture( "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar", "ADD" );
		-- Apply row methods
		if ( not getmetatable( RowMethods ) ) then
			setmetatable( RowMethods, getmetatable( Row ) );
		end
		setmetatable( Row, me.RowMeta );
	end

	if ( self[ Index ] ) then -- Move old row below new one
		self[ Index ]:SetPoint( "TOP", Row, "BOTTOM" );
	end
	Row:SetPoint( "TOP", Index == 1 and self.Header or self[ Index - 1 ], "BOTTOM" );

	tinsert( self, Index, Row );
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
		local Row = self[ Index ];
		tremove( self, Index );
		self.UnusedRows[ Row ] = true;
		Row:Hide();
		Row.Key = nil;
		ClearElements( self.NumColumns, Row:GetRegions() );
		for Column = 1, self.NumColumns do -- Remove values
			Row[ Column ] = nil;
		end
		-- Reanchor next row
		if ( self[ Index ] ) then
			self[ Index ]:SetPoint( "TOP", Index == 1 and self.Header or self[ Index - 1 ], "BOTTOM" );
		end
	end
end

--[[****************************************************************************
  * Function: local ColumnCreate                                               *
  * Description: Creates a new column header for the table.                    *
  ****************************************************************************]]
local function ColumnCreate ( self )
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
	Left:SetTexture( "Interface\\FriendsFrame\\WhoFrame-ColumnTabs" );
	Left:SetTexCoord( 0, 0.078125, 0, 0.75 );
	local Right = Column:CreateTexture( nil, "BACKGROUND" );
	Right:SetPoint( "TOPRIGHT" );
	Right:SetPoint( "BOTTOM" );
	Right:SetWidth( 4 );
	Right:SetTexture( "Interface\\FriendsFrame\\WhoFrame-ColumnTabs" );
	Right:SetTexCoord( 0.90625, 0.96875, 0, 0.75 );
	local Middle = Column:CreateTexture( nil, "BACKGROUND" );
	Middle:SetPoint( "TOPLEFT", Left, "TOPRIGHT" );
	Middle:SetPoint( "BOTTOMRIGHT", Right, "BOTTOMLEFT" );
	Middle:SetTexture( "Interface\\FriendsFrame\\WhoFrame-ColumnTabs" );
	Middle:SetTexCoord( 0.078125, 0.90625, 0, 0.75 );

	Columns[ Index ] = Column;
	return Column;
end

--[[****************************************************************************
  * Function: local Resize                                                     *
  * Description: Resizes all table headers and elements.                       *
  ****************************************************************************]]
local function Resize ( self )
	local Width = 0;
	for Index = 1, self.NumColumns do
		local Column = self.Header[ Index ];
		local ColumnWidth = Column:GetTextWidth();
		for _, Row in ipairs( self ) do
			ColumnWidth = max( ColumnWidth, select( Index, Row:GetRegions() ):GetStringWidth() );
		end
		ColumnWidth = ColumnWidth + ColumnPadding * 2;
		Column:SetWidth( ColumnWidth );
		Width = Width + ColumnWidth;
	end

	local MinWidth = self.MinWidth or 1; -- Never set width to 0
	if ( MinWidth > Width and self.NumColumns > 0 ) then
		local LastColumn = self.Header[ #self.Header ];
		LastColumn:SetWidth( LastColumn:GetWidth() + ( MinWidth - Width ) );
	end
	self:SetWidth( max( Width, MinWidth ) );
	self:SetHeight( ( 1 + #self ) * RowHeight );
end
--[[****************************************************************************
  * Function: local OnUpdate                                                   *
  * Description: Handler for tables that limits resizes to once per frame.     *
  ****************************************************************************]]
local function OnUpdate ( self )
	self:SetScript( "OnUpdate", nil );
	Resize( self );
end




--[[****************************************************************************
  * Function: RowObject:GetNumRegions                                          *
  ****************************************************************************]]
do
	local RowMethodsOriginal = getmetatable( ScriptErrorsButton ).__index; -- Generic button metatable
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
	if ( #self > 0 ) then
		self:SetSelection();
		wipe( self.Keys );
		for Index = #self, 1, -1 do -- Remove in reverse so rows don't move mid-loop
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
function TableMethods:SetHeader ( ... )
	local Columns = self.Header;
	local NumColumns = select( "#", ... );
	self.NumColumns = NumColumns;

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

	self:Clear();
end
--[[****************************************************************************
  * Function: TableObject:AddRow                                               *
  * Description: Adds a row of strings to the table with the current header.   *
  ****************************************************************************]]
do
	local function UpdateElements ( self, Row, ... )
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
		self.Keys[ Key ] = Row;
		Row.Key = Key;
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
function TableMethods:Resize ()
	self:SetScript( "OnUpdate", OnUpdate );
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
		if ( type( self.OnSelect ) == "function" ) then
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
  * Function: TableObject:SetMinWidth                                          *
  * Description: Sets a minimum width that the table must occupy.              *
  ****************************************************************************]]
function TableMethods:SetMinWidth ( MinWidth )
	assert( not MinWidth or ( tonumber( MinWidth ) and MinWidth > 0 ), "MinWidth must be a positive number or nil." );
	MinWidth = tonumber( MinWidth );
	if ( self.MinWidth ~= MinWidth ) then
		self.MinWidth = MinWidth;
		self:Resize();
	end
end




--[[****************************************************************************
  * Function: _UTF.Table.New                                                   *
  * Description: Creates a new table.                                          *
  ****************************************************************************]]
function me.New ( Name, Parent, HeaderFont, ElementFont )
	local Table = CreateFrame( "Frame", Name, Parent );
	if ( not getmetatable( TableMethods ) ) then
		setmetatable( TableMethods, getmetatable( Table ) );
	end
	setmetatable( Table, me.TableMeta );

	Table.HeaderFont = HeaderFont;
	Table.ElementFont = ElementFont;

	local Header = CreateFrame( "Frame", nil, Table );
	Table.Header = Header;
	Header:SetPoint( "TOPLEFT" );
	Header:SetPoint( "RIGHT" );
	Header:SetHeight( RowHeight );

	Table.Keys = {};
	Table.UnusedRows = {};
	Table:SetHeader(); -- Clear all and resize

	return Table;
end

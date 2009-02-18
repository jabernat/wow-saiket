--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Table.lua - Simple string table control.                              *
  ****************************************************************************]]


local _UTF = _UTF;
local me = {};
_UTF.Table = me;

me.Methods = {};

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
	for Index = #Row + 1, #Columns do
		local Element = Row:CreateFontString( nil, "ARTWORK", self.ElementFont or "GameFontNormalSmall" );
		Element:SetJustifyH( "LEFT" );
		Element:SetPoint( "TOP" );
		Element:SetPoint( "BOTTOM" );
		Element:SetPoint( "LEFT", Columns[ Index ], ColumnPadding, 0 );
		Element:SetPoint( "RIGHT", Columns[ Index ], -ColumnPadding, 0 );
		Row[ Index ] = Element;
	end
end
--[[****************************************************************************
  * Function: local RowCreate                                                  *
  * Description: Creates a new row button for the table.                       *
  ****************************************************************************]]
local function RowCreate ( self )
	local Rows = self;
	local ID = #Rows + 1;

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
		Row:SetHighlightTexture( "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar", "ADD" );
	end
	Row:SetPoint( "TOP", ID == 1 and self.Header or Rows[ ID - 1 ], "BOTTOM" );

	RowAddElements( self, Row );

	Rows[ ID ] = Row;
	return Row;
end

--[[****************************************************************************
  * Function: local ColumnOnClick                                              *
  * Description: Calls the column's defined sort function.                     *
  ****************************************************************************]]
local function ColumnOnClick ( self, ... )
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	if ( type( self.OnClick ) == "function" ) then
		self:OnClick( ... );
	end
end
--[[****************************************************************************
  * Function: local ColumnCreate                                               *
  * Description: Creates a new column header for the table.                    *
  ****************************************************************************]]
local function ColumnCreate ( self )
	local Columns = self.Header;
	local ID = #Columns + 1;

	local Column = CreateFrame( "Button", nil, Columns );
	Column:SetID( ID );
	Column:SetFontString( Column:CreateFontString( nil, "ARTWORK", self.HeaderFont or "GameFontHighlightSmall" ) );
	Column:RegisterForClicks( "LeftButtonUp" );
	Column:SetScript( "OnClick", ColumnOnClick );
	Column:SetPoint( "TOP" );
	Column:SetPoint( "BOTTOM" );
	if ( ID == 1 ) then
		Column:SetPoint( "LEFT" );
	else
		Column:SetPoint( "LEFT", Columns[ ID - 1 ], "RIGHT" );
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
	Column:SetHighlightTexture( "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD" );

	Columns[ ID ] = Column;
	return Column;
end

--[[****************************************************************************
  * Function: local Resize                                                     *
  * Description: Resizes all table headers and elements.                       *
  ****************************************************************************]]
local function Resize ( self )
	local Columns = self.Header;

	local Width = 0;
	for Index, Column in ipairs( Columns ) do
		if ( not Column:IsShown() ) then
			break;
		else
			local ColumnWidth = Column:GetTextWidth();
			for _, Row in ipairs( self ) do
				ColumnWidth = max( ColumnWidth, Row[ Index ]:GetStringWidth() );
			end
			ColumnWidth = ColumnWidth + ColumnPadding * 2;
			Column:SetWidth( ColumnWidth );
			Width = Width + ColumnWidth;
		end
	end

	local MinWidth = self.MinWidth or 1;
	if ( MinWidth > Width and #Columns > 0 ) then
		local LastColumn = Columns[ #Columns ];
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
  * Function: _UTF.Table.Methods:Clear                                         *
  * Description: Empties the table of all rows.                                *
  ****************************************************************************]]
function me.Methods:Clear ()
	if ( self.Selection ) then
		self.Selection:UnlockHighlight();
		self.Selection = nil;
		if ( type( self.OnSelect ) == "function" ) then
			self:OnSelect();
		end
	end
	wipe( self.Keys );
	for Index, Row in ipairs( self ) do
		self[ Index ] = nil;
		self.UnusedRows[ Row ] = true;
		Row:Hide();
		Row.Key = nil;
		for _, Element in ipairs( Row ) do
			Element:Hide();
			Element:SetText();
			Element.Value = nil;
		end
	end
	self:Resize();
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:SetHeader                                     *
  * Description: Sets the header configuration for the data table.  Accepts a  *
  *   list of argument pairs representing column names and corresponding       *
  *   header click callbacks.  Any non-function callback disables that         *
  *   column's header button.                                                  *
  ****************************************************************************]]
function me.Methods:SetHeader ( ... )
	local Columns = self.Header;
	local ColumnCount = ceil( select( "#", ... ) / 2 );
	self.ColumnCount = ColumnCount;

	-- Create necessary column buttons
	if ( #Columns < ColumnCount ) then
		for Index = #Columns + 1, ColumnCount do
			ColumnCreate( self );
		end
		-- Add new elements to rows
		for _, Row in ipairs( self ) do
			RowAddElements( self, Row );
		end
	end

	-- Fill out buttons
	for Index, Column in ipairs( Columns ) do
		if ( Index > ColumnCount ) then
			Column:Hide();
			Column:SetText();
			Column:SetScript( "OnClick", nil );
		else
			local Value = select( Index * 2 - 1, ... );
			Column:SetText( Value ~= nil and tostring( Value ) or nil );

			local OnClick = select( Index * 2, ... );
			Column.OnClick = type( OnClick ) == "function" and OnClick or nil;
			Column[ Column.OnClick and "Enable" or "Disable" ]( Column );
			Column:Show();
		end
	end

	self:Clear();
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:AddRow                                        *
  * Description: Adds a row of strings to the table with the current header.   *
  ****************************************************************************]]
function me.Methods:AddRow ( Key, ... )
	local Row = RowCreate( self );
	assert( Key == nil or self.Keys[ Key ] == nil, "Index key must be unique." );
	self.Keys[ Key ] = Row;
	Row.Key = Key;
	for Index = 1, self.ColumnCount do
		local Element = Row[ Index ];
		local Value = select( Index, ... );
		Element.Value = Value;
		Element:SetText( Value ~= nil and tostring( Value ) or nil );
		Element:Show();
	end
	-- Hide unused elements
	for Index = self.ColumnCount + 1, #Row do
		Row[ Index ]:Hide();
	end

	self:Resize();
	return Row;
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:Resize                                        *
  * Description: Requests that the table be resized on the next update.        *
  ****************************************************************************]]
function me.Methods:Resize ()
	self:SetScript( "OnUpdate", OnUpdate );
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:GetSelection                                  *
  * Description: Returns the data contained in the selected row.               *
  ****************************************************************************]]
do
	local RowData = {};
	function me.Methods:GetSelection ()
		if ( self.Selection ) then
			wipe( RowData );
			for Index = 1, self.ColumnCount do
				RowData[ Index ] = self.Selection[ Index ].Value;
			end
			return self.Selection.Key, unpack( RowData );
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:SetSelection                                  *
  * Description: Sets the selection to a given row.                            *
  ****************************************************************************]]
function me.Methods:SetSelection ( Row )
	if ( type( Row ) ~= "table" ) then -- Lookup by key
		Row = self.Keys[ Row ];
	end
	if ( Row ~= self.Selection ) then
		if ( self.Selection ) then -- Remove old selection
			self.Selection:UnlockHighlight();
		end

		self.Selection = Row;
		if ( Row ) then
			Row:LockHighlight();
		end
		if ( type( self.OnSelect ) == "function" ) then
			self:OnSelect( self:GetSelection() );
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Table.Methods:SetMinWidth                                   *
  * Description: Sets a minimum width that the table must occupy.              *
  ****************************************************************************]]
function me.Methods:SetMinWidth ( MinWidth )
	assert( not MinWidth or ( tonumber( MinWidth ) and MinWidth > 0 ), "MinWidth must be a positive number or nil." );
	self.MinWidth = tonumber( MinWidth );
	self:Resize();
end




--[[****************************************************************************
  * Function: _UTF.Table.New                                                   *
  * Description: Creates a new table.                                          *
  ****************************************************************************]]
function me.New ( Name, Parent, HeaderFont, ElementFont )
	local Table = CreateFrame( "Frame", Name, Parent );
	-- Add shared methods
	for Key, Value in pairs( me.Methods ) do
		Table[ Key ] = Value;
	end
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

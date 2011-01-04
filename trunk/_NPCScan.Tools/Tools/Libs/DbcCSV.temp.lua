--[[ DbcCSV by Saiket
DbcCSV.lua: Parses CSV files into tables.
]]


local _G = _G;
local io = io;
local assert = assert;
local ipairs = ipairs;
local select = select;
local tonumber = tonumber;
local setmetatable = setmetatable;
module( "DbcCSV" );


do
	local function NextStringQuoted ( Text, Start )
		local Index, Quotes = Start + 1;

		-- Scan until an unescaped closing quote is found
		repeat
			Quotes, Index = Text:match( '("+)()', Index );
			if ( not Index ) then -- End of text
				_G.error( "Unmatched field quote." );
			end
		until ( #Quotes % 2 == 1 ) -- Last quote is unescaped

		local String = Text:sub( Start + 1, Index - 2 );
		return String:gsub( '""', '"' ), Index; -- Unescape any enclosed quotes
	end
	local function NextString ( Text, Start )
		if ( Text:match( '^"', Start ) ) then -- Quoted
			return NextStringQuoted( Text, Start );
		else
			local _, Next = Text:find( "[^,\n\r]*", Start );
			return Text:sub( Start, Next ), Next + 1;
		end
	end
	--- @return The next field in this row, and the position after it.
	local function NextField ( Text, Start )
		local Field, Start = NextString( Text, Start );
		if ( Text:match( "^,", Start ) ) then
			Start = Start + 1;
		end
		return Field, Start;
	end

	--- @return Table containing line parts, and the end offset of the line.
	function ParseLine ( Text, Start )
		local Row;
		while ( true ) do
			if ( Start >= #Text ) then
				return Row;
			end

			local Newlines = Text:match( "^[\r\n]+", Start );
			if ( Newlines ) then
				return Row, Start + #Newlines;
			end

			if ( not Row ) then
				Row = {};
			end
			Row[ #Row + 1 ], Start = NextField( Text, Start );
		end
	end
end


--- Cast data types into equivalent Lua data types.
local function ConvertType ( Value, Type )
	if ( Type == "bool" ) then
		return Value == "1";
	elseif ( Type == "long" or Type == "float" or Type == "byte" ) then
		return tonumber( Value );
	else -- "flags" or "str" are kept as string data
		return Value;
	end
end
--- Reads a CSV file and packs its contents into a table.
-- The first row is used as type info for interpreting the rest of the file.
-- @param Key  Optional column number to use for each row's key.  If omitted,
--   rows are inserted as a list in the order they are read.
-- @param ...  Column name settings.  Logically false values will omit their
--   respective columns.  True will save that column data in its row table
--   using the original column number.  Anything else will be used as a table
--   key for that column's data.
function Parse ( Filename, Key, ... )
	if ( Key ) then
		Key = assert( tonumber( Key ), "Key must be a column nunber." );
	end

	local File = assert( io.open( Filename, "rb" ) );
	local Text = assert( File:read( "*a" ) );
	assert( File:close() );

	local Row, Start = ParseLine( Text, 1 );
	local Types = assert( Row, "Type row missing." );
	local Data = setmetatable( {}, { __index = {
		Types = Types; -- Put types in a meta-index so pairs won't catch it
	}; } );
	if ( Key and ( not Row[ Key ] or Row[ Key ] == "None" ) ) then
		_G.error( "Key column has no data type." );
	end

	Row, Start = ParseLine( Text, Start );
	while ( Row ) do
		if ( not Key ) then -- Save rows in the order they're read
			Data[ #Data + 1 ] = Row;
		end

		for Index, Type in ipairs( Types ) do
			if ( Type == "None" ) then -- Remove unused column
				Row[ Index ] = nil;
			else
				if ( Index == Key ) then -- Use this field to index the row
					Data[ ConvertType( Row[ Index ], Type ) ] = Row;
				end

				local Name = select( Index, ... );
				if ( not Name ) then -- Remove excluded column
					Row[ Index ] = nil;
				else -- Use field
					local Field = ConvertType( Row[ Index ], Type );

					-- Move named fields
					if ( Name == true ) then -- Use order rows are read in
						Row[ Index ] = Field; -- Update field data type
					else
						Row[ Index ] = nil; -- Remove original column
						Row[ Name ] = Field;
					end
				end
			end
		end
		Row, Start = ParseLine( Text, Start );
	end

	return Data;
end
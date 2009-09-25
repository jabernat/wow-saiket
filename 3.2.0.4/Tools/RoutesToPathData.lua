--[[ Tools/RoutesToPathData.lua - Converts all recognized Routes paths to
     compatible pathdata used by _NPCScan.Overlay.

1. Install Routes addon by Xinhuan. <http://wow.curse.com/downloads/wow-addons/details/routes.aspx>
2. Create a blank path in the desired zone, named with a format
   "Overlay:{NPC ID}:{NPC Name}[:{Region Number}]".  Region Number is optional,
   and only serves to separate different paths used by mobs (i.e. "1", "2", etc.)
3. Outline the region you want shaded in a clockwise manner.  To create a hollow
   region, create a "C"-looking shape and align the two end segments.

When all paths are drawn, reload your UI and run this script with a standalone
Lua 5.1 interpreter.  The <../_NPCScan.Overlay.PathData.lua> data file will be
overwritten.

If the program appears to lock up, one of your paths is "inside-
out" (traced counter-clockwise) or overlaps itself.
]]




local AccountName = assert( assert( io.open( "AccountName.txt" ) ):read(), "AccountName.txt must have account name on first line." );
local RoutesDataFilename = [[..\..\..\..\WTF\Account\]]..AccountName..[[\SavedVariables\Routes.lua]];
local OutputFilename = [[..\_NPCScan.Overlay.PathData.lua]];

require( "bit" );




local EscapeString;
do
	local EscapeSequences = {
		--[ "\a" ] = "\\a"; -- Bell
		--[ "\b" ] = "\\b"; -- Backspace
		--[ "\t" ] = "\\t"; -- Horizontal tab
		[ "\n" ] = "\\n"; -- Newline
		--[ "\v" ] = "\\v"; -- Vertical tab
		--[ "\f" ] = "\\f"; -- Form feed
		[ "\r" ] = "\\r"; -- Carriage return
		[ "\\" ] = "\\\\"; -- Backslash
		[ "\"" ] = "\\\""; -- Quotation mark
	};
	--[[ Add all non-printed characters to replacement table
	for Index = 0, 31 do
		local Character = string.char( Index );
		if ( not EscapeSequences[ Character ] ) then
			EscapeSequences[ Character ] = ( "\\%03d" ):format( Index );
		end
	end
	for Index = 127, 255 do
		local Character = string.char( Index );
		if ( not EscapeSequences[ Character ] ) then
			EscapeSequences[ Character ] = ( "\\%03d" ):format( Index );
		end
	end]]

	function EscapeString ( Input )
		--return ( Input:gsub( "[%z\1-\31\"\\\127-\255]", EscapeSequences ) );
		return ( Input:gsub( "[\r\n\"\\]", EscapeSequences ) );
	end
end




local PolyLineToTris;
do
	local function RemoveCoord ( PolyLine, Index )
		Index = ( Index - 1 ) % #PolyLine + 1;
		table.remove( PolyLine, Index );
		return Index;
	end
	local function GetCoord ( PolyLine, Index )
		local Data = PolyLine[ ( Index - 1 ) % #PolyLine + 1 ];
		local X, Y = math.floor( Data / 10000 ) / 10000, ( Data % 10000 ) / 10000;
		Y = 1 - Y;
		return X, Y;
	end
	local function IsPointInTri ( Ax, Ay, Bx, By, Cx, Cy, Px, Py )
		local V0x, V0y, V1x, V1y, V2x, V2y = Ax - Bx, Ay - By, Cx - Bx, Cy - By, Px - Bx, Py - By;

		local Dot00 = V0x * V0x + V0y * V0y;
		local Dot01 = V0x * V1x + V0y * V1y;
		local Dot02 = V0x * V2x + V0y * V2y;
		local Dot11 = V1x * V1x + V1y * V1y;
		local Dot12 = V1x * V2x + V1y * V2y;

		local Denominator = Dot00 * Dot11 - Dot01 * Dot01;
		local u = ( Dot11 * Dot02 - Dot01 * Dot12 ) / Denominator;
		local v = ( Dot00 * Dot12 - Dot01 * Dot02 ) / Denominator;

		return u > 0 and v > 0 and u + v < 1;
	end

	local function TriTableAdd ( Table, ... )
		for Index = 1, select( "#", ... ), 2 do
			local X, Y = select( Index, ... );
			Table[ #Table + 1 ] = X;
			Table[ #Table + 1 ] = 1 - Y;
		end
	end
	local function TriTableCompile ( Table )
		for Index, Value in ipairs( Table ) do
			Value = math.floor( 65535 * Value + 0.5 );
			Table[ Index ] = string.char( bit.brshift( Value, 8 ), bit.band( Value, 255 ) );
		end
		return table.concat( Table );
	end

	function PolyLineToTris ( PolyLine )
		assert( #PolyLine > 2, "Not enough points in PolyLine." );
		local TriTable = {};

		local Index = 0;
		while ( #PolyLine > 3 ) do
			Index = Index + 1;
			local Ax, Ay = GetCoord( PolyLine, Index - 1 );
			local Bx, By = GetCoord( PolyLine, Index );
			local Cx, Cy = GetCoord( PolyLine, Index + 1 );

			if ( ( math.atan2( Cy - By, Cx - Bx ) - math.atan2( Ay - By, Ax - Bx ) ) % ( 2 * math.pi ) < math.pi ) then -- Convex
				-- Make sure no other points are inside this tri
				local Empty = true;
				for Index = Index + 2, Index + #PolyLine - 2 do
					if ( IsPointInTri( Ax, Ay, Bx, By, Cx, Cy, GetCoord( PolyLine, Index ) ) ) then
						Empty = false;
						break;
					end
				end
				if ( Empty ) then
					TriTableAdd( TriTable, Ax, Ay, Bx, By, Cx, Cy );
					Index = RemoveCoord( PolyLine, Index );
				end
			end
		end

		local Ax, Ay = GetCoord( PolyLine, 1 );
		local Bx, By = GetCoord( PolyLine, 2 );
		local Cx, Cy = GetCoord( PolyLine, 3 );
		TriTableAdd( TriTable, Ax, Ay, Bx, By, Cx, Cy );

		return TriTableCompile( TriTable );
	end
end




assert( loadfile( RoutesDataFilename ) )();
local Success, DB = pcall( function ()
	return RoutesDB.global.routes;
end );
assert( Success and DB, "Couldn't find path data in Routes saved variables." );
local Outfile = assert( io.open( OutputFilename, "w+" ) );

local Zones = {};
for ZoneName in pairs( DB ) do
	Zones[ #Zones + 1 ] = ZoneName;
end
table.sort( Zones );

Outfile:write( "_NPCScan.Overlay.PathData = {\n" );
for _, ZoneName in ipairs( Zones ) do
	local ZoneData = RoutesDB.global.routes[ ZoneName ];
	local Overlays = {};
	local Names = {};

	for RouteName, RouteData in pairs( ZoneData ) do
		if ( RouteName:match( "^Overlay:(.+)$" ) ) then
			local ID, Name = RouteName:match( "Overlay:([^:]+):([^:]+)" );
			ID = tonumber( ID );
			if ( ID and Name ) then
				if ( Overlays[ ID ] ) then
					table.insert( Overlays[ ID ], RouteName );
				else
					Overlays[ ID ] = { RouteName };
				end
			end
		end
	end
	for ID, Data in pairs( Overlays ) do
		Names[ #Names + 1 ] = Data[ 1 ];
	end

	if ( #Names > 0 ) then
		print( ZoneName );
		Outfile:write( ( "\t[ \"%s\" ] = {\n" ):format( ZoneName ) );

		table.sort( Names, function ( Arg1, Arg2 )
			return Arg1:match( "Overlay:[^:]+:([^:]+)" ) < Arg2:match( "Overlay:[^:]+:([^:]+)" );
		end );
		for _, RouteName in ipairs( Names ) do
			local ID, Name = RouteName:match( "Overlay:([^:]+):([^:]+)" );
			ID = tonumber( ID );
			local Data = Overlays[ ID ];

			print( ( "\t%s (%d)" ):format( Name, ID ) );
			local PolyData = "";
			for Index, RouteName in ipairs( Data ) do
				print( ( "\t\t%s" ):format( RouteName ) );
				PolyData = PolyData..PolyLineToTris( ZoneData[ RouteName ].route );
			end
			Outfile:write( ( "\t\t-- %s\n" ):format( Name ) );
			Outfile:write( ( "\t\t[ %d ] = \"%s\";\n" ):format( ID, EscapeString( PolyData ) ) );
		end
		Outfile:write( "\t};\n" );
	end
end
Outfile:write( "};\n" );

Outfile:flush();
Outfile:close();

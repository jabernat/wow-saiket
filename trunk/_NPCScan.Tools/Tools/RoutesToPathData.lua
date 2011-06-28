--[[ _NPCScan.Tools by Saiket
Tools/RoutesToPathData.lua - Converts all recognized Routes paths to compatible
  pathdata used by _NPCScan.Overlay.

1. Create a file in the Tools folder named <Account.dat>, and type in your
   account name, server, and character (ex. "AccountName/ServerName/CharacterName").
   This path is used to find your saved Routes settings.
2. Prepare database files from the WoW client: (Only needs to be done once per WoW patch)
   a. Find the latest versions of these DBC files in WoW's MPQ archives using a
      tool such as WinMPQ:
      * <DBFilesClient/WorldMapArea.dbc>
      * <DBFilesClient/AreaTable.dbc>
   b. Extract them to the <DBFilesClient> folder.
   c. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
      nneonneo's <DBCUtil.exe> program.
3. Define route data in-game:
   a. Install Routes addon by Xinhuan. <http://wow.curse.com/downloads/wow-addons/details/routes.aspx>
   b. Create a blank path in the desired zone, named with a format
      "Overlay:{NPC ID}:{NPC Name}[:{Region Number}]".  Region Number is
      optional, and only serves to separate different paths used by mobs (i.e.
      "1", "2", etc.)
   c. Outline the region you want shaded in a clockwise manner.  To create a
      hollow region, create a "C"-looking shape and align the two end segments.

When all paths are drawn, reload your UI and run this script with a standalone
Lua 5.1 interpreter.  The <../../_NPCScan.Overlay/_NPCScan.Overlay.PathData.lua>
data file will be overwritten.

If the program appears to lock up, one of your paths is "inside-out" (traced
counter-clockwise) or overlaps itself.
]]


local AccountFilename = [[Account.dat]];
local RoutesDataFilename = [[../../../../WTF/Account/%s/SavedVariables/Routes.lua]]; -- 1st arg is account name
local OutputFilename = [[../../_NPCScan.Overlay/_NPCScan.Overlay.PathData.lua]];


package.cpath = [[.\Libs\?.dll;]]..package.cpath;
package.path = [[.\Libs\?.lua;]]..package.path;
require( "bit" );
require( "DbcCsv" );




local function assertf ( Success, Format, ... ) -- Doesn't allocate error messages until needed
	if ( Success ) then
		return Success;
	end
	local Args = { ... }; -- Convert all to strings
	for Index = 1, select( "#", ... ) do
		Args[ Index ] = tostring( Args[ Index ] );
	end
	error( Format:format( unpack( Args, 1, select( "#", ... ) ) ) );
end




-- Load data files
print( "Parsing game data..." );

local AccountFile = assert( io.open( AccountFilename ) );
local AccountName = assertf( AccountFile:read(), "<%s> must have account data path on first line.", AccountFilename ):match( "^[^/]+" );
assert( AccountFile:close() );
assertf( AccountName and #AccountName > 0, "Missing account name in <%s>.", AccountFilename );


-- Create lookups for map filenames to IDs, and IDs to localized names
local WorldMapAreas = DbcCsv.Parse( [[DBFilesClient/WorldMapArea.dbc.csv]], 1,
	"ID", nil, "AreaTableID", "Filename", nil, nil, nil, nil, nil, nil, nil, "Flags" );
local AreaTable = DbcCsv.Parse( [[DBFilesClient/AreaTable.dbc.csv]], 1,
	"ID", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
	"Localization" );

local MapIDs, MapNames = {}, {};
local FLAG_PHASE = 0x2;
for ID, WorldMapArea in pairs( WorldMapAreas ) do
	if ( WorldMapArea.AreaTableID ~= 0 -- Not a continent
		and bit.band( tonumber( WorldMapArea.Flags, 16 ), FLAG_PHASE ) == 0 -- Not a phased map
	) then
		MapIDs[ WorldMapArea.Filename ] = ID;
		MapNames[ ID ] = AreaTable[ WorldMapArea.AreaTableID ].Localization;
	end
end


assert( loadfile( RoutesDataFilename:format( AccountName ) ) )();
local Success, DB = pcall( function ()
	return RoutesDB.global.routes;
end );
assert( Success and DB, "Couldn't find path data in Routes saved variables." );

local MapFilenames = {};
for MapFilename in pairs( DB ) do
	MapFilenames[ #MapFilenames + 1 ] = MapFilename;
end
table.sort( MapFilenames, function ( MapFilename1, MapFilename2 )
	return MapNames[ MapIDs[ MapFilename1 ] ] < MapNames[ MapIDs[ MapFilename2 ] ];
end );




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




local OutFile = assert( io.open( OutputFilename, "w+b" ) );

assert( OutFile:write( "-- AUTOMATICALLY GENERATED BY <_NPCScan.Tools/Tools/RoutesToPathData.lua>!\n" ) );
assert( OutFile:write( "select( 2, ... ).PathData = {\n" ) );
for _, MapFilename in ipairs( MapFilenames ) do
	local ZoneData = RoutesDB.global.routes[ MapFilename ];
	local Overlays = {};
	local Names = {};
	local IDs = {};

	for RouteName, RouteData in pairs( ZoneData ) do
		if ( RouteName:match( "^Overlay:(.+)$" ) ) then
			local ID = RouteName:match( "^Overlay:([^:]+):[^:]+" );
			ID = tonumber( ID );
			if ( ID ) then
				if ( Overlays[ ID ] ) then
					table.insert( Overlays[ ID ], RouteName );
				else
					Overlays[ ID ] = { RouteName };
				end
			end
		end
	end
	for ID, Data in pairs( Overlays ) do
		-- Sort route parts
		table.sort( Data, function ( Route1, Route2 )
			Route1 = tonumber( Route1:match( "^Overlay:[^:]+:[^:]+:([^:]+)" ) ) or 1;
			Route2 = tonumber( Route2:match( "^Overlay:[^:]+:[^:]+:([^:]+)" ) ) or 1;
			return Route1 < Route2;
		end );
		IDs[ #IDs + 1 ] = ID;
		Names[ ID ] = Data[ 1 ]:match( "^Overlay:[^:]+:([^:]+)" );
	end

	if ( #IDs > 0 ) then
		local MapID = MapIDs[ MapFilename ];
		local MapName = MapNames[ MapID ];
		print( ( "[Map:%d] %s" ):format( MapID, MapName ) );
		assert( OutFile:write( ( "\t[ %d ] = { -- %s\n" ):format( MapID, MapName ) ) );

		table.sort( IDs, function ( ID1, ID2 )
			return Names[ ID1 ] < Names[ ID2 ];
		end);
		for _, ID in ipairs( IDs ) do
			local Data = Overlays[ ID ];
			local Name = Names[ ID ];

			print( ( "\t[Npc:%d] %s" ):format( ID, Name or "Unknown" ) );
			local PolyData = "";
			for Index, RouteName in ipairs( Data ) do
				print( ( "\t\t%s" ):format( RouteName ) );
				PolyData = PolyData..PolyLineToTris( ZoneData[ RouteName ].route );
			end
			if ( Name ) then
				assert( OutFile:write( ( "\t\t-- %s\n" ):format( Name ) ) );
			end
			assert( OutFile:write( ( "\t\t[ %d ] = %q;\n" ):format( ID, PolyData ) ) );
		end
		assert( OutFile:write( "\t};\n" ) );
	end
end
assert( OutFile:write( "};\n" ) );

assert( OutFile:flush() );
assert( OutFile:close() );
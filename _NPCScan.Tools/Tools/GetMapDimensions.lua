--[[ _NPCScan.Tools by Saiket
Tools/GetMapDimensions.lua - Extracts necessary map sizes from WoW's data files.

1. Prepare database files from the WoW client: (Only needs to be done once per WoW patch)
   a. Find the latest versions of these DBC files in WoW's MPQ archives using a
      tool such as WinMPQ:
      * <DBFilesClient/Map.dbc>
      * <DBFilesClient/WorldMapContinent.dbc>
      * <DBFilesClient/WorldMapArea.dbc>
      * <DBFilesClient/AreaTable.dbc>
   b. Extract them to the <DBFilesClient> folder.
   c. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
      nneonneo's <DBCUtil.exe> program.
2. Convert routes to path data using the <RoutesToPathData.lua> tool.

Once <DBFilesClient> contains the up-to-date *.CSV files, run this script with a
standalone Lua 5.1 interpreter.  Output must be copied from the console into
_NPCScan.Overlay's "_NPCScan.Overlay.ZoneData.lua" source file.

Note: Multi-level maps such as Dalaran are unsupported.
]]


local InputFilename = [[../../_NPCScan.Overlay/_NPCScan.Overlay.PathData.lua]];


package.cpath = [[.\Libs\?.dll;]]..package.cpath;
package.path = [[.\Libs\?.lua;]]..package.path;
require( "DbcCSV" );




-- Read the pathdata with binary option enabled, otherwise it won't read it all
local InputFile = assert( io.open( InputFilename, "rb" ) );
local InputData = assert( InputFile:read( "*a" ) );
assert( InputFile:close() );

local Env = {};
assert( loadstring( InputData ) )( nil, Env );
local MapIDs = assert( Env.PathData, "PathData missing from _NPCScan.Overlay.PathData.lua." );


-- Create lookup tables from DBC CSV files
local Maps = DbcCSV.Parse( [[DBFilesClient/Map.dbc.csv]], 1,
	"ID", nil, nil, nil, nil, "Name" );
local WorldMapContinents = DbcCSV.Parse( [[DBFilesClient/WorldMapContinent.dbc.csv]], 2, -- Index by MapID
	"ID", "MapID" );
local WorldMapAreas = DbcCSV.Parse( [[DBFilesClient/WorldMapArea.dbc.csv]], 1,
	"ID", "ParentMapID", "AreaTableID", nil, "Ax", "Bx", "Ay", "By", "VirtualMapID" );
local AreaTable = DbcCSV.Parse( [[DBFilesClient/AreaTable.dbc.csv]], 1,
	"ID", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Localization" );




local MapNames = {};
-- Sort maps into their parent continents
for ID in pairs( MapIDs ) do
	local WorldMapArea = WorldMapAreas[ ID ]
	if ( WorldMapArea.AreaTableID ~= 0 ) then -- Not a continent
		MapNames[ ID ] = AreaTable[ WorldMapArea.AreaTableID ].Localization;

		-- Some maps are virtualized to other continents, such as Eversong Woods appearing on the Eastern Kingdoms map
		local Continent = WorldMapContinents[ WorldMapArea.VirtualMapID ~= -1 and WorldMapArea.VirtualMapID or WorldMapArea.ParentMapID ];
		if ( Continent ) then
			Continent[ #Continent + 1 ] = WorldMapArea;
		end
	end
end

-- Sort by the order continents are added to the game
local ContinentOrder = {};
for MapID, Continent in pairs( WorldMapContinents ) do
	ContinentOrder[ #ContinentOrder + 1 ] = Continent;
end
table.sort( ContinentOrder, function ( Continent1, Continent2 )
	return Continent1.ID < Continent2.ID;
end );




-- Print relevant map data
for _, Continent in ipairs( ContinentOrder ) do
	print( "\n-- "..Maps[ Continent.MapID ].Name );

	-- Sort zones by name
	table.sort( Continent, function ( WorldMapArea1, WorldMapArea2 )
		return MapNames[ WorldMapArea1.ID ] < MapNames[ WorldMapArea2.ID ];
	end	);

	for _, WorldMapArea in ipairs( Continent ) do
		print( ( "Add( %d, %f, %f ); -- %s" ):format( WorldMapArea.ID,
			WorldMapArea.Ax - WorldMapArea.Bx, -- Axes are flipped
			WorldMapArea.Ay - WorldMapArea.By,
			MapNames[ WorldMapArea.ID ] ) );
	end
end

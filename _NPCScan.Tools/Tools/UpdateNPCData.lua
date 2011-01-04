--[[ _NPCScan.Tools by Saiket
Tools/UpdateNPCData.lua - Updates NPC info with data from WowHead.

1. Find the latest versions of these DBC files in WoW's MPQ archives using a
   tool such as WinMPQ:
   * <DBFilesClient/Achievement.dbc>
   * <DBFilesClient/Achievement_Criteria.dbc>
   * <DBFilesClient/WorldMapArea.dbc>
2. Extract them to the <DBFilesClient> folder.
3. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
   nneonneo's <DBCUtil.exe> program.

Once data files are ready, run this script with a standalone Lua 5.1 interpreter.
The <../../_NPCScan.Tools/_NPCScan.Tools.NPCData.lua> data file will be overwritten.
]]


local AccountFilename = [[Account.dat]];
local SettingsFilename = [[../../../../WTF/Account/%s/SavedVariables/_NPCScan.lua]];
local OutputFilename = [[../_NPCScan.Tools.NPCData.lua]];


package.cpath = [[.\Libs\?.dll;]]..package.cpath;
package.path = [[.\Libs\?.lua;]]..package.path;
local http = require( "socket.http" );
require( "json" );
require( "bit" );
require( "DbcCsv" );




--- Doesn't allocate error messages until needed.
local function assertf ( Success, Format, ... )
	if ( Success ) then
		return Success;
	end
	local Args = { ... }; -- Convert all to strings
	for Index = 1, select( "#", ... ) do
		Args[ Index ] = tostring( Args[ Index ] );
	end
	error( Format:format( unpack( Args, 1, select( "#", ... ) ) ) );
end




-- Load list of NPCs
print( "Building NPC list..." );

local AccountFile = assert( io.open( AccountFilename ) );
local DataPath = assertf( AccountFile:read(),
	"<%s> must have account data path on first line.", AccountFilename );
assertf( #DataPath > 0, "Missing account data path in <%s>.", AccountFilename );

local Achievements = DbcCsv.Parse( [[DBFilesClient/Achievement.dbc.csv]], 1,
	"ID", nil, nil, "CriteriaParent", "Name" );

local AchievementCriteria = DbcCsv.Parse( [[DBFilesClient/Achievement_Criteria.dbc.csv]], 1,
	"ID", "AchievementID", "Type", "AssetID", nil, nil, nil, nil, nil, "Name" );

-- Load _NPCScan saved variables
print( "\tAdding _NPCScan custom list NPCs." );
assert( loadfile( SettingsFilename:format( DataPath ) ) )();
local Options = assert( _NPCScanOptionsCharacter,
	"Character options missing from _NPCScan saved variables." );
local Names = assert( Options.NPCs,
	"NPC data missing from _NPCScan saved variables." );
local AchievementsActive = assert( Options.Achievements,
	"Achievement data missing from _NPCScan saved variables." );

-- Remove temporary scans
for NpcID, Name in pairs( Names ) do
	if ( Name:match( "^!" ) ) then
		Names[ NpcID ] = nil;
	end
end

-- Find mobs that are criteria for achievements
local AchievementFilter = {};
--- Adds achievement ID and all its criteria to the Names list.
local function AddAchievement ( AchievementID )
	AchievementFilter[ AchievementID ] = true;

	local Achievement = Achievements[ AchievementID ];
	print( ( "\tAdding achievement [ %d ] %s." ):format(
		AchievementID, Achievement.Name ) );
	-- Recurse any achievements whos criteria must also be met
	local CriteriaParent = Achievement.CriteriaParent;
	if ( CriteriaParent ~= 0 ) then
		return AddAchievement( CriteriaParent );
	end
end

for AchievementID, Enabled in pairs( AchievementsActive ) do
	if ( Enabled ) then
		AddAchievement( AchievementID );
	end
end
for CriteriaID, Criteria in pairs( AchievementCriteria ) do
	if ( AchievementFilter[ Criteria.AchievementID ]
		and Criteria.Type == 0 -- Mob kill type
	) then
		Names[ Criteria.AssetID ] = Criteria.Name;
	end
end

local SortOrder = {};
for NpcID in pairs( Names ) do
	SortOrder[ #SortOrder + 1 ] = NpcID;
end
table.sort( SortOrder );




-- Read display IDs and NPC locations
print( "Reading NPC data..." );

-- Create a lookup of AreaTableIDs to zone IDs
local WorldMapAreas = DbcCsv.Parse( [[DBFilesClient/WorldMapArea.dbc.csv]], 1,
	"ID", nil, "AreaTableID", nil, nil, nil, nil, nil, nil, nil, nil, "Flags" );

local AreaMapIDs = {};
local FLAG_PHASE = 0x2;
for MapID, WorldMapArea in pairs( WorldMapAreas ) do
	if ( WorldMapArea.AreaTableID ~= 0 -- Not a continent
		and bit.band( tonumber( WorldMapArea.Flags, 16 ), FLAG_PHASE ) == 0 -- Not a phased map
	) then
		AreaMapIDs[ WorldMapArea.AreaTableID ] = MapID;
	end
end

local EncodeMapData;
do
	local MaxCoordValue = 2 ^ 16 - 1;
	local char, floor = string.char, math.floor;
	local rshift, band = bit.brshift, bit.band;
	--- Parses location data from WowHead.
	-- @return MapID, PointData for Data.
	function EncodeMapData ( Data )
		local CountMax, AreaKeyPrimary = 0;
		-- Find area where NPC was seen most
		for AreaKey, Phases in pairs( Data ) do
			local Count = 0;
			for PhaseID, PhaseData in pairs( Phases ) do
				Count = Count + PhaseData.count;
			end
			if ( CountMax < Count ) then
				CountMax, AreaKeyPrimary = Count, AreaKey;
			end
		end

		local AreaID = tonumber( AreaKeyPrimary );
		if ( AreaID ) then
			local MapID, Bytes = assertf( AreaMapIDs[ AreaID ],
				"MapID not found for area %d.", AreaID ), {};
			for PhaseID, PhaseData in pairs( Data[ AreaKeyPrimary ] ) do
				for _, Point in ipairs( PhaseData.coords ) do
					local X = floor( MaxCoordValue * Point[ 1 ] / 100 + 0.5 );
					local Y = floor( MaxCoordValue * Point[ 2 ] / 100 + 0.5 );
					Bytes[ #Bytes + 1 ] = char(
						rshift( X, 8 ), band( X, 255 ),
						rshift( Y, 8 ), band( Y, 255 ) );
				end
			end
			return MapID, table.concat( Bytes );
		end
	end
end

local DisplayIDs, MapIDs, PointData = {}, {}, {};
for _, NpcID in ipairs( SortOrder ) do
	print( ( "\t[ %d ] %s" ):format( NpcID, Names[ NpcID ] ) );
	local Success, ErrorMessage = pcall( function ()
		local Text, Status = http.request( [[http://www.wowhead.com/?npc=]]..NpcID );
		assertf( Text and Status == 200, "Request failed: Status code %d.", Status );

		local ModelData = Text:match( [[onclick="this%.blur%(%); ModelViewer%.show%((.-)%)">]] );
		local DisplayID = ModelData and tonumber( json.decode( ModelData ).displayId );
		if ( DisplayID ) then
			DisplayIDs[ NpcID ] = DisplayID;
		else
			print( "\t- Model data not found!" );
		end

		local MapID, Points;
		local NPCData = Text:match( [[<script type="text/javascript">//<!%[CDATA%[%s*var g_mapperData%s*=%s*(.-);]] );
		if ( NPCData ) then
			MapID, Points = EncodeMapData( json.decode( NPCData ) );
		end
		if ( MapID ) then
			MapIDs[ NpcID ], PointData[ NpcID ] = MapID, Points;
		else
			print( "\t- Location data not found!" );
		end
	end );
	if ( not Success ) then
		print( "\t- "..ErrorMessage );
	end
end




local OutFile = assert( io.open( OutputFilename, "w+" ) );

OutFile:write( "-- AUTOMATICALLY GENERATED BY <_NPCScan.Tools/Tools/UpdateNPCData.lua>!\n" );
OutFile:write( "local Tools = select( 2, ... );\n" );

-- Write NPC names
OutFile:write( "Tools.NPCNames = {\n" );
for _, NpcID in ipairs( SortOrder ) do
	OutFile:write( ( "\t[ %d ] = %q;\n" ):format( NpcID, Names[ NpcID ] ) );
end
OutFile:write( "};\n" );

-- Write NPC display IDs
OutFile:write( "Tools.NPCDisplayIDs = {\n" );
for _, NpcID in ipairs( SortOrder ) do
	local DisplayID = DisplayIDs[ NpcID ];
	if ( DisplayID ) then
		OutFile:write( ( "\t[ %d ] = %d;\n" ):format( NpcID, DisplayID ) );
	end
end
OutFile:write( "};\n" );

-- Write NPC map IDs
OutFile:write( "Tools.NPCMapIDs = {\n" );
for _, NpcID in ipairs( SortOrder ) do
	local MapID = MapIDs[ NpcID ];
	if ( MapID ) then
		OutFile:write( ( "\t[ %d ] = %d;\n" ):format( NpcID, MapID ) );
	end
end
OutFile:write( "};\n" );

-- Write NPC path data
OutFile:write( "Tools.NPCPointData = {\n" );
for _, NpcID in ipairs( SortOrder ) do
	local Data = PointData[ NpcID ];
	if ( Data ) then
		OutFile:write( ( "\t[ %d ] = %q;\n" ):format( NpcID, Data ) );
	end
end
OutFile:write( "};" );

OutFile:flush();
OutFile:close();
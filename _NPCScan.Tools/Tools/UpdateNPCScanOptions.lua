--[[ _NPCScan.Tools by Saiket
Tools/UpdateNPCScanOptions.lua - Updates a complete _NPCScan options file.

1. Find the latest versions of these DBC files in WoW's MPQ archives using a
   tool such as WinMPQ:
   * <DBFilesClient/Achievement.dbc>
   * <DBFilesClient/Achievement_Criteria.dbc>
   * <DBFilesClient/AreaTable.dbc>
   * <DBFilesClient/Map.dbc>
   * <DBFilesClient/WorldMapArea.dbc>
   * <DBFilesClient/WorldMapContinent.dbc>
2. Extract them to the <DBFilesClient> folder.
3. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
   nneonneo's <DBCUtil.exe> program.

Once data files are ready, run this script with a standalone Lua 5.1 interpreter.
The <../_NPCScan.lua> data file will be overwritten.
]]

local OutputFilename = [[../_NPCScan.lua]];
local LEVEL_MAX = 85; -- Max rare level to query for

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




-- Get list of all rares from WowHead
print( "Retrieving list of rares..." );
local NPCData = {};
do
	--- Adds query results to list, or recursively subdivides query if results omitted.
	local function QueryLevelRange ( LevelMin, LevelMax )
		print( ( "\tQuerying levels %d - %d..." ):format( LevelMin, LevelMax ) );
		local Path = ( [[http://www.wowhead.com/npcs?filter=cl=4:2;minle=%d;maxle=%d]] ):format(
			LevelMin, LevelMax );
		local Text, Status = http.request( Path );
		assertf( Text and Status == 200, "Request failed: Status code %d.", Status );

		local ListData = assert( Text:match(
			[[<script type="text/javascript">//<!%[CDATA%[%s*new Listview%((.-%));%s*//%]%]></script>]]
			), "Listview data not found." );
		local ResultsMax, ResultsShown = ListData:match( [[note: $WH%.sprintf%(LANG%.lvnote_npcsfound, (%d+), (%d+)%)]] );
		if ( ResultsMax ) then -- Too many results; Subdivide query
			print( ( "\t\tSubdividing %d query results." ):format( ResultsMax ) );
			local LevelMid = math.floor( ( LevelMin + LevelMax ) / 2 );
			QueryLevelRange( LevelMin, LevelMid );
			QueryLevelRange( LevelMid + 1, LevelMax );
		else -- Parse results
			local Data = json.decode( ListData );
			assertf( Data.template == "npc" and Data.id == "npcs",
				"Invalid list template %q or id %q.", Data.template, Data.id );
			for _, NPC in ipairs( assert( Data.data, "List data not found." ) ) do
				NPCData[ NPC.id ] = {
					Name = NPC.name;
					AreaIDs = ( NPC.location and #NPC.location > 0 and NPC.location ) or nil;
				};
			end
		end
	end
	QueryLevelRange( 1, LEVEL_MAX );
end


-- Remove achievement rares
print( "Removing achievement rares..." );
local AchievementsActive = {
	[ 1312 ] = true; -- Bloody Rare
	[ 2257 ] = true; -- Frostbitten
};
do
	local Achievements = DbcCsv.Parse( [[DBFilesClient/Achievement.dbc.csv]], 1,
		"ID", nil, nil, "CriteriaParent", "Name" );
	local AchievementFilter = {};

	--- Adds AchievementID and all its parents to achievement filter.
	local function AddAchievement ( AchievementID )
		AchievementFilter[ AchievementID ] = true;

		local Achievement = Achievements[ AchievementID ];
		print( ( "\tRemoving achievement [ %d ] %s." ):format(
			AchievementID, Achievement.Name ) );
		-- Recurse any achievements whos criteria must also be met
		if ( Achievement.CriteriaParent ~= 0 ) then
			return AddAchievement( Achievement.CriteriaParent );
		end
	end
	for AchievementID in pairs( AchievementsActive ) do
		AddAchievement( AchievementID );
	end

	local AchievementCriteria = DbcCsv.Parse( [[DBFilesClient/Achievement_Criteria.dbc.csv]], 1,
		"ID", "AchievementID", "Type", "AssetID" );
	for CriteriaID, Criteria in pairs( AchievementCriteria ) do
		if ( AchievementFilter[ Criteria.AchievementID ]
			and Criteria.Type == 0 -- Mob kill type
		) then
			NPCData[ Criteria.AssetID ] = nil;
		end
	end
end


-- Find continent order numbers for numeric WorldIDs
print( "Generating WorldIDs..." );
local WorldMapContinent = DbcCsv.Parse( [[DBFilesClient/WorldMapContinent.dbc.csv]], 2,
	"ID", "MapID" );
do
	local WorldMapAreas = DbcCsv.Parse( [[DBFilesClient/WorldMapArea.dbc.csv]], 1,
		"ID", "MapID", "AreaID", nil, nil, nil, nil, nil, nil, nil, nil, "Flags" );

	local Order = {};
	local FLAG_PHASE = 0x2;
	for ID, WorldMapArea in pairs( WorldMapAreas ) do
		local Continent = WorldMapContinent[ WorldMapArea.MapID ];
		if ( Continent and WorldMapArea.AreaID == 0 -- Is a continent
			and bit.band( tonumber( WorldMapArea.Flags, 16 ), FLAG_PHASE ) == 0 -- Not a phased map
		) then
			Continent.WorldMapAreaID, Order[ #Order + 1 ] = ID, Continent;
		end
	end
	-- Continents appear to be sorted by their WorldMapAreaIDs rather than ContinentIDs.
	-- Kalimdor and Eastern Kingdoms are in reverse order in WorldMapContinent.dbc.
	table.sort( Order, function ( Continent1, Continent2 )
		return Continent1.WorldMapAreaID < Continent2.WorldMapAreaID;
	end );
	for Index, Continent in ipairs( Order ) do
		Continent.Index = Index;
	end
end


local GetAreaContinent, GetAreaName;
do
	local Maps = DbcCsv.Parse( [[DBFilesClient/Map.dbc.csv]], 1,
		"ID", nil, nil, nil, nil, nil, "Name", "AreaID" );
	local AreaTable = DbcCsv.Parse( [[DBFilesClient/AreaTable.dbc.csv]], 1,
		"ID", "MapID", "ParentID", nil, nil, nil, nil, nil, nil, nil, nil, "Name" );

	--- @return Map table for given AreaID.
	local function GetAreaMap ( AreaID )
		return Maps[ AreaTable[ AreaID ].MapID ];
	end
	--- @return The continent ID of AreaID's map, or nil if not a continent.
	function GetAreaContinent ( AreaID )
		local Continent = WorldMapContinent[ GetAreaMap( AreaID ).ID ];
		return Continent and Continent.Index;
	end
	--- @return The localized name of AreaID's map.
	function GetAreaName ( AreaID )
		local Map = GetAreaMap( AreaID );
		if ( Map.AreaID == 0 ) then
			return Map.Name;
		else
			return AreaTable[ Map.AreaID ].Name;
		end
	end
end




-- Write _NPCScanOptionsCharacter data
print( "Writing _NPCScan options file..." );
local OutFile = assert( io.open( OutputFilename, "w+" ) );
assert( OutFile:write( [[
_NPCScanOptionsCharacter = {
	Version = "4.0.3.5";
	Achievements = {
]] ) );

-- Sort output by NPC ID
local Order = {};
for NpcID in pairs( NPCData ) do
	Order[ #Order + 1 ] = NpcID;
end
table.sort( Order );

-- Active achievement IDs
for AchievementID in pairs( AchievementsActive ) do
	assert( OutFile:write( ( "\t\t[ %d ] = true;\n" ):format( AchievementID ) ) );
end
assert( OutFile:write( [[
	};
	NPCs = {
]] ) );

-- Custom NPC names
for _, NpcID in ipairs( Order ) do
	assert( OutFile:write( ( "\t\t[ %d ] = %q;\n" ):format( NpcID, NPCData[ NpcID ].Name ) ) );
end
assert( OutFile:write( [[
	};
	NPCWorldIDs = {
]] ) );

-- Custom NPC worlds
for _, NpcID in ipairs( Order ) do
	local AreaIDs = NPCData[ NpcID ].AreaIDs;
	if ( AreaIDs ) then
		local WorldID;
		for _, AreaID in ipairs( AreaIDs ) do
			local WorldIDCurrent = GetAreaContinent( AreaID ) or GetAreaName( AreaID );
			if ( WorldID == nil ) then -- First world
				WorldID = WorldIDCurrent;
			elseif ( WorldID ~= WorldIDCurrent ) then -- Exists on multiple worlds
				WorldID = nil; -- Don't filter by world
				break;
			end
		end

		if ( WorldID ) then
			local Format = type( WorldID ) == "number"
				and "\t\t[ %d ] = %d;\n" or "\t\t[ %d ] = %q;\n";
			assert( OutFile:write( ( Format ):format( NpcID, WorldID ) ) );
		end
	end
end

assert( OutFile:write( [[
	};
};]] ) );
assert( OutFile:flush() );
assert( OutFile:close() );
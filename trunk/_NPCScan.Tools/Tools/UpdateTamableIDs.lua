--[[ _NPCScan.Tools by Saiket
Tools/UpdateTamableIDs.lua - Pulls tamable NPC IDs and locations from WowHead.

1. Prepare database files from the WoW client: (Only needs to be done once per WoW patch)
   a. Find the latest versions of these DBC files in WoW's MPQ archives using a
      tool such as WinMPQ:
      * <DBFilesClient/CreatureFamily.dbc>
      * <DBFilesClient/WorldMapArea.dbc>
      * <DBFilesClient/AreaTable.dbc>
   b. Extract them to the <DBFilesClient> folder.
   c. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
      nneonneo's <DBCUtil.exe> program.

This script must be run with a standalone Lua 5.1 interpreter, and it
overwrites <../../_NPCScan/_NPCScan.TamableIDs.lua>.
]]


local RareMapOverrides = { -- [ NpcID ] = ForcedMapID;
};
local CreatureTypeBlacklist = { -- Querying WowHead for these results in an empty result
	[ 59 ] = true; -- Silithid
};
local OutputFilename = [[../../_NPCScan/_NPCScan.TamableIDs.lua]];


package.cpath = [[.\Libs\?.dll;]]..package.cpath;
package.path = [[.\Libs\?.lua;]]..package.path;
local http = require( "socket.http" );
require( "json" );
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




-- Create a list of all tamable creature types for the WowHead query
local CreatureFamilies = DbcCsv.Parse( [[DBFilesClient/CreatureFamily.dbc.csv]], 1,
	"ID", nil, nil, nil, nil, nil, nil, nil, "PetTalentType" );

local PetTypes = {};
for ID, CreatureFamily in pairs( CreatureFamilies ) do
	if ( CreatureFamily.PetTalentType ~= -1 -- Tamable mob type
		and not CreatureTypeBlacklist[ ID ]
	) then
		PetTypes[ #PetTypes + 1 ] = ID;
	end
end


-- Create a lookup for zone AreaTable IDs used by WowHead to WorldMapArea IDs
local WorldMapAreas = DbcCsv.Parse( [[DBFilesClient/WorldMapArea.dbc.csv]], 1,
	"ID", nil, "AreaTableID", nil, nil, nil, nil, nil, nil, nil, nil, "Flags" );
local AreaTable = DbcCsv.Parse( [[DBFilesClient/AreaTable.dbc.csv]], 1,
	"ID", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Localization" );

local MapIDs, MapNames = {}, {};
local FLAG_PHASE = 0x2;
for ID, WorldMapArea in pairs( WorldMapAreas ) do
	if ( WorldMapArea.AreaTableID ~= 0 -- Not a continent
		and bit.band( tonumber( WorldMapArea.Flags, 16 ), FLAG_PHASE ) == 0 -- Not a phased map
	) then
		MapIDs[ WorldMapArea.AreaTableID ] = ID;
		MapNames[ ID ] = AreaTable[ WorldMapArea.AreaTableID ].Localization;
	end
end




local function HandleRare ( NpcData ) -- Parses WowHead's rare data
	local ID = assertf( tonumber( NpcData.id ), "Invalid Npc ID %s.", NpcData.id );
	local Name = assert( NpcData.name, "Missing Npc name." );
	print( ( "[%d]\t%s" ):format( ID, Name ) );
	local LocationTable = NpcData.location;

	local MapID;
	if ( RareMapOverrides[ ID ] ) then
		print( "  - Map override set; Ignoring reported zone." );
		MapID, RareMapOverrides[ ID ] = RareMapOverrides[ ID ];
	elseif ( type( LocationTable ) == "table" and #LocationTable > 0 ) then
		MapID = MapIDs[ LocationTable[ 1 ] ];
		if ( #LocationTable > 1 ) then
			print( "  - More than one potential zone!  First option taken." );
		end
	end

	if ( not MapID ) then
		print( "  - Mapless zone; Don't filter by location." );
	end
	return { ID = ID; Name = Name; MapID = MapID or true; };
end




print( "Reading tamable rare list:" );

-- Query to filter all rare/rare elite tamable mobs
local Query = ( "http://www.wowhead.com/npcs?filter=cl=4:2;fa=%s" ):format( table.concat( PetTypes, ":" ) );
local ListViewPattern = [[<script type="text/javascript">//<!%[CDATA%[
new Listview%((%b{})%);
//%]%]></script>]]

local Text, Status = http.request( Query );
assertf( Text and Status == 200, "Request failed: Status code %d.", Status );

Text = assert( Text:match( ListViewPattern ), "Could not find rare mob data!" );
local ListData = json.decode( Text );
assertf( ListData.id == "npcs", "Invalid id %s.", ListData.id );

local RaresList = {};
for _, NpcData in ipairs( ListData.data ) do
	local Success, Rare = pcall( HandleRare, NpcData );
	if ( not Success ) then
		print( "  - "..Rare );
	else
		RaresList[ #RaresList + 1 ] = Rare;
	end
end

-- Add extra overrides
if ( next( RareMapOverrides ) ) then
	print( "\nAdding unlisted overrides..." );
	for NpcID, MapID in pairs( RareMapOverrides ) do
		print( ( "[%d]\t%s" ):format( NpcID, tostring( MapID ) ) );
		RaresList[ #RaresList + 1 ] = { ID = NpcID; MapID = MapID; };
	end
end

-- Sort by npc name
table.sort( RaresList, function ( Rare1, Rare2 )
	local Name1, Name2 = Rare1.Name or "", Rare2.Name or "";
	if ( Name1 == Name2 ) then
		return Rare1.ID < Rare2.ID;
	else
		return Name1 < Name2;
	end
end );




local Outfile = assert( io.open( OutputFilename, "w+" ) );

Outfile:write( "-- AUTOMATICALLY GENERATED BY <_NPCScan.Tools/Tools/UpdateTamableIDs.lua>!\n" );
Outfile:write( "select( 2, ... ).TamableIDs = {\n" );

for _, Rare in ipairs( RaresList ) do
	local Name;
	if ( Rare.Name ) then
		Name = "\""..Rare.Name.."\"";
	end
	local MapName = MapNames[ Rare.MapID ];
	if ( MapName ) then
		Name = ( Name and Name.." " or "" ).."from "..MapName;
	end
	Name = Name and " -- "..Name or "";

	Outfile:write( ( "\t[ %d ] = %s;%s\n" ):format( Rare.ID, tostring( Rare.MapID ), Name ) );
end

Outfile:write( "};\n" );

Outfile:flush();
Outfile:close();
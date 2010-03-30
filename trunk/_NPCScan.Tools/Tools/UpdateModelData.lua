--[[ _NPCScan.Tools by Saiket
Tools/UpdateModelData.lua - Gets model file paths for rares from WowHead.

1. Create a file in the Tools folder named <Account.dat>, and type in the account
   name, server, and character (ex. "AccountName/ServerName/CharacterName") for
   the character used to configure _NPCScan.  This path is used to find your
   saved _NPCScan settings.
2. Prepare database files from the WoW client: (Only needs to be done once per WoW patch)
   a. Find the latest versions of these DBC files in WoW's MPQ archives using a
      tool such as WinMPQ:
      * <DBFilesClient/Achievement.dbc>
      * <DBFilesClient/Achievement_Criteria.dbc>
   b. Extract them to the <DBFilesClient> folder.
   c. Run <DBCUtil.bat> to convert all found *.DBC files into *.CSV files using
      nneonneo's <DBCUtil.exe> program.
3. Log on to a character and set up its _NPCScan search list with all mobs you
   want data for.

Once you have selected a set of NPCs and configured the account file, reload your
UI and run this script with a standalone Lua 5.1 interpreter.  The
<../../_NPCScan.Tools/_NPCScan.Tools.ModelData.lua> data file will be overwritten.
]]


package.cpath = [[.\Libs\?.dll;]]..package.cpath;
package.path = [[.\Libs\?.lua;]]..package.path;
local http = require( "socket.http" );
require( "json" );
require( "bit" );
require( "DbcCSV" );


local AccountFile = assert( io.open( "Account.dat" ) );
local DataPath = assert( AccountFile:read(), "Account.dat must have account data path on first line." );
assert( #DataPath > 0, "Missing data path in Account.dat." );


local DataFilename = [[../../../../WTF/Account/]]..DataPath..[[/SavedVariables/_NPCScan.lua]];
local OutputFilename = [[../_NPCScan.Tools.ModelData.lua]];




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




print( "Parsing game data..." ); -- This takes a while
local Achievements = DbcCSV.Parse( [[DBFilesClient/Achievement.dbc.csv]], 1,
	"ID", nil, nil, nil, "Name", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
	nil --[[Description]], nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
	nil, nil, nil, nil, nil,
	nil --[[Rewards]], nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
	nil, "CriteriaParent" );

local AchievementCriteria = DbcCSV.Parse( [[DBFilesClient/Achievement_Criteria.dbc.csv]], 1,
	"ID", "AchievementID", "Type", "AssetID", nil, nil, nil, nil, nil, "Name" );

-- WowHead serves mob graphic data as its CreatureDisplayInfo ID
local CreatureDisplayInfo = DbcCSV.Parse( [[DBFilesClient/CreatureDisplayInfo.dbc.csv]], 1,
	"ID", "ModelDataID" );

local CreatureModelData = DbcCSV.Parse( [[DBFilesClient/CreatureModelData.dbc.csv]], 1,
	"ID", nil, "Path" );




-- Load _NPCScan saved variables
assert( loadfile( DataFilename ) )();
local Success, NpcNames, AchievementsActive = assert( pcall( function ()
	local Options = _NPCScanOptionsCharacter;
	return assert( Options.NPCs, "NPC data missing in _NPCScan saved variables." ),
		assert( Options.Achievements, "Achievement data missing in _NPCScan saved variables." );
end ) );

local NpcIDs = {};
for Name, NpcID in pairs( NpcNames ) do
	NpcIDs[ NpcID ] = Name;
end




-- Find mobs that are criteria for achievements
local AchievementFilter = {};
local function AddAchievement ( ID )
	AchievementFilter[ ID ] = true;
	-- Recurse any achievements whos criteria must also be met
	local CriteriaParent = Achievements[ ID ].CriteriaParent;
	if ( CriteriaParent ~= 0 ) then
		AddAchievement( CriteriaParent );
	end
end
for AchievementID, Enabled in pairs( AchievementsActive ) do
	if ( Enabled ) then
		AddAchievement( AchievementID );
	end
end

-- Get rare mob kill criteria for found achievements
for ID, Criteria in pairs( AchievementCriteria ) do
	if ( AchievementFilter[ Criteria.AchievementID ]
		and Criteria.Type == 0 -- Mob kill type
	) then
		NpcIDs[ Criteria.AssetID ] = Criteria.Name;
	end
end




print( "Reading NPC model IDs:" );
local NpcModelPaths = {};
for NpcID, Name in pairs( NpcIDs ) do
	local Success, ErrorMessage = pcall( function ()
		print( "+ ID "..NpcID..":", Name );
		local Text, Status = http.request( [[http://www.wowhead.com/?npc=]]..NpcID );
		assertf( Text and math.floor( Status / 100 ) == 2, "Request failed: Status code %d.", Status );

		if ( Status ~= 200 ) then
			print( "  + Status code "..Status..":", #Text.." bytes." );
		end

		Text = assert( Text:match( [[onclick="this%.blur%(%); ModelViewer%.show%((.-)%)">]] ), "Could not find model data!" );
		local DisplayID = json.decode( Text ).displayId;
		local DisplayInfo = assertf( CreatureDisplayInfo[ DisplayID ], "Invalid displayID %s.", DisplayID );
		NpcModelPaths[ NpcID ] = CreatureModelData[ DisplayInfo.ModelDataID ].Path;
	end );
	if ( not Success ) then
		print( "  - "..ErrorMessage );
	end
end


-- Sort by npc ID
local SortOrder = {};
for NpcID in pairs( NpcModelPaths ) do
	SortOrder[ #SortOrder + 1 ] = NpcID;
end
table.sort( SortOrder );




local Outfile = assert( io.open( OutputFilename, "w+" ) );

Outfile:write( "-- AUTOMATICALLY GENERATED BY <_NPCScan.Tools/Tools/UpdateModelData.lua>!\n" );
Outfile:write( "_NPCScan.Tools.ModelData = {\n" );

for _, NpcID in ipairs( SortOrder ) do
	Outfile:write( ( "\t\t[ %d ] = %q;\n" ):format( NpcID, NpcModelPaths[ NpcID ] ) );
end

Outfile:write( "};\n" );

Outfile:flush();
Outfile:close();

--[[ Tools/UpdateLocationData.lua - Pulls NPC location data from WoWDB and WowHead.

1. Log on to a character and set up its _NPCScan search list with all mobs you
   want data for.
2. Create a file in the Tools folder named <Account.dat>, and type in the account
   name, server, and character (ex. "AccountName\ServerName\CharacterName") for
   the character used to configure _NPCScan.  This path is used to find your
   saved _NPCScan settings.

Once you have selected a set of NPCs and configured the account file, reload your
UI and run this script with a standalone Lua 5.1 interpreter.  The
<../../_NPCScan.Overlay._NPCScan.Overlay.PathData.lua> data file will be overwritten.
]]




local AccountFile = assert( io.open( "Account.dat" ) );
local DataPath = assert( AccountFile:read(), "Account.dat must have account data path on first line." );
assert( #DataPath > 0, "Missing data path in Account.dat." );


local DataFilename = [[..\..\..\..\WTF\Account\]]..DataPath..[[\SavedVariables\_NPCScan.lua]];
local OutputFilename = [[..\_NPCScan.Tools.LocationData.lua]];

local MapIDs = {
	-- Kalimdor
	[ "Azuremyst Isle" ] = "AzuremystIsle";
	[ "Moonglade" ] = "Moonglade";
	[ "Thousand Needles" ] = "ThousandNeedles";
	[ "Winterspring" ] = "Winterspring";
	[ "Ashenvale" ] = "Ashenvale";
	[ "Teldrassil" ] = "Teldrassil";
	[ "Un'Goro Crater" ] = "UngoroCrater";
	[ "Mulgore" ] = "Mulgore";
	[ "Dustwallow Marsh" ] = "Dustwallow";
	[ "Felwood" ] = "Felwood";
	[ "Darkshore" ] = "Darkshore";
	[ "Orgrimmar" ] = "Ogrimmar";
	[ "Desolace" ] = "Desolace";
	[ "The Exodar" ] = "TheExodar";
	[ "Tanaris" ] = "Tanaris";
	[ "Durotar" ] = "Durotar";
	[ "Azshara" ] = "Aszhara";
	[ "Feralas" ] = "Feralas";
	[ "Silithus" ] = "Silithus";
	[ "The Barrens" ] = "Barrens";
	[ "Thunder Bluff" ] = "ThunderBluff";
	[ "Bloodmyst Isle" ] = "BloodmystIsle";
	[ "Stonetalon Mountains" ] = "StonetalonMountains";
	[ "Darnassus" ] = "Darnassis";
	-- Eastern Kingdoms
	[ "The Hinterlands" ] = "Hinterlands";
	[ "Stranglethorn Vale" ] = "Stranglethorn";
	[ "Eastern Plaguelands" ] = "EasternPlaguelands";
	[ "Duskwood" ] = "Duskwood";
	[ "Ghostlands" ] = "Ghostlands";
	[ "Blasted Lands" ] = "BlastedLands";
	[ "Elwynn Forest" ] = "Elwynn";
	[ "Arathi Highlands" ] = "Arathi";
	[ "Eversong Woods" ] = "EversongWoods";
	[ "Ironforge" ] = "Ironforge";
	[ "Badlands" ] = "Badlands";
	[ "Searing Gorge" ] = "SearingGorge";
	[ "Loch Modan" ] = "LochModan";
	[ "Burning Steppes" ] = "BurningSteppes";
	[ "Undercity" ] = "Undercity";
	[ "Westfall" ] = "Westfall";
	[ "Western Plaguelands" ] = "WesternPlaguelands";
	[ "Wetlands" ] = "Wetlands";
	[ "Tirisfal Glades" ] = "Tirisfal";
	[ "Stormwind City" ] = "Stormwind";
	[ "Silverpine Forest" ] = "Silverpine";
	[ "Silvermoon City" ] = "SilvermoonCity";
	[ "Redridge Mountains" ] = "Redridge";
	[ "Isle of Quel'Danas" ] = "Sunwell";
	[ "Deadwind Pass" ] = "DeadwindPass";
	[ "Hillsbrad Foothills" ] = "Hilsbrad";
	[ "Swamp of Sorrows" ] = "SwampOfSorrows";
	[ "Dun Morogh" ] = "DunMorogh";
	[ "Alterac Mountains" ] = "Alterac";
	-- Outlands
	[ "Blade's Edge Mountains" ] = "BladesEdgeMountains";
	[ "Zangarmarsh" ] = "Zangarmarsh";
	[ "Netherstorm" ] = "Netherstorm";
	[ "Shattrath City" ] = "ShattrathCity";
	[ "Terokkar Forest" ] = "TerokkarForest";
	[ "Shadowmoon Valley" ] = "ShadowmoonValley";
	[ "Nagrand" ] = "Nagrand";
	[ "Hellfire Peninsula" ] = "Hellfire";
	-- Northrend
	[ "Icecrown" ] = "IcecrownGlacier";
	[ "Wintergrasp" ] = "LakeWintergrasp";
	[ "Crystalsong Forest" ] = "CrystalsongForest";
	[ "Dragonblight" ] = "Dragonblight";
	[ "Howling Fjord" ] = "HowlingFjord";
	[ "Borean Tundra" ] = "BoreanTundra";
	[ "The Storm Peaks" ] = "TheStormPeaks";
	[ "Hrothgar's Landing" ] = "HrothgarsLanding";
	[ "Sholazar Basin" ] = "SholazarBasin";
	[ "Dalaran" ] = "Dalaran";
	[ "Grizzly Hills" ] = "GrizzlyHills";
	[ "Zul'Drak" ] = "ZulDrak";
};

local http = require( "socket.http" );
require( "Json" );
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


local function GetNpcData ( NpcData ) -- Returns the mob's primary MapID and a list of coords
	-- Validate map data and choose the primary zone
	local PrimaryCount, PrimaryMap = 0;
	for _, MapData in ipairs( NpcData ) do
		assert( MapData.mapType == "npc", "Invalid mapType "..MapData.mapType.."." );
		assert( MapData.locale == "en", "Invalid locale "..MapData.locale.."." );
		local Name = MapData.mapLabel;
		assert( MapIDs[ Name ], "Unrecognized zone name "..Name.."." );

		local CountTotal = 0;
		for _, Coord in ipairs( MapData.coords ) do
			Coord[ 3 ] = tonumber( Coord[ 3 ]:match( "<div>Spotted here (%d+) times</div>" ) );
			CountTotal = CountTotal + Coord[ 3 ];
			for Index = 4, #Coord do -- Clear unused data
				Coord[ Index ] = nil;
			end
		end

		if ( CountTotal > PrimaryCount ) then
			PrimaryCount = CountTotal;
			PrimaryMap = MapData;
		end
	end

	assert( PrimaryMap, "No points found for NPC." );
	return MapIDs[ PrimaryMap.mapLabel ], PrimaryMap.coords, PrimaryCount;
end


local EncodeNpcData; -- Packs coordinates and relative sighting density info into a string
do
	local MaxCoordValue = 2 ^ 16 - 1;
	local unpack, char = unpack, string.char;
	local floor, ceil, min = math.floor, math.ceil, math.min;
	local rshift, band = bit.brshift, bit.band;
	function EncodeNpcData ( NpcData )
		local MapID, Coords, CountTotal = GetNpcData( NpcData );
		local Bytes = {};
		for Index, Coord in ipairs( Coords ) do
			local X, Y, Count = unpack( Coord );
			X, Y = floor( MaxCoordValue * X / 100 + 0.5 ), floor( MaxCoordValue * Y / 100 + 0.5 );
			Count = ceil( min( 1, Count / ( CountTotal / #Coords ) ) * 255 );
			Bytes[ Index ] = char( rshift( X, 8 ), band( X, 255 ), rshift( Y, 8 ), band( Y, 255 ), Count );
		end
		return MapID, table.concat( Bytes );
	end
end




assert( loadfile( DataFilename ) )();
local Success, NpcNames, Achievements = assert( pcall( function ()
	local Options = _NPCScanOptionsCharacter;
	return assert( Options.NPCs, "NPC data missing in _NPCScan saved variables." ),
		assert( Options.Achievements, "Achievement data missing in _NPCScan saved variables." );
end ) );

local NpcIDs = {};
for Name, NpcID in pairs( NpcNames ) do
	NpcIDs[ NpcID ] = Name;
end




print( "____" );
print( "Reading achievement data:" );
local function ReplaceSingleQuotes ( Escapes )
	if ( #Escapes % 2 == 0 ) then -- Even number; not escaped.
		return Escapes..[["]];
	end
end
for AchievementID, Enabled in pairs( Achievements ) do
	if ( Enabled ) then
		print( "* ID "..AchievementID..":" );
		local Text, Status = http.request( [[http://www.wowhead.com/?achievement=]]..AchievementID );
		if ( not Text ) then
			print( "  - Request failed:", Status );
		elseif ( math.floor( Status / 100 ) ~= 2 ) then
			print( "  - Invalid status code:", Status );
		else
			if ( Status ~= 200 ) then
				print( "  + Status code "..Status..":", #Text.." bytes." );
			end
			local AchievementName = Text:match( [[var g_pageInfo = (%b{});]] );
			if ( AchievementName ) then
				AchievementName = AchievementName:gsub( ",([%]}])", "%1" ); -- Extra commas aren't allowed
				AchievementName = AchievementName:gsub( "([{,])%s*(%w+)%s*:%s*", [[%1"%2":]] ); -- Key identifiers must be wrapped in quotes!
				AchievementName = AchievementName:gsub( "(\\*)'", ReplaceSingleQuotes );
				local Success, Data = pcall( Json.Decode, AchievementName );
				if ( not Success ) then
					print( "  - Couldn't parse achievement name:", Data );
					AchievementName = nil;
				elseif ( Data.name ) then
					AchievementName = Data.name;
				end
			end
			if ( not AchievementName ) then
				print( "  - Could not find achievement name!" );
				AchievementName = "Unknown";
			end

			local Count = 0;
			for NpcID, Name in Text:gmatch( [[<td><a href="/%?npc=([%d]+)">(.-)</a> slain</td>]] ) do
				NpcIDs[ NpcID ] = Name;
				Count = Count + 1;
			end
			print( "  + "..AchievementName..":", Count.." NPCs." );
		end
	end
end




print( "\n____" );
print( "Reading NPC data:" );
local NpcData, NpcMapIDs = {}, {};
for NpcID, Name in pairs( NpcIDs ) do
	print( "+ ID "..NpcID..":", Name );
	local Text, Status = http.request( ( [[http://www.wowdb.com/npc.aspx?id=]]..NpcID );
	if ( not Text ) then
		print( "  - Request failed:", Status );
	elseif ( math.floor( Status / 100 ) ~= 2 ) then
		print( "  - Invalid status code:", Status );
	else
		if ( Status ~= 200 ) then
			print( "  + Status code "..Status..":", #Text.." bytes." );
		end

		Text = Text:match( [[<script>addMapLocations%((.*)%)</script>]] );
		if ( not Text ) then
			print( "  - Could not find map location data!" );
		else
			Text = Text:gsub( ",([%]}])", "%1" ); -- Extra commas aren't allowed
			Text = Text:gsub( "([{,])%s*(%w+)%s*:%s*", [[%1"%2":]] ); -- Key identifiers must be wrapped in quotes!
			local Success, Data = pcall( Json.Decode, Text );

			if ( not Success ) then
				print( "  - Couldn't parse map data:", Data:sub( 1, 128 ) );
			else
				local Success, MapID, Message = pcall( EncodeNpcData, Data );
				if ( not Success ) then
					print( "  - "..MapID );
				else
					NpcMapIDs[ NpcID ] = MapID;
					NpcData[ NpcID ] = Message;
				end
			end
		end
	end
end




local Outfile = assert( io.open( OutputFilename, "w+" ) );

Outfile:write( "_NPCScan.Tools.LocationData = {\n" );


Outfile:write( "\tNpcMapIDs = {\n" );
for NpcID, MapID in pairs( NpcMapIDs ) do
	Outfile:write( "\t\t[ "..NpcID.." ] = \""..MapID.."\";\n" );
end
Outfile:write( "\t};\n" );


Outfile:write( "\tNpcData = {\n" );
for NpcID, NpcData in pairs( NpcData ) do
	Outfile:write( "\t\t[ "..NpcID.." ] = \""..EscapeString( NpcData ).."\";\n" );
end
Outfile:write( "\t};\n" );


Outfile:write( "};\n" );

Outfile:flush();
Outfile:close();

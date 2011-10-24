--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Dump.lua - Prints the contents of Lua datatypes to chat.              *
  ****************************************************************************]]


_DevOptions.Dump = {
	SkipGlobalEnv = false; -- Precaches _G to avoid lockups

	-- 0 = None
	-- 1 = Escape pipes
	-- 2 = Escape pipes and extended characters
	EscapeMode = 2;

	-- Any of the following limits can be false to skip the test
	MaxDepth = 6; -- Max number of recursive tables to check
	MaxStrLen = false; -- Cutoff length for printed strings
	MaxTableLen = false; -- Max table elements to print before leaving the table

	MaxExploreTime = 10.0; -- Seconds to run before stopping execution
};


local _Dev = _Dev;
local L = _DevLocalization;
local NS = {
	EscapeSequences = {
		[ "\a" ] = "\\a"; -- Bell
		[ "\b" ] = "\\b"; -- Backspace
		[ "\t" ] = "\\t"; -- Horizontal tab
		[ "\n" ] = "\\n"; -- Newline
		[ "\v" ] = "\\v"; -- Vertical tab
		[ "\f" ] = "\\f"; -- Form feed
		[ "\r" ] = "\\r"; -- Carriage return
		[ "\\" ] = "\\\\"; -- Backslash
		[ "\"" ] = "\\\""; -- Quotation mark
		[ "|" ]  = "||";
	};
};
_Dev.Dump = NS;
local EscapeSequences = NS.EscapeSequences;

local Temp = { -- Private: Lists of known object references
	[ "table" ] = {};
	[ "function" ] = {};
	[ "userdata" ] = {};
	[ "thread" ] = {};
};




--[[****************************************************************************
  * Function: _Dev.Dump.EscapeString                                           *
  * Description: Optionally escapes the given string's pipe characters,        *
  *   newlines/tabs, and extended characters.                                  *
  ****************************************************************************]]
do
	local EscapeMode, MaxStrLen, Truncated;
	function NS.EscapeString ( Input )
		EscapeMode = _DevOptions.Dump.EscapeMode;
		if ( EscapeMode >= 1 ) then
			MaxStrLen = _DevOptions.Dump.MaxStrLen;
			Truncated = MaxStrLen and #Input > MaxStrLen;
			if ( Truncated ) then
				Input = Input:sub( 1, MaxStrLen );
			end
			if ( EscapeMode == 1 ) then
				Input = Input:gsub( "|", "||" );
			elseif ( EscapeMode >= 2 ) then
				Input = Input:gsub( "[%z\1-\31\"\\|\127-\255]", EscapeSequences );
			end
			if ( Truncated ) then
				Input = Input..L.DUMP_MAXSTRLEN_ABBR;
			end
		end
		return Input;
	end
end
--[[****************************************************************************
  * Function: _Dev.Dump.ToString                                               *
  * Description: Returns a nicely formatted string representation of the given *
  *   value. If called for an object reference not in Temp, returns plain      *
  *   tostring value.                                                          *
  ****************************************************************************]]
do
	local tostring = tostring;
	local type = type;
	function NS.ToString ( Input )
		local Type = type( Input );
		local Count = Temp[ Type ] and Temp[ Type ][ Input ];

		if ( Count ) then -- Table, function, userdata, or thread
			Input = _Dev.IsUIObject( Input )
				and L.DUMP_UIOBJECT_FORMAT:format( Count, Input:GetObjectType(), NS.ToString( Input:GetName() ) )
				or Count;
		elseif ( Type == "string" ) then
			Input = NS.EscapeString( Input );
		else -- Numbers and booleans
			Type = "other";
			Input = tostring( Input );
		end

		return L.DUMP_TYPE_FORMATS[ Type ]:format( Input );
	end
end


--[[****************************************************************************
  * Function: _Dev.Dump.Explore                                                *
  * Description: Prints the contents of a variable to the default chat frame.  *
  ****************************************************************************]]
do
	local type = type;
	local function AddHistory ( Input ) -- Adds Input to History if it's an object reference, and returns true if successfull
		local History = Temp[ type( Input ) ];

		if ( History and not History[ Input ] ) then
			History.n = History.n + 1;
			History[ Input ] = History.n;
			return true;
		end
	end

	local Depth = nil; -- Depth of recursion; nil if first call.
	local EndTime = nil; -- Set to the cutoff execution time when limited.
	local OverTime = false; -- Boolean, true when ran out of time.

	local time = time;
	local next = next;
	local pairs = pairs;
	local select = select;
	local rawequal = rawequal;
	local wipe = wipe;
	function NS.Explore ( LValueString, ... )
		local ArgCount = 1;
		if ( not Depth ) then -- First iteration, initialize
			Depth = 0;
			Temp[ "table" ].n = 0;
			Temp[ "function" ].n = 0;
			Temp[ "userdata" ].n = 0;
			Temp[ "thread" ].n = 0;
			if ( _DevOptions.Dump.SkipGlobalEnv ) then
				Temp[ "table" ][ getfenv( 0 ) ] = L.DUMP_GLOBALENV;
			end
			LValueString = LValueString
				and "("..tostring( LValueString )..")" or L.DUMP_LVALUE_DEFAULT;
			OverTime = false;
			EndTime = _DevOptions.Dump.MaxExploreTime
				and ( _DevOptions.Dump.MaxExploreTime + time() ) or nil;

			-- Trim nil values from end
			for Index = select( "#", ... ), 1, -1 do
				ArgCount = Index;
				if ( not rawequal( select( Index, ... ), nil ) ) then
					break;
				end
			end
			if ( ArgCount > 1 ) then
				_Dev.Print( LValueString.." = ( ... )["..NS.ToString( select( "#", ... ) ).."]:" );
			end
		end

		local IndentString = L.DUMP_INDENT:rep( Depth );

		for Index = 1, ArgCount do
			local Input = ArgCount == 1 and ... or select( Index, ... );
			-- Only print a nil arg when it's the only arg
			if ( ArgCount == 1 or not rawequal( Input, nil ) ) then
				if ( ArgCount > 1 ) then
					LValueString = "["..NS.ToString( Index ).."]";
				end

				if ( AddHistory( Input ) and type( Input ) == "table" ) then -- New table
					local TableString = IndentString..LValueString.." = "..NS.ToString( Input );
					if ( next( Input ) == nil ) then -- Empty array
						_Dev.Print( TableString.." {};" );
					else -- Display the table's contents
						local MaxDepth = _DevOptions.Dump.MaxDepth;
						if ( MaxDepth and Depth >= MaxDepth ) then -- Too deep
							_Dev.Print( TableString.." { "..L.DUMP_MAXDEPTH_ABBR.." };" );
						else -- Not too deep
							_Dev.Print( TableString.." {" );
							local MaxTableLen = _DevOptions.Dump.MaxTableLen;
							local TableLen = 0;
							Depth = Depth + 1;
							for Key, Value in pairs( Input ) do
								if ( EndTime ) then
									if ( OverTime ) then
										break;
									elseif ( EndTime <= time() ) then
										_Dev.Print( IndentString..L.DUMP_INDENT..L.DUMP_MAXEXPLORETIME_ABBR );
										OverTime = true;
										break;
									end
								end

								if ( MaxTableLen ) then
									TableLen = TableLen + 1;
									if ( TableLen > MaxTableLen ) then -- Table is too long
										_Dev.Print( IndentString..L.DUMP_INDENT..L.DUMP_MAXTABLELEN_ABBR );
										break;
									end
								end
								AddHistory( Key );

								NS.Explore( "["..NS.ToString( Key ).."]", Value );
							end
							Depth = Depth - 1;
							_Dev.Print( IndentString.."};" );
						end
					end
				else
					_Dev.Print( IndentString..LValueString.." = "..NS.ToString( Input )..";" );
				end
			end
		end

		if ( Depth == 0 ) then -- Clean up
			Depth = nil;
			wipe( Temp[ "table" ] );
			wipe( Temp[ "function" ] );
			wipe( Temp[ "userdata" ] );
			wipe( Temp[ "thread" ] );
			if ( OverTime ) then
				return L.DUMP_TIME_EXCEEDED;
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.Dump.SlashCommand                                           *
  * Description: Slash command chat handler for the _Dev.Dump function.        *
  ****************************************************************************]]
do
	local function Explore ( Input, Success, ... )
		if ( Success ) then
			local ErrorMessage = NS.Explore( Input, ... );
			if ( ErrorMessage ) then
				_Dev.Error( L.DUMP_MESSAGE_FORMAT:format( ErrorMessage ) );
			end
		else -- Couldn't parse/runtime error
			_Dev.Error( L.DUMP_MESSAGE_FORMAT:format( tostring( ( ... ) ) ) );
		end
	end
	function NS.SlashCommand ( Input )
		if ( Input and not Input:find( "^%s*$" ) ) then
			Input = Input:gsub( "||", "|" );
			Explore( Input, _Dev.Exec( Input ) );
		end
	end
end




-- Add all non-printed characters to replacement table
for Index = 0, 31 do
	local Character = strchar( Index );
	if ( not EscapeSequences[ Character ] ) then
		EscapeSequences[ Character ] = ( "\\%03d" ):format( Index );
	end
end
for Index = 127, 255 do
	local Character = strchar( Index );
	if ( not EscapeSequences[ Character ] ) then
		EscapeSequences[ Character ] = ( "\\%03d" ):format( Index );
	end
end


dump = NS.Explore;

SlashCmdList[ "_DEV_DUMP" ] = NS.SlashCommand;
SlashCmdList[ "DUMP" ] = nil; -- Overwrite default /dump command from Blizzard_DebugTools
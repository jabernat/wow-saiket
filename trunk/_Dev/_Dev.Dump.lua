--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Dump.lua - Functions and data used by the dump function.              *
  *                                                                            *
  * + Adds /dump for executing LUA by command line. It executes its argument   *
  *   and displays the returned value in a chat window. The argument should be *
  *   an RValue.                                                               *
  *   + Pipes typed into the command will be unescaped to allow manual         *
  *     construction of color and link tags.                                   *
  * + Dump will show the type, the expression used, and will iterate through   *
  *   the contents of tables. Output is color coded.                           *
  * + Escapes special characters with their C-style escape sequences if        *
  *   applicable, else with their more general escaped code points.            *
  * + Shows the names and types of UIObjects.                                  *
  * + The function dump(input,label) works identically to the slash command,   *
  *   but a label can be specified to uniquely identify the result. Care       *
  *   should be taken to not specify a third argument, as it's used            *
  *   internally.                                                              *
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
local me = {
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
_Dev.Dump = me;
local EscapeSequences = me.EscapeSequences;

local Temp = {}; -- Private: Lists of known data structures




--[[****************************************************************************
  * Function: _Dev.Dump.EscapeString                                           *
  * Description: Optionally escapes the given string's pipe characters,        *
  *   newlines/tabs, and extended characters.                                  *
  ****************************************************************************]]
do
	local EscapeMode, MaxStrLen, Truncated;
	function me.EscapeString ( Input )
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
  *   value. Relies on Temp and should only be called by _Dev. If called for   *
  *   a type that requires Temp and Temp is nil, returns plain tostring value. *
  ****************************************************************************]]
do
	local IsUIObject = _Dev.IsUIObject;
	local EscapeString = me.EscapeString;
	local tostring = tostring;
	local type = type;
	function me.ToString ( Input )
		local Type = type( Input );
		local Count = Temp and Temp[ Type ] and Temp[ Type ][ Input ];

		if ( Count ) then -- Table, function, userdata, or thread
			Input = IsUIObject( Input )
				and L.DUMP_UIOBJECT_FORMAT:format( Count, Input:GetObjectType(), me.ToString( Input:GetName() ) )
				or Count;
		elseif ( Type == "string" ) then
			Input = EscapeString( Input );
		else -- Numbers and booleans
			Type = "other";
			Input = tostring( Input );
		end

		return L.DUMP_TYPE_FORMATS[ Type ]:format( Input );
	end
end
--[[****************************************************************************
  * Function: _Dev.Dump.AddHistory                                             *
  * Description: Adds the given value to History if it's a new table,          *
  *   function, thread, or userdata, and returns whether or not anything was   *
  *   actually added.                                                          *
  ****************************************************************************]]
do
	local type = type;

	local History;
	function me.AddHistory ( Input )
		History = Temp[ type( Input ) ];
	
		if ( History and not History[ Input ] ) then
			History.n = History.n + 1;
			History[ Input ] = History.n;
			return true;
		end
	end
end


--[[****************************************************************************
  * Function: _Dev.Dump.Explore                                                *
  * Description: Prints the contents of a variable to the default chat frame.  *
  ****************************************************************************]]
do
	local Depth = nil; -- Private: Depth of recursion; nil if first call.
	local EndTime = nil; -- Private: Set to the cutoff execution time when limited.
	local OverTime = false; -- Private: Boolean, true when ran out of time.

	local ToString = me.ToString;
	local AddHistory = me.AddHistory;
	local Print = _Dev.Print;
	local GetTime = GetTime;
	local type = type;
	local next = next;
	local pairs = pairs;
	function me.Explore ( Input, LValueString )
		if ( not Depth ) then -- First iteration, initialize
			Depth = 0;
			Temp[ "table" ]    = { n = 0; };
			Temp[ "function" ] = { n = 0 };
			Temp[ "userdata" ] = { n = 0 };
			Temp[ "thread" ]   = { n = 0 };
			if ( _DevOptions.Dump.SkipGlobalEnv ) then
				Temp[ "table" ][ getfenv( 0 ) ] = L.DUMP_GLOBALENV;
			end
			LValueString = LValueString
				and "("..LValueString..")" or L.DUMP_LVALUE_DEFAULT;
			OverTime = false;
			EndTime = _DevOptions.Dump.MaxExploreTime
				and ( _DevOptions.Dump.MaxExploreTime + GetTime() )
				or nil;
		end

		local IndentString = L.DUMP_INDENT:rep( Depth );

		if ( AddHistory( Input ) and type( Input ) == "table" ) then -- New table
			local TableString = IndentString..LValueString.." = "..ToString( Input );
			if ( not next( Input ) ) then -- Empty array
				Print( TableString.." {};" );
			else -- Display the table's contents
				local MaxDepth = _DevOptions.Dump.MaxDepth;
				if ( MaxDepth and Depth >= MaxDepth ) then -- Too deep
					Print( TableString.." { "..L.DUMP_MAXDEPTH_ABBR.." };" );
				else -- Not too deep
					Print( TableString.." {" );
					local MaxTableLen = _DevOptions.Dump.MaxTableLen;
					local TableLen = 0;
					Depth = Depth + 1;
					for Key, Value in pairs( Input ) do
						if ( EndTime ) then
							if ( OverTime ) then
								break;
							elseif ( EndTime <= GetTime() ) then
								Print( IndentString..L.DUMP_INDENT..L.DUMP_MAXEXPLORETIME_ABBR );
								OverTime = true;
								break;
							end
						end

						if ( MaxTableLen ) then
							TableLen = TableLen + 1;
							if ( TableLen > MaxTableLen ) then -- Table is too long
								Print( IndentString..L.DUMP_INDENT..L.DUMP_MAXTABLELEN_ABBR );
								break;
							end
						end
						AddHistory( Key );

						me.Explore( Value, "["..ToString( Key ).."]" );
					end
					Depth = Depth - 1;
					Print( IndentString.."};" );
				end
			end
		else
			Print( IndentString..LValueString.." = "..ToString( Input )..";" );
		end

		if ( Depth == 0 ) then -- Clean up
			Depth = nil;
			for Type in pairs( Temp ) do
				Temp[ Type ] = nil;
			end
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
function me.SlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		Input = Input:gsub( "||", "|" );
		local Success, Target = _Dev.Exec( Input );
		if ( Success ) then
			local ErrorMessage = me.Explore( Target, Input );
			if ( ErrorMessage ) then
				_Dev.Error( L.DUMP_MESSAGE_FORMAT:format( ErrorMessage ) );
			end
		else -- Couldn't parse/runtime error
			_Dev.Error( L.DUMP_MESSAGE_FORMAT:format( Target ) );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Add all non-printed characters to replacement table
	for Index = 0, 31 do
		EscapeSequences[ strchar( Index ) ] = ( "\\%03d" ):format( Index );
	end
	for Index = 127, 255 do
		EscapeSequences[ strchar( Index ) ] = ( "\\%03d" ):format( Index );
	end


	dump = me.Explore;

	SlashCmdList[ "DEV_DUMP" ] = me.SlashCommand;

	local Forbidden = {
		[ "PRINT" ] = true;
	};
	for Key in pairs( Forbidden ) do
		SlashCmdList[ Key ] = nil;
	end
	setmetatable( SlashCmdList, { __newindex = function ( self, Key, Value )
		if ( not Forbidden[ Key ] ) then
			rawset( self, Key, Value );
		end
	end; } );
end

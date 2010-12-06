--[[ For all Indents and Purposes
Copyright (c) 2007 Kristofer Karlsson <kristofer.karlsson@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

--- This is a _DevPad-specific version of "For All Indents And Purposes",
-- originally by krka <kristofer.karlsson@gmail.com> and modified for Hack by
-- Mud, aka Eric Tetz <erictetz@gmail.com>.
--
-- @usage Apply auto-indentation/syntax highlighting to an editboxe like this:
--   lib.Enable(Editbox, [TabWidth], [ColorTable]);
-- If TabWidth or ColorTable are omitted, those featues won't be applied.
-- ColorTable should map TokenIDs and string Token values to color codes.
-- @see lib.Tokens


local lib = {};
select( 2, ... ).IndentationLib = lib;

local UpdateCooldown = 0.2; -- Time to wait after last keypress before updating




do
	local CursorPosition, CursorDelta;
	--- Callback for gsub to remove unescaped codes.
	local function StripCodeGsub ( Escapes, Code, End )
		if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
			if ( CursorPosition and CursorPosition >= End - 1 ) then
				CursorDelta = CursorDelta - #Code;
			end
			return Escapes;
		end
	end
	--- Removes a single escape sequence.
	local function StripCode ( Pattern, Text, OldCursor )
		CursorPosition, CursorDelta = OldCursor, 0;
		return Text:gsub( Pattern, StripCodeGsub ),
			OldCursor and CursorPosition + CursorDelta;
	end
	--- Strips Text of all color escape sequences.
	-- @param Cursor  Optional cursor position to keep track of.
	-- @return Stripped text, and the updated cursor position if Cursor was given.
	function lib.StripColors ( Text, Cursor )
		Text, Cursor = StripCode( "(|*)(|c%x%x%x%x%x%x%x%x)()", Text, Cursor );
		return StripCode( "(|*)(|r)()", Text, Cursor );
	end
end

do
	local Enabled, Updaters = {}, {};

	local CodeCache, ColoredCache = {}, {};
	local NumLinesCache = {};

	local SetTextBackup, GetTextBackup, InsertBackup;
	--- Reapplies formatting to this editbox using settings from when it was enabled.
	-- @param ForceIndent  Forces auto-indent even if the line count didn't change.
	-- @return True if text was changed.
	function lib:Update ( ForceIndent )
		if ( not Enabled[ self ] ) then
			return;
		end

		local Colored = GetTextBackup( self );
		if ( ColoredCache[ self ] == Colored ) then
			return;
		end
		local Code, Cursor = lib.StripColors( Colored, self:GetCursorPosition() );

		if ( self.faiap_tabWidth ) then
			-- Reindent if line count changes
			local NumLines, IndexLast = 0, 0;
			for Index in Code:gmatch( "[^\r\n]*()" ) do
				if ( IndexLast ~= Index ) then
					NumLines, IndexLast = NumLines + 1, Index;
				end
			end
			if ( NumLinesCache[ self ] ~= NumLines ) then
				NumLinesCache[ self ], ForceIndent = NumLines, true;
			end
		end

		ForceIndent = true;
		local ColoredNew, Cursor = lib.FormatCode( Code,
			ForceIndent and self.faiap_tabWidth, self.faiap_colorTable, Cursor );
		CodeCache[ self ], ColoredCache[ self ] = Code, ColoredNew;

		if ( Colored ~= ColoredNew ) then
			SetTextBackup( self, ColoredNew );
			self:SetCursorPosition( Cursor );
			return true;
		end
	end
	--- @return True if successfully disabled for this editbox.
	function lib:Disable ()
		if ( not Enabled[ self ] ) then
			return;
		end
		Enabled[ self ] = false;
		self.GetText, self.SetText, self.Insert = nil;

		local Code, Cursor = lib.StripColors( self:GetText(),
			self:GetCursorPosition() );
		self:SetText( Code );
		self:SetCursorPosition( Cursor );

		self:SetMaxBytes( self.faiap_maxBytes );
		self:SetCountInvisibleLetters( self.faiap_countInvisible );

		CodeCache[ self ], ColoredCache[ self ] = nil;
		NumLinesCache[ self ] = nil;
		return true;
	end

	local GetTime = GetTime;
	--- Flags the editbox to be reformatted when its contents change.
	local function OnTextChanged ( self, ... )
		if ( Enabled[ self ] ) then
			CodeCache[ self ] = nil;
			local Updater = Updaters[ self ];
			Updater:Stop();
			Updater:Play();
		end
		if ( self.faiap_OnTextChanged ) then
			return self:faiap_OnTextChanged( ... );
		end
	end
	--- Forces a re-indent for this editbox on tab.
	local function OnTabPressed ( self, ... )
		if ( self.faiap_OnTabPressed ) then
			self:faiap_OnTabPressed( ... );
		end
		if ( Enabled[ self ] ) then
			return lib.Update( self, true );
		end
	end
	--- @return Un-colored text as if FAIAP wasn't there.
	-- @param Raw  True to return fully formatted contents.
	local function GetText( self, Raw )
		if ( Raw ) then
			return GetTextBackup( self );
		else
			local Code = CodeCache[ self ];
			if ( not Code ) then
				Code = lib.StripColors( ( GetTextBackup( self ) ) );
				CodeCache[ self ] = Code;
			end
			return Code;
		end
	end
	--- Clears cached contents if set directly.
	-- This is necessary because OnTextChanged won't fire immediately or if the
	-- edit box is hidden.
	local function SetText ( self, ... )
		CodeCache[ self ] = nil;
		return SetTextBackup( self, ... );
	end
	local function Insert ( self, ... )
		CodeCache[ self ] = nil;
		return InsertBackup( self, ... );
	end
	--- Updates the code a moment after the user quits typing.
	local function UpdaterOnFinished ( Updater )
		return lib.Update( Updater:GetParent() );
	end

	local function HookHandler ( self, Handler, Script )
		self[ "faiap_"..Handler ] = self:GetScript( Handler );
		self:SetScript( Handler, Script );
	end
	--- Enables syntax highlighting or auto-indentation on this edit box.
	-- Can be run again to change the TabWidth or ColorTable.
	-- @param TabWidth  Tab width to indent code by, or nil for no indentation.
	-- @param ColorTable  Table of tokens and token types to color codes used for
	--   syntax highlighting, or nil for no syntax highlighting.
	-- @return True if enabled and formatted.
	function lib:Enable ( TabWidth, ColorTable )
		if ( not SetTextBackup ) then
			SetTextBackup, GetTextBackup = self.SetText, self.GetText;
			InsertBackup = self.Insert;
		end
		if ( not ( TabWidth or ColorTable ) ) then
			return lib.Disable( self );
		end

		self.faiap_tabWidth, self.faiap_colorTable = TabWidth, ColorTable;
		if ( Enabled[ self ] ) then
			ColoredCache[ self ] = nil; -- Force update with new tab width/colors
		else
			self.faiap_maxBytes = self:GetMaxBytes();
			self.faiap_countInvisible = self:IsCountInvisibleLetters();
			self:SetMaxBytes( 0 );
			self:SetCountInvisibleLetters( false );
			self.GetText, self.SetText = GetText, SetText;

			if ( Enabled[ self ] == nil ) then -- Never hooked before
				local Updater = self:CreateAnimationGroup();
				Updaters[ self ] = Updater;
				Updater:CreateAnimation( "Animation" ):SetDuration( UpdateCooldown );
				Updater:SetScript( "OnFinished", UpdaterOnFinished );
				HookHandler( self, "OnTextChanged", OnTextChanged );
				HookHandler( self, "OnTabPressed", OnTabPressed );
			end
			Enabled[ self ] = true;
		end

		return lib.Update( self, true );
	end
end




-- Token types
lib.Tokens = {}; --- Token names to TokenTypeIDs, used to define custom ColorTables.
local NewToken;
do
	local Count = 0;
	--- @return A new token ID assigned to Name.
	function NewToken ( Name )
		Count = Count + 1;
		lib.Tokens[ Name ] = Count;
		return Count;
	end
end

local TK_UNKNOWN = NewToken( "UNKNOWN" );
local TK_IDENTIFIER = NewToken( "IDENTIFIER" );
local TK_KEYWORD = NewToken( "KEYWORD" ); -- Reserved words

local TK_ADD = NewToken( "ADD" );
local TK_ASSIGNMENT = NewToken( "ASSIGNMENT" );
local TK_COLON = NewToken( "COLON" );
local TK_COMMA = NewToken( "COMMA" );
local TK_COMMENT_LONG = NewToken( "COMMENT_LONG" );
local TK_COMMENT_SHORT = NewToken( "COMMENT_SHORT" );
local TK_CONCAT = NewToken( "CONCAT" );
local TK_DIVIDE = NewToken( "DIVIDE" );
local TK_EQUALITY = NewToken( "EQUALITY" );
local TK_GT = NewToken( "GT" );
local TK_GTE = NewToken( "GTE" );
local TK_LEFTBRACKET = NewToken( "LEFTBRACKET" );
local TK_LEFTCURLY = NewToken( "LEFTCURLY" );
local TK_LEFTPAREN = NewToken( "LEFTPAREN" );
local TK_LINEBREAK = NewToken( "LINEBREAK" );
local TK_LT = NewToken( "LT" );
local TK_LTE = NewToken( "LTE" );
local TK_MODULUS = NewToken( "MODULUS" );
local TK_MULTIPLY = NewToken( "MULTIPLY" );
local TK_NOTEQUAL = NewToken( "NOTEQUAL" );
local TK_NUMBER = NewToken( "NUMBER" );
local TK_PERIOD = NewToken( "PERIOD" );
local TK_POWER = NewToken( "POWER" );
local TK_RIGHTBRACKET = NewToken( "RIGHTBRACKET" );
local TK_RIGHTCURLY = NewToken( "RIGHTCURLY" );
local TK_RIGHTPAREN = NewToken( "RIGHTPAREN" );
local TK_SEMICOLON = NewToken( "SEMICOLON" );
local TK_SIZE = NewToken( "SIZE" );
local TK_STRING = NewToken( "STRING" );
local TK_STRING_LONG = NewToken( "STRING_LONG" ); -- [=[...]=]
local TK_SUBTRACT = NewToken( "SUBTRACT" );
local TK_VARARG = NewToken( "VARARG" );
local TK_WHITESPACE = NewToken( "WHITESPACE" );

local strbyte = string.byte;
local BYTE_0 = strbyte( "0" );
local BYTE_9 = strbyte( "9" );
local BYTE_ASTERISK = strbyte( "*" );
local BYTE_BACKSLASH = strbyte( "\\" );
local BYTE_CIRCUMFLEX = strbyte( "^" );
local BYTE_COLON = strbyte( ":" );
local BYTE_COMMA = strbyte( "," );
local BYTE_CR = strbyte( "\r" );
local BYTE_DOUBLE_QUOTE = strbyte( "\"" );
local BYTE_E = strbyte( "E" );
local BYTE_e = strbyte( "e" );
local BYTE_EQUALS = strbyte( "=" );
local BYTE_GREATERTHAN = strbyte( ">" );
local BYTE_HASH = strbyte( "#" );
local BYTE_LEFTBRACKET = strbyte( "[" );
local BYTE_LEFTCURLY = strbyte( "{" );
local BYTE_LEFTPAREN = strbyte( "(" );
local BYTE_LESSTHAN = strbyte( "<" );
local BYTE_LF = strbyte( "\n" );
local BYTE_MINUS = strbyte( "-" );
local BYTE_PERCENT = strbyte( "%" );
local BYTE_PERIOD = strbyte( "." );
local BYTE_PLUS = strbyte( "+" );
local BYTE_RIGHTBRACKET = strbyte( "]" );
local BYTE_RIGHTCURLY = strbyte( "}" );
local BYTE_RIGHTPAREN = strbyte( ")" );
local BYTE_SEMICOLON = strbyte( ";" );
local BYTE_SINGLE_QUOTE = strbyte( "'" );
local BYTE_SLASH = strbyte( "/" );
local BYTE_SPACE = strbyte( " " );
local BYTE_TAB = strbyte( "\t" );
local BYTE_TILDE = strbyte( "~" );

local Linebreaks = {
	[ BYTE_CR ] = true;
	[ BYTE_LF ] = true;
};
local Whitespace = {
	[ BYTE_SPACE ] = true;
	[ BYTE_TAB ] = true;
};
--- Mapping of bytes to the only tokens they can represent, or true if indeterminate
local TokenBytes = {
	[ BYTE_ASTERISK ] = TK_MULTIPLY;
	[ BYTE_CIRCUMFLEX ] = TK_POWER;
	[ BYTE_COLON ] = TK_COLON;
	[ BYTE_COMMA ] = TK_COMMA;
	[ BYTE_DOUBLE_QUOTE ] = true;
	[ BYTE_EQUALS ] = true;
	[ BYTE_GREATERTHAN ] = true;
	[ BYTE_HASH ] = TK_SIZE;
	[ BYTE_LEFTBRACKET ] = true;
	[ BYTE_LEFTCURLY ] = TK_LEFTCURLY;
	[ BYTE_LEFTPAREN ] = TK_LEFTPAREN;
	[ BYTE_LESSTHAN ] = true;
	[ BYTE_MINUS ] = true;
	[ BYTE_PERCENT ] = TK_MODULUS;
	[ BYTE_PERIOD ] = true;
	[ BYTE_PLUS ] = TK_ADD;
	[ BYTE_RIGHTBRACKET ] = TK_RIGHTBRACKET;
	[ BYTE_RIGHTCURLY ] = TK_RIGHTCURLY;
	[ BYTE_RIGHTPAREN ] = TK_RIGHTPAREN;
	[ BYTE_SEMICOLON ] = TK_SEMICOLON;
	[ BYTE_SINGLE_QUOTE ] = true;
	[ BYTE_SLASH ] = TK_DIVIDE;
	[ BYTE_TILDE ] = true;
};

local function NextNumberExponentPartInt ( Text, Pos )
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( Byte and Byte >= BYTE_0 and Byte <= BYTE_9 ) then
			Pos = Pos + 1;
		else
			return TK_NUMBER, Pos;
		end
	end
end
local function NextNumberExponentPart ( Text, Pos )
	local Byte = strbyte( Text, Pos );
	if ( not Byte ) then
		return TK_NUMBER, Pos;
	end

	if ( Byte == BYTE_MINUS ) then
		-- Handle this case: "1.2e-- comment" with "1.2e" as a number
		Byte = strbyte( Text, Pos + 1 );
		if ( Byte == BYTE_MINUS ) then
			return TK_NUMBER, Pos;
		end
		return NextNumberExponentPartInt( Text, Pos + 1 );
	end
	return NextNumberExponentPartInt( Text, Pos );
end
local function NextNumberFractionPart ( Text, Pos )
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( Byte and Byte >= BYTE_0 and Byte <= BYTE_9 ) then
			Pos = Pos + 1;
		elseif ( Byte == BYTE_E or Byte == BYTE_e ) then
			return NextNumberExponentPart( Text, Pos + 1 );
		else
			return TK_NUMBER, Pos;
		end
	end
end
local function NextNumber ( Text, Pos )
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( Byte and Byte >= BYTE_0 and Byte <= BYTE_9 ) then
			Pos = Pos + 1;
		elseif ( Byte == BYTE_PERIOD ) then
			return NextNumberFractionPart( Text, Pos + 1 );
		elseif ( Byte == BYTE_E or Byte == BYTE_e ) then
			return NextNumberExponentPart( Text, Pos + 1 );
		else
			return TK_NUMBER, Pos;
		end
	end
end

local function NextIdentifier ( Text, Pos )
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( not Byte
			or Linebreaks[ Byte ] or Whitespace[ Byte ] or TokenBytes[ Byte ]
		) then
			return TK_IDENTIFIER, Pos;
		end
		Pos = Pos + 1;
	end
end

--- @return True, PosNext, EqualsCount if next token is a long string.
local function IsNextLongString ( Text, Start )
	local Byte = strbyte( Text, Start );
	if ( Byte == BYTE_LEFTBRACKET ) then
		local Pos = Start + 1;
		Byte = strbyte( Text, Pos );
		while ( Byte == BYTE_EQUALS ) do
			Pos = Pos + 1;
			Byte = strbyte( Text, Pos );
		end
		if ( Byte == BYTE_LEFTBRACKET ) then
			return true, Pos + 1, ( Pos - 1 ) - Start;
		end
	end
end
local function NextLongString ( Text, Pos, EqualsCount )
	-- Beginning of long string already parsed
	local EqualsCurrent;
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( not Byte ) then
			return TK_STRING_LONG, Pos;
		end

		if ( Byte == BYTE_RIGHTBRACKET ) then
			if ( not EqualsCurrent ) then
				EqualsCurrent = 0;
			elseif ( EqualsCurrent == EqualsCount ) then
				return TK_STRING_LONG, Pos + 1;
			else
				EqualsCurrent = nil;
			end
		elseif ( EqualsCurrent and Byte == BYTE_EQUALS ) then
			EqualsCurrent = EqualsCurrent + 1;
		else
			EqualsCurrent = nil;
		end
		Pos = Pos + 1;
	end
end

local function NextComment ( Text, Pos )
	-- Beginning of short comment already parsed
	local IsLong, PosNext, EqualsCount = IsNextLongString( Text, Pos );
	if ( IsLong ) then
		local _, PosNext = NextLongString( Text, PosNext, EqualsCount );
		return TK_COMMENT_LONG, PosNext;
	end

	-- Short comment, find the first linebreak
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( not Byte or Linebreaks[ Byte ] ) then
			return TK_COMMENT_SHORT, Pos;
		end
		Pos = Pos + 1;
	end
end

local function NextString ( Text, Pos, Quote )
	local Escaped = false;
	while ( true ) do
		local Byte = strbyte( Text, Pos );
		if ( not Byte ) then
			return TK_STRING, Pos;
		end

		if ( Escaped ) then
			Escaped = false;
		elseif ( Byte == BYTE_BACKSLASH ) then
			Escaped = true;
		elseif ( Byte == Quote ) then
			return TK_STRING, Pos + 1;
		end
		Pos = Pos + 1;
	end
end

--- @return Token type or nil if end of string, position of char after token.
local function NextToken ( Text, Pos )
	local Byte = strbyte( Text, Pos );
	if ( not Byte ) then
		return;
	end

	if ( Linebreaks[ Byte ] ) then
		return TK_LINEBREAK, Pos + 1;
	end

	if ( Whitespace[ Byte ] ) then
		while ( Whitespace[ Byte ] ) do
			Pos = Pos + 1;
			Byte = strbyte( Text, Pos );
		end
		return TK_WHITESPACE, Pos;
	end

	local Token = TokenBytes[ Byte ];
	if ( Token ) then
		if ( Token ~= true ) then -- Byte can only represent this token
			return Token, Pos + 1;
		end

		if ( Byte == BYTE_SINGLE_QUOTE or Byte == BYTE_DOUBLE_QUOTE ) then
			return NextString( Text, Pos + 1, Byte );
		end

		if ( Byte == BYTE_LEFTBRACKET ) then
			local IsLongString, PosNext, EqualsCount = IsNextLongString( Text, Pos );
			if ( IsLongString ) then
				return NextLongString( Text, PosNext, EqualsCount );
			else
				return TK_LEFTBRACKET, Pos + 1;
			end
		end

		local Byte2 = strbyte( Text, Pos + 1 );

		if ( Byte == BYTE_MINUS ) then
			if ( Byte2 == BYTE_MINUS ) then
				return NextComment( Text, Pos + 2 );
			end
			return TK_SUBTRACT, Pos + 1;
		end

		if ( Byte == BYTE_EQUALS ) then
			if ( Byte2 == BYTE_EQUALS ) then
				return TK_EQUALITY, Pos + 2;
			end
			return TK_ASSIGNMENT, Pos + 1;
		end

		if ( Byte == BYTE_PERIOD ) then
			if ( Byte2 == BYTE_PERIOD ) then
				if ( strbyte( Text, Pos + 2 ) == BYTE_PERIOD ) then
					return TK_VARARG, Pos + 3;
				end
				return TK_CONCAT, Pos + 2;
			elseif ( Byte2 and Byte2 >= BYTE_0 and Byte2 <= BYTE_9 ) then
				return NextNumberFractionPart( Text, Pos + 2 );
			end
			return TK_PERIOD, Pos + 1;
		end

		if ( Byte == BYTE_LESSTHAN ) then
			if ( Byte2 == BYTE_EQUALS ) then
				return TK_LTE, Pos + 2;
			end
			return TK_LT, Pos + 1;
		end

		if ( Byte == BYTE_GREATERTHAN ) then
			if ( Byte2 == BYTE_EQUALS ) then
				return TK_GTE, Pos + 2;
			end
			return TK_GT, Pos + 1;
		end

		if ( Byte == BYTE_TILDE and Byte2 == BYTE_EQUALS ) then
			return TK_NOTEQUAL, Pos + 2;
		end

		return TK_UNKNOWN, Pos + 1;
	elseif ( Byte >= BYTE_0 and Byte <= BYTE_9 ) then
		return NextNumber( Text, Pos + 1 );
	else
		return NextIdentifier( Text, Pos + 1 );
	end
end


local Keywords = {
	[ "nil" ] = true;
	[ "true" ] = true;
	[ "false" ] = true;
	[ "local" ] = true;
	[ "and" ] = true;
	[ "or" ] = true;
	[ "not" ] = true;
	[ "while" ] = true;
	[ "for" ] = true;
	[ "in" ] = true;
	[ "do" ] = true;
	[ "repeat" ] = true;
	[ "break" ] = true;
	[ "until" ] = true;
	[ "if" ] = true;
	[ "elseif" ] = true;
	[ "then" ] = true;
	[ "else" ] = true;
	[ "function" ] = true;
	[ "return" ] = true;
	[ "end" ] = true;
};
local IndentOpen = { 0, 1 };
local IndentClose = { -1, 0 };
local IndentBoth = { -1, 1 };
local Indents = {
	[ "do" ] = IndentOpen;
	[ "then" ] = IndentOpen;
	[ "repeat" ] = IndentOpen;
	[ "function" ] = IndentOpen;
	[ TK_LEFTPAREN ] = IndentOpen;
	[ TK_LEFTBRACKET ] = IndentOpen;
	[ TK_LEFTCURLY ] = IndentOpen;

	[ "until" ] = IndentClose;
	[ "elseif" ] = IndentClose;
	[ "end" ] = IndentClose;
	[ TK_RIGHTPAREN ] = IndentClose;
	[ TK_RIGHTBRACKET ] = IndentClose;
	[ TK_RIGHTCURLY ] = IndentClose;

	[ "else" ] = IndentBoth;
};


local strrep = string.rep;
local strsub = string.sub;
local tinsert = table.insert;
local Buffer = {};
local ColorStop = "|r";
--- Syntax highlights and indents a string of Lua code.
-- @param CursorOld  Optional cursor position to keep track of.
-- @see lib.Enable
-- @return Formatted text, and an updated cursor position if requested.
function lib:FormatCode ( TabWidth, ColorTable, CursorOld )
	if ( not ( TabWidth or ColorTable ) ) then
		return self, CursorOld;
	end

	wipe( Buffer );
	local BufferLen = 0;
	local Cursor, CursorIndented;
	local ColorLast;

	local LineLast, PassedIndent = 0, false;
	local Depth, DepthNext = 0, 0;

	local TokenType, PosNext, Pos = TK_UNKNOWN, 1;
	while ( TokenType ) do
		Pos, TokenType, PosNext = PosNext, NextToken( self, PosNext );

		if ( TokenType
			and ( PassedIndent or not TabWidth or TokenType ~= TK_WHITESPACE )
		) then
			PassedIndent = true; -- Passed leading whitespace
			local Token = strsub( self, Pos, PosNext - 1 );

			if ( ColorTable ) then -- Add coloring
				local Color = ColorTable[ Keywords[ Token ] and TK_KEYWORD or Token ]
					or ColorTable[ TokenType ];
				if ( ColorLast and not Color ) then -- Stop color
					Buffer[ #Buffer + 1 ], BufferLen = ColorStop, BufferLen + #ColorStop;
				elseif Color and Color ~= ColorLast then -- Change color
					Buffer[ #Buffer + 1 ], BufferLen = Color, BufferLen + #Color;
				end
				ColorLast = Color;
			end

			Buffer[ #Buffer + 1 ], BufferLen = Token, BufferLen + #Token;

			if ( CursorOld and not Cursor and CursorOld < PosNext ) then
				local Offset = PosNext - CursorOld - 1; -- Distance to end of token
				if ( Offset > #Token ) then -- Cursor was in a previous skipped token
					Offset = #Token; -- Move to start of current token
				end
				Cursor = BufferLen - Offset;
			end

			if ( TabWidth ) then -- See if this is an indent-modifier
				local Indent = TokenType == TK_IDENTIFIER
					and Indents[ Token ] or Indents[ TokenType ];
				if ( Indent ) then
					if ( DepthNext > 0 ) then
						DepthNext = DepthNext + Indent[ 1 ];
					else
						Depth = Depth + Indent[ 1 ];
					end
					DepthNext = DepthNext + Indent[ 2 ];
				end
			end
		end

		if ( TabWidth and ( not TokenType or TokenType == TK_LINEBREAK ) ) then
			-- Indent previous line
			local Indent = strrep( " ", Depth * TabWidth );
			BufferLen = BufferLen + #Indent;
			tinsert( Buffer, LineLast + 1, Indent );

			if ( Cursor and not CursorIndented ) then
				Cursor = Cursor + #Indent;
				if ( CursorOld < Pos ) then -- Cursor on this line
					CursorIndented = true;
				end -- Else cursor is on next line and must be indented again
			end

			LineLast, PassedIndent = #Buffer, false;
			Depth, DepthNext = Depth + DepthNext, 0;
			if ( Depth < 0 ) then
				Depth = 0;
			end
		end
	end
	return table.concat( Buffer ), Cursor or 0;
end
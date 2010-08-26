--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.lua - Common Unicode translation functions.  See RFC3629.             *
  *   IntToUTF and UTFToInt based on sarnold@free.fr's library routines at     *
  *   <http://lua-users.org/wiki/ValidateUnicodeString> under the MIT license. *
  ****************************************************************************]]


_UTFOptions = {};


local me = select( 2, ... );
_UTF = me;

me.Min = 0;
me.Max = 0x10FFFF;




--- @return True if Int is a valid codepoint.
function me.IsValidCodepoint ( Int )
	return me.Min <= Int and Int <= me.Max
		and not ( 0xD800 <= Int and Int <= 0xDFFF ); -- Invalid range
end
do
	local strchar = string.char;
	local band = bit.band;
	local rshift = bit.rshift;
	--- Converts a Unicode codepoint to a UTF-8 string.
	-- @param Int  Integer codepoint.
	-- @return 1-4 byte string representing the character, or nil if out of range.
	function me.IntToUTF ( Int )
		if ( me.IsValidCodepoint( Int ) ) then
			if ( Int < 128 ) then -- 1-byte
				return strchar( Int );
			else
				local B1 = 0x80 + band( Int, 0x3F );
				Int = rshift( Int, 6 );
				if ( Int < 32 ) then -- 2-byte
					return strchar( 0xC0 + Int, B1 );
				else
					local B2 = 0x80 + band( Int, 0x3F );
					Int = rshift( Int, 6 );
					if ( Int < 16 ) then -- 3-byte
						if ( Int ~= 13 or B2 < 0xA0 ) then
							return strchar( 0xE0 + Int, B2, B1 );
						end
					elseif ( Int < 0x110 ) then -- 4-byte
						return strchar( 0xF0 + rshift( Int, 6 ), 0x80 + band( Int, 0x3F ), B2, B1 );
					end
				end
			end
		end
	end
end
do
	local lshift = bit.lshift;
	--- Converts a UTF-8 character string into its Unicode codepoint.
	-- @param String  String to read a UTF-8 character from.
	-- @param Index  Optional start position to read from in the string.
	-- @return The character's codepoint and byte length, or nil if an invalid UTF-8 sequence.
	function me.UTFToInt ( String, Index )
		local B1, B2, B3, B4 = String:byte( Index, ( Index or 1 ) + 3 );
		if ( B1 ) then
			if ( B1 < 0x80 ) then
				return B1, 1;
			elseif ( 0xC2 <= B1 and B1 <= 0xF4 -- Octets C0, C1, and F5-FF are invalid
				and B2 and 0x80 <= B2 and B2 < 0xC0
			) then
				local Int = lshift( B1 - 0xC0, 6 ) + ( B2 - 0x80 );
				if ( B1 < 0xE0 ) then -- 2-byte
					return Int, 2;
				elseif ( B3 and 0x80 <= B3 and B3 < 0xC0 ) then -- 3-byte
					Int = lshift( Int - 0x800, 6 ) + ( B3 - 0x80 );
					if ( B1 == 0xED ) then
						if ( B2 < 0xA0 ) then
							return Int, 3;
						end
					elseif ( 0xE0 < B1 and B1 < 0xF0 ) then
						return Int, 3;
					elseif ( B1 == 0xE0 ) then
						if ( 0xA0 <= B2 ) then
							return Int, 3;
						end
					elseif ( B4 and 0x80 <= B4 and B4 < 0xC0 ) then -- 4-byte
						Int = lshift( Int - 0x10000, 6 ) + ( B4 - 0x80 );
						if ( 0xF0 < B1 and B1 < 0xF4 ) then
							return Int, 4;
						elseif ( B1 == 0xF0 ) then
							if ( 0x90 <= B2 ) then
								return Int, 4;
							end
						elseif ( B1 == 0xF4 ) then
							if ( B2 < 0x90 ) then
								return Int, 4;
							end
						end
					end
				end
			end
		end
	end
end




do
	local CursorPosition, CursorDelta;
	local tonumber = tonumber;
	--- Gsub routine to replace entities with UTF-8 character equivalents.
	-- @param Start  Position of first byte in overall string.
	-- @param Flags  Non-alphanumeric characters after the ampersand in an entity.
	-- @param Name  Alphanumeric identifier, either a name, decimal, or hex value.
	-- @param End  Position of last byte in overall string.
	local function GsubReplace ( Start, Flags, Name, End )
		local CodePoint;

		if ( #Flags == 0 ) then -- Character entity
			CodePoint = _UTFOptions.CharacterEntities[ Name ]
				or me.CharacterEntities[ Name ];
		elseif ( Flags == "#" ) then -- Decimal
			-- Prevent tonumber from interpreting implied hex ("0xAA") or exponents ("1e3")
			if ( Name:match( "^%d+$" ) ) then
				CodePoint = tonumber( Name, 10 );
			end
		elseif ( Flags:lower() == "#x" ) then -- Hexadecimal
			if ( Name:match( "^%x+$" ) ) then
				CodePoint = tonumber( Name, 16 );
			end
		end

		if ( CodePoint ) then
			local Char = me.IntToUTF( CodePoint );
			if ( Char and CursorPosition ) then
				if ( CursorPosition >= End - 1 ) then
					CursorDelta = CursorDelta - ( End - Start ) + #Char; -- Shift left to account for removed reference
				elseif ( CursorPosition >= Start ) then
					CursorDelta = CursorDelta - ( CursorPosition - Start + 1 ) + #Char; -- Move cursor to after the replacement glyph
				end
			end
			return Char;
		end
	end
	--- Replaces character entity references with Unicode characters.
	-- @param Text  String to replace entities in.
	-- @param OldCursorPosition  Optional current cursor position.  If set, calculates new position after replacements.
	-- @return String with entities replaced by UTF-8 sequences, and the updated cursor position if OldCursorPosition was set.
	function me.ReplaceCharacterReferences ( Text, OldCursorPosition )
		CursorPosition, CursorDelta = OldCursorPosition, 0;
		return Text:gsub( "()&(#?[Xx]?)(%w+);()", GsubReplace ),
			CursorPosition and ( CursorPosition + CursorDelta );
	end
end
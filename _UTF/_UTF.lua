--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.lua - Common Unicode translation functions.                           *
  *                                                                            *
  * + Provides various functions to convert between code points and the UTF-   *
  *   encoded characters they represent.                                       *
  * + Replaces HTML character entities with the characters they represent. The *
  *   following example formats are supported:                                 *
  *   + &<EntityName>;, where <EntityName> is found in the                     *
  *     _UTF.CharacterEntities.lua file.                                       *
  *   + &#<DecCodePoint>;, where <DecCodePoint> is a decimal representation of *
  *     the character's code point.                                            *
  *   + &#x<HexCodePoint>;, where <HexCodePoint> is a hexadecimal              *
  *     representation of the character's code point.                          *
  ****************************************************************************]]


_UTFOptions = {};


local me = {
	Min = 0;
	Max = 1114111;
};
_UTF = me;




--[[****************************************************************************
  * Function: _UTF.Print                                                       *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
do
	local tostring = tostring;
	me.Print = _Dev and _Dev.Print or function ( Message, ChatFrame, Color )
		if ( not Color ) then
			Color = NORMAL_FONT_COLOR;
		end
		( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( tostring( Message ), Color.r, Color.g, Color.b, Color.id );
	end;
end


--[[****************************************************************************
  * Function: _UTF.HexToDec                                                    *
  * Description: Parses a string representation of a hexadecimal number.       *
  ****************************************************************************]]
do
	local tonumber = tonumber;
	function me.HexToDec ( String )
		return tonumber( String, 16 );
	end
end
--[[****************************************************************************
  * Function: _UTF.DecToHex                                                    *
  * Description: Returns a string representing a given number in hexadecimal.  *
  ****************************************************************************]]
function me.DecToHex ( Int )
	return ( "%X" ):format( Int );
end
--[[****************************************************************************
  * Function: _UTF.DecToUTF                                                    *
  * Description: Takes an integer and returns the corresponding UTF-8 string   *
  *   of bytes.                                                                *
  ****************************************************************************]]
do
	local strchar = strchar;
	local bor = bit.bor;
	local band = bit.band;
	local rshift = bit.rshift;
	function me.DecToUTF ( Int )
		if ( Int < 128 ) then -- 1-byte
			return strchar( Int );
		elseif ( Int < 2048 ) then -- 2-byte
			return strchar( bor( 192, rshift( Int, 6 ) ),
				bor( 128, band( 63, Int ) ) );
		elseif ( Int < 65536 ) then -- 3-byte
			return strchar( bor( 224, rshift( Int, 12 ) ),
				bor( 128, band( 63, rshift( Int, 6 ) ) ),
				bor( 128, band( 63, Int ) ) );
		elseif ( Int < 1114112 ) then -- 4-byte
			return strchar( bor( 240, rshift( Int, 18 ) ),
				bor( 128, band( 63, rshift( Int, 12 ) ) ),
				bor( 128, band( 63, rshift( Int, 6 ) ) ),
				bor( 128, band( 63, Int ) ) );
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.UTFToDec                                                    *
  * Description: Takes a UTF-8 string and returns the corresponding            *
  *   character's integer value.                                               *
  ****************************************************************************]]
do
	local lshift = bit.lshift;
	function me.UTFToDec ( String )
		local Length = #String;
	
		if ( Length == 1 ) then
			local B1 = String:byte();
			return B1 < 128 and B1;
		elseif ( Length == 2 ) then
			local B1, B2 = String:byte(), String:byte( 2 );
			if ( B1 >= 192 and B1 < 224 and B2 >= 128 and B2 < 192 ) then
				return lshift( B1 - 192, 6 ) + B2 - 128;
			end
		elseif ( Length == 3 ) then
			local B1, B2, B3 = String:byte(), String:byte( 2 ), String:byte( 3 );
			if ( B1 >= 224 and B1 < 240 and B2 >= 128 and B2 < 191 and B3 >= 128 and B3 < 192 ) then
				return lshift( B1 - 224, 12 ) + lshift( B2 - 128, 6 ) + B3 - 128;
			end
		elseif ( Length == 4 ) then
			local B1, B2, B3, B4 = String:byte(), String:byte( 2 ), String:byte( 3 ), String:byte( 4 );
			if ( B1 >= 240 and B1 < 248 and B2 >= 128 and B2 < 191 and B3 >= 128 and B3 < 192 and B4 >= 128 and B4 < 192 ) then
				return lshift( B1 - 224, 18 ) + lshift( B2 - 128, 12 ) + lshift( B3 - 128, 6 ) + B4 - 128;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.HexToUTF                                                    *
  * Description: Takes a hexadecimal string representation of an integer and   *
  *   returns the corresponding UTF-8 string of bytes.                         *
  ****************************************************************************]]
do
	local DecToUTF = me.DecToUTF;
	local HexToDec = me.HexToDec;
	function me.HexToUTF ( String )
		return DecToUTF( HexToDec( String ) );
	end
end




--[[****************************************************************************
  * Function: _UTF.GsubReplaceCharacterReferences                              *
  * Description: Gsub handler function to replace character entities.          *
  ****************************************************************************]]
do
	local HexToDec = me.HexToDec;
	local DecToUTF = me.DecToUTF;
	local tonumber = tonumber;
	function me.GsubReplaceCharacterReferences ( Flags, Name )
		local CodePoint;
	
		if ( #Flags == 0 ) then -- Character entity
			CodePoint = _UTFOptions.CharacterEntities[ Name ]
				or me.CharacterEntities[ Name ];
		elseif ( Flags == "#" ) then -- Decimal
			CodePoint = tonumber( Name );
		elseif ( Flags:lower() == "#x" ) then -- Hexadecimal
			CodePoint = HexToDec( Name );
		end
	
		if ( CodePoint ) then
			return DecToUTF( CodePoint );
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.ReplaceCharacterReferences                                  *
  * Description: Replaces character entity references with Unicode characters. *
  ****************************************************************************]]
function me.ReplaceCharacterReferences ( Text )
	return ( Text:gsub( "&(#?[Xx]?)(%w+);", me.GsubReplaceCharacterReferences ) );
end

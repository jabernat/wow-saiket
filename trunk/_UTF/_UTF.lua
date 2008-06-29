--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.lua - Common functions.                                               *
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


_UTF = {
	Blocks = {};
	UnicodeData = {};
	CharacterEntities = {};

	Min = 0;
	Max = 1114111;

	Pane;

	ChatEditSendTextBackup = ChatEdit_SendText;


--[[****************************************************************************
  * Function: _UTF.Print                                                       *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
Print = _Dev and _Dev.Print or function ( Message, ChatFrame, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( tostring( Message ), Color.r, Color.g, Color.b, Color.id );
end;


--[[****************************************************************************
  * Function: _UTF.HexToDec                                                    *
  * Description: Parses a string representation of a hexadecimal number.       *
  ****************************************************************************]]
HexToDec = function ( String )
	return tonumber( String, 16 );
end;
--[[****************************************************************************
  * Function: _UTF.DecToHex                                                    *
  * Description: Returns a string representing a given number in hexadecimal.  *
  ****************************************************************************]]
DecToHex = function ( Int )
	return string.format( "%X", Int );
end;


--[[****************************************************************************
  * Function: _UTF.DecToUTF                                                    *
  * Description: Takes an integer and returns the corresponding UTF-8 string   *
  *   of bytes.                                                                *
  ****************************************************************************]]
DecToUTF = function ( Int )
	if ( Int < 128 ) then
		-- 1-byte
		return string.char( Int );
	elseif ( Int < 2048 ) then
		-- 2-byte
		return string.char( bit.bor( 192, bit.rshift( Int, 6 ) ), bit.bor( 128, bit.band( 63, Int ) ) );
	elseif ( Int < 65536 ) then
		-- 3-byte
		return string.char( bit.bor( 224, bit.rshift( Int, 12 ) ), bit.bor( 128, bit.band( 63, bit.rshift( Int, 6 ) ) ), bit.bor( 128, bit.band( 63, Int ) ) );
	elseif ( Int < 1114112 ) then
		-- 4-byte
		return string.char( bit.bor( 240, bit.rshift( Int, 18 ) ), bit.bor( 128, bit.band( 63, bit.rshift( Int, 12 ) ) ), bit.bor( 128, bit.band( 63, bit.rshift( Int, 6 ) ) ), bit.bor( 128, bit.band( 63, Int ) ) );
	end
end;
--[[****************************************************************************
  * Function: _UTF.UTFToDec                                                    *
  * Description: Takes a UTF-8 string and returns the corresponding            *
  *   character's integer value.                                               *
  ****************************************************************************]]
UTFToDec = function ( String )
	if ( string.find( String, "^[%z-\127]$" ) ) then
		-- 1-byte
		return string.byte( String );
	elseif ( string.find( String, "^[\192-\223][\128-\191]$" ) ) then
		-- 2-byte
		return bit.lshift( string.byte( String ) - 192, 6 ) + string.byte( String, 2 ) - 128;
	elseif ( string.find( String, "^[\224-\239][\128-\191][\128-\191]$" ) ) then
		-- 3-byte
		return bit.lshift( string.byte( String ) - 224, 12 ) + bit.lshift( string.byte( String, 2 ) - 128, 6 ) + string.byte( String, 3 ) - 128;
	elseif ( string.find( String, "^[\240-\247][\128-\191][\128-\191][\128-\191]$" ) ) then
		-- 4-byte
		return bit.lshift( string.byte( String ) - 224, 18 ) + bit.lshift( string.byte( String, 2 ) - 128, 12 ) + bit.lshift( string.byte( String, 3 ) - 128, 6 ) + string.byte( String, 4 ) - 128;
	end
end;
--[[****************************************************************************
  * Function: _UTF.HexToUTF                                                    *
  * Description: Takes a hexadecimal string representation of an integer and   *
  *   returns the corresponding UTF-8 string of bytes.                         *
  ****************************************************************************]]
HexToUTF = function ( String )
	return _UTF.DecToUTF( _UTF.HexToDec( String ) );
end;
	



--[[****************************************************************************
  * Function: _UTF.SetPane                                                     *
  * Description: TODO()                                                        *
  ****************************************************************************]]
SetPane = function ( PaneID )
	PanelTemplates_SetTab( _UTFFrame, PaneID );

	_UTF.Pane = PaneID;
	for Index = 1, _UTFFrame.numTabs do
		local Pane = getglobal( "_UTFFramePane"..Index );
		if ( Index == PaneID ) then
			Pane:Show();
		else
			Pane:Hide();
		end
	end
end;


--[[****************************************************************************
  * Function: _UTF.OnHide                                                      *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnHide = function ()
	PlaySound( "igCharacterInfoClose" );
end;
--[[****************************************************************************
  * Function: _UTF.OnShow                                                      *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnShow = function ()
	if ( not _UTF.Pane ) then
		_UTF.SetPane( 1 );
	end
	PlaySound( "igCharacterInfoOpen" );
end;
--[[****************************************************************************
  * Function: _UTF.OnLoad                                                      *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnLoad = function ()
	this:SetUserPlaced( true );
end;

--[[****************************************************************************
  * Function: _UTF.Toggle                                                      *
  * Description: TODO()                                                        *
  ****************************************************************************]]
Toggle = function ( Show )
	if ( Show == nil ) then
		Show = not _UTFFrame:IsVisible();
	end

	if ( Show ) then
		_UTFFrame:Show();
	else
		_UTFFrame:Hide();
	end
end;

--[[****************************************************************************
  * Function: _UTF.SlashCommand                                                *
  * Description: TODO()                                                        *
  ****************************************************************************]]
SlashCommand = function ( Show )
	_UTF.Toggle();
end;


--[[****************************************************************************
  * Function: _UTF.GsubReplaceCharacterReferences                              *
  * Description: TODO()                                                        *
  ****************************************************************************]]
GsubReplaceCharacterReferences = function ( Flags, Name )
	if ( string.len( Flags ) == 0 ) then
		-- Name is a character entity
		if ( _UTF.CharacterEntities[ Name ] ) then
			return _UTF.DecToUTF( _UTF.CharacterEntities[ Name ] );
		end
	else
		local CodePoint;
		if ( Flags == "#" ) then -- Name is decimal
			CodePoint = tonumber( Name );
		elseif ( string.lower( Flags ) == "#x" ) then -- Name is hexadecimal
			CodePoint = tonumber( Name, 16 );
		end
		if ( CodePoint ) then
			return _UTF.DecToUTF( CodePoint );
		end
	end

	-- Not a valid character reference
	return "&"..Flags..Name..";";
end;
--[[****************************************************************************
  * Function: _UTF.ReplaceCharacterReferences                                  *
  * Description: TODO()                                                        *
  ****************************************************************************]]
ReplaceCharacterReferences = function ( Text )
	return ( string.gsub( Text, "&(#?[Xx]?)(%w+);", _UTF.GsubReplaceCharacterReferences ) );
end;

--[[****************************************************************************
  * Function: _UTF.ChatEditSendText                                            *
  * Description: TODO()                                                        *
  ****************************************************************************]]
ChatEditSendText = function ( EditBox, AddHistory )
	EditBox:SetText( _UTF.ReplaceCharacterReferences( EditBox:GetText() ) );
	_UTF.ChatEditSendTextBackup( EditBox, AddHistory );
end;




--------------------------------------------------------------------------------
-- _UTF.Tab
-----------

	Tab = {

--[[****************************************************************************
  * Function: _UTF.Tab.OnClick                                                 *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnClick = function ()
	PlaySound( "igCharacterInfoTab" );
	_UTF.SetPane( this:GetID() );
end;
--[[****************************************************************************
  * Function: _UTF.Tab.OnLoad                                                  *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnLoad = function ()
	local Window = this:GetParent();
	local ID = this:GetID();

	if ( ID ~= 1 ) then
		this:SetPoint( "LEFT", getglobal( Window:GetName().."Tab"..( ID - 1 ) ), "RIGHT", -12, 0 );
	else
		this:SetPoint( "TOPLEFT", Window, "BOTTOMLEFT", 4, 8 );
	end
	PanelTemplates_SetNumTabs( Window, Window.numTabs and Window.numTabs + 1 or 1 );
end;

	}; -- End _UTF.Tab

}; -- End _UTF




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

SlashCmdList[ "UTF" ] = _UTF.SlashCommand;

ChatEdit_SendText = _UTF.ChatEditSendText;

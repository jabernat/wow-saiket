--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Browse.lua - Frame for finding individual characters by ID or by      *
  *   automatically scanning for ones that exist in the current font.          *
  *                                                                            *
  * + Using the mouse wheel over the frame will initiate a scan in the given   *
  *   direction that will stop when the next character is found in the font.   *
  ****************************************************************************]]


_UTF.Browse = {


--[[****************************************************************************
  * Function: _UTF.Browse.IsVisible                                            *
  * Description: TODO()                                                        *
  ****************************************************************************]]
IsVisible = function ( Frame )
	return getglobal( Frame:GetName().."GlyphText" ):GetStringWidth() ~= 0;
end;
--[[****************************************************************************
  * Function: _UTF.Browse.NextChar                                             *
  * Description: TODO()                                                        *
  ****************************************************************************]]
NextChar = function ( Frame )
	if ( not Frame.Direction ) then
		return;
	end

	local EditBox = getglobal( Frame:GetName().."Value" );
	local Int = _UTF.HexToDec( EditBox:GetText() ) + Frame.Direction;

	EditBox:SetText( _UTF.DecToHex( Int ) );
end;
--[[****************************************************************************
  * Function: _UTF.Browse.EndSeek                                              *
  * Description: TODO()                                                        *
  ****************************************************************************]]
EndSeek = function ( Frame )
	getglobal( Frame:GetName().."Glyph" ):Enable();
	getglobal( Frame:GetName().."GlyphBackground" ):Show();

	Frame:SetScript( "OnUpdate", _UTF.Browse.OnUpdateCheck );
	Frame.Started = nil;
	Frame.Direction = nil;
end;
--[[****************************************************************************
  * Function: _UTF.Browse.BeginSeek                                            *
  * Description: TODO()                                                        *
  ****************************************************************************]]
BeginSeek = function ( Frame, Direction )
	local Int = _UTF.HexToDec( getglobal( Frame:GetName().."Value" ):GetText() );
	if ( Direction < 0 and Int <= _UTF.Min or Direction > 0 and Int >= _UTF.Max ) then
		return;
	end

	getglobal( Frame:GetName().."Glyph" ):Disable();
	getglobal( Frame:GetName().."GlyphBackground" ):Hide();

	Frame:SetScript( "OnUpdate", _UTF.Browse.OnUpdateSeek );
	Frame.Direction = Direction;
	_UTF.Browse.NextChar( Frame );
end;


--[[****************************************************************************
  * Function: _UTF.Browse.GlyphOnClick                                         *
  * Description: TODO()                                                        *
  ****************************************************************************]]
GlyphOnClick = function ()
	local EditBox = DEFAULT_CHAT_FRAME.editBox;
	if ( not EditBox:IsVisible() ) then
		EditBox:Show();
	end
	EditBox:Insert( this:GetText() );
end;


--[[****************************************************************************
  * Function: _UTF.Browse.OnMouseWheel                                         *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnMouseWheel = function ()
	_UTF.Browse.BeginSeek( this, arg1 );
end;
--[[****************************************************************************
  * Function: _UTF.Browse.OnUpdateCheck                                        *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnUpdateCheck = function ()
	-- Skip the first frame
	if ( not this.Checking ) then
		this.Checking = true;
		return;
	end

	local Button = getglobal( this:GetName().."Glyph" );
	local Background = getglobal( this:GetName().."GlyphBackground" );
	if ( not _UTF.Browse.IsVisible( this ) ) then
		Button:SetText( _UTF_BROWSE_GLYPH_NOTAVAILABLE );
		Button:Disable();
		Background:Hide();
	else
		Button:Enable();
		Background:Show();
	end

	this:SetScript( "OnUpdate", nil );
	this.Checking = nil;
end;
--[[****************************************************************************
  * Function: _UTF.Browse.OnUpdateSeek                                         *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnUpdateSeek = function ()
	-- Skip the first frame
	if ( not this.Started ) then
		this.Started = true;
		return;
	end

	local Int = _UTF.HexToDec( getglobal( this:GetName().."Value" ):GetText() );

	-- If Int is nil, the user probably tried typing in the Value field while the frame was seeking to the next character
	if ( Int ) then
		if ( Int <= _UTF.Min or Int >= _UTF.Max or _UTF.Browse.IsVisible( this ) ) then
			-- Found the next available character or finished with no results; end search
			_UTF.Browse.EndSeek( this );
		else
			_UTF.Browse.NextChar( this );
		end
	end
end;


--[[****************************************************************************
  * Function: _UTF.Browse.Toggle                                               *
  * Description: TODO()                                                        *
  ****************************************************************************]]
Toggle = function ( Show )
	local Frame = _UTFBrowseFrame;

	if ( Show == nil ) then
		Show = not Frame:IsVisible();
	end

	if ( Show ) then
		local CharMap = _UTFCharMapFrame;
		if ( not _UTFCharMapFrame:IsVisible() ) then
			_UTFCharMapFrame:Show();
		end
		Frame:Show();
	else
		Frame:Hide();
	end
end;


--------------------------------------------------------------------------------
-- _UTF.Browse.Value
--------------------

	Value = {

--[[****************************************************************************
  * Function: _UTF.Browse.Value.OnEscapePressed                                *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnEscapePressed = function ()
	local Frame = this:GetParent();
	if ( Frame.Direction ) then
		_UTF.Browse.EndSeek( Frame );
	else
		this:ClearFocus();
	end
end;
--[[****************************************************************************
  * Function: _UTF.Browse.Value.OnTextChanged                                  *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnTextChanged = function ()
	local Frame = this:GetParent();
	local Text = this:GetText();
	local Int;

	if ( Text == "" ) then
		Int = _UTF.Min;
		this.Last = Int;
	else
		Int = _UTF.HexToDec( Text );
		if ( not Int or Int < _UTF.Min or Int > _UTF.Max ) then
			Int = this.Last;
		else
			this.Last = Int;
		end
	end

	this:SetText( _UTF.DecToHex( Int ) );
	getglobal( Frame:GetName().."Glyph" ):SetText( _UTF.DecToUTF( Int ) );

	if ( not Frame.Direction ) then
		Frame:SetScript( "OnUpdate", _UTF.Browse.OnUpdateCheck );
	end
end;
--[[****************************************************************************
  * Function: _UTF.Browse.Value.OnLoad                                         *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnLoad = function ()
	this.Last = _UTF.Min;
	this:SetText( _UTF.Min );
end;

	}; -- End _UTF.Browse.Value

}; -- End _UTF.Browse

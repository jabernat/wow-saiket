--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Browse.lua - Frame for finding individual characters by ID or by      *
  *   automatically scanning for glyphs that exist in the current font.        *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame", "_UTFBrowse", UIParent );
_UTF.Browse = me;

me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );




--[[****************************************************************************
  * Function: _UTF.Browse:IsGlyphVisible                                       *
  * Description: Determines whether the current character is visible.          *
  ****************************************************************************]]
function me:IsGlyphVisible ()
	return self.Glyph.Text:GetStringWidth() ~= 0;
end
--[[****************************************************************************
  * Function: _UTF.Browse:GetCodePoint                                         *
  * Description: Gets the current code point.                                  *
  ****************************************************************************]]
do
	local min = min;
	local max = max;
	function me:GetCodePoint ()
		return max( _UTF.Min, min( _UTF.Max, self.EditBox:GetNumber() ) );
	end
end
--[[****************************************************************************
  * Function: _UTF.Browse:NextChar                                             *
  * Description: Increments the current code point in the scan's direction.    *
  ****************************************************************************]]
function me:NextChar ()
	if ( not self.Direction ) then
		return;
	end

	self.EditBox:SetNumber( self:GetCodePoint() + self.Direction );
end
--[[****************************************************************************
  * Function: _UTF.Browse:EndSeek                                              *
  * Description: Ends any scan in progress.                                    *
  ****************************************************************************]]
function me:EndSeek ()
	local Glyph = self.Glyph;
	Glyph.Text:SetAlpha( 1.0 );
	Glyph:Enable();
	Glyph.Background:Show();

	self:SetScript( "OnUpdate", self.OnUpdateCheck );
	self.Started = nil;
	self.Direction = nil;
end
--[[****************************************************************************
  * Function: _UTF.Browse:BeginSeek                                            *
  * Description: Starts a scan to the next available character.                *
  ****************************************************************************]]
function me:BeginSeek ( Direction )
	local CodePoint = self:GetCodePoint();
	if ( ( Direction < 0 and CodePoint == _UTF.Min )
		or ( Direction > 0 and CodePoint == _UTF.Max )
	) then
		return;
	end

	local Glyph = self.Glyph;
	Glyph:Disable();
	Glyph.Background:Hide();

	self:SetScript( "OnUpdate", self.OnUpdateSeek );
	self.Direction = Direction;
	self:NextChar();
	Glyph.Text:SetAlpha( 0.0 ); -- Hide '?' when character missing
end




--[[****************************************************************************
  * Function: _UTF.Browse:OnMouseWheel                                         *
  * Description: Initiates a character scan in the given direction.            *
  ****************************************************************************]]
function me:OnMouseWheel ( Delta )
	self:BeginSeek( Delta );
end
--[[****************************************************************************
  * Function: _UTF.Browse:OnUpdateCheck                                        *
  * Description: Checks the previously set glyph's display state.              *
  ****************************************************************************]]
function me:OnUpdateCheck ()
	-- Skip the first frame
	if ( not self.Checking ) then
		self.Checking = true;
		return;
	end

	local Glyph = self.Glyph;
	if ( not self:IsGlyphVisible() ) then
		Glyph:SetText( L.BROWSE_GLYPH_NOTAVAILABLE );
		Glyph:Disable();
		Glyph.Background:Hide();
	else
		Glyph:Enable();
		Glyph.Background:Show();
	end

	self:SetScript( "OnUpdate", nil );
	self.Checking = nil;
end
--[[****************************************************************************
  * Function: _UTF.Browse:OnUpdateSeek                                         *
  * Description: Increments or stops the current seek each frame.              *
  ****************************************************************************]]
function me:OnUpdateSeek ()
	-- Skip the first frame
	if ( not self.Started ) then
		self.Started = true;
		return;
	end

	local CodePoint = self:GetCodePoint();
	if ( CodePoint == _UTF.Min or CodePoint == _UTF.Max or self:IsGlyphVisible() ) then
		-- Found the next available character or finished with no results; end search
		self:EndSeek();
	else
		self:NextChar();
	end
end
--[[****************************************************************************
  * Function: _UTF.Browse:OnHide                                               *
  * Description: Plays a closing sound when the _UTF window is closed.         *
  ****************************************************************************]]
function me:OnHide ()
	PlaySound( "igCharacterInfoClose" );
end
--[[****************************************************************************
  * Function: _UTF.Browse:OnShow                                               *
  * Description: Plays an opening sound when the _UTF window is opened.        *
  ****************************************************************************]]
function me:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
end




--[[****************************************************************************
  * Function: _UTF.Browse.Toggle                                               *
  * Description: Toggles the _UTF browse window.                               *
  ****************************************************************************]]
function me.Toggle ( Show )
	if ( Show == nil ) then
		Show = not me:IsVisible();
	end
	if ( Show ) then
		me:Show();
	else
		me:Hide();
	end
end
--[[****************************************************************************
  * Function: _UTF.Browse.ToggleSlashCommand                                   *
  * Description: Slash command that toggles the _UTF browse window.            *
  ****************************************************************************]]
function me.ToggleSlashCommand ()
	me.Toggle();
end




--[[****************************************************************************
  * Function: _UTF.Browse:GlyphOnUpdate                                        *
  * Description: Readjusts the glyph text's size.                              *
  ****************************************************************************]]
function me:GlyphOnUpdate ()
	self.Text:SetTextHeight( self:GetHeight() - 30 );
end
--[[****************************************************************************
  * Function: _UTF.Browse:GlyphOnClick                                         *
  * Description: Adds the current character to the chat edit box if visible.   *
  ****************************************************************************]]
function me:GlyphOnClick ()
	if ( MacroFrameText and MacroFrameText:IsVisible() and MacroFrameText:HasFocus() ) then
		MacroFrameText:Insert( self:GetText() );
	else
		local EditBox = DEFAULT_CHAT_FRAME.editBox;
		if ( EditBox:IsVisible() ) then
			EditBox:Insert( self:GetText() );
		end
	end
end


--[[****************************************************************************
  * Function: _UTF.Browse:EditBoxOnEscapePressed                               *
  * Description: Clears keyboard focus and stops scans.                        *
  ****************************************************************************]]
function me:EditBoxOnEscapePressed ()
	local Pane = self:GetParent();
	if ( Pane.Direction ) then
		Pane:EndSeek();
	else
		self:ClearFocus();
	end
end
--[[****************************************************************************
  * Function: _UTF.Browse:EditBoxOnTextChanged                                 *
  * Description: Updates the glyph graphic when the value changes.             *
  ****************************************************************************]]
function me:EditBoxOnTextChanged ()
	local Pane = self:GetParent();
	local CodePoint = Pane:GetCodePoint();
	self:SetNumber( CodePoint );

	Pane.Glyph:SetText( _UTF.DecToUTF( CodePoint ) );

	if ( not Pane.Direction ) then
		Pane:SetScript( "OnUpdate", me.OnUpdateCheck );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Set up window
	me:Hide();
	me:SetSize( 200, 192 );
	me:SetPoint( "CENTER" );
	me:SetFrameStrata( "DIALOG" );
	me:EnableMouse( true );
	me:SetToplevel( true );
	me:SetBackdrop( {
		bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
		edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder";
		tile = true; tileSize = 32; edgeSize = 32;
		insets = { left = 7; right = 5; top = 3; bottom = 6; };
	} );
	-- Make dragable
	me:SetMovable( true );
	me:SetUserPlaced( true );
	me:SetClampedToScreen( true );
	me:CreateTitleRegion():SetAllPoints();
	-- Close button
	CreateFrame( "Button", nil, me, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 4, 4 );
	-- Title
	me.Title:SetText( L.BROWSE_TITLE );
	me.Title:SetPoint( "TOPLEFT", me, 11, -6 );
	me:EnableMouseWheel( true );


	me:SetScript( "OnMouseWheel", me.OnMouseWheel );
	me:SetScript( "OnHide", me.OnHide );
	me:SetScript( "OnShow", me.OnShow );


	-- Create edit box
	local Label = me:CreateFontString( nil, "ARTWORK", "GameFontDisableSmall" );
	Label:SetText( L.BROWSE_CODEPOINT );
	Label:SetHeight( 16 );
	Label:SetPoint( "BOTTOMLEFT", 12, 12 );
	local EditBox = CreateFrame( "EditBox", "_UTFBrowseEditBox", me, "InputBoxTemplate" );
	me.EditBox = EditBox;
	EditBox:SetPoint( "TOPLEFT", Label, "TOPRIGHT", 8, 0 );
	EditBox:SetPoint( "BOTTOMRIGHT", -12, 12 );
	EditBox:SetAutoFocus( false );
	EditBox:SetMaxLetters( floor( log10( _UTF.Max ) ) + 1 );
	EditBox:SetNumeric( true );
	EditBox:SetScript( "OnEditFocusGained", nil );
	EditBox:SetScript( "OnEscapePressed", me.EditBoxOnEscapePressed );
	EditBox:SetScript( "OnTextChanged", me.EditBoxOnTextChanged );


	-- Create glyph button
	local Glyph = CreateFrame( "Button", nil, me );
	me.Glyph = Glyph;
	Glyph:SetPoint( "TOPLEFT", 12, -34 );
	Glyph:SetPoint( "BOTTOMRIGHT", EditBox, "TOPRIGHT", 2, 12 );
	Glyph:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background";
		tile = true; tileSize = 32;
	} );
	Glyph:SetScript( "OnUpdate", me.GlyphOnUpdate );
	Glyph:SetScript( "OnClick", me.GlyphOnClick );

	-- Set up glyph font
	local GlyphFont = CreateFont( "_UTFBrowseGlyphFont" );
	Glyph.Font = GlyphFont;
	GlyphFont:SetFont( "Fonts\\ARIALN.TTF", 50 );
	GlyphFont:SetTextColor( 1.0, 0.82, 0.0 );

	local GlyphFontDisable = CreateFont( "_UTFBrowseGlyphFontDisable" );
	Glyph.FontDisable = GlyphFontDisable;
	GlyphFontDisable:SetFontObject( GlyphFont );
	GlyphFontDisable:SetTextColor( 0.5, 0.5, 0.5 );

	local GlyphFontHighlight = CreateFont( "_UTFBrowseGlyphFontHighlight" );
	Glyph.FontHighlight = GlyphFontHighlight;
	GlyphFontHighlight:SetFontObject( GlyphFont );
	GlyphFontHighlight:SetTextColor( 1.0, 1.0, 1.0 );

	Glyph:SetNormalFontObject( GlyphFont );
	Glyph:SetDisabledFontObject( GlyphFontDisable );
	Glyph:SetHighlightFontObject( GlyphFontHighlight );

	-- Initialize button text
	local GlyphText = Glyph:CreateFontString();
	Glyph.Text = GlyphText;
	GlyphText:SetSize( 0, 0 );
	GlyphText:SetPoint( "CENTER" );
	Glyph:SetFontString( GlyphText );

	-- Add background to text
	local GlyphBackground = Glyph:CreateTexture( nil, "BACKGROUND" );
	Glyph.Background = GlyphBackground;
	GlyphBackground:SetAllPoints( GlyphText );
	GlyphBackground:SetTexture( 0.1, 0.1, 0.1 );


	-- Initialize to character 0
	EditBox:SetNumber( _UTF.Min );

	SlashCmdList[ "_UTFTOGGLE" ] = me.ToggleSlashCommand;
end

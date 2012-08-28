--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Browse.lua - Frame for finding individual characters by ID or by      *
  *   automatically scanning for glyphs that exist in the current font.        *
  ****************************************************************************]]


local _UTF = select( 2, ... );
local L = _UTF.L;
local NS = CreateFrame( "Frame", "_UTFBrowse", UIParent );
_UTF.Browse = NS;

local Glyph = CreateFrame( "Button", nil, NS );
NS.Glyph = Glyph;
Glyph.Font = CreateFont( "_UTFBrowseGlyphFont" );
Glyph.FontDisable = CreateFont( "_UTFBrowseGlyphFontDisable" );
Glyph.FontHighlight = CreateFont( "_UTFBrowseGlyphFontHighlight" );

NS.EntityName = CreateFrame( "EditBox", "_UTFBrowseEntityName", NS, "InputBoxTemplate" );
NS.CodePoint = CreateFrame( "EditBox", "_UTFBrowseCodePoint", NS, "InputBoxTemplate" );




--- Determines whether the current character is visible.
-- @return True if current codepoint's glyph is visible.
function NS.IsGlyphVisible ()
	return Glyph.Text:GetStringWidth() ~= 0;
end


do
	--- Gets the entity name that corresponds to a codepoint.
	local function FindCodePointName ( Search )
		for Name, CodePoint in pairs( _UTFOptions.CharacterEntities ) do
			if ( CodePoint == Search ) then
				return Name;
			end
		end
		for Name, CodePoint in pairs( _UTF.CharacterEntities ) do
			if ( CodePoint == Search ) then
				return Name;
			end
		end
	end
	local CodePoint;
	--- Sets the current glyph to a code point.
	-- @param NewCodePoint  Codepoint between _UTF.Min and _UTF.Max.
	-- @return True if codepoint changed.
	function NS.SetCodePoint ( NewCodePoint )
		NewCodePoint = tonumber( NewCodePoint );
		if ( NewCodePoint and CodePoint ~= NewCodePoint
			and _UTF.Min <= NewCodePoint and NewCodePoint <= _UTF.Max
		) then
			CodePoint = NewCodePoint;

			NS.EntityName:SetText( FindCodePointName( CodePoint ) or "" );
			NS.CodePoint:SetNumber( CodePoint );

			Glyph:SetText( _UTF.IntToUTF( CodePoint ) );
			Glyph.Text:SetAlpha( 1.0 );
			if ( NS.IsGlyphVisible() ) then
				Glyph:Enable();
				Glyph.Background:Show();
			else
				Glyph:Disable();
				Glyph.Background:Hide();
				Glyph:SetText( L.BROWSE_GLYPH_NOTAVAILABLE );
			end
			return true;
		end
	end
	--- Gets the current code point.
	function NS.GetCodePoint ()
		return CodePoint;
	end
end


--- Blocking scan to the next available character.
-- @param Direction  Step size for loop, ex. 1 for forward and -1 for reverse.
-- @param MaxJump  Optional limit to number of empty characters to skip.  If omitted, scan will end at _UTF.Min or _UTF.Max based on Direction.
-- @return True if a visible glyph was found.
function NS.Seek ( Direction, MaxJump )
	local Text = Glyph.Text;
	local SetText, GetStringWidth = Text.SetText, Text.GetStringWidth;

	local CodePoint = NS.GetCodePoint();
	if ( not MaxJump ) then
		MaxJump = math.huge;
	end
	local Limit = Direction > 0 and min( CodePoint + MaxJump, _UTF.Max ) or max( CodePoint - MaxJump, _UTF.Min );
	for CodePoint = CodePoint + Direction, Limit, Direction do
		SetText( Text, _UTF.IntToUTF( CodePoint ) );
		if ( GetStringWidth( Text ) > 0 ) then
			NS.SetCodePoint( CodePoint );
			return true;
		end
	end
	-- Reached end with no match
	NS.SetCodePoint( Limit );
end




--- Initiates a character scan in the given direction.
function NS:OnMouseWheel ( Delta )
	NS.Seek( Delta, 16384 ); -- 2^14
end
--- Plays a sound when closed.
function NS:OnHide ()
	PlaySound( "igCharacterInfoClose" );
end
--- Plays a sound when opened.
function NS:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
end




--- Toggles the _UTF browse window.
-- @param Show  Optional boolean to force the frame shown.
function NS.Toggle ( Show )
	if ( Show == nil ) then
		Show = not NS:IsShown();
	end
	NS:SetShown( Show );
end
--- Slash command that toggles the _UTF browse window.
function NS.ToggleSlashCommand ()
	NS.Toggle();
end




--- Readjusts the glyph text's size to nearly fill the glyph.
function Glyph:OnUpdate ()
	-- Must be called every frame or updates will cap its height at 50 pixels
	self.Text:SetTextHeight( self:GetHeight() - 30 );
end
--- Adds the current character to any edit box with focus.
function Glyph:OnClick ()
	local EditBox = GetCurrentKeyBoardFocus();
	if ( EditBox and EditBox ~= NS.EntityName and EditBox ~= NS.CodePoint ) then
		EditBox:Insert( self:GetText() );
	end
end


--- Validates the entity name typed into the name edit box.
function NS.EntityName:OnTextChanged ( IsUserInput )
	local Name = self:GetText();
	local CodePoint = _UTFOptions.CharacterEntities[ Name ] or _UTF.CharacterEntities[ Name ];

	local Color = CodePoint and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR;
	self:SetTextColor( Color.r, Color.g, Color.b );
	if ( IsUserInput and CodePoint ) then
		NS.SetCodePoint( CodePoint );
	end
end
--- Updates the glyph when the user types a new codepoint in.
function NS.CodePoint:OnTextChanged ( IsUserInput )
	if ( IsUserInput ) then
		local NewCodePoint = max( _UTF.Min, min( _UTF.Max, self:GetNumber() ) );
		if ( not NS.SetCodePoint( NewCodePoint ) ) then -- Already at this codepoint
			-- Set number anyway
			self:SetNumber( NewCodePoint );
		end
	end
end




NS:Hide();
NS:SetSize( 150, 192 );
NS:SetPoint( "CENTER" );
NS:SetFrameStrata( "DIALOG" );
NS:EnableMouse( true );
NS:SetToplevel( true );
NS:EnableMouseWheel( true );
NS:SetBackdrop( {
	bgFile = [[Interface\TutorialFrame\TutorialFrameBackground]];
	edgeFile = [[Interface\TutorialFrame\TutorialFrameBorder]];
	tile = true; tileSize = 32; edgeSize = 32;
	insets = { left = 7; right = 5; top = 3; bottom = 6; };
} );
tinsert( UISpecialFrames, NS:GetName() ); -- Allow escape to close

NS:SetScript( "OnMouseWheel", NS.OnMouseWheel );
NS:SetScript( "OnHide", NS.OnHide );
NS:SetScript( "OnShow", NS.OnShow );

-- Make dragable
NS:SetMovable( true );
NS:SetUserPlaced( true );
NS:SetClampedToScreen( true );
NS:CreateTitleRegion():SetAllPoints();
-- Close button
CreateFrame( "Button", nil, NS, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 4, 4 );
-- Title
local Title = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
Title:SetText( L.BROWSE_TITLE );
Title:SetPoint( "TOPLEFT", NS, 11, -6 );


-- Edit boxes
local CodePointLabel = NS:CreateFontString( nil, "ARTWORK", "GameFontDisableSmall" );
CodePointLabel:SetText( L.BROWSE_CODEPOINT );
CodePointLabel:SetHeight( 16 );
CodePointLabel:SetPoint( "BOTTOMLEFT", 8, 12 );

local EntityNameLabel = NS:CreateFontString( nil, "ARTWORK", "GameFontDisableSmall" );
EntityNameLabel:SetText( L.BROWSE_ENTITYNAME );
EntityNameLabel:SetHeight( 16 );
EntityNameLabel:SetPoint( "BOTTOMLEFT", CodePointLabel, "TOPLEFT", 0, 8 );

local CodePoint = NS.CodePoint;
CodePoint:SetPoint( "TOP", CodePointLabel );
CodePoint:SetPoint( "BOTTOMRIGHT", -8, 12 );
CodePoint:SetPoint( "LEFT",
	CodePointLabel:GetStringWidth() > EntityNameLabel:GetStringWidth() and CodePointLabel or EntityNameLabel,
	"RIGHT", 8, 0 );
CodePoint:SetAutoFocus( false );
CodePoint:SetMaxLetters( floor( log10( _UTF.Max ) ) + 1 );
CodePoint:SetNumeric( true );
CodePoint:SetScript( "OnEditFocusGained", nil );
CodePoint:SetScript( "OnTextChanged", CodePoint.OnTextChanged );

local EntityName = NS.EntityName;
EntityName:SetPoint( "TOP", EntityNameLabel );
EntityName:SetPoint( "BOTTOM", EntityNameLabel );
EntityName:SetPoint( "LEFT", CodePoint );
EntityName:SetPoint( "RIGHT", CodePoint );
EntityName:SetAutoFocus( false );
EntityName:SetScript( "OnEditFocusGained", nil );
EntityName:SetScript( "OnTextChanged", EntityName.OnTextChanged );


-- Create glyph button
Glyph:SetBackdrop( {
	bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]];
	tile = true; tileSize = 32;
} );
Glyph:SetScript( "OnUpdate", Glyph.OnUpdate );
Glyph:SetScript( "OnClick", Glyph.OnClick );

Glyph:SetPoint( "TOPLEFT", 10, -28 );
Glyph:SetPoint( "RIGHT", -10, 0 );
Glyph:SetPoint( "BOTTOM", EntityName, "TOP", 0, 6 );

-- Set up glyph fonts
Glyph.Font:SetFont( [[Fonts\ARIALN.TTF]], 50 );
Glyph.Font:SetTextColor( 1.0, 0.82, 0.0 );

Glyph.FontDisable:SetFontObject( Glyph.Font );
Glyph.FontDisable:SetTextColor( 0.5, 0.5, 0.5 );

Glyph.FontHighlight:SetFontObject( Glyph.Font );
Glyph.FontHighlight:SetTextColor( 1.0, 1.0, 1.0 );

Glyph:SetNormalFontObject( Glyph.Font );
Glyph:SetDisabledFontObject( Glyph.FontDisable );
Glyph:SetHighlightFontObject( Glyph.FontHighlight );

-- Initialize button text
Glyph.Text = Glyph:CreateFontString();
Glyph.Text:SetPoint( "CENTER" );
Glyph:SetFontString( Glyph.Text );

-- Add background to text
Glyph.Background = Glyph:CreateTexture( nil, "BACKGROUND" );
Glyph.Background:SetAllPoints( Glyph.Text );
Glyph.Background:SetTexture( 0.1, 0.1, 0.1 );


-- Initialize to minimum character
NS.SetCodePoint( _UTF.Min );

SlashCmdList[ "_UTFTOGGLE" ] = NS.ToggleSlashCommand;
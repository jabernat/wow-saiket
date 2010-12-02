--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.Editor.lua - Script text editor frame.                             *
  ****************************************************************************]]


local _DevPad = select( 2, ... );
local L = _DevPad.L;

local me = _DevPad.Dialog:New( "_DevPadEditor" );
_DevPad.Editor = me;

me.Run = CreateFrame( "Button", nil, me );
me.Lua = me:NewButton( [[Interface\MacroFrame\MacroFrame-Icon]] );
me.FontCycle = me:NewButton( [[Interface\ICONS\INV_Letter_18]] );
me.FontDecrease = me:NewButton( [[Interface\Icons\Spell_ChargeNegative]] );
me.FontIncrease = me:NewButton( [[Interface\Icons\Spell_ChargePositive]] );
me.Revert = CreateFrame( "Button", nil, me );

me.Focus = CreateFrame( "Frame", nil, me.Window );
me.Margin = CreateFrame( "Frame", nil, me.ScrollFrame );
me.Margin.Gutter = me.Focus:CreateTexture( nil, "BORDER" );
me.Margin.Lines = {};
me.Edit = CreateFrame( "EditBox", nil, me.Margin );

me.Shortcuts = CreateFrame( "Frame", nil, me.Edit );

me.DefaultWidth, me.DefaultHeight = 500, 500;

local TextInset = 8; -- If too small, mouse dragging the text selection won't scroll the view easily.
local TabWidth = 2;
local AutoIndent = true; -- True to enable auto-indentation for Lua scripts
if ( _DevPad.IndentationLib ) then
	local T = _DevPad.IndentationLib.Tokens;
	me.SyntaxColors = {};
	--- Assigns a color to multiple tokens at once.
	local function Color ( Code, ... )
		for Index = 1, select( "#", ... ) do
			me.SyntaxColors[ select( Index, ... ) ] = Code;
		end
	end
	Color( "|cff8dbbd7", T.KEYWORD ); -- Reserved words
	Color( "|cffc27272", T.CONCAT, T.VARARG,
		T.ASSIGNMENT, T.PERIOD, T.COMMA, T.SEMICOLON, T.COLON, T.SIZE );
	Color( "|cffffa600", T.NUMBER );
	Color( "|cff888888", T.STRING, T.STRING_LONG );
	Color( "|cff55cc55", T.COMMENT_SHORT, T.COMMENT_LONG );
	Color( "|cffccaa88", T.LEFTCURLY, T.RIGHTCURLY,
		T.LEFTBRACKET, T.RIGHTBRACKET,
		T.LEFTPAREN, T.RIGHTPAREN,
		T.ADD, T.SUBTRACT, T.MULTIPLY, T.DIVIDE, T.POWER, T.MODULUS );
	Color( "|cffccddee", T.EQUALITY, T.NOTEQUAL, T.LT, T.LTE, T.GT, T.GTE );
	Color( "|cff55ddcc", -- Minimal standard Lua functions
		"assert", "error", "ipairs", "next", "pairs", "pcall", "print", "select",
		"tonumber", "tostring", "type", "unpack",
		-- Libraries
		"bit", "coroutine", "math", "string", "table" );
	Color( "|cffddaaff", -- Some of WoW's aliases for standard Lua functions
		-- math
		"abs", "ceil", "floor", "max", "min",
		-- string
		"format", "gsub", "strbyte", "strchar", "strconcat", "strfind", "strjoin",
		"strlower", "strmatch", "strrep", "strrev", "strsplit", "strsub", "strtrim",
		"strupper", "tostringall",
		-- table
		"sort", "tinsert", "tremove", "wipe" );
end

local DejaVuSansMono = [[Interface\AddOns\]]..( ... )..[[\Skin\DejaVuSansMono.ttf]];
me.Font = CreateFont( "_DevPadEditorFont" );
me.Font.Paths = { -- Font file paths for font cycling button
	DejaVuSansMono,
	[[Fonts\FRIZQT__.TTF]],
	[[Fonts\ARIALN.TTF]]
};

-- Editor colors
--me.Font:SetTextColor( 1, 1, 1 ); -- Default text/line number color
--me.Background:SetTexture( 0.05, 0.05, 0.06 ); -- Text background
me.Margin.Gutter:SetTexture( 0.2, 0.2, 0.2 ); -- Line number background




--- @return True if script changed.
function me:SetScriptObject ( Script )
	if ( self.Script ~= Script ) then
		self.Script = Script;
		if ( Script ) then
			self:ObjectSetName( nil, Script );
			_DevPad.RegisterCallback( self, "ObjectSetName" );
			_DevPad.RegisterCallback( self, "ScriptSetLua" );
			if ( Script.Parent ) then
				_DevPad.RegisterCallback( self, "FolderRemove" );
			end
			self.ScrollFrame.Bar:SetValue( 0 );
			self.Edit:SetText( Script.Text:gsub( "|", "||" ) );
			self.Edit:SetCursorPosition( 0 );
			self:ScriptSetLua( nil, Script );
			self:Show();
		else
			_DevPad.UnregisterCallback( self, "ObjectSetName" );
			_DevPad.UnregisterCallback( self, "ScriptSetLua" );
			_DevPad.UnregisterCallback( self, "FolderRemove" );
			self:Hide();
			self.Edit:ClearFocus();
		end
		_DevPad.Callbacks:Fire( "EditorSetScriptObject", Script );
		return true;
	end
end
--- @return True if font changed.
function me:SetFont ( Path, Size )
	Path, Size = Path or DejaVuSansMono, Size or 10;
	if ( ( self.FontPath ~= Path or self.FontSize ~= Size )
		and self.Font:SetFont( Path, Size )
	) then
		self.FontPath, self.FontSize = Path, Size;
		self.Margin:Update();
		return true;
	end
end


--- Shows the selected script from the list frame.
function me:ListSetSelection ( _, Object )
	if ( Object and Object.Class == "Script" ) then
		return self:SetScriptObject( Object );
	end
end
--- Shows the selected script from the list frame.
function me:ObjectSetName ( _, Object )
	if ( Object == self.Script ) then
		self.Title:SetText( Object.Name );
	end
end
do
	--- Sets both button textures' vertex colors.
	local function SetVertexColors ( self, ... )
		self:GetNormalTexture():SetVertexColor( ... );
		self:GetPushedTexture():SetVertexColor( ... );
	end
	--- Enables or disables syntax highlighting in the edit box.
	function me:ScriptSetLua ( _, Script )
		if ( Script == self.Script and _DevPad.IndentationLib ) then
			if ( Script.Lua ) then
				_DevPad.IndentationLib.Enable( self.Edit,
					AutoIndent and TabWidth, me.SyntaxColors );
				SetVertexColors( self.Lua, 1, 1, 1 );
			else
				_DevPad.IndentationLib.Disable( self.Edit );
				SetVertexColors( self.Lua, 0.4, 0.4, 0.4 );
			end
		end
	end
end
--- Hides the editor if the edited script gets removed.
function me:FolderRemove ( _, _, Object )
	if ( Object == self.Script
		or ( Object.Class == "Folder" and Object:Contains( self.Script ) )
	) then
		self:SetScriptObject();
	end
end


--- Runs the open script.
function me.Run:OnClick ()
	return me.Script:Run();
end
--- Cycles to the next available font.
function me.FontCycle:OnClick ()
	local Paths, NewIndex = me.Font.Paths, 1;
	for Index = 1, #Paths - 1 do
		if ( me.FontPath == Paths[ Index ] ) then
			NewIndex = Index + 1;
			break;
		end
	end
	return me:SetFont( Paths[ NewIndex ], me.FontSize );
end
do
	local SizeDelta, SizeMin, SizeMax = 2, 6, 34;
	--- Decrements the current font size.
	function me.FontDecrease:OnClick ()
		return me:SetFont( me.FontPath, max( SizeMin, me.FontSize - SizeDelta ) );
	end
	--- Increments the current font size.
	function me.FontIncrease:OnClick ()
		return me:SetFont( me.FontPath, min( SizeMax, me.FontSize + SizeDelta ) );
	end
end
--- Toggles syntax highlighting for this script.
function me.Lua:OnClick ()
	return me.Script:SetLua( not me.Script.Lua );
end
--- Undoes changes since the player opened this script.
function me.Revert:OnClick ()
	return me.Edit:SetText( me.Script.TextOriginal:gsub( "|", "||" ) );
end


--- Updates the margin's line numbers.
function me.Margin:Update ()
	local Index, Count = 0, 0;
	local Text, Lines = self.Text, self.Lines;
	local Width = me.ScrollFrame:GetWidth()
		- ( self:GetWidth() + TextInset ); -- Size of margins
	local EndingLast;
	for Line, Ending in me.Edit:GetText( true ):gmatch( "([^\r\n]*)()" ) do
		if ( EndingLast ~= Ending ) then
			EndingLast = Ending;
			Index, Count = Index + 1, Count + 1;
			Lines[ Index ] = Count;

			-- Add blank space for wrapped lines
			Text:SetText( Line );
			for Extra = 1, Text:GetStringWidth() / Width do
				Index = Index + 1;
				Lines[ Index ] = "";
			end
		end
	end
	for Index = Index + 1, #Lines do
		Lines[ Index ] = nil;
	end

	Text:SetText( table.concat( Lines, "\n" ) );
	local Width, Height = Text:GetSize();
	self:SetSize( Width + TextInset, Height + TextInset * 2 );
end
--- Highlights the entire clicked line.
function me.Margin:OnMouseDown ()
	local Edit = me.Edit;
	if ( Edit.LineHeight ) then
		local _, CursorHeight = GetCursorPosition();
		local Offset = self:GetTop() - TextInset - CursorHeight / self:GetEffectiveScale();

		local Lines = self.Lines;
		local Index = max( 1, min( #Lines, ceil( Offset / Edit.LineHeight ) ) );
		-- Seek up to start of line
		while ( Lines[ Index ] == "" ) do
			Index = Index - 1;
		end
		local Line = Lines[ Index ] or 1;
		local Start = Edit:GetLinePosition( Line );
		local End = Edit:GetLinePosition( Line + 1 );
		if ( Start == End ) then -- Last line
			End = #Edit:GetText( true );
		end
		Edit:SetCursorPosition( End );
		Edit:HighlightText( Start, End );
		Edit:SetFocus();
	end
end
--- Focus the edit box text if empty space gets clicked.
function me.Focus:OnMouseDown ()
	me.Edit:SetCursorPosition( #me.Edit:GetText( true ) );
	me.Edit:SetFocus();
end
--- Focus the edit box text if empty space gets clicked.
function me.Edit:OnTabPressed ()
	self:Insert( ( " " ):rep( TabWidth ) );
end
do
	local LastX, LastY, LastWidth, LastHeight;
	--- Moves the edit box's view to follow the cursor.
	function me.Edit:OnCursorChanged ( CursorX, CursorY, CursorWidth, CursorHeight )
		self.LineHeight = CursorHeight;
		if ( self:HasFocus() and (
			LastX ~= CursorX or LastY ~= CursorY -- Only move view when cursor *moves*
			or LastWidth ~= CursorWidth or LastHeight ~= CursorHeight
		) ) then
			LastX, LastY = CursorX, CursorY;
			LastWidth, LastHeight = CursorWidth, CursorHeight;

			local ScrollFrame = me.ScrollFrame;
			if ( ScrollFrame:GetVerticalScrollRange() > 0 ) then
				CursorY = -CursorY;
				local CursorBottom = CursorY + CursorHeight + 2 * TextInset;

				local Height = ScrollFrame:GetHeight();
				local Top = ScrollFrame:GetVerticalScroll();
				local Bottom = Top + Height;

				if ( CursorY < Top ) then -- Too high
					ScrollFrame:SetVerticalScroll( CursorY );
				elseif ( CursorBottom > Bottom ) then -- Too low
					ScrollFrame:SetVerticalScroll( CursorBottom - Height );
				end
			end
		end
	end
end
--- @return Cursor position for the start of Line within the edit box.
function me.Edit:GetLinePosition ( Line )
	local Count, PositionLast = 1, 0;
	for Position in self:GetText( true ):gmatch( "()[\r\n]" ) do
		if ( Count >= Line ) then
			return PositionLast;
		end
		Count, PositionLast = Count + 1, Position;
	end
	return PositionLast;
end
--- Updates line numbers and saves text.
function me.Edit:OnTextChanged ()
	local Script = me.Script;
	if ( Script ) then
		if ( not Script.TextOriginal ) then
			Script.TextOriginal = Script.Text;
		end
		Script:SetText( self:GetText():gsub( "||", "|" ) );
		if ( Script.TextOriginal == Script.Text ) then
			me.Revert:Disable();
		else
			me.Revert:Enable();
		end
	end
	return me.Margin:Update();
end
--- Start listening for shortcut keys.
function me.Edit:OnEditFocusGained ()
	me.Shortcuts:EnableKeyboard( true );
end
--- Stop listening for shortcut keys.
function me.Edit:OnEditFocusLost ()
	me.Shortcuts:EnableKeyboard( false );
end
--- Stop listening for control commands.
function me.Shortcuts:OnKeyDown ( Key )
	if ( self[ Key ] ) then
		return self[ Key ]( self, Key );
	end
end
--- Cancels pending focus change.
function me.Shortcuts:OnHide ()
	self:SetScript( "OnUpdate", nil );
end
do
	local PendingEditBox;
	--- Sets keyboard focus on next frame.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		PendingEditBox:HighlightText();
		return PendingEditBox:SetFocus();
	end
	--- Changes the keyboard focus after a shortcut gets processed.
	-- This prevents the new edit box from receiving the original shortcut key.
	function me.Shortcuts:SetFocus ( EditBox )
		PendingEditBox = EditBox;
		self:SetScript( "OnUpdate", OnUpdate );
	end
end

--- Focus search edit box.
function me.Shortcuts:F ()
	if ( IsControlKeyDown() ) then
		self:SetFocus( _DevPad.List.FindEdit );
	end
end

--- Goes to the given line number.
function me:GoToOnAccept ()
	local Line = self.editBox:GetNumber();
	if ( Line == 0 ) then
		return true; -- Keep open
	end
	local Position = me.Edit:GetLinePosition( Line );
	me.Edit:HighlightText( Position, Position ); -- Clear
	me.Edit:SetCursorPosition( Position );
	me.Edit:SetFocus();
end
--- Undo changes to the edit box.
function me:GoToOnHide ()
	self.editBox:SetNumeric( false );
end
--- Accepts the typed line number.
function me:GoToOnEnterPressed ()
	return self:GetParent().button1:Click();
end
--- Go to line number.
function me.Shortcuts:G ()
	if ( IsControlKeyDown() ) then
		local PositionLast, LineMax, LineCurrent = 0, 0, 1;
		local Cursor = me.Edit:GetCursorPosition() + 1;
		for Start, End in me.Edit:GetText( true ):gmatch( "()[^\r\n]*()" ) do
			if ( PositionLast ~= Start ) then
				LineMax, PositionLast = LineMax + 1, End;
				if ( Cursor and Start <= Cursor and Cursor <= End ) then
					LineCurrent, Cursor = LineMax;
				end
			end
		end

		local Dialog = StaticPopup_Show( "_DEVPAD_GOTO", LineMax );
		if ( Dialog ) then
			Dialog.editBox:SetNumeric( true );
			Dialog.editBox:SetNumber( LineCurrent );
			self:SetFocus( Dialog.editBox );
		end
	end
end


function me:OnShow ()
	PlaySound( "igQuestListOpen" );
	UISpecialFrames[ "_DevPad" ] = self:GetName(); -- Cause escape to close the editor before the list frame
end
--- Close the open script.
function me:OnHide ()
	PlaySound( "igQuestListClose" );
	StaticPopup_Hide( "_DEVPAD_GOTO" );
	-- Note: Don't add/remove keys, since :Hide was likely called while looping over UISpecialFrames.
	UISpecialFrames[ "_DevPad" ] = _DevPad.List:GetName(); -- Allow escape to close the list frame next
	return self:SetScriptObject();
end


do
	local Pack = me.Pack;
	--- Saves font, position, and size information for saved variables.
	function me:Pack ( ... )
		local Options = Pack( self, ... );
		Options.FontPath, Options.FontSize = self.FontPath, self.FontSize;
		return Options;
	end
	local Unpack = me.Unpack;
	--- Loads font, position, and size from saved variables.
	function me:Unpack ( Options, ... )
		self:SetFont( Options.FontPath, Options.FontSize );
		return Unpack( self, Options, ... );
	end
end


StaticPopupDialogs[ "_DEVPAD_GOTO" ] = {
	text = L.GOTO_FORMAT;
	button1 = ACCEPT;
	button2 = CANCEL;
	OnAccept = me.GoToOnAccept;
	OnHide = me.GoToOnHide;
	EditBoxOnEnterPressed = me.GoToOnEnterPressed;
	EditBoxOnEscapePressed = StaticPopupDialogs[ "ADD_FRIEND" ].EditBoxOnEscapePressed;
	hasEditBox = true;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
};




_DevPad.Dialog.StickyFrames[ "Editor" ] = me;
me:SetScript( "OnShow", me.OnShow );
me:SetScript( "OnHide", me.OnHide );
me.Title:SetJustifyH( "LEFT" );
me:SetMinResize( 200, 100 );

-- Title buttons
local Run = me.Run;
Run:SetSize( 26, 26 );
Run:SetPoint( "TOPLEFT", 5, 1 );
Run:SetHitRectInsets( 4, 4, 4, 4 );
me.Title:SetPoint( "TOPLEFT", Run, "TOPRIGHT", 0, -7 );
Run:SetNormalTexture( [[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]] );
Run:SetPushedTexture( [[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]] );
Run:SetHighlightTexture( [[Interface\BUTTONS\UI-ScrollBar-Button-Overlay]] );
local Highlight = Run:GetHighlightTexture();
Highlight:SetVertexColor( 0, 0.8, 0 );
Highlight:SetTexCoord( 0.13, 0.87, 0.13, 0.82 );
Run:SetScript( "OnEnter", _DevPad.Dialog.ControlOnEnter );
Run:SetScript( "OnLeave", GameTooltip_Hide );
Run:SetScript( "OnClick", Run.OnClick );
Run.tooltipText = L.SCRIPT_RUN;

--- Flips a revert texture and sets its vertex color.
local function AdjustTexture ( self, ... )
	self:SetTexCoord( 1, 0, 0, 1 );
	self:SetVertexColor( ... );
end
local Revert = me.Revert;
Revert:SetSize( 34, 34 );
Revert:SetHitRectInsets( 8, 8, 8, 8 );
Revert:SetNormalTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Up]] );
AdjustTexture( Revert:GetNormalTexture(), 1, 1, 0 );
Revert:SetPushedTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Down]] );
AdjustTexture( Revert:GetPushedTexture(), 1, 1, 0 );
Revert:SetDisabledTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Up]] );
local Disabled = Revert:GetDisabledTexture();
Disabled:SetDesaturated( true );
AdjustTexture( Disabled, 0.6, 0.6, 0.6 );
Revert:SetHighlightTexture( [[Interface\BUTTONS\UI-ScrollBar-Button-Overlay]] );
Revert:GetHighlightTexture():SetVertexColor( 1, 0, 0 );
Revert:SetScript( "OnEnter", _DevPad.Dialog.ControlOnEnter );
Revert:SetScript( "OnLeave", GameTooltip_Hide );

local LastButton = me.Close;
--- @return A new title button.
local function SetupTitleButton ( Button, TooltipText, Offset )
	Button:SetPoint( "RIGHT", LastButton, "LEFT", -2 - ( Offset or 0 ), 0 );
	LastButton = Button;
	Button:SetScript( "OnClick", Button.OnClick );
	Button:SetMotionScriptsWhileDisabled( true );
	Button.tooltipText = TooltipText;
end
if ( _DevPad.IndentationLib ) then
	SetupTitleButton( me.Lua, L.LUA_TOGGLE );
else
	me.Lua:Hide();
end
SetupTitleButton( me.FontCycle, L.FONT_CYCLE, 8 );
SetupTitleButton( me.FontIncrease, L.FONT_DECREASE );
SetupTitleButton( me.FontDecrease, L.FONT_INCREASE );
SetupTitleButton( Revert, L.REVERT, 8 );
me.Title:SetPoint( "RIGHT", LastButton, "LEFT" );

local Focus = me.Focus;
Focus:SetAllPoints( me.ScrollFrame);
Focus:SetScript( "OnMouseDown", Focus.OnMouseDown );

local ScrollFrame, Margin = me.ScrollFrame, me.Margin;
ScrollFrame:SetScrollChild( Margin );
Margin:SetScript( "OnMouseDown", Margin.OnMouseDown );
local Text = Margin:CreateFontString();
Margin.Text = Text;
Text:SetFontObject( me.Font );
Text:SetPoint( "TOPLEFT", 0, -TextInset );
Text:SetJustifyV( "TOP" );
Text:SetJustifyH( "RIGHT" );
local Gutter = Margin.Gutter;
Gutter:SetPoint( "TOPLEFT" );
Gutter:SetPoint( "RIGHT", Text );
Gutter:SetPoint( "BOTTOM" );

local Edit = me.Edit;
Edit:SetPoint( "TOPLEFT", Margin, "TOPRIGHT" );
Edit:SetPoint( "RIGHT", ScrollFrame );
Edit:SetAutoFocus( false );
Edit:SetMultiLine( true );
Edit:SetFontObject( me.Font );
-- Note: Left inset simulated by margin.
Edit:SetTextInsets( 0, TextInset, TextInset, TextInset );
Edit:SetScript( "OnEscapePressed", Edit.ClearFocus );
Edit:SetScript( "OnTabPressed", Edit.OnTabPressed );
Edit:SetScript( "OnCursorChanged", Edit.OnCursorChanged );
Edit:SetScript( "OnTextChanged", Edit.OnTextChanged );
-- Enable extra keyboard shortcuts
Edit:SetScript( "OnEditFocusGained", Edit.OnEditFocusGained );
Edit:SetScript( "OnEditFocusLost", Edit.OnEditFocusLost );
me.Shortcuts:SetPropagateKeyboardInput( true );
me.Shortcuts:SetScript( "OnKeyDown", me.Shortcuts.OnKeyDown );
me.Shortcuts:SetScript( "OnHide", me.Shortcuts.OnHide );
me.Shortcuts:EnableKeyboard( false );

_DevPad.RegisterCallback( me, "ListSetSelection" );

me:Unpack( {} ); -- Default position/size and font
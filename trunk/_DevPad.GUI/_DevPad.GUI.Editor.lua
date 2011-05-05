--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.Editor.lua - Script text editor frame.                         *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );
local L = GUI.L;

local me = GUI.Dialog:New( "_DevPadGUIEditor" );
GUI.Editor = me;

me.Run = CreateFrame( "Button", nil, me );
me.Lua = me:NewButton( [[Interface\MacroFrame\MacroFrame-Icon]] );
me.FontCycle = me:NewButton( [[Interface\ICONS\INV_Misc_Note_04]] );
me.FontDecrease = me:NewButton( [[Interface\Icons\Spell_ChargeNegative]] );
me.FontIncrease = me:NewButton( [[Interface\Icons\Spell_ChargePositive]] );
me.Revert = CreateFrame( "Button", nil, me );

me.Focus = CreateFrame( "Frame", nil, me.Window );
me.Margin = CreateFrame( "Frame", nil, me.ScrollFrame );
me.Margin.Gutter = me.Focus:CreateTexture( nil, "BORDER" );
me.Margin.Lines = {};
local MarginUpdateFrequency = 0.2; -- Time to wait after last keypress before updating
me.Edit = CreateFrame( "EditBox", nil, me.Margin );

me.Shortcuts = CreateFrame( "Frame", nil, me.Edit );

me.DefaultWidth, me.DefaultHeight = 500, 500;

local TextInset = 8; -- If too small, mouse dragging the text selection won't scroll the view easily.
local TabWidth = 2;
local AutoIndent = true; -- True to enable auto-indentation for Lua scripts
if ( GUI.IndentationLib ) then
	local T = GUI.IndentationLib.Tokens;
	me.SyntaxColors = {};
	--- Assigns a color to multiple tokens at once.
	local function Color ( Code, ... )
		for Index = 1, select( "#", ... ) do
			me.SyntaxColors[ select( Index, ... ) ] = Code;
		end
	end
	Color( "|cff88bbdd", T.KEYWORD ); -- Reserved words
	Color( "|cffff6666", T.UNKNOWN );
	Color( "|cffcc7777", T.CONCAT, T.VARARG,
		T.ASSIGNMENT, T.PERIOD, T.COMMA, T.SEMICOLON, T.COLON, T.SIZE );
	Color( "|cffffaa00", T.NUMBER );
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
me.Font = CreateFont( "_DevPadGUIEditorFont" );
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
			if ( Script._Parent ) then
				_DevPad.RegisterCallback( self, "FolderRemove" );
			end
			self.ScrollFrame.Bar:SetValue( 0 );
			self.Edit:SetText( me.LuaEnabled and Script._Text:gsub( "|", "||" ) or Script._Text );
			self:ScriptSetLua( nil, Script );
			self.Edit:SetCursorPosition( 0 );
			self.Margin:Update();
			self:Show();
		else
			_DevPad.UnregisterCallback( self, "ObjectSetName" );
			_DevPad.UnregisterCallback( self, "ScriptSetLua" );
			_DevPad.UnregisterCallback( self, "FolderRemove" );
			self:Hide();
			self.Edit:ClearFocus();
		end
		GUI.Callbacks:Fire( "EditorSetScriptObject", Script );
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
do
	--- @return Number of Substring found between cursor positions Start and End.
	local function CountSubstring ( Text, Substring, Start, End )
		local Count = 0;
		Start, End = Start + 1, End - #Substring + 1;
		while ( true ) do
			Start = Text:find( Substring, Start, true );
			if ( not Start or Start > End ) then
				return Count;
			end
			Count, Start = Count + 1, Start + #Substring;
		end
	end
	--- Highlights a substring in the editor and moves the view to it.
	-- Positions should be relative to script text, not edit box contents, to
	-- account for pipe characters being escaped.
	function me:SetScriptHighlight ( Start, End )
		if ( Start ) then
			if ( self.LuaEnabled ) then
				local Text = self.Script._Text;
				local PipesBefore = CountSubstring( Text, "|", 0, Start );
				End = End + PipesBefore + CountSubstring( Text, "|", Start, End );
				Start = Start + PipesBefore;
			end
			self.Edit.CursorForceUpdate = true; -- Force into view, even if not focused
			self.Edit:SetCursorPosition( End );
		end
		self.Edit:HighlightText( Start or 0, End or 0 );
	end
	--- @return Cursor position, ignoring extra pipe escape characters.
	function me:GetScriptCursorPosition ()
		local Cursor = self.Edit:GetCursorPosition();
		return not self.LuaEnabled and Cursor
			or Cursor - CountSubstring( self.Edit:GetText(), "||", 0, Cursor );
	end


	--- Sets both button textures' vertex colors.
	local function SetVertexColors ( self, ... )
		self:GetNormalTexture():SetVertexColor( ... );
		self:GetPushedTexture():SetVertexColor( ... );
	end
	--- Enables or disables syntax highlighting in the edit box.
	function me:ScriptSetLua ( _, Script )
		if ( Script == self.Script ) then
			local Lib, Edit = GUI.IndentationLib, self.Edit;
			if ( Script._Lua ) then
				if ( not self.LuaEnabled ) then
					self.LuaEnabled = true;
					SetVertexColors( self.Lua, 0.4, 0.8, 1 );

					-- Escape control codes
					local Text, Cursor = Edit:GetText(), Edit:GetCursorPosition();
					Edit:SetText( Text:gsub( "|", "||" ) );
					Edit:SetCursorPosition( Cursor + CountSubstring( Text, "|", 0, Cursor ) );
				end
				if ( Lib ) then -- Force immediate recolor even if already enabled
					Lib.Enable( Edit, AutoIndent and TabWidth, me.SyntaxColors );
				end
			elseif ( self.LuaEnabled ) then
				self.LuaEnabled = nil;
				SetVertexColors( self.Lua, 0.4, 0.4, 0.4 );

				-- Disable syntax highlighting and unescape control codes
				if ( Lib ) then
					Lib.Disable( Edit );
				end
				local Text, Cursor = Edit:GetText(), Edit:GetCursorPosition();
				Edit:SetText( Text:gsub( "||", "|" ) );
				Edit:SetCursorPosition( Cursor - CountSubstring( Text, "||", 0, Cursor ) );
			end
		end
	end
end
--- Shows the selected script from the list frame.
function me:ListSetSelection ( _, Object )
	if ( Object and Object._Class == "Script" ) then
		return self:SetScriptObject( Object );
	end
end
--- Shows the selected script from the list frame.
function me:ObjectSetName ( _, Object )
	if ( Object == self.Script ) then
		self.Title:SetText( Object._Name );
	end
end
--- Hides the editor if the edited script gets removed.
function me:FolderRemove ( _, _, Object )
	if ( Object == self.Script
		or ( Object._Class == "Folder" and Object:Contains( self.Script ) )
	) then
		self:SetScriptObject();
	end
end


--- Runs the open script.
function me.Run:OnClick ()
	PlaySound( "igMiniMapZoomIn" );
	return _DevPad.SafeCall( me.Script );
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
	return me.Script:SetLua( not me.Script._Lua );
end
--- Undoes changes since the player opened this script.
function me.Revert:OnClick ()
	local Text = me.Script._TextOriginal;
	me.Edit:SetText( me.LuaEnabled and Text:gsub( "|", "||" ) or Text );
	me.Edit:SetCursorPosition( 0 );
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
	for Index = #Lines, Index + 1, -1 do
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
			End = #Edit:GetText();
		end
		Edit:SetCursorPosition( End );
		Edit:HighlightText( Start, End );
		Edit:SetFocus();
	end
end
--- Focus the edit box text if empty space gets clicked.
function me.Focus:OnMouseDown ()
	me.Edit:HighlightText( 0, 0 );
	me.Edit:SetCursorPosition( #me.Edit:GetText() );
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
		if ( self.CursorForceUpdate -- Force view to cursor, even if it didn't change
			or ( self:HasFocus() and ( -- Only move view when cursor *moves*
				LastX ~= CursorX or LastY ~= CursorY
				or LastWidth ~= CursorWidth or LastHeight ~= CursorHeight
		) ) ) then
			self.CursorForceUpdate = nil;
			LastX, LastY = CursorX, CursorY;
			LastWidth, LastHeight = CursorWidth, CursorHeight;

			local Top, Bottom = -CursorY, CursorHeight + 2 * TextInset - CursorY;
			me.ScrollFrame:SetVerticalScrollToCoord( Top, Bottom );
		end
	end
end
--- @return Cursor position for the start of Line within the edit box.
function me.Edit:GetLinePosition ( Line )
	local Count, PositionLast = 1, 0;
	for Position in self:GetText():gmatch( "()[\r\n]" ) do
		if ( Count >= Line ) then
			return PositionLast;
		end
		Count, PositionLast = Count + 1, Position;
	end
	return PositionLast;
end
do
	--- Updates the margin a moment after the user quits typing.
	local function OnFinished ( Updater )
		return me.Margin:Update();
	end
	local Updater = CreateFrame( "Frame", nil, me.Margin ):CreateAnimationGroup();
	Updater:CreateAnimation( "Animation" ):SetDuration( MarginUpdateFrequency );
	Updater:SetScript( "OnFinished", OnFinished );
	--- Updates line numbers and saves text.
	function me.Edit:OnTextChanged ()
		local Script = me.Script;
		if ( Script ) then
			if ( not Script._TextOriginal ) then
				Script._TextOriginal = Script._Text;
			end
			local Text = self:GetText();
			Script:SetText( me.LuaEnabled and Text:gsub( "||", "|" ) or Text );
			if ( Script._TextOriginal == Script._Text ) then
				me.Revert:Disable();
			else
				me.Revert:Enable();
			end
		end
		Updater:Stop();
		Updater:Play();
	end
end
--- Links/opens the clicked link.
function me.Edit:OnMouseUp ( MouseButton )
	if ( me.LuaEnabled ) then
		return;
	end
	local Text, Cursor = self:GetText(), self:GetCursorPosition();

	-- Find first unescaped link delimiter
	local LinkEnd, Start, Code = Cursor;
	while ( LinkEnd ) do
		Start, LinkEnd, Code = Text:find( "|+([Hh])", LinkEnd + 1 );
		if ( LinkEnd and ( LinkEnd - Start ) % 2 == 1 ) then -- Pipes not escaped
			break;
		end
	end
	if ( Code ~= "h" ) then
		return; -- Not inside a link
	end

	-- Find start of link
	local End, Start, LinkStart = 0;
	while ( End ) do
		Start, End = Text:find( "|+H", End + 1 );
		if ( End ) then
			if ( End > Cursor ) then
				break;
			elseif ( ( End - Start ) % 2 == 1 ) then -- Pipes not escaped
				LinkStart = Start;
			end
		end
	end

	if ( LinkStart and LinkEnd ) then
		local Link = Text:sub( LinkStart, LinkEnd );
		local ChatEdit = ChatEdit_GetActiveWindow();
		if ( ChatEdit and IsModifiedClick( "CHATLINK" ) ) then
			ChatEdit:SetFocus();
		end
		SetItemRef( Link:match( "^|H(.-)|h" ), Link, MouseButton );
	end
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
		self:SetFocus( GUI.List.SearchEdit );
	end
end
--- Jump to next/previous search result.
function me.Shortcuts:F3 ()
	if ( GUI.List.Search ) then
		local Cursor, Reverse = me:GetScriptCursorPosition(), IsShiftKeyDown();
		if ( Reverse and Cursor > 0 ) then
			Cursor = Cursor - 1;
		end
		me:SetScriptHighlight(
			GUI.List:NextMatchWrap( me.Script, Cursor, Reverse ) );
	end
end

--- Goes to the given line number.
function me:GoToOnAccept ()
	local Line = self.editBox:GetNumber();
	if ( Line == 0 ) then
		return true; -- Keep open
	end
	me.Edit:HighlightText( 0, 0 );
	me.Edit:SetCursorPosition( me.Edit:GetLinePosition( Line ) );
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
		for Start, End in me.Edit:GetText():gmatch( "()[^\r\n]*()" ) do
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


do
	local Backup = ChatEdit_InsertLink;
	--- Hook to add clicked links' code to the edit box.
	function me.ChatEditInsertLink ( Link, ... )
		if ( Link and me.Edit:HasFocus() ) then
			me.Edit:Insert( me.LuaEnabled and Link:gsub( "|", "||" ) or Link );
			return true;
		end
		return Backup( Link, ... );
	end
end
do
	local Backup = ChatEdit_OnEditFocusLost;
	--- Hook to keep the chat edit box open when focusing the editor.
	function me:ChatEditOnEditFocusLost ( ... )
		if ( IsMouseButtonDown() ) then
			local Focus = GetMouseFocus();
			if ( Focus == me.Edit or Focus == me.Margin or Focus == me.Focus ) then
				return; -- Probably clicked the editor to change focus
			end
		end
		return Backup( self, ... );
	end
end


function me:OnShow ()
	PlaySound( "igQuestListOpen" );
end
--- Close the open script.
function me:OnHide ()
	PlaySound( "igQuestListClose" );
	StaticPopup_Hide( "_DEVPAD_GOTO" );
	if ( not self:IsShown() ) then -- Explicitly hidden, not obscured by world map
		return self:SetScriptObject();
	end
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




GUI.Dialog.StickyFrames[ "Editor" ] = me;
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
Highlight:SetDesaturated( true );
Highlight:SetVertexColor( 0.2, 0.8, 0.4 );
Highlight:SetTexCoord( 0.13, 0.87, 0.13, 0.82 );
Run:SetScript( "OnEnter", GUI.Dialog.ControlOnEnter );
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
Revert:SetScript( "OnEnter", GUI.Dialog.ControlOnEnter );
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
SetupTitleButton( me.Lua, GUI.IndentationLib and L.LUA_TOGGLE or L.RAW_TOGGLE );
SetupTitleButton( me.FontCycle, L.FONT_CYCLE, 8 );
SetupTitleButton( me.FontIncrease, L.FONT_INCREASE );
SetupTitleButton( me.FontDecrease, L.FONT_DECREASE );
SetupTitleButton( Revert, L.REVERT, 8 );
me.Title:SetPoint( "RIGHT", LastButton, "LEFT" );

local Focus = me.Focus;
Focus:SetAllPoints( me.ScrollFrame);
Focus:SetScript( "OnMouseDown", Focus.OnMouseDown );

local ScrollFrame, Margin = me.ScrollFrame, me.Margin;
Margin:SetSize( 1, 1 );
Margin:SetHitRectInsets( 0, 0, 0, TextInset );
ScrollFrame:SetScrollChild( Margin );
Margin:SetScript( "OnMouseDown", Margin.OnMouseDown );
local Text = Margin:CreateFontString();
Margin.Text = Text;
Text:SetFontObject( me.Font );
Text:SetPoint( "TOPLEFT", 0, -TextInset );
Text:SetJustifyV( "TOP" );
Text:SetJustifyH( "RIGHT" );

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
Edit:SetScript( "OnMouseUp", Edit.OnMouseUp );
-- Enable extra keyboard shortcuts
Edit:SetScript( "OnEditFocusGained", Edit.OnEditFocusGained );
Edit:SetScript( "OnEditFocusLost", Edit.OnEditFocusLost );
me.Shortcuts:SetPropagateKeyboardInput( true );
me.Shortcuts:SetScript( "OnKeyDown", me.Shortcuts.OnKeyDown );
me.Shortcuts:SetScript( "OnHide", me.Shortcuts.OnHide );
me.Shortcuts:EnableKeyboard( false );
local Gutter = Margin.Gutter;
Gutter:SetPoint( "TOPLEFT" );
Gutter:SetPoint( "RIGHT", Edit, "LEFT", -4, 0 );
Gutter:SetPoint( "BOTTOM" );

-- Cursor line highlight
local Line, Cursor = Edit:CreateTexture(), select( 5, Edit:GetRegions() );
-- Note: Anchoring Line to the editor's sides causes it to flicker when quickly
-- updating the text.  Setting an absolute width avoids this.
Line:SetWidth( 1e6 ); -- Big enough to always span editor's width
Line:SetPoint( "TOP", Cursor );
Line:SetPoint( "BOTTOM", Cursor );
Line:SetTexture( 1, 1, 1, 0.05 );

ChatEdit_InsertLink = me.ChatEditInsertLink;
ChatEdit_OnEditFocusLost = me.ChatEditOnEditFocusLost;
GUI.RegisterCallback( me, "ListSetSelection" );

me:Unpack( {} ); -- Default position/size and font
--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.Editor.lua - Script text editor frame.                         *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );

local NS = GUI.Dialog:New( "_DevPadGUIEditor" );
GUI.Editor = NS;

NS.Run = CreateFrame( "Button", nil, NS );
NS.Lua = NS:NewButton( [[Interface\MacroFrame\MacroFrame-Icon]] );
NS.FontCycle = NS:NewButton( [[Interface\ICONS\INV_Misc_Note_04]] );
NS.FontDecrease = NS:NewButton( [[Interface\Icons\Spell_ChargeNegative]] );
NS.FontIncrease = NS:NewButton( [[Interface\Icons\Spell_ChargePositive]] );

NS.ScrollChild = CreateFrame( "Frame", nil, NS.ScrollFrame );
NS.Focus = CreateFrame( "Frame", nil, NS.Window );
NS.Edit = CreateFrame( "EditBox", nil, NS.ScrollChild );
NS.Edit.Line = NS.Edit:CreateTexture();

NS.Shortcuts = CreateFrame( "Frame", nil, NS.Edit );

NS.DefaultWidth, NS.DefaultHeight = 500, 500;

NS.TEXT_INSET = 8; -- If too small, mouse dragging the text selection won't scroll the view easily.
local TAB_WIDTH = 2;
local AUTO_INDENT = true; -- True to enable auto-indentation for Lua scripts
if ( GUI.IndentationLib ) then
	local T = GUI.IndentationLib.Tokens;
	NS.SyntaxColors = {};
	--- Assigns a color to multiple tokens at once.
	local function Color ( Code, ... )
		for Index = 1, select( "#", ... ) do
			NS.SyntaxColors[ select( Index, ... ) ] = Code;
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

local DEJAVU_SANS_MONO = [[Interface\AddOns\]]..( ... )..[[\Skin\DejaVuSansMono.ttf]];
NS.Font = CreateFont( "_DevPadGUIEditorFont" );
NS.Font.Paths = { -- Font file paths for font cycling button
	DEJAVU_SANS_MONO,
	[[Fonts\FRIZQT__.TTF]],
	[[Fonts\ARIALN.TTF]]
};

-- Editor colors
--NS.Edit:SetTextColor( 1, 1, 1 ); -- Default text color
--NS.Background:SetTexture( 0.05, 0.05, 0.06 ); -- Text background




--- @return True if script changed.
function NS:SetScriptObject ( Script )
	if ( self.Script ~= Script ) then
		if ( self.Script ) then
			self.Script._EditCursor = self.Edit:GetCursorPositionUnescaped();
		end
		self.Script = Script;
		if ( Script ) then
			_DevPad.RegisterCallback( self, "ObjectSetName" );
			_DevPad.RegisterCallback( self, "ScriptSetText" );
			_DevPad.RegisterCallback( self, "ScriptSetLua" );
			if ( Script._Parent ) then
				_DevPad.RegisterCallback( self, "FolderRemove" );
			end
			self.ScrollFrame.Bar:SetValue( 0 );
			self:ObjectSetName( nil, Script );
			self:ScriptSetText( nil, Script );
			self:ScriptSetLua( nil, Script );
			self.Edit:ScrollToNextCursorPosition();
			self.Edit:SetCursorPositionUnescaped(
				self.Edit:ValidateCursorPosition( Script._EditCursor or 0 ) );
			self:Show();
		else
			_DevPad.UnregisterCallback( self, "ObjectSetName" );
			_DevPad.UnregisterCallback( self, "ScriptSetText" );
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
function NS:SetFont ( Path, Size )
	Path, Size = Path or DEJAVU_SANS_MONO, Size or 10;
	if ( ( self.FontPath ~= Path or self.FontSize ~= Size )
		and self.Font:SetFont( Path, Size )
	) then
		self.FontPath, self.FontSize = Path, Size;
		GUI.Callbacks:Fire( "EditorSetFont", Path, Size );
		return true;
	end
end


do
	--- @return Number of Substring found between cursor positions Start and End.
	local function CountSubstring ( Text, Substring, Start, End )
		if ( Start >= End ) then
			return 0;
		end
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
	--- Highlights a substring in the editor, accounting for escaped pipes.
	function NS.Edit:HighlightTextUnescaped ( Start, End )
		if ( self.Lua ) then
			local PipesBeforeStart;
			if ( Start or End ) then
				PipesBeforeStart = CountSubstring( NS.Script._Text, "|", 0, Start or 0 );
			end
			if ( End ) then
				End = End + PipesBeforeStart + CountSubstring( NS.Script._Text, "|", Start or 0, End );
			end
			if ( Start ) then
				Start = Start + PipesBeforeStart;
			end
		end
		return self:HighlightText( Start, End );
	end
	--- Forces the cursor into view the next time it moves, even if this editbox isn't focused.
	function NS.Edit:ScrollToNextCursorPosition ()
		self.CursorForceUpdate = true;
	end
	--- Moves the cursor to a position in the current script, accounting for escaped pipes.
	function NS.Edit:SetCursorPositionUnescaped ( Cursor )
		if ( self.Lua ) then
			Cursor = Cursor + CountSubstring( NS.Script._Text, "|", 0, Cursor );
		end
		return self:SetCursorPosition( Cursor );
	end
	--- @return Cursor position, ignoring extra pipe escape characters.
	function NS.Edit:GetCursorPositionUnescaped ()
		local Cursor = self:GetCursorPosition();
		if ( self.Lua ) then
			Cursor = Cursor - CountSubstring( self:GetText(), "||", 0, Cursor );
		end
		return Cursor;
	end
end
do
	local BYTE_PIPE = ( "|" ):byte();
	--- @return True if the pipe at Position isn't escaped.
	local function IsPipeActive ( Text, Position )
		local Pipes = 0;
		for Index = Position, 1, -1 do
			if ( Text:byte( Index ) ~= BYTE_PIPE ) then
				break;
			end
			Pipes = Pipes + 1;
		end
		return Pipes % 2 == 1;
	end
	local COLOR_LENGTH = 10;
	--- Moves the cursor if it's currently in an invalid position.
	-- The cursor cannot be placed just after color codes or just before color
	--   terminators.  On live realms, the cursor interacts with codes in these
	--   positions like visible characters, which is confusing.  On builds with
	--   debug assertions enabled, doing this crashes the game instead.
	function NS.Edit:ValidateCursorPosition ( Cursor )
		if ( self.Lua ) then -- Pipes are escaped
			return Cursor;
		end
		local Text = NS.Script._Text;
		if ( Cursor > 0 and IsPipeActive( Text, Cursor ) ) then
			Cursor = Cursor - 1; -- Can't be just after an active pipe
		end
		local _, End = Text:find( "^|[Rr]", Cursor + 1 );
		if ( End ) then -- Cursor is just before a color terminator
			Cursor = End;
		elseif ( Cursor > 0 ) then
			local Start = Text:find( "|[Cc]%x%x%x%x%x%x%x%x", max( 1, Cursor - COLOR_LENGTH + 1 ) );
			if ( Start and Start <= Cursor ) then -- Cursor is in or just after a color code
				Cursor = Start - 1;
			end
		end
		return Cursor;
	end
end


do
	--- Sets both button textures' vertex colors.
	local function SetVertexColors ( self, ... )
		self:GetNormalTexture():SetVertexColor( ... );
		self:GetPushedTexture():SetVertexColor( ... );
	end
	--- Enables or disables syntax highlighting in the edit box.
	function NS:ScriptSetLua ( _, Script )
		if ( Script == self.Script ) then
			local Edit = self.Edit;
			if ( Script._Lua ) then
				if ( not Edit.Lua ) then -- Escape control codes
					SetVertexColors( self.Lua, 0.4, 0.8, 1 );
					local Cursor = Edit:GetCursorPositionUnescaped();
					Edit.Lua = true;
					Edit:SetText( self.Script._Text:gsub( "|", "||" ) );
					Edit:SetCursorPositionUnescaped( Cursor );
					if ( GUI.IndentationLib ) then
						GUI.IndentationLib.Enable( Edit, -- Suppress immediate auto-indent
							AUTO_INDENT and TAB_WIDTH, self.SyntaxColors, true );
					end
				end
			elseif ( Edit.Lua ) then -- Disable syntax highlighting and unescape control codes
				SetVertexColors( self.Lua, 0.4, 0.4, 0.4 );
				if ( GUI.IndentationLib ) then
					GUI.IndentationLib.Disable( Edit );
				end
				local Cursor = Edit:GetCursorPositionUnescaped();
				Edit.Lua = false;
				Edit:SetText( self.Script._Text );
				Edit:SetCursorPositionUnescaped( Edit:ValidateCursorPosition( Cursor ) );
			end
		end
	end
end
--- Shows the selected script from the list frame.
function NS:ListSetSelection ( _, Object )
	if ( Object and Object._Class == "Script" ) then
		return self:SetScriptObject( Object );
	end
end
--- Updates the script's name on the window title.
function NS:ObjectSetName ( _, Object )
	if ( Object == self.Script ) then
		self.Title:SetText( Object._Name );
	end
end
--- Synchronizes editor text with the script object if it gets set externally while editing.
function NS:ScriptSetText ( _, Script )
	if ( Script == self.Script ) then
		local Text = self.Edit.Lua and Script._Text:gsub( "|", "||" ) or Script._Text;
		-- Don't clear syntax highlighting unnecessarily
		if ( self.Edit:GetText() ~= Text ) then
			self.Edit:SetText( Text );
			if ( self.Edit.Lua and GUI.IndentationLib ) then -- Immediately recolor
				GUI.IndentationLib.Update( self.Edit, false ); -- Suppress auto-indent
			end
		end
	end
end
--- Hides the editor if the edited script gets removed.
function NS:FolderRemove ( _, _, Object )
	if ( Object == self.Script
		or ( Object._Class == "Folder" and Object:Contains( self.Script ) )
	) then
		self:SetScriptObject();
	end
end


--- Runs the open script.
function NS.Run:OnClick ()
	PlaySound( "igMiniMapZoomIn" );
	return _DevPad.SafeCall( NS.Script );
end
--- Cycles to the next available font.
function NS.FontCycle:OnClick ()
	local Paths, NewIndex = NS.Font.Paths, 1;
	for Index = 1, #Paths - 1 do
		if ( NS.FontPath == Paths[ Index ] ) then
			NewIndex = Index + 1;
			break;
		end
	end
	return NS:SetFont( Paths[ NewIndex ], NS.FontSize );
end
do
	local SizeDelta, SizeMin, SizeMax = 2, 6, 34;
	--- Decrements the current font size.
	function NS.FontDecrease:OnClick ()
		return NS:SetFont( NS.FontPath, max( SizeMin, NS.FontSize - SizeDelta ) );
	end
	--- Increments the current font size.
	function NS.FontIncrease:OnClick ()
		return NS:SetFont( NS.FontPath, min( SizeMax, NS.FontSize + SizeDelta ) );
	end
end
--- Toggles Lua mode for this script.
function NS.Lua:OnClick ()
	return NS.Script:SetLua( not NS.Script._Lua );
end


--- Focus the edit box text if empty space gets clicked.
function NS.Focus:OnMouseDown ()
	NS.Edit:HighlightText( 0, 0 );
	NS.Edit:ScrollToNextCursorPosition();
	NS.Edit:SetCursorPositionUnescaped( NS.Edit:ValidateCursorPosition( #NS.Script._Text ) );
	NS.Edit:SetFocus();
end
--- Simulate a tab character with spaces.
function NS.Edit:OnTabPressed ()
	self:Insert( ( " " ):rep( TAB_WIDTH ) );
end
do
	local LastX, LastY, LastWidth, LastHeight;
	--- Moves the edit box's view to follow the cursor.
	function NS.Edit:OnCursorChanged ( CursorX, CursorY, CursorWidth, CursorHeight )
		self.LineHeight = CursorHeight;
		-- Update line highlight
		self.Line:SetHeight( CursorHeight );
		self.Line:SetPoint( "TOP", 0, CursorY - NS.TEXT_INSET );

		if ( self.CursorForceUpdate -- Force view to cursor, even if it didn't change
			or ( self:HasFocus() and ( -- Only move view when cursor *moves*
				LastX ~= CursorX or LastY ~= CursorY
				or LastWidth ~= CursorWidth or LastHeight ~= CursorHeight
		) ) ) then
			self.CursorForceUpdate = nil;
			LastX, LastY = CursorX, CursorY;
			LastWidth, LastHeight = CursorWidth, CursorHeight;

			local Top, Bottom = -CursorY, CursorHeight + 2 * NS.TEXT_INSET - CursorY;
			NS.ScrollFrame:SetVerticalScrollToCoord( Top, Bottom );
		end
	end
end
--- Saves text immediately after it changes.
function NS.Edit:OnTextChanged ()
	if ( NS.Script ) then
		local Text = self:GetText();
		NS.Script:SetText( self.Lua and Text:gsub( "||", "|" ) or Text );
	end
end
--- Links/opens the clicked link.
function NS.Edit:OnMouseUp ( MouseButton )
	if ( self.Lua ) then
		return;
	end
	local Text, Cursor = NS.Script._Text, self:GetCursorPositionUnescaped();

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
function NS.Edit:OnEditFocusGained ()
	NS.Shortcuts:EnableKeyboard( true );
end
--- Stop listening for shortcut keys.
function NS.Edit:OnEditFocusLost ()
	NS.Shortcuts:EnableKeyboard( false );
end
--- Stop listening for control commands.
function NS.Shortcuts:OnKeyDown ( Key )
	if ( self[ Key ] ) then
		return self[ Key ]( self, Key );
	end
end
--- Cancels pending focus change.
function NS.Shortcuts:OnHide ()
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
	function NS.Shortcuts:SetFocus ( EditBox )
		PendingEditBox = EditBox;
		self:SetScript( "OnUpdate", OnUpdate );
	end
end


do
	local Backup = ChatEdit_InsertLink;
	--- Hook to add clicked links' code to the edit box.
	function NS.ChatEditInsertLink ( Link, ... )
		if ( Link and NS.Edit:HasFocus() ) then
			NS.Edit:Insert( NS.Edit.Lua and Link:gsub( "|", "||" ) or Link );
			return true;
		end
		return Backup( Link, ... );
	end
end
do
	local Backup = ChatEdit_OnEditFocusLost;
	--- Hook to keep the chat edit box open when focusing the editor.
	function NS:ChatEditOnEditFocusLost ( ... )
		if ( IsMouseButtonDown() ) then
			local Focus = GetMouseFocus();
			if ( Focus and ( Focus == NS.Edit or Focus == NS.Focus or Focus == NS.Margin ) ) then
				return; -- Probably clicked the editor to change focus
			end
		end
		return Backup( self, ... );
	end
end


function NS:OnShow ()
	PlaySound( "igQuestListOpen" );
end
--- Close the open script.
function NS:OnHide ()
	PlaySound( "igQuestListClose" );
	StaticPopup_Hide( "_DEVPAD_GOTO" );
	if ( not self:IsShown() ) then -- Explicitly hidden, not obscured by world map
		return self:SetScriptObject();
	end
end


do
	local Pack = NS.Pack;
	--- Saves font, position, and size information for saved variables.
	function NS:Pack ( ... )
		local Options = Pack( self, ... );
		Options.FontPath, Options.FontSize = self.FontPath, self.FontSize;
		if ( self.Color ) then
			Options.Color = self.Color:Pack();
		end
		return Options;
	end
	local Unpack = NS.Unpack;
	--- Loads font, position, and size from saved variables.
	function NS:Unpack ( Options, ... )
		self:SetFont( Options.FontPath, Options.FontSize );
		if ( self.Color ) then
			self.Color:Unpack( Options.Color or {} );
		end
		return Unpack( self, Options, ... );
	end
end




GUI.Dialog.StickyFrames[ "Editor" ] = NS;
NS:SetScript( "OnShow", NS.OnShow );
NS:SetScript( "OnHide", NS.OnHide );
NS.Title:SetJustifyH( "LEFT" );
NS:SetMinResize( 100, 100 );

-- Title buttons
local Run = NS.Run;
Run:SetSize( 26, 26 );
Run:SetPoint( "TOPLEFT", 5, 1 );
Run:SetHitRectInsets( 4, 4, 4, 4 );
NS.Title:SetPoint( "TOPLEFT", Run, "TOPRIGHT", 0, -7 );
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
Run.tooltipText = GUI.L.SCRIPT_RUN;

--- @return A new title button.
local function SetupTitleButton ( Button, TooltipText, Offset )
	NS:AddTitleButton( Button, ( Offset or 0 ) - 2 );
	Button:SetScript( "OnClick", Button.OnClick );
	Button:SetMotionScriptsWhileDisabled( true );
	Button.tooltipText = TooltipText;
end
SetupTitleButton( NS.Lua, GUI.L.LUA_TOGGLE );
SetupTitleButton( NS.FontCycle, GUI.L.FONT_CYCLE, -8 );
SetupTitleButton( NS.FontIncrease, GUI.L.FONT_INCREASE );
SetupTitleButton( NS.FontDecrease, GUI.L.FONT_DECREASE );

local Focus = NS.Focus;
Focus:SetAllPoints( NS.ScrollFrame);
Focus:SetScript( "OnMouseDown", Focus.OnMouseDown );

NS.ScrollChild:SetSize( 1, 1 );
NS.ScrollFrame:SetScrollChild( NS.ScrollChild );
local Edit = NS.Edit;
Edit:SetPoint( "TOPLEFT", NS.TEXT_INSET, 0 );
Edit:SetPoint( "RIGHT", NS.ScrollFrame );
Edit:SetAutoFocus( false );
Edit:SetMultiLine( true );
Edit:SetFontObject( NS.Font );
Edit:SetTextInsets( 0, NS.TEXT_INSET, NS.TEXT_INSET, NS.TEXT_INSET );
Edit:SetScript( "OnEscapePressed", Edit.ClearFocus );
Edit:SetScript( "OnTabPressed", Edit.OnTabPressed );
Edit:SetScript( "OnCursorChanged", Edit.OnCursorChanged );
Edit:SetScript( "OnTextChanged", Edit.OnTextChanged );
Edit:SetScript( "OnMouseUp", Edit.OnMouseUp );
-- Enable extra keyboard shortcuts
Edit:SetScript( "OnEditFocusGained", Edit.OnEditFocusGained );
Edit:SetScript( "OnEditFocusLost", Edit.OnEditFocusLost );
NS.Shortcuts:SetPropagateKeyboardInput( true );
NS.Shortcuts:SetScript( "OnKeyDown", NS.Shortcuts.OnKeyDown );
NS.Shortcuts:SetScript( "OnHide", NS.Shortcuts.OnHide );
NS.Shortcuts:EnableKeyboard( false );

-- Cursor line highlight
Edit.Line:SetPoint( "LEFT", Margin );
Edit.Line:SetPoint( "RIGHT" );
Edit.Line:SetTexture( 1, 1, 1, 0.05 );

ChatEdit_InsertLink = NS.ChatEditInsertLink;
ChatEdit_OnEditFocusLost = NS.ChatEditOnEditFocusLost;
GUI.RegisterCallback( NS, "ListSetSelection" );

NS:Unpack( {} ); -- Default position/size and font
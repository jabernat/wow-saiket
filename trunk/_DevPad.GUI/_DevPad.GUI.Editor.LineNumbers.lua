--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.Editor.LineNumbers.lua - Adds line numbering to the editor.    *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );
local Editor = GUI.Editor;

local NS = CreateFrame( "Frame", nil, Editor.ScrollChild );
Editor.LineNumbers = NS;

NS.Gutter = Editor.Focus:CreateTexture( nil, "BORDER" ); -- Behind line highlight
NS.Text = NS:CreateFontString();
NS.Lines = {};
local UPDATE_INTERVAL = 0.2; -- Time to wait after last keypress before updating

-- Editor colors
NS.Text:SetTextColor( 1, 1, 1 ); -- Line number color
NS.Gutter:SetTexture( 0.2, 0.2, 0.2 ); -- Line number background




--- @return Cursor position for the start of Line within the editor.
function NS:GetLinePosition ( Line )
	local LineCurrent, PositionLast = 1, 0;
	for Position in Editor.Script._Text:gmatch( "()[\r\n]" ) do
		if ( LineCurrent >= Line ) then
			break;
		end
		LineCurrent, PositionLast = LineCurrent + 1, Position;
	end
	return PositionLast;
end


--- Immediately update numbering when switching scripts.
function NS:EditorSetScriptObject ( Script )
	if ( Script ) then
		self:Update();
		_DevPad.RegisterCallback( self, "ScriptSetLua" );
		GUI.RegisterCallback( self, "EditorSetFont" );
	else
		_DevPad.UnregisterCallback( self, "ScriptSetLua" );
		GUI.UnregisterCallback( self, "EditorSetFont" );
	end
end
function NS:ScriptSetLua ( _, Script )
	if ( Script == Editor.Script ) then
		self:Update();
	end
end
function NS:EditorSetFont ()
	self:Update();
end
do
	--- Updates numbering a moment after the user quits typing.
	local function OnFinished ( Updater )
		return NS:Update();
	end
	local Updater = CreateFrame( "Frame", nil, NS ):CreateAnimationGroup();
	Updater:CreateAnimation( "Animation" ):SetDuration( UPDATE_INTERVAL );
	Updater:SetScript( "OnFinished", OnFinished );
	--- Restarts an update timer when text changes.
	function NS:OnTextChanged ()
		if ( Editor.Script ) then
			Updater:Stop();
			Updater:Play();
		end
	end
end


--- Updates the margin's line numbers.
function NS:Update ()
	if ( not Editor.Script ) then
		return;
	end
	local Index, Count = 0, 0;
	local Text, Lines = self.Text, self.Lines;
	local Width = Editor.ScrollFrame:GetWidth() - ( self:GetWidth() + Editor.TEXT_INSET ); -- Editor width
	local EndingLast;
	for Line, Ending in Editor.Edit:GetText():gmatch( "([^\r\n]*)()" ) do
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
	self:SetSize( Width + Editor.TEXT_INSET, Height + Editor.TEXT_INSET * 2 );
end
--- Highlights the entire clicked line.
function NS:OnMouseDown ()
	if ( not Editor.Edit.LineHeight ) then
		return;
	end
	local _, CursorHeight = GetCursorPosition();
	local Offset = self:GetTop() - Editor.TEXT_INSET - CursorHeight / self:GetEffectiveScale();

	local Lines = self.Lines;
	local Index = max( 1, min( #Lines, ceil( Offset / Editor.Edit.LineHeight ) ) );
	-- Seek up to start of line
	while ( Lines[ Index ] == "" ) do
		Index = Index - 1;
	end
	local Line = Lines[ Index ] or 1;
	local Start, End = NS:GetLinePosition( Line ), NS:GetLinePosition( Line + 1 );
	if ( Start == End ) then -- Last line
		End = #Editor.Script._Text;
	end
	Start, End = Editor.Edit:ValidateCursorPosition( Start ), Editor.Edit:ValidateCursorPosition( End );
	Editor.Edit:ScrollToNextCursorPosition();
	Editor.Edit:SetCursorPositionUnescaped( End );
	Editor.Edit:HighlightTextUnescaped( Start, End );
	Editor.Edit:SetFocus();
end


--- Goes to the given line number.
function NS:GoToOnAccept ()
	local Line = self.editBox:GetNumber();
	if ( Line == 0 ) then
		return true; -- Keep open
	end
	Editor.Edit:HighlightText( 0, 0 );
	Editor.Edit:ScrollToNextCursorPosition();
	Editor.Edit:SetCursorPositionUnescaped(
		Editor.Edit:ValidateCursorPosition( NS:GetLinePosition( Line ) ) );
	Editor.Edit:SetFocus();
end
--- Undo changes to the edit box.
function NS:GoToOnHide ()
	self.editBox:SetNumeric( false );
end
--- Accepts the typed line number.
function NS:GoToOnEnterPressed ()
	return self:GetParent().button1:Click();
end
--- Go to line number.
function Editor.Shortcuts:G ()
	if ( IsControlKeyDown() ) then
		-- Use current line number as default
		local PositionLast, LineMax, LineCurrent = 0, 0, 1;
		local Cursor = Editor.Edit:GetCursorPositionUnescaped() + 1;
		for Start, End in Editor.Script._Text:gmatch( "()[^\r\n]*()" ) do
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


StaticPopupDialogs[ "_DEVPAD_GOTO" ] = {
	text = GUI.L.GOTO_FORMAT;
	button1 = ACCEPT; button2 = CANCEL;
	OnAccept = NS.GoToOnAccept; OnHide = NS.GoToOnHide;
	EditBoxOnEnterPressed = NS.GoToOnEnterPressed;
	EditBoxOnEscapePressed = StaticPopupDialogs[ "ADD_FRIEND" ].EditBoxOnEscapePressed;
	hasEditBox = true; timeout = 0; hideOnEscape = true; whileDead = true;
};




NS:SetSize( 1, 1 );
NS:SetPoint( "TOPLEFT" );
NS:SetHitRectInsets( 0, 0, 0, Editor.TEXT_INSET );
NS:SetScript( "OnMouseDown", NS.OnMouseDown );
NS.Text:SetFontObject( Editor.Font );
NS.Text:SetPoint( "TOPLEFT", 0, -Editor.TEXT_INSET );
NS.Text:SetJustifyV( "TOP" );
NS.Text:SetJustifyH( "RIGHT" );

Editor.Edit:SetPoint( "TOPLEFT", NS, "TOPRIGHT" );
Editor.Edit:HookScript( "OnTextChanged", NS.OnTextChanged );
NS.Gutter:SetPoint( "TOPLEFT" );
NS.Gutter:SetPoint( "RIGHT", Editor.Edit, "LEFT", -4, 0 );
NS.Gutter:SetPoint( "BOTTOM" );

GUI.RegisterCallback( NS, "EditorSetScriptObject" );
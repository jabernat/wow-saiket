--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.Editor.History.lua - Adds undo/redo commands to the editor.    *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );

local NS = {};
GUI.Editor.History = NS;

NS.UndoButton = CreateFrame( "Button", nil, GUI.Editor );
NS.RedoButton = CreateFrame( "Button", nil, GUI.Editor );
NS.CompareTimer = CreateFrame( "Frame", nil, GUI.Editor ):CreateAnimationGroup();

local COMPARE_INTERVAL = 0.5; -- Time to wait after last keypress before recomparing
NS.MaxEntries = 128; -- Use math.huge for unlimited history, or delete this file to disable history
local KEYS_PER_ENTRY = 3; -- Number of _History array indices required to store one entry




--- Compares script text when it changes.
function NS:ScriptSetText ( _, Script )
	if ( Script == self.Script ) then -- Delay comparisons for scripts being edited
		self.CompareTimer:Stop();
		self.CompareTimer:Play();
	else
		return self:Compare( Script );
	end
end
--- Begins throttling comparisons on scripts being edited.
function NS:EditorSetScriptObject ( _, Script )
	if ( self.Script ) then
		self:Compare( self.Script ); -- Compare pending edits immediately
	end
	self.Script = Script;
	if ( Script ) then -- Synchronize history to initial state of script
		self:Compare( Script );
	end
	self:UpdateButtons( Script );
end


--- Enables and disables the undo/redo buttons when appropriate.
function NS:UpdateButtons ( Script )
	if ( Script ~= self.Script ) then -- Not shown in the editor
		return;
	end
	if ( Script and Script._HistoryIndex > 0 ) then
		self.UndoButton:Enable();
	else
		self.UndoButton:Disable();
	end
	if ( Script and Script._HistoryIndex < #Script._History ) then
		self.RedoButton:Enable();
	else
		self.RedoButton:Disable();
	end
end
--- Undoes an edit when clicked.
function NS.UndoButton:OnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	return NS:Undo( NS.Script );
end
--- Redoes an edit when clicked.
function NS.RedoButton:OnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	return NS:Redo( NS.Script );
end
--- Undoes/redoes a change to the script with <ctrl+z> and <ctrl+shift+Z>.
function GUI.Editor.Shortcuts:Z ()
	if ( NS.Script and IsControlKeyDown() ) then
		return NS[ IsShiftKeyDown() and "Redo" or "Undo" ]( NS, NS.Script );
	end
end


--- Recompares text a moment after the user quits typing.
function NS.CompareTimer:OnFinished ()
	return NS:Compare( NS.Script );
end
do
	local strsub, floor, ceil = string.sub, math.floor, math.ceil;
	--- @return Number of leading bytes shared by both String1 and String2.
	-- Uses a binary search instead of a linear one for considerable performance
	-- gains due to how string equality comparisons are done in Lua.
	-- See <http://neil.fraser.name/news/2007/10/09/> for benchmarking.
	local function GetCommonPrefixLength ( String1, String2 )
		local Min, Max = 1, #String1 < #String2 and #String1 or #String2;
		repeat
			local Middle = floor( Min + ( Max - Min ) / 2 );
			if ( strsub( String1, Min, Middle ) == strsub( String2, Min, Middle ) ) then
				Min = Middle + 1;
			else
				Max = Middle - 1;
			end
		until ( Min > Max );
		return Max;
	end
	--- @return Number of trailing bytes shared by both String1 and String2.
	local function GetCommonSuffixLength ( String1, String2, PrefixLength )
		local Min, Max = 1, ( #String1 < #String2 and #String1 or #String2 ) - PrefixLength;
		repeat
			local Middle = ceil( Min + ( Max - Min ) / 2 );
			if ( strsub( String1, -Middle, -Min ) == strsub( String2, -Middle, -Min ) ) then
				Min = Middle + 1;
			else
				Max = Middle - 1;
			end
		until ( Min > Max );
		return Max;
	end
	--- Checks Script's text for changes, and adds a history entry if any are found.
	-- @return True if a new history entry was added.
	function NS:Compare ( Script )
		self.CompareTimer:Stop();
		local History = Script._History;
		if ( not History ) then
			Script._History, Script._HistoryIndex = {}, 0;
			Script._HistoryText = Script._Text;
			return;
		end
		local HistoryText, Text = Script._HistoryText, Script._Text;
		if ( HistoryText == Text ) then
			return; -- No change
		end

		-- Overwrite previously undone changes
		for Index = Script._HistoryIndex + 1, #History do
			History[ Index ] = nil;
		end

		-- Find the smallest contiguous range of changed text, and save its position
		-- and previous/current value.  This works well with the assumption that most
		-- edits affect only a small range at the cursor.
		local Prefix = GetCommonPrefixLength( HistoryText, Text );
		local Start, End = Prefix + 1, -GetCommonSuffixLength( HistoryText, Text, Prefix ) - 1;
		History[ #History + 1 ] = HistoryText:sub( Start, End ); -- Original text at range
		History[ #History + 1 ] = Text:sub( Start, End ); -- Replacement text at range
		History[ #History + 1 ] = Start; -- Offset for changed range
		-- Delete extra history entries over the cap
		for Index = NS.MaxEntries * KEYS_PER_ENTRY + 1, #Script._History do
			tremove( Script._History, 1 );
		end
		Script._HistoryIndex, Script._HistoryText = #History, Text;

		self:UpdateButtons( Script );
		return true;
	end
end
do
	local COLOR_TERMINATOR = "|r";
	--- Applies an edit from the history buffer to Script.
	local function ApplyHistory ( Script, Start, MiddleNew, MiddleCurrent )
		local Prefix = Script._Text:sub( 1, Start - 1 );
		local Suffix = Script._Text:sub( Start + #MiddleCurrent );

		local Text = ( "" ):join( Prefix, MiddleNew, Suffix );
		Script._HistoryText = Text; -- Prevent the undo/redo from counting as a new edit
		Script:SetText( Text );
		if ( NS.Script == Script ) then -- Move cursor to just after replaced text
			Start = Start + #MiddleNew - 1;
			-- Cursor can't be directly after a color code or before a terminator
			if ( Suffix:sub( 1, #COLOR_TERMINATOR ) == COLOR_TERMINATOR ) then
				Start = Start + #COLOR_TERMINATOR; -- Move cursor to after terminator
			else -- Check for color code just before cursor
				local ColorEnd, _, Escapes, Color = 0;
				while ( true ) do
					_, ColorEnd, Escapes, Color = Text:find( "(|*)(|c%x%x%x%x%x%x%x%x)", ColorEnd + 1 );
					if ( not ColorEnd or ColorEnd > Start ) then
						break;
					elseif ( ColorEnd == Start and #Escapes % 2 == 0 ) then
						Start = Start - #Color;
					end
				end
			end
			GUI.Editor:SetScriptCursorPosition( Start );
		end
	end
	--- Undoes one edit on Script, if available.
	-- @return True if an edit was undone.
	function NS:Undo ( Script )
		self:Compare( Script );
		if ( Script._HistoryIndex == 0 ) then
			return; -- Nothing to undo
		end

		local History, Index = Script._History, Script._HistoryIndex;
		Script._HistoryIndex = Index - KEYS_PER_ENTRY;
		self:UpdateButtons( Script );
		ApplyHistory( Script, History[ Index ], History[ Index - 2 ], History[ Index - 1 ] );
		return true;
	end
	--- Redoes one edit on Script, if available.
	-- @return True if an edit was redone.
	function NS:Redo ( Script )
		self:Compare( Script );
		if ( Script._HistoryIndex == #Script._History ) then
			return; -- Nothing to redo
		end

		local History, Index = Script._History, Script._HistoryIndex + KEYS_PER_ENTRY;
		Script._HistoryIndex = Index;
		self:UpdateButtons( Script );
		ApplyHistory( Script, History[ Index ], History[ Index - 1 ], History[ Index - 2 ] );
		return true;
	end
end




--- Initializes Button to be a title button on the editor window.
local function SetupButton ( Button )
	Button:SetSize( 34, 34 );
	Button:SetHitRectInsets( 8, 8, 8, 8 );
	Button:SetNormalTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Up]] );
	Button:SetPushedTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Down]] );
	Button:SetDisabledTexture( [[Interface\GLUES\CHARACTERCREATE\UI-RotationRight-Big-Up]] );
	local Disabled = Button:GetDisabledTexture();
	Disabled:SetDesaturated( true );
	Disabled:SetVertexColor( 0.6, 0.6, 0.6 );
	Button:SetHighlightTexture( [[Interface\BUTTONS\UI-ScrollBar-Button-Overlay]] );
	Button:GetHighlightTexture():SetVertexColor( 1, 0, 0 );
	Button:SetMotionScriptsWhileDisabled( true );
	Button:SetScript( "OnEnter", GUI.Dialog.ControlOnEnter );
	Button:SetScript( "OnLeave", GameTooltip_Hide );
	Button:SetScript( "OnClick", Button.OnClick );
end

-- Title buttons
local Redo = NS.RedoButton;
SetupButton( Redo );
GUI.Editor:AddTitleButton( Redo, -2 );
Redo.tooltipText = GUI.L.REDO;

local Undo = NS.UndoButton;
SetupButton( Undo );
GUI.Editor:AddTitleButton( Undo, 12 );
Undo.tooltipText = GUI.L.UNDO;
-- Flip texture to the left since no left arrow texture exists
Undo:GetNormalTexture():SetTexCoord( 1, 0, 0, 1 );
Undo:GetPushedTexture():SetTexCoord( 1, 0, 0, 1 );
Undo:GetDisabledTexture():SetTexCoord( 1, 0, 0, 1 );


NS.CompareTimer:CreateAnimation( "Animation" ):SetDuration( COMPARE_INTERVAL );
NS.CompareTimer:SetScript( "OnFinished", NS.CompareTimer.OnFinished );

_DevPad.RegisterCallback( NS, "ScriptSetText" );
GUI.RegisterCallback( NS, "EditorSetScriptObject" );
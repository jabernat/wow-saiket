--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.List.lua - Tree view of folders and scripts.                   *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );
local L = GUI.L;

local me = GUI.Dialog:New( "_DevPadGUIList" );
GUI.List = me;

me.ScrollChild = CreateFrame( "Frame", nil, me.ScrollFrame );

me.Send = me:NewButton( [[Interface\BUTTONS\UI-GuildButton-MOTD-Up]] );
me.Delete = me:NewButton( [[Interface\BUTTONS\UI-GroupLoot-Pass-Up]] )
me.NewScript = me:NewButton( [[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]] );
me.NewFolder = me:NewButton( [[Interface\MINIMAP\TRACKING\Banker]] );

me.Edited = me:CreateTexture( nil, "OVERLAY" );
me.RenameEdit = CreateFrame( "EditBox" );
me.SearchEdit = CreateFrame( "EditBox", "_DevPadGUIListSearchEdit", me.Bottom, "InputBoxTemplate" );
me.SearchEdit.InactiveAlpha = 0.5;
me.SearchMismatchAlpha = 0.5;
local SearchFrequency = 0.25; -- Update rate of list item highlighting

me.DefaultWidth, me.DefaultHeight = 180, 250;
me.SendNoticeThreshold = 4096; -- Larger objects print a wait message

local ButtonHeight = 16;
local IndentSize = 20;

local ObjectButtons = {}; -- [ Object ] = Button;




--- Sets or clears the list selection.
-- @param Object  Descendant of Root to select, or nil to clear.
-- @return True if selection changed.
function me:SetSelection ( Object )
	if ( self.Selection ~= Object ) then
		if ( self.Selection ) then
			ObjectButtons[ self.Selection ]:UnlockHighlight();
		end
		self.Selection = Object;
		self:SetRenaming(); -- Stop renaming
		if ( Object ) then
			ObjectButtons[ Object ]:LockHighlight();
		end
		GUI.Callbacks:Fire( "ListSetSelection", Object );
		return true;
	elseif ( Object ) then -- Fire event anyway to reopen editor if closed
		GUI.Callbacks:Fire( "ListSetSelection", Object );
	end
end
--- Shows or hides the renaming UI for an object.
-- @param Object  Descendant of Root to rename, or nil to stop.
-- @return True if renaming target changed.
function me:SetRenaming ( Object )
	if ( self.Renaming ~= Object ) then
		if ( self.Renaming ) then -- Restore last edited button
			ObjectButtons[ self.Renaming ].Name:Show();
		end
		self.Renaming = Object;
		local Edit = self.RenameEdit;
		if ( Object ) then
			local Button = ObjectButtons[ Object ];
			Button.Name:Hide();
			Edit:SetParent( Button.Visual );
			Edit:SetAllPoints( Button.Name );
			Edit:SetFontObject( Button.Name:GetFontObject() );
			Edit:SetText( Object._Name );
			Edit:Show();
			Edit:SetFocus();
		else
			Edit:Hide();
		end
		return true;
	end
end
do
	local CLOSED_FOLDER_WAIT = 1; -- Seconds before folder will open while dragging
	local MouseoverObject, MouseoverTime;
	--- Moves Object Offset places from the top of Folder.
	-- @return Number of shown objects in Folder if not placed.
	local function SetAbsPosition( Object, Folder, Offset, Elapsed )
		for Index, Child in ipairs( Folder ) do
			Offset = Offset - 1;
			if ( Offset <= 0 ) then -- Child at Offset
				if ( MouseoverObject ~= Child ) then
					MouseoverObject, MouseoverTime = Child, 0;
				else
					MouseoverTime = MouseoverTime + Elapsed;
				end
				if ( Child._Class == "Folder" and -Offset < 0.5 ) then -- Over bottom half of folder
					-- Pause before opening closed folders
					if ( not Child._Closed or MouseoverTime >= CLOSED_FOLDER_WAIT ) then
						Child:SetClosed( false );
						Child:Insert( Object, 1 );
					end
				else
					Folder:Insert( Object, Index );
				end
				return;
			end
			if ( Child._Class == "Folder" and not Child._Closed ) then
				Offset = SetAbsPosition( Object, Child, Offset, Elapsed );
				if ( not Offset ) then
					return;
				end
			end
		end
		return Offset;
	end
	local GetCursorPosition = GetCursorPosition;
	local Huge = math.huge;
	--- Periodically moves the dragged object within the tree.
	local function OnUpdate ( self, Elapsed )
		local _, CursorY = GetCursorPosition();
		local ScrollFrame = me.ScrollFrame;
		-- Distance from top of list
		CursorY = me.ScrollChild:GetTop() - CursorY / ScrollFrame:GetEffectiveScale();
		if ( not ScrollFrame:IsMouseOver() ) then -- Scroll to follow
			local Scroll = ScrollFrame:GetVerticalScroll();
			if ( CursorY < Scroll ) then -- Above
				ScrollFrame.Bar:SetValue( CursorY );
			else
				local Height = ScrollFrame:GetHeight();
				if ( CursorY - Height > Scroll ) then -- Below
					ScrollFrame.Bar:SetValue( CursorY - Height );
				end
			end
		end
		if ( self:IsMouseOver( 0, 0, -Huge, Huge ) ) then -- Over dragged object
			MouseoverObject, MouseoverTime = nil;
		else -- Above or below
			if ( SetAbsPosition( self.Object, _DevPad.FolderRoot, CursorY / ButtonHeight, Elapsed ) ) then
				-- Below end of tree
				return _DevPad.FolderRoot:Insert( self.Object );
			end
		end
	end
	local ClosedBackup;
	--- Stop or start dragging an object within the tree.
	-- @param Object  Descendant of Root to drag, or nil to stop.
	-- @return True if drag target changed.
	function me:SetDragging ( Object )
		if ( self.Dragging ~= Object ) then
			if ( self.Dragging ) then
				local Button = ObjectButtons[ self.Dragging ];
				Button:SetScript( "OnUpdate", nil );
				Button:GetHighlightTexture():SetVertexColor( 1, 1, 1 );
				if ( self.Dragging._Class == "Folder" ) then
					self.Dragging:SetClosed( ClosedBackup );
				end
			end
			self.Dragging = Object;
			MouseoverObject, MouseoverTime = nil;
			if ( Object ) then
				local Button = ObjectButtons[ Object ];
				Button:SetScript( "OnUpdate", OnUpdate );
				local Color = ORANGE_FONT_COLOR;
				Button:GetHighlightTexture():SetVertexColor( Color.r, Color.g, Color.b ); -- Orange
				if ( Object._Class == "Folder" ) then -- Close while dragging
					ClosedBackup = Object._Closed;
					Object:SetClosed( true );
				end
				self:SetSelection( Object );
			end
			return true;
		end
	end
end
do
	local Escapes = { n = "\n"; r = "\r"; };
	--- Unescapes escape sequences found by gsub.
	local function EscapesGsub ( Character )
		return Escapes[ Character ] or Character;
	end
	--- Updates the search highlight or stops searching.
	-- @param Search  Pattern to search for in scripts; Empty string to stop.
	--   Backslashes and pipes get unescaped.
	-- @return True if search pattern changed.
	function me:SetSearch ( Text )
		local Search = false;
		if ( Text ~= "" ) then
			Search = Text:gsub( "||", "|" ):gsub( [[\(.)]], EscapesGsub );
		end
		if ( self.Search ~= Search ) then
			self.Search = Search;
			local Edit = self.SearchEdit;
			Edit:SetText( Text );

			if ( Search ) then
				Edit:SetAlpha( 1 );
				self:UpdateSearch();
			else
				if ( not Edit:HasFocus() ) then
					Edit:SetAlpha( Edit.InactiveAlpha );
				end
				for _, Button in pairs( ObjectButtons ) do
					Button.Visual:SetAlpha( 1 );
				end
			end
			return true;
		end
	end
end
do
	local ipairs = ipairs;
	local pcall, strfind = pcall, strfind;
	--- Recursively highlights folders if any of their children match.
	-- @return True if the folder contained at least one match.
	local function UpdateFolder ( Folder )
		local MatchChild;
		for _, Child in ipairs( Folder or _DevPad.FolderRoot ) do
			if ( Child._Class == "Folder" ) then
				MatchChild = UpdateFolder( Child ) or MatchChild;
			elseif ( Child._Class == "Script" ) then
				local Valid, Match = pcall( strfind, Child._Text, me.Search );
				Match = Valid and Match ~= nil; -- Valid pattern too
				MatchChild = MatchChild or Match;
				ObjectButtons[ Child ].Visual:SetAlpha(
					Match and 1 or me.SearchMismatchAlpha );
			end
		end
		if ( Folder ) then -- Not root
			ObjectButtons[ Folder ].Visual:SetAlpha(
				MatchChild and 1 or me.SearchMismatchAlpha );
		end
		return MatchChild;
	end

	local Timer = me.SearchEdit:CreateAnimationGroup();
	Timer:CreateAnimation( "Animation" ):SetDuration( 1e-7 );
	local Animation = Timer:CreateAnimation( "Animation" );
	Animation:SetOrder( 2 ); -- Note: Keeps OnPlay from firing right after :Play.
	Animation:SetDuration( SearchFrequency );
	--- Throttles search updates.
	Animation:SetScript( "OnPlay", function ( self )
		Timer.UpdatePending = nil;
		if ( me.Search ) then
			return UpdateFolder();
		end
	end );
	--- Refilter after the cooldown if requested since the last update.
	Timer:SetScript( "OnFinished", function ( self )
		if ( self.UpdatePending ) then
			return self:Play();
		end
	end );
	--- Updates search match highlights.
	function me:UpdateSearch ()
		Timer.UpdatePending = true;
		return Timer:Play();
	end
end
--- Gets the position of the next match within a given script.
-- @param Script  Script to search within.
-- @param Cursor  Cursor position to start from.
-- @param Reverse  True to find the previous match.
-- @return (Start position, End position), or nil if no match.
function me:NextMatch ( Script, Cursor, Reverse )
	local Start, End;
	if ( Reverse ) then
		local StartCurrent, EndCurrent;
		EndCurrent = 0;
		while ( EndCurrent and EndCurrent <= Cursor ) do
			Start, End = StartCurrent, EndCurrent;
			StartCurrent, EndCurrent = Script._Text:find( self.Search, EndCurrent + 1 );
		end
	else
		Start, End = Script._Text:find( self.Search, Cursor + 1 );
	end
	if ( Start ) then
		return Start - 1, End;
	end
end
--- Gets the position of the next match, possibly wrapping around.
-- @see me:NextMatch
function me:NextMatchWrap ( Script, Cursor, Reverse )
	local Start, End = self:NextMatch( Script, Cursor, Reverse );
	if ( not Start ) then
		Cursor = Reverse and #Script._Text or 0;
		Start, End = self:NextMatch( Script, Cursor, Reverse );
	end
	return Start, End;
end
do
	--- @return Script at or after Start, or nil if no scripts found.
	local function NextScript ( Start, Direction )
		local Object = Start;
		repeat
			if ( Object._Class == "Script" ) then
				return Object;
			end
			Object = Object[ Direction ];
		until ( Object == Start );
	end
	--- Gets the position of the next match, cycling through all scripts for a match.
	-- @see me:NextMatch
	function me:NextMatchGlobal ( Script, Cursor, Reverse )
		local Direction = Reverse and "_Previous" or "_Next";
		if ( not Script ) then
			Script = NextScript( self.Selection or _DevPad.FolderRoot, Direction );
			if ( not Script ) then -- No scripts in root
				return;
			end
		end
		local Start, End = self:NextMatch( Script, Cursor, Reverse );
		if ( Start ) then
			return Script, Start, End;
		end
		-- Wrap through other scripts, then search the rest of the first one
		local First = Script;
		repeat
			Script = NextScript( Script[ Direction ], Direction );
			Start, End = self:NextMatch( Script, Reverse and #Script._Text or 0, Reverse );
			if ( Start and ( Script ~= First
				or ( Reverse and Start > Cursor ) -- Wrapped back into rest of start
				or ( not Reverse and End <= Cursor )
			) ) then
				return Script, Start, End;
			end
		until ( Script == First );
	end
end
do
	--- Recursively adds script and folder buttons to the list.
	-- @param Depth  How deep Folder is nested.  Leave nil on initial call.
	-- @param Count  Number of buttons already visible in list.
	-- @return Total number of buttons shown.
	local function LayoutFolder ( Folder, Depth, Count )
		if ( not Depth ) then
			Depth, Count = 0, 0;
		end
		if ( not Folder._Closed ) then
			for _, Child in ipairs( Folder ) do
				Count = Count + 1;
				local Button = ObjectButtons[ Child ];
				Button:SetPoint( "TOP", 0, -( Count - 1 ) * ButtonHeight );
				Button.Visual:SetPoint( "LEFT", IndentSize * Depth, 0 );

				if ( Child._Class == "Folder" ) then
					Count = LayoutFolder( Child, Depth + 1, Count );
				end
			end
		end
		return Count;
	end
	--- Throttles tree repaints to once per frame.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		LayoutFolder( _DevPad.FolderRoot )
		self.ScrollFrame:UpdateScrollChildRect();
	end
	--- Request that the list be redrawn before the next frame.
	function me:Update ()
		return self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Updates the title buttons for the current selection.
function me:ListSetSelection ( _, Object )
	if ( Object ) then
		self.Delete:Enable();
		self.Send:Enable();
	else
		self.Delete:Disable();
		self.Send:Disable();
	end
end
--- Clears popup data when closed.
function me:StaticPopupOnHide ()
	self.data = nil;
end
do
	--- Prints a message after the object is sent.
	local function SendCallback ( Data, Bytes, BytesTotal )
		if ( Bytes == BytesTotal ) then
			_DevPad.Print( L.SEND_COMPLETE_FORMAT:format(
				Data.Name, Data.Target ), GREEN_FONT_COLOR );
		end
	end
	--- Sends an object over the given channel.
	-- @param TargetName  Printable name of send target.
	local function Send ( Object, Channel, Target, TargetName )
		local Data = { Name = Object._Name; Target = TargetName; };
		local Size = Object:Send( Channel, Target, nil, SendCallback, Data );
		if ( Size > me.SendNoticeThreshold ) then
			_DevPad.Print( L.SEND_LARGE_FORMAT:format(
				Data.Name, Size / 1024, Data.Target ) );
		end
	end
	--- Sends the object to the given channel.
	local function SendBroadcast ( self, Channel )
		if ( me.Selection ) then
			Send( me.Selection, Channel, nil, _G[ Channel ] );
		end
	end
	--- Whispers the object to a player.
	function me.Send:NameOnAccept ( Object )
		local Name = self.editBox:GetText():trim();
		if ( Name == "" ) then
			return true; -- Keep open
		elseif ( UnitIsUnit( Name, "player" ) ) then -- Direct copy
			local Copy = Object:Copy();
			Copy:SetName( L.COPY_OBJECTNAME_FORMAT:format( Object._Name ) );
			_DevPad.FolderRoot:Insert( Copy );
		else
			Send( Object, "WHISPER", Name, Name );
		end
	end
	--- Accepts the typed name.
	function me.Send:NameOnEnterPressed ()
		return self:GetParent().button1:Click();
	end
	--- Requests a player name to send to.
	local function SendToPlayer ( self )
		local Dialog = StaticPopup_Show( "_DEVPAD_SEND_PLAYER", nil, nil, me.Selection );
		if ( Dialog ) then
			if ( UnitIsPlayer( "target" ) ) then
				Dialog.editBox:SetText( UnitName( "player" ) );
			end
			Dialog.editBox:SetFocus();
		end
	end
	local Dropdown = CreateFrame( "Frame", "_DevPadGUIListSendDropDown", me.Send, "UIDropDownMenuTemplate" );
	local Menu = {
		{ text = PLAYER; func = SendToPlayer; arg1 = "WHISPER"; notCheckable = true; },
		{ text = PARTY; func = SendBroadcast; arg1 = "PARTY"; notCheckable = true; },
		{ text = RAID; func = SendBroadcast; arg1 = "RAID"; notCheckable = true; },
		{ text = GUILD; func = SendBroadcast; arg1 = "GUILD"; notCheckable = true; },
		{ text = OFFICER; func = SendBroadcast; arg1 = "OFFICER"; notCheckable = true; },
	};
	--- Opens a dropdown menu with potential script recipients.
	function me.Send:OnClick ()
		-- Match chat colors
		for _, Info in ipairs( Menu ) do
			local Type = ChatTypeInfo[ Info.arg1 ];
			Info.colorCode = ( "|cff%02x%02x%02x" ):format( Type.r * 255, Type.g * 255, Type.b * 255 );
		end
		Menu[ 2 ].disabled = GetNumPartyMembers() == 0;
		Menu[ 3 ].disabled = GetNumRaidMembers() == 0;
		Menu[ 4 ].disabled = not IsInGuild();
		Menu[ 5 ].disabled = not IsInGuild();
		EasyMenu( Menu, Dropdown, "cursor", nil, nil, "MENU" );
	end
end
do
	--- Add the received object to the list.
	function me.Send:ReceiveOnAccept ( Object )
		Object:SetName( L.RECEIVE_OBJECTNAME_FORMAT:format( Object._Name, Object._Author ) );
		_DevPad.FolderRoot:Insert( Object );
	end
	local Queue, Ignored = _DevPad.ReceiveQueue, _DevPad.ReceiveIgnored;
	--- Puts the author on the ignore list.
	function me.Send:ReceiveOnIgnore ( Object )
		Ignored[ Object._Author:lower() ] = true;
		AddIgnore( Object._Author );
	end
	--- Prompts the user to receive the next object in the queue.
	local function ConfirmNext ()
		if ( #Queue == 0 or StaticPopup_Visible( "_DEVPAD_RECEIVE_CONFIRM" ) ) then
			return;
		end
		while ( #Queue > 0 ) do
			local Object = tremove( Queue, 1 );
			if ( not Ignored[ Object._Author:lower() ] ) then
				StaticPopupDialogs[ "_DEVPAD_RECEIVE_CONFIRM" ].text = Object._Class == "Folder"
					and L.RECEIVE_CONFIRM_FOLDER_FORMAT
					or L.RECEIVE_CONFIRM_SCRIPT_FORMAT;
				return StaticPopup_Show( "_DEVPAD_RECEIVE_CONFIRM",
					Object._Author, Object._Name, Object );
			end
		end
	end
	--- Tries to show confirmation prompts until the queue is empty.
	local function OnUpdate ( self )
		ConfirmNext();
		if ( #Queue == 0 ) then
			self:SetScript( "OnUpdate", nil );
		end
	end
	--- Prompt the user to save received objects.
	function me:ObjectReceived ()
		self.Send:SetScript( "OnUpdate", OnUpdate );
	end
end
--- Deletes the object once confirmed.
function me.Delete:OnAccept ( Object )
	if ( Object._Parent ) then
		Object._Parent:Remove( Object );
	end
	-- Note: Don't return anything, or the dialog won't hide afterwards.
end
--- Opens a confirmation to delete the selected object.
function me.Delete:OnClick ()
	local Object = me.Selection;
	if ( IsShiftKeyDown()
		or ( Object._Class == "Script" and Object._Text == "" )
		or ( Object._Class == "Folder" and #Object == 0 )
	) then
		return self:OnAccept( Object );
	else
		StaticPopup_Show( "_DEVPAD_DELETE_CONFIRM", Object._Name, nil, Object );
	end
end
do
	--- Creates a new object above the selection or at the end.
	local function InsertObject ( Class )
		local Object = _DevPad:GetClass( Class ):New();
		if ( me.Selection ) then -- Add just before selection
			me.Selection._Parent:Insert( Object, me.Selection:GetIndex() );
		else -- Default to end of list
			_DevPad.FolderRoot:Insert( Object );
		end
		me:SetSelection( Object );
		me:SetRenaming( Object );
	end
	--- Creates a new script.
	function me.NewScript:OnClick ()
		InsertObject( "Script" );
	end
	--- Creates a new folder.
	function me.NewFolder:OnClick ()
		InsertObject( "Folder" );
	end
end


--- Stops renaming.
function me.RenameEdit:OnEditFocusLost ()
	return me:SetRenaming();
end
--- Saves the object's new name.
function me.RenameEdit:OnEnterPressed ()
	me.Renaming:SetName( self:GetText() );
	return self:ClearFocus();
end
do
	--- Waits one frame before moving the view in case the edit box was re-anchored.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		local Top = me.ScrollChild:GetTop() - self:GetTop();
		local Bottom = Top + self:GetHeight();
		me.ScrollFrame:SetVerticalScrollToCoord( Top, Bottom );
	end
	--- Scrolls the edit box into view while typing.
	function me.RenameEdit:OnCursorChanged ()
		return self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Lights up search box while typing.
function me.SearchEdit:OnEditFocusGained ()
	self:HighlightText();
	self:SetAlpha( 1 );
end
--- Dims search box if no longer searching.
function me.SearchEdit:OnEditFocusLost ()
	self:HighlightText( 0, 0 );
	if ( self:GetText() == "" ) then
		self:SetAlpha( self.InactiveAlpha );
	end
	if ( GUI.Editor:IsVisible()
		and not GetCurrentKeyBoardFocus() -- Didn't switch to another editbox
	) then
		GUI.Editor.Edit:SetFocus();
	end
end
--- Jumps to next/previous search result.
function me.SearchEdit:OnEnterPressed ()
	if ( me.Search ) then
		local Script, Cursor, Reverse = GUI.Editor.Script, 0, IsShiftKeyDown();
		if ( Script ) then
			Cursor = GUI.Editor:GetScriptCursorPosition();
			if ( Reverse and Cursor > 0 ) then
				Cursor = Cursor - 1;
			end
		end
		local ScriptNew, Start, End = me:NextMatchGlobal( Script, Cursor, Reverse );
		if ( ScriptNew ) then
			GUI.Editor:SetScriptObject( ScriptNew );
		end
		GUI.Editor:SetScriptHighlight( Start, End, true );
	else
		return self:ClearFocus();
	end
end
--- Refilters the list when the search pattern changes.
function me.SearchEdit:OnTextChanged ()
	return me:SetSearch( self:GetText() );
end
--- Builds a tooltip under the edit box so it doesn't cover the list.
function me.SearchEdit:OnEnter ()
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint( "TOPLEFT", self, "BOTTOMLEFT" );
	GameTooltip:SetOwner( self, "ANCHOR_PRESERVE" );
	GameTooltip:SetText( L.SEARCH_DESC, nil, nil, nil, nil, 1 );
end


--- Updates an object's name text.
function me:ObjectSetName ( _, Object )
	if ( ObjectButtons[ Object ] ) then
		return ObjectButtons[ Object ].Name:SetText( Object._Name );
	end
end
do
	local CreateFolderButton, CreateScriptButton;
	do
		local CreateButton;
		do
			--- Selects a folder or script button when clicked.
			local function ButtonOnClick ( self )
				if ( self.Object._Class == "Folder" ) then
					self.Object:SetClosed( not self.Object._Closed );
				end
				if ( me:SetSelection( self.Object ) ) then
					PlaySound( "igMainMenuOptionCheckBoxOn" );
				end
			end
			--- Starts renaming the object when double clicked.
			local function ButtonOnDoubleClick ( self )
				ButtonOnClick( self );
				return me:SetRenaming( self.Object );
			end
			--- Start moving the object on drag.
			local function ButtonOnDragStart ( self )
				return me:SetDragging( self.Object );
			end
			--- Stop dragging the object.
			local function ButtonOnDragStop ( self )
				if ( me.Dragging == self.Object ) then
					return me:SetDragging();
				end
			end
			--- Stop dragging and deselect the object.
			local function ButtonOnHide ( self )
				ButtonOnDragStop( self );
				if ( me.Selection == self.Object ) then
					return me:SetSelection();
				end
			end
			--- @return A new generic list button.
			function CreateButton ()
				local Button = CreateFrame( "Button", nil, me.ScrollChild );
				Button:Hide();
				Button:SetHeight( ButtonHeight );
				Button:SetPoint( "LEFT", me.ScrollFrame );
				Button:SetPoint( "RIGHT", me.ScrollFrame );
				Button:SetHighlightTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]] );
				Button:RegisterForDrag( "LeftButton" );
				Button:SetScript( "OnClick", ButtonOnClick );
				Button:SetScript( "OnDoubleClick", ButtonOnDoubleClick );
				Button:SetScript( "OnDragStart", ButtonOnDragStart );
				Button:SetScript( "OnDragStop", ButtonOnDragStop );
				Button:SetScript( "OnHide", ButtonOnHide );

				-- Button artwork that gets indented with folder level
				Button.Visual = CreateFrame( "Frame", nil, Button );
				Button.Visual:SetPoint( "TOPRIGHT" );
				Button.Visual:SetPoint( "BOTTOM" );

				Button.Name = Button.Visual:CreateFontString( nil, "ARTWORK" );
				Button.Name:SetPoint( "TOP" );
				Button.Name:SetPoint( "BOTTOM" );
				Button.Name:SetPoint( "LEFT" ); -- Allow folder expand button to adjust
				Button.Name:SetPoint( "RIGHT" ); -- Allow script autorun button to adjust
				Button.Name:SetJustifyH( "LEFT" );
				return Button;
			end
		end

		--- Toggles a folder's closed state when clicked.
		local function ExpandOnClick ( self )
			local Folder = self:GetParent():GetParent().Object;
			PlaySound( Folder._Closed and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
			Folder:SetClosed( not Folder._Closed );
		end
		--- @return A new folder button.
		function CreateFolderButton ()
			local Button = CreateButton();

			local Expand = me.NewButton( Button.Visual, [[Interface\ACHIEVEMENTFRAME\UI-ACHIEVEMENT-PLUSMINUS]] );
			Button.Expand = Expand;
			Expand:SetSize( ButtonHeight, ButtonHeight );
			Expand:SetPoint( "LEFT" );
			Expand:SetScript( "OnClick", ExpandOnClick );

			Button.Name:SetFontObject( GameFontNormal );
			Button.Name:SetPoint( "LEFT", Expand, "RIGHT", IndentSize - ButtonHeight, 0 );
			return Button;
		end

		--- Toggles autorun for this script.
		local function AutoRunOnClick ( self )
			local Object = self:GetParent():GetParent().Object;
			return Object:SetAutoRun( not Object._AutoRun );
		end
		--- Shows the script's LuaDoc comment as a tooltip.
		local function ScriptOnEnter ( self )
			local Comment = ( self.Object._Text:match( "^%-%-%-([^\r\n]+)" ) or "" ):trim();
			if ( Comment ~= "" ) then
				GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT" );
				GameTooltip:SetText( Comment, nil, nil, nil, nil, 1 );
			end
		end
		--- @return A new script button.
		function CreateScriptButton ()
			local Button = CreateButton();
			Button:SetScript( "OnEnter", ScriptOnEnter );
			Button:SetScript( "OnLeave", GameTooltip_Hide );

			local AutoRun = me.NewButton( Button.Visual, [[Interface\Archeology\ArchaeologyParts]] );
			Button.AutoRun = AutoRun;
			AutoRun:SetPoint( "RIGHT" );
			AutoRun:SetSize( ButtonHeight, ButtonHeight * 0.8 );
			AutoRun:SetScript( "OnClick", AutoRunOnClick );
			AutoRun.tooltipText = L.SCRIPT_AUTORUN_DESC
			-- Show tab arrow icon
			AutoRun:GetNormalTexture():SetTexCoord( 0.85, 1, 0.01, 0.22 );
			AutoRun:GetPushedTexture():SetTexCoord( 0.85, 1, 0.01, 0.22 );

			Button.Name:SetFontObject( GameFontHighlight );
			Button.Name:SetPoint( "RIGHT", AutoRun, "LEFT" );
			return Button;
		end
	end
	--- Fires a callback for all descendants of Object.
	-- @param ShownOnly  Don't recurse closed folders if true.
	local function RecurseChildren ( Folder, Callback, ShownOnly )
		for Index, Child in ipairs( Folder ) do
			Callback( Child );
			if ( Child._Class == "Folder"
				and not ( ShownOnly and Child._Closed )
			) then
				RecurseChildren( Child, Callback, ShownOnly );
			end
		end
	end
	local UnusedButtons = {
		[ "Folder" ] = setmetatable( {}, { __call = CreateFolderButton; } );
		[ "Script" ] = setmetatable( {}, { __call = CreateScriptButton; } );
	};

	--- Shows or hides an object's button.
	local function ObjectButtonUpdateVisible ( Object )
		local Button = ObjectButtons[ Object ];
		if ( Button ) then
			return Button[ Object:IsHidden() and "Hide" or "Show" ]( Button );
		end
	end
	--- Assigns a button to a new script or folder.
	local function ObjectButtonAssign ( Object )
		local Button, Unused = ObjectButtons[ Object ], UnusedButtons[ Object._Class ];
		if ( not Button and Unused ) then -- Known class and not already assigned
			Button = next( Unused ) or Unused();
			Unused[ Button ] = nil;
			ObjectButtons[ Object ], Button.Object = Button, Object;

			me:ObjectSetName( nil, Object );
			if ( Object._Class == "Script" ) then
				me:ScriptSetAutoRun( nil, Object );
				me:ScriptSetText( nil, Object );
			elseif ( Object._Class == "Folder" ) then
				me:FolderSetClosed( nil, Object );
			end
		end
		ObjectButtonUpdateVisible( Object );
	end
	--- Updates the tree view when an object gets added to a folder.
	function me:FolderInsert ( _, Folder, Object )
		if ( _DevPad.FolderRoot:Contains( Object ) ) then
			ObjectButtonAssign( Object );
			if ( Object._Class == "Folder" ) then -- Also assign child buttons
				RecurseChildren( Object, ObjectButtonAssign );
			end
			self:UpdateSearch();
			if ( not Object:IsHidden() ) then
				return self:Update();
			end
		end
	end

	--- Reclaims a script or folder button for reuse.
	local function ObjectButtonRecycle ( Object )
		local Button = ObjectButtons[ Object ];
		Button:Hide();
		if ( me.Search ) then
			Button.Visual:SetAlpha( 1 );
		end
		if ( me.Edited:GetParent() == Button ) then
			me:EditorSetScriptObject()
		end
		ObjectButtons[ Object ], Button.Object = nil;
		UnusedButtons[ Object._Class ][ Button ] = true;
	end
	--- Updates the tree view when an object gets removed from a folder.
	function me:FolderRemove ( _, Folder, Object )
		if ( ObjectButtons[ Object ] ) then
			ObjectButtonRecycle( Object );
			if ( Object._Class == "Folder" ) then
				RecurseChildren( Object, ObjectButtonRecycle );
			end
			self:UpdateSearch();
			if ( not ( Folder._Closed or Folder:IsHidden() ) ) then
				return self:Update();
			end
		end
	end

	--- Sets both button textures' texcoords.
	local function SetTexCoords ( self, ... )
		self:GetNormalTexture():SetTexCoord( ... );
		self:GetPushedTexture():SetTexCoord( ... );
	end
	--- Redraws a folder when it opens or closes.
	function me:FolderSetClosed ( _, Folder )
		local Button = ObjectButtons[ Folder ];
		if ( Button ) then
			if ( Folder._Closed ) then
				SetTexCoords( Button.Expand, 0, 0.5, 0.5, 0.75 );
			else
				SetTexCoords( Button.Expand, 0, 0.5, 0.75, 1 );
			end
		end
		if ( Folder == _DevPad.FolderRoot
			or ( Button and not Folder:IsHidden() ) -- Contents visible
		) then
			RecurseChildren( Folder, ObjectButtonUpdateVisible, true );
			return self:Update();
		end
	end
end
--- Updates Script's autorun indicator.
function me:ScriptSetAutoRun ( _, Script )
	if ( ObjectButtons[ Script ] ) then
		local AutoRun = ObjectButtons[ Script ].AutoRun;
		local Normal, Pushed = AutoRun:GetNormalTexture(), AutoRun:GetPushedTexture();
		if ( Script._AutoRun ) then
			Normal:SetDesaturated( false );
			Pushed:SetDesaturated( false );
			Normal:SetVertexColor( 0.2, 1, 0.2 );
			Pushed:SetVertexColor( 0.2, 1, 0.2 );
		else
			Normal:SetDesaturated( true );
			Pushed:SetDesaturated( true );
			Normal:SetVertexColor( 0.6, 0.6, 0.6 );
			Pushed:SetVertexColor( 0.6, 0.6, 0.6 );
		end
	end
end
--- Updates search match highlight when text changes.
function me:ScriptSetText ( _, Script )
	if ( ObjectButtons[ Script ] ) then
		return self:UpdateSearch();
	end
end
--- Adds a highlight to scripts open for editing.
function me:EditorSetScriptObject ( _, Script )
	local Button, Edited = ObjectButtons[ Script ], self.Edited;
	if ( Button ) then
		Edited:SetParent( Button );
		Edited:SetAllPoints();
		Edited:Show();
	else
		Edited:Hide();
		Edited:SetParent( self );
	end
end


function me:OnShow ()
	PlaySound( "igSpellBookOpen" );
end
--- Closes open scripts and cancels pending actions.
function me:OnHide ()
	PlaySound( "igSpellBookClose" );
	StaticPopup_Hide( "_DEVPAD_DELETE_CONFIRM" );
	StaticPopup_Hide( "_DEVPAD_SEND_PLAYER" );

	local Popup = _G[ StaticPopup_Visible( "_DEVPAD_RECEIVE_CONFIRM" ) ];
	if ( Popup ) then
		local Object = Popup.data;
		StaticPopup_Hide( "_DEVPAD_RECEIVE_CONFIRM" );
		-- Add back into queue to be confirmed later
		tinsert( _DevPad.ReceiveQueue, 1, Object );
		self:ObjectReceived();
	end
	if ( not self:IsShown() ) then -- Explicitly hidden, not obscured by world map
		return GUI.Editor:Hide();
	end
end




GUI.Dialog.StickyFrames[ "List" ] = me;
me:SetScript( "OnShow", me.OnShow );
me:SetScript( "OnHide", me.OnHide );
me.Title:SetText( L.LIST_TITLE );

me.ScrollChild:SetSize( 1, 1 );
me.ScrollFrame:SetScrollChild( me.ScrollChild );

-- Title buttons
local LastButton, ButtonCount = me.Close, 0;
--- @return A new title button.
local function SetupTitleButton ( Button, TooltipText )
	Button:SetPoint( "RIGHT", LastButton, "LEFT", -2, 0 );
	LastButton, ButtonCount = Button, ButtonCount + 1;
	Button:SetScript( "OnClick", Button.OnClick );
	Button:SetMotionScriptsWhileDisabled( true );
	Button.tooltipText = TooltipText;
end
SetupTitleButton( me.Send, L.SEND );
SetupTitleButton( me.Delete, L.DELETE );
SetupTitleButton( me.NewScript, L.SCRIPT_NEW );
SetupTitleButton( me.NewFolder, L.FOLDER_NEW );
me:SetMinResize( 40 + ButtonCount * 18 + me.Title:GetWidth(), 100 );
me:ListSetSelection(); -- Update title buttons

StaticPopupDialogs[ "_DEVPAD_DELETE_CONFIRM" ] = {
	text = L.DELETE_CONFIRM_FORMAT;
	button1 = YES;
	button2 = NO;
	OnAccept = me.Delete.OnAccept;
	OnHide = me.StaticPopupOnHide;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
	showAlert = true;
};
local Send = me.Send;
StaticPopupDialogs[ "_DEVPAD_SEND_PLAYER" ] = {
	text = L.SEND_PLAYER_NAME;
	button1 = ACCEPT;
	button2 = CANCEL;
	OnAccept = Send.NameOnAccept;
	EditBoxOnEnterPressed = Send.NameOnEnterPressed;
	EditBoxOnEscapePressed = StaticPopupDialogs[ "ADD_FRIEND" ].EditBoxOnEscapePressed;
	hasEditBox = true;
	autoCompleteParams = AUTOCOMPLETE_LIST.WHISPER;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
};
StaticPopupDialogs[ "_DEVPAD_RECEIVE_CONFIRM" ] = {
	button1 = YES;
	button2 = NO;
	button3 = IGNORE_PLAYER;
	OnAccept = Send.ReceiveOnAccept;
	OnAlt = Send.ReceiveOnIgnore;
	OnHide = me.StaticPopupOnHide;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
	showAlertGear = true;
	interruptCinematic = true;
	notClosableByLogout = true;
};

-- Search bar
me.Bottom:SetHeight( 24 );
local Search = me.SearchEdit;
Search:SetHeight( 20 );
Search:SetPoint( "BOTTOMLEFT", 12, 2 );
Search:SetPoint( "RIGHT", -10, 0 );
Search:SetAutoFocus( false );
Search:SetTextInsets( 12, 0, 0, 0 );
Search:SetFontObject( ChatFontSmall );
Search:SetScript( "OnEditFocusGained", Search.OnEditFocusGained );
Search:SetScript( "OnEditFocusLost", Search.OnEditFocusLost );
Search:SetScript( "OnEnterPressed", Search.OnEnterPressed );
Search:SetScript( "OnEscapePressed", Search.ClearFocus );
Search:SetScript( "OnTextChanged", Search.OnTextChanged );
Search:SetScript( "OnEnter", Search.OnEnter );
Search:SetScript( "OnLeave", GameTooltip_Hide );
local Icon = Search:CreateTexture( nil, "OVERLAY" );
Icon:SetPoint( "LEFT", 0, -2 );
Icon:SetSize( 14, 14 );
Icon:SetTexture( [[Interface\COMMON\UI-Searchbox-Icon]] );
me:SetSearch( "" );

-- Object renaming edit box
local Rename = me.RenameEdit;
Rename:Hide();
Rename:SetAutoFocus( false );
Rename:SetScript( "OnEnterPressed", Rename.OnEnterPressed );
Rename:SetScript( "OnEscapePressed", Rename.ClearFocus );
Rename:SetScript( "OnEditFocusGained", Rename.HighlightText );
Rename:SetScript( "OnEditFocusLost", Rename.OnEditFocusLost );
Rename:SetScript( "OnCursorChanged", Rename.OnCursorChanged );

-- Highlight for script open in editor
local Edited = me.Edited;
Edited:Hide();
Edited:SetTexture( [[Interface\ACHIEVEMENTFRAME\UI-Achievement-Category-Highlight]] );
Edited:SetBlendMode( "ADD" );
Edited:SetTexCoord( 0.029, 0.635, 0.149, 0.733 );
Edited:SetAlpha( 0.5 );

_DevPad.RegisterCallback( me, "ObjectSetName" );
_DevPad.RegisterCallback( me, "ObjectReceived" );
_DevPad.RegisterCallback( me, "FolderInsert" );
_DevPad.RegisterCallback( me, "FolderRemove" );
_DevPad.RegisterCallback( me, "FolderSetClosed" );
_DevPad.RegisterCallback( me, "ScriptSetAutoRun" );
_DevPad.RegisterCallback( me, "ScriptSetText" );
GUI.RegisterCallback( me, "ListSetSelection" );
GUI.RegisterCallback( me, "EditorSetScriptObject" );

me:Unpack( {} ); -- Default position/size

-- Synchronize with _DevPad
local Root = _DevPad.FolderRoot;
for _, Child in ipairs( Root ) do
	me:FolderInsert( "FolderInsert", Root, Child );
end
me:ObjectReceived( "ObjectReceived", nil );
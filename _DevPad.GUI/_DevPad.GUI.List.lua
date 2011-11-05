--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.List.lua - Tree view of folders and scripts.                   *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );
local L = GUI.L;

local NS = GUI.Dialog:New( "_DevPadGUIList" );
GUI.List = NS;

NS.ScrollChild = CreateFrame( "Frame", nil, NS.ScrollFrame );

NS.Send = NS:NewButton( [[Interface\BUTTONS\UI-GuildButton-MOTD-Up]] );
NS.Delete = NS:NewButton( [[Interface\BUTTONS\UI-GroupLoot-Pass-Up]] )
NS.NewScript = NS:NewButton( [[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]] );
NS.NewFolder = NS:NewButton( [[Interface\MINIMAP\TRACKING\Banker]] );

NS.Edited = NS:CreateTexture( nil, "OVERLAY" );
NS.RenameEdit = CreateFrame( "EditBox" );

NS.DefaultWidth, NS.DefaultHeight = 180, 250;
NS.SendNoticeThreshold = 4096; -- Larger objects print a wait message

local BUTTON_HEIGHT = 16;
local INDENT_SIZE = 20;




--- Sets the root folder to display the contents of.
-- @return True if the displayed root changed.
function NS:SetRoot ( Folder )
	if ( self.Root ~= Folder ) then
		assert( Folder and Folder._Class == "Folder", "Root must be a Folder object." );
		if ( self.Root ) then
			for _, Child in ipairs( self.Root ) do
				self:FolderRemove( nil, self.Root, Child );
			end
		end
		self.Root = Folder;
		for _, Child in ipairs( Folder ) do
			self:FolderInsert( nil, Folder, Child );
		end
		GUI.Callbacks:Fire( "ListSetRoot", Folder );
		return true;
	end
end
--- Sets or clears the list selection.
-- @param Object  Descendant of root to select, or nil to clear.
-- @return True if selection changed.
function NS:SetSelection ( Object )
	if ( self.Selection ~= Object ) then
		assert( not Object or Object._ListButton, "Object must be in folder root." );
		if ( self.Selection ) then
			self.Selection._ListButton:UnlockHighlight();
		end
		self.Selection = Object;
		self:SetRenaming(); -- Stop renaming
		if ( Object ) then
			Object._ListButton:LockHighlight();
		end
		GUI.Callbacks:Fire( "ListSetSelection", Object );
		return true;
	elseif ( Object ) then -- Fire event anyway to reopen editor if closed
		GUI.Callbacks:Fire( "ListSetSelection", Object );
	end
end
--- Shows or hides the renaming UI for an object.
-- @param Object  Descendant of root to rename, or nil to stop.
-- @return True if renaming target changed.
function NS:SetRenaming ( Object )
	if ( self.Renaming ~= Object ) then
		assert( not Object or Object._ListButton, "Object must be in folder root." );
		if ( self.Renaming ) then -- Restore last edited button
			self.Renaming._ListButton.Name:Show();
		end
		self.Renaming = Object;
		local Edit = self.RenameEdit;
		if ( Object ) then
			local Button = Object._ListButton;
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
					if ( Child._Closed and MouseoverTime >= CLOSED_FOLDER_WAIT ) then
						Child._ListMouseoverOpen = true;
						Child:SetClosed( false );
					end
					if ( not Child._Closed ) then
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
		local ScrollFrame = NS.ScrollFrame;
		-- Distance from top of list
		CursorY = NS.ScrollChild:GetTop() - CursorY / ScrollFrame:GetEffectiveScale();
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
			if ( SetAbsPosition( self.Object, NS.Root, CursorY / BUTTON_HEIGHT, Elapsed ) ) then
				-- Below end of tree
				return NS.Root:Insert( self.Object );
			end
		end
	end
	local ClosedBackup;
	--- Stop or start dragging an object within the tree.
	-- @param Object  Descendant of root to drag, or nil to stop.
	-- @return True if drag target changed.
	function NS:SetDragging ( Object )
		if ( self.Dragging ~= Object ) then
			assert( not Object or Object._ListButton, "Object must be in folder root." );
			if ( self.Dragging ) then
				local Button = self.Dragging._ListButton;
				Button:SetScript( "OnUpdate", nil );
				Button:GetHighlightTexture():SetVertexColor( 1, 1, 1 );
				for Child in self.Root:IterateChildren() do
					if ( Child._ListMouseoverOpen and not Child:Contains( self.Dragging ) ) then
						Child:SetClosed( true );
					end
					Child._ListMouseoverOpen = nil;
				end
				if ( self.Dragging._Class == "Folder" ) then
					self.Dragging:SetClosed( ClosedBackup );
				end
			end
			self.Dragging = Object;
			MouseoverObject, MouseoverTime = nil;
			if ( Object ) then
				local Button = Object._ListButton;
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
				local Button = Child._ListButton;
				Button:SetPoint( "TOP", 0, -( Count - 1 ) * BUTTON_HEIGHT );
				Button.Visual:SetPoint( "LEFT", INDENT_SIZE * Depth, 0 );

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
		LayoutFolder( self.Root )
		self.ScrollFrame:UpdateScrollChildRect();
	end
	--- Request that the list be redrawn before the next frame.
	function NS:Update ()
		return self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Updates the title buttons for the current selection.
function NS:ListSetSelection ( _, Object )
	if ( Object ) then
		self.Delete:Enable();
		self.Send:Enable();
	else
		self.Delete:Disable();
		self.Send:Disable();
	end
end
--- Clears popup data when closed.
function NS:StaticPopupOnHide ()
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
		if ( Size > NS.SendNoticeThreshold ) then
			_DevPad.Print( L.SEND_LARGE_FORMAT:format(
				Data.Name, Size / 1024, Data.Target ) );
		end
	end
	--- Sends the object to the given channel.
	local function SendBroadcast ( self, Channel )
		if ( NS.Selection ) then
			Send( NS.Selection, Channel, nil, _G[ Channel ] );
		end
	end
	--- Whispers the object to a player.
	function NS.Send:NameOnAccept ( Object )
		local Name = self.editBox:GetText():trim();
		if ( Name == "" ) then
			return true; -- Keep open
		elseif ( UnitIsUnit( Name, "player" ) ) then -- Direct copy
			local Copy = Object:Copy();
			Copy:SetName( L.COPY_OBJECTNAME_FORMAT:format( Object._Name ) );
			NS.Root:Insert( Copy );
		else
			Send( Object, "WHISPER", Name, Name );
		end
	end
	--- Accepts the typed name.
	function NS.Send:NameOnEnterPressed ()
		return self:GetParent().button1:Click();
	end
	--- Requests a player name to send to.
	local function SendToPlayer ( self )
		local Dialog = StaticPopup_Show( "_DEVPAD_SEND_PLAYER", nil, nil, NS.Selection );
		if ( Dialog ) then
			if ( UnitIsPlayer( "target" ) ) then
				Dialog.editBox:SetText( UnitName( "player" ) );
			end
			Dialog.editBox:SetFocus();
		end
	end
	local Dropdown = CreateFrame( "Frame", "_DevPadGUIListSendDropDown", NS.Send, "UIDropDownMenuTemplate" );
	local Menu = {
		{ text = PLAYER; func = SendToPlayer; arg1 = "WHISPER"; notCheckable = true; },
		{ text = PARTY; func = SendBroadcast; arg1 = "PARTY"; notCheckable = true; },
		{ text = RAID; func = SendBroadcast; arg1 = "RAID"; notCheckable = true; },
		{ text = GUILD; func = SendBroadcast; arg1 = "GUILD"; notCheckable = true; },
		{ text = OFFICER; func = SendBroadcast; arg1 = "OFFICER"; notCheckable = true; },
	};
	--- Opens a dropdown menu with potential object recipients.
	function NS.Send:OnClick ()
		-- Match chat colors
		for _, Info in ipairs( Menu ) do
			local Color = ChatTypeInfo[ Info.arg1 ];
			Info.colorCode = GUI.FormatColorCode( Color.r, Color.g, Color.b );
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
	function NS.Send:ReceiveOnAccept ( Object )
		Object:SetName( L.RECEIVE_OBJECTNAME_FORMAT:format( Object._Name, Object._Author ) );
		NS.Root:Insert( Object );
	end
	local Queue, Ignored = _DevPad.ReceiveQueue, _DevPad.ReceiveIgnored;
	--- Puts the author on the ignore list.
	function NS.Send:ReceiveOnIgnore ( Object )
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
	function NS:ObjectReceived ()
		self.Send:SetScript( "OnUpdate", OnUpdate );
	end
end
--- Deletes the object once confirmed.
function NS.Delete:OnAccept ( Object )
	if ( Object._Parent ) then
		Object._Parent:Remove( Object );
	end
	-- Note: Don't return anything, or the dialog won't hide afterwards.
end
--- Opens a confirmation to delete the selected object.
function NS.Delete:OnClick ()
	local Object = NS.Selection;
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
		if ( NS.Selection ) then -- Add just before selection
			NS.Selection._Parent:Insert( Object, NS.Selection:GetIndex() );
		else -- Default to end of list
			NS.Root:Insert( Object );
		end
		NS:SetSelection( Object );
		NS:SetRenaming( Object );
	end
	--- Creates a new script.
	function NS.NewScript:OnClick ()
		InsertObject( "Script" );
	end
	--- Creates a new folder.
	function NS.NewFolder:OnClick ()
		InsertObject( "Folder" );
	end
end


--- Stops renaming.
function NS.RenameEdit:OnEditFocusLost ()
	return NS:SetRenaming();
end
--- Saves the object's new name.
function NS.RenameEdit:OnEnterPressed ()
	NS.Renaming:SetName( self:GetText() );
	return self:ClearFocus();
end
do
	--- Waits one frame before moving the view in case the edit box was re-anchored.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		local Top = NS.ScrollChild:GetTop() - self:GetTop();
		local Bottom = Top + self:GetHeight();
		NS.ScrollFrame:SetVerticalScrollToCoord( Top, Bottom );
	end
	--- Scrolls the edit box into view while typing.
	function NS.RenameEdit:OnCursorChanged ()
		return self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Updates an object's name text.
function NS:ObjectSetName ( _, Object )
	if ( Object._ListButton ) then
		return Object._ListButton.Name:SetText( Object._Name );
	end
end
do
	local CreateFolderButton, CreateScriptButton;
	do
		local CreateButton;
		do
			--- Selects this button's object when clicked.
			local function ButtonOnClick ( self )
				if ( self.Object._Class == "Folder" ) then
					self.Object:SetClosed( not self.Object._Closed );
				end
				if ( NS:SetSelection( self.Object ) ) then
					PlaySound( "igMainMenuOptionCheckBoxOn" );
				end
			end
			--- Starts renaming the object when double clicked.
			local function ButtonOnDoubleClick ( self )
				ButtonOnClick( self );
				return NS:SetRenaming( self.Object );
			end
			--- Start moving the object on drag.
			local function ButtonOnDragStart ( self )
				return NS:SetDragging( self.Object );
			end
			--- Stop dragging the object.
			local function ButtonOnDragStop ( self )
				if ( NS.Dragging == self.Object ) then
					return NS:SetDragging();
				end
			end
			--- Stop dragging and deselect the object.
			local function ButtonOnHide ( self )
				ButtonOnDragStop( self );
				if ( NS.Selection == self.Object ) then
					return NS:SetSelection();
				end
			end
			--- @return A new generic list button.
			function CreateButton ()
				local Button = CreateFrame( "Button", nil, NS.ScrollChild );
				Button:Hide();
				Button:SetHeight( BUTTON_HEIGHT );
				Button:SetPoint( "LEFT", NS.ScrollFrame );
				Button:SetPoint( "RIGHT", NS.ScrollFrame );
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

			local Expand = NS.NewButton( Button.Visual, [[Interface\ACHIEVEMENTFRAME\UI-ACHIEVEMENT-PLUSMINUS]] );
			Button.Expand = Expand;
			Expand:SetSize( BUTTON_HEIGHT, BUTTON_HEIGHT );
			Expand:SetPoint( "LEFT" );
			Expand:SetScript( "OnClick", ExpandOnClick );

			Button.Name:SetFontObject( GameFontNormal );
			Button.Name:SetPoint( "LEFT", Expand, "RIGHT", INDENT_SIZE - BUTTON_HEIGHT, 0 );
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

			local AutoRun = NS.NewButton( Button.Visual, [[Interface\Archeology\ArchaeologyParts]] );
			Button.AutoRun = AutoRun;
			AutoRun:SetPoint( "RIGHT" );
			AutoRun:SetSize( BUTTON_HEIGHT, BUTTON_HEIGHT * 0.8 );
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
	local UnusedButtons = {
		[ "Folder" ] = setmetatable( {}, { __call = CreateFolderButton; } );
		[ "Script" ] = setmetatable( {}, { __call = CreateScriptButton; } );
	};

	--- Shows or hides an object's button.
	local function ObjectButtonUpdateVisible ( Object )
		local Button = Object._ListButton;
		if ( Button ) then
			return Button[ Object:IsHidden() and "Hide" or "Show" ]( Button );
		end
	end
	--- Assigns a button to a new script or folder.
	local function ObjectButtonAssign ( Object )
		local Button, Unused = Object._ListButton, UnusedButtons[ Object._Class ];
		if ( not Button and Unused ) then -- Known class and not already assigned
			Button = next( Unused ) or Unused();
			Unused[ Button ] = nil;
			Object._ListButton, Button.Object = Button, Object;

			NS:ObjectSetName( nil, Object );
			if ( Object._Class == "Script" ) then
				NS:ScriptSetAutoRun( nil, Object );
			elseif ( Object._Class == "Folder" ) then
				NS:FolderSetClosed( nil, Object );
			end
		end
		ObjectButtonUpdateVisible( Object );
	end
	--- Updates the tree view when an object gets added to a folder.
	function NS:FolderInsert ( _, Folder, Object )
		if ( self.Root:Contains( Object ) ) then
			ObjectButtonAssign( Object );
			if ( Object._Class == "Folder" ) then -- Also assign child buttons
				for Child in Object:IterateChildren() do
					ObjectButtonAssign( Child );
				end
			end
			if ( not Object:IsHidden() ) then
				return self:Update();
			end
		elseif ( Object._ListButton ) then -- Removed from root
			return self:FolderRemove( nil, Folder, Object );
		end
	end

	--- Reclaims a script or folder button for reuse.
	local function ObjectButtonRecycle ( Object )
		local Button = Object._ListButton;
		Button:Hide();
		Button.Visual:SetAlpha( 1 ); -- Undo fading from search module
		if ( NS.Edited:GetParent() == Button ) then
			NS:EditorSetScriptObject();
		end
		Object._ListButton, Button.Object = nil;
		UnusedButtons[ Object._Class ][ Button ] = true;
	end
	--- Updates the tree view when an object gets removed from a folder.
	function NS:FolderRemove ( _, Folder, Object )
		if ( Object._ListButton ) then
			ObjectButtonRecycle( Object );
			if ( Object._Class == "Folder" ) then
				for Child in Object:IterateChildren() do
					ObjectButtonRecycle( Child );
				end
			end
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
	--- Updates all visible descendants of Folder.
	local function UpdateVisibleChildren ( Folder )
		for Index, Child in ipairs( Folder ) do
			ObjectButtonUpdateVisible( Child );
			if ( Child._Class == "Folder" and not Child._Closed ) then
				UpdateVisibleChildren( Child );
			end
		end
	end
	--- Redraws a folder when it opens or closes.
	function NS:FolderSetClosed ( _, Folder )
		local Button = Folder._ListButton;
		if ( Button ) then
			if ( Folder._Closed ) then
				SetTexCoords( Button.Expand, 0, 0.5, 0.5, 0.75 );
			else
				SetTexCoords( Button.Expand, 0, 0.5, 0.75, 1 );
			end
		end
		if ( Folder == self.Root
			or ( Button and not Folder:IsHidden() ) -- Contents visible
		) then
			UpdateVisibleChildren( Folder );
			return self:Update();
		end
	end
end
--- Updates Script's autorun indicator.
function NS:ScriptSetAutoRun ( _, Script )
	if ( Script._ListButton ) then
		local AutoRun = Script._ListButton.AutoRun;
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
--- Adds a highlight to scripts open for editing.
function NS:EditorSetScriptObject ( _, Script )
	local Button, Edited = Script and Script._ListButton, self.Edited;
	if ( Button ) then
		Edited:SetParent( Button );
		Edited:SetAllPoints();
		Edited:Show();
	else
		Edited:Hide();
		Edited:SetParent( self );
	end
end


function NS:OnShow ()
	PlaySound( "igSpellBookOpen" );
end
--- Closes open scripts and cancels pending actions.
function NS:OnHide ()
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




GUI.Dialog.StickyFrames[ "List" ] = NS;
NS:SetScript( "OnShow", NS.OnShow );
NS:SetScript( "OnHide", NS.OnHide );
NS.Title:SetText( L.LIST_TITLE );
NS.Title:SetJustifyH( "LEFT" );
NS:SetMinResize( 46 + NS.Title:GetStringWidth(), 100 );

NS.ScrollChild:SetSize( 1, 1 );
NS.ScrollFrame:SetScrollChild( NS.ScrollChild );

--- @return A new title button.
local function SetupTitleButton ( Button, TooltipText )
	NS:AddTitleButton( Button, -2 );
	Button:SetScript( "OnClick", Button.OnClick );
	Button:SetMotionScriptsWhileDisabled( true );
	Button.tooltipText = TooltipText;
end
SetupTitleButton( NS.Send, L.SEND );
SetupTitleButton( NS.Delete, L.DELETE );
SetupTitleButton( NS.NewScript, L.SCRIPT_NEW );
SetupTitleButton( NS.NewFolder, L.FOLDER_NEW );

StaticPopupDialogs[ "_DEVPAD_DELETE_CONFIRM" ] = {
	text = L.DELETE_CONFIRM_FORMAT;
	button1 = YES;
	button2 = NO;
	OnAccept = NS.Delete.OnAccept;
	OnHide = NS.StaticPopupOnHide;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
	showAlert = true;
};
local Send = NS.Send;
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
	OnHide = NS.StaticPopupOnHide;
	timeout = 0;
	hideOnEscape = true;
	whileDead = true;
	showAlertGear = true;
	interruptCinematic = true;
	notClosableByLogout = true;
};

-- Object renaming edit box
local Rename = NS.RenameEdit;
Rename:Hide();
Rename:SetAutoFocus( false );
Rename:SetScript( "OnEnterPressed", Rename.OnEnterPressed );
Rename:SetScript( "OnEscapePressed", Rename.ClearFocus );
Rename:SetScript( "OnEditFocusGained", Rename.HighlightText );
Rename:SetScript( "OnEditFocusLost", Rename.OnEditFocusLost );
Rename:SetScript( "OnCursorChanged", Rename.OnCursorChanged );

-- Highlight for script open in editor
local Edited = NS.Edited;
Edited:Hide();
Edited:SetTexture( [[Interface\ACHIEVEMENTFRAME\UI-Achievement-Category-Highlight]] );
Edited:SetBlendMode( "ADD" );
Edited:SetTexCoord( 0.029, 0.635, 0.149, 0.733 );
Edited:SetAlpha( 0.5 );

_DevPad.RegisterCallback( NS, "ObjectSetName" );
_DevPad.RegisterCallback( NS, "ObjectReceived" );
_DevPad.RegisterCallback( NS, "FolderInsert" );
_DevPad.RegisterCallback( NS, "FolderRemove" );
_DevPad.RegisterCallback( NS, "FolderSetClosed" );
_DevPad.RegisterCallback( NS, "ScriptSetAutoRun" );
GUI.RegisterCallback( NS, "ListSetSelection" );
GUI.RegisterCallback( NS, "EditorSetScriptObject" );

NS:Unpack( {} ); -- Default position/size

-- Synchronize with _DevPad
NS:SetRoot( _DevPad.FolderRoot );
NS:ListSetSelection(); -- Update title buttons
NS:ObjectReceived(); -- Handle objects received before GUI loaded
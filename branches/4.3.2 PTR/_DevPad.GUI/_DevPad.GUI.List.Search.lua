--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.List.Search.lua - Adds a script text search box to the list.   *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );

local NS = CreateFrame( "EditBox", "_DevPadGUIListSearch", GUI.List.Bottom, "InputBoxTemplate" );
GUI.List.Search = NS;

NS.InactiveAlpha = 0.5; -- EditBox transparency when not searching
NS.MismatchAlpha = 0.5;

local UPDATE_INTERVAL = 0.25; -- Update rate of list item highlighting




do
	local Escapes = { a = "\a"; b = "\b"; f = "\f"; n = "\n"; r = "\r"; t = "\t"; v = "\v"; };
	--- Unescapes escape sequences found by gsub.
	local function UnescapeGsub ( Character )
		return Escapes[ Character ] or Character; -- Use literal character for unrecognized escapes
	end
	--- Sets the pattern to search for and highlights list matches, or stops searching.
	-- @param PatternEscaped  Pattern to search for in scripts, or an empty string
	--   to stop.  Backslashes must be escaped.
	-- @return True if search pattern changed.
	function NS:SetPattern ( PatternEscaped )
		local Pattern = PatternEscaped ~= "" and PatternEscaped:gsub( [[\(.)]], UnescapeGsub );
		if ( self.Pattern ~= Pattern ) then
			if ( self.Pattern == false ) then
				_DevPad.RegisterCallback( self, "FolderInsert", "Update" );
				_DevPad.RegisterCallback( self, "FolderRemove", "Update" );
				_DevPad.RegisterCallback( self, "ScriptSetText" );
				GUI.RegisterCallback( self, "ListSetRoot", "Update" );
			end
			self.Pattern = Pattern;
			self:SetText( PatternEscaped:gsub( "|", "||" ) );
			if ( Pattern ) then
				self:SetAlpha( 1 );
				self:Update();
			else
				_DevPad.UnregisterCallback( self, "FolderInsert" );
				_DevPad.UnregisterCallback( self, "FolderRemove" );
				_DevPad.UnregisterCallback( self, "ScriptSetText" );
				GUI.UnregisterCallback( self, "ListSetRoot" );
				if ( not self:HasFocus() ) then
					self:SetAlpha( self.InactiveAlpha );
				end
				for Child in GUI.List.Root:IterateChildren() do
					Child._ListButton.Visual:SetAlpha( 1 );
				end
			end
			return true;
		end
	end
end
do
	local ipairs, pcall, strfind = ipairs, pcall, string.find;
	--- Recursively highlights folders if any of their children match.
	-- @return The number of matches found within Folder.
	local function UpdateFolder ( Folder )
		local Matches = 0;
		for _, Child in ipairs( Folder ) do
			if ( Child._Class == "Folder" ) then
				Matches = Matches + UpdateFolder( Child );
			elseif ( Child._Class == "Script" ) then
				-- Don't break with invalid, partially typed patterns
				local Valid, Match = pcall( strfind, Child._Text, NS.Pattern );
				Match = Valid and Match ~= nil; -- Valid pattern too
				if ( Match ) then
					Matches = Matches + 1;
				end
				Child._ListButton.Visual:SetAlpha( Match and 1 or NS.MismatchAlpha );
			end
		end
		if ( Folder._ListButton ) then -- Not root
			Folder._ListButton.Visual:SetAlpha( Matches > 0 and 1 or NS.MismatchAlpha );
		end
		return Matches;
	end

	local Timer = NS:CreateAnimationGroup();
	Timer:CreateAnimation( "Animation" ):SetDuration( UPDATE_INTERVAL );
	--- Updates the search highlight as soon as the timer starts/restarts.
	Timer:SetScript( "OnPlay", function ( self )
		self.Pending = nil;
		if ( not NS.Pattern ) then
			return self:Stop(); -- Reset cooldown
		end
		return UpdateFolder( GUI.List.Root );
	end );
	--- Refilter after the cooldown if requested since the last update.
	Timer:SetScript( "OnFinished", function ( self )
		if ( self.Pending ) then
			return self:Play(); -- Restart
		end
	end );
	--- Waits one frame before updating search highlights.
	-- This delay allows the list to assign buttons, and prevents the update from
	--   only catching the first change when many occur at once.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		Timer.Pending = true;
		return Timer:Play();
	end
	--- Updates search match highlights.
	function NS:Update ()
		if ( self.Pattern ) then
			self:SetScript( "OnUpdate", OnUpdate );
		end
	end
end


do
	--- Called using pcall to catch errors from invalid search patterns.
	local function NextMatch ( self, Script, Cursor, Reverse )
		if ( Reverse ) then
			local End, Start = 0;
			local StartLast, EndLast;
			while ( End and End <= Cursor ) do
				StartLast, EndLast = Start, End;
				Start, End = Script._Text:find( self.Pattern, End + 1 );
				if ( Start and Start > End ) then
					return; -- Matched an empty string, which will cause an infinite loop
				end
			end
			return StartLast, EndLast;
		else
			return Script._Text:find( self.Pattern, Cursor + 1 );
		end
	end
	--- Gets the position of the next match within a given script.
	-- @param Script  Script to search within.
	-- @param Cursor  Cursor position to start from.
	-- @param Reverse  True to find the previous match.
	-- @return (Start position, End position), or nil if no match.
	function NS:NextMatch ( Script, Cursor, Reverse )
		local Success, Start, End = pcall( NextMatch, self, Script, Cursor, Reverse );
		if ( Success and Start ) then
			return Start - 1, End;
		end
	end
end
--- Gets the position of the next match, possibly wrapping around.
-- @see NS:NextMatch
function NS:NextMatchWrap ( Script, Cursor, Reverse )
	local Start, End = self:NextMatch( Script, Cursor, Reverse );
	if ( not Start ) then
		Cursor = Reverse and #Script._Text or 0;
		Start, End = self:NextMatch( Script, Cursor, Reverse );
	end
	return Start, End;
end
do
	--- @return Script within Root at or after Start, or nil if no scripts found.
	local function NextScript ( Root, Start, Direction )
		local Object = Start;
		repeat
			if ( Object._Class == "Script" and Root:Contains( Object ) ) then
				return Object;
			end
			Object = Object[ Direction ];
		until ( Object == Start );
	end
	--- Gets the position of the next match, cycling through all scripts for a match.
	-- @see NS:NextMatch
	function NS:NextMatchGlobal ( Script, Cursor, Reverse )
		local Direction = Reverse and "_Previous" or "_Next";
		if ( not Script ) then
			Script = NextScript( GUI.List.Root, GUI.List.Selection or GUI.List.Root, Direction );
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
			Script = NextScript( GUI.List.Root, Script[ Direction ], Direction );
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


--- Lights up search box while typing.
function NS:OnEditFocusGained ()
	self:HighlightText();
	self:SetAlpha( 1 );
end
--- Dims search box if no longer searching.
function NS:OnEditFocusLost ()
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
--- Refilters the list when the search pattern changes.
function NS:OnTextChanged ()
	return self:SetPattern( self:GetText():gsub( "||", "|" ) );
end
--- Builds a tooltip under the edit box so it doesn't cover the list.
function NS:OnEnter ()
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint( "TOPLEFT", self, "BOTTOMLEFT" );
	GameTooltip:SetOwner( self, "ANCHOR_PRESERVE" );
	GameTooltip:SetText( GUI.L.SEARCH_DESC, nil, nil, nil, nil, 1 );
end
--- Updates match highlight when text changes.
function NS:ScriptSetText ( _, Script )
	if ( Script._ListButton ) then
		return self:Update();
	end
end
do
	--- Highlights the given position and moves the cursor to End.
	local function HighlightMatch ( self, Start, End )
		-- Note: Start and End positions are intentionally left unvalidated, since
		--   validating them would change the displayed result.  
		if ( End ) then
			self:ScrollToNextCursorPosition();
			self:SetCursorPositionUnescaped( End );
		end
		self:HighlightTextUnescaped( Start or 0, End or 0 );
	end
	--- Jumps to next/previous search result.
	function NS:OnEnterPressed ()
		if ( self.Pattern ) then
			local Script, Cursor, Reverse = GUI.Editor.Script, 0, IsShiftKeyDown();
			if ( Script ) then
				Cursor = GUI.Editor.Edit:GetCursorPositionUnescaped();
				if ( Reverse and Cursor > 0 ) then
					Cursor = Cursor - 1;
				end
			end
			local ScriptNew, Start, End = self:NextMatchGlobal( Script, Cursor, Reverse );
			if ( ScriptNew ) then
				GUI.Editor:SetScriptObject( ScriptNew );
			end
			HighlightMatch( GUI.Editor.Edit, Start, End );
		else
			return self:ClearFocus();
		end
	end
	--- Jump to next/previous search result.
	function GUI.Editor.Shortcuts:F3 ()
		if ( NS.Pattern ) then
			local Cursor, Reverse = GUI.Editor.Edit:GetCursorPositionUnescaped(), IsShiftKeyDown();
			if ( Reverse and Cursor > 0 ) then
				Cursor = Cursor - 1;
			end
			HighlightMatch( GUI.Editor.Edit, NS:NextMatchWrap( GUI.Editor.Script, Cursor, Reverse ) );
		end
	end
end
--- Focus search edit box.
function GUI.Editor.Shortcuts:F ()
	if ( IsControlKeyDown() ) then
		self:SetFocus( NS );
	end
end




GUI.List.Bottom:SetHeight( 24 );
NS:SetHeight( 20 );
NS:SetPoint( "BOTTOMLEFT", 12, 2 );
NS:SetPoint( "RIGHT", -10, 0 );
NS:SetAutoFocus( false );
NS:SetTextInsets( 12, 0, 0, 0 );
NS:SetFontObject( ChatFontSmall );
NS:SetScript( "OnEditFocusGained", NS.OnEditFocusGained );
NS:SetScript( "OnEditFocusLost", NS.OnEditFocusLost );
NS:SetScript( "OnEnterPressed", NS.OnEnterPressed );
NS:SetScript( "OnEscapePressed", NS.ClearFocus );
NS:SetScript( "OnTextChanged", NS.OnTextChanged );
NS:SetScript( "OnEnter", NS.OnEnter );
NS:SetScript( "OnLeave", GameTooltip_Hide );
local Icon = NS:CreateTexture( nil, "OVERLAY" );
Icon:SetPoint( "LEFT", 0, -2 );
Icon:SetSize( 14, 14 );
Icon:SetTexture( [[Interface\COMMON\UI-Searchbox-Icon]] );

NS:SetPattern( "" );
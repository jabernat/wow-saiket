--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.lua - Notepad for Lua scripts and mini-addons.                     *
  ****************************************************************************]]


local AddOnName, NS = ...;
_DevPad = NS;

NS.Frame = CreateFrame( "Frame" );
NS.Callbacks = LibStub( "CallbackHandler-1.0" ):New( NS );
NS.ReceiveQueue = {};
NS.ReceiveIgnored = { [ UnitName( "player" ):lower() ] = true; };

local COMM_PREFIX = "_DP";

local AceSerializer, AceComm = LibStub( "AceSerializer-3.0" ), LibStub( "AceComm-3.0" );




--- Prints a message in the default chat window.
function NS.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( NS.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
end
do
	--- Raises an error message when pcall fails.
	local function HandleError ( Success, ... )
		if ( not Success ) then
			geterrorhandler()( ... );
		end
		return Success, ...;
	end
	--- Throws a non-breaking error if a call fails.
	-- @return Success boolean prepended to Script's returns like pcall.
	function NS.SafeCall ( Script, ... )
		return HandleError( pcall( Script, ... ) );
	end
end


local RegisterClass;
do
	local ObjectMeta = { __index = {}; };
	--- @return True if Name changed.
	function ObjectMeta.__index:SetName ( Name )
		Name = type( Name ) == "string" and Name or "";
		if ( self._Name ~= Name ) then
			self._Name = Name;
			NS.Callbacks:Fire( "ObjectSetName", self );
			return true;
		end
	end
	--- Sends this object to other players over an addon comm channel.
	-- @see AceComm-3.0:SendCommMessage
	-- @return Number of bytes being transmitted.
	function ObjectMeta.__index:Send ( ... )
		local Data = AceSerializer:Serialize( "Object", self:Pack() );
		AceComm:SendCommMessage( COMM_PREFIX, Data, ... );
		return #Data;
	end
	-- @return A copy of this object.
	function ObjectMeta.__index:Copy ()
		local Object = self:New();
		Object:Unpack( self:Pack() );
		return Object;
	end
	--- @return Index of this object in its parent, or nil if not found.
	function ObjectMeta.__index:GetIndex ()
		local Parent = self._Parent;
		if ( Parent ) then
			for Index = 1, #Parent do
				if ( Parent[ Index ] == self ) then
					return Index;
				end
			end
		end
	end
	do
		local Parts = {};
		--- @return List of path name parts pointing to this object.
		function ObjectMeta.__index:GetPath ()
			wipe( Parts );
			while ( self and self._Parent ) do -- Leave the root's name out
				tinsert( Parts, 1, self._Name );
				self = self._Parent;
			end
			return unpack( Parts );
		end
	end
	--- Gets an object by path relative to this object.
	-- @param ...  List of path parts.  Values of true go up like URLs' "..".
	-- @return Found object, or nil if not found.
	function ObjectMeta.__index:GetRelObject ( Name, ... )
		if ( not Name ) then
			return self;
		elseif ( Name == true ) then
			if ( self._Parent ) then
				return self._Parent:GetRelObject( ... );
			end
		elseif ( self._Class == "Folder" ) then
			for _, Child in ipairs( self ) do
				if ( Name == Child._Name ) then
					return Child:GetRelObject( ... );
				end
			end
		end
	end
	--- @return True if this object is in a closed folder.
	function ObjectMeta.__index:IsHidden ()
		local Parent = self._Parent;
		while ( Parent ) do
			if ( Parent._Closed ) then
				return true;
			end
			Parent = Parent._Parent;
		end
	end

	local Classes = {};
	--- Registers a new class to a given Name.
	-- @return Metatable to use for class instances.
	function RegisterClass ( Name )
		local Meta = { __index = setmetatable( { _Class = Name; }, ObjectMeta ); };
		Classes[ Name ] = Meta;
		return Meta;
	end
	--- @return The class' metatable index table if the class exists.
	function NS:GetClass ( Name )
		if ( Classes[ Name ] ) then
			return Classes[ Name ].__index;
		end
	end
end


do
	local FolderMeta = RegisterClass( "Folder" );
	do
		--- @return Last descendant of Object.
		local function GetLastDescendant ( Object )
			while ( Object._Class == "Folder" and #Object > 0 ) do
				Object = Object[ #Object ];
			end
			return Object;
		end
		local FireEvents = true;
		--- Adds a child object to this folder.
		-- @return True if child moved successfully.
		function FolderMeta.__index:Insert ( Object, Index )
			Index = Index or ( self ~= Object._Parent and #self + 1 or #self );
			if ( ( Object._Parent ~= self or Index ~= Object:GetIndex() ) -- Moved
				and not ( Object == self
					or ( Object._Class == "Folder" and Object:Contains( self ) ) ) -- Not circular
			) then
				if ( Object._Parent ) then
					FireEvents = false; -- Don't fire a FolderRemoved event before inserts
					Object._Parent:Remove( Object );
					FireEvents = true;
				end

				Object._Parent = self;
				tinsert( self, Index, Object );
				-- Doubly-circular linked list of objects in tree
				local Previous = Index == 1 and self or GetLastDescendant( self[ Index - 1 ] );
				local Next, ObjectLast = Previous._Next, Object._Previous;
				Previous._Next, Next._Previous = Object, ObjectLast;
				ObjectLast._Next, Object._Previous = Next, Previous;

				NS.Callbacks:Fire( "FolderInsert", self, Object, Index );
				return true;
			end
		end
		--- @return True if child removed successfully.
		function FolderMeta.__index:Remove ( Object )
			if ( Object._Parent == self ) then
				tremove( self, assert( Object:GetIndex(),
					"Child not found in parent folder." ) )._Parent = nil;
				local ObjectLast = GetLastDescendant( Object );
				local Previous, Next = Object._Previous, ObjectLast._Next;
				Previous._Next, Next._Previous = Next, Previous;
				ObjectLast._Next, Object._Previous = Object, ObjectLast;

				if ( FireEvents ) then
					NS.Callbacks:Fire( "FolderRemove", self, Object );
				end
				return true;
			end
		end
	end
	--- @return True if Closed state changed.
	function FolderMeta.__index:SetClosed ( Closed )
		Closed = not not Closed;
		if ( self._Closed ~= Closed ) then
			self._Closed = Closed;
			NS.Callbacks:Fire( "FolderSetClosed", self );
			return true;
		end
	end
	--- @return True if this folder contains Object.
	function FolderMeta.__index:Contains ( Object )
		local Parent = Object._Parent;
		while ( Parent ) do
			if ( self == Parent ) then
				return true;
			end
			Parent = Parent._Parent;
		end
	end
	do
		--- @return The next child object of Folder.
		local function NextChild ( Folder, Child )
			Child = Child._Next;
			if ( Folder:Contains( Child ) ) then
				return Child;
			end
		end
		--- @return An iterator function with values to iterate over all of this folder's children.
		-- @usage for Child in Folder:IterateChildren() do ... end
		function FolderMeta.__index:IterateChildren ()
			return NextChild, self, self;
		end
	end
	--- @return Table containing unique settings for this folder and its children.
	function FolderMeta.__index:Pack ()
		local Settings = {
			Class = self._Class;
			Name = self._Name;
			Closed = self._Closed or nil;
		};
		for Index, Child in ipairs( self ) do
			Settings[ Index ] = Child:Pack();
		end
		return Settings;
	end
	--- Synchronizes this folder with values from Folder:Pack.
	function FolderMeta.__index:Unpack ( Settings )
		assert( Settings.Class == self._Class, "Unpack class mismatch." );
		self:SetName( Settings.Name );
		self:SetClosed( Settings.Closed );
		-- Remove old children
		for Index = #self, 1, -1 do
			self:Remove( self[ Index ] );
		end
		for Index, Child in ipairs( Settings ) do
			if ( type( Child ) == "table" ) then
				local Class = NS:GetClass( Child.Class );
				if ( Class ) then
					local Object = Class:New();
					Object:Unpack( Child );
					self:Insert( Object );
				end
			end
		end
	end
	--- @return New Folder instance.
	function FolderMeta.__index:New ()
		local Folder = setmetatable( {}, FolderMeta );
		Folder._Previous, Folder._Next = Folder, Folder;
		Folder:SetName();
		Folder:SetClosed( false );
		return Folder;
	end
end


do
	local ScriptMeta = RegisterClass( "Script" );
	--- Sets the script text and flags it for recompilation.
	-- @return True if Text changed.
	function ScriptMeta.__index:SetText ( Text )
		Text = type( Text ) == "string" and Text or "";
		if ( self._Text ~= Text ) then
			self._Text, self._TextChanged = Text, true;
			NS.Callbacks:Fire( "ScriptSetText", self );
			return true;
		end
	end
	--- Enables/disables running this script on login.
	-- @return True if AutoRun flag changed.
	function ScriptMeta.__index:SetAutoRun ( AutoRun )
		AutoRun = not not AutoRun;
		if ( self._AutoRun ~= AutoRun ) then
			self._AutoRun = AutoRun;
			NS.Callbacks:Fire( "ScriptSetAutoRun", self );
			return true;
		end
	end
	--- Enables/disables Lua mode for this script in the editor.
	-- @return True if Lua mode flag changed.
	function ScriptMeta.__index:SetLua ( Lua )
		Lua = not not Lua;
		if ( self._Lua ~= Lua ) then
			self._Lua = Lua;
			NS.Callbacks:Fire( "ScriptSetLua", self );
			return true;
		end
	end
	--- Executes this script.
	-- @param ...  Arguments to pass to the script.
	-- @return Any values returned from the script.
	function ScriptMeta.__index:Run ( ... )
		if ( self._TextChanged ) then -- Recompile
			local Chunk, ErrorMessage = loadstring( self._Text, self._Name );
			if ( not Chunk ) then
				error( ErrorMessage, 0 ); -- 0 keeps _DevPad's name out of the error message
			end
			self._Chunk, self._TextChanged = Chunk;
		end
		return self:_Chunk( ... );
	end
	--- Shortcut for Script:Run.
	function ScriptMeta:__call ( ... )
		return self:Run( ... );
	end
	--- @return Table containing unique settings for this script.
	function ScriptMeta.__index:Pack ()
		return {
			Class = self._Class;
			Name = self._Name;
			Text = self._Text;
			AutoRun = self._AutoRun or nil;
			Lua = self._Lua or nil;
		};
	end
	--- Synchronizes this script with values from Script:Pack.
	function ScriptMeta.__index:Unpack ( Settings )
		assert( Settings.Class == self._Class, "Unpack class mismatch." );
		self:SetName( Settings.Name );
		self:SetText( Settings.Text );
		self:SetAutoRun( Settings.AutoRun );
		self:SetLua( Settings.Lua );
	end
	--- @return New Script instance.
	function ScriptMeta.__index:New ()
		local Script = setmetatable( {}, ScriptMeta );
		Script._Previous, Script._Next = Script, Script;
		Script:SetName();
		Script:SetText();
		Script:SetAutoRun( false );
		Script:SetLua( true );
		return Script;
	end
end


--- Fires a callback for each script in Folder.
-- @param Callback  Function or method name.
-- @param ...  Extra args passed after script to Callback.
function NS:IterateScripts ( Folder, Callback, ... )
	for Child in Folder:IterateChildren() do
		if ( Child._Class == "Script" ) then
			( Child[ Callback ] or Callback )( Child, ... );
		end
	end
end
do
	local Matches = {};
	--- Finds Script objects by name.
	-- @param Pattern  Name pattern to match by.
	-- @param Folder  Optional folder to search in, otherwise FolderRoot is used.
	-- @return Each matching script, or nil if none found.
	function NS:FindScripts ( Pattern, Folder )
		wipe( Matches );
		for Child in ( Folder or self.FolderRoot ):IterateChildren() do
			if ( Child._Class == "Script" and Child._Name:match( Pattern ) ) then
				Matches[ #Matches + 1 ] = Child;
			end
		end
		return unpack( Matches );
	end
end
--- Gets an object by path from the folder root.
-- @see Object:GetRelObject
function NS:GetAbsObject ( ... )
	return self.FolderRoot:GetRelObject( ... );
end


do
	local SafeNameReplacements = {
		[ "|" ] = "||";
		[ "\n" ] = [[\n]];
		[ "\r" ] = [[\r]];
	};
	local ReopenPrinted = false;
	--- Receives and validates objects sent from other players.
	function NS:OnCommReceived ( Prefix, Text, Channel, Author )
		if ( self.ReceiveIgnored[ Author:lower() ] ) then
			return;
		end
		local Success, MessageType, Settings = AceSerializer:Deserialize( Text );
		if ( not Success or MessageType ~= "Object" or type( Settings ) ~= "table" ) then
			return;
		end
		local Class = self:GetClass( Settings.Class );
		if ( not Class ) then
			return;
		end
		local Object = Class:New();
		if ( not pcall( Object.Unpack, Object, Settings ) ) then
			return;
		end

		PlaySound( "Glyph_MinorCreate" );
		local SafeName = Object._Name:gsub( "[|\r\n]", SafeNameReplacements );
		self.Print( self.L.RECEIVE_MESSAGE_FORMAT:format( Author, SafeName ) );
		if ( not ReopenPrinted and not ( self.GUI and self.GUI.List:IsVisible() ) ) then
			ReopenPrinted = true;
			self.Print( self.L.RECEIVE_MESSAGE_REOPEN, HIGHLIGHT_FONT_COLOR );
		end

		Object._Channel, Object._Author = Channel, Author;
		-- Sanitize scripts
		if ( Object._Class == "Script" ) then
			Object:SetAutoRun( false );
		elseif ( Object._Class == "Folder" ) then
			for Child in Object:IterateChildren() do
				if ( Child._Class == "Script" ) then
					Child:SetAutoRun( false );
				end
			end
		end
		tinsert( self.ReceiveQueue, Object );
		self.Callbacks:Fire( "ObjectReceived", Object );
	end
end
--- Load saved variables and run auto-run scripts.
function NS.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local Options = _DevPadOptions;
		local Scripts = ( Options and Options.Scripts ) or NS.DefaultScripts;
		if ( Scripts ) then
			NS.FolderRoot:Unpack( Scripts );
		end
		for Object in NS.FolderRoot:IterateChildren() do
			if ( Object._Class == "Script" and Object._AutoRun ) then
				NS.SafeCall( Object );
			end
		end
		AceComm.RegisterComm( NS, COMM_PREFIX );
		-- Replace settings last in case of errors loading them
		self:RegisterEvent( "PLAYER_LOGOUT" );
		--_DevPadOptions = nil; -- GC options
		NS.DefaultScripts = nil;
	end
end
--- Save settings before exiting.
function NS.Frame:PLAYER_LOGOUT ()
	_DevPadOptions = {
		Scripts = NS.FolderRoot:Pack();
	};
end
--- Global event handler.
function NS.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end


--- Slash command handler to run scripts by name pattern.
function NS.SlashCommand ( Input )
	local Pattern = Input:trim();
	if ( Pattern == "" ) then
		local Loaded, ErrorReason = LoadAddOn( "_DevPad.GUI" );
		if ( Loaded ) then
			local List = NS.GUI.List;
			if ( List:IsVisible() ) then
				List:Hide();
			else
				List:Show();
			end
		else
			NS.Print( NS.L.SLASH_GUIERROR_FORMAT:format(
				_G[ "ADDON_"..ErrorReason ] ), RED_FONT_COLOR );
		end
	else
		local Script1, Script2 = NS:FindScripts( Pattern );
		if ( Script1 ) then
			if ( Script2 ) then -- Multiple matches for ambiguous pattern
				NS.Print( NS.L.SLASH_RUN_AMBIGUOUS_FORMAT:format( Pattern, Script1._Name ) );
			end
			return NS.SafeCall( Script1 );
		else
			NS.Print( NS.L.SLASH_RUN_MISSING_FORMAT:format( Pattern ), RED_FONT_COLOR );
		end
	end
end




setmetatable( NS, { __call = NS.GetAbsObject; } );
NS.FolderRoot = NS:GetClass( "Folder" ):New();

NS.Frame:SetScript( "OnEvent", NS.Frame.OnEvent );
NS.Frame:RegisterEvent( "ADDON_LOADED" );

SlashCmdList[ "_DEVPAD" ] = NS.SlashCommand;
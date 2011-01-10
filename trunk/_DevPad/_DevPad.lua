--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.lua - Notepad for Lua scripts and mini-addons.                     *
  ****************************************************************************]]


local AddOnName, me = ...;
_DevPad = me;

me.Frame = CreateFrame( "Frame" );
me.Callbacks = LibStub( "CallbackHandler-1.0" ):New( me );
me.ReceiveQueue, me.ReceiveIgnored = {}, {};

me.COMM_PREFIX = "_DP";

local AceSerializer, AceComm = LibStub( "AceSerializer-3.0" ), LibStub( "AceComm-3.0" );




--- Prints a message in the default chat window.
function me.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( me.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
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
	function me.SafeCall ( Script, ... )
		return HandleError( pcall( Script, ... ) );
	end
end


local RegisterClass;
do
	local ObjectMeta = { __index = {}; };
	--- @return True if Name changed.
	function ObjectMeta.__index:SetName ( Name )
		Name = type( Name ) == "string" and Name or "";
		if ( self.Name ~= Name ) then
			self.Name = Name;
			me.Callbacks:Fire( "ObjectSetName", self );
			return true;
		end
	end
	--- Sends this object to other players over an addon comm channel.
	-- @see AceComm-3.0:SendCommMessage
	-- @return Number of bytes being transmitted.
	function ObjectMeta.__index:Send ( ... )
		local Data = AceSerializer:Serialize( "Object", self:Pack() );
		AceComm:SendCommMessage( me.COMM_PREFIX, Data, ... );
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
		local Parent = self.Parent;
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
			while ( self and self.Parent ) do -- Leave the root's name out
				tinsert( Parts, 1, self.Name );
				self = self.Parent;
			end
			return unpack( Parts );
		end
	end
	--- Gets an object by path relative to this object.
	-- @param ...  List of path parts.  Values of true go up like URLs' "..".
	-- @return Found object, or nil if not found.
	function ObjectMeta.__index:GetRelObject ( ... )
		local Object, Parent = self;
		for Index = 1, select( "#", ... ) do
			local Name = select( Index, ... );
			if ( Name == true ) then -- Up/".."
				Object = Object.Parent;
			else
				Parent, Object = Object;
				if ( Parent.Class == "Folder" ) then
					for _, Child in ipairs( Parent ) do
						if ( Name == Child.Name ) then
							Object = Child;
							break;
						end
					end
				end
				if ( not Object ) then
					return;
				end
			end
		end
		return Object;
	end
	--- @return True if this object is in a closed folder.
	function ObjectMeta.__index:IsHidden ()
		local Parent = self.Parent;
		while ( Parent ) do
			if ( Parent.Closed ) then
				return true;
			end
			Parent = Parent.Parent;
		end
	end

	local Classes = {};
	--- Registers a new class to a given Name.
	-- @return Metatable to use for class instances.
	function RegisterClass ( Name )
		local Meta = { __index = setmetatable( { Class = Name; }, ObjectMeta ); };
		Classes[ Name ] = Meta;
		return Meta;
	end
	--- @return The class' metatable index table if the class exists.
	function me:GetClass ( Name )
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
			while ( Object.Class == "Folder" and #Object > 0 ) do
				Object = Object[ #Object ];
			end
			return Object;
		end
		local FireEvents = true;
		--- Adds a child object to this folder.
		-- @return True if child moved successfully.
		function FolderMeta.__index:Insert ( Object, Index )
			Index = Index or ( self ~= Object.Parent and #self + 1 or #self );
			if ( ( Object.Parent ~= self or Index ~= Object:GetIndex() ) -- Moved
				and not ( Object == self
					or ( Object.Class == "Folder" and Object:Contains( self ) ) ) -- Not circular
			) then
				if ( Object.Parent ) then
					FireEvents = false; -- Don't fire a FolderRemoved event before inserts
					Object.Parent:Remove( Object );
					FireEvents = true;
				end
				Object.Parent = self;
				tinsert( self, Index, Object );

				-- Doubly-circular linked list of objects in tree
				Object.Previous = Index == 1 and self
					or GetLastDescendant( self[ Index - 1 ] );
				local ObjectLast = GetLastDescendant( Object );
				ObjectLast.Next = Object.Previous.Next;
				Object.Previous.Next = Object;
				ObjectLast.Next.Previous = ObjectLast;
				me.Callbacks:Fire( "FolderInsert", self, Object, Index );
				return true;
			end
		end
		--- @return True if child removed successfully.
		function FolderMeta.__index:Remove ( Object )
			if ( Object.Parent == self ) then
				local ObjectLast = GetLastDescendant( Object );
				ObjectLast.Next.Previous = Object.Previous;
				Object.Previous.Next = ObjectLast.Next;
				Object.Previous = ObjectLast;
				ObjectLast.Next = Object;
				tremove( self, assert( Object:GetIndex(), "Child not found in parent folder." ) ).Parent = nil;
				if ( FireEvents ) then
					me.Callbacks:Fire( "FolderRemove", self, Object );
				end
				return true;
			end
		end
	end
	--- @return True if Closed state changed.
	function FolderMeta.__index:SetClosed ( Closed )
		Closed = not not Closed;
		if ( self.Closed ~= Closed ) then
			self.Closed = Closed;
			me.Callbacks:Fire( "FolderSetClosed", self );
			return true;
		end
	end
	--- @return True if this folder contains Object.
	function FolderMeta.__index:Contains ( Object )
		local Parent = Object.Parent;
		while ( Parent ) do
			if ( self == Parent ) then
				return true;
			end
			Parent = Parent.Parent;
		end
	end
	--- @return Table containing unique settings for this folder and its children.
	function FolderMeta.__index:Pack ()
		local Settings = {
			Class = self.Class;
			Name = self.Name;
			Closed = self.Closed or nil;
		};
		for Index, Child in ipairs( self ) do
			Settings[ Index ] = Child:Pack();
		end
		return Settings;
	end
	--- Synchronizes this folder with values from Folder:Pack.
	function FolderMeta.__index:Unpack ( Settings )
		assert( Settings.Class == self.Class, "Unpack class mismatch." );
		self:SetName( Settings.Name );
		self:SetClosed( Settings.Closed );
		-- Remove old children
		for Index = #self, 1, -1 do
			self:Remove( self[ Index ] );
		end
		for Index, Child in ipairs( Settings ) do
			if ( type( Child ) == "table" ) then
				local Class = me:GetClass( Child.Class );
				if ( Class ) then
					local Object = Class:New();
					self:Insert( Object );
					Object:Unpack( Child );
				end
			end
		end
	end
	--- @return New Folder instance.
	function FolderMeta.__index:New ()
		local Folder = setmetatable( {}, FolderMeta );
		Folder.Previous, Folder.Next = Folder, Folder;
		Folder:SetName();
		Folder:SetClosed( false );
		return Folder;
	end
end


do
	local ScriptMeta = RegisterClass( "Script" );
	--- Sets the script chunk body and flags it for recompilation.
	-- @return True if Text changed.
	function ScriptMeta.__index:SetText ( Text )
		Text = type( Text ) == "string" and Text or "";
		if ( self.Text ~= Text ) then
			self.Text, self.TextChanged = Text, true;
			me.Callbacks:Fire( "ScriptSetText", self );
			return true;
		end
	end
	--- Enables/disables running this script on login.
	-- @return True if AutoRun flag changed.
	function ScriptMeta.__index:SetAutoRun ( AutoRun )
		AutoRun = not not AutoRun;
		if ( self.AutoRun ~= AutoRun ) then
			self.AutoRun = AutoRun;
			me.Callbacks:Fire( "ScriptSetAutoRun", self );
			return true;
		end
	end
	--- Enables/disables Lua syntax highlighting for this script in the editor.
	-- @return True if SyntaxHighlight flag changed.
	function ScriptMeta.__index:SetLua ( Lua )
		Lua = not not Lua;
		if ( self.Lua ~= Lua ) then
			self.Lua = Lua;
			me.Callbacks:Fire( "ScriptSetLua", self );
			return true;
		end
	end
	--- Executes this script.
	-- @param ...  Arguments to pass to the script.
	-- @return Any values returned from the script.
	function ScriptMeta.__index:Run ( ... )
		if ( self.TextChanged ) then -- Recompile
			self.Chunk = assert( loadstring( self.Text, self.Name ) );
			self.TextChanged = nil;
		end
		return self:Chunk( ... );
	end
	--- Shortcut for Script:Run.
	function ScriptMeta:__call ( ... )
		return self:Run( ... );
	end
	--- @return Table containing unique settings for this script.
	function ScriptMeta.__index:Pack ()
		return {
			Class = self.Class;
			Name = self.Name;
			Text = self.Text;
			AutoRun = self.AutoRun or nil;
			Lua = self.Lua or nil;
		};
	end
	--- Synchronizes this script with values from Script:Pack.
	function ScriptMeta.__index:Unpack ( Settings )
		assert( Settings.Class == self.Class, "Unpack class mismatch." );
		self:SetName( Settings.Name );
		self:SetText( Settings.Text );
		self:SetAutoRun( Settings.AutoRun );
		self:SetLua( Settings.Lua );
	end
	--- @return New Script instance.
	function ScriptMeta.__index:New ()
		local Script = setmetatable( {}, ScriptMeta );
		Script.Previous, Script.Next = Script, Script;
		Script:SetName();
		Script:SetText();
		Script:SetAutoRun( false );
		Script:SetLua( true );
		return Script;
	end
end


--- Fires a callback for each script in Object.
-- @param Callback  Function or method name.
-- @param ...  Extra args passed after Script to Callback.
function me:IterateScripts ( Object, Callback, ... )
	if ( Object.Class == "Script" ) then
		return ( Object[ Callback ] or Callback )( Object, ... );
	elseif ( Object.Class == "Folder" ) then
		for _, Child in ipairs( Object ) do
			self:IterateScripts( Child, Callback, ... );
		end
	end
end
do
	local Matches = {};
	--- Adds scripts to found list matched by name.
	local function Callback ( Script, Pattern )
		if ( Script.Name:match( Pattern ) ) then
			Matches[ #Matches + 1 ] = Script;
		end
	end
	--- Finds Script objects by name.
	-- @param Pattern  Name pattern to match by.
	-- @param Object  Optional object to search in, or FolderRoot if nil.
	-- @return Each matching script, or nil if none found.
	function me:FindScripts ( Pattern, Object )
		wipe( Matches );
		self:IterateScripts( Object or self.FolderRoot, Callback, Pattern );
		return unpack( Matches );
	end
end
--- Gets an object by path from the folder root.
-- @see Object:GetRelObject
function me:GetAbsObject ( ... )
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
	function me:OnCommReceived ( Prefix, Text, Channel, Author )
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
		local SafeName = Object.Name:gsub( "[|\r\n]", SafeNameReplacements );
		self.Print( self.L.RECEIVE_MESSAGE_FORMAT:format( Author, SafeName ) );
		if ( not ReopenPrinted and not ( self.GUI and self.GUI.List:IsVisible() ) ) then
			ReopenPrinted = true;
			self.Print( self.L.RECEIVE_MESSAGE_REOPEN, HIGHLIGHT_FONT_COLOR );
		end

		Object.Channel, Object.Author = Channel, Author;
		self:IterateScripts( Object, "SetAutoRun", false ); -- Sanitize scripts
		tinsert( self.ReceiveQueue, Object );
		self.Callbacks:Fire( "ObjectReceived", Object );
	end
end
--- Load saved variables and run auto-run scripts.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;


		local Options = _DevPadOptions;
		local Scripts = ( Options and Options.Scripts ) or me.DefaultScripts;
		me.DefaultScripts = nil;
		if ( Scripts ) then
			me.FolderRoot:Unpack( Scripts );
		end
		me:IterateScripts( me.FolderRoot, function ( Script )
			if ( Script.AutoRun ) then
				me.SafeCall( Script );
			end
		end );
		AceComm.RegisterComm( me, me.COMM_PREFIX );
		-- Replace settings last in case of errors loading them
		self:RegisterEvent( "PLAYER_LOGOUT" );
		--_DevPadOptions = nil; -- GC options
	end
end
--- Save settings before exiting.
function me.Frame:PLAYER_LOGOUT ()
	_DevPadOptions = {
		Scripts = me.FolderRoot:Pack();
	};
end
--- Global event handler.
function me.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end


--- Slash command handler to run scripts by name pattern.
function me.SlashCommand ( Input )
	local Pattern = Input:trim();
	if ( Pattern == "" ) then
		local Loaded, ErrorReason = LoadAddOn( "_DevPad.GUI" );
		if ( Loaded ) then
			ToggleFrame( me.GUI.List );
		else
			me.Print( me.L.SLASH_GUIERROR_FORMAT:format(
				_G[ "ADDON_"..ErrorReason ] ), RED_FONT_COLOR );
		end
	else
		local Script = me:FindScripts( Pattern );
		if ( Script ) then
			me.Print( me.L.SLASH_RUN_FORMAT:format( Script.Name ) );
			return me.SafeCall( Script );
		else
			me.Print( me.L.SLASH_RUN_MISSING_FORMAT:format( Pattern ), RED_FONT_COLOR );
		end
	end
end




setmetatable( me, { __call = me.GetAbsObject; } );
me.FolderRoot = me:GetClass( "Folder" ):New();

me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );

SlashCmdList[ "_DEVPAD" ] = me.SlashCommand;
--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.lua - Notepad for Lua scripts and mini-addons.                     *
  ****************************************************************************]]


local AddOnName, me = ...;
_DevPad = me;

me.Frame = CreateFrame( "Frame" );
me.Callbacks = LibStub( "CallbackHandler-1.0" ):New( me );

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


--- Fires a callback for each script in Folder.
-- If the callback returns a logically true value, iteration ends.
-- @param Folder  Optional sub-folder to iterate over.
-- @param ...  Extra args passed after Script to Callback.
-- @return The logically true value returned by the final callback call, if any.
function me:IterateScripts ( Folder, Callback, ... )
	if ( not Folder ) then
		Folder = self.FolderRoot;
	end
	for _, Child in ipairs( Folder ) do
		local Result;
		if ( Child.Class == "Folder" ) then
			Result = self:IterateScripts( Child, Callback, ... );
		elseif ( Child.Class == "Script" ) then
			Result = Callback( Child, ... );
		end
		if ( Result ) then
			return Result;
		end
	end
end
do
	--- Matches scripts by name.
	-- @see _DevPad:IterateScripts
	local function Callback ( Script, Pattern )
		if ( Script.Name:match( Pattern ) ) then
			return Script;
		end
	end
	--- Finds a Script object by name.
	-- @param Pattern  Name pattern to match by.
	-- @return The first matching script object found, or nil if none.
	function me:FindScript ( Pattern, Folder )
		return self:IterateScripts( Folder, Callback, Pattern );
	end
end
--- Gets an object by path from the folder root.
-- @see Object:GetRelObject
function me:GetAbsObject ( ... )
	return self.FolderRoot:GetRelObject( ... );
end


--- Receive objects from other players.
function me:OnCommReceived ( Prefix, Text, Channel, Author )
	local Success, MessageType, Settings = AceSerializer:Deserialize( Text );
	if ( Success and MessageType == "Object" and type( Settings ) == "table" ) then
		local Class = self:GetClass( Settings.Class );
		if ( Class ) then
			local Object = Class:New();
			local Success = pcall( Object.Unpack, Object, Settings );
			if ( Success ) then
				Object.Author = Author;
				-- Sanitize scripts
				if ( Object.Class == "Script" ) then
					Object:SetAutoRun( false );
				elseif ( Object.Class == "Folder" ) then
					self:IterateScripts( Object,
						self:GetClass( "Script" ).SetAutoRun, false );
				end
				self.Callbacks:Fire( "ObjectReceived", Object, Channel, Author );
			end
		end
	end
end
--- Load saved variables and run auto-run scripts.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;


		local Options = _DevPadOptions;
		if ( Options and Options.List ) then
			me.List:Unpack( Options.List );
		end
		me.Editor:Unpack( ( Options and Options.Editor )
			or { StickTarget = "List"; StickPoint = "RT"; } );

		local Scripts = ( Options and Options.Scripts ) or me.DefaultScripts;
		me.DefaultScripts = nil;
		if ( Scripts ) then
			me.FolderRoot:Unpack( Scripts );
		end
		me:IterateScripts( nil, function ( Script )
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
		List = me.List:Pack();
		Editor = me.Editor:Pack();
	};
end
do
	local Active = IsLoggedIn();
	--- Keeps the default UI from hiding open dialogs when zoning.
	function me.Frame:PLAYER_LEAVING_WORLD ()
		Active = false;
	end
	function me.Frame:PLAYER_ENTERING_WORLD ()
		Active = true;
	end
	--- @return True if the dialog was hidden.
	local function Hide ( self )
		if ( self:IsShown() ) then
			self:Hide();
			return true;
		end
	end
	local Backup = CloseSpecialWindows;
	--- Hook to hide dialog windows when escape is pressed.
	-- Used instead of UISpecialFrames to prevent closing when zoning.
	function CloseSpecialWindows ( ... )
		return Backup( ... )
			or Active and ( Hide( me.Editor ) or Hide( me.List ) );
	end
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
		ToggleFrame( me.List );
	else
		local Script = me:FindScript( Pattern );
		if ( Script ) then
			return me.SafeCall( Script );
		else
			me.Print( me.L.SLASH_NOTFOUND_FORMAT:format( Pattern ) );
		end
	end
end




me.FolderRoot = me:GetClass( "Folder" ):New();

me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );
me.Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
me.Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" );

SlashCmdList[ "_DEVPAD" ] = me.SlashCommand;
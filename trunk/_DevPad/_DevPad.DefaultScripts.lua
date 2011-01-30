--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.DefaultScripts.lua - Optional defaults file.  Safe to delete.      *
  ****************************************************************************]]


local _DevPad = select( 2, ... );
local L = _DevPad.L;




--- Settings table compatible with Folder:Unpack used when no saved variables are found.
-- Note: Don't use tabs in script text fields!
_DevPad.DefaultScripts = { Class = "Folder"; Name = "ROOT";
	{	Class = "Script"; Name = L.README;
		Text = L.README_TEXT;
	},
	{ Class = "Folder"; Name = L.IMPORTERS;
		{	Class = "Script"; Name = "Hack"; Lua = true;
			Text = [=[
--- Run with Hack enabled to transfer all settings to _DevPad.
-- Hack books transfer as folders.
-- NOTE: You must replace script references to Hack yourself!
--   Ex) Hack.Run("Page") > _DevPad:FindScripts("Page")()

local DB = assert( HackDB, "Hack saved variables not found." );
local FolderClass, ScriptClass = _DevPad:GetClass( "Folder" ), _DevPad:GetClass( "Script" );
local Hack = FolderClass:New();
Hack:SetName( "Hack Import" );
for _, BookData in ipairs( DB.books ) do
  local Book = FolderClass:New();
  Book:SetName( BookData.name );
  for _, PageData in ipairs( BookData.data ) do
    local Script = ScriptClass:New();
    Script:SetName( PageData.name );
    Script:SetText( PageData.data:gsub( "||", "|" ) ); -- Unescape
    Script:SetAutoRun( PageData.autorun );
    Script:SetLua( PageData.colorize );
    Book:Insert( Script );
  end
  Hack:Insert( Book );
end
return _DevPad.FolderRoot:Insert( Hack );]=];
		},
		{	Class = "Script"; Name = "TinyPad"; Lua = true;
			Text = [=[
--- Run with TinyPad enabled to transfer all settings to _DevPad.

local DB = assert( TinyPadPages, "TinyPad saved variables not found." );
local ScriptClass = _DevPad:GetClass( "Script" );
local TinyPad = _DevPad:GetClass( "Folder" ):New();
TinyPad:SetName( "TinyPad Import" );
for Index, Text in ipairs( DB ) do
  local Script = ScriptClass:New();
  Script:SetName( ( "Page %d" ):format( Index ) );
  Script:SetText( Text );
  Script:SetLua( false );
  TinyPad:Insert( Script );
end
return _DevPad.FolderRoot:Insert( TinyPad );]=];
		},
		{	Class = "Script"; Name = "WowLua"; Lua = true;
			Text = [=[
--- Run with WowLua loaded to transfer all settings to _DevPad.
-- _DevPad doesn't support script "locking"; All imported scripts will be writable.

if ( IsAddOnLoadOnDemand( "WowLua" ) ) then
  LoadAddOn( "WowLua" ); -- In case AddonLoader is installed
end
local DB = assert( WowLua_DB, "WowLua saved variables not found." );
local ScriptClass = _DevPad:GetClass( "Script" );
local WowLua = _DevPad:GetClass( "Folder" ):New();
WowLua:SetName( "WowLua Import" );
for _, PageData in ipairs( DB.pages ) do
  local Script = ScriptClass:New();
  Script:SetName( PageData.name );
  Script:SetText( PageData.content );
  Script:SetLua( true );
  WowLua:Insert( Script );
end
return _DevPad.FolderRoot:Insert( WowLua );]=];
		},
	},


	{	Class = "Script"; }, -- Spacer
	{	Class = "Script"; Name = L.EXAMPLE; Lua = true; AutoRun = true;
		Text = [=[
--- A simple example script demonstrating library usage by changing the default macro window's font.

local me = ...; --- First arg is always the table representing this script.
-- Any extra parameters are optionally passed in by the caller.

-- This same table is used even if the script is called more than once, so its contents can be used to keep track of state between calls to your script.  Key names prefixed with a single underscore character (like "._Name") are used internally by _DevPad.




-- Notice that this script is set to auto-run by default, indicated by the green arrow next to its name in the list.  There's no need to run the script manually as long as auto-run is enabled; it will execute on start up like a normal addon.

-- Here we use a flag in the script table to only let the script run once.
if ( me.Loaded ) then
  return;
end
me.Loaded = true;




-- Read the "AddOnInit" script object, or page, contained in the "Libs" folder.
local AddOnInit = _DevPad( "Libs", "AddOnInit" );
-- This page object is like the "me" variable above, but used by AddOnInit.  Another way to get a reference to AddOnInit is by searching, like this:
--   local AddOnInit = _DevPad:FindScripts( "AddOnInit" )
-- In either case, AddOnInit may be nil if that script isn't found.

AddOnInit(); -- Runs the script, allowing it to initialize itself.
-- Various scripts may handle execution differently, by returning results for example.  In this case though, AddOnInit populates its table with methods.




-- With AddOnInit loaded, we can register this function to run once Blizzard's MacroUI addon finishes loading.  If Blizzard_MacroUI is already loaded, the function gets run immediately.
AddOnInit:Register( "Blizzard_MacroUI", function ()
    -- At this point, Blizzard_MacroUI and its saved variables are already loaded.
    
    -- Since our custom font is in the separate addon _DevPad.GUI, we must wait for that to load too.
    AddOnInit:Register( "_DevPad.GUI", function ()
        -- At this point, both Blizzard_MacroUI and _DevPad.GUI are loaded.
        
        -- Set the macro window text to use _DevPad's editor font.
        MacroFrameText:SetFontObject( _DevPad.GUI.Editor.Font );
        -- The macro window will now use the editor's saved font and font size.
    end );
end );

-- Hopefully this example helps illustrate how multiple scripts can interact with each other, and how scripts can easily manipulate addons other than _DevPad.]=];
	},
	{ Class = "Folder"; Name = "Libs";
		{	Class = "Script"; Name = "AddOnInit"; Lua = true;
			Text = [=[
--- API to register a script to run when its target addon loads.
local lib = ...;
if ( lib.Register ) then -- Library already initialized
  return lib;
end


local Frame = CreateFrame( "Frame" );
Frame:SetScript( "OnEvent", _DevPad.Frame.OnEvent );

local AddOnInitializers = {};


--- Runs the given addon's initializer if it loaded.
-- @return True if initializer was run.
local function InitializeAddOn ( Name )
  Name = Name:upper(); -- For case insensitive file systems (Windows')
  local Initializer = AddOnInitializers[ Name ];
  if ( Initializer
    and select( 2, IsAddOnLoaded( Name ) ) -- Returns false if addon is currently loading
  ) then
    if ( type( Initializer ) == "table" ) then
      for _, Script in ipairs( Initializer ) do
        Script();
      end
    else
      Initializer();
    end
    AddOnInitializers[ Name ] = nil;
    return true;
  end
end

--- Attempts to run initializers for any loaded addon.
function Frame:ADDON_LOADED ( _, AddOn )
  return InitializeAddOn( AddOn );
end
Frame:RegisterEvent( "ADDON_LOADED" );

--- Register a function to run when an addon loads.
-- @return True if loaded immediately.
function lib:Register ( Name, Initializer )
  if ( self:IsLoadable( Name ) ) then
    Name = Name:upper();
    local OldInitializer = AddOnInitializers[ Name ];
    if ( OldInitializer ) then -- Put multiple initializers in a table
      if ( type( OldInitializer ) ~= "table" ) then
        AddOnInitializers[ Name ] = { OldInitializer };
      end
      tinsert( AddOnInitializers[ Name ], Initializer );
    else
      AddOnInitializers[ Name ] = Initializer;
    end
    
    return InitializeAddOn( Name );
  end
end

--- @return True if an addon can possibly load this session.
function lib:IsLoadable ( Name )
  local Loadable, Reason = select( 5, GetAddOnInfo( Name ) );
  return Loadable or (
    Reason == "DISABLED"
    and IsAddOnLoadOnDemand( Name ) -- Loadable or can become loadable
  );
end
return lib;]=];
		},
	},
};
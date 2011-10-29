--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.DefaultScripts.lua - Optional defaults file.  Safe to delete.      *
  ****************************************************************************]]


local _DevPad = select( 2, ... );
local L = _DevPad.L;




--- Settings table compatible with Folder:Unpack used when no saved variables are found.
-- Note: Don't use tabs in script text fields!
_DevPad.DefaultScripts = { Class = "Folder"; Name = "ROOT";
	{ Class = "Script"; Name = L.README;
		Text = L.README_TEXT;
	},
	{ Class = "Folder"; Name = L.IMPORTERS;
		{ Class = "Script"; Name = "Hack"; Lua = true;
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
		{ Class = "Script"; Name = "TinyPad"; Lua = true;
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
		{ Class = "Script"; Name = "WowLua"; Lua = true;
			Text = [=[
--- Run with WowLua loaded to transfer all settings to _DevPad.
-- _DevPad doesn't support page "locking"; All imported pages will be writable.

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


	{ Class = "Script"; }, -- Spacer
	{ Class = "Script"; Name = L.EXAMPLE; Lua = true; AutoRun = true;
		Text = [=[
--- A simple example script demonstrating library usage by changing the default macro window's font.

local NS = ...; --- First arg is always the table representing this page.
-- Any extra parameters are optionally passed in by the caller.

-- This same table is used even if the page is called more than once, so its contents can be used to keep track of state between calls.  Key names prefixed with a single underscore character (like "._Name") are used internally by _DevPad.




-- Notice that this page is set to auto-run by default, indicated by the green arrow next to its name in the list.  There's no need to run the page manually as long as auto-run is enabled; it will execute on start up like a normal addon.

-- Here we use a flag in the page's table to only let it run once.
if ( NS.Loaded ) then
  return;
end
NS.Loaded = true;




-- Fetch the "AddOnInit" page contained in the "Libs" folder.
local AddOnInit = _DevPad( "Libs", "AddOnInit" );
-- This page object is like the "NS" variable above, but used by AddOnInit.  Another way to get a reference to AddOnInit is by searching, like this:
--   local AddOnInit = _DevPad:FindScripts( "AddOnInit" )
-- In either case, AddOnInit may be nil if that page isn't found.

AddOnInit(); -- Runs the page, allowing it to initialize its table.
-- Various pages may handle execution differently, by returning results for example.  In this case though, AddOnInit populates its table with methods.




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

-- Hopefully this example helps illustrate how multiple pages can interact with each other, and how pages can easily manipulate addons other than _DevPad.]=];
	},
	{ Class = "Folder"; Name = "Libs";
		{ Class = "Script"; Name = "AddOnInit"; Lua = true;
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
    AddOnInitializers[ Name ] = nil;
    if ( type( Initializer ) == "table" ) then
      for _, Script in ipairs( Initializer ) do
        _DevPad.SafeCall( Script ); -- Don't break execution if one initializer fails
      end
    else
      Initializer();
    end
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
		{ Class = "Script"; Name = "RegisterForSave"; Lua = true;
			Text = [=[
--- Provides an API for pages to save data between sessions.
-- @usage local Value = _DevPad( "Libs", "RegisterForSave" )( "VariableName"[, DefaultValue] );
--   Set new values to _G[ "VariableName" ] and they will be saved on logout.
local lib = ...;
if ( lib.Register ) then
  return lib.Register( ... );
end
local AceSerializer = LibStub( "AceSerializer-3.0" );


local DATA_NAME = "RegisterForSave Data";
--- @return The data folder found in the same folder as this lib, or a new one.
local function GetData ()
  local Data = lib:GetRelObject( true, DATA_NAME );
  if ( not Data ) then
    -- Add data folder just after this library
    Data = _DevPad:GetClass( "Folder" ):New();
    lib._Parent:Insert( Data, lib:GetIndex() + 1 );
    Data:SetName( DATA_NAME );
    Data:SetClosed( true );
  end
  return Data;
end


local Active = {}; --- Active global variable names
--- Registers a global variable to persist between sessions, and loads its previous value.
-- If no previous value was saved, the global won't be overwritten.
-- @param Name  Global variable name to load and save to.
-- @param ...  Optional default value to initialize to if no previous value is found.
-- @return Value loaded from history, if any.
function lib:Register ( Name, ... )
  assert( type( Name ) == "string", "Name must be a string." );
  assert( not Active[ Name ], "Name is already registered." );
  Active[ Name ] = true;
  local Script = GetData():GetRelObject( Name );
  if ( Script ) then
    local Success, Value = AceSerializer:Deserialize( Script._Text );
    if ( not Success ) then -- Invalid saved data
      geterrorhandler()( Value );
      Value = nil; -- Clear global variable
    end
    _G[ Name ] = Value;
    return Value;
  elseif ( select( "#", ... ) > 0 ) then -- Default provided
    _G[ Name ] = ...;
    return ( ... );
  end
end


do
  --- Serializes all active saved variables.
  local function SerializeData ()
    if ( not next( Active ) ) then
      return;
    end
    local Data = GetData();
    
    for Name in pairs( Active ) do
      -- Serialization failures preserve original data
      local Success, Text = pcall( AceSerializer.Serialize, AceSerializer, _G[ Name ] );
      if ( not Success ) then -- Requires a bug grabber with error history to read!
        geterrorhandler()( Text );
      else
        local Script = Data:GetRelObject( Name );
        if ( not Script ) then
          Script = _DevPad:GetClass( "Script" ):New();
          Script:SetName( Name );
          Script:SetLua( false );
          Data:Insert( Script );
        end
        Script:SetText( Text );
      end
    end
  end
  local Pack = _DevPad.FolderRoot.Pack;
  --- Saves variables just before _DevPad does.
  function _DevPad.FolderRoot:Pack ( ... )
    pcall( SerializeData ); -- Entire pad is at stake!
    return Pack( self, ... );
  end
end

return lib.Register( ... );]=];
		},
	},
};
--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.DefaultScripts.lua - Optional defaults file.  Safe to delete.      *
  ****************************************************************************]]


local _DevPad = select( 2, ... );
local L = _DevPad.L;




--- Settings table compatible with Folder:Unpack used when no saved variables are found.
-- Note: Don't use tabs in script text fields!
_DevPad.DefaultScripts = { Class = "Folder";
	{	Class = "Script"; Name = L.README;
		Text = L.README_TEXT;
	},
	{ Class = "Folder"; Name = L.IMPORTERS;
		{	Class = "Script"; Name = "Hack"; Lua = true;
			Text = [=[
--- Run with Hack enabled to transfer all settings to _DevPad.
-- Hack books transfer as folders.
-- NOTE: You must replace script references to Hack yourself!
--   Ex) Hack.Run("Page") > _DevPad:FindScript("Page")()

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

LoadAddOn( "WowLua" ); -- In case AddonLoader is installed
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
	}
};
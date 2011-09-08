--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.Entities.lua - Options sub-pane for custom entities.        *
  ****************************************************************************]]


local _UTF = select( 2, ... );
local L = _UTF.L;
local NS = CreateFrame( "Frame" );
_UTF.Customize.Entities = NS;

NS.Key = L.CUSTOMIZE_ENTITIES_NAME;
NS.Value = L.CUSTOMIZE_ENTITIES_VALUE;




--- Rebuilds the table of entities.
function NS.Update ()
	local Table = _UTF.Customize.Table;
	Table:SetHeader( L.CUSTOMIZE_ENTITIES_GLYPH, L.CUSTOMIZE_ENTITIES_NAME, L.CUSTOMIZE_ENTITIES_VALUE );
	Table:SetSortHandlers( false, true, true );
	Table:SetSortColumn( 2 ); -- Default sort by name

	for Name, ID in pairs( _UTFOptions.CharacterEntities ) do
		Table:AddRow( Name, _UTF.IntToUTF( ID ), Name, ID );
	end
end
--- Callback that specifies new edit box text when a table entry is selected.
function NS.OnSelect ( Name )
	return Name, _UTFOptions.CharacterEntities[ Name ];
end


--- Adds an entity name and value to the data set.
-- @return True if added successfully.
function NS.Add ( Key, Value )
	if ( NS.CanAdd( Key, Value ) ) then
		_UTFOptions.CharacterEntities[ Key ] = tonumber( Value );
		return true;
	end
end
--- Removes an entity by key from the data set.
-- @return True if removed successfully.
function NS.Remove ( Key )
	if ( NS.CanRemove( Key ) ) then
		_UTFOptions.CharacterEntities[ Key ] = nil;
		return true;
	end
end


--- Validates that a key is present and can be removed.
-- @return The unique identifier that can be used to select this removable value in the table.
function NS.CanRemove ( Key )
	if ( _UTFOptions.CharacterEntities[ Key ] ) then
		return Key;
	end
end
--- Validates that a key/value pair can be added.
-- @return True if the values can be added successfully.
function NS.CanAdd ( Key, Value )
	Value = tonumber( Value );
	if ( Value and Key:match( "^%w+$" )
		and _UTFOptions.CharacterEntities[ Key ] ~= Value
		and _UTF.IsValidCodepoint( Value )
	) then
		return true;
	end
end


--- Initializes the value editbox to numeric mode when opening this pane.
function NS:OnShow ()
	_UTF.Customize.Value:SetNumeric( true );
end
--- Restores the value editbox back to text mode when this pane is closed.
function NS:OnHide ()
	_UTF.Customize.Value:SetNumeric( false );
end




NS:SetScript( "OnShow", NS.OnShow );
NS:SetScript( "OnHide", NS.OnHide );

_UTF.Customize.AddPane( NS, L.CUSTOMIZE_ENTITIES_TITLE );
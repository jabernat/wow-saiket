--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.TextReplace.lua - Options sub-pane for custom replacements. *
  ****************************************************************************]]


local _UTF = select( 2, ... );
local L = _UTF.L;
local me = CreateFrame( "Frame" );
_UTF.Customize.TextReplace = me;

me.Key = L.CUSTOMIZE_TEXTREPLACE_FIND;
me.Value = L.CUSTOMIZE_TEXTREPLACE_REPLACE;




--- Returns the index of a search pattern if already being used.
-- @param Key  Search pattern to look for.
-- @return Index that the pattern was found at in the options table, or nil if unused.
local function KeyToIndex ( Key )
	for Index, Replacement in ipairs( _UTFOptions.Chat.TextReplacements ) do
		if ( Replacement[ 1 ] == Key ) then
			return Index;
		end
	end
end


--- Rebuilds the table of entities.
function me.Update ()
	local Table = _UTF.Customize.Table;
	Table:SetHeader( L.CUSTOMIZE_TEXTREPLACE_INDEX, L.CUSTOMIZE_TEXTREPLACE_FIND, L.CUSTOMIZE_TEXTREPLACE_REPLACE );
	for Index, Data in ipairs( _UTFOptions.Chat.TextReplacements ) do
		Table:AddRow( Index, Index, Data[ 1 ], Data[ 2 ] );
	end
end
--- Callback that specifies new edit box text when a table entry is selected.
function me.OnSelect ( Index )
	return unpack( _UTFOptions.Chat.TextReplacements[ Index ], 1, 2 );
end


--- Adds a search pattern and replacement to the data set.
-- @return True if added successfully.
function me.Add ( Key, Value )
	if ( me.CanAdd( Key, Value ) ) then
		local TextReplacements = _UTFOptions.Chat.TextReplacements;
		local Index = KeyToIndex( Key );
		local Value = _UTF.ReplaceCharacterReferences( Value );
		if ( Index ) then -- Replace old value
			TextReplacements[ Index ][ 2 ] = Value;
		else
			tinsert( TextReplacements, { Key, Value } );
		end
		return true;
	end
end
--- Removes a text replacement by key from the data set.
-- @return True if removed successfully.
function me.Remove ( Key )
	local Index = me.CanRemove( Key );
	if ( Index ) then
		tremove( _UTFOptions.Chat.TextReplacements, Index );
		return true;
	end
end


--- Validates that a key is present and can be removed.
-- @return The unique identifier that can be used to select this removable value in the table.
function me.CanRemove ( Key )
	if ( Key ~= "" ) then
		return KeyToIndex( Key );
	end
end
--- Validates that a key/value pair can be added.
-- @return True if the values can be added successfully.
function me.CanAdd ( Key, Value )
	if ( Key ~= "" ) then
		local Index = KeyToIndex( Key );
		if ( not Index or _UTFOptions.Chat.TextReplacements[ Index ][ 2 ] ~= Value ) then
			return true;
		end
	end
end




_UTF.Customize.AddPane( me, L.CUSTOMIZE_TEXTREPLACE_TITLE );
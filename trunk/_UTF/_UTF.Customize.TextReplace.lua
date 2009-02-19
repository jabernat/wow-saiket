--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.TextReplace.lua - Options sub-pane for custom replacements. *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame" );
_UTF.Customize.TextReplace = me;

me.Label1 = L.CUSTOMIZE_TEXTREPLACE_FIND;
me.Label2 = L.CUSTOMIZE_TEXTREPLACE_REPLACE;




--[[****************************************************************************
  * Function: local KeyToIndex                                                 *
  * Description: Gets the table index of a key if present.                     *
  ****************************************************************************]]
local function KeyToIndex ( Key )
	for Index, Replacement in ipairs( _UTFOptions.Chat.TextReplacements ) do
		if ( Replacement[ 1 ] == Key ) then
			return Index;
		end
	end
end


--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.Update                                *
  * Description: Updates the data display.                                     *
  ****************************************************************************]]
do
	local Table = _UTF.Customize.Table;
	function me.Update ()
		Table:SetHeader( L.CUSTOMIZE_TEXTREPLACE_INDEX, L.CUSTOMIZE_TEXTREPLACE_FIND, L.CUSTOMIZE_TEXTREPLACE_REPLACE );
		for Index, Data in ipairs( _UTFOptions.Chat.TextReplacements ) do
			Table:AddRow( Index, Index, Data[ 1 ]:gsub( "|", "||" ), Data[ 2 ]:gsub( "|", "||" ) );
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.OnSelect                              *
  * Description: Updates the edit boxes to match the table selection.          *
  ****************************************************************************]]
function me.OnSelect ( Index )
	return _UTFOptions.Chat.TextReplacements[ Index ][ 1 ], _UTFOptions.Chat.TextReplacements[ Index ][ 2 ];
end

--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.Add                                   *
  * Description: Adds a pair of values to the data set.                        *
  ****************************************************************************]]
function me.Add ( Key, ValueEditBox )
	if ( me.CanAdd( Key, ValueEditBox ) ) then
		local Table = _UTFOptions.Chat.TextReplacements;
		local Index = KeyToIndex( Key );
		local Value = _UTF.ReplaceCharacterReferences( ValueEditBox:GetText() );
		if ( Index ) then -- Replace old value
			Table[ Index ][ 2 ] = Value;
		else
			tinsert( Table, { Key, Value } );
		end

		return true;
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.Remove                                *
  * Description: Adds a pair of values to the data set.                        *
  ****************************************************************************]]
function me.Remove ( Key )
	if ( me.CanRemove( Key ) ) then
		tremove( _UTFOptions.Chat.TextReplacements, KeyToIndex( Key ) );

		return true;
	end
end

--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.CanRemove                             *
  * Description: Returns the input's key if it is present and can be removed.  *
  ****************************************************************************]]
function me.CanRemove ( Key )
	if ( Key ~= "" ) then
		return KeyToIndex( Key );
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.CanAdd                                *
  * Description: Returns the input's key if it can be added.                   *
  ****************************************************************************]]
function me.CanAdd ( Key, ValueEditBox )
	if ( Key ~= "" ) then
		Key = KeyToIndex( Key );
		if ( not Key or _UTFOptions.Chat.TextReplacements[ Key ][ 2 ] ~= ValueEditBox:GetText() ) then
			return Key or true;
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_UTF.Customize.AddPane( me, L.CUSTOMIZE_TEXTREPLACE_TITLE );
end

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
  * Function: _UTF.Customize.TextReplace.KeyToIndex                            *
  * Description: Gets the table index of a key if present.                     *
  ****************************************************************************]]
function me.KeyToIndex ( Key )
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
function me.Update ()
	print( "Updated TextReplace." );
end

--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.Add                                   *
  * Description: Adds a pair of values to the data set.                        *
  ****************************************************************************]]
function me.Add ( Key, ValueEditBox )
	if ( me.CanAdd( Key, ValueEditBox ) ) then
		local Table = _UTFOptions.Chat.TextReplacements;
		local Index = me.KeyToIndex( Key );
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
		tremove( _UTFOptions.Chat.TextReplacements, me.KeyToIndex( Key ) );

		return true;
	end
end

--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.CanRemove                             *
  * Description: True if a key is present and can be removed.                  *
  ****************************************************************************]]
function me.CanRemove ( Key )
	if ( Key ~= "" and me.KeyToIndex( Key ) ) then
		return true;
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.TextReplace.CanAdd                                *
  * Description: True if a key can be added.                                   *
  ****************************************************************************]]
function me.CanAdd ( Key, ValueEditBox )
	if ( Key ~= "" ) then
		Key = me.KeyToIndex( Key );
		if ( not Key or _UTFOptions.Chat.TextReplacements[ Key ][ 2 ] ~= ValueEditBox:GetText() ) then
			return true;
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_UTF.Customize.AddPane( me, L.CUSTOMIZE_TEXTREPLACE_TITLE );
end

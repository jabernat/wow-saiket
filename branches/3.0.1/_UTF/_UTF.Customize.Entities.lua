--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.Entities.lua - Options sub-pane for custom entities.        *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame" );
_UTF.Customize.Entities = me;

me.Label1 = L.CUSTOMIZE_ENTITIES_NAME;
me.Label2 = L.CUSTOMIZE_ENTITIES_VALUE;




--[[****************************************************************************
  * Function: _UTF.Customize.Entities.Update                                   *
  * Description: Updates the data display.                                     *
  ****************************************************************************]]
function me.Update ()
	print( "Updated Entities." );
end
--[[****************************************************************************
  * Function: _UTF.Customize.Entities.Add                                      *
  * Description: Adds a pair of values to the data set.                        *
  ****************************************************************************]]
function me.Add ( Key, ValueEditBox )
	if ( me.CanAdd( Key, ValueEditBox ) ) then
		_UTFOptions.CharacterEntities[ Key ] = ValueEditBox:GetNumber();

		return true;
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.Entities.Remove                                   *
  * Description: Adds a pair of values to the data set.                        *
  ****************************************************************************]]
function me.Remove ( Key )
	if ( me.CanRemove( Key ) ) then
		_UTFOptions.CharacterEntities[ Key ] = nil;

		return true;
	end
end

--[[****************************************************************************
  * Function: _UTF.Customize.Entities.CanRemove                                *
  * Description: True if a key is present and can be removed.                  *
  ****************************************************************************]]
function me.CanRemove ( Key )
	if ( Key ~= "" and _UTFOptions.CharacterEntities[ Key ] ) then
		return true;
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.Entities.CanAdd                                   *
  * Description: True if a key can be added.                                   *
  ****************************************************************************]]
function me.CanAdd ( Key, ValueEditBox )
	if ( strfind( Key, "^%w+$" ) and ValueEditBox:GetText() ~= "" ) then
		local Value = ValueEditBox:GetNumber();
		if ( _UTFOptions.CharacterEntities[ Key ] ~= Value and Value <= _UTF.Max and Value >= _UTF.Min ) then
			return true;
		end
	end
end


--[[****************************************************************************
  * Function: _UTF.Customize.Entities:OnShow                                   *
  * Description: Sets the value editbox to numeric mode.                       *
  ****************************************************************************]]
function me:OnShow ()
	_UTF.Customize.EditBox2:SetNumeric( true );
end
--[[****************************************************************************
  * Function: _UTF.Customize.Entities:OnHide                                   *
  * Description: Sets the value editbox back to text mode.                     *
  ****************************************************************************]]
function me:OnHide ()
	_UTF.Customize.EditBox2:SetNumeric( false );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnShow", me.OnShow );
	me:SetScript( "OnHide", me.OnHide );

	_UTF.Customize.AddPane( me, L.CUSTOMIZE_ENTITIES_TITLE );
end

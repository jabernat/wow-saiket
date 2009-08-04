--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.ColorPickerFrame.lua - Modifies the color picker frame.              *
  *                                                                            *
  * + Adds an editbox to modify the color with a hex triplet.                  *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {};
_Misc.ColorPickerFrame = me;




--[[****************************************************************************
  * Function: _Misc.ColorPickerFrame.OnHide                                    *
  * Description: Clears focus so that the text will be rehighlighted when this *
  *   dialog is opened again.                                                  *
  ****************************************************************************]]
function me:OnHide ()
	self:ClearFocus();
end
--[[****************************************************************************
  * Function: _Misc.ColorPickerFrame.OnEscapePressed                           *
  * Description: Hides the dialog without applying changes.                    *
  ****************************************************************************]]
function me:OnEscapePressed ()
	local Parent = self:GetParent();
	HideUIPanel( Parent );
	if ( Parent.cancelFunc ) then
		Parent.cancelFunc( Parent.previousValues );
	end
end
--[[****************************************************************************
  * Function: _Misc.ColorPickerFrame.OnTextChanged                             *
  * Description: When the user types in a full and valid hex triplet, this     *
  *   updates the color picker frame to match.                                 *
  ****************************************************************************]]
do
	local rshift = bit.rshift;
	local band = bit.band;
	function me:OnTextChanged ()
		local Text = self:GetText();
		local Value = tonumber( Text, 16 );
		local Color;
	
		if ( Value and #Text == 6 ) then -- Valid
			Color = HIGHLIGHT_FONT_COLOR;
			self:GetParent():SetColorRGB(
				rshift( Value, 16 ) / 255,
				band( rshift( Value, 8 ), 255 ) / 255,
				band( Value, 255 ) / 255 );
		else -- Invalid
			Color = RED_FONT_COLOR;
		end
	
		self:SetTextColor( Color.r, Color.g, Color.b );
	end
end
--[[****************************************************************************
  * Function: _Misc.ColorPickerFrame.OnColorSelect                             *
  * Description: Sets the hex triplet to match the shown color.                *
  ****************************************************************************]]
do
	local lshift = bit.lshift;
	local floor = floor;
	function me:OnColorSelect ( R, G, B )
		self.EditBox:SetText( ( "%06X" ):format( -- No SetFormattedText for editboxes
			lshift( floor( R * 255 + 0.5 ), 16 )
			+ lshift( floor( G * 255 + 0.5 ), 8 )
			+ floor( B * 255 + 0.5 )
		) );
	end
end
--[[****************************************************************************
  * Function: _Misc.ColorPickerFrame.OnLoad                                    *
  * Description: Makes room for the editbox and hooks the color picker.        *
  ****************************************************************************]]
function me:OnLoad ()
	ColorPickerCancelButton:SetWidth( 96 );
	ColorPickerOkayButton:SetWidth( 96 );

	self:GetParent().EditBox = self;
	ColorPickerFrame:HookScript( "OnColorSelect", me.OnColorSelect );
end

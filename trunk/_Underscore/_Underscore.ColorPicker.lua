--[[****************************************************************************
  * _Underscore by Saiket                                                      *
  * _Underscore.ColorPicker.lua - Modifies the color picker frame.             *
  ****************************************************************************]]


local me = CreateFrame( "EditBox", "_UnderscoreColorPickerEditBox", ColorPickerFrame, "InputBoxTemplate" );
_Underscore.ColorPicker = me;




--[[****************************************************************************
  * Function: _Underscore.ColorPicker:OnTextChanged                            *
  * Description: Validates hex triplet.                                        *
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
			ColorPickerFrame:SetColorRGB(
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
  * Function: _Underscore.ColorPicker:OnColorSelect                            *
  * Description: Sets the hex triplet to match the shown color.                *
  ****************************************************************************]]
do
	local lshift = bit.lshift;
	local floor = floor;
	function me:OnColorSelect ( R, G, B )
		me:SetText( ( "%06X" ):format( -- No SetFormattedText for editboxes
			lshift( floor( R * 255 + 0.5 ), 16 )
			+ lshift( floor( G * 255 + 0.5 ), 8 )
			+ floor( B * 255 + 0.5 )
		) );
	end
end




-- Make room for the edit box
ColorPickerCancelButton:SetWidth( 100 );
ColorPickerOkayButton:SetWidth( 100 );

me:SetPoint( "BOTTOMLEFT", 20, 10 );
me:SetPoint( "TOPRIGHT", ColorPickerOkayButton, "TOPLEFT", -2, 0 );
me:SetMaxLetters( 6 );


ColorPickerFrame:HookScript( "OnColorSelect", me.OnColorSelect );
me:SetScript( "OnHide", me.ClearFocus );
me:SetScript( "OnEscapePressed", ColorPickerCancelButton:GetScript( "OnClick" ) );
me:SetScript( "OnTextChanged", me.OnTextChanged );
--[[****************************************************************************
  * _Underscore by Saiket                                                      *
  * _Underscore.ColorPicker.lua - Modifies the color picker frame.             *
  ****************************************************************************]]


local NS = CreateFrame( "EditBox", "_UnderscoreColorPickerEditBox", ColorPickerFrame, "InputBoxTemplate" );
select( 2, ... ).ColorPicker = NS;




do
	local rshift = bit.rshift;
	local band = bit.band;
	--- Validates hex triplet.
	function NS:OnTextChanged ()
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
do
	local lshift = bit.lshift;
	local floor = floor;
	--- Sets the hex triplet to match the shown color.
	function NS:OnColorSelect ( R, G, B )
		NS:SetText( ( "%06X" ):format( -- No SetFormattedText for editboxes
			lshift( floor( R * 255 + 0.5 ), 16 )
			+ lshift( floor( G * 255 + 0.5 ), 8 )
			+ floor( B * 255 + 0.5 )
		) );
	end
end




-- Make room for the edit box
ColorPickerCancelButton:SetWidth( 100 );
ColorPickerOkayButton:SetWidth( 100 );

NS:SetPoint( "BOTTOMLEFT", 20, 10 );
NS:SetPoint( "TOPRIGHT", ColorPickerOkayButton, "TOPLEFT", -2, 0 );
NS:SetMaxLetters( 6 );


ColorPickerFrame:HookScript( "OnColorSelect", NS.OnColorSelect );
NS:SetScript( "OnHide", NS.ClearFocus );
NS:SetScript( "OnEscapePressed", ColorPickerCancelButton:GetScript( "OnClick" ) );
NS:SetScript( "OnTextChanged", NS.OnTextChanged );
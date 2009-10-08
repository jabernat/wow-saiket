--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BigWigs.lua - Modifies the BigWigs addon.                           *
  ****************************************************************************]]


--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

if ( select( 6, GetAddOnInfo( "BigWigs_Plugins" ) ) ~= "MISSING" ) then
	_Clean.RegisterAddOnInitializer( "BigWigs_Plugins", function ()
		BigWigs:GetModule( "Bars 2" ); -- Will error if missing

		-- Reposition bar anchors to the middle of the screen
		local function LockAnchor ( Anchor )
			Anchor:RegisterForDrag();
			Anchor:SetUserPlaced( false );

			Anchor.ClearAllPoints = _Clean.NilFunction;
			Anchor.SetPoint = _Clean.NilFunction;
			Anchor.StartMoving = _Clean.NilFunction;
		end

		BigWigsAnchor:ClearAllPoints();
		BigWigsAnchor:SetPoint( "BOTTOM", _Clean.BottomPane, "TOP" );
		LockAnchor( BigWigsAnchor );

		BigWigsEmphasizeAnchor:ClearAllPoints();
		BigWigsEmphasizeAnchor:SetPoint( "TOP", _Clean.BottomPane );
		LockAnchor( BigWigsEmphasizeAnchor );
	end );
end
if ( select( 6, GetAddOnInfo( "BigWigs_Extras" ) ) ~= "MISSING" ) then
	_Clean.RegisterAddOnInitializer( "BigWigs_Extras", function ()
		-- Recolor flash frame red
		local Flash = BigWigs:GetModule( "Flash" );
		local BigWigsMessageBackup = Flash.BigWigs_Message;
		local function VarArg ( ... )
			if ( BWFlash ) then
				local Color = RED_FONT_COLOR;
				BWFlash:SetBackdropColor( Color.r, Color.g, Color.b, select( 4, BWFlash:GetBackdropColor() ) );
				BWFlash:GetRegions():SetBlendMode( "ADD" );
				Flash.BigWigs_Message = BigWigsMessageBackup;
			end
			return ...;
		end
		function Flash:BigWigs_Message ( ... )
			return VarArg( BigWigsMessageBackup( self, ... ) );
		end
	end );
end

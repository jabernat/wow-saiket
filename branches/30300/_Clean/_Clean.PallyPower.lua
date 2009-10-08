--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.PallyPower.lua - Modifies PallyPower's buff buttons.                *
  ****************************************************************************]]


if ( select( 6, GetAddOnInfo( "PallyPower" ) ) == "MISSING" ) then
	return;
end
local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.PallyPower = me;




--[[****************************************************************************
  * Function: _Clean.PallyPower.IterateButtons                                 *
  * Description: Runs a function for all buff buttons.                         *
  ****************************************************************************]]
function me.IterateButtons ( Method )
	Method( PallyPowerAuto, "Auto" );
	Method( PallyPowerRF, "RF" );
	Method( PallyPowerAura, "Aura" );
	for ClassIndex, ClassButton in ipairs( PallyPower.classButtons ) do
		Method( ClassButton, "Class" );
		for _, PlayerButton in ipairs( PallyPower.playerButtons[ ClassIndex ] ) do
			Method( PlayerButton, "Player" );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.PallyPower:ApplySkin                                      *
  * Description: Applies a skin to all buff buttons.                           *
  ****************************************************************************]]
do
	local Backdrop = {};
	local function Apply ( Button )
		Button:SetBackdrop( Backdrop );
	end
	function me:ApplySkin ( SkinName )
		Backdrop.bgFile = PallyPower.Skins[ SkinName ];
		me.IterateButtons( Apply );
	end
end
--[[****************************************************************************
  * Function: _Clean.PallyPower:PLAYER_LOGIN                                   *
  * Description: Undoes saved frame positions for the buff frame.              *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	PallyPowerFrame:ClearAllPoints();
	PallyPowerFrame:SetPoint( "TOPRIGHT", Dominos.Frame:Get( 3 ), "TOPRIGHT", -6, 40 * 3 - 18 ); -- Leave room for three buttons
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "PallyPower", function ()
		me.IterateButtons( function ( Button, Type )
			local Name = Button:GetName();
			if ( Type == "Auto" or Type == "Aura" or Type == "RF" ) then
				_Clean.RemoveButtonIconBorder( _G[ Name.."Icon" ] );
			end
			if ( Type == "RF" ) then
				_Clean.RemoveButtonIconBorder( _G[ Name.."IconSeal" ] );
			end
			if ( Type == "Class" or Type == "Player" ) then
				_Clean.RemoveButtonIconBorder( _G[ Name.."BuffIcon" ] );
			end
			if ( Type == "Class" ) then
				_Clean.RemoveButtonIconBorder( _G[ Name.."ClassIcon" ] );
			end
		end );
		hooksecurefunc( PallyPower, "ApplySkin", me.ApplySkin );
		if ( PallyPower.opt.skin ) then
			me.ApplySkin( PallyPower, PallyPower.opt.skin );
		end

		PallyPowerFrame:SetUserPlaced( false );
		me:SetScript( "OnEvent", _Clean.OnEvent );
		me:RegisterEvent( "PLAYER_LOGIN" );
	end );
end

--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.DBM.lua - Modifies the Deadly Boss Mods addon.                      *
  *                                                                            *
  * + Makes bars less obtrusive.                                               *
  * + Greatly increases the size of special warning text.                      *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, _Clean );
_Clean.DBM = me;




--[[****************************************************************************
  * Function: _Clean.DBM.SetAlpha                                              *
  * Description: Hook to make sure bars are never fully opaque.                *
  ****************************************************************************]]
function me:SetAlpha ( Alpha )
	if ( Alpha > 0.75 and not UIFrameIsFlashing( self ) ) then
		getmetatable( self ).__index.SetAlpha( self, 0.75 );
	end
end
--[[****************************************************************************
  * Function: _Clean.DBM.DBMStatusBarsCreateNewBar                             *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.DBMStatusBarsCreateNewBar ()
	local BarNumber = me.DBMStatusBarsCreateNewBarBackup();
	if ( BarNumber ) then -- Newly made bar
		local Name = "DBM_StatusBarTimer"..BarNumber;
		local Frame = _G[ Name ];
		Frame:SetAlpha( 0.75 );
		Frame:EnableMouse( false );
		Frame:SetFrameStrata( "LOW" );
		hooksecurefunc( Frame, "SetAlpha", me.SetAlpha );

		local Bar = _G[ Name.."Bar" ];
		Bar:EnableMouse( false );
		Bar:SetAlpha( 0.5 );
		Bar.SetAlpha = _Clean.NilFunction;

		_G[ Name.."Icon" ]:SetAlpha( 0.6 );

		return BarNumber;
	end
end
--[[****************************************************************************
  * Function: _Clean.DBM.UpdatePosition                                        *
  * Description: Repositions the timer bars.                                   *
  ****************************************************************************]]
function me.UpdatePosition ()
	me:UnregisterEvent( "PLAYER_ENTERING_WORLD" );

	DBM_StatusBarTimerAnchor:ClearAllPoints();
	DBM_StatusBarTimerAnchor:SetPoint( "TOP", ChatFrame1Background );
	DBM_StatusBarTimerAnchor:SetPoint( "LEFT", UIParent, "CENTER" );
	DBM_StatusBarTimerAnchor:SetPoint( "RIGHT", UIParent, "CENTER" );
	DBM_StatusBarTimerAnchor:SetUserPlaced( false );
	DBM_StatusBarTimerAnchor:SetHeight( DBM_StatusBarTimerDrag:GetHeight()
		* DBM_StatusBarTimerDrag:GetEffectiveScale() / DBM_StatusBarTimerAnchor:GetEffectiveScale() )
	DBM_StatusBarTimerDrag:EnableMouse( false );
	DBM_StatusBarTimerDragBar:EnableMouse( false );
end


--[[****************************************************************************
  * Function: _Clean.DBM.OnLoad                                                *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	me.DBMStatusBarsCreateNewBarBackup = DBMStatusBars_CreateNewBar;
	DBMStatusBars_CreateNewBar = me.DBMStatusBarsCreateNewBar;

	-- Enlarge the special warning text
	DBMSpecialWarningFrameText:SetTextHeight( 60 );
	DBMSpecialWarningFrameText:SetHeight( 120 ); -- Two lines

	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	me:SetScript( "OnEvent", me.UpdatePosition );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "DBM_API", me.OnLoad );
end

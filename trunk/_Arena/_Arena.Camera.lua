--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * _Arena.Camera.lua - Allows the first person view camera to drift left      *
  *   through walls when moving.                                               *
  ****************************************************************************]]


local L = _ArenaLocalization;
local _Arena = _Arena;
local me = {};
_Arena.Camera = me;

-- Commonly used functions
local SetCVar = SetCVar;




--[[****************************************************************************
  * Function: _Arena.Camera.Toggle                                             *
  * Description: Toggles camera movement.                                      *
  ****************************************************************************]]
function me.Toggle ()
	me[ _Arena.Buttons.CameraCheckbox:GetChecked() and "Disable" or "Enable" ]();
end
--[[****************************************************************************
  * Function: _Arena.Camera.Enable                                             *
  * Description: Enables camera movement.                                      *
  ****************************************************************************]]
function me.Enable ()
	SetCVar( "CameraBobbing", 1 );
	SetCVar( "CameraBobbingUDAmplitude", 0 );
	SetCVar( "CameraBobbingLRAmplitude", 10000 );
	SetCVar( "CameraBobbingFrequency", 0.01 );
	SetCVar( "CameraBobbingSmoothSpeed", 0.0028 );

	-- Show frame if hidden
	if ( not _Arena:IsShown() ) then
		_Arena:Show();
	end

	local CheckBox = _Arena.Buttons.CameraCheckbox;
	if ( not CheckBox:GetChecked() ) then
		CheckBox:SetChecked( true );
		-- Zoom to first person
		MoveViewInStart();
	end
end
--[[****************************************************************************
  * Function: _Arena.Camera.Disable                                            *
  * Description: Disables camera movement and returns the camera to normal.    *
  ****************************************************************************]]
function me.Disable ()
	SetCVar( "CameraBobbing", 1 );
	SetCVar( "CameraBobbingUDAmplitude", 0 );
	SetCVar( "CameraBobbingLRAmplitude", 0 );
	SetCVar( "CameraBobbingFrequency", 1 );
	SetCVar( "CameraBobbingSmoothSpeed", 10 );

	local CheckBox = _Arena.Buttons.CameraCheckbox;
	if ( CheckBox:GetChecked() ) then
		CheckBox:SetChecked( false );
		-- Remove longsight and zoom the camera in to first person
		CancelPlayerBuff( L.LONGSIGHT );
		MoveViewInStart();
	end
end

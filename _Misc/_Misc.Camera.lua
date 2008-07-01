--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.Camera.lua - Adds new bindings for positioning the camera.           *
  *                                                                            *
  * + Unlike the default UI's version, the binding to flip the camera 180      *
  *   degrees will spring back when released.                                  *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {};
_Misc.Camera = me;




--[[****************************************************************************
  * Function: _Misc.Camera.FlipView                                            *
  * Description: Key binding to flip the camera completely around; this bind   *
  *   will reset the camera when the key is released.                          *
  ****************************************************************************]]
function me.FlipView ()
	FlipCameraYaw( 180 );
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewOut                                         *
  * Description: Key binding to zoom the camera away from the character.       *
  ****************************************************************************]]
function me.MoveViewOut ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewOutStart();
	else
		MoveViewOutStop();
	end
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewIn                                          *
  * Description: Key binding to zoom the camera towards the character.         *
  ****************************************************************************]]
function me.MoveViewIn ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewInStart();
	else
		MoveViewInStop();
	end
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewRight                                       *
  * Description: Key binding to begin turning the character to the right.      *
  ****************************************************************************]]
function me.MoveViewRight ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewRightStart();
	else
		MoveViewRightStop();
	end
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewLeft                                        *
  * Description: Key binding to begin turning the character to the left.       *
  ****************************************************************************]]
function me.MoveViewLeft ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewLeftStart();
	else
		MoveViewLeftStop();
	end
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewDown                                        *
  * Description: Key binding to begin rotating the camera to look downwards.   *
  ****************************************************************************]]
function me.MoveViewDown ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewUpStart();
	else
		MoveViewUpStop();
	end
end
--[[****************************************************************************
  * Function: _Misc.Camera.MoveViewUp                                          *
  * Description: Key binding to begin rotating the camera to look upwards.     *
  ****************************************************************************]]
function me.MoveViewUp ( KeyState )
	if ( KeyState == "down" ) then
		MoveViewDownStart();
	else
		MoveViewDownStop();
	end
end

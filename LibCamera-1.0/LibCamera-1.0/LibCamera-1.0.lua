--[[****************************************************************************
  * LibCamera by Saiket                                                        *
  * LibCamera-1.0.lua - Keeps track of the camera's position.                  *
  ****************************************************************************]]


local MAJOR, MINOR = "LibCamera-1.0", 4;

local lib = LibStub:NewLibrary( MAJOR, MINOR );
if ( not lib ) then
	return;
end
lib.Events = lib.Events or LibStub( "CallbackHandler-1.0" ):New( lib, nil, nil, false );
lib.Updater = lib.Updater or CreateFrame( "Frame", nil, WorldFrame );


local Pitch;
local Yaw;
local Distance;

local YawOffset = 0;

local IsCameraMoving = false;

local EventsUsed = 0; -- Number of events registered for by addons


local AngleMinDelta = 1e-5; -- Minimum angle change to trigger an OnChanged event
local PI = math.pi;
local DegreesToRadians = PI / 180;
local EVENT_UPDATE, EVENT_UPDATEDISTANCE = "LibCamera_Update", "LibCamera_UpdateDistance";




--[[****************************************************************************
  * Function: lib.Updater:OnUpdate                                             *
  * Description: Saves the camera position every frame.                        *
  ****************************************************************************]]
do
	local SaveView = SaveView;
	local IsMouselooking = IsMouselooking;
	local GetPlayerFacing = GetPlayerFacing;
	local GetCVar = GetCVar;
	local SetCVar = SetCVar;
	local tonumber = tonumber;
	local abs = abs;

	local Changed, NewPitch, NewYaw, NewDistance;
	local OriginalPitch, OriginalYaw, OriginalDistance;

	function lib.Updater:OnUpdate ( Elapsed )
		Changed = false;

		-- Backup any existing camera data
		OriginalPitch = GetCVar( "cameraPitchD" );
		OriginalYaw = GetCVar( "cameraYawD" );
		OriginalDistance = GetCVar( "cameraDistanceD" );

		-- Cache current camera information
		SaveView( 5 );
		NewPitch = DegreesToRadians * GetCVar( "cameraPitchD" );
		-- Note: A pitch of zero (exactly) indicates an error related to pitchLimit CVar, so disregard
		if ( not Pitch or ( NewPitch ~= 0 and abs( NewPitch - Pitch ) >= AngleMinDelta ) ) then
			Pitch = NewPitch;
			Changed = true;
		end
		NewYaw = DegreesToRadians * GetCVar( "cameraYawD" ) + YawOffset;
		if ( not ( IsCameraMoving or IsMouselooking() ) ) then -- Camera angle relative to player face
			NewYaw = NewYaw + GetPlayerFacing();
		end
		NewYaw = NewYaw % ( PI * 2 );
		if ( not Yaw or abs( NewYaw - Yaw ) >= AngleMinDelta ) then
			Yaw = NewYaw;
			Changed = true;
		end
		NewDistance = tonumber( GetCVar( "cameraDistanceD" ) );
		if ( NewDistance ~= Distance ) then
			Distance = NewDistance;
			Changed = true;
			lib:OnChangedDistance();
		end

		-- Restore original camera data
		SetCVar( "cameraPitchD", OriginalPitch );
		SetCVar( "cameraYawD", OriginalYaw );
		SetCVar( "cameraDistanceD", OriginalDistance );


		if ( Changed ) then
			lib:OnChanged();
		end
	end
end


--[[****************************************************************************
  * Function: lib.Events:OnUsed                                                *
  * Description: Begins updating camera positions.                             *
  ****************************************************************************]]
function lib.Events:OnUsed ( Target, Event )
	if ( Event == EVENT_UPDATE or Event == EVENT_UPDATEDISTANCE ) then
		if ( EventsUsed == 0 ) then
			Target.Updater:Show();
			Target.Updater:OnUpdate( math.huge ); -- Force instant update
		end
		EventsUsed = EventsUsed + 1;
	end
end
--[[****************************************************************************
  * Function: lib.Events:OnUnused                                              *
  * Description: Stops updating camera positions.                              *
  ****************************************************************************]]
function lib.Events:OnUnused ( Target, Event )
	if ( Event == EVENT_UPDATE or Event == EVENT_UPDATEDISTANCE ) then
		EventsUsed = EventsUsed - 1;
		if ( EventsUsed == 0 ) then
			Target.Updater:Hide();
			Pitch, Yaw, Distance = nil; -- Clear cache
		end
	end
end


--[[****************************************************************************
  * Function: lib.GetCameraDistance                                            *
  * Description: Returns the camera's distance from the player in yards, or    *
  *   nil if unknown.  At lease one callback must be registered for this       *
  *   function to update.                                                      *
  ****************************************************************************]]
function lib.GetCameraDistance ()
	return Distance;
end
--[[****************************************************************************
  * Function: lib.GetCameraPosition                                            *
  * Description: Returns the camera pitch and yaw in radians and distance from *
  *   the player in yards, or nil if unknown.  At lease one callback must be   *
  *   registered for this function to update.                                  *
  ****************************************************************************]]
function lib.GetCameraPosition ()
	return Pitch, Yaw, lib.GetCameraDistance();
end
--[[****************************************************************************
  * Function: lib:OnChangedDistance                                            *
  * Description: Fired when the player's camera zoom changes.                  *
  ****************************************************************************]]
function lib:OnChangedDistance ()
	self.Events:Fire( EVENT_UPDATEDISTANCE, self.GetCameraDistance() );
end
--[[****************************************************************************
  * Function: lib:OnChanged                                                    *
  * Description: Fired when the player's camera moves.                         *
  ****************************************************************************]]
function lib:OnChanged ()
	self.Events:Fire( EVENT_UPDATE, self.GetCameraPosition() );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	lib.Updater:Hide();
	lib.Updater:SetScript( "OnUpdate", lib.Updater.OnUpdate );

	-- Hook camera movement
	hooksecurefunc( "CameraOrSelectOrMoveStart", function ()
		IsCameraMoving = true;
	end );
	hooksecurefunc( "CameraOrSelectOrMoveStop", function ()
		IsCameraMoving = false;
	end );
	hooksecurefunc( "FlipCameraYaw", function ( Offset )
		YawOffset = ( YawOffset + Offset * DegreesToRadians ) % ( PI * 2 );
	end );
end

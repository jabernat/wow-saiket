--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Frames.lua - Allows point and click frame identification.             *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local NS = CreateFrame( "Frame" );
_Dev.Frames = NS;

NS.Enabled = false;
NS.Interactive = false;

local Primary = CreateFrame( "Frame", nil, NS, "_DevBorderTemplate" );
NS.Primary = Primary;
local Auxiliary = CreateFrame( "Frame", nil, NS, "_DevBorderTemplate" );
NS.Auxiliary = Auxiliary;




--[[****************************************************************************
  * Function: _Dev.Frames.ToString                                             *
  * Description: Creates a string representation of a UIObject.                *
  ****************************************************************************]]
function NS.ToString ( UIObject )
	return UIObject
		and L.FRAMES_UIOBJECT_FORMAT:format( UIObject:GetObjectType(), _Dev.Dump.ToString( UIObject:GetName() ) )
		or _Dev.Dump.ToString( nil );
end
--[[****************************************************************************
  * Function: _Dev.Frames.GetTarget                                            *
  * Description: Returns the active target frame, primary or auxiliary.        *
  ****************************************************************************]]
function NS.GetTarget ()
	return Auxiliary.Target or Primary.Target;
end
--[[****************************************************************************
  * Function: _Dev.Frames.GetMouseFocus                                        *
  * Description: Gets the mouse focus, and never the outline frame.            *
  ****************************************************************************]]
function NS.GetMouseFocus ()
	if ( NS.Interactive and Primary.Target ) then
		return Primary.Target;
	else
		local Target = GetMouseFocus();
		if ( Target ~= WorldFrame ) then
			return Target;
		end
	end
end




--[[****************************************************************************
  * Function: _Dev.Frames.Primary:SetTarget                                    *
  * Description: Shows the primary outline on the specified frame.             *
  ****************************************************************************]]
function Primary:SetTarget ( Target )
	if ( Target ) then
		if ( self.Target ~= Target ) then
			self.Target = Target;
			self:SetAllPoints( Target );
			self:Show();
		end
		local Strata = Target:GetFrameStrata();
		self:SetFrameStrata( Strata == "UNKNOWN" and "BACKGROUND" or Strata );
		self:SetFrameLevel( Target:GetFrameLevel() + 1 );

		return true;
	elseif ( self.Target ) then
		self:ClearTarget();
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Primary:ClearTarget                                  *
  * Description: Hides the primary and auxiliary outlines.                     *
  ****************************************************************************]]
function Primary:ClearTarget ()
	self.Target = nil;
	self:Hide();
end


--[[****************************************************************************
  * Function: _Dev.Frames.Primary:OnMouseUp                                    *
  * Description: Handles various clicks on the primary frame.                  *
  ****************************************************************************]]
function Primary:OnMouseUp ( Button )
	local Target = NS.GetTarget();

	if ( IsModifiedClick( "_DEV_FRAMES_OUTLINE" ) ) then
		-- Outline frame
		_Dev.Outline.Toggle( Target, L.FRAMES_MOUSEFOCUS );
	end
	if ( IsModifiedClick( "_DEV_FRAMES_NAME" ) ) then
		-- Print brief summary to chat
		_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_BRIEF_FORMAT:format( NS.ToString( Target ), NS.ToString( Target:GetParent() ) ) ) );
	end
	if ( IsModifiedClick( "_DEV_FRAMES_DUMP" ) ) then
		-- Dump frame in full
		_Dev.Dump.Explore( L.FRAMES_MOUSEFOCUS, Target );
	end
end




--[[****************************************************************************
  * Function: _Dev.Frames:OnUpdate                                             *
  * Description: Searches for a new focus frame every update.                  *
  ****************************************************************************]]
function NS:OnUpdate ()
	Primary:SetTarget( NS.GetMouseFocus() );
end


--[[****************************************************************************
  * Function: _Dev.Frames.SetInteractive                                       *
  * Description: Sets whether or not the outline is in interactive mode.       *
  ****************************************************************************]]
function NS.SetInteractive ( Enable )
	if ( NS.Interactive ~= Enable ) then
		NS.Interactive = Enable;
		Primary:EnableMouse( Enable );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Enable                                               *
  * Description: Enables the mouse focus module.                               *
  ****************************************************************************]]
function NS.Enable ()
	if ( not NS.Enabled ) then
		NS.Enabled = true;
		NS:Show();

		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Disable                                              *
  * Description: Disables the mouse focus module and hides all outlines.       *
  ****************************************************************************]]
function NS.Disable ()
	if ( NS.Enabled ) then
		NS.Enabled = false;
		Primary:ClearTarget();
		NS:Hide();

		return true;
	end
end


--[[****************************************************************************
  * Function: _Dev.Frames.Toggle                                               *
  * Description: Toggles enabled or disabled status, and prints any details.   *
  ****************************************************************************]]
function NS.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not NS.Enabled;
	end

	if ( Enable ) then
		if ( NS.Enable() ) then
			_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_ENABLED ) );
		end
	else
		if ( NS.Disable() ) then
			_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_DISABLED ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.ToggleSlashCommand                                   *
  * Description: Slash command chat handler for _Dev.Frames.Toggle.            *
  ****************************************************************************]]
function NS.ToggleSlashCommand ()
	NS.Toggle();
end




NS:Hide();
NS:SetScript( "OnUpdate", NS.OnUpdate );

Primary:SetScript( "OnMouseUp", Primary.OnMouseUp );
Primary:EnableMouse( false ); -- Enabled by SetScript
Primary:EnableMouseWheel( true );
Primary:SetScale( 2.0 );

for _, Region in ipairs( { Primary:GetRegions() } ) do
	Region:SetVertexColor( L.COLOR.r, L.COLOR.g, L.COLOR.b );
end

SlashCmdList[ "_DEV_FRAMESTOGGLE" ] = NS.ToggleSlashCommand;
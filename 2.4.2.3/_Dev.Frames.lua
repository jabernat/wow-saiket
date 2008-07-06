--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Frames.lua - Allows point and click frame identification.             *
  *                                                                            *
TODO(
Add informational tooltip to outline frame {not GameTooltip}.

...

Scrollwheel creates auxiliary focus for frames below the current.
	If no aux focus, dim real focus and outline frame below it.
	If at frame just below and moving up, restore real focus and hide aux focus.
	When real focus changes, remove aux focus.
	Store only reference to aux frame {no "depth", etc.} and dynamically find the next lowest frame by EnumerateFrames on mousewheel.

...

Use alt modifier event to add mouse-enabled outline frames over regions in the current focus.
	On mousing over region outlines, add tooltip.
)
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local me = CreateFrame( "Frame" );
_Dev.Frames = me;

me.Enabled = false;
me.Interactive = false;

local Primary = CreateFrame( "Frame", nil, me, "_DevBorderTemplate" );
me.Primary = Primary;
local Auxiliary = CreateFrame( "Frame", nil, me, "_DevBorderTemplate" );
me.Auxiliary = Auxiliary;




--[[****************************************************************************
  * Function: _Dev.Frames.ToString                                             *
  * Description: Creates a string representation of a UIObject.                *
  ****************************************************************************]]
function me.ToString ( UIObject )
	return UIObject
		and L.FRAMES_UIOBJECT_FORMAT:format( UIObject:GetObjectType(), _Dev.Dump.ToString( UIObject:GetName() ) )
		or _Dev.Dump.ToString( nil );
end
--[[****************************************************************************
  * Function: _Dev.Frames.GetTarget                                            *
  * Description: Returns the active target frame, primary or auxiliary.        *
  ****************************************************************************]]
function me.GetTarget ()
	return Auxiliary.Target or Primary.Target;
end
--[[****************************************************************************
  * Function: _Dev.Frames.GetMouseFocus                                        *
  * Description: Gets the mouse focus, and never the outline frame.            *
  ****************************************************************************]]
function me.GetMouseFocus ()
	if ( me.Interactive and Primary.Target ) then
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
  * Function: _Dev.Frames.Primary:OnMouseWheel                                 *
  * Description: Handles scrolling through covered frames.                     *
  ****************************************************************************]]
function Primary:OnMouseWheel ( Delta )
	if ( Delta > 0 ) then -- Drill down
		--_Dev.Print"DOWN"
	else -- Climb out
		--_Dev.Print"UP"
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Primary:OnMouseUp                                    *
  * Description: Handles various clicks on the primary frame.                  *
  ****************************************************************************]]
function Primary:OnMouseUp ( Button )
	local Target = me.GetTarget();

	if ( IsModifiedClick( "_DEV_FRAMES_OUTLINE" ) ) then
		-- Outline frame
		_Dev.Outline.Toggle( Target, L.FRAMES_MOUSEFOCUS );
	end
	if ( IsModifiedClick( "_DEV_FRAMES_NAME" ) ) then
		-- Print brief summary to chat
		_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_BRIEF_FORMAT:format( me.ToString( Target ), me.ToString( Target:GetParent() ) ) ) );
	end
	if ( IsModifiedClick( "_DEV_FRAMES_DUMP" ) ) then
		-- Dump frame in full
		_Dev.Dump.Explore( Target, L.FRAMES_MOUSEFOCUS );
	end
end




--[[****************************************************************************
  * Function: _Dev.Frames:OnUpdate                                             *
  * Description: Searches for a new focus frame every update.                  *
  ****************************************************************************]]
function me:OnUpdate ()
	Primary:SetTarget( me.GetMouseFocus() );
end


--[[****************************************************************************
  * Function: _Dev.Frames.SetInteractive                                       *
  * Description: Sets whether or not the outline is in interactive mode.       *
  ****************************************************************************]]
function me.SetInteractive ( Enable )
	if ( me.Interactive ~= Enable ) then
		me.Interactive = Enable;
		Primary:EnableMouse( Enable );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Enable                                               *
  * Description: Enables the mouse focus module.                               *
  ****************************************************************************]]
function me.Enable ()
	if ( not me.Enabled ) then
		me.Enabled = true;
		me:Show();

		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.Disable                                              *
  * Description: Disables the mouse focus module and hides all outlines.       *
  ****************************************************************************]]
function me.Disable ()
	if ( me.Enabled ) then
		me.Enabled = false;
		Primary:ClearTarget();
		me:Hide();

		return true;
	end
end


--[[****************************************************************************
  * Function: _Dev.Frames.Toggle                                               *
  * Description: Toggles enabled or disabled status, and prints any details.   *
  ****************************************************************************]]
function me.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not me.Enabled;
	end

	if ( Enable ) then
		if ( me.Enable() ) then
			_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_ENABLED ) );
		end
	else
		if ( me.Disable() ) then
			_Dev.Print( L.FRAMES_MESSAGE_FORMAT:format( L.FRAMES_DISABLED ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Frames.ToggleSlashCommand                                   *
  * Description: Slash command chat handler for _Dev.Frames.Toggle.            *
  ****************************************************************************]]
function me.ToggleSlashCommand ()
	me.Toggle();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetScript( "OnUpdate", me.OnUpdate );

	Primary:SetScript( "OnMouseWheel", Primary.OnMouseWheel );
	Primary:SetScript( "OnMouseUp", Primary.OnMouseUp );
	Primary:EnableMouseWheel( true );
	Primary:SetScale( 2.0 );

	for _, Region in ipairs( { Primary:GetRegions() } ) do
		Region:SetVertexColor( L.COLOR.r, L.COLOR.g, L.COLOR.b );
	end

	SlashCmdList[ "DEV_FRAMESTOGGLE" ] = me.ToggleSlashCommand;
end

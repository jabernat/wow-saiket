-- StateMachine.lua by Saiket
-- Simple state machine template


--- Prototype of State object.
local StateMeta = { __index = {}; };
--- Gets this state's controlling state machine.
-- @return Controlling state machine table.
function StateMeta.__index:GetMachine ()
	return self.Machine;
end
--- Gets whether this state is active or not.
-- @return True if this state is active.
function StateMeta.__index:IsActive ()
	return self.Machine:GetActiveState() == self;
end
--- Activates this state, replacing the previously active state.
-- @param ...  Arguments to pass to this state's OnActivate handler.
-- @return True if state changed successfully.
function StateMeta.__index:Activate ( ... )
	return self.Machine:SetActiveState( self, ... );
end
--- Deactivates this state.
-- @return True if state successfully deactivated.
function StateMeta.__index:Deactivate ()
	return self:IsActive() and self.Machine:SetActiveState( nil );
end




--- Prototype of StateMachine object.
local MachineMeta = { __index = {}; };
--- Adds a new state to the state machine.
-- @return The created State object.
function MachineMeta.__index:NewState ()
	return setmetatable( {
		Machine = self;
	}, StateMeta );
end
--- Gets the active State object.
-- @return The active State object, or nil if none.
function MachineMeta.__index:GetActiveState ()
	return self.ActiveState;
end
--- Sets the active State.
-- @param State  State to activate, or nil to deactivate.
-- @param ...  Arguments to pass to the new state's OnActivate handler.
-- @return True if changed state.
function MachineMeta.__index:SetActiveState ( State, ... )
	if ( self.ActiveState ~= State ) then
		local OldState = self.ActiveState;
		self.ActiveState = State;

		if ( OldState and OldState.OnDeactivate ) then
			OldState:OnDeactivate();
		end
		if ( State and State.OnActivate ) then
			State:OnActivate( ... );
		end
		return true;
	end
end




--- Creates a new state machine.
-- @return State machine object.
local NS = select( 2, ... );
function NS.NewStateMachine ()
	return setmetatable( {}, MachineMeta );
end
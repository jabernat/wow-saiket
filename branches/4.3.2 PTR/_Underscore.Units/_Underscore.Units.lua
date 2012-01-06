--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * _Underscore.Units.lua - Modifies the default unit frames.                  *
  ****************************************************************************]]


local NS = select( 2, ... );
_Underscore.Units = NS;




do
	local DropDown = CreateFrame( "Frame", "_UnderscoreUnitsDropDown", UIParent, "UIDropDownMenuTemplate" );
	--- Constructs the unit popup menu.
	function DropDown:initialize ()
		local UnitID = self.unit or "player";
		local Which, Name, ID;

		if ( UnitIsUnit( UnitID, "player" ) ) then
			Which = "SELF";
		elseif ( UnitIsUnit( UnitID, "pet" ) ) then
			Which = "PET";
		elseif ( UnitIsPlayer( UnitID ) ) then
			ID = UnitInRaid( UnitID );
			if ( ID ) then
				Which = "RAID_PLAYER";
			elseif ( UnitInParty( UnitID ) ) then
				Which = "PARTY";
			else
				Which = "PLAYER";
			end
		else
			Which, Name = "RAID_TARGET_ICON", RAID_TARGET_ICON;
		end
		if ( Which ) then
			UnitPopup_ShowMenu( self, Which, UnitID, Name, ID );
		end
	end
	--- Adds a unit popup at the cursor for the given unit.
	-- @param UnitID  Unit to show a dropdown menu for.
	function NS:ShowGenericMenu ( UnitID )
		HideDropDownMenu( 1 );

		DropDown.unit = UnitID or SecureButton_GetUnit( self );
		if ( DropDown.unit ) then
			ToggleDropDownMenu( 1, nil, DropDown, "cursor" );
		end
	end

	tinsert( UnitPopupFrames, DropDown:GetName() );
	UIDropDownMenu_Initialize( DropDown, DropDown.initialize, "MENU" );
end




do
	local TargetNoise = CreateFrame( "Frame" );
	--- Plays target gained/lost sounds from the default UI when changing target or focus.
	function TargetNoise:OnEvent ( Event )
		local UnitID = Event == "PLAYER_FOCUS_CHANGED" and "focus" or "target";
		PlaySound( UnitExists( UnitID ) and "igCharacterSelect" or "igCharacterDeselect" );
	end
	TargetNoise:SetScript( "OnEvent", TargetNoise.OnEvent );
	TargetNoise:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	TargetNoise:RegisterEvent( "PLAYER_FOCUS_CHANGED" );
end




-- Disable default buff frame
BuffFrame:UnregisterAllEvents();
local Hidden = CreateFrame( "Frame" );
Hidden:Hide();
BuffFrame:SetParent( Hidden );
ConsolidatedBuffs:SetParent( Hidden );
ConsolidatedBuffsTooltip:SetParent( Hidden );
TemporaryEnchantFrame:SetParent( Hidden );
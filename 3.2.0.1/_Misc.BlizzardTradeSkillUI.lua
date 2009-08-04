--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.BlizzardTradeSkillUI.lua - Modifies the Blizzard_TradeSkillUI addon. *
  *                                                                            *
  * + If you click a reagent for a craftable item and the reagent itself is    *
  *   craftable by the same profession, that skill will be displayed.          *
  * + Expands the list to show 24 items per screen.                            *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {
	MaxSkills = 24;
};
_Misc.BlizzardTradeSkillUI = me;




--[[****************************************************************************
  * Function: _Misc.BlizzardTradeSkillUI:ReagentOnClick                        *
  * Description: If the reagent is also crafted by the same skill, jumps to    *
  *   that recipe in the tradeskill list.                                      *
  ****************************************************************************]]
function me:ReagentOnClick ()
	if ( not IsModifierKeyDown() ) then
		-- Search skills and jump to reagent if found
		local ReagentName = GetTradeSkillReagentInfo( GetTradeSkillSelectionIndex(), self:GetID() );
		for Index = 1, GetNumTradeSkills() do
			local Name, Type = GetTradeSkillInfo( Index );
			-- Assumes all headers are expanded
			if ( Type ~= "header" and Name == ReagentName ) then
				TradeSkillFrame_SetSelection( Index );
				TradeSkillFrame_Update();
				break;
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "Blizzard_TradeSkillUI", function ()
		for Index = 1, MAX_TRADE_SKILL_REAGENTS do
			local Button = _G[ "TradeSkillReagent"..Index ];
	
			Button:HookScript( "OnClick", me.ReagentOnClick );
		end

		TradeSkillFrame:SetHeight( 768 );
		TradeSkillListScrollFrame:SetHeight( 386 );
		TradeSkillHorizontalBarLeft:SetPoint( "TOPLEFT", 15, -477 );
		TradeSkillDetailScrollFrame:SetPoint( "TOPLEFT", 20, -490 );
		TradeSkillCreateButton:SetPoint( "CENTER", TradeSkillFrame, "TOPLEFT", 224, -678 );
		TradeSkillCancelButton:SetPoint( "CENTER", TradeSkillFrame, "TOPLEFT", 305, -678 );

		-- Patch the hole with two new textures stretched between it
		local Texture = TradeSkillFrame:CreateTexture( nil, "BORDER" );
		Texture:SetWidth( 256 );
		Texture:SetHeight( 256 );
		Texture:SetPoint( "TOPLEFT", 0, -256 );
		Texture:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopLeft" );
		Texture:SetTexCoord( 0, 1, 0.4, 1 );
		Texture = TradeSkillFrame:CreateTexture( nil, "BORDER" );
		Texture:SetWidth( 128 );
		Texture:SetHeight( 256 );
		Texture:SetPoint( "TOPRIGHT", 0, -256 );
		Texture:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopRight" );
		Texture:SetTexCoord( 0, 1, 0.4, 1 );
		Texture = TradeSkillListScrollFrame:CreateTexture( nil, "BACKGROUND" );
		Texture:SetWidth( 32 );
		Texture:SetHeight( 147 );
		Texture:SetPoint( "TOPLEFT", TradeSkillListScrollFrame, "TOPRIGHT", -2, -118 );
		Texture:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
		Texture:SetTexCoord( 0, 0.484375, 0.125, 1 );


		-- Add the extra lines
		for Index = TRADE_SKILLS_DISPLAYED + 1, me.MaxSkills do
			local Button = CreateFrame( "Button", "TradeSkillSkill"..Index, TradeSkillFrame, "TradeSkillSkillButtonTemplate" );
			Button:SetPoint( "TOPLEFT", "TradeSkillSkill"..( Index - 1 ), "BOTTOMLEFT" );
		end
		TRADE_SKILLS_DISPLAYED = max( me.MaxSkills, TRADE_SKILLS_DISPLAYED );
	end );
end

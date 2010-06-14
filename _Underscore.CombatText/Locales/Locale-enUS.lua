--[[****************************************************************************
  * _Underscore.CombatText by Saiket                                           *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


_UnderscoreLocalization.CombatText = setmetatable( {
	HEAL_FORMAT = "%s +%d %s"; -- Caster, Amount, Target
	OVERHEAL_FORMAT = "%s +%d %s {%d}"; -- Caster, Amount, Target, Overhealed
}, getmetatable( _UnderscoreLocalization ) );
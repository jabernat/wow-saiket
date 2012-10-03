# -*- coding: utf_8 -*-
"""Generates a complete _NPCScan options file."""

import os.path

import wowdata.dbc as dbc
import wowdata.lua
import wowdata.mpq
import wowdata.wowhead

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'GPL'

_KILL_ACHIEVEMENTS = set((  # Rare mob achievements tracked by _NPCScan
  1312,  # Bloody Rare
  2257,  # Frostbitten
  7439,  # Glorious!
))
_KILL_CRITERIA_TYPE = 0  # Criteria TypeID for NPC kills

def write(output_filename, data_path, locale):
  """Writes a settings file including all rare mobs from Wowhead."""
  output_filename = os.path.normcase(output_filename)
  data_path = os.path.normcase(data_path)
  print 'Writing all rares from {:s} Wowhead to <{:s}>...'.format(locale, output_filename)
  npcs = wowdata.wowhead.get_npcs_all_levels(locale, cl='2:4')  # Rare and rare elite

  with wowdata.mpq.open_dbc_mpq(data_path, locale) as archive:
    # Remove NPCs that _NPCScan already tracks as part of achievements
    print '\tRemoving achievement criteria rares...'
    with dbc.DBC(archive.open('DBFilesClient/Achievement.dbc'),
      'id', None, None, 'criteria_parent', 'name') as achievements \
    :
      achievements.rows = {achievement.int('id'): achievement for achievement in achievements}
      kill_achievements = set()
      def add_kill_achievement(achievement_id):
        """Adds an achievement and all its parents to the filter."""
        achievement = achievements.rows[achievement_id]
        print '\t\tAchievement{:d} - {!r}'.format(achievement_id, achievement.str('name'))
        kill_achievements.add(achievement_id)
        parent_id = achievement.int('criteria_parent')
        if parent_id:
          add_kill_achievement(parent_id)
      for achievement_id in _KILL_ACHIEVEMENTS:
        add_kill_achievement(achievement_id)
    with dbc.DBC(archive.open('DBFilesClient/Achievement_Criteria.dbc'),
      'id', 'achievement_id', 'type', 'asset_id') as achievement_criteria \
    :
      for criteria in achievement_criteria:
        if (criteria.int('achievement_id') in kill_achievements
          and criteria.int('type') == _KILL_CRITERIA_TYPE
        ):
          npc_id = criteria.int('asset_id')
          if npc_id in npcs:
            del npcs[npc_id]

    # Generate ContinentIDs that match in-game APIs
    with dbc.DBC(archive.open('DBFilesClient/WorldMapArea.dbc'),
      'id', 'map_id', 'area_id', flags=11) as worldmaps \
    :
      worldmaps.rows = {worldmap.int('id'): worldmap for worldmap in worldmaps}
      FLAG_PHASE = 0x2
      map_continent_ids = {map_id: continent_id
        for continent_id, map_id in enumerate(start=1, sequence=(worldmap.int('map_id')
          for worldmap_id, worldmap in sorted(worldmaps.rows.iteritems())  # Ordered by WorldMapID
            if not worldmap.int('area_id')  # Is a continent
              and not worldmap.int('flags') & FLAG_PHASE))}  # Not a phased map

    with \
      dbc.DBC(archive.open('DBFilesClient/AreaTable.dbc'),
        'id', 'map_id', name=13) as areas, \
      dbc.DBC(archive.open('DBFilesClient/Map.dbc'),
        'id', name=5, area_id=7) as maps \
    :
      areas.rows = {area.int('id'): area for area in areas}
      maps.rows = {map.int('id'): map for map in maps}

      def get_world_id(area_id):
        """Returns a "WorldID" for the map containing the given area ID."""
        map_id = areas.rows[area_id].int('map_id')
        if map_id in map_continent_ids:
          return map_continent_ids[map_id]
        else:  # Use localized name
          area_id = maps.rows[map_id].int('area_id')
          row = areas.rows[area_id] if area_id else maps.rows[map_id]
          return row.str('name')

      with open(output_filename, 'w+b') as output:
        output.write('_NPCScanOptionsCharacter = {\n')
        output.write('\tVersion = "4.0.3.5";\n')
        output.write('\tAchievements = {\n')
        for achievement_id in sorted(_KILL_ACHIEVEMENTS):
          output.write('\t\t[ ' + str(achievement_id) + ' ] = true;\n')
        output.write('\t};\n')
        output.write('\tNPCs = {\n')
        for npc_id, npc_data in sorted(npcs.iteritems()):
          output.write('\t\t[ ' + str(npc_id) + ' ] = '
            + wowdata.lua.escape_data(npc_data['name']) + ';\n')
        output.write('\t};\n')
        output.write('\tNPCWorldIDs = {\n')
        for npc_id, npc_data in sorted(npcs.iteritems()):
          if 'location' in npc_data:
            world_ids = set(get_world_id(area_id) for area_id in npc_data['location'])
            if len(world_ids) == 1:  # Only spawns on one map
              world_id = world_ids.pop()
              if isinstance(world_id, unicode):
                output.write('\t\t[ ' + str(npc_id) + ' ] = '
                  + wowdata.lua.escape_data(world_id.encode('utf_8')) + ';\n')
              else: # ContinentID
                output.write('\t\t[ ' + str(npc_id) + ' ] = ' + str(world_id) + ';\n')
        output.write('\t};\n')
        output.write('};')


if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(
    description='Generates a complete _NPCScan options file including all know rares.')
  parser.add_argument('--locale', '-l', type=unicode, required=True,
    help='Locale code to retrieve data for.')
  parser.add_argument('data_path', type=unicode,
    help='The path to World of Warcraft\'s Data folder.')
  parser.add_argument('output_filename', type=unicode,
    help='Output path for the resulting Lua source file.')
  write(**vars(parser.parse_args()))
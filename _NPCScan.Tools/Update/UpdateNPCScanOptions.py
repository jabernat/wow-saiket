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
))
_KILL_CRITERIA_TYPE = 0  # Criteria TypeID for NPC kills

def updateNPCScanOptions(dataPath, outputFilename, locale):
  """Writes a settings file including all rare mobs from Wowhead."""
  dataPath = os.path.normcase(dataPath)
  outputFilename = os.path.normcase(outputFilename)
  print 'Writing all rares from %s Wowhead to <%s>...' % (locale, outputFilename)
  npcs = wowdata.wowhead.getNPCsAllLevels(locale, cl='2:4')  # Rare and rare elite

  with wowdata.mpq.openLocaleMPQ(dataPath, locale) as archive:
    # Remove NPCs that _NPCScan already tracks as part of achievements
    print '\tRemoving achievement criteria rares...'
    with dbc.DBC(archive.open('DBFilesClient/Achievement.dbc'),
      'id', None, None, 'criteriaParent', 'name') as achievements \
    :
      achievements.rows = {achievement.int('id'): achievement for achievement in achievements}
      killAchievements = set()
      def addKillAchievement(achievementID):
        """Adds an achievement and all its parents to the filter."""
        achievement = achievements.rows[achievementID]
        print '\t\tAchievement%d - %r' % (achievementID, achievement.str('name'))
        killAchievements.add(achievementID)
        parentID = achievement.int('criteriaParent')
        if parentID:
          addKillAchievement(parentID)
      for achievementID in _KILL_ACHIEVEMENTS:
        addKillAchievement(achievementID)
    with dbc.DBC(archive.open('DBFilesClient/Achievement_Criteria.dbc'),
      'id', 'achievementID', 'type', 'assetID') as achievementCriteria \
    :
      for criteria in achievementCriteria:
        if (criteria.int('achievementID') in killAchievements
          and criteria.int('type') == _KILL_CRITERIA_TYPE
        ):
          npcID = criteria.int('assetID')
          if npcID in npcs:
            del npcs[npcID]

    # Generate ContinentIDs that match in-game APIs
    with dbc.DBC(archive.open('DBFilesClient/WorldMapArea.dbc'),
      'id', 'mapID', 'areaID', flags=11) as worldMapAreas \
    :
      worldMapAreas.rows = {worldMap.int('id'): worldMap for worldMap in worldMapAreas}
      FLAG_PHASE = 0x2
      mapContinentIDs = {mapID: continentID
        for continentID, mapID in enumerate(start=1, sequence=(worldMap.int('mapID')
          for worldMapID, worldMap in sorted(worldMapAreas.rows.iteritems())  # Ordered by WorldMapID
            if not worldMap.int('areaID')  # Is a continent
              and not worldMap.int('flags') & FLAG_PHASE))}  # Not a phased map

    with \
      dbc.DBC(archive.open('DBFilesClient/AreaTable.dbc'),
        'id', 'mapID', 'parentID', name=11) as areaTable, \
      dbc.DBC(archive.open('DBFilesClient/Map.dbc'),
        'id', name=6, areaID=7) as maps \
    :
      areaTable.rows = {area.int('id'): area for area in areaTable}
      maps.rows = {map.int('id'): map for map in maps}

      def getAreaWorldID(areaID):
        """Returns a "WorldID" for the map containing the given area ID."""
        mapID = areaTable.rows[areaID].int('mapID')
        if mapID in mapContinentIDs:
          return mapContinentIDs[mapID]
        else:  # Use localized name
          areaID = maps.rows[mapID].int('areaID')
          row = areaTable.rows[areaID] if areaID else maps.rows[mapID]
          return row.str('name')

      with open(outputFilename, 'w+b') as output:
        output.write('_NPCScanOptionsCharacter = {\n')
        output.write('\tVersion = "4.0.3.5";\n')
        output.write('\tAchievements = {\n')
        for achievementID in sorted(_KILL_ACHIEVEMENTS):
          output.write('\t\t[ %d ] = true;\n' % achievementID)
        output.write('\t};\n')
        output.write('\tNPCs = {\n')
        for npcID, npcData in sorted(npcs.iteritems()):
          output.write('\t\t[ %d ] = %s;\n' % (npcID, wowdata.lua.escapeData(npcData['name'])))
        output.write('\t};\n')
        output.write('\tNPCWorldIDs = {\n')
        for npcID, npcData in sorted(npcs.iteritems()):
          if 'location' in npcData:
            worldIDs = set(getAreaWorldID(areaID) for areaID in npcData['location'])
            if len(worldIDs) == 1:  # Only spawns on one map
              worldID = worldIDs.pop()
              if isinstance(worldID, unicode):
                output.write('\t\t[ %d ] = %s;\n' % (
                  npcID, wowdata.lua.escapeData(worldID.encode('utf_8'))))
              else: # ContinentID
                output.write('\t\t[ %d ] = %d;\n' % (npcID, worldID))
        output.write('\t};\n')
        output.write('};')


if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(
    description='Generates a complete _NPCScan options file including all know rares.')
  parser.add_argument('--locale', '-l', type=unicode, required=True,
    help='Locale code to retrieve data for.')
  parser.add_argument('dataPath', type=unicode,
    help='The path to World of Warcraft\'s Data folder.')
  parser.add_argument('outputFilename', type=unicode,
    help='Output path for the resulting Lua source file.')
  updateNPCScanOptions(**vars(parser.parse_args()))
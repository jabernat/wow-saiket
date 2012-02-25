# -*- coding: utf_8 -*-
"""Runs all of _NPCScan.Tools' update scripts in turn."""

import os.path
import subprocess

import RoutesToObjs
import ObjsToOverlays
import UpdateTamableIDs
import UpdateNPCScanOptions
import UpdateNPCData

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'GPL'

def _path(*args):
  """Joins and normalizes case of all path parts."""
  return os.path.normcase(os.path.join(*args))


def updateAll(account=None, realm=None, character=None,
  dataPath=None, interfacePath=None, wtfPath=None, objPath=None, locale=None
):
  """Runs each update script with simplified path arguments."""
  print 'Running all update scripts...'
  if account is None:
    account = raw_input('Account name: ')
  if realm is None:
    realm = raw_input('Realm name: ')
  if character is None:
    character = raw_input('Character name: ')
  if locale is None:
    locale = 'enUS'

  dataPath = (_path(dataPath) if dataPath is not None
    else _path('..', '..', '..', '..', 'Data'))
  interfacePath = (_path(interfacePath) if interfacePath is not None
    else _path('..', '..', '..'))
  wtfPath = (_path(wtfPath) if wtfPath is not None
    else _path('..', '..', '..', '..', 'WTF'))
  objPath = (_path(objPath) if objPath is not None
    else _path('PathData'))

  print
  RoutesToObjs.routesToObjs(dataPath,
    _path(wtfPath, 'Account', account, 'SavedVariables', 'Routes.lua'), objPath)
  print
  ObjsToOverlays.objsToOverlays(objPath,
    _path(interfacePath, 'AddOns', '_NPCScan.Overlay', '_NPCScan.Overlay.PathData.lua'))
  print
  print 'Staging new *.obj files for commit...'
  try:
    subprocess.check_call(('svn', 'add', '--force', '--non-interactive', objPath))
  except (OSError, subprocess.CalledProcessError) as e:
    print '\t%r' % e
  print
  UpdateTamableIDs.updateTamableIDs(dataPath,
    _path(interfacePath, 'AddOns', '_NPCScan', '_NPCScan.TamableIDs.lua'), locale)
  print
  UpdateNPCScanOptions.updateNPCScanOptions(dataPath,
    _path(interfacePath, 'AddOns', '_NPCScan.Tools', '_NPCScan.lua'), locale)
  print
  UpdateNPCData.updateNPCData(dataPath,
    _path(interfacePath, 'AddOns', '_NPCScan.Tools', '_NPCScan.Tools.NPCData.lua'), locale)


if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(description='Runs all update scripts in turn, sharing common arguments.')
  parser.add_argument('--account', type=unicode,
    help='Name or full path of account-wide settings folder.')
  parser.add_argument('--realm', type=unicode,
    help='Name or full path of server-wide settings folder.')
  parser.add_argument('--character', type=unicode,
    help='Name or full path of character-wide settings folder.')
  parser.add_argument('--data', '-d', type=unicode, dest='dataPath',
    help='Path to WoW\'s Data folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--interface', '-i', type=unicode, dest='interfacePath',
    help='Path to WoW\'s Interface folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--wtf', '-w', type=unicode, dest='wtfPath',
    help='Path to WoW\'s WTF folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--objs', '-o', type=unicode, dest='objPath',
    help='Path to save overlay *.obj model files to.  Defaults to a PathData sub-directory if omitted.')
  parser.add_argument('--locale', '-l', type=unicode,
    help='Locale code to read and write data files for.')
  updateAll(**vars(parser.parse_args()))
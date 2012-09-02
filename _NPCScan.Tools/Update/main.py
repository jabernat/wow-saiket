# -*- coding: utf_8 -*-
"""Runs all of _NPCScan.Tools' update scripts in turn."""

import os.path
import subprocess

import npcscan_options
import npc_data
import objs_to_overlays
import routes_to_objs
import tamable_ids

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'GPL'

def _path(*args):
  """Joins and normalizes case of all path parts."""
  return os.path.normcase(os.path.join(*args))


def run_all(account=None, realm=None, character=None,
  data_path=None, interface_path=None, wtf_path=None, obj_path=None, locale=None
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

  data_path = (_path(data_path) if data_path is not None
    else _path('..', '..', '..', '..', 'Data'))
  interface_path = (_path(interface_path) if interface_path is not None
    else _path('..', '..', '..'))
  wtf_path = (_path(wtf_path) if wtf_path is not None
    else _path('..', '..', '..', '..', 'WTF'))
  obj_path = (_path(obj_path) if obj_path is not None
    else _path('geometry'))

  print
  routes_to_objs.write(obj_path,
    data_path, _path(wtf_path, 'Account', account, 'SavedVariables', 'Routes.lua'))
  print
  objs_to_overlays.write(
    _path(interface_path, 'AddOns', '_NPCScan.Overlay', '_NPCScan.Overlay.Geometry.lua'),
    obj_path)
  print
  print 'Staging new *.obj files for commit...'
  try:
    subprocess.check_call(('svn', 'add', '--force', '--non-interactive', obj_path))
  except (OSError, subprocess.CalledProcessError) as e:
    print '\t{!r}'.format(e)
  print
  '''
  tamable_ids.write(
    _path(interface_path, 'AddOns', '_NPCScan', '_NPCScan.TamableIDs.lua'),
    data_path, locale)
  print
  npcscan_options.write(
    _path(interface_path, 'AddOns', '_NPCScan.Tools', '_NPCScan.lua'),
    data_path, locale)
  print
  npc_data.write(
    _path(interface_path, 'AddOns', '_NPCScan.Tools', '_NPCScan.Tools.NPCData.lua'),
    data_path, locale)
  '''


if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(description='Runs all update scripts in turn, sharing common arguments.')
  parser.add_argument('--account', type=unicode,
    help='Name or full path of account-wide settings folder.')
  parser.add_argument('--realm', type=unicode,
    help='Name or full path of server-wide settings folder.')
  parser.add_argument('--character', type=unicode,
    help='Name or full path of character-wide settings folder.')
  parser.add_argument('--data', '-d', type=unicode, dest='data_path',
    help='Path to WoW\'s Data folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--interface', '-i', type=unicode, dest='interface_path',
    help='Path to WoW\'s Interface folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--wtf', '-w', type=unicode, dest='wtf_path',
    help='Path to WoW\'s WTF folder.  If omitted, assume the default location relative to this script.')
  parser.add_argument('--objs', '-o', type=unicode, dest='obj_path',
    help='Path to save overlay *.obj model files to.  Defaults to the "geometry" sub-directory if omitted.')
  parser.add_argument('--locale', '-l', type=unicode,
    help='Locale code to read and write data files for.')
  run_all(**vars(parser.parse_args()))
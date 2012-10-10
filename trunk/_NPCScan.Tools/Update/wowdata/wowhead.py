# -*- coding: utf_8 -*-
"""Shared routines to query Wowhead for game data."""

import contextlib
import re
import time
import urllib
import urllib2

import bs4
import PyV8

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'

_LOCALE_SUBDOMAINS = {  # Subdomains for localized Wowhead.com data
	'deDE': 'de',
	'enEU': 'www',
	'enUS': 'www',
	'esES': 'es',
	'esMX': 'es',
	'frFR': 'fr',
	'ptBR': 'pt',
	'ptPT': 'pt',
	'ruRU': 'ru',
}
_REQUEST_INTERVAL = 30  # Seconds between requests to Wowhead
_NPC_LEVEL_MIN = 0  # Querying level 0 returns mobs without a listed level
_NPC_LEVEL_MAX = 90 + 3  # Max rare mob level (+3 for boss level)
_NPC_LEVEL_UNKNOWN = 9999  # Sentinel value used for level "??"
_BEAUTIFULSOUP_PARSER = 'lxml'

class InvalidResultError(Exception):
  """Used when a requested web page can't be parsed properly."""
  pass

class EmptyResultError(Exception):
  """Used by `get_search_listview` when no results match a filter."""
  pass

class TruncatedResultsError(Exception):
  """Used when a listview query returns too many results.
  
  `args` attribute contains number of results total and returned.
  """
  pass


class _WH(PyV8.JSClass):
  """Wowhead JS utility function library stubs."""
  def sprintf(self, *args):
    """Joins printf arguments so they can easily be split later."""
    return '[' + ','.join(map(unicode, args)) + ']';


class _LANG(PyV8.JSClass):
  """Simulates Wowhead's localization constant lookup table by returning key names."""
  def __getattr__(self, name):
    """Identity function that returns the localization constant's name."""
    try:
      return super(_LANG, self).__getattr__(name)
    except AttributeError:
      return '<LANG.{:s}>'.format(name)


class _Globals(PyV8.JSClass):
  """JS global scope with simulated Wowhead APIs to intercept listview data."""
  LANG = _LANG()

  def __init__(self):
    self._listviews = {}

  def Listview(self, data):
    """Impersonates Wowhead's JS Listview constructor."""
    self._listviews[data['id']] = data
setattr(_Globals, '$WH', _WH())


class _MinInterval(object):
  """Decorator to enforce a minimum wait between calls."""
  def __init__(self, interval):
    self.interval, self.last_call = interval, 0

  def __call__(self, func):
    def wrapped(*args, **kwargs):
      interval_remaining = self.interval - (time.time() - self.last_call)
      if interval_remaining > 0:
        time.sleep(interval_remaining)
      returns = func(*args, **kwargs)
      self.last_call = time.time()  # Read after call, in case func takes a while
      return returns
    return wrapped


@_MinInterval(_REQUEST_INTERVAL)
def get_page(locale, query):
  """Returns a BeautifulSoup4 object for `query` from Wowhead's `locale` subdomain."""
  try:
    subdomain = _LOCALE_SUBDOMAINS[locale]
  except KeyError:
    raise ValueError('Unsupported locale code {!r}.'.format(locale))
  request = urllib2.Request('http://{:s}.wowhead.com/{:s}'.format(subdomain, query), unverifiable=True)
  with contextlib.closing(urllib2.urlopen(request)) as response:
    return bs4.BeautifulSoup(response.read(), _BEAUTIFULSOUP_PARSER,
      from_encoding=response.info().getparam('charset'))


def _percent_encode(value):
  """Percent encodes `value` for use in a URL."""
  return urllib.quote_plus(
    str(value.encode('utf_8') if isinstance(value, unicode) else value))


def get_search_listview(type, locale, **filters):
  """Returns listview data of the given search from Wowhead.

  `filters` are used as search query parameters.
  """
  query = '{:s}?filter={:s}'.format(type, ';'.join(
    '{:s}={:s}'.format(*map(_percent_encode, item)) for item in filters.iteritems()))
  page = get_page(locale, query)
  div = page.find('div', id='lv-' + type)
  if div is None:
    raise EmptyResultError()
  try:
    script = div.find_next_sibling('script', type='text/javascript').get_text()
  except AttributeError:
    raise InvalidResultError('{!r} listview script not found for query {!r}.'.format(type, query))

  # Run JS source and intercept Listview definitions
  with PyV8.JSContext(_Globals()) as context:
    context.eval(script.encode('utf_8'))
    listviews = context.locals._listviews

  if type not in listviews:
    raise InvalidResultError('{!r} listview not initialized for query {!r}.'.format(type, query))
  elif '_errors' in listviews[type]:
    raise InvalidResultError('Invalid {!r} query filter {!r}.'.format(type, query))
  elif '_truncated' in listviews[type]:
    note = listviews[type]['note'].decode('utf_8')
    match = re.search(r'\[<LANG\.lvnote_' + re.escape(type) + 'found>,(?P<total>\d+),(?P<displayed>\d+)\]', note)
    if match is None:
      raise InvalidResultError('Result total not found in view note {!r}.'.format(note))
    raise TruncatedResultsError(int(match.group('total')), int(match.group('displayed')))
  return listviews[type]


def get_search_results(type, locale, **filters):
  """Returns a `dict` of IDs with result rows returned by `get_search_listview`."""
  try:
    return {result['id']: result
      for result in get_search_listview(type, locale, **filters)['data']}
  except EmptyResultError:
    return {}


def get_npcs_by_level(locale, minle, maxle, **filters):
  """Queries `get_search_results` for NPCs by level, subdividing between `minle` and `maxle` if necessary."""
  try:
    return get_search_results('npcs', locale, minle=minle, maxle=maxle, **filters)
  except TruncatedResultsError:
    if minle >= maxle:
      raise InvalidResultError('Too many level {:d} NPC results; Cannot subdivide further.'.format(minle))
    mid = (minle + maxle) // 2
    npcs = get_npcs_by_level(locale, minle=minle, maxle=mid, **filters)
    npcs.update(get_npcs_by_level(locale, minle=mid + 1, maxle=maxle, **filters))
    return npcs


def get_npcs_all_levels(locale, **filters):
  """Queries `get_npcs_by_level` for NPCs of all levels."""
  npcs = get_npcs_by_level(locale, minle=_NPC_LEVEL_MIN, maxle=_NPC_LEVEL_MAX, **filters)
  npcs.update(get_npcs_by_level(locale, minle=_NPC_LEVEL_UNKNOWN, maxle=_NPC_LEVEL_UNKNOWN, **filters))
  return npcs
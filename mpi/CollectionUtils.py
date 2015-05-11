# Some utility methods for sets and dictionaries.  In a better world these 
# could all be replaced by fold().

import copy
import itertools

def iterlen(iterator):
  return sum(1 for i in iterator)

def intersection(sets):
  if len(sets) == 0:
    return set()
  base = copy.copy(sets[0])
  for s in itertools.islice(sets, 1, None):
    base &= s
  return base

def intersection_update(sets):
  if len(sets) == 0:
    return set()
  base = sets[0]
  for s in itertools.islice(sets, 1, None):
    base &= s
  return base

def union(sets):
  base = set()
  for s in sets:
    base |= s
  return base

def union_update(sets):
  if len(sets) == 0:
    return set()
  base = sets[0]
  for s in itertools.islice(sets, 1, None):
    base |= s
  return base

def addAll(dicts):
  if len(dicts) == 0:
    return {}
  base = {}
  for d in dicts:
    base.update(d)
  return base

def addAll_update(dicts):
  if len(dicts) == 0:
    return {}
  base = dicts[0]
  for d in itertools.islice(dicts, 1, None):
    base.update(d)
  return base
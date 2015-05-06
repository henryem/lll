# Some utility methods for sets.

import copy
import itertools

def intersection(sets):
  if len(sets) == 0:
    return set()
  base = copy.copy(sets[0])
  for s in itertools.islice(sets, 1):
    base &= s
  return base

def intersection_update(sets):
  if len(sets) == 0:
    return set()
  base = sets[0]
  for s in itertools.islice(sets, 1):
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
  for s in itertools.islice(sets, 1):
    base |= s
  return base
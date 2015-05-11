import numpy as np
import sys

# Return a new RandomState whose seed is a deterministic function of the
# seed in @rand and the machine ID, and which is different for different
# machines.  Useful if we want to run a deterministic distributed job without
# actually using the same seed on every machine.
def reseed(comm, rand):
  return np.random.RandomState(rand.randint(0, sys.maxint) + 53*comm.rank)

# Return a new RandomState whose seed is a deterministic function of @seed
# and of @idx.  Useful for generating a range of random values that does not
# change when the partitioning changes, e.g.:
#   seed = rand.randint()
#   makeRange(10).map(lambda item: makeRandForItem(seed, item))
def makeRandForItem(seed, idx):
  return np.random.RandomState(seed + 59*idx)

# Execute some computation embodied in @thunk on the master, or return None
# on slaves.  This is just a convenience method for this common pattern in MPI
# code.  (For example, MpiCollection.collect() will only collect on the master,
# so any code that uses its return value should be wrapped in onMaster().)
def onMaster(comm, thunk):
  if comm.rank == 0:
    return thunk()
  else:
    return None
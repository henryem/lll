import itertools

import Utils
from MpiChunks import MpiChunks

# A simple distributed collection in MPI.  Each processor has its own
# subcollection.  The implementation follows the MPMD model of MPI.  The
# programmer should populate the local part of the collection with local
# elements.  After that, most code can ignore the MPI model and use a
# functional style to manipulate the collection in the same way everywhere.
# When non-BSP-style communication is required, that simple model breaks down,
# and the programmer must remember to think like a thread managing its own
# data.
# 
# Due to the simplicity of this implementation, there are many caveats:
#  - Currently none of the operations on this collection are lazy.
#  - It is assumed that no operations on this collection change its
#    partitioning.  Explicit repartitioning could be supported.
class MpiCollection(object):
  def __init__(self, distributedChunks, partitioner):
    self.distributedChunks = distributedChunks
    self.partitioner = partitioner
  
  def map(self, f):
    return MpiCollection(self.distributedChunks.mapChunks(lambda chunk: [f(elt) for elt in chunk]), self.partitioner)
  
  def filter(self, pred):
    return MpiCollection(self.distributedChunks.mapChunks(lambda chunk: [elt for elt in chunk if pred(elt)]), self.partitioner)
  
  # Should be called on all processors; will return None on all but processor
  # 0.
  def collect(self):
    collectedChunks = self.distributedChunks.collect()
    if collectedChunks is None:
      return None
    else:
      return itertools.chain.from_iterable(collectedChunks)

  def mapChunks(self, f):
    return MpiCollection(self.distributedChunks.mapChunks(f), self.partitioner)

  def partitionOf(self, elt):
    return self.partitioner.apply(elt)

  def localElements(self):
    return self.distributedChunks.localChunk

def makeRange(comm, numElements):
  numProcessors = comm.size
  partitioning = Utils.partitionEvenly(numElements, numProcessors)
  localProcIdx = comm.rank
  numLocalElements = partitioning[localProcIdx]
  localStartIdx = sum(partitioning[0:localProcIdx])
  localElements = range(localStartIdx, localStartIdx+numLocalElements)
  partitioner = Partitioner(Utils.makeEvenPartitioner(numElements, numProcessors))
  return MpiCollection(MpiChunks(comm, localElements), partitioner)

class Partitioner(object):
  def __init__(self, partitionFunc):
    self.partitionFunc = partitionFunc
  
  def apply(self, elt):
    self.partitionFunc(elt)
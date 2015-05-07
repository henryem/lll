import itertools

import Utils
import CollectionUtils
from MpiChunks import MpiChunks
from MpiUtils import onMaster

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
  #FIXME
  def __init__(self, distributedChunks):#, partitioner):
    self.distributedChunks = distributedChunks
    # self.partitioner = partitioner
  
  def map(self, f):
    return MpiCollection(self.mapChunks(lambda chunk: [f(elt) for elt in chunk]))#, self.partitioner)
  
  def filter(self, pred):
    return MpiCollection(self.mapChunks(lambda chunk: [elt for elt in chunk if pred(elt)]))#, self.partitioner)
  
  # Should be called on all processors; will return None on all but processor
  # 0.
  def collect(self):
    collectedChunks = self.distributedChunks.collect()
    return onMaster(self.comm(), lambda : itertools.chain.from_iterable(collectedChunks))

  def reduce(self, zero, plus):
    return self.mapChunks(lambda chunk: reduce(plus, chunk, zero)).reduce(zero, plus)

  def reduceEverywhere(self, zero, plus):
    return self.mapChunks(lambda chunk: reduce(plus, chunk, zero)).reduceEverywhere(zero, plus)

  def size(self):
    numElements = self.mapChunks(lambda chunk: len(chunk)).reduce(0, lambda x, y: x + y)
    return onMaster(self.comm(), lambda : numElements)

  def sizeEverywhere(self):
    return self.mapChunks(lambda chunk: len(chunk)).reduceEverywhere(0, lambda x, y: x + y)

  # Should be called on all processors.  Will return the entire collection
  # everywhere.
  def collectEverywhere(self):
    return itertools.chain.from_iterable(self.distributedChunks.collectEverywhere())

  def mapChunks(self, f):
    return self.distributedChunks.mapChunks(f)#, self.partitioner)

  #FIXME
  # def partitionOf(self, elt):
  #   return self.partitioner.apply(elt)

  def localElements(self):
    return self.distributedChunks.localChunk

  # Valid only on a collection of pairs with unique keys.  No warning will be
  # given if the keys are not unique.
  def toDict(self):
    return MpiDict(self.mapChunks(lambda chunk: dict(chunk)))

  def comm(self):
    return self.distributedChunks.comm

def collectionFromLocal(comm, localCollection):
  return MpiCollection(MpiChunks(comm, localCollection))

def makeRange(comm, numElements):
  numProcessors = comm.size
  partitioning = Utils.partitionEvenly(numElements, numProcessors)
  localProcIdx = comm.rank
  numLocalElements = partitioning[localProcIdx]
  localStartIdx = sum(partitioning[0:localProcIdx])
  localElements = range(localStartIdx, localStartIdx+numLocalElements)
  # partitioner = Partitioner(Utils.makeEvenPartitioner(numElements, numProcessors))
  return collectionFromLocal(comm, localElements)#, partitioner)

def makeEmpty(comm):#, partitioner):
  return collectionFromLocal(comm, [])#, partitioner)

# class Partitioner(object):
#   def __init__(self, partitionFunc):
#     self.partitionFunc = partitionFunc
#
#   def apply(self, elt):
#     self.partitionFunc(elt)


# A distributed dictionary.  Currently only supports local lookups.
class MpiDict(object):
  def __init__(self, dictChunks):
    self.dictChunks = dictChunks
  
  def localDict(self):
    return self.dictChunks.localData()
  
  def comm(self):
    return self.dictChunks.comm
  
  def values(self):
    return collectionFromLocal(self.comm(), self.localDict().values())
  
  def collect(self):
    dicts = self.dictChunks.collect()
    return onMaster(self.comm(), lambda : addAll_update(dicts))
  
  def collectEverywhere(self):
    dicts = self.dictChunks.collectEverywhere()
    return CollectionUtils.addAll_update(dicts)
  
  def __getitem__(self, item):
    return self.dictChunks.localData()[item]

def dictFromLocal(comm, localDict):
  return MpiDict(MpiChunks(comm, localDict))


# A distributed set.
class MpiSet(object):
  def __init__(self, setChunks):
    self.setChunks = setChunks
  
  def localSet(self):
    return self.setChunks.localData()
  
  def comm(self):
    return self.setChunks.comm
  
  def toCollection(self):
    return MpiCollection(self.setChunks)

def setFromLocal(comm, localSet):
  return MpiSet(MpiChunks(comm, localSet))
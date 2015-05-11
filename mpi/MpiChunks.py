from MpiUtils import onMaster

# A very primitive distributed data structure.  Each processor is associated
# with a local chunk of arbitrary data.
# Currently none of the operations on this object are lazy, so
# mutating it is okay, subject to the usual issues with distributed data
# structures.  However, lazy collections may be implemented on top of this
# by passing lazy mappers to mapChunks().
class MpiChunks(object):
  def __init__(self, comm, localChunk):
    self.comm = comm
    self.localChunk = localChunk
  
  def localData(self):
    return self.localChunk
  
  def mapChunks(self, f):
    return MpiChunks(self.comm, f(self.localChunk))
  
  # Should be called on all processors; will return None on all but processor
  # 0.
  def collect(self):
    return self.comm.gather(self.localChunk, root=0)
  
  # Should be called on all processors.  Will return the entire collection
  # everywhere.
  def collectEverywhere(self):
    return self.comm.allgather(self.localChunk)
  
  def reduce(self, zero, plus):
    collectedValue = self.collect()
    return onMaster(self.comm, lambda : reduce(plus, collectedValue, zero))
  
  def reduceEverywhere(self, zero, plus):
    return reduce(plus, self.collectEverywhere(), zero)
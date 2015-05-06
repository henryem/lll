from MpiChunks import MpiChunks

# A mutable broadcast value.  Implementations should ensure that the value
# is initialized and mutated in the same way on every processor.  The
# functionality of this object is essentially identical to that of MpiChunks,
# but using this object indicates that it is intended to be kept identical
# across processors.  Applications must provide and enforce their own
# definition of "identical".
class MpiMutableBroadcast(object):
  def __init__(self, comm, value):
    self.chunks = MpiChunks(comm, value)
  
  def value(self):
    return self.chunks.localData()
  
  def comm(self):
    return self.chunks.comm()
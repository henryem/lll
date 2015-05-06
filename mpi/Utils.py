import sys

def randBernoulli(rand, p):
  return rand.uniform() < p

def randBit(rand):
  return rand.randint(0, 2)

def randLargeInt(rand):
  #TODO: Not the optimal range to use.
  return rand.randint(0, sys.maxint)

def partitionEvenly(numElts, numPartitions):
  usualNumElts = numElts // numPartitions
  numPartitionsWithExtraElement = numElts % numPartitions
  return [usualNumElts + 1 if i < numPartitionsWithExtraElement else usualNumElts for i in xrange(numPartitions)]

def makeEvenPartitioner(numElts, numPartitions):
  usualNumElts = numElts // numPartitions
  numPartitionsWithExtraElement = numElts % numPartitions
  
  def partitionFunc(elt):
    if elt >= numPartitionsWithExtraElement*(usualNumElts+1):
      return numPartitionsWithExtraElement + (elt - numPartitionsWithExtraElement*(usualNumElts+1)) // usualNumElts
    else:
      return elt // (usualNumElts+1)
  
  return partitionFunc

def divRoundUp(dividend, divisor):
  return (dividend + divisor - 1) // divisor
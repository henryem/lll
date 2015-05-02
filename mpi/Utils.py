import random

def randBernoulli(p):
  return random.random() < p

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
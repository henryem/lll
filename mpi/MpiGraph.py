# A distributed undirected graph.  Nodes are simply integer IDs.  Nodes are 
# distributed, and each node knows its neighbors, some of which may reside
# in other processes.
class MpiGraph(object):
  def __init__(self, nodes, incidentEdges):
    self.nodes = nodes
    self.incidentEdges = incidentEdges

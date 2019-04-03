final encapsulated package GraphTest

import Graph;

function topologicalSortTest
  input list<tuple<Integer, list<Integer>>> inGraph;
  output list<Integer> outNodes;
  output list<tuple<Integer, list<Integer>>> outRemainingGraph;
algorithm
  (outNodes, outRemainingGraph) := Graph.topologicalSort(inGraph, intEq);
end topologicalSortTest;

function topologicalSortTestDetectCycles
  input list<tuple<Integer, list<Integer>>> inGraph;
  output list<Integer> outNodes;
  output list<list<Integer>> outCycles;
protected
  list<tuple<Integer, list<Integer>>> remainingGraph;
algorithm
  (outNodes, remainingGraph) := Graph.topologicalSort(inGraph, intEq);
  outCycles := Graph.findCycles(remainingGraph, intEq);
end topologicalSortTestDetectCycles;

end GraphTest;

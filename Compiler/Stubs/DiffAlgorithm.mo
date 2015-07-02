encapsulated package DiffAlgorithm

type Diff = Integer;

function diff<T,F>
  input list<T> seq1;
  input list<T> seq2;
  input F equals;
  output list<tuple<Diff,list<T>>> out;
algorithm
  assert(false, getInstanceName());
end diff;

function printActual<A,B>
  input A seq;
  input B toString;
  output String res;
algorithm
  assert(false, getInstanceName());
end printActual;

function printDiffTerminalColor<A,B>
  input A seq;
  input B toString;
  output String res;
algorithm
  assert(false, getInstanceName());
end printDiffTerminalColor;

function printDiffXml<A,B>
  input A seq;
  input B toString;
  output String res;
algorithm
  assert(false, getInstanceName());
end printDiffXml;

annotation(__OpenModelica_Interface="util");
end DiffAlgorithm;

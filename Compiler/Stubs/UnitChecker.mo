encapsulated package UnitChecker

function check<A,B>
  input A tms;
  input B ist;
  output B outSt;
algorithm
  assert(false, getInstanceName());
end check;

function isComplete<A>
  input A st;
  output Boolean complete;
  output A stout;
algorithm
  assert(false, getInstanceName());
end isComplete;

annotation(__OpenModelica_Interface="frontend");
end UnitChecker;

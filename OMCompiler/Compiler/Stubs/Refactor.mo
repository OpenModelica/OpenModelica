encapsulated package Refactor

function refactorGraphicalAnnotation<A,B>
  input A wholeAST;
  input B classToRefactor;
  output B changedClass;
algorithm
  assert(false, getInstanceName());
end refactorGraphicalAnnotation;

annotation(__OpenModelica_Interface="backend");
end Refactor;

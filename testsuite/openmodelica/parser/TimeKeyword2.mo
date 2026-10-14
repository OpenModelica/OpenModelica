// name: TimeKeyword2
// keywords: Modelica 3.7 time keyword
// status: correct
// cflags: -d=newInst --std=3.6 --strict
//
// time is an identifier before Modelica 3.7.
//

record TimeKeyword2
  Real time;
end TimeKeyword2;

// Result:
// class TimeKeyword2
//   Real time;
// end TimeKeyword2;
// endResult

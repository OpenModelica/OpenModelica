// name: redeclare3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Invalid usage of time inside function not checked.
//

package A
  function f
    replaceable input Real x;
    output Real y = x;
  end f;
end A;

model B
  function f = A.f(redeclare Real x = time);
  Real x = f();
end B;

// Result:
//
// EXPANDED FORM:
//
// class B
//   Real x = f();
// end B;
//
//
// Found 1 components and 0 parameters.
// function B.f
//   Real x;
//   output Real y = x;
// end B.f;
//
// class B
//   Real x = 6.9532112725263e-310;
// end B;
// [redeclare3.mo:9:5-9:29:writable] Warning: Invalid public variable x, function variables that are not input/output must be protected.
//
// endResult

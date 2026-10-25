// name:     Array7
// keywords: array,array of components
// status:   correct
//
// This demonstrates how a modifier is split
// among a an array of componets.
//
// It also demonstrates heterogenous arrays (a.x).
//
model Array7
  model A
    parameter Integer n;
    parameter Real x[n,n](each fixed = false);
  end A;
  A a[2](n={1,2});
end Array7;

// Result:
// class Array7
//   final parameter Integer a[1].n = 1;
//   parameter Real a[1].x[1,1](fixed = false);
//   final parameter Integer a[2].n = 2;
//   parameter Real a[2].x[1,1](fixed = false);
//   parameter Real a[2].x[1,2](fixed = false);
//   parameter Real a[2].x[2,1](fixed = false);
//   parameter Real a[2].x[2,2](fixed = false);
// end Array7;
// endResult

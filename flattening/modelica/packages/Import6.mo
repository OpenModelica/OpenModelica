// name:     Import6
// keywords: import
// status:   correct
//
// Import of constants in packages.

package Constants
constant Real mue_0 = 2.0;
end Constants;

package A
  import mu_0 = Constants.mue_0;
  model C
    Real x = time*mu_0;
  end C;
end A;

model Import6
  extends A.C;
end Import6;

// Result:
// class Import6
//   Real x = 2.0 * time;
// end Import6;
// endResult

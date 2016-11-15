// status: correct
// cflags: -d=newInst

model function1
  function myfill
    input Real x,y,z;
    output Real o[y,z];
  end myfill;

  function f
    input Integer r;
    output Real o = x + y;
  protected
    Real x = sin(r);
    Real y = sin(x);
    Real z2[integer(x)] = {1};
    Real z[size(z2,1),2];
    Real z3[:];
  algorithm
    for r in 1:2 loop
      o := r;
    end for;
    o := x;
    o := c;
    z3 := {1,2};
  end f;
  Real r = sin(time), x = f(integer(time));
  constant Real c = 3.4;
  Real a[2];
end function1;

// Result:
// Error processing file: function1.mo
// [function1.mo:16:5-16:31:writable] Error: Type mismatch in assignment in z2 := {1} of Real[integer(x)] := Integer[1]
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult

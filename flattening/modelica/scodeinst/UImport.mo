// name: Uimport.mo
// status: correct
// cflags: -d=newInst

package A
  package B
    function f
      input Real x;
      output Real y;
    algorithm
      y := x;
    end f;
  end B;
  
end A;

model M
  import A.B.*;
  parameter Real x = f(100);
end M;

// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
// end f;
//
// class M
//   parameter Real x = f(100.0);
// end M;
// endResult


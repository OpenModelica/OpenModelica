// name: ImportUnqualified3.mo
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

model ImportUnqualified3
  import A.B.*;
  parameter Real x = f(100);
end ImportUnqualified3;


// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
// end f;
//
// class ImportUnqualified3
//   parameter Real x = f(100.0);
// end ImportUnqualified3;
// endResult

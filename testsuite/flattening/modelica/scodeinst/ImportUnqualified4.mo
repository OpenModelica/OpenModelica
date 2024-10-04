// name: ImportUnqualified4.mo
// status: correct

package A
  import A.Units.*;

  model AM
    parameter Pressure p = 0;
  end AM;

  package Units
    type Pressure = Real;
  end Units;
end A;

model ImportUnqualified4
  A.AM am;
end ImportUnqualified4;


// Result:
// class ImportUnqualified4
//   parameter Real am.p = 0.0;
// end ImportUnqualified4;
// endResult

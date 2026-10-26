// name:     RDCL.mo [BUG: #2346]
// keywords: redeclare check
// status:   correct

package B
  connector Flange_b
    Real phi;
    flow Real tau;
  end  Flange_b;

  partial model Base
   parameter Real pD;
   Flange_b f_b;
  end Base;

  model BaseImpl
    parameter Real pD;
    Real y;
    Flange_b f_b;
  end BaseImpl;

  model WA
    parameter Real diam = 1;
    replaceable Base cm(pD = diam);
    Real x = cm.f_b.phi;
  end WA;

end B;

model RDCL
  B.WA w(redeclare B.BaseImpl cm);
end RDCL;


// Result:
// class RDCL
//   parameter Real w.diam = 1.0;
//   parameter Real w.cm.pD = w.diam;
//   Real w.cm.y;
//   Real w.cm.f_b.phi;
//   Real w.cm.f_b.tau;
//   Real w.x = w.cm.f_b.phi;
// equation
//   w.cm.f_b.tau = 0.0;
// end RDCL;
// endResult

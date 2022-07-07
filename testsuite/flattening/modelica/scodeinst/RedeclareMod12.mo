// name: RedeclareMod12
// keywords:
// status: correct
// cflags: -d=newInst
//

partial package C
  partial connector FluidPort
    Real p;
    replaceable flow Real Q;
  end FluidPort;

  partial connector FluidOutlet
    extends C.FluidPort(redeclare Real Q(start = -500, nominal = -500));
  end FluidOutlet;
end C;

partial model FluidSource
  replaceable C.FluidOutlet C_out(Q(start = -1e3));
end FluidSource;

connector Outlet
  extends C.FluidOutlet;
end Outlet;

model RedeclareMod12
  extends FluidSource(redeclare Outlet C_out);
end RedeclareMod12;

// Result:
// class RedeclareMod12
//   Real C_out.p;
//   Real C_out.Q(start = -1000.0, nominal = -500.0);
// equation
//   C_out.Q = 0.0;
// end RedeclareMod12;
// endResult

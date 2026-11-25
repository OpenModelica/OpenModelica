//name:        ExpandableConnectorHierarchy2
//keyword:     expandable bug2385
//status:      correct

connector RealInput = input Real;
connector RealOutput = output Real;

expandable connector A
  Real ax;
end A;

expandable connector B
  Real bx[2];
end B;

model Bsource
  output B bout;
  RealOutput genx[2](each start = 1.0);
equation
  connect(genx,bout.bx);
  genx[1] = sin(time);
  genx[2] = genx[1]*genx[1];
end Bsource;

model Busage
  input B bin;
  RealInput bx[2];
  Real bx2[2];
equation
  connect(bx,bin.bx);
  bx2[1] = 2.0 * bx[1];
  bx2[2] = 3.0 * bx[2];
end Busage;

model Asource
  output A aout;
  RealOutput ax;
equation
  connect(ax,aout.ax);
  ax = cos(time);
end Asource;

model Ausage
  input A ain;
  RealInput ax;
  Real ax2;
equation
  connect(ain.ax,ax);
  ax2 = 2.0 * ax;
end Ausage;

model ExpandableConnectorHierarchy2
  Bsource Bs;
  Busage  Bu;
  Asource As;
  Ausage  Au;
  B       Bcon;
equation
  connect(Bs.bout,Bcon);
  connect(As.aout,Bcon);
  connect(Bcon,Bu.bin);
  connect(Bcon,Au.ain);
end ExpandableConnectorHierarchy2;

// Result:
// class ExpandableConnectorHierarchy2
//   Real Bs.bout.ax "variable added to expandable connector";
//   Real Bcon.ax "variable added to expandable connector";
//   Real As.aout.bx[1] "variable added to expandable connector";
//   Real As.aout.bx[2] "variable added to expandable connector";
//   Real Bu.bin.ax "variable added to expandable connector";
//   Real Au.ain.bx[1] "variable added to expandable connector";
//   Real Au.ain.bx[2] "variable added to expandable connector";
//   Real Bs.bout.bx[1];
//   Real Bs.bout.bx[2];
//   Real Bs.genx[1](start = 1.0);
//   Real Bs.genx[2](start = 1.0);
//   Real Bu.bin.bx[1];
//   Real Bu.bin.bx[2];
//   Real Bu.bx[1];
//   Real Bu.bx[2];
//   Real Bu.bx2[1];
//   Real Bu.bx2[2];
//   Real As.aout.ax;
//   Real As.ax;
//   Real Au.ain.ax;
//   Real Au.ax;
//   Real Au.ax2;
//   Real Bcon.bx[1];
//   Real Bcon.bx[2];
// equation
//   Bs.genx[1] = Bs.bout.bx[1];
//   Bs.genx[2] = Bs.bout.bx[2];
//   Bu.bx[1] = Bu.bin.bx[1];
//   Bu.bx[2] = Bu.bin.bx[2];
//   As.ax = As.aout.ax;
//   Au.ain.ax = Au.ax;
//   Bcon.ax = Au.ain.ax;
//   Bcon.ax = Bu.bin.ax;
//   Bcon.ax = As.aout.ax;
//   Bcon.ax = Bs.bout.ax;
//   Bcon.bx[1] = Au.ain.bx[1];
//   Bcon.bx[1] = Bu.bin.bx[1];
//   Bcon.bx[1] = As.aout.bx[1];
//   Bcon.bx[1] = Bs.bout.bx[1];
//   Bcon.bx[2] = Au.ain.bx[2];
//   Bcon.bx[2] = Bu.bin.bx[2];
//   Bcon.bx[2] = As.aout.bx[2];
//   Bcon.bx[2] = Bs.bout.bx[2];
//   Bs.genx[1] = sin(time);
//   Bs.genx[2] = Bs.genx[1] * Bs.genx[1];
//   Bu.bx2[1] = 2.0 * Bu.bx[1];
//   Bu.bx2[2] = 3.0 * Bu.bx[2];
//   As.ax = cos(time);
//   Au.ax2 = 2.0 * Au.ax;
// end ExpandableConnectorHierarchy2;
// endResult

// name: CevalLog2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalLog2
  constant Real r1 = log(-1);
end CevalLog2;

// Result:
// class CevalLog2
//   constant Real r1 = log(-1.0);
// end CevalLog2;
// [flattening/modelica/scodeinst/CevalLog2.mo:9:3-9:29:writable] Error: Argument -1 of log is out of range (x > 0)
//
// endResult

// name: CevalLog102
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalLog102
  constant Real r1 = log10(-1);
end CevalLog102;

// Result:
// class CevalLog102
//   constant Real r1 = log10(-1.0);
// end CevalLog102;
// [flattening/modelica/scodeinst/CevalLog102.mo:9:3-9:31:writable] Error: Argument -1 of log10 is out of range (x > 0)
//
// endResult

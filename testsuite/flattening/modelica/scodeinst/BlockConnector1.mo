// name: BlockConnector1
// keywords:
// status: correct
//
// Checks that a warning is given for a public connector in a block that has
// variables that are neither input nor output.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

block BlockConnector1
  Pin p;
  output Real y;
equation
  y = p.v;
end BlockConnector1;

// Result:
// class BlockConnector1
//   Real p.v;
//   Real p.i;
//   output Real y;
// equation
//   p.i = 0.0;
//   y = p.v;
// end BlockConnector1;
// [flattening/modelica/scodeinst/BlockConnector1.mo:15:3-15:8:writable] Warning: Public connector p in a block may only have variables that are input or output, but the following are neither: p.v, p.i.
//
// endResult

// name: BlockConnector2
// keywords:
// status: correct
//
// Checks that a warning is given for a public connector in a block that is
// missing the input/output prefix.
//

connector RealSig = Real;

block BlockConnector2
  RealSig u;
  output RealSig y;
equation
  y = 2*u;
end BlockConnector2;

// Result:
// class BlockConnector2
//   Real u;
//   output Real y;
// equation
//   y = 2.0 * u;
// end BlockConnector2;
// [flattening/modelica/scodeinst/BlockConnector2.mo:12:3-12:12:writable] Warning: Connector u is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/scodeinst/BlockConnector2.mo:12:3-12:12:writable] Warning: Public connector u in a block may only have variables that are input or output, but the following are neither: u.
//
// endResult

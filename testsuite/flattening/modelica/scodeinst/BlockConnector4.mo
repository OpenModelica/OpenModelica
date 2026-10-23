// name: BlockConnector4
// keywords:
// status: incorrect
//
// Checks that the input/output restriction on connectors in a block is also
// checked for nested connectors and inherited connectors in a block instance.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

connector C
  Pin p;
  input Real u;
end C;

partial model PartialM
  C c;
end PartialM;

block B
  extends PartialM;
equation
  c.p.v = c.u;
end B;

model BlockConnector4
  B b;
end BlockConnector4;

// Result:
// Error processing file: BlockConnector4.mo
// [flattening/modelica/scodeinst/BlockConnector4.mo:20:3-20:6:writable] Error: Public connector c in a block may only have variables that are input or output, but the following are neither: c.p.v, c.p.i.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult

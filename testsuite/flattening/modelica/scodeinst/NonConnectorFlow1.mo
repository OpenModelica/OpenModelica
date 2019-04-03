// name: NonConnectorFlow1
// keywords:
// status: correct
// cflags: -d=newInst
//

model NonConnectorFlow1
  flow Real f = 1.0;
end NonConnectorFlow1;

// Result:
// class NonConnectorFlow1
//   Real f = 1.0;
// end NonConnectorFlow1;
// [flattening/modelica/scodeinst/NonConnectorFlow1.mo:8:3-8:20:writable] Warning: Prefix 'flow' used outside connector declaration.
//
// endResult

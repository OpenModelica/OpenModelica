// name: expconn7.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: This should fail, since neither of the connected components
//             exist.
//

expandable connector EC
end EC;

model M
  EC ec1, ec2;
equation
  connect(ec1.r, ec2.e);
end M;

// Result:
// Error processing file: expconn7.mo
// [flattening/modelica/scodeinst/expconn7.mo:16:3-16:24:writable] Error: Cannot connect undeclared connectors ec1.r with ec2.e. At least one of them must be declared.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult

// name:     ConnectTwoSources
// keywords: connect
// status:   correct
// cflags: -d=-newInst
//
// Connecting two sources should not be allowed.
//

connector RealInput = input Real;
connector RealOutput = output Real;

model ConnectTwoSources
  RealInput ri1, ri2;
equation
  connect(ri1, ri2);
end ConnectTwoSources;

// Result:
// class ConnectTwoSources
//   input Real ri1;
//   input Real ri2;
// equation
//   ri1 = ri2;
// end ConnectTwoSources;
// [flattening/modelica/connectors/ConnectTwoSources.mo:15:3-15:20:writable] Warning: Connecting two signal sources while connecting ri1 to ri2.
//
// endResult

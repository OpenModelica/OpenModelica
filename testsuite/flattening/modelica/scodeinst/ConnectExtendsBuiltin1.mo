// name: ConnectExtendsBuiltin1
// keywords:
// status: correct
//

model ConnectExtendsBuiltin1
  type MyReal
    extends Real;
  end MyReal;

  connector RealInput = input MyReal;
  connector RealOutput = output Real;
  RealInput ci;
  RealOutput co;
equation
  connect(ci, co);
end ConnectExtendsBuiltin1;

// Result:
// class ConnectExtendsBuiltin1
//   input Real ci;
//   output Real co;
// equation
//   ci = co;
// end ConnectExtendsBuiltin1;
// endResult

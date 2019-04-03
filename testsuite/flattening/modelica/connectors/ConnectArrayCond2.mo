// name:     ConnectArrayCond2
// keywords: connect conditional #3473
// status:   correct
//
// Tests connecting deleted conditional array components.
//

connector InConn = input Real;
connector OutConn = output Real;

block Foo
  parameter Boolean enabled = false;
  InConn x if enabled;
end Foo;

block Src
  OutConn x = time;
end Src;

model ConnectArrayCond2
  Foo[2] foo(enabled = {true, false});
  Src src;
  Src src1;
equation
  connect(src.x, foo[1].x);
  connect(src1.x, foo[2].x);
end ConnectArrayCond2;

// Result:
// class ConnectArrayCond2
//   parameter Boolean foo[1].enabled = true;
//   Real foo[1].x;
//   parameter Boolean foo[2].enabled = false;
//   Real src.x = time;
//   Real src1.x = time;
// equation
//   foo[1].x = src.x;
// end ConnectArrayCond2;
// endResult

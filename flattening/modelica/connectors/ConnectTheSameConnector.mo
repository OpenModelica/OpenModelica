// name:     ConnectTheSameConnector
// keywords: connect(A, A) should be ignored
// status:   correct
//
//


model ConnectTheSameConnector
 connector C
   flow Real i;
   Real u;
 end C;

 C c1;
 C c2;
equation
 connect(c1, c2);
 connect(c1, c1) "bummer!";
end ConnectTheSameConnector;


//
// Result:
// class ConnectTheSameConnector
//   Real c1.i;
//   Real c1.u;
//   Real c2.i;
//   Real c2.u;
// equation
//   c1.i = 0.0;
//   c2.i = 0.0;
//   (-c1.i) + (-c2.i) = 0.0;
//   c1.u = c2.u;
// end ConnectTheSameConnector;
// [flattening/modelica/connectors/ConnectTheSameConnector.mo:18:2-18:27:writable] Warning: connect(c1, c1) connects the same connector instance! The connect equation will be ignored.
//
// endResult

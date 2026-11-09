// name: AlgorithmNoRetCall
// status: correct

package Modelica
package Utilities
package Streams

impure function print
  input String str;
algorithm
  .print(str);
end print;

end Streams;
end Utilities;
end Modelica;

package P

model A
  import Modelica.Utilities.Streams;
algorithm
  Streams.print(String(time) + "\n");
end A;

model B

  A a;

end B;

end P;

model AlgorithmNoRetCall
  extends P.B;
end AlgorithmNoRetCall;

// Result:
// impure function Modelica.Utilities.Streams.print
//   input String str;
// algorithm
//   print(str);
// end Modelica.Utilities.Streams.print;
//
// class AlgorithmNoRetCall
// algorithm
//   Modelica.Utilities.Streams.print(String(time, 6, 0, true) + "
//   ");
// end AlgorithmNoRetCall;
// endResult

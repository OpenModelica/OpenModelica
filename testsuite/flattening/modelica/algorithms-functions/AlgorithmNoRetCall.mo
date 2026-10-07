// name: AlgorithmNoRetCall
// status: correct

package Modelica
package Utilities
package Streams

function print
  input String str;
algorithm
  .print(str);
end print;

end Streams;
end Utilities;
end Modelica;

package P

class A
  import Modelica.Utilities.Streams;
algorithm
  Streams.print(String(time) + "\n");
end A;

class B

  A a;

end B;

end P;

class AlgorithmNoRetCall
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
// [flattening/modelica/algorithms-functions/AlgorithmNoRetCall.mo:23:3-23:37:writable] Warning: Algorithm sections are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmNoRetCall.mo:8:1-12:10:writable] Warning: Pure function 'Modelica.Utilities.Streams.print' contains a call to impure function 'print'.
//
// endResult

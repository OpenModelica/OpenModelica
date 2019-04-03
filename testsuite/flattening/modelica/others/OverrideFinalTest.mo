// name:     OverrideFinalTest
// keywords: setting, final, parameter
// status:   correct
//
// Tests for bug: http://openmodelica.ida.liu.se:8080/cb/issue/1155?navigation=true
//


model OverrideFinalTest

 function fcall
   input Real[3] inArr;
   output Real[3] outArr;
 algorithm
   outArr := inArr;
 end fcall;

 final parameter Real eAxis_ia[3](each final unit="1") = fcall({1,2,3});
 final parameter Real eAxis_ia2[3](each final unit="1") = {1,2,3};

end OverrideFinalTest;

// function OverrideFinalTest.fcall
// input Real[3] inArr;
// output Real[3] outArr;
// algorithm
//   outArr := {inArr[1],inArr[2],inArr[3]};
// end OverrideFinalTest.fcall;
//
// Result:
// function OverrideFinalTest.fcall
//   input Real[3] inArr;
//   output Real[3] outArr;
// algorithm
//   outArr := {inArr[1], inArr[2], inArr[3]};
// end OverrideFinalTest.fcall;
//
// class OverrideFinalTest
//   final parameter Real eAxis_ia[1](unit = "1") = 1.0;
//   final parameter Real eAxis_ia[2](unit = "1") = 2.0;
//   final parameter Real eAxis_ia[3](unit = "1") = 3.0;
//   final parameter Real eAxis_ia2[1](unit = "1") = 1.0;
//   final parameter Real eAxis_ia2[2](unit = "1") = 2.0;
//   final parameter Real eAxis_ia2[3](unit = "1") = 3.0;
// end OverrideFinalTest;
// endResult

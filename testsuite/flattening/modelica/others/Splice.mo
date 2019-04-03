// name: Splice
// status: correct

model Splice
  parameter Integer dimensions = 5;
  parameter Real myArray[dimensions] = {1,2,3,4,5};
  parameter Real mySumArray[dimensions] = {sum(myArray[1:i]) for i in 1:dimensions};
end Splice;

// Result:
// class Splice
//   parameter Integer dimensions = 5;
//   parameter Real myArray[1] = 1.0;
//   parameter Real myArray[2] = 2.0;
//   parameter Real myArray[3] = 3.0;
//   parameter Real myArray[4] = 4.0;
//   parameter Real myArray[5] = 5.0;
//   parameter Real mySumArray[1] = myArray[1];
//   parameter Real mySumArray[2] = myArray[1] + myArray[2];
//   parameter Real mySumArray[3] = myArray[1] + myArray[2] + myArray[3];
//   parameter Real mySumArray[4] = myArray[1] + myArray[2] + myArray[3] + myArray[4];
//   parameter Real mySumArray[5] = myArray[1] + myArray[2] + myArray[3] + myArray[4] + myArray[5];
// end Splice;
// endResult

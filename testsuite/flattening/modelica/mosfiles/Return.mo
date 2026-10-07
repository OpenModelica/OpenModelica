// name: Return
// keywords: function, return
// status: correct
//
// Tests return within a function algorithm
//

function ReturnFunc
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger := inInteger * 2;
  return;
  outInteger := inInteger * 4; // this statement is never reached
end ReturnFunc;

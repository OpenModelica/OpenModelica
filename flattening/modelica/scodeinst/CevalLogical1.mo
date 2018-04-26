// name: CevalLogical1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalLogical1
  constant Boolean ba1 = false and false;
  constant Boolean ba2 = false and true;
  constant Boolean ba3 = true and false;
  constant Boolean ba4 = true and true;

  constant Boolean bo1 = false or false;
  constant Boolean bo2 = false or true;
  constant Boolean bo3 = true or false;
  constant Boolean bo4 = true or true;
  
  constant Boolean bn1 = not false;
  constant Boolean bn2 = not true;
end CevalLogical1;

// Result:
// class CevalLogical1
//   constant Boolean ba1 = false;
//   constant Boolean ba2 = false;
//   constant Boolean ba3 = false;
//   constant Boolean ba4 = true;
//   constant Boolean bo1 = false;
//   constant Boolean bo2 = true;
//   constant Boolean bo3 = true;
//   constant Boolean bo4 = true;
//   constant Boolean bn1 = true;
//   constant Boolean bn2 = false;
// end CevalLogical1;
// endResult

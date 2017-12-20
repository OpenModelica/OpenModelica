// name: CevalAcos2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalAcos2
  constant Real r1 = acos(1.3);
end CevalAcos2;

// Result:
// class CevalAcos2
//   constant Real r1 = acos(1.3);
// end CevalAcos2;
// [flattening/modelica/scodeinst/CevalAcos2.mo:9:3-9:31:writable] Error: Argument 1.3 of acos is out of range (-1 <= x <= 1)
//
// endResult

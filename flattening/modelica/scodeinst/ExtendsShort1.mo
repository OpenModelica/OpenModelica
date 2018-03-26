// name: ExtendsShort1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

package P
  constant Integer n = 2;

  model M
    Integer x = n;
  end M;
end P;

model ExtendsShort1
  model M = P.M;
  M m;
end ExtendsShort1;

// Result:
// class ExtendsShort1
//   Integer m.x = 2;
// end ExtendsShort1;
// endResult

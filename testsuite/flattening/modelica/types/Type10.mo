// name:     Type10
// keywords: types
// status:   correct
//
// This checks that types can be written using long class definition too.
//

type TypeInteger
  extends Integer(min=0,max=10);
end TypeInteger;

type Integer2
  extends TypeInteger(max=9);
end Integer2;

model test
  Integer2 t;
  Integer2 t2(max=8);
  TypeInteger t3;

end test;

// Result:
// class test
//   Integer t(min = 0, max = 9);
//   Integer t2(min = 0, max = 8);
//   Integer t3(min = 0, max = 10);
// end test;
// endResult

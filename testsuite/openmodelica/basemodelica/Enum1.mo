// name: Enum1
// status: correct

model Enum1
  type E1 = enumeration(a, b, c);
  type E2 = enumeration(a);
  E1 e1 = E1.b;
  E2 e2 = E2.a;

  annotation(__OpenModelica_commandLineOptions="-f");
end Enum1;

// Result:
// //! base 0.1.0
// package 'Enum1'
//   type 'E1' = enumeration('a', 'b', 'c');
//
//   type 'E2' = enumeration('a');
//
//   model 'Enum1'
//     'E1' 'e1' = 'E1'.'b';
//     'E2' 'e2' = 'E2'.'a';
//   end 'Enum1';
// end 'Enum1';
// endResult

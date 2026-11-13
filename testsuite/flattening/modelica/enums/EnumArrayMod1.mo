// name:     EnumArrayMod1
// keywords: enumeration enum array mod
// status:   correct
//
// Tests that enumeration arrays with modifiers work correctly.
//


model EnumArrayMod1
  record R
    E e;
  end R;

  type E = enumeration(a, b, c);

  R[E] re(e = {i for i in E});
end EnumArrayMod1;

// Result:
// class EnumArrayMod1
//   enumeration(a, b, c) re[E.a].e = E.a;
//   enumeration(a, b, c) re[E.b].e = E.b;
//   enumeration(a, b, c) re[E.c].e = E.c;
// end EnumArrayMod1;
// endResult

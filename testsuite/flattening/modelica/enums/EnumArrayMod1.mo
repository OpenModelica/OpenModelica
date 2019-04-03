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
// function EnumArrayMod1.R "Automatically generated record constructor for EnumArrayMod1.R"
//   input enumeration(a, b, c) e;
//   output R res;
// end EnumArrayMod1.R;
//
// function EnumArrayMod1.R$re "Automatically generated record constructor for EnumArrayMod1.R$re"
//   input enumeration(a, b, c) e;
//   output R$re res;
// end EnumArrayMod1.R$re;
//
// class EnumArrayMod1
//   enumeration(a, b, c) re[EnumArrayMod1.E.a].e = EnumArrayMod1.E.a;
//   enumeration(a, b, c) re[EnumArrayMod1.E.b].e = EnumArrayMod1.E.b;
//   enumeration(a, b, c) re[EnumArrayMod1.E.c].e = EnumArrayMod1.E.c;
// end EnumArrayMod1;
// endResult

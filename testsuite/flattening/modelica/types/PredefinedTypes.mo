// name:     PredefinedTypes
// keywords: Predefined types, modifications
// status:   correct

type enum = enumeration(a,b,c);
model PredefinedTypes
  Real real(quantity="quant_str_real",unit="string1",displayUnit="string2",min = 2.3, max = 4.9,start=1,fixed= true, nominal= 2.5,stateSelect=StateSelect.default);
  Integer integer(quantity="quant_str_integer",min = 2, max = 4,start=1,fixed= true);
  Boolean boolean(quantity="quant_str_boolean",start=false,fixed=true);
  String string(quantity="quant_str_string",start="start");
  enum f(quantity="quant_str_enumeration",min = enum.a,max = enum.b,fixed = true,start = enum.c);

end PredefinedTypes;

// Result:
// class PredefinedTypes
//   Real real(quantity = "quant_str_real", unit = "string1", displayUnit = "string2", min = 2.3, max = 4.9, start = 1.0, fixed = true, nominal = 2.5, stateSelect = StateSelect.default);
//   Integer integer(quantity = "quant_str_integer", min = 2, max = 4, start = 1, fixed = true);
//   Boolean boolean(quantity = "quant_str_boolean", start = false, fixed = true);
//   String string(quantity = "quant_str_string", start = "start");
//   enumeration(a, b, c) f(quantity = "quant_str_enumeration", min = enum.a, max = enum.b, start = enum.c, fixed = true);
// end PredefinedTypes;
// endResult

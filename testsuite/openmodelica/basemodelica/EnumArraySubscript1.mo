// name: EnumArraySubscript1
// status: correct

model EnumArraySubscript1
  type Color = enumeration(Red, Green, Blue);

  constant Integer map[Color] = {1, 2, 3};
  Color c;
  Integer v;
equation
  c = Color.Green;
  v = map[Color.Green];
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=scalarize");
end EnumArraySubscript1;

// Result:
// //! base 0.1.0
// package 'EnumArraySubscript1'
//   type 'Color' = enumeration('Red', 'Green', 'Blue');
//
//   model 'EnumArraySubscript1'
//     constant Integer 'map[\'Color\'.\'Red\']' = 1;
//     constant Integer 'map[\'Color\'.\'Green\']' = 2;
//     constant Integer 'map[\'Color\'.\'Blue\']' = 3;
//     'Color' 'c';
//     Integer 'v';
//   equation
//     'c' = 'Color'.'Green';
//     'v' = 2;
//   end 'EnumArraySubscript1';
// end 'EnumArraySubscript1';
// endResult

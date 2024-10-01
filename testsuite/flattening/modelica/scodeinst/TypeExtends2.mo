// name: TypeExtends2
// keywords:
// status: correct
//

type TypeInteger
  extends Integer;
end TypeInteger;

type TypeInteger2
  extends TypeInteger;
end TypeInteger2;

type Color = TypeInteger2[3](each min = 0, each max = 255);

model TypeExtends2
  Color color = {0, 0, 0};
  Integer icolor[3] = color;
end TypeExtends2;

// Result:
// class TypeExtends2
//   Integer color[1](min = 0, max = 255);
//   Integer color[2](min = 0, max = 255);
//   Integer color[3](min = 0, max = 255);
//   Integer icolor[1];
//   Integer icolor[2];
//   Integer icolor[3];
// equation
//   color = {0, 0, 0};
//   icolor = color;
// end TypeExtends2;
// endResult

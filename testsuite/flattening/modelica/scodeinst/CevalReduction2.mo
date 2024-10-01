// name: CevalReduction2
// keywords:
// status: correct
//
//

model CevalReduction2
  constant Real x = sum(j for j in 1:i, i in 1:4);
end CevalReduction2;

// Result:
// class CevalReduction2
//   constant Real x = 20.0;
// end CevalReduction2;
// endResult

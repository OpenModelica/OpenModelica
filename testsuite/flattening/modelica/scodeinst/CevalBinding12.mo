// name: CevalBinding12
// status: correct
//
//

model CevalBinding12
  constant Real reference_X[4] = cat(1, Conc.*C2X, {1 - (Conc*C2X)});
  final constant Integer nS = 4;
  constant Real Conc[nS - 1] = {0.21, 0.0004, 0.02};
  constant Real C2X[nS - 1] = aMM[1:nS - 1]./(Conc*aMM[1:nS - 1] + (1 - sum(Conc))*aMM[nS]);
  constant Real aMM[nS] = ones(nS)./2;
end CevalBinding12;

// Result:
// class CevalBinding12
//   constant Real reference_X[1] = 0.21;
//   constant Real reference_X[2] = 4e-4;
//   constant Real reference_X[3] = 0.02;
//   constant Real reference_X[4] = 0.7696000000000001;
//   final constant Integer nS = 4;
//   constant Real Conc[1] = 0.21;
//   constant Real Conc[2] = 4e-4;
//   constant Real Conc[3] = 0.02;
//   constant Real C2X[1] = 1.0;
//   constant Real C2X[2] = 1.0;
//   constant Real C2X[3] = 1.0;
//   constant Real aMM[1] = 0.5;
//   constant Real aMM[2] = 0.5;
//   constant Real aMM[3] = 0.5;
//   constant Real aMM[4] = 0.5;
// end CevalBinding12;
// endResult

// name:     ConnectionOrder2
// keywords: connect
// status:   correct
// cflags: +orderConnections=false
//
// Makes sure that the connection order is preserved when
// +orderConnections=false is used.
//

connector C
  flow Real f;
  Real e;
end C;

model ConnectionOrder2
  C JJczR;
  C xvCSn;
  C APNzi;
  C wWAqt;
  C CauvN;
  C Nizss;
  C iCWhD;
  C SsIbl;
  C xPLdp;
  C hAhvy;
equation
  connect(JJczR, xvCSn);
  connect(APNzi, wWAqt);
  connect(CauvN, Nizss);
  connect(SsIbl, iCWhD);
  connect(hAhvy, xPLdp);
end ConnectionOrder2;

// Result:
// class ConnectionOrder2
//   Real JJczR.f;
//   Real JJczR.e;
//   Real xvCSn.f;
//   Real xvCSn.e;
//   Real APNzi.f;
//   Real APNzi.e;
//   Real wWAqt.f;
//   Real wWAqt.e;
//   Real CauvN.f;
//   Real CauvN.e;
//   Real Nizss.f;
//   Real Nizss.e;
//   Real iCWhD.f;
//   Real iCWhD.e;
//   Real SsIbl.f;
//   Real SsIbl.e;
//   Real xPLdp.f;
//   Real xPLdp.e;
//   Real hAhvy.f;
//   Real hAhvy.e;
// equation
//   JJczR.f = 0.0;
//   xvCSn.f = 0.0;
//   APNzi.f = 0.0;
//   wWAqt.f = 0.0;
//   CauvN.f = 0.0;
//   Nizss.f = 0.0;
//   iCWhD.f = 0.0;
//   SsIbl.f = 0.0;
//   xPLdp.f = 0.0;
//   hAhvy.f = 0.0;
//   JJczR.e = xvCSn.e;
//   (-JJczR.f) + (-xvCSn.f) = 0.0;
//   APNzi.e = wWAqt.e;
//   (-APNzi.f) + (-wWAqt.f) = 0.0;
//   CauvN.e = Nizss.e;
//   (-CauvN.f) + (-Nizss.f) = 0.0;
//   SsIbl.e = iCWhD.e;
//   (-iCWhD.f) + (-SsIbl.f) = 0.0;
//   hAhvy.e = xPLdp.e;
//   (-xPLdp.f) + (-hAhvy.f) = 0.0;
// end ConnectionOrder2;
// endResult

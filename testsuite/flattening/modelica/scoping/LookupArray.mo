// name:     Lookup with arrays
// keywords: Lookup array
// status:   correct
//
//
// To test that the lookup of model vars with arrays works correctly.
//
model A
  model B
    model G
      Boolean[2] setdg;
    end G;
    G[2] g;
    Boolean set;
  end B;
  B[2,3,1] C;

  Boolean b4[3,1,2,2];
  equation
    b4 = C[1,:,:].g.setdg;
end A;

// Result:
// class A
//   Boolean C[1,1,1].g[1].setdg[1];
//   Boolean C[1,1,1].g[1].setdg[2];
//   Boolean C[1,1,1].g[2].setdg[1];
//   Boolean C[1,1,1].g[2].setdg[2];
//   Boolean C[1,1,1].set;
//   Boolean C[1,2,1].g[1].setdg[1];
//   Boolean C[1,2,1].g[1].setdg[2];
//   Boolean C[1,2,1].g[2].setdg[1];
//   Boolean C[1,2,1].g[2].setdg[2];
//   Boolean C[1,2,1].set;
//   Boolean C[1,3,1].g[1].setdg[1];
//   Boolean C[1,3,1].g[1].setdg[2];
//   Boolean C[1,3,1].g[2].setdg[1];
//   Boolean C[1,3,1].g[2].setdg[2];
//   Boolean C[1,3,1].set;
//   Boolean C[2,1,1].g[1].setdg[1];
//   Boolean C[2,1,1].g[1].setdg[2];
//   Boolean C[2,1,1].g[2].setdg[1];
//   Boolean C[2,1,1].g[2].setdg[2];
//   Boolean C[2,1,1].set;
//   Boolean C[2,2,1].g[1].setdg[1];
//   Boolean C[2,2,1].g[1].setdg[2];
//   Boolean C[2,2,1].g[2].setdg[1];
//   Boolean C[2,2,1].g[2].setdg[2];
//   Boolean C[2,2,1].set;
//   Boolean C[2,3,1].g[1].setdg[1];
//   Boolean C[2,3,1].g[1].setdg[2];
//   Boolean C[2,3,1].g[2].setdg[1];
//   Boolean C[2,3,1].g[2].setdg[2];
//   Boolean C[2,3,1].set;
//   Boolean b4[1,1,1,1];
//   Boolean b4[1,1,1,2];
//   Boolean b4[1,1,2,1];
//   Boolean b4[1,1,2,2];
//   Boolean b4[2,1,1,1];
//   Boolean b4[2,1,1,2];
//   Boolean b4[2,1,2,1];
//   Boolean b4[2,1,2,2];
//   Boolean b4[3,1,1,1];
//   Boolean b4[3,1,1,2];
//   Boolean b4[3,1,2,1];
//   Boolean b4[3,1,2,2];
// equation
//   b4[1,1,1,1] = C[1,1,1].g[1].setdg[1];
//   b4[1,1,1,2] = C[1,1,1].g[1].setdg[2];
//   b4[1,1,2,1] = C[1,1,1].g[2].setdg[1];
//   b4[1,1,2,2] = C[1,1,1].g[2].setdg[2];
//   b4[2,1,1,1] = C[1,2,1].g[1].setdg[1];
//   b4[2,1,1,2] = C[1,2,1].g[1].setdg[2];
//   b4[2,1,2,1] = C[1,2,1].g[2].setdg[1];
//   b4[2,1,2,2] = C[1,2,1].g[2].setdg[2];
//   b4[3,1,1,1] = C[1,3,1].g[1].setdg[1];
//   b4[3,1,1,2] = C[1,3,1].g[1].setdg[2];
//   b4[3,1,2,1] = C[1,3,1].g[2].setdg[1];
//   b4[3,1,2,2] = C[1,3,1].g[2].setdg[2];
// end A;
// endResult

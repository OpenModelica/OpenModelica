// name: CevalArrayConstructor4
// keywords:
// status: correct
//
// Evaluates a dimension through an array constructor in a record binding.
//

model CevalArrayConstructor4
  record Mat
    parameter Integer nSta = 1;
  end Mat;

  record Gen
    parameter Integer nLay;
    parameter Mat material[nLay];
    final parameter Integer nSta[nLay] = {material[i].nSta for i in 1:nLay};
  end Gen;

  model Layer
    parameter Gen layers;
    Real T[sum(layers.nSta)];
  equation
    der(T) = -T;
  end Layer;

  model Slab
    parameter Gen layers;
    parameter Integer iLayPip = 1;
    Layer con[2](each layers(final nLay = layers.nLay - iLayPip,
      final material = {layers.material[i] for i in iLayPip + 1:layers.nLay}));
  end Slab;

  Slab sla(layers(nLay = 3, material = {Mat(nSta = 1), Mat(nSta = 2), Mat(nSta = 3)}));
end CevalArrayConstructor4;

// Result:
// class CevalArrayConstructor4
//   final parameter Integer sla.layers.nLay = 3;
//   parameter Integer sla.layers.material[1].nSta = 1;
//   parameter Integer sla.layers.material[2].nSta = 2;
//   parameter Integer sla.layers.material[3].nSta = 3;
//   final parameter Integer sla.layers.nSta[1] = sla.layers.material[1].nSta;
//   final parameter Integer sla.layers.nSta[2] = sla.layers.material[2].nSta;
//   final parameter Integer sla.layers.nSta[3] = sla.layers.material[3].nSta;
//   final parameter Integer sla.iLayPip = 1;
//   final parameter Integer sla.con[1].layers.nLay = 2;
//   final parameter Integer sla.con[1].layers.material[1].nSta = 2;
//   final parameter Integer sla.con[1].layers.material[2].nSta = 3;
//   final parameter Integer sla.con[1].layers.nSta[1] = 2;
//   final parameter Integer sla.con[1].layers.nSta[2] = 3;
//   Real sla.con[1].T[1];
//   Real sla.con[1].T[2];
//   Real sla.con[1].T[3];
//   Real sla.con[1].T[4];
//   Real sla.con[1].T[5];
//   final parameter Integer sla.con[2].layers.nLay = 2;
//   final parameter Integer sla.con[2].layers.material[1].nSta = 2;
//   final parameter Integer sla.con[2].layers.material[2].nSta = 3;
//   final parameter Integer sla.con[2].layers.nSta[1] = 2;
//   final parameter Integer sla.con[2].layers.nSta[2] = 3;
//   Real sla.con[2].T[1];
//   Real sla.con[2].T[2];
//   Real sla.con[2].T[3];
//   Real sla.con[2].T[4];
//   Real sla.con[2].T[5];
// equation
//   der(sla.con[1].T[1]) = -sla.con[1].T[1];
//   der(sla.con[1].T[2]) = -sla.con[1].T[2];
//   der(sla.con[1].T[3]) = -sla.con[1].T[3];
//   der(sla.con[1].T[4]) = -sla.con[1].T[4];
//   der(sla.con[1].T[5]) = -sla.con[1].T[5];
//   der(sla.con[2].T[1]) = -sla.con[2].T[1];
//   der(sla.con[2].T[2]) = -sla.con[2].T[2];
//   der(sla.con[2].T[3]) = -sla.con[2].T[3];
//   der(sla.con[2].T[4]) = -sla.con[2].T[4];
//   der(sla.con[2].T[5]) = -sla.con[2].T[5];
// end CevalArrayConstructor4;
// [NFFrontEnd/NFCeval.mo:0:0-0:0:writable] Error: Internal error NFCeval.evalBinaryAdd failed to evaluate ‘i + 1‘
//
// endResult

// name: ExpandableConnectorArray5
// keywords: expandable connector
// status: correct
// suite: disabled
//

expandable connector SolBus
end SolBus;

expandable connector WeaBus
  SolBus[2] solBus;
end WeaBus;

model ShadedRadSol
  SolBus solBus;
  connector RealOutput = output Real;
  RealOutput TenvExpr;
equation
  connect(TenvExpr, solBus.Tenv);
end ShadedRadSol;

model SimInfoManager
  WeaBus weaBus;
  ShadedRadSol[2] radSol;
equation
  connect(radSol[1].solBus, weaBus.solBus[1]);
  connect(radSol[2].solBus, weaBus.solBus[2]);
end SimInfoManager;

model ExpandableConnectorArray5
  SimInfoManager sim;
  WeaBus weaBus;
equation
  connect(sim.weaBus, weaBus);
end ExpandableConnectorArray5;

// Result:

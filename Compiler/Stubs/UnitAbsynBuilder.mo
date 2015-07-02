encapsulated package UnitAbsynBuilder

import UnitAbsyn;

function emptyInstStore
  output UnitAbsyn.InstStore st = UnitAbsyn.noStore;
end emptyInstStore;

function instBuildUnitTerms<A,B>
  input A env;
  input B dae;
  input B compDae;
  input UnitAbsyn.InstStore store;
  output UnitAbsyn.InstStore outStore;
  output UnitAbsyn.UnitTerms terms;
algorithm
  assert(false, getInstanceName());
end instBuildUnitTerms;

function registerUnitWeights<A,B,C>
  input A cache;
  input B env;
  input C dae;
algorithm
  assert(false, getInstanceName());
end registerUnitWeights;

function instAddStore<A,B>
  input UnitAbsyn.InstStore istore;
  input A itp;
  input B cr;
  output UnitAbsyn.InstStore outStore = istore;
end instAddStore;

function unit2str<A>
  input A unit;
  output String res;
algorithm
  assert(false, getInstanceName());
end unit2str;

annotation(__OpenModelica_Interface="frontend");
end UnitAbsynBuilder;

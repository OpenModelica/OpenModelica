// name: SimpleCoolingCycle
// status: correct
// cflags: -d=newInst -f

type MolarMass = Real(final quantity = "MolarMass");

package PartialMedium
  record ThermodynamicState
    Real p;
    Real T;
  end ThermodynamicState;

  replaceable partial function specificHeatCapacityCp
    input ThermodynamicState state;
    output Real cp;
  end specificHeatCapacityCp;
end PartialMedium;

package DryAirNasa
  extends PartialMedium;

  constant T.DataRecord data;

  redeclare function extends specificHeatCapacityCp
  algorithm
    cp := T.Functions.cp_T(data, state.T);
  end specificHeatCapacityCp;
end DryAirNasa;

package T
  record DataRecord
    MolarMass MM;
  end DataRecord;

  package Functions
    function cp_T
      input DataRecord data;
      input Real T;
      output Real cp = 0;
    end cp_T;
  end Functions;
end T;

model CounterFlowNTU
  replaceable package MediumA = PartialMedium;
  MediumA.ThermodynamicState state;
protected
  Real cpA_in = MediumA.specificHeatCapacityCp(state);
end CounterFlowNTU;

model SimpleCoolingCycle
  replaceable package Medium_air = DryAirNasa;
  CounterFlowNTU heatExchange_CounterFlowNTU(redeclare package MediumA = Medium_air);
end SimpleCoolingCycle;

// Result:
// //! base 0.1.0
// package 'SimpleCoolingCycle'
//   function 'SimpleCoolingCycle.heatExchange_CounterFlowNTU.MediumA.specificHeatCapacityCp'
//     input 'heatExchange_CounterFlowNTU.MediumA.ThermodynamicState' 'state';
//     output Real 'cp';
//   algorithm
//     'cp' := 'T.Functions.cp_T'('T.DataRecord'('heatExchange_CounterFlowNTU.MediumA.data'.'MM'), 'state'.'T');
//   end 'SimpleCoolingCycle.heatExchange_CounterFlowNTU.MediumA.specificHeatCapacityCp';
//
//   function 'T.Functions.cp_T'
//     input 'T.DataRecord' 'data';
//     input Real 'T';
//     output Real 'cp' = 0.0;
//   end 'T.Functions.cp_T';
//
//   record 'heatExchange_CounterFlowNTU.MediumA.ThermodynamicState'
//     Real 'p';
//     Real 'T';
//   end 'heatExchange_CounterFlowNTU.MediumA.ThermodynamicState';
//
//   record 'T.DataRecord'
//     Real 'MM'(quantity = "MolarMass");
//   end 'T.DataRecord';
//
//   model 'SimpleCoolingCycle'
//     'heatExchange_CounterFlowNTU.MediumA.ThermodynamicState' 'heatExchange_CounterFlowNTU.state';
//     Real 'heatExchange_CounterFlowNTU.cpA_in' = 'SimpleCoolingCycle.heatExchange_CounterFlowNTU.MediumA.specificHeatCapacityCp'('heatExchange_CounterFlowNTU.state');
//   end 'SimpleCoolingCycle';
// end 'SimpleCoolingCycle';
// endResult

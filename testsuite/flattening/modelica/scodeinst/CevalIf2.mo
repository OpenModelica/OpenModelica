// name: CevalIf2
// keywords:
// status: correct
//
//

pure function getTable2DValue
  input ExternalCombiTable2D tableID;
  output Real y;
  external "C" y = ext(tableID);
end getTable2DValue;

class ExternalCombiTable2D
  extends ExternalObject;

  function constructor
    input String tableName;
    output ExternalCombiTable2D externalCombiTable2D;
    external "C" externalCombiTable2D = ext(tableName);
  end constructor;

  function destructor
    input ExternalCombiTable2D externalCombiTable2D;
    external "C" ModelicaStandardTables_CombiTable2D_close(externalCombiTable2D);
  end destructor;
end ExternalCombiTable2D;

model FlowControlled_m_flow
  parameter Real m_flow_nominal;
equation
  if m_flow_nominal > 0 then
  end if;
end FlowControlled_m_flow;

record GenericHeatPump
  parameter Real mEva_flow_nominal = getTable2DValue(tableID_QCon_flow);
  final parameter ExternalCombiTable2D tableID_QCon_flow = ExternalCombiTable2D("NoName");
end GenericHeatPump;

model HeatPumpModular
  parameter GenericHeatPump dat;
  FlowControlled_m_flow pumEva(final m_flow_nominal = dat.mEva_flow_nominal);
end HeatPumpModular;

model CevalIf2
  HeatPumpModular ets(dat = datHeaPum);
  parameter GenericHeatPump datHeaPum;
end CevalIf2;

// Result:
// impure function ExternalCombiTable2D.constructor
//   input String tableName;
//   output ExternalCombiTable2D externalCombiTable2D;
//
//   external "C" externalCombiTable2D = ext(tableName);
// end ExternalCombiTable2D.constructor;
//
// impure function ExternalCombiTable2D.destructor
//   input ExternalCombiTable2D externalCombiTable2D;
//
//   external "C" ModelicaStandardTables_CombiTable2D_close(externalCombiTable2D);
// end ExternalCombiTable2D.destructor;
//
// function getTable2DValue
//   input ExternalCombiTable2D tableID;
//   output Real y;
//
//   external "C" y = ext(tableID);
// end getTable2DValue;
//
// class CevalIf2
//   final parameter Real ets.dat.mEva_flow_nominal = datHeaPum.mEva_flow_nominal;
//   parameter ExternalCombiTable2D ets.dat.tableID_QCon_flow = datHeaPum.tableID_QCon_flow;
//   final parameter Real ets.pumEva.m_flow_nominal = datHeaPum.mEva_flow_nominal;
//   parameter Real datHeaPum.mEva_flow_nominal = getTable2DValue(datHeaPum.tableID_QCon_flow);
//   parameter ExternalCombiTable2D datHeaPum.tableID_QCon_flow = ExternalCombiTable2D.constructor("NoName");
// end CevalIf2;
// [flattening/modelica/scodeinst/CevalIf2.mo:35:1-38:20:writable] Warning: Pure function 'GenericHeatPump' contains a call to impure function 'ExternalCombiTable2D.constructor'.
//
// endResult

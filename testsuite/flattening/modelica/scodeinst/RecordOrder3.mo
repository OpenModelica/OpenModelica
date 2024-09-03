// name: RecordOrder3
// keywords:
// status: correct
// cflags: -d=newInst
//

package Cooling
  record DXCoil
    parameter Cooling.Stage sta[1];
  end DXCoil;

  record Stage
    parameter Real m_flow_nominal;
    parameter Real TEvaIn_nominal = 292.55;
  end Stage;
end Cooling;

package Heating
  record DXCoil
    parameter Heating.Stage sta[1];
  end DXCoil;

  record Stage
    parameter Real TEvaIn_nominal = 292.55;
    parameter Real m_flow_nominal;
  end Stage;
end Heating;

model RecordOrder3
  parameter Cooling.DXCoil datCoi(sta = {Heating.Stage(m_flow_nominal = 2)});
end RecordOrder3;

// Result:
// class RecordOrder3
//   parameter Real datCoi.sta[1].m_flow_nominal = 2.0;
//   parameter Real datCoi.sta[1].TEvaIn_nominal = 292.55;
// end RecordOrder3;
// endResult

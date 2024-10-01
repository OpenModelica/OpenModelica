// name: RecordBinding14
// keywords:
// status: correct
//

package Cooling
  record DXCoil
    parameter Integer nSta = 1;
    parameter Stage sta[nSta];
  end DXCoil;

  record NominalValues
    parameter Real TEvaIn_nominal = 292.55;
    parameter Real m_flow_nominal;
  end NominalValues;

  record Stage
    parameter NominalValues nomVal;
  end Stage;
end Cooling;

package Heating
  model DryCoil
    parameter Cooling.DXCoil datCoi;
  end DryCoil;

  model SingleSpeed
    parameter DXCoil datCoi;
    DryCoil dxCoi(final datCoi = datCoi);
  end SingleSpeed;

  record DXCoil
    parameter Integer nSta = 1;
    parameter Stage sta[nSta];
  end DXCoil;

  record NominalValues
    parameter Real m_flow_nominal;
    parameter Real TEvaIn_nominal = 292.55;
  end NominalValues;

  record Stage
    parameter NominalValues nomVal;
  end Stage;
end Heating;

model RecordBinding14
  parameter Heating.DXCoil datCoi(sta = {Heating.Stage(nomVal = Heating.NominalValues(m_flow_nominal = 2))});
  Heating.SingleSpeed sinSpeDX(final datCoi = datCoi);
end RecordBinding14;

// Result:
// class RecordBinding14
//   final parameter Integer datCoi.nSta = 1;
//   parameter Real datCoi.sta[1].nomVal.m_flow_nominal = 2.0;
//   parameter Real datCoi.sta[1].nomVal.TEvaIn_nominal = 292.55;
//   final parameter Integer sinSpeDX.datCoi.nSta = 1;
//   final parameter Real sinSpeDX.datCoi.sta[1].nomVal.m_flow_nominal = datCoi.sta[1].nomVal.m_flow_nominal;
//   final parameter Real sinSpeDX.datCoi.sta[1].nomVal.TEvaIn_nominal = datCoi.sta[1].nomVal.TEvaIn_nominal;
//   final parameter Integer sinSpeDX.dxCoi.datCoi.nSta = 1;
//   final parameter Real sinSpeDX.dxCoi.datCoi.sta[1].nomVal.TEvaIn_nominal = 292.55;
//   final parameter Real sinSpeDX.dxCoi.datCoi.sta[1].nomVal.m_flow_nominal = 2.0;
// end RecordBinding14;
// endResult

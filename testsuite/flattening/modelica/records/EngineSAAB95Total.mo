// name: EngineSAAB95Total
// keywords: record
// status: correct
//
// Tests the built-in cos function
//
package EngineModel
  model Engine
  public
    EngineModel.EngineGeometry data;
    Real displacement;
    constant Real pi=3.1415956;
  equation
    displacement=pi/4*data.bore^2*data.stroke;
  end Engine;

  record EngineGeometry
  public
    parameter Real bore;
    parameter Real stroke;
  end EngineGeometry;

  record SAAB95i
    extends EngineModel.EngineGeometry(bore=0.09, stroke=0.09);
  end SAAB95i;

end EngineModel;

model EngineSAAB95
  EngineModel.Engine engine(data=EngineModel.SAAB95i());
  EngineModel.Engine engine2(data=EngineModel.SAAB95i(bore=3,stroke=5));
end EngineSAAB95;

// Result:
// function EngineModel.EngineGeometry "Automatically generated record constructor for EngineModel.EngineGeometry"
//   input Real bore;
//   input Real stroke;
//   output EngineGeometry res;
// end EngineModel.EngineGeometry;
//
// function EngineModel.SAAB95i "Automatically generated record constructor for EngineModel.SAAB95i"
//   input Real bore = 0.09;
//   input Real stroke = 0.09;
//   output SAAB95i res;
// end EngineModel.SAAB95i;
//
// class EngineSAAB95
//   parameter Real engine.data.bore = 0.09;
//   parameter Real engine.data.stroke = 0.09;
//   Real engine.displacement;
//   constant Real engine.pi = 3.1415956;
//   parameter Real engine2.data.bore = 3.0;
//   parameter Real engine2.data.stroke = 5.0;
//   Real engine2.displacement;
//   constant Real engine2.pi = 3.1415956;
// equation
//   engine.displacement = 0.7853989 * engine.data.bore ^ 2.0 * engine.data.stroke;
//   engine2.displacement = 0.7853989 * engine2.data.bore ^ 2.0 * engine2.data.stroke;
// end EngineSAAB95;
// endResult

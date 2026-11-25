// name:    ExpandableConnectorHierarchy3
// keyword: expandable
// status:  correct
// suite:   disabled
//
// Model by MathCore
//

package Modelica "Modelica Standard Library - Version 3.2.1 (Build 2)"
  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    package Interfaces "Library of connectors and partial models for input/output blocks"
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";

      partial block SO "Single Output continuous control block"
        RealOutput y "Connector of Real output signal";
      end SO;

      package Adaptors "Obsolete package with components to send signals to a bus or receive signals from a bus (only for backward compatibility)"
        block SendReal "Obsolete block to send Real signal to bus"
          RealOutput toBus "Output signal to be connected to bus";
          RealInput u "Input signal to be send to bus";
        equation
          toBus = u;
        end SendReal;

        block ReceiveReal "Obsolete block to receive Real signal from bus"
          RealInput fromBus "To be connected with signal on bus";
          RealOutput y "Output signal to be received from bus";
        equation
          y = fromBus;
        end ReceiveReal;
      end Adaptors;
    end Interfaces;

    package Sources "Library of signal source blocks generating Real and Boolean signals"
      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;
  end Blocks;
end Modelica;

package TestPackage
  expandable connector MyBus
  end MyBus;

  model InputToBus
    MyBus controlBus;
    RealToBus velocityIn;
    Modelica.Blocks.Sources.Constant const(k = 30);
  protected
    MySubBus chassisBus;
  equation
    connect(velocityIn.subBus, chassisBus);
    connect(chassisBus, controlBus.chassis);
    connect(const.y, velocityIn.u);
  end InputToBus;

  model OutputFromBus
    MyBus controlBus;
    RealFromBus vehicleVelocity;
  protected
    MySubBus chassisBus;
  equation
    connect(chassisBus, controlBus.chassis);
    connect(vehicleVelocity.subBus, chassisBus);
  end OutputFromBus;

  expandable connector MySubBus
  end MySubBus;

  model RealToBus
    Modelica.Blocks.Interfaces.RealInput u;
    MySubBus subBus;
    Modelica.Blocks.Interfaces.Adaptors.SendReal velocity(toBus(unit = "m/s"));
  equation
    connect(u, velocity.u);
    connect(velocity.toBus, subBus.velocity);
  end RealToBus;

  model RealFromBus
    Modelica.Blocks.Interfaces.RealOutput y;
    MySubBus subBus;
    Modelica.Blocks.Interfaces.Adaptors.ReceiveReal velocity(y(unit = "m/s"));
  equation
    connect(velocity.y, y);
    connect(velocity.fromBus, subBus.velocity);
  end RealFromBus;
end TestPackage;

model TestModel
  TestPackage.OutputFromBus outputFromBus;
  TestPackage.InputToBus inputToBus;
equation
  connect(outputFromBus.controlBus, inputToBus.controlBus);
end TestModel;

// Result:
// class TestModel
//   Real outputFromBus.vehicleVelocity.y;
//   Real outputFromBus.vehicleVelocity.velocity.fromBus "To be connected with signal on bus";
//   Real outputFromBus.vehicleVelocity.velocity.y(unit = "m/s") "Output signal to be received from bus";
//   Real outputFromBus.vehicleVelocity.subBus.velocity "virtual variable in expandable connector";
//   Real outputFromBus.chassisBus.velocity "virtual variable in expandable connector";
//   Real outputFromBus.controlBus.chassis.velocity "virtual variable in expandable connector";
//   Real inputToBus.velocityIn.u;
//   Real inputToBus.velocityIn.velocity.toBus(unit = "m/s") "Output signal to be connected to bus";
//   Real inputToBus.velocityIn.velocity.u "Input signal to be send to bus";
//   Real inputToBus.velocityIn.subBus.velocity "virtual variable in expandable connector";
//   Real inputToBus.const.y "Connector of Real output signal";
//   parameter Real inputToBus.const.k(start = 1.0) = 30.0 "Constant output value";
//   Real inputToBus.chassisBus.velocity "virtual variable in expandable connector";
//   Real inputToBus.controlBus.chassis.velocity "virtual variable in expandable connector";
// equation
//   outputFromBus.vehicleVelocity.velocity.y = outputFromBus.vehicleVelocity.velocity.fromBus;
//   inputToBus.velocityIn.velocity.toBus = inputToBus.velocityIn.velocity.u;
//   inputToBus.const.y = inputToBus.const.k;
//   outputFromBus.vehicleVelocity.velocity.y = outputFromBus.vehicleVelocity.y;
//   outputFromBus.vehicleVelocity.subBus.velocity = outputFromBus.vehicleVelocity.velocity.fromBus;
//   outputFromBus.chassisBus.velocity = outputFromBus.controlBus.chassis.velocity;
//   outputFromBus.chassisBus.velocity = outputFromBus.vehicleVelocity.subBus.velocity;
//   inputToBus.velocityIn.u = inputToBus.velocityIn.velocity.u;
//   inputToBus.velocityIn.subBus.velocity = inputToBus.velocityIn.velocity.toBus;
//   inputToBus.chassisBus.velocity = inputToBus.controlBus.chassis.velocity;
//   inputToBus.chassisBus.velocity = inputToBus.velocityIn.subBus.velocity;
//   inputToBus.const.y = inputToBus.velocityIn.u;
//   inputToBus.controlBus.chassis.velocity = outputFromBus.controlBus.chassis.velocity;
// end TestModel;
//
// endResult

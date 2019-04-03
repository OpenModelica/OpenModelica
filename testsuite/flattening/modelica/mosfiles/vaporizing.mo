package Modelica
  package Fluid
    package Interfaces
      connector FluidPort
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        flow Real m_flow;
        Real p;
        stream Real[Medium.nC] C_outflow;
      end FluidPort;

      partial model PartialTwoPort
        Modelica.Fluid.System system;
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        Modelica.Fluid.Interfaces.FluidPort port_a(redeclare package Medium = Medium);
      end PartialTwoPort;

      partial model PartialTwoPortTransport
        extends PartialTwoPort;
        parameter Real m_flow_small = system.m_flow_small;
      end PartialTwoPortTransport;
    end Interfaces;

    model System
      parameter Real m_flow_small(min = 0) = 0.01;
    end System;

    package Valves
      model ValveVaporizing
        extends BaseClasses.PartialValve;
      end ValveVaporizing;

      package BaseClasses
        partial model PartialValve
          extends Modelica.Fluid.Interfaces.PartialTwoPortTransport(m_flow_small = system.m_flow_small);
        end PartialValve;
      end BaseClasses;
    end Valves;
  end Fluid;

  package Media
    package Interfaces
      partial package PartialMedium
        final constant Integer nC = 0;
      end PartialMedium;
    end Interfaces;
  end Media;
end Modelica;

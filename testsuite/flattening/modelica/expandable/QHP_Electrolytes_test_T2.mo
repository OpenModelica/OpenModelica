package Modelica
  package Blocks
    package Continuous
      block Integrator
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1;
        parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.InitialState;
        parameter Real y_start = 0;
        extends Interfaces.SISO(y(start = y_start));
      initial equation
        if initType == Init.SteadyState then
          der(y) = 0;
        elseif initType == Init.InitialState or initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = k*u;
      end Integrator;
    end Continuous;

    package Interfaces
      connector RealInput = input Real;
      connector RealOutput = output Real;

      partial block SISO
        RealInput u;
        RealOutput y;
      end SISO;

      partial block SI2SO
        RealInput u1;
        RealInput u2;
        RealOutput y;
      end SI2SO;

      partial block MISO
        parameter Integer nin = 1;
        RealInput u[nin];
        RealOutput y;
      end MISO;
    end Interfaces;

    package Math
      import Modelica.Blocks.Interfaces;

      block Gain
        parameter Real k(start = 1);
        Interfaces.RealInput u;
        Interfaces.RealOutput y;
      equation
        y = k*u;
      end Gain;

      block Sum
        extends Interfaces.MISO;
        parameter Real k[nin] = ones(nin);
      equation
        y = k*u;
      end Sum;

      block Feedback
        input Interfaces.RealInput u1;
        input Interfaces.RealInput u2;
        output Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;

      block Add
        extends Interfaces.SI2SO;
        parameter Real k1 = +1;
        parameter Real k2 = +1;
      equation
        y = k1*u1 + k2*u2;
      end Add;

      block Add3
        parameter Real k1 = +1;
        parameter Real k2 = +1;
        parameter Real k3 = +1;
        input Interfaces.RealInput u1;
        input Interfaces.RealInput u2;
        input Interfaces.RealInput u3;
        output Interfaces.RealOutput y;
      equation
        y = k1*u1 + k2*u2 + k3*u3;
      end Add3;

      block Product
        extends Interfaces.SI2SO;
      equation
        y = u1*u2;
      end Product;

      block Division
        extends Interfaces.SI2SO;
      equation
        y = u1/u2;
      end Division;
    end Math;

    package Types
      type Init = enumeration(NoInit, SteadyState, InitialState, InitialOutput);
    end Types;
  end Blocks;
end Modelica;

package QHP
  package Library
    package Interfaces
      partial model BaseModel end BaseModel;

      partial model BaseFactorIcon
        RealInput_ yBase;
        RealOutput_ y;
      end BaseFactorIcon;

      partial model BaseFactorIcon3
        RealInput_ yBase;
        RealOutput_ y;
      end BaseFactorIcon3;

      partial model BaseFactorIcon4
        RealInput_ yBase;
        RealOutput_ y;
      end BaseFactorIcon4;

      partial model BaseFactorIcon5
        RealInput_ yBase;
        RealOutput_ y;
      end BaseFactorIcon5;

      partial connector SignalBusBlue end SignalBusBlue;

      connector RealInput = input Real;
      connector RealInput_ = input Real;
      connector RealOutput_ = output Real;

      expandable connector BusConnector
        extends QHP.Library.Interfaces.SignalBusBlue;
      end BusConnector;
    end Interfaces;

    package Curves
      function SplineSlope
        input Real x[:];
        input Real y[:];
        input Real slope[:];
        input Real xVal;
        output Real yVal;
      protected
        Integer index;
        Real a1;
        Real a2;
        Real a3;
        Real a4;
        Real x1;
        Real x2;
        Real y1;
        Real y2;
        Real slope1;
        Real slope2;
      algorithm
        if (xVal <= x[1]) then
          yVal := (xVal)*slope[1] + y[1] - x[1]*slope[1];
        elseif (xVal >= x[size(x, 1)]) then
          yVal := (xVal)*slope[size(slope, 1)] + y[size(y, 1)] - (x[size(x, 1)]*slope[size(slope, 1)]);
        else
          index := 1;
          while (xVal > x[index] and index <= size(x, 1)) loop
            index := index + 1;
          end while;
          x1 := x[index - 1];
          x2 := x[index];
          y1 := y[index - 1];
          y2 := y[index];
          slope1 := slope[index - 1];
          slope2 := slope[index];
          a1 := -(-x2*slope2 - x2*slope1 + slope2*x1 + slope1*x1 + 2*y2 - 2*y1)/(x2 - x1)^3;
          a2 := (-x2^2*slope2 - 2*x2^2*slope1 - 3*x2*y1 + x2*slope1*x1 + 3*x2*y2 - x2*slope2*x1 - 3*y1*x1 + slope1*x1^2 + 3*y2*x1 + 2*slope2*x1^2)/(x2 - x1)^3;
          a3 := -(-slope1*x2^3 - 2*x2^2*slope2*x1 - x2^2*slope1*x1 + x2*slope2*x1^2 + 2*x2*slope1*x1^2 + 6*x2*x1*y2 - 6*x2*x1*y1 + slope2*x1^3)/(x2 - x1)^3;
          a4 := (-slope1*x2^3*x1 + y1*x2^3 - slope2*x1^2*x2^2 + slope1*x1^2*x2^2 - 3*y1*x2^2*x1 + 3*y2*x1^2*x2 + slope2*x1^3*x2 - y2*x1^3)/(x2 - x1)^3;
          yVal := a1*(xVal)^3 + a2*(xVal)^2 + a3*(xVal) + a4;
        end if;
      end SplineSlope;

      model Curve
        parameter Real x[:];
        parameter Real y[:];
        parameter Real slope[:];
        QHP.Library.Interfaces.RealInput_ u;
        QHP.Library.Interfaces.RealOutput_ val;
      equation
        val = SplineSlope(x, y, slope, u);
      end Curve;
    end Curves;

    package Factors
      model SimpleMultiply
        extends QHP.Library.Interfaces.BaseFactorIcon;
        QHP.Library.Interfaces.RealInput_ u;
        Modelica.Blocks.Math.Product product;
      equation
        connect(yBase, product.u1);
        connect(product.y, y);
        connect(u, product.u2);
      end SimpleMultiply;

      model SplineValue
        extends QHP.Library.Interfaces.BaseFactorIcon4;
        QHP.Library.Interfaces.RealInput_ u;
        parameter Real data[:, 3];
        Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
        Modelica.Blocks.Math.Product product;
      equation
        connect(curve.u, u);
        connect(yBase, product.u1);
        connect(curve.val, product.u2);
        connect(product.y, y);
      end SplineValue;

      model DelayedToSpline
        extends QHP.Library.Interfaces.BaseFactorIcon5;
        QHP.Library.Interfaces.RealInput_ u;
        parameter Real Tau = 40;
        parameter Real initialValue = 1;
        parameter Real data[:, 3];
        Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
        Modelica.Blocks.Math.Product product;
        Modelica.Blocks.Continuous.Integrator integrator(k = (1/Tau)/Library.SecPerMin, y_start = initialValue);
        Modelica.Blocks.Math.Feedback feedback;
      equation
        connect(yBase, product.u1);
        connect(product.y, y);
        connect(feedback.y, integrator.u);
        connect(integrator.y, feedback.u2);
        connect(feedback.u1, u);
        connect(integrator.y, curve.u);
        connect(curve.val, product.u2);
      end DelayedToSpline;

      model SplineDelayByDay
        extends QHP.Library.Interfaces.BaseFactorIcon3;
        QHP.Library.Interfaces.RealInput_ u;
        parameter Real Tau;
        parameter Real data[:, 3];
        Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
        Modelica.Blocks.Math.Product product;
        Modelica.Blocks.Continuous.Integrator integrator(y_start = 1, k = (1/(Tau*1440))/Library.SecPerMin);
        Modelica.Blocks.Math.Feedback feedback;
      equation
        connect(curve.u, u);
        connect(yBase, product.u1);
        connect(product.y, y);
        connect(curve.val, feedback.u1);
        connect(feedback.y, integrator.u);
        connect(integrator.y, feedback.u2);
        connect(integrator.y, product.u2);
      end SplineDelayByDay;
    end Factors;

    package Blocks
      block Constant
        parameter Real k(start = 1);
        QHP.Library.Interfaces.RealOutput_ y;
      equation
        y = k;
      end Constant;

      block FractConstant
        parameter Real k(start = 1);
        QHP.Library.Interfaces.RealOutput_ y(final unit = "1");
      equation
        y = k/100;
      end FractConstant;

      block OsmolarityConstant
        parameter Real k(start = 1, final quantity = "Osmolarity", final unit = "mOsm");
        QHP.Library.Interfaces.RealOutput_ y(final quantity = "Osmolarity", final unit = "mOsm");
      equation
        y = k;
      end OsmolarityConstant;

      block ElectrolytesMassConstant
        parameter Real k(start = 1, final quantity = "Mass", final unit = "mEq");
        QHP.Library.Interfaces.RealOutput_ y(final quantity = "Mass", final unit = "mEq");
      equation
        y = k;
      end ElectrolytesMassConstant;

      block ElectrolytesFlowConstant
        parameter Real k(start = 1, final quantity = "Flow", final unit = "mEq/min");
        QHP.Library.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "mEq/min");
      equation
        y = k;
      end ElectrolytesFlowConstant;
    end Blocks;

    package ConcentrationFlow
      replaceable type Concentration = Real(final quantity = "Concentration");
      replaceable type SoluteFlow = Real(final quantity = "Flow");

      connector ConcentrationFlow
        Concentration conc;
        flow SoluteFlow q;
      end ConcentrationFlow;

      connector PositiveConcentrationFlow
        extends QHP.Library.ConcentrationFlow.ConcentrationFlow;
      end PositiveConcentrationFlow;

      connector NegativeConcentrationFlow
        extends QHP.Library.ConcentrationFlow.ConcentrationFlow;
      end NegativeConcentrationFlow;

      model FlowMeasure
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        QHP.Library.Interfaces.RealOutput_ actualFlow;
      equation
        q_in.q + q_out.q = 0;
        q_out.conc = q_in.conc;
        actualFlow = q_in.q;
      end FlowMeasure;

      model ConcentrationMeasure
        parameter String unitsString = "";
        parameter Real toAnotherUnitCoef = 1;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        QHP.Library.Interfaces.RealOutput_ actualConc;
      equation
        actualConc = toAnotherUnitCoef*q_in.conc;
        q_in.q = 0;
      end ConcentrationMeasure;

      model SolventFlowPump
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        Interfaces.RealInput_ solventFlow;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
      equation
        if (solventFlow >= 0) then
          q_in.q + q_out.q = 0;
          q_in.q = solventFlow*q_in.conc;
        else
          q_in.q + q_out.q = 0;
          q_in.q = solventFlow*q_out.conc;
        end if;
      end SolventFlowPump;

      model SolventOutflowPump
        QHP.Library.Interfaces.RealInput solventFlow;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        parameter Real K = 1;
      equation
        q_in.q = K*solventFlow*q_in.conc;
      end SolventOutflowPump;

      model InputPump
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.Interfaces.RealInput_ desiredFlow;
      equation
        q_out.q = -desiredFlow;
      end InputPump;

      model OutputPump
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        QHP.Library.Interfaces.RealInput_ desiredFlow;
      equation
        q_in.q = desiredFlow;
      end OutputPump;

      model SoluteFlowPump
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.Interfaces.RealInput soluteFlow;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
      equation
        q_in.q + q_out.q = 0;
        q_in.q = soluteFlow;
      end SoluteFlowPump;

      model FractReabsorbtion
        Library.ConcentrationFlow.PositiveConcentrationFlow Inflow;
        Library.ConcentrationFlow.NegativeConcentrationFlow Outflow;
        Library.ConcentrationFlow.NegativeConcentrationFlow Reabsorbtion;
        QHP.Library.Interfaces.RealInput_ Normal(final unit = "1");
        QHP.Library.Interfaces.RealInput_ Effects(final unit = "1");
        parameter SoluteFlow MaxReab = 14;
        Interfaces.RealOutput_ ReabFract(final unit = "1");
      equation
        Outflow.q + Inflow.q + Reabsorbtion.q = 0;
        Outflow.conc = Inflow.conc;
        Reabsorbtion.q = -min(ReabFract*Inflow.q, MaxReab);
        ReabFract = if (Normal <= 0) or (Effects <= 0) then 0 else if Normal > 1 then 1 else Normal^(1/Effects);
      end FractReabsorbtion;

      model FractReabsorbtion2
        Library.ConcentrationFlow.PositiveConcentrationFlow Inflow;
        Library.ConcentrationFlow.NegativeConcentrationFlow Outflow;
        Library.ConcentrationFlow.NegativeConcentrationFlow Reabsorbtion;
        QHP.Library.Interfaces.RealInput_ Normal(final unit = "1");
        QHP.Library.Interfaces.RealInput_ Effects(final unit = "1");
        Real ReabFract(final unit = "1");
        QHP.Library.Interfaces.RealInput_ MaxReab;
      equation
        Outflow.q + Inflow.q + Reabsorbtion.q = 0;
        Outflow.conc = Inflow.conc;
        Reabsorbtion.q = -min(ReabFract*Inflow.q, MaxReab);
        ReabFract = if (Normal <= 0) or (Effects <= 0) then 0 else if Normal > 1 then 1 else Normal^(1/Effects);
      end FractReabsorbtion2;

      model ConcentrationCompartment
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        parameter Real initialSoluteMass;
        QHP.Library.Interfaces.RealInput_ SolventVolume(final quantity = "Volume", final unit = "ml");
        QHP.Library.Interfaces.RealOutput_ SoluteMass;
      initial equation
        SoluteMass = initialSoluteMass;
      equation
        q_out.conc = if (SolventVolume > 0) then SoluteMass/SolventVolume else 0;
        der(SoluteMass) = q_out.q/Library.SecPerMin;
      end ConcentrationCompartment;
    end ConcentrationFlow;

    constant Real SecPerMin(unit = "s/min") = 60;
  end Library;

  package Electrolytes
    package Sodium
      model GlomerulusCationFiltration
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        Library.Interfaces.RealInput_ otherCations(final quantity = "Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
        Real KAdjustment;
        Real Cations(final quantity = "Concentration", final unit = "mEq/l");
        Real Anions(final quantity = "Concentration", final unit = "mEq/l");
      equation
        q_in.q + q_out.q = 0;
        Cations = q_in.conc*1000 + otherCations;
        Anions = Cations;
        KAdjustment = (Cations - (Anions - ProteinAnions))/(Cations + (Anions - ProteinAnions));
        q_out.conc = (1 - KAdjustment)*q_in.conc;
      end GlomerulusCationFiltration;

      model Sodium2
        Library.ConcentrationFlow.ConcentrationCompartment NaPool(initialSoluteMass = 2170.0);
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 80.0);
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion;
        Modelica.Blocks.Math.Gain Perm(k = .0015);
        Library.ConcentrationFlow.OutputPump Hemorrhage;
        Library.ConcentrationFlow.OutputPump DialyzerActivity;
        Library.ConcentrationFlow.OutputPump SweatDuct;
        Library.ConcentrationFlow.InputPump IVDrip;
        Library.ConcentrationFlow.InputPump Transfusion;
        Library.ConcentrationFlow.SolventFlowPump glomerulusSudiumRate;
        QHP.Electrolytes.Sodium.GlomerulusCationFiltration glomerulus;
        Library.ConcentrationFlow.FractReabsorbtion PT;
        Library.Blocks.FractConstant const1(k = 58);
        QHP.Library.Factors.SplineValue IFPEffect(data = {{1.0, 1.4, 0}, {4.0, 1.0, -0.2}, {7.0, 0.3, 0}});
        QHP.Library.Factors.SplineValue ANPEffect(data = {{0.0, 1.2, 0}, {1.3, 1.0, -0.2}, {2.7, 0.6, 0}});
        QHP.Library.Factors.SplineValue SympsEffect(data = {{0.6, 0.6, 0}, {1.0, 1.0, 0.5}, {4.0, 1.5, 0}});
        QHP.Library.Factors.SplineValue A2Effect(data = {{0.7, 0.8, 0}, {1.3, 1.0, 0.8}, {1.6, 1.2, 0}});
        Library.ConcentrationFlow.FractReabsorbtion LH(MaxReab = 7);
        Library.Blocks.FractConstant const2(k = 75);
        Library.ConcentrationFlow.FractReabsorbtion2 DT;
        Library.ConcentrationFlow.FractReabsorbtion CD(MaxReab = .7);
        Library.Blocks.FractConstant const3(k = 75);
        Library.Blocks.FractConstant const4(k = 75);
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0);
        QHP.Library.Factors.SplineValue Furosemide(data = {{0.0, 1.0, -1}, {0.1, 0.0, 0}});
        Library.Factors.DelayedToSpline AldoEffect(data = {{0.0, 0.7, 0}, {10.0, 1.0, 0}}, Tau = 3*60, initialValue = 11);
        QHP.Library.Factors.SplineValue LoadEffect(data = {{0.0, 3.0, 0}, {7.2, 1.0, -0.2}, {20.0, 0.5, 0}});
        QHP.Library.Factors.SimpleMultiply FurosemideEffect;
        QHP.Library.Factors.SimpleMultiply Filtering_xNormal;
        Library.ConcentrationFlow.FlowMeasure flowMeasure;
        Library.ConcentrationFlow.FlowMeasure flowMeasure1;
        QHP.Library.Factors.SplineValue LoadEffect1(data = {{0.0, 2.0, 0}, {1.6, 1.0, 0}});
        QHP.Library.Factors.SplineValue ThiazideEffect(data = {{0.0, 1.0, -2.0}, {0.6, 0.2, 0.0}});
        Library.ConcentrationFlow.FlowMeasure flowMeasure2;
        QHP.Library.Factors.SplineValue LoadEffect2(data = {{0.0, 2.0, 0}, {0.4, 1.0, 0}});
        QHP.Library.Factors.SplineValue ANPEffect2(data = {{0.0, 1.2, 0}, {1.3, 1.0, -0.4}, {2.7, 0.2, 0}});
        Library.Factors.SimpleMultiply AldoEffect2;
        QHP.Library.Blocks.Constant const5(k = 2);
        Library.ConcentrationFlow.InputPump Diet;
        Library.ConcentrationFlow.OutputPump Diarrhea;
        Library.ConcentrationFlow.FlowMeasure flowMeasure3;
        Library.ConcentrationFlow.ConcentrationCompartment Medulla(initialSoluteMass = 13);
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
        Library.ConcentrationFlow.SolventFlowPump VasaRectaOutflow;
        Modelica.Blocks.Math.Gain gain(k = .03);
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid;
        Library.ConcentrationFlow.FlowMeasure flowMeasure4;
        Library.ConcentrationFlow.FlowMeasure flowMeasure5;
        Library.ConcentrationFlow.FlowMeasure flowMeasure6;
        Library.Interfaces.BusConnector busConnector;
        Modelica.Blocks.Math.Gain Osm(k = 2);
        Library.Factors.DelayedToSpline AldoEffect1(Tau = 3*60, initialValue = 11, data = {{0.0, 0.5, 0}, {12.0, 1.0, 0.08}, {50.0, 3.0, 0}});
      equation
        connect(NaPool.SolventVolume, busConnector.ECFV_Vol);
        connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass);
        connect(GILumen.q_out, Absorbtion.q_in);
        connect(Absorbtion.q_out, NaPool.q_out);
        connect(Hemorrhage.q_in, NaPool.q_out);
        connect(DialyzerActivity.q_in, NaPool.q_out);
        connect(NaPool.q_out, SweatDuct.q_in);
        connect(Transfusion.q_out, NaPool.q_out);
        connect(IVDrip.q_out, NaPool.q_out);
        connect(glomerulusSudiumRate.solventFlow, busConnector.GlomerulusFiltrate_GFR);
        connect(glomerulus.q_in, NaPool.q_out);
        connect(glomerulus.q_out, glomerulusSudiumRate.q_in);
        connect(glomerulusSudiumRate.q_out, PT.Inflow);
        connect(const1.y, PT.Normal);
        connect(A2Effect.yBase, busConnector.KidneyFunctionEffect);
        connect(A2Effect.y, SympsEffect.yBase);
        connect(SympsEffect.y, ANPEffect.yBase);
        connect(ANPEffect.y, IFPEffect.yBase);
        connect(IFPEffect.y, PT.Effects);
        connect(busConnector.A2Pool_Log10Conc, A2Effect.u);
        connect(SympsEffect.u, busConnector.KidneyAlpha_PT_NA);
        connect(busConnector.NephronANP_Log10Conc, ANPEffect.u);
        connect(busConnector.NephronIFP_Pressure, IFPEffect.u);
        connect(const2.y, LH.Normal);
        connect(const3.y, CD.Normal);
        connect(const4.y, DT.Normal);
        connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass);
        connect(busConnector.Aldo_conc_in_nG_per_dl, AldoEffect.u);
        connect(Furosemide.u, busConnector.FurosemidePool_Furosemide_conc);
        connect(AldoEffect.y, LoadEffect.yBase);
        connect(LoadEffect.y, LH.Effects);
        connect(FurosemideEffect.y, AldoEffect.yBase);
        connect(Filtering_xNormal.u, busConnector.Kidney_NephronCount_Filtering_xNormal);
        connect(Filtering_xNormal.y, FurosemideEffect.u);
        connect(Furosemide.y, Filtering_xNormal.yBase);
        connect(busConnector.KidneyFunctionEffect, Furosemide.yBase);
        connect(FurosemideEffect.yBase, busConnector.KidneyFunctionEffect);
        connect(PT.Outflow, flowMeasure.q_in);
        connect(flowMeasure.q_out, LH.Inflow);
        connect(flowMeasure.actualFlow, LoadEffect.u);
        connect(DT.Inflow, flowMeasure1.q_out);
        connect(flowMeasure1.q_in, LH.Outflow);
        connect(LoadEffect1.y, DT.Effects);
        connect(LoadEffect1.u, flowMeasure1.actualFlow);
        connect(ThiazideEffect.u, busConnector.ThiazidePool_Thiazide_conc);
        connect(CD.Inflow, flowMeasure2.q_out);
        connect(flowMeasure2.q_in, DT.Outflow);
        connect(LoadEffect2.y, CD.Effects);
        connect(LoadEffect2.u, flowMeasure2.actualFlow);
        connect(ANPEffect2.y, LoadEffect2.yBase);
        connect(ANPEffect2.yBase, busConnector.KidneyFunctionEffect);
        connect(ANPEffect2.u, busConnector.NephronANP_Log10Conc);
        connect(IVDrip.desiredFlow, busConnector.IVDrip_NaRate);
        connect(Transfusion.desiredFlow, busConnector.Transfusion_NaRate);
        connect(SweatDuct.desiredFlow, busConnector.SweatDuct_NaRate);
        connect(const5.y, AldoEffect2.yBase);
        connect(AldoEffect2.y, DT.MaxReab);
        connect(busConnector.Hemorrhage_NaRate, Hemorrhage.desiredFlow);
        connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_Na_Flux);
        connect(glomerulus.otherCations, busConnector.KPool);
        connect(glomerulus.ProteinAnions, busConnector.BloodIons_ProteinAnions);
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_Na);
        connect(Diet.q_out, GILumen.q_out);
        connect(Diarrhea.desiredFlow, busConnector.GILumenDiarrhea_NaLoss);
        connect(GILumen.q_out, Diarrhea.q_in);
        connect(GILumen.SoluteMass, Perm.u);
        connect(Perm.y, Absorbtion.soluteFlow);
        connect(CD.Outflow, flowMeasure3.q_in);
        connect(flowMeasure3.q_out, Bladder.q_out);
        connect(CD.Reabsorbtion, Medulla.q_out);
        connect(Medulla.q_out, concentrationMeasure.q_in);
        connect(concentrationMeasure.actualConc, busConnector.MedullaNa_conc);
        connect(Medulla.q_out, VasaRectaOutflow.q_in);
        connect(VasaRectaOutflow.q_out, NaPool.q_out);
        connect(gain.y, VasaRectaOutflow.solventFlow);
        connect(busConnector.VasaRecta_Outflow, gain.u);
        connect(Medulla.SolventVolume, busConnector.Medulla_Volume);
        connect(NaPool.SoluteMass, busConnector.NaPool_mass);
        connect(concentrationMeasure1.q_in, NaPool.q_out);
        connect(Bladder.q_out, bladderVoid.q_in);
        connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow);
        connect(GILumen.SoluteMass, busConnector.GILumenSodium_Mass);
        connect(AldoEffect1.y, busConnector.DT_AldosteroneEffect);
        connect(DT.Reabsorbtion, flowMeasure4.q_in);
        connect(flowMeasure4.q_out, NaPool.q_out);
        connect(flowMeasure5.actualFlow, busConnector.LH_Na_Reab);
        connect(LH.Reabsorbtion, flowMeasure5.q_in);
        connect(flowMeasure5.q_out, NaPool.q_out);
        connect(flowMeasure6.actualFlow, busConnector.PT_Na_Reab);
        connect(PT.Reabsorbtion, flowMeasure6.q_in);
        connect(flowMeasure6.q_out, NaPool.q_out);
        connect(concentrationMeasure1.actualConc, busConnector.NaPool_conc_per_liter);
        connect(concentrationMeasure.actualConc, Osm.u);
        connect(Osm.y, busConnector.MedullaNa_Osmolarity);
        connect(busConnector.Aldo_conc_in_nG_per_dl, AldoEffect1.u);
        connect(busConnector.KidneyFunctionEffect, AldoEffect1.yBase);
        connect(AldoEffect1.y, ThiazideEffect.yBase);
        connect(ThiazideEffect.y, LoadEffect1.yBase);
        connect(AldoEffect1.y, AldoEffect2.u);
        connect(LH.ReabFract, busConnector.LH_Na_FractReab);
        connect(PT.ReabFract, busConnector.PT_Na_FractReab);
        connect(flowMeasure2.actualFlow, busConnector.DT_Na_Outflow);
        connect(flowMeasure3.actualFlow, busConnector.CD_Na_Outflow);
        connect(flowMeasure4.actualFlow, busConnector.DT_Na_Reab);
        connect(concentrationMeasure.actualConc, busConnector.MedullaNa_conc);
      end Sodium2;
    end Sodium;

    package Potassium
      model IkedaPotasiumIntoICFFactor
        Library.Interfaces.RealInput_ yBase;
        Library.Interfaces.RealOutput_ y;
        Library.Interfaces.RealInput_ Artys_pH;
        Library.Interfaces.RealInput_ PotasiumECF_conc;
        Real effect;
      equation
        effect = 1 + 0.5*log(PotasiumECF_conc/(56.744 - 7.06*Artys_pH));
        y = yBase*effect;
      end IkedaPotasiumIntoICFFactor;

      model Potassium2
        Library.ConcentrationFlow.ConcentrationCompartment KPool(initialSoluteMass = 66.0);
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 25);
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion;
        Modelica.Blocks.Math.Gain Perm(k = .002);
        Library.ConcentrationFlow.OutputPump Hemorrhage;
        Library.ConcentrationFlow.OutputPump DialyzerActivity;
        Library.ConcentrationFlow.OutputPump SweatDuct;
        Library.ConcentrationFlow.InputPump IVDrip;
        Library.ConcentrationFlow.InputPump Transfusion;
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0);
        QHP.Library.Factors.SplineValue NaEffect(data = {{0.0, 0.3, 0}, {0.4, 1.0, 1.5}, {4.0, 3.0, 0}});
        Library.Factors.DelayedToSpline AldoEffect(data = {{0.0, 0.5, 0}, {12.0, 1.0, 0.08}, {50.0, 3.0, 0}}, Tau = 3*60, initialValue = 11);
        QHP.Library.Factors.SplineValue ThiazideEffect(data = {{0.0, 1.0, 2.0}, {0.6, 2.0, 0}});
        Library.ConcentrationFlow.InputPump Diet;
        Library.ConcentrationFlow.OutputPump Diarrhea;
        Library.ConcentrationFlow.ConcentrationCompartment KCell(initialSoluteMass = 3980);
        Library.ConcentrationFlow.SoluteFlowPump KFluxToCell;
        Modelica.Blocks.Math.Gain Perm1(k = .002);
        Library.ConcentrationFlow.SoluteFlowPump KFluxToPool;
        Modelica.Blocks.Math.Feedback feedback;
        QHP.Library.Blocks.ElectrolytesMassConstant KCell_CaptiveMass(k = 2180);
        Modelica.Blocks.Math.Gain Perm2(k = 7.4e-5);
        Library.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k = .05);
        Library.ConcentrationFlow.SoluteFlowPump DT_K;
        QHP.Library.Factors.SplineValue KEffect(data = {{0.0, 0.0, 0}, {4.4, 1.0, 0.5}, {5.5, 3.0, 0}});
        Modelica.Blocks.Math.Gain mEq_per_L(k = 1000);
        Modelica.Blocks.Math.Division division;
        Library.Factors.SimpleMultiply KidneyFunction;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
        Modelica.Blocks.Math.Gain gain(k = 1000);
        Library.Factors.SplineDelayByDay splineDelayByDay(data = {{0, 0.9, 0.0}, {300, 1.0, 0.00025}, {1500, 1.1, 0.0}}, Tau = 120*1440);
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
        Library.ConcentrationFlow.FlowMeasure flowMeasure;
        Library.ConcentrationFlow.SoluteFlowPump KFluxToCellWithGlucose;
        Modelica.Blocks.Math.Gain CGL3(k = .03);
        IkedaPotasiumIntoICFFactor IkedaIntoICF;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
        Library.Interfaces.BusConnector busConnector;
        Modelica.Blocks.Math.Add3 YGLS;
      equation
        connect(KPool.SolventVolume, busConnector.ECFV_Vol);
        connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass);
        connect(GILumen.q_out, Absorbtion.q_in);
        connect(Absorbtion.q_out, KPool.q_out);
        connect(Hemorrhage.q_in, KPool.q_out);
        connect(DialyzerActivity.q_in, KPool.q_out);
        connect(KPool.q_out, SweatDuct.q_in);
        connect(Transfusion.q_out, KPool.q_out);
        connect(IVDrip.q_out, KPool.q_out);
        connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass);
        connect(AldoEffect.y, NaEffect.yBase);
        connect(ThiazideEffect.y, AldoEffect.yBase);
        connect(ThiazideEffect.u, busConnector.ThiazidePool_Thiazide_conc);
        connect(IVDrip.desiredFlow, busConnector.IVDrip_KRate);
        connect(Transfusion.desiredFlow, busConnector.Transfusion_KRate);
        connect(SweatDuct.desiredFlow, busConnector.SweatDuct_KRate);
        connect(busConnector.Hemorrhage_KRate, Hemorrhage.desiredFlow);
        connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_K_Flux);
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_K);
        connect(Diet.q_out, GILumen.q_out);
        connect(Diarrhea.desiredFlow, busConnector.GILumenDiarrhea_KLoss);
        connect(GILumen.q_out, Diarrhea.q_in);
        connect(KCell.SolventVolume, busConnector.CellH2O_Vol);
        connect(Perm.y, Absorbtion.soluteFlow);
        connect(Perm.u, GILumen.SoluteMass);
        connect(KFluxToCell.q_out, KCell.q_out);
        connect(KCell.q_out, KFluxToPool.q_in);
        connect(KPool.SoluteMass, Perm1.u);
        connect(KCell.SoluteMass, feedback.u1);
        connect(KCell_CaptiveMass.y, feedback.u2);
        connect(feedback.y, Perm2.u);
        connect(KFluxToPool.soluteFlow, Perm2.y);
        connect(AldoEffect.u, busConnector.Aldo_conc_in_nG_per_dl);
        connect(NaEffect.u, busConnector.DT_Na_Outflow);
        connect(KPool.q_out, DT_K.q_in);
        connect(NaEffect.y, KEffect.yBase);
        connect(KEffect.y, DT_K.soluteFlow);
        connect(mEq_per_L.y, KEffect.u);
        connect(division.u1, KPool.SoluteMass);
        connect(busConnector.ECFV_Vol, division.u2);
        connect(division.y, mEq_per_L.u);
        connect(electrolytesFlowConstant.y, KidneyFunction.yBase);
        connect(KidneyFunction.y, ThiazideEffect.yBase);
        connect(KidneyFunction.u, busConnector.KidneyFunctionEffect);
        connect(DT_K.q_out, Bladder.q_out);
        connect(busConnector.KCell_Mass, KCell.SoluteMass);
        connect(KPool.SoluteMass, busConnector.KPool_mass);
        connect(concentrationMeasure.q_in, KPool.q_out);
        connect(concentrationMeasure.actualConc, gain.u);
        connect(gain.y, busConnector.KPool_conc_per_liter);
        connect(Perm1.y, splineDelayByDay.yBase);
        connect(splineDelayByDay.u, busConnector.AldoPool_Aldo);
        connect(Bladder.q_out, bladderVoid.q_in);
        connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow);
        connect(GILumen.SoluteMass, busConnector.GILumenPotassium_Mass);
        connect(KCell.q_out, concentrationMeasure1.q_in);
        connect(concentrationMeasure1.actualConc, busConnector.KCell_conc);
        connect(KPool.q_out, flowMeasure.q_in);
        connect(flowMeasure.q_out, KFluxToPool.q_out);
        connect(flowMeasure.q_out, KFluxToCell.q_in);
        connect(flowMeasure.actualFlow, busConnector.PotassiumToCells);
        connect(flowMeasure.q_out, KFluxToCellWithGlucose.q_in);
        connect(KFluxToCellWithGlucose.q_out, KCell.q_out);
        connect(CGL3.y, KFluxToCellWithGlucose.soluteFlow);
        connect(IkedaIntoICF.y, KFluxToCell.soluteFlow);
        connect(splineDelayByDay.y, IkedaIntoICF.yBase);
        connect(IkedaIntoICF.Artys_pH, busConnector.Artys_pH);
        connect(concentrationMeasure2.q_in, KPool.q_out);
        connect(concentrationMeasure2.actualConc, IkedaIntoICF.PotasiumECF_conc);
        connect(concentrationMeasure2.actualConc, busConnector.KPool_per_liter);
        connect(busConnector.skeletalMuscle_GlucoseToCellStorageFlow, YGLS.u2);
        connect(busConnector.liver_GlucoseToCellStorageFlow, YGLS.u1);
        connect(busConnector.respiratoryMuscle_GlucoseToCellStorageFlow, YGLS.u3);
        connect(YGLS.y, CGL3.u);
        connect(KEffect.y, busConnector.CD_K_Outflow);
        connect(concentrationMeasure2.actualConc, busConnector.KPool);
        connect(GILumen.SoluteMass, busConnector.GILumenPotassium_Mass);
      end Potassium2;
    end Potassium;

    package Chloride
      model Chloride2
        Library.ConcentrationFlow.ConcentrationCompartment ClPool(initialSoluteMass = 1562.23);
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 90);
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion;
        Modelica.Blocks.Math.Gain Perm(k = .0015);
        Library.ConcentrationFlow.OutputPump Hemorrhage;
        Library.ConcentrationFlow.OutputPump DialyzerActivity;
        Library.ConcentrationFlow.OutputPump SweatDuct;
        Library.ConcentrationFlow.InputPump IVDrip;
        Library.ConcentrationFlow.InputPump Transfusion;
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0);
        Library.ConcentrationFlow.InputPump Diet;
        Library.ConcentrationFlow.OutputPump Diarrhea;
        Library.ConcentrationFlow.SoluteFlowPump CD_Cl;
        QHP.Library.Factors.SplineValue KEffect1(data = {{7.00, 1.00, 0}, {7.45, 0.93, -0.5}, {7.80, 0.00, 0}});
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
        Modelica.Blocks.Math.Gain gain(k = 1000);
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid;
        Library.Interfaces.BusConnector busConnector;
      equation
        connect(ClPool.SolventVolume, busConnector.ECFV_Vol);
        connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass);
        connect(GILumen.q_out, Absorbtion.q_in);
        connect(Absorbtion.q_out, ClPool.q_out);
        connect(Hemorrhage.q_in, ClPool.q_out);
        connect(DialyzerActivity.q_in, ClPool.q_out);
        connect(ClPool.q_out, SweatDuct.q_in);
        connect(Transfusion.q_out, ClPool.q_out);
        connect(IVDrip.q_out, ClPool.q_out);
        connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass);
        connect(IVDrip.desiredFlow, busConnector.IVDrip_ClRate);
        connect(Transfusion.desiredFlow, busConnector.Transfusion_ClRate);
        connect(SweatDuct.desiredFlow, busConnector.SweatDuct_ClRate);
        connect(busConnector.Hemorrhage_ClRate, Hemorrhage.desiredFlow);
        connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_Cl_Flux);
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_Cl);
        connect(Diet.q_out, GILumen.q_out);
        connect(Diarrhea.desiredFlow, busConnector.GILumenVomitus_ClLoss);
        connect(GILumen.q_out, Diarrhea.q_in);
        connect(Perm.y, Absorbtion.soluteFlow);
        connect(Perm.u, GILumen.SoluteMass);
        connect(busConnector.CollectingDuct_NetSumCats, KEffect1.yBase);
        connect(CD_Cl.soluteFlow, KEffect1.y);
        connect(CD_Cl.q_out, Bladder.q_out);
        connect(CD_Cl.q_in, ClPool.q_out);
        connect(ClPool.SoluteMass, busConnector.ClPool_mass);
        connect(concentrationMeasure.actualConc, gain.u);
        connect(gain.y, busConnector.ClPool_conc_per_liter);
        connect(ClPool.q_out, concentrationMeasure.q_in);
        connect(Bladder.q_out, bladderVoid.q_in);
        connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow);
        connect(busConnector.Artys_pH, KEffect1.u);
      end Chloride2;
    end Chloride;

    package Phosphate
      model GlomerulusStrongAnionFiltration
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        Library.Interfaces.RealInput_ Cations(final quantity = "Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ otherStrongAnions(final quantity = "Concentration", final unit = "mEq/l");
        Real KAdjustment;
        Real Anions(final quantity = "Concentration", final unit = "mEq/l");
        Real ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ HCO3(final quantity = "Concentration", final unit = "mEq/l");
      equation
        q_in.q + q_out.q = 0;
        Anions = Cations;
        ProteinAnions = Anions - otherStrongAnions - q_in.conc*1000 - HCO3;
        KAdjustment = (Cations - (Anions - ProteinAnions))/(Cations + (Anions - ProteinAnions));
        q_out.conc = (1 + KAdjustment)*q_in.conc;
      end GlomerulusStrongAnionFiltration;

      model Phosphate2
        Library.ConcentrationFlow.ConcentrationCompartment PO4Pool(initialSoluteMass = 2.6);
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0);
        Library.ConcentrationFlow.InputPump Diet;
        Library.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate;
        GlomerulusStrongAnionFiltration glomerulus;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
        Modelica.Blocks.Math.Gain gain(k = 1000);
        Library.ConcentrationFlow.FlowMeasure flowMeasure;
        Modelica.Blocks.Math.Gain gain1(k = .5);
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mmol/l", toAnotherUnitCoef = 1000);
        Library.Interfaces.BusConnector busConnector;
      equation
        connect(PO4Pool.SolventVolume, busConnector.ECFV_Vol);
        connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass);
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_PO4);
        connect(Diet.q_out, PO4Pool.q_out);
        connect(glomerulusPhosphateRate.solventFlow, busConnector.GlomerulusFiltrate_GFR);
        connect(glomerulus.q_out, glomerulusPhosphateRate.q_in);
        connect(PO4Pool.q_out, glomerulus.q_in);
        connect(glomerulus.HCO3, busConnector.CO2Veins_cHCO3);
        connect(concentrationMeasure.actualConc, gain.u);
        connect(gain.y, busConnector.PO4Pool_conc_per_liter);
        connect(concentrationMeasure.q_in, PO4Pool.q_out);
        connect(flowMeasure.actualFlow, busConnector.CD_PO4_Outflow);
        connect(flowMeasure.q_out, Bladder.q_out);
        connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in);
        connect(busConnector.BloodIons_StrongAnionsLessPO4, glomerulus.otherStrongAnions);
        connect(busConnector.BloodIons_Cations, glomerulus.Cations);
        connect(PO4Pool.SoluteMass, gain1.u);
        connect(gain1.y, busConnector.PO4Pool_Osmoles);
        connect(Bladder.q_out, bladderVoid.q_in);
        connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow);
        connect(concentrationMeasure1.actualConc, busConnector.ctPO4);
        connect(concentrationMeasure1.q_in, PO4Pool.q_out);
      end Phosphate2;
    end Phosphate;

    package Sulphate
      model GlomerulusStrongAnionFiltration
        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out;
        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in;
        Library.Interfaces.RealInput_ Cations(final quantity = "Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ otherStrongAnions(final quantity = "Concentration", final unit = "mEq/l");
        Real KAdjustment;
        Real Anions(final quantity = "Concentration", final unit = "mEq/l");
        Real ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ HCO3(final quantity = "Concentration", final unit = "mEq/l");
      equation
        q_in.q + q_out.q = 0;
        Anions = Cations;
        ProteinAnions = Anions - otherStrongAnions - q_in.conc*1000 - HCO3;
        KAdjustment = (Cations - (Anions - ProteinAnions))/(Cations + (Anions - ProteinAnions));
        q_out.conc = (1 + KAdjustment)*q_in.conc;
      end GlomerulusStrongAnionFiltration;

      model Sulphate2
        Library.ConcentrationFlow.ConcentrationCompartment SO4Pool(initialSoluteMass = 4.2);
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0);
        Library.ConcentrationFlow.InputPump Diet;
        Library.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate;
        GlomerulusStrongAnionFiltration glomerulus;
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
        Modelica.Blocks.Math.Gain gain(k = 1000);
        Library.ConcentrationFlow.FlowMeasure flowMeasure;
        Modelica.Blocks.Math.Gain gain1(k = .5);
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid;
        Library.Interfaces.BusConnector busConnector;
      equation
        connect(SO4Pool.SolventVolume, busConnector.ECFV_Vol);
        connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass);
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_SO4);
        connect(Diet.q_out, SO4Pool.q_out);
        connect(glomerulusPhosphateRate.solventFlow, busConnector.GlomerulusFiltrate_GFR);
        connect(glomerulus.q_out, glomerulusPhosphateRate.q_in);
        connect(SO4Pool.q_out, glomerulus.q_in);
        connect(glomerulus.HCO3, busConnector.CO2Veins_cHCO3);
        connect(concentrationMeasure.actualConc, gain.u);
        connect(gain.y, busConnector.SO4Pool_conc_per_liter);
        connect(concentrationMeasure.q_in, SO4Pool.q_out);
        connect(flowMeasure.actualFlow, busConnector.CD_SO4_Outflow);
        connect(flowMeasure.q_out, Bladder.q_out);
        connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in);
        connect(busConnector.BloodIons_StrongAnionsLessSO4, glomerulus.otherStrongAnions);
        connect(busConnector.BloodIons_Cations, glomerulus.Cations);
        connect(gain1.y, busConnector.SO4Pool_Osmoles);
        connect(gain1.u, SO4Pool.SoluteMass);
        connect(Bladder.q_out, bladderVoid.q_in);
        connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow);
      end Sulphate2;
    end Sulphate;

    package NH4
      model Amonium2
        extends Library.Interfaces.BaseModel;
        Library.Factors.SplineValue AcuteEffect(data = {{7.00, 2.0, 0}, {7.45, 1.0, -3.0}, {7.80, 0.0, 0}});
        Library.Factors.SplineDelayByDay ChronicEffect(Tau = 3, data = {{7.00, 3.0, 0}, {7.45, 1.0, -4.0}, {7.80, 0.0, 0}});
        Library.Factors.SplineValue PhOnFlux(data = {{7.00, 1.0, 0}, {7.45, 0.6, -2.0}, {7.80, 0.0, 0}});
        Library.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k = 0.04);
        Library.Interfaces.BusConnector busConnector;
      equation
        connect(AcuteEffect.y, ChronicEffect.yBase);
        connect(ChronicEffect.y, PhOnFlux.yBase);
        connect(electrolytesFlowConstant.y, AcuteEffect.yBase);
        connect(busConnector.Artys_pH, AcuteEffect.u);
        connect(PhOnFlux.y, busConnector.CD_NH4_Outflow);
        connect(busConnector.Artys_pH, ChronicEffect.u);
        connect(busConnector.Artys_pH, PhOnFlux.u);
      end Amonium2;
    end NH4;

    package setup
      model ElectrolytesConstInputs2
        Library.Interfaces.BusConnector busConnector;
        Library.Blocks.Constant BladderVoidFlow(k = 0);
        Library.Blocks.Constant A2Pool_Log10Conc(k = 1.29916);
        Library.Blocks.Constant AldoPool_Aldo(k = 0.290854848569316);
        Library.Blocks.Constant BladderVolume_Mass(k = 629.260404013417);
        Library.Blocks.Constant Artys_pH(k = 7.38644600458198);
        Library.Blocks.Constant CD_KA_Outflow(k = 6.08968322729714e-005);
        Library.Blocks.Constant CO2Veins_cHCO3(k = 25.7071728935027);
        Library.Blocks.Constant CellH2O_Vol(k = 27335.8967957385);
        Library.Blocks.Constant ECFV_Vol(k = 15491.3023234116);
        Library.Blocks.Constant GILumenVolume_Mass(k = 959.290660950713);
        Library.Blocks.Constant GlomerulusFiltrate_GFR(k = 130.805);
        Library.Blocks.Constant KAPool_Osmoles(k = 2.10110505683432);
        Library.Blocks.Constant KAPool_conc(k = 1.3839925831359e-002);
        Library.Blocks.Constant KidneyAlpha_PT_NA(k = 1.);
        Library.Blocks.Constant KidneyFunction_Effect(k = 0.995580586980285);
        Library.Blocks.Constant Kidney_NephronCount_Total_xNormal(k = 1.);
        Library.Blocks.Constant LacPool_Mass_mEq(k = 18.2596543652006);
        Library.Blocks.Constant LacPool_Lac_mEq_per_litre(k = 1.17870363536868);
        Library.Blocks.Constant Medulla_Volume(k = 31.);
        Library.Blocks.Constant NephronANP_Log10Conc(k = 1.25866025557014);
        Library.Blocks.Constant NephronAldo_conc_in_nG_per_dl(k = 9.9383249094754);
        Library.Blocks.Constant NephroneIFP_Pressure(k = 3.98695);
        Library.Blocks.Constant VasaRecta_Outflow(k = 21.7865579572364);
        Library.Blocks.Constant liver_GlucoseToCellStorageFlow(k = 0);
        Library.Blocks.Constant skeletalMuscle_GlucoseToCellStorageFlow(k = 0);
        Library.Blocks.Constant skeletalMuscle_GlucoseToCellStorageFlow1(k = 0);
        Library.Blocks.Constant Constant14(k = 0);
        Library.Blocks.Constant Constant15(k = 0);
        Library.Blocks.Constant Constant16(k = 0);
        Library.Blocks.Constant Constant17(k = 0);
        Library.Blocks.Constant Constant18(k = 0);
        Library.Blocks.Constant Constant19(k = .12);
        Library.Blocks.Constant Constant20(k = 0);
        Library.Blocks.Constant Constant1(k = 0);
        Library.Blocks.Constant Constant2(k = 0);
        Library.Blocks.Constant Kidney_NephronCount_Filtering_xNormal(k = 1.);
        Library.Blocks.Constant Constant21(k = 0);
        Library.Blocks.Constant Constant22(k = 0);
        Library.Blocks.Constant Constant23(k = 0);
        Library.Blocks.Constant Constant24(k = 0);
        Library.Blocks.Constant Constant25(k = 0);
        Library.Blocks.Constant Constant26(k = 5.2e-002);
        Library.Blocks.Constant Constant27(k = 0);
        Library.Blocks.Constant Constant28(k = 0);
        Library.Blocks.Constant Constant29(k = 0);
        Library.Blocks.Constant Constant30(k = 0);
        Library.Blocks.Constant Constant31(k = 0);
        Library.Blocks.Constant Constant32(k = 0);
        Library.Blocks.Constant Constant33(k = 0.149511);
        Library.Blocks.Constant Constant34(k = 0);
        Library.Blocks.Constant A2Pool_Log10Conc1(k = 11.1951);
        Library.Blocks.Constant A2Pool_Log10Conc2(k = 2.5e-002);
        Library.Blocks.Constant A2Pool_Log10Conc3(k = 4.2e-002);
        Library.Blocks.Constant A2Pool_Log10Conc4(k = 14.9621);
      equation
        connect(BladderVoidFlow.y, busConnector.BladderVoidFlow);
        connect(A2Pool_Log10Conc.y, busConnector.A2Pool_Log10Conc);
        connect(AldoPool_Aldo.y, busConnector.AldoPool_Aldo);
        connect(BladderVolume_Mass.y, busConnector.BladderVolume_Mass);
        connect(Artys_pH.y, busConnector.Artys_pH);
        connect(CD_KA_Outflow.y, busConnector.CD_KA_Outflow);
        connect(CO2Veins_cHCO3.y, busConnector.CO2Veins_cHCO3);
        connect(CellH2O_Vol.y, busConnector.CellH2O_Vol);
        connect(ECFV_Vol.y, busConnector.ECFV_Vol);
        connect(GILumenVolume_Mass.y, busConnector.GILumenVolume_Mass);
        connect(GlomerulusFiltrate_GFR.y, busConnector.GlomerulusFiltrate_GFR);
        connect(KAPool_Osmoles.y, busConnector.KAPool_Osmoles);
        connect(KAPool_conc.y, busConnector.KAPool_conc_per_liter);
        connect(KidneyAlpha_PT_NA.y, busConnector.KidneyAlpha_PT_NA);
        connect(KidneyFunction_Effect.y, busConnector.KidneyFunctionEffect);
        connect(Kidney_NephronCount_Total_xNormal.y, busConnector.Kidney_NephronCount_Total_xNormal);
        connect(LacPool_Mass_mEq.y, busConnector.LacPool_Mass_mEq);
        connect(LacPool_Lac_mEq_per_litre.y, busConnector.LacPool_Lac_mEq_per_litre);
        connect(Medulla_Volume.y, busConnector.Medulla_Volume);
        connect(NephronANP_Log10Conc.y, busConnector.NephronANP_Log10Conc);
        connect(NephronAldo_conc_in_nG_per_dl.y, busConnector.NephronAldo_conc_in_nG_per_dl);
        connect(NephroneIFP_Pressure.y, busConnector.NephronIFP_Pressure);
        connect(VasaRecta_Outflow.y, busConnector.VasaRecta_Outflow);
        connect(liver_GlucoseToCellStorageFlow.y, busConnector.liver_GlucoseToCellStorageFlow);
        connect(skeletalMuscle_GlucoseToCellStorageFlow.y, busConnector.skeletalMuscle_GlucoseToCellStorageFlow);
        connect(skeletalMuscle_GlucoseToCellStorageFlow1.y, busConnector.respiratoryMuscle_GlucoseToCellStorageFlow);
        connect(Constant14.y, busConnector.IVDrip_NaRate);
        connect(Constant15.y, busConnector.Transfusion_NaRate);
        connect(Constant16.y, busConnector.SweatDuct_NaRate);
        connect(Constant17.y, busConnector.Hemorrhage_NaRate);
        connect(Constant18.y, busConnector.DialyzerActivity_Na_Flux);
        connect(Constant19.y, busConnector.DietIntakeElectrolytes_Na);
        connect(Constant20.y, busConnector.GILumenDiarrhea_NaLoss);
        connect(Constant1.y, busConnector.FurosemidePool_Furosemide_conc);
        connect(Constant2.y, busConnector.ThiazidePool_Thiazide_conc);
        connect(Kidney_NephronCount_Filtering_xNormal.y, busConnector.Kidney_NephronCount_Filtering_xNormal);
        connect(Constant21.y, busConnector.IVDrip_KRate);
        connect(Constant22.y, busConnector.Transfusion_KRate);
        connect(Constant23.y, busConnector.SweatDuct_KRate);
        connect(Constant24.y, busConnector.Hemorrhage_KRate);
        connect(Constant25.y, busConnector.DialyzerActivity_K_Flux);
        connect(Constant26.y, busConnector.DietIntakeElectrolytes_K);
        connect(Constant27.y, busConnector.GILumenDiarrhea_KLoss);
        connect(Constant28.y, busConnector.IVDrip_ClRate);
        connect(Constant29.y, busConnector.Transfusion_ClRate);
        connect(Constant30.y, busConnector.SweatDuct_ClRate);
        connect(Constant31.y, busConnector.Hemorrhage_ClRate);
        connect(Constant32.y, busConnector.DialyzerActivity_Cl_Flux);
        connect(Constant33.y, busConnector.DietIntakeElectrolytes_Cl);
        connect(Constant34.y, busConnector.GILumenVomitus_ClLoss);
        connect(A2Pool_Log10Conc1.y, busConnector.Aldo_conc_in_nG_per_dl);
        connect(A2Pool_Log10Conc2.y, busConnector.DietIntakeElectrolytes_PO4);
        connect(A2Pool_Log10Conc3.y, busConnector.DietIntakeElectrolytes_SO4);
        connect(A2Pool_Log10Conc4.y, busConnector.BloodIons_ProteinAnions);
      end ElectrolytesConstInputs2;
    end setup;

    package test
      model T2
        Electrolytes2 electrolytes(sodium(Medulla(initialSoluteMass = 20.2451)));
        setup.ElectrolytesConstInputs2 electrolytesConstInputs;
      equation
        connect(electrolytesConstInputs.busConnector, electrolytes.busConnector);
      end T2;
    end test;

    model Electrolytes2
      Sodium.Sodium2 sodium;
      Potassium.Potassium2 potassium;
      Chloride.Chloride2 chloride;
      Phosphate.Phosphate2 phosphate;
      Sulphate.Sulphate2 sulphate;
      Library.Interfaces.BusConnector busConnector;
      NH4.Amonium2 ammonia;
      ElectrolytesProperties electrolytesProperties;
    equation
      connect(sodium.busConnector, busConnector);
      connect(busConnector, potassium.busConnector);
      connect(busConnector, chloride.busConnector);
      connect(ammonia.busConnector, busConnector);
      connect(busConnector, electrolytesProperties.busConnector);
      connect(sulphate.busConnector, busConnector);
      connect(phosphate.busConnector, busConnector);
    end Electrolytes2;

    model ElectrolytesProperties
      Library.Interfaces.BusConnector busConnector;
      Library.Blocks.OsmolarityConstant OsmCell_OtherCations(k = 692);
      Library.Blocks.OsmolarityConstant CellElectrolytesMass(k = 1000);
      Modelica.Blocks.Math.Add3 Cells(k1 = 2, k2 = 2, k3 = -1);
      Library.Blocks.OsmolarityConstant OsmECFV_OtherAnions(k = 373.0);
      Modelica.Blocks.Math.Sum ECF(nin = 8);
      Modelica.Blocks.Math.Sum BloodCations(nin = 2);
      Modelica.Blocks.Math.Feedback feedback1;
      Modelica.Blocks.Math.Feedback feedback2;
      Modelica.Blocks.Math.Add3 AnFlow;
      Modelica.Blocks.Math.Add3 CatFlow;
      Modelica.Blocks.Math.Feedback CollectingDuct_NetSumCats;
      Modelica.Blocks.Math.Sum StrongAnions(nin = 5);
      Modelica.Blocks.Math.Feedback StrongAnions2;
      Modelica.Blocks.Math.Add WeakAnions;
    equation
      connect(busConnector.KCell_Mass, Cells.u1);
      connect(OsmCell_OtherCations.y, Cells.u2);
      connect(CellElectrolytesMass.y, Cells.u3);
      connect(busConnector.NaPool_mass, ECF.u[1]);
      connect(busConnector.KPool_mass, ECF.u[2]);
      connect(busConnector.ClPool_mass, ECF.u[3]);
      connect(OsmECFV_OtherAnions.y, ECF.u[8]);
      connect(busConnector.NaPool_conc_per_liter, BloodCations.u[1]);
      connect(busConnector.KPool_conc_per_liter, BloodCations.u[2]);
      connect(feedback2.y, busConnector.BloodIons_StrongAnionsLessSO4);
      connect(busConnector.BloodIons_StrongAnionsLessPO4, feedback1.y);
      connect(busConnector.PO4Pool_conc_per_liter, feedback1.u2);
      connect(busConnector.SO4Pool_conc_per_liter, feedback2.u2);
      connect(CollectingDuct_NetSumCats.y, busConnector.CollectingDuct_NetSumCats);
      connect(CatFlow.y, CollectingDuct_NetSumCats.u1);
      connect(AnFlow.y, CollectingDuct_NetSumCats.u2);
      connect(busConnector.CD_NH4_Outflow, CatFlow.u1);
      connect(busConnector.CD_PO4_Outflow, AnFlow.u2);
      connect(busConnector.CD_SO4_Outflow, AnFlow.u3);
      connect(BloodCations.y, StrongAnions2.u1);
      connect(busConnector.PO4Pool_conc_per_liter, StrongAnions.u[2]);
      connect(busConnector.SO4Pool_conc_per_liter, StrongAnions.u[3]);
      connect(busConnector.ClPool_conc_per_liter, StrongAnions.u[5]);
      connect(busConnector.PO4Pool_Osmoles, ECF.u[4]);
      connect(busConnector.SO4Pool_Osmoles, ECF.u[5]);
      connect(busConnector.LacPool_Mass_mEq, ECF.u[6]);
      connect(busConnector.LacPool_Lac_mEq_per_litre, StrongAnions.u[4]);
      connect(busConnector.CO2Veins_cHCO3, WeakAnions.u2);
      connect(WeakAnions.y, StrongAnions2.u2);
      connect(ECF.y, busConnector.OsmECFV_Electrolytes);
      connect(Cells.y, busConnector.OsmCell_Electrolytes);
      connect(busConnector.KAPool_conc_per_liter, StrongAnions.u[1]);
      connect(busConnector.CD_KA_Outflow, AnFlow.u1);
      connect(busConnector.KAPool_Osmoles, ECF.u[7]);
      connect(BloodCations.y, busConnector.BloodIons_Cations);
      connect(busConnector.CD_Na_Outflow, CatFlow.u2);
      connect(busConnector.CD_K_Outflow, CatFlow.u3);
      connect(BloodCations.y, busConnector.BloodCations);
      connect(busConnector.BloodIons_ProteinAnions, WeakAnions.u1);
      connect(StrongAnions2.y, busConnector.BloodIons_StrongAnions);
      connect(StrongAnions2.y, feedback2.u1);
      connect(StrongAnions2.y, feedback1.u1);
    end ElectrolytesProperties;
  end Electrolytes;
end QHP;

model QHP_Electrolytes_test_T2
  extends QHP.Electrolytes.test.T2;
end QHP_Electrolytes_test_T2;

model QHP_Electrolytes_test_T2_total
  extends QHP_Electrolytes_test_T2;
end QHP_Electrolytes_test_T2_total;

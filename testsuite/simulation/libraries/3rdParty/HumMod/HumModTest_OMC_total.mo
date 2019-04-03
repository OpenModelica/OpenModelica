package HumMod

package CardioVascular  "Blood and Cardio-Vascular System"

package VascularCompartments  "Blood Cardio-Vascular Distribution"
package heart  "Heart Ventricle Components"
model Systole
Physiolibrary.PressureFlow.NegativePressureFlow outflow;
Physiolibrary.Interfaces.RealInput_ contractility "heart muscle contractility [xNormal]" annotation(extent = [70, 90; 90, 110], rotation = -90);
parameter Real n_Systole "parametrization of end diastolic volume curve";
parameter Real Abasic_Systole "parametrization of end systolic volume curve";
parameter Real additionalPressure_Systolic "parametrization of end systolic volume curve";
Physiolibrary.Interfaces.RealOutput ESV(final quantity = "Volume", final unit = "ml");
Physiolibrary.Interfaces.RealInput_ externalPressure(final quantity = "Pressure", final unit = "mmHg") "pressure around ventricle";
Physiolibrary.Interfaces.RealOutput_ P(final quantity = "Pressure", final unit = "mmHg");
equation
outflow.q = 0;
P = outflow.pressure;
ESV = ((outflow.pressure + additionalPressure_Systolic - externalPressure) / (contractility * Abasic_Systole)) ^ (1 / n_Systole);
end Systole;

model VentricleVolumeAndPumping2  "Multiple PressureFlow connector with pressures from multiple inputs"
extends Physiolibrary.Interfaces.BaseModel;
extends Physiolibrary.Utilities.DynamicState;
Physiolibrary.Interfaces.RealInput_ BloodFlow(final quantity = "Flow", final unit = "ml/min") "heart cardiac output";
Physiolibrary.PressureFlow.PositivePressureFlow q_in;
parameter Real initialVolume(final quantity = "Volume", final unit = "ml");
Physiolibrary.PressureFlow.NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
Real delta(final quantity = "Flow", final unit = "ml/min");
Physiolibrary.Interfaces.RealInput_ VentricleSteadyStateVolume(final quantity = "Volume", final unit = "ml") "heart ventricle steady state volume";
parameter Real K(final unit = "1/min") = 1;
parameter Real V0(final quantity = "Volume", final unit = "ml") = 0;
parameter Real BasicCompliance(final quantity = "Compliance", final unit = "ml/mmHg");
Physiolibrary.Interfaces.RealOutput_ Volume(start = initialVolume, final quantity = "Volume", final unit = "ml");
equation
delta = (VentricleSteadyStateVolume - Volume) * K;
q_in.q + q_out.q = delta;
if STEADY then
q_in.q = BloodFlow;
else
q_in.q = if delta < 0 then BloodFlow else BloodFlow + delta;
end if;
stateValue = Volume;
changePerMin = delta;
end VentricleVolumeAndPumping2;

model Ventricle3
extends HumMod.CardioVascular.VascularCompartments.Interfaces.IVentricle;
parameter String stateName;
Physiolibrary.Blocks.Constant basicContractility(k = contractilityBasic);
HumMod.Nerves.BetaReceptorsActivityFactor betaReceptorsActivityFactor;
Modelica.Blocks.Math.Add Vol_SteadyState(k1 = 0.5, k2 = 0.5);
Diastole3 diastole(stiffnes = stiffnes, n_Diastole = n_Diastole, Abasic_Diastole = Abasic_Diastole);
Systole systole(n_Systole = n_Systole, Abasic_Systole = Abasic_Systole, additionalPressure_Systolic = additionalPressure_Systolic);
Modelica.Blocks.Math.Feedback StrokeVolume;
VentricleVolumeAndPumping2 ventricle(initialVolume = initialVol, K = K, BasicCompliance = BasicCompliance, stateName = stateName);
Modelica.Blocks.Math.Product BloodFlow;
equation
connect(basicContractility.y, betaReceptorsActivityFactor.yBase);
connect(busConnector.BetaPool_Effect, betaReceptorsActivityFactor.BetaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BetaBlocade_Effect, betaReceptorsActivityFactor.BetaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, betaReceptorsActivityFactor.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(diastole.externalPressure, busConnector.Pericardium_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Pericardium_Pressure, systole.externalPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(betaReceptorsActivityFactor.y, systole.contractility);
connect(diastole.EDV, StrokeVolume.u1);
connect(Vol_SteadyState.u2, diastole.EDV);
connect(systole.outflow, q_out);
connect(q_in, diastole.inflow);
connect(systole.ESV, Vol_SteadyState.u1);
connect(systole.ESV, StrokeVolume.u2);
connect(Vol_SteadyState.y, ventricle.VentricleSteadyStateVolume);
connect(q_in, ventricle.q_in);
connect(ventricle.q_out, q_out);
connect(StrokeVolume.y, BloodFlow.u1);
connect(BloodFlow.y, ventricle.BloodFlow);
connect(ventricle.Volume, Vol);
connect(BloodFlow.u2, busConnector.HeartVentricleRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(BloodFlow.y, CO);
connect(diastole.HR, busConnector.HeartVentricleRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Ventricle3;

model Diastole3
Physiolibrary.PressureFlow.PositivePressureFlow inflow;
Physiolibrary.Interfaces.RealInput_ externalPressure(final quantity = "Pressure", final unit = "mmHg") "pericardium pressure around ventricle";
parameter Real stiffnes "parametrization of end diastolic volume curve";
parameter Real n_Diastole "parametrization of end systolic volume curve";
parameter Real Abasic_Diastole "parametrization of end diastolic volume curve";
Physiolibrary.Interfaces.RealOutput EDV(final quantity = "Volume", final unit = "ml");
Physiolibrary.Interfaces.RealOutput_ P(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealOutput_ Stiffness;
Physiolibrary.Interfaces.RealInput_ HR(final quantity = "Frequency", final unit = "1/min") "heart rate";
Real HR_effect;
Real a;
Real b;
equation
inflow.q = 0;
P = inflow.pressure;
HR_effect = a * HR + b;
1 = a * 75 + b;
0.52 = a * 200 + b;
EDV = ((inflow.pressure - externalPressure) / (stiffnes * Abasic_Diastole)) ^ (1 / n_Diastole) * HR_effect;
Stiffness = stiffnes;
end Diastole3;
end heart;

model SystemicVeinsElacticBloodCompartment
Physiolibrary.PressureFlow.PositivePressureFlow referencePoint annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ ExternalPressure(final quantity = "Pressure", final unit = "mmHg") "external pressure around the compartment" annotation(extent = [-10, 90; 10, 110], rotation = -90);
Physiolibrary.Interfaces.RealInput_ Compliance(final quantity = "Compliance", final unit = "ml/mmHg") "elasticity of the stressed walls" annotation(extent = [50, 90; 70, 110], rotation = -90);
Modelica.Blocks.Interfaces.RealOutput Pressure(final quantity = "Pressure", final unit = "mmHg") "blod pressure in compartment";
Modelica.Blocks.Interfaces.RealOutput Vol(final quantity = "Volume", final unit = "ml") "blood volume in compartment";
Physiolibrary.Interfaces.BusConnector busConnector;
HumMod.CardioVascular.VascularCompartments.VascularElasticBloodCompartment systemicVeins(initialVol = initialSystemisVeinsVol, stateName = "SystemicVeins.Vol") "systemic veins";
Physiolibrary.Factors.CurveValue V0_A2_Effect(data = {{0.0, 1.05, 0.0}, {1.3, 1.0, -0.1}, {3.0, 0.85, 0.0}});
Physiolibrary.Utilities.ConstantFromFile const4(units = "ml", k = 1700, varName = "SystemicVeins.V0Basic", varValue = 1700.0, initType = Physiolibrary.Utilities.Init.NoInit);
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors(NEURALK = 0.333, HUMORALK = 0.5, data = {{0.0, 1.2, 0.0}, {1.0, 1.0, -0.3}, {3.0, 0.6, 0.0}});
Modelica.Blocks.Interfaces.RealOutput V0(final quantity = "Volume", final unit = "ml") "maximal zero pressure blood volume in compartment";
parameter Real initialSystemisVeinsVol(final quantity = "Volume", final unit = "ml") = 2329.57;
Modelica.Blocks.Interfaces.RealOutput NormalizedVolume(final quantity = "NormalizedVolume", final unit = "1") "maximal zero pressure blood volume in compartment";
equation
connect(V0_A2_Effect.y, systemicVeins.V0);
connect(AplhaReceptors.y, V0_A2_Effect.yBase);
connect(AplhaReceptors.yBase, const4.y);
connect(systemicVeins.referencePoint, referencePoint);
connect(systemicVeins.Vol, Vol);
connect(systemicVeins.Pressure, Pressure);
connect(systemicVeins.ExternalPressure, ExternalPressure);
connect(systemicVeins.Compliance, Compliance);
connect(busConnector.A2Pool_Log10Conc, V0_A2_Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(V0_A2_Effect.y, V0);
connect(systemicVeins.NormalizedVolume, NormalizedVolume);
end SystemicVeinsElacticBloodCompartment;

model SequesteredBlood
extends Interfaces.ISequesteredBlood;
parameter Real initialVol(final quantity = "Volume", final unit = "ml") "initial compartment blood volume";
parameter Real[:, 3] data;
Physiolibrary.PressureFlow.PressureControledCompartment pressureControledCompartment(initialVolume = initialVol);
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Add add;
equation
connect(pressureControledCompartment.Volume, curve.u);
connect(pressureControledCompartment.Volume, Vol);
connect(referencePoint, pressureControledCompartment.y);
connect(add.y, pressureControledCompartment.pressure);
connect(curve.val, add.u2);
connect(ExternalPressure, add.u1);
connect(add.y, Pressure);
end SequesteredBlood;

model VascularElasticBloodCompartment
extends Physiolibrary.Utilities.DynamicState;
extends HumMod.CardioVascular.VascularCompartments.Interfaces.IVascularElasticBloodCompartment;
Real StressedVolume(final quantity = "Volume", final unit = "ml");
Modelica.Blocks.Interfaces.RealOutput NormalizedVolume(final quantity = "NormalizedVolume", final unit = "1") "actual volume divided by standard compartement volume";
equation
StressedVolume = max(Vol - V0, 0);
Pressure = StressedVolume / Compliance + ExternalPressure;
referencePoint.pressure = Pressure;
NormalizedVolume = if initialVol == 0 then 0 else Vol / initialVol;
stateValue = Vol;
changePerMin = referencePoint.q;
end VascularElasticBloodCompartment;

model LungBloodFlow
Physiolibrary.Interfaces.RealInput_ CardiacOutput;
parameter Real BasicRLShuntPercentage(final unit = "%") = 2 "basic percentage of total blood flow not exposed to lung air";
parameter Real RightHemithorax_Pressure(final unit = "mmHg") = -4;
parameter Real LeftHemithorax_Pressure(final unit = "mmHg") = -4;
Real PressureGradientRightLeft(final unit = "mmHg") "difference between right and left hemithorax pressure";
Real Thorax_RightLungFlowFract(final unit = "1") "fraction of blood flow to right lung";
Real Thorax_LeftLungFlowFract(final unit = "1") "fraction of blood flow to left lung";
Real RightHemithorax_LungInflation(final unit = "1") "dammage effect of right hemithorax inflation";
Real LeftHemithorax_LungInflation(final unit = "1") "dammage effect of left hemithorax inflation";
Real Total(final unit = "ml/min") "cardiac output";
Real RightLeftShunt(final unit = "ml/min") "blood flow not exposed to lung air without dammage effect";
Real Alveolar(final unit = "ml/min") "blood flow exposed to lung air without dammage effect";
parameter Real[:, 3] PressureOnInflation = {{-4.0, 1.0, 0}, {4.0, 0.0, 0}};
parameter Real[:, 3] PressureGradientOnFlowDist = {{-25, 0.0, 0}, {0, 0.5, 0.03}, {25, 1.0, 0}};
Physiolibrary.Interfaces.RealOutput_ AlveolarVentilated(final unit = "ml/min");
Physiolibrary.Curves.Curve Thorax_PressureGradientOnFlowDist(x = PressureGradientOnFlowDist[:, 1], y = PressureGradientOnFlowDist[:, 2], slope = PressureGradientOnFlowDist[:, 3]);
Physiolibrary.Curves.Curve Thorax_PressureOnInflationR(x = PressureOnInflation[:, 1], y = PressureOnInflation[:, 2], slope = PressureOnInflation[:, 3]);
Physiolibrary.Curves.Curve Thorax_PressureOnInflationL(x = PressureOnInflation[:, 1], y = PressureOnInflation[:, 2], slope = PressureOnInflation[:, 3]);
equation
PressureGradientRightLeft = RightHemithorax_Pressure - LeftHemithorax_Pressure;
Thorax_PressureGradientOnFlowDist.u = PressureGradientRightLeft;
Thorax_LeftLungFlowFract = Thorax_PressureGradientOnFlowDist.val;
Thorax_RightLungFlowFract = 1.0 - Thorax_LeftLungFlowFract;
Thorax_PressureOnInflationR.u = RightHemithorax_Pressure;
RightHemithorax_LungInflation = Thorax_PressureOnInflationR.val;
Thorax_PressureOnInflationL.u = LeftHemithorax_Pressure;
LeftHemithorax_LungInflation = Thorax_PressureOnInflationL.val;
Total = CardiacOutput;
RightLeftShunt = BasicRLShuntPercentage / 100.0 * Total;
Alveolar = Total - RightLeftShunt;
AlveolarVentilated = Alveolar * (Thorax_RightLungFlowFract * RightHemithorax_LungInflation + Thorax_LeftLungFlowFract * LeftHemithorax_LungInflation);
end LungBloodFlow;

package Interfaces  "Abstract Interfaces"
partial model IVascularElasticBloodCompartment
Physiolibrary.PressureFlow.PositivePressureFlow referencePoint annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ V0(final quantity = "Volume", final unit = "ml") "maximal nonstressed volume" annotation(extent = [-70, 90; -50, 110], rotation = -90);
Physiolibrary.Interfaces.RealInput_ ExternalPressure(final quantity = "Pressure", final unit = "mmHg") "external pressure around the compartment" annotation(extent = [-10, 90; 10, 110], rotation = -90);
Physiolibrary.Interfaces.RealInput_ Compliance(final quantity = "Compliance", final unit = "ml/mmHg") "elasticity of the stressed walls" annotation(extent = [50, 90; 70, 110], rotation = -90);
Modelica.Blocks.Interfaces.RealOutput Pressure(final quantity = "Pressure", final unit = "mmHg") "blod pressure in compartment";
parameter Real initialVol = 0;
Modelica.Blocks.Interfaces.RealOutput Vol(start = initialVol, final quantity = "Volume", final unit = "ml") "blood volume in compartment";
end IVascularElasticBloodCompartment;

model ISequesteredBlood
Physiolibrary.PressureFlow.PositivePressureFlow referencePoint annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ ExternalPressure(final quantity = "Pressure", final unit = "mmHg") "external pressure around the compartment" annotation(extent = [-100, 90; -80, 110], rotation = -90);
Modelica.Blocks.Interfaces.RealOutput Pressure(final quantity = "Pressure", final unit = "mmHg") "blod pressure in compartment";
Modelica.Blocks.Interfaces.RealOutput Vol(final quantity = "Volume", final unit = "ml") "blood volume in compartment";
end ISequesteredBlood;

partial model IVentricle
parameter Real initialVol(final quantity = "Volume", final unit = "ml") = 90;
parameter Real initialESV(final quantity = "Volume", final unit = "ml") = 50;
parameter Real stiffnes = 1 "parametrization of end diastolic volume curve";
parameter Real n_Diastole = 2 "parametrization of end systolic volume curve";
parameter Real n_Systole = 0.5 "parametrization of end diastolic volume curve";
parameter Real Abasic_Diastole = 0.00051 "parametrization of end diastolic volume curve";
parameter Real Abasic_Systole = 17.39 "parametrization of end systolic volume curve";
parameter Real additionalPressure_Systolic = 24 "parametrization of end systolic volume curve";
parameter Real contractilityBasic = 1 "parametrization of end systolic volume curve";
parameter Real K(final quantity = "TimeCoefficient", final unit = "1/min") = 1 "time adaptation coeficient of average ventricle blood volume";
parameter Real BasicCompliance(final quantity = "Compliance", final unit = "ml/mmHg") = 1;
parameter Real MaxContractionCompliance(final quantity = "Compliance", final unit = "ml/mmHg") = 1;
parameter Real Cond1 = 1;
parameter Real Cond2 = 1;
Physiolibrary.PressureFlow.PositivePressureFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.PressureFlow.NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ Vol(final quantity = "Volume", final unit = "ml");
Physiolibrary.Interfaces.RealOutput_ CO(final quantity = "Flow", final unit = "ml/min");
end IVentricle;
end Interfaces;

model PulmonaryCirculation
extends Physiolibrary.PressureFlow.ResistorBase;
VascularElasticBloodCompartment pulmCapys(initialVol = 200.141, stateName = "PulmCapys.Vol") "pulmonary capilaries";
VascularElasticBloodCompartment pulmArty(initialVol = 200.488, stateName = "PulmArty.Vol");
VascularElasticBloodCompartment pulmVeins(initialVol = 210.463, stateName = "PulmVeins.Vol") "pulmonary veins";
Physiolibrary.PressureFlow.ResistorWithCondParam pulmArtyConductance(cond = 1350);
Physiolibrary.Blocks.VolumeConstant ArtysV0(k = 110);
Physiolibrary.Blocks.ComplianceConstant ArtysCompliance(k = 5.3);
Physiolibrary.Blocks.Constant CapysV0(k = 140);
Physiolibrary.Blocks.ComplianceConstant CapysCompliance(k = 4.6);
Physiolibrary.PressureFlow.ResistorWithCondParam pulmCapysConductance(cond = 1800);
Physiolibrary.Blocks.Constant VeinsV0(k = 150);
Physiolibrary.Blocks.ComplianceConstant VeinsCompliance(k = 6);
Physiolibrary.PressureFlow.ResistorWithCondParam pulmVeinsConductance(cond = 5400);
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
LungBloodFlow lungBloodFlow;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
Modelica.Blocks.Math.Sum sum1(nin = 3);
Modelica.Blocks.Math.Sum sum2(nin = 2);
equation
connect(pulmArty.referencePoint, pulmArtyConductance.q_in);
connect(pulmArty.ExternalPressure, busConnector.Thorax_AvePressure);
connect(pulmCapys.ExternalPressure, busConnector.Thorax_AvePressure);
connect(pulmVeins.ExternalPressure, busConnector.Thorax_AvePressure);
connect(pulmArty.V0, ArtysV0.y);
connect(pulmArty.Compliance, ArtysCompliance.y);
connect(CapysV0.y, pulmCapys.V0);
connect(CapysCompliance.y, pulmCapys.Compliance);
connect(pulmCapys.referencePoint, pulmCapysConductance.q_in);
connect(pulmCapysConductance.q_out, pulmVeins.referencePoint);
connect(pulmVeins.V0, VeinsV0.y);
connect(VeinsCompliance.y, pulmVeins.Compliance);
connect(pulmVeins.referencePoint, pulmVeinsConductance.q_in);
connect(lungBloodFlow.AlveolarVentilated, busConnector.AlveolarVentilated_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(pulmArtyConductance.q_out, flowMeasure.q_in);
connect(flowMeasure.q_out, pulmCapys.referencePoint);
connect(flowMeasure.actualFlow, lungBloodFlow.CardiacOutput);
connect(ArtysV0.y, sum1.u[1]);
connect(CapysV0.y, sum1.u[2]);
connect(VeinsV0.y, sum1.u[3]);
connect(pulmCapys.Vol, sum2.u[1]);
connect(pulmVeins.Vol, sum2.u[2]);
connect(pulmCapys.Pressure, busConnector.PulmCapys_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, -6}, {6, -6}}));
connect(sum1.y, busConnector.PulmonaryCirculation_V0) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(pulmArty.Vol, busConnector.PulmonaryCirculation_DeoxygenatedBloodVolume) annotation(Text(string = "%second", index = 1, extent = {{6, -16}, {6, -16}}));
connect(busConnector.PulmonaryCirculation_OxygenatedBloodVolume, sum2.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(q_in, pulmArty.referencePoint);
connect(pulmVeinsConductance.q_out, q_out);
end PulmonaryCirculation;

model Heart
VascularElasticBloodCompartment RightAtrium(initialVol = 51.6454, stateName = "RightAtrium.Vol") "right atrium";
Physiolibrary.Blocks.ComplianceConstant RightAtriumCompliance(k = 12.5);
Physiolibrary.Blocks.VolumeConstant RightAtriumV0(k = 0);
heart.Ventricle3 rightVentricle(stiffnes = 1.0, n_Diastole = 2.0, n_Systole = 0.5, Abasic_Diastole = 0.00026, Abasic_Systole = 3.53, contractilityBasic = 1, K = 1, additionalPressure_Systolic = 9, BasicCompliance = 29.2, Cond1 = 60000000, Cond2 = 60000000, MaxContractionCompliance = 2, initialVol = 87.5, stateName = "RightVentricle.Vol");
VascularElasticBloodCompartment LeftAtrium(initialVol = 50.5035, stateName = "LeftAtrium.Vol") "left atrium";
Physiolibrary.Blocks.VolumeConstant LeftAtriumV0(k = 0);
Physiolibrary.Blocks.ComplianceConstant LeftAtriumCompliance(k = 6.25);
heart.Ventricle3 leftVentricle(stiffnes = 1, n_Diastole = 2, n_Systole = 0.5, Abasic_Diastole = 0.00051, Abasic_Systole = 17.39, additionalPressure_Systolic = 24, contractilityBasic = 1, K = 1, BasicCompliance = 14.6, MaxContractionCompliance = 0.4, Cond1 = 60000000, Cond2 = 60000000, initialVol = 87.5, stateName = "LeftVentricle.Vol");
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
Physiolibrary.PressureFlow.PositivePressureFlow rightAtrium "blood inflow to right atrium";
Physiolibrary.PressureFlow.NegativePressureFlow fromRightVentricle "blood outflow to pulmonary circulation";
Physiolibrary.PressureFlow.NegativePressureFlow fromLeftVentricle "blood outflow to aorta";
Physiolibrary.PressureFlow.PositivePressureFlow leftAtrium "blood inflow to left atrium";
Modelica.Blocks.Math.Sum sum1(nin = 2);
Modelica.Blocks.Math.Sum sum3(nin = 2);
Modelica.Blocks.Math.Sum sum2(nin = 2);
Modelica.Blocks.Math.Feedback rightAtrium_TMP;
Modelica.Blocks.Math.Feedback leftAtrium_TMP;
Nerves.SA_Node SA_node;
Hormones.ANP atriopeptin;
equation
connect(RightAtrium.V0, RightAtriumV0.y);
connect(RightAtrium.Compliance, RightAtriumCompliance.y);
connect(RightAtrium.referencePoint, rightVentricle.q_in);
connect(busConnector.Pericardium_Pressure, RightAtrium.ExternalPressure) annotation(Text(string = "%first", index = -1, extent = {{110, 10}, {110, 10}}));
connect(busConnector, rightVentricle.busConnector);
connect(LeftAtrium.V0, LeftAtriumV0.y);
connect(LeftAtrium.Compliance, LeftAtriumCompliance.y);
connect(LeftAtrium.referencePoint, leftVentricle.q_in);
connect(busConnector, leftVentricle.busConnector);
connect(busConnector.Pericardium_Pressure, LeftAtrium.ExternalPressure);
connect(rightAtrium, RightAtrium.referencePoint);
connect(rightVentricle.q_out, fromRightVentricle);
connect(leftVentricle.q_out, fromLeftVentricle);
connect(LeftAtrium.referencePoint, leftAtrium);
connect(busConnector.CardiacOutput, leftVentricle.CO) annotation(Text(string = "%first", index = -1, extent = {{-6, -10}, {-6, -10}}));
connect(RightAtrium.Pressure, busConnector.RightAtrium_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, -5}, {6, -5}}));
connect(RightAtriumV0.y, sum1.u[1]);
connect(LeftAtriumV0.y, sum1.u[2]);
connect(RightAtrium.Vol, sum3.u[1]);
connect(rightVentricle.Vol, sum3.u[2]);
connect(LeftAtrium.Vol, sum2.u[1]);
connect(leftVentricle.Vol, sum2.u[2]);
connect(LeftAtrium.Pressure, busConnector.LeftAtrium_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(sum3.y, busConnector.Heart_DeoxygenatedBloodVolume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Heart_OxygenatedBloodVolume, sum2.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(sum1.y, busConnector.Heart_V0) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(RightAtrium.Pressure, rightAtrium_TMP.u1);
connect(rightAtrium_TMP.u2, busConnector.Pericardium_Pressure);
connect(LeftAtrium.Pressure, leftAtrium_TMP.u1);
connect(busConnector.Pericardium_Pressure, leftAtrium_TMP.u2);
connect(rightAtrium_TMP.y, busConnector.rightAtrium_TMP);
connect(leftAtrium_TMP.y, busConnector.leftAtrium_TMP) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(SA_node.Rate, busConnector.HeartVentricleRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.BetaPool_Effect, SA_node.BetaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BetaBlocade_Effect, SA_node.BetaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.VagusNerve_NA_Hz, SA_node.VagusNerve_NA_Hz) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, SA_node.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector, atriopeptin.busConnector);
end Heart;

model SystemicCirculationFullDynamic
extends Physiolibrary.PressureFlow.ResistorBase2;
VascularElasticBloodCompartment systemicArtys(initialVol = 1000.36, stateName = "SystemicArtys.Vol");
Physiolibrary.Blocks.Constant V0_artys(k = 850);
Physiolibrary.Blocks.ComplianceConstant SystemicVeinsCompliance(k = 88.59999999999999);
OrganFlow.PeripheralFlow peripheral;
Physiolibrary.PressureFlow.InputPump volumeCorrections;
OrganFlow.SystemicVeins veins(BaseConductance = 856) "scaled to coronary vessels reorganisation";
SystemicVeinsElacticBloodCompartment systemicVeinsElacticBloodCompartment;
Physiolibrary.Blocks.PressureConstant SystemicArtysExternalPressure(k = 0);
Physiolibrary.Blocks.PressureConstant SystemicVeinsExternalPressure(k = 0);
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
Physiolibrary.Blocks.ComplianceConstant SystemicArtysCompliance(k = 1.55);
OrganFlow.CollapsingVeins collapsedVeins;
Physiolibrary.PressureFlow.GravityHydrostaticDifference gravityHydrostaticDifference;
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure;
Modelica.Blocks.Math.Gain G(k = 9.81);
OrganFlow.LeftHeart leftCororaryCirculation(BasicLargeVeselsConductance = 50 * 0.9367710946995053, BasicSmallVeselsConductance = 2.2 * 0.9367710946995053) "scaled to normal pressure gradient 94 mmHg";
OrganFlow.RightHeart rightCororaryCirculation(BasicLargeVeselsConductance = 10 * 0.9367710946995053, BasicSmallVeselsConductance = 0.4 * 0.9367710946995053) "scaled to normal pressure gradient 94 mmHg";
OrganFlow.SplanchnicCirculation splanchnicCirculation;
Physiolibrary.PressureFlow.ResistorWithCondParam legsArtys(cond = 40);
Physiolibrary.Blocks.PressureConstant const8(k = 0);
Physiolibrary.PressureFlow.GravityHydrostaticDifference hydrostaticDifference;
SequesteredBlood sequesteredBlood(data = {{0, 0, 10 ^ (-10)}, {50, 97, 1.0}, {200, 150, 0.5}}, initialVol = 50.0044, pressureControledCompartment(stateName = "BVSeqArtys.Vol"));
SequesteredBlood sequesteredBlood1(data = {{0, -100, 2.0}, {150, 11, 0.11}, {600, 50, 0.15}}, initialVol = 120.691, pressureControledCompartment(stateName = "BVSeqVeins.Vol"));
Physiolibrary.PressureFlow.ResistorWithCondParam legsVeins(cond = 100);
Physiolibrary.PressureFlow.GravityHydrostaticDifferenceWithPumpEffect hydrostaticDifference1;
Physiolibrary.Blocks.PressureConstant const12(k = 0);
equation
connect(systemicArtys.Compliance, SystemicArtysCompliance.y);
connect(systemicArtys.V0, V0_artys.y);
connect(busConnector, peripheral.busConnector);
connect(veins.busConnector, busConnector);
connect(SystemicVeinsCompliance.y, systemicVeinsElacticBloodCompartment.Compliance);
connect(busConnector, systemicVeinsElacticBloodCompartment.busConnector);
connect(systemicVeinsElacticBloodCompartment.referencePoint, volumeCorrections.q_out);
connect(systemicArtys.ExternalPressure, SystemicArtysExternalPressure.y);
connect(systemicVeinsElacticBloodCompartment.ExternalPressure, SystemicVeinsExternalPressure.y);
connect(busConnector.BloodVolume_change, volumeCorrections.desiredFlow);
connect(systemicArtys.Compliance, SystemicArtysCompliance.y);
connect(collapsedVeins.ExternalPressure, busConnector.Thorax_AvePressure);
connect(pressureMeasure.actualPressure, busConnector.CarotidSinus_Pressure);
connect(gravityHydrostaticDifference.height, busConnector.CarotidSinusHeight);
connect(gravityHydrostaticDifference.q_down, systemicArtys.referencePoint);
connect(systemicArtys.Pressure, busConnector.SystemicArtys_Pressure) annotation(Text(string = "%second", index = 1, extent = {{3, -3}, {3, -3}}));
connect(gravityHydrostaticDifference.q_up, pressureMeasure.q_in);
connect(pressureMeasure.actualPressure, busConnector.CarotidSinusArteryPressure);
connect(systemicVeinsElacticBloodCompartment.Pressure, busConnector.SystemicVeins_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(systemicVeinsElacticBloodCompartment.V0, busConnector.SystemicVeins_V0);
connect(V0_artys.y, busConnector.SystemicArtys_V0);
connect(q_in, systemicArtys.referencePoint);
connect(collapsedVeins.q_out, q_out);
connect(busConnector.Gravity_Gz, G.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(G.y, gravityHydrostaticDifference.G);
connect(rightCororaryCirculation.busConnector, busConnector);
connect(leftCororaryCirculation.busConnector, busConnector);
connect(leftCororaryCirculation.BloodFlow, busConnector.leftHeart_BloodFlow);
connect(rightCororaryCirculation.BloodFlow, busConnector.rightHeart_BloodFlow);
connect(leftCororaryCirculation.BloodFlow, busConnector.LeftHeart_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(rightCororaryCirculation.BloodFlow, busConnector.RightHeart_BloodFlow);
connect(splanchnicCirculation.busConnector, busConnector);
connect(splanchnicCirculation.q_in, systemicArtys.referencePoint);
connect(splanchnicCirculation.q_out, systemicVeinsElacticBloodCompartment.referencePoint);
connect(peripheral.q_in, systemicArtys.referencePoint);
connect(peripheral.q_out, systemicVeinsElacticBloodCompartment.referencePoint);
connect(rightCororaryCirculation.q_out, q_out);
connect(leftCororaryCirculation.q_out, q_out);
connect(leftCororaryCirculation.q_in, q_in);
connect(systemicVeinsElacticBloodCompartment.referencePoint, veins.q_in);
connect(veins.q_out, collapsedVeins.q_in);
connect(rightCororaryCirculation.q_in, q_in);
connect(legsArtys.q_in, sequesteredBlood.referencePoint);
connect(sequesteredBlood.ExternalPressure, const8.y);
connect(legsArtys.q_out, hydrostaticDifference.q_down);
connect(hydrostaticDifference.q_up, systemicArtys.referencePoint);
connect(sequesteredBlood1.ExternalPressure, const12.y);
connect(sequesteredBlood1.referencePoint, legsVeins.q_in);
connect(legsVeins.q_out, hydrostaticDifference1.q_down);
connect(hydrostaticDifference1.q_up, systemicVeinsElacticBloodCompartment.referencePoint);
connect(hydrostaticDifference1.height, busConnector.LowerTorsoVeinHeight) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(hydrostaticDifference1.pumpEffect, busConnector.Exercise_MusclePump_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(hydrostaticDifference.height, busConnector.LowerTorsoArtyHeight);
connect(sequesteredBlood1.Vol, busConnector.LegVeins_DeoxygenatedBloodVolume);
connect(sequesteredBlood.Vol, busConnector.LegArtys_OxygenatedBloodVolume);
connect(G.y, hydrostaticDifference1.G);
connect(G.y, hydrostaticDifference.G);
connect(systemicArtys.Vol, busConnector.SystemicArtys_OxygenatedBloodVolume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(systemicVeinsElacticBloodCompartment.Vol, busConnector.SystemicVeins_DeoxygenatedBloodVolume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end SystemicCirculationFullDynamic;
end VascularCompartments;

package OrganFlow  "Tissue vessels hydraulic conductance (=1/resistance)"
package ConductanceFactors  "Multiplication factors on conductance (=1/resistance)"
model HeartInfraction
extends Physiolibrary.Interfaces.BaseFactorIcon;
parameter Real DamagedArea_percent = 0;
Physiolibrary.Blocks.Constant Constant0(k = DamagedArea_percent);
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.Blocks.Constant Constant2(k = 100);
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Math.Product product;
equation
connect(product.y, y);
connect(product.u1, yBase);
connect(feedback.y, product.u2);
connect(Constant0.y, division.u1);
connect(Constant2.y, division.u2);
connect(Constant1.y, feedback.u1);
connect(division.y, feedback.u2);
end HeartInfraction;

model MetabolicVasolidation2
extends Physiolibrary.Interfaces.BaseFactorIcon5;
Physiolibrary.Interfaces.RealInput_ O2Need;
parameter Real[:, 3] data = {{50, 1.0, 0}, {1000, 3.5, 0.003}, {3000, 5.5, 0}};
parameter Real OnTau = 0.2;
parameter Real OffTau = 1;
parameter Real initialEffectValue = 1;
parameter String stateName;
Physiolibrary.Curves.Curve SteadyState(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Physiolibrary.Blocks.Integrator effect(y_start = initialEffectValue, k = 1 / Physiolibrary.SecPerMin, stateName = stateName);
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Math.Product product;
Modelica.Blocks.Math.Product product1;
Modelica.Blocks.Logical.Switch switch1(u2(start = false));
Modelica.Blocks.Logical.GreaterThreshold greaterThreshold;
Physiolibrary.Blocks.Inv OnK;
Physiolibrary.Blocks.Inv OffK;
Physiolibrary.Blocks.Constant Constant0(k = OnTau);
Physiolibrary.Blocks.Constant Constant1(k = OffTau);
equation
connect(SteadyState.val, feedback.u1);
connect(effect.y, feedback.u2);
connect(SteadyState.u, O2Need);
connect(product.u2, effect.y);
connect(product.u1, yBase);
connect(product.y, y);
connect(product1.y, effect.u);
connect(product1.u1, feedback.y);
connect(switch1.y, product1.u2);
connect(greaterThreshold.u, feedback.y);
connect(greaterThreshold.y, switch1.u2);
connect(OnK.y, switch1.u1);
connect(OffK.y, switch1.u3);
connect(Constant1.y, OffK.u);
connect(Constant0.y, OnK.u);
end MetabolicVasolidation2;
end ConductanceFactors;

model CollapsingVeins
extends Physiolibrary.PressureFlow.Resistor;
Physiolibrary.Interfaces.RealInput_ ExternalPressure;
parameter Real PR1LL(final quantity = "Pressure", final unit = "mmHg") = 0 "start-collapsing sucking pressure, when external pressure is zero";
equation
q_in.pressure = if q_out.pressure > PR1LL + ExternalPressure then q_out.pressure else PR1LL + ExternalPressure;
end CollapsingVeins;

partial model Base
extends Physiolibrary.PressureFlow.ResistorBase;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
Physiolibrary.Interfaces.RealOutput_ BloodFlow;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
equation
connect(q_in, flowMeasure.q_in);
connect(flowMeasure.actualFlow, BloodFlow);
end Base;

partial model BaseBadDirection
extends Physiolibrary.PressureFlow.ResistorBase2;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
Physiolibrary.Interfaces.RealOutput_ BloodFlow(start = 1000);
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
equation
connect(flowMeasure.actualFlow, BloodFlow);
connect(flowMeasure.q_in, q_in);
end BaseBadDirection;

model SystemicVeins
extends Physiolibrary.PressureFlow.ResistorBase2;
Physiolibrary.PressureFlow.ResistorWithCond systemicVeinsConductance;
Physiolibrary.Factors.SimpleMultiply ViscosityEffect;
Physiolibrary.Factors.SimpleMultiply ExerciseEffect;
Physiolibrary.Factors.SimpleMultiply CollapseEffect;
Physiolibrary.Blocks.CondConstant const12(k = BaseConductance);
parameter Real BaseConductance(final quantity = "Conductance", final unit = "ml/(min.mmHg)") = 692;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
Physiolibrary.Interfaces.RealOutput_ BloodFlow;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
equation
connect(systemicVeinsConductance.cond, ViscosityEffect.y);
connect(ViscosityEffect.yBase, ExerciseEffect.y);
connect(ExerciseEffect.yBase, CollapseEffect.y);
connect(busConnector.Viscosity_ConductanceEffect, ViscosityEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Exercise_MusclePump_Effect, ExerciseEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BloodVol_CollapsedEffect, CollapseEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(const12.y, CollapseEffect.yBase);
connect(flowMeasure.actualFlow, BloodFlow);
connect(flowMeasure.q_in, q_in);
connect(flowMeasure.q_out, systemicVeinsConductance.q_in);
connect(systemicVeinsConductance.q_out, q_out);
end SystemicVeins;

model GITract
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Factors.CurveValue ADHEffect(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Blocks.CondConstant BasicConductance(k = 11.2);
Physiolibrary.Factors.SimpleMultiply Anesthesia;
Physiolibrary.Factors.SimpleMultiply Viscosity;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature(Tau = 30, data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, stateName = "GITract-Vasculature.Effect");
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.3}, {5.0, 0.1, 0}});
Physiolibrary.PressureFlow.ResistorWithCond GITract;
Physiolibrary.Factors.CurveValue PO2OnConductance(data = {{10, 2.0, 0}, {30, 1.0, 0}});
equation
connect(Vasculature.y, PO2OnConductance.yBase);
connect(Viscosity.y, Anesthesia.yBase);
connect(Vasculature.yBase, Anesthesia.y);
connect(ADHEffect.y, GITract.cond);
connect(PO2OnConductance.y, A2Effect.yBase);
connect(BasicConductance.y, Viscosity.yBase);
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GITract_PO2, PO2OnConductance.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GITract_Function_Failed, Vasculature.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GITract_PO2, Vasculature.u);
connect(busConnector.Anesthesia_VascularConductance, Anesthesia.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Viscosity_ConductanceEffect, Viscosity.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AplhaReceptors.yBase, A2Effect.y);
connect(AplhaReceptors.y, ADHEffect.yBase);
connect(GITract.q_in, flowMeasure.q_out);
connect(GITract.q_out, q_out);
end GITract;

model Bone
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.CurveValue A2Effect_Bone(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Factors.CurveValue ADHEffect_Bone(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Blocks.CondConstant BasicConductance(k = 3.62859) "scaled to new coronary circulation";
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors_Bone(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.3}, {5.0, 0.1, 0}});
Physiolibrary.Factors.SimpleMultiply Viscosity_Bone;
Physiolibrary.Factors.SimpleMultiply Anesthesia_Bone;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_Bone(data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, Tau = 30, stateName = "Bone-Vasculature.Effect");
Physiolibrary.PressureFlow.ResistorWithCond bone;
equation
connect(Anesthesia_Bone.yBase, Viscosity_Bone.y);
connect(Anesthesia_Bone.y, Vasculature_Bone.yBase);
connect(Vasculature_Bone.y, A2Effect_Bone.yBase);
connect(BasicConductance.y, Viscosity_Bone.yBase);
connect(busConnector.Viscosity_ConductanceEffect, Viscosity_Bone.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Anesthesia_VascularConductance, Anesthesia_Bone.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Bone_Function_Failed, Vasculature_Bone.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Bone_PO2, Vasculature_Bone.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect_Bone.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_Bone.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_Bone.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_Bone.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect_Bone.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(A2Effect_Bone.y, ADHEffect_Bone.yBase);
connect(ADHEffect_Bone.y, AplhaReceptors_Bone.yBase);
connect(AplhaReceptors_Bone.y, bone.cond);
connect(flowMeasure.q_out, bone.q_in);
connect(bone.q_out, q_out);
end Bone;

model Brain
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_Brain(Tau = 30, data = {{27, 1.2, 0}, {37, 1.0, -0.03}, {47, 0.8, 0}}, stateName = "Brain-Vasculature.Effect");
Physiolibrary.Factors.SimpleMultiply Viscosity_Brain;
Physiolibrary.Factors.CurveValue PO2OnTension(data = {{22, 0.0, 0}, {36, 1.0, 0.02}, {60, 1.2, 0}});
Physiolibrary.Factors.CurveValue PCO2OnTension(data = {{20, 1.8, 0}, {45, 1.0, -0.05}, {75, 0.0, 0}});
Physiolibrary.Factors.CurveValue TensionEffect(data = {{0.0, 2.2, 0}, {1.0, 1.0, -0.5}, {2.0, 0.6, 0}});
Physiolibrary.PressureFlow.ResistorWithCond brain;
Physiolibrary.Blocks.CondConstant BasicConductance(k = 9.1);
equation
connect(Viscosity_Brain.y, Vasculature_Brain.yBase);
connect(BasicConductance.y, Viscosity_Brain.yBase);
connect(PO2OnTension.y, PCO2OnTension.yBase);
connect(Vasculature_Brain.y, TensionEffect.yBase);
connect(TensionEffect.y, brain.cond);
connect(TensionEffect.u, PCO2OnTension.y);
connect(PO2OnTension.u, busConnector.Brain_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PCO2OnTension.u, busConnector.Brain_PCO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Vasculature_Brain.Failed, busConnector.Brain_Function_Failed) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PO2OnTension.yBase, busConnector.Anesthesia_VascularConductance) annotation(Text(string = "%second", index = 1, extent = {{6, 13}, {6, 13}}));
connect(Vasculature_Brain.u, busConnector.Brain_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Viscosity_Brain.u, busConnector.Viscosity_ConductanceEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.q_out, brain.q_in);
connect(brain.q_out, q_out);
end Brain;

model Fat
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.CurveValue A2Effect_Fat(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Factors.CurveValue ADHEffect_Fat(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.PressureFlow.ResistorWithCond fat;
Physiolibrary.Blocks.CondConstant BasicConductance(k = 2.7);
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors_Fat(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.3}, {5.0, 0.1, 0}});
Physiolibrary.Factors.SimpleMultiply Viscosity_Fat;
Physiolibrary.Factors.SimpleMultiply Anesthesia_Fat;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_Fat(data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, Tau = 30, stateName = "Fat-Vasculature.Effect");
equation
connect(Anesthesia_Fat.yBase, Viscosity_Fat.y);
connect(Anesthesia_Fat.y, Vasculature_Fat.yBase);
connect(Vasculature_Fat.y, A2Effect_Fat.yBase);
connect(Viscosity_Fat.yBase, BasicConductance.y);
connect(fat.cond, ADHEffect_Fat.y);
connect(busConnector.Viscosity_ConductanceEffect, Viscosity_Fat.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Anesthesia_VascularConductance, Anesthesia_Fat.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Fat_Function_Failed, Vasculature_Fat.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Fat_PO2, Vasculature_Fat.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect_Fat.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_Fat.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_Fat.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_Fat.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect_Fat.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AplhaReceptors_Fat.yBase, A2Effect_Fat.y);
connect(AplhaReceptors_Fat.y, ADHEffect_Fat.yBase);
connect(flowMeasure.q_out, fat.q_in);
connect(fat.q_out, q_out);
end Fat;

model Kidney
extends HumMod.CardioVascular.OrganFlow.Base;
Physiolibrary.Factors.SimpleMultiply NephronCountEffect_AfferentArtery;
Physiolibrary.Blocks.CondConstant Afferent_BasicConductance(k = 34);
VariableResistorWithMyogenicResponse AfferentArtery(PressureChangeOnMyogenicCondEffect = {{-20.0, 1.2, 0.0}, {0.0, 1.0, -0.02}, {20.0, 0.8, 0.0}}, pressureChange(start = 0));
Physiolibrary.Factors.CurveValue A2Effect2(data = {{0.0, 1.2, 0.0}, {1.3, 1.0, -0.4}, {3.0, 0.6, 0.0}});
Physiolibrary.Blocks.CondConstant Efferent_BasicConductance(k = 23);
Physiolibrary.Factors.SimpleMultiply NephronCountEffect_KidneyEfferentArtery;
Physiolibrary.PressureFlow.ResistorWithCond EfferentArtery;
Physiolibrary.PressureFlow.ResistorWithCondParam ArcuateArtery(cond = 600);
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors_KidneyAfferentArtery(data = {{1.5, 1.0, 0.0}, {7.0, 0.9, 0.0}});
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors_KidneyEfferentArtery(data = {{1.5, 1.0, 0.0}, {7.0, 0.9, 0.0}});
Physiolibrary.Factors.SimpleMultiply Anesthesia_KidneyEfferentArtery;
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure;
Modelica.Blocks.Math.Product KidneyPlasmaFlow;
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure1;
Modelica.Blocks.Math.Gain IFP(k = 0.042);
Physiolibrary.Factors.DelayedToSpline TGFEffect(data = {{0.0, 1.2, 0.0}, {1.3, 1.0, -0.4}, {3.0, 0.6, 0.0}}, Tau = 1, initialValue = 1.01309, adaptationSignalName = "TGF-Vascular.Signal") "Macula Densa TGF vascular signal delay and effect to afferent arteriole";
Physiolibrary.Factors.CurveValue FurosemideEffect(data = {{0.0, 1.0, 0.0}, {1.3, 0.2, 0.0}}) "furosemide outflow on Macula Densa Na sensibility";
Physiolibrary.Factors.CurveValue NaEffect_MaculaDensa(data = {{0, 0.0, 0.0}, {48, 1.0, 0.03}, {100, 3.0, 0.0}});
Physiolibrary.Factors.CurveValue ANP_Effect(data = {{0.0, 1.2, 0.0}, {1.3, 1.0, -0.3}, {2.7, 0.8, 0.0}});
Physiolibrary.Factors.CurveValue A2Effect3(data = {{0.0, 0.0, 0.0}, {0.2, 0.6, 0.05}, {1.3, 1.0, 0.1}, {3.0, 8.0, 0.0}});
Physiolibrary.Blocks.Constant MedulaDensa_BaseTGFSignal(k = 1);
VasaRecta vasaRecta;
equation
connect(Afferent_BasicConductance.y, NephronCountEffect_AfferentArtery.yBase);
connect(busConnector.Kidney_NephronCount_Total_xNormal, NephronCountEffect_AfferentArtery.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_KidneyAfferentArtery.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_KidneyAfferentArtery.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_KidneyAfferentArtery.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_KidneyEfferentArtery.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_KidneyEfferentArtery.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_KidneyEfferentArtery.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Kidney_NephronCount_Total_xNormal, NephronCountEffect_KidneyEfferentArtery.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Anesthesia_VascularConductance, Anesthesia_KidneyEfferentArtery.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Efferent_BasicConductance.y, NephronCountEffect_KidneyEfferentArtery.yBase);
connect(A2Effect2.y, AplhaReceptors_KidneyEfferentArtery.yBase);
connect(NephronCountEffect_KidneyEfferentArtery.y, Anesthesia_KidneyEfferentArtery.yBase);
connect(Anesthesia_KidneyEfferentArtery.y, A2Effect2.yBase);
connect(AplhaReceptors_KidneyEfferentArtery.y, EfferentArtery.cond);
connect(AplhaReceptors_KidneyAfferentArtery.y, AfferentArtery.cond);
connect(pressureMeasure.q_in, AfferentArtery.q_out);
connect(pressureMeasure.actualPressure, busConnector.GlomerulusBloodPressure) annotation(Text(string = "%second", index = 1, extent = {{6, -3}, {6, -3}}));
connect(busConnector.BloodVol_PVCrit, KidneyPlasmaFlow.u2) annotation(Text(string = "%first", index = -1, extent = {{6, -3}, {6, -3}}));
connect(KidneyPlasmaFlow.y, busConnector.KidneyPlasmaFlow) annotation(Text(string = "%second", index = 1, extent = {{3, 3}, {3, 3}}));
connect(ArcuateArtery.q_out, AfferentArtery.q_in);
connect(EfferentArtery.q_in, AfferentArtery.q_out);
connect(EfferentArtery.q_out, q_out);
connect(AfferentArtery.q_in, pressureMeasure1.q_in);
connect(IFP.u, pressureMeasure1.actualPressure);
connect(ANP_Effect.y, A2Effect3.yBase);
connect(FurosemideEffect.y, ANP_Effect.yBase);
connect(NaEffect_MaculaDensa.y, FurosemideEffect.yBase);
connect(MedulaDensa_BaseTGFSignal.y, NaEffect_MaculaDensa.yBase);
connect(A2Effect3.y, TGFEffect.u);
connect(NephronCountEffect_AfferentArtery.y, TGFEffect.yBase);
connect(TGFEffect.y, AplhaReceptors_KidneyAfferentArtery.yBase);
connect(busConnector.FurosemidePool_Loss, FurosemideEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ANPPool_Log10Conc, ANP_Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect3.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(flowMeasure.actualFlow, KidneyPlasmaFlow.u1);
connect(flowMeasure.q_out, ArcuateArtery.q_in);
connect(busConnector, vasaRecta.busConnector);
connect(pressureMeasure1.actualPressure, vasaRecta.ArcuateArtery_Pressure);
connect(busConnector.NephronIFP_Pressure, IFP.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MD_Na, NaEffect_MaculaDensa.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Kidney;

model VariableResistorWithMyogenicResponse
extends Physiolibrary.PressureFlow.Resistor;
extends Physiolibrary.Utilities.DynamicState(stateName = "Kidney-MyogenicDelay.PressureChange");
Physiolibrary.Interfaces.RealInput_ cond(final quantity = "Conductance", final unit = "ml/(min.mmHg)");
Real myogenicEffect;
Real pressureChange;
parameter Real K_PressureChange(final unit = "1/min") = 2.0;
parameter Real Tau_PressureAdoption(final unit = "hod") = 4.0;
parameter Real[:, 3] PressureChangeOnMyogenicCondEffect;
Physiolibrary.Curves.Curve PressureChangeOnCondEffect(x = PressureChangeOnMyogenicCondEffect[:, 1], y = PressureChangeOnMyogenicCondEffect[:, 2], slope = PressureChangeOnMyogenicCondEffect[:, 3]);
AfferentArteryMyogenicReceptors kidneyMyogenic;
equation
q_in.q = myogenicEffect * cond * (q_in.pressure - q_out.pressure);
kidneyMyogenic.InterlobarPressure = (q_in.pressure + q_out.pressure) / 2;
stateValue = pressureChange;
changePerMin = K_PressureChange * (kidneyMyogenic.PressureChange_SteadyState - pressureChange);
PressureChangeOnCondEffect.u = pressureChange;
myogenicEffect = PressureChangeOnCondEffect.val;
end VariableResistorWithMyogenicResponse;

model OtherTissue
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Blocks.CondConstant BasicConductance(k = 4.2);
Physiolibrary.PressureFlow.ResistorWithCond OtherTissue;
Physiolibrary.Factors.CurveValue A2Effect_OtherTissue(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Factors.CurveValue ADHEffect_OtherTissue(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Factors.SimpleMultiply Anesthesia_OtherTissue;
Physiolibrary.Factors.SimpleMultiply Viscosity_OtherTissue;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_OtherTissue(Tau = 30, data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, stateName = "OtherTissue-Vasculature.Effect");
HumMod.Nerves.AplhaReceptorsActivityFactor AplhaReceptors_OtherTissue(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.3}, {5.0, 0.1, 0}});
Physiolibrary.Factors.CurveValue PO2OnConductance_OtherTissue(data = {{10, 2.0, 0}, {30, 1.0, 0}});
equation
connect(Vasculature_OtherTissue.y, PO2OnConductance_OtherTissue.yBase);
connect(Viscosity_OtherTissue.y, Anesthesia_OtherTissue.yBase);
connect(Vasculature_OtherTissue.yBase, Anesthesia_OtherTissue.y);
connect(PO2OnConductance_OtherTissue.y, A2Effect_OtherTissue.yBase);
connect(BasicConductance.y, Viscosity_OtherTissue.yBase);
connect(ADHEffect_OtherTissue.y, OtherTissue.cond);
connect(busConnector.Viscosity_ConductanceEffect, Viscosity_OtherTissue.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Anesthesia_VascularConductance, Anesthesia_OtherTissue.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OtherTissue_Function_Failed, Vasculature_OtherTissue.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OtherTissue_PO2, Vasculature_OtherTissue.u);
connect(busConnector.OtherTissue_PO2, PO2OnConductance_OtherTissue.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect_OtherTissue.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_OtherTissue.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_OtherTissue.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_OtherTissue.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect_OtherTissue.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AplhaReceptors_OtherTissue.yBase, A2Effect_OtherTissue.y);
connect(AplhaReceptors_OtherTissue.y, ADHEffect_OtherTissue.yBase);
connect(flowMeasure.q_out, OtherTissue.q_in);
connect(OtherTissue.q_out, q_out);
end OtherTissue;

model SkeletalMuscle
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Blocks.CondConstant BasicConductance(k = 7.2);
Physiolibrary.Factors.CurveValue ADHEffect(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Factors.SimpleMultiply Viscosity;
Physiolibrary.Factors.SimpleMultiply Anesthesia;
Physiolibrary.PressureFlow.ResistorWithCond SkeletalMuscle;
HumMod.Nerves.AplhaReceptorsActivityFactor aplhaReceptorsActivityFactor(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.2}, {4.0, 0.5, 0}});
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_skeletalMuscle(data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, Tau = 30, stateName = "SkeletalMuscle-Vasculature.Effect");
Physiolibrary.Factors.CurveValue PO2Effect(data = {{0, 4.0, 0}, {25, 2.5, -0.2}, {35, 1.0, 0}});
Physiolibrary.Factors.CurveValue IntensityEffect(data = {{0, 0.0, 0.007}, {300, 1.0, 0.0}});
Physiolibrary.Factors.CurveValue RateEffect(data = {{0, 0.0, 0.04}, {60, 1.0, 0.0}});
Physiolibrary.Factors.SimpleMultiply MusclePumping_SkeletalMuscle;
Physiolibrary.Blocks.Constant BaseMusclePumpEffect(k = 1);
ConductanceFactors.MetabolicVasolidation2 metabolicVasolidation(data = {{50, 1.0, 0}, {1000, 3.5, 0.003}, {3000, 5.5, 0}}, OnTau = 0.2, OffTau = 1, stateName = "SkeletalMuscle-MetabolicVasodilation.Effect");
Physiolibrary.Blocks.Add add(k = 1);
equation
connect(Viscosity.y, Anesthesia.yBase);
connect(Vasculature_skeletalMuscle.yBase, Anesthesia.y);
connect(Vasculature_skeletalMuscle.y, PO2Effect.yBase);
connect(MusclePumping_SkeletalMuscle.y, A2Effect.yBase);
connect(Viscosity.yBase, BasicConductance.y);
connect(SkeletalMuscle.cond, ADHEffect.y);
connect(BaseMusclePumpEffect.y, IntensityEffect.yBase);
connect(IntensityEffect.y, RateEffect.yBase);
connect(Viscosity.u, busConnector.Viscosity_ConductanceEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Anesthesia.u, busConnector.Anesthesia_VascularConductance) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Vasculature_skeletalMuscle.Failed, busConnector.SkeletalMuscle_Function_Failed) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(metabolicVasolidation.O2Need, busConnector.SkeletalMuscle_O2Need) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(A2Effect.u, busConnector.A2Pool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.AlphaPool_Effect, busConnector.AlphaPool_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.AlphaBlockade_Effect, busConnector.AlphaBlocade_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.GangliaGeneral_NA, busConnector.GangliaGeneral_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ADHEffect.u, busConnector.ADHPool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(IntensityEffect.u, busConnector.Exercise_Metabolism_MotionWatts) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(RateEffect.u, busConnector.Exercise_Metabolism_ContractionRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(metabolicVasolidation.yBase, PO2Effect.y);
connect(metabolicVasolidation.y, MusclePumping_SkeletalMuscle.yBase);
connect(A2Effect.y, aplhaReceptorsActivityFactor.yBase);
connect(ADHEffect.yBase, aplhaReceptorsActivityFactor.y);
connect(MusclePumping_SkeletalMuscle.u, add.y);
connect(add.u, RateEffect.y);
connect(flowMeasure.q_out, SkeletalMuscle.q_in);
connect(SkeletalMuscle.q_out, q_out);
connect(Vasculature_skeletalMuscle.u, busConnector.SkeletalMuscle_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PO2Effect.u, busConnector.SkeletalMuscle_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end SkeletalMuscle;

model RespiratoryMuscle
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Blocks.CondConstant BasicConductance(k = 1.1);
Physiolibrary.Factors.CurveValue ADHEffect(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Factors.SimpleMultiply Viscosity;
Physiolibrary.Factors.SimpleMultiply Anesthesia;
Physiolibrary.PressureFlow.ResistorWithCond respiratorylMuscle;
HumMod.Nerves.AplhaReceptorsActivityFactor aplhaReceptorsActivityFactor(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.3}, {5.0, 0.1, 0}});
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature(Tau = 30, data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, stateName = "RespiratoryMuscle-Vasculature.Effect");
Physiolibrary.Factors.CurveValue PO2Effect(data = {{10, 2.0, 0}, {30, 1.0, 0}});
Physiolibrary.Factors.CurveValue MetabolismEffect(data = {{6, 1.0, 0}, {12, 1.3, 0.08}, {400, 24.0, 0}});
equation
connect(Viscosity.y, Anesthesia.yBase);
connect(Vasculature.yBase, Anesthesia.y);
connect(Vasculature.y, PO2Effect.yBase);
connect(Viscosity.yBase, BasicConductance.y);
connect(respiratorylMuscle.cond, ADHEffect.y);
connect(Viscosity.u, busConnector.Viscosity_ConductanceEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Anesthesia.u, busConnector.Anesthesia_VascularConductance) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Vasculature.Failed, busConnector.RespiratoryMuscle_Function_Failed) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Vasculature.u, busConnector.RespiratoryMuscle_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PO2Effect.u, busConnector.RespiratoryMuscle_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(A2Effect.u, busConnector.A2Pool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.AlphaPool_Effect, busConnector.AlphaPool_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.AlphaBlockade_Effect, busConnector.AlphaBlocade_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(aplhaReceptorsActivityFactor.GangliaGeneral_NA, busConnector.GangliaGeneral_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ADHEffect.u, busConnector.ADHPool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PO2Effect.y, MetabolismEffect.yBase);
connect(MetabolismEffect.u, busConnector.RespiratoryMuscle_O2Need) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MetabolismEffect.y, A2Effect.yBase);
connect(aplhaReceptorsActivityFactor.yBase, A2Effect.y);
connect(aplhaReceptorsActivityFactor.y, ADHEffect.yBase);
connect(flowMeasure.q_out, respiratorylMuscle.q_in);
connect(respiratorylMuscle.q_out, q_out);
end RespiratoryMuscle;

model Heart
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
parameter Real BasicLargeVeselsConductance(final quantity = "Conductance", final unit = "ml/(min.mmHg)");
parameter Real BasicSmallVeselsConductance(final quantity = "Conductance", final unit = "ml/(min.mmHg)");
Physiolibrary.Factors.CurveValue PO2Effect(data = {{12, 2.0, 0}, {17, 1.0, -0.04}, {30, 0.8, 0}}, u(start = 20));
Physiolibrary.Factors.CurveValue ADHEffect2(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Factors.CurveValue MetabolismEffect(data = {{30, 1.0, 0}, {100, 3.0, 0}});
Physiolibrary.Factors.SimpleMultiply Anesthesia;
Physiolibrary.Blocks.CondConstant LargeVesselBasicConductance(k = BasicLargeVeselsConductance);
Physiolibrary.Factors.SimpleMultiply Viscosity1;
Physiolibrary.Blocks.CondConstant SmallVesselBasicConductance(k = BasicSmallVeselsConductance);
HumMod.Nerves.AplhaReceptorsActivityFactor aplhaReceptorsActivityFactor(data = {{0.0, 1.3, 0}, {1.0, 1.0, -0.16}, {4.0, 0.8, 0}});
ConductanceFactors.HeartInfraction Infraction;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature(data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, Tau = 30, u(start = 20), integrator(y_start = 1.2));
Physiolibrary.Factors.SimpleMultiply Viscosity;
Physiolibrary.PressureFlow.ResistorWith2Cond vessels;
equation
connect(LargeVesselBasicConductance.y, Viscosity1.yBase);
connect(Viscosity.y, Anesthesia.yBase);
connect(busConnector.Anesthesia_VascularConductance, Anesthesia.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Viscosity_ConductanceEffect, Viscosity.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, aplhaReceptorsActivityFactor.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, aplhaReceptorsActivityFactor.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, aplhaReceptorsActivityFactor.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Viscosity_ConductanceEffect, Viscosity1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Viscosity.yBase, SmallVesselBasicConductance.y);
connect(Anesthesia.y, ADHEffect2.yBase);
connect(ADHEffect2.y, aplhaReceptorsActivityFactor.yBase);
connect(aplhaReceptorsActivityFactor.y, Vasculature.yBase);
connect(Vasculature.y, PO2Effect.yBase);
connect(PO2Effect.y, MetabolismEffect.yBase);
connect(MetabolismEffect.y, Infraction.yBase);
connect(vessels.q_in, flowMeasure.q_out);
connect(Infraction.y, vessels.cond2);
connect(Viscosity1.y, vessels.cond1);
connect(vessels.q_out, q_out);
end Heart;

model PeripheralFlow
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
HumMod.CardioVascular.OrganFlow.Bone bone;
HumMod.CardioVascular.OrganFlow.Brain brain;
HumMod.CardioVascular.OrganFlow.Fat fat;
HumMod.CardioVascular.OrganFlow.Kidney kidney;
HumMod.CardioVascular.OrganFlow.Skin skin;
HumMod.CardioVascular.OrganFlow.OtherTissue otherTissue;
HumMod.CardioVascular.OrganFlow.SkeletalMuscle skeletalMuscle;
HumMod.CardioVascular.OrganFlow.RespiratoryMuscle respiratoryMuscle;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
equation
connect(bone.q_in, flowMeasure.q_out);
connect(brain.q_in, flowMeasure.q_out);
connect(fat.q_in, flowMeasure.q_out);
connect(skin.q_in, flowMeasure.q_out);
connect(otherTissue.q_in, flowMeasure.q_out);
connect(skeletalMuscle.q_in, flowMeasure.q_out);
connect(respiratoryMuscle.q_in, flowMeasure.q_out);
connect(respiratoryMuscle.q_out, q_out);
connect(skeletalMuscle.q_out, q_out);
connect(otherTissue.q_out, q_out);
connect(skin.q_out, q_out);
connect(fat.q_out, q_out);
connect(brain.q_out, q_out);
connect(bone.q_out, q_out);
connect(busConnector, otherTissue.busConnector);
connect(busConnector, skin.busConnector);
connect(busConnector, kidney.busConnector);
connect(busConnector, fat.busConnector);
connect(busConnector, brain.busConnector);
connect(busConnector, bone.busConnector);
connect(busConnector, skeletalMuscle.busConnector);
connect(busConnector, respiratoryMuscle.busConnector);
connect(bone.BloodFlow, busConnector.bone_BloodFlow);
connect(brain.BloodFlow, busConnector.brain_BloodFlow);
connect(fat.BloodFlow, busConnector.fat_BloodFlow);
connect(kidney.BloodFlow, busConnector.kidney_BloodFlow);
connect(skin.BloodFlow, busConnector.skin_BloodFlow);
connect(skeletalMuscle.BloodFlow, busConnector.skeletalMuscle_BloodFlow);
connect(respiratoryMuscle.BloodFlow, busConnector.respiratoryMuscle_BloodFlow);
connect(otherTissue.BloodFlow, busConnector.otherTissue_BloodFlow);
connect(bone.BloodFlow, busConnector.Bone_BloodFlow);
connect(brain.BloodFlow, busConnector.Brain_BloodFlow);
connect(fat.BloodFlow, busConnector.Fat_BloodFlow);
connect(kidney.BloodFlow, busConnector.Kidney_BloodFlow);
connect(skin.BloodFlow, busConnector.Skin_BloodFlow);
connect(skeletalMuscle.BloodFlow, busConnector.SkeletalMuscle_BloodFlow);
connect(respiratoryMuscle.BloodFlow, busConnector.RespiratoryMuscle_BloodFlow);
connect(otherTissue.BloodFlow, busConnector.OtherTissue_BloodFlow);
connect(kidney.q_out, q_out);
connect(kidney.q_in, flowMeasure.q_out);
end PeripheralFlow;

model VasaRecta
Physiolibrary.PressureFlow.ResistorWithCond resistorWithCond;
Physiolibrary.Factors.CurveValue OsmOnConductance(data = {{600, 1.4, 0}, {1100, 1.0, -0.0005999999999999999}, {2000, 0.8, 0}});
Physiolibrary.Factors.CurveValue A2OnConductance(data = {{0.0, 1.3, 0}, {1.3, 1.0, -0.6}, {2.0, 0.5, 0}});
Physiolibrary.Factors.CurveValue SympsOnConductance(data = {{0.0, 1.1, 0}, {1.0, 1.0, -0.13}, {1.4, 0.6, 0}});
Physiolibrary.Blocks.CondConstant condConstant(k = 0.27);
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
Physiolibrary.PressureFlow.InputPump inputPump;
Modelica.Blocks.Math.Add Osm;
Physiolibrary.Interfaces.RealInput_ ArcuateArtery_Pressure;
Physiolibrary.Factors.CurveValue NephroneADHOnConductance(data = {{0.0, 1.4, 0}, {0.3, 1.0, -0.4}, {1.0, 0.9, 0}});
Physiolibrary.PressureFlow.InputPressurePump arcuateArtery;
Physiolibrary.PressureFlow.OutputPressurePump veins;
equation
connect(SympsOnConductance.y, resistorWithCond.cond);
connect(A2OnConductance.y, SympsOnConductance.yBase);
connect(OsmOnConductance.y, A2OnConductance.yBase);
connect(busConnector.A2Pool_Log10Conc, A2OnConductance.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Kidney_Alpha_NA, SympsOnConductance.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(resistorWithCond.q_out, flowMeasure.q_in);
connect(flowMeasure.actualFlow, busConnector.VasaRecta_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, -12}, {6, -12}}));
connect(inputPump.q_out, flowMeasure.q_in);
connect(Osm.y, OsmOnConductance.u);
connect(busConnector.MedullaNa_Osmolarity, Osm.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MedullaUrea_Osmolarity, Osm.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CD_H2O_Reab, inputPump.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(NephroneADHOnConductance.y, OsmOnConductance.yBase);
connect(condConstant.y, NephroneADHOnConductance.yBase);
connect(busConnector.NephronADH, NephroneADHOnConductance.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(arcuateArtery.p_out, resistorWithCond.q_in);
connect(ArcuateArtery_Pressure, arcuateArtery.desiredPressure);
connect(veins.desiredPressure, busConnector.SystemicVeins_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.q_out, veins.p_in);
end VasaRecta;

model LeftHeart
extends Heart(Vasculature(stateName = "LeftHeart-Vasculature.Effect"));
equation
connect(busConnector.LeftHeart_Function_Failed, Vasculature.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LeftHeart_PO2, PO2Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LeftHeart_O2Need, MetabolismEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LeftHeart_PO2, Vasculature.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end LeftHeart;

model RightHeart
extends Heart(Vasculature(stateName = "RightHeart-Vasculature.Effect"));
equation
connect(busConnector.RightHeart_PO2, Vasculature.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RightHeart_PO2, PO2Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RightHeart_O2Need, MetabolismEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RightHeart_Function_Failed, Vasculature.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end RightHeart;

model SplanchnicCirculation
extends Physiolibrary.PressureFlow.ResistorBase2;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
VascularCompartments.VascularElasticBloodCompartment portalVein(initialVol = 1009.99, stateName = "SplanchnicVeins.Vol");
OrganFlow.GITract GITract;
Physiolibrary.Blocks.PressureConstant ExternalPressure(k = 0);
Physiolibrary.Blocks.ComplianceConstant Compliance(k = 62.5);
Physiolibrary.Blocks.Constant V0(k = 500);
Liver liver;
equation
connect(GITract.busConnector, busConnector);
connect(portalVein.ExternalPressure, ExternalPressure.y);
connect(portalVein.Compliance, Compliance.y);
connect(portalVein.V0, V0.y);
connect(GITract.BloodFlow, busConnector.GITract_BloodFlow);
connect(portalVein.Pressure, busConnector.SplanchnicVeins_Pressure) annotation(Text(string = "%second", index = 1, extent = {{3, -3}, {3, -3}}));
connect(V0.y, busConnector.PortalVein_V0) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(portalVein.Vol, busConnector.SplanchnicCirculation_DeoxygenatedBloodVolume);
connect(portalVein.referencePoint, liver.portalVein);
connect(busConnector, liver.busConnector);
connect(GITract.q_out, portalVein.referencePoint);
connect(GITract.q_in, q_in);
connect(liver.q_in, q_in);
connect(liver.q_out, q_out);
end SplanchnicCirculation;

model Liver
extends Base;
Physiolibrary.PressureFlow.PositivePressureFlow portalVein annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.PressureFlow.ResistorWithCondParam splachnicVeinsConductance(cond = 1250) "corrected to flow 1250ml/min in pressure gradient 1 mmHg";
Physiolibrary.PressureFlow.FlowMeasure flowMeasure1;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure2;
Physiolibrary.PressureFlow.ResistorWithCondParam HepaticArtyConductance(cond = 2.8);
Physiolibrary.PressureFlow.FlowMeasure flowMeasure3;
equation
connect(flowMeasure1.actualFlow, busConnector.Liver_BloodFlow);
connect(flowMeasure2.actualFlow, busConnector.PortalVein_BloodFlow);
connect(flowMeasure3.actualFlow, busConnector.HepaticArty_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(portalVein, flowMeasure2.q_in);
connect(flowMeasure.q_out, flowMeasure3.q_in);
connect(flowMeasure3.q_out, HepaticArtyConductance.q_in);
connect(splachnicVeinsConductance.q_out, flowMeasure1.q_in);
connect(flowMeasure1.q_out, q_out);
connect(flowMeasure2.q_out, splachnicVeinsConductance.q_in);
connect(HepaticArtyConductance.q_out, splachnicVeinsConductance.q_in);
end Liver;

model AfferentArteryMyogenicReceptors
extends Physiolibrary.Utilities.DynamicState(stateName = "Kidney-Myogenic.AdaptedPressure");
parameter Real Tau = 4;
parameter Real K = 1 / (60.0 * Tau);
Real AdaptedPressure(unit = "mmHg");
Physiolibrary.Interfaces.RealInput InterlobarPressure(unit = "mmHg");
Physiolibrary.Interfaces.RealOutput PressureChange_SteadyState(unit = "mmHg");
equation
stateValue = AdaptedPressure;
changePerMin = K * (InterlobarPressure - AdaptedPressure);
PressureChange_SteadyState = InterlobarPressure - AdaptedPressure;
end AfferentArteryMyogenicReceptors;

model Skin
extends HumMod.CardioVascular.OrganFlow.BaseBadDirection;
Physiolibrary.PressureFlow.ResistorWithCond skin;
Physiolibrary.Factors.CurveValue A2Effect_Skin(data = {{0.0, 1.05, 0}, {1.3, 1.0, -0.08}, {3.5, 0.5, 0}});
Physiolibrary.Factors.CurveValue ADHEffect_Skin(data = {{0.8, 1.0, 0}, {3.0, 0.1, 0}});
Physiolibrary.Blocks.CondConstant BasicConductance(k = 1.6);
Physiolibrary.Factors.SimpleMultiply Viscosity_Skin;
Physiolibrary.Factors.SimpleMultiply Anesthesia_Skin;
Physiolibrary.Factors.SplineDelayFactorByDayWithFailture Vasculature_Skin(Tau = 30, data = {{41, 1.2, 0}, {51, 1.0, -0.03}, {61, 0.8, 0}}, stateName = "Skin-Vasculature.Effect");
Physiolibrary.Factors.SimpleMultiply TermoregulationEffect;
equation
connect(Anesthesia_Skin.yBase, Viscosity_Skin.y);
connect(Anesthesia_Skin.y, Vasculature_Skin.yBase);
connect(Vasculature_Skin.y, A2Effect_Skin.yBase);
connect(BasicConductance.y, Viscosity_Skin.yBase);
connect(busConnector.Viscosity_ConductanceEffect, Viscosity_Skin.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Anesthesia_VascularConductance, Anesthesia_Skin.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Skin_Function_Failed, Vasculature_Skin.Failed) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Skin_PO2, Vasculature_Skin.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.A2Pool_Log10Conc, A2Effect_Skin.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ADHPool_Log10Conc, ADHEffect_Skin.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(skin.q_out, q_out);
connect(skin.q_in, flowMeasure.q_out);
connect(ADHEffect_Skin.y, busConnector.skin_conductanceWithoutTermoregulationEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.skinFlow_termoregulationEffect, TermoregulationEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(ADHEffect_Skin.y, TermoregulationEffect.yBase);
connect(TermoregulationEffect.y, skin.cond);
connect(A2Effect_Skin.y, ADHEffect_Skin.yBase);
end Skin;
end OrganFlow;

package BlooodVolume  "Red Cells and Blood Properties"
model RedCells2
Physiolibrary.PressureFlow.OutputPump RBCClearance;
Physiolibrary.PressureFlow.VolumeCompartement RBCVolume(initialVolume = 2373.2, stateName = "RBCVol.Vol");
Physiolibrary.PressureFlow.InputPump transfusion;
Physiolibrary.PressureFlow.OutputPump hemorrhage;
Physiolibrary.Factors.SplineDelayByDay EPOEffect(Tau = 3, data = {{0.0, 0.0, 0}, {1.3, 1.0, 1.0}, {4.0, 4.0, 0}}, stateName = "[EPO]Delay.Effect");
Physiolibrary.Blocks.FlowConstant RBCBaseSecretionRate(k = 0.013889);
Physiolibrary.PressureFlow.InputPump RBCProduction;
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Gain gain(k = 1 / 120 * 1 / 1440);
Modelica.Blocks.Math.Gain H2O(k = 1 - 0.34);
equation
connect(busConnector.Transfusion_RBCRate, transfusion.desiredFlow);
connect(busConnector.Hemorrhage_RBCRate, hemorrhage.desiredFlow);
connect(RBCBaseSecretionRate.y, EPOEffect.yBase);
connect(EPOEffect.u, busConnector.EPOPool_Log10Conc);
connect(RBCProduction.desiredFlow, EPOEffect.y);
connect(RBCProduction.q_out, RBCVolume.con);
connect(transfusion.q_out, RBCVolume.con);
connect(RBCVolume.con, hemorrhage.q_in);
connect(RBCVolume.con, RBCClearance.q_in);
connect(RBCVolume.Volume, gain.u);
connect(gain.y, RBCClearance.desiredFlow);
connect(RBCVolume.Volume, busConnector.RBCVol_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, -5}, {6, -5}}));
connect(RBCVolume.Volume, H2O.u);
connect(H2O.y, busConnector.RBCH2O_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end RedCells2;

model BloodPropertiesBase
Modelica.Blocks.Math.Add BloodVolume;
Modelica.Blocks.Math.Min CollapsedEffect;
Modelica.Blocks.Math.Division division;
Physiolibrary.Blocks.Constant const(k = 1);
Modelica.Blocks.Math.Division HtcFract;
Physiolibrary.Curves.Curve HtcOnVisc(x = {0, 0.44, 0.8}, y = {0.5, 1, 5}, slope = {0.8, 3, 30});
Modelica.Blocks.Math.Division division1;
Physiolibrary.Blocks.Constant const1(k = 1);
Physiolibrary.Blocks.Constant const2(k = 1);
Modelica.Blocks.Math.Feedback PVCrit;
Physiolibrary.Blocks.Constant Constant4(k = 8.4);
Physiolibrary.Blocks.Constant Constant1(k = 0.44);
Physiolibrary.Factors.SimpleMultiply hematocritEffect;
Modelica.Blocks.Math.Division division2;
Physiolibrary.Blocks.Constant Constant5(k = 5.4);
Physiolibrary.Blocks.Constant Constant6(k = 0.005);
Physiolibrary.Blocks.Constant Constant7(k = 0.005);
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Division division3(y(unit = "mmol/l"));
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Math.Add BloodVolume1;
Modelica.Blocks.Math.Product product;
Modelica.Blocks.Math.Sum V0(nin = 5);
Modelica.Blocks.Math.Sum VeinsVol(nin = 4) "volume of deoxygenated blood";
Modelica.Blocks.Math.Sum ArtysVol(nin = 3) "volume of oxygenated blood";
equation
connect(busConnector.PlasmaVol_Vol, BloodVolume.u2);
connect(busConnector.RBCVol_Vol, BloodVolume.u1);
connect(division.y, CollapsedEffect.u1);
connect(busConnector.Vesseles_V0, division.u2);
connect(BloodVolume.y, division.u1);
connect(const.y, CollapsedEffect.u2);
connect(CollapsedEffect.y, busConnector.BloodVol_CollapsedEffect);
connect(HtcFract.u2, BloodVolume.y);
connect(HtcFract.u1, busConnector.RBCVol_Vol);
connect(HtcFract.y, HtcOnVisc.u);
connect(const1.y, division1.u1);
connect(HtcOnVisc.val, division1.u2);
connect(division1.y, busConnector.Viscosity_ConductanceEffect);
connect(HtcFract.y, busConnector.BloodVol_Hct);
connect(const2.y, PVCrit.u1);
connect(HtcFract.y, PVCrit.u2);
connect(PVCrit.y, busConnector.BloodVol_PVCrit) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Constant4.y, hematocritEffect.yBase);
connect(hematocritEffect.y, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(division2.y, hematocritEffect.u);
connect(Constant1.y, division2.u2);
connect(HtcFract.y, division2.u1);
connect(busConnector.cDPG, Constant5.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.FMetHb, Constant6.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.FHbF, Constant7.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant4.y, division3.u1);
connect(HtcFract.y, division3.u2);
connect(division3.y, busConnector.ctHb_ery) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(BloodVolume.y, feedback.u1);
connect(busConnector.ArtysVol, BloodVolume1.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.VeinsVol, BloodVolume1.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(BloodVolume1.y, feedback.u2);
connect(PVCrit.y, product.u2);
connect(busConnector.PortalVein_BloodFlow, product.u1);
connect(product.y, busConnector.PortalVein_PlasmaFlow);
connect(V0.y, busConnector.Vesseles_V0) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.PulmonaryCirculation_V0, V0.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.Heart_V0, V0.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 2}, {-6, 2}}));
connect(busConnector.SystemicArtys_V0, V0.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -2}, {-6, -2}}));
connect(busConnector.PortalVein_V0, V0.u[4]) annotation(Text(string = "%first", index = -1, extent = {{-6, -6}, {-6, -6}}));
connect(busConnector.SystemicVeins_V0, V0.u[5]) annotation(Text(string = "%first", index = -1, extent = {{-6, -10}, {-6, -10}}));
connect(VeinsVol.y, busConnector.VeinsVol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.PulmonaryCirculation_DeoxygenatedBloodVolume, VeinsVol.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.Heart_DeoxygenatedBloodVolume, VeinsVol.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 2}, {-6, 2}}));
connect(busConnector.SplanchnicCirculation_DeoxygenatedBloodVolume, VeinsVol.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -2}, {-6, -2}}));
connect(busConnector.SystemicVeins_DeoxygenatedBloodVolume, VeinsVol.u[4]) annotation(Text(string = "%first", index = -1, extent = {{-6, -6}, {-6, -6}}));
connect(ArtysVol.y, busConnector.ArtysVol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.PulmonaryCirculation_OxygenatedBloodVolume, ArtysVol.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.Heart_OxygenatedBloodVolume, ArtysVol.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 2}, {-6, 2}}));
connect(busConnector.SystemicArtys_OxygenatedBloodVolume, ArtysVol.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -2}, {-6, -2}}));
connect(feedback.y, busConnector.BloodVolume_change) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(BloodVolume.y, busConnector.BloodVolume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end BloodPropertiesBase;
end BlooodVolume;

model CVS_Dynamic
VascularCompartments.Heart heart;
VascularCompartments.PulmonaryCirculation pulmonaryCirculation;
VascularCompartments.SystemicCirculationFullDynamic systemicCirculation;
Physiolibrary.Interfaces.BusConnector busConnector "signals of organ bood flow resistence";
BlooodVolume.RedCells2 redCells;
BlooodVolume.BloodPropertiesBase bloodProperties;
equation
connect(busConnector, pulmonaryCirculation.busConnector);
connect(busConnector, systemicCirculation.busConnector);
connect(busConnector, redCells.busConnector);
connect(busConnector, bloodProperties.busConnector);
connect(busConnector, heart.busConnector);
connect(heart.fromLeftVentricle, systemicCirculation.q_in);
connect(systemicCirculation.q_out, heart.rightAtrium);
connect(pulmonaryCirculation.q_in, heart.fromRightVentricle);
connect(pulmonaryCirculation.q_out, heart.leftAtrium);
end CVS_Dynamic;
end CardioVascular;

package Water  "Body Water"

package Hydrostatics  "Hydrostatic pressure difference in upper, midle and lower torso"
type Posture = enumeration(Lying, Sitting, Standing, Tilting, SteadyState);

model TorsoHydrostatics
extends Physiolibrary.Interfaces.BaseModel;
parameter Real Alpha = 0.1667 "torso: capilary pressure coeficient between artery and vein pressure";
parameter Real Gravity_Gz = 1 "gravity constant / 10";
parameter Real TorsoCM(final quantity = "Height", final unit = "cm") "torso: center of gravity - height";
parameter Real[Posture] artyFractGz "torso: arty hydrostatic effects for posturing";
parameter Real[Posture] veinFractGz "torso: vein hydrostatic effects for posturing";
Real ArtyFractGz;
Real VeinFractGz;
Real TorsoArtyGradient(final quantity = "Pressure", final unit = "mmHg");
Real TorsoVeinGradient(final quantity = "Pressure", final unit = "mmHg");
Real Arty(final quantity = "Pressure", final unit = "mmHg");
Real Vein(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealInput Pump_Effect(final unit = "1") "xNormal";
Physiolibrary.Interfaces.RealInput fromPressure(final quantity = "Pressure", final unit = "mmHg") "torso: systemic arteries pressure";
Physiolibrary.Interfaces.RealInput toPressure(final quantity = "Pressure", final unit = "mmHg") "torso: systemic veins pressure";
PostureInput Status_Posture "Lying, Sitting, Standing or Tilting";
Physiolibrary.Interfaces.RealOutput_ Capy(final quantity = "Pressure", final unit = "mmHg") "torso: average capilaries pressure";
equation
ArtyFractGz = artyFractGz[Status_Posture];
VeinFractGz = veinFractGz[Status_Posture];
TorsoArtyGradient = TorsoCM * Gravity_Gz * ArtyFractGz;
TorsoVeinGradient = TorsoCM * Gravity_Gz * VeinFractGz;
Arty = max(fromPressure + TorsoArtyGradient, 0);
Vein = max(toPressure + TorsoVeinGradient * Pump_Effect, 0);
Capy = max(Alpha * Arty + (1.0 - Alpha) * Vein, 0);
end TorsoHydrostatics;

model Hydrostatics
parameter Real TiltTable_Degrees(final quantity = "Angle", final unit = "Deg") = 0;
TorsoHydrostatics UpperTorsoHydrostatics(TorsoCM = -10, artyFractGz = {0, 1, 1, sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), 1.76947}, veinFractGz = {0, 1, 1, sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), 1.76947});
TorsoHydrostatics LowerTorsoHydrostatics(TorsoCM = 50.0, artyFractGz = {0, 0.7, 1, sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), 0.0190301}, veinFractGz = {0.2, 0.7, 1, 0.2 + sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), 0.0190301});
TorsoHydrostatics MiddleTorsoHydrostatics(TorsoCM = 4, artyFractGz = {0, 1, 1, sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), -0.00024891}, veinFractGz = {0, 1, 1, sin(Modelica.SIunits.Conversions.from_deg(TiltTable_Degrees)), -0.00024891});
Physiolibrary.Blocks.Constant PumpEffect(k = 1);
Physiolibrary.Interfaces.RealInput SystemicArtys_Pressure(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealInput RightAtrium_Pressure(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealInput LegMusclePump_Effect(final quantity = "Flow", final unit = "ml/min");
Physiolibrary.Interfaces.RealInput_ Status_Posture "Lying, Sitting, Standing or Tilting";
Physiolibrary.Interfaces.RealOutput RegionalPressure_UpperCapy(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealOutput RegionalPressure_MiddleCapy(final quantity = "Pressure", final unit = "mmHg");
Physiolibrary.Interfaces.RealOutput RegionalPressure_LowerCapy(final quantity = "Pressure", final unit = "mmHg");
Real2Posture real2Posture;
equation
connect(RightAtrium_Pressure, LowerTorsoHydrostatics.toPressure);
connect(RightAtrium_Pressure, MiddleTorsoHydrostatics.toPressure);
connect(RightAtrium_Pressure, UpperTorsoHydrostatics.toPressure);
connect(PumpEffect.y, UpperTorsoHydrostatics.Pump_Effect);
connect(MiddleTorsoHydrostatics.Pump_Effect, PumpEffect.y);
connect(SystemicArtys_Pressure, LowerTorsoHydrostatics.fromPressure);
connect(SystemicArtys_Pressure, MiddleTorsoHydrostatics.fromPressure);
connect(SystemicArtys_Pressure, UpperTorsoHydrostatics.fromPressure);
connect(LegMusclePump_Effect, LowerTorsoHydrostatics.Pump_Effect);
connect(UpperTorsoHydrostatics.Capy, RegionalPressure_UpperCapy);
connect(MiddleTorsoHydrostatics.Capy, RegionalPressure_MiddleCapy);
connect(LowerTorsoHydrostatics.Capy, RegionalPressure_LowerCapy);
connect(UpperTorsoHydrostatics.Status_Posture, real2Posture.y);
connect(real2Posture.y, MiddleTorsoHydrostatics.Status_Posture);
connect(LowerTorsoHydrostatics.Status_Posture, real2Posture.y);
connect(real2Posture.u, Status_Posture);
end Hydrostatics;

connector PostureInput = input Posture "'input Posture' as connector";
connector PostureOutput = output Posture "'input Posture' as connector";

model Real2Posture  "Convert Real to type Posture"
extends Physiolibrary.Interfaces.ConversionIcon;
PostureOutput y "Connector of Real output signal";
Physiolibrary.Interfaces.RealInput_ u;
Integer tmp;
equation
tmp = integer(u);
y = if tmp <= 0 then Posture.Lying elseif tmp == 1 then Posture.Sitting
elseif tmp == 2 then Posture.Standing
elseif tmp == 3 then Posture.Tilting else Posture.SteadyState;
end Real2Posture;
end Hydrostatics;

package Osmoles  "Intracellular vs. Extracellular Water"
model OsmBody
Physiolibrary.Interfaces.RealInput OsmECFV_Electrolytes(final unit = "mOsm");
Physiolibrary.Interfaces.RealInput OsmCell_Electrolytes(final unit = "mOsm");
Physiolibrary.Interfaces.RealInput UreaECF(final unit = "mOsm");
Physiolibrary.Interfaces.RealInput UreaICF(final unit = "mOsm");
Physiolibrary.Interfaces.RealInput BodyH2O_Vol(final unit = "ml") "all water in body";
Physiolibrary.Interfaces.RealOutput ECFV(final unit = "ml") "extracellular water";
Physiolibrary.Interfaces.RealOutput ICFV(final unit = "ml") "intracellular water";
parameter Real Dissociation = 0.89;
Real OsmECFV_NonElectrolytes;
Real OsmCell_NonElectrolytes;
Real Electrolytes;
Real NonElectrolytes;
Real Total;
Real ECFVActiveElectrolytes;
Real ICFVActiveElectrolytes;
Real ActiveElectrolytes;
Real ECFVActiveOsmoles;
Real ICFVActiveOsmoles;
Real ActiveOsmoles(start = 11683.1341496947);
Physiolibrary.Interfaces.RealOutput OsmBody_Osm_conc_CellWalls(final unit = "mOsm/ml");
Physiolibrary.Interfaces.RealOutput Osmoreceptors(start = 0.25331, final unit = "mOsm/ml");
Physiolibrary.Interfaces.RealInput GlucoseECF(final unit = "mOsm");
equation
OsmECFV_NonElectrolytes = UreaECF + GlucoseECF + 340.0;
OsmCell_NonElectrolytes = UreaICF + 354.0;
Electrolytes = OsmECFV_Electrolytes + OsmCell_Electrolytes;
NonElectrolytes = OsmECFV_NonElectrolytes + OsmCell_NonElectrolytes;
Total = Electrolytes + NonElectrolytes;
ECFVActiveElectrolytes = Dissociation * OsmECFV_Electrolytes;
ICFVActiveElectrolytes = Dissociation * OsmCell_Electrolytes;
ActiveElectrolytes = ECFVActiveElectrolytes + ICFVActiveElectrolytes;
ECFVActiveOsmoles = ECFVActiveElectrolytes + OsmECFV_NonElectrolytes;
ICFVActiveOsmoles = ICFVActiveElectrolytes + OsmCell_NonElectrolytes;
ActiveOsmoles = ECFVActiveOsmoles + ICFVActiveOsmoles;
OsmBody_Osm_conc_CellWalls = ActiveOsmoles / BodyH2O_Vol;
Osmoreceptors = ActiveElectrolytes / BodyH2O_Vol;
ICFV = ICFVActiveOsmoles / ActiveOsmoles * BodyH2O_Vol;
ECFV = BodyH2O_Vol - ICFV;
end OsmBody;
end Osmoles;

package WaterCompartments  "Body Water Distribution"
model Outtake
Physiolibrary.VolumeFlow.PositiveVolumeFlow H2OLoss;
parameter Real[:, 3] H2OMassEffect = {{0.0, 0.0, 0.0}, {50.0, 1.0, 0.0}};
Physiolibrary.VolumeFlow.OutputPump outputPump;
Physiolibrary.Curves.Curve curve(x = H2OMassEffect[:, 1], y = H2OMassEffect[:, 2], slope = H2OMassEffect[:, 3]);
Modelica.Blocks.Math.Product product;
Physiolibrary.VolumeFlow.VolumeMeasure volumeMeasure;
Physiolibrary.Interfaces.RealOutput_ outflow;
Physiolibrary.Interfaces.RealInput_ H2OTarget(quantity = "Flow", unit = "ml/min");
equation
connect(curve.val, product.u2);
connect(product.y, outputPump.desiredFlow);
connect(H2OLoss, volumeMeasure.q_in);
connect(volumeMeasure.q_in, outputPump.q_in);
connect(volumeMeasure.actualVolume, curve.u);
connect(product.y, outflow);
connect(H2OTarget, product.u1);
end Outtake;

package Kidney  "Kidney Water Excretion"
model CD_H2OChannels
extends Physiolibrary.Utilities.DynamicState(stateName = "CD_H2OChannels.Inactive");
extends Physiolibrary.Interfaces.BaseModel;
parameter Real initialActive(final unit = "1") = 1;
parameter Real InactivateK(final unit = "1/m1") = 0.000125;
parameter Real ReactivateK(final unit = "1/m1") = 0.0004;
Physiolibrary.PressureFlow.PositivePressureFlow CD_H2O_Reab;
Real Inactive(start = 2 - initialActive, final unit = "1");
Physiolibrary.Interfaces.RealOutput_ Active(final unit = "1");
Physiolibrary.PressureFlow.NegativePressureFlow q_out;
equation
q_out.q + CD_H2O_Reab.q = 0;
q_out.pressure = CD_H2O_Reab.pressure;
Active = 2 - Inactive;
stateValue = Inactive;
changePerMin = InactivateK * CD_H2O_Reab.q - ReactivateK * Inactive;
end CD_H2OChannels;

model DistalTubule
Physiolibrary.PressureFlow.PositivePressureFlow Inflow;
Physiolibrary.PressureFlow.NegativePressureFlow Outflow;
Physiolibrary.PressureFlow.NegativePressureFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ DesiredFlow(final quantity = "Flow", final unit = "ml/min");
equation
Outflow.q + Inflow.q + Reabsorbtion.q = 0;
Inflow.pressure = Outflow.pressure;
Outflow.q = -DesiredFlow;
end DistalTubule;

model Glomerulus4
Physiolibrary.Semipermeable.ColloidHydraulicPressure0 colloidHydraulicPressure;
Physiolibrary.Semipermeable.ColloidOsmolarity colloidOsmolarity(q_out(o(start = 0.08500000000000001)), q_in(q(start = -569.708)));
Physiolibrary.PressureFlow.ResistorWithCond Kf;
Physiolibrary.Factors.SimpleMultiply NephronCountEffect;
Physiolibrary.Blocks.Constant const(k = 20);
Physiolibrary.Semipermeable.ColloidHydraulicPressure colloidHydraulicPressure1(q_in(q(start = 132.696)));
Physiolibrary.PressureFlow.PositivePressureFlow fromAffHydraulic;
Physiolibrary.PressureFlow.NegativePressureFlow Filtration;
Physiolibrary.PressureFlow.NegativePressureFlow toEffHydraulic;
Physiolibrary.Interfaces.RealInput_ Protein_massFlow(final quantity = "Flow", final unit = "g/min");
Physiolibrary.Interfaces.RealInput_ NephronCount_xNormal(final unit = "1");
equation
connect(colloidOsmolarity.q_out, colloidHydraulicPressure.q_in);
connect(colloidOsmolarity.P, colloidHydraulicPressure.hydraulicPressure);
connect(NephronCountEffect.y, Kf.cond);
connect(NephronCountEffect.yBase, const.y);
connect(NephronCountEffect.u, NephronCount_xNormal);
connect(Kf.q_out, Filtration);
connect(Kf.q_in, colloidHydraulicPressure1.q_out);
connect(colloidHydraulicPressure1.q_in, colloidHydraulicPressure.q_in);
connect(colloidOsmolarity.P, colloidHydraulicPressure1.hydraulicPressure);
connect(fromAffHydraulic, colloidHydraulicPressure.withoutCOP);
connect(colloidOsmolarity.q_in, toEffHydraulic);
connect(colloidOsmolarity.proteinMassFlow, Protein_massFlow);
end Glomerulus4;

model Nephron
Physiolibrary.PressureFlow.NegativePressureFlow EfferentArtery_Water_Hydraulic "outgoing plasma from kidneys";
Physiolibrary.PressureFlow.NegativePressureFlow urine "H2O excretion";
Physiolibrary.PressureFlow.ResistorWithCondParam ProximalTubule_Conductance(cond = 7, q_in(pressure(start = 18.9565)));
Physiolibrary.PressureFlow.Reabsorbtion LoopOfHenle;
Physiolibrary.PressureFlow.Reabsorbtion ProximalTubule;
Modelica.Blocks.Math.Gain gain(k = 0.37);
Physiolibrary.Factors.SimpleMultiply ADHEffect;
Physiolibrary.PressureFlow.ReabsorbtionWithMinimalOutflow CollectingDuct;
Modelica.Blocks.Math.Gain gain1(k = 0.5);
Modelica.Blocks.Math.Sum sum1(nin = 4);
Physiolibrary.Factors.SimpleMultiply MedullaNaEffect;
.HumMod.Water.WaterCompartments.Kidney.Glomerulus4 glomerulus;
Physiolibrary.PressureFlow.PositivePressureFlow AfferentArtery_Water_Hydraulic "ingoing plasma to kidney";
CD_H2OChannels H2OChannels(initialActive = 0.969492);
.HumMod.Water.WaterCompartments.Kidney.DistalTubule distalTubule;
Physiolibrary.Blocks.Inv inv1;
Physiolibrary.Blocks.Inv inv2;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure1;
Physiolibrary.Factors.CurveValue NephronADHOnPerm(data = {{0.0, 0.3, 0}, {2.0, 1.0, 0.5}, {10.0, 3.0, 0}});
Physiolibrary.Factors.CurveValue PermOnOutflow(data = {{0.3, 0.0, 0}, {1.0, 0.93, 0.1}, {3.0, 1.0, 0}});
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.Factors.CurveValue NephronADHEffect(data = {{0.0, 0.06, 0}, {2.0, 0.11, 0.02}, {10.0, 0.16, 0}});
Physiolibrary.PressureFlow.FlowMeasure flowMeasure2;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure3;
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Product ProteinsFlow;
Modelica.Blocks.Math.Division conc;
equation
connect(ProximalTubule.Reabsorbtion, EfferentArtery_Water_Hydraulic);
connect(LoopOfHenle.Reabsorbtion, EfferentArtery_Water_Hydraulic);
connect(gain1.y, sum1.u[1]);
connect(MedullaNaEffect.yBase, sum1.y);
connect(distalTubule.Reabsorbtion, EfferentArtery_Water_Hydraulic);
connect(CollectingDuct.Inflow, distalTubule.Outflow);
connect(distalTubule.DesiredFlow, ADHEffect.y);
connect(inv1.y, ADHEffect.u);
connect(inv2.y, MedullaNaEffect.u);
connect(ProximalTubule_Conductance.q_out, ProximalTubule.Inflow);
connect(flowMeasure.q_out, ProximalTubule_Conductance.q_in);
connect(ProximalTubule.Outflow, LoopOfHenle.Inflow);
connect(glomerulus.NephronCount_xNormal, busConnector.Kidney_NephronCount_Total_xNormal);
connect(AfferentArtery_Water_Hydraulic, glomerulus.fromAffHydraulic);
connect(glomerulus.Filtration, flowMeasure.q_in);
connect(glomerulus.toEffHydraulic, EfferentArtery_Water_Hydraulic);
connect(CollectingDuct.Outflow, flowMeasure1.q_in);
connect(flowMeasure1.q_out, urine);
connect(H2OChannels.Active, NephronADHOnPerm.yBase);
connect(NephronADHOnPerm.y, PermOnOutflow.u);
connect(PermOnOutflow.y, CollectingDuct.FractReab);
connect(Constant.y, PermOnOutflow.yBase);
connect(CollectingDuct.Reabsorbtion, H2OChannels.CD_H2O_Reab);
connect(Constant1.y, NephronADHEffect.yBase);
connect(NephronADHEffect.y, inv1.u);
connect(LoopOfHenle.FractReab, gain.y);
connect(CollectingDuct.OutflowMin, MedullaNaEffect.y);
connect(H2OChannels.q_out, flowMeasure2.q_in);
connect(flowMeasure2.q_out, EfferentArtery_Water_Hydraulic);
connect(LoopOfHenle.Outflow, flowMeasure3.q_in);
connect(flowMeasure3.q_out, distalTubule.Inflow);
connect(flowMeasure.actualFlow, busConnector.GlomerulusFiltrate_GFR);
connect(busConnector.NephronADH, NephronADHEffect.u);
connect(busConnector.NephronADH, NephronADHOnPerm.u);
connect(busConnector.DT_Na_Outflow, ADHEffect.yBase);
connect(ProximalTubule.FractReab, busConnector.PT_Na_FractReab);
connect(gain.u, busConnector.LH_Na_FractReab);
connect(flowMeasure1.actualFlow, busConnector.CD_H2O_Outflow);
connect(inv2.u, busConnector.MedullaNa_conc);
connect(busConnector.CD_Glucose_Outflow, gain1.u);
connect(busConnector.CD_NH4_Outflow, sum1.u[2]);
connect(busConnector.CD_K_Outflow, sum1.u[3]);
connect(busConnector.CD_Na_Outflow, sum1.u[4]);
connect(flowMeasure2.actualFlow, busConnector.CD_H2O_Reab);
connect(flowMeasure3.actualFlow, busConnector.LH_H2O_Outflow);
connect(busConnector.KidneyPlasmaFlow, ProteinsFlow.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PlasmaProtein_Mass, conc.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PlasmaVol, conc.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(conc.y, ProteinsFlow.u2);
connect(ProteinsFlow.y, glomerulus.Protein_massFlow);
connect(busConnector.Glomerulus_GFR, flowMeasure.actualFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Nephron;

model Kidney
Physiolibrary.Interfaces.BusConnector busConnector;
.HumMod.Water.WaterCompartments.Kidney.Nephron nephron;
Physiolibrary.Semipermeable.PositiveOsmoticFlow vascularH2O(o(unit = "g/ml"));
Physiolibrary.PressureFlow.NegativePressureFlow urine;
Physiolibrary.Semipermeable.ColloidHydraulicPressure0 colloidhydraulicPressure0_1;
Physiolibrary.PressureFlow.Pump kidneyFlow;
Physiolibrary.Utilities.ConstantFromFile Medulla_Volume(varName = "Medulla.Volume", varValue = 31.0, initType = Physiolibrary.Utilities.Init.NoInit) "Kidney medulla interstitial water volume. [ml]";
equation
connect(nephron.urine, urine);
connect(busConnector.GlomerulusBloodPressure, colloidhydraulicPressure0_1.hydraulicPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(vascularH2O, colloidhydraulicPressure0_1.q_in);
connect(kidneyFlow.q_in, colloidhydraulicPressure0_1.withoutCOP);
connect(busConnector.KidneyPlasmaFlow, kidneyFlow.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(kidneyFlow.q_out, nephron.AfferentArtery_Water_Hydraulic);
connect(colloidhydraulicPressure0_1.withoutCOP, nephron.EfferentArtery_Water_Hydraulic);
connect(busConnector, nephron.busConnector);
connect(Medulla_Volume.y, busConnector.Medulla_Volume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Kidney;
end Kidney;

model GILumen2
Physiolibrary.Semipermeable.NegativeOsmoticFlow vascularH2O(o(unit = "g/l"));
parameter Real Fiber_mass(final quantity = "Mass", final unit = "mOsm") = 0.043;
parameter Real Na_EqToAllConnectedOsm(final unit = "mOsm/mEq") = 2;
parameter Real K_EqToAllConnectedOsm(final unit = "mOsm/mEq") = 2;
HumMod.Water.WaterCompartments.GILumen gILumen(Fiber_mass = Fiber_mass, Na_EqToAllConnectedOsm = Na_EqToAllConnectedOsm, K_EqToAllConnectedOsm = K_EqToAllConnectedOsm, stateName = "GILumenVolume.Mass");
Outtake vomitus;
Outtake diarrhea;
Physiolibrary.Semipermeable.ResistorWithCondParam absorbtion1(cond = 150);
Physiolibrary.PressureFlow.InputPump Diet;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure;
Physiolibrary.Factors.CurveValue DietThirst(data = {{233, 0.0, 0}, {253, 2.0, 0.2}, {313, 30.0, 0}});
Physiolibrary.Blocks.Constant Constant0(k = 1 / 1.44);
Modelica.Blocks.Math.Gain ML_TO_L(k = 1000);
Physiolibrary.Semipermeable.OsmoticPump osmoticPump;
Modelica.Blocks.Math.Gain per_ml(k = 1);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.PressureFlow.FlowMeasure flowMeasure1;
equation
connect(gILumen.outtake, diarrhea.H2OLoss);
connect(gILumen.outtake, vomitus.H2OLoss);
connect(gILumen.absorbtion, absorbtion1.q_in);
connect(absorbtion1.q_out, flowMeasure.q_in);
connect(Constant0.y, DietThirst.yBase);
connect(ML_TO_L.y, DietThirst.u);
connect(flowMeasure.q_out, osmoticPump.q_in);
connect(osmoticPump.q_out, vascularH2O);
connect(per_ml.y, osmoticPump.desiredOsmoles);
connect(busConnector.OsmBody_Osm_conc_CellWalls, per_ml.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenSodium_Mass, gILumen.GILumenSodium_Mass) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Osmreceptors, ML_TO_L.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gILumen.Vol, busConnector.GILumenVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.actualFlow, busConnector.GILumenVolume_Absorption) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.GILumenPotassium_Mass, gILumen.GILumenPotassium_Mass) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenDiarrhea_H2OLoss, diarrhea.outflow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenVomitus_H2OLoss, vomitus.outflow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Diet.q_out, flowMeasure1.q_in);
connect(flowMeasure1.q_out, gILumen.intake);
connect(busConnector.GILumenVolume_Intake, flowMeasure1.actualFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenVomitus_H2OTarget, vomitus.H2OTarget) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenDiarrhea_H2OTarget, diarrhea.H2OTarget) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(DietThirst.y, Diet.desiredFlow);
end GILumen2;

package test
model Bladder_steady
Physiolibrary.PressureFlow.PositivePressureFlow con;
Physiolibrary.PressureFlow.OutputPump bladderVoidFlow;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.VolumeConstant volumeConstant(k = 300);
Physiolibrary.PressureFlow.FlowMeasure flowMeasure;
Physiolibrary.PressureFlow.VolumeCompartement volumeCompartement(stateName = "BladderVolume.Mass", STEADY = false, initialVolume = 300);
equation
connect(con, flowMeasure.q_in);
connect(flowMeasure.q_out, bladderVoidFlow.q_in);
connect(flowMeasure.actualFlow, busConnector.BladderVoidFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.CD_H2O_Outflow, bladderVoidFlow.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(con, volumeCompartement.con);
connect(volumeCompartement.Volume, busConnector.BladderVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Bladder_steady;
end test;

model TorsoExtravascularWater
extends Physiolibrary.Utilities.DynamicState;
Physiolibrary.Semipermeable.NegativeOsmoticFlow q_out(o(final unit = "g"));
parameter Real initialWaterVolume(final quantity = "Volume", unit = "ml");
parameter Real[:, 3] PressureVolume = {{600.0, -30.0, 0.01}, {2400.0, -4.8, 0.0004}, {6000.0, 0.0, 0.0004}, {12000.0, 50.0, 0.01}} "curve of water pressure, that depends on interstitial water volume";
Physiolibrary.Interfaces.RealInput_ NotpermeableSolutes(quantity = "Mass", unit = "g");
Physiolibrary.Interfaces.RealOutput_ WaterVolume(start = initialWaterVolume, final quantity = "Volume", unit = "ml");
Physiolibrary.Interfaces.RealInput_ ICFV(quantity = "Volume", unit = "ml") "intracellular water volume";
Physiolibrary.Interfaces.RealOutput_ ECFV "extracellular water";
Physiolibrary.Curves.Curve PressureVolumeCurve(x = PressureVolume[:, 1], y = PressureVolume[:, 2], slope = PressureVolume[:, 3]) "curve of water hydraulic pressure, that depends on interstitial water volume";
Physiolibrary.Interfaces.RealOutput_ InterstitialPressure "torso interstitial pressure";
equation
ECFV = WaterVolume - ICFV;
q_out.o = if ECFV > 0 then NotpermeableSolutes / ECFV else 0;
stateValue = WaterVolume;
changePerMin = q_out.q;
PressureVolumeCurve.u = ECFV;
connect(PressureVolumeCurve.val, InterstitialPressure);
end TorsoExtravascularWater;

model UT
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Semipermeable.PositiveOsmoticFlow vascularH2O(o(final unit = "g/ml")) "plasma capillary wall osmotic connector";
Modelica.Blocks.Math.Gain MetabolicH2O(k = 1.0 / 4.0);
Real volume;
Real change;
.HumMod.Water.WaterCompartments.CapilaryMembrane capilaryMembrane(CapilaryWallPermeability = 0.27);
.HumMod.Water.WaterCompartments.Lymph lymph(InterstitialPressureOnLymphFlow = {{-14.0, 0.0, 0.0}, {-4.0, 1.0, 0.1}, {2.0, 8.0, 4.0}, {6.0, 25.0, 0.0}}, NormalLymphFlowRate = 0.4);
.HumMod.Water.WaterCompartments.TorsoExtravascularWater extravascularH2O(NotpermeableSolutes(unit = "g"), stateName = "UT_H2O.Vol", PressureVolume = {{600.0, -30.0, 0.01}, {2000.0, -4.8, 0.0004}, {5000.0, 0.0, 0.0004}, {12000.0, 50.0, 0.01}}, initialWaterVolume = 7224.68);
Physiolibrary.Semipermeable.InputPump metabolic;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure1;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure2;
.HumMod.Water.Skin.SweatGland sweatGland;
.HumMod.Water.Skin.InsensibleSkin insensibleSkin(bodyPart = 1.0 / 3.0);
equation
volume = extravascularH2O.WaterVolume;
change = extravascularH2O.q_out.q;
connect(capilaryMembrane.q_out, extravascularH2O.q_out);
connect(lymph.port_a, extravascularH2O.q_out);
connect(extravascularH2O.InterstitialPressure, capilaryMembrane.InterstitialPressure);
connect(extravascularH2O.InterstitialPressure, lymph.InterstitialPressure);
connect(lymph.port_b, vascularH2O);
connect(capilaryMembrane.q_in, vascularH2O);
connect(busConnector.RegionalPressure_UpperCapy, capilaryMembrane.capilaryPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(extravascularH2O.ICFV, busConnector.UT_Cell_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.NotpermeableSolutes, busConnector.UT_InterstitialProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MetabolicH2O.y, metabolic.desiredFlow);
connect(metabolic.q_out, extravascularH2O.q_out);
connect(lymph.LymphFlow, busConnector.UT_LymphFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.ECFV, busConnector.UT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.WaterVolume, busConnector.UT_H2O_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MetabolicH2O.u, busConnector.MetabolicH2O_Rate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure2.q_in, extravascularH2O.q_out);
connect(insensibleSkin.q_out, flowMeasure2.q_out);
connect(sweatGland.q_out, flowMeasure1.q_out);
connect(flowMeasure1.q_in, extravascularH2O.q_out);
connect(busConnector, insensibleSkin.busConnector);
connect(sweatGland.busConnector, busConnector);
connect(flowMeasure1.actualFlow, busConnector.UT_Sweat_H2OOutflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure2.actualFlow, busConnector.UT_InsensibleSkin_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end UT;

model MT
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Semipermeable.PositiveOsmoticFlow vascularH2O(o(final unit = "g/ml")) "plasma capillary wall osmotic connector";
Real volume;
Real change;
.HumMod.Water.InsensibleLungs lungs;
.HumMod.Water.Skin.InsensibleSkin insensibleSkin(bodyPart = 1.0 / 3.0);
.HumMod.Water.WaterCompartments.TorsoExtravascularWater extravascularH2O(NotpermeableSolutes(unit = "g"), initialWaterVolume = 18613, stateName = "MT_H2O.Vol", PressureVolume = {{1200.0, -30.0, 0.01}, {4800.0, -4.8, 0.0004}, {12000.0, 0.0, 0.0004}, {24000.0, 50.0, 0.01}});
.HumMod.Water.WaterCompartments.CapilaryMembrane capilaryMembrane(CapilaryWallPermeability = 0.44);
.HumMod.Water.WaterCompartments.Lymph lymph(NormalLymphFlowRate = 0.8, InterstitialPressureOnLymphFlow = {{-14.0, 0.0, 0.0}, {-4.0, 1.0, 0.1}, {2.0, 8.0, 4.0}, {6.0, 25.0, 0.0}});
Physiolibrary.Semipermeable.FlowMeasure flowMeasure;
.HumMod.Water.Skin.SweatGland sweatGland;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure1;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure2;
Modelica.Blocks.Math.Gain MetabolicH2O(k = 1.0 / 2.0);
Physiolibrary.Semipermeable.InputPump metabolic;
Physiolibrary.Blocks.VolumeConstant lungEdema(k = 0);
.HumMod.Water.WaterCompartments.Peritoneum_const peritoneum_const;
equation
volume = extravascularH2O.WaterVolume;
change = extravascularH2O.q_out.q;
connect(lungs.busConnector, busConnector);
connect(busConnector, insensibleSkin.busConnector);
connect(extravascularH2O.InterstitialPressure, lymph.InterstitialPressure);
connect(extravascularH2O.InterstitialPressure, capilaryMembrane.InterstitialPressure);
connect(extravascularH2O.q_out, lymph.port_a);
connect(extravascularH2O.q_out, capilaryMembrane.q_out);
connect(capilaryMembrane.q_in, vascularH2O);
connect(lymph.port_b, vascularH2O);
connect(extravascularH2O.NotpermeableSolutes, busConnector.MT_InterstitialProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.ICFV, busConnector.MT_Cell_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.WaterVolume, busConnector.MT_H2O_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.ECFV, busConnector.MT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.RegionalPressure_MiddleCapy, capilaryMembrane.capilaryPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(flowMeasure.q_in, extravascularH2O.q_out);
connect(flowMeasure.q_out, lungs.q_out);
connect(sweatGland.q_out, flowMeasure1.q_out);
connect(flowMeasure1.q_in, extravascularH2O.q_out);
connect(flowMeasure.actualFlow, busConnector.HeatInsensibleLung_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(insensibleSkin.q_out, flowMeasure2.q_out);
connect(flowMeasure2.q_in, extravascularH2O.q_out);
connect(flowMeasure2.actualFlow, busConnector.MT_InsensibleSkin_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(sweatGland.busConnector, busConnector);
connect(flowMeasure1.actualFlow, busConnector.MT_Sweat_H2OOutflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MetabolicH2O.y, metabolic.desiredFlow);
connect(MetabolicH2O.u, busConnector.MetabolicH2O_Rate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(metabolic.q_out, extravascularH2O.q_out);
connect(lymph.LymphFlow, busConnector.MT_LymphFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(lungEdema.y, busConnector.ExcessLungWater_Volume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(peritoneum_const.flux, vascularH2O);
connect(peritoneum_const.busConnector, busConnector);
end MT;

model LT
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Semipermeable.PositiveOsmoticFlow vascularH2O(o(final unit = "g/ml")) "plasma capillary wall osmotic connector";
Real volume;
Real change;
.HumMod.Water.WaterCompartments.Lymph lymph(InterstitialPressureOnLymphFlow = {{-14.0, 0.0, 0.0}, {-4.0, 1.0, 0.1}, {2.0, 8.0, 4.0}, {6.0, 25.0, 0.0}}, NormalLymphFlowRate = 1.3);
.HumMod.Water.WaterCompartments.CapilaryMembrane capilaryMembrane(CapilaryWallPermeability = 0.71);
.HumMod.Water.WaterCompartments.TorsoExtravascularWater extravascularH2O(NotpermeableSolutes(unit = "g"), stateName = "LT_H2O.Vol", initialWaterVolume = 10876.6, PressureVolume = {{600.0, -30.0, 0.02}, {3000.0, -4.8, 0.0004}, {4000.0, -4.0, 0.0004}, {6000.0, 50.0, 0.03}});
Physiolibrary.Semipermeable.FlowMeasure flowMeasure1;
Physiolibrary.Semipermeable.FlowMeasure flowMeasure2;
.HumMod.Water.Skin.SweatGland sweatGland;
.HumMod.Water.Skin.InsensibleSkin insensibleSkin(bodyPart = 1.0 / 3.0);
Modelica.Blocks.Math.Gain MetabolicH2O1(k = 1.0 / 4.0);
Physiolibrary.Semipermeable.InputPump metabolic1;
equation
volume = extravascularH2O.WaterVolume;
change = extravascularH2O.q_out.q;
connect(lymph.port_b, vascularH2O);
connect(capilaryMembrane.q_in, vascularH2O);
connect(capilaryMembrane.q_out, extravascularH2O.q_out);
connect(lymph.port_a, extravascularH2O.q_out);
connect(extravascularH2O.InterstitialPressure, capilaryMembrane.InterstitialPressure);
connect(extravascularH2O.InterstitialPressure, lymph.InterstitialPressure);
connect(extravascularH2O.NotpermeableSolutes, busConnector.LT_InterstitialProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.ICFV, busConnector.LT_Cell_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.WaterVolume, busConnector.LT_H2O_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(extravascularH2O.ECFV, busConnector.LT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.RegionalPressure_LowerCapy, capilaryMembrane.capilaryPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(flowMeasure2.q_in, extravascularH2O.q_out);
connect(insensibleSkin.q_out, flowMeasure2.q_out);
connect(sweatGland.q_out, flowMeasure1.q_out);
connect(flowMeasure1.q_in, extravascularH2O.q_out);
connect(busConnector, insensibleSkin.busConnector);
connect(sweatGland.busConnector, busConnector);
connect(flowMeasure2.actualFlow, busConnector.LT_InsensibleSkin_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure1.actualFlow, busConnector.LT_Sweat_H2OOutflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MetabolicH2O1.y, metabolic1.desiredFlow);
connect(metabolic1.q_out, extravascularH2O.q_out);
connect(MetabolicH2O1.u, busConnector.MetabolicH2O_Rate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(lymph.LymphFlow, busConnector.LT_LymphFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end LT;

model Plasma
Physiolibrary.Semipermeable.PositiveOsmoticFlow q_in(o(unit = "g/ml"));
Physiolibrary.Semipermeable.WaterColloidOsmoticCompartment waterColloidOsmoticCompartment(stateName = "PlasmaVol.Vol", initialWaterVolume = 3000.4);
Physiolibrary.Interfaces.BusConnector busConnector;
Real volume;
Real change;
equation
volume = waterColloidOsmoticCompartment.WaterVolume;
change = q_in.q;
connect(busConnector.PlasmaProtein_Mass, waterColloidOsmoticCompartment.NotpermeableSolutes);
connect(waterColloidOsmoticCompartment.q_out, q_in);
connect(waterColloidOsmoticCompartment.WaterVolume, busConnector.PlasmaVol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(waterColloidOsmoticCompartment.WaterVolume, busConnector.PlasmaVol_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Plasma;

model CapilaryMembrane
Physiolibrary.Interfaces.RealInput_ InterstitialPressure(final quantity = "Pressure", final unit = "mmHg") "interstitial pressure";
parameter Real CapilaryWallPermeability(final unit = "ml/(min.mmHg)") = 1 "Capilary wall permeability for water";
Physiolibrary.Semipermeable.PositiveOsmoticFlow q_in(o(final unit = "g/ml")) "plasma capillary wall osmotic connector";
Physiolibrary.Semipermeable.ColloidHydraulicPressure toPressure;
Physiolibrary.Semipermeable.ColloidHydraulicPressure toPressure1;
Physiolibrary.PressureFlow.ResistorWithCondParam CapillaryWall(cond = CapilaryWallPermeability);
Physiolibrary.Interfaces.RealInput_ capilaryPressure(final quantity = "Pressure", final unit = "mmHg") "average capilary hydraulic pressure in torso";
Physiolibrary.Semipermeable.NegativeOsmoticFlow q_out;
equation
connect(toPressure.q_in, q_in);
connect(toPressure.q_out, CapillaryWall.q_in);
connect(CapillaryWall.q_out, toPressure1.q_out);
connect(capilaryPressure, toPressure.hydraulicPressure);
connect(toPressure1.hydraulicPressure, InterstitialPressure);
connect(toPressure1.q_in, q_out);
end CapilaryMembrane;

model Lymph
parameter Boolean CALC_INTERSTITIAL_PRESSURE_FROM_FLOW = false "==STEADY";
parameter Real[:, 3] InterstitialPressureOnLymphFlow = {{-14.0, 0.0, 0.0}, {-4.0, 1.0, 0.1}, {2.0, 8.0, 4.0}, {6.0, 25.0, 0.0}} "dependence between interstitial water hydraulic pressure and lymph flow";
parameter Real NormalLymphFlowRate(final unit = "ml/min") = 0.4;
Physiolibrary.Semipermeable.NegativeOsmoticFlow port_b(o(final unit = "g/ml")) "plasma capillary wall osmotic connector";
Physiolibrary.Interfaces.RealOutput_ LymphFlow(final quantity = "Flow", final unit = "ml/min");
Physiolibrary.Semipermeable.Pump pump;
Physiolibrary.Factors.SplineValue2 InterstitialPressureEffect(data = InterstitialPressureOnLymphFlow, INVERSE = CALC_INTERSTITIAL_PRESSURE_FROM_FLOW);
Physiolibrary.Blocks.FlowConstant flowConstant(k = NormalLymphFlowRate);
Physiolibrary.Semipermeable.PositiveOsmoticFlow port_a;
Physiolibrary.Interfaces.RealInput_ InterstitialPressure(final quantity = "Pressure", final unit = "mmHg") "interstitial pressure";
equation
connect(InterstitialPressureEffect.y, pump.desiredFlow);
connect(flowConstant.y, InterstitialPressureEffect.yBase);
connect(InterstitialPressureEffect.y, LymphFlow);
connect(port_b, pump.q_out);
connect(pump.q_in, port_a);
connect(InterstitialPressureEffect.u, InterstitialPressure);
end Lymph;

model Peritoneum_const
replaceable class Variable = Physiolibrary.Utilities.ConstantFromFile;
Physiolibrary.Semipermeable.PositiveOsmoticFlow flux "plasma proteins concentration";
parameter Real initialVolume(final quantity = "Volume", final unit = "ml") = 0 "initial water in peritoneum";
Physiolibrary.Interfaces.BusConnector busConnector;
Variable PeritoneumSpace_Gain(varName = "PeritoneumSpace.Gain", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit) "Water gain to peritoneum. [ml/min]";
Variable PeritoneumSpace_Volume(varName = "PeritoneumSpace.Volume", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit) "Water in peritoneum. [ml]";
Variable PeritoneumSpace_Loss(varName = "PeritoneumSpace.Loss", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit) "Water flow from peritoneum to plasma. [ml/min]";
equation
flux.q = 0;
connect(PeritoneumSpace_Volume.y, busConnector.PeritoneumSpace_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PeritoneumSpace_Gain.y, busConnector.PeritoneumSpace_Gain) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PeritoneumSpace_Loss.y, busConnector.PeritoneumSpace_Loss) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Peritoneum_const;

model GILumen
extends Physiolibrary.Utilities.DynamicState;
Physiolibrary.Interfaces.RealInput_ GILumenSodium_Mass(final quantity = "Mass", final unit = "mEq") "sodium in gastro intestinal lumen";
Physiolibrary.Interfaces.RealInput_ GILumenPotassium_Mass(final quantity = "Mass", final unit = "mEq") "potasium in gastro intestinal lumen";
Physiolibrary.Semipermeable.NegativeOsmoticFlow absorbtion;
Physiolibrary.VolumeFlow.NegativeVolumeFlow outtake;
Physiolibrary.PressureFlow.PositivePressureFlow intake;
parameter Real Fiber_mass(final quantity = "Mass", final unit = "mOsm") = 0.043;
parameter Real Na_EqToAllConnectedOsm(final unit = "mOsm/mEq") = 2;
parameter Real K_EqToAllConnectedOsm(final unit = "mOsm/mEq") = 2;
Real mass(final quantity = "Volume", final unit = "ml", start = 949.201) "water volume in gastro intestinal lumen";
Real OsmNa;
Real OsmK;
Real Fiber;
Physiolibrary.Interfaces.RealOutput_ Vol;
equation
intake.pressure = 0;
OsmNa = Na_EqToAllConnectedOsm * GILumenSodium_Mass / mass;
OsmK = K_EqToAllConnectedOsm * GILumenPotassium_Mass / mass;
Fiber = Fiber_mass;
absorbtion.o = Fiber + OsmNa + OsmK;
outtake.volume = mass;
Vol = mass;
stateValue = mass;
changePerMin = intake.q + absorbtion.q + outtake.q;
end GILumen;
end WaterCompartments;

package TissuesVolume  "Division of intracellular and interstitial water into tissues"
model Tissue  "compute tissue size from global interstitial and cell H20 volume"
parameter Real FractIFV;
parameter Real FractOrganH2O;
Physiolibrary.Interfaces.RealInput_ InterstitialWater_Vol(final unit = "ml");
Physiolibrary.Interfaces.RealInput_ CellH2O_Vol(final unit = "ml");
Physiolibrary.Interfaces.RealOutput_ LiquidVol(final unit = "ml") "all tissue water volume";
Physiolibrary.Interfaces.RealOutput_ OrganH2O(final unit = "ml") "tissue cells water volume";
Physiolibrary.Interfaces.RealOutput_ InterstitialWater(final unit = "ml") "tissue interstitial water volume";
equation
OrganH2O = FractOrganH2O * CellH2O_Vol;
LiquidVol = FractIFV * InterstitialWater_Vol + OrganH2O;
InterstitialWater = LiquidVol - OrganH2O;
end Tissue;

model Tissues
SkeletalMuscle skeletalMuscle(FractIFV = 0.597041124206978, FractOrganH2O = 0.597041124206978);
Bone bone(FractIFV = 0.075535107692334, FractOrganH2O = 0.075535107692334);
Fat fat(FractIFV = 0.0686793125415955, FractOrganH2O = 0.0686793125415955);
Brain brain(FractIFV = 0.0213850278381526, FractOrganH2O = 0.0213850278381526);
.HumMod.Water.TissuesVolume.RightHeart rightHeart(FractIFV = 0.000711479063056408, FractOrganH2O = 0.000711479063056408);
RespiratoryMuscle respiratoryMuscle(FractIFV = 0.0671126519181567, FractOrganH2O = 0.0671126519181567);
OtherTissue otherTissue(FractIFV = 0.0670823116596042, FractOrganH2O = 0.0670823116596042);
Liver liver(FractIFV = 0.0284998184687167, FractOrganH2O = 0.0284998184687167);
.HumMod.Water.TissuesVolume.LeftHeart leftHeart(FractIFV = 0.00426887437833845, FractOrganH2O = 0.00426887437833845);
.HumMod.Water.TissuesVolume.Kidney kidney(FractIFV = 0.00471608978940247, FractOrganH2O = 0.00471608978940247);
.HumMod.Water.TissuesVolume.GITract gITract(FractIFV = 0.0234991370540916, FractOrganH2O = 0.0234991370540916);
Physiolibrary.Interfaces.BusConnector busConnector;
Skin skin(FractIFV = 0.0414690653895735, FractOrganH2O = 0.0414690653895735);
equation
connect(busConnector.InterstitialWater_Vol, bone.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, brain.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, fat.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, gITract.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, kidney.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, leftHeart.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, liver.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, otherTissue.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, respiratoryMuscle.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, rightHeart.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, skin.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.InterstitialWater_Vol, skeletalMuscle.InterstitialWater_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, bone.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, brain.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, fat.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, gITract.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, kidney.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, leftHeart.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, liver.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, otherTissue.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, respiratoryMuscle.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, rightHeart.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, skin.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.CellH2O_Vol, skeletalMuscle.CellH2O_Vol) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(bone.LiquidVol, busConnector.bone_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.LiquidVol, busConnector.brain_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.LiquidVol, busConnector.fat_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITract.LiquidVol, busConnector.GITract_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.LiquidVol, busConnector.kidney_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.LiquidVol, busConnector.leftHeart_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.LiquidVol, busConnector.liver_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.LiquidVol, busConnector.otherTissue_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.LiquidVol, busConnector.respiratoryMuscle_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.LiquidVol, busConnector.rightHeart_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.LiquidVol, busConnector.skin_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.LiquidVol, busConnector.skeletalMuscle_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.LiquidVol, busConnector.Bone_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.LiquidVol, busConnector.Brain_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.LiquidVol, busConnector.Fat_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.LiquidVol, busConnector.Kidney_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.LiquidVol, busConnector.LeftHeart_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.LiquidVol, busConnector.Liver_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.LiquidVol, busConnector.OtherTissue_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.LiquidVol, busConnector.RespiratoryMuscle_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.LiquidVol, busConnector.RightHeart_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.LiquidVol, busConnector.Skin_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.LiquidVol, busConnector.SkeletalMuscle_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.OrganH2O, busConnector.bone_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.OrganH2O, busConnector.brain_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.OrganH2O, busConnector.fat_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITract.OrganH2O, busConnector.GITract_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.OrganH2O, busConnector.kidney_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.OrganH2O, busConnector.leftHeart_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.OrganH2O, busConnector.liver_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.OrganH2O, busConnector.otherTissue_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.OrganH2O, busConnector.respiratoryMuscle_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.OrganH2O, busConnector.rightHeart_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.OrganH2O, busConnector.skin_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.OrganH2O, busConnector.skeletalMuscle_CellH2OVol) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.InterstitialWater, busConnector.bone_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.InterstitialWater, busConnector.brain_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.InterstitialWater, busConnector.fat_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITract.InterstitialWater, busConnector.GITract_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.InterstitialWater, busConnector.kidney_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.InterstitialWater, busConnector.leftHeart_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.InterstitialWater, busConnector.liver_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.InterstitialWater, busConnector.otherTissue_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.InterstitialWater, busConnector.respiratoryMuscle_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.InterstitialWater, busConnector.rightHeart_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.InterstitialWater, busConnector.skin_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.InterstitialWater, busConnector.skeletalMuscle_InterstitialWater) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
end Tissues;

model SkeletalMuscle
extends Tissue;
end SkeletalMuscle;

model Bone
extends Tissue;
end Bone;

model OtherTissue
extends Tissue;
end OtherTissue;

model RespiratoryMuscle
extends Tissue;
end RespiratoryMuscle;

model Fat
extends Tissue;
end Fat;

model Skin
extends Tissue;
end Skin;

model Liver
extends Tissue;
end Liver;

model Brain
extends Tissue;
end Brain;

model GITract
extends Tissue;
end GITract;

model Kidney
extends Tissue;
end Kidney;

model LeftHeart
extends Tissue;
end LeftHeart;

model RightHeart
extends Tissue;
end RightHeart;
end TissuesVolume;

model WaterProperties
Osmoles.OsmBody osmBody(ECFV(start = 14600)) "intra/extracellular water";
Hydrostatics.Hydrostatics hydrostatics;
Modelica.Blocks.Math.Feedback sub;
Physiolibrary.Blocks.Parts CellH2O(nout = 3, w = {0.2, 0.5, 0.3});
Modelica.Blocks.Math.Sum BodyH2O1(nin = 6);
Physiolibrary.Interfaces.BusConnector busConnector;
TissuesVolume.Tissues tissues;
Modelica.Blocks.Math.Sum InterstitialWater(nin = 3);
Modelica.Blocks.Math.Sum ExternalH2O(nin = 3);
Modelica.Blocks.Math.Sum IntravascularVol(nin = 2);
Modelica.Blocks.Math.Sum ExtravascularVol(nin = 3);
Modelica.Blocks.Math.Sum BodyH2O(nin = 2);
Modelica.Blocks.Math.Sum BodyH2O_Gain(nin = 4);
Modelica.Blocks.Math.Feedback BodyH2O_Change;
Modelica.Blocks.Math.Sum BodyH2O_Loss(nin = 8);
Modelica.Blocks.Math.Sum sweatDuct(nin = 3);
Modelica.Blocks.Math.Sum insensibleSkin(nin = 3);
equation
connect(hydrostatics.RegionalPressure_UpperCapy, busConnector.RegionalPressure_UpperCapy);
connect(hydrostatics.RegionalPressure_MiddleCapy, busConnector.RegionalPressure_MiddleCapy);
connect(hydrostatics.RegionalPressure_LowerCapy, busConnector.RegionalPressure_LowerCapy);
connect(osmBody.ICFV, sub.u1);
connect(sub.y, CellH2O.u);
connect(CellH2O.y[1], busConnector.UT_Cell_H2O);
connect(CellH2O.y[2], busConnector.MT_Cell_H2O);
connect(CellH2O.y[3], busConnector.LT_Cell_H2O);
connect(BodyH2O1.y, osmBody.BodyH2O_Vol);
connect(osmBody.OsmBody_Osm_conc_CellWalls, busConnector.OsmBody_Osm_conc_CellWalls);
connect(busConnector.Status_Posture, hydrostatics.Status_Posture) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.SystemicArtys_Pressure, hydrostatics.SystemicArtys_Pressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RightAtrium_Pressure, hydrostatics.RightAtrium_Pressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LegMusclePump_Effect, hydrostatics.LegMusclePump_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OsmECFV_Electrolytes, osmBody.OsmECFV_Electrolytes) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OsmCell_Electrolytes, osmBody.OsmCell_Electrolytes) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RBCH2O_Vol, sub.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector, tissues.busConnector);
connect(sub.y, busConnector.CellH2O_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(InterstitialWater.y, busConnector.InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(osmBody.ECFV, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(BodyH2O1.y, busConnector.BodyH2O_Vol);
connect(osmBody.ICFV, busConnector.ICFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(osmBody.Osmoreceptors, busConnector.Osmreceptors) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.UreaECF_Osmoles, osmBody.UreaECF) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.UreaICF_Osmoles, osmBody.UreaICF) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GlucoseECF_Osmoles, osmBody.GlucoseECF) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PlasmaVol, BodyH2O1.u[1]);
connect(busConnector.LT_H2O_Vol, BodyH2O1.u[2]);
connect(busConnector.MT_H2O_Vol, BodyH2O1.u[3]);
connect(busConnector.UT_H2O_Vol, BodyH2O1.u[4]);
connect(busConnector.RBCH2O_Vol, BodyH2O1.u[5]);
connect(ExternalH2O.y, BodyH2O1.u[6]);
connect(busConnector.UT_InterstitialWater_Vol, InterstitialWater.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MT_InterstitialWater_Vol, InterstitialWater.u[2]);
connect(busConnector.LT_InterstitialWater_Vol, InterstitialWater.u[3]);
connect(busConnector.ExcessLungWater_Volume, ExternalH2O.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.GILumenVolume_Mass, ExternalH2O.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 2}, {-6, 2}}));
connect(busConnector.PeritoneumSpace_Vol, ExternalH2O.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(busConnector.PlasmaVol, IntravascularVol.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.RBCH2O_Vol, IntravascularVol.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, -2}, {-6, -2}}));
connect(ExternalH2O.y, ExtravascularVol.u[1]);
connect(busConnector.CellH2O_Vol, ExtravascularVol.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.InterstitialWater_Vol, ExtravascularVol.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -2}, {-6, -2}}));
connect(ExtravascularVol.y, BodyH2O.u[1]);
connect(IntravascularVol.y, BodyH2O.u[2]);
connect(BodyH2O_Gain.y, BodyH2O_Change.u1);
connect(BodyH2O_Loss.y, BodyH2O_Change.u2);
connect(busConnector.GILumenVolume_Intake, BodyH2O_Gain.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 5}, {-6, 5}}));
connect(busConnector.MetabolicH2O_Rate, BodyH2O_Gain.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 2}, {-6, 2}}));
connect(busConnector.IVDrip_H2ORate, BodyH2O_Gain.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -1}, {-6, -1}}));
connect(busConnector.Transfusion_H2ORate, BodyH2O_Gain.u[4]) annotation(Text(string = "%first", index = -1, extent = {{-6, -4}, {-6, -4}}));
connect(busConnector.CD_H2O_Outflow, BodyH2O_Loss.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 12}, {-6, 12}}));
connect(busConnector.SweatDuct_H2OOutflow, BodyH2O_Loss.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 9}, {-6, 9}}));
connect(busConnector.Hemorrhage_H2ORate, BodyH2O_Loss.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.DialyzerActivity_UltrafiltrationRate, BodyH2O_Loss.u[4]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.HeatInsensibleSkin_H2O, BodyH2O_Loss.u[5]) annotation(Text(string = "%first", index = -1, extent = {{-6, 0}, {-6, 0}}));
connect(busConnector.HeatInsensibleLung_H2O, BodyH2O_Loss.u[6]) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(busConnector.GILumenVomitus_H2OLoss, BodyH2O_Loss.u[7]) annotation(Text(string = "%first", index = -1, extent = {{-6, -6}, {-6, -6}}));
connect(busConnector.GILumenDiarrhea_H2OLoss, BodyH2O_Loss.u[8]) annotation(Text(string = "%first", index = -1, extent = {{-6, -9}, {-6, -9}}));
connect(busConnector.UT_Sweat_H2OOutflow, sweatDuct.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MT_Sweat_H2OOutflow, sweatDuct.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LT_Sweat_H2OOutflow, sweatDuct.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(insensibleSkin.y, busConnector.HeatInsensibleSkin_H2O) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.UT_InsensibleSkin_H2O, insensibleSkin.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MT_InsensibleSkin_H2O, insensibleSkin.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LT_InsensibleSkin_H2O, insensibleSkin.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(sweatDuct.y, busConnector.SweatGland_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end WaterProperties;

package Skin
model SweatGland
parameter Real bodyPart = 1 / 3;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Semipermeable.NegativeOsmoticFlow q_out;
Physiolibrary.Semipermeable.OutputPump sweat;
Physiolibrary.Blocks.Constant fractConstant(k = bodyPart);
Physiolibrary.Factors.SimpleMultiply BodyPart;
equation
connect(sweat.q_in, q_out);
connect(busConnector.SweatDuct_H2OOutflow, BodyPart.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(fractConstant.y, BodyPart.u);
connect(BodyPart.y, sweat.desiredFlow);
end SweatGland;

model InsensibleSkin
parameter Real bodyPart = 1 / 3;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.FlowConstant H2OReab1(k = 0.37 * bodyPart);
Physiolibrary.Semipermeable.NegativeOsmoticFlow q_out;
Physiolibrary.Semipermeable.OutputPump vapor;
equation
connect(vapor.q_in, q_out);
connect(H2OReab1.y, vapor.desiredFlow);
end InsensibleSkin;
end Skin;

model InsensibleLungs
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Product product;
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Product product1;
Physiolibrary.Blocks.PressureConstant pressureConstant(k = 47);
Physiolibrary.Blocks.Constant Constant(k = 0.0008);
Physiolibrary.Semipermeable.OutputPump vapor;
Physiolibrary.Semipermeable.NegativeOsmoticFlow q_out;
equation
connect(busConnector.BarometerPressure, division.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(product1.y, division.u1);
connect(feedback.y, product1.u2);
connect(pressureConstant.y, feedback.u1);
connect(busConnector.EnvironmentRelativeHumidity, feedback.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(product.y, product1.u1);
connect(busConnector.BreathingTotalVentilation, product.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant.y, product.u1);
connect(vapor.q_in, q_out);
connect(division.y, vapor.desiredFlow);
end InsensibleLungs;

model Water2
.HumMod.Water.WaterCompartments.Plasma plasma;
Physiolibrary.Semipermeable.OutputPump Hemorrhage;
Physiolibrary.Semipermeable.InputPump Transfusion;
Physiolibrary.Semipermeable.InputPump IVDrip;
Physiolibrary.Interfaces.BusConnector busConnector;
.HumMod.Water.WaterCompartments.UT UpperTorso;
.HumMod.Water.WaterCompartments.MT MiddleTorso;
.HumMod.Water.WaterCompartments.LT LowerTorso;
.HumMod.Water.WaterCompartments.GILumen2 GILumen;
.HumMod.Water.WaterCompartments.Kidney.Kidney Kidney;
HumMod.Water.WaterCompartments.test.Bladder_steady Bladder;
.HumMod.Water.WaterProperties waterProperties;
.HumMod.Hormones.ADH antidiureticHormone;
equation
connect(IVDrip.desiredFlow, busConnector.IVDrip_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion.desiredFlow, busConnector.Transfusion_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage.desiredFlow, busConnector.Hemorrhage_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(plasma.q_in, Hemorrhage.q_in);
connect(plasma.q_in, Transfusion.q_out);
connect(IVDrip.q_out, plasma.q_in);
connect(Kidney.urine, Bladder.con);
connect(busConnector, Kidney.busConnector);
connect(busConnector, waterProperties.busConnector);
connect(UpperTorso.busConnector, busConnector);
connect(MiddleTorso.busConnector, busConnector);
connect(LowerTorso.busConnector, busConnector);
connect(busConnector, GILumen.busConnector);
connect(Bladder.busConnector, busConnector);
connect(busConnector, plasma.busConnector);
connect(plasma.q_in, UpperTorso.vascularH2O);
connect(plasma.q_in, MiddleTorso.vascularH2O);
connect(plasma.q_in, LowerTorso.vascularH2O);
connect(plasma.q_in, Kidney.vascularH2O);
connect(GILumen.vascularH2O, plasma.q_in);
connect(antidiureticHormone.busConnector, busConnector);
end Water2;
end Water;

package Proteins  "Body Proteins"

model Proteins
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ResistorWithCondParam UT_Capillary(cond = 0.22);
Physiolibrary.ConcentrationFlow.ResistorWithCondParam MT_Capillary(cond = 0.44);
Physiolibrary.ConcentrationFlow.ResistorWithCondParam LT_Capillary(cond = 0.71);
Physiolibrary.ConcentrationFlow.OutputPump Hemorrhage;
Physiolibrary.ConcentrationFlow.InputPump Transfusion;
Physiolibrary.ConcentrationFlow.InputPump IVDrip;
Physiolibrary.ConcentrationFlow.SolventFlowPump UT_Lymph;
Physiolibrary.ConcentrationFlow.SolventFlowPump MT_Lymph;
Physiolibrary.ConcentrationFlow.SolventFlowPump LT_Lymph;
Physiolibrary.ConcentrationFlow.SolventFlowPump Change;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment plasma(initialSoluteMass = 211.361, stateName = "PlasmaProtein.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationCompartment UpperTorso(initialSoluteMass = 74.3639, stateName = "UT_InterstitialProtein.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationCompartment MiddleTorso(initialSoluteMass = 148.686, stateName = "MT_InterstitialProtein.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationCompartment LowerTorso(initialSoluteMass = 76.11499999999999, stateName = "LT_InterstitialProtein.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationCompartment peritoneum(initialSoluteMass = 0, stateName = "PeritoneumProtein.Mass", STEADY = false);
Physiolibrary.ConcentrationFlow.Synthesis synthesis(SynthesisBasic = 0.01);
Physiolibrary.ConcentrationFlow.Degradation degradation(DegradationBasic = 0.01);
Physiolibrary.ConcentrationFlow.ResistorWithCondParam GlomerulusProtein_Perm(cond = 0);
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Bladder(stateName = "BladderProtein.Mass", STEADY = false, initialSoluteMass = 0);
Physiolibrary.Blocks.Parts alb_glb(nout = 2, w = {60, 40}) "distribution to albumins(60%) and globulins(40%) ";
Modelica.Blocks.Math.Gain alb_molar_mass(y(unit = "mmol/l"), k(unit = "mmol/g") = 1 / 66.438, u(unit = "g/l"));
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "g/l", toAnotherUnitCoef = 1000);
Modelica.Blocks.Math.Feedback PeritoneumChange;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "g/ml", toAnotherUnitCoef = 1);
Physiolibrary.Utilities.ConstantFromFile NBB(varName = "BloodIons.Protein", varValue = 15.0835337930175, initType = Physiolibrary.Utilities.Init.NoInit);
equation
connect(Transfusion.desiredFlow, busConnector.Transfusion_ProteinRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(IVDrip.desiredFlow, busConnector.IVDripProteinRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Hemorrhage_ProteinRate, Hemorrhage.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(UpperTorso.SolventVolume, busConnector.UT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(MiddleTorso.SolventVolume, busConnector.MT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LowerTorso.SolventVolume, busConnector.LT_InterstitialWater_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.PeritoneumSpace_Vol, peritoneum.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LT_LymphFlow, LT_Lymph.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MT_LymphFlow, MT_Lymph.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.UT_LymphFlow, UT_Lymph.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LT_InterstitialProtein_Mass, LowerTorso.soluteMass) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.MT_InterstitialProtein_Mass, MiddleTorso.soluteMass) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.UT_InterstitialProtein_Mass, UpperTorso.soluteMass) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(plasma.soluteMass, busConnector.PlasmaProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(synthesis.q_out, plasma.q_out);
connect(UT_Capillary.q_out, UpperTorso.q_out);
connect(UT_Lymph.q_in, UpperTorso.q_out);
connect(plasma.q_out, UT_Capillary.q_in);
connect(plasma.q_out, UT_Lymph.q_out);
connect(plasma.q_out, MT_Capillary.q_in);
connect(MT_Capillary.q_out, MiddleTorso.q_out);
connect(MT_Lymph.q_in, MiddleTorso.q_out);
connect(plasma.q_out, MT_Lymph.q_out);
connect(plasma.q_out, LT_Capillary.q_in);
connect(plasma.q_out, LT_Lymph.q_out);
connect(plasma.q_out, GlomerulusProtein_Perm.q_in);
connect(plasma.q_out, Hemorrhage.q_in);
connect(plasma.q_out, Transfusion.q_out);
connect(plasma.q_out, IVDrip.q_out);
connect(plasma.q_out, degradation.q_in);
connect(plasma.q_out, Change.q_in);
connect(LT_Capillary.q_out, LowerTorso.q_out);
connect(LT_Lymph.q_in, LowerTorso.q_out);
connect(Change.q_out, peritoneum.q_out);
connect(GlomerulusProtein_Perm.q_out, Bladder.q_out);
connect(alb_molar_mass.u, alb_glb.y[1]);
connect(alb_molar_mass.y, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(alb_glb.y[2], busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{6, -3}, {6, -3}}));
connect(concentrationMeasure.actualConc, alb_glb.u);
connect(concentrationMeasure.q_in, plasma.q_out);
connect(busConnector.PeritoneumSpace_Gain, PeritoneumChange.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PeritoneumSpace_Loss, PeritoneumChange.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(PeritoneumChange.y, Change.solventFlow);
connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(plasma.q_out, concentrationMeasure1.q_in);
connect(concentrationMeasure1.actualConc, busConnector.PlasmaProteinConc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(plasma.SolventVolume, busConnector.PlasmaVol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(NBB.y, busConnector.BloodIons_ProteinAnions) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Proteins;
end Proteins;

package Electrolytes  "Body Electrolytes"

package Sodium  "Body Sodium Distribution"
model GlomerulusCationFiltration
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.Interfaces.RealInput_ otherCations(final quantity = "Concentration", final unit = "mEq/l");
Physiolibrary.Interfaces.RealInput_ ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
Real KAdjustment;
Real Cations(final quantity = "Concentration", final unit = "mEq/l");
Real Anions(final quantity = "Concentration", final unit = "mEq/l");
equation
q_in.q + q_out.q = 0;
Cations = q_in.conc * 1000 + otherCations;
Anions = Cations;
KAdjustment = (Cations - (Anions - ProteinAnions)) / (Cations + Anions - ProteinAnions);
q_out.conc = (1 - KAdjustment) * q_in.conc;
end GlomerulusCationFiltration;

model Sodium
Physiolibrary.ConcentrationFlow.ConcentrationCompartment NaPool(initialSoluteMass = 2058.45, stateName = "NaPool.Mass");
Physiolibrary.ConcentrationFlow.OutputPump Hemorrhage;
Physiolibrary.ConcentrationFlow.OutputPump DialyzerActivity;
Physiolibrary.ConcentrationFlow.InputPump IVDrip;
Physiolibrary.ConcentrationFlow.InputPump Transfusion;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.BusConnector busConnector;
Real ECF_conc;
SweatGlandSalt sweatGlandSalt;
GILumen gILumen;
.HumMod.Electrolytes.Bladder bladder(stateVarName = "BladderSodium.Mass");
.HumMod.Electrolytes.Sodium.KidneyNa kidneyNa;
equation
ECF_conc = concentrationMeasure1.actualConc;
connect(NaPool.SolventVolume, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage.q_in, NaPool.q_out);
connect(DialyzerActivity.q_in, NaPool.q_out);
connect(Transfusion.q_out, NaPool.q_out);
connect(IVDrip.q_out, NaPool.q_out);
connect(IVDrip.desiredFlow, busConnector.IVDrip_NaRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion.desiredFlow, busConnector.Transfusion_NaRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Hemorrhage_NaRate, Hemorrhage.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_Na_Flux) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(concentrationMeasure1.q_in, NaPool.q_out);
connect(concentrationMeasure1.actualConc, busConnector.NaPool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(NaPool.q_out, sweatGlandSalt.salt);
connect(gILumen.busConnector, busConnector);
connect(gILumen.q_out, NaPool.q_out);
connect(bladder.busConnector, busConnector);
connect(busConnector, sweatGlandSalt.busConnector);
connect(kidneyNa.q_out, bladder.q_in);
connect(kidneyNa.q_in, NaPool.q_out);
connect(kidneyNa.busConnector, busConnector);
connect(NaPool.soluteMass, busConnector.NaPool_mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Sodium;

model GILumen
Physiolibrary.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 80, stateName = "GILumenSodium.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion;
Modelica.Blocks.Math.Gain Perm(k = 0.0015);
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.ConcentrationFlow.OutputPump Diarrhea;
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.Blocks.Constant Constant7(k = 180 / 1440);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
equation
connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(GILumen.q_out, Absorbtion.q_in);
connect(Diet.q_out, GILumen.q_out);
connect(Diarrhea.desiredFlow, busConnector.GILumenDiarrhea_NaLoss) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(GILumen.q_out, Diarrhea.q_in);
connect(GILumen.soluteMass, Perm.u);
connect(Perm.y, Absorbtion.soluteFlow);
connect(GILumen.soluteMass, busConnector.GILumenSodium_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(LeptinEffect2.y, Diet.desiredFlow);
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Absorbtion.q_out, q_out);
end GILumen;

model KidneyNa
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "sodium concentration in blood incomming to glomerulus capillaries; sodium mass flow is filtration - reabsorbtion";
Physiolibrary.ConcentrationFlow.SolventFlowPump_InitialPatch glomerulusSudiumRate;
Physiolibrary.ConcentrationFlow.FractReabsorbtion PT;
Physiolibrary.Blocks.FractConstant const1(k = 58);
Physiolibrary.Factors.CurveValue IFPEffect(data = {{1.0, 1.4, 0}, {4.0, 1.0, -0.2}, {7.0, 0.3, 0}});
Physiolibrary.Factors.CurveValue ANPEffect(data = {{0.0, 1.2, 0}, {1.3, 1.0, -0.2}, {2.7, 0.6, 0}});
Physiolibrary.Factors.CurveValue SympsEffect(data = {{0.6, 0.6, 0}, {1.0, 1.0, 0.5}, {4.0, 1.5, 0}});
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.7, 0.8, 0}, {1.3, 1.0, 0.8}, {1.6, 1.2, 0}});
Physiolibrary.ConcentrationFlow.FractReabsorbtion LH(MaxReab = 7);
Physiolibrary.Blocks.FractConstant const2(k = 75);
Physiolibrary.ConcentrationFlow.FractReabsorbtion2 DT;
Physiolibrary.ConcentrationFlow.FractReabsorbtion CD(MaxReab = 0.7);
Physiolibrary.Blocks.FractConstant const3(k = 75);
Physiolibrary.Blocks.FractConstant const4(k = 75);
Physiolibrary.Factors.CurveValue Furosemide(data = {{0.0, 1.0, -1}, {0.1, 0.0, 0}});
Physiolibrary.Factors.CurveValue AldoEffect(data = {{0.0, 0.7, 0}, {10.0, 1.0, 0}});
Physiolibrary.Factors.CurveValue LoadEffect(data = {{0.0, 3.0, 0}, {7.2, 1.0, -0.2}, {20.0, 0.5, 0}});
Physiolibrary.Factors.SimpleMultiply FurosemideEffect;
Physiolibrary.Factors.SimpleMultiply Filtering_xNormal;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure1;
Physiolibrary.Factors.CurveValue LoadEffect1(data = {{0.0, 2.0, 0}, {1.6, 1.0, 0}});
Physiolibrary.Factors.CurveValue ThiazideEffect(data = {{0.0, 1.0, -2.0}, {0.6, 0.2, 0.0}});
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure2;
Physiolibrary.Factors.CurveValue LoadEffect2(data = {{0.0, 2.0, 0}, {0.4, 1.0, 0}});
Physiolibrary.Factors.CurveValue ANPEffect2(data = {{0.0, 1.2, 0}, {1.3, 1.0, -0.4}, {2.7, 0.2, 0}});
Physiolibrary.Factors.SimpleMultiply AldoEffect2;
Physiolibrary.Blocks.Constant const5(k = 2);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure3;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Medulla(stateName = "MedullaNa.Mass", initialSoluteMass = 13);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
Physiolibrary.ConcentrationFlow.SolventFlowPump VasaRectaOutflow;
Modelica.Blocks.Math.Gain gain(k = 0.03);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure4;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure5;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure6;
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Gain Osm(k = 2);
Physiolibrary.Factors.CurveValue AldoEffect1(data = {{0.0, 0.5, 0}, {12.0, 1.0, 0.08}, {50.0, 3.0, 0}});
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Gain ml2l(k = 1000);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2(unitsString = "mEq/ml", toAnotherUnitCoef = 1);
GlomerulusCationFiltration glomerulus;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "sodium mass outflow to urine from collecting ducts";
equation
connect(glomerulusSudiumRate.solventFlow, busConnector.GlomerulusFiltrate_GFR) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(glomerulusSudiumRate.q_out, PT.Inflow);
connect(const1.y, PT.Normal);
connect(A2Effect.yBase, busConnector.KidneyFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(A2Effect.y, SympsEffect.yBase);
connect(SympsEffect.y, ANPEffect.yBase);
connect(ANPEffect.y, IFPEffect.yBase);
connect(IFPEffect.y, PT.Effects);
connect(busConnector.A2Pool_Log10Conc, A2Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(SympsEffect.u, busConnector.KidneyAlpha_PT_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.NephronANP_Log10Conc, ANPEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.NephronIFP_Pressure, IFPEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(const2.y, LH.Normal);
connect(const3.y, CD.Normal);
connect(const4.y, DT.Normal);
connect(Furosemide.u, busConnector.FurosemidePool_Furosemide_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AldoEffect.y, LoadEffect.yBase);
connect(LoadEffect.y, LH.Effects);
connect(FurosemideEffect.y, AldoEffect.yBase);
connect(Filtering_xNormal.u, busConnector.Kidney_NephronCount_Filtering_xNormal) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Filtering_xNormal.y, FurosemideEffect.u);
connect(Furosemide.y, Filtering_xNormal.yBase);
connect(busConnector.KidneyFunctionEffect, Furosemide.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(FurosemideEffect.yBase, busConnector.KidneyFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PT.Outflow, flowMeasure.q_in);
connect(flowMeasure.q_out, LH.Inflow);
connect(flowMeasure.actualFlow, LoadEffect.u);
connect(DT.Inflow, flowMeasure1.q_out);
connect(flowMeasure1.q_in, LH.Outflow);
connect(LoadEffect1.y, DT.Effects);
connect(LoadEffect1.u, flowMeasure1.actualFlow);
connect(ThiazideEffect.u, busConnector.ThiazidePool_Thiazide_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CD.Inflow, flowMeasure2.q_out);
connect(flowMeasure2.q_in, DT.Outflow);
connect(LoadEffect2.y, CD.Effects);
connect(LoadEffect2.u, flowMeasure2.actualFlow);
connect(ANPEffect2.y, LoadEffect2.yBase);
connect(ANPEffect2.yBase, busConnector.KidneyFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ANPEffect2.u, busConnector.NephronANP_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(const5.y, AldoEffect2.yBase);
connect(AldoEffect2.y, DT.MaxReab);
connect(CD.Outflow, flowMeasure3.q_in);
connect(CD.Reabsorbtion, Medulla.q_out);
connect(Medulla.q_out, concentrationMeasure.q_in);
connect(Medulla.q_out, VasaRectaOutflow.q_in);
connect(gain.y, VasaRectaOutflow.solventFlow);
connect(busConnector.VasaRecta_Outflow, gain.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Medulla.SolventVolume, busConnector.Medulla_Volume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AldoEffect1.y, busConnector.DT_AldosteroneEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(DT.Reabsorbtion, flowMeasure4.q_in);
connect(flowMeasure5.actualFlow, busConnector.LH_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LH.Reabsorbtion, flowMeasure5.q_in);
connect(flowMeasure6.actualFlow, busConnector.PT_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PT.Reabsorbtion, flowMeasure6.q_in);
connect(concentrationMeasure.actualConc, Osm.u);
connect(Osm.y, busConnector.MedullaNa_Osmolarity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.KidneyFunctionEffect, AldoEffect1.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AldoEffect1.y, ThiazideEffect.yBase);
connect(ThiazideEffect.y, LoadEffect1.yBase);
connect(AldoEffect1.y, AldoEffect2.u);
connect(LH.ReabFract, busConnector.LH_Na_FractReab) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PT.ReabFract, busConnector.PT_Na_FractReab) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure2.actualFlow, busConnector.DT_Na_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure3.actualFlow, busConnector.CD_Na_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure4.actualFlow, busConnector.DT_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure1.actualFlow, division.u1);
connect(busConnector.LH_H2O_Outflow, division.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(ml2l.u, division.y);
connect(ml2l.y, busConnector.MD_Na) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.NephronAldo_conc_in_nG_per_dl, AldoEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.NephronAldo_conc_in_nG_per_dl, AldoEffect1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Medulla.q_out, concentrationMeasure2.q_in);
connect(concentrationMeasure2.actualConc, busConnector.MedullaNa_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(glomerulus.ProteinAnions, busConnector.BloodIons_ProteinAnions) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(glomerulusSudiumRate.q_in, glomerulus.q_out);
connect(glomerulus.q_in, q_in);
connect(flowMeasure6.q_out, q_in);
connect(flowMeasure5.q_out, q_in);
connect(flowMeasure4.q_out, q_in);
connect(VasaRectaOutflow.q_out, q_in);
connect(flowMeasure3.q_out, q_out);
connect(busConnector.KAPool_conc_per_liter, glomerulus.otherCations) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end KidneyNa;
end Sodium;

package Potassium  "Body Potassium Distribution"
model Potassium
Physiolibrary.ConcentrationFlow.ConcentrationCompartment KPool(initialSoluteMass = 62.897, stateName = "KPool.Mass");
Physiolibrary.ConcentrationFlow.OutputPump Hemorrhage;
Physiolibrary.ConcentrationFlow.OutputPump DialyzerActivity;
Physiolibrary.ConcentrationFlow.InputPump IVDrip;
Physiolibrary.ConcentrationFlow.InputPump Transfusion;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.BusConnector busConnector;
GILumenK gILumenK;
.HumMod.Electrolytes.Bladder bladder(stateVarName = "BladderPotassium.Mass");
.HumMod.Electrolytes.Potassium.KindeyK kindeyK;
Real ECF_conc;
.HumMod.Electrolytes.SweatGlandSalt sweatGlandSalt(FractReabBasic = 0, FractReabK = 0);
.HumMod.Electrolytes.Potassium.IntracellularPotassium_const intracellularPotassium;
equation
ECF_conc = concentrationMeasure2.actualConc;
connect(KPool.SolventVolume, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(Hemorrhage.q_in, KPool.q_out);
connect(DialyzerActivity.q_in, KPool.q_out);
connect(Transfusion.q_out, KPool.q_out);
connect(IVDrip.q_out, KPool.q_out);
connect(IVDrip.desiredFlow, busConnector.IVDrip_KRate) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(Transfusion.desiredFlow, busConnector.Transfusion_KRate) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(busConnector.Hemorrhage_KRate, Hemorrhage.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-3, 1}, {-3, 1}}));
connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_K_Flux) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure2.q_in, KPool.q_out);
connect(concentrationMeasure2.actualConc, busConnector.KPool_per_liter) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure2.actualConc, busConnector.KPool) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(gILumenK.busConnector, busConnector);
connect(gILumenK.q_out, KPool.q_out);
connect(kindeyK.q_out, bladder.q_in);
connect(kindeyK.q_in, KPool.q_out);
connect(bladder.busConnector, busConnector);
connect(kindeyK.busConnector, busConnector);
connect(concentrationMeasure2.actualConc, busConnector.KPool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(KPool.soluteMass, busConnector.KPool_mass) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(KPool.q_out, sweatGlandSalt.salt);
connect(sweatGlandSalt.busConnector, busConnector);
connect(KPool.q_out, intracellularPotassium.q_in);
connect(busConnector, intracellularPotassium.busConnector);
end Potassium;

model KindeyK
Physiolibrary.Factors.CurveValue NaEffect(data = {{0.0, 0.3, 0}, {0.4, 1.0, 1.5}, {4.0, 3.0, 0}});
Physiolibrary.Factors.CurveValue AldoEffect(data = {{0.0, 0.3, 0}, {12.0, 1.0, 0.06}, {50.0, 3.0, 0}});
Physiolibrary.Factors.CurveValue ThiazideEffect(data = {{0.0, 1.0, 2.0}, {0.6, 2.0, 0}});
Physiolibrary.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k = 0.05);
Physiolibrary.ConcentrationFlow.SoluteFlowPump DT_K;
Physiolibrary.Factors.CurveValue KEffect(data = {{0.0, 0.0, 0}, {4.4, 1.0, 0.5}, {5.5, 3.0, 0}});
Physiolibrary.Factors.SimpleMultiply KidneyFunction;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "sodium concentration in blood incomming to glomerulus capillaries; sodium mass flow is filtration - reabsorbtion";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "sodium mass outflow to urine from collecting ducts";
equation
connect(AldoEffect.y, NaEffect.yBase);
connect(ThiazideEffect.y, AldoEffect.yBase);
connect(ThiazideEffect.u, busConnector.ThiazidePool_Thiazide_conc) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(NaEffect.u, busConnector.DT_Na_Outflow) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(NaEffect.y, KEffect.yBase);
connect(KEffect.y, DT_K.soluteFlow);
connect(electrolytesFlowConstant.y, KidneyFunction.yBase);
connect(KidneyFunction.y, ThiazideEffect.yBase);
connect(KidneyFunction.u, busConnector.KidneyFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(KEffect.y, busConnector.CD_K_Outflow) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(AldoEffect.u, busConnector.NephronAldo_conc_in_nG_per_dl) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(q_in, DT_K.q_in);
connect(DT_K.q_out, q_out);
connect(busConnector.KPool_conc_per_liter, KEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end KindeyK;

model GILumenK
Physiolibrary.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 25, stateName = "GILumenPotassium.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion;
Modelica.Blocks.Math.Gain Perm(k = 0.002);
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.ConcentrationFlow.OutputPump Diarrhea;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.Constant Constant7(k = 70 / 1440);
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "sodium mass outflow to urine from collecting ducts";
equation
connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(GILumen.q_out, Absorbtion.q_in);
connect(Diet.q_out, GILumen.q_out);
connect(Diarrhea.desiredFlow, busConnector.GILumenDiarrhea_KLoss) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(GILumen.q_out, Diarrhea.q_in);
connect(Perm.y, Absorbtion.soluteFlow);
connect(Perm.u, GILumen.soluteMass);
connect(GILumen.soluteMass, busConnector.GILumenPotasium_Mass) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(GILumen.soluteMass, busConnector.GILumenPotassium_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(LeptinEffect2.y, Diet.desiredFlow);
connect(Absorbtion.q_out, q_out);
end GILumenK;

model IntracellularPotassium_const
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant1(k = 0);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "sodium concentration in blood incomming to glomerulus capillaries; sodium mass flow is filtration - reabsorbtion";
Modelica.Blocks.Math.Gain gain(k = 1000, y(unit = "mEq/l"));
Physiolibrary.Blocks.ElectrolytesConcentrationConstant_per_l electrolytesFlowConstant2(k = 142);
Physiolibrary.Blocks.ElectrolytesMassConstant electrolytesFlowConstant3(k = 0.142 * 26481.1911733325);
Modelica.Blocks.Math.Division division;
equation
q_in.q = 0;
connect(gain.y, busConnector.KCell_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(electrolytesFlowConstant1.y, busConnector.PotassiumToCells) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(electrolytesFlowConstant3.y, busConnector.KCell_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(division.y, gain.u);
connect(busConnector.ICFV_Vol, division.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(electrolytesFlowConstant3.y, division.u1);
end IntracellularPotassium_const;
end Potassium;

package Chloride  "Body Chloride Distribution"
model GILumenCl
Physiolibrary.ConcentrationFlow.ConcentrationCompartment GILumen(initialSoluteMass = 90, stateName = "GILumenChloride.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion;
Modelica.Blocks.Math.Gain Perm(k = 0.0015);
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.ConcentrationFlow.OutputPump Diarrhea;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.Constant Constant7(k = 200 / 1440);
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "sodium mass outflow to urine from collecting ducts";
equation
connect(GILumen.SolventVolume, busConnector.GILumenVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(GILumen.q_out, Absorbtion.q_in);
connect(Diet.q_out, GILumen.q_out);
connect(Diarrhea.desiredFlow, busConnector.GILumenVomitus_ClLoss) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(GILumen.q_out, Diarrhea.q_in);
connect(Perm.y, Absorbtion.soluteFlow);
connect(Perm.u, GILumen.soluteMass);
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(LeptinEffect2.y, Diet.desiredFlow);
connect(Absorbtion.q_out, q_out);
end GILumenCl;

model KidneyCl
Physiolibrary.Factors.CurveValue PhEffect(data = {{7.0, 1.0, 0}, {7.45, 0.93, -0.5}, {7.8, 0.0, 0}});
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.SoluteFlowPump CD_Outflow;
Modelica.Blocks.Math.Sum CD_Cations_Outflow(nin = 3);
Modelica.Blocks.Math.Sum CD_AnionsLessCl_Outflow(nin = 3);
Modelica.Blocks.Math.Feedback CD_Cl_Outflow;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "sodium concentration in blood incomming to glomerulus capillaries; sodium mass flow is filtration - reabsorbtion";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "sodium mass outflow to urine from collecting ducts";
Modelica.Blocks.Math.Sum CD_AnionsLessCl_Outflow1(nin = 3);
equation
connect(busConnector.CollectingDuct_NetSumCats, PhEffect.yBase) annotation(Text(string = "%first", index = -1, extent = {{-3, 1}, {-3, 1}}));
connect(busConnector.Artys_pH, PhEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CD_Na_Outflow, CD_Cations_Outflow.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CD_NH4_Outflow, CD_Cations_Outflow.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 0}, {-6, 0}}));
connect(busConnector.CD_K_Outflow, CD_Cations_Outflow.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(busConnector.CD_PO4_mEq_Outflow, CD_AnionsLessCl_Outflow.u[1]) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CD_SO4_Outflow, CD_AnionsLessCl_Outflow.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 0}, {-6, 0}}));
connect(busConnector.CD_KA_Outflow, CD_AnionsLessCl_Outflow.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(CD_Cations_Outflow.y, CD_Cl_Outflow.u1);
connect(q_in, CD_Outflow.q_in);
connect(CD_Outflow.q_out, q_out);
connect(busConnector.CD_SO4_Outflow, CD_AnionsLessCl_Outflow1.u[2]) annotation(Text(string = "%first", index = -1, extent = {{-6, 0}, {-6, 0}}));
connect(busConnector.CD_KA_Outflow, CD_AnionsLessCl_Outflow1.u[3]) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(busConnector.CD_PO4_Outflow, CD_AnionsLessCl_Outflow1.u[1]);
connect(CD_AnionsLessCl_Outflow.y, CD_Cl_Outflow.u2);
connect(PhEffect.y, CD_Outflow.soluteFlow);
end KidneyCl;

model Chloride2
Physiolibrary.ConcentrationFlow.OutputPump Hemorrhage;
Physiolibrary.ConcentrationFlow.OutputPump DialyzerActivity;
Physiolibrary.ConcentrationFlow.InputPump IVDrip;
Physiolibrary.ConcentrationFlow.InputPump Transfusion;
Physiolibrary.Interfaces.BusConnector busConnector;
Real ECF_conc;
SweatGlandSalt sweatGlandSalt;
GILumenCl gILumenCl;
.HumMod.Electrolytes.Bladder bladder(stateVarName = "BladderChloride.Mass");
.HumMod.Electrolytes.Chloride.KidneyCl kidneyCl;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ClPool(initialSoluteMass = 1515.2456531712, stateName = "ClPool.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
equation
ECF_conc = concentrationMeasure1.actualConc;
connect(Hemorrhage.q_in, ClPool.q_out);
connect(DialyzerActivity.q_in, ClPool.q_out);
connect(Transfusion.q_out, ClPool.q_out);
connect(IVDrip.q_out, ClPool.q_out);
connect(IVDrip.desiredFlow, busConnector.IVDrip_ClRate) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(Transfusion.desiredFlow, busConnector.Transfusion_ClRate) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(busConnector.Hemorrhage_ClRate, Hemorrhage.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-3, 1}, {-3, 1}}));
connect(DialyzerActivity.desiredFlow, busConnector.DialyzerActivity_Cl_Flux) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(ClPool.q_out, sweatGlandSalt.salt);
connect(busConnector, gILumenCl.busConnector);
connect(gILumenCl.q_out, ClPool.q_out);
connect(bladder.busConnector, busConnector);
connect(sweatGlandSalt.busConnector, busConnector);
connect(kidneyCl.busConnector, busConnector);
connect(bladder.q_in, kidneyCl.q_out);
connect(kidneyCl.q_in, ClPool.q_out);
connect(concentrationMeasure1.actualConc, busConnector.ClPool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ClPool.soluteMass, busConnector.ClPool_mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.ECFV_Vol, ClPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(ClPool.q_out, concentrationMeasure1.q_in);
end Chloride2;
end Chloride;

package Phosphate  "Body Phosphate Distribution"
model GlomerulusStrongAnionFiltration
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.Interfaces.RealInput_ Cations(final quantity = "Concentration", final unit = "mEq/l");
Physiolibrary.Interfaces.RealInput_ ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
Real KAdjustment;
Real Anions(final quantity = "Concentration", final unit = "mEq/l");
equation
q_in.q + q_out.q = 0;
Anions = Cations;
KAdjustment = (Cations - (Anions - ProteinAnions)) / (Cations + Anions - ProteinAnions);
q_out.conc = (1 + KAdjustment) * q_in.conc;
end GlomerulusStrongAnionFiltration;

model Phosphate3
Physiolibrary.ConcentrationFlow.ConcentrationCompartment PO4Pool(initialSoluteMass = 2.43011, stateName = "PO4Pool.Mass");
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate;
.HumMod.Electrolytes.Sulphate.GlomerulusStrongAnionFiltration glomerulus;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
Modelica.Blocks.Math.Gain gain(k = 1000);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Modelica.Blocks.Math.Gain gain1(k = 0.5);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mmol/l", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.Constant Constant7(k = 30 / 1440);
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Real ECF_conc;
.HumMod.Electrolytes.Bladder bladder(stateVarName = "BladderPhosphate.Mass");
equation
ECF_conc = concentrationMeasure1.actualConc;
connect(PO4Pool.SolventVolume, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(Diet.q_out, PO4Pool.q_out);
connect(glomerulusPhosphateRate.solventFlow, busConnector.GlomerulusFiltrate_GFR) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(glomerulus.q_out, glomerulusPhosphateRate.q_in);
connect(PO4Pool.q_out, glomerulus.q_in);
connect(concentrationMeasure.actualConc, gain.u);
connect(gain.y, busConnector.PO4Pool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure.q_in, PO4Pool.q_out);
connect(flowMeasure.actualFlow, busConnector.CD_PO4_Outflow) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in);
connect(busConnector.BloodIons_Cations, glomerulus.Cations) annotation(Text(string = "%first", index = -1, extent = {{-3, 1}, {-3, 1}}));
connect(PO4Pool.soluteMass, gain1.u);
connect(gain1.y, busConnector.PO4Pool_Osmoles) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure1.actualConc, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure1.q_in, PO4Pool.q_out);
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(LeptinEffect2.y, Diet.desiredFlow);
connect(busConnector.BloodIons_ProteinAnions, glomerulus.ProteinAnions) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(bladder.busConnector, busConnector);
connect(bladder.q_in, flowMeasure.q_out);
connect(flowMeasure.actualFlow, busConnector.CD_PO4_mEq_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Phosphate3;
end Phosphate;

package Sulphate  "Body Sulphate Distribution"
model GlomerulusStrongAnionFiltration
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.Interfaces.RealInput_ Cations(final quantity = "Concentration", final unit = "mEq/l");
Physiolibrary.Interfaces.RealInput_ ProteinAnions(final quantity = "Concentration", final unit = "mEq/l");
Real KAdjustment;
Real Anions(final quantity = "Concentration", final unit = "mEq/l");
equation
q_in.q + q_out.q = 0;
Anions = Cations;
KAdjustment = (Cations - (Anions - ProteinAnions)) / (Cations + Anions - ProteinAnions);
q_out.conc = (1 + KAdjustment) * q_in.conc;
end GlomerulusStrongAnionFiltration;

model Sulphate2
Physiolibrary.ConcentrationFlow.ConcentrationCompartment SO4Pool(initialSoluteMass = 4.00254, stateName = "SO4Pool.Mass");
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate;
GlomerulusStrongAnionFiltration glomerulus;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
Modelica.Blocks.Math.Gain gain(k = 1000);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Modelica.Blocks.Math.Gain gain1(k = 0.5);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.Constant Constant7(k = 50 / 1440);
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Real ECF_conc;
.HumMod.Electrolytes.Bladder bladder(stateVarName = "BladderSulphate.Mass");
equation
ECF_conc = gain.y;
connect(SO4Pool.SolventVolume, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(Diet.q_out, SO4Pool.q_out);
connect(glomerulusPhosphateRate.solventFlow, busConnector.GlomerulusFiltrate_GFR) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(glomerulus.q_out, glomerulusPhosphateRate.q_in);
connect(SO4Pool.q_out, glomerulus.q_in);
connect(concentrationMeasure.actualConc, gain.u);
connect(gain.y, busConnector.SO4Pool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(concentrationMeasure.q_in, SO4Pool.q_out);
connect(flowMeasure.actualFlow, busConnector.CD_SO4_Outflow) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in);
connect(busConnector.BloodIons_Cations, glomerulus.Cations) annotation(Text(string = "%first", index = -1, extent = {{-3, 1}, {-3, 1}}));
connect(gain1.y, busConnector.SO4Pool_Osmoles) annotation(Text(string = "%second", index = 1, extent = {{3, 1}, {3, 1}}));
connect(gain1.u, SO4Pool.soluteMass);
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(LeptinEffect2.y, Diet.desiredFlow);
connect(busConnector.BloodIons_ProteinAnions, glomerulus.ProteinAnions) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(flowMeasure.q_out, bladder.q_in);
connect(bladder.busConnector, busConnector);
end Sulphate2;
end Sulphate;

package NH4  "Body Amonium Distribution"
model Amonium2
Physiolibrary.Factors.CurveValue AcuteEffect(data = {{7.0, 2.0, 0}, {7.45, 1.0, -3.0}, {7.8, 0.0, 0}});
Physiolibrary.Factors.SplineDelayByDay ChronicEffect(Tau = 3, data = {{7.0, 3.0, 0}, {7.45, 1.0, -4.0}, {7.8, 0.0, 0}}, stateName = "PT_NH3.ChronicPhEffect");
Physiolibrary.Factors.CurveValue PhOnFlux(data = {{7.0, 1.0, 0}, {7.45, 0.6, -2.0}, {7.8, 0.0, 0}});
Physiolibrary.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k = 0.04);
Physiolibrary.Interfaces.BusConnector busConnector;
equation
connect(AcuteEffect.y, ChronicEffect.yBase);
connect(ChronicEffect.y, PhOnFlux.yBase);
connect(electrolytesFlowConstant.y, AcuteEffect.yBase);
connect(busConnector.Artys_pH, AcuteEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(PhOnFlux.y, busConnector.CD_NH4_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, -3}, {6, -3}}));
connect(busConnector.Artys_pH, ChronicEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Artys_pH, PhOnFlux.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Amonium2;
end NH4;

model Electrolytes
Sodium.Sodium sodium;
Potassium.Potassium potassium;
Chloride.Chloride2 chloride;
Phosphate.Phosphate3 phosphate;
Sulphate.Sulphate2 sulphate;
Physiolibrary.Interfaces.BusConnector busConnector;
ElectrolytesProperties electrolytesProperties;
NH4.Amonium2 amonium;
equation
connect(sodium.busConnector, busConnector);
connect(busConnector, potassium.busConnector);
connect(busConnector, chloride.busConnector);
connect(busConnector, electrolytesProperties.busConnector);
connect(sulphate.busConnector, busConnector);
connect(phosphate.busConnector, busConnector);
connect(amonium.busConnector, busConnector);
end Electrolytes;

model ElectrolytesProperties
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.OsmolarityConstant OsmCell_OtherCations(k = 692);
Physiolibrary.Blocks.OsmolarityConstant CellElectrolytesMass(k = 1000);
Modelica.Blocks.Math.Add3 Cells(k3 = -1, k1 = 2, k2 = 2);
Physiolibrary.Blocks.OsmolarityConstant OsmECFV_OtherAnions(k = 373.0);
Modelica.Blocks.Math.Sum ECF(nin = 8);
Modelica.Blocks.Math.Sum BloodCations(nin = 2);
Modelica.Blocks.Math.Feedback lessPO4;
Modelica.Blocks.Math.Feedback lessSO4;
Modelica.Blocks.Math.Add3 AnFlow;
Modelica.Blocks.Math.Add3 CatFlow;
Modelica.Blocks.Math.Feedback CollectingDuct_NetSumCats;
Modelica.Blocks.Math.Sum StrongAnions(nin = 5);
Modelica.Blocks.Math.Feedback WeakAnions2;
Modelica.Blocks.Math.Feedback NBB(y(unit = "mEq/l")) "nonbicarbonate buffers";
Modelica.Blocks.Math.Feedback lessCl;
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
connect(lessSO4.y, busConnector.BloodIons_StrongAnionsLessSO4);
connect(busConnector.BloodIons_StrongAnionsLessPO4, lessPO4.y);
connect(busConnector.PO4Pool_conc_per_liter, lessPO4.u2);
connect(busConnector.SO4Pool_conc_per_liter, lessSO4.u2);
connect(CollectingDuct_NetSumCats.y, busConnector.CollectingDuct_NetSumCats) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CatFlow.y, CollectingDuct_NetSumCats.u1);
connect(AnFlow.y, CollectingDuct_NetSumCats.u2);
connect(busConnector.CD_NH4_Outflow, CatFlow.u1);
connect(busConnector.CD_PO4_Outflow, AnFlow.u2);
connect(busConnector.CD_SO4_Outflow, AnFlow.u3);
connect(BloodCations.y, WeakAnions2.u1);
connect(busConnector.PO4Pool_conc_per_liter, StrongAnions.u[2]);
connect(busConnector.SO4Pool_conc_per_liter, StrongAnions.u[3]);
connect(busConnector.ClPool_conc_per_liter, StrongAnions.u[5]);
connect(busConnector.PO4Pool_Osmoles, ECF.u[4]);
connect(busConnector.SO4Pool_Osmoles, ECF.u[5]);
connect(busConnector.LacPool_Mass_mEq, ECF.u[6]);
connect(busConnector.LacPool_Lac_mEq_per_litre, StrongAnions.u[4]);
connect(ECF.y, busConnector.OsmECFV_Electrolytes) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Cells.y, busConnector.OsmCell_Electrolytes) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.KAPool_conc_per_liter, StrongAnions.u[1]);
connect(busConnector.CD_KA_Outflow, AnFlow.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.KAPool_Osmoles, ECF.u[7]);
connect(BloodCations.y, busConnector.BloodIons_Cations) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.CD_Na_Outflow, CatFlow.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CD_K_Outflow, CatFlow.u3) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(BloodCations.y, busConnector.BloodCations) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(StrongAnions.y, busConnector.BloodIons_StrongAnions) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(StrongAnions.y, lessSO4.u1);
connect(StrongAnions.y, lessPO4.u1);
connect(StrongAnions.y, WeakAnions2.u2);
connect(WeakAnions2.y, NBB.u1);
connect(busConnector.CO2Veins_cHCO3, NBB.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ClPool_conc_per_liter, lessCl.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(StrongAnions.y, lessCl.u1);
connect(lessCl.y, busConnector.BloodIons_StrongAnionsLessCl) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(WeakAnions2.y, busConnector.BloodIons_SID) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end ElectrolytesProperties;

model SweatGlandSalt
parameter Real FractReabBasic = 0.8;
parameter Real FractReabK = log(FractReabBasic) / 15.0;
Physiolibrary.Factors.CurveValue AldoEffect(data = {{0, 0.5, 0.0}, {12, 1.0, 0.03}, {100, 2.0, 0.0}});
Physiolibrary.Blocks.Constant Constant(k = 1);
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Exp FractReab;
Modelica.Blocks.Math.Product product;
Physiolibrary.Blocks.Constant Constant1(k = FractReabK);
Modelica.Blocks.Math.Product Reab;
Modelica.Blocks.Math.Feedback Outflow;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow salt;
Physiolibrary.ConcentrationFlow.OutputPump outputPump(desiredFlow(start = 0));
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure;
Physiolibrary.Interfaces.BusConnector busConnector;
Modelica.Blocks.Math.Product SaltInflow;
equation
connect(Constant.y, AldoEffect.yBase);
connect(AldoEffect.y, division.u2);
connect(division.y, FractReab.u);
connect(product.y, division.u1);
connect(Constant1.y, product.u2);
connect(FractReab.y, Reab.u1);
connect(Reab.y, Outflow.u2);
connect(salt, outputPump.q_in);
connect(outputPump.desiredFlow, Outflow.y);
connect(salt, concentrationMeasure.q_in);
connect(busConnector.Aldo_conc_in_nG_per_dl, AldoEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.SweatGland_H2ORate, product.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(concentrationMeasure.actualConc, SaltInflow.u2);
connect(busConnector.SweatGland_H2ORate, SaltInflow.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(SaltInflow.y, Reab.u2);
connect(SaltInflow.y, Outflow.u1);
end SweatGlandSalt;

model Bladder
parameter String stateVarName;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Bladder(initialSoluteMass = 0, stateName = stateVarName);
Physiolibrary.ConcentrationFlow.SolventOutflowPump bladderVoid;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
equation
connect(Bladder.SolventVolume, busConnector.BladderVolume_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Bladder.q_out, bladderVoid.q_in);
connect(bladderVoid.solventFlow, busConnector.BladderVoidFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(q_in, Bladder.q_out);
end Bladder;
end Electrolytes;

package Gases  "Body O2 and CO2"

package O2  "Body O2 Transport"
model O2
Physiolibrary.ConcentrationFlow.ConcentrationCompartment artys(stateName = "O2Artys.Mass[mMol]", initialSoluteMass = 13.0979);
Physiolibrary.ConcentrationFlow.ConcentrationCompartment veins(stateName = "O2Veins.Mass[mMol]", initialSoluteMass = 24.7781);
ExternalO2 air_O2(concentration = 21);
Physiolibrary.Interfaces.BusConnector busConnector;
RespiratoryRegulations.AlveolarVentilation alveolarVentilation(solventFlowPump(q_out(conc(start = 104 / 760))));
TissuesO2 tissuesO2(boneO2(O2Tissue(pO2(start = 7.706), cO2Hb(start = 5.915), a(start = 0.4183)), arty(q(start = 2.58114))), fatO2(O2Tissue(pO2(start = 9.066280000000001), cO2Hb(start = 6.72935), a(start = 0.40662)), arty(q(start = 1.9206))), otherTissueO2(O2Tissue(pO2(start = 9.50212), cO2Hb(start = 6.92105), a(start = 0.403818)), arty(q(start = 2.9876))), respiratoryMuscleO2(O2Tissue(pO2(start = 6.979), cO2Hb(start = 5.3182), a(start = 0.426692)), arty(q(start = 0.7824680000000001))), skinO2(O2Tissue(pO2(start = 5.32132), cO2Hb(start = 6.27243), a(start = 0.422803)), arty(q(start = 1.26465))), liverO2(O2Tissue(pO2(start = 4.12887), cO2Hb(start = 2.50865), a(start = 0.401361)), pCO2(start = 4.71942), hepaticArty(q(start = 1.96287))), brainO2(O2Tissue(pO2(start = 7.47591), cO2Hb(start = 5.73949), a(start = 0.420777)), arty(q(start = 6.50714))), GITractO2(O2Tissue(pO2(start = 10.0668), cO2Hb(start = 7.1305), a(start = 0.40072)), arty(q(start = 9.18834))), kidneyO2(O2Tissue(pO2(start = 10.0613), cO2Hb(start = 7.12884), a(start = 0.400742)), arty(q(start = 9.896940000000001))), leftHeartO2(O2Tissue(pO2(start = 3.579), cO2Hb(start = 1.59478), a(start = 0.476472)), arty(q(start = 1.48263))), rightHeartO2(O2Tissue(pO2(start = 3.41451), cO2Hb(start = 1.44372), a(start = 0.478421)), arty(q(start = 0.278399))), skeletalMuscleO2(arty(q(start = 5.12266)), O2Tissue(cO2Hb(start = 5.857), pO2(start = 8.33), a(start = 0.46))));
Physiolibrary.ConcentrationFlow.SolventFlowPump pulmShortCircuit;
Modelica.Blocks.Math.Feedback pulmShortCircuitFlow;
Physiolibrary.PressureFlow.Gas_FromMLtoMMOL fromMLtoMMOL;
MeassureBloodO2 artysO2(pO2(start = 13.459), cO2Hb(start = 7.82305), pCO2(start = 4.42803), a(start = -0.1));
MeassureBloodO2 veinsO2(pO2(start = 6.14), cO2Hb(start = 6.52), a(start = 0.076), pCO2(start = 6.4));
HumMod.Gases.O2.BloodO2_Siggaard O2Lung(pCO2(start = 5.7), pO2(start = 13.87), sO2CO(start = 0.977), q_in(q(start = 10)), a(start = -0.1), cO2Hb(start = 8.16), tO2(start = 8.161));
Real x;
equation
x = ((-O2Lung.q_out.q) - tissuesO2.O2ToTissues) / O2Lung.BloodFlow * veins.SolventVolume;
connect(busConnector.ArtysVol, artys.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.VeinsVol, veins.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(alveolarVentilation.inspired, air_O2.q_out);
connect(air_O2.q_out, alveolarVentilation.expired);
connect(tissuesO2.q_in, artys.q_out);
connect(tissuesO2.busConnector, busConnector);
connect(tissuesO2.q_out, veins.q_out);
connect(pulmShortCircuitFlow.u1, busConnector.CardiacOutput) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(pulmShortCircuit.q_out, artys.q_out);
connect(pulmShortCircuit.solventFlow, pulmShortCircuitFlow.y);
connect(busConnector.AlveolarVentilated_BloodFlow, pulmShortCircuitFlow.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(veins.q_out, pulmShortCircuit.q_in);
connect(alveolarVentilation.alveolar, fromMLtoMMOL.q_ML);
connect(busConnector.CO2Artys_pCO2, artysO2.pCO2_mmHg) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artysO2.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysO2.cDPG, busConnector.cDPG) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysO2.FHbF, busConnector.FHbF) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysO2.pCO_mmHg, busConnector.pCO) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Artys_pH, artysO2.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.core_T, artysO2.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artys.q_out, artysO2.q_in);
connect(veinsO2.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsO2.cDPG, busConnector.cDPG) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsO2.FHbF, busConnector.FHbF) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsO2.pCO_mmHg, busConnector.pCO) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.CO2Veins_pCO2, veinsO2.pCO2_mmHg) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Veins_pH, veinsO2.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.core_T, veinsO2.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(veins.q_out, veinsO2.q_in);
connect(busConnector.O2Veins_sO2, veinsO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-3, -3}, {-3, -3}}));
connect(artysO2.sO2, busConnector.O2Artys_sO2) annotation(Text(string = "%second", index = 1, extent = {{3, -3}, {3, -3}}));
connect(artysO2.PO2, busConnector.O2Artys_PO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.CO2Lung_pCO2, O2Lung.pCO2_mmHg) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(O2Lung.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(O2Lung.cDPG, busConnector.cDPG) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(O2Lung.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(O2Lung.FHbF, busConnector.FHbF) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(O2Lung.pCO_mmHg, busConnector.pCO) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.AlveolarVentilated_BloodFlow, O2Lung.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(O2Lung.sO2, busConnector.O2Lung_sO2) annotation(Text(string = "%second", index = 1, extent = {{6, -3}, {6, -3}}));
connect(busConnector.core_T, O2Lung.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(veins.q_out, O2Lung.q_in);
connect(O2Lung.q_out, artys.q_out);
connect(fromMLtoMMOL.q_MMOL, O2Lung.alveolar);
connect(busConnector.BarometerPressure, alveolarVentilation.EnvironmentPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.lungs_pH_plasma, O2Lung.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(alveolarVentilation.AlveolarVentilation_STPD, busConnector.AlveolarVentilation_STPD) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(alveolarVentilation.BronchiDilution, busConnector.BronchiDilution) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(fromMLtoMMOL.T, busConnector.core_T);
end O2;

model TissuesO2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
tissues.SkeletalMuscleO2 skeletalMuscleO2(initialMass = 323.9);
tissues.BoneO2 boneO2(initialMass = 56.2);
tissues.FatO2 fatO2(initialMass = 39.8);
tissues.BrainO2 brainO2(initialMass = 19.1);
tissues.RightHeartO2 rightHeartO2(initialMass = 0.6);
tissues.RespiratoryMuscleO2 respiratoryMuscleO2(initialMass = 48.1);
tissues.OtherTissueO2 otherTissueO2(initialMass = 50.7);
tissues.TissueO2_liver2 liverO2(initialMass = 22.8);
tissues.LeftHeartO2 leftHeartO2(initialMass = 3.5);
HumMod.Gases.O2.tissues.TissueO2_kidney kidneyO2(initialMass = 4.1);
tissues.GITractO2 GITractO2(initialMass = 17.6);
Physiolibrary.Interfaces.BusConnector busConnector;
tissues.SkinO2 skinO2(initialMass = 28.2);
Real O2ToTissues(unit = "mmol/min");
Real O2ToTissues2(unit = "mmol/min");
Real O2ToTissues3(unit = "ml/min");
Real BloodFlow(unit = "ml/min");
equation
O2ToTissues = q_in.q + q_out.q;
O2ToTissues2 = skeletalMuscleO2.O2Use_mmol_per_min + boneO2.O2Use_mmol_per_min + fatO2.O2Use_mmol_per_min + brainO2.O2Use_mmol_per_min + rightHeartO2.O2Use_mmol_per_min + respiratoryMuscleO2.O2Use_mmol_per_min + otherTissueO2.O2Use_mmol_per_min + liverO2.O2Use_mmol_per_min + leftHeartO2.O2Use_mmol_per_min + kidneyO2.O2Use_mmol_per_min + GITractO2.O2Use_mmol_per_min + skinO2.O2Use_mmol_per_min;
O2ToTissues3 = skeletalMuscleO2.O2Use_ml_per_min + boneO2.O2Use_ml_per_min + fatO2.O2Use_ml_per_min + brainO2.O2Use_ml_per_min + rightHeartO2.O2Use_ml_per_min + respiratoryMuscleO2.O2Use_ml_per_min + otherTissueO2.O2Use_ml_per_min + liverO2.O2Use_ml_per_min + leftHeartO2.O2Use_ml_per_min + kidneyO2.O2Use_ml_per_min + GITractO2.O2Use_ml_per_min + skinO2.O2Use_ml_per_min;
BloodFlow = skeletalMuscleO2.BloodFlow + boneO2.BloodFlow + fatO2.BloodFlow + brainO2.BloodFlow + rightHeartO2.BloodFlow + respiratoryMuscleO2.BloodFlow + otherTissueO2.BloodFlow + liverO2.HepaticArtyBloodFlow + leftHeartO2.BloodFlow + kidneyO2.BloodFlow + GITractO2.BloodFlow + skinO2.BloodFlow;
connect(q_out, skeletalMuscleO2.vein);
connect(q_out, boneO2.vein);
connect(q_out, otherTissueO2.vein);
connect(q_out, respiratoryMuscleO2.vein);
connect(q_out, fatO2.vein);
connect(q_out, skinO2.vein);
connect(q_out, liverO2.vein);
connect(q_out, brainO2.vein);
connect(q_out, kidneyO2.vein);
connect(q_out, leftHeartO2.vein);
connect(skeletalMuscleO2.arty, q_in);
connect(brainO2.arty, q_in);
connect(GITractO2.arty, q_in);
connect(kidneyO2.arty, q_in);
connect(leftHeartO2.arty, q_in);
connect(rightHeartO2.arty, q_in);
connect(rightHeartO2.vein, q_out);
connect(boneO2.arty, q_in);
connect(otherTissueO2.arty, q_in);
connect(fatO2.arty, q_in);
connect(skinO2.arty, q_in);
connect(q_in, respiratoryMuscleO2.arty);
connect(busConnector.cDPG, boneO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, brainO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, fatO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, GITractO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, kidneyO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, leftHeartO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, liverO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, otherTissueO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, respiratoryMuscleO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, rightHeartO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, skinO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.cDPG, skeletalMuscleO2.cDPG) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, boneO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, brainO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, fatO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, GITractO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, kidneyO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, leftHeartO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, liverO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, otherTissueO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, respiratoryMuscleO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, rightHeartO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, skinO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.FHbF, skeletalMuscleO2.FHbF) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_pCO2, boneO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_pCO2, brainO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_pCO2, fatO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_pCO2, GITractO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_pCO2, kidneyO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_pCO2, leftHeartO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_pCO2, liverO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_pCO2, otherTissueO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_pCO2, respiratoryMuscleO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_pCO2, rightHeartO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_pCO2, skinO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_pCO2, skeletalMuscleO2.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, boneO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, brainO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, fatO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, GITractO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, kidneyO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, leftHeartO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, liverO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, otherTissueO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, respiratoryMuscleO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, rightHeartO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, skinO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.ctHb, skeletalMuscleO2.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, boneO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, brainO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, fatO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, GITractO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, kidneyO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, leftHeartO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, liverO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, otherTissueO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, respiratoryMuscleO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, rightHeartO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, skinO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.pCO, skeletalMuscleO2.pCO) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(boneO2.pH_plasma, busConnector.bone_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainO2.pH_plasma, busConnector.brain_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatO2.pH_plasma, busConnector.fat_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITractO2.pH_plasma, busConnector.GITract_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyO2.pH_plasma, busConnector.kidney_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartO2.pH_plasma, busConnector.leftHeart_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverO2.pH_plasma, busConnector.liver_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueO2.pH_plasma, busConnector.otherTissue_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleO2.pH_plasma, busConnector.respiratoryMuscle_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartO2.pH_plasma, busConnector.rightHeart_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinO2.pH_plasma, busConnector.skin_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleO2.pH_plasma, busConnector.skeletalMuscle_pH_plasma) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITractO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleO2.FMetHb, busConnector.FMetHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneO2.Tissue_O2Use, busConnector.bone_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainO2.Tissue_O2Use, busConnector.brain_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatO2.Tissue_O2Use, busConnector.fat_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITractO2.Tissue_O2Use, busConnector.GITract_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyO2.Tissue_O2Use, busConnector.kidney_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartO2.Tissue_O2Use, busConnector.leftHeart_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverO2.Tissue_O2Use, busConnector.liver_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueO2.Tissue_O2Use, busConnector.otherTissue_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleO2.Tissue_O2Use, busConnector.respiratoryMuscle_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartO2.Tissue_O2Use, busConnector.rightHeart_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinO2.Tissue_O2Use, busConnector.skin_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleO2.Tissue_O2Use, busConnector.skeletalMuscle_O2Use) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneO2.BloodFlow, busConnector.bone_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainO2.BloodFlow, busConnector.brain_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatO2.BloodFlow, busConnector.fat_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITractO2.BloodFlow, busConnector.GITract_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyO2.BloodFlow, busConnector.kidney_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartO2.BloodFlow, busConnector.leftHeart_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueO2.BloodFlow, busConnector.otherTissue_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleO2.BloodFlow, busConnector.respiratoryMuscle_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartO2.BloodFlow, busConnector.rightHeart_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinO2.BloodFlow, busConnector.skin_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleO2.BloodFlow, busConnector.skeletalMuscle_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneO2.T, busConnector.bone_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainO2.T, busConnector.brain_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatO2.T, busConnector.fat_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITractO2.T, busConnector.GITract_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyO2.T, busConnector.kidney_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartO2.T, busConnector.leftHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverO2.T, busConnector.liver_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueO2.T, busConnector.otherTissue_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleO2.T, busConnector.respiratoryMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartO2.T, busConnector.rightHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinO2.T, busConnector.skin_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleO2.T, busConnector.skeletalMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneO2.sO2, busConnector.bone_sO2);
connect(brainO2.sO2, busConnector.brain_sO2);
connect(fatO2.sO2, busConnector.fat_sO2);
connect(GITractO2.sO2, busConnector.GITract_sO2);
connect(kidneyO2.sO2, busConnector.kidney_sO2);
connect(leftHeartO2.sO2, busConnector.leftHeart_sO2);
connect(liverO2.sO2, busConnector.liver_sO2);
connect(otherTissueO2.sO2, busConnector.otherTissue_sO2);
connect(respiratoryMuscleO2.sO2, busConnector.respiratoryMuscle_sO2);
connect(rightHeartO2.sO2, busConnector.rightHeart_sO2);
connect(skinO2.sO2, busConnector.skin_sO2);
connect(skeletalMuscleO2.sO2, busConnector.skeletalMuscle_sO2);
connect(boneO2.pO2, busConnector.Bone_PO2);
connect(brainO2.pO2, busConnector.Brain_PO2);
connect(fatO2.pO2, busConnector.Fat_PO2);
connect(GITractO2.pO2, busConnector.GITract_PO2);
connect(kidneyO2.pO2, busConnector.Kidney_PO2);
connect(leftHeartO2.pO2, busConnector.LeftHeart_PO2);
connect(liverO2.pO2, busConnector.Liver_PO2);
connect(otherTissueO2.pO2, busConnector.OtherTissue_PO2);
connect(respiratoryMuscleO2.pO2, busConnector.RespiratoryMuscle_PO2);
connect(rightHeartO2.pO2, busConnector.RightHeart_PO2);
connect(skinO2.pO2, busConnector.Skin_PO2);
connect(skeletalMuscleO2.pO2, busConnector.SkeletalMuscle_PO2);
connect(liverO2.hepaticArty, q_in);
connect(GITractO2.vein, liverO2.portalVein);
connect(liverO2.HepaticArtyBloodFlow, busConnector.HepaticArty_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(liverO2.PortalVeinBloodFlow, busConnector.GITract_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{3, 13}, {3, 13}}));
connect(kidneyO2.TubulePO2, busConnector.KidneyO2_TubulePO2) annotation(Text(string = "%second", index = 1, extent = {{6, -3}, {6, -3}}));
end TissuesO2;

package tissues
model TissueO2_kidney
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow arty;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow vein;
parameter Real initialMass;
Physiolibrary.Interfaces.RealInput_ ctHb "concentration of haemoglobin";
Physiolibrary.Interfaces.RealInput_ cDPG "outgoing concentration of DPG";
Physiolibrary.Interfaces.RealInput_ BloodFlow "blood flow through tissue";
Physiolibrary.Interfaces.RealInput_ T "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ pCO "outgoing partial pressure of CO";
Physiolibrary.Interfaces.RealInput_ FHbF "Foetal haemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ FMetHb "methaemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ Tissue_O2Use;
Physiolibrary.Interfaces.RealInput_ pH_plasma "outgoing veins pH of plasma";
BloodO2_Siggaard O2Tissue;
Physiolibrary.PressureFlow.OutputPump Metabolism_O2Use;
Physiolibrary.Interfaces.RealOutput_ sO2;
Physiolibrary.Interfaces.RealInput_ pCO2 "outgoing veins CO2 partial pressure";
Physiolibrary.Interfaces.RealOutput_ pO2(final unit = "mmHg");
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure;
Physiolibrary.PressureFlow.Gas_FromMLtoMMOL fromMLtoMMOL;
Physiolibrary.PressureFlow.ResistorWithCond resistorWithCond;
Physiolibrary.Blocks.CondConstant O2PermBasic(k = 0.9);
Physiolibrary.Factors.CurveValue HgbOnPerm(data = {{0.0, 0.4, 0}, {0.15, 1.0, 8.0}, {0.25, 2.0, 0}}) "\"recalculated [Hb] in mmol = 56*[Hb] in ml\"";
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure1;
Physiolibrary.Interfaces.RealOutput_ TubulePO2(final unit = "mmHg") "KidneyO2_TubulePO2";
Modelica.Blocks.Math.Gain mmol_TO_ml(k = 0.15 / 8.4);
Real O2Use_ml_per_min;
Real O2Use_mmol_per_min;
equation
O2Use_mmol_per_min = fromMLtoMMOL.q_MMOL.q;
O2Use_ml_per_min = -fromMLtoMMOL.q_ML.q;
connect(O2Tissue.sO2, sO2);
connect(pH_plasma, O2Tissue.pH);
connect(T, O2Tissue.T);
connect(O2Tissue.pCO2_mmHg, pCO2);
connect(BloodFlow, O2Tissue.BloodFlow);
connect(O2Tissue.ctHb, ctHb);
connect(O2Tissue.cDPG, cDPG);
connect(FMetHb, O2Tissue.FMetHb);
connect(FHbF, O2Tissue.FHbF);
connect(O2Tissue.pCO_mmHg, pCO);
connect(arty, O2Tissue.q_in);
connect(O2Tissue.q_out, vein);
connect(O2Tissue.alveolar, pressureMeasure.q_in);
connect(pressureMeasure.actualPressure, pO2);
connect(Tissue_O2Use, Metabolism_O2Use.desiredFlow);
connect(fromMLtoMMOL.q_MMOL, O2Tissue.alveolar);
connect(O2PermBasic.y, HgbOnPerm.yBase);
connect(HgbOnPerm.y, resistorWithCond.cond);
connect(fromMLtoMMOL.q_ML, resistorWithCond.q_in);
connect(resistorWithCond.q_out, Metabolism_O2Use.q_in);
connect(pressureMeasure1.actualPressure, TubulePO2);
connect(resistorWithCond.q_out, pressureMeasure1.q_in);
connect(mmol_TO_ml.y, HgbOnPerm.u);
connect(O2Tissue.ceHb_, mmol_TO_ml.u);
connect(T, fromMLtoMMOL.T);
end TissueO2_kidney;

model TissueO2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow arty;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow vein;
parameter Real initialMass;
Physiolibrary.Interfaces.RealInput_ ctHb "concentration of haemoglobin";
Physiolibrary.Interfaces.RealInput_ cDPG "outgoing concentration of DPG";
Physiolibrary.Interfaces.RealInput_ BloodFlow "blood flow through tissue";
Physiolibrary.Interfaces.RealInput_ T "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ pCO "outgoing partial pressure of CO";
Physiolibrary.Interfaces.RealInput_ FHbF "Foetal haemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ FMetHb "methaemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ Tissue_O2Use;
Physiolibrary.Interfaces.RealInput_ pH_plasma "outgoing veins pH of plasma";
BloodO2_Siggaard O2Tissue;
Physiolibrary.PressureFlow.OutputPump Metabolism_O2Use;
Physiolibrary.Interfaces.RealOutput_ sO2;
Physiolibrary.Interfaces.RealInput_ pCO2 "outgoing veins CO2 partial pressure";
Physiolibrary.Interfaces.RealOutput_ pO2(final unit = "mmHg");
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure;
Physiolibrary.PressureFlow.Gas_FromMLtoMMOL fromMLtoMMOL;
Real O2Use_ml_per_min;
Real O2Use_mmol_per_min;
equation
O2Use_mmol_per_min = fromMLtoMMOL.q_MMOL.q;
O2Use_ml_per_min = -fromMLtoMMOL.q_ML.q;
connect(O2Tissue.sO2, sO2);
connect(pH_plasma, O2Tissue.pH);
connect(T, O2Tissue.T);
connect(O2Tissue.pCO2_mmHg, pCO2);
connect(BloodFlow, O2Tissue.BloodFlow);
connect(O2Tissue.ctHb, ctHb);
connect(O2Tissue.cDPG, cDPG);
connect(FMetHb, O2Tissue.FMetHb);
connect(FHbF, O2Tissue.FHbF);
connect(O2Tissue.pCO_mmHg, pCO);
connect(arty, O2Tissue.q_in);
connect(O2Tissue.q_out, vein);
connect(O2Tissue.alveolar, pressureMeasure.q_in);
connect(pressureMeasure.actualPressure, pO2);
connect(Tissue_O2Use, Metabolism_O2Use.desiredFlow);
connect(fromMLtoMMOL.q_ML, Metabolism_O2Use.q_in);
connect(fromMLtoMMOL.q_MMOL, O2Tissue.alveolar);
connect(T, fromMLtoMMOL.T);
end TissueO2;

model SkeletalMuscleO2
extends HumMod.Gases.O2.tissues.TissueO2(arty(q(start = 5.048)));
end SkeletalMuscleO2;

model BoneO2
extends HumMod.Gases.O2.tissues.TissueO2;
end BoneO2;

model OtherTissueO2
extends HumMod.Gases.O2.tissues.TissueO2;
end OtherTissueO2;

model RespiratoryMuscleO2
extends HumMod.Gases.O2.tissues.TissueO2;
end RespiratoryMuscleO2;

model FatO2
extends HumMod.Gases.O2.tissues.TissueO2;
end FatO2;

model SkinO2
extends TissueO2;
end SkinO2;

model BrainO2
extends TissueO2;
end BrainO2;

model GITractO2
extends TissueO2;
end GITractO2;

model LeftHeartO2
extends TissueO2;
end LeftHeartO2;

model RightHeartO2
extends TissueO2;
end RightHeartO2;

model TissueO2_liver2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow hepaticArty;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow vein;
parameter Real initialMass;
Physiolibrary.Interfaces.RealInput_ ctHb "concentration of haemoglobin";
Physiolibrary.Interfaces.RealInput_ cDPG "outgoing concentration of DPG";
Physiolibrary.Interfaces.RealInput_ HepaticArtyBloodFlow "blood flow through hepatic artery";
Physiolibrary.Interfaces.RealInput_ T "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ pCO "outgoing partial pressure of CO";
Physiolibrary.Interfaces.RealInput_ FHbF "Foetal haemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ FMetHb "methaemoglobin fraction";
Physiolibrary.Interfaces.RealInput_ Tissue_O2Use;
Physiolibrary.Interfaces.RealInput_ pH_plasma "outgoing veins pH of plasma";
BloodO2_Siggaard O2Tissue;
Physiolibrary.PressureFlow.OutputPump Metabolism_O2Use;
Physiolibrary.Interfaces.RealOutput_ sO2;
Physiolibrary.Interfaces.RealInput_ pCO2 "outgoing veins CO2 partial pressure";
Physiolibrary.Interfaces.RealOutput_ pO2(final unit = "mmHg");
Physiolibrary.PressureFlow.PressureMeasure pressureMeasure;
Physiolibrary.PressureFlow.Gas_FromMLtoMMOL fromMLtoMMOL;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow portalVein;
Physiolibrary.Interfaces.RealInput_ PortalVeinBloodFlow "blood flow through portal vein";
Real O2Use_ml_per_min;
Real O2Use_mmol_per_min;
Modelica.Blocks.Math.Add add;
equation
O2Use_mmol_per_min = fromMLtoMMOL.q_MMOL.q;
O2Use_ml_per_min = -fromMLtoMMOL.q_ML.q;
connect(O2Tissue.sO2, sO2);
connect(pH_plasma, O2Tissue.pH);
connect(T, O2Tissue.T);
connect(O2Tissue.pCO2_mmHg, pCO2);
connect(O2Tissue.ctHb, ctHb);
connect(O2Tissue.cDPG, cDPG);
connect(FMetHb, O2Tissue.FMetHb);
connect(FHbF, O2Tissue.FHbF);
connect(O2Tissue.pCO_mmHg, pCO);
connect(O2Tissue.q_out, vein);
connect(O2Tissue.alveolar, pressureMeasure.q_in);
connect(pressureMeasure.actualPressure, pO2);
connect(Tissue_O2Use, Metabolism_O2Use.desiredFlow);
connect(fromMLtoMMOL.q_ML, Metabolism_O2Use.q_in);
connect(fromMLtoMMOL.q_MMOL, O2Tissue.alveolar);
connect(hepaticArty, O2Tissue.q_in);
connect(PortalVeinBloodFlow, add.u2);
connect(add.u1, HepaticArtyBloodFlow);
connect(portalVein, O2Tissue.q_out);
connect(HepaticArtyBloodFlow, O2Tissue.BloodFlow);
connect(T, fromMLtoMMOL.T);
end TissueO2_liver2;
end tissues;

model ExternalO2
extends Physiolibrary.ConcentrationFlow.UnlimitedStorage;
end ExternalO2;

model MeassureBloodO2
extends HumMod.Gases.O2.BloodO2Base;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
equation
q_in.q = 0;
tO2 = MiniliterPerLiter * q_in.conc;
end MeassureBloodO2;

model BloodO2_Siggaard
extends HumMod.Gases.O2.BloodO2Base;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
Physiolibrary.PressureFlow.PositivePressureFlow alveolar;
Physiolibrary.Interfaces.RealOutput_ ceHb_(unit = "mmol/l") "effective haemoglobin";
Physiolibrary.Interfaces.RealInput_ BloodFlow(unit = "ml/min");
equation
q_in.q + q_out.q + alveolar.q = 0;
alveolar.pressure = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pO2;
q_in.conc = q_in.q / BloodFlow;
tO2 = MiniliterPerLiter * (-q_out.q / BloodFlow);
ceHb_ = ceHb;
end BloodO2_Siggaard;

partial model BloodO2Base
parameter Boolean isSaturated = false;
Real tO2(start = 5.17, unit = "mmol/l");
Real aO2;
Real pO2(start = 5.33, unit = "kPa");
Real sO2CO(start = 0.75);
Real pO2CO(start = 5.33, unit = "kPa");
Real cO2Hb(start = 6, unit = "mmol/l");
Real sCO;
Real ceHb(start = 8.38915596, unit = "mmol/l");
Real a(start = 0.5);
Real k;
Real x;
Real y;
Real h;
Real FCOHb(start = 0);
Real pCO;
Real pCO2;
Physiolibrary.Interfaces.RealOutput_ sO2;
Physiolibrary.Interfaces.RealInput_ pH;
Physiolibrary.Interfaces.RealInput_ ctHb(unit = "mmol/l");
Physiolibrary.Interfaces.RealInput_ T(unit = "DegC", start = 37);
Physiolibrary.Interfaces.RealInput_ pCO_mmHg(unit = "mmHg");
Physiolibrary.Interfaces.RealInput_ pCO2_mmHg(unit = "mmHg");
Physiolibrary.Interfaces.RealInput_ cDPG(unit = "mmol/l");
Physiolibrary.Interfaces.RealInput_ FMetHb;
Physiolibrary.Interfaces.RealInput_ FHbF;
constant Real MiniliterPerLiter(final unit = "ml/l") = 1000;
Physiolibrary.Interfaces.RealOutput_ PO2;
Real cdO2;
parameter Real T0(unit = "degC") = 37 "normal temperature";
parameter Real pH0 = 7.4 "normal arterial pH";
parameter Real pCO20(unit = "kPa") = 5.33 "normal arterial CO2 partial pressure";
parameter Real cDPG0(unit = "mmol/l") = 5 "normal DPG,used by a";
parameter Real dadcDPG0 = 0.3 "used by a";
parameter Real dadcDPGxHbF = -0.1 "or perhabs -0.125";
parameter Real dadpH = -0.88 "used by a";
parameter Real dadlnpCO2 = 0.048 "used by a";
parameter Real dadxMetHb = -0.7 "used by a";
parameter Real dadxHbF = -0.25 "used by a";
equation
PO2 = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pO2;
pCO_mmHg = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pCO;
pCO2_mmHg = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pCO2;
ceHb = ctHb * (1 - FCOHb - FMetHb);
aO2 = exp(log(0.0105) + (-0.0115 * (T - 37)) + 0.5 * 0.00042 * (T - 37) ^ 2);
cdO2 = aO2 * pO2;
tO2 = aO2 * pO2 + ceHb * sO2;
sO2 = cO2Hb / ceHb;
a = dadpH * (pH - pH0) + dadlnpCO2 * log(max(1e-015 + 1e-019 * pCO2, pCO2 / pCO20)) + dadxMetHb * FMetHb + (dadcDPG0 + dadcDPGxHbF * FHbF) * (cDPG / cDPG0 - 1);
x = log(max(Modelica.Constants.eps * (1 + pO2CO), pO2CO) / 7) - a - 0.055 * (T - 37);
y - 1.8747 = x + h * tanh(k * x);
k = 0.5342857;
h = 3.5 + a;
y = log(sO2CO / (1 - sO2CO));
pCO = sCO * pO2CO / 218 * sO2CO;
pO2CO = pO2 + 218 * pCO;
sO2CO = (cO2Hb + ctHb * FCOHb) / (ctHb * (1 - FMetHb));
sCO = ctHb * FCOHb / (ctHb * (1 - FMetHb));
end BloodO2Base;
end O2;

package CO2  "Body CO2 Transport"
partial model HendersonHasselbach
Real pK;
Real aCO2(final unit = "mmol/(l.kPa)");
Real cdCO2(final unit = "mmol/l");
Real pCO2(start = 6, unit = "kPa");
constant Real MiniliterPerLiter(final unit = "ml/l") = 1000;
Physiolibrary.Interfaces.RealOutput_ cHCO3(final unit = "mmol/l") "outgoing concentration of HCO3";
Physiolibrary.Interfaces.RealInput_ T(final unit = "degC") "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ pH "outgoing plasma pH";
equation
pK = 6.1 + (-0.0026) * (T - 37);
aCO2 = 0.23 * 10 ^ (-0.0092 * (T - 37));
cdCO2 = aCO2 * pCO2;
cdCO2 * 10 ^ (pH - pK) = cHCO3;
end HendersonHasselbach;

partial model BloodCO2Base
extends HumMod.Gases.CO2.HendersonHasselbach;
Real tCO2_P(start = 24, final unit = "mmol/l");
Real pK_ery;
Real aCO2_ery(final unit = "mmol/l/mmHg");
Real tCO2_ery(final unit = "mmol/l");
Real tCO2(final unit = "mmol/l");
Physiolibrary.Interfaces.RealInput_ pH_ery "outgoing intracellular erytrocytes pH";
Physiolibrary.Interfaces.RealInput_ Hct "outgoing hematocrit (erytrocytes volume/blood volume)";
Physiolibrary.Interfaces.RealInput_ sO2 "outgoing oxygen saturation";
Physiolibrary.Interfaces.RealOutput_ pCO2_mmHg(unit = "mmHg") "alveolar partial pressure of pCO2";
equation
pCO2_mmHg = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pCO2;
tCO2_P = cHCO3 + cdCO2;
pK_ery = 6.125 - log10(1 + 10 ^ (pH_ery - 7.84 - 0.06 * sO2));
tCO2_ery = aCO2_ery * pCO2 * (1 + 10 ^ (pH_ery - pK_ery));
aCO2_ery = 0.195;
tCO2 = tCO2_ery * Hct + tCO2_P * (1 - Hct);
end BloodCO2Base;

partial model BloodCO2TransportBase
extends BloodCO2Base;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "CO2 inflow to ventilated alveols in mmol/ml";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "CO2 outflow from ventilated alveols in mmol/ml";
Physiolibrary.Interfaces.RealInput_ BloodFlow(final unit = "ml/min") "blood flow through ventilated alveols";
equation
q_in.conc = q_in.q / BloodFlow;
tCO2 = MiniliterPerLiter * (-q_out.q / BloodFlow);
end BloodCO2TransportBase;

model BloodCO2
extends HumMod.Gases.CO2.BloodCO2TransportBase;
Physiolibrary.PressureFlow.NegativePressureFlow alveolar_outflow "CO2 outflow from blood to alveol space in mmol/min";
equation
q_in.q + q_out.q + alveolar_outflow.q = 0;
alveolar_outflow.pressure = pCO2_mmHg;
end BloodCO2;

model CO2
Physiolibrary.ConcentrationFlow.ConcentrationCompartment veins(stateName = "CO2Veins.Mass[mMol]", initialSoluteMass = 86.90000000000001);
Physiolibrary.ConcentrationFlow.ConcentrationCompartment artys(stateName = "CO2Artys.Mass[mMol]", initialSoluteMass = 34.3);
TissuesWithInterstitium.TissuesCO2 CO2Tissues(skeletalMuscleCO2(vein(q(start = -14.5357))), liverCO2(vein(q(start = -31.11))), boneCO2(vein(q(start = -7.3))), brainCO2(vein(q(start = -18.5364)), tissueVeinsCO2(tCO2_P(start = 27.1283))), otherTissueCO2(vein(q(start = -8.148999999999999))), gITractCO2(vein(q(start = -24.8656))), respiratoryMuscleCO2(vein(q(start = -2.26257))), kidneyCO2(vein(q(start = -26.7849))), fatCO2(vein(q(start = -5.277))), leftHeartCO2(vein(q(start = -4.84675))), rightHeartCO2(vein(q(start = -0.914))), skinCO2(vein(q(start = -3.5889))));
Physiolibrary.Interfaces.BusConnector busConnector;
ExternalCO2 air_CO2(concentration = 0);
RespiratoryRegulations.AlveolarVentilation alveolarVentilation;
Physiolibrary.ConcentrationFlow.SolventFlowPump pulmShortCircuit;
Modelica.Blocks.Math.Feedback pulmShortCircuitFlow;
Physiolibrary.PressureFlow.Gas_FromMLtoMMOL fromMLtoMMOL;
HumMod.Gases.CO2.MeassureBloodCO2 veinsCO2(tCO2_P(start = 27.4), pCO2(start = 6.24));
HumMod.Gases.CO2.MeassureBloodCO2 artysCO2(tCO2_P(start = 26), pCO2(start = 5.33));
HumMod.Gases.CO2.BloodCO2 CO2Lung(q_in(q(start = 115.472)), pCO2(start = 5.16), tCO2_P(start = 24.9));
equation
connect(busConnector.VeinsVol, veins.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artys.SolventVolume, busConnector.ArtysVol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CO2Tissues.q_out, veins.q_out);
connect(air_CO2.q_out, alveolarVentilation.inspired);
connect(air_CO2.q_out, alveolarVentilation.expired);
connect(pulmShortCircuit.solventFlow, pulmShortCircuitFlow.y);
connect(pulmShortCircuitFlow.u1, busConnector.CardiacOutput) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.AlveolarVentilated_BloodFlow, pulmShortCircuitFlow.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(veins.q_out, pulmShortCircuit.q_in);
connect(pulmShortCircuit.q_out, artys.q_out);
connect(busConnector.Veins_pH, veinsCO2.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Veins_pH_ery, veinsCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(veinsCO2.sO2, busConnector.O2Veins_sO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsCO2.Hct, busConnector.BloodVol_Hct) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(veinsCO2.T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(alveolarVentilation.alveolar, fromMLtoMMOL.q_ML);
connect(veinsCO2.cHCO3, busConnector.CO2Veins_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{3, -3}, {3, -3}}));
connect(veins.q_out, veinsCO2.q_in);
connect(busConnector.Artys_pH, artysCO2.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Artys_pH_ery, artysCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artysCO2.sO2, busConnector.O2Artys_sO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysCO2.Hct, busConnector.BloodVol_Hct) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysCO2.T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artysCO2.q_in, artys.q_out);
connect(artysCO2.cHCO3, busConnector.CO2Artys_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{3, -3}, {3, -3}}));
connect(veinsCO2.pCO2_mmHg, busConnector.CO2Veins_pCO2);
connect(artysCO2.pCO2_mmHg, busConnector.CO2Artys_pCO2);
connect(busConnector, CO2Tissues.busConnector);
connect(CO2Lung.sO2, busConnector.O2Lung_sO2) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.AlveolarVentilated_BloodFlow, CO2Lung.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(CO2Lung.q_out, artys.q_out);
connect(CO2Lung.Hct, busConnector.BloodVol_Hct) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CO2Lung.T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CO2Lung.pCO2_mmHg, busConnector.CO2Lung_pCO2) annotation(Text(string = "%second", index = 1, extent = {{6, -5}, {6, -5}}));
connect(CO2Lung.cHCO3, busConnector.CO2Lung_cHCO3);
connect(veins.q_out, CO2Lung.q_in);
connect(fromMLtoMMOL.q_MMOL, CO2Lung.alveolar_outflow);
connect(busConnector.BarometerPressure, alveolarVentilation.EnvironmentPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.lungs_pH_plasma, CO2Lung.pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.lungs_pH_ery, CO2Lung.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(alveolarVentilation.AlveolarVentilation_STPD, busConnector.AlveolarVentilation_STPD) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(artys.q_out, CO2Tissues.q_in);
connect(alveolarVentilation.BronchiDilution, busConnector.BronchiDilution) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(fromMLtoMMOL.T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end CO2;

model MeassureBloodCO2
extends BloodCO2Base;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
equation
q_in.q = 0;
tCO2 = q_in.conc * MiniliterPerLiter;
end MeassureBloodCO2;

model TissueHCO3
extends HumMod.Gases.CO2.HendersonHasselbach;
Real tCO2(final unit = "mmol/l");
Physiolibrary.Interfaces.RealInput_ pCO2_mmHg(unit = "mmHg") "tissue venous partial pressure of CO2";
equation
pCO2_mmHg = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pCO2;
tCO2 = cHCO3 + cdCO2;
end TissueHCO3;

model FlowMeasureCO2
extends HumMod.Gases.CO2.BloodCO2Base;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "CO2 inflow to ventilated alveols in mmol/ml";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "CO2 outflow from ventilated alveols in mmol/ml";
Physiolibrary.Interfaces.RealInput_ BloodFlow(final unit = "ml/min") "blood flow through ventilated alveols";
equation
q_in.q + q_out.q = 0;
q_in.conc = q_in.q / BloodFlow;
tCO2 = MiniliterPerLiter * (-q_out.q / BloodFlow);
end FlowMeasureCO2;

package TissuesWithInterstitium
model TissuesCO2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
SkeletalMuscleCO2 skeletalMuscleCO2(initialMass = 323.9);
BoneCO2 boneCO2(initialMass = 56.2);
FatCO2 fatCO2(initialMass = 39.8);
BrainCO2 brainCO2(initialMass = 19.1);
.HumMod.Gases.CO2.TissuesWithInterstitium.RightHeartCO2 rightHeartCO2(initialMass = 0.6);
RespiratoryMuscleCO2 respiratoryMuscleCO2(initialMass = 48.1);
OtherTissueCO2 otherTissueCO2(initialMass = 50.7);
TissueCO2_liver liverCO2(initialMass = 22.8);
.HumMod.Gases.CO2.TissuesWithInterstitium.LeftHeartCO2 leftHeartCO2(initialMass = 3.5);
.HumMod.Gases.CO2.TissuesWithInterstitium.KidneyCO2 kidneyCO2(initialMass = 4.1);
.HumMod.Gases.CO2.TissuesWithInterstitium.GITractCO2 gITractCO2(initialMass = 17.6);
Physiolibrary.Interfaces.BusConnector busConnector;
SkinCO2 skinCO2(initialMass = 28.2);
Real CO2FromTissues(unit = "mmol/min");
equation
CO2FromTissues = -(q_out.q + q_in.q);
connect(q_out, skeletalMuscleCO2.vein);
connect(q_out, boneCO2.vein);
connect(q_out, otherTissueCO2.vein);
connect(q_out, respiratoryMuscleCO2.vein);
connect(q_out, fatCO2.vein);
connect(q_out, skinCO2.vein);
connect(q_out, liverCO2.vein);
connect(q_out, brainCO2.vein);
connect(q_out, kidneyCO2.vein);
connect(q_out, leftHeartCO2.vein);
connect(skeletalMuscleCO2.arty, q_in);
connect(brainCO2.arty, q_in);
connect(gITractCO2.arty, q_in);
connect(kidneyCO2.arty, q_in);
connect(leftHeartCO2.arty, q_in);
connect(rightHeartCO2.arty, q_in);
connect(rightHeartCO2.vein, q_out);
connect(boneCO2.arty, q_in);
connect(otherTissueCO2.arty, q_in);
connect(fatCO2.arty, q_in);
connect(skinCO2.arty, q_in);
connect(q_in, respiratoryMuscleCO2.arty);
connect(busConnector.bone_pH_plasma, boneCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_pH_plasma, brainCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_pH_plasma, fatCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_pH_plasma, gITractCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_pH_plasma, kidneyCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_pH_plasma, leftHeartCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_pH_plasma, liverCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_pH_plasma, otherTissueCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_pH_plasma, respiratoryMuscleCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_pH_plasma, rightHeartCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_pH_plasma, skinCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_pH_plasma, skeletalMuscleCO2.pH_plasma) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_pH_ery, boneCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_pH_ery, brainCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_pH_ery, fatCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_pH_ery, gITractCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_pH_ery, kidneyCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_pH_ery, leftHeartCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_pH_ery, liverCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_pH_ery, otherTissueCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_pH_ery, respiratoryMuscleCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_pH_ery, rightHeartCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_pH_ery, skinCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_pH_ery, skeletalMuscleCO2.pH_ery) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_sO2, boneCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_sO2, brainCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_sO2, fatCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_sO2, gITractCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_sO2, kidneyCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_sO2, leftHeartCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_sO2, liverCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_sO2, otherTissueCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_sO2, respiratoryMuscleCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_sO2, rightHeartCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_sO2, skinCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_sO2, skeletalMuscleCO2.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, boneCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, brainCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, fatCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, gITractCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, kidneyCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, leftHeartCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, liverCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, otherTissueCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, respiratoryMuscleCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, rightHeartCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, skinCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.BloodVol_Hct, skeletalMuscleCO2.Hct) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(boneCO2.Tissue_CO2FromMetabolism, busConnector.bone_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainCO2.Tissue_CO2FromMetabolism, busConnector.brain_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatCO2.Tissue_CO2FromMetabolism, busConnector.fat_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITractCO2.Tissue_CO2FromMetabolism, busConnector.GITract_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyCO2.Tissue_CO2FromMetabolism, busConnector.kidney_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartCO2.Tissue_CO2FromMetabolism, busConnector.leftHeart_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverCO2.Tissue_CO2FromMetabolism, busConnector.liver_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueCO2.Tissue_CO2FromMetabolism, busConnector.otherTissue_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleCO2.Tissue_CO2FromMetabolism, busConnector.respiratoryMuscle_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartCO2.Tissue_CO2FromMetabolism, busConnector.rightHeart_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinCO2.Tissue_CO2FromMetabolism, busConnector.skin_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleCO2.Tissue_CO2FromMetabolism, busConnector.skeletalMuscle_CO2FromMetabolism) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneCO2.BloodFlow, busConnector.bone_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainCO2.BloodFlow, busConnector.brain_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatCO2.BloodFlow, busConnector.fat_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITractCO2.BloodFlow, busConnector.GITract_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyCO2.BloodFlow, busConnector.kidney_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartCO2.BloodFlow, busConnector.leftHeart_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueCO2.BloodFlow, busConnector.otherTissue_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleCO2.BloodFlow, busConnector.respiratoryMuscle_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartCO2.BloodFlow, busConnector.rightHeart_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinCO2.BloodFlow, busConnector.skin_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleCO2.BloodFlow, busConnector.skeletalMuscle_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneCO2.T, busConnector.bone_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brainCO2.T, busConnector.brain_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fatCO2.T, busConnector.fat_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(gITractCO2.T, busConnector.GITract_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidneyCO2.T, busConnector.kidney_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeartCO2.T, busConnector.leftHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liverCO2.T, busConnector.liver_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissueCO2.T, busConnector.otherTissue_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscleCO2.T, busConnector.respiratoryMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeartCO2.T, busConnector.rightHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skinCO2.T, busConnector.skin_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscleCO2.T, busConnector.skeletalMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(boneCO2.pCO2, busConnector.bone_pCO2);
connect(brainCO2.pCO2, busConnector.brain_pCO2);
connect(fatCO2.pCO2, busConnector.fat_pCO2);
connect(gITractCO2.pCO2, busConnector.GITract_pCO2);
connect(kidneyCO2.pCO2, busConnector.kidney_pCO2);
connect(leftHeartCO2.pCO2, busConnector.leftHeart_pCO2);
connect(liverCO2.pCO2, busConnector.liver_pCO2);
connect(otherTissueCO2.pCO2, busConnector.otherTissue_pCO2);
connect(respiratoryMuscleCO2.pCO2, busConnector.respiratoryMuscle_pCO2);
connect(rightHeartCO2.pCO2, busConnector.rightHeart_pCO2);
connect(skinCO2.pCO2, busConnector.skin_pCO2);
connect(skeletalMuscleCO2.pCO2, busConnector.skeletalMuscle_pCO2);
connect(boneCO2.pCO2, busConnector.Bone_PCO2);
connect(brainCO2.pCO2, busConnector.Brain_PCO2);
connect(fatCO2.pCO2, busConnector.Fat_PCO2);
connect(gITractCO2.pCO2, busConnector.GITract_PCO2);
connect(kidneyCO2.pCO2, busConnector.Kidney_PCO2);
connect(leftHeartCO2.pCO2, busConnector.LeftHeart_PCO2);
connect(liverCO2.pCO2, busConnector.Liver_PCO2);
connect(otherTissueCO2.pCO2, busConnector.OtherTissue_PCO2);
connect(respiratoryMuscleCO2.pCO2, busConnector.RespiratoryMuscle_PCO2);
connect(rightHeartCO2.pCO2, busConnector.RightHeart_PCO2);
connect(skinCO2.pCO2, busConnector.Skin_PCO2);
connect(skeletalMuscleCO2.pCO2, busConnector.SkeletalMuscle_PCO2);
connect(boneCO2.cHCO3, busConnector.bone_cHCO3);
connect(brainCO2.cHCO3, busConnector.brain_cHCO3);
connect(fatCO2.cHCO3, busConnector.fat_cHCO3);
connect(gITractCO2.cHCO3, busConnector.GITract_cHCO3);
connect(kidneyCO2.cHCO3, busConnector.kidney_cHCO3);
connect(leftHeartCO2.cHCO3, busConnector.leftHeart_cHCO3);
connect(liverCO2.cHCO3, busConnector.liver_cHCO3);
connect(otherTissueCO2.cHCO3, busConnector.otherTissue_cHCO3);
connect(respiratoryMuscleCO2.cHCO3, busConnector.respiratoryMuscle_cHCO3);
connect(rightHeartCO2.cHCO3, busConnector.rightHeart_cHCO3);
connect(skinCO2.cHCO3, busConnector.skin_cHCO3);
connect(skeletalMuscleCO2.cHCO3, busConnector.skeletalMuscle_cHCO3);
connect(boneCO2.cHCO3_interstitial, busConnector.bone_cHCO3_interstitial);
connect(brainCO2.cHCO3_interstitial, busConnector.brain_cHCO3_interstitial);
connect(fatCO2.cHCO3_interstitial, busConnector.fat_cHCO3_interstitial);
connect(gITractCO2.cHCO3_interstitial, busConnector.GITract_cHCO3_interstitial);
connect(kidneyCO2.cHCO3_interstitial, busConnector.kidney_cHCO3_interstitial);
connect(leftHeartCO2.cHCO3_interstitial, busConnector.leftHeart_cHCO3_interstitial);
connect(liverCO2.cHCO3_interstitial, busConnector.liver_cHCO3_interstitial);
connect(otherTissueCO2.cHCO3_interstitial, busConnector.otherTissue_cHCO3_interstitial);
connect(respiratoryMuscleCO2.cHCO3_interstitial, busConnector.respiratoryMuscle_cHCO3_interstitial);
connect(rightHeartCO2.cHCO3_interstitial, busConnector.rightHeart_cHCO3_interstitial);
connect(skinCO2.cHCO3_interstitial, busConnector.skin_cHCO3_interstitial);
connect(skeletalMuscleCO2.cHCO3_interstitial, busConnector.skeletalMuscle_cHCO3_interstitial);
connect(liverCO2.HepaticArtyBloodFlow, busConnector.HepaticArty_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.GITract_BloodFlow, liverCO2.PortalVeinBloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-3, 13}, {-3, 13}}));
connect(gITractCO2.vein, liverCO2.portalVein);
connect(q_in, liverCO2.hepaticArty);
end TissuesCO2;

model TissueCO2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow arty;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow vein;
Physiolibrary.ConcentrationFlow.InputPump InflowBase;
parameter Real initialMass;
Physiolibrary.Interfaces.RealInput_ pH_plasma "outgoing plasma pH";
Physiolibrary.Interfaces.RealInput_ pH_ery "outgoing intracellular erytrocytes pH";
Physiolibrary.Interfaces.RealInput_ BloodFlow "blood flow through ventilated alveols";
Physiolibrary.Interfaces.RealInput_ T "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ sO2 "outgoing oxygen saturation";
Physiolibrary.Interfaces.RealInput_ Hct "outgoing hematocrit (erytrocytes volume/blood volume)";
Physiolibrary.Interfaces.RealInput_ Tissue_CO2FromMetabolism "Co2 flow from metabolism";
Physiolibrary.Interfaces.RealOutput_ pCO2(start = 45);
Physiolibrary.Interfaces.RealOutput_ cHCO3;
Physiolibrary.Interfaces.RealOutput_ cHCO3_interstitial;
Physiolibrary.ConcentrationFlow.SolventFlowPump tissueFlow;
FlowMeasureCO2 tissueVeinsCO2;
Modelica.Blocks.Math.Gain DonnansCoeficient(k = 1.04);
equation
connect(arty, tissueFlow.q_in);
connect(tissueFlow.solventFlow, BloodFlow);
connect(tissueVeinsCO2.pCO2_mmHg, pCO2);
connect(tissueVeinsCO2.cHCO3, cHCO3);
connect(tissueVeinsCO2.T, T);
connect(tissueVeinsCO2.Hct, Hct);
connect(tissueVeinsCO2.sO2, sO2);
connect(tissueVeinsCO2.pH, pH_plasma);
connect(pH_ery, tissueVeinsCO2.pH_ery);
connect(InflowBase.q_out, tissueVeinsCO2.q_in);
connect(tissueFlow.q_out, tissueVeinsCO2.q_in);
connect(tissueVeinsCO2.q_out, vein);
connect(BloodFlow, tissueVeinsCO2.BloodFlow);
connect(InflowBase.desiredFlow, Tissue_CO2FromMetabolism);
connect(DonnansCoeficient.y, cHCO3_interstitial);
connect(tissueVeinsCO2.cHCO3, DonnansCoeficient.u);
end TissueCO2;

model TissueCO2_liver
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow vein;
Physiolibrary.ConcentrationFlow.InputPump InflowBase;
parameter Real initialMass;
Physiolibrary.Interfaces.RealInput_ pH_plasma "outgoing plasma pH";
Physiolibrary.Interfaces.RealInput_ pH_ery "outgoing intracellular erytrocytes pH";
Physiolibrary.Interfaces.RealInput_ T "outgoing temperature";
Physiolibrary.Interfaces.RealInput_ sO2 "outgoing oxygen saturation";
Physiolibrary.Interfaces.RealInput_ Hct "outgoing hematocrit (erytrocytes volume/blood volume)";
Physiolibrary.Interfaces.RealOutput_ pCO2;
Physiolibrary.Interfaces.RealOutput_ cHCO3;
Physiolibrary.Interfaces.RealOutput_ cHCO3_interstitial;
Physiolibrary.ConcentrationFlow.SolventFlowPump tissueFlow;
FlowMeasureCO2 tissueVeinsCO2;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow portalVein;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow hepaticArty;
Physiolibrary.Interfaces.RealInput_ HepaticArtyBloodFlow "blood flow through hepatic artery";
Physiolibrary.Interfaces.RealInput_ PortalVeinBloodFlow "blood flow through portal vein";
Modelica.Blocks.Math.Add add;
Physiolibrary.Interfaces.RealInput_ Tissue_CO2FromMetabolism "Co2 flow from metabolism";
Modelica.Blocks.Math.Gain DonnansCoeficient(k = 1.04);
equation
connect(tissueVeinsCO2.pCO2_mmHg, pCO2);
connect(tissueVeinsCO2.cHCO3, cHCO3);
connect(tissueVeinsCO2.T, T);
connect(tissueVeinsCO2.Hct, Hct);
connect(tissueVeinsCO2.sO2, sO2);
connect(tissueVeinsCO2.pH, pH_plasma);
connect(pH_ery, tissueVeinsCO2.pH_ery);
connect(InflowBase.q_out, tissueVeinsCO2.q_in);
connect(tissueFlow.q_out, tissueVeinsCO2.q_in);
connect(tissueVeinsCO2.q_out, vein);
connect(hepaticArty, tissueFlow.q_in);
connect(tissueVeinsCO2.q_in, portalVein);
connect(HepaticArtyBloodFlow, tissueFlow.solventFlow);
connect(PortalVeinBloodFlow, add.u2);
connect(HepaticArtyBloodFlow, add.u1);
connect(add.y, tissueVeinsCO2.BloodFlow);
connect(InflowBase.desiredFlow, Tissue_CO2FromMetabolism);
connect(DonnansCoeficient.y, cHCO3_interstitial);
connect(tissueVeinsCO2.cHCO3, DonnansCoeficient.u);
end TissueCO2_liver;

model SkeletalMuscleCO2
extends TissueCO2;
end SkeletalMuscleCO2;

model BoneCO2
extends TissueCO2;
end BoneCO2;

model OtherTissueCO2
extends TissueCO2;
end OtherTissueCO2;

model RespiratoryMuscleCO2
extends TissueCO2;
end RespiratoryMuscleCO2;

model FatCO2
extends TissueCO2;
end FatCO2;

model SkinCO2
extends TissueCO2;
end SkinCO2;

model BrainCO2
extends TissueCO2;
end BrainCO2;

model GITractCO2
extends TissueCO2;
end GITractCO2;

model LeftHeartCO2
extends TissueCO2;
end LeftHeartCO2;

model RightHeartCO2
extends TissueCO2;
end RightHeartCO2;

model KidneyCO2
extends TissueCO2;
end KidneyCO2;
end TissuesWithInterstitium;

model ExternalCO2
extends Physiolibrary.ConcentrationFlow.UnlimitedStorage;
end ExternalCO2;
end CO2;

package AcidBase  "Body Acid-Base Balance"
partial model BloodPhBase
Real betaX(unit = "mEq/l") "buffer value of blood";
Real betaP(unit = "mEq/l") "buffer value of plasma";
Real _cTH(unit = "mEq/l") "total concentration of tiratable hydrogen ions";
Real _BE(unit = "mEq/l") "base excess";
Real _BEox(unit = "mEq/l") "base excess in fully oxygenated blood";
Real _cTHox(unit = "mEq/l") "total concentration of tiratable hydrogen ions in fully oxygenated blood";
Physiolibrary.Interfaces.RealOutput_ pH(start = 7.4) "plasma pH";
Physiolibrary.Interfaces.RealOutput_ pH_ery "intracellular erytrocytes pH";
Physiolibrary.Interfaces.RealInput_ cHCO3(final unit = "mmol/l") "concentration of plasma HCO3 ions (default=24.5mmol/l)";
Physiolibrary.Interfaces.RealInput_ ctHb(final unit = "mmol/l") "concentration of total haemoglobin in whole blood (8.4)";
parameter Real cHb(unit = "mmol/l") = 43 "an empirical parameter accounting for erythrocyte plasma distributions = concentration of Hb inside erythrocytes divided by (1-0.57)";
Physiolibrary.Interfaces.RealInput_ sO2 "oxygen saturation";
Physiolibrary.Interfaces.RealInput_ ctAlb(final unit = "mmol/l") "concentration of total plasma albumins(dofault=0.65mmol/l)";
Physiolibrary.Interfaces.RealInput_ ctGlb(final unit = "g/l") "concentration of total plasma globulins";
Physiolibrary.Interfaces.RealInput_ ctPO4(final unit = "mmol/l") "concentration of total inorganic phosphate in plasma";
equation
_cTH = -(1 - ctHb / cHb) * (cHCO3 - 24.5 + betaX * (pH - 7.4));
betaX = 2.3 * ctHb + betaP;
betaP = 8 * ctAlb + 0.075 * ctGlb + 0.309 * ctPO4;
_cTH = homotopy(_cTHox - 0.3 * (1 - sO2), _cTHox);
_BEox = -_cTHox;
_BE = -_cTH;
pH_ery = homotopy(7.19 + 0.77 * (pH - 7.4) + 0.035 * (1 - sO2), 7.19 + 0.77 * (pH - 7.4));
end BloodPhBase;

package Tissues  "Acidity of tissue veins, interstitium or intracellular space"
model TissuesPh_interstitial
SkeletalMuscleInterstitialPh skeletalMuscle;
BoneInterstitialPh bone;
FatInterstitialPh fat;
BrainInterstitialPh brain;
RightHeartInterstitialPh rightHeart;
RespiratoryMuscleInterstitialPh respiratoryMuscle;
OtherTissueInterstitialPh otherTissue;
LiverInterstitialPh liver;
LeftHeartInterstitialPh leftHeart;
KidneyInterstitialPh kidney;
GITractInterstitialPh GITract;
Physiolibrary.Interfaces.BusConnector busConnector;
SkinInterstitialPh skin;
equation
connect(busConnector.bone_cHCO3_interstitial, bone.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_cHCO3_interstitial, brain.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_cHCO3_interstitial, fat.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_cHCO3_interstitial, GITract.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_cHCO3_interstitial, kidney.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_cHCO3_interstitial, leftHeart.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_cHCO3_interstitial, liver.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_cHCO3_interstitial, otherTissue.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_cHCO3_interstitial, respiratoryMuscle.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_cHCO3_interstitial, rightHeart.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_cHCO3_interstitial, skin.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_cHCO3_interstitial, skeletalMuscle.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_pCO2, bone.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_pCO2, brain.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_pCO2, fat.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_pCO2, GITract.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_pCO2, kidney.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_pCO2, leftHeart.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_pCO2, liver.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_pCO2, otherTissue.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_pCO2, respiratoryMuscle.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_pCO2, rightHeart.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_pCO2, skin.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_pCO2, skeletalMuscle.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_T, bone.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_T, brain.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_T, fat.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_T, GITract.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_T, kidney.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_T, leftHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_T, liver.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_T, otherTissue.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_T, respiratoryMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_T, rightHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_T, skin.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_T, skeletalMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(bone.pH_interstitial, busConnector.bone_pH_interstitial);
connect(brain.pH_interstitial, busConnector.brain_pH_interstitial);
connect(fat.pH_interstitial, busConnector.fat_pH_interstitial);
connect(GITract.pH_interstitial, busConnector.GITract_pH_interstitial);
connect(kidney.pH_interstitial, busConnector.kidney_pH_interstitial);
connect(leftHeart.pH_interstitial, busConnector.leftHeart_pH_interstitial);
connect(liver.pH_interstitial, busConnector.liver_pH_interstitial);
connect(otherTissue.pH_interstitial, busConnector.otherTissue_pH_interstitial);
connect(rightHeart.pH_interstitial, busConnector.rightHeart_pH_interstitial);
connect(respiratoryMuscle.pH_interstitial, busConnector.respiratoryMuscle_pH_interstitial);
connect(skin.pH_interstitial, busConnector.skin_pH_interstitial);
connect(skeletalMuscle.pH_interstitial, busConnector.skeletalMuscle_pH_interstitial);
end TissuesPh_interstitial;

model TissuePh_interstitial
Physiolibrary.Interfaces.RealInput_ cHCO3(final unit = "mEq/ml") "tissue interstitial bicarbonate concentration";
Physiolibrary.Interfaces.RealOutput_ pH_interstitial "tissue interstitial pH";
CO2.TissueHCO3 interstitium;
Modelica.Blocks.Math.InverseBlockConstraints inverseBlockConstraints;
Physiolibrary.Interfaces.RealInput_ T(final unit = "degC") "tissue interstitial bicarbonate concentration";
Physiolibrary.Interfaces.RealInput_ pCO2(final unit = "mmHg") "tissue interstitial bicarbonate concentration";
equation
connect(interstitium.cHCO3, inverseBlockConstraints.u2);
connect(interstitium.pH, inverseBlockConstraints.y2);
connect(interstitium.T, T);
connect(inverseBlockConstraints.y1, pH_interstitial);
connect(interstitium.pCO2_mmHg, pCO2);
connect(cHCO3, inverseBlockConstraints.u1);
end TissuePh_interstitial;

model TissuesPh_intracellular
SkeletalMuscleIntracellularPh skeletalMuscle;
BoneIntracellularPh bone;
FatIntracellularPh fat;
BrainIntracellularPh brain;
RightHeartIntracellularPh rightHeart;
RespiratoryMuscleIntracellularPh respiratoryMuscle;
OtherTissueIntracellularPh otherTissue;
LiverIntracellularPh liver;
LeftHeartIntracellularPh leftHeart;
KidneyIntracellularPh kidney;
GITractIntracellularPh GITract;
Physiolibrary.Interfaces.BusConnector busConnector;
SkinIntracellularPh skin;
equation
connect(busConnector.KCell_conc_per_liter, bone.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, brain.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, fat.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, GITract.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, kidney.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, leftHeart.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, liver.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, otherTissue.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, respiratoryMuscle.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, rightHeart.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, skin.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.KCell_conc_per_liter, skeletalMuscle.KCell) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_cLactate, bone.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_cLactate, brain.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_cLactate, fat.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_cLactate, GITract.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_cLactate, kidney.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_cLactate, leftHeart.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_cLactate, liver.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_cLactate, otherTissue.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_cLactate, respiratoryMuscle.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_cLactate, rightHeart.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_cLactate, skin.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_cLactate, skeletalMuscle.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_pCO2, bone.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_pCO2, brain.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_pCO2, fat.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_pCO2, GITract.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_pCO2, kidney.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_pCO2, leftHeart.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_pCO2, liver.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_pCO2, otherTissue.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_pCO2, respiratoryMuscle.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_pCO2, rightHeart.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_pCO2, skin.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_pCO2, skeletalMuscle.pCO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(bone.pH, busConnector.bone_pH_intracellular);
connect(brain.pH, busConnector.brain_pH_intracellular);
connect(fat.pH, busConnector.fat_pH_intracellular);
connect(GITract.pH, busConnector.GITract_pH_intracellular);
connect(kidney.pH, busConnector.kidney_pH_intracellular);
connect(leftHeart.pH, busConnector.leftHeart_pH_intracellular);
connect(liver.pH, busConnector.liver_pH_intracellular);
connect(otherTissue.pH, busConnector.otherTissue_pH_intracellular);
connect(rightHeart.pH, busConnector.rightHeart_pH_intracellular);
connect(respiratoryMuscle.pH, busConnector.respiratoryMuscle_pH_intracellular);
connect(skin.pH, busConnector.skin_pH_intracellular);
connect(skeletalMuscle.pH, busConnector.skeletalMuscle_pH_intracellular);
end TissuesPh_intracellular;

model TissuePh_intracellular
parameter Real CellSID_OtherCations(final unit = "mEq/l") = 12;
parameter Real CellSID_StrongAnions(final unit = "mEq/l") = 117;
Physiolibrary.Interfaces.RealInput_ KCell(final unit = "mEq/l") "tissue interstitial titratable acidity";
Physiolibrary.Interfaces.RealInput_ cLactate(final unit = "mEq/l") "tissue lactate concentration";
Physiolibrary.Interfaces.RealOutput_ pH "tissue intracellular pH";
Physiolibrary.Interfaces.RealInput_ pCO2(final unit = "mmHg") "tissue partial CO2 pressure";
Modelica.Blocks.Math.Add cations;
Modelica.Blocks.Math.Add anions;
Modelica.Blocks.Math.Feedback SID "intracellular";
Physiolibrary.Blocks.ElectrolytesConcentrationConstant_per_l electrolytesConcentrationConstant_per_l1(k = CellSID_OtherCations);
Physiolibrary.Blocks.ElectrolytesConcentrationConstant_per_l electrolytesConcentrationConstant_per_l2(k = CellSID_StrongAnions);
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Log10 log10_1;
Modelica.Blocks.Math.Add add1;
Physiolibrary.Blocks.Constant const(k = 7.15);
Modelica.Blocks.Math.Max max;
Physiolibrary.Blocks.Constant PCO2_min_value(k = 0.001);
Physiolibrary.Blocks.Constant PCO2_min_value1(k = 10 ^ (-7.15));
Modelica.Blocks.Math.Max max1;
equation
connect(anions.y, SID.u2);
connect(cations.y, SID.u1);
connect(electrolytesConcentrationConstant_per_l1.y, cations.u2);
connect(electrolytesConcentrationConstant_per_l2.y, anions.u1);
connect(KCell, cations.u1);
connect(cLactate, anions.u2);
connect(log10_1.y, add1.u1);
connect(add1.y, pH);
connect(const.y, add1.u2);
connect(SID.y, division.u1);
connect(max.y, division.u2);
connect(pCO2, max.u2);
connect(PCO2_min_value.y, max.u1);
connect(PCO2_min_value1.y, max1.u1);
connect(max1.u2, division.y);
connect(max1.y, log10_1.u);
end TissuePh_intracellular;

model SkeletalMuscleInterstitialPh
extends TissuePh_interstitial;
end SkeletalMuscleInterstitialPh;

model BoneInterstitialPh
extends TissuePh_interstitial;
end BoneInterstitialPh;

model OtherTissueInterstitialPh
extends TissuePh_interstitial;
end OtherTissueInterstitialPh;

model RespiratoryMuscleInterstitialPh
extends TissuePh_interstitial;
end RespiratoryMuscleInterstitialPh;

model FatInterstitialPh
extends TissuePh_interstitial;
end FatInterstitialPh;

model SkinInterstitialPh
extends TissuePh_interstitial;
end SkinInterstitialPh;

model LiverInterstitialPh
extends TissuePh_interstitial;
end LiverInterstitialPh;

model BrainInterstitialPh
extends TissuePh_interstitial;
end BrainInterstitialPh;

model GITractInterstitialPh
extends TissuePh_interstitial;
end GITractInterstitialPh;

model KidneyInterstitialPh
extends TissuePh_interstitial;
end KidneyInterstitialPh;

model LeftHeartInterstitialPh
extends TissuePh_interstitial;
end LeftHeartInterstitialPh;

model RightHeartInterstitialPh
extends TissuePh_interstitial;
end RightHeartInterstitialPh;

model SkeletalMuscleIntracellularPh
extends TissuePh_intracellular;
end SkeletalMuscleIntracellularPh;

model BoneIntracellularPh
extends TissuePh_intracellular;
end BoneIntracellularPh;

model OtherTissueIntracellularPh
extends TissuePh_intracellular;
end OtherTissueIntracellularPh;

model RespiratoryMuscleIntracellularPh
extends TissuePh_intracellular;
end RespiratoryMuscleIntracellularPh;

model FatIntracellularPh
extends TissuePh_intracellular;
end FatIntracellularPh;

model SkinIntracellularPh
extends TissuePh_intracellular;
end SkinIntracellularPh;

model LiverIntracellularPh
extends TissuePh_intracellular;
end LiverIntracellularPh;

model BrainIntracellularPh
extends TissuePh_intracellular;
end BrainIntracellularPh;

model GITractIntracellularPh
extends TissuePh_intracellular;
end GITractIntracellularPh;

model KidneyIntracellularPh
extends TissuePh_intracellular;
end KidneyIntracellularPh;

model LeftHeartIntracellularPh
extends TissuePh_intracellular;
end LeftHeartIntracellularPh;

model RightHeartIntracellularPh
extends TissuePh_intracellular;
end RightHeartIntracellularPh;
end Tissues;

model AcidBase3
ExtracellularPhMeassure2 artysPH(_BEox(start = -0.177));
ExtracellularPhMeassure2 veinsPH(_cTHox(start = 0), pH(start = 7.37));
Physiolibrary.Interfaces.BusConnector busConnector;
ExtracellularPhMeassure2 lungsPH;
Tissues_NSID.TissuesPh tissues_blood_acidity;
Tissues.TissuesPh_intracellular tissues_intracellular;
Tissues.TissuesPh_interstitial tissues_interstitial_acidity;
Modelica.Blocks.Math.Gain ml2l(k = 0.001);
HumMod.Gases.AcidBase.NormalSID normalSID;
Physiolibrary.Blocks.FractConstant sO2(k = 100);
Modelica.Blocks.Math.Feedback BEox;
equation
connect(busConnector.O2Artys_sO2, artysPH.sO2) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.O2Veins_sO2, veinsPH.sO2) annotation(Text(string = "%first", index = -1, extent = {{-6, 6}, {-6, 6}}));
connect(busConnector.ctAlb, artysPH.ctAlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CO2Artys_cHCO3, artysPH.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctAlb, veinsPH.ctAlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CO2Veins_cHCO3, veinsPH.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artysPH.pH, busConnector.Artys_pH) annotation(Text(string = "%second", index = 1, extent = {{6, -8}, {6, -8}}));
connect(artysPH.pH_ery, busConnector.Artys_pH_ery) annotation(Text(string = "%second", index = 1, extent = {{6, -13}, {6, -13}}));
connect(veinsPH.pH, busConnector.Veins_pH) annotation(Text(string = "%second", index = 1, extent = {{6, -8}, {6, -8}}));
connect(veinsPH.pH_ery, busConnector.Veins_pH_ery) annotation(Text(string = "%second", index = 1, extent = {{6, -13}, {6, -13}}));
connect(busConnector.ctGlb, artysPH.ctGlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctPO4, artysPH.ctPO4) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctGlb, veinsPH.ctGlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctPO4, veinsPH.ctPO4) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(artysPH.pH, busConnector.BloodPh_ArtysPh);
connect(busConnector.ctAlb, lungsPH.ctAlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(lungsPH.pH, busConnector.Lung_pH) annotation(Text(string = "%second", index = 1, extent = {{6, -8}, {6, -8}}));
connect(lungsPH.pH_ery, busConnector.Lung_pH_ery) annotation(Text(string = "%second", index = 1, extent = {{6, -13}, {6, -13}}));
connect(busConnector.ctGlb, lungsPH.ctGlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctPO4, lungsPH.ctPO4) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.O2Lung_sO2, lungsPH.sO2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CO2Lung_cHCO3, lungsPH.cHCO3) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector, tissues_blood_acidity.busConnector);
connect(tissues_intracellular.busConnector, busConnector);
connect(busConnector, tissues_interstitial_acidity.busConnector);
connect(lungsPH.pH, busConnector.lungs_pH_plasma);
connect(lungsPH.pH_ery, busConnector.lungs_pH_ery);
connect(busConnector.ctHb, veinsPH.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctHb, lungsPH.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctHb, artysPH.ctHb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BloodVolume, ml2l.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BloodVol_Hct, normalSID.Hct) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.HeatCore_Temp, normalSID.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctHb_ery, normalSID.tHb_E) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctAlb, normalSID.ctAlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctGlb, normalSID.ctGlb) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctPO4, normalSID.ctPO4_E) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ctPO4, normalSID.ctPO4_P) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(sO2.y, normalSID.sO2);
connect(normalSID.NSID, BEox.u2);
connect(BEox.y, busConnector.Blood_BEox) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.BloodIons_SID, BEox.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(BEox.y, veinsPH.BEox);
connect(BEox.y, lungsPH.BEox);
connect(BEox.y, artysPH.BEox);
end AcidBase3;

package buffers
model Bicarbonate
extends BufferInterface;
Physiolibrary.Interfaces.RealInput pCO2(unit = "mmHg");
Physiolibrary.Interfaces.RealInput T(unit = "degC");
Real pCO2_kPa;
Real pK;
Real aCO2;
Real cdCO2;
equation
pCO2 = Physiolibrary.NonSIunits.PaTOmmHg * 1000 * pCO2_kPa;
pK = 6.1 + (-0.0026) * (T - 37);
aCO2 = 0.23 * 10 ^ (-0.0092 * (T - 37));
cdCO2 = aCO2 * pCO2_kPa;
y = -cdCO2 * 10 ^ (pH - pK);
end Bicarbonate;

model Albumin
extends BufferInterface;
Physiolibrary.Interfaces.RealInput tAlb(unit = "mmol/l");
Real tAlb_g_per_dl;
parameter Real Alb_MolarMass(unit = "g/mol") = 66463;
equation
tAlb_g_per_dl = tAlb / 1000 * Alb_MolarMass / 10;
y = -10 * tAlb_g_per_dl * (0.123 * pH - 0.631);
end Albumin;

model Globulins
extends BufferInterface;
Physiolibrary.Interfaces.RealInput ctGlb;
equation
y = -ctGlb * (0.075 / 0.77 * (pH - 7.4) + 2.5 / 28);
end Globulins;

model Phosphates
extends BufferInterface;
Physiolibrary.Interfaces.RealInput tPO4;
parameter Real pKa1 = 2.1;
parameter Real pKa2 = 6.8;
parameter Real pKa3 = 12.7;
equation
y = -tPO4 * (10 ^ (pKa2 - pH) + 2 + 3 * 10 ^ (pH - pKa3)) / (10 ^ (pKa1 + pKa2 - 2 * pH) + 10 ^ (pKa2 - pH) + 1 + 10 ^ (pH - pKa3));
end Phosphates;

model Haemoglobin
extends BufferInterface;
Physiolibrary.Interfaces.RealInput tHb_E "total concentration of haemoglobin in erythrocytes";
Physiolibrary.Interfaces.RealInput sO2 "saturation of haemoglobin by O2";
Physiolibrary.Interfaces.RealInput pCO2 "partial pressure of CO2";
parameter Real betaOxyHb = 3.1 "buffer value for oxygenated Hb without CO2";
parameter Real betaDeoxyHb = 3.3 "buffer value for Hb without O2 and CO2";
parameter Real pIo = 7.13 "isoelectric pH for oxygenated Hb without CO2";
parameter Real pIr = 7.32 "isoelectric pH for Hb without O2 and CO2";
parameter Real pKzO = 8.08 "pKa for NH3+ end of oxygenated haemoglobin chain";
parameter Real pKzR = 7.14 "pKa for NH3+ end of deoxygenated haemoglobin chain";
parameter Real pKcO = 4.62 "10^(pH-pKcO) is the dissociation constatnt for O2HbNH2 + CO2 <-> O2HbNHCOO- + H+ ";
parameter Real pKcR = 4.62 "10^(pH-pKcR) is the dissociation constatnt for HbNH2 + CO2 <-> HbNHCOO- + H+ ";
parameter Real KcR = 10 ^ (-pKcR);
parameter Real KzR = 10 ^ (-pKzR);
parameter Real KcO = 10 ^ (-pKcO);
parameter Real KzO = 10 ^ (-pKzO);
Real carbaminohaemoglobin;
Real sCO2;
Real zOxyHb;
Real zDeoxyHb;
Real zOxyCarbaminoHb;
Real zDeoxyCarbaminoHb;
Real H = 10 ^ (-pH);
Real aCO2;
Real cdCO2;
Physiolibrary.Interfaces.RealInput T;
equation
aCO2 = 0.23 * 10 ^ (-0.0092 * (T - 37));
cdCO2 = aCO2 * pCO2 * 0.001;
carbaminohaemoglobin = tHb_E * cdCO2 * (H * H * ((1 - sO2) / (KzO * KcO) + sO2 / (KzR * KcR)) + H * ((1 - sO2) / KcO + sO2 / KcR) + cdCO2) / ((H * H / (KzR * KcR) + H / KcR + cdCO2) * (H * H / (KzO * KcO) + H / KcO + cdCO2));
sCO2 = carbaminohaemoglobin / tHb_E;
y = -tHb_E * (sO2 * (1 - sCO2) * zOxyHb + (1 - sO2) * (1 - sCO2) * zDeoxyHb + sO2 * sCO2 * zOxyCarbaminoHb + (1 - sO2) * sCO2 * zDeoxyCarbaminoHb);
zOxyHb = betaOxyHb * (pH - pIo);
zDeoxyHb = betaDeoxyHb * (pH - pIr);
zOxyCarbaminoHb = zOxyHb + (1 + 2 * 10 ^ (pKzO - pH)) / (1 + 10 ^ (pKzO - pH));
zDeoxyCarbaminoHb = zDeoxyHb + (1 + 2 * 10 ^ (pKzR - pH)) / (1 + 10 ^ (pKzR - pH));
end Haemoglobin;

partial model BufferInterface
Physiolibrary.Interfaces.RealInput pH;
Physiolibrary.Interfaces.RealOutput y(unit = "e.mmol/l") "charge of buffer";
end BufferInterface;
end buffers;

model NormalSID
Physiolibrary.Interfaces.RealInput_ sO2 "oxygen saturation";
Physiolibrary.Interfaces.RealInput_ ctAlb(final unit = "mmol/l") "concentration of total plasma albumins(dofault=0.65mmol/l)";
Physiolibrary.Interfaces.RealInput_ ctGlb(final unit = "g/l") "concentration of total plasma globulins";
Physiolibrary.Interfaces.RealInput_ ctPO4_P(final unit = "mmol/l") "concentration of total inorganic phosphate in plasma";
Physiolibrary.Interfaces.RealOutput NSID;
Physiolibrary.Interfaces.RealInput_ Hct "hematocrit";
buffers.Bicarbonate bicarbonate;
buffers.Albumin albumin;
Modelica.Blocks.Math.Sum NSIDP(nin = 4);
buffers.Globulins globulins;
buffers.Phosphates phosphates;
buffers.Haemoglobin haemoglobin;
buffers.Phosphates phosphates1;
Modelica.Blocks.Math.Sum NSIDE(nin = 3);
Modelica.Blocks.Math.Feedback Pct;
Modelica.Blocks.Math.Product product1;
Modelica.Blocks.Math.Product product2;
Modelica.Blocks.Math.Add add(k1 = -1, k2 = -1);
Modelica.Blocks.Sources.Constant const(k = 1);
Modelica.Blocks.Sources.Constant n_pH_P(k = 7.4);
Modelica.Blocks.Sources.Constant n_pCO2(k = 40);
Physiolibrary.Interfaces.RealInput_ T "temperature";
buffers.Bicarbonate bicarbonate1;
Modelica.Blocks.Sources.Constant n_pH_E(k = 7.19) "should be calculated, but how?";
Physiolibrary.Interfaces.RealInput_ ctPO4_E(final unit = "mmol/l") "concentration of total inorganic phosphate in erythrocytes";
Physiolibrary.Interfaces.RealInput_ tHb_E "haemoglobin concentration in erythrocyte";
equation
connect(ctAlb, albumin.tAlb);
connect(bicarbonate.y, NSIDP.u[1]);
connect(albumin.y, NSIDP.u[2]);
connect(globulins.y, NSIDP.u[3]);
connect(phosphates.y, NSIDP.u[4]);
connect(Hct, Pct.u2);
connect(add.y, NSID);
connect(product1.y, add.u2);
connect(product2.y, add.u1);
connect(Pct.y, product2.u2);
connect(Hct, product1.u1);
connect(NSIDE.y, product1.u2);
connect(NSIDP.y, product2.u1);
connect(const.y, Pct.u1);
connect(n_pH_P.y, albumin.pH);
connect(n_pH_P.y, globulins.pH);
connect(n_pH_P.y, phosphates.pH);
connect(n_pH_P.y, bicarbonate.pH);
connect(T, bicarbonate.T);
connect(bicarbonate1.y, NSIDE.u[1]);
connect(haemoglobin.y, NSIDE.u[2]);
connect(phosphates1.y, NSIDE.u[3]);
connect(n_pCO2.y, bicarbonate.pCO2);
connect(n_pCO2.y, bicarbonate1.pCO2);
connect(n_pH_E.y, bicarbonate1.pH);
connect(n_pH_E.y, haemoglobin.pH);
connect(n_pH_E.y, phosphates1.pH);
connect(T, bicarbonate1.T);
connect(ctPO4_P, phosphates.tPO4);
connect(ctPO4_E, phosphates1.tPO4);
connect(tHb_E, haemoglobin.tHb_E);
connect(sO2, haemoglobin.sO2);
connect(n_pCO2.y, haemoglobin.pCO2);
connect(T, haemoglobin.T);
connect(ctGlb, globulins.ctGlb);
end NormalSID;

model ExtracellularPhMeassure2
extends HumMod.Gases.AcidBase.BloodPhBase;
Physiolibrary.Interfaces.RealInput BEox;
equation
_BEox = BEox;
end ExtracellularPhMeassure2;

package Tissues_NSID  "Acidity of tissue veins, interstitium or intracellular space"
model TissuesPh
SkeletalMuscleBloodPh skeletalMuscle;
BoneBloodPh bone;
FatBloodPh fat;
BrainBloodPh brain;
RightHeartBloodPh rightHeart;
RespiratoryMuscleBloodPh respiratoryMuscle;
OtherTissueBloodPh otherTissue;
LiverBloodPh liver;
LeftHeartBloodPh leftHeart;
KidneyBloodPh kidney;
GITractBloodPh GITract;
Physiolibrary.Interfaces.BusConnector busConnector;
SkinBloodPh skin;
Modelica.Blocks.Math.Add cTH_lessLactate(k1 = -1, k2 = -1);
equation
connect(busConnector.bone_sO2, bone.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_sO2, brain.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_sO2, fat.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_sO2, GITract.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_sO2, kidney.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_sO2, leftHeart.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_sO2, liver.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_sO2, otherTissue.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_sO2, respiratoryMuscle.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_sO2, rightHeart.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_sO2, skin.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_sO2, skeletalMuscle.sO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_T, bone.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_T, brain.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_T, fat.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_T, GITract.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_T, kidney.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_T, leftHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_T, liver.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_T, otherTissue.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_T, respiratoryMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_T, rightHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_T, skin.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_T, skeletalMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, bone.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, brain.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, fat.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, GITract.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, kidney.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, leftHeart.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, liver.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, otherTissue.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, respiratoryMuscle.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, rightHeart.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(cTH_lessLactate.y, skin.ctHox_lessLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.bone_cLactate, bone.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.brain_cLactate, brain.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.fat_cLactate, fat.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.GITract_cLactate, GITract.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.kidney_cLactate, kidney.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.leftHeart_cLactate, leftHeart.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.liver_cLactate, liver.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.otherTissue_cLactate, otherTissue.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.respiratoryMuscle_cLactate, respiratoryMuscle.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.rightHeart_cLactate, rightHeart.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skin_cLactate, skin.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(busConnector.skeletalMuscle_cLactate, skeletalMuscle.cLactate) annotation(Text(string = "%first", index = -1, extent = {{-5, 2}, {-5, 2}}));
connect(bone.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.ctHb, busConnector.ctHb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.ctAlb, busConnector.ctAlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.ctGlb, busConnector.ctGlb) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.ctPO4, busConnector.ctPO4) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.cHCO3, busConnector.bone_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.cHCO3, busConnector.brain_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.cHCO3, busConnector.fat_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.cHCO3, busConnector.GITract_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.cHCO3, busConnector.kidney_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.cHCO3, busConnector.leftHeart_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.cHCO3, busConnector.liver_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.cHCO3, busConnector.otherTissue_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.cHCO3, busConnector.respiratoryMuscle_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.cHCO3, busConnector.rightHeart_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.cHCO3, busConnector.skin_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.cHCO3, busConnector.skeletalMuscle_cHCO3) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.pH_ery, busConnector.bone_pH_ery);
connect(brain.pH_ery, busConnector.brain_pH_ery);
connect(fat.pH_ery, busConnector.fat_pH_ery);
connect(GITract.pH_ery, busConnector.GITract_pH_ery);
connect(kidney.pH_ery, busConnector.kidney_pH_ery);
connect(leftHeart.pH_ery, busConnector.leftHeart_pH_ery);
connect(liver.pH_ery, busConnector.liver_pH_ery);
connect(otherTissue.pH_ery, busConnector.otherTissue_pH_ery);
connect(rightHeart.pH_ery, busConnector.rightHeart_pH_ery);
connect(respiratoryMuscle.pH_ery, busConnector.respiratoryMuscle_pH_ery);
connect(skin.pH_ery, busConnector.skin_pH_ery);
connect(skeletalMuscle.pH_ery, busConnector.skeletalMuscle_pH_ery);
connect(bone.pH, busConnector.bone_pH_plasma);
connect(brain.pH, busConnector.brain_pH_plasma);
connect(fat.pH, busConnector.fat_pH_plasma);
connect(GITract.pH, busConnector.GITract_pH_plasma);
connect(kidney.pH, busConnector.kidney_pH_plasma);
connect(leftHeart.pH, busConnector.leftHeart_pH_plasma);
connect(liver.pH, busConnector.liver_pH_plasma);
connect(otherTissue.pH, busConnector.otherTissue_pH_plasma);
connect(rightHeart.pH, busConnector.rightHeart_pH_plasma);
connect(respiratoryMuscle.pH, busConnector.respiratoryMuscle_pH_plasma);
connect(skin.pH, busConnector.skin_pH_plasma);
connect(skeletalMuscle.pH, busConnector.skeletalMuscle_pH_plasma);
connect(busConnector.Blood_BEox, cTH_lessLactate.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.LacPool_Lac_mEq_per_litre, cTH_lessLactate.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(cTH_lessLactate.y, skeletalMuscle.ctHox_lessLactate);
end TissuesPh;

model TissuePh
extends HumMod.Gases.AcidBase.BloodPhBase;
Physiolibrary.Interfaces.RealInput_ ctHox_lessLactate(final unit = "mEq/l") "titratable acidity of oxygenated blood";
Physiolibrary.Interfaces.RealInput_ T(final unit = "degC") "tissue interstitial bicarbonate concentration";
Physiolibrary.Interfaces.RealInput_ cLactate(final unit = "mEq/l") "titratable acidity of oxygenated blood";
equation
ctHox_lessLactate + cLactate = _cTHox;
end TissuePh;

model SkeletalMuscleBloodPh
extends TissuePh;
end SkeletalMuscleBloodPh;

model BoneBloodPh
extends TissuePh;
end BoneBloodPh;

model OtherTissueBloodPh
extends TissuePh;
end OtherTissueBloodPh;

model RespiratoryMuscleBloodPh
extends TissuePh;
end RespiratoryMuscleBloodPh;

model FatBloodPh
extends TissuePh;
end FatBloodPh;

model SkinBloodPh
extends TissuePh;
end SkinBloodPh;

model LiverBloodPh
extends TissuePh;
end LiverBloodPh;

model BrainBloodPh
extends TissuePh;
end BrainBloodPh;

model GITractBloodPh
extends TissuePh;
end GITractBloodPh;

model KidneyBloodPh
extends TissuePh;
end KidneyBloodPh;

model LeftHeartBloodPh
extends TissuePh;
end LeftHeartBloodPh;

model RightHeartBloodPh
extends TissuePh;
end RightHeartBloodPh;
end Tissues_NSID;
end AcidBase;

package RespiratoryRegulations
model RespiratoryNeuralDrive3
RespiratoryCenter2 afferentPath;
Physiolibrary.Interfaces.BusConnector busConnector;
HumMod.Gases.RespiratoryRegulations.PeripheralChemoreceptors peripheralChemoreceptors;
HumMod.Gases.RespiratoryRegulations.SkeletalMuscleMetaboreflex skeletalMuscleMetaboreflex;
HumMod.Gases.RespiratoryRegulations.CentralChemoreceptors centralChemoreceptors;
RespiratoryCenterEfferent efferentPath;
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Blocks.deprecated_HomotopyStrongComponentBreaker homotopyBreak(defaultSlope = 0.1, defaultValue = 1.02);
Modelica.Blocks.Sources.Clock clock(offset = 0.9, startTime = 0.9);
Modelica.Blocks.Logical.Switch switch1;
Modelica.Blocks.Sources.BooleanConstant booleanConstant(k = true);
equation
connect(busConnector, afferentPath.busConnector);
connect(busConnector, peripheralChemoreceptors.busConnector);
connect(peripheralChemoreceptors.Chemoreceptors_FiringRate, afferentPath.Chemoreceptors_FiringRate);
connect(skeletalMuscleMetaboreflex.NA, afferentPath.Metaboreflex);
connect(busConnector.skeletalMuscle_pH_intracellular, skeletalMuscleMetaboreflex.skeletalMuscle_pH) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, peripheralChemoreceptors.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.brain_pH_intracellular, centralChemoreceptors.Brain_pH_intracellular) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.O2Artys_PO2, peripheralChemoreceptors.artys_pO2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Artys_pH, peripheralChemoreceptors.artys_ph) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(efferentPath.RespRate, busConnector.RespiratoryCenter_RespRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(efferentPath.RespiratoryCenterOutput_MotorNerveActivity, busConnector.RespiratoryCenter_MotorNerveActivity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(efferentPath.busConnector, busConnector);
connect(homotopyBreak.u, afferentPath.TotalDrive);
connect(booleanConstant.y, switch1.u2);
connect(Constant.y, switch1.u1);
connect(clock.y, switch1.u3);
connect(centralChemoreceptors.CentralChemoreceptors, afferentPath.CentralChemoreceptors);
connect(homotopyBreak.y, efferentPath.TotalDrive);
end RespiratoryNeuralDrive3;

model RespiratoryCenter2
parameter Real[:, 3] RadiationTotalDrive = {{0, 0.0, 0}, {500, 3.5, 0.003}, {1000, 4.0, 0}};
parameter Real[:, 3] OutputRate = {{0, 0, 12}, {1, 12, 4}, {10, 40, 0}};
Physiolibrary.Interfaces.RealOutput_ TotalDrive;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ Chemoreceptors_FiringRate;
Physiolibrary.Curves.Curve Radiation(x = RadiationTotalDrive[:, 1], y = RadiationTotalDrive[:, 2], slope = RadiationTotalDrive[:, 3]);
Modelica.Blocks.Math.Add RespiratoryCenterChemical_TotalDrive(k1 = 0.6, k2 = 0.4);
Physiolibrary.Interfaces.RealInput_ Metaboreflex;
Modelica.Blocks.Math.Add RespiratoryCenterExercise_TotalDrive;
Modelica.Blocks.Math.Add RespiratoryCenterIntegration_TotalDrive;
Physiolibrary.Interfaces.RealInput_ CentralChemoreceptors;
equation
connect(Radiation.val, RespiratoryCenterExercise_TotalDrive.u2);
connect(Metaboreflex, RespiratoryCenterExercise_TotalDrive.u1);
connect(RespiratoryCenterChemical_TotalDrive.y, RespiratoryCenterIntegration_TotalDrive.u1);
connect(RespiratoryCenterExercise_TotalDrive.y, RespiratoryCenterIntegration_TotalDrive.u2);
connect(busConnector.ExerciseMetabolism_TotalWatts, Radiation.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(RespiratoryCenterChemical_TotalDrive.u1, CentralChemoreceptors);
connect(RespiratoryCenterIntegration_TotalDrive.y, TotalDrive);
connect(Chemoreceptors_FiringRate, RespiratoryCenterChemical_TotalDrive.u2);
end RespiratoryCenter2;

model RespiratoryCenterEfferent
parameter Real[:, 3] RadiationTotalDrive = {{0, 0.0, 0}, {500, 3.5, 0.003}, {1000, 4.0, 0}};
parameter Real[:, 3] OutputRate = {{0, 0, 12}, {1, 12, 4}, {10, 40, 0}};
Physiolibrary.Curves.Curve RespiratoryCenterOutput(x = OutputRate[:, 1], y = OutputRate[:, 2], slope = OutputRate[:, 3]);
Physiolibrary.Interfaces.RealOutput_ RespRate;
Physiolibrary.Interfaces.RealOutput_ RespiratoryCenterOutput_MotorNerveActivity;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ TotalDrive(start = 1);
Modelica.Blocks.Math.Product Rate;
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.Factors.SimpleMultiply AnesthesiaEffect;
equation
connect(RespiratoryCenterOutput.val, Rate.u2);
connect(Rate.y, RespRate);
connect(FunctionEffect.y, AnesthesiaEffect.yBase);
connect(AnesthesiaEffect.y, RespiratoryCenterOutput_MotorNerveActivity);
connect(busConnector.AnesthesiaTidalVolume, AnesthesiaEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.brain_FunctionEffect, FunctionEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.brain_FunctionEffect, Rate.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(TotalDrive, RespiratoryCenterOutput.u);
connect(TotalDrive, FunctionEffect.yBase);
end RespiratoryCenterEfferent;

model CentralChemoreceptors
parameter Real[:, 3] data = {{6.6, 0.0, 0}, {6.87, 10.0, 0}, {7.12, 1.0, -8.0}, {7.5, 0.0, 0}};
Physiolibrary.Interfaces.RealOutput_ CentralChemoreceptors;
Physiolibrary.Blocks.Constant Constant(k = 0.6);
Physiolibrary.Interfaces.RealInput_ Brain_pH_intracellular;
Physiolibrary.Factors.CurveValue splineValue(data = {{6.6, 0.0, 0}, {6.87, 10.0, 0}, {7.12, 1.0, -8.0}, {7.5, 0.0, 0}});
Modelica.Blocks.Math.Gain gain(k = 7.12 / 7.09) "marekov korekcny faktor medzi Tomom Colemanom(normal value=7.12) a Siggardom Andersnom(normal value=7.09), 7.137/7.095";
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
equation
connect(Constant.y, splineValue.yBase);
connect(Brain_pH_intracellular, gain.u);
connect(Brain_pH_intracellular, splineValue.u);
connect(Brain_pH_intracellular, curve.u);
connect(curve.val, CentralChemoreceptors);
end CentralChemoreceptors;

model PeripheralChemoreceptors
Physiolibrary.Curves.Curve PhEffectCurve(x = PhEffect[:, 1], y = PhEffect[:, 2], slope = PhEffect[:, 3]);
Physiolibrary.Interfaces.RealOutput_ Chemoreceptors_FiringRate;
parameter Real[:, 3] PhEffect = {{7.1, 2, 0}, {7.4, 0.4, -3}, {7.7, 0, 0}};
parameter Real[:, 3] PO2Effect = {{30, 10.0, 0}, {60, 2.0, -0.05}, {85, 0.5, -0.005}, {200, 0.2, 0}};
parameter Real[:, 3] PO2Effect_original = {{30, 10.0, 0}, {60, 2.0, -0.05}, {94, 0.5, -0.005}, {200, 0.2, 0}};
parameter Real[:, 3] SteadyState = {{0, 0, 0}, {1, 1, 0.3}, {10, 2, 0}};
parameter Real Tau(final quantity = "Time", final unit = "h") = 20;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ GangliaGeneral_NA;
HumMod.Nerves.AplhaReceptorsActivityFactor aplhaReceptorsActivityFactor(data = {{0, 0.0, 0}, {1, 0.1, 0.2}, {4, 0.6, 0}}, NEURALK = 0.5, HUMORALK = 0.5);
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Curves.Curve PO2EffectCurve(x = PO2Effect[:, 1], y = PO2Effect[:, 2], slope = PO2Effect[:, 3]);
Modelica.Blocks.Math.Sum sum(nin = 3);
Modelica.Blocks.Math.Product product;
Physiolibrary.Curves.Curve SteadyStateCurve(x = SteadyState[:, 1], y = SteadyState[:, 2], slope = SteadyState[:, 3]) "ChemoreceptorAcclimation";
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Blocks.Integrator integrator(stateName = "ChemoreceptorAcclimation.Effect", k = 1 / (60 * Tau * Physiolibrary.SecPerMin), y_start = 1.01445) "ChemoreceptorAcclimation.Effect";
Physiolibrary.Interfaces.RealInput_ artys_ph;
Physiolibrary.Interfaces.RealInput_ artys_pO2;
Physiolibrary.Curves.Curve PO2EffectCurve1(x = PO2Effect_original[:, 1], y = PO2Effect_original[:, 2], slope = PO2Effect_original[:, 3]);
equation
assert(artys_pO2 > 30, "artys_pO2 should be greater then 30 mmHg!");
connect(Constant.y, aplhaReceptorsActivityFactor.yBase);
connect(busConnector.AlphaPool_Effect, aplhaReceptorsActivityFactor.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, aplhaReceptorsActivityFactor.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(aplhaReceptorsActivityFactor.GangliaGeneral_NA, GangliaGeneral_NA);
connect(PhEffectCurve.val, sum.u[2]);
connect(aplhaReceptorsActivityFactor.y, sum.u[1]);
connect(product.y, Chemoreceptors_FiringRate);
connect(sum.y, product.u1);
connect(sum.y, SteadyStateCurve.u);
connect(integrator.y, product.u2);
connect(SteadyStateCurve.val, feedback.u1);
connect(integrator.y, feedback.u2);
connect(feedback.y, integrator.u);
connect(PhEffectCurve.u, artys_ph);
connect(PO2EffectCurve.u, artys_pO2);
connect(artys_pO2, PO2EffectCurve1.u);
connect(PO2EffectCurve1.val, sum.u[3]);
end PeripheralChemoreceptors;

model GasEquation
Physiolibrary.Interfaces.RealInput V1(final unit = "ml");
Physiolibrary.Interfaces.RealInput P1(final unit = "mmHg");
Physiolibrary.Interfaces.RealInput T1(final unit = "degC");
Physiolibrary.Interfaces.RealInput P2(final unit = "mmHg");
Physiolibrary.Interfaces.RealInput T2(final unit = "degC");
Physiolibrary.Interfaces.RealOutput V2(final unit = "ml");
equation
P1 * V1 / (T1 + 273.15) = P2 * V2 / (T2 + 273.15);
end GasEquation;

model VaporPressure
Physiolibrary.Interfaces.RealInput T(final quantity = "ThermodynamicTemperature", final unit = "degC");
Physiolibrary.Interfaces.RealOutput VaporPressure(final unit = "mmHg");
equation
VaporPressure = if T < 0 then 0 else if T > 100 then 760 else exp(18.6686 - 4030.183 / (T + 235));
end VaporPressure;

model NaturalVentilation2
Physiolibrary.Interfaces.RealInput_ RespiratoryCenterOutput_MotorNerveActivity(final unit = "Hz");
Physiolibrary.Interfaces.RealInput_ Thorax_LungInflation(final unit = "1");
Physiolibrary.Interfaces.RealInput_ ExcessLungWater_Volume(final unit = "1");
Physiolibrary.Interfaces.RealOutput_ TidalVolume(final unit = "ml");
Physiolibrary.Interfaces.RealOutput_ DeadSpace(final unit = "ml");
Physiolibrary.Interfaces.RealInput_ RespiratoryMuscleFunctionEffect(final unit = "ml");
parameter Real DeadSpaceSlope = 0.2;
parameter Real DeadSpaceMin = 60.0;
parameter Real[:, 3] DriveOnTidalVolume = {{0, 0, 0}, {1, 450, 400}, {10, 2630, 0}};
Physiolibrary.Curves.Curve curve(x = DriveOnTidalVolume[:, 1], y = DriveOnTidalVolume[:, 2], slope = DriveOnTidalVolume[:, 3]);
Physiolibrary.Factors.SimpleMultiply LungInflation;
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Modelica.Blocks.Math.Max max;
Modelica.Blocks.Math.Feedback tidalVol0;
Physiolibrary.Blocks.VolumeConstant Breathing_TidalVolumeMin(k = 0) "Breathing.TidalVolumeMin";
Physiolibrary.Blocks.VolumeConstant Breathing_DeadSpaceMin(k = DeadSpaceMin) "Breathing.DeadSpaceMin";
Physiolibrary.Blocks.Constant deadSpaceSlope(k = DeadSpaceSlope);
Modelica.Blocks.Math.Product product;
Modelica.Blocks.Math.Add add;
equation
connect(RespiratoryCenterOutput_MotorNerveActivity, curve.u);
connect(RespiratoryMuscleFunctionEffect, FunctionEffect.u);
connect(Thorax_LungInflation, LungInflation.u);
connect(curve.val, FunctionEffect.yBase);
connect(FunctionEffect.y, LungInflation.yBase);
connect(LungInflation.y, tidalVol0.u1);
connect(ExcessLungWater_Volume, tidalVol0.u2);
connect(tidalVol0.y, max.u1);
connect(Breathing_TidalVolumeMin.y, max.u2);
connect(add.y, DeadSpace);
connect(deadSpaceSlope.y, product.u2);
connect(product.y, add.u1);
connect(Breathing_DeadSpaceMin.y, add.u2);
connect(product.u1, TidalVolume);
connect(max.y, TidalVolume);
end NaturalVentilation2;

model AlveolarVentilation
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow expired annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow inspired;
Physiolibrary.Interfaces.RealInput_ AlveolarVentilation_STPD;
Physiolibrary.ConcentrationFlow.SolventFlowPump solventFlowPump(q_out(conc(start = 0.13686)));
Physiolibrary.ConcentrationFlow.Dilution dilution;
Physiolibrary.ConcentrationFlow.SolventFlowPump solventFlowPump1;
Physiolibrary.PressureFlow.NegativePressureFlow alveolar annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PartialPressure gasConcToPartialPressure;
Physiolibrary.Interfaces.RealInput_ EnvironmentPressure;
Physiolibrary.Interfaces.RealInput_ BronchiDilution;
equation
connect(inspired, dilution.q_concentrated);
connect(dilution.q_diluted, solventFlowPump.q_in);
connect(solventFlowPump1.q_out, expired);
connect(solventFlowPump.q_out, solventFlowPump1.q_in);
connect(gasConcToPartialPressure.q_in, solventFlowPump.q_out);
connect(alveolar, gasConcToPartialPressure.outflow);
connect(EnvironmentPressure, gasConcToPartialPressure.ambientPressure);
connect(AlveolarVentilation_STPD, solventFlowPump.solventFlow);
connect(AlveolarVentilation_STPD, solventFlowPump1.solventFlow);
connect(BronchiDilution, dilution.dilution);
end AlveolarVentilation;

model AlveolarVentilation_STPD_
Physiolibrary.Interfaces.RealInput_ RespRate;
Physiolibrary.Interfaces.RealInput_ TidalVolume;
Physiolibrary.Interfaces.RealInput_ DeadSpace;
Physiolibrary.Interfaces.RealInput_ core_T;
GasEquation tidalVolume(V2(start = 400));
GasEquation deadVolume(V2(start = 150));
Modelica.Blocks.Math.Product alveolarVentilation_STPD;
VaporPressure vaporPressure;
Modelica.Blocks.Math.Division vaporPart;
Physiolibrary.Blocks.Constant Constant0(k = 3176.28);
Modelica.Blocks.Math.Feedback added_pH2O;
VaporPressure vaporPressure1;
Modelica.Blocks.Math.Product air_pH2O;
Physiolibrary.Interfaces.RealInput_ AmbientTemperature;
Physiolibrary.Interfaces.RealInput_ EnvironmentPressure;
Physiolibrary.Interfaces.RealInput_ EnvironmentRelativeHumidity;
Physiolibrary.Blocks.TemperatureConstant STPD_Temperature(k = 0);
Physiolibrary.Blocks.PressureConstant STPD_Pressure(k = 760);
Modelica.Blocks.Math.Feedback alveolarVolume_STPD;
Modelica.Blocks.Math.Feedback airPressureWitoutVapor;
Physiolibrary.Interfaces.RealOutput_ AlveolarVentilation_STPD;
Modelica.Blocks.Math.Feedback dilution;
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Interfaces.RealOutput_ BronchiDilution;
equation
connect(TidalVolume, tidalVolume.V1);
connect(DeadSpace, deadVolume.V1);
connect(RespRate, alveolarVentilation_STPD.u2);
connect(core_T, vaporPressure.T);
connect(vaporPressure1.VaporPressure, air_pH2O.u2);
connect(air_pH2O.y, added_pH2O.u2);
connect(added_pH2O.y, vaporPart.u1);
connect(added_pH2O.u1, vaporPressure.VaporPressure);
connect(AmbientTemperature, vaporPressure1.T);
connect(EnvironmentRelativeHumidity, air_pH2O.u1);
connect(EnvironmentPressure, vaporPart.u2);
connect(STPD_Temperature.y, deadVolume.T2);
connect(STPD_Temperature.y, tidalVolume.T2);
connect(STPD_Pressure.y, tidalVolume.P2);
connect(STPD_Pressure.y, deadVolume.P2);
connect(core_T, tidalVolume.T1);
connect(core_T, deadVolume.T1);
connect(alveolarVolume_STPD.y, alveolarVentilation_STPD.u1);
connect(tidalVolume.V2, alveolarVolume_STPD.u1);
connect(alveolarVolume_STPD.u2, deadVolume.V2);
connect(EnvironmentPressure, airPressureWitoutVapor.u1);
connect(airPressureWitoutVapor.y, tidalVolume.P1);
connect(airPressureWitoutVapor.y, deadVolume.P1);
connect(added_pH2O.y, airPressureWitoutVapor.u2);
connect(AlveolarVentilation_STPD, alveolarVentilation_STPD.y);
connect(Constant.y, dilution.u1);
connect(vaporPart.y, dilution.u2);
connect(dilution.y, BronchiDilution);
end AlveolarVentilation_STPD_;

model Ventilation
Physiolibrary.Interfaces.BusConnector busConnector;
AlveolarVentilation_STPD_ alveolarVentilation;
NaturalVentilation2 naturalVentilation;
Modelica.Blocks.Math.Product TotalVentilation;
RespiratoryNeuralDrive3 respiratoryNeuralDrive2_1;
equation
connect(alveolarVentilation.TidalVolume, naturalVentilation.TidalVolume);
connect(alveolarVentilation.DeadSpace, naturalVentilation.DeadSpace);
connect(naturalVentilation.ExcessLungWater_Volume, busConnector.ExcessLungWater_Volume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(naturalVentilation.Thorax_LungInflation, busConnector.Thorax_LungInflation) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(naturalVentilation.RespiratoryMuscleFunctionEffect, busConnector.RespiratoryMuscleFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(naturalVentilation.RespiratoryCenterOutput_MotorNerveActivity, busConnector.RespiratoryCenter_MotorNerveActivity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(alveolarVentilation.core_T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(naturalVentilation.TidalVolume, TotalVentilation.u2);
connect(busConnector.RespiratoryCenter_RespRate, TotalVentilation.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(TotalVentilation.y, busConnector.BreathingTotalVentilation) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(alveolarVentilation.RespRate, busConnector.RespiratoryCenter_RespRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.BarometerPressure, alveolarVentilation.EnvironmentPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AmbientTemperature, alveolarVentilation.AmbientTemperature) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.EnvironmentRelativeHumidity, alveolarVentilation.EnvironmentRelativeHumidity) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(alveolarVentilation.AlveolarVentilation_STPD, busConnector.AlveolarVentilation_STPD) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(respiratoryNeuralDrive2_1.busConnector, busConnector);
connect(alveolarVentilation.BronchiDilution, busConnector.BronchiDilution) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Ventilation;

model SkeletalMuscleMetaboreflex
Physiolibrary.Interfaces.RealInput_ skeletalMuscle_pH;
Physiolibrary.Curves.Curve NerveActivity(x = PhOnNerveActivity[:, 1], y = PhOnNerveActivity[:, 2], slope = PhOnNerveActivity[:, 3]);
Physiolibrary.Interfaces.RealOutput_ NA;
parameter Real[:, 3] PhOnNerveActivity = {{6.5, 5.0, 0}, {6.9, 0.0, 0}};
equation
connect(NerveActivity.val, NA);
connect(skeletalMuscle_pH, NerveActivity.u);
end SkeletalMuscleMetaboreflex;
end RespiratoryRegulations;

model Gases
Physiolibrary.Interfaces.BusConnector busConnector;
O2.O2 oxygen;
CO2.CO2 carbonDioxyd;
AcidBase.AcidBase3 acidBase;
RespiratoryRegulations.Ventilation ventilation;
equation
connect(carbonDioxyd.busConnector, busConnector);
connect(oxygen.busConnector, busConnector);
connect(acidBase.busConnector, busConnector);
connect(ventilation.busConnector, busConnector);
end Gases;
end Gases;

package Heat  "Body Temperature Balance"

model TissuesHeat
tissues.Bone Bone;
tissues.Fat Fat;
tissues.Brain Brain;
tissues.RightHeart RightHeart;
tissues.RespiratoryMuscle RespiratoryMuscle;
tissues.OtherTissue OtherTissue;
tissues.Liver Liver;
tissues.LeftHeart LeftHeart;
tissues.Kidney Kidney;
tissues.GITract GITract;
Physiolibrary.Interfaces.BusConnector busConnector;
equation
connect(busConnector.core_T, Brain.BaseT) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.core_T, RespiratoryMuscle.BaseT) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.core_T, LeftHeart.BaseT) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.core_T, RightHeart.BaseT) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(Bone.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(Liver.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(Kidney.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(GITract.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(Fat.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(OtherTissue.BaseT, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(RightHeart.T, busConnector.rightHeart_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Brain.T, busConnector.brain_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(RespiratoryMuscle.T, busConnector.respiratoryMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LeftHeart.T, busConnector.leftHeart_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.liver_T, Liver.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.bone_T, Bone.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GITract_T, GITract.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.kidney_T, Kidney.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.fat_T, Fat.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.otherTissue_T, OtherTissue.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end TissuesHeat;

package tissues
model TissueTemperature
Physiolibrary.Interfaces.RealInput_ BaseT(unit = "degC");
Physiolibrary.Interfaces.RealOutput_ T(unit = "degC");
equation
T = BaseT;
end TissueTemperature;

model RightHeart
extends TissueTemperature;
end RightHeart;

model Brain
extends TissueTemperature;
end Brain;

model RespiratoryMuscle
extends TissueTemperature;
end RespiratoryMuscle;

model LeftHeart
extends TissueTemperature;
end LeftHeart;

model Liver
extends TissueTemperature;
end Liver;

model Bone
extends TissueTemperature;
end Bone;

model GITract
extends TissueTemperature;
end GITract;

model Kidney
extends TissueTemperature;
end Kidney;

model Fat
extends TissueTemperature;
end Fat;

model OtherTissue
extends TissueTemperature;
end OtherTissue;
end tissues;

model BladderHeat
Physiolibrary.HeatFlow.HeatAccumulation Bladder(STEADY = false, stateName = "BladderTemperature.Mass", initialHeatMass = 0.2 * 37);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.OutputPump bladderVoid(specificHeat = 0.001);
Physiolibrary.HeatFlow.PositiveHeatFlow positiveHeatFlow;
equation
connect(busConnector.BladderVolume_Mass, Bladder.weight) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BladderVoidFlow, bladderVoid.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Bladder.q_in, bladderVoid.q_in);
connect(positiveHeatFlow, Bladder.q_in);
end BladderHeat;

model GILumenHeat
Physiolibrary.HeatFlow.HeatAccumulation GILumen(specificHeat = 1, stateName = "GILumenTemperature.Mass", initialHeatMass = 308.09);
Physiolibrary.HeatFlow.ResistorWithCondParam resistorWithCondParam(cond = 0.01);
Physiolibrary.HeatFlow.InputPump Intake;
Modelica.Blocks.Math.Gain SpecificHeat(k = 0.001);
Modelica.Blocks.Math.Product tempTOgramIntake;
Modelica.Blocks.Math.Gain mlTOkg(k = 0.001);
Physiolibrary.HeatFlow.Pump Convection(specificHeat = 0.001);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.NegativeHeatFlow q_out;
equation
connect(GILumen.q_in, resistorWithCondParam.q_in);
connect(Intake.q_out, GILumen.q_in);
connect(SpecificHeat.y, Intake.desiredFlow);
connect(SpecificHeat.u, tempTOgramIntake.y);
connect(busConnector.DietGoalH2O_DegK, tempTOgramIntake.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenVolume_Intake, tempTOgramIntake.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(mlTOkg.y, GILumen.weight);
connect(busConnector.GILumenVolume_Mass, mlTOkg.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Convection.desiredFlow, busConnector.GILumenVolume_Absorption) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(GILumen.q_in, Convection.q_in);
connect(Convection.q_out, q_out);
connect(resistorWithCondParam.q_out, q_out);
end GILumenHeat;

model MuscleHeat
Physiolibrary.HeatFlow.HeatAccumulation skeletalMuscle(specificHeat = 0.83, stateName = "HeatSkeletalMuscle.Mass", initialHeatMass = 7064.94, q_in(T(start = 310.666)));
Physiolibrary.HeatFlow.HeatFlux muscleFlux(specificHeat = 0.92);
Modelica.Blocks.Math.Gain ML2KG1(k = 0.001);
Physiolibrary.HeatFlow.InputPump Metabolism2;
Modelica.Blocks.Math.Gain gain2(k = 0.001);
Modelica.Blocks.Math.Gain gTOkg1(k = 0.001);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.NegativeHeatFlow q_out;
Physiolibrary.Interfaces.RealInput_ HypothalamusShivering_NerveActivity;
Physiolibrary.Factors.CurveValue HeatShivering(data = {{0.0, 0.0, 0}, {4.0, 70.0, 0}});
Modelica.Blocks.Math.Add heat;
equation
connect(ML2KG1.y, muscleFlux.substanceFlow);
connect(skeletalMuscle.q_in, muscleFlux.q_in);
connect(busConnector.skeletalMuscle_BloodFlow, ML2KG1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Metabolism2.q_out, skeletalMuscle.q_in);
connect(busConnector.skeletalMuscle_T, skeletalMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(gain2.y, Metabolism2.desiredFlow);
connect(busConnector.skeletalMuscle_SizeMass, gTOkg1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gTOkg1.y, skeletalMuscle.weight);
connect(muscleFlux.q_out, q_out);
connect(HeatShivering.u, HypothalamusShivering_NerveActivity);
connect(HeatShivering.y, busConnector.skeletalMuscle_shiveringCals) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(heat.y, gain2.u);
connect(HeatShivering.y, heat.u1);
connect(busConnector.skeletalMuscle_HeatWithoutTermoregulation, heat.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.SkeletalMuscle_StructureEffect, HeatShivering.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end MuscleHeat;

model SkinHeat2
Modelica.Blocks.Math.Gain gTOkg3(k = 0.001);
Modelica.Blocks.Math.Gain gain(k = 0.001);
Physiolibrary.HeatFlow.InputPump Metabolism1;
Physiolibrary.HeatFlow.HeatAccumulation skin(specificHeat = 0.83, stateName = "HeatSkin.Mass", initialHeatMass = 564.432);
Physiolibrary.HeatFlow.HeatFlux skinFlux(specificHeat = 0.92);
Modelica.Blocks.Math.Gain ML2KG(k = 0.001);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.PositiveHeatFlow positiveHeatFlow;
Physiolibrary.HeatFlow.NegativeHeatFlow q_out;
Modelica.Blocks.Math.Feedback pressureGradient;
Modelica.Blocks.Math.Product bloodFlow;
Physiolibrary.Factors.SimpleMultiply TermoregulationEffect;
Physiolibrary.Interfaces.RealInput_ HypothalamusSkinFlow_NervesActivity;
Physiolibrary.Interfaces.RealOutput_ skin_T;
Physiolibrary.Curves.Curve SympsDilateEffect(x = {0.0, 1.0, 4.0}, y = {0.3, 1.0, 8.0}, slope = {0, 2.2, 0});
Physiolibrary.Factors.CurveValue LocalTempVsNA(data = {{1.2, 1.0, 0}, {1.5, 0.0, 0}});
Nerves.AplhaReceptorsActivityFactor AplhaReceptors_Skin(data = {{0.0, 0.3, 0}, {1.0, 0.0, -0.3}, {5.0, -0.9, 0}});
Physiolibrary.Factors.CurveValue LocalTempEffect(data = {{10.8, -0.8, 0}, {29.0, 0.0, 0.1}, {45.0, 4.0, 0}});
Physiolibrary.Blocks.Constant Skin_BasicConductance_1(k = 1);
Physiolibrary.Blocks.Add add(k = 1);
Physiolibrary.Blocks.Add add1(k = 1);
Physiolibrary.Factors.SimpleMultiply SympsEffect_Skin;
Physiolibrary.Factors.SimpleMultiply LocalTempEffect_Skin;
equation
connect(busConnector.skinSizeMass, gTOkg3.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gTOkg3.y, skin.weight);
connect(busConnector.MetabolismCaloriesUsed_SkinHeat, gain.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gain.y, Metabolism1.desiredFlow);
connect(Metabolism1.q_out, skin.q_in);
connect(skinFlux.q_out, skin.q_in);
connect(ML2KG.y, skinFlux.substanceFlow);
connect(skinFlux.q_in, positiveHeatFlow);
connect(skin.q_in, q_out);
connect(skin.T, busConnector.skin_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.SystemicArtys_Pressure, pressureGradient.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.SystemicVeins_Pressure, pressureGradient.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(pressureGradient.y, bloodFlow.u1);
connect(bloodFlow.y, ML2KG.u);
connect(TermoregulationEffect.y, bloodFlow.u2);
connect(skin.T, skin_T);
connect(SympsDilateEffect.val, busConnector.skinFlow_termoregulationEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(HypothalamusSkinFlow_NervesActivity, SympsDilateEffect.u);
connect(SympsDilateEffect.val, TermoregulationEffect.u);
connect(LocalTempVsNA.yBase, Skin_BasicConductance_1.y);
connect(LocalTempEffect.yBase, LocalTempVsNA.y);
connect(busConnector.skin_T, LocalTempEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaPool_Effect, AplhaReceptors_Skin.AlphaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AlphaBlocade_Effect, AplhaReceptors_Skin.AlphaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, AplhaReceptors_Skin.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AplhaReceptors_Skin.yBase, LocalTempVsNA.y);
connect(LocalTempEffect.y, add.u);
connect(add1.u, AplhaReceptors_Skin.y);
connect(SympsEffect_Skin.u, add1.y);
connect(add.y, LocalTempEffect_Skin.u);
connect(busConnector.skin_conductanceWithoutTermoregulationEffect, LocalTempEffect_Skin.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(LocalTempEffect_Skin.y, SympsEffect_Skin.yBase);
connect(SympsEffect_Skin.y, TermoregulationEffect.yBase);
connect(HypothalamusSkinFlow_NervesActivity, LocalTempVsNA.u);
end SkinHeat2;

model Heat2
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.HeatOutflow HeatInsensibleSkin(TempToolsVapor = 580.0, specificHeat = 1, q_in(T(start = 303.824)));
Physiolibrary.Blocks.MassFlowConstant_kg massFlowConstant(k = 0.00037);
Physiolibrary.HeatFlow.ResistorWithCond conduction;
Physiolibrary.Factors.CurveValue WindEffect(data = {{0.0, 1.0, 0}, {20.0, 4.0, 0}});
Physiolibrary.Factors.CurveValue BloodFlowEffect(data = {{0, 0.8, 0}, {250, 1.0, 0.001}, {8000, 8.0, 0}});
Physiolibrary.Factors.CurveValue ClothesEffect(data = {{0.0, 4.0, 0}, {2.0, 1.0, -1.2}, {4.0, 0.2, 0}});
Physiolibrary.Blocks.Constant Constant(k = 0.034);
Physiolibrary.Blocks.Constant Constant1(k = 2);
Physiolibrary.HeatFlow.AmbientTemperature ambientTemperature;
Physiolibrary.HeatFlow.ResistorWithCond radiation;
Physiolibrary.Factors.CurveValue ClothesEffect1(data = {{0.0, 4.0, 0}, {2.0, 1.0, -1.2}, {4.0, 0.2, 0}});
Physiolibrary.Blocks.Constant Constant3(k = 0.068);
TissuesHeat otherTissuesHeat;
Physiolibrary.HeatFlow.Pump toUrine(specificHeat = 0.001, q_in(T(start = 310.16)));
BladderHeat bladderHeat;
GILumenHeat gILumenHeat(GILumen(q_in(T(start = 308.099))));
SkinHeat2 skinHeat(SympsDilateEffect(iFrom(start = 2)), LocalTempEffect(curve(iFrom(start = 2))));
MuscleHeat muscleHeat;
Nerves.Hypothalamus hypothalamus(TemperatureEffect_(curve(iFrom(start = 2))), HypothalamusSweatingAcclimation1(curve(iFrom(start = 2))), HypothalamusShiveringAcclimation(curve(iFrom(start = 2))));
Skin.SweatGland sweatGland(AcclimationEffect(curve(iFrom(start = 2))));
Lungs lungs;
Core core1;
equation
connect(massFlowConstant.y, HeatInsensibleSkin.liquidOutflow);
connect(BloodFlowEffect.y, WindEffect.yBase);
connect(ClothesEffect.y, BloodFlowEffect.yBase);
connect(Constant.y, ClothesEffect.yBase);
connect(Constant1.y, ClothesEffect.u);
connect(busConnector.skin_BloodFlow, BloodFlowEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(WindEffect.y, conduction.cond);
connect(conduction.q_out, ambientTemperature.q_in);
connect(Constant1.y, ClothesEffect1.u);
connect(ClothesEffect1.y, radiation.cond);
connect(Constant3.y, ClothesEffect1.yBase);
connect(radiation.q_out, ambientTemperature.q_in);
connect(busConnector, otherTissuesHeat.busConnector);
connect(busConnector.CD_H2O_Outflow, toUrine.desiredFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(toUrine.q_out, bladderHeat.positiveHeatFlow);
connect(busConnector, bladderHeat.busConnector);
connect(gILumenHeat.busConnector, busConnector);
connect(skinHeat.q_out, HeatInsensibleSkin.q_in);
connect(skinHeat.q_out, conduction.q_in);
connect(skinHeat.q_out, radiation.q_in);
connect(skinHeat.busConnector, busConnector);
connect(muscleHeat.busConnector, busConnector);
connect(busConnector.brain_FunctionEffect, hypothalamus.BrainFunctionEffect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(hypothalamus.HypothalamusSkinFlow_NA, skinHeat.HypothalamusSkinFlow_NervesActivity);
connect(skinHeat.skin_T, hypothalamus.HeatSkin_Temp);
connect(hypothalamus.HypothalamusSweating_NA, sweatGland.HypothalamusSweating_NA);
connect(sweatGland.busConnector, busConnector);
connect(hypothalamus.HypothalamusShivering_NA, muscleHeat.HypothalamusShivering_NerveActivity);
connect(WindEffect.u, busConnector.Wind_MPH) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(skinHeat.q_out, sweatGland.port_a);
connect(sweatGland.port_b, ambientTemperature.q_in);
connect(lungs.busConnector, busConnector);
connect(lungs.positiveHeatFlow, core1.positiveHeatFlow);
connect(core1.positiveHeatFlow, skinHeat.positiveHeatFlow);
connect(core1.positiveHeatFlow, toUrine.q_in);
connect(core1.positiveHeatFlow, muscleHeat.q_out);
connect(core1.positiveHeatFlow, gILumenHeat.q_out);
connect(core1.core_T, hypothalamus.HeatCore_Temp);
connect(core1.busConnector, busConnector);
connect(lungs.air, ambientTemperature.q_in);
connect(hypothalamus.HypothalamusShivering_NA, busConnector.HypothalamusShivering_NerveActivity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Heat2;

package Skin
model SweatGland
Physiolibrary.Blocks.FlowConstant flowConstant(k = 1);
Physiolibrary.Factors.CurveValue NerveEffect(data = {{0.0, 0.0, 0.0}, {4.0, 30.0, 0.0}});
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Factors.SimpleMultiply FuelEffect;
Physiolibrary.Factors.SplineDelayByDay AcclimationEffect(Tau = 6, data = {{60, 0.5, 0.0}, {85, 1.0, 0.05}, {100, 2.0, 0.0}}, stateName = "SweatAcclimation.Effect");
Physiolibrary.Factors.SimpleMultiply SkinFunctionEffect;
Physiolibrary.NonSIunits.degC_to_degF degC_to_degF;
Physiolibrary.ConcentrationFlow.MassStorageCompartment SweatFuel(initialSoluteMass = 1, stateName = "SweatFuel.Mass");
Physiolibrary.ConcentrationFlow.InputPump inputPump;
Physiolibrary.ConcentrationFlow.OutputPump outputPump;
Modelica.Blocks.Math.Gain gain(k = 0.0004);
Physiolibrary.Factors.CurveValue MassEffect(data = {{0.9, 1.0, 0.0}, {1.0, 0.0, 0.0}});
Physiolibrary.Blocks.Constant Constant(k = 0.004);
Modelica.Blocks.Math.Feedback H2OOutflow;
Physiolibrary.Blocks.FlowConstant H2OReab(k = 0);
Physiolibrary.Interfaces.RealInput_ HypothalamusSweating_NA;
Physiolibrary.HeatFlow.PositiveHeatFlow port_a;
Physiolibrary.HeatFlow.HeatFlux HeatSweatConvection(specificHeat = 1);
Physiolibrary.HeatFlow.NegativeHeatFlow port_b;
Modelica.Blocks.Math.Min H2OEvaporation;
Physiolibrary.HeatFlow.HeatOutflow HeatSweatEvaporation;
Physiolibrary.Factors.CurveValue BasicEvaporation(data = {{0, 0, 0.0}, {40, 20, 0.0}});
Physiolibrary.Factors.CurveValue WindEffect(data = {{0, 1.0, 0.0}, {20, 1.5, 0.0}});
Physiolibrary.Blocks.Constant Constant1(k = 1);
Gases.RespiratoryRegulations.VaporPressure vaporPressure;
Modelica.Blocks.Math.Feedback Gradient;
Gases.RespiratoryRegulations.VaporPressure vaporPressure1;
Modelica.Blocks.Math.Product air_pH2O;
equation
connect(flowConstant.y, NerveEffect.yBase);
connect(busConnector.skin_FunctionEffect, SkinFunctionEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AcclimationEffect.y, SkinFunctionEffect.yBase);
connect(NerveEffect.y, FuelEffect.yBase);
connect(FuelEffect.y, AcclimationEffect.yBase);
connect(busConnector.skin_T, degC_to_degF.degC) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(degC_to_degF.degF, AcclimationEffect.u);
connect(SweatFuel.soluteMass, FuelEffect.u);
connect(inputPump.q_out, SweatFuel.q_out);
connect(SweatFuel.q_out, outputPump.q_in);
connect(gain.y, outputPump.desiredFlow);
connect(MassEffect.y, inputPump.desiredFlow);
connect(SweatFuel.soluteMass, MassEffect.u);
connect(Constant.y, MassEffect.yBase);
connect(SkinFunctionEffect.y, H2OOutflow.u1);
connect(H2OReab.y, H2OOutflow.u2);
connect(SkinFunctionEffect.y, gain.u);
connect(NerveEffect.u, HypothalamusSweating_NA);
connect(port_a, HeatSweatConvection.q_in);
connect(H2OOutflow.y, HeatSweatConvection.substanceFlow);
connect(HeatSweatConvection.q_out, port_b);
connect(H2OOutflow.y, H2OEvaporation.u2);
connect(H2OEvaporation.y, HeatSweatEvaporation.liquidOutflow);
connect(port_a, HeatSweatEvaporation.q_in);
connect(BasicEvaporation.y, WindEffect.yBase);
connect(Constant1.y, BasicEvaporation.yBase);
connect(WindEffect.y, H2OEvaporation.u1);
connect(busConnector.Wind_MPH, WindEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(vaporPressure.VaporPressure, Gradient.u1);
connect(vaporPressure1.VaporPressure, air_pH2O.u2);
connect(busConnector.EnvironmentRelativeHumidity, air_pH2O.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AmbientTemperature, vaporPressure1.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(air_pH2O.y, Gradient.u2);
connect(Gradient.y, BasicEvaporation.u);
connect(busConnector.skin_T, vaporPressure.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(H2OOutflow.y, busConnector.SweatDuct_H2OOutflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end SweatGland;
end Skin;

model Lungs
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.PositiveHeatFlow positiveHeatFlow;
Physiolibrary.HeatFlow.HeatOutflow lungsVapor(TempToolsVapor = 580.0, specificHeat = 1);
Physiolibrary.Blocks.MassFlowConstant_kg massFlowConstant1(k = 0.00028);
Modelica.Blocks.Math.Feedback gradient;
Gases.RespiratoryRegulations.VaporPressure vaporPressure1;
Modelica.Blocks.Math.Product air_pH2O;
Gases.RespiratoryRegulations.VaporPressure vaporPressure2;
Modelica.Blocks.Math.Division division;
Modelica.Blocks.Math.Product product;
Modelica.Blocks.Math.Gain K(k = 8e-007);
Physiolibrary.HeatFlow.NegativeHeatFlow air;
Physiolibrary.HeatFlow.ResistorWithCond resistorWithCond;
Modelica.Blocks.Math.Gain SpecificHeat_Air(k = 3.1e-007);
equation
connect(positiveHeatFlow, lungsVapor.q_in);
connect(vaporPressure1.VaporPressure, air_pH2O.u2);
connect(busConnector.AmbientTemperature, vaporPressure1.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.EnvironmentRelativeHumidity, air_pH2O.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(vaporPressure2.VaporPressure, gradient.u1);
connect(busConnector.core_T, vaporPressure2.T) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(air_pH2O.y, gradient.u2);
connect(gradient.y, division.u1);
connect(busConnector.BarometerPressure, division.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(division.y, product.u1);
connect(busConnector.BreathingTotalVentilation, product.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(product.y, K.u);
connect(K.y, lungsVapor.liquidOutflow);
connect(positiveHeatFlow, resistorWithCond.q_out);
connect(resistorWithCond.q_in, air);
connect(SpecificHeat_Air.y, resistorWithCond.cond);
connect(busConnector.BreathingTotalVentilation, SpecificHeat_Air.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Lungs;

model Core
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.HeatFlow.PositiveHeatFlow positiveHeatFlow;
Modelica.Blocks.Math.Gain gain1(k = 0.001);
Physiolibrary.HeatFlow.InputPump CoreMetabolism;
Physiolibrary.HeatFlow.HeatAccumulation core(specificHeat = 0.83, stateName = "HeatCore.Mass", initialHeatMass = 10749.4);
Modelica.Blocks.Math.Gain gTOkg4(k = 0.001);
Physiolibrary.Interfaces.RealOutput_ core_T;
equation
connect(busConnector.MetabolismCaloriesUsed_CoreHeat, gain1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gain1.y, CoreMetabolism.desiredFlow);
connect(CoreMetabolism.q_out, core.q_in);
connect(busConnector.WeightCore, gTOkg4.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gTOkg4.y, core.weight);
connect(core.T, busConnector.HeatCore_Temp) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(core.q_in, positiveHeatFlow);
connect(core.T, core_T);
connect(core.T, busConnector.core_T) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Core;
end Heat;

package Metabolism  "Body Nutrients, Metabolism and Heat Systems"

model LiverMetabolism
HumMod.Metabolism.Glycogen glycogen(MINUTE_FLOW_TO_MASS_CONVERSION = 0.001, initialSoluteMass = 120);
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_Glycogenesis;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_Glycogenolysis;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_FA_Glucose;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_Gluconeogenesis;
Physiolibrary.ConcentrationFlow.SimpleReaction2 AA_TO_GLU;
Physiolibrary.ConcentrationFlow.SimpleReaction GLU_TO_FA;
Physiolibrary.Factors.CurveValue InsulinEffect(data = {{0, 0.0, 0.0}, {35, 1.0, 0.03}, {120, 3.0, 0.0}});
Physiolibrary.Factors.CurveValue InsulinEffect3(data = {{0, 0.0, 0.0}, {50, 1.0, 0.06}, {200, 3.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.CurveValue InsulinEffect4(data = {{0, 2.5, 0.0}, {50, 1.0, -0.005}, {500, 0.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Blocks.MassFlowConstant massFlowConstant2(k = 75);
Physiolibrary.Blocks.MassFlowConstant massFlowConstant3(k = 70);
Physiolibrary.Blocks.MassFlowConstant massFlowConstant4(k = 30);
Physiolibrary.Factors.SplineValue2 MassEffect(data = {{0, 3.0, 0.0}, {100, 1.0, -0.05}, {200, 0.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SplineValue2 GlucoseEffect(data = {{120, 0.0, 0.0}, {130, 1.0, 0.06}, {200, 2.0, 0.0}});
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect;
Physiolibrary.Factors.CurveValue InsulinEffect1(data = {{0, 2.0, 0.0}, {35, 1.0, -0.02}, {120, 0.0, 0.0}});
Physiolibrary.Blocks.MassFlowConstant massFlowConstant5(k = 75);
Physiolibrary.Factors.SplineValue2 MassEffect1(data = {{0, 0.0, 0.0}, {100, 1.0, 0.0}});
Physiolibrary.Factors.SplineValue2 GlucoseEffect1(data = {{45, 2.0, 0.0}, {125, 1.0, -0.01}, {350, 0.3, 0.0}});
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect1;
Physiolibrary.Factors.CurveValue GlucagonEffect(data = {{170, 1.0, 0.0}, {680, 2.0, 0.0}});
Physiolibrary.Factors.CurveValue EpinephrineEffect(data = {{0, 0.8, 0.0}, {40, 1.0, 0.01}, {400, 10.0, 0.02}, {1200, 20.0, 0.0}});
Physiolibrary.Blocks.Constant Constant2(k = 0.42);
Physiolibrary.Blocks.Constant Constant3(k = 0.6);
Physiolibrary.Factors.CurveValue GlucoseEffect2(data = {{120, 0.0, 0.0}, {130, 1.0, 0.05}, {200, 2.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect2;
Physiolibrary.Factors.CurveValue GlucagonEffect1(data = {{170, 1.0, 0.0}, {680, 2.0, 0.0}});
Physiolibrary.Factors.CurveValue GlucoseEffect3(data = {{45, 2.0, 0.0}, {125, 1.0, -0.008}, {340, 0.3, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.CurveValue AminoAcidEffect(data = {{0, 0.0, 0.0}, {50, 1.0, 0.02}, {200, 2.0, 0.0}}, curve(iFrom(start = 2)), y(start = 1.13856), u(start = 57.2753));
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect3;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Glucose(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow triglicerides(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Ketoacids(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_Ketoacids;
Physiolibrary.ConcentrationFlow.SimpleReaction FA_TO_KA;
Physiolibrary.Blocks.Constant Constant4(k = 1.02);
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect4;
Physiolibrary.Factors.CurveValue FattyAcidEffect(data = {{0, 0.5, 0.0}, {15, 1.0, 0.05}, {75, 5.0, 0.0}}, curve(iFrom(start = 2))) "effect on fatty acids concentration in mg/dl";
Physiolibrary.Factors.CurveValue GlucagonEffect2(data = {{0, 0.5, 0.0}, {170, 1.0, 0.01}, {340, 10.0, 0.0}});
Physiolibrary.Blocks.MassFlowConstant massFlowConstant1(k = 2.2);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mg/dl", toAnotherUnitCoef = 100) "from mg/ml to mg/dl";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow AminoAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mg/dl", toAnotherUnitCoef = 100) "from mg/ml to mg/dl";
Physiolibrary.ConcentrationFlow.SoluteFlowPump LM_FA_AminoAcids;
Physiolibrary.ConcentrationFlow.SimpleReaction2 AA_TO_FA;
Physiolibrary.Factors.CurveValue InsulinEffect2(data = {{0, 0.0, 0.0}, {50, 1.0, 0.05}, {80, 4.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Blocks.MassFlowConstant massFlowConstant6(k = 20);
Physiolibrary.Blocks.Constant Constant5(k = 0.437);
Physiolibrary.Factors.SimpleMultiply LiverFunctionEffect5;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Urea(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.Blocks.Constant Constant6(k = 0.3);
Physiolibrary.Blocks.Constant Constant7(k = 0.3);
Glucose_MG_TO_MMOL glucose_MG_TO_MMOL;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Factors.SimpleMultiply AAEffect;
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.Factors.SimpleMultiply AAEffect1;
equation
connect(InsulinEffect.yBase, massFlowConstant2.y);
connect(InsulinEffect4.yBase, massFlowConstant4.y);
connect(InsulinEffect3.yBase, massFlowConstant3.y);
connect(GlucoseEffect.y, LiverFunctionEffect.yBase);
connect(InsulinEffect1.yBase, massFlowConstant5.y);
connect(GlucagonEffect.yBase, InsulinEffect1.y);
connect(EpinephrineEffect.yBase, GlucoseEffect1.y);
connect(EpinephrineEffect.y, LiverFunctionEffect1.yBase);
connect(Constant2.y, GLU_TO_FA.coef);
connect(Constant3.y, AA_TO_GLU.coef);
connect(InsulinEffect3.y, GlucoseEffect2.yBase);
connect(GlucoseEffect2.y, LiverFunctionEffect2.yBase);
connect(LiverFunctionEffect2.y, LM_FA_Glucose.soluteFlow);
connect(InsulinEffect4.y, GlucagonEffect1.yBase);
connect(GlucagonEffect1.y, GlucoseEffect3.yBase);
connect(LiverFunctionEffect3.y, LM_Gluconeogenesis.soluteFlow);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect.u);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect1.u);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect3.u);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect2.u);
connect(busConnector.PortalVein_Glucagon, GlucagonEffect1.u);
connect(GlucagonEffect.u, busConnector.PortalVein_Glucagon);
connect(GLU_TO_FA.q_in, LM_FA_Glucose.q_out);
connect(AA_TO_GLU.q_in, LM_Gluconeogenesis.q_out);
connect(Constant4.y, FA_TO_KA.coef);
connect(LM_Ketoacids.q_out, FA_TO_KA.q_in);
connect(LiverFunctionEffect4.y, LM_Ketoacids.soluteFlow);
connect(GlucagonEffect2.y, LiverFunctionEffect4.yBase);
connect(FattyAcidEffect.y, GlucagonEffect2.yBase);
connect(FattyAcidEffect.yBase, massFlowConstant1.y);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect4.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PortalVein_Glucagon, GlucagonEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(concentrationMeasure.actualConc, FattyAcidEffect.u);
connect(busConnector.PortalVein_Glucose, GlucoseEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PortalVein_Glucose, GlucoseEffect1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PortalVein_Glucose, GlucoseEffect3.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.PortalVein_Glucose, GlucoseEffect2.u);
connect(EpinephrineEffect.u, busConnector.EpiPool_Epi) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Glucose, LM_Glycogenesis.q_in);
connect(LM_Glycogenolysis.q_out, Glucose);
connect(LM_FA_Glucose.q_in, Glucose);
connect(AA_TO_GLU.q_out, Glucose);
connect(GLU_TO_FA.q_out, triglicerides);
connect(Ketoacids, FA_TO_KA.q_out);
connect(AminoAcids, LM_Gluconeogenesis.q_in);
connect(AminoAcids, concentrationMeasure1.q_in);
connect(InsulinEffect2.yBase, massFlowConstant6.y);
connect(Constant5.y, AA_TO_FA.coef);
connect(LiverFunctionEffect5.y, LM_FA_AminoAcids.soluteFlow);
connect(busConnector.LiverFunctionEffect, LiverFunctionEffect5.u);
connect(AA_TO_FA.q_in, LM_FA_AminoAcids.q_out);
connect(AA_TO_FA.q_out, triglicerides);
connect(LM_FA_AminoAcids.q_in, AminoAcids);
connect(Urea, AA_TO_GLU.q_out2);
connect(AA_TO_FA.q_out2, Urea);
connect(AA_TO_GLU.coef2, Constant6.y);
connect(AA_TO_FA.coef2, Constant7.y);
connect(LM_Glycogenesis.soluteFlow, glucose_MG_TO_MMOL.u);
connect(glucose_MG_TO_MMOL.y, busConnector.liver_GlucoseToCellStorageFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.LM_Insulin_InsulinDelayed, InsulinEffect.u);
connect(busConnector.LM_Insulin_InsulinDelayed, InsulinEffect1.u);
connect(busConnector.LM_Insulin_InsulinDelayed, InsulinEffect3.u);
connect(busConnector.LM_Insulin_InsulinDelayed, InsulinEffect4.u);
connect(InsulinEffect2.u, busConnector.LM_Insulin_InsulinDelayed);
connect(fattyAcids, concentrationMeasure.q_in);
connect(fattyAcids, LM_Ketoacids.q_in);
connect(InsulinEffect.y, GlucoseEffect.yBase);
connect(LiverFunctionEffect.y, MassEffect.yBase);
connect(MassEffect.y, LM_Glycogenesis.soluteFlow);
connect(GlucagonEffect.y, GlucoseEffect1.yBase);
connect(MassEffect1.yBase, LiverFunctionEffect1.y);
connect(MassEffect1.y, LM_Glycogenolysis.soluteFlow);
connect(LM_Glycogenolysis.q_in, glycogen.q_out);
connect(LM_Glycogenesis.q_out, glycogen.q_out);
connect(concentrationMeasure1.actualConc, AminoAcidEffect.u);
connect(glycogen.soluteMass, MassEffect.u);
connect(glycogen.soluteMass, MassEffect1.u);
connect(GlucoseEffect3.y, AAEffect.yBase);
connect(LiverFunctionEffect3.yBase, AAEffect.y);
connect(Constant1.y, AminoAcidEffect.yBase);
connect(AminoAcidEffect.y, AAEffect.u);
connect(InsulinEffect2.y, AAEffect1.yBase);
connect(AAEffect1.y, LiverFunctionEffect5.yBase);
connect(AminoAcidEffect.y, AAEffect1.u);
end LiverMetabolism;

model Glucose
Physiolibrary.ConcentrationFlow.ConcentrationCompartment GlucosePool(stateName = "GlucosePool.Mass", initialSoluteMass = 15513);
Physiolibrary.ConcentrationFlow.OutputPump Decomposition;
Modelica.Blocks.Math.Gain K(k = 0.0007);
Physiolibrary.ConcentrationFlow.SolventFlowPump Glomerulus;
Physiolibrary.ConcentrationFlow.ConstLimitedReabsorbtion Reabsorbtion;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_out(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mg/dl", toAnotherUnitCoef = 100);
Modelica.Blocks.Math.Add3 YGLS "Ikeda glucose to cells flow";
Modelica.Blocks.Math.Gain MW(k = 1 / 180);
Electrolytes.Bladder bladder(stateVarName = "BladderGlucose.Mass");
equation
connect(Decomposition.q_in, GlucosePool.q_out);
connect(K.u, GlucosePool.soluteMass);
connect(K.y, Decomposition.desiredFlow);
connect(Glomerulus.q_out, Reabsorbtion.Inflow);
connect(GlucosePool.q_out, Glomerulus.q_in);
connect(Reabsorbtion.Reabsorbtion, GlucosePool.q_out);
connect(GlucosePool.q_out, q_out);
connect(busConnector.ECFV_Vol, GlucosePool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Glomerulus_GFR, Glomerulus.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Reabsorbtion.Outflow, flowMeasure.q_in);
connect(busConnector.CD_Glucose_Outflow, flowMeasure.actualFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(GlucosePool.q_out, concentrationMeasure.q_in);
connect(busConnector.Glucose, concentrationMeasure.actualConc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(YGLS.y, busConnector.GlucoseToCellsFlow);
connect(busConnector.skeletalMuscle_GlucoseToCellStorageFlow, YGLS.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.liver_GlucoseToCellStorageFlow, YGLS.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.respiratoryMuscle_GlucoseToCellStorageFlow, YGLS.u3) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(MW.u, GlucosePool.soluteMass);
connect(MW.y, busConnector.GlucoseECF_Osmoles) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.q_out, bladder.q_in);
connect(bladder.busConnector, busConnector);
end Glucose;

model Proteins
Physiolibrary.ConcentrationFlow.ConcentrationCompartment CellProteins(stateName = "CellProtein.Mass", initialSoluteMass = 5549290.0);
Physiolibrary.ConcentrationFlow.SoluteFlowPump Degradation;
Modelica.Blocks.Math.Gain K(k = 5.3e-006);
Physiolibrary.ConcentrationFlow.SolventFlowPump Outflow;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow aminoAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.SolventFlowPump Inflow;
Physiolibrary.Blocks.Constant Constant(k = 0.88);
Physiolibrary.Blocks.Constant Constant1(k = 464);
equation
connect(Degradation.q_in, CellProteins.q_out);
connect(K.u, CellProteins.soluteMass);
connect(CellProteins.q_out, Outflow.q_in);
connect(busConnector.ICFV_Vol, CellProteins.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(CellProteins.q_out, Inflow.q_out);
connect(Inflow.q_in, aminoAcids);
connect(Outflow.q_out, aminoAcids);
connect(Constant.y, Outflow.solventFlow);
connect(Inflow.solventFlow, Constant1.y);
connect(busConnector.CellProtein_Mass, CellProteins.soluteMass) annotation(Text(string = "%first", index = -1, extent = {{-6, -3}, {-6, -3}}));
connect(K.y, Degradation.soluteFlow);
connect(Degradation.q_out, aminoAcids);
end Proteins;

model Urea
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow ureaFromMetabolism(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.Reabsorbtion reabsorbtion;
Physiolibrary.ConcentrationFlow.SolventFlowPump CD_Outflow;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Medulla(stateName = "MedullaUrea.Mass", initialSoluteMass = 955.045);
Physiolibrary.Blocks.FractConstant fractConstant(k = 40);
Physiolibrary.ConcentrationFlow.SolventFlowPump VasaRecta_Outflow;
Physiolibrary.Blocks.Fract2Constant CCEfficiency(k = 98);
Modelica.Blocks.Math.Product product;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Urea(stateName = "UreaPool.Mass", initialSoluteMass = 7206.24);
Physiolibrary.ConcentrationFlow.SolventFlowPump Glomerulus;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment UreaCell(stateName = "UreaCell.Mass", initialSoluteMass = 13288.1);
Physiolibrary.ConcentrationFlow.ResistorWithCondParam DC(cond = 910);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure osmolarityMeasure(unitsString = "Osmolarity", toAnotherUnitCoef = 16.67);
Modelica.Blocks.Math.Gain mg2mosm(k = 0.01667);
Modelica.Blocks.Math.Gain mg2mosm1(k = 0.01667);
Electrolytes.Bladder bladder(stateVarName = "BladderUrea.Mass");
equation
connect(reabsorbtion.Outflow, CD_Outflow.q_in);
connect(reabsorbtion.Outflow, Medulla.q_out);
connect(fractConstant.y, reabsorbtion.ReabsorbedFract);
connect(VasaRecta_Outflow.q_in, Medulla.q_out);
connect(CCEfficiency.y2, product.u2);
connect(product.y, VasaRecta_Outflow.solventFlow);
connect(busConnector.CD_H2O_Outflow, CD_Outflow.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Medulla_Volume, Medulla.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Glomerulus.q_out, reabsorbtion.Inflow);
connect(Urea.q_out, Glomerulus.q_in);
connect(VasaRecta_Outflow.q_out, Urea.q_out);
connect(reabsorbtion.Reabsorbtion, Urea.q_out);
connect(ureaFromMetabolism, Urea.q_out);
connect(busConnector.ICFV_Vol, UreaCell.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Urea.q_out, DC.q_in);
connect(DC.q_out, UreaCell.q_out);
connect(busConnector.ECFV_Vol, Urea.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.VasaRecta_Outflow, product.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(CD_Outflow.q_out, flowMeasure.q_in);
connect(flowMeasure.actualFlow, busConnector.CD_Urea_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Medulla.q_out, osmolarityMeasure.q_in);
connect(osmolarityMeasure.actualConc, busConnector.MedullaUrea_Osmolarity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Urea.soluteMass, mg2mosm.u);
connect(busConnector.UreaECF_Osmoles, mg2mosm.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(UreaCell.soluteMass, mg2mosm1.u);
connect(busConnector.UreaICF_Osmoles, mg2mosm1.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(flowMeasure.q_out, bladder.q_in);
connect(bladder.busConnector, busConnector);
connect(Glomerulus.solventFlow, busConnector.GlomerulusFiltrate_GFR) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Urea;

model KetoAcids
Physiolibrary.ConcentrationFlow.ConcentrationCompartment KAPool(stateName = "KAPool.Mass", initialSoluteMass = 316.7) "mg/ml";
Physiolibrary.ConcentrationFlow.InputPump KAPump;
Physiolibrary.ConcentrationFlow.SolventFlowPump glomerulusKARate;
Electrolytes.Phosphate.GlomerulusStrongAnionFiltration glomerulus;
Physiolibrary.ConcentrationFlow.FractReabsorbtion NephronKetoacids(MaxReab = 30);
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Factors.CurveValue PhEffect(data = {{7.0, 0.0, 0}, {7.4, 1.0, 0}});
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.ConcentrationFlow.OutputPump KADecomposition;
Modelica.Blocks.Math.Gain K(k = 0.0007);
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mmol/l", toAnotherUnitCoef = 9.800000000000001);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Modelica.Blocks.Math.Gain gain1(k = 0.0098);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Blocks.MassFlowConstant electrolytesFlowConstant4(k = 0);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mg/dl", toAnotherUnitCoef = 100.0);
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure1;
Modelica.Blocks.Math.Gain MG_TO_MMOL(k = 0.0098);
Electrolytes.Bladder bladder(stateVarName = "BladderKetoacid.Mass");
equation
connect(glomerulus.q_out, glomerulusKARate.q_in);
connect(glomerulusKARate.q_out, NephronKetoacids.Inflow);
connect(NephronKetoacids.Effects, Constant.y);
connect(Constant1.y, PhEffect.yBase);
connect(KAPool.soluteMass, K.u);
connect(K.y, KADecomposition.desiredFlow);
connect(KAPool.q_out, concentrationMeasure.q_in);
connect(NephronKetoacids.Outflow, flowMeasure.q_in);
connect(KAPool.soluteMass, gain1.u);
connect(KAPool.SolventVolume, busConnector.ECFV_Vol);
connect(PhEffect.u, busConnector.BloodPh_ArtysPh);
connect(busConnector.BloodIons_Cations, glomerulus.Cations);
connect(gain1.y, busConnector.KAPool_Osmoles);
connect(electrolytesFlowConstant4.y, KAPump.desiredFlow);
connect(flowMeasure.actualFlow, busConnector.CD_KA_Outflow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(KAPool.q_out, concentrationMeasure1.q_in);
connect(concentrationMeasure.actualConc, busConnector.KAPool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(KAPump.q_out, flowMeasure1.q_in);
connect(KADecomposition.q_in, flowMeasure1.q_in);
connect(q_out, flowMeasure1.q_in);
connect(flowMeasure1.q_out, KAPool.q_out);
connect(flowMeasure1.actualFlow, MG_TO_MMOL.u);
connect(PhEffect.y, NephronKetoacids.Normal);
connect(KAPool.q_out, glomerulus.q_in);
connect(NephronKetoacids.Reabsorbtion, KAPool.q_out);
connect(busConnector.BloodIons_ProteinAnions, glomerulus.ProteinAnions) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(MG_TO_MMOL.y, busConnector.KA_Change_mmol_per_min) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.q_out, bladder.q_in);
connect(bladder.busConnector, busConnector);
connect(glomerulusKARate.solventFlow, busConnector.GlomerulusFiltrate_GFR);
connect(concentrationMeasure1.actualConc, busConnector.KAPool_mg_per_dl) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end KetoAcids;

model Lipids
Physiolibrary.ConcentrationFlow.MassStorageCompartment LipidDeposits(stateName = "LipidDeposits.Mass", initialSoluteMass = 12032.4);
Physiolibrary.ConcentrationFlow.SimpleReaction FA_TO_Lipids;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LipidDeposits_Uptake;
Physiolibrary.ConcentrationFlow.SoluteFlowPump LipidDeposits_Release;
Physiolibrary.Blocks.MassFlowConstant massFlowConstant2(k = 100);
Physiolibrary.Factors.SplineValue2 InsulinEffect(data = {{0, 0.5, 0.0}, {20, 1.0, 0.03}, {100, 2.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SplineValue2 FattyAcidEffect(data = {{0, 0.0, 0.0}, {15, 1.0, 0.1}, {50, 3.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Blocks.Constant massFlowConstant5(k = 0.009299999999999999);
Physiolibrary.Factors.SplineValue2 GlucagonEffect(data = {{120, 1.0, 0.0}, {200, 2.0, 0.0}});
Physiolibrary.Factors.SplineValue2 InsulinEffect_(data = {{0, 2.0, 0.0}, {20, 1.0, -0.04}, {100, 0.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SplineValue2 EpinephrineEffect(data = {{0, 0.5, 0.0}, {40, 1.0, 0.013}, {400, 4.0, 0.0}});
Physiolibrary.Blocks.Constant Constant1(k = 0.001);
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow FattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mg/dl", toAnotherUnitCoef = 100) "from mg/ml to mg/dl";
Physiolibrary.Factors.SimpleMultiply Fraction;
Physiolibrary.Factors.SplineValue2 FattyAcidEffect_(data = {{0, 3.0, 0.0}, {15, 1.0, -0.04}, {100, 0.0, 0.0}});
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Triglyceride(stateName = "TriglyceridePool.Mass", initialSoluteMass = 17000);
Modelica.Blocks.Math.Gain K(k = 0.0007);
Physiolibrary.ConcentrationFlow.OutputPump Decomposition;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mg/dl", toAnotherUnitCoef = 100) "from mg/ml to mg/dl";
Physiolibrary.ConcentrationFlow.ConcentrationCompartment FAPool(stateName = "FAPool.Mass", initialSoluteMass = 2400) "mg/ml";
Physiolibrary.ConcentrationFlow.OutputPump FADecomposition;
Modelica.Blocks.Math.Gain K1(k = 0.0007);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2;
Modelica.Blocks.Math.Gain gain(k = 3.92, y(final unit = "mmol/l"));
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow toTriglicerides(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "from GILumen";
Physiolibrary.ConcentrationFlow.SoluteFlowPump TriglycerideHydrolysis;
Physiolibrary.Factors.CurveValue TriglycerideEffect1(data = {{0, 0.0, 0.0}, {100, 1.0, 0.03}, {200, 3.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure3(unitsString = "mg/dl", toAnotherUnitCoef = 100) "from mg/ml to mg/dl";
Physiolibrary.ConcentrationFlow.SimpleReaction TRIG_TO_FFA;
Physiolibrary.Blocks.Constant Constant2(k = 0.89);
Physiolibrary.Blocks.MassFlowConstant massFlowConstant1(k = 100);
Physiolibrary.ConcentrationFlow.SimpleReaction FFA_TO_TRIG;
Physiolibrary.Blocks.Constant massFlowConstant3(k = 0.0075);
equation
connect(FA_TO_Lipids.q_out, LipidDeposits.q_out);
connect(InsulinEffect.y, FattyAcidEffect.yBase);
connect(EpinephrineEffect.yBase, GlucagonEffect.y);
connect(Constant1.y, FA_TO_Lipids.coef);
connect(LipidDeposits_Release.q_in, FA_TO_Lipids.q_in);
connect(LipidDeposits_Uptake.q_out, FA_TO_Lipids.q_in);
connect(FattyAcids, concentrationMeasure.q_in);
connect(massFlowConstant2.y, InsulinEffect.yBase);
connect(busConnector.Insulin, InsulinEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(FattyAcidEffect.y, LipidDeposits_Uptake.soluteFlow);
connect(Fraction.y, InsulinEffect_.yBase);
connect(busConnector.Insulin, InsulinEffect_.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(GlucagonEffect.yBase, InsulinEffect_.y);
connect(busConnector.Glucagon_conc, GlucagonEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.EpiPool_Epi, EpinephrineEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(LipidDeposits_Release.soluteFlow, FattyAcidEffect_.y);
connect(EpinephrineEffect.y, FattyAcidEffect_.yBase);
connect(concentrationMeasure.actualConc, FattyAcidEffect_.u);
connect(FattyAcids, LipidDeposits_Release.q_out);
connect(K.y, Decomposition.desiredFlow);
connect(K.u, Triglyceride.soluteMass);
connect(Decomposition.q_in, Triglyceride.q_out);
connect(Triglyceride.SolventVolume, busConnector.ECFV_Vol) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(concentrationMeasure1.actualConc, FattyAcidEffect.u);
connect(FAPool.SolventVolume, busConnector.ECFV_Vol);
connect(FAPool.soluteMass, K1.u);
connect(K1.y, FADecomposition.desiredFlow);
connect(concentrationMeasure2.actualConc, gain.u);
connect(gain.y, busConnector.FAPool_conc_per_liter);
connect(FAPool.q_out, concentrationMeasure2.q_in);
connect(FAPool.q_out, FattyAcids);
connect(TriglycerideEffect1.y, TriglycerideHydrolysis.soluteFlow);
connect(Triglyceride.q_out, TriglycerideHydrolysis.q_in);
connect(Triglyceride.q_out, concentrationMeasure3.q_in);
connect(Constant2.y, TRIG_TO_FFA.coef);
connect(TRIG_TO_FFA.q_out, FattyAcids);
connect(TRIG_TO_FFA.q_in, TriglycerideHydrolysis.q_out);
connect(TriglycerideEffect1.yBase, massFlowConstant1.y);
connect(FattyAcids, LipidDeposits_Uptake.q_in);
connect(concentrationMeasure1.q_in, FattyAcids);
connect(FFA_TO_TRIG.q_out, toTriglicerides);
connect(FFA_TO_TRIG.q_in, Triglyceride.q_out);
connect(Constant2.y, FFA_TO_TRIG.coef);
connect(FAPool.q_out, FADecomposition.q_in);
connect(concentrationMeasure3.actualConc, TriglycerideEffect1.u);
connect(LipidDeposits.soluteMass, busConnector.LipidDeposits_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LipidDeposits.soluteMass, Fraction.yBase);
connect(massFlowConstant3.y, Fraction.u);
end Lipids;

block Glucose_MG_TO_MMOL  "convert glucose units from mg to mmol "
Physiolibrary.Interfaces.RealInput_ u;
Physiolibrary.Interfaces.RealOutput_ y;
constant Real MG_TO_MMOL = 5.551;
equation
y = MG_TO_MMOL * u;
end Glucose_MG_TO_MMOL;

model Lactate
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Lactate(q(final unit = "mEq/min"), conc(final unit = "mEq/ml", min = 0, start = 0)) "extracellular storage";
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Lactate1(initialSoluteMass(unit = "mmol/ml") = 0, stateName = "LacPool.Mass", soluteMass(start = 0, fixed = false));
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
Modelica.Blocks.Math.Gain to_mmol(k = 1);
equation
connect(busConnector.ECFV_Vol, Lactate1.SolventVolume);
connect(concentrationMeasure.actualConc, busConnector.LacPool_Lac_mEq_per_litre) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(to_mmol.y, busConnector.LactateFromTissues) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(flowMeasure.actualFlow, to_mmol.u);
connect(Lactate, flowMeasure.q_in);
connect(Lactate1.soluteMass, busConnector.LacPool_Mass_mEq) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Lactate1.q_out, flowMeasure.q_out);
connect(Lactate1.q_out, concentrationMeasure.q_in);
end Lactate;

model AminoAcids
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow AminoAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min")) "extracellular storage";
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment AminoAcidsPool(stateName = "AAPool.Mass", initialSoluteMass = 6617.84);
equation
connect(AminoAcids, AminoAcidsPool.q_out);
connect(busConnector.ECFV_Vol, AminoAcidsPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end AminoAcids;

model Glycogen
extends Physiolibrary.ConcentrationFlow.MassStorageCompartment(stateName = "LM_Glycogen.Mass");
end Glycogen;

model CellularMetabolism
parameter Boolean canBurnFattyAcids = true;
parameter Real eTOglu_coef(unit = "g/kcal") = 0.2439 "how much carbohydrates will be produced with one kilocalorie";
parameter Real eTOlac_coef(unit = "g/kcal") = 0.2538 "how much lactate will produce one kilocalorie";
parameter Real eTOfat_coef(unit = "g/kcal") = 0.1075 "how much fatty acids will produce one kilocalorie";
parameter Real eTOketo_coef(unit = "g/kcal") = 0.1075 "how much ketoacids will produce one kilocalorie";
parameter Real eTOo2_coef(unit = "ml/kcal") = 0.2093 "how much oxygen will be produced with one kilocalorie";
parameter Real RQglu(unit = "1") = 1 "how much CO2 will be produced with one oxygen by glucose burning";
parameter Real RQlac(unit = "1") = 1 "how much CO2 will be produced with one oxygen by lactate burning";
parameter Real RQfat(unit = "1") = 0.7 "how much CO2 will be produced with one oxygen by fatty acid burning";
parameter Real RQketo(unit = "1") = 0.7 "how much CO2 will be produced with one oxygen by keto acid burning";
parameter Real lacDensity(unit = "g/mmol") = 90.08 "density of lactate";
parameter Real glu2lac(unit = "mEq/g") = 1.0 / lacDensity "how much lactate will produce one gram of glucose";
parameter Real anaerobic_glu2energy(unit = "kcal/g") = 1.0 / eTOglu_coef - 1.0 / eTOlac_coef "how much energy in callories will produce one unit of reactant by anaerobic metabolism";
parameter Real[:, 3] LacFractionData "fraction of oxygen to be use for lactate metabolism (depends on lactate concentration)";
parameter Real[:, 3] PO2OnAerobicFractionData = {{2, 0, 0}, {10, 1, 0}} "Aerobic Fraction of O2 tissue use depents on pO2";
Physiolibrary.Curves.Curve LacFraction(x = LacFractionData[:, 1], y = LacFractionData[:, 2], slope = LacFractionData[:, 3]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow lactate(q(final unit = "mEq/min"), conc(final unit = "mEq/ml")) "in mEq/ml";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow glucose(q(final unit = "mg/min"), conc(final unit = "mg/ml")) "in mg/ml";
Physiolibrary.Interfaces.RealOutput_ Tissue_CO2FromMetabolism;
Physiolibrary.Interfaces.RealOutput_ Tissue_MotabolicH2ORate(unit = "ml/min");
Physiolibrary.Interfaces.RealInput_ CalsUse(unit = "kcal/min");
Physiolibrary.Curves.Curve AerobicFraction(x = PO2OnAerobicFractionData[:, 1], y = PO2OnAerobicFractionData[:, 2], slope = PO2OnAerobicFractionData[:, 3]);
Physiolibrary.Interfaces.RealInput_ pO2(unit = "mmHg");
Real O2UseByGlu;
Real O2UseByLac;
Real O2UseByFA;
Real FAfraction;
Real O2UseByKA;
Real KAfraction;
Real Ratio;
Real AnaerobicCals;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(q(final unit = "mg/min"), conc(final unit = "mg/ml")) "in mg/ml";
parameter Real gly2lac(unit = "mEq/g") = 1.0 / lacDensity "how much lactate is produced by one gram of glycogen";
parameter Real gly2energy(unit = "kcal/g") = anaerobic_glu2energy "how much energy in callories is produced by one gram of glycogen";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow glycogen "glycogen flow";
parameter Real[:, 3] GlycogenAvailability = {{0, 0.0, 0.0}, {50, 1.0, 0.0}};
Physiolibrary.Curves.Curve GlycogenAvailabilityCurve(x = GlycogenAvailability[:, 1], y = GlycogenAvailability[:, 2], slope = GlycogenAvailability[:, 3]);
Physiolibrary.Interfaces.RealOutput_ O2Use;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow ketoAcids(q(final unit = "mg/min"), conc(final unit = "mg/ml")) "in mg/ml";
equation
AerobicFraction.u = pO2;
LacFraction.u = lactate.conc * lacDensity * 100.0;
O2Use = AerobicFraction.val * eTOo2_coef * CalsUse;
O2UseByLac = LacFraction.val * O2Use;
if canBurnFattyAcids then
ketoAcids.q = 0;
KAfraction = 0;
O2UseByKA = 0;
O2UseByFA = FAfraction * O2Use;
O2UseByGlu + O2UseByLac + O2UseByFA = O2Use;
FAfraction = (1 - LacFraction.val) * Ratio / (Ratio + 0.026);
Ratio = fattyAcids.conc / glucose.conc;
Tissue_CO2FromMetabolism = 0.0446 * (O2UseByGlu * RQglu + O2UseByLac * RQlac + O2UseByFA * RQfat);
Tissue_MotabolicH2ORate = 0.000176 * CalsUse;
fattyAcids.q = FAfraction * CalsUse * eTOfat_coef;
else
fattyAcids.q = 0;
FAfraction = 0;
O2UseByFA = 0;
O2UseByKA = KAfraction * O2Use;
O2UseByGlu + O2UseByLac + O2UseByKA = O2Use;
KAfraction = (1 - LacFraction.val) * Ratio / (Ratio + 0.222);
Ratio = ketoAcids.conc / glucose.conc;
Tissue_CO2FromMetabolism = 0.0446 * (O2UseByGlu * RQglu + O2UseByLac * RQlac + O2UseByKA * RQketo);
Tissue_MotabolicH2ORate = 0.000176 * CalsUse;
ketoAcids.q = KAfraction * CalsUse * eTOketo_coef;
end if;
GlycogenAvailabilityCurve.u = glycogen.conc * 0.001;
if AerobicFraction.val < 1 then
AnaerobicCals = (1 - AerobicFraction.val) * CalsUse;
glycogen.q = GlycogenAvailabilityCurve.val * AnaerobicCals;
anaerobic_glu2energy * (glucose.q - O2UseByGlu / eTOo2_coef * eTOglu_coef) + gly2energy * glycogen.q = AnaerobicCals;
glucose.q - O2UseByGlu / eTOo2_coef * eTOglu_coef + gly2lac * glycogen.q = lactate.q * lacDensity - LacFraction.val * CalsUse * eTOlac_coef;
else
AnaerobicCals = 0.0;
glycogen.q = 0.0;
lactate.q * lacDensity = LacFraction.val * CalsUse * eTOlac_coef;
glucose.q = O2UseByGlu / eTOo2_coef * eTOglu_coef;
end if;
end CellularMetabolism;

model NutrientsAndMetabolism
HumMod.Metabolism.TissueMetabolism.Metabolism tissuesMetabolism(glucose(conc(start = 1.05)));
Physiolibrary.Interfaces.BusConnector busConnector;
HumMod.Metabolism.LiverMetabolism liverMetabolism;
HumMod.Metabolism.Glucose glucose;
HumMod.Metabolism.KetoAcids ketoAcids;
.HumMod.Metabolism.Proteins CellProteins;
.HumMod.Metabolism.GILumen.GILumenLeptinDriven gILumen;
.HumMod.Metabolism.Urea urea;
.HumMod.Metabolism.Lipids lipids;
Lactate lactate;
HumMod.Metabolism.AminoAcids aminoAcids;
.HumMod.Hormones.Glucagon glucagon;
.HumMod.Hormones.Insulin insulin;
.HumMod.Hormones.Thyrotropin thyrotropin;
.HumMod.Hormones.Thyroxine thyroxine;
.HumMod.Hormones.Leptin leptin;
equation
connect(tissuesMetabolism.busConnector, busConnector);
connect(liverMetabolism.busConnector, busConnector);
connect(busConnector, glucose.busConnector);
connect(glucose.q_out, tissuesMetabolism.glucose);
connect(ketoAcids.q_out, tissuesMetabolism.ketoAcids);
connect(liverMetabolism.Glucose, glucose.q_out);
connect(busConnector, gILumen.busConnector);
connect(ketoAcids.q_out, liverMetabolism.Ketoacids);
connect(urea.ureaFromMetabolism, liverMetabolism.Urea);
connect(urea.busConnector, busConnector);
connect(ketoAcids.busConnector, busConnector);
connect(CellProteins.busConnector, busConnector);
connect(busConnector, lipids.busConnector);
connect(lipids.FattyAcids, tissuesMetabolism.fattyAcids);
connect(lactate.busConnector, busConnector);
connect(lactate.Lactate, tissuesMetabolism.lactate);
connect(aminoAcids.busConnector, busConnector);
connect(gILumen.Protein_Absorption, aminoAcids.AminoAcids);
connect(aminoAcids.AminoAcids, liverMetabolism.AminoAcids);
connect(aminoAcids.AminoAcids, CellProteins.aminoAcids);
connect(gILumen.Carbohydrates_Absorption, tissuesMetabolism.GILumenCarbohydrates);
connect(lipids.toTriglicerides, gILumen.Fat_Absorption);
connect(lipids.toTriglicerides, liverMetabolism.triglicerides);
connect(lipids.FattyAcids, liverMetabolism.fattyAcids);
connect(insulin.Insulin, glucagon.Insulin);
connect(busConnector, glucagon.busConnector);
connect(busConnector, insulin.busConnector);
connect(busConnector, thyroxine.busConnector);
connect(busConnector, thyrotropin.busConnector);
connect(thyrotropin.TSH, thyroxine.TSH);
connect(thyroxine.Thyroxine, thyrotropin.Thyroxine);
connect(busConnector, leptin.busConnector);
connect(insulin.LM_Insulin_InsulinDelayed, busConnector.LM_Insulin_InsulinDelayed) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end NutrientsAndMetabolism;

package GILumen
model GILumenLeptinDriven
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Carbohydrates(initialSoluteMass = 1976.32, stateName = "GILumenCarbohydrates.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion;
Physiolibrary.ConcentrationFlow.InputPump Diet;
Physiolibrary.Factors.CurveValue AbsorptionSaturation(data = {{0, 0, 0.0}, {1900, 150, 0.08}, {6000, 600, 0.0}});
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Fat(initialSoluteMass = 2041.83, stateName = "GILumenFat.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion1;
Physiolibrary.ConcentrationFlow.InputPump Diet1;
Physiolibrary.Factors.SimpleMultiply AbsorptionSaturation1;
Physiolibrary.Blocks.Constant Constant1(k = 0.03);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Carbohydrates_Absorption(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Fat_Absorption(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.ConcentrationCompartment Protein(initialSoluteMass = 1637.19, stateName = "GILumenProtein.Mass");
Physiolibrary.ConcentrationFlow.SoluteFlowPump Absorbtion2;
Physiolibrary.ConcentrationFlow.InputPump Diet2;
Physiolibrary.Factors.SimpleMultiply AbsorptionSaturation2;
Physiolibrary.Blocks.Constant Constant2(k = 0.05);
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow Protein_Absorption(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Factors.CurveValue LeptinEffect(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.Blocks.Constant Constant3(k = 751 / 9.300000000000001 * 1000);
Physiolibrary.Blocks.Constant Constant4(k = 1 / 1440);
Physiolibrary.Factors.SimpleMultiply DietFeedingFraction;
Physiolibrary.Factors.CurveValue LeptinEffect1(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.Blocks.Constant Constant5(k = 500 / 4.35 * 1000);
Physiolibrary.Blocks.Constant Constant6(k = 1 / 1440);
Physiolibrary.Factors.SimpleMultiply DietFeedingFraction1;
Physiolibrary.Factors.CurveValue LeptinEffect2(data = {{0, 3.0, 0}, {8, 1.0, -0.04}, {50, 0.0, 0}});
Physiolibrary.Blocks.Constant Constant7(k = 900 / 4.1 * 1000);
Physiolibrary.Blocks.Constant Constant8(k = 1 / 1440);
Physiolibrary.Factors.SimpleMultiply DietFeedingFraction2;
Physiolibrary.Blocks.Constant Constant9(k = 25);
equation
connect(Carbohydrates.q_out, Absorbtion.q_in);
connect(Diet.q_out, Carbohydrates.q_out);
connect(Carbohydrates.soluteMass, AbsorptionSaturation.u);
connect(AbsorptionSaturation.y, Absorbtion.soluteFlow);
connect(AbsorptionSaturation.yBase, Constant.y);
connect(Fat.q_out, Absorbtion1.q_in);
connect(Diet1.q_out, Fat.q_out);
connect(Fat.soluteMass, AbsorptionSaturation1.u);
connect(AbsorptionSaturation1.y, Absorbtion1.soluteFlow);
connect(AbsorptionSaturation1.yBase, Constant1.y);
connect(busConnector.GILumenVolume_Mass, Fat.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GILumenVolume_Mass, Carbohydrates.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Absorbtion1.q_out, Fat_Absorption);
connect(Absorbtion.q_out, Carbohydrates_Absorption);
connect(Protein.q_out, Absorbtion2.q_in);
connect(Diet2.q_out, Protein.q_out);
connect(Protein.soluteMass, AbsorptionSaturation2.u);
connect(AbsorptionSaturation2.y, Absorbtion2.soluteFlow);
connect(AbsorptionSaturation2.yBase, Constant2.y);
connect(busConnector.GILumenVolume_Mass, Protein.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Absorbtion2.q_out, Protein_Absorption);
connect(busConnector.FA_Absorbtion, AbsorptionSaturation1.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Leptin, LeptinEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant3.y, LeptinEffect.yBase);
connect(Constant4.y, DietFeedingFraction.u);
connect(LeptinEffect.y, DietFeedingFraction.yBase);
connect(busConnector.Leptin, LeptinEffect1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant5.y, LeptinEffect1.yBase);
connect(Constant6.y, DietFeedingFraction1.u);
connect(LeptinEffect1.y, DietFeedingFraction1.yBase);
connect(busConnector.Leptin, LeptinEffect2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant7.y, LeptinEffect2.yBase);
connect(Constant8.y, DietFeedingFraction2.u);
connect(LeptinEffect2.y, DietFeedingFraction2.yBase);
connect(DietFeedingFraction2.y, Diet.desiredFlow);
connect(DietFeedingFraction1.y, Diet2.desiredFlow);
connect(DietFeedingFraction.y, Diet1.desiredFlow);
end GILumenLeptinDriven;
end GILumen;

package TissueMetabolism  "Metabolism Reactions in Tissues"
partial model TissueMetabolismBase
parameter Real initialTissueO2(final unit = "ml") = 4;
parameter Real O2solubility(final unit = "ml/mmHg") = 3e-005;
parameter Real O2fromBloodtoTissueConductance(final unit = "ml/(min.mmHg)") = 1000000;
parameter Real initialLactateMass(final unit = "mEq") = 0;
parameter Real NormalCalsUsed(final unit = "cal/min");
parameter Real DC(final unit = "(mEq/min)/(mEq/ml)");
parameter Real[:, 3] PO2OnAerobicFractionData = {{2, 0, 0}, {10, 1, 0}} "Aerobic Fraction of O2 tissue use depents on pO2";
Physiolibrary.Interfaces.RealInput_ LiquidVol(final unit = "ml") "sum of interstitial and intracellular tissue water";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow lactate(conc(final unit = "mEq/ml"), q(final unit = "mEq/min"));
Physiolibrary.Factors.SimpleMultiply Thyroid;
Physiolibrary.Factors.CurveValue HeatMetabolism_Skin(data = {{10, 0.0, 0}, {37, 1.0, 0.12}, {40, 1.5, 0}, {46, 0.0, 0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SimpleMultiply StructureEffect;
Physiolibrary.Blocks.CaloriesFlowConstant caloriesConstant(k = NormalCalsUsed);
Physiolibrary.Interfaces.RealInput_ T(final unit = "degC") "temperature";
Physiolibrary.Interfaces.RealInput_ Structure_Effect(final unit = "1");
Physiolibrary.Interfaces.RealInput_ ThyroidEffect(final unit = "1");
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow glucose(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Interfaces.RealInput_ BloodFlow(final unit = "ml/min") "blood flow through all tissue capilaries cross-section";
Modelica.Blocks.Math.Product PlasmaFlow1;
Modelica.Blocks.Math.Gain CalToO2(k = 0.2093);
Physiolibrary.Interfaces.RealInput_ BloodVol_PVCrit(final unit = "1") "part of plasma in blood";
Physiolibrary.Interfaces.RealInput_ pO2(final unit = "mmHg") "tissue venous O2 partial pressure";
Modelica.Blocks.Math.Sum TotalCaloriesUse;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "mEq/l", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.RealOutput_ cLactate(unit = "mEq/l");
Physiolibrary.Interfaces.RealOutput_ Tissue_CO2FromMetabolism(unit = "ml/min");
Physiolibrary.Interfaces.RealOutput_ Fuel_FractUseDelay;
Physiolibrary.Interfaces.RealOutput_ O2Use(unit = "ml/min");
Physiolibrary.Interfaces.RealOutput_ O2Need(unit = "ml/min");
Physiolibrary.Interfaces.RealOutput_ LactateFromMetabolism(unit = "mEq/min", start = 0);
Physiolibrary.Interfaces.RealOutput_ H2OFromMetabolism(unit = "ml/min");
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.Blocks.Min min(nin = 2);
Physiolibrary.Interfaces.RealOutput_ TotalCalsUsed(unit = "cal/min");
Modelica.Blocks.Math.Sum PartCaloriesUse;
NutrientDelivery lactateDelivery;
equation
connect(Thyroid.y, HeatMetabolism_Skin.yBase);
connect(HeatMetabolism_Skin.y, StructureEffect.yBase);
connect(caloriesConstant.y, Thyroid.yBase);
connect(T, HeatMetabolism_Skin.u);
connect(Structure_Effect, StructureEffect.u);
connect(Thyroid.u, ThyroidEffect);
connect(PlasmaFlow1.u1, BloodFlow);
connect(BloodVol_PVCrit, PlasmaFlow1.u2);
connect(TotalCaloriesUse.y, CalToO2.u);
connect(concentrationMeasure.actualConc, cLactate);
connect(CalToO2.y, O2Need);
connect(flowMeasure.actualFlow, LactateFromMetabolism);
connect(min.y, Fuel_FractUseDelay);
connect(TotalCaloriesUse.y, TotalCalsUsed);
connect(PartCaloriesUse.y, TotalCaloriesUse.u[1]);
connect(StructureEffect.y, PartCaloriesUse.u[1]);
connect(PlasmaFlow1.y, lactateDelivery.solventFlow);
connect(lactateDelivery.q_out, lactate);
connect(lactate, lactateDelivery.q_in);
connect(lactateDelivery.neededFlow, concentrationMeasure.q_in);
connect(lactateDelivery.neededFlow, flowMeasure.q_out);
end TissueMetabolismBase;

model TissueMetabolism
extends TissueMetabolismBase;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}});
NutrientDelivery fattyAcidsDelivery;
NutrientDelivery glucoseDelivery;
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage(concentration = 0);
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
equation
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(cellularMetabolism.Tissue_MotabolicH2ORate, H2OFromMetabolism);
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(fattyAcids, fattyAcidsDelivery.q_in);
connect(PlasmaFlow1.y, fattyAcidsDelivery.solventFlow);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.q_out, glucose);
connect(fattyAcidsDelivery.q_out, fattyAcids);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(glucoseDelivery.neededFlow, cellularMetabolism.glucose);
connect(fattyAcidsDelivery.neededFlow, cellularMetabolism.fattyAcids);
connect(fattyAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(unlimitedStorage.q_out, cellularMetabolism.glycogen);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(cellularMetabolism.ketoAcids, unlimitedStorage1.q_out);
end TissueMetabolism;

model SkeletalMuscleMetabolism
extends TissueMetabolismBase(TotalCaloriesUse(nin = 3), HeatMetabolism_Skin(data = {{10.0, 0.0, 0}, {37.1, 1.0, 0.12}, {40.0, 1.5, 0}, {46.0, 0.0, 0}}), PartCaloriesUse(nin = 3));
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}}, GlycogenAvailabilityCurve(iFrom(start = 2)));
Physiolibrary.Blocks.CaloriesFlowConstant Posture_Cals(k = 19);
Physiolibrary.Blocks.FractConstant fractConstant(k = 30);
Modelica.Blocks.Math.Division TotalCals;
Physiolibrary.Interfaces.RealInput_ ExerciseMetabolism_MotionCals(final unit = "cal/min");
Physiolibrary.ConcentrationFlow.MassStorageCompartment glycogen(q_out(conc(unit = "mg"), q(unit = "mg/min")), stateName = "SkeletalMuscle-Glycogen.Mass", MINUTE_FLOW_TO_MASS_CONVERSION = 0.001, initialSoluteMass(unit = "g") = 500, STEADY = false, soluteMass(unit = "g"));
Physiolibrary.ConcentrationFlow.SoluteFlowPump synthesis;
Physiolibrary.Blocks.MassFlowConstant massFlowConstant(k = 20);
Physiolibrary.Factors.SplineValue2 GlucoseEffect(data = {{0, 0.0, 0.0}, {100, 1.0, 0.01}, {300, 3.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SplineValue2 Space(data = {{0, 4.0, 0.0}, {400, 1.0, -0.015}, {500, 0.0, 0.0}}, curve(iFrom(start = 3)));
Physiolibrary.Factors.DelayedToSpline InsulinEffect(initialValue = 20, data = {{0, 0.0, 0.0}, {20, 1.0, 0.2}, {100, 20.0, 0.0}}, curve(iFrom(start = 2)), integrator(stateName = "SkeletalMuscle-Insulin.[InsulinDelayed]"), adaptationSignalName = "SkeletalMuscle-Insulin.[InsulinDelayed]");
Physiolibrary.Interfaces.RealInput_ Insulin(final unit = "uU/ml") "tissue venous O2 partial pressure";
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure3(unitsString = "mg/dl", toAnotherUnitCoef = 100);
Physiolibrary.Interfaces.RealOutput_ GlucoseToCellsStorageFlow(unit = "mmol/min") "glucose to muscle cells";
Glucose_MG_TO_MMOL glucose_MG_TO_MMOL;
NutrientDelivery fattyAcidsDelivery;
NutrientDelivery glucoseDelivery;
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
Physiolibrary.Interfaces.RealOutput_ skeletalMuscle_HeatWithoutTermoregulation(unit = "kcal/min") "Skeletal muscle termal energy flow without shivering effect. (Used in termoragulation to calculate whole thermal energy flow from muscle connected with hypothalamus shivering drive.) [Cal/min]";
Modelica.Blocks.Math.Feedback HeatCals;
Physiolibrary.Interfaces.RealInput_ ShiveringCals;
equation
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(ExerciseMetabolism_MotionCals, TotalCals.u1);
connect(fractConstant.y, TotalCals.u2);
connect(synthesis.q_out, glycogen.q_out);
connect(glycogen.q_out, cellularMetabolism.glycogen);
connect(GlucoseEffect.y, synthesis.soluteFlow);
connect(Space.yBase, massFlowConstant.y);
connect(InsulinEffect.y, GlucoseEffect.yBase);
connect(InsulinEffect.yBase, Space.y);
connect(InsulinEffect.u, Insulin);
connect(concentrationMeasure3.actualConc, GlucoseEffect.u);
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(glucose_MG_TO_MMOL.y, GlucoseToCellsStorageFlow);
connect(GlucoseEffect.y, glucose_MG_TO_MMOL.u);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(H2OFromMetabolism, cellularMetabolism.Tissue_MotabolicH2ORate);
connect(glucoseDelivery.neededFlow, synthesis.q_in);
connect(glucoseDelivery.neededFlow, concentrationMeasure3.q_in);
connect(glucoseDelivery.neededFlow, cellularMetabolism.glucose);
connect(fattyAcids, fattyAcidsDelivery.q_in);
connect(PlasmaFlow1.y, fattyAcidsDelivery.solventFlow);
connect(fattyAcidsDelivery.neededFlow, cellularMetabolism.fattyAcids);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.q_out, glucose);
connect(fattyAcidsDelivery.q_out, fattyAcids);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(fattyAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(glycogen.soluteMass, Space.u);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(cellularMetabolism.ketoAcids, unlimitedStorage1.q_out);
connect(Posture_Cals.y, PartCaloriesUse.u[3]);
connect(ExerciseMetabolism_MotionCals, TotalCaloriesUse.u[3]);
connect(TotalCals.y, HeatCals.u1);
connect(HeatCals.y, PartCaloriesUse.u[2]);
connect(ExerciseMetabolism_MotionCals, HeatCals.u2);
connect(PartCaloriesUse.y, skeletalMuscle_HeatWithoutTermoregulation);
connect(ShiveringCals, TotalCaloriesUse.u[2]);
end SkeletalMuscleMetabolism;

model RespiratoryMuscle
extends HumMod.Metabolism.TissueMetabolism.TissueMetabolismBase(TotalCaloriesUse(nin = 4), HeatMetabolism_Skin(data = {{10.0, 0.0, 0}, {37.1, 1.0, 0.12}, {40.0, 1.5, 0}, {46.0, 0.0, 0}}));
Physiolibrary.Blocks.CaloriesFlowConstant Shivering_Cals(k = 0);
Physiolibrary.Blocks.CaloriesFlowConstant motionCals(k = 5);
Physiolibrary.Blocks.CaloriesFlowConstant heatCals(k = 16);
Physiolibrary.ConcentrationFlow.MassStorageCompartment glycogen(stateName = "RespiratoryMuscle-Glycogen.Mass", MINUTE_FLOW_TO_MASS_CONVERSION = 0.001, q_out(q(unit = "mg/min"), conc(unit = "g")), initialSoluteMass(unit = "g") = 46, STEADY = false, soluteMass(unit = "g"));
Physiolibrary.ConcentrationFlow.SoluteFlowPump synthesis;
Physiolibrary.Blocks.MassFlowConstant massFlowConstant(k = 20);
Physiolibrary.Factors.CurveValue GlucoseEffect(data = {{0, 0.0, 0.0}, {100, 1.0, 0.01}, {300, 3.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.CurveValue Space(data = {{0, 4.0, 0.0}, {40, 1.0, -0.15}, {46, 0.0, 0.0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.DelayedToSpline InsulinEffect(initialValue = 20, data = {{0, 0.0, 0.0}, {20, 1.0, 0.2}, {100, 20.0, 0.0}}, curve(iFrom(start = 2)), integrator(stateName = "RespiratoryMuscle-Insulin.[InsulinDelayed]"), adaptationSignalName = "RespiratoryMuscle-Insulin.[InsulinDelayed]");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure3(unitsString = "mg/dl", toAnotherUnitCoef = 100);
Physiolibrary.Interfaces.RealInput_ Insulin(final unit = "uU/ml") "tissue venous O2 partial pressure";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}}, GlycogenAvailability = {{0, 0, 0}, {5, 1, 0}}, GlycogenAvailabilityCurve(iFrom(start = 2)));
Glucose_MG_TO_MMOL glucose_MG_TO_MMOL;
Physiolibrary.Interfaces.RealOutput_ GlucoseToCellsStorageFlow(unit = "mmol/min") "glucose to muscle cells";
NutrientDelivery fattyAcidsDelivery;
NutrientDelivery glucoseDelivery;
Physiolibrary.Interfaces.RealOutput_ MotionCals_(unit = "cal/min");
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
equation
connect(Shivering_Cals.y, TotalCaloriesUse.u[4]);
connect(motionCals.y, TotalCaloriesUse.u[2]);
connect(heatCals.y, TotalCaloriesUse.u[3]);
connect(synthesis.q_out, glycogen.q_out);
connect(glycogen.q_out, cellularMetabolism.glycogen);
connect(GlucoseEffect.y, synthesis.soluteFlow);
connect(Space.yBase, massFlowConstant.y);
connect(InsulinEffect.y, GlucoseEffect.yBase);
connect(InsulinEffect.yBase, Space.y);
connect(InsulinEffect.u, Insulin);
connect(concentrationMeasure3.actualConc, GlucoseEffect.u);
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(glucose_MG_TO_MMOL.y, GlucoseToCellsStorageFlow);
connect(GlucoseEffect.y, glucose_MG_TO_MMOL.u);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(H2OFromMetabolism, cellularMetabolism.Tissue_MotabolicH2ORate);
connect(fattyAcids, fattyAcidsDelivery.q_in);
connect(PlasmaFlow1.y, fattyAcidsDelivery.solventFlow);
connect(fattyAcidsDelivery.neededFlow, cellularMetabolism.fattyAcids);
connect(glucoseDelivery.neededFlow, synthesis.q_in);
connect(glucoseDelivery.neededFlow, concentrationMeasure3.q_in);
connect(glucoseDelivery.neededFlow, cellularMetabolism.glucose);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.q_out, glucose);
connect(fattyAcidsDelivery.q_out, fattyAcids);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(fattyAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(motionCals.y, MotionCals_);
connect(glycogen.soluteMass, Space.u);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(cellularMetabolism.ketoAcids, unlimitedStorage1.q_out);
end RespiratoryMuscle;

model Brain
extends HumMod.Metabolism.TissueMetabolism.TissueMetabolismBase;
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}}, canBurnFattyAcids = false);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow ketoAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
NutrientDelivery ketoAcidsDelivery;
NutrientDelivery glucoseDelivery;
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage(concentration = 0);
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
equation
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(H2OFromMetabolism, cellularMetabolism.Tissue_MotabolicH2ORate);
connect(glucoseDelivery.neededFlow, cellularMetabolism.glucose);
connect(ketoAcidsDelivery.solventFlow, PlasmaFlow1.y);
connect(ketoAcids, ketoAcidsDelivery.q_in);
connect(ketoAcidsDelivery.neededFlow, cellularMetabolism.ketoAcids);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.q_out, glucose);
connect(ketoAcidsDelivery.q_out, ketoAcids);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(ketoAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(unlimitedStorage.q_out, cellularMetabolism.glycogen);
connect(unlimitedStorage1.q_out, cellularMetabolism.fattyAcids);
end Brain;

model Kidney
extends HumMod.Metabolism.TissueMetabolism.TissueMetabolism(TotalCaloriesUse(nin = 4));
Physiolibrary.Interfaces.RealInput_ PT_Na_Reab(final quantity = "flow", final unit = "mEq/min");
Physiolibrary.Interfaces.RealInput_ LH_Na_Reab(final quantity = "flow", final unit = "mEq/min");
Physiolibrary.Interfaces.RealInput_ DT_Na_Reab(final quantity = "flow", final unit = "mEq/min");
Modelica.Blocks.Math.Gain CalPerNa(k = 3.6) "CalPerNa+(Meq/Min)";
Modelica.Blocks.Math.Gain CalPerNa1(k = 3.6) "CalPerNa+(Meq/Min)";
Modelica.Blocks.Math.Gain CalPerNa2(k = 3.6) "CalPerNa+(Meq/Min)";
equation
connect(CalPerNa.y, TotalCaloriesUse.u[2]);
connect(CalPerNa1.y, TotalCaloriesUse.u[3]);
connect(CalPerNa2.y, TotalCaloriesUse.u[4]);
connect(CalPerNa.u, PT_Na_Reab);
connect(LH_Na_Reab, CalPerNa2.u);
connect(DT_Na_Reab, CalPerNa1.u);
end Kidney;

model HeartMuscle
extends HumMod.Metabolism.TissueMetabolism.TissueMetabolism(TotalCaloriesUse(nin = 3));
parameter Real MotionCals(final unit = "cal/min");
parameter Real HeatCals(final unit = "cal/min");
Physiolibrary.Blocks.CaloriesFlowConstant motionCals(k = MotionCals);
Physiolibrary.Blocks.CaloriesFlowConstant heatCals(k = HeatCals);
equation
connect(motionCals.y, TotalCaloriesUse.u[2]);
connect(heatCals.y, TotalCaloriesUse.u[3]);
end HeartMuscle;

model GITract
extends TissueMetabolismBase;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}});
NutrientDelivery fattyAcidsDelivery;
NutrientDelivery glucoseDelivery;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure1;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure2;
Physiolibrary.Interfaces.RealOutput_ GIT_GluUse(unit = "mg/min");
Physiolibrary.Interfaces.RealOutput_ GIT_FatUse(unit = "mg/min");
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage2(concentration = 0);
equation
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(cellularMetabolism.Tissue_MotabolicH2ORate, H2OFromMetabolism);
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(fattyAcids, fattyAcidsDelivery.q_in);
connect(PlasmaFlow1.y, fattyAcidsDelivery.solventFlow);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(fattyAcidsDelivery.q_out, fattyAcids);
connect(glucoseDelivery.q_out, glucose);
connect(flowMeasure1.q_in, cellularMetabolism.glucose);
connect(glucoseDelivery.neededFlow, flowMeasure1.q_out);
connect(flowMeasure2.q_in, cellularMetabolism.fattyAcids);
connect(fattyAcidsDelivery.neededFlow, flowMeasure2.q_out);
connect(flowMeasure1.actualFlow, GIT_GluUse);
connect(flowMeasure2.actualFlow, GIT_FatUse);
connect(fattyAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(cellularMetabolism.ketoAcids, unlimitedStorage1.q_out);
connect(cellularMetabolism.glycogen, unlimitedStorage2.q_out);
end GITract;

model Liver
extends TissueMetabolismBase;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
HumMod.Metabolism.CellularMetabolism cellularMetabolism(LacFractionData = {{10, 0, 0}, {100, 0.3, 0}}, Ratio(start = 0.08699999999999999), glucose(conc(start = 1.43)));
NutrientDelivery_Fat fattyAcidsDelivery(neededFlow(q(start = 125.166135276543)));
NutrientDelivery_2 glucoseDelivery(delivery(start = 991.319));
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow GILumenCarbohydrates(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "mg/dl", toAnotherUnitCoef = 100);
Physiolibrary.Interfaces.RealOutput_ PortalVeinGlucose(unit = "mg/dl");
Physiolibrary.Interfaces.RealOutput_ PortalVeinFat(unit = "mg/dl");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2(unitsString = "mg/dl", toAnotherUnitCoef = 100);
Physiolibrary.Interfaces.RealInput_ GITract_GlucoseUsed(final unit = "mg/min") "glucose to GIT metabolism flow";
Physiolibrary.Interfaces.RealInput_ GITract_FatUsed(final unit = "mg/min") "fat to GIT metabolism flow";
Physiolibrary.Interfaces.RealInput_ FatAbsorbtion(final unit = "mg/min") "from GILumen";
Physiolibrary.Interfaces.RealInput_ HepaticArtyBloodFlow(final unit = "ml/min") "blood flow through all tissue capilaries cross-section";
Modelica.Blocks.Math.Product PlasmaFlow2;
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage1(concentration = 0);
Physiolibrary.ConcentrationFlow.UnlimitedStorage unlimitedStorage2(concentration = 0);
equation
connect(cellularMetabolism.Tissue_CO2FromMetabolism, Tissue_CO2FromMetabolism);
connect(flowMeasure.q_in, cellularMetabolism.lactate);
connect(cellularMetabolism.Tissue_MotabolicH2ORate, H2OFromMetabolism);
connect(TotalCaloriesUse.y, cellularMetabolism.CalsUse);
connect(glucoseDelivery.neededFlow, cellularMetabolism.glucose);
connect(fattyAcids, fattyAcidsDelivery.q_in);
connect(PlasmaFlow1.y, fattyAcidsDelivery.solventFlow);
connect(fattyAcidsDelivery.neededFlow, cellularMetabolism.fattyAcids);
connect(PlasmaFlow1.y, glucoseDelivery.solventFlow);
connect(glucose, glucoseDelivery.q_in);
connect(glucoseDelivery.FuelFractUseDelay, min.u[2]);
connect(concentrationMeasure1.actualConc, PortalVeinGlucose);
connect(concentrationMeasure2.actualConc, PortalVeinFat);
connect(glucoseDelivery.neededFlow, concentrationMeasure1.q_in);
connect(glucoseDelivery.q_out, glucose);
connect(fattyAcidsDelivery.q_out, fattyAcids);
connect(fattyAcidsDelivery.neededFlow, concentrationMeasure2.q_in);
connect(GITract_GlucoseUsed, glucoseDelivery.GITUsed);
connect(GITract_FatUsed, fattyAcidsDelivery.GITUsed);
connect(fattyAcidsDelivery.FatAbsorbtion, FatAbsorbtion);
connect(fattyAcidsDelivery.FuelFractUseDelay, min.u[1]);
connect(BloodVol_PVCrit, PlasmaFlow2.u2);
connect(HepaticArtyBloodFlow, PlasmaFlow2.u1);
connect(PlasmaFlow2.y, glucoseDelivery.HepaticArty);
connect(GILumenCarbohydrates, glucoseDelivery.fromGILumen);
connect(cellularMetabolism.ketoAcids, unlimitedStorage1.q_out);
connect(pO2, cellularMetabolism.pO2);
connect(cellularMetabolism.O2Use, O2Use);
connect(unlimitedStorage2.q_out, cellularMetabolism.glycogen);
end Liver;

model Skin
extends TissueMetabolism(HeatMetabolism_Skin(data = {{10.0, 0.0, 0}, {29.5, 1.0, 0.12}, {40.0, 1.5, 0}, {46.0, 0.0, 0}}));
end Skin;

model Bone
extends TissueMetabolism;
end Bone;

model Fat
extends TissueMetabolism;
end Fat;

model OtherTissue
extends TissueMetabolism;
end OtherTissue;

model Metabolism
HumMod.Metabolism.TissueMetabolism.Bone bone(DC = 180, initialTissueO2 = 4.57, NormalCalsUsed = 69.8614);
HumMod.Metabolism.TissueMetabolism.Brain brain(DC = 180, PO2OnAerobicFractionData = {{2.0, 0.0, 0}, {20.0, 1.0, 0}}, NormalCalsUsed = 193.709);
HumMod.Metabolism.TissueMetabolism.Fat fat(DC = 270, initialTissueO2 = 21.87, NormalCalsUsed = 29.9658);
HumMod.Metabolism.TissueMetabolism.GITract gITract(DC = 180, initialTissueO2 = 1.826, NormalCalsUsed = 92.7945);
HumMod.Metabolism.TissueMetabolism.Kidney kidney(DC = 20, PO2OnAerobicFractionData = {{2.0, 0.0, 0}, {20.0, 1.0, 0}}, initialTissueO2 = 0.48, NormalCalsUsed = 36.8312);
HumMod.Metabolism.TissueMetabolism.Liver liver(DC = 100, PO2OnAerobicFractionData = {{2.0, 0.0, 0}, {10.0, 1.0, 0}}, initialTissueO2 = 2.96, NormalCalsUsed = 147.338);
HumMod.Metabolism.TissueMetabolism.OtherTissue otherTissue(DC = 270, initialTissueO2 = 5.05, NormalCalsUsed = 39.1075);
HumMod.Metabolism.TissueMetabolism.RespiratoryMuscle respiratoryMuscle(DC = 270, initialTissueO2 = 0.57, NormalCalsUsed = 6.27882);
HumMod.Metabolism.TissueMetabolism.RightHeartMuscle rightHeart(MotionCals = 5, HeatCals = 17, DC = 3, initialTissueO2 = 0.02, NormalCalsUsed = 2.34779);
HumMod.Metabolism.TissueMetabolism.LeftHeartMuscle leftHeart(MotionCals = 24, HeatCals = 87, DC = 18, initialTissueO2 = 0.115, NormalCalsUsed = 15.7067);
HumMod.Metabolism.TissueMetabolism.SkeletalMuscleMetabolism skeletalMuscle(DC = 1875, PO2OnAerobicFractionData = {{0.0, 0.0, 0}, {15.0, 0.2, 0.04}, {20.0, 1.0, 0}}, initialTissueO2 = 52.363, NormalCalsUsed = 145.228);
HumMod.Metabolism.TissueMetabolism.Skin skin(DC = 270, PO2OnAerobicFractionData = {{2.0, 0.0, 0}, {20.0, 1.0, 0}}, initialTissueO2 = 1.84, HeatMetabolism_Skin(data = {{10.0, 0.0, 0}, {29.5, 1.0, 0.12}, {40.0, 1.5, 0}, {46.0, 0.0, 0}}), NormalCalsUsed = 31.2457);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow glucose(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fattyAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow ketoAcids(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow GILumenCarbohydrates(conc(final unit = "mg/ml"), q(final unit = "mg/min"));
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow lactate(conc(final unit = "mEq/ml"), q(final unit = "mEq/min"));
Modelica.Blocks.Math.Feedback Heat;
Modelica.Blocks.Math.Sum MetabolicH2ORate(nin = 12);
Modelica.Blocks.Math.Sum CoreHeat(nin = 11);
Modelica.Blocks.Math.Sum MotionCals(nin = 3);
Modelica.Blocks.Math.Gain gain(k = -1);
equation
connect(brain.glucose, glucose);
connect(respiratoryMuscle.glucose, glucose);
connect(rightHeart.glucose, glucose);
connect(leftHeart.glucose, glucose);
connect(skeletalMuscle.glucose, glucose);
connect(skin.glucose, glucose);
connect(bone.glucose, glucose);
connect(kidney.glucose, glucose);
connect(gITract.glucose, glucose);
connect(fat.glucose, glucose);
connect(otherTissue.glucose, glucose);
connect(brain.lactate, lactate);
connect(respiratoryMuscle.lactate, lactate);
connect(leftHeart.lactate, lactate);
connect(rightHeart.lactate, lactate);
connect(skeletalMuscle.lactate, lactate);
connect(skin.lactate, lactate);
connect(bone.lactate, lactate);
connect(liver.lactate, lactate);
connect(kidney.lactate, lactate);
connect(gITract.lactate, lactate);
connect(fat.lactate, lactate);
connect(otherTissue.lactate, lactate);
connect(respiratoryMuscle.fattyAcids, fattyAcids);
connect(rightHeart.fattyAcids, fattyAcids);
connect(leftHeart.fattyAcids, fattyAcids);
connect(skeletalMuscle.fattyAcids, fattyAcids);
connect(skin.fattyAcids, fattyAcids);
connect(bone.fattyAcids, fattyAcids);
connect(kidney.fattyAcids, fattyAcids);
connect(gITract.fattyAcids, fattyAcids);
connect(fat.fattyAcids, fattyAcids);
connect(otherTissue.fattyAcids, fattyAcids);
connect(busConnector.Brain_LiquidVol, brain.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RespiratoryMuscle_LiquidVol, respiratoryMuscle.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RightHeart_LiquidVol, rightHeart.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.LeftHeart_LiquidVol, leftHeart.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.SkeletalMuscle_LiquidVol, skeletalMuscle.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(bone.LiquidVol, busConnector.Bone_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(liver.LiquidVol, busConnector.Liver_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(gITract.LiquidVol, busConnector.GITract_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(fat.LiquidVol, busConnector.Fat_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(otherTissue.LiquidVol, busConnector.OtherTissue_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.LiquidVol, busConnector.Kidney_LiquidVol) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(busConnector.Skin_LiquidVol, skin.LiquidVol) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.LeftHeart_BloodFlow, leftHeart.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RightHeart_BloodFlow, rightHeart.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.Brain_BloodFlow, brain.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RespiratoryMuscle_BloodFlow, respiratoryMuscle.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.SkeletalMuscle_BloodFlow, skeletalMuscle.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.Skin_BloodFlow, skin.BloodFlow) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(bone.BloodFlow, busConnector.Bone_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.BloodFlow, busConnector.Kidney_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(gITract.BloodFlow, busConnector.GITract_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(fat.BloodFlow, busConnector.Fat_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(otherTissue.BloodFlow, busConnector.OtherTissue_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(bone.Structure_Effect, busConnector.Bone_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(liver.Structure_Effect, busConnector.Liver_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.Structure_Effect, busConnector.Kidney_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(gITract.Structure_Effect, busConnector.GITract_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(fat.Structure_Effect, busConnector.Fat_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(otherTissue.Structure_Effect, busConnector.OtherTissue_StructureEffect) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(busConnector.Skin_StructureEffect, skin.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.SkeletalMuscle_StructureEffect, skeletalMuscle.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.LeftHeart_StructureEffect, leftHeart.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RightHeart_StructureEffect, rightHeart.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RespiratoryMuscle_StructureEffect, respiratoryMuscle.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.Brain_StructureEffect, brain.Structure_Effect) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(kidney.PT_Na_Reab, busConnector.PT_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.LH_Na_Reab, busConnector.LH_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.DT_Na_Reab, busConnector.DT_Na_Reab) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(busConnector.ExerciseMetabolism_MotionCals, skeletalMuscle.ExerciseMetabolism_MotionCals) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.BloodVol_PVCrit, brain.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, respiratoryMuscle.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, rightHeart.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, leftHeart.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, skeletalMuscle.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, skin.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, bone.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, liver.BloodVol_PVCrit);
connect(gITract.BloodVol_PVCrit, busConnector.BloodVol_PVCrit);
connect(otherTissue.BloodVol_PVCrit, busConnector.BloodVol_PVCrit);
connect(fat.BloodVol_PVCrit, busConnector.BloodVol_PVCrit);
connect(busConnector.BloodVol_PVCrit, kidney.BloodVol_PVCrit);
connect(busConnector.ThyroidEffect, brain.ThyroidEffect);
connect(busConnector.ThyroidEffect, respiratoryMuscle.ThyroidEffect);
connect(busConnector.ThyroidEffect, rightHeart.ThyroidEffect);
connect(busConnector.ThyroidEffect, leftHeart.ThyroidEffect);
connect(busConnector.ThyroidEffect, skeletalMuscle.ThyroidEffect);
connect(busConnector.ThyroidEffect, skin.ThyroidEffect);
connect(busConnector.ThyroidEffect, bone.ThyroidEffect);
connect(busConnector.ThyroidEffect, liver.ThyroidEffect);
connect(gITract.ThyroidEffect, busConnector.ThyroidEffect);
connect(otherTissue.ThyroidEffect, busConnector.ThyroidEffect);
connect(fat.ThyroidEffect, busConnector.ThyroidEffect);
connect(busConnector.ThyroidEffect, kidney.ThyroidEffect);
connect(bone.pO2, busConnector.Bone_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(liver.pO2, busConnector.Liver_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.pO2, busConnector.Kidney_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(gITract.pO2, busConnector.GITract_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(fat.pO2, busConnector.Fat_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(otherTissue.pO2, busConnector.OtherTissue_PO2) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(busConnector.Skin_PO2, skin.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.SkeletalMuscle_PO2, skeletalMuscle.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.LeftHeart_PO2, leftHeart.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RightHeart_PO2, rightHeart.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.RespiratoryMuscle_PO2, respiratoryMuscle.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.Brain_PO2, brain.pO2) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(bone.T, busConnector.bone_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(liver.T, busConnector.liver_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(kidney.T, busConnector.kidney_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(gITract.T, busConnector.GITract_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(fat.T, busConnector.fat_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(otherTissue.T, busConnector.otherTissue_T) annotation(Text(string = "%second", index = 1, extent = {{5, 0}, {5, 0}}));
connect(busConnector.skin_T, skin.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.skeletalMuscle_T, skeletalMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.leftHeart_T, leftHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.rightHeart_T, rightHeart.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.respiratoryMuscle_T, respiratoryMuscle.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(busConnector.brain_T, brain.T) annotation(Text(string = "%first", index = -1, extent = {{-5, 0}, {-5, 0}}));
connect(bone.cLactate, busConnector.bone_cLactate);
connect(liver.cLactate, busConnector.liver_cLactate);
connect(kidney.cLactate, busConnector.kidney_cLactate);
connect(gITract.cLactate, busConnector.GITract_cLactate);
connect(fat.cLactate, busConnector.fat_cLactate);
connect(otherTissue.cLactate, busConnector.otherTissue_cLactate);
connect(busConnector.skin_cLactate, skin.cLactate);
connect(busConnector.skeletalMuscle_cLactate, skeletalMuscle.cLactate);
connect(busConnector.leftHeart_cLactate, leftHeart.cLactate);
connect(busConnector.rightHeart_cLactate, rightHeart.cLactate);
connect(busConnector.respiratoryMuscle_cLactate, respiratoryMuscle.cLactate);
connect(busConnector.brain_cLactate, brain.cLactate);
connect(bone.Tissue_CO2FromMetabolism, busConnector.bone_CO2FromMetabolism);
connect(liver.Tissue_CO2FromMetabolism, busConnector.liver_CO2FromMetabolism);
connect(kidney.Tissue_CO2FromMetabolism, busConnector.kidney_CO2FromMetabolism);
connect(gITract.Tissue_CO2FromMetabolism, busConnector.GITract_CO2FromMetabolism);
connect(fat.Tissue_CO2FromMetabolism, busConnector.fat_CO2FromMetabolism);
connect(otherTissue.Tissue_CO2FromMetabolism, busConnector.otherTissue_CO2FromMetabolism);
connect(busConnector.skin_CO2FromMetabolism, skin.Tissue_CO2FromMetabolism);
connect(busConnector.skeletalMuscle_CO2FromMetabolism, skeletalMuscle.Tissue_CO2FromMetabolism);
connect(busConnector.leftHeart_CO2FromMetabolism, leftHeart.Tissue_CO2FromMetabolism);
connect(busConnector.rightHeart_CO2FromMetabolism, rightHeart.Tissue_CO2FromMetabolism);
connect(busConnector.respiratoryMuscle_CO2FromMetabolism, respiratoryMuscle.Tissue_CO2FromMetabolism);
connect(busConnector.brain_CO2FromMetabolism, brain.Tissue_CO2FromMetabolism);
connect(bone.LactateFromMetabolism, busConnector.bone_LactateFromMetabolism);
connect(liver.LactateFromMetabolism, busConnector.liver_LactateFromMetabolism);
connect(kidney.LactateFromMetabolism, busConnector.kidney_LactateFromMetabolism);
connect(gITract.LactateFromMetabolism, busConnector.GITract_LactateFromMetabolism);
connect(fat.LactateFromMetabolism, busConnector.fat_LactateFromMetabolism);
connect(otherTissue.LactateFromMetabolism, busConnector.otherTissue_LactateFromMetabolism);
connect(busConnector.skin_LactateFromMetabolism, skin.LactateFromMetabolism);
connect(busConnector.skeletalMuscle_LactateFromMetabolism, skeletalMuscle.LactateFromMetabolism);
connect(busConnector.leftHeart_LactateFromMetabolism, leftHeart.LactateFromMetabolism);
connect(busConnector.rightHeart_LactateFromMetabolism, rightHeart.LactateFromMetabolism);
connect(busConnector.respiratoryMuscle_LactateFromMetabolism, respiratoryMuscle.LactateFromMetabolism);
connect(busConnector.brain_LactateFromMetabolism, brain.LactateFromMetabolism);
connect(bone.O2Use, busConnector.bone_O2Use);
connect(liver.O2Use, busConnector.liver_O2Use);
connect(kidney.O2Use, busConnector.kidney_O2Use);
connect(gITract.O2Use, busConnector.GITract_O2Use);
connect(fat.O2Use, busConnector.fat_O2Use);
connect(otherTissue.O2Use, busConnector.otherTissue_O2Use);
connect(busConnector.skin_O2Use, skin.O2Use);
connect(busConnector.skeletalMuscle_O2Use, skeletalMuscle.O2Use);
connect(busConnector.leftHeart_O2Use, leftHeart.O2Use);
connect(busConnector.rightHeart_O2Use, rightHeart.O2Use);
connect(busConnector.respiratoryMuscle_O2Use, respiratoryMuscle.O2Use);
connect(busConnector.brain_O2Use, brain.O2Use);
connect(bone.O2Need, busConnector.Bone_O2Need);
connect(liver.O2Need, busConnector.Liver_O2Need);
connect(kidney.O2Need, busConnector.Kidney_O2Need);
connect(gITract.O2Need, busConnector.GITract_O2Need);
connect(fat.O2Need, busConnector.Fat_O2Need);
connect(otherTissue.O2Need, busConnector.OtherO2Need);
connect(busConnector.Skin_O2Need, skin.O2Need);
connect(busConnector.SkeletalMuscle_O2Need, skeletalMuscle.O2Need);
connect(busConnector.LeftHeart_O2Need, leftHeart.O2Need);
connect(busConnector.RightHeart_O2Need, rightHeart.O2Need);
connect(busConnector.RespiratoryMuscle_O2Need, respiratoryMuscle.O2Need);
connect(busConnector.Brain_O2Need, brain.O2Need);
connect(bone.Fuel_FractUseDelay, busConnector.bone_Fuel_FractUseDelay);
connect(liver.Fuel_FractUseDelay, busConnector.liver_Fuel_FractUseDelay);
connect(kidney.Fuel_FractUseDelay, busConnector.kidney_Fuel_FractUseDelay);
connect(gITract.Fuel_FractUseDelay, busConnector.GITract_Fuel_FractUseDelay);
connect(fat.Fuel_FractUseDelay, busConnector.fat_Fuel_FractUseDelay);
connect(otherTissue.Fuel_FractUseDelay, busConnector.otherTissue_Fuel_FractUseDelay);
connect(busConnector.skin_Fuel_FractUseDelay, skin.Fuel_FractUseDelay);
connect(busConnector.skeletalMuscle_Fuel_FractUseDelay, skeletalMuscle.Fuel_FractUseDelay);
connect(busConnector.leftHeart_Fuel_FractUseDelay, leftHeart.Fuel_FractUseDelay);
connect(busConnector.rightHeart_Fuel_FractUseDelay, rightHeart.Fuel_FractUseDelay);
connect(busConnector.respiratoryMuscle_Fuel_FractUseDelay, respiratoryMuscle.Fuel_FractUseDelay);
connect(busConnector.brain_Fuel_FractUseDelay, brain.Fuel_FractUseDelay);
connect(brain.ketoAcids, ketoAcids);
connect(busConnector.Insulin, skeletalMuscle.Insulin) annotation(Text(string = "%first", index = -1, extent = {{-6, 1}, {-6, 1}}));
connect(busConnector.Insulin, respiratoryMuscle.Insulin) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.skeletalMuscle_GlucoseToCellStorageFlow, skeletalMuscle.GlucoseToCellsStorageFlow);
connect(busConnector.respiratoryMuscle_GlucoseToCellStorageFlow, respiratoryMuscle.GlucoseToCellsStorageFlow);
connect(skin.TotalCalsUsed, busConnector.MetabolismCaloriesUsed_SkinHeat);
connect(skeletalMuscle.TotalCalsUsed, Heat.u1);
connect(busConnector.ExerciseMetabolism_MotionCals, Heat.u2);
connect(Heat.y, busConnector.MetabolismCaloriesUsed_SkeletalMuscleHeat);
connect(MetabolicH2ORate.y, busConnector.MetabolicH2O_Rate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(bone.H2OFromMetabolism, MetabolicH2ORate.u[1]);
connect(liver.H2OFromMetabolism, MetabolicH2ORate.u[2]);
connect(kidney.H2OFromMetabolism, MetabolicH2ORate.u[3]);
connect(gITract.H2OFromMetabolism, MetabolicH2ORate.u[4]);
connect(fat.H2OFromMetabolism, MetabolicH2ORate.u[5]);
connect(otherTissue.H2OFromMetabolism, MetabolicH2ORate.u[6]);
connect(MetabolicH2ORate.u[7], skin.H2OFromMetabolism);
connect(MetabolicH2ORate.u[8], skeletalMuscle.H2OFromMetabolism);
connect(MetabolicH2ORate.u[9], leftHeart.H2OFromMetabolism);
connect(MetabolicH2ORate.u[10], rightHeart.H2OFromMetabolism);
connect(MetabolicH2ORate.u[11], respiratoryMuscle.H2OFromMetabolism);
connect(MetabolicH2ORate.u[12], brain.H2OFromMetabolism);
connect(liver.GILumenCarbohydrates, GILumenCarbohydrates);
connect(liver.PortalVeinGlucose, busConnector.PortalVein_Glucose) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(liver.glucose, glucose);
connect(liver.fattyAcids, fattyAcids);
connect(gITract.GIT_GluUse, liver.GITract_GlucoseUsed);
connect(gITract.GIT_FatUse, liver.GITract_FatUsed);
connect(liver.FatAbsorbtion, busConnector.FA_Absorbtion) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CoreHeat.y, busConnector.MetabolismCaloriesUsed_CoreHeat) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(bone.TotalCalsUsed, CoreHeat.u[1]);
connect(liver.TotalCalsUsed, CoreHeat.u[2]);
connect(kidney.TotalCalsUsed, CoreHeat.u[3]);
connect(gITract.TotalCalsUsed, CoreHeat.u[4]);
connect(fat.TotalCalsUsed, CoreHeat.u[5]);
connect(otherTissue.TotalCalsUsed, CoreHeat.u[6]);
connect(CoreHeat.u[7], leftHeart.TotalCalsUsed);
connect(CoreHeat.u[8], rightHeart.TotalCalsUsed);
connect(CoreHeat.u[9], respiratoryMuscle.TotalCalsUsed);
connect(CoreHeat.u[10], brain.TotalCalsUsed);
connect(rightHeart.MotionCals_, MotionCals.u[1]);
connect(leftHeart.MotionCals_, MotionCals.u[2]);
connect(respiratoryMuscle.MotionCals_, MotionCals.u[3]);
connect(MotionCals.y, gain.u);
connect(gain.y, CoreHeat.u[11]);
connect(liver.BloodFlow, busConnector.Liver_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(liver.HepaticArtyBloodFlow, busConnector.HepaticArty_BloodFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(skeletalMuscle.skeletalMuscle_HeatWithoutTermoregulation, busConnector.skeletalMuscle_HeatWithoutTermoregulation);
connect(busConnector.skeletalMuscle_shiveringCals, skeletalMuscle.ShiveringCals) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Metabolism;

model NutrientDelivery
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ solventFlow annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow neededFlow;
Physiolibrary.ConcentrationFlow.SolventFlowPump toCapylaries;
FuelDeficit fuelDeficit;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.Interfaces.RealOutput_ FuelFractUseDelay;
equation
connect(solventFlow, toCapylaries.solventFlow);
connect(q_in, toCapylaries.q_in);
connect(fuelDeficit.neededFlow, neededFlow);
connect(toCapylaries.q_out, flowMeasure.q_in);
connect(flowMeasure.q_out, fuelDeficit.delivered);
connect(flowMeasure.actualFlow, fuelDeficit.maximalDeliveryFlow);
connect(fuelDeficit.FractUseDelay, FuelFractUseDelay);
connect(flowMeasure.q_out, q_out);
end NutrientDelivery;

model FuelDeficit
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow delivered "delivery flow is limited";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow neededFlow "needed solute mass flow have to be achieved";
Physiolibrary.Interfaces.RealInput_ maximalDeliveryFlow "maximal flow limit of delivered connector";
Physiolibrary.Interfaces.RealOutput_ FractUseDelay(start = 1) "less than 1 if neededFlow is grater than delivered flow";
parameter Real Zero = 0.1;
equation
delivered.conc = neededFlow.conc;
if not initial() and (-neededFlow.q) > maximalDeliveryFlow and (-neededFlow.q) > Zero then
delivered.q = maximalDeliveryFlow;
FractUseDelay * (-neededFlow.q) = delivered.q;
else
delivered.q + neededFlow.q = 0;
FractUseDelay = 1;
end if;
end FuelDeficit;

model LeftHeartMuscle
extends HeartMuscle;
Physiolibrary.Interfaces.RealOutput_ MotionCals_(unit = "cal/min");
equation
connect(motionCals.y, MotionCals_);
end LeftHeartMuscle;

model RightHeartMuscle
extends HeartMuscle;
Physiolibrary.Interfaces.RealOutput_ MotionCals_(unit = "cal/min");
equation
connect(motionCals.y, MotionCals_);
end RightHeartMuscle;

model FuelDeficit2
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow delivered "delivery flow is limited";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow neededFlow "needed solute mass flow have to be achieved";
Physiolibrary.Interfaces.RealInput_ maximalDeliveryFlow "maximal flow limit of delivered connector";
Physiolibrary.Interfaces.RealOutput_ FractUseDelay "less than 1 if neededFlow is grater than delivered flow";
parameter Real Zero = 1e-010;
Physiolibrary.Interfaces.RealInput_ concChange "aditional change of delivered concentration";
equation
delivered.conc + concChange = neededFlow.conc;
if (-neededFlow.q) > maximalDeliveryFlow then
delivered.q = maximalDeliveryFlow;
FractUseDelay = delivered.q / (-neededFlow.q);
else
delivered.q + neededFlow.q = 0;
FractUseDelay = 1;
end if;
end FuelDeficit2;

model NutrientDelivery_Fat
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ solventFlow annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow neededFlow;
Physiolibrary.ConcentrationFlow.SolventFlowPump toCapylaries;
FuelDeficit2 fuelDeficit;
Physiolibrary.ConcentrationFlow.FlowMeasure flowMeasure;
Physiolibrary.Interfaces.RealOutput_ FuelFractUseDelay;
Physiolibrary.Interfaces.RealInput_ GITUsed "GITract concumption";
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Math.Division division;
Physiolibrary.Interfaces.RealInput_ FatAbsorbtion "fat from GILumen absorbtion";
equation
connect(solventFlow, toCapylaries.solventFlow);
connect(q_in, toCapylaries.q_in);
connect(fuelDeficit.neededFlow, neededFlow);
connect(toCapylaries.q_out, flowMeasure.q_in);
connect(flowMeasure.q_out, fuelDeficit.delivered);
connect(flowMeasure.actualFlow, fuelDeficit.maximalDeliveryFlow);
connect(fuelDeficit.FractUseDelay, FuelFractUseDelay);
connect(flowMeasure.q_out, q_out);
connect(GITUsed, feedback.u2);
connect(feedback.y, division.u1);
connect(solventFlow, division.u2);
connect(division.y, fuelDeficit.concChange);
connect(FatAbsorbtion, feedback.u1);
end NutrientDelivery_Fat;

model NutrientDelivery_2
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "Base plasma pool of glucose, outflow of glucose to plasma pool from tissue" annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ solventFlow "Portal vein plus hepatic artery plasma flow" annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "Base plasma pool of glucose, delivery of glucose minus absorbtion from GI lumen";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow neededFlow "Glucose flow to metabolism, its concentration in tissue";
Physiolibrary.Interfaces.RealOutput_ FuelFractUseDelay "1 if enough glucose delivery";
Physiolibrary.Interfaces.RealInput_ GITUsed "Negative GITract consumption";
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow fromGILumen "Absorbtion flow of glucose from gastro intestinal lumen and GIT glucose concentration";
Physiolibrary.Interfaces.RealInput_ HepaticArty "Hepatic artery plasma flow";
Real consumption;
Real delivery(start = 300);
equation
if (-neededFlow.q) > delivery then
consumption = delivery;
FuelFractUseDelay = consumption / (-neededFlow.q);
else
consumption + neededFlow.q = 0;
FuelFractUseDelay = 1;
end if;
delivery = q_in.q + fromGILumen.q + GITUsed;
consumption = q_in.q + q_out.q + fromGILumen.q;
neededFlow.conc * solventFlow = -q_out.q;
q_in.q = q_in.conc * solventFlow;
q_in.conc = fromGILumen.conc;
end NutrientDelivery_2;
end TissueMetabolism;
end Metabolism;

package Hormones  "Hormones"

model Insulin
Physiolibrary.ConcentrationFlow.ConcentrationCompartment InsulinPool(stateName = "InsulinPool.Mass", initialSoluteMass = 324) "0.021 mU/ml * 15000 ml  = 307 mU .. all initial extracellular insulin";
Physiolibrary.ConcentrationFlow.SoluteFlowPump secretion;
Physiolibrary.ConcentrationFlow.InputPump synthesis;
Physiolibrary.ConcentrationFlow.OutputPump clearance;
Physiolibrary.ConcentrationFlow.FlowConcentrationMeasure PortalVeinConcentration;
Physiolibrary.ConcentrationFlow.MassStorageCompartment InsulinStorage(stateName = "InsulinStorage.Mass", initialSoluteMass = 1954.91);
Modelica.Blocks.Math.Gain gain(k = 0.0571413755);
Physiolibrary.Factors.CurveValue KAEffect(data = {{0.0, 0.6, 0}, {0.5, 1.0, 0.05}, {50.0, 2.0, 0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.CurveValue MassEffect(data = {{0, 200, 0}, {2000, 17, -0.02}, {3000, 0, 0}});
Physiolibrary.Blocks.Constant hormoneFlowConstant(k = 1);
Physiolibrary.Factors.CurveValueWithLinearSimplificationByHomotopy GlucoseEffect(data = {{0, 0.0, 0}, {105, 1.0, 0.01}, {600, 50.0, 0}}, defaultU = 105, defaultSlope = 0.01, defaultValue = 1, curve(iFrom(start = 2)));
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.Factors.SimpleMultiply BasicFraction;
Physiolibrary.Blocks.Constant Constant(k = 0.008500000000000001);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "uU/l", toAnotherUnitCoef = 1);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ Insulin(quantity = "Concentration", final unit = "uU/ml");
Modelica.Blocks.Math.Gain mU_per_l(k = 10 ^ 3) "from mU/ml to mU/l";
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(unitsString = "uU/ml", toAnotherUnitCoef = 1000);
Physiolibrary.Blocks.Integrator integrator(k = 1 / 20 / Physiolibrary.SecPerMin, stateName = "InsulinSynthesis.Rate", y_start = 18.1363);
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Blocks.Integrator integrator1(k = 1 / 40 / Physiolibrary.SecPerMin, stateName = "LM_Insulin.[InsulinDelayed]", y_start = 57);
Modelica.Blocks.Math.Feedback feedback1;
Physiolibrary.Interfaces.RealOutput_ LM_Insulin_InsulinDelayed(quantity = "Concentration", unit = "uU/ml");
equation
connect(InsulinPool.soluteMass, gain.u);
connect(gain.y, clearance.desiredFlow);
connect(InsulinStorage.soluteMass, MassEffect.u);
connect(hormoneFlowConstant.y, MassEffect.yBase);
connect(secretion.soluteFlow, FunctionEffect.y);
connect(FunctionEffect.yBase, KAEffect.y);
connect(KAEffect.yBase, GlucoseEffect.y);
connect(GlucoseEffect.yBase, BasicFraction.y);
connect(Constant.y, BasicFraction.u);
connect(InsulinStorage.soluteMass, BasicFraction.yBase);
connect(PortalVeinConcentration.AdditionalSoluteFlow, FunctionEffect.y);
connect(busConnector.Glucose, GlucoseEffect.u);
connect(busConnector.GITractFunctionEffect, FunctionEffect.u);
connect(InsulinPool.q_out, PortalVeinConcentration.q_in);
connect(InsulinPool.q_out, secretion.q_out);
connect(secretion.q_in, InsulinStorage.q_out);
connect(InsulinStorage.q_out, synthesis.q_out);
connect(clearance.q_in, InsulinPool.q_out);
connect(concentrationMeasure.q_in, InsulinPool.q_out);
connect(busConnector.PortalVein_PlasmaFlow, PortalVeinConcentration.SolventFlow) annotation(Text(string = "%first", index = -1, extent = {{-3, 3}, {-3, 3}}));
connect(busConnector.ECFV_Vol, InsulinPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(mU_per_l.y, busConnector.PortalVein_Insulin) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PortalVeinConcentration.Conc, mU_per_l.u);
connect(concentrationMeasure1.actualConc, Insulin);
connect(InsulinPool.q_out, concentrationMeasure1.q_in);
connect(concentrationMeasure1.actualConc, busConnector.Insulin) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(MassEffect.y, feedback.u1);
connect(integrator.y, synthesis.desiredFlow);
connect(feedback1.y, integrator1.u);
connect(integrator1.y, feedback1.u2);
connect(mU_per_l.y, feedback1.u1);
connect(busConnector.KAPool_mg_per_dl, KAEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(integrator1.y, LM_Insulin_InsulinDelayed);
end Insulin;

model Glucagon
Modelica.Blocks.Math.Gain gain(k = 0.05);
Physiolibrary.ConcentrationFlow.OutputPump clearance;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment GlucagonPool(stateName = "GlucagonPool.Mass", initialSoluteMass = 990.792) "66.2 pg/ml * 15000 ml * 0.001 ng/pg = 993 ng .. all initial extracellular glucagon";
Physiolibrary.ConcentrationFlow.FlowConcentrationMeasure PortalVeinConcentration;
Physiolibrary.ConcentrationFlow.InputPump synthesis;
Physiolibrary.Blocks.HormoneFlowConstant_nG hormoneFlowConstant_pG(k = 50);
Physiolibrary.Factors.CurveValue InsulinEffect(data = {{0, 6.0, 0}, {7, 1.3, -0.02}, {20, 1.0, -0.006}, {100, 0.6, 0}}, curve(iFrom(start = 3)));
Physiolibrary.Factors.CurveValue GlucoseEffect(data = {{0, 2.5, 0}, {70, 1.1, -0.005}, {110, 1.0, -0.001}, {400, 0.6, 0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Modelica.Blocks.Math.Gain gain1(k = 0.001);
Modelica.Blocks.Math.Gain gain2(k = 0.001);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ Insulin(unit = "uU/ml");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "ng/l");
Physiolibrary.Interfaces.RealOutput_ Glucagon(quantity = "Concentration", final unit = "ng/l");
equation
connect(GlucagonPool.soluteMass, gain.u);
connect(gain.y, clearance.desiredFlow);
connect(clearance.q_in, GlucagonPool.q_out);
connect(GlucagonPool.q_out, PortalVeinConcentration.q_in);
connect(PortalVeinConcentration.Conc, busConnector.PortalVein_Glucagon) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(PortalVeinConcentration.AdditionalSoluteFlow, FunctionEffect.y);
connect(busConnector.GITractFunctionEffect, FunctionEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Glucose, GlucoseEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(InsulinEffect.yBase, GlucoseEffect.y);
connect(InsulinEffect.y, FunctionEffect.yBase);
connect(synthesis.desiredFlow, FunctionEffect.y);
connect(hormoneFlowConstant_pG.y, GlucoseEffect.yBase);
connect(synthesis.q_out, GlucagonPool.q_out);
connect(busConnector.ECFV_Vol, gain1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gain1.y, GlucagonPool.SolventVolume);
connect(gain2.y, PortalVeinConcentration.SolventFlow);
connect(gain2.u, busConnector.PortalVein_PlasmaFlow) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Insulin, InsulinEffect.u);
connect(GlucagonPool.q_out, concentrationMeasure.q_in);
connect(concentrationMeasure.actualConc, Glucagon);
connect(busConnector.Glucagon_conc, concentrationMeasure.actualConc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end Glucagon;

model ADH
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ADHPool(stateName = "ADHPool.Mass", initialSoluteMass = 2.2251 * 0.001 * 14361.0097207699) "2pg/ml * 15000 ml * 0.001 ng/pg = 30 ng .. all initial extracellular insulin";
Physiolibrary.ConcentrationFlow.SoluteFlowPump secretion;
Physiolibrary.ConcentrationFlow.InputPump synthesis;
Physiolibrary.ConcentrationFlow.SolventOutflowPump Liver_clearance(K = 0.0005);
Physiolibrary.Factors.CurveValue NeuralEffect(data = {{0.5, 0.4, 0}, {1.0, 1.0, 0.4}, {1.2, 2.0, 5.0}, {1.5, 20.0, 0}});
Physiolibrary.Blocks.HormoneFlowConstant_nG hormoneFlowConstant(k = 3.2);
Physiolibrary.Factors.CurveValue OsmEffect(data = {{0.243, 0.0, 0}, {0.253, 1.0, 180}, {0.263, 5.0, 0}});
Physiolibrary.Factors.SimpleMultiply BasicFraction;
Physiolibrary.Blocks.Constant BaseK(k = 0.001);
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "ng/l");
Modelica.Blocks.Math.Gain gain2(k = 0.001);
Physiolibrary.ConcentrationFlow.SolventOutflowPump Kidney_clearance(K = 0.00059);
Physiolibrary.ConcentrationFlow.SolventOutflowPump Other_clearance(K = 0.00108);
Physiolibrary.ConcentrationFlow.MassStorageCompartment SlowMass(initialSoluteMass = 15782.3, stateName = "ADHSlowMass.Mass");
Physiolibrary.ConcentrationFlow.MassStorageCompartment FastMass(initialSoluteMass = 2632.19, stateName = "ADHFastMass.Mass");
Physiolibrary.Factors.CurveValue Feedback(data = {{0, 4.0, 0}, {17000, 1.0, -0.0003}, {20000, 0.0, 0}});
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ ADH(quantity = "Concentration", final unit = "nG/l");
Physiolibrary.Blocks.Log10AsEffect log10_1;
Physiolibrary.ConcentrationFlow.SoluteFlowPump fluxDown;
Physiolibrary.ConcentrationFlow.SoluteFlowPump fluxUp;
Modelica.Blocks.Math.Gain gain1(k = 0.0043);
Modelica.Blocks.Math.Gain gain3(k = 0.001);
Physiolibrary.Blocks.Integrator integrator1(k = 1 / 20 / Physiolibrary.SecPerMin, y_start = 2.27115, stateName = "NephronADH.[ADHDelayed]");
Modelica.Blocks.Math.Feedback feedback1;
Physiolibrary.Interfaces.RealOutput_ NephronADH(quantity = "Concentration", unit = "ng/l");
equation
connect(NeuralEffect.yBase, OsmEffect.y);
connect(OsmEffect.yBase, BasicFraction.y);
connect(BaseK.y, BasicFraction.u);
connect(busConnector.Osmreceptors, OsmEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.SympsCNS_PituitaryNA, NeuralEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(ADHPool.q_out, secretion.q_out);
connect(Liver_clearance.q_in, ADHPool.q_out);
connect(concentrationMeasure.q_in, ADHPool.q_out);
connect(concentrationMeasure.actualConc, busConnector.ADH) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(gain2.y, ADHPool.SolventVolume);
connect(busConnector.ECFV_Vol, gain2.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(ADHPool.q_out, Kidney_clearance.q_in);
connect(ADHPool.q_out, Other_clearance.q_in);
connect(NeuralEffect.y, secretion.soluteFlow);
connect(secretion.q_in, FastMass.q_out);
connect(SlowMass.q_out, synthesis.q_out);
connect(FastMass.soluteMass, BasicFraction.yBase);
connect(Feedback.y, synthesis.desiredFlow);
connect(Feedback.yBase, hormoneFlowConstant.y);
connect(SlowMass.soluteMass, Feedback.u);
connect(concentrationMeasure.actualConc, ADH);
connect(concentrationMeasure.actualConc, log10_1.u);
connect(log10_1.y, busConnector.ADHPool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.Kidney_BloodFlow, Kidney_clearance.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OtherTissue_BloodFlow, Other_clearance.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gain1.y, fluxDown.soluteFlow);
connect(FastMass.soluteMass, gain1.u);
connect(gain3.y, fluxUp.soluteFlow);
connect(gain3.u, SlowMass.soluteMass);
connect(fluxDown.q_out, SlowMass.q_out);
connect(fluxUp.q_in, SlowMass.q_out);
connect(FastMass.q_out, fluxDown.q_in);
connect(FastMass.q_out, fluxUp.q_out);
connect(feedback1.y, integrator1.u);
connect(integrator1.y, feedback1.u2);
connect(concentrationMeasure.actualConc, feedback1.u1);
connect(integrator1.y, NephronADH);
connect(integrator1.y, busConnector.NephronADH) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.GITract_BloodFlow, Liver_clearance.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
end ADH;

model Aldosterone
Physiolibrary.ConcentrationFlow.ConcentrationCompartment AldoPool(initialSoluteMass = 13477.9, stateName = "AldoPool.Mass") " 0.33 pmol/ml * 43000 ml = 14190.0 ng .. all initial extracellular insulin";
Physiolibrary.ConcentrationFlow.InputPump adrenalCortex;
Physiolibrary.ConcentrationFlow.SolventOutflowPump Clearance(K = 0.78);
Physiolibrary.Factors.CurveValue KEffect(data = {{3.0, 0.3, 0}, {4.4, 1.0, 1.0}, {6.0, 3.0, 0}});
Physiolibrary.Blocks.HormoneFlowConstant_pmol hormoneFlowConstant(k = 330.0);
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.0, 0.4, 0}, {1.3, 1.0, 1.0}, {4.0, 4.0, 0}});
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "pmol/l", toAnotherUnitCoef = 1000);
Physiolibrary.ConcentrationFlow.OutputPump Degradation;
Modelica.Blocks.Math.Gain DegradeK(k = 0.0007);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ A2Pool_Log10Conc;
Physiolibrary.Interfaces.RealOutput_ Aldo(quantity = "Concentration", final unit = "pmol/l");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure TO_ng_per_dl(unitsString = "ng/dl", toAnotherUnitCoef = 36) "conversion from \"pmol/ml\" to \"ng/dl\"";
Physiolibrary.Blocks.Integrator AldoDelayed(k = 1 / (3 * 60) / Physiolibrary.SecPerMin, stateName = "NephronAldo.[AldoDelayed]", y_start = 11);
Modelica.Blocks.Math.Feedback feedback1;
Physiolibrary.Interfaces.RealOutput_ NephronAldo(quantity = "Concentration", final unit = "ngl/dl");
equation
connect(KEffect.yBase, A2Effect.y);
connect(A2Effect.yBase, FunctionEffect.y);
connect(AldoPool.q_out, adrenalCortex.q_out);
connect(Clearance.q_in, AldoPool.q_out);
connect(concentrationMeasure.q_in, AldoPool.q_out);
connect(concentrationMeasure.actualConc, busConnector.Aldo) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AldoPool.q_out, Degradation.q_in);
connect(busConnector.BodyH2O_Vol, AldoPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Liver_BloodFlow, Clearance.solventFlow) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AldoPool.soluteMass, DegradeK.u);
connect(FunctionEffect.u, busConnector.OtherTissueFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(adrenalCortex.desiredFlow, KEffect.y);
connect(FunctionEffect.yBase, hormoneFlowConstant.y);
connect(Degradation.desiredFlow, DegradeK.y);
connect(A2Pool_Log10Conc, A2Effect.u);
connect(concentrationMeasure.actualConc, Aldo);
connect(busConnector.AldoPool_Aldo, concentrationMeasure.actualConc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(TO_ng_per_dl.q_in, AldoPool.q_out);
connect(busConnector.Aldo_conc_in_nG_per_dl, TO_ng_per_dl.actualConc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(feedback1.y, AldoDelayed.u);
connect(AldoDelayed.y, feedback1.u2);
connect(AldoDelayed.y, NephronAldo);
connect(TO_ng_per_dl.actualConc, feedback1.u1);
connect(busConnector.NephronAldo_conc_in_nG_per_dl, AldoDelayed.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(KEffect.u, busConnector.KPool_conc_per_liter) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Aldosterone;

model ANP
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ANPPool(initialSoluteMass = 285.895, stateName = "ANPPool.Mass") "default = 20 pmol/l";
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Factors.CurveValue LAPEffect(data = {{0.0, 0.0, 0}, {8.0, 1.0, 0.4}, {20.0, 10.0, 0}});
Physiolibrary.Blocks.HormoneFlowConstant_pmol hormoneFlowConstant(k = 41);
Physiolibrary.Factors.CurveValue RAPEffect(data = {{0.0, 0.0, 0}, {4.0, 1.0, 0.4}, {20.0, 10.0, 0}});
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "pmol/l", toAnotherUnitCoef = 1000);
Physiolibrary.ConcentrationFlow.OutputPump Degradation;
Modelica.Blocks.Math.Gain DegradeK(k = 0.223);
Physiolibrary.Blocks.HormoneFlowConstant_pmol hormoneFlowConstant1(k = 26);
Modelica.Blocks.Math.Add SteadyState;
Physiolibrary.Blocks.Integrator integrator(k = 1 / 20 / Physiolibrary.SecPerMin, y_start = 67, stateName = "ANPSecretion.NaturalRate");
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ ANP(quantity = "Concentration", final unit = "pmol/l");
Physiolibrary.Blocks.Log10AsEffect log10_1;
Physiolibrary.Blocks.Log10AsEffect log10_2;
Physiolibrary.Blocks.Integrator integrator1(k = 1 / 20 / Physiolibrary.SecPerMin, y_start = 20, stateName = "NephronANP.[ANPDelayed]");
Modelica.Blocks.Math.Feedback feedback1;
Physiolibrary.Interfaces.RealOutput_ NephronANP_Log10Conc;
equation
connect(ANPPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, ANPPool.q_out);
connect(ANPPool.q_out, Degradation.q_in);
connect(ANPPool.soluteMass, DegradeK.u);
connect(Degradation.desiredFlow, DegradeK.y);
connect(hormoneFlowConstant1.y, LAPEffect.yBase);
connect(hormoneFlowConstant.y, RAPEffect.yBase);
connect(RAPEffect.y, SteadyState.u2);
connect(LAPEffect.y, SteadyState.u1);
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(SteadyState.y, feedback.u1);
connect(integrator.y, secretion.desiredFlow);
connect(concentrationMeasure.actualConc, ANP);
connect(concentrationMeasure.actualConc, log10_1.u);
connect(busConnector.NephronANP_Log10Conc, log10_2.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ANPPool_Log10Conc, log10_1.y) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ANP, concentrationMeasure.actualConc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.rightAtrium_TMP, RAPEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.leftAtrium_TMP, LAPEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ECFV_Vol, ANPPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(feedback1.y, integrator1.u);
connect(integrator1.y, feedback1.u2);
connect(integrator1.y, log10_2.u);
connect(concentrationMeasure.actualConc, feedback1.u1);
connect(log10_2.y, NephronANP_Log10Conc);
end ANP;

package Catechols  "Epinephrine and Norepinephrine"
model Epinephrine
Physiolibrary.ConcentrationFlow.ConcentrationCompartment EpiPool(initialSoluteMass = 571.7910000000001, stateName = "EpiPool.Mass") "0.040 ng/ml * 15000 ml =  600 ng ";
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Blocks.HormoneFlowConstant_nG hormoneFlowConstant(k = 375);
Physiolibrary.Factors.CurveValue AdrenalNerveEffect(data = {{2.0, 1.0, 0}, {8.0, 20.0, 0}});
Physiolibrary.Interfaces.RealInput OtherTissueFunctionEffect;
Physiolibrary.Interfaces.RealInput ECFV_Vol(final quantity = "Volume", final unit = "ml");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "pg/ml", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.RealOutput Epinephrine(final quantity = "Concentration", final unit = "pg/ml");
Physiolibrary.Interfaces.RealInput AdrenalNerve_NA(final quantity = "Frequency", final unit = "Hz");
Physiolibrary.ConcentrationFlow.SolventOutflowPump Clearance(K = 1);
Physiolibrary.Blocks.FlowConstant flowConstant(k = 9400);
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
equation
connect(EpiPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, EpiPool.q_out);
connect(concentrationMeasure.actualConc, Epinephrine);
connect(ECFV_Vol, EpiPool.SolventVolume);
connect(AdrenalNerve_NA, AdrenalNerveEffect.u);
connect(hormoneFlowConstant.y, AdrenalNerveEffect.yBase);
connect(EpiPool.q_out, Clearance.q_in);
connect(flowConstant.y, Clearance.solventFlow);
connect(OtherTissueFunctionEffect, FunctionEffect.u);
connect(AdrenalNerveEffect.y, FunctionEffect.yBase);
connect(FunctionEffect.y, secretion.desiredFlow);
end Epinephrine;

model Norepinephrine
Physiolibrary.ConcentrationFlow.ConcentrationCompartment NEPool(initialSoluteMass = 3430.74, stateName = "NEPool.Mass") "0.240 ng/ml * 15000 ml =  3600 ng ";
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Blocks.HormoneFlowConstant_nG hormoneFlowConstant(k = 220);
Physiolibrary.Factors.CurveValue AdrenalNerveEffect(data = {{2.0, 1.0, 0}, {8.0, 20.0, 0}});
Physiolibrary.Interfaces.RealInput OtherTissueFunctionEffect;
Physiolibrary.Interfaces.RealInput ECFV_Vol(final quantity = "Volume", final unit = "ml");
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "pg/ml", toAnotherUnitCoef = 1000);
Physiolibrary.Interfaces.RealOutput Norepinephrine(final quantity = "Concentration", final unit = "pg/ml");
Physiolibrary.Interfaces.RealInput AdrenalNerve_NA(final quantity = "Frequency", final unit = "Hz");
Physiolibrary.ConcentrationFlow.SolventOutflowPump Clearance(K = 1);
Physiolibrary.Blocks.FlowConstant flowConstant(k = 4500);
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.ConcentrationFlow.InputPump Spillover;
Physiolibrary.Blocks.Constant hormoneFlowConstant1(k = 570.0);
Physiolibrary.Factors.SimpleMultiply SpilloverK;
Physiolibrary.Interfaces.RealInput GangliaGeneral_NA(final quantity = "Frequency", final unit = "Hz");
equation
connect(NEPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, NEPool.q_out);
connect(concentrationMeasure.actualConc, Norepinephrine);
connect(ECFV_Vol, NEPool.SolventVolume);
connect(AdrenalNerve_NA, AdrenalNerveEffect.u);
connect(hormoneFlowConstant.y, AdrenalNerveEffect.yBase);
connect(NEPool.q_out, Clearance.q_in);
connect(flowConstant.y, Clearance.solventFlow);
connect(OtherTissueFunctionEffect, FunctionEffect.u);
connect(AdrenalNerveEffect.y, FunctionEffect.yBase);
connect(FunctionEffect.y, secretion.desiredFlow);
connect(NEPool.q_out, Spillover.q_out);
connect(GangliaGeneral_NA, SpilloverK.u);
connect(hormoneFlowConstant1.y, SpilloverK.yBase);
connect(SpilloverK.y, Spillover.desiredFlow);
end Norepinephrine;

model Catechols
Physiolibrary.Interfaces.BusConnector busConnector;
Epinephrine epinephrine;
Norepinephrine norepinephrine;
Physiolibrary.Interfaces.RealOutput_ EpinephrineConc(quantity = "Concentration", final unit = "pg/ml");
Physiolibrary.Interfaces.RealOutput_ NorepinephrineConc(quantity = "Concentration", final unit = "pg/ml");
Physiolibrary.Blocks.Log10AsEffect log10_1;
Modelica.Blocks.Math.Add3 AlphaTotal(k1 = 0.021, k2 = 0.125, k3 = 5);
Physiolibrary.Blocks.Constant Desglymidodrine(k = 0);
Modelica.Blocks.Math.Add BetaTotal(k1 = 0.021, k2 = 0.125);
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.Blocks.Log10AsEffect log10_2;
equation
connect(busConnector.ECFV_Vol, epinephrine.ECFV_Vol) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.ECFV_Vol, norepinephrine.ECFV_Vol) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AdrenalNerve_NA, epinephrine.AdrenalNerve_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OtherTissueFunctionEffect, epinephrine.OtherTissueFunctionEffect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.OtherTissueFunctionEffect, norepinephrine.OtherTissueFunctionEffect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.AdrenalNerve_NA, norepinephrine.AdrenalNerve_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaGeneral_NA, norepinephrine.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(epinephrine.Epinephrine, busConnector.EpiPool_Epi) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(norepinephrine.Norepinephrine, busConnector.NEPool_NE) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(norepinephrine.Norepinephrine, NorepinephrineConc);
connect(epinephrine.Epinephrine, EpinephrineConc);
connect(log10_1.y, busConnector.AlphaPool_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AlphaTotal.y, log10_1.u);
connect(AlphaTotal.u1, norepinephrine.Norepinephrine);
connect(epinephrine.Epinephrine, AlphaTotal.u2);
connect(Desglymidodrine.y, AlphaTotal.u3);
connect(BetaTotal.u1, norepinephrine.Norepinephrine);
connect(BetaTotal.u2, epinephrine.Epinephrine);
connect(BetaTotal.y, log10_2.u);
connect(log10_2.y, busConnector.BetaPool_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Constant.y, busConnector.AlphaBlocade_Effect);
connect(Constant1.y, busConnector.BetaBlocade_Effect);
end Catechols;
end Catechols;

model EPO
Physiolibrary.ConcentrationFlow.ConcentrationCompartment EPOPool(stateName = "EPOPool.Mass", initialSoluteMass = 0.02 * 14361.0097207699 * 0.4) "default = 6.7 U/L = 0.0067 U/ml ; may be it is better to set 0.020, then is red cells count more in steady state";
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Factors.SimpleMultiply CountEffect;
Physiolibrary.Blocks.Constant hormoneFlowConstant(k = 1);
Physiolibrary.Factors.CurveValue PO2Effect(data = {{0.0, 4.0, 0}, {35.0, 0.0, -0.14}, {60.0, -1.0, 0}});
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "U/l", toAnotherUnitCoef = 1000);
Physiolibrary.ConcentrationFlow.OutputPump Clearance;
Modelica.Blocks.Math.Gain K(k = 0.00555);
Physiolibrary.Blocks.HormoneFlowConstant_U hormoneFlowConstant1(k = 0.67);
Modelica.Blocks.Math.Gain VODIST(k = 0.4);
Physiolibrary.Blocks.Pow avg1;
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.Factors.SimpleMultiply PO2Effect_;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ Erythropoetin(quantity = "Concentration", final unit = "mU/ml");
Physiolibrary.Blocks.Log10AsEffect log10_1;
equation
connect(EPOPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, EPOPool.q_out);
connect(concentrationMeasure.actualConc, busConnector.EPO) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(EPOPool.q_out, Clearance.q_in);
connect(EPOPool.soluteMass, K.u);
connect(Clearance.desiredFlow, K.y);
connect(busConnector.KidneyO2_TubulePO2, PO2Effect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.Kidney_NephronCount_Total_xNormal, CountEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(hormoneFlowConstant1.y, CountEffect.yBase);
connect(hormoneFlowConstant.y, PO2Effect.yBase);
connect(busConnector.ECFV_Vol, VODIST.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(avg1.u, PO2Effect.y);
connect(CountEffect.y, FunctionEffect.yBase);
connect(FunctionEffect.y, PO2Effect_.yBase);
connect(PO2Effect_.y, secretion.desiredFlow);
connect(avg1.y, PO2Effect_.u);
connect(FunctionEffect.u, busConnector.KidneyFunctionEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(concentrationMeasure.actualConc, Erythropoetin);
connect(concentrationMeasure.actualConc, log10_1.u);
connect(log10_1.y, busConnector.EPOPool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(VODIST.y, EPOPool.SolventVolume);
end EPO;

model Thyroxine
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ThyroidPool(stateName = "ThyroidPool.Mass", initialSoluteMass = 1168.05) "default = 8 uG/dl";
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Blocks.HormoneFlowConstant_uG hormoneFlowConstant(k = 0.05);
Physiolibrary.Factors.CurveValue TSHEffect(data = {{0.0, 0.0, 0}, {4.0, 1.0, 0.4}, {30.0, 10.0, 0}});
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "ug/dl", toAnotherUnitCoef = 100);
Physiolibrary.ConcentrationFlow.OutputPump Clearance;
Modelica.Blocks.Math.Gain K(k = 4.1e-005);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ TSH(quantity = "Concentration", final unit = "uU/ml") "thyrotropin";
Physiolibrary.Interfaces.RealOutput_ Thyroxine(quantity = "Concentration", final unit = "ug/ml");
Physiolibrary.Curves.Curve curve(x = {0, 8, 40}, y = {0.7, 1.0, 1.5}, slope = {0, 0.4, 0});
equation
connect(ThyroidPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, ThyroidPool.q_out);
connect(concentrationMeasure.actualConc, busConnector.ThyroidPool_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ThyroidPool.q_out, Clearance.q_in);
connect(ThyroidPool.soluteMass, K.u);
connect(Clearance.desiredFlow, K.y);
connect(hormoneFlowConstant.y, TSHEffect.yBase);
connect(secretion.desiredFlow, TSHEffect.y);
connect(TSH, TSHEffect.u);
connect(busConnector.ECFV_Vol, ThyroidPool.SolventVolume) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(concentrationMeasure.actualConc, Thyroxine);
connect(curve.val, busConnector.ThyroidEffect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(concentrationMeasure.actualConc, curve.u);
end Thyroxine;

model Thyrotropin
Physiolibrary.Blocks.ConcentrationConstant_uU_per_ml hormoneFlowConstant(k = 4);
Physiolibrary.Factors.CurveValue ThyroxineEffect(data = {{0.0, 8.0, 0}, {8.0, 1.0, -0.2}, {20.0, 0.0, 0}}, curve(iFrom(start = 2)));
Physiolibrary.Factors.SimpleMultiply HypothalamusTSH;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ TSH(quantity = "Concentration", final unit = "uU/ml") "thyrotropin";
Physiolibrary.Interfaces.RealInput_ Thyroxine(quantity = "Concentration", final unit = "ug/ml");
Physiolibrary.Factors.CurveValue TemperatureEffect_(data = {{-2.0, 4.0, 0}, {0.0, 1.0, -1.0}, {2.0, 0.2, 0}});
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Blocks.TemperatureConstant temperatureConstant(k = 37);
equation
connect(hormoneFlowConstant.y, ThyroxineEffect.yBase);
connect(ThyroxineEffect.y, HypothalamusTSH.yBase);
connect(HypothalamusTSH.y, TSH);
connect(Thyroxine, ThyroxineEffect.u);
connect(busConnector.brain_FunctionEffect, TemperatureEffect_.yBase) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(TemperatureEffect_.u, feedback.y);
connect(feedback.u1, busConnector.HeatCore_Temp) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(feedback.u2, temperatureConstant.y);
connect(TemperatureEffect_.y, HypothalamusTSH.u);
end Thyrotropin;

model Renin
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ReninPool(initialSoluteMass = 17153.7, stateName = "ReninPool.Mass") " 2 GU/ml * 0.6 * 15000 ml =  18000 GU ";
Physiolibrary.ConcentrationFlow.SoluteFlowPump secretion;
Physiolibrary.Factors.SimpleMultiply CountEffect;
Physiolibrary.Blocks.Constant hormoneFlowConstant(k = 0.0033);
Physiolibrary.Factors.CurveValue TGFEffect(data = {{0.0, 8.0, 0}, {0.5, 2.0, -4.0}, {1.0, 1.0, -1.0}, {3.0, 0.5, 0}});
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "GU/ml");
Physiolibrary.ConcentrationFlow.OutputPump Clearance;
Modelica.Blocks.Math.Gain K(k = 0.0161);
Physiolibrary.Blocks.HormoneFlowConstant_GU hormoneFlowConstant1(k = 290);
Modelica.Blocks.Math.Gain VODIST(k = 0.6);
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Physiolibrary.Factors.SimpleMultiply BaseFraction;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ReninFree(initialSoluteMass = 87000, stateName = "ReninFree.Mass");
Physiolibrary.ConcentrationFlow.ConcentrationCompartment ReninGranules(initialSoluteMass = 870000.0, stateName = "ReninGranules.Mass");
Physiolibrary.ConcentrationFlow.InputPump synthesis;
Physiolibrary.Blocks.Constant Constant(k = 1) "only a normalized volume to normal value of ReginFree solute volume";
Physiolibrary.Blocks.Constant Constant1(k = 10) "only a normalized volume to normal value of ReginFree solute volume";
Physiolibrary.Factors.CurveValue TGFEffect1(data = {{0.0, 10.0, 0}, {0.6, 2.0, -4.0}, {1.0, 1.0, -1.0}, {2.0, 0.3, 0}});
Physiolibrary.Blocks.Integrator integrator(k = 1 / 60 / Physiolibrary.SecPerMin, y_start = 290, stateName = "ReninSynthesis.Rate");
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealOutput_ ReninPool_PRA(quantity = "Concentration", final unit = "GU/ml") "ReninPool.[PRA]";
Nerves.BetaReceptorsActivityFactor betaReceptorsActivityFactor;
Physiolibrary.Factors.CurveValue NaEffect(data = {{0, 0.0, 0.0}, {48, 1.0, 0.03}, {100, 2.0, 0.0}});
Physiolibrary.Factors.CurveValue ANPEffect(data = {{0.0, 1.2, 0.0}, {1.3, 1.0, -0.3}, {2.7, 0.8, 0.0}});
Physiolibrary.Factors.CurveValue A2Effect(data = {{0.0, 0.9, 0.0}, {1.3, 1.0, 0.1}, {2.5, 2.0, 2.0}, {3.5, 5.0, 0.0}});
Physiolibrary.Factors.CurveValue FurosemideEffect(data = {{0.0, 1.0, 0.0}, {1.3, 0.2, 0.0}});
Physiolibrary.Blocks.Constant Constant2(k = 1);
Physiolibrary.Factors.CurveValue SympsEffect(data = {{0.0, 0.5, 0}, {1.0, 1.0, 1.0}, {3.0, 4.0, 0}});
Physiolibrary.Blocks.Constant Constant3(k = 1);
Physiolibrary.Factors.CurveValue SympsEffect1(data = {{0.0, 0.5, 0}, {1.0, 1.0, 1.0}, {2.5, 4.0, 0}});
Physiolibrary.ConcentrationFlow.SoluteFlowPump fluxReninFree;
Physiolibrary.ConcentrationFlow.SoluteFlowPump fluxReninGranules;
Modelica.Blocks.Math.Gain gain1(k = 0.01);
Modelica.Blocks.Math.Gain gain3(k = 0.001);
equation
connect(ReninPool.q_out, secretion.q_out);
connect(concentrationMeasure.q_in, ReninPool.q_out);
connect(concentrationMeasure.actualConc, busConnector.Renin) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ReninPool.q_out, Clearance.q_in);
connect(ReninPool.soluteMass, K.u);
connect(Clearance.desiredFlow, K.y);
connect(busConnector.Kidney_NephronCount_Total_xNormal, CountEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(hormoneFlowConstant1.y, CountEffect.yBase);
connect(busConnector.ECFV_Vol, VODIST.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(VODIST.y, ReninPool.SolventVolume);
connect(CountEffect.y, FunctionEffect.yBase);
connect(BaseFraction.y, TGFEffect.yBase);
connect(hormoneFlowConstant.y, BaseFraction.u);
connect(ReninFree.soluteMass, BaseFraction.yBase);
connect(Constant.y, ReninFree.SolventVolume);
connect(Constant1.y, ReninGranules.SolventVolume);
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(integrator.y, synthesis.desiredFlow);
connect(secretion.q_in, ReninFree.q_out);
connect(ReninFree.q_out, synthesis.q_out);
connect(concentrationMeasure.actualConc, ReninPool_PRA);
connect(busConnector.BetaPool_Effect, betaReceptorsActivityFactor.BetaPool_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.BetaBlocade_Effect, betaReceptorsActivityFactor.BetaBlockade_Effect) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.GangliaKidney_NA, betaReceptorsActivityFactor.GangliaGeneral_NA) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(Constant2.y, NaEffect.yBase);
connect(NaEffect.y, ANPEffect.yBase);
connect(ANPEffect.y, A2Effect.yBase);
connect(A2Effect.y, FurosemideEffect.yBase);
connect(busConnector.KidneyFunctionEffect, FunctionEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(TGFEffect1.y, feedback.u1);
connect(FurosemideEffect.y, TGFEffect1.u);
connect(ANPEffect.u, busConnector.ANPPool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(A2Effect.u, busConnector.A2Pool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(FurosemideEffect.u, busConnector.FurosemidePool_Loss) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(TGFEffect.u, FurosemideEffect.y);
connect(TGFEffect.y, SympsEffect.yBase);
connect(SympsEffect.y, secretion.soluteFlow);
connect(betaReceptorsActivityFactor.y, SympsEffect.u);
connect(Constant3.y, betaReceptorsActivityFactor.yBase);
connect(SympsEffect1.y, TGFEffect1.yBase);
connect(FunctionEffect.y, SympsEffect1.yBase);
connect(betaReceptorsActivityFactor.y, SympsEffect1.u);
connect(NaEffect.u, busConnector.MD_Na) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(gain1.y, fluxReninFree.soluteFlow);
connect(gain3.y, fluxReninGranules.soluteFlow);
connect(fluxReninFree.q_out, ReninGranules.q_out);
connect(fluxReninGranules.q_in, ReninGranules.q_out);
connect(ReninFree.q_out, fluxReninFree.q_in);
connect(ReninFree.q_out, fluxReninGranules.q_out);
connect(ReninGranules.soluteMass, gain3.u);
connect(ReninFree.soluteMass, gain1.u);
end Renin;

model Angiotensine2
Physiolibrary.Blocks.Constant CEBase(k = 30.0);
Physiolibrary.Factors.SimpleMultiply A2_pG_per_mL;
Physiolibrary.Factors.SimpleMultiply EndogenousRate;
Physiolibrary.Blocks.ConcentrationConstant_pg_per_ml concentrationConstant_pg_per_ml(k = 0.3333);
Physiolibrary.Factors.SimpleMultiply PG_TO_PMOL;
Physiolibrary.Blocks.Constant CEBase1(k = 0.956) "conversion AII from pg to pmol coeficient";
Physiolibrary.Blocks.Log10AsEffect log10_1;
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.Interfaces.RealInput_ ReninPool_PRA(unit = "GU/ml");
Physiolibrary.Interfaces.RealOutput_ A2Pool_Log10Conc(quantity = "ConcentrationEffect", final unit = "log10(pg/ml)");
Physiolibrary.Interfaces.RealOutput_ Angiotensine2(final unit = "pg/ml", quantity = "Concentration");
equation
connect(concentrationConstant_pg_per_ml.y, A2_pG_per_mL.yBase);
connect(CEBase1.y, PG_TO_PMOL.u);
connect(log10_1.y, busConnector.A2Pool_Log10Conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ReninPool_PRA, EndogenousRate.u);
connect(log10_1.y, A2Pool_Log10Conc);
connect(PG_TO_PMOL.y, Angiotensine2);
connect(log10_1.y, busConnector.A2Pool_Log10Con) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CEBase.y, EndogenousRate.yBase);
connect(EndogenousRate.y, A2_pG_per_mL.u);
connect(A2_pG_per_mL.y, log10_1.u);
connect(A2_pG_per_mL.y, PG_TO_PMOL.yBase);
end Angiotensine2;

model Hormones
Aldosterone aldosterone;
Angiotensine2 angiotensine2;
Renin renin;
Physiolibrary.Interfaces.BusConnector busConnector;
Catechols.Catechols catechols;
EPO erythropoietin;
equation
connect(busConnector, aldosterone.busConnector);
connect(busConnector, angiotensine2.busConnector);
connect(busConnector, renin.busConnector);
connect(renin.ReninPool_PRA, angiotensine2.ReninPool_PRA);
connect(angiotensine2.A2Pool_Log10Conc, aldosterone.A2Pool_Log10Conc);
connect(busConnector, catechols.busConnector);
connect(busConnector, erythropoietin.busConnector);
end Hormones;

model Leptin
Modelica.Blocks.Math.Gain gain(k = 0.0119);
Physiolibrary.ConcentrationFlow.OutputPump clearance;
Physiolibrary.ConcentrationFlow.ConcentrationCompartment LeptinPool(stateName = "LeptinPool.Mass", initialSoluteMass = 106.978);
Physiolibrary.ConcentrationFlow.InputPump secretion;
Physiolibrary.Blocks.HormoneFlowConstant_nG hormoneFlowConstant_pG(k = 1.2);
Physiolibrary.Factors.CurveValue AdiposeEffect(data = {{0, 0.0, 0}, {3600, 1.0, 8.000000000000001e-005}, {100000, 6.0, 0}});
Physiolibrary.Factors.SimpleMultiply FunctionEffect;
Modelica.Blocks.Math.Gain gain1(k = 0.001);
Physiolibrary.Interfaces.BusConnector busConnector;
Physiolibrary.ConcentrationFlow.ConcentrationMeasure concentrationMeasure(unitsString = "ng/ml");
Physiolibrary.Interfaces.RealOutput_ Leptin(quantity = "Concentration", final unit = "ng/ml");
Modelica.Blocks.Sources.Constant const(k = 7.44919);
equation
connect(LeptinPool.soluteMass, gain.u);
connect(gain.y, clearance.desiredFlow);
connect(clearance.q_in, LeptinPool.q_out);
connect(busConnector.FatFunctionEffect, FunctionEffect.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AdiposeEffect.y, FunctionEffect.yBase);
connect(secretion.desiredFlow, FunctionEffect.y);
connect(secretion.q_out, LeptinPool.q_out);
connect(busConnector.ECFV_Vol, gain1.u) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gain1.y, LeptinPool.SolventVolume);
connect(LeptinPool.q_out, concentrationMeasure.q_in);
connect(hormoneFlowConstant_pG.y, AdiposeEffect.yBase);
connect(AdiposeEffect.u, busConnector.LipidDeposits_Mass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(concentrationMeasure.actualConc, Leptin);
connect(concentrationMeasure.actualConc, busConnector.Leptin) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Leptin;
end Hormones;

package Nerves  "Autonimic Nerves"

model BaroReceptorInHoursAdaptation
Physiolibrary.Interfaces.RealInput_ pressure;
Physiolibrary.Blocks.Integrator adaptivePressure(y_start = AdaptivePressure, k = 1 / (Tau * 60 * Physiolibrary.SecPerMin), stateName = "Baroreflex.AdaptedPressure");
Modelica.Blocks.Math.Feedback pressureChange;
Physiolibrary.Curves.Curve pressureChangeOnNA(x = PressureChangeOnNA[:, 1], y = PressureChangeOnNA[:, 2], slope = PressureChangeOnNA[:, 3]);
Physiolibrary.Interfaces.RealOutput_ NA;
parameter Real AdaptivePressure(final unit = "mmHg");
parameter Real Tau(final unit = "h");
parameter Real[3, :] PressureChangeOnNA;
equation
connect(pressureChange.u2, adaptivePressure.y);
connect(pressureChange.y, adaptivePressure.u);
connect(pressureChangeOnNA.val, NA);
connect(pressureChange.y, pressureChangeOnNA.u);
connect(pressure, pressureChange.u1);
end BaroReceptorInHoursAdaptation;

model BaroReceptorInDaysAdaptation
Physiolibrary.Interfaces.RealInput_ pressure;
Physiolibrary.Blocks.Integrator adaptivePressure(y_start = AdaptivePressure, k = 1 / (Tau * 1440 * Physiolibrary.SecPerMin), stateName = "LowPressureReceptors.AdaptedPressure");
Modelica.Blocks.Math.Feedback pressureChange;
Physiolibrary.Curves.Curve pressureChangeOnNA(x = PressureChangeOnNA[:, 1], y = PressureChangeOnNA[:, 2], slope = PressureChangeOnNA[:, 3]);
Physiolibrary.Interfaces.RealOutput_ NA;
parameter Real AdaptivePressure(final unit = "mmHg");
parameter Real Tau(final unit = "d");
parameter Real[3, :] PressureChangeOnNA;
equation
connect(pressureChange.u2, adaptivePressure.y);
connect(pressureChange.y, adaptivePressure.u);
connect(pressureChangeOnNA.val, NA);
connect(pressureChange.y, pressureChangeOnNA.u);
connect(pressure, pressureChange.u1);
end BaroReceptorInDaysAdaptation;

model SympatheticCNS
parameter Real[:, 3] BaroEffect = {{0.0, 1.5, 0}, {1.0, 1.0, -0.5}, {2.0, 0.5, 0}};
parameter Real[:, 3] LowPressureEffect = {{0.0, 1.1, 0}, {1.0, 1.0, -0.1}, {4.0, 0.9, 0}};
parameter Real[:, 3] FuelEffect = {{0.3, 0.0, 0}, {0.6, 3.0, 0}, {0.8, 0.0, 0}};
parameter Real[:, 3] A2ConcEffect = {{1.7, 1.0, 0}, {2.3, 1.4, 0}};
Physiolibrary.Interfaces.RealInput_ CarotidSinusReceptors;
Physiolibrary.Interfaces.RealInput_ LowPressureReceptors;
Physiolibrary.Curves.Curve baroEffect(x = BaroEffect[:, 1], y = BaroEffect[:, 2], slope = BaroEffect[:, 3]);
Physiolibrary.Curves.Curve lowPressureEffect(x = LowPressureEffect[:, 1], y = LowPressureEffect[:, 2], slope = LowPressureEffect[:, 3]);
Physiolibrary.Interfaces.RealInput_ brain_Fuel_FractUseDelay;
Physiolibrary.Curves.Curve fuelEffect(x = FuelEffect[:, 1], y = FuelEffect[:, 2], slope = FuelEffect[:, 3]);
Physiolibrary.Interfaces.RealInput_ A2Pool_Log10Conc;
Physiolibrary.Curves.Curve A2Effect(x = A2ConcEffect[:, 1], y = A2ConcEffect[:, 2], slope = A2ConcEffect[:, 3]);
Modelica.Blocks.Math.Product reflexNA;
Modelica.Blocks.Math.Product neuralActivity;
Modelica.Blocks.Math.Sum stimulus(nin = 3);
Physiolibrary.Interfaces.RealOutput_ NA(unit = "Hz");
Physiolibrary.Interfaces.RealInput_ ExerciseSymps_TotalEffect;
Modelica.Blocks.Math.Gain gain(k = 1.5);
Physiolibrary.Interfaces.RealOutput_ SympsCNS_A2Effect;
Physiolibrary.Interfaces.RealOutput_ SympsCNS_BaroEffect;
equation
connect(CarotidSinusReceptors, baroEffect.u);
connect(LowPressureReceptors, lowPressureEffect.u);
connect(brain_Fuel_FractUseDelay, fuelEffect.u);
connect(A2Pool_Log10Conc, A2Effect.u);
connect(baroEffect.val, reflexNA.u1);
connect(lowPressureEffect.val, reflexNA.u2);
connect(A2Effect.val, neuralActivity.u2);
connect(fuelEffect.val, stimulus.u[1]);
connect(stimulus.y, neuralActivity.u1);
connect(reflexNA.y, stimulus.u[2]);
connect(ExerciseSymps_TotalEffect, stimulus.u[3]);
connect(neuralActivity.y, gain.u);
connect(gain.y, NA);
connect(baroEffect.val, SympsCNS_BaroEffect);
connect(A2Effect.val, SympsCNS_A2Effect);
end SympatheticCNS;

model ExerciseSympathetic
parameter Real[:, 3] MotorRadiation_TotalEffect = {{0, 0.0, 0.004}, {500, 2.2, 0.002}, {1000, 2.6, 0}};
parameter Real[:, 3] PhOnNerveActivity = {{6.5, 5.0, 0}, {6.9, 0.0, 0}};
Physiolibrary.Curves.Curve SkeletalMuscle_Metaboreflex_NerveActivity(x = PhOnNerveActivity[:, 1], y = PhOnNerveActivity[:, 2], slope = PhOnNerveActivity[:, 3]);
Physiolibrary.Interfaces.RealInput_ SkeletalMuscle_Ph;
Physiolibrary.Curves.Curve motorRadiation_TotalEffect(x = MotorRadiation_TotalEffect[:, 1], y = MotorRadiation_TotalEffect[:, 2], slope = MotorRadiation_TotalEffect[:, 3]);
Modelica.Blocks.Math.Sum totalEffect(nin = 2);
Modelica.Blocks.Math.Gain gain(k = 0.32);
Physiolibrary.Interfaces.RealOutput_ ExerciseSymps_TotalEffect;
Physiolibrary.Interfaces.RealInput_ ExerciseMetabolism_TotalWats;
equation
connect(SkeletalMuscle_Ph, SkeletalMuscle_Metaboreflex_NerveActivity.u);
connect(SkeletalMuscle_Metaboreflex_NerveActivity.val, gain.u);
connect(gain.y, totalEffect.u[1]);
connect(motorRadiation_TotalEffect.val, totalEffect.u[2]);
connect(ExerciseMetabolism_TotalWats, motorRadiation_TotalEffect.u);
connect(totalEffect.y, ExerciseSymps_TotalEffect);
end ExerciseSympathetic;

model VagusNerve
parameter Real[:, 3] SympsOnParasymps = {{0.0, 8.0, 0}, {1.5, 2.0, -2.0}, {4.5, 0.0, 0}};
Physiolibrary.Curves.Curve sympsOnParasymps(x = SympsOnParasymps[:, 1], y = SympsOnParasymps[:, 2], slope = SympsOnParasymps[:, 3]);
Physiolibrary.Interfaces.RealOutput_ VagusNerve_NA_Hz;
Physiolibrary.Interfaces.RealInput_ SympsCNS_NA_Hz;
equation
connect(SympsCNS_NA_Hz, sympsOnParasymps.u);
connect(sympsOnParasymps.val, VagusNerve_NA_Hz);
end VagusNerve;

model SA_Node
parameter Real[:, 3] SympatheticEffect = {{0.0, 0, 0}, {1.0, 10, 10}, {5.0, 120, 0}};
parameter Real[:, 3] ParasympatheticEffect = {{0.0, 0, 0}, {2.0, -20, -8}, {8.0, -40, 0}};
Physiolibrary.Interfaces.RealInput_ GangliaGeneral_NA;
Physiolibrary.Curves.Curve parasympatheticEffect(x = ParasympatheticEffect[:, 1], y = ParasympatheticEffect[:, 2], slope = ParasympatheticEffect[:, 3]);
Modelica.Blocks.Math.Sum rate(nin = 3);
Physiolibrary.Interfaces.RealOutput_ Rate;
Physiolibrary.Interfaces.RealInput_ VagusNerve_NA_Hz;
HumMod.Nerves.BetaReceptorsActivityFactor betaReceptorsActivityFactor;
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Blocks.Constant Constant1(k = 82);
Physiolibrary.Interfaces.RealInput_ BetaBlockade_Effect;
Physiolibrary.Interfaces.RealInput_ BetaPool_Effect;
Physiolibrary.Curves.Curve sympatheticEffect(x = SympatheticEffect[:, 1], y = SympatheticEffect[:, 2], slope = SympatheticEffect[:, 3]);
equation
connect(parasympatheticEffect.val, rate.u[2]);
connect(VagusNerve_NA_Hz, parasympatheticEffect.u);
connect(rate.y, Rate);
connect(Constant.y, betaReceptorsActivityFactor.yBase);
connect(Constant1.y, rate.u[1]);
connect(BetaPool_Effect, betaReceptorsActivityFactor.BetaPool_Effect);
connect(betaReceptorsActivityFactor.BetaBlockade_Effect, BetaBlockade_Effect);
connect(GangliaGeneral_NA, betaReceptorsActivityFactor.GangliaGeneral_NA);
connect(betaReceptorsActivityFactor.y, sympatheticEffect.u);
connect(sympatheticEffect.val, rate.u[3]);
end SA_Node;

model GangliaKidney
parameter Real[:, 3] LowPressureEffect = {{0.0, 1.5, 0}, {1.0, 1.0, -0.4}, {4.0, 0.2, 0}};
parameter Real[:, 3] FuelEffect = {{0.3, 0.0, 0}, {0.6, 3.0, 0}, {0.8, 0.0, 0}};
Physiolibrary.Interfaces.RealInput_ SympsCNS_BaroEffect;
Physiolibrary.Interfaces.RealOutput_ NA;
Physiolibrary.Interfaces.RealInput_ LowPressureReceptors_NA;
Physiolibrary.Interfaces.RealInput_ brain_Fuel_FractUseDelay;
Physiolibrary.Interfaces.RealInput_ SympsCNS_A2Effect;
Physiolibrary.Interfaces.RealInput_ ExerciseSymps_TotalEffect;
Physiolibrary.Blocks.MultiProduct ReflexNA(nin = 2);
Physiolibrary.Curves.Curve LowPressureEffectCurve(x = LowPressureEffect[:, 1], y = LowPressureEffect[:, 2], slope = LowPressureEffect[:, 3]);
Physiolibrary.Curves.Curve FuelEffectCurve(x = FuelEffect[:, 1], y = FuelEffect[:, 2], slope = FuelEffect[:, 3]);
Modelica.Blocks.Math.Sum sum1(nin = 3);
Modelica.Blocks.Math.Product NeuralActivity;
Modelica.Blocks.Math.Gain toHz(k = 1.5);
equation
connect(SympsCNS_BaroEffect, ReflexNA.u[1]);
connect(LowPressureReceptors_NA, LowPressureEffectCurve.u);
connect(LowPressureEffectCurve.val, ReflexNA.u[2]);
connect(brain_Fuel_FractUseDelay, FuelEffectCurve.u);
connect(ReflexNA.y, sum1.u[1]);
connect(ExerciseSymps_TotalEffect, sum1.u[2]);
connect(FuelEffectCurve.val, sum1.u[3]);
connect(sum1.y, NeuralActivity.u1);
connect(SympsCNS_A2Effect, NeuralActivity.u2);
connect(NeuralActivity.y, toHz.u);
connect(toHz.y, NA);
end GangliaKidney;

model BetaReceptorsActivityFactor
Physiolibrary.Interfaces.RealInput_ GangliaGeneral_NA(final quantity = "Frequency", final unit = "Hz");
Physiolibrary.Interfaces.RealInput_ BetaPool_Effect;
Physiolibrary.Interfaces.RealInput_ BetaBlockade_Effect;
Physiolibrary.Interfaces.RealInput_ yBase;
Physiolibrary.Interfaces.RealOutput_ y;
parameter Real NEURALK(final quantity = "FrequencyCoefficient", final unit = "1/Hz") = 0.333;
parameter Real HUMORALK = 0.5;
parameter Boolean Switch = false;
parameter Real Setting = 0;
Modelica.Blocks.Math.Add TotalAgonism(k1 = NEURALK, k2 = HUMORALK);
Modelica.Blocks.Logical.Switch switch1;
Physiolibrary.Blocks.BooleanConstant booleanConstant(k = Switch);
Physiolibrary.Blocks.Constant Constant(k = Setting);
Modelica.Blocks.Math.Product Activity;
Modelica.Blocks.Math.Product SympsEffect;
equation
connect(Activity.u2, BetaBlockade_Effect);
connect(Activity.u1, switch1.y);
connect(switch1.u3, TotalAgonism.y);
connect(switch1.u2, booleanConstant.y);
connect(switch1.u1, Constant.y);
connect(yBase, SympsEffect.u1);
connect(SympsEffect.y, y);
connect(GangliaGeneral_NA, TotalAgonism.u1);
connect(BetaPool_Effect, TotalAgonism.u2);
connect(Activity.y, SympsEffect.u2);
end BetaReceptorsActivityFactor;

model AplhaReceptorsActivityFactor
Physiolibrary.Interfaces.RealInput_ GangliaGeneral_NA(final quantity = "Frequency", final unit = "Hz");
Physiolibrary.Interfaces.RealInput_ AlphaPool_Effect;
Physiolibrary.Interfaces.RealInput_ AlphaBlockade_Effect;
Physiolibrary.Interfaces.RealInput_ yBase;
Physiolibrary.Interfaces.RealOutput_ y;
parameter Real[:, 3] data;
parameter Real NEURALK(final quantity = "FrequencyCoefficient", final unit = "1/Hz") = 0.333;
parameter Real HUMORALK = 0.5;
parameter Boolean Switch = false;
parameter Real Setting = 0;
Modelica.Blocks.Math.Add TotalAgonism(k1 = NEURALK, k2 = HUMORALK);
Modelica.Blocks.Logical.Switch switch1;
Physiolibrary.Blocks.BooleanConstant booleanConstant(k = Switch);
Physiolibrary.Blocks.Constant Constant(k = Setting);
Physiolibrary.Curves.Curve SympsOnConductance(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product Activity;
Modelica.Blocks.Math.Product SympsEffect;
equation
connect(SympsEffect.u2, SympsOnConductance.val);
connect(SympsOnConductance.u, Activity.y);
connect(Activity.u2, AlphaBlockade_Effect);
connect(Activity.u1, switch1.y);
connect(switch1.u3, TotalAgonism.y);
connect(switch1.u2, booleanConstant.y);
connect(switch1.u1, Constant.y);
connect(yBase, SympsEffect.u1);
connect(SympsEffect.y, y);
connect(GangliaGeneral_NA, TotalAgonism.u1);
connect(AlphaPool_Effect, TotalAgonism.u2);
end AplhaReceptorsActivityFactor;

model Pituitary
parameter Real[:, 3] BaroreflexOnBaroEffectData = {{0.0, 1.5, 0}, {1.0, 1.0, -0.5}, {2.0, 0.5, 0}};
Physiolibrary.Curves.Curve BaroreflexOnBaroEffect(x = BaroreflexOnBaroEffectData[:, 1], y = BaroreflexOnBaroEffectData[:, 2], slope = BaroreflexOnBaroEffectData[:, 3]);
Physiolibrary.Interfaces.RealOutput_ BaroEffect;
Physiolibrary.Interfaces.RealInput_ Baroreflex_NA;
Modelica.Blocks.Math.Feedback sub;
Physiolibrary.Blocks.Constant Constant(k = 1);
Modelica.Blocks.Math.Add add;
Modelica.Blocks.Math.Product product;
Physiolibrary.Blocks.Constant BaroSensitivity(k = 1);
equation
connect(Baroreflex_NA, BaroreflexOnBaroEffect.u);
connect(BaroreflexOnBaroEffect.val, sub.u1);
connect(Constant.y, sub.u2);
connect(add.y, BaroEffect);
connect(Constant.y, add.u2);
connect(product.y, add.u1);
connect(sub.y, product.u2);
connect(BaroSensitivity.y, product.u1);
end Pituitary;

model Hypothalamus
Physiolibrary.Interfaces.RealInput_ BrainFunctionEffect;
Physiolibrary.Interfaces.RealOutput_ HypothalamusSkinFlow_NA;
Physiolibrary.Interfaces.RealInput_ HeatCore_Temp;
Physiolibrary.Factors.CurveValue TemperatureEffect_(data = {{-2.0, 0.0, 0}, {0.0, 1.0, 1.8}, {2.0, 4.0, 0}});
Modelica.Blocks.Math.Feedback feedback;
Physiolibrary.Blocks.TemperatureConstant temperatureConstant(k = 37);
Physiolibrary.Factors.CurveValue SkinTempOffset(data = {{24, 0.0, 0}, {32, -1.0, 0}});
Physiolibrary.Interfaces.RealInput_ HeatSkin_Temp;
Physiolibrary.Blocks.TemperatureConstant temperatureConstant1(k = 37);
Modelica.Blocks.Math.Feedback feedback1;
Physiolibrary.Curves.Curve NerveActivity(x = {-2, 0}, y = {4, 0}, slope = {0, 0});
Physiolibrary.Factors.SplineDelayByDay HypothalamusShiveringAcclimation(Tau = 7, data = {{20, 0.3, 0}, {28, 0.0, -0.04}, {39, -0.3, 0}}, integrator(y_start = 0), stateName = "HypothalamusShiveringAcclimation.Offset");
Physiolibrary.Interfaces.RealOutput_ HypothalamusShivering_NA;
Physiolibrary.Interfaces.RealOutput_ HypothalamusSweating_NA;
Physiolibrary.Curves.Curve NerveActivity1(slope = {0, 0}, x = {0, 2}, y = {0, 4});
Modelica.Blocks.Math.Feedback feedback2;
Modelica.Blocks.Math.Sum SetPoint(nin = 3);
Physiolibrary.Blocks.TemperatureConstant temperatureConstant2(k = 37);
Physiolibrary.Curves.Curve SkinTempOffset_Sweating(slope = {0, 0}, x = {25, 35}, y = {1, 0});
Physiolibrary.Factors.SplineDelayByDay HypothalamusSweatingAcclimation1(data = {{20, 0.3, 0}, {28, 0.0, -0.04}, {39, -0.3, 0}}, integrator(y_start = 0), stateName = "HypothalamusSweatingAcclimation.Offset", Tau = 7);
Physiolibrary.Blocks.Constant Constant(k = 1);
equation
connect(TemperatureEffect_.u, feedback.y);
connect(feedback.u2, temperatureConstant.y);
connect(TemperatureEffect_.yBase, BrainFunctionEffect);
connect(TemperatureEffect_.y, HypothalamusSkinFlow_NA);
connect(HeatCore_Temp, feedback.u1);
connect(HeatSkin_Temp, SkinTempOffset.u);
connect(temperatureConstant1.y, SkinTempOffset.yBase);
connect(HeatCore_Temp, feedback1.u1);
connect(feedback1.y, NerveActivity.u);
connect(HeatSkin_Temp, HypothalamusShiveringAcclimation.u);
connect(SkinTempOffset.y, HypothalamusShiveringAcclimation.yBase);
connect(NerveActivity.val, HypothalamusShivering_NA);
connect(NerveActivity1.val, HypothalamusSweating_NA);
connect(feedback2.u1, HeatCore_Temp);
connect(feedback2.y, NerveActivity1.u);
connect(SetPoint.y, feedback2.u2);
connect(temperatureConstant2.y, SetPoint.u[1]);
connect(SkinTempOffset_Sweating.val, SetPoint.u[2]);
connect(HeatSkin_Temp, SkinTempOffset_Sweating.u);
connect(HypothalamusSweatingAcclimation1.y, SetPoint.u[3]);
connect(HeatSkin_Temp, HypothalamusSweatingAcclimation1.u);
connect(Constant.y, HypothalamusSweatingAcclimation1.yBase);
connect(SetPoint.y, feedback1.u2);
end Hypothalamus;

model Nerves
Modelica.Blocks.Math.Add avePressure(k1 = 0.5, k2 = 0.5);
BaroReceptorInDaysAdaptation lowPressureReceptors(PressureChangeOnNA = {{-4.0, 0.0, 0}, {0.0, 1.0, 0.3}, {12.0, 4.0, 0}}, AdaptivePressure = 6, Tau = 30);
BaroReceptorInHoursAdaptation Baroreflex(Tau = 10, PressureChangeOnNA = {{-50.0, 0.0, 0}, {0.0, 1.0, 0.02}, {50.0, 2.0, 0}}, AdaptivePressure = 96.86790000000001);
ExerciseSympathetic exercise;
SympatheticCNS sympatheticCNS;
VagusNerve vagusNerve;
Physiolibrary.Blocks.Constant const38(k = 1);
Physiolibrary.Interfaces.BusConnector busConnector;
GangliaKidney gangliaKidney;
Modelica.Blocks.Math.Gain AdrenalNerve(k = 0.667) "from Hz to normal activity";
Physiolibrary.Blocks.Constant Constant(k = 1);
Physiolibrary.Blocks.Constant KidneyAlpha_PT_NA(k = 1);
Pituitary pituitary;
equation
connect(avePressure.y, lowPressureReceptors.pressure);
connect(sympatheticCNS.ExerciseSymps_TotalEffect, exercise.ExerciseSymps_TotalEffect);
connect(sympatheticCNS.brain_Fuel_FractUseDelay, const38.y);
connect(vagusNerve.SympsCNS_NA_Hz, sympatheticCNS.NA);
connect(sympatheticCNS.NA, busConnector.GangliaGeneral_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(lowPressureReceptors.NA, sympatheticCNS.LowPressureReceptors);
connect(Baroreflex.NA, sympatheticCNS.CarotidSinusReceptors);
connect(busConnector.A2Pool_Log10Con, sympatheticCNS.A2Pool_Log10Conc) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.CarotidSinusArteryPressure, Baroreflex.pressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(exercise.ExerciseSymps_TotalEffect, gangliaKidney.ExerciseSymps_TotalEffect);
connect(lowPressureReceptors.NA, gangliaKidney.LowPressureReceptors_NA);
connect(busConnector.brain_Fuel_FractUseDelay, gangliaKidney.brain_Fuel_FractUseDelay) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(gangliaKidney.NA, busConnector.GangliaKidney_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(sympatheticCNS.SympsCNS_BaroEffect, gangliaKidney.SympsCNS_BaroEffect);
connect(sympatheticCNS.SympsCNS_A2Effect, gangliaKidney.SympsCNS_A2Effect);
connect(busConnector.ExerciseMetabolism_TotalWatts, exercise.ExerciseMetabolism_TotalWats) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(sympatheticCNS.NA, AdrenalNerve.u);
connect(AdrenalNerve.y, busConnector.AdrenalNerve_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Constant.y, busConnector.Kidney_Alpha_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(KidneyAlpha_PT_NA.y, busConnector.KidneyAlpha_PT_NA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Baroreflex.NA, pituitary.Baroreflex_NA);
connect(pituitary.BaroEffect, busConnector.SympsCNS_PituitaryNA) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(busConnector.skeletalMuscle_pH_intracellular, exercise.SkeletalMuscle_Ph) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.rightAtrium_TMP, avePressure.u1) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(busConnector.leftAtrium_TMP, avePressure.u2) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(vagusNerve.VagusNerve_NA_Hz, busConnector.VagusNerve_NA_Hz) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Nerves;
end Nerves;

package Setup  "Environment Influences"

model Setup_variables
replaceable class Variable = Physiolibrary.Utilities.ConstantFromFile;
Physiolibrary.Interfaces.BusConnector busConnector;
Variable AirSupplyInspiredAirPressure(varName = "AirSupply-InspiredAir.Pressure", varValue = 760.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Anesthesia_VascularConductance(varName = "Anesthesia.VascularConductance", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable AnesthesiaTidalVolume(varName = "Anesthesia.TidalVolume", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable BarometerPressure(varName = "Barometer.Pressure", varValue = 760.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable CarotidSinusHeight(varName = "Hydrostatics.CarotidCM", varValue = 0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DialyzerActivity_Cl_Flux(varName = "DialyzerActivity.Cl-Flux", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DialyzerActivity_K_Flux(varName = "DialyzerActivity.K+Flux", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DialyzerActivity_Na_Flux(varName = "DialyzerActivity.Na+Flux", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietGoalH2O_DegK(varName = "DietGoalH2O.DegK", varValue = 294.261111111111, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeElectrolytes_Cl(varName = "DietIntakeElectrolytes.Cl-_mEq/Min", varValue = 0.13910967422831, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeElectrolytes_K(varName = "DietIntakeElectrolytes.K+_mEq/Min", varValue = 0.0486883859799086, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeElectrolytes_Na(varName = "DietIntakeElectrolytes.Na+_mEq/Min", varValue = 0.125198706805479, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeElectrolytes_PO4(varName = "DietIntakeElectrolytes.PO4--mEq/Min", varValue = 0.0230576, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeElectrolytes_SO4(varName = "DietIntakeElectrolytes.SO4--mEq/Min", varValue = 0.0347774185570776, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Exercise_Metabolism_ContractionRate(varName = "Exercise-Metabolism.ContractionRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Exercise_Metabolism_MotionWatts(varName = "Exercise-Metabolism.MotionWatts", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Exercise_MusclePump_Effect(varName = "Exercise-MusclePump.Effect", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable ExerciseMetabolism_MotionCals(varName = "Exercise-Metabolism.MotionCals", varValue = 55.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable ExerciseMetabolism_TotalWatts(varName = "Exercise-Metabolism.TotalWatts", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable FurosemidePool_Furosemide_conc(varName = "FurosemidePool.[Furosemide]", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable FurosemidePool_Loss(varName = "FurosemidePool.Loss", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Gravity_Gz(varName = "Gravity.Gz", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable GILumenDiarrhea_KLoss(varName = "GILumenDiarrhea.K+Loss", varValue = 0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable GILumenDiarrhea_NaLoss(varName = "GILumenDiarrhea.Na+Loss", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable GILumenVomitus_ClLoss(varName = "GILumenVomitus.Cl-Loss", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_ClRate(varName = "Hemorrhage.ClRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_KRate(varName = "Hemorrhage.KRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_NaRate(varName = "Hemorrhage.NaRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_PlasmaRate(varName = "Hemorrhage.PlasmaRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_ProteinRate(varName = "Hemorrhage.ProteinRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_RBCRate(varName = "Hemorrhage.RBCRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable IVDrip_ClRate(varName = "IVDrip.ClRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable IVDrip_H2ORate(varName = "IVDrip.H2ORate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable IVDrip_KRate(varName = "IVDrip.KRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable IVDrip_NaRate(varName = "IVDrip.NaRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Kidney_NephronCount_Filtering_xNormal(varName = "Kidney-NephronCount.Filtering(xNormal)", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Kidney_NephronCount_Total_xNormal(varName = "Kidney-NephronCount.Total(xNormal)", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable LegMusclePump_Effect(varName = "LegMusclePump.Effect", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable LowerTorsoArtyHeight(varName = "Hydrostatics.LowerTorsoCM", varValue = 0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable LowerTorsoVeinHeight(varName = "Hydrostatics.LowerTorsoCM", varValue = 0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable pCO(varName = "pCO", varValue = 0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Pericardium_Pressure(varName = "Pericardium-Cavity.Pressure", varValue = -3.34522126058954, initType = Physiolibrary.Utilities.Init.NoInit);
Variable skeletalMuscle_SizeMass(varName = "SkeletalMuscle-Size.Mass", varValue = 27400.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable skinSizeMass(varName = "Skin-Size.Mass", varValue = 2244.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Status_Posture(varName = "Status.Posture", varValue = 5.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable ThiazidePool_Thiazide_conc(varName = "ThiazidePool.[Thiazide]", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Thorax_AvePressure(varName = "Thorax.AvePressure", varValue = -4.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Thorax_LungInflation(varName = "Thorax.LungInflation", varValue = 1.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_ClRate(varName = "Transfusion.ClRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_KRate(varName = "Transfusion.KRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_NaRate(varName = "Transfusion.NaRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_PlasmaRate(varName = "Transfusion.PlasmaRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_ProteinRate(varName = "Transfusion.ProteinRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_RBCRate(varName = "Transfusion.RBCRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable WeightCore(varName = "Weight.Core", varValue = 41757.328756, initType = Physiolibrary.Utilities.Init.NoInit);
Variable IVDrip_ProteinRate(varName = "IVDrip.ProteinRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable AmbientTemperature(varName = "AmbientTemperature.Temp(C)", varValue = 22.2222222222222, initType = Physiolibrary.Utilities.Init.NoInit);
Variable EnvironmentRelativeHumidity(varName = "EnvironmentRelativeHumidity", varValue = 0.7, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DietIntakeH2O_Rate(varName = "DietIntakeH2O.Rate(mL/Min)", varValue = 1.489407, initType = Physiolibrary.Utilities.Init.NoInit);
Variable DialyzerActivity_UltrafiltrationRate(varName = "DialyzerActivity.UltrafiltrationRate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Hemorrhage_PlasmaRate1(varName = "Hemorrhage.H2ORate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Transfusion_PlasmaRate1(varName = "Transfusion.H2ORate", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable GILumenVomitus_H2OTarget(varName = "GILumenVomitus.H2OTarget", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable GILumenDiarrhea_H2OTarget(varName = "GILumenDiarrhea.H2OTarget", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
Variable Wind_MPH(varName = "Wind.MPH", varValue = 0.0, initType = Physiolibrary.Utilities.Init.NoInit);
equation
connect(Gravity_Gz.y, busConnector.Gravity_Gz) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(BarometerPressure.y, busConnector.BarometerPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(AirSupplyInspiredAirPressure.y, busConnector.AirSupplyInspiredAirPressure) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(pCO.y, busConnector.pCO) annotation(Text(string = "%first", index = -1, extent = {{-6, 3}, {-6, 3}}));
connect(IVDrip_NaRate.y, busConnector.IVDrip_NaRate);
connect(Transfusion_NaRate.y, busConnector.Transfusion_NaRate);
connect(Hemorrhage_NaRate.y, busConnector.Hemorrhage_NaRate);
connect(DialyzerActivity_Na_Flux.y, busConnector.DialyzerActivity_Na_Flux);
connect(DietIntakeElectrolytes_Na.y, busConnector.DietIntakeElectrolytes_Na);
connect(GILumenDiarrhea_NaLoss.y, busConnector.GILumenDiarrhea_NaLoss);
connect(IVDrip_KRate.y, busConnector.IVDrip_KRate);
connect(Transfusion_KRate.y, busConnector.Transfusion_KRate);
connect(Hemorrhage_KRate.y, busConnector.Hemorrhage_KRate);
connect(DialyzerActivity_K_Flux.y, busConnector.DialyzerActivity_K_Flux);
connect(DietIntakeElectrolytes_K.y, busConnector.DietIntakeElectrolytes_K);
connect(GILumenDiarrhea_KLoss.y, busConnector.GILumenDiarrhea_KLoss);
connect(IVDrip_ClRate.y, busConnector.IVDrip_ClRate);
connect(Transfusion_ClRate.y, busConnector.Transfusion_ClRate);
connect(Hemorrhage_ClRate.y, busConnector.Hemorrhage_ClRate);
connect(DialyzerActivity_Cl_Flux.y, busConnector.DialyzerActivity_Cl_Flux);
connect(DietIntakeElectrolytes_Cl.y, busConnector.DietIntakeElectrolytes_Cl);
connect(GILumenVomitus_ClLoss.y, busConnector.GILumenVomitus_ClLoss);
connect(DietIntakeElectrolytes_PO4.y, busConnector.DietIntakeElectrolytes_PO4);
connect(DietIntakeElectrolytes_SO4.y, busConnector.DietIntakeElectrolytes_SO4);
connect(DietGoalH2O_DegK.y, busConnector.DietGoalH2O_DegK) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Exercise_MusclePump_Effect.y, busConnector.Exercise_MusclePump_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Exercise_Metabolism_ContractionRate.y, busConnector.Exercise_Metabolism_ContractionRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Exercise_Metabolism_MotionWatts.y, busConnector.Exercise_Metabolism_MotionWatts) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LegMusclePump_Effect.y, busConnector.LegMusclePump_Effect) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ExerciseMetabolism_MotionCals.y, busConnector.ExerciseMetabolism_MotionCals) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ExerciseMetabolism_TotalWatts.y, busConnector.ExerciseMetabolism_TotalWatts) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LowerTorsoArtyHeight.y, busConnector.LowerTorsoArtyHeight) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(LowerTorsoVeinHeight.y, busConnector.LowerTorsoVeinHeight) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(CarotidSinusHeight.y, busConnector.CarotidSinusHeight) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Status_Posture.y, busConnector.Status_Posture) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(FurosemidePool_Furosemide_conc.y, busConnector.FurosemidePool_Furosemide_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(ThiazidePool_Thiazide_conc.y, busConnector.ThiazidePool_Thiazide_conc) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(FurosemidePool_Loss.y, busConnector.FurosemidePool_Loss) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage_ProteinRate.y, busConnector.Hemorrhage_ProteinRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion_ProteinRate.y, busConnector.Transfusion_ProteinRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(IVDrip_H2ORate.y, busConnector.IVDrip_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion_PlasmaRate.y, busConnector.Transfusion_PlasmaRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage_PlasmaRate.y, busConnector.Hemorrhage_PlasmaRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage_RBCRate.y, busConnector.Hemorrhage_RBCRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion_RBCRate.y, busConnector.Transfusion_RBCRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Pericardium_Pressure.y, busConnector.Pericardium_Pressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Thorax_AvePressure.y, busConnector.Thorax_AvePressure) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Thorax_LungInflation.y, busConnector.Thorax_LungInflation) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Kidney_NephronCount_Total_xNormal.y, busConnector.Kidney_NephronCount_Total_xNormal) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Kidney_NephronCount_Filtering_xNormal.y, busConnector.Kidney_NephronCount_Filtering_xNormal) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AnesthesiaTidalVolume.y, busConnector.AnesthesiaTidalVolume) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Anesthesia_VascularConductance.y, busConnector.Anesthesia_VascularConductance) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(skeletalMuscle_SizeMass.y, busConnector.skeletalMuscle_SizeMass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(skinSizeMass.y, busConnector.skinSizeMass) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(WeightCore.y, busConnector.WeightCore) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(IVDrip_ProteinRate.y, busConnector.IVDripProteinRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(AmbientTemperature.y, busConnector.AmbientTemperature) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(EnvironmentRelativeHumidity.y, busConnector.EnvironmentRelativeHumidity) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(DietIntakeH2O_Rate.y, busConnector.DietIntakeH2O_Rate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(DialyzerActivity_UltrafiltrationRate.y, busConnector.DialyzerActivity_UltrafiltrationRate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Hemorrhage_PlasmaRate1.y, busConnector.Hemorrhage_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Transfusion_PlasmaRate1.y, busConnector.Transfusion_H2ORate) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(GILumenDiarrhea_H2OTarget.y, busConnector.GILumenDiarrhea_H2OTarget) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(GILumenVomitus_H2OTarget.y, busConnector.GILumenVomitus_H2OTarget) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
connect(Wind_MPH.y, busConnector.Wind_MPH) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
end Setup_variables;
end Setup;

package Status  "Fitness Status of Tissue Structures and Functionality"

model TissuesFitness
tissues.SkeletalMuscle skeletalMuscle;
tissues.Bone bone;
tissues.Fat fat;
tissues.Brain brain;
tissues.RightHeart rightHeart;
tissues.RespiratoryMuscle respiratoryMuscle;
tissues.OtherTissue otherTissue;
tissues.Liver liver;
tissues.LeftHeart leftHeart;
tissues.Kidney kidney;
tissues.GITract GITract;
Physiolibrary.Interfaces.BusConnector busConnector;
tissues.Skin skin;
PatientStatus patientStatus;
equation
connect(bone.pH_intracellular, busConnector.bone_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.pH_intracellular, busConnector.brain_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.pH_intracellular, busConnector.fat_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.pH_intracellular, busConnector.GITract_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.pH_intracellular, busConnector.kidney_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.pH_intracellular, busConnector.leftHeart_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.pH_intracellular, busConnector.liver_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.pH_intracellular, busConnector.otherTissue_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.pH_intracellular, busConnector.respiratoryMuscle_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.pH_intracellular, busConnector.rightHeart_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.pH_intracellular, busConnector.skin_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.pH_intracellular, busConnector.skeletalMuscle_pH_intracellular) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.T, busConnector.bone_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.T, busConnector.brain_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.T, busConnector.fat_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.T, busConnector.GITract_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.T, busConnector.kidney_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.T, busConnector.leftHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.T, busConnector.liver_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.T, busConnector.otherTissue_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.T, busConnector.respiratoryMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.T, busConnector.rightHeart_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.T, busConnector.skin_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.T, busConnector.skeletalMuscle_T) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.Fuel_FractUseDelay, busConnector.bone_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.Fuel_FractUseDelay, busConnector.brain_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.Fuel_FractUseDelay, busConnector.fat_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.Fuel_FractUseDelay, busConnector.GITract_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.Fuel_FractUseDelay, busConnector.kidney_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.Fuel_FractUseDelay, busConnector.leftHeart_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.Fuel_FractUseDelay, busConnector.liver_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.Fuel_FractUseDelay, busConnector.otherTissue_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.Fuel_FractUseDelay, busConnector.respiratoryMuscle_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.Fuel_FractUseDelay, busConnector.rightHeart_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.Fuel_FractUseDelay, busConnector.skin_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.Fuel_FractUseDelay, busConnector.skeletalMuscle_Fuel_FractUseDelay) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(brain.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(fat.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(GITract.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(kidney.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(leftHeart.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(liver.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(otherTissue.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(respiratoryMuscle.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(rightHeart.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skin.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(skeletalMuscle.CellProtein_Mass, busConnector.CellProtein_Mass) annotation(Text(string = "%second", index = 1, extent = {{5, 2}, {5, 2}}));
connect(bone.StructureEffect, busConnector.bone_StructureEffect);
connect(brain.StructureEffect, busConnector.brain_StructureEffect);
connect(fat.StructureEffect, busConnector.fat_StructureEffect);
connect(GITract.StructureEffect, busConnector.GITract_StructureEffect);
connect(kidney.StructureEffect, busConnector.kidney_StructureEffect);
connect(leftHeart.StructureEffect, busConnector.leftHeart_StructureEffect);
connect(liver.StructureEffect, busConnector.liver_StructureEffect);
connect(otherTissue.StructureEffect, busConnector.otherTissue_StructureEffect);
connect(rightHeart.StructureEffect, busConnector.rightHeart_StructureEffect);
connect(respiratoryMuscle.StructureEffect, busConnector.respiratoryMuscle_StructureEffect);
connect(skin.StructureEffect, busConnector.skin_StructureEffect);
connect(skeletalMuscle.StructureEffect, busConnector.skeletalMuscle_StructureEffect);
connect(bone.StructureEffect, busConnector.Bone_StructureEffect);
connect(brain.StructureEffect, busConnector.Brain_StructureEffect);
connect(fat.StructureEffect, busConnector.Fat_StructureEffect);
connect(kidney.StructureEffect, busConnector.Kidney_StructureEffect);
connect(leftHeart.StructureEffect, busConnector.LeftHeart_StructureEffect);
connect(liver.StructureEffect, busConnector.Liver_StructureEffect);
connect(otherTissue.StructureEffect, busConnector.OtherTissue_StructureEffect);
connect(rightHeart.StructureEffect, busConnector.RightHeart_StructureEffect);
connect(respiratoryMuscle.StructureEffect, busConnector.RespiratoryMuscle_StructureEffect);
connect(skin.StructureEffect, busConnector.Skin_StructureEffect);
connect(skeletalMuscle.StructureEffect, busConnector.SkeletalMuscle_StructureEffect);
connect(bone.FunctionEffect, busConnector.bone_FunctionEffect);
connect(brain.FunctionEffect, busConnector.brain_FunctionEffect);
connect(fat.FunctionEffect, busConnector.fat_FunctionEffect);
connect(GITract.FunctionEffect, busConnector.GITract_FunctionEffect);
connect(kidney.FunctionEffect, busConnector.kidney_FunctionEffect);
connect(leftHeart.FunctionEffect, busConnector.leftHeart_FunctionEffect);
connect(liver.FunctionEffect, busConnector.liver_FunctionEffect);
connect(otherTissue.FunctionEffect, busConnector.otherTissue_FunctionEffect);
connect(rightHeart.FunctionEffect, busConnector.rightHeart_FunctionEffect);
connect(respiratoryMuscle.FunctionEffect, busConnector.respiratoryMuscle_FunctionEffect);
connect(skin.FunctionEffect, busConnector.skin_FunctionEffect);
connect(skeletalMuscle.FunctionEffect, busConnector.skeletalMuscle_FunctionEffect);
connect(bone.FunctionEffect, busConnector.BoneFunctionEffect);
connect(brain.FunctionEffect, busConnector.BrainFunctionEffect);
connect(fat.FunctionEffect, busConnector.FatFunctionEffect);
connect(GITract.FunctionEffect, busConnector.GITractFunctionEffect);
connect(kidney.FunctionEffect, busConnector.KidneyFunctionEffect);
connect(leftHeart.FunctionEffect, busConnector.LeftHeartFunctionEffect);
connect(liver.FunctionEffect, busConnector.LiverFunctionEffect);
connect(otherTissue.FunctionEffect, busConnector.OtherTissueFunctionEffect);
connect(rightHeart.FunctionEffect, busConnector.RightHeartFunctionEffect);
connect(respiratoryMuscle.FunctionEffect, busConnector.RespiratoryMuscleFunctionEffect);
connect(skin.FunctionEffect, busConnector.SkinFunctionEffect);
connect(skeletalMuscle.FunctionEffect, busConnector.SkeletalMuscleFunctionEffect);
connect(bone.FunctionFailed, busConnector.Bone_Function_Failed);
connect(brain.FunctionFailed, busConnector.Brain_Function_Failed);
connect(GITract.FunctionFailed, busConnector.GITract_Function_Failed);
connect(fat.FunctionFailed, busConnector.Fat_Function_Failed);
connect(kidney.FunctionFailed, busConnector.Kidney_Function_Failed);
connect(leftHeart.FunctionFailed, busConnector.LeftHeart_Function_Failed);
connect(liver.FunctionFailed, busConnector.Liver_Function_Failed);
connect(otherTissue.FunctionFailed, busConnector.OtherTissue_Function_Failed);
connect(rightHeart.FunctionFailed, busConnector.RightHeart_Function_Failed);
connect(respiratoryMuscle.FunctionFailed, busConnector.RespiratoryMuscle_Function_Failed);
connect(skin.FunctionFailed, busConnector.Skin_Function_Failed);
connect(skeletalMuscle.FunctionFailed, busConnector.SkeletalMuscle_Function_Failed);
connect(brain.FunctionEffect, patientStatus.BrainFunctionEffect);
end TissuesFitness;

model Failed
parameter Real effectAtFailing = 0.2;
parameter Real effectAtRevitaling = 0.4;
Physiolibrary.Interfaces.RealInput_ FunctionEffect;
Physiolibrary.Interfaces.BooleanOutput Failed;
Boolean a(start = false);
Boolean b(start = true);
Boolean c(start = false);
equation
a = FunctionEffect < effectAtFailing;
b = FunctionEffect > effectAtRevitaling;
c = pre(Failed);
Failed = a or c and not b;
end Failed;

model PatientStatus
Normal normal;
Confused confused(nOut = 2, nIn = 2);
Modelica.StateGraph.TransitionWithSignal worse1 "He's like confused.
";
Modelica.StateGraph.TransitionWithSignal better "Now he's feeling better.
";
Impaired impaired(nIn = 2, nOut = 2);
Comatose comatose(nIn = 2, nOut = 2);
NotBreathing notBreathing(nOut = 2, nIn = 3);
MayBeDead mayBeDead(nOut = 2);
IsReallyDead isReallyDead;
Physiolibrary.Interfaces.RealInput_ BrainFunctionEffect;
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold(threshold = 0.8);
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold1(threshold = 0.6);
Modelica.StateGraph.TransitionWithSignal worse2 "He can't talk wery well ...
";
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold2(threshold = 0.4);
Modelica.StateGraph.TransitionWithSignal worse3 "Your patient is not conscious!
";
Modelica.StateGraph.TransitionWithSignal worse4 "Your patient is not conscious!
";
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold3(threshold = 0.2);
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold4(threshold = 0.1);
Modelica.StateGraph.TransitionWithSignal worse5 "Your patient is not conscious!
";
Modelica.Blocks.Logical.LessEqualThreshold lessEqualThreshold5(threshold = 0);
Modelica.StateGraph.TransitionWithSignal worse6 "Your patient is not conscious!
";
Modelica.StateGraph.TransitionWithSignal better2 "Your patient seems to be conscious again.
";
Modelica.StateGraph.TransitionWithSignal better3 "Your patient is breathing again.
";
Modelica.StateGraph.TransitionWithSignal better4 "Wait. Your patient is not dead! ";
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold6(threshold = 0.2);
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold7(threshold = 0.4);
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold8(threshold = 0.6);
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold9(threshold = 0.95);
Modelica.StateGraph.TransitionWithSignal better5 "Wait. Your patient is not dead!";
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold10(threshold = 0.2);
Physiolibrary.Interfaces.BooleanOutput IS_NORMAL;
Physiolibrary.Interfaces.BooleanOutput IS_CONFUSED;
Physiolibrary.Interfaces.BooleanOutput IS_IMPAIRED;
Physiolibrary.Interfaces.BooleanOutput IS_COMATOUS;
Physiolibrary.Interfaces.BooleanOutput IS_NOT_BREATHING;
Physiolibrary.Interfaces.BooleanOutput IS_MAY_BE_DEAD;
Physiolibrary.Interfaces.BooleanOutput IS_REALLY_DEAD;
Modelica.StateGraph.TransitionWithSignal better1 "Your patient seems to be conscious again.
";
Modelica.Blocks.Logical.GreaterEqualThreshold lessEqualThreshold11(threshold = 0.8);
equation
connect(normal.outPort[1], worse1.inPort);
connect(worse1.outPort, confused.inPort[1]);
connect(better.outPort, normal.inPort[1]);
connect(lessEqualThreshold.y, worse1.condition);
connect(BrainFunctionEffect, lessEqualThreshold.u);
connect(BrainFunctionEffect, lessEqualThreshold1.u);
connect(lessEqualThreshold1.y, worse2.condition);
connect(confused.outPort[1], worse2.inPort);
connect(worse2.outPort, impaired.inPort[1]);
connect(BrainFunctionEffect, lessEqualThreshold2.u);
connect(lessEqualThreshold2.y, worse3.condition);
connect(impaired.outPort[1], worse3.inPort);
connect(worse3.outPort, comatose.inPort[1]);
connect(lessEqualThreshold3.y, worse4.condition);
connect(BrainFunctionEffect, lessEqualThreshold3.u);
connect(lessEqualThreshold4.y, worse5.condition);
connect(lessEqualThreshold5.y, worse6.condition);
connect(BrainFunctionEffect, lessEqualThreshold4.u);
connect(BrainFunctionEffect, lessEqualThreshold5.u);
connect(notBreathing.outPort[1], worse5.inPort);
connect(worse5.outPort, mayBeDead.inPort[1]);
connect(mayBeDead.outPort[1], worse6.inPort);
connect(worse6.outPort, isReallyDead.inPort[1]);
connect(lessEqualThreshold6.y, better4.condition);
connect(mayBeDead.outPort[2], better4.inPort);
connect(better4.outPort, notBreathing.inPort[2]);
connect(BrainFunctionEffect, lessEqualThreshold6.u);
connect(BrainFunctionEffect, lessEqualThreshold7.u);
connect(lessEqualThreshold7.y, better3.condition);
connect(notBreathing.outPort[2], better3.inPort);
connect(better3.outPort, comatose.inPort[2]);
connect(comatose.outPort[2], better2.inPort);
connect(better2.outPort, impaired.inPort[2]);
connect(lessEqualThreshold8.y, better2.condition);
connect(lessEqualThreshold8.u, BrainFunctionEffect);
connect(better.condition, lessEqualThreshold9.y);
connect(BrainFunctionEffect, lessEqualThreshold9.u);
connect(normal.active, IS_NORMAL);
connect(confused.active, IS_CONFUSED);
connect(impaired.active, IS_IMPAIRED);
connect(comatose.active, IS_COMATOUS);
connect(notBreathing.active, IS_NOT_BREATHING);
connect(IS_MAY_BE_DEAD, mayBeDead.active);
connect(isReallyDead.active, IS_REALLY_DEAD);
connect(better5.condition, lessEqualThreshold10.y);
connect(BrainFunctionEffect, lessEqualThreshold10.u);
connect(comatose.outPort[1], worse4.inPort);
connect(worse4.outPort, notBreathing.inPort[1]);
connect(confused.outPort[2], better.inPort);
connect(better5.outPort, notBreathing.inPort[3]);
connect(isReallyDead.outPort[1], better5.inPort);
connect(lessEqualThreshold11.y, better1.condition);
connect(lessEqualThreshold11.u, BrainFunctionEffect);
connect(impaired.outPort[2], better1.inPort);
connect(better1.outPort, confused.inPort[2]);
end PatientStatus;

block Normal
extends Modelica.StateGraph.InitialStepWithSignal;
end Normal;

block Confused
extends Modelica.StateGraph.StepWithSignal;
end Confused;

block Impaired
extends Modelica.StateGraph.StepWithSignal;
end Impaired;

block Comatose
extends Modelica.StateGraph.StepWithSignal;
end Comatose;

block NotBreathing
extends Modelica.StateGraph.StepWithSignal;
end NotBreathing;

block MayBeDead
extends Modelica.StateGraph.StepWithSignal;
end MayBeDead;

block IsReallyDead
extends Modelica.StateGraph.StepWithSignal;
end IsReallyDead;

package tissues
model TissueFitness
Physiolibrary.Interfaces.RealOutput_ FunctionEffect;
Physiolibrary.Interfaces.RealOutput_ StructureEffect;
Physiolibrary.Interfaces.RealInput_ pH_intracellular;
Physiolibrary.Interfaces.RealInput_ T(final unit = "degC") "tissue temperature";
Physiolibrary.Interfaces.RealInput_ Fuel_FractUseDelay;
Physiolibrary.Interfaces.RealInput_ CellProtein_Mass(final unit = "g");
Physiolibrary.Factors.CurveValue PhOnStructure(data = {{6.5, 0.1, 0}, {6.6, 0.0, 0}});
Physiolibrary.Factors.CurveValue FuelOnStructure(data = {{0.5, 0.05, 0}, {0.8, 0.0, 0}});
Physiolibrary.Factors.CurveValue TemperatureOnStructure(data = {{44.0, 0.0, 0}, {46.0, 0.05, 0}});
Physiolibrary.Blocks.Constant Constant(k = 1);
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Continuous.Integrator integrator(y_start = 1, k = 1 / Physiolibrary.SecPerMin);
Physiolibrary.Factors.CurveValue PhOnFunction(data = {{6.6, 0.0, 0}, {6.7, 1.0, 0}});
Physiolibrary.Factors.CurveValue ProteinOnFunction(data = {{3000.0, 0.0, 0}, {5200.0, 1.0, 0}});
Physiolibrary.Factors.CurveValue FuelOnFunction(data = {{0.0, 0.0, 0}, {0.9, 1.0, 0}});
Physiolibrary.Factors.CurveValue TemperatureOnFunction(data = {{10, 0.0, 0}, {37, 1.0, 0.12}, {40, 1.5, 0}, {46, 0.0, 0}});
Physiolibrary.Blocks.Constant Constant1(k = 1);
Physiolibrary.Factors.SimpleMultiply StructureEff;
Failed failed;
Physiolibrary.Interfaces.BooleanOutput FunctionFailed;
Physiolibrary.Blocks.Constant Constant2(k = 0);
equation
connect(PhOnStructure.u, pH_intracellular);
connect(FuelOnStructure.u, Fuel_FractUseDelay);
connect(TemperatureOnStructure.u, T);
connect(PhOnStructure.y, FuelOnStructure.yBase);
connect(FuelOnStructure.y, TemperatureOnStructure.yBase);
connect(Constant.y, PhOnStructure.yBase);
connect(TemperatureOnStructure.y, feedback.u2);
connect(feedback.y, integrator.u);
connect(integrator.y, StructureEffect);
connect(pH_intracellular, PhOnFunction.u);
connect(CellProtein_Mass, ProteinOnFunction.u);
connect(Fuel_FractUseDelay, FuelOnFunction.u);
connect(T, TemperatureOnFunction.u);
connect(TemperatureOnFunction.y, FuelOnFunction.yBase);
connect(FuelOnFunction.y, PhOnFunction.yBase);
connect(PhOnFunction.y, ProteinOnFunction.yBase);
connect(Constant1.y, TemperatureOnFunction.yBase);
connect(integrator.y, StructureEff.u);
connect(ProteinOnFunction.y, StructureEff.yBase);
connect(StructureEff.y, FunctionEffect);
connect(StructureEff.y, failed.FunctionEffect);
connect(failed.Failed, FunctionFailed);
connect(Constant2.y, feedback.u1);
end TissueFitness;

model SkeletalMuscle
extends TissueFitness;
end SkeletalMuscle;

model Bone
extends TissueFitness;
end Bone;

model OtherTissue
extends TissueFitness;
end OtherTissue;

model RespiratoryMuscle
extends TissueFitness;
end RespiratoryMuscle;

model Fat
extends TissueFitness;
end Fat;

model Skin
extends TissueFitness(TemperatureOnFunction(data = {{10.0, 0.0, 0}, {29.5, 1.0, 0.12}, {40.0, 1.5, 0}, {46.0, 0.0, 0}}));
end Skin;

model Liver
extends TissueFitness;
end Liver;

model Brain
extends TissueFitness;
end Brain;

model GITract
extends TissueFitness;
end GITract;

model Kidney
extends TissueFitness;
end Kidney;

model LeftHeart
extends TissueFitness;
end LeftHeart;

model RightHeart
extends TissueFitness;
end RightHeart;
end tissues;
end Status;

package Main
package test
model HumMod_GolemEdition2  "Main model"
.HumMod.CardioVascular.CVS_Dynamic cardioVascularSystem;
.HumMod.Metabolism.NutrientsAndMetabolism nutrientsAndMetabolism;
.HumMod.Electrolytes.Electrolytes electrolytes;
.HumMod.Hormones.Hormones hormones;
.HumMod.Nerves.Nerves nerves;
.HumMod.Setup.Setup_variables setup;
.HumMod.Water.Water2 water;
.HumMod.Proteins.Proteins proteins;
.HumMod.Status.TissuesFitness status;
.HumMod.Gases.Gases gases;
.HumMod.Heat.Heat2 heat;
equation
connect(setup.busConnector, hormones.busConnector);
connect(setup.busConnector, proteins.busConnector);
connect(setup.busConnector, cardioVascularSystem.busConnector);
connect(setup.busConnector, nutrientsAndMetabolism.busConnector);
connect(setup.busConnector, water.busConnector);
connect(setup.busConnector, nerves.busConnector);
connect(status.busConnector, setup.busConnector);
connect(electrolytes.busConnector, setup.busConnector);
connect(gases.busConnector, setup.busConnector);
connect(heat.busConnector, setup.busConnector);
annotation(Commands(file = "view.mos"), experiment(StartTime = 0, StopTime = 2592000.0, Tolerance = 0.01, Interval = 60));
end HumMod_GolemEdition2;
end test;
end Main;
end HumMod;

package Physiolibrary  "Physiological domains library"

package Interfaces  "Abstract Interfaces"
partial model BaseModel  end BaseModel;

partial model BaseFactorIcon
RealInput_ yBase;
RealOutput_ y;
end BaseFactorIcon;

partial model BaseFactorIcon2
RealInput_ yBase;
RealOutput_ y;
end BaseFactorIcon2;

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

partial connector SignalBusBlue  "Icon for signal bus" end SignalBusBlue;

connector RealInput = input Real "'input Real' as connector";
connector RealInput_ = input Real "'input Real' as connector";
connector RealOutput = output Real "'output Real' as connector";
connector RealOutput_ = output Real "'output Real' as connector";
connector BooleanInput = input Boolean "'input Boolean' as connector";
connector BooleanOutput = output Boolean "'output Boolean' as connector";

partial block SIMO  "Single Input Multiple Output continuous control block"
parameter Integer nout = 1 "Number of outputs";
Modelica.Blocks.Interfaces.RealInput u "Connector of Real input signal";
Modelica.Blocks.Interfaces.RealOutput[nout] y "Connector of Real output signals";
end SIMO;

partial block SISO  "Single Input Single Output continuous control block"
Modelica.Blocks.Interfaces.RealInput u "Connector of Real input signals";
Modelica.Blocks.Interfaces.RealOutput y "Connector of Real output signal";
end SISO;

partial class ConversionIcon  "Base icon for conversion functions" end ConversionIcon;

expandable connector BusConnector  "Empty control bus that is adapted to the signals connected to it"
extends Physiolibrary.Interfaces.SignalBusBlue;
end BusConnector;
end Interfaces;

package Blocks  "Base Signal Blocks Library"
block BooleanConstant  "Generate constant signal of type Boolean"
parameter Boolean k = true "Constant output value";
extends Modelica.Blocks.Interfaces.partialBooleanSource;
equation
y = k;
end BooleanConstant;

block Parts  "Divide the input value by weights"
extends Physiolibrary.Interfaces.SIMO;
parameter Real[nout] w = ones(nout) "Optional: weight coeficients";
protected
Real coef;
Real[nout] weight;
equation
ones(nout) * weight = 1;
for i in 1:nout loop
weight[i] = w[i] * coef;
y[i] = u * weight[i];
end for;
end Parts;

block Add  "Output the addition of a value with the input signal"
parameter Real k(start = 1) "value added to input signal";
Modelica.Blocks.Interfaces.RealInput u "Input signal connector";
Modelica.Blocks.Interfaces.RealOutput y "Output signal connector";
equation
y = k + u;
end Add;

block Pow  "the power of parameter"
extends Physiolibrary.Interfaces.SISO;
parameter Real power_base = 10 "base";
equation
y = power_base ^ u;
end Pow;

block Inv  "Output the inverse value of the input"
extends Modelica.Blocks.Interfaces.SISO;
equation
y = 1 / u;
end Inv;

block MultiProduct  "Output the product of the elements of the input vector"
extends Modelica.Blocks.Interfaces.MISO;
equation
y = product(u);
end MultiProduct;

block Log10AsEffect  "Output the base 10 logarithm of the input > 1, or 0 otherwise"
extends Modelica.Blocks.Interfaces.SISO;
equation
y = if u > 1 then Modelica.Math.log10(u) else 0;
end Log10AsEffect;

block Constant  "Generate constant signal of type Real"
parameter Real k(start = 1) "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y "Connector of Real output signal";
equation
y = k;
end Constant;

block FractConstant  "Generate constant signal in part from 1"
parameter Real k(start = 1, final unit = "%") "Part in percent";
Physiolibrary.Interfaces.RealOutput_ y(final unit = "1") "Connector of Real output signal";
equation
y = k / 100;
end FractConstant;

block Fract2Constant  "Generate constant signal y as part on interval <0,1> and signal 1-y"
parameter Real k(start = 1, final unit = "%") "Part in percent";
Physiolibrary.Interfaces.RealOutput_ y(final unit = "1") "Connector of Real output signal";
Physiolibrary.Interfaces.RealOutput_ y2(final unit = "1") "Connector of Real output signal";
equation
y = k / 100;
y2 = 1 - y;
end Fract2Constant;

block PressureConstant  "Generate constant signal of type Pressure_mmHg"
parameter Real k(start = 1, final quantity = "Pressure", final unit = "mmHg") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Pressure", final unit = "mmHg") "Connector of Real output signal";
equation
y = k;
end PressureConstant;

block VolumeConstant  "Generate constant signal of type Volume_ml"
parameter Real k(start = 1, final quantity = "Volume", final unit = "ml") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Volume", final unit = "ml") "Connector of Real output signal";
equation
y = k;
end VolumeConstant;

block OsmolarityConstant  "Generate constant signal of type mOsm"
parameter Real k(start = 1, final quantity = "Osmolarity", final unit = "mOsm") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Osmolarity", final unit = "mOsm") "Connector of Real output signal";
equation
y = k;
end OsmolarityConstant;

block TemperatureConstant  "Generate constant signal of type temperature in Celsius degrees"
parameter Real k(start = 1, final quantity = "Temperature", final unit = "degC") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Temperature", final unit = "degC") "Connector of Real output signal";
equation
y = k;
end TemperatureConstant;

block FlowConstant  "Generate constant signal in units ml/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "ml/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "ml/min") "Connector of Real output signal";
equation
y = k;
end FlowConstant;

block ElectrolytesMassConstant  "Generate constant signal of type Mass_mEq"
parameter Real k(start = 1, final quantity = "Mass", final unit = "mEq") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Mass", final unit = "mEq") "Connector of Real output signal";
equation
y = k;
end ElectrolytesMassConstant;

block ComplianceConstant  "Generate constant signal in units ml/mmHg"
parameter Real k(start = 1, final quantity = "Compliance", final unit = "ml/mmHg") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Compliance", final unit = "ml/mmHg") "Connector of Real output signal";
equation
y = k;
end ComplianceConstant;

block CondConstant  "Generate constant signal in units (ml/min)/mmHg"
parameter Real k(start = 1, final quantity = "Conductance", final unit = "ml/(min.mmHg)") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Conductance", final unit = "ml/(min.mmHg)") "Connector of Real output signal";
equation
y = k;
end CondConstant;

block ElectrolytesConcentrationConstant_per_l  "Generate constant signal of type mEq/L"
parameter Real k(start = 1, final quantity = "Concentration", final unit = "mEq/l") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Concentration", final unit = "mEq/l") "Connector of Real output signal";
equation
y = k;
end ElectrolytesConcentrationConstant_per_l;

block ConcentrationConstant_pg_per_ml  "Generate constant signal in units pg/ml"
parameter Real k(start = 1, final quantity = "Concentration", final unit = "pg/ml") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Concentration", final unit = "pg/ml") "Connector of Real output signal";
equation
y = k;
end ConcentrationConstant_pg_per_ml;

block ConcentrationConstant_uU_per_ml  "Generate constant signal in units uU/ml"
parameter Real k(start = 1, final quantity = "Concentration", final unit = "uU/ml") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Concentration", final unit = "uU/ml") "Connector of Real output signal";
equation
y = k;
end ConcentrationConstant_uU_per_ml;

block MassFlowConstant  "Generate constant signal in units mg/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "mg/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "mg/min") "Connector of Real output signal";
equation
y = k;
end MassFlowConstant;

block ElectrolytesFlowConstant  "Generate constant signal of type Mass_mEq_per_min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "mEq/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "mEq/min") "Connector of Real output signal";
equation
y = k;
end ElectrolytesFlowConstant;

block HormoneFlowConstant_nG  "Generate constant signal in units nG/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "ng/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "ng/min") "Connector of Real output signal";
equation
y = k;
end HormoneFlowConstant_nG;

block HormoneFlowConstant_pmol  "Generate constant signal in units pmol/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "pmol/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "pmol/min") "Connector of Real output signal";
equation
y = k;
end HormoneFlowConstant_pmol;

block HormoneFlowConstant_uG  "Generate constant signal in units uG/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "ug/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "ug/min") "Connector of Real output signal";
equation
y = k;
end HormoneFlowConstant_uG;

block HormoneFlowConstant_GU  "Generate constant signal in units U/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "GU/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "GU/min") "Connector of Real output signal";
equation
y = k;
end HormoneFlowConstant_GU;

block CaloriesFlowConstant  "Generate constant signal of type Energy Flow in calories per minute"
parameter Real k(start = 1, final quantity = "Flow", final unit = "cal/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "Cal/min") "Connector of Real output signal";
equation
y = k;
end CaloriesFlowConstant;

block MassFlowConstant_kg  "Generate constant signal in units kg/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "kg/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "kg/min") "Connector of Real output signal";
equation
y = k;
end MassFlowConstant_kg;

block Min  "Pass through the smallest signal"
extends Modelica.Blocks.Interfaces.MISO;
equation
y = min(u);
end Min;

block HormoneFlowConstant_U  "Generate constant signal in units U/min"
parameter Real k(start = 1, final quantity = "Flow", final unit = "U/min") "Constant output value";
Physiolibrary.Interfaces.RealOutput_ y(final quantity = "Flow", final unit = "U/min") "Connector of Real output signal";
equation
y = k;
end HormoneFlowConstant_U;

model Integrator
extends Utilities.DynamicState;
parameter Real k = 1 "Integrator gain";
parameter Real y_start = 0 "Initial or guess value of output (= state)";
extends Interfaces.SISO(y(start = y_start));
equation
stateValue = y;
changePerMin = k * u * SecPerMin;
end Integrator;

block deprecated_HomotopyStrongComponentBreaker  "break the strong component in normalized signal with default value"
extends Physiolibrary.Interfaces.SISO;
parameter Real defaultValue = 1;
parameter Real defaultSlope = 0;
equation
y = homotopy(u, defaultValue + defaultSlope * (u - defaultValue));
end deprecated_HomotopyStrongComponentBreaker;
end Blocks;

package Curves  "Empirical Dependence of Two Variables"
model Curve
extends pavol_version.Curve;
parameter Boolean INVERSION = false "only for compatibility";
end Curve;

package pavol_version
function Spline
input Real[:] x;
input Real[:, 4] a;
input Real xVal;
output Real yVal;
protected
Integer index;
Integer n;
algorithm
if xVal <= x[1] then
yVal := xVal * a[1, 3] + a[1, 4];
else
n := size(x, 1);
if xVal >= x[n] then
yVal := xVal * a[n + 1, 3] + a[n + 1, 4];
else
index := 2;
while xVal > x[index] and index < n loop
index := index + 1;
end while;
yVal := ((a[index, 1] * xVal + a[index, 2]) * xVal + a[index, 3]) * xVal + a[index, 4];
end if;
end if;
end Spline;

function SplineCoeficients
input Real[:] x;
input Real[:] y;
input Real[:] slope;
output Real[size(x, 1) + 1, 4] a;
protected
Integer n;
Integer i;
Real x1;
Real x2;
Real y1;
Real y2;
Real slope1;
Real slope2;
algorithm
n := size(x, 1);
for i in 2:n loop
x1 := x[i - 1];
x2 := x[i];
y1 := y[i - 1];
y2 := y[i];
slope1 := slope[i - 1];
slope2 := slope[i];
a[i, 1] := -((-x2 * slope2) - x2 * slope1 + x1 * slope2 + x1 * slope1 + 2 * y2 - 2 * y1) / (x2 - x1) ^ 3;
a[i, 2] := ((-x2 ^ 2 * slope2) - 2 * x2 ^ 2 * slope1 - 3 * x2 * y1 + x2 * slope1 * x1 + 3 * x2 * y2 - x2 * slope2 * x1 - 3 * y1 * x1 + slope1 * x1 ^ 2 + 3 * y2 * x1 + 2 * slope2 * x1 ^ 2) / (x2 - x1) ^ 3;
a[i, 3] := -((-slope1 * x2 ^ 3) - 2 * x2 ^ 2 * slope2 * x1 - x2 ^ 2 * slope1 * x1 + x2 * slope2 * x1 ^ 2 + 2 * x2 * slope1 * x1 ^ 2 + 6 * x2 * x1 * y2 - 6 * x2 * x1 * y1 + slope2 * x1 ^ 3) / (x2 - x1) ^ 3;
a[i, 4] := ((-slope1 * x2 ^ 3 * x1) + y1 * x2 ^ 3 - slope2 * x1 ^ 2 * x2 ^ 2 + slope1 * x1 ^ 2 * x2 ^ 2 - 3 * y1 * x2 ^ 2 * x1 + 3 * y2 * x1 ^ 2 * x2 + slope2 * x1 ^ 3 * x2 - y2 * x1 ^ 3) / (x2 - x1) ^ 3;
end for;
a[1, :] := {0, 0, slope[1], y[1] - x[1] * slope[1]};
a[n + 1, :] := {0, 0, slope[n], y[n] - x[n] * slope[n]};
end SplineCoeficients;

model Curve  "2D natural cubic interpolation spline defined with (x,y,slope) points"
parameter Real[:] x;
parameter Real[:] y;
parameter Real[:] slope;
parameter Integer iFrom = 0;
Physiolibrary.Interfaces.RealInput_ u;
Physiolibrary.Interfaces.RealOutput_ val;
protected
parameter Real[:, :] a = Physiolibrary.Curves.pavol_version.SplineCoeficients(x, y, slope);
equation
val = Physiolibrary.Curves.pavol_version.Spline(x, a, u);
end Curve;
end pavol_version;
end Curves;

package Factors  "Multiplication Effect Types"
model SimpleMultiply  "multiplication"
extends Physiolibrary.Interfaces.BaseFactorIcon;
Physiolibrary.Interfaces.RealInput_ u;
Modelica.Blocks.Math.Product product;
Real effect;
equation
effect = u;
connect(yBase, product.u1);
connect(product.y, y);
connect(u, product.u2);
end SimpleMultiply;

model CurveValue  "calculate multiplication factor from function defined by curve"
extends Physiolibrary.Interfaces.BaseFactorIcon4;
Physiolibrary.Interfaces.RealInput_ u;
parameter Real[:, 3] data;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Real effect;
equation
effect = curve.val;
connect(curve.u, u);
connect(yBase, product.u1);
connect(curve.val, product.u2);
connect(product.y, y);
end CurveValue;

model DelayedToSpline  "adapt the signal, from which is by curve multiplication coeficient calculated"
extends Physiolibrary.Interfaces.BaseFactorIcon5;
Physiolibrary.Interfaces.RealInput_ u;
parameter Real Tau = 40;
parameter Real initialValue = 1;
parameter Real[:, 3] data;
parameter String adaptationSignalName;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Blocks.Integrator integrator(k = 1 / Tau / SecPerMin, y_start = initialValue, stateName = adaptationSignalName);
Modelica.Blocks.Math.Feedback feedback;
Real effect;
equation
effect = curve.val;
connect(yBase, product.u1);
connect(product.y, y);
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(feedback.u1, u);
connect(integrator.y, curve.u);
connect(curve.val, product.u2);
end DelayedToSpline;

model SplineDelayByDay  "adapt the value of multiplication coeficient calculated from curve"
extends Physiolibrary.Interfaces.BaseFactorIcon3;
Physiolibrary.Interfaces.RealInput_ u;
parameter Real Tau;
parameter Real[:, 3] data;
parameter String stateName;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Blocks.Integrator integrator(y_start = 1, k = 1 / (Tau * 1440) / SecPerMin, stateName = stateName);
Modelica.Blocks.Math.Feedback feedback;
Real effect;
equation
effect = integrator.y;
connect(curve.u, u);
connect(yBase, product.u1);
connect(product.y, y);
connect(curve.val, feedback.u1);
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(integrator.y, product.u2);
end SplineDelayByDay;

model SplineDelayFactorByDayWithFailture  "combination of SplineDelayByDay and ZeroIfFalse"
extends Physiolibrary.Interfaces.BaseFactorIcon2;
Physiolibrary.Interfaces.RealInput_ u;
parameter Real Tau;
parameter Real[:, 3] data;
parameter String stateName;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Blocks.Integrator integrator(y_start = 1, k = 1 / (Tau * 1440) / SecPerMin, stateName = stateName);
Modelica.Blocks.Math.Feedback feedback;
Modelica.Blocks.Logical.Switch switch1;
Physiolibrary.Blocks.Constant Constant1(k = 0);
Physiolibrary.Interfaces.BooleanInput Failed;
Real effect;
equation
effect = integrator.y;
connect(curve.u, u);
connect(yBase, product.u1);
connect(product.y, y);
connect(feedback.y, integrator.u);
connect(integrator.y, feedback.u2);
connect(integrator.y, product.u2);
connect(switch1.y, feedback.u1);
connect(curve.val, switch1.u3);
connect(Constant1.y, switch1.u1);
connect(switch1.u2, Failed);
end SplineDelayFactorByDayWithFailture;

model SplineValue2  "calculate multiplication factor from spline value"
extends Physiolibrary.Interfaces.BaseFactorIcon4;
Physiolibrary.Interfaces.RealInput_ u;
parameter Boolean INVERSE = false;
parameter Real[:, 3] data;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Real effect;
equation
effect = curve.val;
connect(curve.u, u);
connect(yBase, product.u1);
connect(curve.val, product.u2);
connect(product.y, y);
end SplineValue2;

model CurveValueWithLinearSimplificationByHomotopy  "calculate multiplication factor from function defined by curve"
extends Physiolibrary.Interfaces.BaseFactorIcon4;
Physiolibrary.Interfaces.RealInput_ u;
parameter Real defaultU = 0;
parameter Real defaultSlope = 0;
parameter Real defaultValue = 1;
parameter Real[:, 3] data;
Physiolibrary.Curves.Curve curve(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Modelica.Blocks.Math.Product product;
Real effect;
equation
effect = homotopy(curve.val, defaultSlope * (u - defaultU) + defaultValue);
product.u2 = effect;
connect(curve.u, u);
connect(yBase, product.u1);
connect(product.y, y);
end CurveValueWithLinearSimplificationByHomotopy;
end Factors;

package ConcentrationFlow  "Concentration Physical Domain"
replaceable type Concentration = Real(final quantity = "Concentration");
replaceable type SoluteFlow = Real(final quantity = "Flow");
replaceable type SoluteMass = Real(final quantity = "Mass");

connector ConcentrationFlow  "Concentration and Solute flow"
Concentration conc;
flow SoluteFlow q;
end ConcentrationFlow;

connector PositiveConcentrationFlow  "Concentration and Solute inflow"
extends Physiolibrary.ConcentrationFlow.ConcentrationFlow;
end PositiveConcentrationFlow;

connector NegativeConcentrationFlow  "Concentration and negative Solute outflow"
extends Physiolibrary.ConcentrationFlow.ConcentrationFlow;
end NegativeConcentrationFlow;

model FlowMeasure
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualFlow;
equation
q_in.q + q_out.q = 0;
q_out.conc = q_in.conc;
actualFlow = q_in.q;
end FlowMeasure;

model ConcentrationMeasure
parameter String unitsString = "";
parameter Real toAnotherUnitCoef = 1;
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualConc;
equation
actualConc = toAnotherUnitCoef * q_in.conc;
q_in.q = 0;
end ConcentrationMeasure;

partial model ResistorBase
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
end ResistorBase;

partial model Resistor
extends ResistorBase;
equation
q_in.q + q_out.q = 0;
end Resistor;

model ResistorWithCondParam
extends Resistor;
parameter Real cond "speed of solute in dependence on concentration gradient";
equation
q_in.q = cond * (q_in.conc - q_out.conc);
end ResistorWithCondParam;

model SolventFlowPump
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "second side connector with value of q (solute mass flow) and conc (concentration)" annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ solventFlow "solvent flow (solution volume flow = solventFlow + solute volume flow)" annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "first side connector with value of q (solute mass flow) and conc (concentration)";
equation
q_in.q + q_out.q = 0;
q_in.q = if initial() or solventFlow >= 0 then solventFlow * q_in.conc else solventFlow * q_out.conc;
end SolventFlowPump;

model SolventOutflowPump
Physiolibrary.Interfaces.RealInput solventFlow "solvent outflow" annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "solute outflow";
parameter Real K = 1 "part of real mass flow in solution outflow";
equation
q_in.q = K * solventFlow * q_in.conc;
end SolventOutflowPump;

model Synthesis
parameter SoluteFlow SynthesisBasic = 0.01;
parameter Real[:, 3] data = {{20.0, 3.0, 0.0}, {28.0, 1.0, -0.2}, {40.0, 0.0, 0.0}} "COPEffect";
Physiolibrary.Curves.Curve c(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Real COP;
SoluteMass synthetized(start = 0);
protected
parameter Real C1 = 320.0;
parameter Real C2 = 1160.0;
equation
COP = if q_out.conc > 0.0 then C1 * q_out.conc + C2 * q_out.conc * q_out.conc else 0.0;
c.u = COP;
q_out.q = -SynthesisBasic * c.val;
der(synthetized) = -q_out.q / SecPerMin;
end Synthesis;

model Degradation
parameter SoluteFlow DegradationBasic = 0.01;
parameter Real[:, 3] data = {{0.0, 0.0, 0.0}, {0.07000000000000001, 1.0, 40.0}, {0.09, 6.0, 0.0}} "ProteinEffect";
Physiolibrary.Curves.Curve c(x = data[:, 1], y = data[:, 2], slope = data[:, 3]);
PositiveConcentrationFlow q_in;
SoluteMass degraded(start = 0);
equation
c.u = q_in.conc;
q_in.q = DegradationBasic * c.val;
der(degraded) = q_in.q / SecPerMin;
end Degradation;

model InputPump
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow "speed of solute flow" annotation(extent = [-10, 30; 10, 50], rotation = -90);
equation
q_out.q = -desiredFlow;
end InputPump;

model OutputPump
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow annotation(extent = [-10, 30; 10, 50], rotation = -90);
equation
q_in.q = desiredFlow;
end OutputPump;

model SoluteFlowPump
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput soluteFlow annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
equation
q_in.q + q_out.q = 0;
q_in.q = soluteFlow;
end SoluteFlowPump;

model PartialPressure  "partial gas concentration in ml/ml multiplied by ambient pressure"
PressureFlow.NegativePressureFlow outflow;
PositiveConcentrationFlow q_in;
Interfaces.RealInput_ ambientPressure(final unit = "mmHg");
equation
q_in.q + outflow.q = 0;
outflow.pressure = q_in.conc * ambientPressure;
end PartialPressure;

model Dilution
NegativeConcentrationFlow q_diluted annotation(extent = [-10, -110; 10, -90]);
PositiveConcentrationFlow q_concentrated;
Interfaces.RealInput_ dilution "dilution = one minus (part of added solvent volume(not containing solute) normalized to whole summed volume)";
equation
q_diluted.q + q_concentrated.q = 0;
q_diluted.conc = dilution * q_concentrated.conc;
end Dilution;

model Reabsorbtion
PositiveConcentrationFlow Inflow;
NegativeConcentrationFlow Outflow;
NegativeConcentrationFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ ReabsorbedFract(final unit = "1");
equation
Outflow.q + Inflow.q + Reabsorbtion.q = 0;
Outflow.conc = Inflow.conc;
Reabsorbtion.q = -ReabsorbedFract * Inflow.q;
end Reabsorbtion;

model FractReabsorbtion
PositiveConcentrationFlow Inflow;
NegativeConcentrationFlow Outflow;
NegativeConcentrationFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ Normal(final unit = "1");
Physiolibrary.Interfaces.RealInput_ Effects(final unit = "1");
parameter SoluteFlow MaxReab = 14 "maximum reabsorbtion solute flow";
Interfaces.RealOutput_ ReabFract(final unit = "1");
equation
Outflow.q + Inflow.q + Reabsorbtion.q = 0;
Outflow.conc = Inflow.conc;
Reabsorbtion.q = -min(ReabFract * Inflow.q, MaxReab);
ReabFract = if Normal <= 0 or Effects <= 0 then 0 else if Normal > 1 then 1 else Normal ^ (1 / Effects);
end FractReabsorbtion;

model FractReabsorbtion2
PositiveConcentrationFlow Inflow;
NegativeConcentrationFlow Outflow;
NegativeConcentrationFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ Normal(final unit = "1");
Physiolibrary.Interfaces.RealInput_ Effects(final unit = "1");
Real ReabFract(final unit = "1");
Physiolibrary.Interfaces.RealInput_ MaxReab;
equation
Outflow.q + Inflow.q + Reabsorbtion.q = 0;
Outflow.conc = Inflow.conc;
Reabsorbtion.q = -min(ReabFract * Inflow.q, MaxReab);
ReabFract = if Normal <= 0 or Effects <= 0 then 0 else if Normal > 1 then 1 else Normal ^ (1 / Effects);
end FractReabsorbtion2;

model ConstLimitedReabsorbtion
PositiveConcentrationFlow Inflow;
NegativeConcentrationFlow Outflow;
NegativeConcentrationFlow Reabsorbtion;
parameter SoluteFlow MaxReab = 250 "maximum reabsorbtion solute flow";
equation
Outflow.q + Inflow.q + Reabsorbtion.q = 0;
Outflow.conc = Inflow.conc;
Reabsorbtion.q = -min(Inflow.q, MaxReab);
end ConstLimitedReabsorbtion;

model FlowConcentrationMeasure
PositiveConcentrationFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ SolventFlow(final quantity = "Flow", final unit = "ml/min") annotation(extent = [-10, 50; 10, 70], rotation = -90);
Interfaces.RealInput_ AdditionalSoluteFlow;
Interfaces.RealOutput_ Conc;
equation
Conc = q_in.conc + AdditionalSoluteFlow / SolventFlow;
q_in.q = 0;
end FlowConcentrationMeasure;

model SimpleReaction
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ coef "who much units of q_out produce one unit of q_in" annotation(extent = [-10, 30; 10, 50], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
equation
q_out.q + coef * q_in.q = 0;
q_out.conc = coef * q_in.conc;
end SimpleReaction;

model SimpleReaction2
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ coef "who much units of q_out produce one unit of q_in" annotation(extent = [-10, 30; 10, 50], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out2 annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ coef2 "who much units of q_out2 produce one unit of q_in";
equation
q_out.q + coef * q_in.q = 0;
q_out2.q + coef2 * q_in.q = 0;
q_out.conc = coef * q_in.conc;
end SimpleReaction2;

model UnlimitedStorage
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
parameter Real concentration(final unit = "%");
equation
q_out.conc = 0.01 * concentration;
end UnlimitedStorage;

model ConcentrationCompartment
extends Physiolibrary.Utilities.DynamicState;
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
parameter Real initialSoluteMass;
Physiolibrary.Interfaces.RealInput_ SolventVolume(final quantity = "Volume", final unit = "ml");
Physiolibrary.Interfaces.RealOutput_ soluteMass(start = initialSoluteMass);
equation
q_out.conc = if SolventVolume > 0 then soluteMass / SolventVolume else 0;
stateValue = soluteMass;
changePerMin = q_out.q;
end ConcentrationCompartment;

model MassStorageCompartment
extends Physiolibrary.Utilities.DynamicState;
parameter Real MINUTE_FLOW_TO_MASS_CONVERSION = 1 "this constant will multiply the flow inside integration to mass";
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out;
parameter SoluteMass initialSoluteMass;
Physiolibrary.Interfaces.RealOutput_ soluteMass(start = initialSoluteMass);
equation
q_out.conc = soluteMass;
stateValue = soluteMass;
changePerMin = q_out.q * MINUTE_FLOW_TO_MASS_CONVERSION;
end MassStorageCompartment;

model SolventFlowPump_InitialPatch
Physiolibrary.ConcentrationFlow.NegativeConcentrationFlow q_out "second side connector with value of q (solute mass flow) and conc (concentration)" annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ solventFlow "solvent flow (solution volume flow = solventFlow + solute volume flow)" annotation(extent = [-10, 50; 10, 70], rotation = -90);
Physiolibrary.ConcentrationFlow.PositiveConcentrationFlow q_in "first side connector with value of q (solute mass flow) and conc (concentration)";
equation
q_in.q + q_out.q = 0;
q_in.q = solventFlow * q_in.conc;
end SolventFlowPump_InitialPatch;
end ConcentrationFlow;

package HeatFlow  "Temperature Physical Domain"
connector HeatFlowConnector  "Heat flow connector"
Real T(final unit = "K") "temperature";
flow Real q(final unit = "kCal/min") "heat flow";
end HeatFlowConnector;

connector PositiveHeatFlow  "Heat inflow"
extends Physiolibrary.HeatFlow.HeatFlowConnector;
end PositiveHeatFlow;

connector NegativeHeatFlow  "Heat outflow"
extends Physiolibrary.HeatFlow.HeatFlowConnector;
annotation(Coordsys(extent = [-100, -100; 100, 100], grid = [1, 1], component = [20, 20], scale = 0.2));
end NegativeHeatFlow;

partial model ResistorBase
PositiveHeatFlow q_in annotation(extent = [-10, -110; 10, -90]);
NegativeHeatFlow q_out annotation(extent = [-10, -110; 10, -90]);
end ResistorBase;

partial model Resistor
extends ResistorBase;
equation
q_in.q + q_out.q = 0;
end Resistor;

model ResistorWithCond
extends Resistor;
Physiolibrary.Interfaces.RealInput_ cond(final quantity = "Conductance", final unit = "kCal/(min.K)") annotation(extent = [-5, 30; 5, 50], rotation = -90);
equation
q_in.q = cond * (q_in.T - q_out.T);
end ResistorWithCond;

model ResistorWithCondParam
extends Resistor;
parameter Real cond;
equation
q_in.q = cond * (q_in.T - q_out.T);
end ResistorWithCondParam;

model HeatFlux  "flow circuit through mass with different temperature"
NegativeHeatFlow q_out "surrounding mass" annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ substanceFlow(final unit = "kg/min") "flowing speed in circuit" annotation(extent = [-10, 50; 10, 70], rotation = -90);
PositiveHeatFlow q_in "flow circuit";
parameter Real specificHeat(unit = "kCal/kg/K") "of flow circuit medium";
equation
q_in.q + q_out.q = 0;
q_in.q = substanceFlow * (q_in.T - q_out.T) * specificHeat;
end HeatFlux;

model HeatOutflow  "heat outflow through vaporization and outflowing heatted steam"
Interfaces.RealInput_ liquidOutflow(final unit = "kg/min") "speed of vaporization" annotation(extent = [-10, 50; 10, 70], rotation = -90);
PositiveHeatFlow q_in "flow circuit";
parameter Real TempToolsVapor(final unit = "kCal/kg") = 580.0 "needed heat to vaporization";
parameter Real specificHeat(final unit = "kCal/kg/K") = 1 "of liquid";
equation
q_in.q = liquidOutflow * (q_in.T * specificHeat + TempToolsVapor);
end HeatOutflow;

model InputPump
NegativeHeatFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow "speed of heat flow" annotation(extent = [-10, 30; 10, 50], rotation = -90);
equation
q_out.q = -desiredFlow;
end InputPump;

model HeatAccumulation  "accumulating heat to substance mass with specific heat constant"
extends Physiolibrary.Utilities.DynamicState;
extends Interfaces.BaseModel;
PositiveHeatFlow q_in "heat inflow/outflow connector";
parameter Real initialHeatMass "=weight[kg]*initialTemperature[K]*(specificHeat[kCal/kg/K])";
parameter Real specificHeat(final unit = "kCal/kg/K") = 1 "of the mass, where the heat are accumulated";
Real heatMass(start = initialHeatMass, final unit = "kCal") "accumulated heat";
Real T_degC(final unit = "degC") "temperature in celsius degrees";
Interfaces.RealInput_ weight(final unit = "kg") "weight of mass, where the heat are accumulated";
Interfaces.RealOutput_ T(unit = "degC");
equation
q_in.T = heatMass / (weight * specificHeat);
T_degC = q_in.T - 273.15;
T = T_degC;
stateValue = heatMass;
changePerMin = q_in.q;
end HeatAccumulation;

model AmbientTemperature  "constant temperature, undefinned heat flow"
extends Interfaces.BaseModel;
PositiveHeatFlow q_in "heat inflow/outflow connector";
parameter Real Temperature(final unit = "K") = 295.37 "to calculate initial heat";
Real T_degC(final unit = "degC") "temperature in celsius degrees";
equation
q_in.T = Temperature;
T_degC = q_in.T - 273.15;
end AmbientTemperature;

model Pump
NegativeHeatFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow(unit = "ml/min") "speed of liquid flow" annotation(extent = [-10, 30; 10, 50], rotation = -90);
PositiveHeatFlow q_in;
parameter Real specificHeat(unit = "kCal/ml/K") "of flow circuit medium";
equation
q_in.q + q_out.q = 0;
q_in.q = specificHeat * q_in.T * desiredFlow;
end Pump;

model OutputPump
Physiolibrary.Interfaces.RealInput_ desiredFlow(unit = "ml/min") "speed of liquid flow" annotation(extent = [-10, 30; 10, 50], rotation = -90);
PositiveHeatFlow q_in;
parameter Real specificHeat(unit = "kCal/ml/K") "of flow circuit medium";
equation
q_in.q = specificHeat * q_in.T * desiredFlow;
end OutputPump;
end HeatFlow;

package PressureFlow  "Hydraulic Physical Domain"
connector PressureFlow  "Pressure[mmHg] and Flow[ml/min]"
Real pressure(final quantity = "Pressure", final unit = "mmHg");
flow Real q(final quantity = "Flow", final unit = "ml/min") "flow";
end PressureFlow;

connector PositivePressureFlow  "Pressure[mmHg] and Inflow[ml/min]"
extends PressureFlow;
end PositivePressureFlow;

connector NegativePressureFlow  "Pressure[mmHg] and negative Outflow[ml/min]"
extends PressureFlow;
end NegativePressureFlow;

model FlowMeasure  "Convert connector volume flow value to signal flow value"
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
PositivePressureFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualFlow(final quantity = "Flow", final unit = "ml/min");
equation
q_in.q + q_out.q = 0;
q_out.pressure = q_in.pressure;
actualFlow = q_in.q;
end FlowMeasure;

model PressureMeasure  "Convert connector hydraulic pressure value to signal flow value"
Physiolibrary.PressureFlow.PositivePressureFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualPressure;
equation
actualPressure = q_in.pressure;
q_in.q = 0;
end PressureMeasure;

partial model ResistorBase  "Hydraulic Volume Flow Resistance"
PositivePressureFlow q_in annotation(extent = [-10, -110; 10, -90]);
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
end ResistorBase;

partial model ResistorBase2  "Hydraulic Volume Flow Resistance"
PositivePressureFlow q_in annotation(extent = [-10, -110; 10, -90]);
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
Real ActualConductance;
equation
ActualConductance = if abs(q_in.pressure - q_out.pressure) < Modelica.Constants.small then 0 else q_in.q / (q_in.pressure - q_out.pressure);
end ResistorBase2;

partial model Resistor
extends ResistorBase;
equation
q_in.q + q_out.q = 0;
end Resistor;

model ResistorWithCond
extends Resistor;
Physiolibrary.Interfaces.RealInput_ cond(final quantity = "Conductance", final unit = "ml/(min.mmHg)") annotation(extent = [-5, 30; 5, 50], rotation = -90);
equation
q_in.q = cond * (q_in.pressure - q_out.pressure);
end ResistorWithCond;

model ResistorWithCondParam
extends Resistor;
parameter Real cond(final quantity = "Conductance", final unit = "ml/(min.mmHg)");
equation
q_in.q = cond * (q_in.pressure - q_out.pressure);
end ResistorWithCondParam;

model PumpBase  "Defined flow to/from/in system by real signal"
Interfaces.RealInput_ desiredFlow(quantity = "Flow", unit = "ml/min") "desired volume flow value";
end PumpBase;

model InputPump
extends PumpBase;
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
equation
q_out.q = -desiredFlow;
end InputPump;

model OutputPump
extends PumpBase;
PositivePressureFlow q_in annotation(extent = [-10, -110; 10, -90]);
equation
q_in.q = desiredFlow;
end OutputPump;

model Pump
extends PumpBase;
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
PositivePressureFlow q_in;
equation
q_in.q + q_out.q = 0;
q_in.q = desiredFlow;
end Pump;

model PressurePumpBase  "Defined pressure to/from/in system by real signal"
Interfaces.RealInput_ desiredPressure(quantity = "Pressure", unit = "mmHg") "desired pressure flow value";
end PressurePumpBase;

model InputPressurePump
extends PressurePumpBase;
NegativePressureFlow p_out annotation(extent = [-10, -110; 10, -90]);
equation
p_out.pressure = desiredPressure;
end InputPressurePump;

model OutputPressurePump
extends PressurePumpBase;
PositivePressureFlow p_in annotation(extent = [-10, -110; 10, -90]);
equation
p_in.pressure = desiredPressure;
end OutputPressurePump;

model ReabsorbtionWithMinimalOutflow  "Divide inflow to outflow and reabsorbtion if it is under defined treshold"
PositivePressureFlow Inflow;
NegativePressureFlow Outflow;
NegativePressureFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ FractReab;
Physiolibrary.Interfaces.RealInput_ OutflowMin(final quantity = "Flow", final unit = "ml/min");
FlowMeasure flowMeasure;
Factors.SimpleMultiply simpleMultiply;
Pump reabsorbtion;
Pump MinimalFlow;
FlowMeasure flowMeasure1;
Modelica.Blocks.Math.Min min;
equation
connect(flowMeasure.actualFlow, simpleMultiply.yBase);
connect(simpleMultiply.u, FractReab);
connect(reabsorbtion.q_out, Reabsorbtion);
connect(simpleMultiply.y, reabsorbtion.desiredFlow);
connect(flowMeasure.q_out, Outflow);
connect(flowMeasure.q_out, reabsorbtion.q_in);
connect(Inflow, flowMeasure1.q_in);
connect(flowMeasure1.q_out, flowMeasure.q_in);
connect(flowMeasure1.q_out, MinimalFlow.q_in);
connect(MinimalFlow.q_out, Outflow);
connect(OutflowMin, min.u1);
connect(flowMeasure1.actualFlow, min.u2);
connect(min.y, MinimalFlow.desiredFlow);
end ReabsorbtionWithMinimalOutflow;

model Reabsorbtion  "Divide inflow to outflow and reabsorbtion"
PositivePressureFlow Inflow;
NegativePressureFlow Outflow;
NegativePressureFlow Reabsorbtion;
Physiolibrary.Interfaces.RealInput_ FractReab;
FlowMeasure flowMeasure;
Factors.SimpleMultiply simpleMultiply;
Pump pump;
equation
connect(Inflow, flowMeasure.q_in);
connect(flowMeasure.actualFlow, simpleMultiply.yBase);
connect(simpleMultiply.u, FractReab);
connect(pump.q_out, Reabsorbtion);
connect(simpleMultiply.y, pump.desiredFlow);
connect(flowMeasure.q_out, Outflow);
connect(flowMeasure.q_out, pump.q_in);
end Reabsorbtion;

model GravityHydrostaticDifferenceWithPumpEffect  "Create hydrostatic pressure between connectors in different altitude with specific pressure pump effect"
PositivePressureFlow q_up annotation(extent = [-10, -110; 10, -90]);
PositivePressureFlow q_down annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ height(final unit = "cm");
parameter Real ro(final unit = "kg/m3") = 1060;
Interfaces.RealInput_ pumpEffect;
Interfaces.RealInput_ G(final unit = "m/(s.s)");
equation
q_down.pressure = q_up.pressure + G * ro * height / 100 * 760 / 101325 * pumpEffect;
q_up.q + q_down.q = 0;
end GravityHydrostaticDifferenceWithPumpEffect;

model GravityHydrostaticDifference  "Create hydrostatic pressure between connectors in different altitude"
PositivePressureFlow q_up annotation(extent = [-10, -110; 10, -90]);
PositivePressureFlow q_down annotation(extent = [-10, -110; 10, -90]);
Interfaces.RealInput_ height(final unit = "cm");
parameter Real ro(final unit = "kg/m3") = 1060;
Interfaces.RealInput_ G(final unit = "m/(s.s)");
equation
q_down.pressure = q_up.pressure + G * ro * height / 100 * 760 / 101325;
q_up.q + q_down.q = 0;
end GravityHydrostaticDifference;

model VolumeCompartement  "Generate constant pressure independ on inflow or outflow"
extends Physiolibrary.Utilities.DynamicState;
parameter Real pressure = 0;
PositivePressureFlow con;
parameter Real initialVolume;
Interfaces.RealOutput_ Volume(start = initialVolume);
equation
if Volume > 0 or con.q > 0 then
con.pressure = pressure;
else
con.q = 0;
end if;
stateValue = Volume;
changePerMin = con.q;
annotation(Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid));
end VolumeCompartement;

model PressureControledCompartment  "Multiple PressureFlow connector with pressures from multiple inputs"
extends Interfaces.BaseModel;
extends Physiolibrary.Utilities.DynamicState;
Interfaces.RealInput_ pressure(final quantity = "Pressure", final unit = "mmHg") "Pressure value input signal";
PositivePressureFlow y "PressureFlow output connectors";
parameter Real initialVolume;
Interfaces.RealOutput_ Volume(start = initialVolume, final quantity = "Volume", final unit = "ml");
equation
y.pressure = pressure;
stateValue = Volume;
changePerMin = y.q;
end PressureControledCompartment;

model Gas_FromMLtoMMOL  "ideal gas conversion of flow units from ml to mmol, in connector should be absolute partial pressure of calculated gas"
PositivePressureFlow q_ML "flow in ml";
NegativePressureFlow q_MMOL "flow in mmol";
parameter Real Temp(unit = "K") = 273.15;
parameter Real P(unit = "mmHg") = 760;
Interfaces.RealInput_ T;
equation
q_ML.q * P * 101.325 / 760 / Temp / Modelica.Constants.R + q_MMOL.q = 0;
q_ML.pressure = q_MMOL.pressure;
end Gas_FromMLtoMMOL;

model ResistorWith2Cond
Interfaces.RealInput_ cond1(quantity = "Flow", unit = "ml/min") "desired volume flow value";
Interfaces.RealInput_ cond2(quantity = "Flow", unit = "ml/min") "desired volume flow value";
PositivePressureFlow q_in;
NegativePressureFlow q_out annotation(extent = [-10, -110; 10, -90]);
equation
q_in.q + q_out.q = 0;
q_in.q = cond1 * cond2 / (cond1 + cond2) * (q_in.pressure - q_out.pressure);
end ResistorWith2Cond;
end PressureFlow;

package Semipermeable  "Osmotic Physical Domain"
connector OsmoticFlow  "H2O flow throught semipermeable membrane by osmotic pressure gradient"
Real o(quantity = "Osmolarity", unit = "mOsm");
flow Real q(quantity = "Flow", unit = "ml/min");
end OsmoticFlow;

connector PositiveOsmoticFlow  "H2O inflow"
extends OsmoticFlow;
end PositiveOsmoticFlow;

connector NegativeOsmoticFlow  "H2O outflow"
extends OsmoticFlow;
end NegativeOsmoticFlow;

model FlowMeasure
NegativeOsmoticFlow q_out annotation(extent = [-10, -110; 10, -90]);
PositiveOsmoticFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualFlow(final quantity = "Flow", final unit = "ml/min");
equation
q_in.q + q_out.q = 0;
q_out.o = q_in.o;
actualFlow = q_in.q;
end FlowMeasure;

partial model ResistorBase  "semipermeable membrane"
PositiveOsmoticFlow q_in annotation(extent = [-10, -110; 10, -90]);
NegativeOsmoticFlow q_out annotation(extent = [-10, -110; 10, -90]);
end ResistorBase;

partial model Resistor
extends ResistorBase;
equation
q_in.q + q_out.q = 0;
end Resistor;

model ResistorWithCondParam
extends Resistor;
parameter Real cond "H2O membrane permeability";
equation
q_in.q = cond * (q_out.o - q_in.o);
end ResistorWithCondParam;

model InputPump
NegativeOsmoticFlow q_out annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow "pure H2O inflow" annotation(extent = [-10, 30; 10, 50], rotation = -90);
equation
q_out.q = -desiredFlow;
end InputPump;

model OutputPump
PositiveOsmoticFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow annotation(extent = [-10, 30; 10, 50], rotation = -90);
equation
q_in.q = desiredFlow;
end OutputPump;

model ColloidOsmolarity  "set osmolarity from protein mass flow"
extends Interfaces.ConversionIcon;
Interfaces.RealInput_ proteinMassFlow(unit = "g/min");
PressureFlow.PositivePressureFlow q_in "hydraulic pressure";
NegativeOsmoticFlow q_out(o(final unit = "g/ml")) "colloid osmotic pressure";
parameter Real C1 = 320.0;
parameter Real C2 = 1160.0;
Interfaces.RealOutput_ P;
equation
q_in.q + q_out.q = 0;
q_out.o = abs(proteinMassFlow / q_in.q);
P = q_in.pressure;
end ColloidOsmolarity;

model ColloidHydraulicPressure  "set pressure as sum of osmotic pressure(from osmoles) and hydrostatic/hydrodynamic pressure(from signal)"
extends Interfaces.ConversionIcon;
Interfaces.RealInput_ hydraulicPressure(unit = "mmHg");
PressureFlow.NegativePressureFlow q_out "pressure on semipermeable membrane wall = osmotic + hydrostatic";
PositiveOsmoticFlow q_in(o(unit = "g")) "osmoles";
parameter Real C1 = 320.0;
parameter Real C2 = 1160.0;
equation
q_in.q + q_out.q = 0;
q_out.pressure = hydraulicPressure - (C1 * q_in.o + C2 * q_in.o ^ 2);
end ColloidHydraulicPressure;

model ColloidHydraulicPressure0
extends Interfaces.ConversionIcon;
Interfaces.RealInput_ hydraulicPressure(unit = "mmHg");
PositiveOsmoticFlow q_in(o(unit = "g")) "osmoles";
parameter Real C1 = 320.0;
parameter Real C2 = 1160.0;
PressureFlow.NegativePressureFlow withoutCOP "only hydrostatic pressure without colloid osmotic pressure";
equation
q_in.q + withoutCOP.q = 0;
withoutCOP.pressure = hydraulicPressure;
end ColloidHydraulicPressure0;

model WaterColloidOsmoticCompartment
extends Physiolibrary.Utilities.DynamicState;
NegativeOsmoticFlow q_out(o(final unit = "g/ml"));
parameter Real initialWaterVolume(final quantity = "Volume", unit = "ml");
Physiolibrary.Interfaces.RealInput_ NotpermeableSolutes(quantity = "Mass", unit = "g");
Physiolibrary.Interfaces.RealOutput_ WaterVolume(start = initialWaterVolume, final quantity = "Volume", unit = "ml");
equation
q_out.o = if WaterVolume > 0 then NotpermeableSolutes / WaterVolume else 0;
changePerMin = q_out.q;
stateValue = WaterVolume;
end WaterColloidOsmoticCompartment;

model OsmoticPump
extends OsmoticPumpBase;
PositiveOsmoticFlow q_in;
NegativeOsmoticFlow q_out;
equation
q_in.q + q_out.q = 0;
q_in.o = desiredOsmoles;
end OsmoticPump;

model OsmoticPumpBase  "Defined osmoles to/from/in system by real signal"
Interfaces.RealInput_ desiredOsmoles(quantity = "Osmolarity", unit = "mOsm") "desired pressure flow value";
end OsmoticPumpBase;

model Pump
PositiveOsmoticFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput_ desiredFlow annotation(extent = [-10, 30; 10, 50], rotation = -90);
NegativeOsmoticFlow q_out;
equation
q_in.q + q_out.q = 0;
q_in.q = desiredFlow;
end Pump;
end Semipermeable;

package VolumeFlow  "Volume and Volume Flow domains"
connector VolumeFlow
Real volume(final quantity = "Volume", final unit = "ml");
flow Real q(final quantity = "Flow", final unit = "ml/min");
end VolumeFlow;

connector PositiveVolumeFlow
extends VolumeFlow;
annotation(Coordsys(extent = [-100, -100; 100, 100], grid = [1, 1], component = [20, 20], scale = 0.2));
end PositiveVolumeFlow;

connector NegativeVolumeFlow
extends VolumeFlow;
annotation(Coordsys(extent = [-100, -100; 100, 100], grid = [1, 1], component = [20, 20], scale = 0.2));
end NegativeVolumeFlow;

model VolumeMeasure
PositiveVolumeFlow q_in;
Physiolibrary.Interfaces.RealOutput_ actualVolume;
equation
q_in.q = 0;
actualVolume = q_in.volume;
end VolumeMeasure;

model OutputPump
PositiveVolumeFlow q_in annotation(extent = [-10, -110; 10, -90]);
Physiolibrary.Interfaces.RealInput desiredFlow(final quantity = "Flow", final unit = "ml/min") annotation(extent = [-10, 50; 10, 70], rotation = -90);
equation
q_in.q = desiredFlow;
end OutputPump;
end VolumeFlow;

constant Real SecPerMin(unit = "s/min") = 60 "Conversion coeficient from minutes to seconds";

package NonSIunits  "Non SI-units Support"
constant Real PaTOmmHg(final unit = "mmHg/Pa") = 760 / 101325;

model degC_to_degF  "Convert from Celsius degrees to Farenhein degrees"
Interfaces.RealInput_ degC;
Interfaces.RealOutput_ degF;
equation
degF = degC * 9.0 / 5.0 + 32.0;
end degC_to_degF;
end NonSIunits;

package Utilities
constant String ORIGINAL_DATA_FILE = "setup/default.txt";
constant String DATA_FILE = "setup/default.txt";
constant String OUTPUT_FILE = "setup/output2_s.txt";
constant String OUTPUT_DIF_FILE = "setup/dif3_s.txt";

function readRealParameter  "Read the value of a Real parameter from file"
input String fileName "Name of file";
input String name "Name of parameter";
input Real varValue = 0 "default value of parameter";
input Init initType = Init.NoInit "input type settings";
output Real result "Actual value of parameter on file";
protected
String line;
Integer nextIndex;
Integer iline = 1;
Boolean found = false;
Boolean endOfFile = false;
algorithm
if initType == Init.FromFile then
if not .Modelica.Utilities.Files.exist(fileName) then
.Modelica.Utilities.Streams.error("readRealParameter(\"" + name + "\", \"" + fileName + "\")  Error: the file does not exist.\n");
else
(line, endOfFile) := .Modelica.Utilities.Streams.readLine(fileName, iline);
while not found and not endOfFile loop
if line == name then
(line, endOfFile) := .Modelica.Utilities.Streams.readLine(fileName, iline + 1);
result := .Modelica.Utilities.Strings.scanReal(line, 1);
found := true;
else
iline := iline + 2;
(line, endOfFile) := .Modelica.Utilities.Streams.readLine(fileName, iline);
end if;
end while;
if not found then
.Modelica.Utilities.Streams.error("Parameter \"" + name + "\" not found in file \"" + fileName + "\"\n");
else
end if;
end if;
else
result := varValue;
end if;
end readRealParameter;

type Init = enumeration(NoInit "No abstract initialization (start values are used as guess values with fixed=false or from start=value in instances)", CalculateInitialSteadyState "Steady state initialization (derivatives of states are zero)", FromFile "Initialization from file");

partial model DynamicState
extends DynamicStateDynamicNoInit;
parameter String stateName "state name must be unique for each instance";
Real stateValue(stateSelect = StateSelect.prefer) "state must be connected in inherited class definition";
Real changePerMin "dynamic change of state value per minute";
parameter Real originalValue = readRealParameter(ORIGINAL_DATA_FILE, stateName);
parameter Real initialValue(fixed = false);
initial equation
if initType == Init.CalculateInitialSteadyState then
der(stateValue) = 0;
elseif initType == Init.FromFile then
stateValue = readRealParameter(DATA_FILE, stateName);
end if;
initialValue = stateValue;
equation
when SAVE_VALUES and terminal() then
.Modelica.Utilities.Streams.print(stateName + "\n" + String(stateValue), OUTPUT_FILE);
.Modelica.Utilities.Streams.print((if abs(originalValue) > Modelica.Constants.eps then String(abs((stateValue - originalValue) / originalValue)) else "Zero vs. " + String(stateValue)) + ";" + stateName + ";" + String(initialValue) + ";" + String(stateValue) + ";" + String(originalValue), OUTPUT_DIF_FILE);
end when;
if STEADY then
changePerMin = 0;
else
der(stateValue) = changePerMin / SecPerMin;
end if;
end DynamicState;

partial model DynamicStateDynamicNoInit
parameter Boolean STEADY = false;
parameter Boolean SAVE_VALUES = false;
parameter Init initType = Init.NoInit;
end DynamicStateDynamicNoInit;

block ConstantFromFile  "Generate constant signal of type Real with value from file"
extends ModelVariable(k = readRealParameter(DATA_FILE, varName, varValue, initType));
Physiolibrary.Interfaces.RealOutput_ y "Connector of Real output signal";
equation
y = k;
end ConstantFromFile;

partial block ModelVariable  "abstract variable of the model - could be input or output"
parameter Real k(fixed = true) = 1e-007 "Constant output value";
parameter String varName;
parameter Real varValue(fixed = true) = 1e-007;
parameter String units = "1";
parameter Init initType = Init.FromFile;
end ModelVariable;
end Utilities;

end Physiolibrary;

model HumModTest
extends HumMod.Main.test.HumMod_GolemEdition2;
inner Modelica.StateGraph.Interfaces.CompositeStepState stateGraphRoot;
annotation(uses(Modelica(version="3.2.1")), experiment(StartTime = 0, StopTime = 86400, Tolerance = 0.01, Interval = 1));
end HumModTest;

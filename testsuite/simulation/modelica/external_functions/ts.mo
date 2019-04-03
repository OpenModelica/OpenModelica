package ExternalMedia
  extends Modelica.Icons.Package;

  package Common  "Package with common definitions"
    extends Modelica.Icons.Package;
    type InputChoice = enumeration(dT "(d,T) as inputs", hs "(h,s) as inputs", ph "(p,h) as inputs", ps "(p,s) as inputs", pT "(p,T) as inputs");
  end Common;

  package Media  "Medium packages compatible with Modelica.Media"
    extends Modelica.Icons.Package;

    package TestMedium  "Simple water medium model for debugging and testing"
      extends BaseClasses.ExternalTwoPhaseMedium(mediumName = "TestMedium", libraryName = "TestMedium", ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pT);
    end TestMedium;

    package BaseClasses  "Base classes for external media packages"
      extends Modelica.Icons.BasesPackage;

      package ExternalTwoPhaseMedium  "Generic external two phase medium package"
        extends Modelica.Media.Interfaces.PartialTwoPhaseMedium(singleState = false, onePhase = false, smoothModel = false, fluidConstants = {externalFluidConstants});
        constant String mediumName = "unusablePartialMedium" "Name of the medium";
        constant String libraryName = "UnusableExternalMedium" "Name of the external fluid property computation library";
        constant String substanceName = substanceNames[1] "Only one substance can be specified";
        constant FluidConstants externalFluidConstants = FluidConstants(iupacName = "unknown", casRegistryNumber = "unknown", chemicalFormula = "unknown", structureFormula = "unknown", molarMass = getMolarMass(), criticalTemperature = getCriticalTemperature(), criticalPressure = getCriticalPressure(), criticalMolarVolume = getCriticalMolarVolume(), acentricFactor = 0, triplePointTemperature = 280.0, triplePointPressure = 500.0, meltingPoint = 280, normalBoilingPoint = 380.0, dipoleMoment = 2.0);
        constant .ExternalMedia.Common.InputChoice inputChoice = .ExternalMedia.Common.InputChoice.ph "Default choice of input variables for property computations";

        redeclare replaceable record ThermodynamicState
          Temperature T "temperature";
          VelocityOfSound a "velocity of sound";
          Modelica.SIunits.CubicExpansionCoefficient beta "isobaric expansion coefficient";
          SpecificHeatCapacity cp "specific heat capacity cp";
          SpecificHeatCapacity cv "specific heat capacity cv";
          Density d "density";
          DerDensityByEnthalpy ddhp "derivative of density wrt enthalpy at constant pressure";
          DerDensityByPressure ddph "derivative of density wrt pressure at constant enthalpy";
          DynamicViscosity eta "dynamic viscosity";
          SpecificEnthalpy h "specific enthalpy";
          Modelica.SIunits.Compressibility kappa "compressibility";
          ThermalConductivity lambda "thermal conductivity";
          AbsolutePressure p "pressure";
          FixedPhase phase(min = 0, max = 2) "phase flag: 2 for two-phase, 1 for one-phase";
          SpecificEntropy s "specific entropy";
        end ThermodynamicState;

        redeclare record SaturationProperties
          Temperature Tsat "saturation temperature";
          Real dTp "derivative of Ts wrt pressure";
          DerDensityByPressure ddldp "derivative of dls wrt pressure";
          DerDensityByPressure ddvdp "derivative of dvs wrt pressure";
          DerEnthalpyByPressure dhldp "derivative of hls wrt pressure";
          DerEnthalpyByPressure dhvdp "derivative of hvs wrt pressure";
          Density dl "density at bubble line (for pressure ps)";
          Density dv "density at dew line (for pressure ps)";
          SpecificEnthalpy hl "specific enthalpy at bubble line (for pressure ps)";
          SpecificEnthalpy hv "specific enthalpy at dew line (for pressure ps)";
          AbsolutePressure psat "saturation pressure";
          SurfaceTension sigma "surface tension";
          SpecificEntropy sl "specific entropy at bubble line (for pressure ps)";
          SpecificEntropy sv "specific entropy at dew line (for pressure ps)";
        end SaturationProperties;

        redeclare replaceable model extends BaseProperties(p(stateSelect = if preferredMediumStates and (basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ph or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.pT or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ps) then StateSelect.prefer else StateSelect.default), T(stateSelect = if preferredMediumStates and (basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.pT or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.dT) then StateSelect.prefer else StateSelect.default), h(stateSelect = if preferredMediumStates and (basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.hs or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ph) then StateSelect.prefer else StateSelect.default), d(stateSelect = if preferredMediumStates and basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.dT then StateSelect.prefer else StateSelect.default))
          parameter .ExternalMedia.Common.InputChoice basePropertiesInputChoice = inputChoice "Choice of input variables for property computations";
          FixedPhase phaseInput "Phase input for property computation functions, 2 for two-phase, 1 for one-phase, 0 if not known";
          Integer phaseOutput "Phase output for medium, 2 for two-phase, 1 for one-phase";
          SpecificEntropy s(stateSelect = if basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.hs or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ps then StateSelect.prefer else StateSelect.default) "Specific entropy";
          SaturationProperties sat "saturation property record";
        equation
          MM = externalFluidConstants.molarMass;
          R = Modelica.Constants.R / MM;
          if onePhase or basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.pT then
            phaseInput = 1 "Force one-phase property computation";
          else
            phaseInput = 0 "Unknown phase";
          end if;
          if basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ph then
            state = setState_ph(p, h, phaseInput);
            d = density_ph(p, h, phaseInput);
            s = specificEntropy_ph(p, h, phaseInput);
            T = temperature_ph(p, h, phaseInput);
          elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.dT then
            state = setState_dT(d, T, phaseInput);
            h = specificEnthalpy(state);
            p = pressure(state);
            s = specificEntropy(state);
          elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.pT then
            state = setState_pT(p, T, phaseInput);
            d = density(state);
            h = specificEnthalpy(state);
            s = specificEntropy(state);
          elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ps then
            state = setState_ps(p, s, phaseInput);
            d = density(state);
            h = specificEnthalpy(state);
            T = temperature(state);
          elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.hs then
            state = setState_hs(h, s, phaseInput);
            d = density(state);
            p = pressure(state);
            T = temperature(state);
          end if;
          u = h - p / d;
          sat = setSat_p_state(state);
          if smoothModel then
            phaseOutput = state.phase;
          else
            if basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ph then
              phaseOutput = if h > bubbleEnthalpy(sat) and h < dewEnthalpy(sat) and p < fluidConstants[1].criticalPressure then 2 else 1;
            elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.dT then
              phaseOutput = if d < bubbleDensity(sat) and d > dewDensity(sat) and T < fluidConstants[1].criticalTemperature then 2 else 1;
            elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.ps then
              phaseOutput = if s > bubbleEntropy(sat) and s < dewEntropy(sat) and p < fluidConstants[1].criticalPressure then 2 else 1;
            elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.hs then
              phaseOutput = if s > bubbleEntropy(sat) and s < dewEntropy(sat) and h > bubbleEnthalpy(sat) and h < dewEnthalpy(sat) then 2 else 1;
            elseif basePropertiesInputChoice == .ExternalMedia.Common.InputChoice.pT then
              phaseOutput = 1;
            else
              assert(false, "You are using an unsupported pair of inputs.");
            end if;
          end if;
        end BaseProperties;

        redeclare function molarMass  "Return the molar mass of the medium"
          input ThermodynamicState state;
          output MolarMass MM "Mixture molar mass";
        algorithm
          MM := fluidConstants[1].molarMass;
        end molarMass;

        replaceable function getMolarMass
          output MolarMass MM "molar mass";
          external "C" MM = TwoPhaseMedium_getMolarMass_C_impl(mediumName, libraryName, substanceName)
        annotation(Include = "
double TwoPhaseMedium_getMolarMass_C_impl(const char* mediumName, const char* libraryName, const char* substanceName)
{
  assert(mediumName[0] != 0); assert(libraryName[0] != 0); assert(substanceName[0] != 0);
  fprintf(stdout, \"TwoPhaseMedium_getMolarMass_C_impl: medium: [%s] library [%s] substance [%s]\\n\\n\", mediumName, libraryName, substanceName); fflush(stdout);
  return 0.1;
}");
        end getMolarMass;

        replaceable function getCriticalTemperature
          output Temperature Tc "Critical temperature";
          external "C" Tc = TwoPhaseMedium_getCriticalTemperature_C_impl(mediumName, libraryName, substanceName)
        annotation(Include = "
double TwoPhaseMedium_getCriticalTemperature_C_impl(const char* mediumName, const char* libraryName, const char* substanceName)
{
  assert(mediumName[0] != 0); assert(libraryName[0] != 0); assert(substanceName[0] != 0);
  return 0.2;
}");
        end getCriticalTemperature;

        replaceable function getCriticalPressure
          output AbsolutePressure pc "Critical temperature";
          external "C" pc = TwoPhaseMedium_getCriticalPressure_C_impl(mediumName, libraryName, substanceName)
        annotation(Include = "
double TwoPhaseMedium_getCriticalPressure_C_impl(const char* mediumName, const char* libraryName, const char* substanceName)
{
  assert(mediumName[0] != 0); assert(libraryName[0] != 0); assert(substanceName[0] != 0);
  return 0.3;
}");
        end getCriticalPressure;

        replaceable function getCriticalMolarVolume
          output MolarVolume vc "Critical molar volume";
          external "C" vc = TwoPhaseMedium_getCriticalMolarVolume_C_impl(mediumName, libraryName, substanceName)
        annotation(Include = "
double TwoPhaseMedium_getCriticalMolarVolume_C_impl(const char* mediumName, const char* libraryName, const char* substanceName)
{
  assert(mediumName[0] != 0); assert(libraryName[0] != 0); assert(substanceName[0] != 0);
  return 0.4;
}");
        end getCriticalMolarVolume;

        redeclare replaceable function setState_ph  "Return thermodynamic state record from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "pressure";
          input SpecificEnthalpy h "specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state;
          external "C" TwoPhaseMedium_setState_ph_C_impl(p, h, phase, state, mediumName, libraryName, substanceName)
        annotation(Include = "typedef struct {
  //! Temperature
  double T;
  //! Velocity of sound
  double a;
  //! Isobaric expansion coefficient
  double beta;
  //! Specific heat capacity cp
  double cp;
  //! Specific heat capacity cv
  double cv;
  //! Density
  double d;
  //! Derivative of density wrt enthalpy at constant pressure
  double ddhp;
  //! Derivative of density wrt pressure at constant enthalpy
  double ddph;
  //! Dynamic viscosity
  double eta;
  //! Specific enthalpy
  double h;
  //! Compressibility
  double kappa;
  //! Thermal conductivity
  double lambda;
  //! Pressure
  double p;
  //! Phase flag: 2 for two-phase, 1 for one-phase
  long phase;
  //! Specific entropy
  double s;
} ExternalThermodynamicState;
void TwoPhaseMedium_setState_ph_C_impl(double p, double h, double phase, ExternalThermodynamicState *state, const char* mediumName, const char* libraryName, const char* substanceName)
{
  assert(mediumName[0] != 0); assert(libraryName[0] != 0); assert(substanceName[0] != 0);
  state->T = 100.5;
  state->a = 0.6;
  state->beta = 0.7;
  state->cp = 0.8;
  state->cv = 0.9;
  state->d = 1.11;
  state->ddhp = 1.1;
  state->ddph = 1.2;
  state->eta = 1.3;
  state->h = 1.4;
  state->kappa = 1.5;
  state->lambda = 1.6;
  state->p = 1.7;
  state->phase = 1;
  state->s = 2.1;
}");
        end setState_ph;

        redeclare replaceable function setState_pT  "Return thermodynamic state record from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "pressure";
          input Temperature T "temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state;
          external "C" TwoPhaseMedium_setState_pT_C_impl(p, T, state, mediumName, libraryName, substanceName) annotation(Include = "");
        end setState_pT;

        redeclare replaceable function setState_dT  "Return thermodynamic state record from d and T"
          extends Modelica.Icons.Function;
          input Density d "density";
          input Temperature T "temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state;
          external "C" TwoPhaseMedium_setState_dT_C_impl(d, T, phase, state, mediumName, libraryName, substanceName) annotation(Include = "");
        end setState_dT;

        redeclare replaceable function setState_ps  "Return thermodynamic state record from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "pressure";
          input SpecificEntropy s "specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state;
          external "C" TwoPhaseMedium_setState_ps_C_impl(p, s, phase, state, mediumName, libraryName, substanceName) annotation(Include = "");
        end setState_ps;

        replaceable function setState_hs  "Return thermodynamic state record from h and s"
          extends Modelica.Icons.Function;
          input SpecificEnthalpy h "specific enthalpy";
          input SpecificEntropy s "specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state;
          external "C" TwoPhaseMedium_setState_hs_C_impl(h, s, phase, state, mediumName, libraryName, substanceName) annotation(Include = "");
        end setState_hs;

        redeclare function extends setState_phX
        algorithm
          state := setState_ph(p, h, phase);
        end setState_phX;

        redeclare function extends setState_pTX
        algorithm
          state := setState_pT(p, T, phase);
        end setState_pTX;

        redeclare function extends setState_dTX
        algorithm
          state := setState_dT(d, T, phase);
        end setState_dTX;

        redeclare function extends setState_psX
        algorithm
          state := setState_ps(p, s, phase);
        end setState_psX;

        redeclare replaceable function density_ph  "Return density from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density_ph_state(p = p, h = h, state = setState_ph(p = p, h = h, phase = phase));
          annotation(Inline = true);
        end density_ph;

        function density_ph_state  "returns density for given p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Enthalpy";
          input ThermodynamicState state;
          output Density d "density";
        algorithm
          d := density(state);
          annotation(Inline = false, LateInline = true, derivative(noDerivative = state) = density_ph_der);
        end density_ph_state;

        replaceable function density_ph_der  "Total derivative of density_ph"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input ThermodynamicState state;
          input Real p_der "time derivative of pressure";
          input Real h_der "time derivative of specific enthalpy";
          output Real d_der "time derivative of density";
        algorithm
          d_der := p_der * density_derp_h(state = state) + h_der * density_derh_p(state = state);
          annotation(Inline = true);
        end density_ph_der;

        redeclare replaceable function temperature_ph  "Return temperature from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature_ph_state(p = p, h = h, state = setState_ph(p = p, h = h, phase = phase));
          annotation(Inline = true, inverse(h = specificEnthalpy_pT(p = p, T = T, phase = phase)));
        end temperature_ph;

        function temperature_ph_state  "returns temperature for given p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Enthalpy";
          input ThermodynamicState state;
          output Temperature T "Temperature";
        algorithm
          T := temperature(state);
          annotation(Inline = false, LateInline = true, inverse(h = specificEnthalpy_pT_state(p = p, T = T, state = state)));
        end temperature_ph_state;

        replaceable function specificEntropy_ph  "Return specific entropy from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEntropy s "specific entropy";
        algorithm
          s := specificEntropy_ph_state(p = p, h = h, state = setState_ph(p = p, h = h, phase = phase));
          annotation(Inline = true, inverse(h = specificEnthalpy_ps(p = p, s = s, phase = phase)));
        end specificEntropy_ph;

        function specificEntropy_ph_state  "returns specific entropy for a given p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific Enthalpy";
          input ThermodynamicState state;
          output SpecificEntropy s "Specific Entropy";
        algorithm
          s := specificEntropy(state);
          annotation(Inline = false, LateInline = true, derivative(noDerivative = state) = specificEntropy_ph_der);
        end specificEntropy_ph_state;

        function specificEntropy_ph_der  "time derivative of specificEntropy_ph"
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input ThermodynamicState state;
          input Real p_der "time derivative of pressure";
          input Real h_der "time derivative of specific enthalpy";
          output Real s_der "time derivative of specific entropy";
        algorithm
          s_der := p_der * (-1.0 / (state.d * state.T)) + h_der * (1.0 / state.T);
          annotation(Inline = true);
        end specificEntropy_ph_der;

        redeclare function extends prandtlNumber  "Returns Prandtl number"  annotation(Inline = true); end prandtlNumber;

        redeclare replaceable function extends temperature  "Return temperature from state"
        algorithm
          T := state.T;
          annotation(Inline = true);
        end temperature;

        redeclare replaceable function extends velocityOfSound  "Return velocity of sound from state"
        algorithm
          a := state.a;
          annotation(Inline = true);
        end velocityOfSound;

        redeclare replaceable function extends isobaricExpansionCoefficient  "Return isobaric expansion coefficient from state"
        algorithm
          beta := state.beta;
          annotation(Inline = true);
        end isobaricExpansionCoefficient;

        redeclare replaceable function extends isentropicExponent  "Return isentropic exponent"
          extends Modelica.Icons.Function;
        algorithm
          gamma := density(state) / pressure(state) * velocityOfSound(state) * velocityOfSound(state);
        end isentropicExponent;

        redeclare replaceable function extends specificHeatCapacityCp  "Return specific heat capacity cp from state"
        algorithm
          cp := state.cp;
          annotation(Inline = true);
        end specificHeatCapacityCp;

        redeclare replaceable function extends specificHeatCapacityCv  "Return specific heat capacity cv from state"
        algorithm
          cv := state.cv;
          annotation(Inline = true);
        end specificHeatCapacityCv;

        redeclare replaceable function extends density  "Return density from state"
        algorithm
          d := state.d;
          annotation(Inline = true);
        end density;

        redeclare replaceable function extends density_derh_p  "Return derivative of density wrt enthalpy at constant pressure from state"
        algorithm
          ddhp := state.ddhp;
          annotation(Inline = true);
        end density_derh_p;

        redeclare replaceable function extends density_derp_h  "Return derivative of density wrt pressure at constant enthalpy from state"
        algorithm
          ddph := state.ddph;
          annotation(Inline = true);
        end density_derp_h;

        redeclare replaceable function extends density_derp_T
        algorithm
          ddpT := state.kappa * state.d;
        end density_derp_T;

        redeclare replaceable function extends density_derT_p
        algorithm
          ddTp := -state.beta * state.d;
        end density_derT_p;

        redeclare replaceable function extends dynamicViscosity  "Return dynamic viscosity from state"
        algorithm
          eta := state.eta;
          annotation(Inline = true);
        end dynamicViscosity;

        redeclare replaceable function extends specificEnthalpy  "Return specific enthalpy from state"
        algorithm
          h := state.h;
          annotation(Inline = true);
        end specificEnthalpy;

        redeclare replaceable function extends specificInternalEnergy  "Returns specific internal energy"
          extends Modelica.Icons.Function;
        algorithm
          u := specificEnthalpy(state) - pressure(state) / density(state);
        end specificInternalEnergy;

        redeclare replaceable function extends isothermalCompressibility  "Return isothermal compressibility from state"
        algorithm
          kappa := state.kappa;
          annotation(Inline = true);
        end isothermalCompressibility;

        redeclare replaceable function extends thermalConductivity  "Return thermal conductivity from state"
        algorithm
          lambda := state.lambda;
          annotation(Inline = true);
        end thermalConductivity;

        redeclare replaceable function extends pressure  "Return pressure from state"
        algorithm
          p := state.p;
          annotation(Inline = true);
        end pressure;

        redeclare replaceable function extends specificEntropy  "Return specific entropy from state"
        algorithm
          s := state.s;
          annotation(Inline = true);
        end specificEntropy;

        redeclare replaceable function extends isentropicEnthalpy
          external "C" h_is = TwoPhaseMedium_isentropicEnthalpy_C_impl(p_downstream, refState, mediumName, libraryName, substanceName) annotation(Include = "");
        end isentropicEnthalpy;

        redeclare replaceable function setSat_p  "Return saturation properties from p"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "pressure";
          output SaturationProperties sat "saturation property record";
          external "C" TwoPhaseMedium_setSat_p_C_impl(p, sat, mediumName, libraryName, substanceName) annotation(Include = "");
        end setSat_p;

        replaceable function setSat_p_state  "Return saturation properties from the state"
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SaturationProperties sat "saturation property record";
        algorithm
          sat := setSat_p(state.p);
          annotation(Inline = true);
        end setSat_p_state;

        redeclare replaceable function setSat_T  "Return saturation properties from p"
          extends Modelica.Icons.Function;
          input Temperature T "temperature";
          output SaturationProperties sat "saturation property record";
          external "C" TwoPhaseMedium_setSat_T_C_impl(T, sat, mediumName, libraryName, substanceName) annotation(Include = "");
        end setSat_T;

        redeclare replaceable function extends setBubbleState  "set the thermodynamic state on the bubble line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "phase: default is one phase";
          output ThermodynamicState state "complete thermodynamic state info";
        algorithm
          state := setState_ph(sat.psat, sat.hl, phase);
          annotation(Inline = true);
        end setBubbleState;

        redeclare replaceable function extends setDewState  "set the thermodynamic state on the dew line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "phase: default is one phase";
          output ThermodynamicState state "complete thermodynamic state info";
        algorithm
          state := setState_ph(sat.psat, sat.hv, phase);
          annotation(Inline = true);
        end setDewState;

        redeclare replaceable function extends saturationTemperature
        algorithm
          T := saturationTemperature_sat(setSat_p(p));
          annotation(Inline = true);
        end saturationTemperature;

        redeclare function extends saturationTemperature_sat   annotation(Inline = true); end saturationTemperature_sat;

        redeclare replaceable function extends saturationTemperature_derp  "Returns derivative of saturation temperature w.r.t.. pressureBeing this function inefficient, it is strongly recommended to use saturationTemperature_derp_sat
             and never use saturationTemperature_derp directly"
          external "C" dTp = TwoPhaseMedium_saturationTemperature_derp_C_impl(p, mediumName, libraryName, substanceName) annotation(Include = "");
        end saturationTemperature_derp;

        redeclare replaceable function saturationTemperature_derp_sat  "Returns derivative of saturation temperature w.r.t.. pressure"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "saturation property record";
          output Real dTp "derivative of saturation temperature w.r.t. pressure";
        algorithm
          dTp := sat.dTp;
          annotation(Inline = true);
        end saturationTemperature_derp_sat;

        redeclare replaceable function extends dBubbleDensity_dPressure  "Returns bubble point density derivative"
        algorithm
          ddldp := sat.ddldp;
          annotation(Inline = true);
        end dBubbleDensity_dPressure;

        redeclare replaceable function extends dDewDensity_dPressure  "Returns dew point density derivative"
        algorithm
          ddvdp := sat.ddvdp;
          annotation(Inline = true);
        end dDewDensity_dPressure;

        redeclare replaceable function extends dBubbleEnthalpy_dPressure  "Returns bubble point specific enthalpy derivative"
        algorithm
          dhldp := sat.dhldp;
          annotation(Inline = true);
        end dBubbleEnthalpy_dPressure;

        redeclare replaceable function extends dDewEnthalpy_dPressure  "Returns dew point specific enthalpy derivative"
        algorithm
          dhvdp := sat.dhvdp;
          annotation(Inline = true);
        end dDewEnthalpy_dPressure;

        redeclare replaceable function extends bubbleDensity  "Returns bubble point density"
        algorithm
          dl := sat.dl;
          annotation(Inline = true);
        end bubbleDensity;

        redeclare replaceable function extends dewDensity  "Returns dew point density"
        algorithm
          dv := sat.dv;
          annotation(Inline = true);
        end dewDensity;

        redeclare replaceable function extends bubbleEnthalpy  "Returns bubble point specific enthalpy"
        algorithm
          hl := sat.hl;
          annotation(Inline = true);
        end bubbleEnthalpy;

        redeclare replaceable function extends dewEnthalpy  "Returns dew point specific enthalpy"
        algorithm
          hv := sat.hv;
          annotation(Inline = true);
        end dewEnthalpy;

        redeclare replaceable function extends saturationPressure
        algorithm
          p := saturationPressure_sat(setSat_T(T));
          annotation(Inline = false, LateInline = true, derivative = saturationPressure_der);
        end saturationPressure;

        function saturationPressure_der  "Return saturation pressure time derivative"
          extends Modelica.Icons.Function;
          input Temperature T "temperature";
          input Real T_der "Temperature derivative";
          output Real p_der "saturation pressure derivative";
        algorithm
          p_der := T_der / saturationTemperature_derp_sat(setSat_T(T));
          annotation(Inline = true);
        end saturationPressure_der;

        redeclare function extends saturationPressure_sat   annotation(Inline = true); end saturationPressure_sat;

        redeclare replaceable function extends surfaceTension  "Returns surface tension sigma in the two phase region"
        algorithm
          sigma := sat.sigma;
          annotation(Inline = true);
        end surfaceTension;

        redeclare replaceable function extends bubbleEntropy  "Returns bubble point specific entropy"
        algorithm
          sl := specificEntropy(setBubbleState(sat));
          annotation(Inline = true);
        end bubbleEntropy;

        redeclare replaceable function extends dewEntropy  "Returns dew point specific entropy"
        algorithm
          sv := specificEntropy(setDewState(sat));
          annotation(Inline = true);
        end dewEntropy;
      end ExternalTwoPhaseMedium;
    end BaseClasses;
  end Media;

  package Test  "Test models for the different solvers"
    extends Modelica.Icons.ExamplesPackage;

    package TestMedium  "Test cases for TestMedium"
      extends Modelica.Icons.ExamplesPackage;

      model TestState  "Test case using TestMedium with a single state record"
        extends Modelica.Icons.Example;
        replaceable package Medium = Media.TestMedium;
        Medium.ThermodynamicState state;
      equation
        state = Medium.setState_ph(1e5, 1e5 + 1e5 * time);
      end TestState;
    end TestMedium;
  end Test;
  annotation(uses(Modelica(version = "3.2.1")), Documentation(info = "<html>
<p>The <b>ExternalMedia</b> library provides a framework for interfacing external codes computing fluid properties to Modelica.Media-compatible component models. The library has been designed with two main goals: maximizing the efficiency of the code, while minimizing the amount of extra code required to interface existing external codes to the library.</p>
<p>The library covers pure fluids models, possibly two-phase, compliant with the <a href=\"modelica://Modelica.Media.Interfaces.PartialTwoPhaseMedium\">Modelica.Media.Interfaces.PartialTwoPhaseMedium</a> interface. </p>
<p>Two external softwares for fluid property computation are currently suppored by the ExternalMedia library:</p>
<ul>
<li><a href=\"http://www.fluidprop.com\">FluidProp</a>, formerly developed at TU Delft and currently devloped and maintained by Asimptote</li>
<li><a href=\"http://coolprop.org\">CoolProp</a>, developed at the University of Liege and at the Technical University of Denmark (DTU)</li>
</ul>
<p>The library has been tested with the Dymola and OpenModelica tools under the Windows operating system. If you are interested in the support of other tools, operating systems, and external fluid property computation codes, please contact the developers.</p>
<p>Main contributors: Francesco Casella, Christoph Richter, Roberto Bonifetto, Ian Bell.</p>
<p><b>The code is licensed under the Modelica License 2. </b>For license conditions (including the disclaimer of warranty) visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\">https://www.modelica.org/licenses/ModelicaLicense2</a>. </p>
<p>Copyright &copy; 2006-2014, Politecnico di Milano, TU Braunschweig, Politecnico di Torino, Universit&eacute; de Liege.</p>
</html>"));
end ExternalMedia;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
  <p>
  Package in which processor specific constants are defined that are needed
  by numerical algorithms. Typically these constants are not directly used,
  but indirectly via the alias definition in
  <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
  </p>
  </html>"));
  end Machine;
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
Copyright &copy; 2009-2013, DLR and Dassault Syst&egrave;mes AB.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 3)"
  extends Modelica.Icons.Package;

  package Media  "Library of media property models"
    extends Modelica.Icons.Package;

    package Interfaces  "Interfaces for media models"
      extends Modelica.Icons.InterfacesPackage;

      partial package PartialMedium  "Partial medium properties (base package of all media packages)"
        extends Modelica.Media.Interfaces.Types;
        extends Modelica.Icons.MaterialPropertiesPackage;
        constant Modelica.Media.Interfaces.Choices.IndependentVariables ThermoStates "Enumeration type for independent variables";
        constant String mediumName = "unusablePartialMedium" "Name of the medium";
        constant String[:] substanceNames = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
        constant String[:] extraPropertiesNames = fill("", 0) "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
        constant Boolean singleState "= true, if u and d are not a function of pressure";
        constant Boolean reducedX = true "= true if medium contains the equation sum(X) = 1.0; set reducedX=true if only one substance (see docu for details)";
        constant Boolean fixedX = false "= true if medium contains the equation X = reference_X";
        constant MassFraction[nX] reference_X = fill(1 / nX, nX) "Default mass fractions of medium";
        constant AbsolutePressure p_default = 101325 "Default value for pressure of medium (for initialization)";
        constant Temperature T_default = Modelica.SIunits.Conversions.from_degC(20) "Default value for temperature of medium (for initialization)";
        constant MassFraction[nX] X_default = reference_X "Default value for mass fractions of medium (for initialization)";
        final constant Integer nS = size(substanceNames, 1) "Number of substances" annotation(Evaluate = true);
        constant Integer nX = nS "Number of mass fractions" annotation(Evaluate = true);
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)" annotation(Evaluate = true);
        final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties" annotation(Evaluate = true);
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

        replaceable record ThermodynamicState  "Minimal variable set that is available as input argument to every medium function"
          extends Modelica.Icons.Record;
        end ThermodynamicState;

        replaceable partial model BaseProperties  "Base properties (p, d, T, h, u, R, MM and, if applicable, X and Xi) of a medium"
          InputAbsolutePressure p "Absolute pressure of medium";
          InputMassFraction[nXi] Xi(start = reference_X[1:nXi]) "Structurally independent mass fractions";
          InputSpecificEnthalpy h "Specific enthalpy of medium";
          Density d "Density of medium";
          Temperature T "Temperature of medium";
          MassFraction[nX] X(start = reference_X) "Mass fractions (= (component mass)/total mass  m_i/m)";
          SpecificInternalEnergy u "Specific internal energy of medium";
          SpecificHeatCapacity R "Gas constant (of mixture if applicable)";
          MolarMass MM "Molar mass (of mixture or single fluid)";
          ThermodynamicState state "Thermodynamic state record for optional functions";
          parameter Boolean preferredMediumStates = false "= true if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true, Dialog(tab = "Advanced"));
          parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
          .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_degC = Modelica.SIunits.Conversions.to_degC(T) "Temperature of medium in [degC]";
          .Modelica.SIunits.Conversions.NonSIunits.Pressure_bar p_bar = Modelica.SIunits.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
          connector InputAbsolutePressure = input .Modelica.SIunits.AbsolutePressure "Pressure as input signal connector";
          connector InputSpecificEnthalpy = input .Modelica.SIunits.SpecificEnthalpy "Specific enthalpy as input signal connector";
          connector InputMassFraction = input .Modelica.SIunits.MassFraction "Mass fraction as input signal connector";
        equation
          if standardOrderComponents then
            Xi = X[1:nXi];
            if fixedX then
              X = reference_X;
            end if;
            if reducedX and not fixedX then
              X[nX] = 1 - sum(Xi);
            end if;
            for i in 1:nX loop
              assert(X[i] >= (-1.e-5) and X[i] <= 1 + 1.e-5, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
            end for;
          end if;
          assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255}), Text(extent = {{-152, 164}, {152, 102}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
        <p>
        Model <b>BaseProperties</b> is a model within package <b>PartialMedium</b>
        and contains the <b>declarations</b> of the minimum number of
        variables that every medium model is supposed to support.
        A specific medium inherits from model <b>BaseProperties</b> and provides
        the equations for the basic properties.</p>
        <p>
        The BaseProperties model contains the following <b>7+nXi variables</b>
        (nXi is the number of independent mass fractions defined in package
        PartialMedium):
        </p>
        <table border=1 cellspacing=0 cellpadding=2>
          <tr><td valign=\"top\"><b>Variable</b></td>
              <td valign=\"top\"><b>Unit</b></td>
              <td valign=\"top\"><b>Description</b></td></tr>
          <tr><td valign=\"top\">T</td>
              <td valign=\"top\">K</td>
              <td valign=\"top\">temperature</td></tr>
          <tr><td valign=\"top\">p</td>
              <td valign=\"top\">Pa</td>
              <td valign=\"top\">absolute pressure</td></tr>
          <tr><td valign=\"top\">d</td>
              <td valign=\"top\">kg/m3</td>
              <td valign=\"top\">density</td></tr>
          <tr><td valign=\"top\">h</td>
              <td valign=\"top\">J/kg</td>
              <td valign=\"top\">specific enthalpy</td></tr>
          <tr><td valign=\"top\">u</td>
              <td valign=\"top\">J/kg</td>
              <td valign=\"top\">specific internal energy</td></tr>
          <tr><td valign=\"top\">Xi[nXi]</td>
              <td valign=\"top\">kg/kg</td>
              <td valign=\"top\">independent mass fractions m_i/m</td></tr>
          <tr><td valign=\"top\">R</td>
              <td valign=\"top\">J/kg.K</td>
              <td valign=\"top\">gas constant</td></tr>
          <tr><td valign=\"top\">M</td>
              <td valign=\"top\">kg/mol</td>
              <td valign=\"top\">molar mass</td></tr>
        </table>
        <p>
        In order to implement an actual medium model, one can extend from this
        base model and add <b>5 equations</b> that provide relations among
        these variables. Equations will also have to be added in order to
        set all the variables within the ThermodynamicState record state.</p>
        <p>
        If standardOrderComponents=true, the full composition vector X[nX]
        is determined by the equations contained in this base class, depending
        on the independent mass fraction vector Xi[nXi].</p>
        <p>Additional <b>2 + nXi</b> equations will have to be provided
        when using the BaseProperties model, in order to fully specify the
        thermodynamic conditions. The input connector qualifier applied to
        p, h, and nXi indirectly declares the number of missing equations,
        permitting advanced equation balance checking by Modelica tools.
        Please note that this doesn't mean that the additional equations
        should be connection equations, nor that exactly those variables
        should be supplied, in order to complete the model.
        For further information, see the Modelica.Media User's guide, and
        Section 4.7 (Balanced Models) of the Modelica 3.0 specification.</p>
        </html>"));
        end BaseProperties;

        replaceable partial function setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_pTX;

        replaceable partial function setState_phX  "Return thermodynamic state as function of p, h and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_phX;

        replaceable partial function setState_psX  "Return thermodynamic state as function of p, s and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_psX;

        replaceable partial function setState_dTX  "Return thermodynamic state as function of d, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_dTX;

        replaceable partial function dynamicViscosity  "Return dynamic viscosity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DynamicViscosity eta "Dynamic viscosity";
        end dynamicViscosity;

        replaceable partial function thermalConductivity  "Return thermal conductivity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output ThermalConductivity lambda "Thermal conductivity";
        end thermalConductivity;

        replaceable function prandtlNumber  "Return the Prandtl number"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output PrandtlNumber Pr "Prandtl number";
        algorithm
          Pr := dynamicViscosity(state) * specificHeatCapacityCp(state) / thermalConductivity(state);
        end prandtlNumber;

        replaceable partial function pressure  "Return pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output AbsolutePressure p "Pressure";
        end pressure;

        replaceable partial function temperature  "Return temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Temperature T "Temperature";
        end temperature;

        replaceable partial function density  "Return density"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density d "Density";
        end density;

        replaceable partial function specificEnthalpy  "Return specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnthalpy h "Specific enthalpy";
        end specificEnthalpy;

        replaceable partial function specificInternalEnergy  "Return specific internal energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy u "Specific internal energy";
        end specificInternalEnergy;

        replaceable partial function specificEntropy  "Return specific entropy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEntropy s "Specific entropy";
        end specificEntropy;

        replaceable partial function specificHeatCapacityCp  "Return specific heat capacity at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv  "Return specific heat capacity at constant volume"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
        end specificHeatCapacityCv;

        replaceable partial function isentropicExponent  "Return isentropic exponent"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsentropicExponent gamma "Isentropic exponent";
        end isentropicExponent;

        replaceable partial function isentropicEnthalpy  "Return isentropic enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p_downstream "Downstream pressure";
          input ThermodynamicState refState "Reference state for entropy";
          output SpecificEnthalpy h_is "Isentropic enthalpy";
          annotation(Documentation(info = "<html>
        <p>
        This function computes an isentropic state transformation:
        </p>
        <ol>
        <li> A medium is in a particular state, refState.</li>
        <li> The enthalpy at another state (h_is) shall be computed
             under the assumption that the state transformation from refState to h_is
             is performed with a change of specific entropy ds = 0 and the pressure of state h_is
             is p_downstream and the composition X upstream and downstream is assumed to be the same.</li>
        </ol>

        </html>"));
        end isentropicEnthalpy;

        replaceable partial function velocityOfSound  "Return velocity of sound"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output VelocityOfSound a "Velocity of sound";
        end velocityOfSound;

        replaceable partial function isobaricExpansionCoefficient  "Return overall the isobaric expansion coefficient beta"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
          annotation(Documentation(info = "<html>
        <pre>
        beta is defined as  1/v * der(v,T), with v = 1/d, at constant pressure p.
        </pre>
        </html>"));
        end isobaricExpansionCoefficient;

        replaceable partial function isothermalCompressibility  "Return overall the isothermal compressibility factor"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility";
          annotation(Documentation(info = "<html>
        <pre>

        kappa is defined as - 1/v * der(v,p), with v = 1/d at constant temperature T.

        </pre>
        </html>"));
        end isothermalCompressibility;

        replaceable partial function density_derp_h  "Return density derivative w.r.t. pressure at const specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
        end density_derp_h;

        replaceable partial function density_derh_p  "Return density derivative w.r.t. specific enthalpy at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByEnthalpy ddhp "Density derivative w.r.t. specific enthalpy";
        end density_derh_p;

        replaceable partial function density_derp_T  "Return density derivative w.r.t. pressure at const temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddpT "Density derivative w.r.t. pressure";
        end density_derp_T;

        replaceable partial function density_derT_p  "Return density derivative w.r.t. temperature at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByTemperature ddTp "Density derivative w.r.t. temperature";
        end density_derT_p;

        replaceable partial function molarMass  "Return the molar mass of the medium"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output MolarMass MM "Mixture molar mass";
        end molarMass;

        replaceable function specificEnthalpy_pTX  "Return specific enthalpy from p, T, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
          annotation(inverse(T = temperature_phX(p, h, X)));
        end specificEnthalpy_pTX;

        replaceable function temperature_phX  "Return temperature from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X));
        end temperature_phX;

        replaceable function density_phX  "Return density from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X));
        end density_phX;
        annotation(Documentation(info = "<html>
      <p>
      <b>PartialMedium</b> is a package and contains all <b>declarations</b> for
      a medium. This means that constants, models, and functions
      are defined that every medium is supposed to support
      (some of them are optional). A medium package
      inherits from <b>PartialMedium</b> and provides the
      equations for the medium. The details of this package
      are described in
      <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.
      </p>
      </html>", revisions = "<html>

      </html>"));
      end PartialMedium;

      partial package PartialPureSubstance  "Base class for pure substances of one chemical substance"
        extends PartialMedium(final reducedX = true, final fixedX = true);

        replaceable function setState_pT  "Return thermodynamic state from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_pTX(p, T, fill(0, 0));
        end setState_pT;

        replaceable function setState_ph  "Return thermodynamic state from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_phX(p, h, fill(0, 0));
        end setState_ph;

        replaceable function setState_ps  "Return thermodynamic state from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_psX(p, s, fill(0, 0));
        end setState_ps;

        replaceable function setState_dT  "Return thermodynamic state from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_dTX(d, T, fill(0, 0));
        end setState_dT;

        replaceable function density_ph  "Return density from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0, 0));
        end density_ph;

        replaceable function temperature_ph  "Return temperature from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0, 0));
        end temperature_ph;

        redeclare replaceable partial model extends BaseProperties(final standardOrderComponents = true)  end BaseProperties;
      end PartialPureSubstance;

      partial package PartialTwoPhaseMedium  "Base class for two phase medium of one substance"
        extends PartialPureSubstance(redeclare record FluidConstants = Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants);
        constant Boolean smoothModel = false "True if the (derived) model should not generate state events";
        constant Boolean onePhase = false "True if the (derived) model should never be called with two-phase inputs";
        constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

        redeclare replaceable record extends ThermodynamicState  "Thermodynamic state of two phase medium"
          FixedPhase phase(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";
        end ThermodynamicState;

        redeclare replaceable partial model extends BaseProperties  "Base properties (p, d, T, h, u, R, MM, sat) of two phase medium"
          SaturationProperties sat "Saturation properties at the medium pressure";
        end BaseProperties;

        replaceable partial function setDewState  "Return the thermodynamic state on the dew line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "Phase: default is one phase";
          output ThermodynamicState state "Complete thermodynamic state info";
        end setDewState;

        replaceable partial function setBubbleState  "Return the thermodynamic state on the bubble line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "Phase: default is one phase";
          output ThermodynamicState state "Complete thermodynamic state info";
        end setBubbleState;

        redeclare replaceable partial function extends setState_dTX  "Return thermodynamic state as function of d, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_dTX;

        redeclare replaceable partial function extends setState_phX  "Return thermodynamic state as function of p, h and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_phX;

        redeclare replaceable partial function extends setState_psX  "Return thermodynamic state as function of p, s and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_psX;

        redeclare replaceable partial function extends setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_pTX;

        replaceable function setSat_T  "Return saturation property record from temperature"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SaturationProperties sat "Saturation property record";
        algorithm
          sat.Tsat := T;
          sat.psat := saturationPressure(T);
        end setSat_T;

        replaceable function setSat_p  "Return saturation property record from pressure"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          output SaturationProperties sat "Saturation property record";
        algorithm
          sat.psat := p;
          sat.Tsat := saturationTemperature(p);
        end setSat_p;

        replaceable partial function bubbleEnthalpy  "Return bubble point specific enthalpy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEnthalpy hl "Boiling curve specific enthalpy";
        end bubbleEnthalpy;

        replaceable partial function dewEnthalpy  "Return dew point specific enthalpy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEnthalpy hv "Dew curve specific enthalpy";
        end dewEnthalpy;

        replaceable partial function bubbleEntropy  "Return bubble point specific entropy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEntropy sl "Boiling curve specific entropy";
        end bubbleEntropy;

        replaceable partial function dewEntropy  "Return dew point specific entropy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEntropy sv "Dew curve specific entropy";
        end dewEntropy;

        replaceable partial function bubbleDensity  "Return bubble point density"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output Density dl "Boiling curve density";
        end bubbleDensity;

        replaceable partial function dewDensity  "Return dew point density"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output Density dv "Dew curve density";
        end dewDensity;

        replaceable partial function saturationPressure  "Return saturation pressure"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output AbsolutePressure p "Saturation pressure";
        end saturationPressure;

        replaceable partial function saturationTemperature  "Return saturation temperature"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          output Temperature T "Saturation temperature";
        end saturationTemperature;

        replaceable function saturationPressure_sat  "Return saturation temperature"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output AbsolutePressure p "Saturation pressure";
        algorithm
          p := sat.psat;
        end saturationPressure_sat;

        replaceable function saturationTemperature_sat  "Return saturation temperature"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output Temperature T "Saturation temperature";
        algorithm
          T := sat.Tsat;
        end saturationTemperature_sat;

        replaceable partial function saturationTemperature_derp  "Return derivative of saturation temperature w.r.t. pressure"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          output DerTemperatureByPressure dTp "Derivative of saturation temperature w.r.t. pressure";
        end saturationTemperature_derp;

        replaceable function saturationTemperature_derp_sat  "Return derivative of saturation temperature w.r.t. pressure"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerTemperatureByPressure dTp "Derivative of saturation temperature w.r.t. pressure";
        algorithm
          dTp := saturationTemperature_derp(sat.psat);
        end saturationTemperature_derp_sat;

        replaceable partial function surfaceTension  "Return surface tension sigma in the two phase region"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output SurfaceTension sigma "Surface tension sigma in the two phase region";
        end surfaceTension;

        redeclare replaceable function extends molarMass  "Return the molar mass of the medium"
        algorithm
          MM := fluidConstants[1].molarMass;
        end molarMass;

        replaceable partial function dBubbleDensity_dPressure  "Return bubble point density derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerDensityByPressure ddldp "Boiling curve density derivative";
        end dBubbleDensity_dPressure;

        replaceable partial function dDewDensity_dPressure  "Return dew point density derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerDensityByPressure ddvdp "Saturated steam density derivative";
        end dDewDensity_dPressure;

        replaceable partial function dBubbleEnthalpy_dPressure  "Return bubble point specific enthalpy derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerEnthalpyByPressure dhldp "Boiling curve specific enthalpy derivative";
        end dBubbleEnthalpy_dPressure;

        replaceable partial function dDewEnthalpy_dPressure  "Return dew point specific enthalpy derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerEnthalpyByPressure dhvdp "Saturated steam specific enthalpy derivative";
        end dDewEnthalpy_dPressure;

        redeclare replaceable function specificEnthalpy_pTX  "Return specific enthalpy from pressure, temperature and mass fraction"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy at p, T, X";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X, phase));
        end specificEnthalpy_pTX;

        redeclare replaceable function temperature_phX  "Return temperature from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X, phase));
        end temperature_phX;

        redeclare replaceable function density_phX  "Return density from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X, phase));
        end density_phX;

        redeclare replaceable function setState_pT  "Return thermodynamic state from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_pTX(p, T, fill(0, 0), phase);
        end setState_pT;

        redeclare replaceable function setState_ph  "Return thermodynamic state from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_phX(p, h, fill(0, 0), phase);
        end setState_ph;

        redeclare replaceable function setState_ps  "Return thermodynamic state from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_psX(p, s, fill(0, 0), phase);
        end setState_ps;

        redeclare replaceable function setState_dT  "Return thermodynamic state from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_dTX(d, T, fill(0, 0), phase);
        end setState_dT;

        redeclare replaceable function density_ph  "Return density from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0, 0), phase);
        end density_ph;

        redeclare replaceable function temperature_ph  "Return temperature from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0, 0), phase);
        end temperature_ph;
      end PartialTwoPhaseMedium;

      package Choices  "Types, constants to define menu choices"
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
        annotation(Documentation(info = "<html>
      <p>
      Enumerations and data types for all types of fluids
      </p>

      <p>
      Note: Reference enthalpy might have to be extended with enthalpy of formation.
      </p>
      </html>"));
      end Choices;

      package Types  "Types to be used in fluid models"
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5) "Type for absolute pressure with medium specific attributes";
        type Density = .Modelica.SIunits.Density(min = 0, max = 1.e5, nominal = 1, start = 1) "Type for density with medium specific attributes";
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3) "Type for dynamic viscosity with medium specific attributes";
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
        type MolarMass = .Modelica.SIunits.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
        type MolarVolume = .Modelica.SIunits.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0) "Type for molar volume with medium specific attributes";
        type IsentropicExponent = .Modelica.SIunits.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2) "Type for isentropic exponent with medium specific attributes";
        type SpecificEnergy = .Modelica.SIunits.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6) "Type for specific energy with medium specific attributes";
        type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
        type SpecificEnthalpy = .Modelica.SIunits.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6) "Type for specific enthalpy with medium specific attributes";
        type SpecificEntropy = .Modelica.SIunits.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3) "Type for specific entropy with medium specific attributes";
        type SpecificHeatCapacity = .Modelica.SIunits.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3) "Type for specific heat capacity with medium specific attributes";
        type SurfaceTension = .Modelica.SIunits.SurfaceTension "Type for surface tension with medium specific attributes";
        type Temperature = .Modelica.SIunits.Temperature(min = 1, max = 1.e4, nominal = 300, start = 300) "Type for temperature with medium specific attributes";
        type ThermalConductivity = .Modelica.SIunits.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
        type PrandtlNumber = .Modelica.SIunits.PrandtlNumber(min = 1e-3, max = 1e5, nominal = 1.0) "Type for Prandtl number with medium specific attributes";
        type VelocityOfSound = .Modelica.SIunits.Velocity(min = 0, max = 1.e5, nominal = 1000, start = 1000) "Type for velocity of sound with medium specific attributes";
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
        type DerDensityByPressure = .Modelica.SIunits.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";
        type DerDensityByEnthalpy = .Modelica.SIunits.DerDensityByEnthalpy "Type for partial derivative of density with respect to enthalpy with medium specific attributes";
        type DerEnthalpyByPressure = .Modelica.SIunits.DerEnthalpyByPressure "Type for partial derivative of enthalpy with respect to pressure with medium specific attributes";
        type DerDensityByTemperature = .Modelica.SIunits.DerDensityByTemperature "Type for partial derivative of density with respect to temperature with medium specific attributes";
        type DerTemperatureByPressure = Real(final unit = "K/Pa") "Type for partial derivative of temperature with respect to pressure with medium specific attributes";

        replaceable record SaturationProperties  "Saturation properties of two phase medium"
          extends Modelica.Icons.Record;
          AbsolutePressure psat "Saturation pressure";
          Temperature Tsat "Saturation temperature";
        end SaturationProperties;

        type FixedPhase = Integer(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";

        package Basic  "The most basic version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Critical, triple, molecular and other standard data of fluid"
            extends Modelica.Icons.Record;
            String iupacName "Complete IUPAC name (or common name, if non-existent)";
            String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
            String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
            String structureFormula "Chemical structure formula";
            MolarMass molarMass "Molar mass";
          end FluidConstants;
        end Basic;

        package TwoPhase  "The two phase fluid version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Extended fluid constants"
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature "Critical temperature";
            AbsolutePressure criticalPressure "Critical pressure";
            MolarVolume criticalMolarVolume "Critical molar Volume";
            Real acentricFactor "Pitzer acentric factor";
            Temperature triplePointTemperature "Triple point temperature";
            AbsolutePressure triplePointPressure "Triple point pressure";
            Temperature meltingPoint "Melting point at 101325 Pa";
            Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
            DipoleMoment dipoleMoment "Dipole moment of molecule in Debye (1 debye = 3.33564e10-30 C.m)";
            Boolean hasIdealGasHeatCapacity = false "True if ideal gas heat capacity is available";
            Boolean hasCriticalData = false "True if critical data are known";
            Boolean hasDipoleMoment = false "True if a dipole moment known";
            Boolean hasFundamentalEquation = false "True if a fundamental equation";
            Boolean hasLiquidHeatCapacity = false "True if liquid heat capacity is available";
            Boolean hasSolidHeatCapacity = false "True if solid heat capacity is available";
            Boolean hasAccurateViscosityData = false "True if accurate data for a viscosity function is available";
            Boolean hasAccurateConductivityData = false "True if accurate data for thermal conductivity is available";
            Boolean hasVapourPressureCurve = false "True if vapour pressure data, e.g., Antoine coefficents are known";
            Boolean hasAcentricFactor = false "True if Pitzer accentric factor is known";
            SpecificEnthalpy HCRIT0 = 0.0 "Critical specific enthalpy of the fundamental equation";
            SpecificEntropy SCRIT0 = 0.0 "Critical specific entropy of the fundamental equation";
            SpecificEnthalpy deltah = 0.0 "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
            SpecificEntropy deltas = 0.0 "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
          end FluidConstants;
        end TwoPhase;
      end Types;
      annotation(Documentation(info = "<HTML>
    <p>
    This package provides basic interfaces definitions of media models for different
    kind of media.
    </p>
    </HTML>"));
    end Interfaces;
    annotation(preferredView = "info", Documentation(info = "<HTML>
  <p>
  This library contains <a href=\"modelica://Modelica.Media.Interfaces\">interface</a>
  definitions for media and the following <b>property</b> models for
  single and multiple substance fluids with one and multiple phases:
  </p>
  <ul>
  <li> <a href=\"modelica://Modelica.Media.IdealGases\">Ideal gases:</a><br>
       1241 high precision gas models based on the
       NASA Glenn coefficients, plus ideal gas mixture models based
       on the same data.</li>
  <li> <a href=\"modelica://Modelica.Media.Water\">Water models:</a><br>
       ConstantPropertyLiquidWater, WaterIF97 (high precision
       water model according to the IAPWS/IF97 standard)</li>
  <li> <a href=\"modelica://Modelica.Media.Air\">Air models:</a><br>
       SimpleAir, DryAirNasa, ReferenceAir, MoistAir, ReferenceMoistAir.</li>
  <li> <a href=\"modelica://Modelica.Media.Incompressible\">
       Incompressible media:</a><br>
       TableBased incompressible fluid models (properties are defined by tables rho(T),
       HeatCapacity_cp(T), etc.)</li>
  <li> <a href=\"modelica://Modelica.Media.CompressibleLiquids\">
       Compressible liquids:</a><br>
       Simple liquid models with linear compressibility</li>
  <li> <a href=\"modelica://Modelica.Media.R134a\">Refrigerant Tetrafluoroethane (R134a)</a>.</li>
  </ul>
  <p>
  The following parts are useful, when newly starting with this library:
  <ul>
  <li> <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.</li>
  <li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage\">Modelica.Media.UsersGuide.MediumUsage</a>
       describes how to use a medium model in a component model.</li>
  <li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumDefinition\">
       Modelica.Media.UsersGuide.MediumDefinition</a>
       describes how a new fluid medium model has to be implemented.</li>
  <li> <a href=\"modelica://Modelica.Media.UsersGuide.ReleaseNotes\">Modelica.Media.UsersGuide.ReleaseNotes</a>
       summarizes the changes of the library releases.</li>
  <li> <a href=\"modelica://Modelica.Media.Examples\">Modelica.Media.Examples</a>
       contains examples that demonstrate the usage of this library.</li>
  </ul>
  <p>
  Copyright &copy; 1998-2013, Modelica Association.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </HTML>", revisions = "<html>
  <ul>
  <li><i>May 16, 2013</i> by Stefan Wischhusen (XRG Simulation):<br/>
      Added new media models Air.ReferenceMoistAir, Air.ReferenceAir, R134a.</li>
  <li><i>May 25, 2011</i> by Francesco Casella:<br/>Added min/max attributes to Water, TableBased, MixtureGasNasa, SimpleAir and MoistAir local types.</li>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added individual settings for polynomial fittings of properties.</li>
  </ul>
  </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-76, -80}, {-62, -30}, {-32, 40}, {4, 66}, {48, 66}, {73, 45}, {62, -8}, {48, -50}, {38, -80}}, color = {64, 64, 64}, smooth = Smooth.Bezier), Line(points = {{-40, 20}, {68, 20}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-40, 20}, {-44, 88}, {-44, 88}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{68, 20}, {86, -58}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {56, -28}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {-74, 84}, {-74, 84}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{56, -28}, {70, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {38, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {-94, -16}, {-94, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}));
  end Media;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Icon for a mathematical function, consisting of an y-axis in the middle.
      It is expected, that an x-axis is added and a plot of the function.
      </p>
      </html>")); end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
      <p>
      This function returns y = asin(u), with -1 &le; u &le; +1:
      </p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
      </p>
      </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
      <p>
      This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
      </p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
      </p>
      </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
    end exp;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
  <p>
  This package contains <b>basic mathematical functions</b> (such as sin(..)),
  as well as functions operating on
  <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
  <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
  <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
  <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
  </p>

  <dl>
  <dt><b>Main Authors:</b>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
      Marcus Baur<br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
      Institut f&uuml;r Robotik und Mechatronik<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      Germany<br>
      email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
  </dl>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>October 21, 2002</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
         Function tempInterpol2 added.</li>
  <li><i>Oct. 24, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Icons for icon and diagram level introduced.</li>
  <li><i>June 30, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>

  </html>"));
  end Math;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real R(final unit = "J/(mol.K)") = 8.314472 "Molar gas constant";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
    annotation(Documentation(info = "<html>
  <p>
  This package provides often needed constants from mathematics, machine
  dependent constants and constants from nature. The latter constants
  (name, value, description) are from the following source:
  </p>

  <dl>
  <dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
  <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
      Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
      Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
  \"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
  </dl>

  <p>CODATA is the Committee on Data for Science and Technology.</p>

  <dl>
  <dt><b>Main Author:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 11 16<br>
      D-82230 We&szlig;ling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>Nov 8, 2004</i>
         by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
         Constants updated according to 2002 CODATA values.</li>
  <li><i>Dec 9, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants updated according to 1998 CODATA values. Using names, values
         and description text from this source. Included magnetic and
         electric constant.</li>
  <li><i>Sep 18, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants eps, inf, small introduced.</li>
  <li><i>Nov 15, 1997</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>
  </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986, 37.145}, {9.986, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.071}, {13.336, 0.071}, {7.515, -9.983}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)}));
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {8.0, 14.0}, lineColor = {78, 138, 73}, fillColor = {78, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-58.0, 46.0}, {42.0, -14.0}, {-58.0, -74.0}, {-58.0, 46.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains executable examples.</p>
    </html>"));
    end ExamplesPackage;

    partial model Example  "Icon for runnable examples"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {75, 138, 73}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Polygon(lineColor = {0, 0, 255}, fillColor = {75, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-36, 60}, {64, 0}, {-36, -60}, {-36, 60}})}), Documentation(info = "<html>
    <p>This icon indicates an example. The play button suggests that the example can be executed.</p>
    </html>")); end Example;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
    <p>Standard package icon.</p>
    </html>")); end Package;

    partial package BasesPackage  "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-30.0, -30.0}, {30.0, 30.0}}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
    <p>This icon shall be used for a package/library that contains base models and classes, respectively.</p>
    </html>"));
    end BasesPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
    <p>This icon indicates packages containing interfaces.</p>
    </html>"));
    end InterfacesPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {102, 102, 102}, fillColor = {204, 204, 204}, pattern = LinePattern.None, fillPattern = FillPattern.Sphere, extent = {{-60.0, -60.0}, {60.0, 60.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains properties</p>
    </html>"));
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
    <p>This icon indicates Modelica functions.</p>
    </html>")); end Function;

    partial record Record  "Icon for records"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 60}, {150, 100}}, textString = "%name"), Rectangle(origin = {0.0, -25.0}, lineColor = {64, 64, 64}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100.0, -75.0}, {100.0, 75.0}}, radius = 25.0), Line(points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -50.0}, points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -25.0}, points = {{0.0, 75.0}, {0.0, -75.0}}, color = {64, 64, 64})}), Documentation(info = "<html>
    <p>
    This icon is indicates a record.
    </p>
    </html>")); end Record;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}), Documentation(info = "<html>
  <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

  <h4>Main Authors:</h4>

  <dl>
  <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
      <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
      <dd>Oberpfaffenhofen</dd>
      <dd>Postfach 1116</dd>
      <dd>D-82230 Wessling</dd>
      <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  <dt>Christian Kral</dt>
      <dd><a href=\"http://christiankral.net/\">Electric Machines, Drives and Systems</a></dd>
      <dd>1060 Vienna, Austria</dd>
      <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
  <dt>Johan Andreasson</dt>
      <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
      <dd>Ideon Science Park</dd>
      <dd>22370 Lund, Sweden</dd>
      <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
  </dl>

  <p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>
  <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
  </html>"));
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Icons  "Icons for SIunits"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  "Base icon for conversion functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-90, 0}, {30, 0}}, color = {191, 0, 0}), Polygon(points = {{90, 0}, {30, 20}, {30, -20}, {90, 0}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-115, 155}, {115, 105}}, textString = "%name", lineColor = {0, 0, 255})})); end Conversion;
    end Icons;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar") "Absolute pressure in bar";
        annotation(Documentation(info = "<HTML>
      <p>
      This package provides predefined types, such as <b>Angle_deg</b> (angle in
      degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
      minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
      which are in common use but are not part of the international standard on
      units according to ISO 31-1992 \"General principles concerning quantities,
      units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
      the use of their multiples and of certain other units\".</p>
      <p>If possible, the types in this package should not be used. Use instead
      types of package Modelica.SIunits. For more information on units, see also
      the book of Francois Cardarelli <b>Scientific Unit Conversion - A
      Practical Guide to Metrication</b> (Springer 1997).</p>
      <p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
      Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
      definitions have been placed erroneously in Modelica.SIunits although they
      are not SIunits. For backward compatibility, these type definitions are
      still kept in Modelica.SIunits.</p>
      </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, lineColor = {0, 0, 0}, textString = "[km/h]")}));
      end NonSIunits;

      function to_degC  "Convert from Kelvin to degCelsius"
        extends Modelica.SIunits.Icons.Conversion;
        input Temperature Kelvin "Kelvin value";
        output NonSIunits.Temperature_degC Celsius "Celsius value";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "K"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "degC")}));
      end to_degC;

      function from_degC  "Convert from degCelsius to Kelvin"
        extends Modelica.SIunits.Icons.Conversion;
        input NonSIunits.Temperature_degC Celsius "Celsius value";
        output Temperature Kelvin "Kelvin value";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "degC"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "K")}));
      end from_degC;

      function to_bar  "Convert from Pascal to bar"
        extends Modelica.SIunits.Icons.Conversion;
        input Pressure Pa "Pascal value";
        output NonSIunits.Pressure_bar bar "bar value";
      algorithm
        bar := Pa / 1e5;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-12, 100}, {-100, 56}}, lineColor = {0, 0, 0}, textString = "Pa"), Text(extent = {{98, -52}, {-4, -100}}, lineColor = {0, 0, 0}, textString = "bar")}));
      end to_bar;
      annotation(Documentation(info = "<HTML>
    <p>This package provides conversion functions from the non SI Units
    defined in package Modelica.SIunits.Conversions.NonSIunits to the
    corresponding SI Units defined in package Modelica.SIunits and vice
    versa. It is recommended to use these functions in the following
    way (note, that all functions have one Real input and one Real output
    argument):</p>
    <pre>
      <b>import</b> SI = Modelica.SIunits;
      <b>import</b> Modelica.SIunits.Conversions.*;
         ...
      <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
      <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
      <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                          // to radian per seconds
    </pre>

    </html>"));
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type SurfaceTension = Real(final quantity = "SurfaceTension", final unit = "N/m");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type CubicExpansionCoefficient = Real(final quantity = "CubicExpansionCoefficient", final unit = "1/K");
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificEnthalpy = SpecificEnergy;
    type DerDensityByEnthalpy = Real(final unit = "kg.s2/m5");
    type DerDensityByPressure = Real(final unit = "s2/m2");
    type DerDensityByTemperature = Real(final unit = "kg/(m3.K)");
    type DerEnthalpyByPressure = Real(final unit = "J.m.s2/kg2");
    type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
    type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
    type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    type PrandtlNumber = Real(final quantity = "PrandtlNumber", final unit = "1");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
  <p>This package provides predefined types, such as <i>Mass</i>,
  <i>Angle</i>, <i>Time</i>, based on the international standard
  on units, e.g.,
  </p>

  <pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                       <b>final</b> unit     = \"rad\",
                       displayUnit    = \"deg\");
  </pre>

  <p>
  as well as conversion functions from non SI-units to SI-units
  and vice versa in subpackage
  <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
  </p>

  <p>
  For an introduction how units are used in the Modelica standard library
  with package SIunits, have a look at:
  <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
  </p>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
  <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
  <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
  <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
  <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
  <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
  <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
  <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
  <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
  <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
  <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
  </ul>
  </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.1", versionBuild = 3, versionDate = "2013-08-14", dateModified = "2014-06-27 19:30:00Z", revisionId = "$Id:: package.mo 7762 2014-06-27 09:35:59Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>
<p>
Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><b>1360</b> models and blocks, and</li>
<li><b>1280</b> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.&nbsp;Haumer, ITI, C.&nbsp;Kral, Modelon,
TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

<p>
<b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;

model TestState_total  "Test case using TestMedium with a single state record"
  extends ExternalMedia.Test.TestMedium.TestState;
end TestState_total;

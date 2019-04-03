package Modelica "Modelica Standard Library (Version 3.1)"

  package SIunits "Library of type and unit definitions based on SI units according to ISO 31-1992"
    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      package NonSIunits "Type definitions of non SI units"
        type Volume_litre= Real(final quantity="Volume", final unit="l") "Volume in litres";
      end NonSIunits;
    end Conversions;

    type Angle= Real(final quantity="Angle", final unit="rad", displayUnit="deg");
  end SIunits;

end Modelica;
package BioChem
  package Math
  end Math;

  package Units "Units used in BioChem"
    type Volume= Modelica.SIunits.Conversions.NonSIunits.Volume_litre;
    type StoichiometricCoefficient= Real(quantity="Stoichiometric coefficient", unit="1");
    type ReactionRate= Real(quantity="Reaction rate", unit="mol/s");
    type MolarFlowRate= Real(quantity="Molar flow rate", unit="mol/s");
    type Concentration= Real(quantity="Concentration", unit="mol/l", min=0);
    type AmountOfSubstance= Real(quantity="AmountOfSubstance", unit="mol", min=0);
  end Units;

  package Substances "Reaction nodes"
    model Substance "Substance with variable concentration"
      extends BioChem.Interfaces.Substances.Substance;
    equation
      der(n)=rNet;
    end Substance;

    model AmbientSubstance "Substance used as a reservoir in reactions"
      extends BioChem.Interfaces.Substances.Substance;
    equation
      der(n)=0;
    end AmbientSubstance;

  end Substances;

  package Interfaces "Connection points and icons used in the BioChem package"
    package Substances
      partial model Substance "Basics for a substance"
        BioChem.Units.Concentration c(stateSelect=StateSelect.prefer) "Current concentration of substance (mM)";
        BioChem.Units.MolarFlowRate rNet "Net flow rate of substance into the node";
        BioChem.Units.AmountOfSubstance n(stateSelect=StateSelect.prefer) "Number of moles of substance in pool (mol)";
        BioChem.Interfaces.Nodes.SubstanceConnector n1;
      protected
        outer BioChem.Units.Volume V "Compartment volume";
      equation
        rNet=n1.r;
        c=n1.c;
        V=n1.V;
        c=n/V;
      end Substance;

    end Substances;

    package Reactions "Partial models, extended by models in the subpackage Reactions"
      partial model Uui "Uni-Uni irreversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.OneSubstrate;
        extends BioChem.Interfaces.Reactions.Basics.OneProduct;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for the substrate";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for the product";
      equation
        s1.r=nS1*rr;
        p1.r=-nP1*rr;
      end Uui;

      package Modifiers "Partial models of modifiers to reactions"
        model Modifier
          BioChem.Interfaces.Nodes.ModifierConnector m1;
        equation
          m1.r=0;
        end Modifier;

      end Modifiers;

      package Basics "Basic properties of reactions"
        partial model OneSubstrate "SubstanceConnector for one substrate"
          BioChem.Interfaces.Nodes.SubstrateConnector s1;
        end OneSubstrate;

        partial model OneProduct "SubstanceConnector for one product"
          BioChem.Interfaces.Nodes.ProductConnector p1;
        end OneProduct;

        partial model Reaction "Basics for a reaction edge"
          BioChem.Units.ReactionRate rr "Rate of the reaction";
        end Reaction;

      end Basics;

    end Reactions;

    package Nodes "Connector interfaces used in the package"
      connector SubstrateConnector "Connector between substances and reactions (substrate side of reaction)"
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end SubstrateConnector;

      connector SubstanceConnector "Connector between substances and reactions"
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        output BioChem.Units.Volume V;
      end SubstanceConnector;

      connector ProductConnector "Connector between substances and reactions (product side of reaction)"
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end ProductConnector;

      connector ModifierConnector "Connector between general modifieres and reactions"
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end ModifierConnector;

    end Nodes;

    package Compartments "Properties for compartments"
      partial model Compartment "Default properties for a compartment"
        inner BioChem.Units.Volume V(start=1, stateSelect=StateSelect.prefer) "Compartment volume";
      end Compartment;

      partial model MainCompartment "Default properties for a compartment."
        extends BioChem.Interfaces.Compartments.Compartment;
      end MainCompartment;

    end Compartments;

  end Interfaces;

  package Examples "Some examples of BioChem models"
    package CircadianOscillator "Weimann2004_CircadianOscillator"
      model Container
        extends BioChem.Compartments.MainCompartment/*(V(start=1))*/;
        import BioChem.Math.*;
        import BioChem.Constants.*;
        BioChem.Examples.CircadianOscillator.Nucleus nucleus(k3t=k3t, k3d=k3d, k6t=k6t, k6d=k6d, k6a=k6a, k7a=k7a, k7d=k7d);
        Cytoplasm cytoplasm(trans_per2_cry=trans_per2_cry, k1d=k1d, k2b=k2b, q=q, k2d=k2d, k2t=k2t, trans_Bmal1=trans_Bmal1, k4d=k4d, k5b=k5b, k5d=k5d, k5t=k5t);
        inner Real Nucleus_V=nucleus.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        inner Real Cytoplasm_V=cytoplasm.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        inner Real Container_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        Real trans_per2_cry(start=0);
        parameter Real v1b=9;
        parameter Real c_sbml=0.01;
        parameter Real k1b=1;
        parameter Real k1i=0.56;
        parameter Real hill_coeff=8;
        Real trans_Bmal1(start=0);
        parameter Real v4b=3.6;
        parameter Real r_sbml=3;
        parameter Real k4b=2.16;
        Real y5_y6_y7(start=3.05);
        parameter Real k1d=0.12;
        parameter Real k2b=0.3;
        parameter Real q=2;
        parameter Real k2d=0.05;
        parameter Real k2t=0.24;
        parameter Real k3t=0.02;
        parameter Real k3d=0.12;
        parameter Real k4d=0.75;
        parameter Real k5b=0.24;
        parameter Real k5d=0.06;
        parameter Real k5t=0.45;
        parameter Real k6t=0.06;
        parameter Real k6d=0.12;
        parameter Real k6a=0.09;
        parameter Real k7a=0.003;
        parameter Real k7d=0.09;
      equation
        connect(cytoplasm.y5_node,nucleus.y5_node);
        connect(nucleus.y6_node,cytoplasm.y6_node);
        connect(cytoplasm.y2_node,nucleus.y2_node);
        connect(nucleus.y3_node,cytoplasm.y3_node);
        trans_per2_cry=v1b*(nucleus.y7.c + c_sbml)/(k1b*(1 + (nucleus.y3.c/k1i)^hill_coeff) + nucleus.y7.c + c_sbml);
        trans_Bmal1=v4b*nucleus.y3.c^r_sbml/(k4b^r_sbml + nucleus.y3.c^r_sbml);
        y5_y6_y7=cytoplasm.y5.c + nucleus.y6.c + nucleus.y7.c;
      end Container;

      model Nucleus "Nucleus"
        extends BioChem.Compartments.Compartment(V(start=1));
        model y3_
          extends BioChem.Substances.Substance;
        end y3_;

        model y6_
          extends BioChem.Substances.Substance;
        end y6_;

        model y7_
          extends BioChem.Substances.Substance;
        end y7_;

        model per2_cry_nuclear_export_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k3t;
        equation
          rr=Nucleus_V*k3t*s1.c;
        end per2_cry_nuclear_export_;

        model nuclear_per2_cry_complex_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k3d;
        equation
          rr=Nucleus_V*k3d*s1.c;
        end nuclear_per2_cry_complex_degradation_;

        model BMAL1_nuclear_export_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6t;
        equation
          rr=Nucleus_V*k6t*s1.c;
        end BMAL1_nuclear_export_;

        model nuclear_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6d;
        equation
          rr=Nucleus_V*k6d*s1.c;
        end nuclear_BMAL1_degradation_;

        model BMAL1_activation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6a;
        equation
          rr=Nucleus_V*k6a*s1.c;
        end BMAL1_activation_;

        model BMAL1_deactivation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k7a;
        equation
          rr=Nucleus_V*k7a*s1.c;
        end BMAL1_deactivation_;

        model Active_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k7d;
        equation
          rr=Nucleus_V*k7d*s1.c;
        end Active_BMAL1_degradation_;

        inner Real Nucleus_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        BioChem.Examples.CircadianOscillator.Nucleus.y3_ y3(c(start=1.1));
        BioChem.Examples.CircadianOscillator.Nucleus.y6_ y6(c(start=1));
        BioChem.Examples.CircadianOscillator.Nucleus.y7_ y7(c(start=1.05));
        BioChem.Interfaces.Nodes.SubstanceConnector y3_node;
        parameter Real k3t;
        BioChem.Interfaces.Nodes.SubstanceConnector y2_node;
        BioChem.Examples.CircadianOscillator.Nucleus.per2_cry_nuclear_export_ per2_cry_nuclear_export(k3t=k3t);
        BioChem.Substances.AmbientSubstance ambientSubstance;
        parameter Real k3d;
        BioChem.Examples.CircadianOscillator.Nucleus.nuclear_per2_cry_complex_degradation_ nuclear_per2_cry_complex_degradation(k3d=k3d);
        BioChem.Interfaces.Nodes.SubstanceConnector y6_node;
        parameter Real k6t;
        BioChem.Interfaces.Nodes.SubstanceConnector y5_node;
        Nucleus.BMAL1_nuclear_export_ BMAL1_nuclear_export(k6t=k6t);
        parameter Real k6d;
        BioChem.Examples.CircadianOscillator.Nucleus.nuclear_BMAL1_degradation_ nuclear_BMAL1_degradation(k6d=k6d);
        parameter Real k6a;
        Nucleus.BMAL1_activation_ BMAL1_activation(k6a=k6a);
        parameter Real k7a;
        Nucleus.BMAL1_deactivation_ BMAL1_deactivation(k7a=k7a);
        parameter Real k7d;
        BioChem.Examples.CircadianOscillator.Nucleus.Active_BMAL1_degradation_ Active_BMAL1_degradation(k7d=k7d);
      equation
        connect(y3.n1,nuclear_per2_cry_complex_degradation.s1);
        connect(y3.n1,per2_cry_nuclear_export.s1);
        connect(y3.n1,y3_node);
        connect(y7.n1,BMAL1_activation.p1);
        connect(y7.n1,Active_BMAL1_degradation.s1);
        connect(y7.n1,BMAL1_deactivation.s1);
        connect(y6.n1,BMAL1_deactivation.p1);
        connect(y6.n1,BMAL1_activation.s1);
        connect(y6.n1,nuclear_BMAL1_degradation.s1);
        connect(y6.n1,BMAL1_nuclear_export.s1);
        connect(y6.n1,y6_node);
        connect(ambientSubstance.n1,nuclear_per2_cry_complex_degradation.p1);
        connect(ambientSubstance.n1,nuclear_BMAL1_degradation.p1);
        connect(BMAL1_nuclear_export.p1,y5_node);
        connect(per2_cry_nuclear_export.p1,y2_node);
        connect(ambientSubstance.n1,Active_BMAL1_degradation.p1);
      end Nucleus;

      model Cytoplasm "Cytoplasm"
        extends BioChem.Compartments.Compartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        model y1_
          extends BioChem.Substances.Substance;
        end y1_;

        model y2_
          extends BioChem.Substances.Substance;
        end y2_;

        model y4_
          extends BioChem.Substances.Substance;
        end y4_;

        model y5_
          extends BioChem.Substances.Substance;
        end y5_;

        model per2_cry_transcription_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real trans_per2_cry;
        equation
          rr=Cytoplasm_V*trans_per2_cry;
        end per2_cry_transcription_;

        model per2_cry_mRNA_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k1d;
        equation
          rr=Cytoplasm_V*k1d*s1.c;
        end per2_cry_mRNA_degradation_;

        model per2_cry_complex_formation_
          extends BioChem.Interfaces.Reactions.Uui;
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2b;
          parameter Real q;
        equation
          rr=Cytoplasm_V*k2b*m1.c^q;
        end per2_cry_complex_formation_;

        model cytoplasmic_per2_cry_complex_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2d;
        equation
          rr=Cytoplasm_V*k2d*s1.c;
        end cytoplasmic_per2_cry_complex_degradation_;

        model per2_cry_nuclear_import_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2t;
        equation
          rr=Cytoplasm_V*k2t*s1.c;
        end per2_cry_nuclear_import_;

        model Bmal1_transcription_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real trans_Bmal1;
        equation
          rr=Cytoplasm_V*trans_Bmal1;
        end Bmal1_transcription_;

        model Bmal1_mRNA_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k4d;
        equation
          rr=Cytoplasm_V*k4d*s1.c;
        end Bmal1_mRNA_degradation_;

        model BMAL1_translation_
          extends BioChem.Interfaces.Reactions.Uui;
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5b;
        equation
          rr=Cytoplasm_V*k5b*m1.c;
        end BMAL1_translation_;

        model cytoplasmic_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5d;
        equation
          rr=Cytoplasm_V*k5d*s1.c;
        end cytoplasmic_BMAL1_degradation_;

        model BMAL1_nuclear_import_
          extends BioChem.Interfaces.Reactions.Uui;
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5t;
        equation
          rr=Cytoplasm_V*k5t*s1.c;
        end BMAL1_nuclear_import_;

        inner Real Cytoplasm_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        Cytoplasm.y1_ y1(c(start=0.2));
        Cytoplasm.y2_ y2(c(start=0));
        Cytoplasm.y4_ y4(c(start=0.8));
        Cytoplasm.y5_ y5(c(start=1));
        BioChem.Substances.AmbientSubstance ambientSubstance;
        input Real trans_per2_cry;
        Cytoplasm.per2_cry_transcription_ per2_cry_transcription(trans_per2_cry=trans_per2_cry);
        parameter Real k1d;
        Cytoplasm.per2_cry_mRNA_degradation_ per2_cry_mRNA_degradation(k1d=k1d);
        parameter Real k2b;
        parameter Real q;
        Cytoplasm.per2_cry_complex_formation_ per2_cry_complex_formation(k2b=k2b, q=q);
        parameter Real k2d;
        Cytoplasm.cytoplasmic_per2_cry_complex_degradation_ cytoplasmic_per2_cry_complex_degradation(k2d=k2d);
        parameter Real k2t;
        BioChem.Interfaces.Nodes.SubstanceConnector y3_node;
        Cytoplasm.per2_cry_nuclear_import_ per2_cry_nuclear_import(k2t=k2t);
        BioChem.Interfaces.Nodes.SubstanceConnector y2_node;
        input Real trans_Bmal1;
        Cytoplasm.Bmal1_transcription_ Bmal1_transcription(trans_Bmal1=trans_Bmal1);
        parameter Real k4d;
        Cytoplasm.Bmal1_mRNA_degradation_ Bmal1_mRNA_degradation(k4d=k4d);
        parameter Real k5b;
        Cytoplasm.BMAL1_translation_ BMAL1_translation(k5b=k5b);
        parameter Real k5d;
        Cytoplasm.cytoplasmic_BMAL1_degradation_ cytoplasmic_BMAL1_degradation(k5d=k5d);
        parameter Real k5t;
        BioChem.Interfaces.Nodes.SubstanceConnector y6_node;
        Cytoplasm.BMAL1_nuclear_import_ BMAL1_nuclear_import(k5t=k5t);
        BioChem.Interfaces.Nodes.SubstanceConnector y5_node;
      equation
        connect(BMAL1_nuclear_import.p1,y6_node) annotation(Line(visible=true, origin={128.8,-92.4506}, points={{-78.8,1.2006},{-78.8,-3.0509},{48.2,-3.0509},{48.2,2.4506},{61.2,2.4506}}, smooth=Smooth.Bezier));
        connect(y2.n1,y2_node) annotation(Line(visible=true, origin={169.0149,-25.9149}, points={{-29.0149,4.0851},{8.5,4.0851},{8.5,-4.0851},{20.9851,-4.0851}}, smooth=Smooth.Bezier));
        connect(per2_cry_nuclear_import.p1,y3_node) annotation(Line(visible=true, origin={183.3333,27.0833}, points={{-3.3333,-5.8333},{-3.3333,2.9167},{6.6667,2.9167}}, smooth=Smooth.Bezier));
        connect(y5.n1,y5_node) annotation(Line(visible=true, origin={121.75,70.0}, points={{-101.75,-50.0},{-41.75,30.0},{65.25,10.0},{68.25,10.0}}, smooth=Smooth.Bezier));
        connect(y2.n1,per2_cry_nuclear_import.s1) annotation(Line(visible=true, origin={166.6667,-14.9699}, points={{-26.6667,-6.8599},{13.3333,-6.8599},{13.3333,13.7199}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_complex_formation.m1) annotation(Line(visible=true, origin={167.0495,33.3333}, points={{2.9505,26.6667},{2.9505,-13.3333},{-5.9009,-13.3333}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_complex_formation.s1) annotation(Line(visible=true, origin={120.0594,32.4506}, points={{-30.0594,-2.4506},{-17.0594,-2.4506},{-17.0594,3.0509},{32.0892,3.0509},{32.0892,-1.2006}}, smooth=Smooth.Bezier));
        connect(y2.n1,per2_cry_complex_formation.p1) annotation(Line(visible=true, origin={146.0743,-1.0207}, points={{-6.0743,-20.8091},{-6.0743,5.5192},{6.0743,5.5192},{6.0743,9.7707}}, smooth=Smooth.Bezier));
        connect(y2.n1,cytoplasmic_per2_cry_complex_degradation.s1) annotation(Line(visible=true, origin={130.0,-8.5207}, points={{10.0,-13.3091},{10.0,3.0192},{-10.0,3.0192},{-10.0,7.2707}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,cytoplasmic_per2_cry_complex_degradation.p1) annotation(Line(visible=true, origin={110.0,27.0833}, points={{-20.0,2.9167},{10.0,2.9167},{10.0,-5.8333}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_transcription.p1) annotation(Line(visible=true, origin={150.5633,55.0}, points={{19.4367,5.0},{-5.0617,5.0},{-5.0617,-5.0},{-9.3133,-5.0}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_mRNA_degradation.s1) annotation(Line(visible=true, origin={150.5633,65.0}, points={{19.4367,-5.0},{-5.0617,-5.0},{-5.0617,5.0},{-9.3133,5.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_mRNA_degradation.p1) annotation(Line(visible=true, origin={99.5833,56.6667}, points={{-9.5833,-26.6667},{-9.5833,13.3333},{19.1667,13.3333}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_transcription.s1) annotation(Line(visible=true, origin={106.872,42.5}, points={{-16.872,-12.5},{-2.6325,-2.5},{7.6265,7.5},{11.878,7.5}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,BMAL1_translation.s1) annotation(Line(visible=true, origin={83.75,10.0}, points={{6.25,20.0},{6.25,-10.0},{-12.5,-10.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,Bmal1_mRNA_degradation.p1) annotation(Line(visible=true, origin={95.0,-4.4367}, points={{-5.0,34.4367},{-5.0,-10.0617},{5.0,-10.0617},{5.0,-14.3133}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,Bmal1_transcription.s1) annotation(Line(visible=true, origin={82.4624,0.5269}, points={{7.5376,29.4731},{7.5376,-8.4072},{-7.5375,-8.4072},{-7.5375,-12.6587}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,cytoplasmic_BMAL1_degradation.p1) annotation(Line(visible=true, origin={80.625,30.0}, points={{9.375,-0.0},{-9.375,0.0}}, smooth=Smooth.Bezier));
        connect(y5.n1,cytoplasmic_BMAL1_degradation.s1) annotation(Line(visible=true, origin={39.4367,25.0}, points={{-19.4367,-5.0},{5.0617,-5.0},{5.0617,5.0},{9.3133,5.0}}, smooth=Smooth.Bezier));
        connect(y5.n1,BMAL1_nuclear_import.s1) annotation(Line(visible=true, origin={35.0,-44.4367}, points={{-15.0,64.4367},{-15.0,-20.0617},{15.0,-20.0617},{15.0,-24.3133}}, smooth=Smooth.Bezier));
        connect(y5.n1,BMAL1_translation.p1) annotation(Line(visible=true, origin={39.4367,10.0}, points={{-19.4367,10.0},{5.0617,10.0},{5.0617,-10.0},{9.3133,-10.0}}, smooth=Smooth.Bezier));
        connect(y4.n1,BMAL1_translation.m1) annotation(Line(visible=true, origin={62.4147,-24.2512}, points={{2.4147,-35.7488},{2.4147,10.2487},{-2.4147,10.2487},{-2.4147,15.2512}}, smooth=Smooth.Bezier));
        connect(y4.n1,Bmal1_transcription.p1) annotation(Line(visible=true, origin={69.8771,-43.0996}, points={{-5.0478,-16.9004},{-5.0478,4.2163},{5.0478,4.2163},{5.0478,8.4678}}, smooth=Smooth.Bezier));
        connect(y4.n1,Bmal1_mRNA_degradation.s1) annotation(Line(visible=true, origin={88.2764,-53.75}, points={{-23.4471,-6.25},{11.7236,-6.25},{11.7236,12.5}}, smooth=Smooth.Bezier));
      end Cytoplasm;

    end CircadianOscillator;

  end Examples;

  package Compartments "Different types of compartments used in the package"
    model Compartment "Default compartment (constant volume)"
      extends BioChem.Interfaces.Compartments.Compartment(V(stateSelect=StateSelect.prefer));
    equation
      der(V)=0 "Compartment volume is constant";
    end Compartment;

    model MainCompartment "Main compartment (constant volume)"
      extends BioChem.Interfaces.Compartments.MainCompartment(V(stateSelect=StateSelect.prefer));
    equation
      der(V)=0 "Compartment volume is constant";
    end MainCompartment;

  end Compartments;

  package Constants "Mathematical constants and constants of nature"
  end Constants;

end BioChem;
model BioChem_Examples_CircadianOscillator_Container
  extends BioChem.Examples.CircadianOscillator.Container;
end BioChem_Examples_CircadianOscillator_Container;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 4)"
  extends Modelica.Icons.Package;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial package Package  "Icon for standard packages" end Package;
  end Icons;
  annotation(version = "3.2.1", versionBuild = 4, versionDate = "2013-08-14", dateModified = "2015-09-30 09:15:00Z");
end Modelica;

package ScalableTestSuite  "A library of scalable Modelica test models"
  package Thermal  "Models from the thermal domain"
    package Advection  "1D advection models"
      package Models
        model AdvectionReaction  "Model of an advection process with chemical reaction"
          parameter Integer N = 10 "Number of volumes";
          parameter Real mu = 1000 "Kinetic coefficient of the reaction";
          constant Real alpha = 0.5 "Parameter of the reaction model";
          Real u_in = 1 "Inlet concentration";
          Real[N] u(each start = 0, each fixed = true) "Concentration at each volume outlet";
        equation
          der(u[1]) = ((-u[1]) + 1) * N - mu * u[1] * (u[1] - alpha) * (u[1] - 1);
          for j in 2:N loop
            der(u[j]) = ((-u[j]) + u[j - 1]) * N - mu * u[j] * (u[j] - alpha) * (u[j] - 1);
          end for;
        end AdvectionReaction;
      end Models;

      package ScaledExperiments
        extends Modelica.Icons.ExamplesPackage;

        model AdvectionReaction_N_3200
          extends Models.AdvectionReaction(N = 3200, mu = 16000);
          annotation(experiment(StopTime = 1, NumberOfIntervals = 5000, Tolerance = 1e-6));
        end AdvectionReaction_N_3200;
      end ScaledExperiments;
    end Advection;
  end Thermal;
  annotation(version = "1.7.1");
end ScalableTestSuite;

model AdvectionReaction_N_3200_total
  extends ScalableTestSuite.Thermal.Advection.ScaledExperiments.AdvectionReaction_N_3200;
 annotation(experiment(StopTime = 1, NumberOfIntervals = 5000, Tolerance = 1e-6));
end AdvectionReaction_N_3200_total;

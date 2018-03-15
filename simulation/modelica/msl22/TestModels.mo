package TestModels
  package BlockModels
      package SourceTests
          model SineTest
              Modelica.Blocks.Sources.Sine sine1(freqHz=1.0/Modelica.Constants.pi/2.0) annotation(Placement(visible=true,transformation(x=-51.9803,y=42.8114,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction1 annotation(Placement(visible=true,transformation(x=-11.0523,y=42.9673,scale=0.0666667)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-99.81},{99.81,100.59}})}));

      equation
        connect(sine1.y,transferFunction1.u) annotation(Line(visible=true,points={{-41.1283,42.962},{-19.1233,42.962}}));
      end SineTest;
      model ConstantTest
              Modelica.Blocks.Sources.Constant constant1 annotation(Placement(visible=true,transformation(x=-71.4489,y=29.9574,scale=0.1)));
        Modelica.Blocks.Continuous.Derivative derivative1(T=1e-05) annotation(Placement(visible=true,transformation(x=-30.8594,y=29.6567,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-99.81,-100.07},{100.07,100.07}})}));

      equation
        connect(constant1.y,derivative1.u) annotation(Line(visible=true,points={{-60.44,30.08},{-42.89,29.8}}));
      end ConstantTest;
      model ExponentialsTest
              Modelica.Blocks.Continuous.Derivative derivative1 annotation(Placement(visible=true,transformation(x=-21.5924,y=4.04084,scale=0.1)));
        Modelica.Blocks.Sources.Exponentials exponentials1 annotation(Placement(visible=true,transformation(x=-68.7459,y=4.04084,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.33}})}));

      equation
        connect(exponentials1.y,derivative1.u) annotation(Line(visible=true,points={{-57.89,4.19},{-33.79,4.19}}));
      end ExponentialsTest;
      model ExpSineTest
              Modelica.Blocks.Sources.ExpSine expSine1 annotation(Placement(visible=true,transformation(x=-68.8203,y=0.697827,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.59,-100.07},{99.81,100.59}})}));
        Modelica.Blocks.Continuous.TransferFunction transferFunction1 annotation(Placement(visible=true,transformation(x=-18.8329,y=-0.108902,scale=0.1)));

      equation
        connect(expSine1.y,transferFunction1.u) annotation(Line(visible=true,points={{-57.8776,0.826823},{-30.8681,0}}));
      end ExpSineTest;
       model PulseTest
          Modelica.Blocks.Sources.Pulse p(period=0.4);
       end PulseTest;
    end SourceTests;
    package SystemTests
          model DCmotor
              parameter Real L=1.0;
        parameter Real R=1.0;
        parameter Real k=1.0;
        parameter Real I=1.0;
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=-20,y=-27.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator2 annotation(Placement(visible=true,transformation(x=25,y=-27.5,scale=0.1)));
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-45,y=25,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=k) annotation(Placement(visible=true,transformation(x=25,y=25,scale=0.1)));
        Modelica.Blocks.Continuous.FirstOrder firstOrder1(k=1/R,T=L/R) annotation(Placement(visible=true,transformation(x=-7.5,y=25,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=1/I) annotation(Placement(visible=true,transformation(x=57.5,y=25,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1 annotation(Placement(visible=true,transformation(x=-82.5,y=32.3151,scale=0.0785891)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-99.81,-100.07},{100.07,100.59}})}));

      equation
        connect(constant1.y,add1.u1) annotation(Line(visible=true,points={{-73.8738,32.2215},{-57.1081,31.1737}}));
        connect(integrator1.u,gain2.y) annotation(Line(visible=true,points={{-32.2215,-27.5062},{-45,-27.5062},{-45,-6.58313},{82.5,-6.58313},{82.5,25.1485},{68.3725,25.1485}}));
        connect(gain1.y,gain2.u) annotation(Line(visible=true,points={{35.889,25.1485},{45.3197,25.1485}}));
        connect(add1.y,firstOrder1.u) annotation(Line(visible=true,points={{-34.0553,25.1485},{-19.6473,25.1485}}));
        connect(firstOrder1.y,gain1.u) annotation(Line(visible=true,points={{3.40553,25.1485},{12.8362,25.1485}}));
        connect(add1.u2,integrator1.y) annotation(Line(visible=true,points={{-57.1081,19.1233},{-67.5,19.1233},{-67.5,0},{-67.5,0},{0,0},{0,-27.5062},{-9.16873,-27.5062}}));
        connect(integrator1.y,integrator2.u) annotation(Line(visible=true,points={{-9.16873,-27.5062},{12.8362,-27.5062}}));
      end DCmotor;
      model Circuit1
              parameter Real C=0.01;
        parameter Real L=0.1;
        parameter Real R1=10;
        parameter Real R2=100;
        Modelica.Blocks.Sources.Sine sine1(amplitude=220,freqHz=50) annotation(Placement(visible=true,transformation(x=-90.09,y=-0.108902,scale=0.1)));
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-59.723,y=-10.3314,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=1/R1) annotation(Placement(visible=true,transformation(x=-20.6368,y=-10.3314,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=1/C) annotation(Placement(visible=true,transformation(x=20.2533,y=-10.3314,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator2 annotation(Placement(visible=true,transformation(x=50.3196,y=-10.0308,scale=0.1)));
        Modelica.Blocks.Math.Add add3 annotation(Placement(visible=true,transformation(x=81.5885,y=19.4342,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=49.9259,y=49.8011,scale=0.1)));
        Modelica.Blocks.Math.Add add2(k1=-1) annotation(Placement(visible=true,transformation(x=-20.995,y=50,scale=0.1)));
        Modelica.Blocks.Math.Gain gain4(k=1/L) annotation(Placement(visible=true,transformation(x=18.657,y=49.8011,scale=0.1)));
        Modelica.Blocks.Math.Gain gain3(k=R2) annotation(Placement(visible=true,transformation(x=-61.0187,y=59.723,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}));

      equation
        connect(gain4.y,integrator1.u) annotation(Line(visible=true,points={{29.6019,49.7731},{37.7228,49.7731}}));
        connect(gain3.y,add2.u1) annotation(Line(visible=true,points={{-50.0351,59.7277},{-38.495,59.7277},{-38.495,56.0602},{-33.0074,56.0602}}));
        connect(integrator1.y,add3.u1) annotation(Line(visible=true,points={{60.7756,49.7731},{66.505,49.7731},{66.505,33.5314},{59.005,33.5314},{59.005,25.4105},{69.4204,25.4105}}));
        connect(sine1.y,add2.u2) annotation(Line(visible=true,points={{-79.113,0},{-75.995,0},{-75.995,44.0099},{-33.0074,44.0099}}));
        connect(add2.y,gain4.u) annotation(Line(visible=true,points={{-9.95462,50.0351},{6.54909,49.7731}}));
        connect(integrator1.y,gain3.u) annotation(Line(visible=true,points={{60.7756,49.7731},{76.085,49.8},{76.085,80.47},{76.085,80.47},{-91.085,80.47},{-91.085,80.47},{-91.085,59.72},{-91.085,59.72},{-73.0879,59.7277}}));
        connect(gain1.y,add3.u2) annotation(Line(visible=true,points={{-9.69266,-10.2166},{-9.69266,13.6221},{69.4204,13.6221}}));
        connect(sine1.y,add1.u1) annotation(Line(visible=true,points={{-79.113,0},{-75,0},{-75,-4.19142},{-71.7781,-4.19142}}));
        connect(integrator2.y,add1.u2) annotation(Line(visible=true,points={{61.2995,-9.95462},{77.68,-9.95462},{77.68,-41.9},{77.68,-41.9},{-83.48,-41.9},{-83.48,-41.9},{-83.48,-16.95},{-83.48,-16.2417},{-71.7781,-16.2417}}));
        connect(gain2.y,integrator2.u) annotation(Line(visible=true,points={{31.19,-10.3},{38.16,-10.03}}));
        connect(gain1.y,gain2.u) annotation(Line(visible=true,points={{-9.75,-10.3},{8.08,-10.3}}));
        connect(add1.y,gain1.u) annotation(Line(visible=true,points={{-48.74,-10.3},{-32.59,-10.3}}));
      end Circuit1;
      model DCmotorControlled
              parameter Real L=1.0;
        parameter Real R=1.0;
        parameter Real k=1.0;
        parameter Real I=1.0;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.59}})}));
        Modelica.Blocks.Continuous.FirstOrder firstOrder1(k=1/R,T=L/R) annotation(Placement(visible=true,transformation(x=-2.5,y=67.5,scale=0.1)));
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-35,y=67.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=k) annotation(Placement(visible=true,transformation(x=32.5,y=67.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=1/I) annotation(Placement(visible=true,transformation(x=67.5,y=67.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=-12.5,y=20,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator2 annotation(Placement(visible=true,transformation(x=32.5,y=20,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1 annotation(Placement(visible=true,transformation(x=40,y=-32.5,scale=0.1,flipHorizontal=true)));
        Modelica.Blocks.Continuous.LimPID limPID1(k=0.1,Ti=0.01,Td=0.01) annotation(Placement(visible=true,transformation(x=5,y=-32.5,scale=0.1,flipHorizontal=true)));

      equation
        connect(integrator1.u,gain2.y) annotation(Line(visible=true,points={{-24.6246,20.1712},{-37.5,20.1712},{-37.5,45},{90,45},{90,67.5},{78.3271,67.5866}}));
        connect(add1.u2,integrator1.y) annotation(Line(visible=true,points={{-47.1535,61.5615},{-60,61.5615},{-60,52.5},{15,52.5},{15,20.1712},{-1.57178,20.1712}}));
        connect(integrator2.y,limPID1.u_m) annotation(Line(visible=true,points={{43.486,20.1712},{60,20.1712},{60,-67.5},{4.97731,-67.5},{4.97731,-44.5338}}));
        connect(limPID1.y,add1.u1) annotation(Line(visible=true,points={{-6.02517,-32.4835},{-84.98,-32.4835},{-84.98,73.6118},{-82.5,73.6118},{-47.1535,73.6118}}));
        connect(constant1.y,limPID1.u_s) annotation(Line(visible=true,points={{29.078,-32.4835},{17.0276,-32.4835}}));
        connect(integrator1.y,integrator2.u) annotation(Line(visible=true,points={{-1.57178,20.1712},{20.4332,20.1712}}));
        connect(gain1.y,gain2.u) annotation(Line(visible=true,points={{43.486,67.5866},{55.2743,67.5866}}));
        connect(firstOrder1.y,gain1.u) annotation(Line(visible=true,points={{8.38284,67.5866},{20.4332,67.5866}}));
        connect(add1.y,firstOrder1.u) annotation(Line(visible=true,points={{-24.1007,67.5866},{-14.67,67.5866}}));
      end DCmotorControlled;
      model DCmotorDeadzone
              parameter Real L=1.0;
        parameter Real R=1.0;
        parameter Real k=1.0;
        parameter Real I=1.0;
        Modelica.Blocks.Continuous.FirstOrder firstOrder1(k=1/R,T=L/R) annotation(Placement(visible=true,transformation(x=-18.1677,y=22.5,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1 annotation(Placement(visible=true,transformation(x=-85.6677,y=27.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=1/I) annotation(Placement(visible=true,transformation(x=81.8323,y=22.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator2 annotation(Placement(visible=true,transformation(x=11.8323,y=-27.5,scale=0.1)));
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-50.6677,y=22.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=-25.6677,y=-27.5,scale=0.1)));
        Modelica.Blocks.Nonlinear.DeadZone deadZone1(uMax=0.1) annotation(Placement(visible=true,transformation(x=49.3323,y=22.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=k) annotation(Placement(visible=true,transformation(x=16.8323,y=22.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-99.84,-99.84},{99.48,99.84}})}));

      equation
        connect(integrator1.y,add1.u2) annotation(Line(visible=true,points={{-14.8167,-27.5167},{-9.37187,-27.5167},{-9.37187,0},{-73.1677,0},{-73.1677,16.6687},{-62.7062,16.6687}}));
        connect(integrator1.y,integrator2.u) annotation(Line(visible=true,points={{-14.8167,-27.5167},{-0.264583,-27.2521}}));
        connect(gain2.y,integrator1.u) annotation(Line(visible=true,points={{92.8687,22.4896},{95.6677,22.5},{95.6677,-56.6208},{-53.0281,-56.6208},{-53.0281,-27.2521},{-37.8354,-27.2521}}));
        connect(constant1.y,add1.u1) annotation(Line(visible=true,points={{-74.6125,27.5167},{-62.7062,28.575}}));
        connect(firstOrder1.y,gain1.u) annotation(Line(visible=true,points={{-7.14375,22.4896},{4.7625,22.4896}}));
        connect(deadZone1.y,gain2.u) annotation(Line(visible=true,points={{60.325,22.4896},{69.5854,22.4896}}));
        connect(add1.y,firstOrder1.u) annotation(Line(visible=true,points={{-39.6875,22.4896},{-30.1625,22.4896}}));
        connect(gain1.y,deadZone1.u) annotation(Line(visible=true,points={{27.7813,22.4896},{37.3063,22.4896}}));
      end DCmotorDeadzone;
      model Tank
              parameter Real A=1;
        parameter Real a=0.01;
        parameter Real g=9.81;
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-35,y=7.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=1/A) annotation(Placement(visible=true,transformation(x=-2.5,y=7.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=30,y=7.5,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1(k=0) annotation(Placement(visible=true,transformation(x=30,y=40,scale=0.1)));
        Modelica.Blocks.Math.Sqrt sqrt1 annotation(Placement(visible=true,transformation(x=-10,y=-52.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain3(k=a) annotation(Placement(visible=true,transformation(x=25,y=-52.5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=2*g) annotation(Placement(visible=true,transformation(x=-42.5,y=-52.5,scale=0.1)));
        Modelica.Blocks.Sources.Pulse pulse1 annotation(Placement(visible=true,transformation(x=-80,y=13.6902,scale=0.1)));
        Modelica.Blocks.Math.Max max1 annotation(Placement(visible=true,transformation(x=72.5,y=13.4282,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.33},{100.33,100.33}})}));

      equation
        connect(gain2.u,max1.y) annotation(Line(visible=true,points={{-54.4884,-52.3927},{-67.5,-52.5},{-67.5,-22.5},{90,-22.5},{90,13.3601},{83.5664,13.3601}}));
        connect(constant1.y,max1.u1) annotation(Line(visible=true,points={{40.8663,40.0804},{45,40.0804},{45,19.6473},{60.5136,19.6473}}));
        connect(integrator1.y,max1.u2) annotation(Line(visible=true,points={{40.8663,7.59695},{60.5136,7.59695}}));
        connect(pulse1.y,add1.u1) annotation(Line(visible=true,points={{-69.1584,13.6221},{-47.1535,13.6221}}));
        connect(add1.u2,gain3.y) annotation(Line(visible=true,points={{-47.1535,1.57178},{-60,1.57178},{-60,-15},{45,-15},{45,-52.5},{35.889,-52.3927}}));
        connect(gain2.y,sqrt1.u) annotation(Line(visible=true,points={{-31.4356,-52.3927},{-22.005,-52.3927}}));
        connect(sqrt1.y,gain3.u) annotation(Line(visible=true,points={{1.04785,-52.3927},{12.8362,-52.3927}}));
        connect(gain1.y,integrator1.u) annotation(Line(visible=true,points={{8.38284,7.59695},{17.8135,7.59695}}));
        connect(add1.y,gain1.u) annotation(Line(visible=true,points={{-24.1007,7.59695},{-14.67,7.59695}}));
      end Tank;
      model Pendulum
              annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-99.94,-100.2},{99.94,100.2}})}),Diagram(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Text(visible=true, extent={{-22.5,48.68},{30,57.41}}, textString="Pendulum"),Text(visible=true, extent={{-18.75,-61.23},{33.75,-52.5}}, textString="Pendulum with friction loss")}));
        parameter Real m=1;
        parameter Real l=1;
        Modelica.Blocks.Continuous.Integrator velocity annotation(Placement(visible=true,transformation(x=13.4125,y=80,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator position(y(start=Modelica.Constants.pi/4)) annotation(Placement(visible=true,transformation(x=53.4125,y=80,scale=0.1)));
        Modelica.Blocks.Math.Gain acceleration(k=Modelica.Constants.g_n/l) annotation(Placement(visible=true,transformation(x=-26.5875,y=80,scale=0.1)));
        Modelica.Blocks.Math.Sin sin1 annotation(Placement(visible=true,transformation(x=-1.5875,y=32.5646,scale=0.075,flipHorizontal=true)));
        Modelica.Blocks.Math.Sin sin1_f annotation(Placement(visible=true,transformation(x=1.11022e-16,y=-85.6708,scale=0.075,flipHorizontal=true)));
        Modelica.Blocks.Continuous.Integrator velocity_f annotation(Placement(visible=true,transformation(x=15,y=2.5,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator position_f(y(start=Modelica.Constants.pi/4)) annotation(Placement(visible=true,transformation(x=55,y=2.5,scale=0.1)));
        Modelica.Blocks.Math.Gain friction(k=0.1) annotation(Placement(visible=true,transformation(x=-30,y=-35.45,scale=0.075,flipHorizontal=true)));
        Modelica.Blocks.Math.Gain acceleration_f(k=Modelica.Constants.g_n/l) annotation(Placement(visible=true,transformation(x=-37.5,y=-85.9396,scale=0.0633958,flipHorizontal=true)));
        Modelica.Blocks.Math.Feedback feedback1 annotation(Placement(visible=true,transformation(x=-65.3833,y=-35.5563,scale=0.075,rotation=810)));

      equation
        connect(acceleration_f.y,feedback1.u1) annotation(Line(visible=true,points={{-44.45,-85.725},{-65.3521,-85.725},{-65.3521,-41.5396}}));
        connect(feedback1.y,velocity_f.u) annotation(Line(visible=true,points={{-65.3521,-28.8396},{-65.3521,2.64583},{2.91042,2.64583}}));
        connect(friction.y,feedback1.u2) annotation(Line(visible=true,points={{-38.3646,-35.4542},{-59.5312,-35.4542}}));
        connect(sin1_f.y,acceleration_f.u) annotation(Line(visible=true,points={{-8.20208,-85.725},{-29.8979,-85.9896}}));
        connect(velocity_f.y,friction.u) annotation(Line(visible=true,points={{25.9292,2.64583},{32.2792,2.64583},{32.2792,-35.4542},{-21.1667,-35.4542}}));
        connect(position_f.y,sin1_f.u) annotation(Line(visible=true,points={{65.8812,2.64583},{78.5812,2.64583},{78.5812,-85.4083},{8.99583,-85.4604}}));
        connect(velocity_f.y,position_f.u) annotation(Line(visible=true,points={{25.9292,2.64583},{42.8625,2.64583}}));
        connect(velocity.y,position.u) annotation(Line(visible=true,points={{24.3417,80.1687},{41.275,80.1687}}));
        connect(sin1.y,acceleration.u) annotation(Line(visible=true,points={{-9.78958,32.5437},{-69.0875,32.5646},{-69.0875,80.1896},{-38.6292,80.1687}}));
        connect(acceleration.y,velocity.u) annotation(Line(visible=true,points={{-15.6104,80.1687},{1.32292,80.1687}}));
        connect(position.y,sin1.u) annotation(Line(visible=true,points={{64.2937,80.1687},{76.9937,80.1896},{76.9937,32.5646},{7.40833,32.5437}}));
      end Pendulum;
      model SAADC
              Modelica.Blocks.Sources.IntegerConstant integerConstant3(k={0,0,0}) annotation(Placement(visible=true,transformation(x=30.1752,y=19.7348,scale=0.1)));
        Modelica.Blocks.Sources.IntegerConstant integerConstant2(k={4,2,1}) annotation(Placement(visible=true,transformation(x=30.1752,y=50.1018,scale=0.1)));
        Modelica.Blocks.Math.IntegerToReal integerToReal1 annotation(Placement(visible=true,transformation(x=60.5421,y=49.8011,scale=0.1)));
        Modelica.Blocks.Multiplexer.DeMultiplex3 deMultiplex31 annotation(Placement(visible=true,transformation(x=88.8045,y=49.5005,scale=0.1)));
        Modelica.Blocks.Multiplexer.DeMultiplex3 deMultiplex32 annotation(Placement(visible=true,transformation(x=88.2031,y=19.4342,scale=0.1)));
        Modelica.Blocks.Math.IntegerToReal integerToReal2 annotation(Placement(visible=true,transformation(x=59.9408,y=18.8329,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch3 annotation(Placement(visible=true,transformation(x=127.777,y=1.32184,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch2 annotation(Placement(visible=true,transformation(x=129.145,y=39.1846,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch1 annotation(Placement(visible=true,transformation(x=128.689,y=71.5733,scale=0.1)));
        Modelica.Blocks.Math.Edge edge2 annotation(Placement(visible=true,transformation(x=215.819,y=-57.5251,scale=0.1)));
        Modelica.Blocks.Discrete.TriggeredSampler triggeredSampler2 annotation(Placement(visible=true,transformation(x=210.801,y=38.2723,scale=0.1)));
        Modelica.Blocks.Sources.IntegerConstant integerConstant1(k={8}) annotation(Placement(visible=true,transformation(x=-87.9646,y=-142.177,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThan2(threshold=0.5) annotation(Placement(visible=true,transformation(x=178.869,y=-57.5251,scale=0.1)));
        Modelica.Blocks.Logical.Compare compare1 annotation(Placement(visible=true,transformation(x=-0.637572,y=-1.57075,scale=0.1)));
        Modelica.Blocks.Math.Edge edge5 annotation(Placement(visible=true,transformation(x=9.17026,y=-94.4756,scale=0.1)));
        Modelica.Blocks.Logical.Or OR2 annotation(Placement(visible=true,transformation(x=70.7543,y=-119.109,scale=0.1)));
        Modelica.Blocks.Logical.And AND2 annotation(Placement(visible=true,transformation(x=101.774,y=-83.0711,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Polygon(visible=true, lineColor={255,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.Solid, points={{-100.07,-82.5},{-82.5,-100.33},{100.59,82.5},{82.5,100.59}}),Ellipse(visible=true, lineColor={255,0,0}, fillColor={255,255,255}, lineThickness=2, extent={{-100.07,-99.81},{99.81,100.59}})}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
        Modelica.Blocks.Discrete.TriggeredSampler triggeredSampler1 annotation(Placement(visible=true,transformation(x=25.6652,y=79.8674,scale=0.1)));
        Modelica.Blocks.Math.Edge edge3 annotation(Placement(visible=true,transformation(x=11.4511,y=-31.523,scale=0.1)));
        Modelica.Blocks.Math.Edge edge4 annotation(Placement(visible=true,transformation(x=11.4511,y=-60.2622,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThan5(threshold=0.5) annotation(Placement(visible=true,transformation(x=-27.7802,y=-94.0194,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1(k=Vdd) annotation(Placement(visible=true,transformation(x=-91.4689,y=-105.942,scale=0.1)));
        Modelica.Blocks.Discrete.TriggeredSampler triggeredSampler3 annotation(Placement(visible=true,transformation(x=56.1566,y=-56.6128,scale=0.1)));
        Modelica.Blocks.Logical.Or OR1 annotation(Placement(visible=true,transformation(x=49.7701,y=-86.2644,scale=0.1)));
        Modelica.Blocks.Math.Add3 add31 annotation(Placement(visible=true,transformation(x=163.815,y=40.097,scale=0.1)));
        Modelica.Blocks.Nonlinear.PadeDelay padeDelay1(delayTime=0.0005,n=3) annotation(Placement(visible=true,transformation(x=142.83,y=-57.5251,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant2(k=Vss) annotation(Placement(visible=true,transformation(x=-91.1578,y=-187.785,scale=0.1)));
        Modelica.Blocks.Math.Add add1(k2=-1) annotation(Placement(visible=true,transformation(x=-47.6343,y=-140.363,scale=0.1)));
        Modelica.Blocks.Math.Division division1 annotation(Placement(visible=true,transformation(x=-9.57452,y=-146.47,scale=0.1)));
        Modelica.Blocks.Math.Product product1 annotation(Placement(visible=true,transformation(x=28.9,y=-151.602,scale=0.1)));
        Modelica.Blocks.Math.Add add2 annotation(Placement(visible=true,transformation(x=71.2209,y=-163.338,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-125,y=85,scale=0.1)));
        Modelica.Blocks.Sources.Pulse pulse1(period=0.001) annotation(Placement(visible=true,transformation(x=-122.5,y=52.5,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThan1(threshold=0.5) annotation(Placement(visible=true,transformation(x=-85,y=52.5,scale=0.1)));
        Modelica.Blocks.Math.Edge edge1 annotation(Placement(visible=true,transformation(x=-50,y=52.5,scale=0.1)));
        Modelica.Blocks.Nonlinear.PadeDelay padeDelay2(n=3,delayTime=0.0001) annotation(Placement(visible=true,transformation(x=-85,y=20,scale=0.1)));
        Modelica.Blocks.Nonlinear.PadeDelay padeDelay3(delayTime=0.00011,n=3) annotation(Placement(visible=true,transformation(x=-47.5,y=20,scale=0.1)));
        Modelica.Blocks.Nonlinear.PadeDelay padeDelay4(delayTime=0.0001,n=3) annotation(Placement(visible=true,transformation(x=-5,y=20,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThan3(threshold=0.5) annotation(Placement(visible=true,transformation(x=-47.5,y=-15,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThan4(threshold=0.5) annotation(Placement(visible=true,transformation(x=-5,y=-17.5,scale=0.1)));
        Modelica.Blocks.Logical.And AND1 annotation(Placement(visible=true,transformation(x=72.5,y=35,scale=0.1)));

      equation
        connect(AND1.y,switch1.u2) annotation(Line(visible=true,points={{83.6083,34.925},{116.417,71.4375}}));
        connect(greaterThan3.y,AND1.u2) annotation(Line(visible=true,points={{-36.5125,-14.8167},{60.325,26.9875}}));
        connect(greaterThan4.y,AND2.u2) annotation(Line(visible=true,points={{5.82083,-17.4625},{89.4292,-91.0167}}));
        connect(greaterThan4.y,edge4.u) annotation(Line(visible=true,points={{5.82083,-17.4625},{-0.529167,-60.325}}));
        connect(padeDelay3.y,greaterThan4.u) annotation(Line(visible=true,points={{-36.5125,20.1083},{-16.9333,-17.4625}}));
        connect(padeDelay2.y,greaterThan3.u) annotation(Line(visible=true,points={{-74.0833,20.1083},{-59.7958,-14.8167}}));
        connect(greaterThan3.y,edge3.u) annotation(Line(visible=true,points={{-36.5125,-14.8167},{-0.529167,-31.2208}}));
        connect(padeDelay3.y,padeDelay4.u) annotation(Line(visible=true,points={{-36.5125,20.1083},{-16.9333,20.1083}}));
        connect(padeDelay4.y,greaterThan5.u) annotation(Line(visible=true,points={{5.82083,20.1083},{-39.6875,-93.6625}}));
        connect(padeDelay2.y,padeDelay3.u) annotation(Line(visible=true,points={{-74.0833,20.1083},{-59.7958,20.1083}}));
        connect(pulse1.y,padeDelay2.u) annotation(Line(visible=true,points={{-111.654,52.3875},{-97.3667,20.1083}}));
        connect(edge1.y,triggeredSampler1.trigger) annotation(Line(visible=true,points={{-39.1583,52.3875},{25.4,68.2625}}));
        connect(greaterThan1.y,edge1.u) annotation(Line(visible=true,points={{-74.0833,52.3875},{-61.9125,52.3875}}));
        connect(pulse1.y,greaterThan1.u) annotation(Line(visible=true,points={{-111.654,52.3875},{-97.3667,52.3875}}));
        connect(pulse1.y,padeDelay1.u) annotation(Line(visible=true,points={{-111.654,52.3875},{130.704,-57.15}}));
        connect(sine1.y,triggeredSampler1.u) annotation(Line(visible=true,points={{-114.3,85.1958},{13.7583,79.9042}}));
        connect(constant2.y,add2.u2) annotation(Line(visible=true,points={{-80.0806,-187.678},{59.2667,-169.333}}));
        connect(product1.y,add2.u1) annotation(Line(visible=true,points={{39.8639,-151.694},{59.2667,-157.339}}));
        connect(add2.y,triggeredSampler3.u) annotation(Line(visible=true,points={{82.1972,-163.336},{44.0972,-56.4444}}));
        connect(division1.y,product1.u2) annotation(Line(visible=true,points={{1.41111,-146.403},{16.9333,-157.339}}));
        connect(add31.y,product1.u1) annotation(Line(visible=true,points={{174.625,40.2167},{16.9333,-145.344}}));
        connect(add1.y,division1.u1) annotation(Line(visible=true,points={{-36.6889,-140.406},{-21.5194,-140.406}}));
        connect(constant2.y,add1.u2) annotation(Line(visible=true,points={{-80.0806,-187.678},{-59.6194,-146.403}}));
        connect(constant1.y,add1.u1) annotation(Line(visible=true,points={{-80.4333,-105.833},{-59.6194,-134.408}}));
        connect(padeDelay1.y,greaterThan2.u) annotation(Line(visible=true,points={{153.811,-57.5028},{166.864,-57.5028}}));
        connect(switch1.y,add31.u1) annotation(Line(visible=true,points={{139.7,71.6139},{151.694,48.3306}}));
        connect(switch2.y,add31.u2) annotation(Line(visible=true,points={{140.053,39.1583},{151.694,40.2167}}));
        connect(switch3.y,add31.u3) annotation(Line(visible=true,points={{138.642,1.41111},{151.694,32.1028}}));
        connect(triggeredSampler2.u,add31.y) annotation(Line(visible=true,points={{198.614,38.4528},{174.625,40.2167}}));
        connect(edge3.y,OR1.u1) annotation(Line(visible=true,points={{22.225,-31.3972},{37.7472,-86.0778}}));
        connect(edge4.y,OR1.u2) annotation(Line(visible=true,points={{22.225,-60.325},{37.7472,-94.1917}}));
        connect(OR1.y,OR2.u1) annotation(Line(visible=true,points={{60.6778,-86.0778},{58.5611,-118.886}}));
        connect(OR2.y,triggeredSampler3.trigger) annotation(Line(visible=true,points={{81.8444,-118.886},{56.0917,-68.4389}}));
        connect(greaterThan5.y,edge5.u) annotation(Line(visible=true,points={{-16.9333,-93.8389},{-2.82222,-94.1917}}));
        connect(switch3.u2,greaterThan5.y) annotation(Line(visible=true,points={{115.711,1.41111},{-16.9333,-93.8389}}));
        connect(AND2.y,switch2.u2) annotation(Line(visible=true,points={{113.64,-82.16},{115.92,40.1}}));
        connect(compare1.y,AND2.u1) annotation(Line(visible=true,points={{11.91,-2.78},{91.28,-79.42}}));
        connect(compare1.y,AND1.u1) annotation(Line(visible=true,points={{10.54,-1.42},{56.16,-12.82}}));
        connect(edge5.y,OR2.u2) annotation(Line(visible=true,points={{19.66,-94.02},{58.89,-125.04}}));
        connect(triggeredSampler3.y,compare1.u2) annotation(Line(visible=true,points={{67.56,-57.07},{-13.64,-7.8}}));
        connect(triggeredSampler1.y,compare1.u1) annotation(Line(visible=true,points={{36.54,79.78},{-12.73,4.52}}));
        connect(greaterThan2.y,edge2.u) annotation(Line(visible=true,points={{189.82,-57.53},{203.5,-57.53}}));
        connect(integerConstant1.y,division1.u2) annotation(Line(visible=true,points={{-77.05,-141.92},{-21.85,-152.41}}));
        connect(edge2.y,triggeredSampler2.trigger) annotation(Line(visible=true,points={{226.77,-58.44},{211.26,24.13}}));
        connect(deMultiplex32.y3,switch3.u3) annotation(Line(visible=true,points={{99.49,11.81},{115.0,-5.98}}));
        connect(deMultiplex32.y2,switch2.u3) annotation(Line(visible=true,points={{98.58,19.57},{115.92,31.43}}));
        connect(deMultiplex32.y1,switch1.u3) annotation(Line(visible=true,points={{98.13,25.96},{115.92,65.64}}));
        connect(deMultiplex31.y3,switch3.u1) annotation(Line(visible=true,points={{98.58,42.83},{115.46,8.16}}));
        connect(deMultiplex31.y2,switch2.u1) annotation(Line(visible=true,points={{99.04,50.13},{117.28,46.03}}));
        connect(deMultiplex31.y1,switch1.u1) annotation(Line(visible=true,points={{99.95,56.06},{115.46,78.42}}));
        connect(integerToReal2.y,deMultiplex32.u) annotation(Line(visible=true,points={{69.84,19.11},{75.77,19.11}}));
        connect(integerToReal1.y,deMultiplex31.u) annotation(Line(visible=true,points={{71.21,50.59},{76.23,50.13}}));
        connect(integerConstant3.y,integerToReal2.u) annotation(Line(visible=true,points={{42.02,19.57},{47.49,19.11}}));
        connect(integerConstant2.y,integerToReal1.u) annotation(Line(visible=true,points={{40.19,49.68},{48.4,49.68}}));
      end SAADC;
      model SpringMass
              parameter Real k=1;
        parameter Real c=1;
        parameter Real m=1;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.33},{100.07,100.07}})}));
        Modelica.Blocks.Continuous.Integrator integrator2 annotation(Placement(visible=true,transformation(x=85,y=35,scale=0.1)));
        Modelica.Blocks.Continuous.Integrator integrator1 annotation(Placement(visible=true,transformation(x=50,y=35,scale=0.1)));
        Modelica.Blocks.Math.Gain gain3(k=1/m) annotation(Placement(visible=true,transformation(x=20,y=35,scale=0.1)));
        Modelica.Blocks.Math.Add3 add31(k1=-1,k2=-1) annotation(Placement(visible=true,transformation(x=-12.5,y=35,scale=0.1)));
        Modelica.Blocks.Math.Gain gain1(k=c) annotation(Placement(visible=true,transformation(x=-57.5,y=35,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-57.5,y=5,scale=0.1)));
        Modelica.Blocks.Math.Gain gain2(k=k) annotation(Placement(visible=true,transformation(x=-57.5,y=70,scale=0.1)));

      equation
        connect(gain2.y,add31.u1) annotation(Line(visible=true,points={{-46.6295,69.9443},{-37.5,69.9443},{-37.5,43.224},{-24.6246,43.224}}));
        connect(sine1.y,add31.u3) annotation(Line(visible=true,points={{-46.6295,4.97731},{-37.5,4.97731},{-37.5,26.9823},{-24.6246,26.9823}}));
        connect(integrator2.y,gain2.u) annotation(Line(visible=true,points={{95.8787,35.1031},{97.5,35.1031},{97.5,95.0928},{-82.5,95.0928},{-82.5,70.9922},{-82.5,70.2063},{-69.6823,70.2063}}));
        connect(integrator1.y,gain1.u) annotation(Line(visible=true,points={{61.0375,35.1031},{61.0375,-46.41},{-82.5,-46.41},{-82.5,-45},{-82.5,26.7203},{-82.5,35.1031},{-69.6823,35.1031}}));
        connect(gain1.y,add31.u2) annotation(Line(visible=true,points={{-46.6295,35.1031},{-24.6246,35.1031}}));
        connect(add31.y,gain3.u) annotation(Line(visible=true,points={{-1.57178,35.1031},{7.85891,35.1031}}));
        connect(gain3.y,integrator1.u) annotation(Line(visible=true,points={{30.9117,35.1031},{37.9847,35.1031}}));
        connect(integrator1.y,integrator2.u) annotation(Line(visible=true,points={{61.0375,35.1031},{72.8259,35.1031}}));
      end SpringMass;
      model Equalizer
              parameter Real damp1=-5;
        parameter Real damp2=-5;
        parameter Real damp3=-5;
        parameter Real pi=3.14159265358979;
        parameter Real freq1=100;
        parameter Real freq2=500;
        parameter Real freq3=1000;
        parameter Real tauL1=1/(2*pi*(freq1 - damp1/100*freq1));
        parameter Real tauL2=1/(2*pi*(freq2 - damp2/100*freq2));
        parameter Real tauL3=1/(2*pi*(freq3 - damp3/100*freq3));
        parameter Real tauH1=1/(2*pi*(freq1 + damp1/100*freq1));
        parameter Real tauH2=1/(2*pi*(freq2 + damp2/100*freq2));
        parameter Real tauH3=1/(2*pi*(freq3 + damp3/100*freq3));
        Modelica.Blocks.Math.Add add1 annotation(Placement(visible=true,transformation(x=-45.4311,y=-37.0875,scale=0.1)));
        Modelica.Blocks.Math.Add add2 annotation(Placement(visible=true,transformation(x=13.7727,y=-39.7071,scale=0.1)));
        Modelica.Blocks.Math.Add add3 annotation(Placement(visible=true,transformation(x=74.0243,y=-39.9691,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction6(a={tauL1,1},b={1}) annotation(Placement(visible=true,transformation(x=-74.5091,y=-20.5837,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction1(b={1,0},a={1,1/tauH1}) annotation(Placement(visible=true,transformation(x=-73.7232,y=-59.6163,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction7(a={tauL2,1}) annotation(Placement(visible=true,transformation(x=-13.9955,y=-20.3218,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction2(b={1,0},a={1,1/tauH2}) annotation(Placement(visible=true,transformation(x=-13.4715,y=-58.8304,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction8(a={tauL3,1}) annotation(Placement(visible=true,transformation(x=39.9691,y=-23.2034,scale=0.1)));
        Modelica.Blocks.Continuous.TransferFunction transferFunction3(b={1,0},a={1,1/tauH3}) annotation(Placement(visible=true,transformation(x=41.5408,y=-59.8783,scale=0.1)));
        Modelica.Blocks.Sources.Ramp ramp2(duration=10,height=300) annotation(Placement(visible=true,transformation(x=-80.5342,y=29.1894,scale=0.1)));
        Modelica.Blocks.Math.Sin sin1 annotation(Placement(visible=true,transformation(x=-17.9249,y=45.6931,scale=0.1)));
        Modelica.Blocks.Math.Product product1 annotation(Placement(visible=true,transformation(x=-50.6704,y=45.6931,scale=0.1)));
        Modelica.Blocks.Sources.Ramp ramp1(duration=10,height=300) annotation(Placement(visible=true,transformation(x=-79.7483,y=59.0532,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,255,0}, fillPattern=FillPattern.Solid, extent={{-100.01,-100.28},{100.01,100.01}})}));

      equation
        connect(sin1.y,transferFunction6.u) annotation(Line(visible=true,points={{-7.07302,45.8436},{15,45.8436},{15,0},{-90,0},{-90,-20.6951},{-86.71,-20.4332}}));
        connect(sin1.y,transferFunction1.u) annotation(Line(visible=true,points={{-7.07302,45.8436},{0,45.8436},{0,7.5},{-97.5,7.5},{-97.5,-59.4658},{-85.9241,-59.4658}}));
        connect(ramp1.y,product1.u1) annotation(Line(visible=true,points={{-68.8965,59.2038},{-62.8713,51.8688}}));
        connect(ramp2.y,product1.u2) annotation(Line(visible=true,points={{-69.6823,29.3399},{-62.8713,39.8185}}));
        connect(product1.y,sin1.u) annotation(Line(visible=true,points={{-39.8185,45.8436},{-30.1258,45.8436}}));
        connect(add2.y,transferFunction3.u) annotation(Line(visible=true,points={{24.79,-39.55},{29.52,-59.88}}));
        connect(transferFunction3.y,add3.u2) annotation(Line(visible=true,points={{52.36,-59.88},{62.11,-45.95}}));
        connect(add2.y,transferFunction8.u) annotation(Line(visible=true,points={{24.79,-39.55},{27.85,-23.12}}));
        connect(transferFunction8.y,add3.u1) annotation(Line(visible=true,points={{50.97,-23.12},{62.11,-33.98}}));
        connect(add1.y,transferFunction2.u) annotation(Line(visible=true,points={{-34.54,-37.04},{-25.62,-58.77}}));
        connect(transferFunction2.y,add2.u2) annotation(Line(visible=true,points={{-2.51,-58.77},{1.67,-45.68}}));
        connect(add1.y,transferFunction7.u) annotation(Line(visible=true,points={{-34.54,-37.04},{-26.18,-20.33}}));
        connect(transferFunction7.y,add2.u1) annotation(Line(visible=true,points={{-3.06,-20.33},{1.67,-33.7}}));
        connect(transferFunction1.y,add1.u2) annotation(Line(visible=true,points={{-62.94,-59.6},{-57.37,-43.17}}));
        connect(transferFunction6.y,add1.u1) annotation(Line(visible=true,points={{-63.5,-20.33},{-57.37,-30.91}}));
      end Equalizer;
    end SystemTests;
  end BlockModels;
  package RotationalModels
      package SpringInertia
          model StepTorque
              Modelica.Blocks.Sources.Step step1(startTime=1) annotation(Placement(visible=true,transformation(x=-80,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-40,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=-5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=10) annotation(Placement(visible=true,transformation(x=32.5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=70,y=-7.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.33},{100.07,100.07}})}));

      equation
        connect(spring1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{42.4381,-7.33498},{69.9443,-7.33498}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{4.97731,-7.33498},{22.5289,-7.33498}}));
        connect(torque1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-30.1258,-7.33498},{-14.9319,-7.33498}}));
        connect(step1.y,torque1.tau) annotation(Line(visible=true,points={{-69.1584,-7.33498},{-52.1308,-7.33498}}));
      end StepTorque;
      model SineTorque
              Modelica.Mechanics.Rotational.Spring spring1(c=10) annotation(Placement(visible=true,transformation(x=40,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=70,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=-2.5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-40,y=-7.5,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1(amplitude=1,freqHz=0.356) annotation(Placement(visible=true,transformation(x=-80,y=-7.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-99.81},{99.81,100.07}})}));

      equation
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-69.1584,-7.33498},{-52.1308,-7.33498}}));
        connect(torque1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-30.1258,-7.33498},{-12.5743,-7.33498}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{7.33498,-7.33498},{29.8639,-7.33498}}));
        connect(spring1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{50.0351,-7.33498},{69.9443,-7.33498}}));
      end SineTorque;
      model StepPosition
              Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=35,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=70,y=-7.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-99.81},{100.07,100.07}})}));
        Modelica.Blocks.Sources.Step step1(startTime=1) annotation(Placement(visible=true,transformation(x=-80,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=-5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Position position1 annotation(Placement(visible=true,transformation(x=-42.5,y=-7.5,scale=0.1)));

      equation
        connect(step1.y,position1.phi_ref) annotation(Line(visible=true,points={{-69.1775,-7.44141},{-54.5703,-7.44141}}));
        connect(position1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-32.5217,-7.44141},{-15.1584,-7.44141}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{4.96094,-7.44141},{24.8047,-7.44141}}));
        connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{45.0578,-7.33498},{69.9443,-7.33498}}));
      end StepPosition;
      model SineAccelerate
              Modelica.Blocks.Sources.Sine sine1(amplitude=1,freqHz=0.356) annotation(Placement(visible=true,transformation(x=-80,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Speed speed1 annotation(Placement(visible=true,transformation(x=-42.5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=-5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=10) annotation(Placement(visible=true,transformation(x=35,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=70,y=-7.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.33}})}));

      equation
        connect(spring1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{45.0578,-7.33498},{69.9443,-7.33498}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{4.97731,-7.33498},{24.8866,-7.33498}}));
        connect(speed1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-32.4835,-7.33498},{-14.9319,-7.33498}}));
        connect(sine1.y,speed1.w_ref) annotation(Line(visible=true,points={{-69.1584,-7.33498},{-54.4884,-7.33498}}));
      end SineAccelerate;
      model SineSpeed
              Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=69.571,y=-10.1052,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=10) annotation(Placement(visible=true,transformation(x=40,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=-2.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Accelerate accelerate1 annotation(Placement(visible=true,transformation(x=-40,y=-10,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1(amplitude=1,freqHz=0.356) annotation(Placement(visible=true,transformation(x=-80,y=-10,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.07}})}));

      equation
        connect(sine1.y,accelerate1.a) annotation(Line(visible=true,points={{-69.1584,-9.95462},{-52.1308,-9.95462}}));
        connect(accelerate1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-30.1258,-9.95462},{-12.5743,-9.95462}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{7.33498,-9.95462},{29.8639,-9.95462}}));
        connect(spring1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{50.0351,-9.95462},{69.4204,-9.95462}}));
      end SineSpeed;
      model SineTorque2intertias
              Modelica.Mechanics.Rotational.Fixed fixed1(phi0=1) annotation(Placement(visible=true,transformation(x=85.4064,y=-5,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=10) annotation(Placement(visible=true,transformation(x=65,y=-5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=2) annotation(Placement(visible=true,transformation(x=37.5,y=-5,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=20,d=1) annotation(Placement(visible=true,transformation(x=7.5,y=-5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=-22.5,y=-5,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-50,y=-5,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1(amplitude=1,freqHz=0.356) annotation(Placement(visible=true,transformation(x=-82.5,y=-5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-99.81},{99.81,100.07}})}));

      equation
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-71.5161,-4.97731},{-62.0854,-4.97731}}));
        connect(torque1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-40.0804,-4.97731},{-32.4835,-4.97731}}));
        connect(inertia2.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{-12.5743,-4.97731},{-2.61964,-4.97731}}));
        connect(springDamper1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{17.5516,-4.97731},{27.5062,-4.97731}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{47.4154,-4.97731},{55.0124,-4.97731}}));
        connect(spring1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{74.9216,-4.97731},{85.4002,-4.97731}}));
      end SineTorque2intertias;
      model Shaft
              Modelica.Mechanics.Rotational.SpringDamper springDamper4(c=30,d=1) annotation(Placement(visible=true,transformation(x=-50,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2(J=5) annotation(Placement(visible=true,transformation(x=-75,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper5(c=22,d=1) annotation(Placement(visible=true,transformation(x=-100,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=-125,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia3(J=3) annotation(Placement(visible=true,transformation(x=-25,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper3(c=29,d=1) annotation(Placement(visible=true,transformation(x=-6.66134e-16,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia4(J=4) annotation(Placement(visible=true,transformation(x=25,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=12,d=1) annotation(Placement(visible=true,transformation(x=50,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia5(J=2) annotation(Placement(visible=true,transformation(x=75,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=18,d=1) annotation(Placement(visible=true,transformation(x=102.5,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia6 annotation(Placement(visible=true,transformation(x=132.5,y=15,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque2 torque21 annotation(Placement(visible=true,transformation(x=7.5,y=52.5,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=7.5,y=85,scale=0.1,rotation=270)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));

      equation
        connect(torque21.flange_b,inertia6.flange_b) annotation(Line(visible=true,points={{17.2861,52.5639},{147.461,52.5},{147.461,15},{142.522,15.1694}}));
        connect(inertia1.flange_a,torque21.flange_a) annotation(Line(visible=true,points={{-135.114,15.1694},{-142.5,15},{-142.5,52.5},{-2.46944,52.5639}}));
        connect(sine1.y,torque21.tau) annotation(Line(visible=true,points={{7.40833,74.0833},{7.40833,56.4444}}));
        connect(springDamper1.flange_b,inertia6.flange_a) annotation(Line(visible=true,points={{112.536,15.1694},{122.414,15.1694}}));
        connect(inertia5.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{85.0194,15.1694},{92.4278,15.1694}}));
        connect(springDamper2.flange_b,inertia5.flange_a) annotation(Line(visible=true,points={{59.9722,15.1694},{64.9111,15.1694}}));
        connect(inertia4.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{34.925,15.1694},{39.8639,15.1694}}));
        connect(springDamper3.flange_b,inertia4.flange_a) annotation(Line(visible=true,points={{9.87778,15.1694},{14.8167,15.1694}}));
        connect(inertia3.flange_b,springDamper3.flange_a) annotation(Line(visible=true,points={{-15.1694,15.1694},{-10.2306,15.1694}}));
        connect(springDamper4.flange_b,inertia3.flange_a) annotation(Line(visible=true,points={{-40.2167,15.1694},{-34.925,15.1694}}));
        connect(inertia1.flange_b,springDamper5.flange_a) annotation(Line(visible=true,points={{-115.006,15.1694},{-110.067,15.1694}}));
        connect(springDamper5.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-89.9583,15.1694},{-85.0194,15.1694}}));
        connect(inertia2.flange_b,springDamper4.flange_a) annotation(Line(visible=true,points={{-64.9111,15.1694},{-59.9722,15.1694}}));
      end Shaft;
      model BacklashTest
              Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=85,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.ElastoBacklash elastoBacklash1(b=1,d=100) annotation(Placement(visible=true,transformation(x=50,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=10,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-25,y=-7.5,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-77.5,y=-7.5,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}));

      equation
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-66.5388,-7.33498},{-37.1988,-7.33498}}));
        connect(torque1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-14.9319,-7.33498},{0,-7.33498}}));
        connect(inertia1.flange_b,elastoBacklash1.flange_a) annotation(Line(visible=true,points={{19.9092,-7.33498},{40.0804,-7.33498}}));
        connect(elastoBacklash1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{59.9897,-7.33498},{84.8762,-7.33498}}));
      end BacklashTest;
    end SpringInertia;
    package Gears
          model IdealGear
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-99.94,-100.33},{99.94,100.33}})}));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=132.5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.IdealGear idealGear1(ratio=2) annotation(Placement(visible=true,transformation(x=53.6489,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=107.351,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10) annotation(Placement(visible=true,transformation(x=25.6188,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=79.3214,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=-5,y=-7.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-37.5,y=-7.5,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-80,y=-7.5,scale=0.1)));

      equation
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-69.2158,-7.33498},{-49.5685,-7.33498}}));
        connect(torque1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-27.5635,-7.33498},{-14.9893,-7.33498}}));
        connect(inertia2.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{4.91997,-7.33498},{15.3985,-7.33498}}));
        connect(springDamper2.flange_b,idealGear1.flange_a) annotation(Line(visible=true,points={{35.5697,-7.33498},{43.4286,-7.33498}}));
        connect(idealGear1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{63.5998,-7.33498},{69.1011,-7.33498}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{89.2723,-7.33498},{97.1312,-7.33498}}));
        connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{117.302,-7.33498},{132.496,-7.33498}}));
      end IdealGear;
      model Gear
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,255,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-42.5,y=-10,scale=0.1)));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-77.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=67.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=95,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10) annotation(Placement(visible=true,transformation(x=-15,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=12.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=120,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear1(ratio=2) annotation(Placement(visible=true,transformation(x=37.5,y=-10,scale=0.1)));

      equation
        connect(inertia2.flange_b,gear1.flange_a) annotation(Line(visible=true,points={{22.3006,-9.82738},{27.2143,-9.82738}}));
        connect(gear1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{47.247,-9.82738},{57.4524,-9.82738}}));
        connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{104.699,-9.82738},{119.818,-9.82738}}));
        connect(springDamper2.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-4.9849,-9.96981},{2.30072,-9.96981}}));
        connect(torque1.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{-32.5936,-9.96981},{-25.308,-9.96981}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{77.4577,-9.96981},{84.7434,-9.96981}}));
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-66.5961,-9.95462},{-54.5458,-9.95462}}));
      end Gear;
      model Gear2
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-82.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=127.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-47.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear2 gear21(i=2,b=0.1) annotation(Placement(visible=true,transformation(x=46.247,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=72.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=102.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=17.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10) annotation(Placement(visible=true,transformation(x=-17.5,y=-10,scale=0.1)));

      equation
        connect(springDamper2.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-7.66908,-9.96981},{7.28563,-9.96981}}));
        connect(torque1.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{-37.5785,-9.96981},{-27.6087,-9.96981}}));
        connect(inertia2.flange_b,gear21.flange_a) annotation(Line(visible=true,points={{27.2252,-9.96981},{36.0447,-9.96981}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{82.3988,-9.82738},{92.2262,-9.82738}}));
        connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{112.259,-9.82738},{127.378,-9.82738}}));
        connect(gear21.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{55.9405,-9.82738},{62.3661,-9.82738}}));
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-71.8155,-9.82738},{-59.7202,-9.82738}}));
      end Gear2;
      model IdealGearClutch
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,255,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.33},{99.81,100.33}})}));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-122.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-85,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=-52.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10) annotation(Placement(visible=true,transformation(x=10,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.IdealGear idealGear1(ratio=2) annotation(Placement(visible=true,transformation(x=42.5,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=75,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=105,y=-10,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=130,y=-10,scale=0.1)));
        Modelica.Blocks.Sources.Step step1(startTime=1,height=10) annotation(Placement(visible=true,transformation(x=-70,y=37.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch1 annotation(Placement(visible=true,transformation(x=-20,y=-10,scale=0.1)));

      equation
        connect(inertia2.flange_b,clutch1.flange_a) annotation(Line(visible=true,points={{-42.7404,-9.49786},{-30.5288,-9.49786}}));
        connect(clutch1.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{-10.1763,-9.49786},{5.68434e-14,-9.49786}}));
        connect(step1.y,clutch1.f_normalized) annotation(Line(visible=true,points={{-59.0224,37.9915},{-20.1083,37.5},{-20.3526,1.35684}}));
        connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{115.006,-9.87778},{129.822,-9.87778}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{85.0194,-9.87778},{94.8972,-9.87778}}));
        connect(idealGear1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{52.5639,-9.87778},{64.9111,-9.87778}}));
        connect(springDamper2.flange_b,idealGear1.flange_a) annotation(Line(visible=true,points={{20.1083,-9.87778},{32.4556,-9.87778}}));
        connect(torque1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-75.1417,-9.87778},{-62.4417,-9.87778}}));
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-111.478,-9.87778},{-97.0139,-9.87778}}));
      end IdealGearClutch;
      model IdealGearBrake
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.59,-99.81},{99.81,100.33}})}));
        Modelica.Blocks.Sources.Sine sine1 annotation(Placement(visible=true,transformation(x=-115,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-77.5,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=-42.5,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10) annotation(Placement(visible=true,transformation(x=-10,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.IdealGear idealGear1(ratio=2) annotation(Placement(visible=true,transformation(x=22.5,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=52.5,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1) annotation(Placement(visible=true,transformation(x=82.5,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.Brake brake1 annotation(Placement(visible=true,transformation(x=115,y=-15,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=140,y=-15,scale=0.1)));
        Modelica.Blocks.Sources.Ramp ramp1(startTime=1) annotation(Placement(visible=true,transformation(x=82.5,y=25,scale=0.1)));

      equation
        connect(ramp1.y,brake1.f_normalized) annotation(Line(visible=true,points={{93.4637,25.1485},{114.945,25.1485},{114.945,-3.92946}}));
        connect(brake1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{124.899,-14.9319},{139.831,-14.9319}}));
        connect(springDamper1.flange_b,brake1.flange_a) annotation(Line(visible=true,points={{92.4158,-14.9319},{104.99,-14.9319}}));
        connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{62.29,-14.9319},{72.5066,-14.9319}}));
        connect(idealGear1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{32.4262,-14.9319},{42.3808,-14.9319}}));
        connect(springDamper2.flange_b,idealGear1.flange_a) annotation(Line(visible=true,points={{-0.0573432,-14.9319},{12.5169,-14.9319}}));
        connect(inertia2.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{-32.5408,-14.9319},{-20.2285,-14.9319}}));
        connect(torque1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-67.644,-14.9319},{-52.712,-14.9319}}));
        connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-104.057,-14.9319},{-89.6489,-14.9319}}));
      end IdealGearBrake;
      model GearB
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-100.33,-100.07},{100.07,100.33}})}));
        Modelica.Mechanics.Rotational.Inertia inertia2_copy_copy annotation(Placement(visible=true,transformation(x=67.5,y=35,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2_copy annotation(Placement(visible=true,transformation(x=2.5,y=35,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear1_copy(ratio=2) annotation(Placement(visible=true,transformation(x=35,y=35,scale=0.1)));
        Modelica.Mechanics.Rotational.ConstantSpeed constantSpeed1(w_fixed=1) annotation(Placement(visible=true,transformation(x=-37.5,y=35.0945,scale=0.075)));

      equation
        connect(constantSpeed1.flange,inertia2_copy.flange_a) annotation(Line(visible=true,points={{-30.0124,35.1461},{-7.50311,35.1461}}));
        connect(gear1_copy.flange_b,inertia2_copy_copy.flange_a) annotation(Line(visible=true,points={{44.9792,35.1518},{57.4524,35.1518}}));
        connect(inertia2_copy.flange_b,gear1_copy.flange_a) annotation(Line(visible=true,points={{12.4732,35.1518},{24.9464,35.1518}}));
      end GearB;
    end Gears;
    package SystemTests
          model CoupledClutches
              annotation(Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.93},{9.99,9.97}})}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
        extends Modelica.Mechanics.Rotational.Examples.CoupledClutches;
      end CoupledClutches;
      model ElasticBearing
              annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}})),Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.95},{9.99,9.95}})}));
        extends Modelica.Mechanics.Rotational.Examples.ElasticBearing;
      end ElasticBearing;
      model First
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.95},{9.99,9.95}})}));
        extends Modelica.Mechanics.Rotational.Examples.First;
      end First;
      model Friction
              annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})),Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.93},{9.99,9.97}})}));
        extends Modelica.Mechanics.Rotational.Examples.Friction;
      end Friction;
      model LossyGearDemo1
              annotation(Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.93},{9.99,9.97}})}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
        extends Modelica.Mechanics.Rotational.Examples.LossyGearDemo1;
      end LossyGearDemo1;
      model LossyGearDemo2
              annotation(Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.93},{9.99,9.97}})}),Diagram(coordinateSystem(extent={{-100,-100},{100,100}})));
        extends Modelica.Mechanics.Rotational.Examples.LossyGearDemo2;
      end LossyGearDemo2;
      model CarTransmission
              annotation(Diagram(coordinateSystem(extent={{-200,-100},{500,100}})),Icon(coordinateSystem(extent={{-10,-10},{10,10}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-9.99,-9.93},{9.99,9.97}})}));
        Modelica.Blocks.Logical.Switch switch3 annotation(Placement(visible=true,transformation(x=116.984,y=8.83422,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch2 annotation(Placement(visible=true,transformation(x=114.169,y=33.0408,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch1 annotation(Placement(visible=true,transformation(x=110.228,y=63.4397,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch4 annotation(Placement(visible=true,transformation(x=119.235,y=-20.1574,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch5 annotation(Placement(visible=true,transformation(x=119.235,y=-48.8675,scale=0.1)));
        Modelica.Blocks.Logical.And AND1 annotation(Placement(visible=true,transformation(x=60.9707,y=69.9136,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold1(threshold=1.1) annotation(Placement(visible=true,transformation(x=15.0909,y=58.6547,scale=0.1)));
        Modelica.Blocks.Logical.And AND2 annotation(Placement(visible=true,transformation(x=64.6299,y=33.3223,scale=0.1)));
        Modelica.Blocks.Logical.And AND3 annotation(Placement(visible=true,transformation(x=63.7855,y=7.9898,scale=0.1)));
        Modelica.Blocks.Logical.And AND4 annotation(Placement(visible=true,transformation(x=63.504,y=-21.8462,scale=0.1)));
        Modelica.Blocks.Logical.And AND5 annotation(Placement(visible=true,transformation(x=66.8816,y=-49.7119,scale=0.1)));
        Modelica.Blocks.Logical.And AND6 annotation(Placement(visible=true,transformation(x=66.6002,y=-84.3329,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold2(threshold=1.9) annotation(Placement(visible=true,transformation(x=-15.3081,y=50.7735,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold2(threshold=2.1) annotation(Placement(visible=true,transformation(x=-14.4637,y=24.8781,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold3(threshold=2.9) annotation(Placement(visible=true,transformation(x=15.9353,y=34.1667,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold3(threshold=3.1) annotation(Placement(visible=true,transformation(x=16.4982,y=10.523,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold4(threshold=3.9) annotation(Placement(visible=true,transformation(x=-12.4934,y=-2.42465,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold4(threshold=4.1) annotation(Placement(visible=true,transformation(x=-12.2119,y=-25.5053,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold5(threshold=4.9) annotation(Placement(visible=true,transformation(x=17.3426,y=-27.4756,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold5(threshold=5.1) annotation(Placement(visible=true,transformation(x=17.6241,y=-50.5563,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold6(threshold=-1.1) annotation(Placement(visible=true,transformation(x=-9.96011,y=-59.8449,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant2(k=0) annotation(Placement(visible=true,transformation(x=-77.5133,y=18.1228,scale=0.1)));
        Modelica.Blocks.Sources.Constant constant1(k=1000) annotation(Placement(visible=true,transformation(x=-77.7948,y=52.1809,scale=0.1)));
        Modelica.Blocks.Logical.GreaterThreshold greaterThreshold1(threshold=0.9) annotation(Placement(visible=true,transformation(x=15,y=85,scale=0.1)));
        Modelica.Blocks.Sources.Ramp ramp2(height=100) annotation(Placement(visible=true,transformation(x=-174.417,y=-13.402,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=-142.892,y=-13.402,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1(J=0.5) annotation(Placement(visible=true,transformation(x=-114.105,y=-13.402,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper3(c=600000000.0,d=1000) annotation(Placement(visible=true,transformation(x=-85.4721,y=-13.402,scale=0.1)));
        Modelica.Blocks.Sources.Trapezoid trapezoid1(amplitude=1000,rising=0.1,falling=0.1,width=0.8) annotation(Placement(visible=true,transformation(x=-80.6095,y=-55.0598,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch1(fn_max=500) annotation(Placement(visible=true,transformation(x=-54.7141,y=-13.1206,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch7(fn_max=500) annotation(Placement(visible=true,transformation(x=148.508,y=-81.2367,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch6(fn_max=500) annotation(Placement(visible=true,transformation(x=147.945,y=-48.8675,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch4(fn_max=500) annotation(Placement(visible=true,transformation(x=144.568,y=8.83422,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch3(fn_max=500) annotation(Placement(visible=true,transformation(x=142.879,y=36.9814,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch2(fn_max=500) annotation(Placement(visible=true,transformation(x=142.598,y=67.0988,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear2(ratio=0.4) annotation(Placement(visible=true,transformation(x=173.841,y=38.1073,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear3(ratio=0.6) annotation(Placement(visible=true,transformation(x=174.967,y=8.83422,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear5 annotation(Placement(visible=true,transformation(x=177.219,y=-48.8675,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear4(ratio=0.8) annotation(Placement(visible=true,transformation(x=176.093,y=-20.1574,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear6(ratio=-0.2) annotation(Placement(visible=true,transformation(x=178.626,y=-80.6738,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=220.847,y=-22.1277,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10000.0,d=10) annotation(Placement(visible=true,transformation(x=255.749,y=-22.1277,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia3 annotation(Placement(visible=true,transformation(x=289.526,y=-21.5647,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia4 annotation(Placement(visible=true,transformation(x=351.731,y=-21.2832,scale=0.1)));
        Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=100000.0,d=10) annotation(Placement(visible=true,transformation(x=382.974,y=-21.2832,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia5 annotation(Placement(visible=true,transformation(x=414.218,y=-21.2832,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=1000) annotation(Placement(visible=true,transformation(x=447.713,y=-21.2832,scale=0.1)));
        Modelica.Mechanics.Rotational.Damper damper1(d=100) annotation(Placement(visible=true,transformation(x=478.675,y=-21.2832,scale=0.1)));
        Modelica.Blocks.Sources.Ramp ramp1(startTime=15,height=100) annotation(Placement(visible=true,transformation(x=400.707,y=43.7367,scale=0.1)));
        Modelica.Mechanics.Rotational.Brake brake1 annotation(Placement(visible=true,transformation(x=442.365,y=14.4637,scale=0.1)));
        Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=476.986,y=14.4637,scale=0.1)));
        Modelica.Mechanics.Rotational.Clutch clutch5(fn_max=500) annotation(Placement(visible=true,transformation(x=150,y=-20,scale=0.1)));
        Modelica.Blocks.Logical.Switch switch6 annotation(Placement(visible=true,transformation(x=118.672,y=-82.9255,scale=0.1)));
        Modelica.Blocks.Sources.TimeTable timeTable1(table={{0,0},{1,0},{1,-1},{2,-1},{2,0},{4,0},{4,1},{5,1},{5,2},{7,2},{7,3},{10,3},{10,4},{14,4},{14,5}}) annotation(Placement(visible=true,transformation(x=-77.5,y=85,scale=0.1)));
        Modelica.Blocks.Logical.LessThreshold lessThreshold6(threshold=-0.9) annotation(Placement(visible=true,transformation(x=-10,y=-87.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear7(ratio=0.25) annotation(Placement(visible=true,transformation(x=320.206,y=-21.5647,scale=0.1)));
        Modelica.Mechanics.Rotational.Gear gear1(ratio=0.2) annotation(Placement(visible=true,transformation(x=173.841,y=67.9433,scale=0.1)));

      equation
        connect(clutch2.flange_b,gear1.flange_a) annotation(Line(visible=true,points={{152.519,67.0278},{163.808,68.0861}}));
        connect(gear1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{183.917,68.0861},{211.081,-22.225}}));
        connect(inertia3.flange_b,gear7.flange_a) annotation(Line(visible=true,points={{299.628,-21.5194},{310.211,-21.5194}}));
        connect(gear7.flange_b,inertia4.flange_a) annotation(Line(visible=true,points={{330.319,-21.5194},{341.961,-21.1667}}));
        connect(AND6.u2,lessThreshold6.y) annotation(Line(visible=true,points={{54.4472,-92.075},{1.17778,-87.4889}}));
        connect(timeTable1.y,lessThreshold6.u) annotation(Line(visible=true,points={{-66.5556,85.0194},{-22.1056,-87.4889}}));
        connect(timeTable1.y,greaterThreshold6.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{-22.0917,-59.7958}}));
        connect(timeTable1.y,lessThreshold5.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{5.425,-50.5354}}));
        connect(timeTable1.y,lessThreshold4.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{-24.4729,-25.4}}));
        connect(timeTable1.y,greaterThreshold5.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{5.16042,-27.2521}}));
        connect(timeTable1.y,greaterThreshold4.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{-24.7375,-2.38125}}));
        connect(timeTable1.y,lessThreshold3.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{4.36667,10.5833}}));
        connect(timeTable1.y,lessThreshold2.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{-26.5896,24.8708}}));
        connect(timeTable1.y,greaterThreshold3.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{3.57292,34.3958}}));
        connect(timeTable1.y,greaterThreshold2.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{-27.6479,50.8}}));
        connect(timeTable1.y,lessThreshold1.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{2.77917,58.7375}}));
        connect(timeTable1.y,greaterThreshold1.u) annotation(Line(visible=true,points={{-66.8063,84.9312},{2.77917,85.1958}}));
        connect(ramp1.y,brake1.f_normalized) annotation(Line(visible=true,points={{411.56,43.9208},{442.5,42.5979},{441.987,25.6646}}));
        connect(trapezoid1.y,clutch1.f_normalized) annotation(Line(visible=true,points={{-69.7167,-55.0333},{-64.9542,-55.5625},{-69.7167,2.91042},{-55.4292,4.49792},{-54.9,-2.11667}}));
        connect(switch2.y,clutch3.f_normalized) annotation(Line(visible=true,points={{125.017,33.0729},{129.25,32.8083},{129.25,52.5},{144.067,52.5},{142.744,48.1542}}));
        connect(switch1.y,clutch2.f_normalized) annotation(Line(visible=true,points={{121.048,63.5},{127.5,65.3521},{127.5,88.1062},{142.5,87.0479},{142.479,78.3167}}));
        connect(switch3.y,clutch4.f_normalized) annotation(Line(visible=true,points={{127.662,8.99583},{130.837,7.5},{130.837,22.5},{145.39,24.6062},{144.331,19.8437}}));
        connect(switch4.y,clutch5.f_normalized) annotation(Line(visible=true,points={{130.044,-20.1083},{135,-19.5792},{135,-4.7625},{150,-3.175},{149.623,-8.99583}}));
        connect(switch5.y,clutch6.f_normalized) annotation(Line(visible=true,points={{130.044,-48.6833},{135,-48.9479},{135,-33.8667},{147.506,-33.8667},{147.771,-37.8354}}));
        connect(switch6.y,clutch7.f_normalized) annotation(Line(visible=true,points={{129.515,-82.8146},{135,-82.5},{135,-62.9708},{148.035,-62.9708},{148.3,-70.1146}}));
        connect(switch6.u2,AND6.y) annotation(Line(visible=true,points={{106.496,-82.8146},{77.3917,-84.4021}}));
        connect(constant1.y,switch6.u1) annotation(Line(visible=true,points={{-67.0708,52.1229},{106.496,-74.8771}}));
        connect(constant2.y,switch6.u3) annotation(Line(visible=true,points={{-66.8063,18.2562},{106.496,-90.7521}}));
        connect(clutch5.flange_a,clutch1.flange_b) annotation(Line(visible=true,points={{139.833,-19.8438},{-44.8458,-12.9646}}));
        connect(clutch5.flange_b,gear4.flange_a) annotation(Line(visible=true,points={{159.942,-19.8438},{166.027,-20.1083}}));
        connect(clutch4.flange_a,clutch1.flange_b) annotation(Line(visible=true,points={{134.277,8.99583},{-44.8458,-12.9646}}));
        connect(brake1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{452.507,14.9931},{477.201,14.9931}}));
        connect(damper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{488.667,-21.1667},{477.201,14.9931}}));
        connect(inertia5.flange_b,brake1.flange_a) annotation(Line(visible=true,points={{424.285,-21.1667},{432.222,14.9931}}));
        connect(spring1.flange_b,damper1.flange_a) annotation(Line(visible=true,points={{457.799,-21.1667},{468.382,-21.1667}}));
        connect(inertia5.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{424.285,-21.1667},{437.514,-21.1667}}));
        connect(springDamper2.flange_b,inertia5.flange_a) annotation(Line(visible=true,points={{392.535,-21.1667},{404,-21.1667}}));
        connect(inertia4.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{361.667,-21.1667},{373.132,-21.1667}}));
        connect(springDamper1.flange_b,inertia3.flange_a) annotation(Line(visible=true,points={{265.535,-22.0486},{279.646,-21.1667}}));
        connect(inertia2.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{231.139,-22.0486},{246.132,-22.0486}}));
        connect(gear6.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{188.806,-80.2569},{210.854,-22.0486}}));
        connect(gear5.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{187.042,-48.5069},{210.854,-22.0486}}));
        connect(gear4.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{186.16,-20.2847},{210.854,-22.0486}}));
        connect(gear3.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{185.278,8.81944},{210.854,-22.0486}}));
        connect(gear2.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{183.514,37.9236},{210.854,-22.0486}}));
        connect(clutch7.flange_b,gear6.flange_a) annotation(Line(visible=true,points={{158.819,-81.1389},{168.521,-80.2569}}));
        connect(gear5.flange_a,clutch6.flange_b) annotation(Line(visible=true,points={{166.757,-48.5069},{157.938,-48.5069}}));
        connect(gear3.flange_a,clutch4.flange_b) annotation(Line(visible=true,points={{164.993,8.81944},{154.41,8.81944}}));
        connect(gear2.flange_a,clutch3.flange_b) annotation(Line(visible=true,points={{164.111,37.9236},{152.646,37.0417}}));
        connect(clutch1.flange_b,clutch2.flange_a) annotation(Line(visible=true,points={{-44.9097,-13.2292},{132.361,67.0278}}));
        connect(clutch3.flange_a,clutch1.flange_b) annotation(Line(visible=true,points={{133.243,37.0417},{-44.9097,-13.2292}}));
        connect(clutch6.flange_a,clutch1.flange_b) annotation(Line(visible=true,points={{137.653,-48.5069},{-44.9097,-13.2292}}));
        connect(clutch7.flange_a,clutch1.flange_b) annotation(Line(visible=true,points={{138.535,-81.1389},{-44.9097,-13.2292}}));
        connect(springDamper3.flange_b,clutch1.flange_a) annotation(Line(visible=true,points={{-75.7778,-13.2292},{-65.1944,-13.2292}}));
        connect(inertia1.flange_b,springDamper3.flange_a) annotation(Line(visible=true,points={{-104,-13.2292},{-95.1806,-13.2292}}));
        connect(torque1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-133.104,-13.2292},{-124.285,-13.2292}}));
        connect(ramp2.y,torque1.tau) annotation(Line(visible=true,points={{-163.09,-13.2292},{-155.153,-13.2292}}));
        connect(greaterThreshold1.y,AND1.u1) annotation(Line(visible=true,points={{25.3898,85.3495},{48.4341,69.9866}}));
        connect(switch1.u3,constant2.y) annotation(Line(visible=true,points={{98.13,56.12},{-67.66,17.84}}));
        connect(constant2.y,switch2.u3) annotation(Line(visible=true,points={{-67.1,18.69},{101.5,26.29}}));
        connect(switch3.u3,constant2.y) annotation(Line(visible=true,points={{104.6,1.8},{-66.82,18.69}}));
        connect(constant2.y,switch4.u3) annotation(Line(visible=true,points={{-66.82,18.69},{106.85,-26.63}}));
        connect(switch5.u3,constant2.y) annotation(Line(visible=true,points={{106.57,-56.19},{-67.66,17.28}}));
        connect(switch5.u1,constant1.y) annotation(Line(visible=true,points={{106.01,-41.27},{-67.66,51.62}}));
        connect(constant1.y,switch4.u1) annotation(Line(visible=true,points={{-67.38,51.9},{106.29,-13.4}}));
        connect(switch3.u1,constant1.y) annotation(Line(visible=true,points={{104.32,14.75},{-67.1,51.62}}));
        connect(constant1.y,switch2.u1) annotation(Line(visible=true,points={{-67.1,52.46},{101.5,40.08}}));
        connect(constant1.y,switch1.u1) annotation(Line(visible=true,points={{-67.1,52.46},{98.13,71.04}}));
        connect(AND5.y,switch5.u2) annotation(Line(visible=true,points={{77.86,-49.43},{106.85,-48.87}}));
        connect(switch4.u2,AND4.y) annotation(Line(visible=true,points={{107.13,-20.44},{74.48,-21.85}}));
        connect(AND3.y,switch3.u2) annotation(Line(visible=true,points={{73.64,8.27},{105.72,8.55}}));
        connect(switch2.u2,AND2.y) annotation(Line(visible=true,points={{101.22,33.6},{75.33,32.48}}));
        connect(AND1.y,switch1.u2) annotation(Line(visible=true,points={{71.67,70.48},{99.25,63.16}}));
        connect(greaterThreshold6.y,AND6.u1) annotation(Line(visible=true,points={{0.74,-59.56},{53.93,-77.86}}));
        connect(lessThreshold5.y,AND5.u2) annotation(Line(visible=true,points={{27.76,-50.56},{54.5,-55.62}}));
        connect(greaterThreshold5.y,AND5.u1) annotation(Line(visible=true,points={{27.76,-27.48},{54.78,-44.08}}));
        connect(lessThreshold4.y,AND4.u2) annotation(Line(visible=true,points={{-0.95,-26.07},{51.4,-27.48}}));
        connect(greaterThreshold4.y,AND4.u1) annotation(Line(visible=true,points={{-2.08,-3.27},{51.12,-15.09}}));
        connect(lessThreshold3.y,AND3.u2) annotation(Line(visible=true,points={{26.07,11.37},{52.81,2.08}}));
        connect(greaterThreshold3.y,AND3.u1) annotation(Line(visible=true,points={{26.07,34.17},{50.84,14.46}}));
        connect(lessThreshold2.y,AND2.u2) annotation(Line(visible=true,points={{-4.61,24.6},{51.68,27.69}}));
        connect(greaterThreshold2.y,AND2.u1) annotation(Line(visible=true,points={{-4.61,50.77},{52.53,39.51}}));
        connect(lessThreshold1.y,AND1.u2) annotation(Line(visible=true,points={{26.35,58.65},{49.71,64.57}}));
      end CarTransmission;
      model DCMotor "Text book example of a DC Motor"
              Modelica.Electrical.Analog.Basic.Ground ground1 annotation(Placement(visible=true,transformation(x=-80.9504,y=-10,scale=0.1)));
        Modelica.Electrical.Analog.Basic.Inductor inductor1 annotation(Placement(visible=true,transformation(x=-70.7895,y=49.8845,scale=0.1)));
        Modelica.Electrical.Analog.Basic.Resistor resistor1 annotation(Placement(visible=true,transformation(x=-40.9504,y=50,scale=0.1)));
        Modelica.Blocks.Sources.Step step1(height=-1) annotation(Placement(visible=true,transformation(x=26.5496,y=57.5,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true,transformation(x=19.0496,y=20,scale=0.1)));
        Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true,transformation(x=74.0496,y=20,scale=0.1)));
        Modelica.Electrical.Analog.Sources.ConstantVoltage constantVoltage1 annotation(Placement(visible=true,transformation(x=-91.2227,y=20.0206,scale=0.0890677,rotation=270)));
        Modelica.Electrical.Analog.Basic.EMF EMF1 annotation(Placement(visible=true,transformation(x=-10.9504,y=20,scale=0.1)));
        Modelica.Mechanics.Rotational.Spring spring1(c=1) annotation(Placement(visible=true,transformation(x=46.5496,y=20,scale=0.1)));
        Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true,transformation(x=75.1295,y=57.4867,scale=0.1)));
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.33},{100.33,100.07}})}));

      equation
        connect(resistor1.n,EMF1.p) annotation(Line(visible=true,points={{-30.9117,50.0351},{-11.0025,50.0351},{-11.0025,45},{-11.0025,30.1258}}));
        connect(constantVoltage1.p,inductor1.p) annotation(Line(visible=true,points={{-91.4253,29.078},{-91.4253,50.0351},{-86.71,50.0351},{-80.9468,50.0351}}));
        connect(EMF1.n,ground1.p) annotation(Line(visible=true,points={{-11.0025,9.95462},{-11.0025,3.92946},{-11.0025,0},{-80.9468,0}}));
        connect(torque1.flange_b,inertia2.flange_b) annotation(Line(visible=true,points={{85.1382,57.632},{95.8787,57.632},{95.8787,20.1712},{84.0903,20.1712}}));
        connect(step1.y,torque1.tau) annotation(Line(visible=true,points={{37.4608,57.632},{63.1333,57.632}}));
        connect(spring1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{56.5842,20.1712},{63.9191,20.1712}}));
        connect(constantVoltage1.n,ground1.p) annotation(Line(visible=true,points={{-91.4253,11.2644},{-91.4804,-0.15},{-91.4804,0},{-80.9468,0}}));
        connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true,points={{29.078,20.1712},{36.413,20.1712}}));
        connect(EMF1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-1.04785,20.1712},{8.90677,20.1712}}));
        connect(inductor1.n,resistor1.p) annotation(Line(visible=true,points={{-60.7756,50.0351},{-51.0829,50.0351}}));
      end DCMotor;
    end SystemTests;
  end RotationalModels;
  package AnalogModels
      package sourceTests
    end sourceTests;
    package SystemTests
          model CauerFilter
              annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.07}})}));
        extends Modelica.Electrical.Analog.Examples.CauerFilter;
      end CauerFilter;
      model ChuaCircuit
              annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100.414,-100.07},{79.6938,48.647}})}));
        extends Modelica.Electrical.Analog.Examples.ChuaCircuit;
      end ChuaCircuit;
      model DifferenceAmplifier
              annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.07}})}));
        extends Modelica.Electrical.Analog.Examples.DifferenceAmplifier;
      end DifferenceAmplifier;
      model NandGate
              annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Ellipse(visible=true, fillColor={255,85,0}, fillPattern=FillPattern.Solid, extent={{-100.07,-100.07},{99.81,100.07}})}));
        extends Modelica.Electrical.Analog.Examples.NandGate;
      end NandGate;
    end SystemTests;
  end AnalogModels;
annotation(uses(Modelica(version="2.2.2")));
package Professional
  model WeakAxis
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(visible=true, fillColor={143,143,143}, fillPattern=FillPattern.HorizontalCylinder, extent={{-100,-25},{100,25}}),Text(visible=true, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-110}}, textString="%name")}));
  Modelica.Blocks.Sources.Pulse pulse1(width=1, period=200) annotation(Placement(visible=true, transformation(x=-67.5, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Torque torque1 annotation(Placement(visible=true, transformation(x=-45, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Inertia inertia3 annotation(Placement(visible=true, transformation(x=67.5, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Spring spring2(c=1) annotation(Placement(visible=true, transformation(x=45, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Inertia inertia2 annotation(Placement(visible=true, transformation(x=22.5, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Inertia inertia1 annotation(Placement(visible=true, transformation(x=-22.5, y=17.5476, scale=0.075)));
  Modelica.Mechanics.Rotational.Spring spring1(c=0.7) annotation(Placement(visible=true, transformation(x=5.9952e-15, y=17.5476, scale=0.075)));

  equation
   connect(inertia1.flange_b,spring1.flange_a) annotation(Line(visible=true, points={{-15.119,17.3869},{-7.55952,17.3869}}));
  connect(spring2.flange_b,inertia3.flange_a) annotation(Line(visible=true, points={{52.5387,17.3869},{60.0982,17.3869}}));
  connect(pulse1.y,torque1.tau) annotation(Line(visible=true, points={{-59.3423,17.3869},{-54.0506,17.3869}}));
  connect(spring1.flange_b,inertia2.flange_a) annotation(Line(visible=true, points={{7.55952,17.3869},{15.119,17.3869}}));
  connect(torque1.flange_b,inertia1.flange_a) annotation(Line(visible=true, points={{-37.4196,17.3869},{-29.8601,17.3869}}));
  connect(inertia2.flange_b,spring2.flange_a) annotation(Line(visible=true, points={{29.8601,17.3869},{37.4196,17.3869}}));
end WeakAxis;
end Professional;
end TestModels;


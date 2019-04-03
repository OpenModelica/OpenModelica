package DataReconciliationTests
  model SimpleExple
    Real q1(uncertain=Uncertainty.refine)=1;
    Real q2(uncertain=Uncertainty.refine)=2;
    Real q3(uncertain=Uncertainty.refine);
    Real q4(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}));
  equation
    q1=q2 + q3;
    q4=q2 + q3;
  end SimpleExple;

  model VDI2048Exple
    Real mFDKEL(uncertain=Uncertainty.refine)=46.241;
    Real mFDKELL(uncertain=Uncertainty.refine)=45.668;
    Real mSPL(uncertain=Uncertainty.refine)=44.575;
    Real mSPLL(uncertain=Uncertainty.refine)=44.319;
    Real mV(uncertain=Uncertainty.refine);
    Real mHK(uncertain=Uncertainty.refine)=69.978;
    Real mA7(uncertain=Uncertainty.refine)=10.364;
    Real mA6(uncertain=Uncertainty.refine)=3.744;
    Real mA5(uncertain=Uncertainty.refine);
    Real mHDNK(uncertain=Uncertainty.refine);
    Real mD=2.092 annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}}),Bitmap(visible=true, origin={182.075,17.4625}, fileName="", imageSource="iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAACXBIWXMAAA7EAAAOxAGVKw4b
AAACj0lEQVQoFQGEAnv9AU1NTQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAABNTU3//03//////03//////03//////03//////03//////03//////01NTU0C
AAAAAACyAABOAACyAABOAACyAABOAACyAABOp6dZTk5OTk4Ap6enAACyAAAAAgAAAAAATgAA
sgAATgAAsgAATgAAsgAATgAAsqenp1lZAFlZAKenpwAATgAAAAIAAAAAALIAAE4AALIAAE4A
ALIAAE4AALIAAE4AAAAAAAAAAAAAAAAAALIAAAAEAAAAAABOAACyAABOAACyAABOAACyAABO
AACyWVmnp6enAAAAWVlZAABOAAAAAE1NTf//////Tf//////Tf//////Tf//////Tf//////
Tf//////Tf///01NTQIAAAAAAE4AALIAAE4AALJOTk5OTgAAAE4AALIAAE4AALIAAE4AALIA
AE4AAAACAAAAAACyAABOAACyTk5OWVlZWVlZTk4AAABOTk4ATk5OAACyAABOAACyAAAABAAA
AAAATgAAsk5OTllZWQAAAKenp1lZWU5Op4aGhgAAAE5OTrKysgAATgAAAAIAAAAAALJOTk5Z
WVkAAAAAAABZWVkAAABZWVl6enoAAACGhoZOTk4AALIAAAACAAAATk5OWVlZAAAAp6enAAAA
AAAAp6enAAAAWVlZenp6AAAAhoaGTk5OAAAAAgAAAFlZWQAAAAAAAFlZWaenpwAAAFlZWaen
pwAAAFlZWXp6egAAAIaGhgAAAAFNTU0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAB4KaX50xp77gAAAABJRU5ErkJggg==
", extent={{-2.075,0.0},{2.075,0.0}})}));
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png", imageSource="", extent={{-142.7312,-86.275},{142.7312,86.275}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png", imageSource="", extent={{-142.7312,-86.275},{142.7312,86.275}})}));
  equation
    mFDKEL + mFDKELL - mSPL - mSPLL + 0.4*mV=0;
    mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5=0;
    mA7 + mA6 + mA5 - mHDNK=0;
  end VDI2048Exple;

  model DistillationTower
    Real F(uncertain=Uncertainty.refine)=1;
    Real B(uncertain=Uncertainty.refine)=1;
    Real D1(uncertain=Uncertainty.refine);
    Real xF1(uncertain=Uncertainty.refine);
    Real xF2(uncertain=Uncertainty.refine);
    Real xB1(uncertain=Uncertainty.refine)=1;
    Real xB2(uncertain=Uncertainty.refine);
    Real xD1(uncertain=Uncertainty.refine)=1;
    Real xD2(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    F*xF1 - B*xB1 - D1*xD1=0;
    F*xF2 - B*xB2 - D1*xD2=0;
    xF1 + xF2=1;
    xB1 + xB2=1;
    xD1 + xD2=1;
  end DistillationTower;

end DataReconciliationTests;

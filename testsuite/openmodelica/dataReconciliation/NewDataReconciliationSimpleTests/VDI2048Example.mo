within NewDataReconciliationSimpleTests;
model VDI2048Example "NOK - Varianle mD cannot be reconciled"
  Real mFDKEL(uncertain=Uncertainty.refine,start=46.241)=46.241;
  Real mFDKELL(uncertain=Uncertainty.refine,start=45.668)=45.668;
  Real mSPL(uncertain=Uncertainty.refine,start=44.575)=44.575;
  Real mSPLL(uncertain=Uncertainty.refine,start=44.319)=44.319;
  Real mV(uncertain=Uncertainty.refine,start=0.525);
  Real mHK(uncertain=Uncertainty.refine,start=69.978)=69.978;
  Real mA7(uncertain=Uncertainty.refine,start=10.364)=10.364;
  Real mA6(uncertain=Uncertainty.refine,start=3.744)=3.744;
  Real mA5(uncertain=Uncertainty.refine,start=4.391);
  Real mHDNK(uncertain=Uncertainty.refine,start=18.498);
  Real mD(uncertain=Uncertainty.refine,start=2.092)=2.092 annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}}),Bitmap(visible=true, origin={182.075,17.4625}, fileName="", imageSource="iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAACXBIWXMAAA7EAAAOxAGVKw4b
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
",
 extent={{-2.075,0.0},{2.075,0.0}})}));
equation
  mFDKEL + mFDKELL - mSPL - mSPLL + 0.4*mV=0;
  mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5=0;
  mA7 + mA6 + mA5 - mHDNK=0;
  annotation(Icon(coordinateSystem(initialScale = 0.1, grid = {10, 10})), Diagram(coordinateSystem(initialScale = 0.1, grid = {10, 10})));
end VDI2048Example;

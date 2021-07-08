within ;
package Issue7544
  model Default
    annotation (Icon(graphics={Rectangle(
            extent={{-80,80},{0,0}},
            lineColor={28,108,200},
            fillColor={28,108,200},
            fillPattern=FillPattern.Solid), Ellipse(
            extent={{-74,76},{-10,8}},
            lineColor={238,46,47},
            fillColor={238,46,47},
            fillPattern=FillPattern.Solid,
            startAngle=0,
            endAngle=270)}));
  end Default;

  model None
    annotation (Icon(graphics={Rectangle(
            extent={{-80,80},{0,0}},
            lineColor={28,108,200},
            fillColor={28,108,200},
            fillPattern=FillPattern.Solid), Ellipse(
            extent={{-74,76},{-10,8}},
            lineColor={238,46,47},
            fillColor={238,46,47},
            fillPattern=FillPattern.Solid,
            startAngle=0,
            endAngle=270,
            closure=EllipseClosure.None)}));
  end None;

  model Chord
    annotation (Icon(graphics={Rectangle(
            extent={{-80,80},{0,0}},
            lineColor={28,108,200},
            fillColor={28,108,200},
            fillPattern=FillPattern.Solid), Ellipse(
            extent={{-74,76},{-10,8}},
            lineColor={238,46,47},
            fillColor={238,46,47},
            fillPattern=FillPattern.Solid,
            startAngle=0,
            endAngle=270,
            closure=EllipseClosure.Chord)}));
  end Chord;

  model Radial
    annotation (Icon(graphics={Rectangle(
            extent={{-80,80},{0,0}},
            lineColor={28,108,200},
            fillColor={28,108,200},
            fillPattern=FillPattern.Solid), Ellipse(
            extent={{-74,76},{-10,8}},
            lineColor={238,46,47},
            fillColor={238,46,47},
            fillPattern=FillPattern.Solid,
            startAngle=0,
            endAngle=270,
            closure=EllipseClosure.Radial)}));
  end Radial;
end Issue7544;

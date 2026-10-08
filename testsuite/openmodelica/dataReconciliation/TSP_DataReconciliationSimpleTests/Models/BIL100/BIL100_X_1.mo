within TSP_DataReconciliationSimpleTests.Models.BIL100;
model BIL100_X_1

  /* WARNING: This model illustrates parts of an industrial use-case but the associated numerical values do not correspond to the reality of the industrial process */
  TSP_DataReconciliationSimpleTests.Models.BIL100.BIL100 bil100(

    //  GV2(DP_pur (Q(uncertain = Uncertainty.refine))),

    //  GV3(DP_pur (Q(uncertain = Uncertainty.refine))),

    //  GV4(DP_pur (Q(uncertain = Uncertainty.refine))),
    sensorARE1(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N20YP(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorARE2(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorARE3(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorARE4(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorVVP1(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N04MP(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N08MT(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorVVP2(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N04MP(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N08MT(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorVVP3(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N04MP(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N08MT(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorVVP4(
      N02MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N04MP(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N08MT(
        Measure(
          signal(
            uncertain=Uncertainty.refine))),
      N01MD(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))),
    sensorGCT(
      N001MP(
        Measure(
          signal(
            uncertain=Uncertainty.refine)))))
    annotation (Placement(transformation(extent={{-72,-18},{44,48}})));
end BIL100_X_1;

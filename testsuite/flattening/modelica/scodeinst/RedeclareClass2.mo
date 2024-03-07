// name: RedeclareClass2
// keywords:
// status: correct
// cflags: -d=newInst
//

model LosslessPipe
  extends PartialTwoPortInterface;
end LosslessPipe;

partial model PartialTwoPortInterface
  parameter Real m_flow_nominal;
end PartialTwoPortInterface;

partial model PartialConnection2Pipe
  replaceable model Model_pipCon = PartialTwoPortInterface(final m_flow_nominal = mCon_flow_nominal);
  parameter Real mCon_flow_nominal;
  Model_pipCon pipCon;
end PartialConnection2Pipe;

model Connection2PipeLossless
  extends PartialConnection2Pipe(redeclare model Model_pipCon = LosslessPipe);
end Connection2PipeLossless;

partial model PartialDistribution2Pipe
  parameter Integer nCon = 1;
  parameter Real[nCon] mCon_flow_nominal = ones(nCon);
  replaceable PartialConnection2Pipe[nCon] con(final mCon_flow_nominal = mCon_flow_nominal);
end PartialDistribution2Pipe;

model RedeclareClass2
  extends PartialDistribution2Pipe(redeclare Connection2PipeLossless con[nCon]);
end RedeclareClass2;


// Result:
// class RedeclareClass2
//   final parameter Integer nCon = 1;
//   parameter Real mCon_flow_nominal[1] = 1.0;
//   final parameter Real con[1].mCon_flow_nominal = mCon_flow_nominal[1];
//   final parameter Real con[1].pipCon.m_flow_nominal = con[1].mCon_flow_nominal;
// end RedeclareClass2;
// endResult

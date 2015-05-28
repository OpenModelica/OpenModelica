#pragma once

// Dummy code for FMU that writes no output file
class BouncingBallWriteOutput {
 public:
  BouncingBallWriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory, boost::shared_ptr<ISimData> simData, boost::shared_ptr<ISimVars> simVars) {}
  virtual ~BouncingBallWriteOutput() {}
  
  virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT) {}
  virtual IHistory* getHistory() {return NULL;}
  
 protected:
  void initialize() {}
};
#pragma once

class Initialization
{
public:
      Initialization(boost::shared_ptr<ISystemInitialization> system_initialization,boost::shared_ptr<ISolver>  );
      ~Initialization(void);
      void initializeSystem(/*double start_time, double end_time*/);
private:

      boost::shared_ptr<ISystemInitialization> _system;
    boost::shared_ptr<ISolver>                  _solver;
};


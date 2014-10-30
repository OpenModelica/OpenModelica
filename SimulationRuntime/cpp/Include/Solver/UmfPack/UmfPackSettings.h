#pragma once

#include <Core/Solver/ILinSolverSettings.h>

class UmfPackSettings : public ILinSolverSettings
{
public:
  UmfPackSettings();
  virtual ~UmfPackSettings();

    virtual bool getUseSparseFormat();
    virtual void setUseSparseFormat(bool value);

    virtual void load(std::string);

private:
    bool useSparse;
};

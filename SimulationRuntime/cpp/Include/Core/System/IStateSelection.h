#pragma once

class IStateSelection
{
public:
   
  virtual ~IStateSelection()  {};
  virtual int getDimStateSets() const = 0;
  virtual int getDimCanditates() const = 0;
  virtual int getDimDummyStates() const = 0;
  virtual void getStates(double* z) = 0;
  virtual void setStates(const double* z) = 0;
  virtual void getStateCanditates(double* z) = 0;
  virtual void getAMatrix(multi_array<int,2> & A) =0 ;
  virtual void setAMatrix(multi_array<int,2>& A)=0;
};

#pragma once

#include <boost/multi_array.hpp>

class IStateSelection
{
public:
   
  virtual ~IStateSelection()  {};
  virtual int getDimStateSets() const = 0;
  virtual int getDimStates(unsigned int index) const = 0;
  virtual int getDimCanditates(unsigned int index) const = 0;
  virtual int getDimDummyStates(unsigned int index) const = 0;
  virtual void getStates(unsigned int index,double* z) = 0;
  virtual void setStates(unsigned int index,const double* z) = 0;
  virtual void getStateCanditates(unsigned int index,double* z) = 0;
  virtual bool getAMatrix(unsigned int index,boost::multi_array<int,2> & A) =0 ;
  virtual void setAMatrix(unsigned int index,boost::multi_array<int,2>& A)=0;
  virtual bool getAMatrix(unsigned int index,boost::multi_array<int,1> & A) =0 ;
  virtual void setAMatrix(unsigned int index,boost::multi_array<int,1>& A)=0;
};

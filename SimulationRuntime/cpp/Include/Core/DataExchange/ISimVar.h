#pragma once
/*
Interface for all sim variables
*/

class ISimVar
{
public:
  virtual ~ISimVar() {};
  virtual void setName(std::string name) = 0;
  virtual std::string getName() = 0;
};

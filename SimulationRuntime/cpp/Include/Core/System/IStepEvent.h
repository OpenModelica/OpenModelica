#pragma once
class IStepEvent
{
 public:

virtual ~IStepEvent(){};
virtual bool isStepEvent() = 0;
};


#include "stdafx.h"
#include "Functions.h"
#include <stdexcept>


double division (const double &a,const double &b,std::string text)
{
  if(b != 0) 
    return a/b ;
    else 
      throw std::invalid_argument(text);
}
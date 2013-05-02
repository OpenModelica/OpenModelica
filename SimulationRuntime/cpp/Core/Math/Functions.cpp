#include "stdafx.h"
#include <Math/Functions.h>
#include <stdexcept>


double division (const double &a,const double &b,std::string text)
{
  if(b != 0)
    return a/b ;
    else
    {
  std::string error_msg = "Division by zeror: ";
      throw std::invalid_argument(error_msg+text);
   }
}

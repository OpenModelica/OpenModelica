#include "utility.h"

int in_range_integer(modelica_integer i, 
		     modelica_integer start,
		     modelica_integer stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

int in_range_real(modelica_real i, 
		  modelica_real start,
		  modelica_real stop)
{
  if (start <= stop) if ((i >= start) && (i <= stop)) return 1;
  if (start > stop) if ((i >= stop) && (i <= start)) return 1;
  return 0;
}

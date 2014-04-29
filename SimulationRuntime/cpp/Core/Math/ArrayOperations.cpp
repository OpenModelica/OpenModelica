#include "stdafx.h"
#include <Math/ArrayOperations.h>
#include <sstream>
#include <stdio.h>
using namespace std;
//void boost::assertion_failed(char const * expr, char const * function,
//                             char const * file, long line)
//{
//  fprintf(stdout, "Range check failed for Array please check indices \n" );
//}
size_t getNextIndex(vector<size_t> idx,size_t k)
{
  if((idx.size()-1)<k)
    return idx.back();
  else
    return idx[k];
}

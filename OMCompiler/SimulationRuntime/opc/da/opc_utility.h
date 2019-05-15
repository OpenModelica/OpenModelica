#ifndef __UTILITY_H__
#define __UTILITY_H__

#include <malloc.h>
#include <string>
#include <vector>

void extractLeaves(int *apCount, const char **globalDataArray, int arraySize, const char *apPath, std::vector<std::string> &leaves);
void extractBranches(int *apCount, const char **globalDataArray, int arraySize, const char *apPath, std::vector<std::string> &branches);

#endif /*  __UTILITY_H__ */

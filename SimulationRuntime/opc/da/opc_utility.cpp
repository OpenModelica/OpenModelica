#include <string.h>

#include "opc_utility.h"

void extractLeaves(int *apCount, const char **globalDataArray, int arraySize, const char *apPath, std::vector<std::string> &leaves)
{
	const char *var_name; // Same as globalDataArray[i], but with the possible "der(" removed.
	for (int i = 0; i < arraySize; i++) {
		// Check whether the variable is a derivative
		bool is_derivative = false;
		if (strstr(globalDataArray[i], "der(") == globalDataArray[i]) {
			is_derivative = true;
			var_name = globalDataArray[i] + 4;
		}
		else {
			var_name = globalDataArray[i];
		}
		/* If apPath is found in the beginning of the variable name
			AND after that there is a '.' (unless apPath is an empty string)
			AND if after the path and the possible '.' there are no more '.' characters
			THEN a new leaf is added. That leaf will be labeld such that the path and
				 the possible '.' are removed from the full variable name.
		*/
		if (strstr(var_name, apPath) == var_name
				&& (!strcmp(apPath, "") || *(var_name + strlen(apPath)) == '.')
				&& strpbrk(var_name + strlen(apPath) + strcmp(apPath, ""), ".") == NULL) {
			(*apCount)++;
			leaves.resize(*apCount);
			// If the variable is a derivative, "der(" is added in the beginning of the name;
			// the ')' character is already in the end
			if (is_derivative) {
				leaves[*apCount - 1] = std::string("der(") + std::string(var_name + strlen(apPath) + strcmp(apPath, ""));
			}
			else {
				leaves[*apCount - 1] = var_name + strlen(apPath) + strcmp(apPath, "");
			}
		}
	}
}

void extractBranches(int *apCount, const char **globalDataArray, int arraySize, const char *apPath, std::vector<std::string> &branches)
{
	for (int i = 0; i < arraySize; i++) {
		/* If there is a "der(" in the beginning of the variable name, we don't need to
			process any further this particular variable name, because the possible branches are
			found when we come to the point where this function is called with the same variable
			but without the "der()"
		*/
		if (strstr(globalDataArray[i], "der(") == globalDataArray[i]) {
			continue;
		}
		/* If apPath is found in the beginning of the variable name
			AND after that there is a '.' (unless apPath is an empty string)
			THEN we have a branch candidate
		*/
		if (strstr(globalDataArray[i], apPath) == globalDataArray[i]
				&& (!strcmp(apPath, "") || *(globalDataArray[i] + strlen(apPath)) == '.')) {
			// Extract the apPath and the possible '.' from the variable name
			const char *candidate_with_cut_str = globalDataArray[i] + strlen(apPath) + strcmp(apPath, "");
			// Cut the previous into two pieces, the latter of which begins with the first '.' character
			char *cut_str = strpbrk(candidate_with_cut_str, ".");
			// If there was indeed at least one '.' character in the string, we have a branch
			if (cut_str != NULL) {
				// Create a string which has the rest cut out, i.e. the string is now a branch
				std::string candidate = std::string(candidate_with_cut_str, cut_str - candidate_with_cut_str);
				// Check whether an identically named branch has already been added in this path
				bool match_found = false;
				for (std::vector<std::string>::iterator it = branches.begin(); it != branches.end(); it++) {
					if (!candidate.compare(*it)) {
						match_found = true;
						break;
					}
				}
				if (match_found) {
					continue;
				}
				// If not, a new branch is added
				(*apCount)++;
				branches.resize(*apCount);
				branches[*apCount - 1] = candidate;
			}
		}
	}
}

#include "TaskGraphResultsCmp.h"

void* HpcOmSchedulerExtImpl__readScheduleFromGraphMl(const char *filename)
{
	void *res = mk_nil();
	std::string errorMsg = std::string("");
	Graph g;

	if (!GraphMLParser::CheckIfFileExists(filename))
	{
		std::cerr << "File " << filename << " not found" << std::endl;
		errorMsg = "File '";
		errorMsg += std::string(filename);
		errorMsg += "' does not exist";
		res = mk_cons(mk_scon(errorMsg.c_str()), mk_nil());
		return res;
	}

	GraphMLParser::ParseGraph(&g, filename,GraphComparator::CompareNodeNamesBool, &errorMsg);

	std::list<Node*> sortedNodeList = std::list<Node*>(g.nodes.begin(), g.nodes.end());
	sortedNodeList.sort(GraphComparator::CompareNodeTaskIdsBool);

    for (std::list<Node*>::iterator iter = sortedNodeList.begin(); iter != sortedNodeList.end(); iter++) {
    	//std::cerr << "Node " << (*iter)->taskId << " th " << atoi((*iter)->threadId.substr(3).c_str()) << std::endl;

    	if((*iter)->threadId.size() < 3)
    		continue;
    	res = mk_cons(mk_icon(atoi((*iter)->threadId.substr(3).c_str())), res);
    }
	return res;
}

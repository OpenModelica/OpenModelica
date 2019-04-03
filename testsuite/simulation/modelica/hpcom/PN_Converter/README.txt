This small jar-file converts a graphml-taskgraph into a petri-net. The output is a xml-file, similar to the standardized pnml-format. You can open it with the open source tool PIPE.

Usage:
java -jar pn_converter.jar 'path to graphml-file' 'output xml-file'

Output:
'output xml-file' : The created state-transtition PN, with backward arcs to create a closed net. You can make a state space analyzation to see if the net is deadlock free.

'output xml-file'_tmp.xml : The created state-transtition PN, without backward arcs. This is just a good presentation net, but can't be used to check deadlocks.
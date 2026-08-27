#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ConnectionGraph.c"
#endif
#include "omc_simulation_settings.h"
#include "ConnectionGraph.h"
#define _OMC_LIT0_data "- ConnectionGraph.filterFromSet: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,33,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data " connect("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,9,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,2,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "cgraph"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Prints out connection graph information."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,40,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(62)),_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "removed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,7,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "allowed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,7,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "- ConnectionGraph.removeBrokenConnects: CS: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,44,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "- ConnectionGraph.removeBrokenConnects: keep: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,46,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "- ConnectionGraph.removeBrokenConnects: delete: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,48,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "- ConnectionGraph.removeBrokenConnects: allow = remove - keep: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,63,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "- ConnectionGraph.removeBrokenConnects: allow - delete: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,56,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "cgraphGraphVizShow"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,18,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Displays the connection graph with the GraphViz lefty tool."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,59,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(12)),_OMC_LIT16,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,0,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "_removed_connections.txt"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,24,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Tyring to start GraphViz *lefty* to visualize the graph. You need to have lefty in your PATH variable"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,101,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "Make sure you quit GraphViz *lefty* via Right Click->quit to be sure the process will be exited."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,96,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "If you quit the GraphViz *lefty* window via X, please kill the process in task manager to continue."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,99,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,1,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "load('"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,6,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "/share/omc/scripts/openmodelica.lefty');"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,40,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "openmodelica.init();openmodelica.createviewandgraph('"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,53,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "','file',null,null);txtview('off');"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,35,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "Running command: lefty -e "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,26,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data " > "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,3,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "lefty -e "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,9,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "GraphViz *lefty* exited with status:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,36,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "GraphViz OpenModelica assistant returned the following broken connects: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,72,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "cgraphGraphVizFile"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,18,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "Generates a graphviz file of the connection graph."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,50,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(11)),_OMC_LIT35,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,1,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data ".gv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,3,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,4) {&IOStream_IOStreamType_LIST__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "// Generated by OpenModelica. \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,31,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "// Overconstrained connection graph for model: \n//    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,54,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "// \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,4,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "// Summary: \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,13,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "//   Roots:              "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,25,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "//   Potential Roots:    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,25,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "//   Unique Roots:       "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,25,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "//   Branches:           "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,25,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "//   Connections:        "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,25,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "//   Final Roots:        "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,25,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "//   Broken Connections: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,25,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "\\l"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,2,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,1,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,1,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,2,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,2,1) {_OMC_LIT56,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "graph \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,7,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "\"\n{\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,5,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "overlap=false;\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,15,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "layout=dot;\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,13,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "node ["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,6,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "fillcolor = \"lightsteelblue1\", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,31,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "shape = box, "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,13,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "style = \"bold, filled\", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,24,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "rank = \"max\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,12,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "]\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,3,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "edge ["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,6,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "color = \"black\", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,17,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "style = bold"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,12,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "graph [fontsize=20, fontname = \"Courier Bold\" label= \"\\n\\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,58,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "\", size=\"6,6\"];\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,16,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "// Definite Roots (Connections.root)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,36,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "// Potential Roots (Connections.potentialRoot)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,46,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "// Branches (Connections.branch)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,32,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "// Connections (connect)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,24,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "\n}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,3,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,2,1) {_OMC_LIT77,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "\n\n\n// graph generation took: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,29,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data " seconds\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,9,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "GraphViz with connection graph for model: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,42,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data " was writen to file: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,21,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data " [fillcolor = orangered, rank = \"min\" label = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,46,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "\\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,2,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "\", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,3,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "shape=ploygon, sides=7, distortion=\"0.265084\", orientation=26, skew=\"0.403659\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,78,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "shape=box"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,9,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "];\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,4,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data " [fillcolor = red, rank = \"source\", label = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,44,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "shape=polygon, sides=8, distortion=\"0.265084\", orientation=26, skew=\"0.403659\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,78,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "[[broken connect]]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,18,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "connect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,7,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "red"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,3,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "green"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,5,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "\"bold, dashed\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,14,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "solid"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,5,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,4,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,5,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "labelfontsize = 20.0, "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,22,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "\" -- \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,6,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data "\" [dir = \"none\", style = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,25,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
#define _OMC_LIT102_data ", decorate = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT102,13,_OMC_LIT102_data);
#define _OMC_LIT102 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data ", color = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,10,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
#define _OMC_LIT104_data "fontcolor = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT104,12,_OMC_LIT104_data);
#define _OMC_LIT104 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT104)
#define _OMC_LIT105_data ", label = \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT105,11,_OMC_LIT105_data);
#define _OMC_LIT105 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data "\"];\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,5,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data " [color = blue, dir = \"none\", fontcolor=blue, label = \"branch\"];\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,66,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
#define _OMC_LIT108_data "- ConnectionGraph.merge()\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT108,26,_OMC_LIT108_data);
#define _OMC_LIT108 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data "Connections:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,13,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "Branches:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,10,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,4,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data " -- "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,4,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,1,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
#define _OMC_LIT114_data "- ConnectionGraph.evalConnectionsOperatorsHelper: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT114,50,_OMC_LIT114_data);
#define _OMC_LIT114 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data " = false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,8,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT116,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT116 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data "- ConnectionGraph.evalConnectionsOperatorsHelper: Found Branche Partner "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,72,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data " = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,3,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data "- ConnectionGraph.evalConnectionsOperatorsHelper: Connections.uniqueRootsIndicies("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,82,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,1,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT122,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT122 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "rooted"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,6,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
#define _OMC_LIT124_data "Connections"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT124,11,_OMC_LIT124_data);
#define _OMC_LIT124 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT124)
#define _OMC_LIT125_data "isRoot"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT125,6,_OMC_LIT125_data);
#define _OMC_LIT125 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT125)
#define _OMC_LIT126_data "uniqueRootIndices"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT126,17,_OMC_LIT126_data);
#define _OMC_LIT126 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT126)
#define _OMC_LIT127_data "The following output from GraphViz OpenModelica assistant cannot be parsed:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT127,75,_OMC_LIT127_data);
#define _OMC_LIT127 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT127)
#define _OMC_LIT128_data "\nExpected format from GrapViz: cref1|cref2#cref3|cref4#. Ignoring malformed input."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT128,82,_OMC_LIT128_data);
#define _OMC_LIT128 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "Ordered Potential Roots: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,25,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "__DUMMY_ROOT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,12,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,1,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "|"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,1,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "User selected the following connect edges for breaking:\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,57,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,2,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "\nAfer ordering:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,16,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "- ConnectionGraph.connectComponents: should remove equations generated from: connect("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,85,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data ") and add {0, ..., 0} = equalityConstraint(cr1, cr2) instead.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,62,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
#define _OMC_LIT138_data "- ConnectionGraph.addConnection("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT138,32,_OMC_LIT138_data);
#define _OMC_LIT138 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data ")\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,2,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
#define _OMC_LIT140_data "- ConnectionGraph.addBranch("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT140,28,_OMC_LIT140_data);
#define _OMC_LIT140 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT140)
#define _OMC_LIT141_data "- ConnectionGraph.addUniqueRoots("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT141,33,_OMC_LIT141_data);
#define _OMC_LIT141 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT141)
#define _OMC_LIT142_data "- ConnectionGraph.addPotentialRoot("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT142,35,_OMC_LIT142_data);
#define _OMC_LIT142 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT142)
#define _OMC_LIT143_data "- ConnectionGraph.addDefiniteRoot("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT143,34,_OMC_LIT143_data);
#define _OMC_LIT143 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT143)
#define _OMC_LIT144_data "Summary: \n	Nr Roots:           "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT144,31,_OMC_LIT144_data);
#define _OMC_LIT144 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT144)
#define _OMC_LIT145_data "Nr Potential Roots: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT145,20,_OMC_LIT145_data);
#define _OMC_LIT145 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data "Nr Unique Roots:    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,20,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data "Nr Branches:        "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,20,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
#define _OMC_LIT148_data "Nr Connections:     "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT148,20,_OMC_LIT148_data);
#define _OMC_LIT148 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT148)
#define _OMC_LIT149_data "Roots: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT149,7,_OMC_LIT149_data);
#define _OMC_LIT149 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT149)
#define _OMC_LIT150_data "Broken connections: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT150,20,_OMC_LIT150_data);
#define _OMC_LIT150 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT150)
#define _OMC_LIT151_data "broken"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT151,6,_OMC_LIT151_data);
#define _OMC_LIT151 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "Allowed connections: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,21,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
#define _OMC_LIT153_data "- ConnectionGraph.handleOverconstrainedConnections failed for model: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT153,69,_OMC_LIT153_data);
#define _OMC_LIT153 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT153)
#include "util/modelica.h"
#include "ConnectionGraph_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_removeFromConnects(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inToRemove);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_removeFromConnects,2,0) {(void*) boxptr_ConnectionGraph_removeFromConnects,0}};
#define boxvar_ConnectionGraph_removeFromConnects MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_removeFromConnects)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_filterFromSet(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inFilter, modelica_metatype _inAcc, modelica_string _msg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_filterFromSet,2,0) {(void*) boxptr_ConnectionGraph_filterFromSet,0}};
#define boxvar_ConnectionGraph_filterFromSet MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_filterFromSet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_splitSetByAllowed(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inConnected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_splitSetByAllowed,2,0) {(void*) boxptr_ConnectionGraph_splitSetByAllowed,0}};
#define boxvar_ConnectionGraph_splitSetByAllowed MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_splitSetByAllowed)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_showGraphViz(threadData_t *threadData, modelica_string _fileNameGraphViz, modelica_string _modelNameQualified);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_showGraphViz,2,0) {(void*) boxptr_ConnectionGraph_showGraphViz,0}};
#define boxvar_ConnectionGraph_showGraphViz MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_showGraphViz)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_generateGraphViz(threadData_t *threadData, modelica_string _modelNameQualified, modelica_metatype _definiteRoots, modelica_metatype _potentialRoots, modelica_metatype _uniqueRoots, modelica_metatype _branches, modelica_metatype _connections, modelica_metatype _finalRoots, modelica_metatype _broken);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_generateGraphViz,2,0) {(void*) boxptr_ConnectionGraph_generateGraphViz,0}};
#define boxvar_ConnectionGraph_generateGraphViz MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_generateGraphViz)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizPotentialRoot(threadData_t *threadData, modelica_metatype _inPotentialRoot, modelica_metatype _inFinalRoots);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizPotentialRoot,2,0) {(void*) boxptr_ConnectionGraph_graphVizPotentialRoot,0}};
#define boxvar_ConnectionGraph_graphVizPotentialRoot MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizPotentialRoot)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizDefiniteRoot(threadData_t *threadData, modelica_metatype _inDefiniteRoot, modelica_metatype _inFinalRoots);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizDefiniteRoot,2,0) {(void*) boxptr_ConnectionGraph_graphVizDefiniteRoot,0}};
#define boxvar_ConnectionGraph_graphVizDefiniteRoot MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizDefiniteRoot)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizDaeEdge(threadData_t *threadData, modelica_metatype _inDaeEdge, modelica_metatype _inBrokenDaeEdges);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizDaeEdge,2,0) {(void*) boxptr_ConnectionGraph_graphVizDaeEdge,0}};
#define boxvar_ConnectionGraph_graphVizDaeEdge MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizDaeEdge)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizEdge(threadData_t *threadData, modelica_metatype _inEdge);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizEdge,2,0) {(void*) boxptr_ConnectionGraph_graphVizEdge,0}};
#define boxvar_ConnectionGraph_graphVizEdge MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_graphVizEdge)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getConnections(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getConnections,2,0) {(void*) boxptr_ConnectionGraph_getConnections,0}};
#define boxvar_ConnectionGraph_getConnections MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getConnections)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getBranches(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getBranches,2,0) {(void*) boxptr_ConnectionGraph_getBranches,0}};
#define boxvar_ConnectionGraph_getBranches MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getBranches)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getPotentialRoots(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getPotentialRoots,2,0) {(void*) boxptr_ConnectionGraph_getPotentialRoots,0}};
#define boxvar_ConnectionGraph_getPotentialRoots MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getPotentialRoots)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getUniqueRoots(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getUniqueRoots,2,0) {(void*) boxptr_ConnectionGraph_getUniqueRoots,0}};
#define boxvar_ConnectionGraph_getUniqueRoots MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getUniqueRoots)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getDefiniteRoots(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getDefiniteRoots,2,0) {(void*) boxptr_ConnectionGraph_getDefiniteRoots,0}};
#define boxvar_ConnectionGraph_getDefiniteRoots MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getDefiniteRoots)
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printConnectionGraph(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printConnectionGraph,2,0) {(void*) boxptr_ConnectionGraph_printConnectionGraph,0}};
#define boxvar_ConnectionGraph_printConnectionGraph MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printConnectionGraph)
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printDaeEdges(threadData_t *threadData, modelica_metatype _inEdges);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printDaeEdges,2,0) {(void*) boxptr_ConnectionGraph_printDaeEdges,0}};
#define boxvar_ConnectionGraph_printDaeEdges MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printDaeEdges)
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printEdges(threadData_t *threadData, modelica_metatype _inEdges);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printEdges,2,0) {(void*) boxptr_ConnectionGraph_printEdges,0}};
#define boxvar_ConnectionGraph_printEdges MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printEdges)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printConnectionStr(threadData_t *threadData, modelica_metatype _connectTuple, modelica_string _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printConnectionStr,2,0) {(void*) boxptr_ConnectionGraph_printConnectionStr,0}};
#define boxvar_ConnectionGraph_printConnectionStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printConnectionStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getEdge1(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _cref1, modelica_metatype _cref2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getEdge1,2,0) {(void*) boxptr_ConnectionGraph_getEdge1,0}};
#define boxvar_ConnectionGraph_getEdge1 MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getEdge1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getEdge(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _edges);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getEdge,2,0) {(void*) boxptr_ConnectionGraph_getEdge,0}};
#define boxvar_ConnectionGraph_getEdge MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getEdge)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_getRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _rooted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_getRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _rooted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_getRooted,2,0) {(void*) boxptr_ConnectionGraph_getRooted,0}};
#define boxvar_ConnectionGraph_getRooted MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_getRooted)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_evalConnectionsOperatorsHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRoots, modelica_metatype *out_outRoots);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_evalConnectionsOperatorsHelper,2,0) {(void*) boxptr_ConnectionGraph_evalConnectionsOperatorsHelper,0}};
#define boxvar_ConnectionGraph_evalConnectionsOperatorsHelper MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_evalConnectionsOperatorsHelper)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_evalConnectionsOperators(threadData_t *threadData, modelica_metatype _inRoots, modelica_metatype _graph, modelica_metatype _inDae);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_evalConnectionsOperators,2,0) {(void*) boxptr_ConnectionGraph_evalConnectionsOperators,0}};
#define boxvar_ConnectionGraph_evalConnectionsOperators MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_evalConnectionsOperators)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnectionRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _itable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnectionRooted,2,0) {(void*) boxptr_ConnectionGraph_addConnectionRooted,0}};
#define boxvar_ConnectionGraph_addConnectionRooted MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnectionRooted)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnectionsRooted(threadData_t *threadData, modelica_metatype _connection, modelica_metatype _itable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnectionsRooted,2,0) {(void*) boxptr_ConnectionGraph_addConnectionsRooted,0}};
#define boxvar_ConnectionGraph_addConnectionsRooted MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnectionsRooted)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addBranches(threadData_t *threadData, modelica_metatype _edge, modelica_metatype _itable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addBranches,2,0) {(void*) boxptr_ConnectionGraph_addBranches,0}};
#define boxvar_ConnectionGraph_addBranches MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addBranches)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_setRootDistance(threadData_t *threadData, modelica_metatype _finalRoots, modelica_metatype _table, modelica_integer _distance, modelica_metatype _nextLevel, modelica_metatype _irooted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_setRootDistance(threadData_t *threadData, modelica_metatype _finalRoots, modelica_metatype _table, modelica_metatype _distance, modelica_metatype _nextLevel, modelica_metatype _irooted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_setRootDistance,2,0) {(void*) boxptr_ConnectionGraph_setRootDistance,0}};
#define boxvar_ConnectionGraph_setRootDistance MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_setRootDistance)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printPotentialRootTuple(threadData_t *threadData, modelica_metatype _potentialRoot);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printPotentialRootTuple,2,0) {(void*) boxptr_ConnectionGraph_printPotentialRootTuple,0}};
#define boxvar_ConnectionGraph_printPotentialRootTuple MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printPotentialRootTuple)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_makeTuple(threadData_t *threadData, modelica_metatype _inLstLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_makeTuple,2,0) {(void*) boxptr_ConnectionGraph_makeTuple,0}};
#define boxvar_ConnectionGraph_makeTuple MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_makeTuple)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printTupleStr(threadData_t *threadData, modelica_metatype _inTpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_printTupleStr,2,0) {(void*) boxptr_ConnectionGraph_printTupleStr,0}};
#define boxvar_ConnectionGraph_printTupleStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_printTupleStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_orderConnectsGuidedByUser(threadData_t *threadData, modelica_metatype _inConnections, modelica_metatype _inUserSelectedBreaking);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_orderConnectsGuidedByUser,2,0) {(void*) boxptr_ConnectionGraph_orderConnectsGuidedByUser,0}};
#define boxvar_ConnectionGraph_orderConnectsGuidedByUser MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_orderConnectsGuidedByUser)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_findResultGraph(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _modelNameQualified, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_findResultGraph,2,0) {(void*) boxptr_ConnectionGraph_findResultGraph,0}};
#define boxvar_ConnectionGraph_findResultGraph MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_findResultGraph)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnections(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inConnections, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnections,2,0) {(void*) boxptr_ConnectionGraph_addConnections,0}};
#define boxvar_ConnectionGraph_addConnections MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addConnections)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addPotentialRootsToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inPotentialRoots, modelica_metatype _inRoots, modelica_metatype _inFirstRoot, modelica_metatype *out_outRoots);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addPotentialRootsToTable,2,0) {(void*) boxptr_ConnectionGraph_addPotentialRootsToTable,0}};
#define boxvar_ConnectionGraph_addPotentialRootsToTable MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addPotentialRootsToTable)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_ord(threadData_t *threadData, modelica_metatype _inEl1, modelica_metatype _inEl2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_ord(threadData_t *threadData, modelica_metatype _inEl1, modelica_metatype _inEl2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_ord,2,0) {(void*) boxptr_ConnectionGraph_ord,0}};
#define boxvar_ConnectionGraph_ord MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_ord)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addBranchesToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inBranches);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addBranchesToTable,2,0) {(void*) boxptr_ConnectionGraph_addBranchesToTable,0}};
#define boxvar_ConnectionGraph_addBranchesToTable MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addBranchesToTable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_resultGraphWithRoots(threadData_t *threadData, modelica_metatype _roots);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_resultGraphWithRoots,2,0) {(void*) boxptr_ConnectionGraph_resultGraphWithRoots,0}};
#define boxvar_ConnectionGraph_resultGraphWithRoots MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_resultGraphWithRoots)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addRootsToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inRoots, modelica_metatype _inFirstRoot);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_addRootsToTable,2,0) {(void*) boxptr_ConnectionGraph_addRootsToTable,0}};
#define boxvar_ConnectionGraph_addRootsToTable MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_addRootsToTable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectCanonicalComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2, modelica_boolean *out_outReallyConnected);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_connectCanonicalComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2, modelica_metatype *out_outReallyConnected);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectCanonicalComponents,2,0) {(void*) boxptr_ConnectionGraph_connectCanonicalComponents,0}};
#define boxvar_ConnectionGraph_connectCanonicalComponents MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectCanonicalComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inDaeEdge, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectComponents,2,0) {(void*) boxptr_ConnectionGraph_connectComponents,0}};
#define boxvar_ConnectionGraph_connectComponents MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectBranchComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectBranchComponents,2,0) {(void*) boxptr_ConnectionGraph_connectBranchComponents,0}};
#define boxvar_ConnectionGraph_connectBranchComponents MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_connectBranchComponents)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_areInSameComponent(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_areInSameComponent(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_areInSameComponent,2,0) {(void*) boxptr_ConnectionGraph_areInSameComponent,0}};
#define boxvar_ConnectionGraph_areInSameComponent MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_areInSameComponent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_canonical(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectionGraph_canonical,2,0) {(void*) boxptr_ConnectionGraph_canonical,0}};
#define boxvar_ConnectionGraph_canonical MMC_REFSTRUCTLIT(boxvar_lit_ConnectionGraph_canonical)
DLLExport
modelica_metatype omc_ConnectionGraph_addBrokenEqualityConstraintEquations(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _inBroken)
{
modelica_metatype _outDAE = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inBroken;
{
modelica_metatype _equalityConstraintElements = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inDAE;
goto tmp2_done;
}
case 1: {
_equalityConstraintElements = omc_List_flatten(threadData, omc_List_map(threadData, _inBroken, boxvar_Util_tuple33));
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _equalityConstraintElements);
tmpMeta[0] = omc_DAEUtil_joinDaes(threadData, tmpMeta[1], _inDAE);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outDAE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_removeFromConnects(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inToRemove)
{
modelica_metatype _outConnects = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inConnects;
tmp3_2 = _inToRemove;
{
modelica_metatype _c = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cset = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _inConnects;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_c = tmpMeta[1];
_rest = tmpMeta[2];
_cset = tmp3_1;
tmpMeta[1] = omc_ConnectUtil_removeReferenceFromConnects(threadData, _cset, _c, &tmp5);
_cset = tmpMeta[1];
if (1 != tmp5) goto goto_1;
_inConnects = _cset;
_inToRemove = _rest;
goto _tailrecursive;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outConnects = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConnects;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_filterFromSet(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inFilter, modelica_metatype _inAcc, modelica_string _msg)
{
modelica_metatype _filteredCrefs = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inFilter;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 2;
tmpMeta[0] = omc_List_unique(threadData, _inAcc);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
modelica_boolean tmp6;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_c1 = tmpMeta[3];
_c2 = tmpMeta[4];
_rest = tmpMeta[2];
tmp5 = omc_ConnectUtil_isReferenceInConnects(threadData, _inConnects, _c1);
if (1 != tmp5) goto goto_1;
tmp6 = omc_ConnectUtil_isReferenceInConnects(threadData, _inConnects, _c2);
if (1 != tmp6) goto goto_1;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT0,_msg);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT1);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ComponentReference_printComponentRefStr(threadData, _c1));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT2);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_ComponentReference_printComponentRefStr(threadData, _c2));
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[6]);
}
tmpMeta[2] = mmc_mk_cons(_c2, _inAcc);
tmpMeta[1] = mmc_mk_cons(_c1, tmpMeta[2]);
tmpMeta[0] = omc_ConnectionGraph_filterFromSet(threadData, _inConnects, _rest, tmpMeta[1], _msg);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
tmpMeta[0] = omc_ConnectionGraph_filterFromSet(threadData, _inConnects, _rest, _inAcc, _msg);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_filteredCrefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _filteredCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_splitSetByAllowed(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inConnected)
{
modelica_metatype _outConnects = NULL;
modelica_metatype _cset = NULL;
modelica_metatype _csets = NULL;
modelica_metatype _e = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _ce = NULL;
modelica_metatype _ce1 = NULL;
modelica_metatype _ce2 = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_csets = tmpMeta[0];
{
modelica_metatype _e;
for (tmpMeta[0] = _inConnected; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cset = tmpMeta[1];
tmpMeta[1] = _e;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr1 = tmpMeta[2];
_cr2 = tmpMeta[3];
{
modelica_metatype _ce;
for (tmpMeta[1] = _inConnects; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_ce = MMC_CAR(tmpMeta[1]);
if(omc_ComponentReference_crefPrefixOf(threadData, _cr1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ce), 2)))))
{
tmpMeta[2] = mmc_mk_cons(_ce, _cset);
_cset = tmpMeta[2];
}
if(omc_ComponentReference_crefPrefixOf(threadData, _cr2, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ce), 2)))))
{
tmpMeta[2] = mmc_mk_cons(_ce, _cset);
_cset = tmpMeta[2];
}
}
}
if((!listEmpty(_cset)))
{
tmpMeta[1] = mmc_mk_cons(_cset, _csets);
_csets = tmpMeta[1];
}
}
}
_outConnects = _csets;
_return: OMC_LABEL_UNUSED
return _outConnects;
}
DLLExport
modelica_metatype omc_ConnectionGraph_removeBrokenConnects(threadData_t *threadData, modelica_metatype _inConnects, modelica_metatype _inConnected, modelica_metatype _inBroken)
{
modelica_metatype _outConnects = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBroken;
{
modelica_metatype _toRemove = NULL;
modelica_metatype _toKeep = NULL;
modelica_metatype _intersect = NULL;
modelica_metatype _cset = NULL;
modelica_metatype _csets = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_inConnects, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_toRemove = omc_ConnectionGraph_filterFromSet(threadData, _inConnects, _inBroken, tmpMeta[1], _OMC_LIT8);
if(listEmpty(_toRemove))
{
tmpMeta[1] = mmc_mk_cons(_inConnects, MMC_REFSTRUCTLIT(mmc_nil));
_csets = tmpMeta[1];
}
else
{
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_toKeep = omc_ConnectionGraph_filterFromSet(threadData, _inConnects, _inConnected, tmpMeta[1], _OMC_LIT9);
_intersect = omc_List_intersectionOnTrue(threadData, _toRemove, _toKeep, boxvar_ComponentReference_crefEqualNoStringCompare);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT10,stringDelimitList(omc_List_map(threadData, _inConnects, boxvar_ConnectUtil_printElementStr), _OMC_LIT11));
omc_Debug_traceln(threadData, tmpMeta[1]);
tmpMeta[1] = stringAppend(_OMC_LIT12,stringDelimitList(omc_List_map(threadData, _toKeep, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[1]);
tmpMeta[1] = stringAppend(_OMC_LIT13,stringDelimitList(omc_List_map(threadData, _toRemove, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[1]);
tmpMeta[1] = stringAppend(_OMC_LIT14,stringDelimitList(omc_List_map(threadData, _intersect, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[1]);
}
_toRemove = omc_List_setDifference(threadData, _toRemove, _intersect);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT15,stringDelimitList(omc_List_map(threadData, _toRemove, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[1]);
}
_cset = omc_ConnectionGraph_removeFromConnects(threadData, _inConnects, _toRemove);
_csets = omc_ConnectionGraph_splitSetByAllowed(threadData, _cset, _inConnected);
}
tmpMeta[0] = _csets;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outConnects = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConnects;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_showGraphViz(threadData_t *threadData, modelica_string _fileNameGraphViz, modelica_string _modelNameQualified)
{
modelica_string _brokenConnectsViaGraphViz = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _leftyCMD = NULL;
modelica_string _fileNameTraceRemovedConnections = NULL;
modelica_string _omhome = NULL;
modelica_string _brokenConnects = NULL;
modelica_integer _leftyExitStatus;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (0 != tmp6) goto goto_2;
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 1: {
tmpMeta[0] = stringAppend(_modelNameQualified,_OMC_LIT21);
_fileNameTraceRemovedConnections = tmpMeta[0];
omc_Debug_traceln(threadData, _OMC_LIT22);
omc_Debug_traceln(threadData, _OMC_LIT23);
omc_Debug_traceln(threadData, _OMC_LIT24);
_omhome = omc_Settings_getInstallationDirectoryPath(threadData);
_omhome = omc_System_stringReplace(threadData, _omhome, _OMC_LIT25, _OMC_LIT20);
tmpMeta[0] = stringAppend(_OMC_LIT26,_omhome);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT27);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT28);
tmpMeta[3] = stringAppend(tmpMeta[2],_fileNameGraphViz);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT29);
_leftyCMD = tmpMeta[4];
tmpMeta[0] = stringAppend(_OMC_LIT30,_leftyCMD);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT31);
tmpMeta[2] = stringAppend(tmpMeta[1],_fileNameTraceRemovedConnections);
omc_Debug_traceln(threadData, tmpMeta[2]);
tmpMeta[0] = stringAppend(_OMC_LIT32,_leftyCMD);
_leftyExitStatus = omc_System_systemCall(threadData, tmpMeta[0], _fileNameTraceRemovedConnections);
tmpMeta[0] = stringAppend(_OMC_LIT33,intString(_leftyExitStatus));
omc_Debug_traceln(threadData, tmpMeta[0]);
_brokenConnects = omc_System_readFile(threadData, _fileNameTraceRemovedConnections);
tmpMeta[0] = stringAppend(_OMC_LIT34,_brokenConnects);
omc_Debug_traceln(threadData, tmpMeta[0]);
tmp1 = _brokenConnects;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_brokenConnectsViaGraphViz = tmp1;
_return: OMC_LABEL_UNUSED
return _brokenConnectsViaGraphViz;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_generateGraphViz(threadData_t *threadData, modelica_string _modelNameQualified, modelica_metatype _definiteRoots, modelica_metatype _potentialRoots, modelica_metatype _uniqueRoots, modelica_metatype _branches, modelica_metatype _connections, modelica_metatype _finalRoots, modelica_metatype _broken)
{
modelica_string _brokenConnectsViaGraphViz = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _fileName = NULL;
modelica_string _i = NULL;
modelica_string _nrDR = NULL;
modelica_string _nrPR = NULL;
modelica_string _nrUR = NULL;
modelica_string _nrBR = NULL;
modelica_string _nrCO = NULL;
modelica_string _nrFR = NULL;
modelica_string _nrBC = NULL;
modelica_string _timeStr = NULL;
modelica_string _infoNodeStr = NULL;
modelica_real _tStart;
modelica_real _tEnd;
modelica_real _t;
modelica_metatype _graphVizStream = NULL;
modelica_metatype _infoNode = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmp6 = (omc_Flags_isSet(threadData, _OMC_LIT38) || omc_Flags_isSet(threadData, _OMC_LIT19));
if (0 != tmp6) goto goto_2;
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 1: {
_tStart = mmc_clock();
_i = _OMC_LIT39;
tmpMeta[0] = stringAppend(_modelNameQualified,_OMC_LIT40);
_fileName = tmpMeta[0];
_graphVizStream = omc_IOStream_create(threadData, _fileName, _OMC_LIT41);
_nrDR = intString(listLength(_definiteRoots));
_nrPR = intString(listLength(_potentialRoots));
_nrUR = intString(listLength(_uniqueRoots));
_nrBR = intString(listLength(_branches));
_nrCO = intString(listLength(_connections));
_nrFR = intString(listLength(_finalRoots));
_nrBC = intString(listLength(_broken));
tmpMeta[0] = mmc_mk_cons(_OMC_LIT42, mmc_mk_cons(_OMC_LIT43, mmc_mk_cons(_modelNameQualified, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT44, mmc_mk_cons(_OMC_LIT45, mmc_mk_cons(_OMC_LIT46, mmc_mk_cons(_nrDR, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT47, mmc_mk_cons(_nrPR, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT48, mmc_mk_cons(_nrUR, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT49, mmc_mk_cons(_nrBR, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT50, mmc_mk_cons(_nrCO, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT51, mmc_mk_cons(_nrFR, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_OMC_LIT52, mmc_mk_cons(_nrBC, mmc_mk_cons(_OMC_LIT11, MMC_REFSTRUCTLIT(mmc_nil))))))))))))))))))))))))))));
_infoNode = tmpMeta[0];
_infoNodeStr = stringAppendList(_infoNode);
_infoNodeStr = omc_System_stringReplace(threadData, _infoNodeStr, _OMC_LIT11, _OMC_LIT53);
_infoNodeStr = omc_System_stringReplace(threadData, _infoNodeStr, _OMC_LIT39, _OMC_LIT54);
_infoNodeStr = omc_System_stringReplace(threadData, _infoNodeStr, _OMC_LIT55, _OMC_LIT20);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, _infoNode);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, _OMC_LIT57);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT58, mmc_mk_cons(_modelNameQualified, mmc_mk_cons(_OMC_LIT59, MMC_REFSTRUCTLIT(mmc_nil))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT60, MMC_REFSTRUCTLIT(mmc_nil)));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT61, MMC_REFSTRUCTLIT(mmc_nil)));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT62, mmc_mk_cons(_OMC_LIT63, mmc_mk_cons(_OMC_LIT64, mmc_mk_cons(_OMC_LIT65, mmc_mk_cons(_OMC_LIT66, mmc_mk_cons(_OMC_LIT67, MMC_REFSTRUCTLIT(mmc_nil))))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT68, mmc_mk_cons(_OMC_LIT69, mmc_mk_cons(_OMC_LIT70, mmc_mk_cons(_OMC_LIT67, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT71, mmc_mk_cons(_infoNodeStr, mmc_mk_cons(_OMC_LIT72, mmc_mk_cons(_i, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT73, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, omc_List_map1(threadData, _definiteRoots, boxvar_ConnectionGraph_graphVizDefiniteRoot, _finalRoots));
tmpMeta[0] = mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT74, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, omc_List_map1(threadData, _potentialRoots, boxvar_ConnectionGraph_graphVizPotentialRoot, _finalRoots));
tmpMeta[0] = mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT75, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, omc_List_map(threadData, _branches, boxvar_ConnectionGraph_graphVizEdge));
tmpMeta[0] = mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, mmc_mk_cons(_OMC_LIT76, mmc_mk_cons(_OMC_LIT11, mmc_mk_cons(_i, MMC_REFSTRUCTLIT(mmc_nil))))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, omc_List_map1(threadData, _connections, boxvar_ConnectionGraph_graphVizDaeEdge, _broken));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, _OMC_LIT78);
_tEnd = mmc_clock();
_t = _tEnd - _tStart;
_timeStr = realString(_t);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT79, mmc_mk_cons(_timeStr, mmc_mk_cons(_OMC_LIT80, MMC_REFSTRUCTLIT(mmc_nil))));
_graphVizStream = omc_IOStream_appendList(threadData, _graphVizStream, tmpMeta[0]);
omc_System_writeFile(threadData, _fileName, omc_IOStream_string(threadData, _graphVizStream));
tmpMeta[0] = stringAppend(_OMC_LIT81,_modelNameQualified);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT82);
tmpMeta[2] = stringAppend(tmpMeta[1],_fileName);
omc_Debug_traceln(threadData, tmpMeta[2]);
tmp1 = omc_ConnectionGraph_showGraphViz(threadData, _fileName, _modelNameQualified);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_brokenConnectsViaGraphViz = tmp1;
_return: OMC_LABEL_UNUSED
return _brokenConnectsViaGraphViz;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizPotentialRoot(threadData_t *threadData, modelica_metatype _inPotentialRoot, modelica_metatype _inFinalRoots)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPotentialRoot;
{
modelica_metatype _c = NULL;
modelica_real _priority;
modelica_boolean _isSelectedRoot;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_real tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_real(tmpMeta[1]);
_c = tmpMeta[0];
_priority = tmp6;
_isSelectedRoot = listMember(_c, _inFinalRoots);
tmpMeta[0] = stringAppend(_OMC_LIT25,omc_ComponentReference_printComponentRefStr(threadData, _c));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT25);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT83);
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT25);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ComponentReference_printComponentRefStr(threadData, _c));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT84);
tmpMeta[6] = stringAppend(tmpMeta[5],realString(_priority));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT85);
tmpMeta[8] = stringAppend(tmpMeta[7],(_isSelectedRoot?_OMC_LIT86:_OMC_LIT87));
tmpMeta[9] = stringAppend(tmpMeta[8],_OMC_LIT88);
tmp1 = tmpMeta[9];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizDefiniteRoot(threadData_t *threadData, modelica_metatype _inDefiniteRoot, modelica_metatype _inFinalRoots)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDefiniteRoot;
{
modelica_metatype _c = NULL;
modelica_boolean _isSelectedRoot;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_c = tmp4_1;
_isSelectedRoot = listMember(_c, _inFinalRoots);
tmpMeta[0] = stringAppend(_OMC_LIT25,omc_ComponentReference_printComponentRefStr(threadData, _c));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT25);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT89);
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT25);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ComponentReference_printComponentRefStr(threadData, _c));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT85);
tmpMeta[6] = stringAppend(tmpMeta[5],(_isSelectedRoot?_OMC_LIT90:_OMC_LIT87));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT88);
tmp1 = tmpMeta[7];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizDaeEdge(threadData_t *threadData, modelica_metatype _inDaeEdge, modelica_metatype _inBrokenDaeEdges)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDaeEdge;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _sc1 = NULL;
modelica_string _sc2 = NULL;
modelica_string _label = NULL;
modelica_string _labelFontSize = NULL;
modelica_string _decorate = NULL;
modelica_string _color = NULL;
modelica_string _style = NULL;
modelica_string _fontColor = NULL;
modelica_boolean _isBroken;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c1 = tmpMeta[0];
_c2 = tmpMeta[1];
_isBroken = listMember(_inDaeEdge, _inBrokenDaeEdges);
_label = (_isBroken?_OMC_LIT91:_OMC_LIT92);
_color = (_isBroken?_OMC_LIT93:_OMC_LIT94);
_style = (_isBroken?_OMC_LIT95:_OMC_LIT96);
_decorate = (_isBroken?_OMC_LIT97:_OMC_LIT98);
_fontColor = (_isBroken?_OMC_LIT93:_OMC_LIT94);
_labelFontSize = (_isBroken?_OMC_LIT99:_OMC_LIT20);
_sc1 = omc_ComponentReference_printComponentRefStr(threadData, _c1);
_sc2 = omc_ComponentReference_printComponentRefStr(threadData, _c2);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT25, mmc_mk_cons(_sc1, mmc_mk_cons(_OMC_LIT100, mmc_mk_cons(_sc2, mmc_mk_cons(_OMC_LIT101, mmc_mk_cons(_style, mmc_mk_cons(_OMC_LIT102, mmc_mk_cons(_decorate, mmc_mk_cons(_OMC_LIT103, mmc_mk_cons(_color, mmc_mk_cons(_OMC_LIT2, mmc_mk_cons(_labelFontSize, mmc_mk_cons(_OMC_LIT104, mmc_mk_cons(_fontColor, mmc_mk_cons(_OMC_LIT105, mmc_mk_cons(_label, mmc_mk_cons(_OMC_LIT106, MMC_REFSTRUCTLIT(mmc_nil))))))))))))))))));
tmp1 = stringAppendList(tmpMeta[0]);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_graphVizEdge(threadData_t *threadData, modelica_metatype _inEdge)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEdge;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c1 = tmpMeta[0];
_c2 = tmpMeta[1];
tmpMeta[0] = stringAppend(_OMC_LIT25,omc_ComponentReference_printComponentRefStr(threadData, _c1));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT100);
tmpMeta[2] = stringAppend(tmpMeta[1],omc_ComponentReference_printComponentRefStr(threadData, _c2));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT25);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT107);
tmp1 = tmpMeta[4];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
DLLExport
modelica_metatype omc_ConnectionGraph_merge(threadData_t *threadData, modelica_metatype _inGraph1, modelica_metatype _inGraph2)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inGraph1;
tmp3_2 = _inGraph2;
{
modelica_boolean _updateGraph;
modelica_boolean _updateGraph1;
modelica_boolean _updateGraph2;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _definiteRoots1 = NULL;
modelica_metatype _definiteRoots2 = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _uniqueRoots1 = NULL;
modelica_metatype _uniqueRoots2 = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _potentialRoots1 = NULL;
modelica_metatype _potentialRoots2 = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _branches1 = NULL;
modelica_metatype _branches2 = NULL;
modelica_metatype _connections = NULL;
modelica_metatype _connections1 = NULL;
modelica_metatype _connections2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 6));
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[0] = _inGraph1;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[0] = _inGraph2;
goto tmp2_done;
}
case 2: {
equality(_inGraph1, _inGraph2);
tmpMeta[0] = _inGraph1;
goto tmp2_done;
}
case 3: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp6 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 6));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
_updateGraph1 = tmp5;
_definiteRoots1 = tmpMeta[2];
_potentialRoots1 = tmpMeta[3];
_uniqueRoots1 = tmpMeta[4];
_branches1 = tmpMeta[5];
_connections1 = tmpMeta[6];
_updateGraph2 = tmp6;
_definiteRoots2 = tmpMeta[8];
_potentialRoots2 = tmpMeta[9];
_uniqueRoots2 = tmpMeta[10];
_branches2 = tmpMeta[11];
_connections2 = tmpMeta[12];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
omc_Debug_trace(threadData, _OMC_LIT108);
}
_updateGraph = (_updateGraph1 || _updateGraph2);
_definiteRoots = omc_List_union(threadData, _definiteRoots1, _definiteRoots2);
_potentialRoots = omc_List_union(threadData, _potentialRoots1, _potentialRoots2);
_uniqueRoots = omc_List_union(threadData, _uniqueRoots1, _uniqueRoots2);
_branches = omc_List_union(threadData, _branches1, _branches2);
_connections = omc_List_union(threadData, _connections1, _connections2);
tmpMeta[1] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, _potentialRoots, _uniqueRoots, _branches, _connections);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getConnections(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _result = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_result = tmpMeta[1];
tmpMeta[0] = _result;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getBranches(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _result = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_result = tmpMeta[1];
tmpMeta[0] = _result;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getPotentialRoots(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _result = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_result = tmpMeta[1];
tmpMeta[0] = _result;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getUniqueRoots(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _result = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_result = tmpMeta[1];
tmpMeta[0] = _result;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getDefiniteRoots(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _result = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_result = tmpMeta[1];
tmpMeta[0] = _result;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printConnectionGraph(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inGraph;
{
modelica_metatype _connections = NULL;
modelica_metatype _branches = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_branches = tmpMeta[0];
_connections = tmpMeta[1];
fputs(MMC_STRINGDATA(_OMC_LIT109),stdout);
omc_ConnectionGraph_printDaeEdges(threadData, _connections);
fputs(MMC_STRINGDATA(_OMC_LIT110),stdout);
omc_ConnectionGraph_printEdges(threadData, _branches);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printDaeEdges(threadData_t *threadData, modelica_metatype _inEdges)
{
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEdges;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _tail = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_c1 = tmpMeta[2];
_c2 = tmpMeta[3];
_tail = tmpMeta[1];
fputs(MMC_STRINGDATA(_OMC_LIT111),stdout);
fputs(MMC_STRINGDATA(omc_ComponentReference_printComponentRefStr(threadData, _c1)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT112),stdout);
fputs(MMC_STRINGDATA(omc_ComponentReference_printComponentRefStr(threadData, _c2)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT11),stdout);
_inEdges = _tail;
goto _tailrecursive;
;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_ConnectionGraph_printEdges(threadData_t *threadData, modelica_metatype _inEdges)
{
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEdges;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _tail = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_c1 = tmpMeta[2];
_c2 = tmpMeta[3];
_tail = tmpMeta[1];
fputs(MMC_STRINGDATA(_OMC_LIT111),stdout);
fputs(MMC_STRINGDATA(omc_ComponentReference_printComponentRefStr(threadData, _c1)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT112),stdout);
fputs(MMC_STRINGDATA(omc_ComponentReference_printComponentRefStr(threadData, _c2)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT11),stdout);
_inEdges = _tail;
goto _tailrecursive;
;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printConnectionStr(threadData_t *threadData, modelica_metatype _connectTuple, modelica_string _ty)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _connectTuple;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c1 = tmpMeta[0];
_c2 = tmpMeta[1];
tmpMeta[0] = stringAppend(_ty,_OMC_LIT113);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_ComponentReference_printComponentRefStr(threadData, _c1));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ComponentReference_printComponentRefStr(threadData, _c2));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
tmp1 = tmpMeta[4];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getEdge1(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _cref1, modelica_metatype _cref2)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmp5 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _cr, _cref1);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _cref2;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _cr, _cref2);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _cref1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_ocr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ocr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_getEdge(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _edges)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _edges;
{
modelica_metatype _rest = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cref1 = tmpMeta[3];
_cref2 = tmpMeta[4];
tmpMeta[0] = omc_ConnectionGraph_getEdge1(threadData, _cr, _cref1, _cref2);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
tmpMeta[0] = omc_ConnectionGraph_getEdge(threadData, _cr, _rest);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_ocr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ocr;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_getRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _rooted)
{
modelica_boolean _result;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_integer _i1;
modelica_integer _i2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_i1 = mmc_unbox_integer(omc_BaseHashTable_get(threadData, _cref1, _rooted));
_i2 = mmc_unbox_integer(omc_BaseHashTable_get(threadData, _cref2, _rooted));
tmp1 = (_i1 < _i2);
goto tmp3_done;
}
case 1: {
tmp1 = 1;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_result = tmp1;
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_getRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _rooted)
{
modelica_boolean _result;
modelica_metatype out_result;
_result = omc_ConnectionGraph_getRooted(threadData, _cref1, _cref2, _rooted);
out_result = mmc_mk_icon(_result);
return out_result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_evalConnectionsOperatorsHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inRoots, modelica_metatype *out_outRoots)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outRoots = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inRoots;
{
modelica_metatype _graph = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _uroots = NULL;
modelica_metatype _nodes = NULL;
modelica_metatype _message = NULL;
modelica_metatype _rooted = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _cref1 = NULL;
modelica_boolean _result;
modelica_metatype _branches = NULL;
modelica_metatype _roots = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (6 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT123), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],16,3) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (!listEmpty(tmpMeta[7])) goto tmp3_end;
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_rooted = tmpMeta[8];
_roots = tmpMeta[9];
_graph = tmpMeta[10];
tmp4 += 1;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT115);
omc_Debug_traceln(threadData, tmpMeta[3]);
}
tmpMeta[2] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = _OMC_LIT116;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (6 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT123), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta[7];
_rooted = tmpMeta[8];
_roots = tmpMeta[9];
_graph = tmpMeta[10];
_branches = omc_ConnectionGraph_getBranches(threadData, _graph);
_cref1 = omc_ConnectionGraph_getEdge(threadData, _cref, _branches);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT117,omc_ComponentReference_printComponentRefStr(threadData, _cref));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT2);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ComponentReference_printComponentRefStr(threadData, _cref1));
omc_Debug_traceln(threadData, tmpMeta[4]);
}
_result = omc_ConnectionGraph_getRooted(threadData, _cref, _cref1, _rooted);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT118);
tmpMeta[4] = stringAppend(tmpMeta[3],(_result?_OMC_LIT97:_OMC_LIT98));
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_result));
tmpMeta[3] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 2: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_rooted = tmpMeta[2];
_roots = tmpMeta[3];
_graph = tmpMeta[4];
_exp = tmp4_1;
tmpMeta[2] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (6 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],16,3) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
if (!listEmpty(tmpMeta[9])) goto tmp3_end;
if (!listEmpty(tmpMeta[8])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_rooted = tmpMeta[10];
_roots = tmpMeta[11];
_graph = tmpMeta[12];
tmp4 += 4;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT115);
omc_Debug_traceln(threadData, tmpMeta[3]);
}
tmpMeta[2] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = _OMC_LIT116;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],13,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (11 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (6 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],16,3) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 4));
if (!listEmpty(tmpMeta[11])) goto tmp3_end;
if (!listEmpty(tmpMeta[10])) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_rooted = tmpMeta[12];
_roots = tmpMeta[13];
_graph = tmpMeta[14];
tmp4 += 3;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT115);
omc_Debug_traceln(threadData, tmpMeta[3]);
}
tmpMeta[2] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = _OMC_LIT116;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (6 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],6,2) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (!listEmpty(tmpMeta[8])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta[9];
_rooted = tmpMeta[10];
_roots = tmpMeta[11];
_graph = tmpMeta[12];
tmp4 += 2;
_result = omc_List_isMemberOnTrue(threadData, _cref, _roots, boxvar_ComponentReference_crefEqualNoStringCompare);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT118);
tmpMeta[4] = stringAppend(tmpMeta[3],(_result?_OMC_LIT97:_OMC_LIT98));
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_result));
tmpMeta[3] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],13,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (11 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (6 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],6,2) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
if (!listEmpty(tmpMeta[10])) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cref = tmpMeta[11];
_rooted = tmpMeta[12];
_roots = tmpMeta[13];
_graph = tmpMeta[14];
tmp4 += 1;
_result = omc_List_isMemberOnTrue(threadData, _cref, _roots, boxvar_ComponentReference_crefEqualNoStringCompare);
_result = (!_result);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT114,omc_ExpressionDump_printExpStr(threadData, _inExp));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT118);
tmpMeta[4] = stringAppend(tmpMeta[3],(_result?_OMC_LIT97:_OMC_LIT98));
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_result));
tmpMeta[3] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (17 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT126), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],16,3) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
if (listEmpty(tmpMeta[8])) goto tmp3_end;
tmpMeta[10] = MMC_CAR(tmpMeta[8]);
tmpMeta[11] = MMC_CDR(tmpMeta[8]);
if (listEmpty(tmpMeta[11])) goto tmp3_end;
tmpMeta[12] = MMC_CAR(tmpMeta[11]);
tmpMeta[13] = MMC_CDR(tmpMeta[11]);
if (!listEmpty(tmpMeta[13])) goto tmp3_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_uroots = tmpMeta[7];
_lst = tmpMeta[9];
_nodes = tmpMeta[10];
_message = tmpMeta[12];
_rooted = tmpMeta[14];
_roots = tmpMeta[15];
_graph = tmpMeta[16];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[2] = stringAppend(_OMC_LIT119,omc_ExpressionDump_printExpStr(threadData, _uroots));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT120);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ExpressionDump_printExpStr(threadData, _nodes));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT120);
tmpMeta[6] = stringAppend(tmpMeta[5],omc_ExpressionDump_printExpStr(threadData, _message));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[7]);
}
_lst = omc_List_fill(threadData, _OMC_LIT121, listLength(_lst));
tmpMeta[2] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _OMC_LIT122, mmc_mk_boolean(0), _lst);
tmpMeta[3] = mmc_mk_box3(0, _rooted, _roots, _graph);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 8: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inRoots;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 9) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta[0+0];
_outRoots = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRoots) { *out_outRoots = _outRoots; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_evalConnectionsOperators(threadData_t *threadData, modelica_metatype _inRoots, modelica_metatype _graph, modelica_metatype _inDae)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inDae;
{
modelica_metatype _rooted = NULL;
modelica_metatype _table = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
_table = omc_HashTable3_emptyHashTable(threadData);
_branches = omc_ConnectionGraph_getBranches(threadData, _graph);
_table = omc_List_fold(threadData, _branches, boxvar_ConnectionGraph_addBranches, _table);
_connections = omc_ConnectionGraph_getConnections(threadData, _graph);
_table = omc_List_fold(threadData, _connections, boxvar_ConnectionGraph_addConnectionsRooted, _table);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_rooted = omc_ConnectionGraph_setRootDistance(threadData, _inRoots, _table, ((modelica_integer) 0), tmpMeta[1], omc_HashTable_emptyHashTable(threadData));
tmpMeta[1] = mmc_mk_box3(0, _rooted, _inRoots, _graph);
tmpMeta[0] = omc_DAEUtil_traverseDAEElementList(threadData, _inDae, boxvar_ConnectionGraph_evalConnectionsOperatorsHelper, tmpMeta[1], NULL);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnectionRooted(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _itable)
{
modelica_metatype _otable = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _crefs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
{
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp6_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
tmpMeta[1] = omc_BaseHashTable_get(threadData, _cref1, _itable);
goto tmp6_done;
}
case 1: {
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[2];
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
tmp6_done:
(void)tmp7;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp6_done2;
goto_5:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp7 < 2) {
goto tmp6_top;
}
goto goto_1;
tmp6_done2:;
}
}
_crefs = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_cref2, _crefs);
tmpMeta[2] = mmc_mk_box2(0, _cref1, tmpMeta[1]);
tmpMeta[0] = omc_BaseHashTable_add(threadData, tmpMeta[2], _itable);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_otable = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _otable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnectionsRooted(threadData_t *threadData, modelica_metatype _connection, modelica_metatype _itable)
{
modelica_metatype _otable = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _connection;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cref1 = tmpMeta[1];
_cref2 = tmpMeta[2];
_otable = omc_ConnectionGraph_addConnectionRooted(threadData, _cref1, _cref2, _itable);
_otable = omc_ConnectionGraph_addConnectionRooted(threadData, _cref2, _cref1, _otable);
_return: OMC_LABEL_UNUSED
return _otable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addBranches(threadData_t *threadData, modelica_metatype _edge, modelica_metatype _itable)
{
modelica_metatype _otable = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _edge;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cref1 = tmpMeta[1];
_cref2 = tmpMeta[2];
_otable = omc_ConnectionGraph_addConnectionRooted(threadData, _cref1, _cref2, _itable);
_otable = omc_ConnectionGraph_addConnectionRooted(threadData, _cref2, _cref1, _otable);
_return: OMC_LABEL_UNUSED
return _otable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_setRootDistance(threadData_t *threadData, modelica_metatype _finalRoots, modelica_metatype _table, modelica_integer _distance, modelica_metatype _nextLevel, modelica_metatype _irooted)
{
modelica_metatype _orooted = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _finalRoots;
tmp3_2 = _nextLevel;
{
modelica_metatype _rooted = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _next = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _irooted;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 3;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ConnectionGraph_setRootDistance(threadData, _nextLevel, _table, ((modelica_integer) 1) + _distance, tmpMeta[1], _irooted);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_cr = tmpMeta[1];
_rest = tmpMeta[2];
tmp5 = omc_BaseHashTable_hasKey(threadData, _cr, _irooted);
if (0 != tmp5) goto goto_1;
tmpMeta[1] = mmc_mk_box2(0, _cr, mmc_mk_integer(_distance));
_rooted = omc_BaseHashTable_add(threadData, tmpMeta[1], _irooted);
_next = omc_BaseHashTable_get(threadData, _cr, _table);
_next = listAppend(_nextLevel, _next);
tmpMeta[0] = omc_ConnectionGraph_setRootDistance(threadData, _rest, _table, _distance, _next, _rooted);
goto tmp2_done;
}
case 3: {
modelica_boolean tmp6;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_cr = tmpMeta[1];
_rest = tmpMeta[2];
tmp6 = omc_BaseHashTable_hasKey(threadData, _cr, _irooted);
if (0 != tmp6) goto goto_1;
tmpMeta[1] = mmc_mk_box2(0, _cr, mmc_mk_integer(_distance));
_rooted = omc_BaseHashTable_add(threadData, tmpMeta[1], _irooted);
tmpMeta[0] = omc_ConnectionGraph_setRootDistance(threadData, _rest, _table, _distance, _nextLevel, _rooted);
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
tmpMeta[0] = omc_ConnectionGraph_setRootDistance(threadData, _rest, _table, _distance, _nextLevel, _irooted);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 5) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_orooted = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _orooted;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_setRootDistance(threadData_t *threadData, modelica_metatype _finalRoots, modelica_metatype _table, modelica_metatype _distance, modelica_metatype _nextLevel, modelica_metatype _irooted)
{
modelica_integer tmp1;
modelica_metatype _orooted = NULL;
tmp1 = mmc_unbox_integer(_distance);
_orooted = omc_ConnectionGraph_setRootDistance(threadData, _finalRoots, _table, tmp1, _nextLevel, _irooted);
return _orooted;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printPotentialRootTuple(threadData_t *threadData, modelica_metatype _potentialRoot)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _potentialRoot;
{
modelica_metatype _cr = NULL;
modelica_real _priority;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_real tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_real(tmpMeta[1]);
_cr = tmpMeta[0];
_priority = tmp6;
tmpMeta[0] = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, _cr),_OMC_LIT113);
tmpMeta[1] = stringAppend(tmpMeta[0],realString(_priority));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT3);
tmp1 = tmpMeta[2];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_makeTuple(threadData_t *threadData, modelica_metatype _inLstLst)
{
modelica_metatype _outLst = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inLstLst;
{
modelica_string _c1 = NULL;
modelica_string _c2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _bad = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 4;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[1]);
tmpMeta[4] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_c1 = tmpMeta[3];
_c2 = tmpMeta[5];
_rest = tmpMeta[2];
tmp3 += 2;
_lst = omc_ConnectionGraph_makeTuple(threadData, _rest);
tmpMeta[2] = mmc_mk_box2(0, _c1, _c2);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _lst);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[1]);
tmpMeta[4] = MMC_CDR(tmpMeta[1]);
if (0 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT20), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
_rest = tmpMeta[2];
tmp3 += 1;
tmpMeta[0] = omc_ConnectionGraph_makeTuple(threadData, _rest);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
_rest = tmpMeta[2];
tmpMeta[0] = omc_ConnectionGraph_makeTuple(threadData, _rest);
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_bad = tmpMeta[1];
_rest = tmpMeta[2];
tmpMeta[1] = stringAppend(_OMC_LIT127,stringDelimitList(_bad, _OMC_LIT2));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT128);
omc_Debug_traceln(threadData, tmpMeta[2]);
tmpMeta[0] = omc_ConnectionGraph_makeTuple(threadData, _rest);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 5) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outLst;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectionGraph_printTupleStr(threadData_t *threadData, modelica_metatype _inTpl)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTpl;
{
modelica_string _c1 = NULL;
modelica_string _c2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c1 = tmpMeta[0];
_c2 = tmpMeta[1];
tmpMeta[0] = stringAppend(_c1,_OMC_LIT112);
tmpMeta[1] = stringAppend(tmpMeta[0],_c2);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_orderConnectsGuidedByUser(threadData_t *threadData, modelica_metatype _inConnections, modelica_metatype _inUserSelectedBreaking)
{
modelica_metatype _outOrderedConnections = NULL;
modelica_metatype _front = NULL;
modelica_metatype _back = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _sc1 = NULL;
modelica_string _sc2 = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_front = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_back = tmpMeta[1];
{
modelica_metatype _e;
for (tmpMeta[2] = _inConnections; !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_e = MMC_CAR(tmpMeta[2]);
tmpMeta[3] = _e;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_c1 = tmpMeta[4];
_c2 = tmpMeta[5];
_sc1 = omc_ComponentReference_printComponentRefStr(threadData, _c1);
_sc2 = omc_ComponentReference_printComponentRefStr(threadData, _c2);
tmpMeta[3] = mmc_mk_box2(0, _sc1, _sc2);
tmpMeta[4] = mmc_mk_box2(0, _sc2, _sc1);
if((listMember(tmpMeta[3], _inUserSelectedBreaking) || listMember(tmpMeta[4], _inUserSelectedBreaking)))
{
tmpMeta[5] = mmc_mk_cons(_e, _back);
_back = tmpMeta[5];
}
else
{
tmpMeta[5] = mmc_mk_cons(_e, _front);
_front = tmpMeta[5];
}
}
}
_outOrderedConnections = omc_List_append__reverse(threadData, _front, _back);
_return: OMC_LABEL_UNUSED
return _outOrderedConnections;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_findResultGraph(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _modelNameQualified, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections)
{
modelica_metatype _outRoots = NULL;
modelica_metatype _outConnectedConnections = NULL;
modelica_metatype _outBrokenConnections = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _definiteRoots = NULL;
modelica_metatype _finalRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _orderedPotentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
modelica_metatype _broken = NULL;
modelica_metatype _connected = NULL;
modelica_metatype _table = NULL;
modelica_metatype _dummyRoot = NULL;
modelica_string _brokenConnectsViaGraphViz = NULL;
modelica_metatype _userBrokenLst = NULL;
modelica_metatype _userBrokenLstLst = NULL;
modelica_metatype _userBrokenTplLst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (!listEmpty(tmpMeta[7])) goto tmp3_end;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = tmpMeta[4];
tmpMeta[0+2] = tmpMeta[5];
goto tmp3_done;
}
case 1: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_definiteRoots = tmpMeta[3];
_potentialRoots = tmpMeta[4];
_uniqueRoots = tmpMeta[5];
_branches = tmpMeta[6];
_connections = tmpMeta[7];
_connections = listReverse(_connections);
_table = omc_ConnectionGraph_resultGraphWithRoots(threadData, _definiteRoots);
_table = omc_ConnectionGraph_addBranchesToTable(threadData, _table, _branches);
_orderedPotentialRoots = omc_List_sort(threadData, _potentialRoots, boxvar_ConnectionGraph_ord);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[3] = stringAppend(_OMC_LIT129,stringDelimitList(omc_List_map(threadData, _orderedPotentialRoots, boxvar_ConnectionGraph_printPotentialRootTuple), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[3]);
}
_table = omc_ConnectionGraph_addConnections(threadData, _table, _connections ,&_connected ,&_broken);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_dummyRoot = omc_ComponentReference_makeCrefIdent(threadData, _OMC_LIT130, _OMC_LIT122, tmpMeta[3]);
_table = omc_ConnectionGraph_addPotentialRootsToTable(threadData, _table, _orderedPotentialRoots, _definiteRoots, _dummyRoot ,&_finalRoots);
_brokenConnectsViaGraphViz = omc_ConnectionGraph_generateGraphViz(threadData, _modelNameQualified, _definiteRoots, _potentialRoots, _uniqueRoots, _branches, _connections, _finalRoots, _broken);
if((stringEqual(_brokenConnectsViaGraphViz, _OMC_LIT20)))
{
}
else
{
_userBrokenLst = omc_Util_stringSplitAtChar(threadData, _brokenConnectsViaGraphViz, _OMC_LIT131);
_userBrokenLstLst = omc_List_map1(threadData, _userBrokenLst, boxvar_Util_stringSplitAtChar, _OMC_LIT132);
_userBrokenTplLst = omc_ConnectionGraph_makeTuple(threadData, _userBrokenLstLst);
tmpMeta[3] = stringAppend(_OMC_LIT133,stringDelimitList(omc_List_map(threadData, _userBrokenTplLst, boxvar_ConnectionGraph_printTupleStr), _OMC_LIT134));
omc_Debug_traceln(threadData, tmpMeta[3]);
omc_ConnectionGraph_printDaeEdges(threadData, _connections);
_connections = omc_ConnectionGraph_orderConnectsGuidedByUser(threadData, _connections, _userBrokenTplLst);
_connections = listReverse(_connections);
fputs(MMC_STRINGDATA(_OMC_LIT135),stdout);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(0), _definiteRoots, _potentialRoots, _uniqueRoots, _branches, _connections);
_finalRoots = omc_ConnectionGraph_findResultGraph(threadData, tmpMeta[3], _modelNameQualified ,&_connected ,&_broken);
}
tmpMeta[0+0] = _finalRoots;
tmpMeta[0+1] = _connected;
tmpMeta[0+2] = _broken;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outRoots = tmpMeta[0+0];
_outConnectedConnections = tmpMeta[0+1];
_outBrokenConnections = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outConnectedConnections) { *out_outConnectedConnections = _outConnectedConnections; }
if (out_outBrokenConnections) { *out_outBrokenConnections = _outBrokenConnections; }
return _outRoots;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addConnections(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inConnections, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections)
{
modelica_metatype _outTable = NULL;
modelica_metatype _outConnectedConnections = NULL;
modelica_metatype _outBrokenConnections = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inTable;
tmp4_2 = _inConnections;
{
modelica_metatype _table = NULL;
modelica_metatype _tail = NULL;
modelica_metatype _broken1 = NULL;
modelica_metatype _broken2 = NULL;
modelica_metatype _broken = NULL;
modelica_metatype _connected1 = NULL;
modelica_metatype _connected2 = NULL;
modelica_metatype _connected = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_table = tmp4_1;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _table;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_2);
tmpMeta[4] = MMC_CDR(tmp4_2);
_e = tmpMeta[3];
_tail = tmpMeta[4];
_table = tmp4_1;
_table = omc_ConnectionGraph_connectComponents(threadData, _table, _e ,&_connected1 ,&_broken1);
_table = omc_ConnectionGraph_addConnections(threadData, _table, _tail ,&_connected2 ,&_broken2);
_connected = listAppend(_connected1, _connected2);
_broken = listAppend(_broken1, _broken2);
tmpMeta[0+0] = _table;
tmpMeta[0+1] = _connected;
tmpMeta[0+2] = _broken;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outTable = tmpMeta[0+0];
_outConnectedConnections = tmpMeta[0+1];
_outBrokenConnections = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outConnectedConnections) { *out_outConnectedConnections = _outConnectedConnections; }
if (out_outBrokenConnections) { *out_outBrokenConnections = _outBrokenConnections; }
return _outTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addPotentialRootsToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inPotentialRoots, modelica_metatype _inRoots, modelica_metatype _inFirstRoot, modelica_metatype *out_outRoots)
{
modelica_metatype _outTable = NULL;
modelica_metatype _outRoots = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inTable;
tmp4_2 = _inPotentialRoots;
tmp4_3 = _inRoots;
tmp4_4 = _inFirstRoot;
{
modelica_metatype _table = NULL;
modelica_metatype _potentialRoot = NULL;
modelica_metatype _firstRoot = NULL;
modelica_metatype _canon1 = NULL;
modelica_metatype _canon2 = NULL;
modelica_metatype _roots = NULL;
modelica_metatype _tail = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_table = tmp4_1;
_roots = tmp4_3;
tmp4 += 2;
tmpMeta[0+0] = _table;
tmpMeta[0+1] = _roots;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_potentialRoot = tmpMeta[4];
_tail = tmpMeta[3];
_table = tmp4_1;
_roots = tmp4_3;
_firstRoot = tmp4_4;
_canon1 = omc_ConnectionGraph_canonical(threadData, _table, _potentialRoot);
_canon2 = omc_ConnectionGraph_canonical(threadData, _table, _firstRoot);
tmpMeta[2] = omc_ConnectionGraph_connectCanonicalComponents(threadData, _table, _canon1, _canon2, &tmp6);
_table = tmpMeta[2];
if (1 != tmp6) goto goto_2;
tmpMeta[2] = mmc_mk_cons(_potentialRoot, _roots);
tmpMeta[0+0] = omc_ConnectionGraph_addPotentialRootsToTable(threadData, _table, _tail, tmpMeta[2], _firstRoot, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
_tail = tmpMeta[3];
_table = tmp4_1;
_roots = tmp4_3;
_firstRoot = tmp4_4;
tmpMeta[0+0] = omc_ConnectionGraph_addPotentialRootsToTable(threadData, _table, _tail, _roots, _firstRoot, &tmpMeta[0+1]);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outTable = tmpMeta[0+0];
_outRoots = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRoots) { *out_outRoots = _outRoots; }
return _outTable;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_ord(threadData_t *threadData, modelica_metatype _inEl1, modelica_metatype _inEl2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEl1;
tmp4_2 = _inEl2;
{
modelica_real _r1;
modelica_real _r2;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_real tmp6;
modelica_real tmp7;
modelica_boolean tmp8;
modelica_integer tmp9;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_real(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_real(tmpMeta[3]);
_c1 = tmpMeta[0];
_r1 = tmp6;
_c2 = tmpMeta[2];
_r2 = tmp7;
tmp8 = (_r1 == _r2);
if (1 != tmp8) goto goto_2;
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _c1);
_s2 = omc_ComponentReference_printComponentRefStr(threadData, _c2);
tmp9 = stringCompare(_s1, _s2);
if (1 != tmp9) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_real tmp10;
modelica_real tmp11;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_real(tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_real(tmpMeta[1]);
_r1 = tmp10;
_r2 = tmp11;
tmp1 = (_r1 > _r2);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_ord(threadData_t *threadData, modelica_metatype _inEl1, modelica_metatype _inEl2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ConnectionGraph_ord(threadData, _inEl1, _inEl2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addBranchesToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inBranches)
{
modelica_metatype _outTable = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inTable;
tmp3_2 = _inBranches;
{
modelica_metatype _table = NULL;
modelica_metatype _table1 = NULL;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _tail = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_ref1 = tmpMeta[3];
_ref2 = tmpMeta[4];
_tail = tmpMeta[2];
_table = tmp3_1;
_table1 = omc_ConnectionGraph_connectBranchComponents(threadData, _table, _ref1, _ref2);
_inTable = _table1;
_inBranches = _tail;
goto _tailrecursive;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_table = tmp3_1;
tmpMeta[0] = _table;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outTable = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_resultGraphWithRoots(threadData_t *threadData, modelica_metatype _roots)
{
modelica_metatype _outTable = NULL;
modelica_metatype _table0 = NULL;
modelica_metatype _dummyRoot = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_dummyRoot = omc_ComponentReference_makeCrefIdent(threadData, _OMC_LIT130, _OMC_LIT122, tmpMeta[0]);
_table0 = omc_HashTableCG_emptyHashTable(threadData);
_outTable = omc_ConnectionGraph_addRootsToTable(threadData, _table0, _roots, _dummyRoot);
_return: OMC_LABEL_UNUSED
return _outTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_addRootsToTable(threadData_t *threadData, modelica_metatype _inTable, modelica_metatype _inRoots, modelica_metatype _inFirstRoot)
{
modelica_metatype _outTable = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inTable;
tmp3_2 = _inRoots;
tmp3_3 = _inFirstRoot;
{
modelica_metatype _table = NULL;
modelica_metatype _root = NULL;
modelica_metatype _firstRoot = NULL;
modelica_metatype _tail = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_root = tmpMeta[1];
_tail = tmpMeta[2];
_table = tmp3_1;
_firstRoot = tmp3_3;
tmpMeta[1] = mmc_mk_box2(0, _root, _firstRoot);
_table = omc_BaseHashTable_add(threadData, tmpMeta[1], _table);
_inTable = _table;
_inRoots = _tail;
_inFirstRoot = _firstRoot;
goto _tailrecursive;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_table = tmp3_1;
tmpMeta[0] = _table;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outTable = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectCanonicalComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2, modelica_boolean *out_outReallyConnected)
{
modelica_metatype _outPartition = NULL;
modelica_boolean _outReallyConnected;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inPartition;
tmp4_2 = _inRef1;
tmp4_3 = _inRef2;
{
modelica_metatype _partition = NULL;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
_partition = tmp4_1;
_ref1 = tmp4_2;
_ref2 = tmp4_3;
tmp6 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _ref1, _ref2);
if (1 != tmp6) goto goto_2;
tmpMeta[0+0] = _partition;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
_partition = tmp4_1;
_ref1 = tmp4_2;
_ref2 = tmp4_3;
tmpMeta[2] = mmc_mk_box2(0, _ref1, _ref2);
_partition = omc_BaseHashTable_add(threadData, tmpMeta[2], _partition);
tmpMeta[0+0] = _partition;
tmp1_c1 = 1;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outPartition = tmpMeta[0+0];
_outReallyConnected = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outReallyConnected) { *out_outReallyConnected = _outReallyConnected; }
return _outPartition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_connectCanonicalComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2, modelica_metatype *out_outReallyConnected)
{
modelica_boolean _outReallyConnected;
modelica_metatype _outPartition = NULL;
_outPartition = omc_ConnectionGraph_connectCanonicalComponents(threadData, _inPartition, _inRef1, _inRef2, &_outReallyConnected);
if (out_outReallyConnected) { *out_outReallyConnected = mmc_mk_icon(_outReallyConnected); }
return _outPartition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inDaeEdge, modelica_metatype *out_outConnectedConnections, modelica_metatype *out_outBrokenConnections)
{
modelica_metatype _outPartition = NULL;
modelica_metatype _outConnectedConnections = NULL;
modelica_metatype _outBrokenConnections = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inPartition;
tmp4_2 = _inDaeEdge;
{
modelica_metatype _partition = NULL;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _canon1 = NULL;
modelica_metatype _canon2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_partition = tmp4_1;
_ref1 = tmpMeta[3];
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_ConnectionGraph_canonical(threadData, _partition, _ref1);
tmp6 = 1;
goto goto_7;
goto_7:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp6) {goto goto_2;}
tmpMeta[3] = mmc_mk_cons(_inDaeEdge, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _partition;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_partition = tmp4_1;
_ref2 = tmpMeta[3];
tmp8 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_ConnectionGraph_canonical(threadData, _partition, _ref2);
tmp8 = 1;
goto goto_9;
goto_9:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp8) {goto goto_2;}
tmpMeta[3] = mmc_mk_cons(_inDaeEdge, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _partition;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
case 2: {
modelica_boolean tmp10;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_partition = tmp4_1;
_ref1 = tmpMeta[3];
_ref2 = tmpMeta[4];
_canon1 = omc_ConnectionGraph_canonical(threadData, _partition, _ref1);
_canon2 = omc_ConnectionGraph_canonical(threadData, _partition, _ref2);
tmpMeta[3] = omc_ConnectionGraph_connectCanonicalComponents(threadData, _partition, _canon1, _canon2, &tmp10);
_partition = tmpMeta[3];
if (1 != tmp10) goto goto_2;
tmpMeta[3] = mmc_mk_cons(_inDaeEdge, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _partition;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
case 3: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_partition = tmp4_1;
_ref1 = tmpMeta[3];
_ref2 = tmpMeta[4];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[3] = stringAppend(_OMC_LIT136,omc_ComponentReference_printComponentRefStr(threadData, _ref1));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT2);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_ComponentReference_printComponentRefStr(threadData, _ref2));
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT137);
omc_Debug_trace(threadData, tmpMeta[6]);
}
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = mmc_mk_cons(_inDaeEdge, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = _partition;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outPartition = tmpMeta[0+0];
_outConnectedConnections = tmpMeta[0+1];
_outBrokenConnections = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outConnectedConnections) { *out_outConnectedConnections = _outConnectedConnections; }
if (out_outBrokenConnections) { *out_outBrokenConnections = _outBrokenConnections; }
return _outPartition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_connectBranchComponents(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2)
{
modelica_metatype _outPartition = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _inPartition;
tmp3_2 = _inRef1;
tmp3_3 = _inRef2;
{
modelica_metatype _partition = NULL;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _canon1 = NULL;
modelica_metatype _canon2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
_partition = tmp3_1;
_ref1 = tmp3_2;
_ref2 = tmp3_3;
_canon1 = omc_ConnectionGraph_canonical(threadData, _partition, _ref1);
_canon2 = omc_ConnectionGraph_canonical(threadData, _partition, _ref2);
tmpMeta[1] = omc_ConnectionGraph_connectCanonicalComponents(threadData, _partition, _canon1, _canon2, &tmp5);
_partition = tmpMeta[1];
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _partition;
goto tmp2_done;
}
case 1: {
_partition = tmp3_1;
tmpMeta[0] = _partition;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outPartition = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPartition;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectionGraph_areInSameComponent(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2)
{
modelica_boolean _outResult;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inPartition;
tmp4_2 = _inRef1;
tmp4_3 = _inRef2;
{
modelica_metatype _partition = NULL;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _canon1 = NULL;
modelica_metatype _canon2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
_partition = tmp4_1;
_ref1 = tmp4_2;
_ref2 = tmp4_3;
_canon1 = omc_ConnectionGraph_canonical(threadData, _partition, _ref1);
_canon2 = omc_ConnectionGraph_canonical(threadData, _partition, _ref2);
tmp6 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _canon1, _canon2);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
tmp1 = 0;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outResult = tmp1;
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectionGraph_areInSameComponent(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef1, modelica_metatype _inRef2)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_ConnectionGraph_areInSameComponent(threadData, _inPartition, _inRef1, _inRef2);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectionGraph_canonical(threadData_t *threadData, modelica_metatype _inPartition, modelica_metatype _inRef)
{
modelica_metatype _outCanonical = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inPartition;
tmp3_2 = _inRef;
{
modelica_metatype _partition = NULL;
modelica_metatype _ref = NULL;
modelica_metatype _parent = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_partition = tmp3_1;
_ref = tmp3_2;
_parent = omc_BaseHashTable_get(threadData, _ref, _partition);
tmpMeta[0] = omc_ConnectionGraph_canonical(threadData, _partition, _parent);
goto tmp2_done;
}
case 1: {
_ref = tmp3_2;
tmpMeta[0] = _ref;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outCanonical = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCanonical;
}
DLLExport
modelica_metatype omc_ConnectionGraph_addConnection(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef1, modelica_metatype _inRef2, modelica_metatype _inDae)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;modelica_metatype tmp3_4;
tmp3_1 = _inGraph;
tmp3_2 = _inRef1;
tmp3_3 = _inRef2;
tmp3_4 = _inDae;
{
modelica_boolean _updateGraph;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_updateGraph = tmp5;
_definiteRoots = tmpMeta[2];
_potentialRoots = tmpMeta[3];
_uniqueRoots = tmpMeta[4];
_branches = tmpMeta[5];
_connections = tmpMeta[6];
_ref1 = tmp3_2;
_ref2 = tmp3_3;
_dae = tmp3_4;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT138,omc_ComponentReference_printComponentRefStr(threadData, _ref1));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ComponentReference_printComponentRefStr(threadData, _ref2));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT139);
omc_Debug_trace(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box3(0, _ref1, _ref2, _dae);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _connections);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, _potentialRoots, _uniqueRoots, _branches, tmpMeta[1]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_ConnectionGraph_addBranch(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef1, modelica_metatype _inRef2)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inGraph;
tmp3_2 = _inRef1;
tmp3_3 = _inRef2;
{
modelica_boolean _updateGraph;
modelica_metatype _ref1 = NULL;
modelica_metatype _ref2 = NULL;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_updateGraph = tmp5;
_definiteRoots = tmpMeta[2];
_potentialRoots = tmpMeta[3];
_uniqueRoots = tmpMeta[4];
_branches = tmpMeta[5];
_connections = tmpMeta[6];
_ref1 = tmp3_2;
_ref2 = tmp3_3;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT140,omc_ComponentReference_printComponentRefStr(threadData, _ref1));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ComponentReference_printComponentRefStr(threadData, _ref2));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(0, _ref1, _ref2);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _branches);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, _potentialRoots, _uniqueRoots, tmpMeta[1], _connections);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_ConnectionGraph_addUniqueRoots(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRoots, modelica_metatype _inMessage)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inGraph;
tmp3_2 = _inRoots;
{
modelica_boolean _updateGraph;
modelica_metatype _root = NULL;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _ty = NULL;
modelica_boolean _scalar;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_root = tmpMeta[1];
_updateGraph = tmp5;
_definiteRoots = tmpMeta[3];
_potentialRoots = tmpMeta[4];
_uniqueRoots = tmpMeta[5];
_branches = tmpMeta[6];
_connections = tmpMeta[7];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT141,omc_ComponentReference_printComponentRefStr(threadData, _root));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ExpressionDump_printExpStr(threadData, _inMessage));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(0, _root, _inMessage);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _uniqueRoots);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, _potentialRoots, tmpMeta[1], _branches, _connections);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[0] = _inGraph;
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_ty = tmpMeta[1];
_scalar = tmp6;
_root = tmpMeta[6];
_rest = tmpMeta[5];
_updateGraph = tmp7;
_definiteRoots = tmpMeta[8];
_potentialRoots = tmpMeta[9];
_uniqueRoots = tmpMeta[10];
_branches = tmpMeta[11];
_connections = tmpMeta[12];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT141,omc_ComponentReference_printComponentRefStr(threadData, _root));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ExpressionDump_printExpStr(threadData, _inMessage));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(0, _root, _inMessage);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _uniqueRoots);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, _potentialRoots, tmpMeta[1], _branches, _connections);
_graph = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(_scalar), _rest);
_inGraph = _graph;
_inRoots = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _inGraph;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_ConnectionGraph_addPotentialRoot(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRoot, modelica_real _inPriority)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_real tmp3_3;
tmp3_1 = _inGraph;
tmp3_2 = _inRoot;
tmp3_3 = _inPriority;
{
modelica_boolean _updateGraph;
modelica_metatype _root = NULL;
modelica_real _priority;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_updateGraph = tmp5;
_definiteRoots = tmpMeta[2];
_potentialRoots = tmpMeta[3];
_uniqueRoots = tmpMeta[4];
_branches = tmpMeta[5];
_connections = tmpMeta[6];
_root = tmp3_2;
_priority = tmp3_3;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT142,omc_ComponentReference_printComponentRefStr(threadData, _root));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT2);
tmpMeta[3] = stringAppend(tmpMeta[2],realString(_priority));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[4]);
}
tmpMeta[2] = mmc_mk_box2(0, _root, mmc_mk_real(_priority));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _potentialRoots);
tmpMeta[3] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), _definiteRoots, tmpMeta[1], _uniqueRoots, _branches, _connections);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
modelica_metatype boxptr_ConnectionGraph_addPotentialRoot(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRoot, modelica_metatype _inPriority)
{
modelica_real tmp1;
modelica_metatype _outGraph = NULL;
tmp1 = mmc_unbox_real(_inPriority);
_outGraph = omc_ConnectionGraph_addPotentialRoot(threadData, _inGraph, _inRoot, tmp1);
return _outGraph;
}
DLLExport
modelica_metatype omc_ConnectionGraph_addDefiniteRoot(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRoot)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inGraph;
tmp3_2 = _inRoot;
{
modelica_boolean _updateGraph;
modelica_metatype _root = NULL;
modelica_metatype _definiteRoots = NULL;
modelica_metatype _potentialRoots = NULL;
modelica_metatype _uniqueRoots = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _connections = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_updateGraph = tmp5;
_definiteRoots = tmpMeta[2];
_potentialRoots = tmpMeta[3];
_uniqueRoots = tmpMeta[4];
_branches = tmpMeta[5];
_connections = tmpMeta[6];
_root = tmp3_2;
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[1] = stringAppend(_OMC_LIT143,omc_ComponentReference_printComponentRefStr(threadData, _root));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT3);
omc_Debug_traceln(threadData, tmpMeta[2]);
}
tmpMeta[1] = mmc_mk_cons(_root, _definiteRoots);
tmpMeta[2] = mmc_mk_box7(3, &ConnectionGraph_ConnectionGraph_GRAPH__desc, mmc_mk_boolean(_updateGraph), tmpMeta[1], _potentialRoots, _uniqueRoots, _branches, _connections);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outGraph = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_ConnectionGraph_handleOverconstrainedConnections(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _modelNameQualified, modelica_metatype _inDAE, modelica_metatype *out_outConnected, modelica_metatype *out_outBroken)
{
modelica_metatype _outDAE = NULL;
modelica_metatype _outConnected = NULL;
modelica_metatype _outBroken = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inGraph;
tmp4_2 = _inDAE;
{
modelica_metatype _graph = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _roots = NULL;
modelica_metatype _broken = NULL;
modelica_metatype _connected = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (!listEmpty(tmpMeta[7])) goto tmp3_end;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inDAE;
tmpMeta[0+1] = tmpMeta[3];
tmpMeta[0+2] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_graph = tmp4_1;
_elts = tmpMeta[3];
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[3] = stringAppend(_OMC_LIT144,intString(listLength(omc_ConnectionGraph_getDefiniteRoots(threadData, _graph))));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT134);
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT145);
tmpMeta[6] = stringAppend(tmpMeta[5],intString(listLength(omc_ConnectionGraph_getPotentialRoots(threadData, _graph))));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT134);
tmpMeta[8] = stringAppend(tmpMeta[7],_OMC_LIT146);
tmpMeta[9] = stringAppend(tmpMeta[8],intString(listLength(omc_ConnectionGraph_getUniqueRoots(threadData, _graph))));
tmpMeta[10] = stringAppend(tmpMeta[9],_OMC_LIT134);
tmpMeta[11] = stringAppend(tmpMeta[10],_OMC_LIT147);
tmpMeta[12] = stringAppend(tmpMeta[11],intString(listLength(omc_ConnectionGraph_getBranches(threadData, _graph))));
tmpMeta[13] = stringAppend(tmpMeta[12],_OMC_LIT134);
tmpMeta[14] = stringAppend(tmpMeta[13],_OMC_LIT148);
tmpMeta[15] = stringAppend(tmpMeta[14],intString(listLength(omc_ConnectionGraph_getConnections(threadData, _graph))));
omc_Debug_traceln(threadData, tmpMeta[15]);
}
_roots = omc_ConnectionGraph_findResultGraph(threadData, _graph, _modelNameQualified ,&_connected ,&_broken);
if(omc_Flags_isSet(threadData, _OMC_LIT7))
{
tmpMeta[3] = stringAppend(_OMC_LIT149,stringDelimitList(omc_List_map(threadData, _roots, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[3]);
tmpMeta[3] = stringAppend(_OMC_LIT150,stringDelimitList(omc_List_map1(threadData, _broken, boxvar_ConnectionGraph_printConnectionStr, _OMC_LIT151), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[3]);
tmpMeta[3] = stringAppend(_OMC_LIT152,stringDelimitList(omc_List_map1(threadData, _connected, boxvar_ConnectionGraph_printConnectionStr, _OMC_LIT9), _OMC_LIT2));
omc_Debug_traceln(threadData, tmpMeta[3]);
}
_elts = omc_ConnectionGraph_evalConnectionsOperators(threadData, _roots, _graph, _elts);
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _connected;
tmpMeta[0+2] = _broken;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT7);
if (1 != tmp6) goto goto_2;
tmpMeta[3] = stringAppend(_OMC_LIT153,_modelNameQualified);
omc_Debug_traceln(threadData, tmpMeta[3]);
goto goto_2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outDAE = tmpMeta[0+0];
_outConnected = tmpMeta[0+1];
_outBroken = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outConnected) { *out_outConnected = _outConnected; }
if (out_outBroken) { *out_outBroken = _outBroken; }
return _outDAE;
}

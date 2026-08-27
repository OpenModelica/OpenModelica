#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Main.c"
#endif
#include "omc_simulation_settings.h"
#include "Main.h"
#define _OMC_LIT0_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "interactive"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,11,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "none"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,4,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,8) {&Flags_FlagData_STRING__FLAG__desc,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "do nothing"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,10,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,0) {_OMC_LIT3,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "corba"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,5,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "Starts omc as a server listening on the Corba interface."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,56,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,0) {_OMC_LIT8,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "tcp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,3,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Starts omc as a server listening on the socket interface."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,57,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,0) {_OMC_LIT12,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "zmq"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,3,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Starts omc as a ZeroMQ server listening on the socket interface."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,64,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,0) {_OMC_LIT16,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,1) {_OMC_LIT19,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,1) {_OMC_LIT15,_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,1) {_OMC_LIT11,_OMC_LIT21}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,1) {_OMC_LIT7,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,4) {&Flags_ValidOptions_STRING__DESC__OPTION__desc,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,1) {_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Sets the interactive mode for omc."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,34,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(114)),_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT2,_OMC_LIT4,_OMC_LIT25,_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "You are trying to run OpenModelica as a server using the root user.\nThis is a very bad idea:\n* The socket interface does not authenticate the user.\n* OpenModelica allows execution of arbitrary commands."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,202,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(557)),_OMC_LIT29,_OMC_LIT30,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,0,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "# Error encountered! Exiting...\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,32,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "# Please check the error message and the flags.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,48,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "\n\n----\n\nError buffer:\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,23,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "Error: OPENMODELICAHOME was not set.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,37,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "  Read the documentation for instructions on how to set it properly.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,69,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "  Most OpenModelica release distributions have scripts that set OPENMODELICAHOME for you.\n\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,91,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "GC stats after initialization:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,30,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,3,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "gcProfiling"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,11,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "Prints garbage collection stats to standard output."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,51,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),_OMC_LIT43,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "alarm"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,5,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "r"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,1,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,1) {_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,5) {&Flags_FlagData_INT__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "Sets the number seconds until omc timeouts and exits. Used by the testing framework to terminate infinite running processes."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,124,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT51}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(101)),_OMC_LIT47,_OMC_LIT49,_OMC_LIT2,_OMC_LIT50,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT52}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "GC stats at end of program:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,27,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,154,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "G_SLICE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,7,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "always-malloc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,13,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "C"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,1,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "locale"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,6,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,2,8) {&Flags_FlagData_STRING__FLAG__desc,_OMC_LIT34}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "Override the locale from the environment."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,41,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT61}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(39)),_OMC_LIT59,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT2,_OMC_LIT60,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT62}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "CC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,2,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "OPENMODELICAHOME"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,16,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "OMDEV"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,5,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "\\tools\\msys\\usr\\bin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,19,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "\\tools\\msys\\"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,12,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "\\bin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,4,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "\\lib\\gcc\\"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,9,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "\\"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,1,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "gcc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,3,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "We could not find some needed MINGW paths in $OPENMODELICAHOME or $OMDEV. Searched for paths:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,94,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,1,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data " [found] "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,9,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data " [not found] "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,13,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "disableWindowsPathCheckWarning"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,30,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "Disables warnings on Windows if OPENMODELICAHOME/MinGW is missing."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,66,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT78}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(98)),_OMC_LIT77,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT79}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "PATH"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,4,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "\\bin;"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,5,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "\\lib;"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,5,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,1,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,1,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "runScript(\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,11,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "\")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,2,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "-s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,2,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data " \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,2,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "quit requested, shutting server down\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,37,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "zeroMQFileSuffix"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,16,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "z"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,1,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,1,1) {_OMC_LIT92}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "Sets the file suffix for zeroMQ port file if --interactive=zmq is used."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,71,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT94}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT96,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(115)),_OMC_LIT91,_OMC_LIT93,_OMC_LIT2,_OMC_LIT60,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT95}};
#define _OMC_LIT96 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,1,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "zmqDangerousAcceptConnectionsFromAnywhere"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,41,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "When opening a zmq connection, listen on all interfaces instead of only connections from 127.0.0.1."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,99,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT99}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(195)),_OMC_LIT98,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT100}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
#define _OMC_LIT102_data "interactivePort"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT102,15,_OMC_LIT102_data);
#define _OMC_LIT102 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data "Sets the port used by the interactive server."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,45,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT103}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(147)),_OMC_LIT102,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT2,_OMC_LIT50,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT104}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "------- Recieved Data from client -----\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,40,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
#define _OMC_LIT108_data "------- End recieved Data-----\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT108,31,_OMC_LIT108_data);
#define _OMC_LIT108 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data "interactivedump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,15,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "Prints out debug information for the interactive server."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,56,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT111,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT110}};
#define _OMC_LIT111 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT111)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT112,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(36)),_OMC_LIT109,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT111}};
#define _OMC_LIT112 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "Failed to initialize Corba! Is another OMC already running?\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,60,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
#define _OMC_LIT114_data "Exiting!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT114,9,_OMC_LIT114_data);
#define _OMC_LIT114 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data "dassl"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,5,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data "plt"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,3,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data ".*"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,2,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data "mat"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,3,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT119,3,3) {&Absyn_FunctionArgs_FUNCTIONARGS__desc,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT119 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data "Codegen Done"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,12,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
#define _OMC_LIT121_data "\n--------------- Parsed program ---------------\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT121,48,_OMC_LIT121_data);
#define _OMC_LIT121 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "dump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,4,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "Dumps the absyn representation of a program."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,44,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT123}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(29)),_OMC_LIT122,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT124}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
#define _OMC_LIT126_data "\n--------------- Julia representation of the parsed program ---------------\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT126,76,_OMC_LIT126_data);
#define _OMC_LIT126 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT126)
#define _OMC_LIT127_data "dumpJL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT127,6,_OMC_LIT127_data);
#define _OMC_LIT127 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT127)
#define _OMC_LIT128_data "Dumps the absyn representation of a program as a Julia representation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT128,69,_OMC_LIT128_data);
#define _OMC_LIT128 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT128)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT129,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT128}};
#define _OMC_LIT129 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT129)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT130,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(187)),_OMC_LIT127,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT129}};
#define _OMC_LIT130 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "graphviz"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,8,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "Dumps the absyn representation of a program in graphviz format."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,63,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT133,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT132}};
#define _OMC_LIT133 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT133)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT134,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(30)),_OMC_LIT131,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT133}};
#define _OMC_LIT134 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "Parsed file"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,11,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "transformsbeforedump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,20,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data "Applies transformations required for code generation before dumping flat code."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,78,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT138,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT137}};
#define _OMC_LIT138 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT138)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT139,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(32)),_OMC_LIT136,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT138}};
#define _OMC_LIT139 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT139)
#define _OMC_LIT140_data "Transformations before Dump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT140,27,_OMC_LIT140_data);
#define _OMC_LIT140 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT140)
#define _OMC_LIT141_data "DAEDump done"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT141,12,_OMC_LIT141_data);
#define _OMC_LIT141 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT141)
#define _OMC_LIT142_data "daedumpgraphv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT142,13,_OMC_LIT142_data);
#define _OMC_LIT142 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT142)
#define _OMC_LIT143_data "Dumps the DAE in graphviz format."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT143,33,_OMC_LIT143_data);
#define _OMC_LIT143 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT143}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT145,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(33)),_OMC_LIT142,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT144}};
#define _OMC_LIT145 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data "Misc Dump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,9,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data "Transformations before backend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,30,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
#define _OMC_LIT148_data "File does not exist: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT148,21,_OMC_LIT148_data);
#define _OMC_LIT148 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT148)
#define _OMC_LIT149_data "Error processing file: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT149,23,_OMC_LIT149_data);
#define _OMC_LIT149 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT149)
#define _OMC_LIT150_data "UTF-8"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT150,5,_OMC_LIT150_data);
#define _OMC_LIT150 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT150)
#define _OMC_LIT151_data "command-line argument"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT151,21,_OMC_LIT151_data);
#define _OMC_LIT151 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,7,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT153,2,1) {_OMC_LIT152,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT153 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT153)
#define _OMC_LIT154_data "Failed to load library: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT154,24,_OMC_LIT154_data);
#define _OMC_LIT154 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT154)
#define _OMC_LIT155_data "!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT155,2,_OMC_LIT155_data);
#define _OMC_LIT155 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT155)
#define _OMC_LIT156_data "Failed to parse file: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT156,22,_OMC_LIT156_data);
#define _OMC_LIT156 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT156)
#define _OMC_LIT157_data "tpl"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT157,3,_OMC_LIT157_data);
#define _OMC_LIT157 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT157)
#define _OMC_LIT158_data "mos"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT158,3,_OMC_LIT158_data);
#define _OMC_LIT158 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT158)
#define _OMC_LIT159_data "mof"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT159,3,_OMC_LIT159_data);
#define _OMC_LIT159 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT159)
#define _OMC_LIT160_data "mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT160,2,_OMC_LIT160_data);
#define _OMC_LIT160 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT160)
#define _OMC_LIT161_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT161,1,_OMC_LIT161_data);
#define _OMC_LIT161 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,1,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
#define _OMC_LIT163_data "}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT163,2,_OMC_LIT163_data);
#define _OMC_LIT163 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT163)
#define _OMC_LIT164_data "Error occurred building AST\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT164,28,_OMC_LIT164_data);
#define _OMC_LIT164 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT164)
#define _OMC_LIT165_data "Syntax Error\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT165,13,_OMC_LIT165_data);
#define _OMC_LIT165 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT165)
#define _OMC_LIT166_data "Stack overflow occurred while evaluating %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT166,44,_OMC_LIT166_data);
#define _OMC_LIT166 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT166)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT167,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT166}};
#define _OMC_LIT167 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT167)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT168,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(205)),_OMC_LIT29,_OMC_LIT30,_OMC_LIT167}};
#define _OMC_LIT168 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT168)
#define _OMC_LIT169_data "Ok\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT169,3,_OMC_LIT169_data);
#define _OMC_LIT169 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT169)
#define _OMC_LIT170_data "quit()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT170,6,_OMC_LIT170_data);
#define _OMC_LIT170 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT170)
#define _OMC_LIT171_data "parsestring"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT171,11,_OMC_LIT171_data);
#define _OMC_LIT171 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT171)
#define _OMC_LIT172_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT172,13,_OMC_LIT172_data);
#define _OMC_LIT172 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT172)
#define _OMC_LIT173_data "\n---DEBUG("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT173,10,_OMC_LIT173_data);
#define _OMC_LIT173 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT173)
#define _OMC_LIT174_data ")---\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT174,5,_OMC_LIT174_data);
#define _OMC_LIT174 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT174)
#define _OMC_LIT175_data "\n---/DEBUG("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT175,11,_OMC_LIT175_data);
#define _OMC_LIT175 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT175)
#include "util/modelica.h"
#include "Main_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_Main_main2(threadData_t *threadData, modelica_metatype _args);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_main2,2,0) {(void*) boxptr_Main_main2,0}};
#define boxvar_Main_main2 MMC_REFSTRUCTLIT(boxvar_lit_Main_main2)
PROTECTED_FUNCTION_STATIC void omc_Main_setDefaultCC(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_setDefaultCC,2,0) {(void*) boxptr_Main_setDefaultCC,0}};
#define boxvar_Main_setDefaultCC MMC_REFSTRUCTLIT(boxvar_lit_Main_setDefaultCC)
PROTECTED_FUNCTION_STATIC void omc_Main_readSettingsFile(threadData_t *threadData, modelica_string _filePath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_readSettingsFile,2,0) {(void*) boxptr_Main_readSettingsFile,0}};
#define boxvar_Main_readSettingsFile MMC_REFSTRUCTLIT(boxvar_lit_Main_readSettingsFile)
PROTECTED_FUNCTION_STATIC void omc_Main_serverLoopCorba(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_serverLoopCorba,2,0) {(void*) boxptr_Main_serverLoopCorba,0}};
#define boxvar_Main_serverLoopCorba MMC_REFSTRUCTLIT(boxvar_lit_Main_serverLoopCorba)
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemodeZMQ(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_interactivemodeZMQ,2,0) {(void*) boxptr_Main_interactivemodeZMQ,0}};
#define boxvar_Main_interactivemodeZMQ MMC_REFSTRUCTLIT(boxvar_lit_Main_interactivemodeZMQ)
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemodeCorba(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_interactivemodeCorba,2,0) {(void*) boxptr_Main_interactivemodeCorba,0}};
#define boxvar_Main_interactivemodeCorba MMC_REFSTRUCTLIT(boxvar_lit_Main_interactivemodeCorba)
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemode(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_interactivemode,2,0) {(void*) boxptr_Main_interactivemode,0}};
#define boxvar_Main_interactivemode MMC_REFSTRUCTLIT(boxvar_lit_Main_interactivemode)
PROTECTED_FUNCTION_STATIC void omc_Main_simcodegen(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineData, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _inClassName, modelica_metatype _inProgram);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_simcodegen,2,0) {(void*) boxptr_Main_simcodegen,0}};
#define boxvar_Main_simcodegen MMC_REFSTRUCTLIT(boxvar_lit_Main_simcodegen)
PROTECTED_FUNCTION_STATIC void omc_Main_optimizeDae(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _dae, modelica_metatype _ap, modelica_metatype _inClassName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_optimizeDae,2,0) {(void*) boxptr_Main_optimizeDae,0}};
#define boxvar_Main_optimizeDae MMC_REFSTRUCTLIT(boxvar_lit_Main_optimizeDae)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Main_instantiate(threadData_t *threadData, modelica_metatype *out_env, modelica_metatype *out_dae, modelica_metatype *out_cname, modelica_string *out_flatString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_instantiate,2,0) {(void*) boxptr_Main_instantiate,0}};
#define boxvar_Main_instantiate MMC_REFSTRUCTLIT(boxvar_lit_Main_instantiate)
PROTECTED_FUNCTION_STATIC void omc_Main_translateFile(threadData_t *threadData, modelica_metatype _inStringLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_translateFile,2,0) {(void*) boxptr_Main_translateFile,0}};
#define boxvar_Main_translateFile MMC_REFSTRUCTLIT(boxvar_lit_Main_translateFile)
PROTECTED_FUNCTION_STATIC void omc_Main_loadLib(threadData_t *threadData, modelica_string _inLib);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_loadLib,2,0) {(void*) boxptr_Main_loadLib,0}};
#define boxvar_Main_loadLib MMC_REFSTRUCTLIT(boxvar_lit_Main_loadLib)
PROTECTED_FUNCTION_STATIC void omc_Main_showErrors(threadData_t *threadData, modelica_string _errorString, modelica_string _errorMessages);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_showErrors,2,0) {(void*) boxptr_Main_showErrors,0}};
#define boxvar_Main_showErrors MMC_REFSTRUCTLIT(boxvar_lit_Main_showErrors)
PROTECTED_FUNCTION_STATIC void omc_Main_isCodegenTemplateFile(threadData_t *threadData, modelica_string _filename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_isCodegenTemplateFile,2,0) {(void*) boxptr_Main_isCodegenTemplateFile,0}};
#define boxvar_Main_isCodegenTemplateFile MMC_REFSTRUCTLIT(boxvar_lit_Main_isCodegenTemplateFile)
PROTECTED_FUNCTION_STATIC void omc_Main_isModelicaScriptFile(threadData_t *threadData, modelica_string _filename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_isModelicaScriptFile,2,0) {(void*) boxptr_Main_isModelicaScriptFile,0}};
#define boxvar_Main_isModelicaScriptFile MMC_REFSTRUCTLIT(boxvar_lit_Main_isModelicaScriptFile)
PROTECTED_FUNCTION_STATIC void omc_Main_isFlatModelicaFile(threadData_t *threadData, modelica_string _filename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_isFlatModelicaFile,2,0) {(void*) boxptr_Main_isFlatModelicaFile,0}};
#define boxvar_Main_isFlatModelicaFile MMC_REFSTRUCTLIT(boxvar_lit_Main_isFlatModelicaFile)
PROTECTED_FUNCTION_STATIC void omc_Main_isEmptyOrFirstIsModelicaFile(threadData_t *threadData, modelica_metatype _libs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_isEmptyOrFirstIsModelicaFile,2,0) {(void*) boxptr_Main_isEmptyOrFirstIsModelicaFile,0}};
#define boxvar_Main_isEmptyOrFirstIsModelicaFile MMC_REFSTRUCTLIT(boxvar_lit_Main_isEmptyOrFirstIsModelicaFile)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Main_isModelicaFile(threadData_t *threadData, modelica_string _inFilename);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Main_isModelicaFile(threadData_t *threadData, modelica_metatype _inFilename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_isModelicaFile,2,0) {(void*) boxptr_Main_isModelicaFile,0}};
#define boxvar_Main_isModelicaFile MMC_REFSTRUCTLIT(boxvar_lit_Main_isModelicaFile)
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_makeClassDefResult(threadData_t *threadData, modelica_metatype _p);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_makeClassDefResult,2,0) {(void*) boxptr_Main_makeClassDefResult,0}};
#define boxvar_Main_makeClassDefResult MMC_REFSTRUCTLIT(boxvar_lit_Main_makeClassDefResult)
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_handleCommand2(threadData_t *threadData, modelica_metatype _inStatements, modelica_metatype _inProgram, modelica_string _inCommand);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_handleCommand2,2,0) {(void*) boxptr_Main_handleCommand2,0}};
#define boxvar_Main_handleCommand2 MMC_REFSTRUCTLIT(boxvar_lit_Main_handleCommand2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Main_parseCommand(threadData_t *threadData, modelica_string _inCommand, modelica_metatype *out_outProgram);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_parseCommand,2,0) {(void*) boxptr_Main_parseCommand,0}};
#define boxvar_Main_parseCommand MMC_REFSTRUCTLIT(boxvar_lit_Main_parseCommand)
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_makeDebugResult(threadData_t *threadData, modelica_metatype _inFlag, modelica_string _res);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_makeDebugResult,2,0) {(void*) boxptr_Main_makeDebugResult,0}};
#define boxvar_Main_makeDebugResult MMC_REFSTRUCTLIT(boxvar_lit_Main_makeDebugResult)
PROTECTED_FUNCTION_STATIC void omc_Main_main2(threadData_t *threadData, modelica_metatype _args)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_string _interactiveMode = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Config_versionRequest(threadData))
{
tmpMeta[0] = stringAppend(omc_Settings_getVersionNr(threadData),_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[0]),stdout);
goto _return;
}
_interactiveMode = omc_Flags_getConfigString(threadData, _OMC_LIT28);
if((omc_System_userIsRoot(threadData) && (((stringEqual(_interactiveMode, _OMC_LIT8)) || (stringEqual(_interactiveMode, _OMC_LIT12))) || (stringEqual(_interactiveMode, _OMC_LIT16)))))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addMessage(threadData, _OMC_LIT33, tmpMeta[0]);
fputs(MMC_STRINGDATA(omc_ErrorExt_printMessagesStr(threadData, 0)),stdout);
MMC_THROW_INTERNAL();
}
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
omc_Settings_getInstallationDirectoryPath(threadData);
omc_Main_readSettings(threadData, _args);
if((stringEqual(_interactiveMode, _OMC_LIT12)))
{
omc_Main_interactivemode(threadData);
}
else
{
if((stringEqual(_interactiveMode, _OMC_LIT8)))
{
omc_Main_interactivemodeCorba(threadData);
}
else
{
if((stringEqual(_interactiveMode, _OMC_LIT16)))
{
omc_Main_interactivemodeZMQ(threadData);
}
else
{
omc_Main_translateFile(threadData, _args);
}
}
}
goto tmp2_done;
}
case 1: {
if((listEmpty(_args) && (stringEqual(omc_Config_classToInstantiate(threadData), _OMC_LIT34))))
{
if((!omc_Config_helpRequest(threadData)))
{
fputs(MMC_STRINGDATA(omc_FlagsUtil_printUsage(threadData)),stdout);
}
goto _return;
}
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
omc_Settings_getInstallationDirectoryPath(threadData);
fputs(MMC_STRINGDATA(_OMC_LIT35),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT36),stdout);
omc_Print_printBuf(threadData, _OMC_LIT37);
fputs(MMC_STRINGDATA(omc_Print_getErrorString(threadData)),stdout);
fputs(MMC_STRINGDATA(omc_ErrorExt_printMessagesStr(threadData, 0)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
goto tmp6_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT38),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT39),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT40),stdout);
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
;
goto goto_1;
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
;
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return;
}
DLLExport
void omc_Main_main(threadData_t *threadData, modelica_metatype _args)
{
modelica_metatype _args_1 = NULL;
modelica_metatype _stats = NULL;
modelica_integer _seconds;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ExecStat_execStatReset(threadData);
{
{
MMC_TRY_STACK()
{
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
_args_1 = omc_Main_init(threadData, _args);
if(omc_Flags_isSet(threadData, _OMC_LIT46))
{
tmpMeta[0] = stringAppend(omc_GC_profStatsStr(threadData, omc_GC_getProfStats(threadData), _OMC_LIT41, _OMC_LIT42),_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[0]),stdout);
}
_seconds = omc_Flags_getConfigInt(threadData, _OMC_LIT53);
if((_seconds > ((modelica_integer) 0)))
{
omc_System_alarm(threadData, _seconds);
}
omc_Main_main2(threadData, _args_1);
goto tmp5_done;
}
case 1: {
modelica_boolean tmp8;
omc_ErrorExt_clearMessages(threadData);
tmp8 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FlagsUtil_new(threadData, _args);
tmp8 = 1;
goto goto_9;
goto_9:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp8) {goto goto_4;}
fputs(MMC_STRINGDATA(omc_ErrorExt_printMessagesStr(threadData, 0)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
goto goto_4;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
;
if(omc_Flags_isSet(threadData, _OMC_LIT46))
{
tmpMeta[0] = stringAppend(omc_GC_profStatsStr(threadData, omc_GC_getProfStats(threadData), _OMC_LIT54, _OMC_LIT42),_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[0]),stdout);
}
MMC_ELSE_STACK()
fputs(MMC_STRINGDATA(_OMC_LIT55),stdout);
{
modelica_metatype _s;
for (tmpMeta[0] = omc_StackOverflow_readableStacktraceMessages(threadData); !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_s = MMC_CAR(tmpMeta[0]);
fputs(MMC_STRINGDATA(_s),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
}
}
MMC_CATCH_STACK()
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Main_init(threadData_t *threadData, modelica_metatype _args)
{
modelica_metatype _args_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_System_setEnv(threadData, _OMC_LIT56, _OMC_LIT57, 1);
omc_System_initGarbageCollector(threadData);
omc_GC_setForceUnmapOnGcollect(threadData, 0);
omc_Global_initialize(threadData);
omc_ErrorExt_registerModelicaFormatError(threadData);
omc_ErrorExt_initAssertionFunctions(threadData);
omc_System_realtimeTick(threadData, ((modelica_integer) 8));
_args_1 = omc_FlagsUtil_new(threadData, _args);
omc_System_gettextInit(threadData, (omc_Testsuite_isRunning(threadData)?_OMC_LIT58:omc_Flags_getConfigString(threadData, _OMC_LIT63)));
omc_Main_setDefaultCC(threadData);
omc_SymbolTable_reset(threadData);
_return: OMC_LABEL_UNUSED
return _args_1;
}
PROTECTED_FUNCTION_STATIC void omc_Main_setDefaultCC(threadData_t *threadData)
{
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
omc_System_setCCompiler(threadData, omc_System_readEnv(threadData, _OMC_LIT64));
goto tmp2_done;
}
case 1: {
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
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Main_setWindowsPaths(threadData_t *threadData, modelica_string _inOMHome)
{
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp3_1;
tmp3_1 = _inOMHome;
{
modelica_string _oldPath = NULL;
modelica_string _newPath = NULL;
modelica_string _omHome = NULL;
modelica_string _omdevPath = NULL;
modelica_string _mingwDir = NULL;
modelica_string _binDir = NULL;
modelica_string _libBinDir = NULL;
modelica_string _msysBinDir = NULL;
modelica_boolean _hasBinDir;
modelica_boolean _hasLibBinDir;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_omHome = tmp3_1;
omc_System_setEnv(threadData, _OMC_LIT65, _omHome, 1);
_omdevPath = omc_Util_makeValueOrDefault(threadData, boxvar_System_readEnv, _OMC_LIT66, _OMC_LIT34);
_mingwDir = omc_System_openModelicaPlatform(threadData);
if((stringEqual(_omdevPath, _OMC_LIT34)))
{
_omdevPath = _omHome;
}
tmpMeta[0] = stringAppend(_omdevPath,_OMC_LIT67);
_msysBinDir = tmpMeta[0];
tmpMeta[0] = stringAppend(_omdevPath,_OMC_LIT68);
tmpMeta[1] = stringAppend(tmpMeta[0],_mingwDir);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT69);
_binDir = tmpMeta[2];
if((stringEqual(omc_System_getCCompiler(threadData), _OMC_LIT72)))
{
tmpMeta[0] = stringAppend(_omdevPath,_OMC_LIT68);
tmpMeta[1] = stringAppend(tmpMeta[0],_mingwDir);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT70);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_System_gccDumpMachine(threadData));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT71);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_System_gccVersion(threadData));
_libBinDir = tmpMeta[5];
}
else
{
_libBinDir = _binDir;
}
_hasBinDir = omc_System_directoryExists(threadData, _binDir);
_hasLibBinDir = omc_System_directoryExists(threadData, _libBinDir);
if((_hasBinDir && _hasLibBinDir))
{
_oldPath = omc_System_readEnv(threadData, _OMC_LIT81);
tmpMeta[1] = stringAppend(_binDir,_OMC_LIT84);
tmpMeta[2] = stringAppend(_libBinDir,_OMC_LIT84);
tmpMeta[3] = stringAppend(_msysBinDir,_OMC_LIT84);
tmpMeta[0] = mmc_mk_cons(_omHome, mmc_mk_cons(_OMC_LIT82, mmc_mk_cons(_omHome, mmc_mk_cons(_OMC_LIT83, mmc_mk_cons(tmpMeta[1], mmc_mk_cons(tmpMeta[2], mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil))))))));
_newPath = stringAppendList(tmpMeta[0]);
tmpMeta[0] = stringAppend(omc_System_stringReplace(threadData, _newPath, _OMC_LIT85, _OMC_LIT71),_oldPath);
_newPath = tmpMeta[0];
omc_System_setEnv(threadData, _OMC_LIT81, _newPath, 1);
}
else
{
if((!omc_Flags_isSet(threadData, _OMC_LIT80)))
{
fputs(MMC_STRINGDATA(_OMC_LIT73),stdout);
tmpMeta[0] = stringAppend(_OMC_LIT74,_binDir);
tmpMeta[1] = stringAppend(tmpMeta[0],(_hasBinDir?_OMC_LIT75:_OMC_LIT76));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
tmpMeta[0] = stringAppend(_OMC_LIT74,_libBinDir);
tmpMeta[1] = stringAppend(tmpMeta[0],(_hasLibBinDir?_OMC_LIT75:_OMC_LIT76));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[2]),stdout);
}
}
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
PROTECTED_FUNCTION_STATIC void omc_Main_readSettingsFile(threadData_t *threadData, modelica_string _filePath)
{
modelica_string _command = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_System_regularFileExists(threadData, _filePath))
{
tmpMeta[0] = stringAppend(_OMC_LIT86,_filePath);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT87);
_command = tmpMeta[1];
omc_Main_handleCommand(threadData, _command, NULL);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Main_readSettings(threadData_t *threadData, modelica_metatype _inArguments)
{
modelica_string _settings_file = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_settings_file = omc_Util_flagValue(threadData, _OMC_LIT88, _inArguments);
if((!stringEqual(_settings_file, _OMC_LIT34)))
{
_settings_file = omc_System_trim(threadData, _settings_file, _OMC_LIT89);
omc_Main_readSettingsFile(threadData, _settings_file);
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_serverLoopCorba(threadData_t *threadData)
{
modelica_string _str = NULL;
modelica_string _reply_str = NULL;
modelica_boolean _cont;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cont = 1;
while(1)
{
if(!1) break;
_str = omc_Corba_waitForCommand(threadData);
_cont = omc_Main_handleCommand(threadData, _str ,&_reply_str);
if(_cont)
{
omc_Corba_sendreply(threadData, _reply_str);
}
else
{
break;
}
}
omc_Corba_sendreply(threadData, _OMC_LIT90);
omc_Corba_close(threadData);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemodeZMQ(threadData_t *threadData)
{
modelica_metatype _zmqSocket = NULL;
modelica_boolean _b;
modelica_string _str = NULL;
modelica_string _replystr = NULL;
modelica_string _suffix = NULL;
modelica_boolean tmp1;
modelica_string tmp2;
modelica_boolean tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_suffix = omc_Flags_getConfigString(threadData, _OMC_LIT96);
tmp1 = (modelica_boolean)(stringEqual(_suffix, _OMC_LIT34));
if(tmp1)
{
tmp2 = _OMC_LIT34;
}
else
{
tmpMeta[0] = stringAppend(_OMC_LIT97,_suffix);
tmp2 = tmpMeta[0];
}
_zmqSocket = omc_ZeroMQ_initialize(threadData, tmp2, omc_Flags_isSet(threadData, _OMC_LIT101), omc_Flags_getConfigInt(threadData, _OMC_LIT105));
tmp3 = valueEq(_OMC_LIT106, _zmqSocket);
if (0 != tmp3) MMC_THROW_INTERNAL();
while(1)
{
if(!1) break;
_str = omc_ZeroMQ_handleRequest(threadData, _zmqSocket);
if(omc_Flags_isSet(threadData, _OMC_LIT112))
{
omc_Debug_trace(threadData, _OMC_LIT107);
omc_Debug_trace(threadData, _str);
omc_Debug_trace(threadData, _OMC_LIT108);
}
_b = omc_Main_handleCommand(threadData, _str ,&_replystr);
_replystr = (_b?_replystr:_OMC_LIT90);
omc_ZeroMQ_sendReply(threadData, _zmqSocket, _replystr);
if((!_b))
{
omc_ZeroMQ_close(threadData, _zmqSocket);
break;
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemodeCorba(threadData_t *threadData)
{
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
omc_Corba_initialize(threadData);
omc_Main_serverLoopCorba(threadData);
goto tmp2_done;
}
case 1: {
omc_Print_printBuf(threadData, _OMC_LIT113);
omc_Print_printBuf(threadData, _OMC_LIT114);
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
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_interactivemode(threadData_t *threadData)
{
modelica_integer _shandle;
modelica_boolean _b;
modelica_string _str = NULL;
modelica_string _replystr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_shandle = omc_Socket_waitforconnect(threadData, ((modelica_integer) 29500));
if((_shandle == ((modelica_integer) -1)))
{
MMC_THROW_INTERNAL();
}
while(1)
{
if(!1) break;
_str = omc_Socket_handlerequest(threadData, _shandle);
if(omc_Flags_isSet(threadData, _OMC_LIT112))
{
omc_Debug_trace(threadData, _OMC_LIT107);
omc_Debug_trace(threadData, _str);
omc_Debug_trace(threadData, _OMC_LIT108);
}
_b = omc_Main_handleCommand(threadData, _str ,&_replystr);
_replystr = (_b?_replystr:_OMC_LIT90);
omc_Socket_sendreply(threadData, _shandle, _replystr);
if((!_b))
{
omc_Socket_close(threadData, _shandle);
omc_Socket_cleanup(threadData);
break;
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_simcodegen(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineData, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _inClassName, modelica_metatype _inProgram)
{
modelica_string _cname = NULL;
modelica_integer _sim_settings;
modelica_integer _intervals;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Config_simulationCg(threadData))
{
omc_Print_clearErrorBuf(threadData);
omc_Print_clearBuf(threadData);
_cname = omc_AbsynUtil_pathString(threadData, _inClassName, _OMC_LIT97, 1, 0);
_sim_settings = (omc_Config_acceptParModelicaGrammar(threadData)?omc_SimCodeMain_createSimulationSettings(threadData, 0.0, 1.0, ((modelica_integer) 1), 1e-06, _OMC_LIT115, _OMC_LIT34, _OMC_LIT116, _OMC_LIT117, _OMC_LIT34):omc_SimCodeMain_createSimulationSettings(threadData, 0.0, 1.0, ((modelica_integer) 500), 1e-06, _OMC_LIT115, _OMC_LIT34, _OMC_LIT118, _OMC_LIT117, _OMC_LIT34));
omc_System_realtimeTock(threadData, ((modelica_integer) 14));
omc_SimCodeMain_generateModelCode(threadData, _inBackendDAE, _inInitDAE, _inInitDAE_lambda0, _inInlineData, _inRemovedInitialEquationLst, _inProgram, _inClassName, _cname, mmc_mk_some(mmc_mk_integer(_sim_settings)), _OMC_LIT119, NULL, NULL, NULL);
omc_ExecStat_execStat(threadData, _OMC_LIT120);
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_optimizeDae(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _dae, modelica_metatype _ap, modelica_metatype _inClassName)
{
modelica_metatype _info = NULL;
modelica_metatype _dlow = NULL;
modelica_metatype _initDAE = NULL;
modelica_metatype _initDAE_lambda0 = NULL;
modelica_metatype _inlineData = NULL;
modelica_metatype _removedInitialEquationLst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Config_simulationCg(threadData))
{
tmpMeta[0] = mmc_mk_box3(3, &BackendDAE_ExtraInfo_EXTRA__INFO__desc, omc_DAEUtil_daeDescription(threadData, _dae), omc_AbsynUtil_pathString(threadData, _inClassName, _OMC_LIT97, 1, 0));
_info = tmpMeta[0];
_dlow = omc_BackendDAECreate_lower(threadData, _dae, _inCache, _inEnv, _info);
_dlow = omc_BackendDAEUtil_getSolvedSystem(threadData, _dlow, _OMC_LIT34, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none() ,&_initDAE ,&_initDAE_lambda0 ,&_inlineData ,&_removedInitialEquationLst);
omc_Main_simcodegen(threadData, _dlow, _initDAE, _initDAE_lambda0, _inlineData, _removedInitialEquationLst, _inClassName, _ap);
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Main_instantiate(threadData_t *threadData, modelica_metatype *out_env, modelica_metatype *out_dae, modelica_metatype *out_cname, modelica_string *out_flatString)
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _cname = NULL;
modelica_string _flatString = NULL;
modelica_string _cls = NULL;
modelica_string tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = omc_Config_classToInstantiate(threadData);
_cname = ((stringLength(_cls) == ((modelica_integer) 0))?omc_AbsynUtil_lastClassname(threadData, omc_SymbolTable_getAbsyn(threadData)):omc_AbsynUtil_stringPath(threadData, _cls));
tmpMeta[3] = omc_CevalScriptBackend_runFrontEnd(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), _cname, 1, (omc_Config_flatModelica(threadData) && (!omc_Config_silent(threadData))), &tmpMeta[0], &tmpMeta[1], &tmp1);
_cache = tmpMeta[3];
if (optionNone(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_env = tmpMeta[0];
_dae = tmpMeta[2];
_flatString = tmp1;
_return: OMC_LABEL_UNUSED
if (out_env) { *out_env = _env; }
if (out_dae) { *out_dae = _dae; }
if (out_cname) { *out_cname = _cname; }
if (out_flatString) { *out_flatString = _flatString; }
return _cache;
}
PROTECTED_FUNCTION_STATIC void omc_Main_translateFile(threadData_t *threadData, modelica_metatype _inStringLst)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inStringLst;
{
modelica_metatype _p = NULL;
modelica_metatype _d = NULL;
modelica_string _s = NULL;
modelica_string _f = NULL;
modelica_metatype _libs = NULL;
modelica_metatype _cname = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _funcs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_libs = tmp3_1;
omc_Main_isEmptyOrFirstIsModelicaFile(threadData, _libs);
omc_ExecStat_execStatReset(threadData);
{
modelica_metatype _lib;
for (tmpMeta[0] = _libs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_lib = MMC_CAR(tmpMeta[0]);
omc_Main_loadLib(threadData, _lib);
}
}
omc_Main_showErrors(threadData, omc_Print_getErrorString(threadData), omc_ErrorExt_printMessagesStr(threadData, 0));
if(omc_Flags_isSet(threadData, _OMC_LIT125))
{
omc_Debug_trace(threadData, _OMC_LIT121);
omc_Dump_dump(threadData, omc_SymbolTable_getAbsyn(threadData));
fputs(MMC_STRINGDATA(omc_Print_getString(threadData)),stdout);
}
if(omc_Flags_isSet(threadData, _OMC_LIT130))
{
omc_Debug_trace(threadData, _OMC_LIT126);
tmpMeta[0] = stringAppend(omc_Tpl_tplString(threadData, boxvar_AbsynJLDumpTpl_dump, omc_SymbolTable_getAbsyn(threadData)),_OMC_LIT0);
fputs(MMC_STRINGDATA(tmpMeta[0]),stdout);
}
if(omc_Flags_isSet(threadData, _OMC_LIT134))
{
omc_DumpGraphviz_dump(threadData, omc_SymbolTable_getAbsyn(threadData));
}
omc_ExecStat_execStat(threadData, _OMC_LIT135);
_cache = omc_Main_instantiate(threadData ,&_env ,&_d ,&_cname ,&_s);
_p = omc_SymbolTable_getAbsyn(threadData);
_d = (omc_Flags_isSet(threadData, _OMC_LIT139)?omc_DAEUtil_transformationsBeforeBackend(threadData, _cache, _env, _d):_d);
_funcs = omc_FCore_getFunctionTree(threadData, _cache);
omc_Print_clearBuf(threadData);
omc_ExecStat_execStat(threadData, _OMC_LIT140);
if(((stringLength(_s) == ((modelica_integer) 0)) && (!omc_Config_silent(threadData))))
{
_s = omc_DAEDump_dumpStr(threadData, _d, _funcs);
omc_ExecStat_execStat(threadData, _OMC_LIT141);
}
omc_Print_printBuf(threadData, _s);
if(omc_Flags_isSet(threadData, _OMC_LIT145))
{
omc_DAEDump_dumpGraphviz(threadData, _d);
}
omc_ExecStat_execStat(threadData, _OMC_LIT146);
_d = ((!omc_Flags_isSet(threadData, _OMC_LIT139))?omc_DAEUtil_transformationsBeforeBackend(threadData, _cache, _env, _d):_d);
if((!omc_Config_silent(threadData)))
{
fputs(MMC_STRINGDATA(omc_Print_getString(threadData)),stdout);
}
omc_ExecStat_execStat(threadData, _OMC_LIT147);
omc_Main_optimizeDae(threadData, _cache, _env, _d, _p, _cname);
omc_Main_showErrors(threadData, omc_Print_getErrorString(threadData), omc_ErrorExt_printMessagesStr(threadData, 0));
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
_f = tmpMeta[0];
_libs = tmpMeta[1];
omc_Main_isModelicaScriptFile(threadData, _f);
{
modelica_metatype _lib;
for (tmpMeta[0] = _libs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_lib = MMC_CAR(tmpMeta[0]);
omc_Main_loadLib(threadData, _lib);
}
}
_stmts = omc_Parser_parseexp(threadData, _f);
omc_Main_showErrors(threadData, omc_Print_getErrorString(threadData), omc_ErrorExt_printMessagesStr(threadData, 0));
omc_Interactive_evaluateToStdOut(threadData, _stmts, 1);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
_f = tmpMeta[0];
omc_Main_isCodegenTemplateFile(threadData, _f);
omc_TplMain_main(threadData, _f);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
_f = tmpMeta[0];
if(omc_System_regularFileExists(threadData, _f))
{
fputs(MMC_STRINGDATA(_OMC_LIT149),stdout);
}
else
{
fputs(MMC_STRINGDATA(omc_System_gettext(threadData, _OMC_LIT148)),stdout);
}
fputs(MMC_STRINGDATA(_f),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
omc_Main_showErrors(threadData, omc_Print_getErrorString(threadData), omc_ErrorExt_printMessagesStr(threadData, 0));
goto goto_1;
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
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_loadLib(threadData_t *threadData, modelica_string _inLib)
{
modelica_boolean _is_modelica_file;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_is_modelica_file = omc_Main_isModelicaFile(threadData, _inLib);
{
volatile modelica_boolean tmp3_1;
tmp3_1 = _is_modelica_file;
{
modelica_string _mp = NULL;
modelica_metatype _pnew = NULL;
modelica_metatype _p = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
tmp3 += 2;
_pnew = omc_Parser_parse(threadData, _inLib, _OMC_LIT150, _OMC_LIT34, mmc_mk_none());
_p = omc_SymbolTable_getAbsyn(threadData);
_pnew = omc_InteractiveUtil_mergeProgram(threadData, _pnew, _p);
omc_SymbolTable_setAbsyn(threadData, _pnew);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (0 != tmp3_1) goto tmp2_end;
_path = omc_AbsynUtil_stringPath(threadData, _inLib);
_mp = omc_Settings_getModelicaPath(threadData, omc_Testsuite_isRunning(threadData));
_p = omc_SymbolTable_getAbsyn(threadData);
tmpMeta[1] = mmc_mk_box4(0, _path, _OMC_LIT151, _OMC_LIT153, mmc_mk_boolean(0));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = omc_CevalScript_loadModel(threadData, tmpMeta[0], _mp, _p, 1, 1, 1, 0, 0, &tmp5);
_pnew = tmpMeta[2];
if (1 != tmp5) goto goto_1;
omc_SymbolTable_setAbsyn(threadData, _pnew);
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = stringAppend(_OMC_LIT154,_inLib);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT155);
omc_Print_printErrorBuf(threadData, tmpMeta[1]);
goto goto_1;
goto tmp2_done;
}
case 3: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[0] = stringAppend(_OMC_LIT156,_inLib);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT155);
omc_Print_printErrorBuf(threadData, tmpMeta[1]);
goto goto_1;
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
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_showErrors(threadData_t *threadData, modelica_string _errorString, modelica_string _errorMessages)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!stringEqual(_errorString, _OMC_LIT34)))
{
fputs(MMC_STRINGDATA(_errorString),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
}
if((!stringEqual(_errorMessages, _OMC_LIT34)))
{
fputs(MMC_STRINGDATA(_errorMessages),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_isCodegenTemplateFile(threadData_t *threadData, modelica_string _filename)
{
modelica_metatype _lst = NULL;
modelica_string _last = NULL;
modelica_boolean tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lst = omc_System_strtok(threadData, _filename, _OMC_LIT97);
tmpMeta[0] = listReverse(_lst);
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_last = tmpMeta[1];
tmp1 = (stringEqual(_last, _OMC_LIT157));
if (1 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_isModelicaScriptFile(threadData_t *threadData, modelica_string _filename)
{
modelica_metatype _lst = NULL;
modelica_string _last = NULL;
modelica_boolean tmp1;
modelica_boolean tmp2;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = omc_System_regularFileExists(threadData, _filename);
if (1 != tmp1) MMC_THROW_INTERNAL();
_lst = omc_System_strtok(threadData, _filename, _OMC_LIT97);
tmpMeta[0] = listReverse(_lst);
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_last = tmpMeta[1];
tmp2 = (stringEqual(_last, _OMC_LIT158));
if (1 != tmp2) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_isFlatModelicaFile(threadData_t *threadData, modelica_string _filename)
{
modelica_metatype _lst = NULL;
modelica_string _last = NULL;
modelica_boolean tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lst = omc_System_strtok(threadData, _filename, _OMC_LIT97);
tmpMeta[0] = listReverse(_lst);
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_last = tmpMeta[1];
tmp1 = (stringEqual(_last, _OMC_LIT159));
if (1 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Main_isEmptyOrFirstIsModelicaFile(threadData_t *threadData, modelica_metatype _libs)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _libs;
{
modelica_string _f = NULL;
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
modelica_boolean tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
_f = tmpMeta[0];
tmp5 = omc_Main_isModelicaFile(threadData, _f);
if (1 != tmp5) goto goto_1;
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
PROTECTED_FUNCTION_STATIC modelica_boolean omc_Main_isModelicaFile(threadData_t *threadData, modelica_string _inFilename)
{
modelica_boolean _outIsModelicaFile;
modelica_metatype _lst = NULL;
modelica_string _file_ext = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lst = omc_System_strtok(threadData, _inFilename, _OMC_LIT97);
if(listEmpty(_lst))
{
_outIsModelicaFile = 0;
}
else
{
_file_ext = omc_List_last(threadData, _lst);
_outIsModelicaFile = ((stringEqual(_file_ext, _OMC_LIT160)) || (stringEqual(_file_ext, _OMC_LIT159)));
}
_return: OMC_LABEL_UNUSED
return _outIsModelicaFile;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Main_isModelicaFile(threadData_t *threadData, modelica_metatype _inFilename)
{
modelica_boolean _outIsModelicaFile;
modelica_metatype out_outIsModelicaFile;
_outIsModelicaFile = omc_Main_isModelicaFile(threadData, _inFilename);
out_outIsModelicaFile = mmc_mk_icon(_outIsModelicaFile);
return out_outIsModelicaFile;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_makeClassDefResult(threadData_t *threadData, modelica_metatype _p)
{
modelica_string _res = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
modelica_metatype _names = NULL;
modelica_metatype _scope = NULL;
modelica_metatype _cls = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cls = tmpMeta[0];
_scope = tmpMeta[2];
_names = omc_List_map(threadData, _cls, boxvar_AbsynUtil_className);
_names = omc_List_map1(threadData, _names, boxvar_AbsynUtil_joinPaths, _scope);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp6;
modelica_string __omcQ_24tmpVar0;
int tmp7;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _names;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp6 = &__omcQ_24tmpVar1;
while(1) {
tmp7 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp7--;
}
if (tmp7 == 0) {
__omcQ_24tmpVar0 = omc_AbsynUtil_pathString(threadData, _n, _OMC_LIT97, 1, 0);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp7 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
tmpMeta[2] = stringAppend(_OMC_LIT161,stringDelimitList(tmpMeta[0], _OMC_LIT162));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT163);
tmp1 = tmpMeta[3];
goto tmp3_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp3_end;
_cls = tmpMeta[0];
_names = omc_List_map(threadData, _cls, boxvar_AbsynUtil_className);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp8;
modelica_string __omcQ_24tmpVar2;
int tmp9;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _names;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[1];
tmp8 = &__omcQ_24tmpVar3;
while(1) {
tmp9 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar2 = omc_AbsynUtil_pathString(threadData, _n, _OMC_LIT97, 1, 0);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar3;
}
tmpMeta[2] = stringAppend(_OMC_LIT161,stringDelimitList(tmpMeta[0], _OMC_LIT162));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT163);
tmp1 = tmpMeta[3];
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_handleCommand2(threadData_t *threadData, modelica_metatype _inStatements, modelica_metatype _inProgram, modelica_string _inCommand)
{
modelica_string _outResult = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inStatements;
tmp4_2 = _inProgram;
{
modelica_metatype _stmts = NULL;
modelica_metatype _prog = NULL;
modelica_metatype _prog2 = NULL;
modelica_metatype _ast = NULL;
modelica_string _result = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _table = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (!optionNone(tmp4_2)) goto tmp3_end;
_stmts = tmpMeta[0];
tmp4 += 2;
tmp1 = omc_Interactive_evaluate(threadData, _stmts, 0);
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_prog = tmpMeta[0];
tmp4 += 1;
_table = omc_SymbolTable_get(threadData);
_ast = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 2)));
_vars = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_table), 4)));
_prog2 = omc_InteractiveUtil_addScope(threadData, _prog, _vars);
_prog2 = omc_InteractiveUtil_updateProgram(threadData, _prog2, _ast, 0);
if(omc_Flags_isSet(threadData, _OMC_LIT125))
{
omc_Debug_trace(threadData, _OMC_LIT121);
omc_Dump_dump(threadData, _prog2);
}
if(omc_Flags_isSet(threadData, _OMC_LIT134))
{
omc_DumpGraphviz_dump(threadData, _prog2);
}
_result = omc_Main_makeClassDefResult(threadData, _prog);
omc_SymbolTable_setAbsyn(threadData, _prog2);
tmp1 = _result;
goto tmp3_done;
}
case 2: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
omc_Print_printBuf(threadData, _OMC_LIT164);
_result = omc_Print_getString(threadData);
tmpMeta[0] = stringAppend(_result,_OMC_LIT165);
_result = tmpMeta[0];
tmpMeta[0] = stringAppend(_result,omc_Error_printMessagesStr(threadData, 0));
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 3: {
modelica_boolean tmp6;
tmp6 = (isSome(_inStatements) || isSome(_inProgram));
if (1 != tmp6) goto goto_2;
tmp1 = omc_Error_printMessagesStr(threadData, 0);
goto tmp3_done;
}
case 4: {
modelica_boolean tmp7;
tmp7 = (isSome(_inStatements) || isSome(_inProgram));
if (1 != tmp7) goto goto_2;
tmpMeta[0] = mmc_mk_cons(_inCommand, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT168, tmpMeta[0]);
tmp1 = _OMC_LIT34;
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
if (++tmp4 < 5) {
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
DLLExport
modelica_boolean omc_Main_handleCommand(threadData_t *threadData, modelica_string _inCommand, modelica_string *out_outResult)
{
modelica_boolean _outContinue;
modelica_string _outResult = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _prog = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Print_clearBuf(threadData);
if(omc_Util_strncmp(threadData, _OMC_LIT170, _inCommand, ((modelica_integer) 6)))
{
_outContinue = 0;
_outResult = _OMC_LIT169;
}
else
{
_outContinue = 1;
_stmts = omc_Main_parseCommand(threadData, _inCommand ,&_prog);
_outResult = omc_Main_handleCommand2(threadData, _stmts, _prog, _inCommand);
_outResult = omc_Main_makeDebugResult(threadData, _OMC_LIT125, _outResult);
_outResult = omc_Main_makeDebugResult(threadData, _OMC_LIT134, _outResult);
}
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outContinue;
}
modelica_metatype boxptr_Main_handleCommand(threadData_t *threadData, modelica_metatype _inCommand, modelica_metatype *out_outResult)
{
modelica_boolean _outContinue;
modelica_metatype out_outContinue;
_outContinue = omc_Main_handleCommand(threadData, _inCommand, out_outResult);
out_outContinue = mmc_mk_icon(_outContinue);
return out_outContinue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Main_parseCommand(threadData_t *threadData, modelica_string _inCommand, modelica_metatype *out_outProgram)
{
modelica_metatype _outStatements = NULL;
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _stmts = NULL;
modelica_metatype _prog = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT171);
_stmts = omc_Parser_parsestringexp(threadData, _inCommand, _OMC_LIT172);
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT171);
tmpMeta[0+0] = mmc_mk_some(_stmts);
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 1: {
omc_ErrorExt_rollBack(threadData, _OMC_LIT171);
_prog = omc_Parser_parsestring(threadData, _inCommand, _OMC_LIT172);
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_some(_prog);
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_none();
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
_outStatements = tmpMeta[0+0];
_outProgram = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outProgram) { *out_outProgram = _outProgram; }
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Main_makeDebugResult(threadData_t *threadData, modelica_metatype _inFlag, modelica_string _res)
{
modelica_string _res_1 = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inFlag;
{
modelica_string _debugstr = NULL;
modelica_string _flagstr = NULL;
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
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_flagstr = tmpMeta[0];
tmp6 = omc_Flags_isSet(threadData, _inFlag);
if (1 != tmp6) goto goto_2;
_debugstr = omc_Print_getString(threadData);
tmpMeta[0] = mmc_mk_cons(_res, mmc_mk_cons(_OMC_LIT173, mmc_mk_cons(_flagstr, mmc_mk_cons(_OMC_LIT174, mmc_mk_cons(_debugstr, mmc_mk_cons(_OMC_LIT175, mmc_mk_cons(_flagstr, mmc_mk_cons(_OMC_LIT174, MMC_REFSTRUCTLIT(mmc_nil)))))))));
tmp1 = stringAppendList(tmpMeta[0]);
goto tmp3_done;
}
case 1: {
tmp1 = _res;
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
_res_1 = tmp1;
_return: OMC_LABEL_UNUSED
return _res_1;
}

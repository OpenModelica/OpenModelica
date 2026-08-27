#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ClassLoader.c"
#endif
#include "omc_simulation_settings.h"
#include "ClassLoader.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,2,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,4) {&Gettext_TranslatableContent_notrans__desc,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(6002)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "__OpenModelica_messageOnLoad"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,28,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,4) {&ErrorTypes_MessageType_GRAMMAR__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "Components referenced in the package.order file must be moved in full chunks. Either split the constants to different lines or make them subsequent in the package.order file."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,174,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(241)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT12}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "Elements in the package.mo-file need to be in the same relative order as the package.order file. Got element named %s but it was already added because it was not the next element in the list at that time."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,204,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(237)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT15}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Got element %1 that was not referenced in the package.order file."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,65,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(240)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,1,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "package.moc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,11,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "package.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,10,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data ".moc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,4,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data ".mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,3,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "%1 was referenced in the package.order file, but was not found in package.mo, %1/package.mo or %1.mo."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,101,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(239)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "The package.order file contains a class %s, which is expected to be stored in file %s, but seems to be named %s. Proceeding since only the case of the names are different."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,171,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(354)),_OMC_LIT1,_OMC_LIT10,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,1,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,2,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "Found duplicate names in package.order file: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,48,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT34}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(247)),_OMC_LIT33,_OMC_LIT10,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT37,0.0);
#define _OMC_LIT37 MMC_REFREALLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "The same class is defined in multiple files: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,48,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(540)),_OMC_LIT33,_OMC_LIT38,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "\n	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,2,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "The package.order file does not list all .mo files and directories (containing package.mo) present in its directory.\nMissing names are:\n	%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,139,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(530)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,17,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT33,_OMC_LIT38,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "getPackageContentNames failed for unknown reason"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,48,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,1) {_OMC_LIT49,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "/package.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,11,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "Modelica library files should contain exactly one package, but found the following classes: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,95,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT52}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(234)),_OMC_LIT9,_OMC_LIT38,_OMC_LIT53}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "Expected the package to have name %s, but got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,49,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(236)),_OMC_LIT1,_OMC_LIT38,_OMC_LIT56}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "Expected the package to have name %s, but got %s. Proceeding since only the case of the names are different."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,108,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT58}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(353)),_OMC_LIT1,_OMC_LIT10,_OMC_LIT59}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "Expected the package to have %s but got %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,43,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT61}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(235)),_OMC_LIT9,_OMC_LIT38,_OMC_LIT62}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "Expected the package to have %s but got %s (ignoring the potential error; the class might have been inserted at an unexpected location)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,136,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(363)),_OMC_LIT9,_OMC_LIT10,_OMC_LIT65}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "%s is a package.mo-file and needs to be based on class parts (i.e. not class extends, derived class, or enumeration)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,117,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(238)),_OMC_LIT9,_OMC_LIT38,_OMC_LIT68}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "/package.moc"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,12,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "Expected file "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,14,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data " to exist"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,9,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/ClassLoader.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,72,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT74_6,1602262265.0);
#define _OMC_LIT74_6 MMC_REFREALLIT(_OMC_LIT_STRUCT74_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(373)),MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),MMC_IMMEDIATE(MMC_TAGFIXNUM(373)),MMC_IMMEDIATE(MMC_TAGFIXNUM(88)),_OMC_LIT74_6}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "package.order"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,13,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT76_6,1602262265.0);
#define _OMC_LIT76_6 MMC_REFREALLIT(_OMC_LIT_STRUCT76_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(288)),MMC_IMMEDIATE(MMC_TAGFIXNUM(11)),MMC_IMMEDIATE(MMC_TAGFIXNUM(288)),MMC_IMMEDIATE(MMC_TAGFIXNUM(93)),_OMC_LIT76_6}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "loadCompletePackageFromMp failed for unknown reason: mp="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,56,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data " pack="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,6,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT79_6,1602262265.0);
#define _OMC_LIT79_6 MMC_REFREALLIT(_OMC_LIT_STRUCT79_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(302)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(302)),MMC_IMMEDIATE(MMC_TAGFIXNUM(128)),_OMC_LIT79_6}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "package.encoding"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,16,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "UTF-8"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,5,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,1,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,1,4) {&Absyn_Within_TOP__desc,}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,7,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "  installPackage("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,17,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data ", \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,3,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "\", exactMatch=false)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,20,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "\", exactMatch="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,14,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,1,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "\", exactMatch=true)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,19,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "You can install the requested package using one of the commands:\n%s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,68,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT91}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(279)),_OMC_LIT1,_OMC_LIT2,_OMC_LIT92}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,1,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,9,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,41,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT96}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT95,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT97}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "ClassLoader.loadClass failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,29,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
#include "util/modelica.h"
#include "ClassLoader_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getProgramFromStrategy(threadData_t *threadData, modelica_string _filename, modelica_metatype _strategy);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getProgramFromStrategy,2,0) {(void*) boxptr_ClassLoader_getProgramFromStrategy,0}};
#define boxvar_ClassLoader_getProgramFromStrategy MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getProgramFromStrategy)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ClassLoader_checkOnLoadMessageWork(threadData_t *threadData, modelica_metatype _mod);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_checkOnLoadMessageWork(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_checkOnLoadMessageWork,2,0) {(void*) boxptr_ClassLoader_checkOnLoadMessageWork,0}};
#define boxvar_ClassLoader_checkOnLoadMessageWork MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_checkOnLoadMessageWork)
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassLoader_packageOrderName(threadData_t *threadData, modelica_metatype _ord);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_packageOrderName,2,0) {(void*) boxptr_ClassLoader_packageOrderName,0}};
#define boxvar_ClassLoader_packageOrderName MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_packageOrderName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_matchCompNames(threadData_t *threadData, modelica_metatype _names, modelica_metatype _comps, modelica_metatype _info, modelica_boolean *out_matchedNames);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_matchCompNames(threadData_t *threadData, modelica_metatype _names, modelica_metatype _comps, modelica_metatype _info, modelica_metatype *out_matchedNames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_matchCompNames,2,0) {(void*) boxptr_ClassLoader_matchCompNames,0}};
#define boxvar_ClassLoader_matchCompNames MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_matchCompNames)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNamesinElts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _inElts, modelica_metatype _po, modelica_boolean _pub, modelica_metatype *out_outNames);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getPackageContentNamesinElts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _inElts, modelica_metatype _po, modelica_metatype _pub, modelica_metatype *out_outNames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNamesinElts,2,0) {(void*) boxptr_ClassLoader_getPackageContentNamesinElts,0}};
#define boxvar_ClassLoader_getPackageContentNamesinElts MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNamesinElts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNamesinParts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _cps, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNamesinParts,2,0) {(void*) boxptr_ClassLoader_getPackageContentNamesinParts,0}};
#define boxvar_ClassLoader_getPackageContentNamesinParts MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNamesinParts)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ClassLoader_existPackage(threadData_t *threadData, modelica_string _name, modelica_string _mp, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_existPackage(threadData_t *threadData, modelica_metatype _name, modelica_metatype _mp, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_existPackage,2,0) {(void*) boxptr_ClassLoader_existPackage,0}};
#define boxvar_ClassLoader_existPackage MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_existPackage)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_checkPackageOrderFilesExist(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpo, modelica_string _mp, modelica_metatype _info, modelica_boolean _encrypted, modelica_metatype __omcQ_24in_5Fdifferences, modelica_metatype *out_differences);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_checkPackageOrderFilesExist(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpo, modelica_metatype _mp, modelica_metatype _info, modelica_metatype _encrypted, modelica_metatype __omcQ_24in_5Fdifferences, modelica_metatype *out_differences);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_checkPackageOrderFilesExist,2,0) {(void*) boxptr_ClassLoader_checkPackageOrderFilesExist,0}};
#define boxvar_ClassLoader_checkPackageOrderFilesExist MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_checkPackageOrderFilesExist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeClassLoad(threadData_t *threadData, modelica_string _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_makeClassLoad,2,0) {(void*) boxptr_ClassLoader_makeClassLoad,0}};
#define boxvar_ClassLoader_makeClassLoad MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_makeClassLoad)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeElement(threadData_t *threadData, modelica_metatype _el, modelica_boolean _pub);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_makeElement(threadData_t *threadData, modelica_metatype _el, modelica_metatype _pub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_makeElement,2,0) {(void*) boxptr_ClassLoader_makeElement,0}};
#define boxvar_ClassLoader_makeElement MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_makeElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeClassPart(threadData_t *threadData, modelica_metatype _part);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_makeClassPart,2,0) {(void*) boxptr_ClassLoader_makeClassPart,0}};
#define boxvar_ClassLoader_makeClassPart MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_makeClassPart)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNames(threadData_t *threadData, modelica_metatype _cl, modelica_string _filename, modelica_string _mp, modelica_integer _numError, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getPackageContentNames(threadData_t *threadData, modelica_metatype _cl, modelica_metatype _filename, modelica_metatype _mp, modelica_metatype _numError, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNames,2,0) {(void*) boxptr_ClassLoader_getPackageContentNames,0}};
#define boxvar_ClassLoader_getPackageContentNames MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getPackageContentNames)
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassLoader_getBothPackageAndFilename(threadData_t *threadData, modelica_string _str, modelica_string _mp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getBothPackageAndFilename,2,0) {(void*) boxptr_ClassLoader_getBothPackageAndFilename,0}};
#define boxvar_ClassLoader_getBothPackageAndFilename MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getBothPackageAndFilename)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp2(threadData_t *threadData, modelica_metatype _po, modelica_string _mp, modelica_metatype _strategy, modelica_metatype _w1, modelica_boolean _encrypted, modelica_metatype _acc);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadCompletePackageFromMp2(threadData_t *threadData, modelica_metatype _po, modelica_metatype _mp, modelica_metatype _strategy, modelica_metatype _w1, modelica_metatype _encrypted, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_loadCompletePackageFromMp2,2,0) {(void*) boxptr_ClassLoader_loadCompletePackageFromMp2,0}};
#define boxvar_ClassLoader_loadCompletePackageFromMp2 MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_loadCompletePackageFromMp2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_mergeBefore(threadData_t *threadData, modelica_metatype _cp, modelica_metatype _cps);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_mergeBefore,2,0) {(void*) boxptr_ClassLoader_mergeBefore,0}};
#define boxvar_ClassLoader_mergeBefore MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_mergeBefore)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp(threadData_t *threadData, modelica_string _id, modelica_string _inIdent, modelica_string _inString, modelica_metatype _strategy, modelica_metatype _inWithin, modelica_integer _numError, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadCompletePackageFromMp(threadData_t *threadData, modelica_metatype _id, modelica_metatype _inIdent, modelica_metatype _inString, modelica_metatype _strategy, modelica_metatype _inWithin, modelica_metatype _numError, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_loadCompletePackageFromMp,2,0) {(void*) boxptr_ClassLoader_loadCompletePackageFromMp,0}};
#define boxvar_ClassLoader_loadCompletePackageFromMp MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_loadCompletePackageFromMp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getAllFilesFromDirectory(threadData_t *threadData, modelica_string _dir, modelica_boolean _encrypted, modelica_metatype _acc);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getAllFilesFromDirectory(threadData_t *threadData, modelica_metatype _dir, modelica_metatype _encrypted, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_getAllFilesFromDirectory,2,0) {(void*) boxptr_ClassLoader_getAllFilesFromDirectory,0}};
#define boxvar_ClassLoader_getAllFilesFromDirectory MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_getAllFilesFromDirectory)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_string _id, modelica_string _path, modelica_string _name, modelica_boolean _isDir, modelica_metatype _optEncoding, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_metatype _id, modelica_metatype _path, modelica_metatype _name, modelica_metatype _isDir, modelica_metatype _optEncoding, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMp,2,0) {(void*) boxptr_ClassLoader_loadClassFromMp,0}};
#define boxvar_ClassLoader_loadClassFromMp MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_string _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_boolean _requireExactVersion, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_metatype _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_metatype _requireExactVersion, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMps,2,0) {(void*) boxptr_ClassLoader_loadClassFromMps,0}};
#define boxvar_ClassLoader_loadClassFromMps MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getProgramFromStrategy(threadData_t *threadData, modelica_string _filename, modelica_metatype _strategy)
{
modelica_metatype _program = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _strategy;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[0] = omc_BaseHashTable_get(threadData, _filename, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_strategy), 2))));
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[0] = omc_Parser_parse(threadData, _filename, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_strategy), 2))), _OMC_LIT0, mmc_mk_none());
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
_program = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _program;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ClassLoader_checkOnLoadMessageWork(threadData_t *threadData, modelica_metatype _mod)
{
modelica_integer _dummy;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
modelica_string _str = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_str = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT5, tmpMeta[0], _info);
tmp1 = ((modelica_integer) 1);
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
_dummy = tmp1;
_return: OMC_LABEL_UNUSED
return _dummy;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_checkOnLoadMessageWork(threadData_t *threadData, modelica_metatype _mod)
{
modelica_integer _dummy;
modelica_metatype out_dummy;
_dummy = omc_ClassLoader_checkOnLoadMessageWork(threadData, _mod);
out_dummy = mmc_mk_icon(_dummy);
return out_dummy;
}
DLLExport
void omc_ClassLoader_checkOnLoadMessage(threadData_t *threadData, modelica_metatype _p1)
{
modelica_metatype _classes = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _p1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_classes = tmpMeta[1];
omc_List_map2(threadData, _classes, boxvar_AbsynUtil_getNamedAnnotationInClass, _OMC_LIT7, boxvar_ClassLoader_checkOnLoadMessageWork);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassLoader_packageOrderName(threadData_t *threadData, modelica_metatype _ord)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ord;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta[0];
tmp1 = _name;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT8;
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
_name = tmp1;
_return: OMC_LABEL_UNUSED
return _name;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_matchCompNames(threadData_t *threadData, modelica_metatype _names, modelica_metatype _comps, modelica_metatype _info, modelica_boolean *out_matchedNames)
{
modelica_metatype _outNames = NULL;
modelica_boolean _matchedNames;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _names;
tmp4_2 = _comps;
{
modelica_boolean _b;
modelica_boolean _b1;
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_metatype _rest1 = NULL;
modelica_metatype _rest2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0+0] = _names;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_2);
tmpMeta[5] = MMC_CDR(tmp4_2);
_n1 = tmpMeta[2];
_rest1 = tmpMeta[3];
_n2 = tmpMeta[4];
_rest2 = tmpMeta[5];
if((stringEqual(_n1, _n2)))
{
_rest1 = omc_ClassLoader_matchCompNames(threadData, _rest1, _rest2, _info ,&_b);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_assertionOrAddSourceMessage(threadData, _b, _OMC_LIT13, tmpMeta[2], _info);
_b1 = 1;
}
else
{
_b1 = 0;
}
tmpMeta[0+0] = _rest1;
tmp1_c1 = _b1;
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
_outNames = tmpMeta[0+0];
_matchedNames = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_matchedNames) { *out_matchedNames = _matchedNames; }
return _outNames;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_matchCompNames(threadData_t *threadData, modelica_metatype _names, modelica_metatype _comps, modelica_metatype _info, modelica_metatype *out_matchedNames)
{
modelica_boolean _matchedNames;
modelica_metatype _outNames = NULL;
_outNames = omc_ClassLoader_matchCompNames(threadData, _names, _comps, _info, &_matchedNames);
if (out_matchedNames) { *out_matchedNames = mmc_mk_icon(_matchedNames); }
return _outNames;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNamesinElts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _inElts, modelica_metatype _po, modelica_boolean _pub, modelica_metatype *out_outNames)
{
modelica_metatype _outOrder = NULL;
modelica_metatype _outNames = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inNamesToSort;
tmp4_2 = _inElts;
{
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_metatype _namesToSort = NULL;
modelica_metatype _names = NULL;
modelica_metatype _compNames = NULL;
modelica_metatype _elts = NULL;
modelica_boolean _b;
modelica_metatype _info = NULL;
modelica_metatype _comps = NULL;
modelica_metatype _ei = NULL;
modelica_metatype _orderElt = NULL;
modelica_metatype _load = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_namesToSort = tmp4_1;
tmpMeta[0+0] = _po;
tmpMeta[0+1] = _namesToSort;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_2);
tmpMeta[5] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,6) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],3,3) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
_name1 = tmpMeta[2];
_ei = tmpMeta[4];
_comps = tmpMeta[8];
_info = tmpMeta[9];
_elts = tmpMeta[5];
_compNames = omc_List_map(threadData, _comps, boxvar_AbsynUtil_componentName);
_names = omc_ClassLoader_matchCompNames(threadData, _inNamesToSort, _compNames, _info ,&_b);
_orderElt = (_b?omc_ClassLoader_makeElement(threadData, _ei, _pub):omc_ClassLoader_makeClassLoad(threadData, _name1));
tmpMeta[2] = mmc_mk_cons(_orderElt, _po);
_inNamesToSort = _names;
_inElts = (_b?_elts:_inElts);
_po = tmpMeta[2];
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_2);
tmpMeta[5] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,6) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,2) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 8));
_name1 = tmpMeta[2];
_namesToSort = tmpMeta[3];
_ei = tmpMeta[4];
_name2 = tmpMeta[9];
_info = tmpMeta[10];
_elts = tmpMeta[5];
_load = omc_ClassLoader_makeClassLoad(threadData, _name1);
_b = (stringEqual(_name1, _name2));
tmpMeta[2] = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (_b?(!listMember(_load, _po)):1), _OMC_LIT16, tmpMeta[2], _info);
_orderElt = (_b?omc_ClassLoader_makeElement(threadData, _ei, _pub):_load);
tmpMeta[2] = mmc_mk_cons(_orderElt, _po);
_inNamesToSort = _namesToSort;
_inElts = (_b?_elts:_inElts);
_po = tmpMeta[2];
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,6) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,2) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 8));
_name2 = tmpMeta[7];
_info = tmpMeta[8];
_load = omc_ClassLoader_makeClassLoad(threadData, _name2);
tmpMeta[2] = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (!listMember(_load, _po)), _OMC_LIT16, tmpMeta[2], _info);
tmpMeta[2] = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT19, tmpMeta[2], _info);
tmpMeta[2] = mmc_mk_cons(_name2, _inNamesToSort);
_inNamesToSort = tmpMeta[2];
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,6) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],3,3) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 6));
_name2 = tmpMeta[10];
_info = tmpMeta[11];
_load = omc_ClassLoader_makeClassLoad(threadData, _name2);
tmpMeta[2] = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (!listMember(_load, _po)), _OMC_LIT16, tmpMeta[2], _info);
tmpMeta[2] = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT19, tmpMeta[2], _info);
tmpMeta[2] = mmc_mk_cons(_name2, _inNamesToSort);
_inNamesToSort = tmpMeta[2];
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
_ei = tmpMeta[2];
_elts = tmpMeta[3];
_namesToSort = tmp4_1;
tmpMeta[3] = mmc_mk_box3(4, &ClassLoader_PackageOrder_ELEMENT__desc, _ei, mmc_mk_boolean(_pub));
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _po);
_inNamesToSort = _namesToSort;
_inElts = _elts;
_po = tmpMeta[2];
goto _tailrecursive;
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
_outOrder = tmpMeta[0+0];
_outNames = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outNames) { *out_outNames = _outNames; }
return _outOrder;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getPackageContentNamesinElts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _inElts, modelica_metatype _po, modelica_metatype _pub, modelica_metatype *out_outNames)
{
modelica_integer tmp1;
modelica_metatype _outOrder = NULL;
tmp1 = mmc_unbox_integer(_pub);
_outOrder = omc_ClassLoader_getPackageContentNamesinElts(threadData, _inNamesToSort, _inElts, _po, tmp1, out_outNames);
return _outOrder;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNamesinParts(threadData_t *threadData, modelica_metatype _inNamesToSort, modelica_metatype _cps, modelica_metatype _acc)
{
modelica_metatype _outOrder = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inNamesToSort;
tmp3_2 = _cps;
{
modelica_metatype _rcp = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _namesToSort = NULL;
modelica_metatype _cp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_namesToSort = tmp3_1;
tmpMeta[0] = listAppend(omc_List_mapReverse(threadData, _namesToSort, boxvar_ClassLoader_makeClassLoad), _acc);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[3];
_rcp = tmpMeta[2];
_namesToSort = tmp3_1;
_outOrder = omc_ClassLoader_getPackageContentNamesinElts(threadData, _namesToSort, _elts, _acc, 1 ,&_namesToSort);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = _outOrder;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[3];
_rcp = tmpMeta[2];
_namesToSort = tmp3_1;
_outOrder = omc_ClassLoader_getPackageContentNamesinElts(threadData, _namesToSort, _elts, _acc, 0 ,&_namesToSort);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = _outOrder;
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_cp = tmpMeta[1];
_rcp = tmpMeta[2];
_namesToSort = tmp3_1;
tmpMeta[2] = mmc_mk_box2(3, &ClassLoader_PackageOrder_CLASSPART__desc, _cp);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _acc);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = tmpMeta[1];
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
_outOrder = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outOrder;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ClassLoader_existPackage(threadData_t *threadData, modelica_string _name, modelica_string _mp, modelica_boolean _encrypted)
{
modelica_boolean _b;
modelica_string _pd = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pd = _OMC_LIT20;
tmpMeta[0] = stringAppend(_mp,_pd);
tmpMeta[1] = stringAppend(tmpMeta[0],_name);
tmpMeta[2] = stringAppend(tmpMeta[1],_pd);
tmpMeta[3] = stringAppend(tmpMeta[2],(_encrypted?_OMC_LIT21:_OMC_LIT22));
_b = omc_System_regularFileExists(threadData, tmpMeta[3]);
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_existPackage(threadData_t *threadData, modelica_metatype _name, modelica_metatype _mp, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_boolean _b;
modelica_metatype out_b;
tmp1 = mmc_unbox_integer(_encrypted);
_b = omc_ClassLoader_existPackage(threadData, _name, _mp, tmp1);
out_b = mmc_mk_icon(_b);
return out_b;
}
static modelica_metatype closure0_Util_stringEqCaseInsensitive(threadData_t *thData, modelica_metatype closure, modelica_string str1)
{
modelica_string str2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_Util_stringEqCaseInsensitive(thData, str1, str2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_checkPackageOrderFilesExist(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpo, modelica_string _mp, modelica_metatype _info, modelica_boolean _encrypted, modelica_metatype __omcQ_24in_5Fdifferences, modelica_metatype *out_differences)
{
modelica_metatype _po = NULL;
modelica_metatype _differences = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_po = __omcQ_24in_5Fpo;
_differences = __omcQ_24in_5Fdifferences;
{
modelica_metatype tmp3_1;
tmp3_1 = _po;
{
modelica_string _pd = NULL;
modelica_string _str = NULL;
modelica_string _str2 = NULL;
modelica_string _str3 = NULL;
modelica_string _str4 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_str = tmpMeta[0];
_pd = _OMC_LIT20;
tmpMeta[0] = stringAppend(_str,(_encrypted?_OMC_LIT23:_OMC_LIT24));
_str2 = tmpMeta[0];
tmpMeta[0] = stringAppend(_mp,_pd);
tmpMeta[1] = stringAppend(tmpMeta[0],_str);
tmpMeta[2] = stringAppend(_mp,_pd);
tmpMeta[3] = stringAppend(tmpMeta[2],_str2);
if((!(omc_System_directoryExists(threadData, tmpMeta[1]) || omc_System_regularFileExists(threadData, tmpMeta[3]))))
{
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
tmpMeta[4] = mmc_mk_box1(0, omc_System_tolower(threadData, _str2));
_str3 = omc_List_find(threadData, omc_System_moFiles(threadData, _mp), (modelica_fnptr) mmc_mk_box2(0,closure0_Util_stringEqCaseInsensitive,tmpMeta[4]));
goto tmp6_done;
}
case 1: {
tmpMeta[4] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT27, tmpMeta[4], _info);
goto goto_5;
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
tmpMeta[4] = mmc_mk_cons(_str, mmc_mk_cons(_str2, mmc_mk_cons(_str3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT30, tmpMeta[4], _info);
_str4 = omc_Util_removeLastNChar(threadData, _str3, (_encrypted?((modelica_integer) 4):((modelica_integer) 3)));
_differences = omc_List_removeOnTrue(threadData, _str4, boxvar_stringEq, _differences);
tmpMeta[4] = mmc_mk_box2(5, &ClassLoader_PackageOrder_CLASSLOAD__desc, _str4);
_po = tmpMeta[4];
}
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
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
if (out_differences) { *out_differences = _differences; }
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_checkPackageOrderFilesExist(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpo, modelica_metatype _mp, modelica_metatype _info, modelica_metatype _encrypted, modelica_metatype __omcQ_24in_5Fdifferences, modelica_metatype *out_differences)
{
modelica_integer tmp1;
modelica_metatype _po = NULL;
tmp1 = mmc_unbox_integer(_encrypted);
_po = omc_ClassLoader_checkPackageOrderFilesExist(threadData, __omcQ_24in_5Fpo, _mp, _info, tmp1, __omcQ_24in_5Fdifferences, out_differences);
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeClassLoad(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box2(5, &ClassLoader_PackageOrder_CLASSLOAD__desc, _str);
_po = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeElement(threadData_t *threadData, modelica_metatype _el, modelica_boolean _pub)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box3(4, &ClassLoader_PackageOrder_ELEMENT__desc, _el, mmc_mk_boolean(_pub));
_po = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_makeElement(threadData_t *threadData, modelica_metatype _el, modelica_metatype _pub)
{
modelica_integer tmp1;
modelica_metatype _po = NULL;
tmp1 = mmc_unbox_integer(_pub);
_po = omc_ClassLoader_makeElement(threadData, _el, tmp1);
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeClassPart(threadData_t *threadData, modelica_metatype _part)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box2(3, &ClassLoader_PackageOrder_CLASSPART__desc, _part);
_po = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNames(threadData_t *threadData, modelica_metatype _cl, modelica_string _filename, modelica_string _mp, modelica_integer _numError, modelica_boolean _encrypted)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
modelica_string _contents = NULL;
modelica_string _duplicatesStr = NULL;
modelica_string _differencesStr = NULL;
modelica_metatype _duplicates = NULL;
modelica_metatype _namesToFind = NULL;
modelica_metatype _mofiles = NULL;
modelica_metatype _subdirs = NULL;
modelica_metatype _differences = NULL;
modelica_metatype _intersection = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _info = NULL;
modelica_metatype _po1 = NULL;
modelica_metatype _po2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_cp = tmpMeta[2];
_info = tmpMeta[3];
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
modelica_boolean tmp9;
tmp9 = omc_System_regularFileExists(threadData, _filename);
if (1 != tmp9) goto goto_5;
_contents = omc_System_readFile(threadData, _filename);
_namesToFind = omc_System_strtok(threadData, _contents, _OMC_LIT31);
_namesToFind = omc_List_removeOnTrue(threadData, _OMC_LIT0, boxvar_stringEqual, omc_List_map(threadData, _namesToFind, boxvar_System_trimWhitespace));
_duplicates = omc_List_sortedDuplicates(threadData, omc_List_sort(threadData, _namesToFind, boxvar_Util_strcmpBool), boxvar_stringEq);
_duplicatesStr = stringDelimitList(_duplicates, _OMC_LIT32);
tmpMeta[1] = mmc_mk_cons(_duplicatesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_duplicates), _OMC_LIT36, tmpMeta[1], tmpMeta[2]);
if(_encrypted)
{
_mofiles = omc_List_map(threadData, omc_System_mocFiles(threadData, _mp), boxvar_Util_removeLast4Char);
}
else
{
_mofiles = omc_List_map(threadData, omc_System_moFiles(threadData, _mp), boxvar_Util_removeLast3Char);
}
_subdirs = omc_System_subDirectories(threadData, _mp);
_subdirs = omc_List_filter2OnTrue(threadData, _subdirs, boxvar_ClassLoader_existPackage, _mp, mmc_mk_boolean(_encrypted));
_intersection = omc_List_intersectionOnTrue(threadData, _subdirs, _mofiles, boxvar_stringEq);
_differencesStr = stringDelimitList(omc_List_map1(threadData, _intersection, boxvar_ClassLoader_getBothPackageAndFilename, _mp), _OMC_LIT32);
tmpMeta[1] = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_intersection), _OMC_LIT41, tmpMeta[1], tmpMeta[2]);
_mofiles = listAppend(_subdirs, _mofiles);
_differences = omc_List_setDifference(threadData, _mofiles, _namesToFind);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_po1 = omc_ClassLoader_getPackageContentNamesinParts(threadData, _namesToFind, _cp, tmpMeta[1]);
_po1 = omc_List_map3Fold(threadData, _po1, boxvar_ClassLoader_checkPackageOrderFilesExist, _mp, _info, mmc_mk_boolean(_encrypted), _differences ,&_differences);
_differencesStr = stringDelimitList(_differences, _OMC_LIT42);
tmpMeta[1] = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_differences), _OMC_LIT45, tmpMeta[1], tmpMeta[2]);
_po2 = omc_List_map(threadData, _differences, boxvar_ClassLoader_makeClassLoad);
_po = listAppend(_po2, _po1);
goto tmp6_done;
}
case 1: {
_mofiles = omc_List_map(threadData, omc_System_moFiles(threadData, _mp), boxvar_Util_removeLast3Char);
_subdirs = omc_System_subDirectories(threadData, _mp);
_subdirs = omc_List_filter2OnTrue(threadData, _subdirs, boxvar_ClassLoader_existPackage, _mp, mmc_mk_boolean(_encrypted));
_mofiles = omc_List_sort(threadData, listAppend(_subdirs, _mofiles), boxvar_Util_strcmpBool);
_intersection = omc_List_sortedDuplicates(threadData, _mofiles, boxvar_stringEq);
_differencesStr = stringDelimitList(omc_List_map1(threadData, _intersection, boxvar_ClassLoader_getBothPackageAndFilename, _mp), _OMC_LIT32);
tmpMeta[1] = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_intersection), _OMC_LIT41, tmpMeta[1], _info);
_po = listAppend(omc_List_map(threadData, _cp, boxvar_ClassLoader_makeClassPart), omc_List_map(threadData, _mofiles, boxvar_ClassLoader_makeClassLoad));
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
tmpMeta[0] = _po;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp10;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_info = tmpMeta[1];
tmp10 = (_numError == omc_Error_getNumErrorMessages(threadData));
if (1 != tmp10) goto goto_1;
omc_Error_addSourceMessage(threadData, _OMC_LIT48, _OMC_LIT50, _info);
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
_po = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getPackageContentNames(threadData_t *threadData, modelica_metatype _cl, modelica_metatype _filename, modelica_metatype _mp, modelica_metatype _numError, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _po = NULL;
tmp1 = mmc_unbox_integer(_numError);
tmp2 = mmc_unbox_integer(_encrypted);
_po = omc_ClassLoader_getPackageContentNames(threadData, _cl, _filename, _mp, tmp1, tmp2);
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassLoader_getBothPackageAndFilename(threadData_t *threadData, modelica_string _str, modelica_string _mp)
{
modelica_string _out = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = stringAppend(_mp,_OMC_LIT20);
tmpMeta[1] = stringAppend(tmpMeta[0],_str);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT24);
tmpMeta[3] = stringAppend(omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, tmpMeta[2])),_OMC_LIT32);
tmpMeta[4] = stringAppend(_mp,_OMC_LIT20);
tmpMeta[5] = stringAppend(tmpMeta[4],_str);
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT51);
tmpMeta[7] = stringAppend(tmpMeta[3],omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, tmpMeta[6])));
_out = tmpMeta[7];
_return: OMC_LABEL_UNUSED
return _out;
}
DLLExport
modelica_metatype omc_ClassLoader_parsePackageFile(threadData_t *threadData, modelica_string _name, modelica_metatype _strategy, modelica_boolean _expectPackage, modelica_metatype _w1, modelica_string _pack)
{
modelica_metatype _cl = NULL;
modelica_metatype _cs = NULL;
modelica_metatype _w2 = NULL;
modelica_metatype _classNames = NULL;
modelica_metatype _info = NULL;
modelica_string _str = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _cname = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_ClassLoader_getProgramFromStrategy(threadData, _name, _strategy);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_cs = tmpMeta[1];
_w2 = tmpMeta[2];
_classNames = omc_List_map(threadData, _cs, boxvar_AbsynUtil_getClassName);
_str = stringDelimitList(_classNames, _OMC_LIT32);
if((!(listLength(_cs) == ((modelica_integer) 1))))
{
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _name, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_addSourceMessage(threadData, _OMC_LIT54, tmpMeta[0], tmpMeta[1]);
MMC_THROW_INTERNAL();
}
tmpMeta[0] = _cs;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
if (!listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
_cl = tmpMeta[1];
_cname = tmpMeta[3];
_body = tmpMeta[4];
_info = tmpMeta[5];
if((!(stringEqual(_cname, _pack))))
{
if((stringEqual(omc_System_tolower(threadData, _cname), omc_System_tolower(threadData, _pack))))
{
tmpMeta[0] = mmc_mk_cons(_pack, mmc_mk_cons(_cname, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT60, tmpMeta[0], _info);
}
else
{
tmpMeta[0] = mmc_mk_cons(_pack, mmc_mk_cons(_cname, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT57, tmpMeta[0], _info);
MMC_THROW_INTERNAL();
}
}
if((_expectPackage && (!omc_AbsynUtil_isParts(threadData, _body))))
{
tmpMeta[0] = mmc_mk_cons(_pack, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT69, tmpMeta[0], _info);
MMC_THROW_INTERNAL();
}
else
{
if((!(omc_AbsynUtil_withinEqual(threadData, _w1, _w2) || omc_Config_languageStandardAtMost(threadData, 2))))
{
_s1 = omc_AbsynUtil_withinString(threadData, _w1);
_s2 = omc_AbsynUtil_withinString(threadData, _w2);
if(omc_AbsynUtil_withinEqualCaseInsensitive(threadData, _w1, _w2))
{
tmpMeta[0] = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT66, tmpMeta[0], _info);
}
else
{
tmpMeta[0] = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT63, tmpMeta[0], _info);
MMC_THROW_INTERNAL();
}
}
}
_return: OMC_LABEL_UNUSED
return _cl;
}
modelica_metatype boxptr_ClassLoader_parsePackageFile(threadData_t *threadData, modelica_metatype _name, modelica_metatype _strategy, modelica_metatype _expectPackage, modelica_metatype _w1, modelica_metatype _pack)
{
modelica_integer tmp1;
modelica_metatype _cl = NULL;
tmp1 = mmc_unbox_integer(_expectPackage);
_cl = omc_ClassLoader_parsePackageFile(threadData, _name, _strategy, tmp1, _w1, _pack);
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp2(threadData_t *threadData, modelica_metatype _po, modelica_string _mp, modelica_metatype _strategy, modelica_metatype _w1, modelica_boolean _encrypted, modelica_metatype _acc)
{
modelica_metatype _cps = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _po;
{
modelica_metatype _ei = NULL;
modelica_string _pd = NULL;
modelica_string _file = NULL;
modelica_string _id = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _cl = NULL;
modelica_boolean _bDirectoryAndFileExists;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cp = tmpMeta[1];
tmpMeta[0] = omc_ClassLoader_mergeBefore(threadData, _cp, _acc);
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp5) goto tmp2_end;
_ei = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta[1]);
tmpMeta[0] = omc_ClassLoader_mergeBefore(threadData, tmpMeta[2], _acc);
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp6) goto tmp2_end;
_ei = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, tmpMeta[1]);
tmpMeta[0] = omc_ClassLoader_mergeBefore(threadData, tmpMeta[2], _acc);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_id = tmpMeta[1];
_pd = _OMC_LIT20;
tmpMeta[1] = stringAppend(_mp,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_id);
tmpMeta[3] = stringAppend(tmpMeta[2],(_encrypted?_OMC_LIT70:_OMC_LIT51));
_file = tmpMeta[3];
tmpMeta[1] = stringAppend(_mp,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_id);
_bDirectoryAndFileExists = (omc_System_directoryExists(threadData, tmpMeta[2]) && omc_System_regularFileExists(threadData, _file));
if(_bDirectoryAndFileExists)
{
_cl = omc_ClassLoader_loadCompletePackageFromMp(threadData, _id, _id, _mp, _strategy, _w1, omc_Error_getNumErrorMessages(threadData), _encrypted);
_ei = omc_AbsynUtil_makeClassElement(threadData, _cl);
tmpMeta[1] = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta[1]);
_cps = omc_ClassLoader_mergeBefore(threadData, tmpMeta[2], _acc);
}
else
{
tmpMeta[1] = stringAppend(_mp,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_id);
tmpMeta[3] = stringAppend(tmpMeta[2],(_encrypted?_OMC_LIT23:_OMC_LIT24));
_file = tmpMeta[3];
if((!omc_System_regularFileExists(threadData, _file)))
{
tmpMeta[1] = stringAppend(_OMC_LIT71,_file);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT72);
omc_Error_addInternalError(threadData, tmpMeta[2], _OMC_LIT74);
goto goto_1;
}
_cl = omc_ClassLoader_parsePackageFile(threadData, _file, _strategy, 0, _w1, _id);
_ei = omc_AbsynUtil_makeClassElement(threadData, _cl);
tmpMeta[1] = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta[1]);
_cps = omc_ClassLoader_mergeBefore(threadData, tmpMeta[2], _acc);
}
tmpMeta[0] = _cps;
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
_cps = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadCompletePackageFromMp2(threadData_t *threadData, modelica_metatype _po, modelica_metatype _mp, modelica_metatype _strategy, modelica_metatype _w1, modelica_metatype _encrypted, modelica_metatype _acc)
{
modelica_integer tmp1;
modelica_metatype _cps = NULL;
tmp1 = mmc_unbox_integer(_encrypted);
_cps = omc_ClassLoader_loadCompletePackageFromMp2(threadData, _po, _mp, _strategy, _w1, tmp1, _acc);
return _cps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_mergeBefore(threadData_t *threadData, modelica_metatype _cp, modelica_metatype _cps)
{
modelica_metatype _ocp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _cp;
tmp3_2 = _cps;
{
modelica_metatype _ei1 = NULL;
modelica_metatype _ei2 = NULL;
modelica_metatype _ei = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmp3_2);
tmpMeta[3] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_ei1 = tmpMeta[1];
_ei2 = tmpMeta[4];
_rest = tmpMeta[3];
_ei = listAppend(_ei1, _ei2);
tmpMeta[2] = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _ei);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _rest);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmp3_2);
tmpMeta[3] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_ei1 = tmpMeta[1];
_ei2 = tmpMeta[4];
_rest = tmpMeta[3];
_ei = listAppend(_ei1, _ei2);
tmpMeta[2] = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _ei);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _rest);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[1] = mmc_mk_cons(_cp, _cps);
tmpMeta[0] = tmpMeta[1];
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
_ocp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ocp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp(threadData_t *threadData, modelica_string _id, modelica_string _inIdent, modelica_string _inString, modelica_metatype _strategy, modelica_metatype _inWithin, modelica_integer _numError, modelica_boolean _encrypted)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp3_1;volatile modelica_string tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _inIdent;
tmp3_2 = _inString;
tmp3_3 = _inWithin;
{
modelica_string _pd = NULL;
modelica_string _mp_1 = NULL;
modelica_string _packagefile = NULL;
modelica_string _orderfile = NULL;
modelica_string _pack = NULL;
modelica_string _mp = NULL;
modelica_string _name = NULL;
modelica_metatype _within_ = NULL;
modelica_metatype _tv = NULL;
modelica_boolean _pp;
modelica_boolean _fp;
modelica_boolean _ep;
modelica_metatype _r = NULL;
modelica_metatype _ca = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _info = NULL;
modelica_metatype _path = NULL;
modelica_metatype _w2 = NULL;
modelica_metatype _reverseOrder = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
_pack = tmp3_1;
_mp = tmp3_2;
_within_ = tmp3_3;
_pd = _OMC_LIT20;
tmpMeta[1] = mmc_mk_cons(_mp, mmc_mk_cons(_pd, mmc_mk_cons(_pack, MMC_REFSTRUCTLIT(mmc_nil))));
_mp_1 = stringAppendList(tmpMeta[1]);
tmpMeta[1] = mmc_mk_cons(_mp_1, mmc_mk_cons(_pd, mmc_mk_cons((_encrypted?_OMC_LIT21:_OMC_LIT22), MMC_REFSTRUCTLIT(mmc_nil))));
_packagefile = stringAppendList(tmpMeta[1]);
tmpMeta[1] = mmc_mk_cons(_mp_1, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT75, MMC_REFSTRUCTLIT(mmc_nil))));
_orderfile = stringAppendList(tmpMeta[1]);
if((!omc_System_regularFileExists(threadData, _packagefile)))
{
tmpMeta[1] = stringAppend(_OMC_LIT71,_packagefile);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT72);
omc_Error_addInternalError(threadData, tmpMeta[2], _OMC_LIT76);
goto goto_1;
}
tmpMeta[1] = omc_ClassLoader_parsePackageFile(threadData, _packagefile, _strategy, 1, _within_, _id);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmp7 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,5) == 0) goto goto_1;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 5));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 6));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_cl = tmpMeta[1];
_name = tmpMeta[2];
_pp = tmp5;
_fp = tmp6;
_ep = tmp7;
_r = tmpMeta[6];
_tv = tmpMeta[8];
_ca = tmpMeta[9];
_cp = tmpMeta[10];
_ann = tmpMeta[11];
_cmt = tmpMeta[12];
_info = tmpMeta[13];
_reverseOrder = omc_ClassLoader_getPackageContentNames(threadData, _cl, _orderfile, _mp_1, omc_Error_getNumErrorMessages(threadData), _encrypted);
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_path = omc_AbsynUtil_joinWithinPath(threadData, _within_, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
_w2 = tmpMeta[1];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cp = omc_List_fold4(threadData, _reverseOrder, boxvar_ClassLoader_loadCompletePackageFromMp2, _mp_1, _strategy, _w2, mmc_mk_boolean(_encrypted), tmpMeta[1]);
tmpMeta[1] = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _tv, _ca, _cp, _ann, _cmt);
tmpMeta[2] = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _name, mmc_mk_boolean(_pp), mmc_mk_boolean(_fp), mmc_mk_boolean(_ep), _r, tmpMeta[1], _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp8;
_pack = tmp3_1;
_mp = tmp3_2;
tmp8 = (_numError == omc_Error_getNumErrorMessages(threadData));
if (1 != tmp8) goto goto_1;
tmpMeta[1] = stringAppend(_OMC_LIT77,_mp);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT78);
tmpMeta[3] = stringAppend(tmpMeta[2],_pack);
omc_Error_addInternalError(threadData, tmpMeta[3], _OMC_LIT79);
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
_cl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadCompletePackageFromMp(threadData_t *threadData, modelica_metatype _id, modelica_metatype _inIdent, modelica_metatype _inString, modelica_metatype _strategy, modelica_metatype _inWithin, modelica_metatype _numError, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cl = NULL;
tmp1 = mmc_unbox_integer(_numError);
tmp2 = mmc_unbox_integer(_encrypted);
_cl = omc_ClassLoader_loadCompletePackageFromMp(threadData, _id, _inIdent, _inString, _strategy, _inWithin, tmp1, tmp2);
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getAllFilesFromDirectory(threadData_t *threadData, modelica_string _dir, modelica_boolean _encrypted, modelica_metatype _acc)
{
modelica_metatype _files = NULL;
modelica_metatype _subdirs = NULL;
modelica_string _pd = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pd = _OMC_LIT20;
if(_encrypted)
{
tmpMeta[1] = stringAppend(_dir,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT21);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_string __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _f_loopVar = 0;
modelica_metatype _f;
_f_loopVar = omc_System_mocFiles(threadData, _dir);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[4];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_f_loopVar)) {
_f = MMC_CAR(_f_loopVar);
_f_loopVar = MMC_CDR(_f_loopVar);
tmp2--;
}
if (tmp2 == 0) {
tmpMeta[5] = stringAppend(_dir,_pd);
tmpMeta[6] = stringAppend(tmpMeta[5],_f);
__omcQ_24tmpVar0 = tmpMeta[6];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar1;
}
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], listAppend(tmpMeta[3], _acc));
_files = tmpMeta[0];
}
else
{
tmpMeta[1] = stringAppend(_dir,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT22);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp3;
modelica_string __omcQ_24tmpVar2;
int tmp4;
modelica_metatype _f_loopVar = 0;
modelica_metatype _f;
_f_loopVar = omc_System_moFiles(threadData, _dir);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[4];
tmp3 = &__omcQ_24tmpVar3;
while(1) {
tmp4 = 1;
if (!listEmpty(_f_loopVar)) {
_f = MMC_CAR(_f_loopVar);
_f_loopVar = MMC_CDR(_f_loopVar);
tmp4--;
}
if (tmp4 == 0) {
tmpMeta[5] = stringAppend(_dir,_pd);
tmpMeta[6] = stringAppend(tmpMeta[5],_f);
__omcQ_24tmpVar2 = tmpMeta[6];
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar3;
}
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], listAppend(tmpMeta[3], _acc));
_files = tmpMeta[0];
}
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp5;
modelica_string __omcQ_24tmpVar4;
int tmp6;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = omc_List_filter2OnTrue(threadData, omc_System_subDirectories(threadData, _dir), boxvar_ClassLoader_existPackage, _dir, mmc_mk_boolean(_encrypted));
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[1];
tmp5 = &__omcQ_24tmpVar5;
while(1) {
tmp6 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp6--;
}
if (tmp6 == 0) {
tmpMeta[2] = stringAppend(_dir,_pd);
tmpMeta[3] = stringAppend(tmpMeta[2],_d);
__omcQ_24tmpVar4 = tmpMeta[3];
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar5;
}
_subdirs = tmpMeta[0];
_files = omc_List_fold1(threadData, _subdirs, boxvar_ClassLoader_getAllFilesFromDirectory, mmc_mk_boolean(_encrypted), _files);
_return: OMC_LABEL_UNUSED
return _files;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_getAllFilesFromDirectory(threadData_t *threadData, modelica_metatype _dir, modelica_metatype _encrypted, modelica_metatype _acc)
{
modelica_integer tmp1;
modelica_metatype _files = NULL;
tmp1 = mmc_unbox_integer(_encrypted);
_files = omc_ClassLoader_getAllFilesFromDirectory(threadData, _dir, tmp1, _acc);
return _files;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_string _id, modelica_string _path, modelica_string _name, modelica_boolean _isDir, modelica_metatype _optEncoding, modelica_boolean _encrypted)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _isDir;
{
modelica_string _pd = NULL;
modelica_string _encoding = NULL;
modelica_string _encodingfile = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _filenames = NULL;
modelica_metatype _strategy = NULL;
modelica_boolean _lveStarted;
modelica_metatype _lveInstance = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
_pd = _OMC_LIT20;
tmpMeta[1] = mmc_mk_cons(_path, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT80, MMC_REFSTRUCTLIT(mmc_nil))));
_encodingfile = stringAppendList(tmpMeta[1]);
_encoding = omc_System_trimChar(threadData, omc_System_trimChar(threadData, (omc_System_regularFileExists(threadData, _encodingfile)?omc_System_readFile(threadData, _encodingfile):omc_Util_getOptionOrDefault(threadData, _optEncoding, _OMC_LIT81)), _OMC_LIT31), _OMC_LIT82);
tmpMeta[1] = mmc_mk_box2(4, &ClassLoader_LoadFileStrategy_STRATEGY__ON__DEMAND__desc, _encoding);
_strategy = tmpMeta[1];
tmpMeta[1] = stringAppend(_path,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_name);
tmpMeta[0] = omc_ClassLoader_parsePackageFile(threadData, tmpMeta[2], _strategy, 0, _OMC_LIT83, _id);
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
_pd = _OMC_LIT20;
tmpMeta[1] = mmc_mk_cons(_path, mmc_mk_cons(_pd, mmc_mk_cons(_name, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT80, MMC_REFSTRUCTLIT(mmc_nil))))));
_encodingfile = stringAppendList(tmpMeta[1]);
_encoding = omc_System_trimChar(threadData, omc_System_trimChar(threadData, (omc_System_regularFileExists(threadData, _encodingfile)?omc_System_readFile(threadData, _encodingfile):omc_Util_getOptionOrDefault(threadData, _optEncoding, _OMC_LIT81)), _OMC_LIT31), _OMC_LIT82);
if(_encrypted)
{
tmpMeta[1] = stringAppend(_path,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_name);
_lveStarted = omc_Parser_startLibraryVendorExecutable(threadData, tmpMeta[2] ,&_lveInstance);
if((!_lveStarted))
{
goto goto_1;
}
}
if(((omc_Testsuite_isRunning(threadData) || (omc_Config_noProc(threadData) == ((modelica_integer) 1))) && (!_encrypted)))
{
tmpMeta[1] = mmc_mk_box2(4, &ClassLoader_LoadFileStrategy_STRATEGY__ON__DEMAND__desc, _encoding);
_strategy = tmpMeta[1];
}
else
{
tmpMeta[1] = stringAppend(_path,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_name);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_filenames = omc_ClassLoader_getAllFilesFromDirectory(threadData, tmpMeta[2], _encrypted, tmpMeta[3]);
tmpMeta[1] = stringAppend(_path,_pd);
tmpMeta[2] = stringAppend(tmpMeta[1],_name);
tmpMeta[3] = mmc_mk_box2(3, &ClassLoader_LoadFileStrategy_STRATEGY__HASHTABLE__desc, omc_Parser_parallelParseFiles(threadData, _filenames, _encoding, omc_Config_noProc(threadData), tmpMeta[2], _lveInstance));
_strategy = tmpMeta[3];
}
_cl = omc_ClassLoader_loadCompletePackageFromMp(threadData, _id, _name, _path, _strategy, _OMC_LIT83, omc_Error_getNumErrorMessages(threadData), _encrypted);
if((_encrypted && _lveStarted))
{
omc_Parser_stopLibraryVendorExecutable(threadData, _lveInstance);
}
tmpMeta[0] = _cl;
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
_outClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_metatype _id, modelica_metatype _path, modelica_metatype _name, modelica_metatype _isDir, modelica_metatype _optEncoding, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_isDir);
tmp2 = mmc_unbox_integer(_encrypted);
_outClass = omc_ClassLoader_loadClassFromMp(threadData, _id, _path, _name, tmp1, _optEncoding, tmp2);
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_string _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_boolean _requireExactVersion, modelica_boolean _encrypted)
{
modelica_metatype _outProgram = NULL;
modelica_string _mp = NULL;
modelica_string _name = NULL;
modelica_string _pwd = NULL;
modelica_string _cmd = NULL;
modelica_string _version = NULL;
modelica_string _userLibraries = NULL;
modelica_boolean _isDir;
modelica_boolean _impactOK;
modelica_metatype _cl = NULL;
modelica_metatype _versionsThatProvideTheWanted = NULL;
modelica_metatype _commands = NULL;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
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
_mp = omc_System_getLoadModelPath(threadData, _id, _prios, _mps, _requireExactVersion ,&_name ,&_isDir);
goto tmp2_done;
}
case 1: {
modelica_string tmp5 = 0;
modelica_string tmp10;
{
modelica_metatype tmp8_1;
tmp8_1 = _prios;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
if (listEmpty(tmp8_1)) goto tmp7_end;
tmpMeta[0] = MMC_CAR(tmp8_1);
tmpMeta[1] = MMC_CDR(tmp8_1);
_version = tmpMeta[0];
tmp5 = _version;
goto tmp7_done;
}
case 1: {
tmp5 = _OMC_LIT84;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
goto goto_1;
goto tmp7_done;
tmp7_done:;
}
}
_version = tmp5;
_versionsThatProvideTheWanted = omc_PackageManagement_versionsThatProvideTheWanted(threadData, _id, _version, 0);
if((!listEmpty(_versionsThatProvideTheWanted)))
{
if(((stringEqual(_version, _OMC_LIT84)) || (stringEqual(_version, _OMC_LIT0))))
{
tmpMeta[1] = stringAppend(_OMC_LIT85,_id);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT89);
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_commands = tmpMeta[0];
}
else
{
tmpMeta[1] = stringAppend(_OMC_LIT85,_id);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT86);
tmpMeta[3] = stringAppend(tmpMeta[2],_version);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT87);
tmpMeta[5] = stringAppend(_OMC_LIT85,_id);
tmpMeta[6] = stringAppend(tmpMeta[5],_OMC_LIT86);
tmpMeta[7] = stringAppend(tmpMeta[6],_version);
tmpMeta[8] = stringAppend(tmpMeta[7],_OMC_LIT88);
tmp10 = modelica_boolean_to_modelica_string(listMember(_version, _versionsThatProvideTheWanted), ((modelica_integer) 0), 1);
tmpMeta[9] = stringAppend(tmpMeta[8],tmp10);
tmpMeta[10] = stringAppend(tmpMeta[9],_OMC_LIT89);
tmpMeta[0] = mmc_mk_cons(tmpMeta[4], mmc_mk_cons(tmpMeta[10], MMC_REFSTRUCTLIT(mmc_nil)));
_commands = tmpMeta[0];
}
if((!stringEqual(listHead(_versionsThatProvideTheWanted), _version)))
{
tmpMeta[1] = stringAppend(_OMC_LIT85,_id);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT86);
tmpMeta[3] = stringAppend(tmpMeta[2],listHead(_versionsThatProvideTheWanted));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT90);
tmpMeta[0] = mmc_mk_cons(tmpMeta[4], _commands);
_commands = tmpMeta[0];
}
tmpMeta[0] = mmc_mk_cons(stringDelimitList(_commands, _OMC_LIT31), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT93, tmpMeta[0]);
}
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
omc_Config_setLanguageStandardFromMSL(threadData, _name);
_cl = omc_ClassLoader_loadClassFromMp(threadData, _id, _mp, _name, _isDir, _encoding, _encrypted);
tmpMeta[0] = mmc_mk_cons(_cl, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta[0], _OMC_LIT83);
_outProgram = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_metatype _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_metatype _requireExactVersion, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_requireExactVersion);
tmp2 = mmc_unbox_integer(_encrypted);
_outProgram = omc_ClassLoader_loadClassFromMps(threadData, _id, _prios, _mps, _encoding, tmp1, tmp2);
return _outProgram;
}
DLLExport
modelica_metatype omc_ClassLoader_loadClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _priorityList, modelica_string _modelicaPath, modelica_metatype _encoding, modelica_boolean _requireExactVersion, modelica_boolean _encrypted)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_string tmp3_2;
tmp3_1 = _inPath;
tmp3_2 = _modelicaPath;
{
modelica_string _gd = NULL;
modelica_string _classname = NULL;
modelica_string _mp = NULL;
modelica_string _pack = NULL;
modelica_metatype _mps = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_classname = tmpMeta[1];
_mp = tmp3_2;
tmp3 += 1;
_gd = _OMC_LIT94;
_mps = omc_System_strtok(threadData, _mp, _gd);
_p = omc_ClassLoader_loadClassFromMps(threadData, _classname, _priorityList, _mps, _encoding, _requireExactVersion, _encrypted);
omc_ClassLoader_checkOnLoadMessage(threadData, _p);
tmpMeta[0] = _p;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_pack = tmpMeta[1];
_mp = tmp3_2;
_gd = _OMC_LIT94;
_mps = omc_System_strtok(threadData, _mp, _gd);
_p = omc_ClassLoader_loadClassFromMps(threadData, _pack, _priorityList, _mps, _encoding, _requireExactVersion, _encrypted);
omc_ClassLoader_checkOnLoadMessage(threadData, _p);
tmpMeta[0] = _p;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT98);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT99);
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outProgram = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_ClassLoader_loadClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _priorityList, modelica_metatype _modelicaPath, modelica_metatype _encoding, modelica_metatype _requireExactVersion, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_requireExactVersion);
tmp2 = mmc_unbox_integer(_encrypted);
_outProgram = omc_ClassLoader_loadClass(threadData, _inPath, _priorityList, _modelicaPath, _encoding, tmp1, tmp2);
return _outProgram;
}

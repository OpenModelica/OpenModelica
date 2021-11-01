#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ClassLoader.c"
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
#define _OMC_LIT73_data "ClassLoader.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,14,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT74_6,0.0);
#define _OMC_LIT74_6 MMC_REFREALLIT(_OMC_LIT_STRUCT74_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(388)),MMC_IMMEDIATE(MMC_TAGFIXNUM(13)),MMC_IMMEDIATE(MMC_TAGFIXNUM(388)),MMC_IMMEDIATE(MMC_TAGFIXNUM(88)),_OMC_LIT74_6}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "package.order"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,13,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT76_6,0.0);
#define _OMC_LIT76_6 MMC_REFREALLIT(_OMC_LIT_STRUCT76_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(295)),MMC_IMMEDIATE(MMC_TAGFIXNUM(11)),MMC_IMMEDIATE(MMC_TAGFIXNUM(295)),MMC_IMMEDIATE(MMC_TAGFIXNUM(93)),_OMC_LIT76_6}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "loadCompletePackageFromMp failed for unknown reason: mp="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,56,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data " pack="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,6,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT79_6,0.0);
#define _OMC_LIT79_6 MMC_REFREALLIT(_OMC_LIT_STRUCT79_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT73,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(313)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(313)),MMC_IMMEDIATE(MMC_TAGFIXNUM(128)),_OMC_LIT79_6}};
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,3,3) {&Absyn_Program_PROGRAM__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT83}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,1,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,9,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,41,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT97}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT96,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT98}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "ClassLoader.loadClass failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,29,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_string _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_boolean _requireExactVersion, modelica_boolean _encrypted);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ClassLoader_loadClassFromMps(threadData_t *threadData, modelica_metatype _id, modelica_metatype _prios, modelica_metatype _mps, modelica_metatype _encoding, modelica_metatype _requireExactVersion, modelica_metatype _encrypted);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMps,2,0) {(void*) boxptr_ClassLoader_loadClassFromMps,0}};
#define boxvar_ClassLoader_loadClassFromMps MMC_REFSTRUCTLIT(boxvar_lit_ClassLoader_loadClassFromMps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getProgramFromStrategy(threadData_t *threadData, modelica_string _filename, modelica_metatype _strategy)
{
modelica_metatype _program = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _strategy;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = omc_BaseHashTable_get(threadData, _filename, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_strategy), 2))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta1 = omc_Parser_parse(threadData, _filename, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_strategy), 2))), _OMC_LIT0, mmc_mk_none());
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
_program = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _program;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ClassLoader_checkOnLoadMessageWork(threadData_t *threadData, modelica_metatype _mod)
{
modelica_integer _dummy;
modelica_integer tmp1 = 0;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_str = tmpMeta9;
_info = tmpMeta10;
tmpMeta11 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT5, tmpMeta11, _info);
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _p1;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_classes = tmpMeta2;
omc_List_map2(threadData, _classes, boxvar_AbsynUtil_getNamedAnnotationInClass, _OMC_LIT7, boxvar_ClassLoader_checkOnLoadMessageWork);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassLoader_packageOrderName(threadData_t *threadData, modelica_metatype _ord)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
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
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta6;
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_n1 = tmpMeta6;
_rest1 = tmpMeta7;
_n2 = tmpMeta8;
_rest2 = tmpMeta9;
if((stringEqual(_n1, _n2)))
{
_rest1 = omc_ClassLoader_matchCompNames(threadData, _rest1, _rest2, _info ,&_b);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_assertionOrAddSourceMessage(threadData, _b, _OMC_LIT13, tmpMeta10, _info);
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,6) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,3,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
_name1 = tmpMeta6;
_ei = tmpMeta8;
_comps = tmpMeta12;
_info = tmpMeta13;
_elts = tmpMeta9;
_compNames = omc_List_map(threadData, _comps, boxvar_AbsynUtil_componentName);
_names = omc_ClassLoader_matchCompNames(threadData, _inNamesToSort, _compNames, _info ,&_b);
_orderElt = (_b?omc_ClassLoader_makeElement(threadData, _ei, _pub):omc_ClassLoader_makeClassLoad(threadData, _name1));
tmpMeta14 = mmc_mk_cons(_orderElt, _po);
_inNamesToSort = _names;
_inElts = (_b?_elts:_inElts);
_po = tmpMeta14;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_2);
tmpMeta18 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,0,6) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,2) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 8));
_name1 = tmpMeta15;
_namesToSort = tmpMeta16;
_ei = tmpMeta17;
_name2 = tmpMeta22;
_info = tmpMeta23;
_elts = tmpMeta18;
_load = omc_ClassLoader_makeClassLoad(threadData, _name1);
_b = (stringEqual(_name1, _name2));
tmpMeta24 = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (_b?(!listMember(_load, _po)):1), _OMC_LIT16, tmpMeta24, _info);
_orderElt = (_b?omc_ClassLoader_makeElement(threadData, _ei, _pub):_load);
tmpMeta25 = mmc_mk_cons(_orderElt, _po);
_inNamesToSort = _namesToSort;
_inElts = (_b?_elts:_inElts);
_po = tmpMeta25;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmp4_2);
tmpMeta27 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,0,6) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 8));
_name2 = tmpMeta31;
_info = tmpMeta32;
_load = omc_ClassLoader_makeClassLoad(threadData, _name2);
tmpMeta33 = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (!listMember(_load, _po)), _OMC_LIT16, tmpMeta33, _info);
tmpMeta34 = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT19, tmpMeta34, _info);
tmpMeta35 = mmc_mk_cons(_name2, _inNamesToSort);
_inNamesToSort = tmpMeta35;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_2);
tmpMeta37 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,0,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,0,6) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,3,3) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
if (listEmpty(tmpMeta40)) goto tmp3_end;
tmpMeta41 = MMC_CAR(tmpMeta40);
tmpMeta42 = MMC_CDR(tmpMeta40);
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 6));
_name2 = tmpMeta44;
_info = tmpMeta45;
_load = omc_ClassLoader_makeClassLoad(threadData, _name2);
tmpMeta46 = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, (!listMember(_load, _po)), _OMC_LIT16, tmpMeta46, _info);
tmpMeta47 = mmc_mk_cons(_name2, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT19, tmpMeta47, _info);
tmpMeta48 = mmc_mk_cons(_name2, _inNamesToSort);
_inNamesToSort = tmpMeta48;
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmp4_2);
tmpMeta50 = MMC_CDR(tmp4_2);
_ei = tmpMeta49;
_elts = tmpMeta50;
_namesToSort = tmp4_1;
tmpMeta52 = mmc_mk_box3(4, &ClassLoader_PackageOrder_ELEMENT__desc, _ei, mmc_mk_boolean(_pub));
tmpMeta51 = mmc_mk_cons(tmpMeta52, _po);
_inNamesToSort = _namesToSort;
_inElts = _elts;
_po = tmpMeta51;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inNamesToSort;
tmp4_2 = _cps;
{
modelica_metatype _rcp = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _namesToSort = NULL;
modelica_metatype _cp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_namesToSort = tmp4_1;
tmpMeta1 = listAppend(omc_List_mapReverse(threadData, _namesToSort, boxvar_ClassLoader_makeClassLoad), _acc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_elts = tmpMeta8;
_rcp = tmpMeta7;
_namesToSort = tmp4_1;
_outOrder = omc_ClassLoader_getPackageContentNamesinElts(threadData, _namesToSort, _elts, _acc, 1 ,&_namesToSort);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = _outOrder;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_elts = tmpMeta11;
_rcp = tmpMeta10;
_namesToSort = tmp4_1;
_outOrder = omc_ClassLoader_getPackageContentNamesinElts(threadData, _namesToSort, _elts, _acc, 0 ,&_namesToSort);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = _outOrder;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
_cp = tmpMeta12;
_rcp = tmpMeta13;
_namesToSort = tmp4_1;
tmpMeta15 = mmc_mk_box2(3, &ClassLoader_PackageOrder_CLASSPART__desc, _cp);
tmpMeta14 = mmc_mk_cons(tmpMeta15, _acc);
_inNamesToSort = _namesToSort;
_cps = _rcp;
_acc = tmpMeta14;
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
_outOrder = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outOrder;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ClassLoader_existPackage(threadData_t *threadData, modelica_string _name, modelica_string _mp, modelica_boolean _encrypted)
{
modelica_boolean _b;
modelica_string _pd = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pd = _OMC_LIT20;
tmpMeta1 = stringAppend(_mp,_pd);
tmpMeta2 = stringAppend(tmpMeta1,_name);
tmpMeta3 = stringAppend(tmpMeta2,_pd);
tmpMeta4 = stringAppend(tmpMeta3,(_encrypted?_OMC_LIT21:_OMC_LIT22));
_b = omc_System_regularFileExists(threadData, tmpMeta4);
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
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_str = tmpMeta5;
_pd = _OMC_LIT20;
tmpMeta6 = stringAppend(_str,(_encrypted?_OMC_LIT23:_OMC_LIT24));
_str2 = tmpMeta6;
tmpMeta7 = stringAppend(_mp,_pd);
tmpMeta8 = stringAppend(tmpMeta7,_str);
tmpMeta9 = stringAppend(_mp,_pd);
tmpMeta10 = stringAppend(tmpMeta9,_str2);
if((!(omc_System_directoryExists(threadData, tmpMeta8) || omc_System_regularFileExists(threadData, tmpMeta10))))
{
{
{
volatile mmc_switch_type tmp13;
int tmp14;
tmp13 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp12_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp13 < 2; tmp13++) {
switch (MMC_SWITCH_CAST(tmp13)) {
case 0: {
modelica_metatype tmpMeta15;
tmpMeta15 = mmc_mk_box1(0, omc_System_tolower(threadData, _str2));
_str3 = omc_List_find(threadData, omc_System_moFiles(threadData, _mp), (modelica_fnptr) mmc_mk_box2(0,closure0_Util_stringEqCaseInsensitive,tmpMeta15));
goto tmp12_done;
}
case 1: {
modelica_metatype tmpMeta16;
tmpMeta16 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT27, tmpMeta16, _info);
goto goto_11;
goto tmp12_done;
}
}
goto tmp12_end;
tmp12_end: ;
}
goto goto_11;
tmp12_done:
(void)tmp13;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp12_done2;
goto_11:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp13 < 2) {
goto tmp12_top;
}
goto goto_1;
tmp12_done2:;
}
}
;
tmpMeta17 = mmc_mk_cons(_str, mmc_mk_cons(_str2, mmc_mk_cons(_str3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT30, tmpMeta17, _info);
_str4 = omc_Util_removeLastNChar(threadData, _str3, (_encrypted?((modelica_integer) 4):((modelica_integer) 3)));
_differences = omc_List_removeOnTrue(threadData, _str4, boxvar_stringEq, _differences);
tmpMeta18 = mmc_mk_box2(5, &ClassLoader_PackageOrder_CLASSLOAD__desc, _str4);
_po = tmpMeta18;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(5, &ClassLoader_PackageOrder_CLASSLOAD__desc, _str);
_po = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_makeElement(threadData_t *threadData, modelica_metatype _el, modelica_boolean _pub)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(4, &ClassLoader_PackageOrder_ELEMENT__desc, _el, mmc_mk_boolean(_pub));
_po = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(3, &ClassLoader_PackageOrder_CLASSPART__desc, _part);
_po = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _po;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_getPackageContentNames(threadData_t *threadData, modelica_metatype _cl, modelica_string _filename, modelica_string _mp, modelica_integer _numError, modelica_boolean _encrypted)
{
modelica_metatype _po = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _cl;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_cp = tmpMeta7;
_info = tmpMeta8;
{
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp10_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
tmp13 = omc_System_regularFileExists(threadData, _filename);
if (1 != tmp13) goto goto_9;
_contents = omc_System_readFile(threadData, _filename);
_namesToFind = omc_System_strtok(threadData, _contents, _OMC_LIT31);
_namesToFind = omc_List_removeOnTrue(threadData, _OMC_LIT0, boxvar_stringEqual, omc_List_map(threadData, _namesToFind, boxvar_System_trimWhitespace));
_duplicates = omc_List_sortedDuplicates(threadData, omc_List_sort(threadData, _namesToFind, boxvar_Util_strcmpBool), boxvar_stringEq);
_duplicatesStr = stringDelimitList(_duplicates, _OMC_LIT32);
tmpMeta14 = mmc_mk_cons(_duplicatesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta15 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_duplicates), _OMC_LIT36, tmpMeta14, tmpMeta15);
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
tmpMeta16 = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta17 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_intersection), _OMC_LIT41, tmpMeta16, tmpMeta17);
_mofiles = listAppend(_subdirs, _mofiles);
_differences = omc_List_setDifference(threadData, _mofiles, _namesToFind);
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
_po1 = omc_ClassLoader_getPackageContentNamesinParts(threadData, _namesToFind, _cp, tmpMeta18);
_po1 = omc_List_map3Fold(threadData, _po1, boxvar_ClassLoader_checkPackageOrderFilesExist, _mp, _info, mmc_mk_boolean(_encrypted), _differences ,&_differences);
_differencesStr = stringDelimitList(_differences, _OMC_LIT42);
tmpMeta19 = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta20 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_differences), _OMC_LIT45, tmpMeta19, tmpMeta20);
_po2 = omc_List_map(threadData, _differences, boxvar_ClassLoader_makeClassLoad);
_po = listAppend(_po2, _po1);
goto tmp10_done;
}
case 1: {
modelica_metatype tmpMeta21;
_mofiles = omc_List_map(threadData, omc_System_moFiles(threadData, _mp), boxvar_Util_removeLast3Char);
_subdirs = omc_System_subDirectories(threadData, _mp);
_subdirs = omc_List_filter2OnTrue(threadData, _subdirs, boxvar_ClassLoader_existPackage, _mp, mmc_mk_boolean(_encrypted));
_mofiles = omc_List_sort(threadData, listAppend(_subdirs, _mofiles), boxvar_Util_strcmpBool);
_intersection = omc_List_sortedDuplicates(threadData, _mofiles, boxvar_stringEq);
_differencesStr = stringDelimitList(omc_List_map1(threadData, _intersection, boxvar_ClassLoader_getBothPackageAndFilename, _mp), _OMC_LIT32);
tmpMeta21 = mmc_mk_cons(_differencesStr, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_assertionOrAddSourceMessage(threadData, listEmpty(_intersection), _OMC_LIT41, tmpMeta21, _info);
_po = listAppend(omc_List_map(threadData, _cp, boxvar_ClassLoader_makeClassPart), omc_List_map(threadData, _mofiles, boxvar_ClassLoader_makeClassLoad));
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
tmp10_done:
(void)tmp11;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp10_done2;
goto_9:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp11 < 2) {
goto tmp10_top;
}
goto goto_2;
tmp10_done2:;
}
}
;
tmpMeta1 = _po;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_info = tmpMeta22;
tmp23 = (_numError == omc_Error_getNumErrorMessages(threadData));
if (1 != tmp23) goto goto_2;
omc_Error_addSourceMessage(threadData, _OMC_LIT48, _OMC_LIT50, _info);
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
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_po = tmpMeta1;
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_mp,_OMC_LIT20);
tmpMeta2 = stringAppend(tmpMeta1,_str);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT24);
tmpMeta4 = stringAppend(omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, tmpMeta3)),_OMC_LIT32);
tmpMeta5 = stringAppend(_mp,_OMC_LIT20);
tmpMeta6 = stringAppend(tmpMeta5,_str);
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT51);
tmpMeta8 = stringAppend(tmpMeta4,omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, tmpMeta7)));
_out = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _out;
}
DLLExport
modelica_metatype omc_ClassLoader_parsePackageFile(threadData_t *threadData, modelica_string _name, modelica_metatype _strategy, modelica_boolean _expectPackage, modelica_metatype _w1, modelica_string _pack, modelica_boolean _encrypted)
{
modelica_metatype _cl = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _cs = NULL;
modelica_metatype _w2 = NULL;
modelica_metatype _classNames = NULL;
modelica_metatype _info = NULL;
modelica_string _str = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _cname = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = omc_ClassLoader_getProgramFromStrategy(threadData, _name, _strategy);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_cs = tmpMeta2;
_w2 = tmpMeta3;
_classNames = omc_List_map(threadData, _cs, boxvar_AbsynUtil_getClassName);
_str = stringDelimitList(_classNames, _OMC_LIT32);
if((!(listLength(_cs) == ((modelica_integer) 1))))
{
if(_encrypted)
{
_cl = mmc_mk_none();
goto _return;
}
else
{
tmpMeta4 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _name, mmc_mk_boolean(1), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT37);
omc_Error_addSourceMessage(threadData, _OMC_LIT54, tmpMeta4, tmpMeta5);
MMC_THROW_INTERNAL();
}
}
tmpMeta6 = _cs;
if (listEmpty(tmpMeta6)) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 7));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 8));
if (!listEmpty(tmpMeta8)) MMC_THROW_INTERNAL();
_class_ = tmpMeta7;
_cname = tmpMeta9;
_body = tmpMeta10;
_info = tmpMeta11;
_cl = mmc_mk_some(_class_);
if((!(stringEqual(_cname, _pack))))
{
if((stringEqual(omc_System_tolower(threadData, _cname), omc_System_tolower(threadData, _pack))))
{
tmpMeta12 = mmc_mk_cons(_pack, mmc_mk_cons(_cname, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT60, tmpMeta12, _info);
}
else
{
tmpMeta13 = mmc_mk_cons(_pack, mmc_mk_cons(_cname, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT57, tmpMeta13, _info);
MMC_THROW_INTERNAL();
}
}
if((_expectPackage && (!omc_AbsynUtil_isParts(threadData, _body))))
{
tmpMeta14 = mmc_mk_cons(_pack, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT69, tmpMeta14, _info);
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
tmpMeta15 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT66, tmpMeta15, _info);
}
else
{
tmpMeta16 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT63, tmpMeta16, _info);
MMC_THROW_INTERNAL();
}
}
}
_return: OMC_LABEL_UNUSED
return _cl;
}
modelica_metatype boxptr_ClassLoader_parsePackageFile(threadData_t *threadData, modelica_metatype _name, modelica_metatype _strategy, modelica_metatype _expectPackage, modelica_metatype _w1, modelica_metatype _pack, modelica_metatype _encrypted)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cl = NULL;
tmp1 = mmc_unbox_integer(_expectPackage);
tmp2 = mmc_unbox_integer(_encrypted);
_cl = omc_ClassLoader_parsePackageFile(threadData, _name, _strategy, tmp1, _w1, _pack, tmp2);
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp2(threadData_t *threadData, modelica_metatype _po, modelica_string _mp, modelica_metatype _strategy, modelica_metatype _w1, modelica_boolean _encrypted, modelica_metatype _acc)
{
modelica_metatype _cps = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _po;
{
modelica_metatype _ei = NULL;
modelica_string _pd = NULL;
modelica_string _file = NULL;
modelica_string _id = NULL;
modelica_metatype _cp = NULL;
modelica_metatype _cl = NULL;
modelica_boolean _bDirectoryAndFileExists;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cp = tmpMeta6;
tmpMeta1 = omc_ClassLoader_mergeBefore(threadData, _cp, _acc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (1 != tmp9) goto tmp3_end;
_ei = tmpMeta7;
tmpMeta10 = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta11 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta10);
tmpMeta1 = omc_ClassLoader_mergeBefore(threadData, tmpMeta11, _acc);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp14 = mmc_unbox_integer(tmpMeta13);
if (0 != tmp14) goto tmp3_end;
_ei = tmpMeta12;
tmpMeta15 = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta16 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, tmpMeta15);
tmpMeta1 = omc_ClassLoader_mergeBefore(threadData, tmpMeta16, _acc);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta17;
_pd = _OMC_LIT20;
tmpMeta18 = stringAppend(_mp,_pd);
tmpMeta19 = stringAppend(tmpMeta18,_id);
tmpMeta20 = stringAppend(tmpMeta19,(_encrypted?_OMC_LIT70:_OMC_LIT51));
_file = tmpMeta20;
tmpMeta21 = stringAppend(_mp,_pd);
tmpMeta22 = stringAppend(tmpMeta21,_id);
_bDirectoryAndFileExists = (omc_System_directoryExists(threadData, tmpMeta22) && omc_System_regularFileExists(threadData, _file));
if(_bDirectoryAndFileExists)
{
_cl = omc_ClassLoader_loadCompletePackageFromMp(threadData, _id, _id, _mp, _strategy, _w1, omc_Error_getNumErrorMessages(threadData), _encrypted);
if(isSome(_cl))
{
_ei = omc_AbsynUtil_makeClassElement(threadData, omc_Util_getOption(threadData, _cl));
tmpMeta23 = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta24 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta23);
_cps = omc_ClassLoader_mergeBefore(threadData, tmpMeta24, _acc);
}
else
{
_cps = _acc;
}
}
else
{
tmpMeta25 = stringAppend(_mp,_pd);
tmpMeta26 = stringAppend(tmpMeta25,_id);
tmpMeta27 = stringAppend(tmpMeta26,(_encrypted?_OMC_LIT23:_OMC_LIT24));
_file = tmpMeta27;
if((!omc_System_regularFileExists(threadData, _file)))
{
tmpMeta28 = stringAppend(_OMC_LIT71,_file);
tmpMeta29 = stringAppend(tmpMeta28,_OMC_LIT72);
omc_Error_addInternalError(threadData, tmpMeta29, _OMC_LIT74);
goto goto_2;
}
_cl = omc_ClassLoader_parsePackageFile(threadData, _file, _strategy, 0, _w1, _id, _encrypted);
if(isSome(_cl))
{
_ei = omc_AbsynUtil_makeClassElement(threadData, omc_Util_getOption(threadData, _cl));
tmpMeta30 = mmc_mk_cons(_ei, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta31 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta30);
_cps = omc_ClassLoader_mergeBefore(threadData, tmpMeta31, _acc);
}
else
{
_cps = _acc;
}
}
tmpMeta1 = _cps;
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
_cps = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cp;
tmp4_2 = _cps;
{
modelica_metatype _ei1 = NULL;
modelica_metatype _ei2 = NULL;
modelica_metatype _ei = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_ei1 = tmpMeta6;
_ei2 = tmpMeta9;
_rest = tmpMeta8;
_ei = listAppend(_ei1, _ei2);
tmpMeta11 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _ei);
tmpMeta10 = mmc_mk_cons(tmpMeta11, _rest);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_2);
tmpMeta14 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_ei1 = tmpMeta12;
_ei2 = tmpMeta15;
_rest = tmpMeta14;
_ei = listAppend(_ei1, _ei2);
tmpMeta17 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _ei);
tmpMeta16 = mmc_mk_cons(tmpMeta17, _rest);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta18;
tmpMeta18 = mmc_mk_cons(_cp, _cps);
tmpMeta1 = tmpMeta18;
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
_ocp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ocp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassLoader_loadCompletePackageFromMp(threadData_t *threadData, modelica_string _id, modelica_string _inIdent, modelica_string _inString, modelica_metatype _strategy, modelica_metatype _inWithin, modelica_integer _numError, modelica_boolean _encrypted)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_string tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inIdent;
tmp4_2 = _inString;
tmp4_3 = _inWithin;
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
modelica_metatype _opt_cl = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _path = NULL;
modelica_metatype _w2 = NULL;
modelica_metatype _reverseOrder = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_metatype tmpMeta15;
modelica_integer tmp16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
_pack = tmp4_1;
_mp = tmp4_2;
_within_ = tmp4_3;
_pd = _OMC_LIT20;
tmpMeta6 = mmc_mk_cons(_mp, mmc_mk_cons(_pd, mmc_mk_cons(_pack, MMC_REFSTRUCTLIT(mmc_nil))));
_mp_1 = stringAppendList(tmpMeta6);
tmpMeta7 = mmc_mk_cons(_mp_1, mmc_mk_cons(_pd, mmc_mk_cons((_encrypted?_OMC_LIT21:_OMC_LIT22), MMC_REFSTRUCTLIT(mmc_nil))));
_packagefile = stringAppendList(tmpMeta7);
tmpMeta8 = mmc_mk_cons(_mp_1, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT75, MMC_REFSTRUCTLIT(mmc_nil))));
_orderfile = stringAppendList(tmpMeta8);
if((!omc_System_regularFileExists(threadData, _packagefile)))
{
tmpMeta9 = stringAppend(_OMC_LIT71,_packagefile);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT72);
omc_Error_addInternalError(threadData, tmpMeta10, _OMC_LIT76);
goto goto_2;
}
_opt_cl = omc_ClassLoader_parsePackageFile(threadData, _packagefile, _strategy, 1, _within_, _id, _encrypted);
if(isSome(_opt_cl))
{
tmpMeta11 = omc_Util_getOption(threadData, _opt_cl);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmp14 = mmc_unbox_integer(tmpMeta13);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
tmp16 = mmc_unbox_integer(tmpMeta15);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 5));
tmp18 = mmc_unbox_integer(tmpMeta17);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 6));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,5) == 0) goto goto_2;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 3));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 4));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 6));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 8));
_class_ = tmpMeta11;
_name = tmpMeta12;
_pp = tmp14;
_fp = tmp16;
_ep = tmp18;
_r = tmpMeta19;
_tv = tmpMeta21;
_ca = tmpMeta22;
_cp = tmpMeta23;
_ann = tmpMeta24;
_cmt = tmpMeta25;
_info = tmpMeta26;
_reverseOrder = omc_ClassLoader_getPackageContentNames(threadData, _class_, _orderfile, _mp_1, omc_Error_getNumErrorMessages(threadData), _encrypted);
tmpMeta27 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
_path = omc_AbsynUtil_joinWithinPath(threadData, _within_, tmpMeta27);
tmpMeta28 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
_w2 = tmpMeta28;
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
_cp = omc_List_fold4(threadData, _reverseOrder, boxvar_ClassLoader_loadCompletePackageFromMp2, _mp_1, _strategy, _w2, mmc_mk_boolean(_encrypted), tmpMeta29);
tmpMeta30 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _tv, _ca, _cp, _ann, _cmt);
tmpMeta31 = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _name, mmc_mk_boolean(_pp), mmc_mk_boolean(_fp), mmc_mk_boolean(_ep), _r, tmpMeta30, _info);
_opt_cl = mmc_mk_some(tmpMeta31);
}
tmpMeta1 = _opt_cl;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
_pack = tmp4_1;
_mp = tmp4_2;
tmp32 = (_numError == omc_Error_getNumErrorMessages(threadData));
if (1 != tmp32) goto goto_2;
tmpMeta33 = stringAppend(_OMC_LIT77,_mp);
tmpMeta34 = stringAppend(tmpMeta33,_OMC_LIT78);
tmpMeta35 = stringAppend(tmpMeta34,_pack);
omc_Error_addInternalError(threadData, tmpMeta35, _OMC_LIT79);
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
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_cl = tmpMeta1;
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta19;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pd = _OMC_LIT20;
if(_encrypted)
{
tmpMeta2 = stringAppend(_dir,_pd);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT21);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp9;
modelica_metatype _f_loopVar = 0;
modelica_metatype _f;
_f_loopVar = omc_System_mocFiles(threadData, _dir);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta6;
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp9 = 1;
if (!listEmpty(_f_loopVar)) {
_f = MMC_CAR(_f_loopVar);
_f_loopVar = MMC_CDR(_f_loopVar);
tmp9--;
}
if (tmp9 == 0) {
tmpMeta7 = stringAppend(_dir,_pd);
tmpMeta8 = stringAppend(tmpMeta7,_f);
__omcQ_24tmpVar0 = tmpMeta8;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp9 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta4 = __omcQ_24tmpVar1;
}
tmpMeta1 = mmc_mk_cons(tmpMeta3, listAppend(tmpMeta4, _acc));
_files = tmpMeta1;
}
else
{
tmpMeta11 = stringAppend(_dir,_pd);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT22);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_string __omcQ_24tmpVar2;
modelica_integer tmp18;
modelica_metatype _f_loopVar = 0;
modelica_metatype _f;
_f_loopVar = omc_System_moFiles(threadData, _dir);
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar3;
while(1) {
tmp18 = 1;
if (!listEmpty(_f_loopVar)) {
_f = MMC_CAR(_f_loopVar);
_f_loopVar = MMC_CDR(_f_loopVar);
tmp18--;
}
if (tmp18 == 0) {
tmpMeta16 = stringAppend(_dir,_pd);
tmpMeta17 = stringAppend(tmpMeta16,_f);
__omcQ_24tmpVar2 = tmpMeta17;
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp18 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar3;
}
tmpMeta10 = mmc_mk_cons(tmpMeta12, listAppend(tmpMeta13, _acc));
_files = tmpMeta10;
}
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_string __omcQ_24tmpVar4;
modelica_integer tmp24;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = omc_List_filter2OnTrue(threadData, omc_System_subDirectories(threadData, _dir), boxvar_ClassLoader_existPackage, _dir, mmc_mk_boolean(_encrypted));
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta21;
tmp20 = &__omcQ_24tmpVar5;
while(1) {
tmp24 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp24--;
}
if (tmp24 == 0) {
tmpMeta22 = stringAppend(_dir,_pd);
tmpMeta23 = stringAppend(tmpMeta22,_d);
__omcQ_24tmpVar4 = tmpMeta23;
*tmp20 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp20 = &MMC_CDR(*tmp20);
} else if (tmp24 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp20 = mmc_mk_nil();
tmpMeta19 = __omcQ_24tmpVar5;
}
_subdirs = tmpMeta19;
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
DLLExport
modelica_metatype omc_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_string _id, modelica_string _path, modelica_string _name, modelica_boolean _isDir, modelica_metatype _optEncoding, modelica_boolean _encrypted)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;
tmp4_1 = _isDir;
{
modelica_string _pd = NULL;
modelica_string _encoding = NULL;
modelica_string _encodingfile = NULL;
modelica_metatype _cl = NULL;
modelica_metatype _filenames = NULL;
modelica_metatype _strategy = NULL;
modelica_boolean _lveStarted;
modelica_metatype _lveInstance = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (0 != tmp4_1) goto tmp3_end;
_pd = _OMC_LIT20;
tmpMeta6 = mmc_mk_cons(_path, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT80, MMC_REFSTRUCTLIT(mmc_nil))));
_encodingfile = stringAppendList(tmpMeta6);
_encoding = omc_System_trimChar(threadData, omc_System_trimChar(threadData, (omc_System_regularFileExists(threadData, _encodingfile)?omc_System_readFile(threadData, _encodingfile):omc_Util_getOptionOrDefault(threadData, _optEncoding, _OMC_LIT81)), _OMC_LIT31), _OMC_LIT82);
tmpMeta7 = mmc_mk_box2(4, &ClassLoader_LoadFileStrategy_STRATEGY__ON__DEMAND__desc, _encoding);
_strategy = tmpMeta7;
tmpMeta8 = stringAppend(_path,_pd);
tmpMeta9 = stringAppend(tmpMeta8,_name);
tmpMeta1 = omc_ClassLoader_parsePackageFile(threadData, tmpMeta9, _strategy, 0, _OMC_LIT83, _id, _encrypted);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (1 != tmp4_1) goto tmp3_end;
_pd = _OMC_LIT20;
tmpMeta10 = mmc_mk_cons(_path, mmc_mk_cons(_pd, mmc_mk_cons(_name, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT80, MMC_REFSTRUCTLIT(mmc_nil))))));
_encodingfile = stringAppendList(tmpMeta10);
_encoding = omc_System_trimChar(threadData, omc_System_trimChar(threadData, (omc_System_regularFileExists(threadData, _encodingfile)?omc_System_readFile(threadData, _encodingfile):omc_Util_getOptionOrDefault(threadData, _optEncoding, _OMC_LIT81)), _OMC_LIT31), _OMC_LIT82);
_lveInstance = mmc_mk_none();
if(_encrypted)
{
tmpMeta11 = stringAppend(_path,_pd);
tmpMeta12 = stringAppend(tmpMeta11,_name);
_lveStarted = omc_Parser_startLibraryVendorExecutable(threadData, tmpMeta12 ,&_lveInstance);
if((!_lveStarted))
{
goto goto_2;
}
}
if(((omc_Testsuite_isRunning(threadData) || (omc_Config_noProc(threadData) == ((modelica_integer) 1))) && (!_encrypted)))
{
tmpMeta13 = mmc_mk_box2(4, &ClassLoader_LoadFileStrategy_STRATEGY__ON__DEMAND__desc, _encoding);
_strategy = tmpMeta13;
}
else
{
tmpMeta14 = stringAppend(_path,_pd);
tmpMeta15 = stringAppend(tmpMeta14,_name);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_filenames = omc_ClassLoader_getAllFilesFromDirectory(threadData, tmpMeta15, _encrypted, tmpMeta16);
tmpMeta17 = stringAppend(_path,_pd);
tmpMeta18 = stringAppend(tmpMeta17,_name);
tmpMeta19 = mmc_mk_box2(3, &ClassLoader_LoadFileStrategy_STRATEGY__HASHTABLE__desc, omc_Parser_parallelParseFiles(threadData, _filenames, _encoding, omc_Config_noProc(threadData), tmpMeta18, _lveInstance));
_strategy = tmpMeta19;
}
_cl = omc_ClassLoader_loadCompletePackageFromMp(threadData, _id, _name, _path, _strategy, _OMC_LIT83, omc_Error_getNumErrorMessages(threadData), _encrypted);
if((_encrypted && _lveStarted))
{
omc_Parser_stopLibraryVendorExecutable(threadData, _lveInstance);
}
tmpMeta1 = _cl;
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ClassLoader_loadClassFromMp(threadData_t *threadData, modelica_metatype _id, modelica_metatype _path, modelica_metatype _name, modelica_metatype _isDir, modelica_metatype _optEncoding, modelica_metatype _encrypted)
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
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_string tmp24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp8_1)) goto tmp7_end;
tmpMeta10 = MMC_CAR(tmp8_1);
tmpMeta11 = MMC_CDR(tmp8_1);
_version = tmpMeta10;
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
tmpMeta13 = stringAppend(_OMC_LIT85,_id);
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT89);
tmpMeta12 = mmc_mk_cons(tmpMeta14, MMC_REFSTRUCTLIT(mmc_nil));
_commands = tmpMeta12;
}
else
{
tmpMeta16 = stringAppend(_OMC_LIT85,_id);
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT86);
tmpMeta18 = stringAppend(tmpMeta17,_version);
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT87);
tmpMeta20 = stringAppend(_OMC_LIT85,_id);
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT86);
tmpMeta22 = stringAppend(tmpMeta21,_version);
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT88);
tmp24 = modelica_boolean_to_modelica_string(listMember(_version, _versionsThatProvideTheWanted), ((modelica_integer) 0), 1);
tmpMeta25 = stringAppend(tmpMeta23,tmp24);
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT89);
tmpMeta15 = mmc_mk_cons(tmpMeta19, mmc_mk_cons(tmpMeta26, MMC_REFSTRUCTLIT(mmc_nil)));
_commands = tmpMeta15;
}
if((!stringEqual(listHead(_versionsThatProvideTheWanted), _version)))
{
tmpMeta28 = stringAppend(_OMC_LIT85,_id);
tmpMeta29 = stringAppend(tmpMeta28,_OMC_LIT86);
tmpMeta30 = stringAppend(tmpMeta29,listHead(_versionsThatProvideTheWanted));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT90);
tmpMeta27 = mmc_mk_cons(tmpMeta31, _commands);
_commands = tmpMeta27;
}
tmpMeta32 = mmc_mk_cons(stringDelimitList(_commands, _OMC_LIT31), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT93, tmpMeta32);
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
if(isSome(_cl))
{
tmpMeta33 = mmc_mk_cons(omc_Util_getOption(threadData, _cl), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta34 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta33, _OMC_LIT83);
_outProgram = tmpMeta34;
}
else
{
_outProgram = _OMC_LIT94;
}
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;
tmp4_1 = _inPath;
tmp4_2 = _modelicaPath;
{
modelica_string _gd = NULL;
modelica_string _classname = NULL;
modelica_string _mp = NULL;
modelica_string _pack = NULL;
modelica_metatype _mps = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_classname = tmpMeta6;
_mp = tmp4_2;
tmp4 += 1;
_gd = _OMC_LIT95;
_mps = omc_System_strtok(threadData, _mp, _gd);
_p = omc_ClassLoader_loadClassFromMps(threadData, _classname, _priorityList, _mps, _encoding, _requireExactVersion, _encrypted);
omc_ClassLoader_checkOnLoadMessage(threadData, _p);
tmpMeta1 = _p;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_pack = tmpMeta7;
_mp = tmp4_2;
_gd = _OMC_LIT95;
_mps = omc_System_strtok(threadData, _mp, _gd);
_p = omc_ClassLoader_loadClassFromMps(threadData, _pack, _priorityList, _mps, _encoding, _requireExactVersion, _encrypted);
omc_ClassLoader_checkOnLoadMessage(threadData, _p);
tmpMeta1 = _p;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp8;
tmp8 = omc_Flags_isSet(threadData, _OMC_LIT99);
if (1 != tmp8) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT100);
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
_outProgram = tmpMeta1;
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

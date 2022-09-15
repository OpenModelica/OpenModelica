#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ExpressionDump.c"
#endif
#include "omc_simulation_settings.h"
#include "ExpressionDump.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data " (local)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,8,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data " (global)"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,9,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "Clock()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,7,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "Clock("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,2,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,1,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "1:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,2,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "--------------------\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,21,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,1,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,7,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,1,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data " =!= "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,5,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "   |"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,4,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "ICONST "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,7,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "RCONST "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,7,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "SCONST \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,8,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "\"\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,2,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "BCONST false\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,13,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "BCONST true\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,12,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "CLKCONST "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,9,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "ENUM_LITERAL "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,13,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data " ["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,2,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "]\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,2,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "CREF "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,5,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data " CREFTYPE:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,10,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "BINARY "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,7,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,1,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "expType:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,8,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data " optype:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,8,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "UNARY "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,6,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "LBINARY "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,8,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "LUNARY "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,7,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "RELATION "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,9,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "IFEXP \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,7,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "CALL "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,5,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,4,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,5,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "ARRAY scalar:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,13,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data " tp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,5,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "TUPLE "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,6,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "},{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,3,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "MATRIX \n{{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,10,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "}}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,3,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "RANGE \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,7,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "CAST \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,6,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,1,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,1,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "ASUB "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,5,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "ASUB \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,6,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "SIZE \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,6,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "REDUCTION \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,11,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "RECORD "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,7,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "RSUB "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,5,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data " fieldName: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,12,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "BOX \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,5,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "UNBOX \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,7,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data " UNKNOWN EXPRESSION ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,21,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "ICONST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,6,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "RCONST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,6,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "SCONST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,6,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "BCONST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,6,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "CREF"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,4,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "BINARY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,6,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "UNARY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,5,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "LBINARY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,7,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "LUNARY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,6,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "RELATION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,8,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "IFEXP"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,5,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "CALL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,4,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "PARTEVALFUNCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,16,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "ARRAY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,5,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "TUPLE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,5,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "{{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,2,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "}}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,2,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "MATRIX"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,6,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,4,3) {&Graphviz_Node_NODE__desc,_OMC_LIT9,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "RANGE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,5,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "CAST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,4,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "ASUB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,4,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "SIZE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,4,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "REDUCTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,9,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data "#UNKNOWN EXPRESSION# ----eeestr "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,32,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,4,3) {&Graphviz_Node_NODE__desc,_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "    case "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,9,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data " then "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,6,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data ";\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,2,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data " then fail();\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,14,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "\n      algorithm\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,17,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "      then "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,11,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "      then fail();\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,19,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "matchcontinue"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,13,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "match"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,5,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "match /* switch */"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,18,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data " in "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,4,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
#define _OMC_LIT102_data " guard "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT102,7,_OMC_LIT102_data);
#define _OMC_LIT102 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data "ENUM_LITERAL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,12,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
#define _OMC_LIT104_data "TSUB"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT104,4,_OMC_LIT104_data);
#define _OMC_LIT104 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT104)
#define _OMC_LIT105_data "CODE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT105,4,_OMC_LIT105_data);
#define _OMC_LIT105 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data "EMPTY"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,5,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "LIST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,4,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
#define _OMC_LIT108_data "CAR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT108,3,_OMC_LIT108_data);
#define _OMC_LIT108 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data "META_TUPLE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,10,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "META_OPTION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,11,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "METARECORDCALL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,14,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "MATCHEXPRESSION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,15,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "BOX"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,3,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
#define _OMC_LIT114_data "UNBOX"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT114,5,_OMC_LIT114_data);
#define _OMC_LIT114 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data "SHARED_LITERAL"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,14,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data "PATTERN"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,7,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data "#UNKNOWN EXPRESSION#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,20,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data "<EMPTY(scope: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,14,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data ", name: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,8,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data ", ty: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,6,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
#define _OMC_LIT121_data ")>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT121,2,_OMC_LIT121_data);
#define _OMC_LIT121 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,1,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "dataReconciliation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,18,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
#define _OMC_LIT124_data "preOptModules+"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT124,14,_OMC_LIT124_data);
#define _OMC_LIT124 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,2,9) {&Flags_FlagData_STRING__LIST__FLAG__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
#define _OMC_LIT127_data "Enables additional pre-optimization modules, e.g. --preOptModules+=module1,module2 would additionally enable module1 and module2. See --help=optmodules for more info."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT127,166,_OMC_LIT127_data);
#define _OMC_LIT127 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT127}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT129,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(76)),_OMC_LIT124,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT125,_OMC_LIT126,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT128}};
#define _OMC_LIT129 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "if "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,3,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data " else "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,6,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "function "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,9,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "DAE.CAST("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,9,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "size("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,5,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "<reduction>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,11,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data " for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,5,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data "Tuple"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,5,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
#define _OMC_LIT138_data "List("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT138,5,_OMC_LIT138_data);
#define _OMC_LIT138 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data "listCons("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,9,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
#define _OMC_LIT140_data "NONE()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT140,6,_OMC_LIT140_data);
#define _OMC_LIT140 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT140)
#define _OMC_LIT141_data "SOME("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT141,5,_OMC_LIT141_data);
#define _OMC_LIT141 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT141)
#define _OMC_LIT142_data "#("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT142,2,_OMC_LIT142_data);
#define _OMC_LIT142 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT142)
#define _OMC_LIT143_data "unbox("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT143,6,_OMC_LIT143_data);
#define _OMC_LIT143 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT143)
#define _OMC_LIT144_data "  end "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT144,6,_OMC_LIT144_data);
#define _OMC_LIT144 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT144)
#define _OMC_LIT145_data "$Code("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT145,6,_OMC_LIT145_data);
#define _OMC_LIT145 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data " , "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,3,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data " < "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,3,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
#define _OMC_LIT148_data " <= "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT148,4,_OMC_LIT148_data);
#define _OMC_LIT148 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT148)
#define _OMC_LIT149_data " > "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT149,3,_OMC_LIT149_data);
#define _OMC_LIT149 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT149)
#define _OMC_LIT150_data " >= "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT150,4,_OMC_LIT150_data);
#define _OMC_LIT150 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT150)
#define _OMC_LIT151_data " == "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT151,4,_OMC_LIT151_data);
#define _OMC_LIT151 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data " <> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,4,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
#define _OMC_LIT153_data "not "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT153,4,_OMC_LIT153_data);
#define _OMC_LIT153 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT153)
#define _OMC_LIT154_data " and "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT154,5,_OMC_LIT154_data);
#define _OMC_LIT154 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT154)
#define _OMC_LIT155_data " or "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT155,4,_OMC_LIT155_data);
#define _OMC_LIT155 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT155)
#define _OMC_LIT156_data "-<UMINUS>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT156,9,_OMC_LIT156_data);
#define _OMC_LIT156 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT156)
#define _OMC_LIT157_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT157,1,_OMC_LIT157_data);
#define _OMC_LIT157 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT157)
#define _OMC_LIT158_data "-<UMINUS_ARR>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT158,13,_OMC_LIT158_data);
#define _OMC_LIT158 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT158)
#define _OMC_LIT159_data " +<"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT159,3,_OMC_LIT159_data);
#define _OMC_LIT159 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT159)
#define _OMC_LIT160_data "> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT160,2,_OMC_LIT160_data);
#define _OMC_LIT160 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT160)
#define _OMC_LIT161_data " -<"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT161,3,_OMC_LIT161_data);
#define _OMC_LIT161 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data " *<"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,3,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
#define _OMC_LIT163_data " /<"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT163,3,_OMC_LIT163_data);
#define _OMC_LIT163 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT163)
#define _OMC_LIT164_data " ^ "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT164,3,_OMC_LIT164_data);
#define _OMC_LIT164 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT164)
#define _OMC_LIT165_data " +<ADD_ARR><"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT165,12,_OMC_LIT165_data);
#define _OMC_LIT165 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT165)
#define _OMC_LIT166_data " -<SUB_ARR><"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT166,12,_OMC_LIT166_data);
#define _OMC_LIT166 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT166)
#define _OMC_LIT167_data " *<MUL_ARRAY> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT167,14,_OMC_LIT167_data);
#define _OMC_LIT167 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT167)
#define _OMC_LIT168_data " /<DIV_ARR><"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT168,12,_OMC_LIT168_data);
#define _OMC_LIT168 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT168)
#define _OMC_LIT169_data " ^<POW_ARR> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT169,12,_OMC_LIT169_data);
#define _OMC_LIT169 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT169)
#define _OMC_LIT170_data " ^<POW_ARR2> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT170,13,_OMC_LIT170_data);
#define _OMC_LIT170 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT170)
#define _OMC_LIT171_data " *<MUL_ARRAY_SCALAR> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT171,21,_OMC_LIT171_data);
#define _OMC_LIT171 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT171)
#define _OMC_LIT172_data " +<ADD_ARRAY_SCALAR> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT172,21,_OMC_LIT172_data);
#define _OMC_LIT172 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT172)
#define _OMC_LIT173_data " -<SUB_SCALAR_ARRAY> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT173,21,_OMC_LIT173_data);
#define _OMC_LIT173 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT173)
#define _OMC_LIT174_data " ^<POW_SCALAR_ARRAY> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT174,21,_OMC_LIT174_data);
#define _OMC_LIT174 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT174)
#define _OMC_LIT175_data " ^<POW_ARRAY_SCALAR> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT175,21,_OMC_LIT175_data);
#define _OMC_LIT175 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT175)
#define _OMC_LIT176_data " *<MUL_SCALAR_PRODUCT> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT176,23,_OMC_LIT176_data);
#define _OMC_LIT176 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT176)
#define _OMC_LIT177_data " *<MUL_MATRIX_PRODUCT> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT177,23,_OMC_LIT177_data);
#define _OMC_LIT177 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT177)
#define _OMC_LIT178_data " /<DIV_SCALAR_ARRAY> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT178,21,_OMC_LIT178_data);
#define _OMC_LIT178 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT178)
#define _OMC_LIT179_data " /<DIV_ARRAY_SCALAR> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT179,21,_OMC_LIT179_data);
#define _OMC_LIT179 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT179)
#define _OMC_LIT180_data " + "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT180,3,_OMC_LIT180_data);
#define _OMC_LIT180 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT180)
#define _OMC_LIT181_data " - "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT181,3,_OMC_LIT181_data);
#define _OMC_LIT181 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT181)
#define _OMC_LIT182_data " * "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT182,3,_OMC_LIT182_data);
#define _OMC_LIT182 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT182)
#define _OMC_LIT183_data " / "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT183,3,_OMC_LIT183_data);
#define _OMC_LIT183 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT183)
#define _OMC_LIT184_data " = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT184,3,_OMC_LIT184_data);
#define _OMC_LIT184 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT184)
#define _OMC_LIT185_data " +ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT185,6,_OMC_LIT185_data);
#define _OMC_LIT185 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT185)
#define _OMC_LIT186_data " -ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT186,6,_OMC_LIT186_data);
#define _OMC_LIT186 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT186)
#define _OMC_LIT187_data " *ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT187,6,_OMC_LIT187_data);
#define _OMC_LIT187 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT187)
#define _OMC_LIT188_data " /ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT188,6,_OMC_LIT188_data);
#define _OMC_LIT188 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT188)
#define _OMC_LIT189_data " ^ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT189,6,_OMC_LIT189_data);
#define _OMC_LIT189 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT189)
#define _OMC_LIT190_data " ^ARR2 "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT190,7,_OMC_LIT190_data);
#define _OMC_LIT190 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT190)
#define _OMC_LIT191_data " ARR*S "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT191,7,_OMC_LIT191_data);
#define _OMC_LIT191 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT191)
#define _OMC_LIT192_data " ARR+S "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT192,7,_OMC_LIT192_data);
#define _OMC_LIT192 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT192)
#define _OMC_LIT193_data " S^ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT193,7,_OMC_LIT193_data);
#define _OMC_LIT193 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT193)
#define _OMC_LIT194_data " ARR^S "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT194,7,_OMC_LIT194_data);
#define _OMC_LIT194 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT194)
#define _OMC_LIT195_data " Dot "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT195,5,_OMC_LIT195_data);
#define _OMC_LIT195 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT195)
#define _OMC_LIT196_data " MatrixProd "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT196,12,_OMC_LIT196_data);
#define _OMC_LIT196 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT196)
#define _OMC_LIT197_data " S/ARR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT197,7,_OMC_LIT197_data);
#define _OMC_LIT197 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT197)
#define _OMC_LIT198_data " ARR/S "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT198,7,_OMC_LIT198_data);
#define _OMC_LIT198 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT198)
#define _OMC_LIT199_data " <UNKNOWN_SYMBOL> "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT199,18,_OMC_LIT199_data);
#define _OMC_LIT199 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT199)
#include "util/modelica.h"
#include "ExpressionDump_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printExpIfDiff(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_printExpIfDiff,2,0) {(void*) boxptr_ExpressionDump_printExpIfDiff,0}};
#define boxvar_ExpressionDump_printExpIfDiff MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_printExpIfDiff)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_genStringNTime(threadData_t *threadData, modelica_string _inString, modelica_integer _inInteger);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionDump_genStringNTime(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_genStringNTime,2,0) {(void*) boxptr_ExpressionDump_genStringNTime,0}};
#define boxvar_ExpressionDump_genStringNTime MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_genStringNTime)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printCase2Str(threadData_t *threadData, modelica_metatype _matchCase);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_printCase2Str,2,0) {(void*) boxptr_ExpressionDump_printCase2Str,0}};
#define boxvar_ExpressionDump_printCase2Str MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_printCase2Str)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printMatchType(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_printMatchType,2,0) {(void*) boxptr_ExpressionDump_printMatchType,0}};
#define boxvar_ExpressionDump_printMatchType MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_printMatchType)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_reductionIteratorStr(threadData_t *threadData, modelica_metatype _riter);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_reductionIteratorStr,2,0) {(void*) boxptr_ExpressionDump_reductionIteratorStr,0}};
#define boxvar_ExpressionDump_reductionIteratorStr MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_reductionIteratorStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printExpTypeStr(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_printExpTypeStr,2,0) {(void*) boxptr_ExpressionDump_printExpTypeStr,0}};
#define boxvar_ExpressionDump_printExpTypeStr MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_printExpTypeStr)
PROTECTED_FUNCTION_STATIC void omc_ExpressionDump_printRow(threadData_t *threadData, modelica_metatype _es_1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_printRow,2,0) {(void*) boxptr_ExpressionDump_printRow,0}};
#define boxvar_ExpressionDump_printRow MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_printRow)
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_binopSymbol2(threadData_t *threadData, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionDump_binopSymbol2,2,0) {(void*) boxptr_ExpressionDump_binopSymbol2,0}};
#define boxvar_ExpressionDump_binopSymbol2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionDump_binopSymbol2)
DLLExport
modelica_string omc_ExpressionDump_constraintDTlistToString(threadData_t *threadData, modelica_metatype _cons, modelica_string _delim)
{
modelica_string _str = NULL;
modelica_metatype _c = NULL;
modelica_boolean _localCon;
modelica_metatype _con = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT0;
{
modelica_metatype _con;
for (tmpMeta1 = _cons; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_con = MMC_CAR(tmpMeta1);
tmpMeta2 = stringAppend(_str,_delim);
tmpMeta3 = stringAppend(tmpMeta2,omc_ExpressionDump_constraintDTtoString(threadData, _con));
_str = tmpMeta3;
}
}
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_constraintDTtoString(threadData_t *threadData, modelica_metatype _con)
{
modelica_string _str = NULL;
modelica_metatype _c = NULL;
modelica_boolean _localCon;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_string tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _con;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,1,2) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
_c = tmpMeta2;
_localCon = tmp4;
_str = omc_ExpressionDump_printExpStr(threadData, _c);
tmp7 = (modelica_boolean)_localCon;
if(tmp7)
{
tmpMeta5 = stringAppend(_str,_OMC_LIT1);
tmp8 = tmpMeta5;
}
else
{
tmpMeta6 = stringAppend(_str,_OMC_LIT2);
tmp8 = tmpMeta6;
}
_str = tmp8;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_clockKindString(threadData_t *threadData, modelica_metatype _inClockKind)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClockKind;
{
modelica_metatype _c = NULL;
modelica_metatype _intervalCounter = NULL;
modelica_metatype _interval = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _resolution = NULL;
modelica_metatype _startInterval = NULL;
modelica_metatype _solverMethod = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT3;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_intervalCounter = tmpMeta5;
_resolution = tmpMeta6;
tmpMeta7 = stringAppend(_OMC_LIT4,omc_ExpressionDump_dumpExpStr(threadData, _intervalCounter, ((modelica_integer) 0)));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT5);
tmpMeta9 = stringAppend(tmpMeta8,omc_ExpressionDump_dumpExpStr(threadData, _resolution, ((modelica_integer) 0)));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT6);
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_interval = tmpMeta11;
tmpMeta12 = stringAppend(_OMC_LIT4,omc_ExpressionDump_dumpExpStr(threadData, _interval, ((modelica_integer) 0)));
tmpMeta13 = stringAppend(tmpMeta12,_OMC_LIT6);
tmp1 = tmpMeta13;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_condition = tmpMeta14;
_startInterval = tmpMeta15;
tmpMeta16 = stringAppend(_OMC_LIT4,omc_ExpressionDump_dumpExpStr(threadData, _condition, ((modelica_integer) 0)));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT5);
tmpMeta18 = stringAppend(tmpMeta17,omc_ExpressionDump_dumpExpStr(threadData, _startInterval, ((modelica_integer) 0)));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT6);
tmp1 = tmpMeta19;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_c = tmpMeta20;
_solverMethod = tmpMeta21;
tmpMeta22 = stringAppend(_OMC_LIT4,omc_ExpressionDump_dumpExpStr(threadData, _c, ((modelica_integer) 0)));
tmpMeta23 = stringAppend(tmpMeta22,_OMC_LIT5);
tmpMeta24 = stringAppend(tmpMeta23,omc_ExpressionDump_dumpExpStr(threadData, _solverMethod, ((modelica_integer) 0)));
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT6);
tmp1 = tmpMeta25;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_parenthesize(threadData_t *threadData, modelica_string _inString1, modelica_integer _inInteger2, modelica_integer _inInteger3, modelica_boolean _rightOpParenthesis)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_integer tmp4_2;volatile modelica_integer tmp4_3;volatile modelica_boolean tmp4_4;
tmp4_1 = _inString1;
tmp4_2 = _inInteger2;
tmp4_3 = _inInteger3;
tmp4_4 = _rightOpParenthesis;
{
modelica_string _str = NULL;
modelica_integer _pparent;
modelica_integer _pexpr;
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
_str = tmp4_1;
_pparent = tmp4_2;
_pexpr = tmp4_3;
if((!(_pparent > _pexpr)))
{
goto goto_2;
}
tmpMeta6 = mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta6);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (1 != tmp4_4) goto tmp3_end;
_str = tmp4_1;
_pparent = tmp4_2;
_pexpr = tmp4_3;
if((!(_pparent == _pexpr)))
{
goto goto_2;
}
tmpMeta7 = mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta7);
goto tmp3_done;
}
case 2: {
_str = tmp4_1;
tmp1 = _str;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_ExpressionDump_parenthesize(threadData_t *threadData, modelica_metatype _inString1, modelica_metatype _inInteger2, modelica_metatype _inInteger3, modelica_metatype _rightOpParenthesis)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inInteger2);
tmp2 = mmc_unbox_integer(_inInteger3);
tmp3 = mmc_unbox_integer(_rightOpParenthesis);
_outString = omc_ExpressionDump_parenthesize(threadData, _inString1, tmp1, tmp2, tmp3);
return _outString;
}
DLLExport
void omc_ExpressionDump_printExp(threadData_t *threadData, modelica_metatype _e)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Tpl_tplPrint2(threadData, boxvar_ExpressionDumpTpl_dumpExp, _e, _OMC_LIT8);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_ExpressionDump_printSubscript(threadData_t *threadData, modelica_metatype _inSubscript)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inSubscript;
{
modelica_metatype _e1 = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
omc_Print_printBuf(threadData, _OMC_LIT9);
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta4;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta4;
omc_ExpressionDump_printExp(threadData, _e1);
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta5;
omc_ExpressionDump_printExp(threadData, _e1);
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta6;
omc_Print_printBuf(threadData, _OMC_LIT10);
omc_ExpressionDump_printExp(threadData, _e1);
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
DLLExport
void omc_ExpressionDump_dumpExp(threadData_t *threadData, modelica_metatype _exp)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_ExpressionDump_dumpExpStr(threadData, _exp, ((modelica_integer) 0));
fputs(MMC_STRINGDATA(_str),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT11),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_ExpressionDump_dumpExpWithTitle(threadData_t *threadData, modelica_string _title, modelica_metatype _exp)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_ExpressionDump_dumpExpStr(threadData, _exp, ((modelica_integer) 0));
fputs(MMC_STRINGDATA(_title),stdout);
fputs(MMC_STRINGDATA(_str),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT12),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_ExpressionDump_dimensionIntString(threadData_t *threadData, modelica_metatype _dim)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _dim;
{
modelica_integer _x;
modelica_integer _size;
modelica_metatype _e = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 7: {
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp6 = mmc_unbox_integer(tmpMeta5);
_size = tmp6;
tmp1 = intString(_size);
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT13;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_x = tmp8;
tmp1 = intString(_x);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta9;
tmp1 = omc_ExpressionDump_printExpStr(threadData, _e);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_dimensionsString(threadData_t *threadData, modelica_metatype _dims)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = stringDelimitList(omc_List_map(threadData, _dims, boxvar_ExpressionDump_dimensionString), _OMC_LIT14);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_dimensionString(threadData_t *threadData, modelica_metatype _dim)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _dim;
{
modelica_integer _x;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 7: {
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta5;
tmp1 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT15, 1, 0);
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT16;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_x = tmp7;
tmp1 = intString(_x);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta8;
tmp1 = omc_ExpressionDump_printExpStr(threadData, _e);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_debugPrintComponentRefExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cr = NULL;
modelica_metatype _expl = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta6;
tmp4 += 1;
tmp1 = omc_ComponentReference_debugPrintComponentRefTypeStr(threadData, _cr);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_expl = tmpMeta7;
tmpMeta8 = stringAppend(_OMC_LIT17,stringAppendList(omc_List_map(threadData, _expl, boxvar_ExpressionDump_debugPrintComponentRefExp)));
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT18);
tmp1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
tmp1 = omc_ExpressionDump_printExpStr(threadData, _inExp);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_typeOfString(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_string _str = NULL;
modelica_metatype _ty = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Expression_typeof(threadData, _inExp);
_str = omc_Types_unparseType(threadData, _ty);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_printArraySizes(threadData_t *threadData, modelica_metatype _inLst)
{
modelica_string _out = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inLst;
{
modelica_integer _x;
modelica_metatype _lst = NULL;
modelica_string _s = NULL;
modelica_string _s2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmp9 = mmc_unbox_integer(tmpMeta8);
_x = tmp9;
_lst = tmpMeta7;
_s = omc_ExpressionDump_printArraySizes(threadData, _lst);
_s2 = intString(_x);
tmpMeta10 = stringAppend(_s2,_s);
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
_lst = tmpMeta12;
tmp1 = omc_ExpressionDump_printArraySizes(threadData, _lst);
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
_out = tmp1;
_return: OMC_LABEL_UNUSED
return _out;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printExpIfDiff(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_string _s = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_boolean tmp4;
modelica_string tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp4 = (modelica_boolean)omc_Expression_expEqual(threadData, _e1, _e2);
if(tmp4)
{
tmp5 = _OMC_LIT0;
}
else
{
tmpMeta1 = stringAppend(omc_ExpressionDump_printExpStr(threadData, _e1),_OMC_LIT19);
tmpMeta2 = stringAppend(tmpMeta1,omc_ExpressionDump_printExpStr(threadData, _e2));
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT12);
tmp5 = tmpMeta3;
}
_s = tmp5;
_return: OMC_LABEL_UNUSED
return _s;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_genStringNTime(threadData_t *threadData, modelica_string _inString, modelica_integer _inInteger)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_integer tmp4_2;
tmp4_1 = _inString;
tmp4_2 = _inInteger;
{
modelica_string _str = NULL;
modelica_string _new_str = NULL;
modelica_integer _new_level;
modelica_integer _level;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_2) goto tmp3_end;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_str = tmp4_1;
_level = tmp4_2;
_new_level = ((modelica_integer) -1) + _level;
_new_str = omc_ExpressionDump_genStringNTime(threadData, _str, _new_level);
tmpMeta6 = stringAppend(_str,_new_str);
tmp1 = tmpMeta6;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionDump_genStringNTime(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _inInteger)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inInteger);
_outString = omc_ExpressionDump_genStringNTime(threadData, _inString, tmp1);
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_dumpExpStr(threadData_t *threadData, modelica_metatype _inExp, modelica_integer _inInteger)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_integer tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inInteger;
{
modelica_string _gen_str = NULL;
modelica_string _s = NULL;
modelica_string _sym = NULL;
modelica_string _lt = NULL;
modelica_string _rt = NULL;
modelica_string _ct = NULL;
modelica_string _tt = NULL;
modelica_string _ft = NULL;
modelica_string _fs = NULL;
modelica_string _argnodes_1 = NULL;
modelica_string _nodes_1 = NULL;
modelica_string _t1 = NULL;
modelica_string _t2 = NULL;
modelica_string _t3 = NULL;
modelica_string _istr = NULL;
modelica_string _crt = NULL;
modelica_string _dimt = NULL;
modelica_string _expt = NULL;
modelica_string _itert = NULL;
modelica_string _tpStr = NULL;
modelica_string _str = NULL;
modelica_integer _level;
modelica_integer _x;
modelica_integer _new_level1;
modelica_integer _new_level2;
modelica_integer _new_level3;
modelica_integer _i;
modelica_metatype _c = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _f = NULL;
modelica_metatype _start = NULL;
modelica_metatype _stop = NULL;
modelica_metatype _step = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _iterexp = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _op = NULL;
modelica_metatype _clk = NULL;
modelica_metatype _argnodes = NULL;
modelica_metatype _nodes = NULL;
modelica_metatype _fcn = NULL;
modelica_metatype _args = NULL;
modelica_metatype _es = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _ty = NULL;
modelica_real _r;
modelica_metatype _lstes = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 32; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_x = tmp7;
_level = tmp4_2;
tmp4 += 30;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = intString(_x);
tmpMeta8 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT21, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta8);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_real tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_real(tmpMeta9);
_r = tmp10;
_level = tmp4_2;
tmp4 += 29;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = realString(_r);
tmpMeta11 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT22, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta11);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta12;
_level = tmp4_2;
tmp4 += 28;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = omc_System_escapedString(threadData, _s, 1);
tmpMeta13 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT23, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT24, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta13);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (0 != tmp15) goto tmp3_end;
_level = tmp4_2;
tmp4 += 27;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
tmpMeta16 = stringAppend(_gen_str,_OMC_LIT25);
tmp1 = tmpMeta16;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
if (1 != tmp18) goto tmp3_end;
_level = tmp4_2;
tmp4 += 26;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
tmpMeta19 = stringAppend(_gen_str,_OMC_LIT26);
tmp1 = tmpMeta19;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_clk = tmpMeta20;
_level = tmp4_2;
tmp4 += 25;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = omc_ExpressionDump_clockKindString(threadData, _clk);
tmpMeta21 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT27, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta21);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp24 = mmc_unbox_integer(tmpMeta23);
_fcn = tmpMeta22;
_i = tmp24;
_level = tmp4_2;
tmp4 += 24;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_istr = intString(_i);
tmpMeta25 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT28, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT29, mmc_mk_cons(_istr, mmc_mk_cons(_OMC_LIT30, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta25);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_c = tmpMeta26;
_ty = tmpMeta27;
_level = tmp4_2;
tmp4 += 23;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = omc_ComponentReference_debugPrintComponentRefTypeStr(threadData, _c);
_tpStr = omc_Types_unparseType(threadData, _ty);
tmpMeta28 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT31, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT32, mmc_mk_cons(_tpStr, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta28);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmp4_1;
_e1 = tmpMeta29;
_op = tmpMeta30;
_e2 = tmpMeta31;
_level = tmp4_2;
tmp4 += 22;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_sym = omc_ExpressionDump_debugBinopSymbol(threadData, _op);
_tp = omc_Expression_typeof(threadData, _exp);
_str = omc_Types_unparseType(threadData, _tp);
_lt = omc_ExpressionDump_dumpExpStr(threadData, _e1, _new_level1);
_rt = omc_ExpressionDump_dumpExpStr(threadData, _e2, _new_level2);
tmpMeta32 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT33, mmc_mk_cons(_sym, mmc_mk_cons(_OMC_LIT34, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_lt, mmc_mk_cons(_rt, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil))))))))));
tmp1 = stringAppendList(tmpMeta32);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta33;
_e = tmpMeta34;
_level = tmp4_2;
tmp4 += 21;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_sym = omc_ExpressionDump_unaryopSymbol(threadData, _op);
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta35 = stringAppend(_OMC_LIT35,omc_Types_unparseType(threadData, omc_Expression_typeof(threadData, _e)));
tmpMeta36 = stringAppend(tmpMeta35,_OMC_LIT36);
tmpMeta37 = stringAppend(tmpMeta36,omc_Types_unparseType(threadData, omc_Expression_typeofOp(threadData, _op)));
_str = tmpMeta37;
tmpMeta38 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT37, mmc_mk_cons(_sym, mmc_mk_cons(_OMC_LIT34, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))))));
tmp1 = stringAppendList(tmpMeta38);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta39;
_op = tmpMeta40;
_e2 = tmpMeta41;
_level = tmp4_2;
tmp4 += 20;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_sym = omc_ExpressionDump_lbinopSymbol(threadData, _op);
_lt = omc_ExpressionDump_dumpExpStr(threadData, _e1, _new_level1);
_rt = omc_ExpressionDump_dumpExpStr(threadData, _e2, _new_level2);
tmpMeta42 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT38, mmc_mk_cons(_sym, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_lt, mmc_mk_cons(_rt, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil))))))));
tmp1 = stringAppendList(tmpMeta42);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta43;
_e = tmpMeta44;
_level = tmp4_2;
tmp4 += 19;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_sym = omc_ExpressionDump_lunaryopSymbol(threadData, _op);
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta45 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT39, mmc_mk_cons(_sym, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta45);
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta46;
_op = tmpMeta47;
_e2 = tmpMeta48;
_level = tmp4_2;
tmp4 += 18;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_sym = omc_ExpressionDump_relopSymbol(threadData, _op);
_lt = omc_ExpressionDump_dumpExpStr(threadData, _e1, _new_level1);
_rt = omc_ExpressionDump_dumpExpStr(threadData, _e2, _new_level2);
tmpMeta49 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT40, mmc_mk_cons(_sym, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_lt, mmc_mk_cons(_rt, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil))))))));
tmp1 = stringAppendList(tmpMeta49);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta50;
_t = tmpMeta51;
_f = tmpMeta52;
_level = tmp4_2;
tmp4 += 17;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_new_level3 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _cond, _new_level1);
_tt = omc_ExpressionDump_dumpExpStr(threadData, _t, _new_level2);
_ft = omc_ExpressionDump_dumpExpStr(threadData, _f, _new_level3);
tmpMeta53 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT41, mmc_mk_cons(_ct, mmc_mk_cons(_tt, mmc_mk_cons(_ft, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta53);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta54;
_args = tmpMeta55;
_level = tmp4_2;
tmp4 += 16;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_new_level1 = ((modelica_integer) 1) + _level;
_argnodes = omc_List_map1(threadData, _args, boxvar_ExpressionDump_dumpExpStr, mmc_mk_integer(_new_level1));
_argnodes_1 = stringAppendList(_argnodes);
tmpMeta56 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT42, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_argnodes_1, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta56);
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,4) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta57;
_args = tmpMeta58;
_level = tmp4_2;
tmp4 += 15;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_new_level1 = ((modelica_integer) 1) + _level;
_argnodes = omc_List_map1(threadData, _args, boxvar_ExpressionDump_dumpExpStr, mmc_mk_integer(_new_level1));
_argnodes_1 = stringAppendList(_argnodes);
tmpMeta59 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT42, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_argnodes_1, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta59);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_integer tmp62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp62 = mmc_unbox_integer(tmpMeta61);
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta60;
_b = tmp62;
_es = tmpMeta63;
_level = tmp4_2;
tmp4 += 14;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_nodes = omc_List_map1(threadData, _es, boxvar_ExpressionDump_dumpExpStr, mmc_mk_integer(_new_level1));
_nodes_1 = stringAppendList(_nodes);
_s = (_b?_OMC_LIT43:_OMC_LIT44);
_tpStr = omc_Types_unparseType(threadData, _tp);
tmpMeta64 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT45, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT46, mmc_mk_cons(_tpStr, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_nodes_1, MMC_REFSTRUCTLIT(mmc_nil))))))));
tmp1 = stringAppendList(tmpMeta64);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta65;
_level = tmp4_2;
tmp4 += 13;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_nodes = omc_List_map1(threadData, _es, boxvar_ExpressionDump_dumpExpStr, mmc_mk_integer(_new_level1));
_nodes_1 = stringAppendList(_nodes);
tmpMeta66 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT47, mmc_mk_cons(_nodes_1, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta66);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lstes = tmpMeta67;
_level = tmp4_2;
tmp4 += 12;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_s = stringDelimitList(omc_List_map1(threadData, _lstes, boxvar_ExpressionDump_printRowStr, _OMC_LIT8), _OMC_LIT48);
tmpMeta68 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT49, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT50, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta68);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_start = tmpMeta69;
_stop = tmpMeta71;
_level = tmp4_2;
tmp4 += 11;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_t1 = omc_ExpressionDump_dumpExpStr(threadData, _start, _new_level1);
_t2 = _OMC_LIT9;
_t3 = omc_ExpressionDump_dumpExpStr(threadData, _stop, _new_level2);
tmpMeta72 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT51, mmc_mk_cons(_t1, mmc_mk_cons(_t2, mmc_mk_cons(_t3, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta72);
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta74)) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 1));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_start = tmpMeta73;
_step = tmpMeta75;
_stop = tmpMeta76;
_level = tmp4_2;
tmp4 += 10;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_new_level3 = ((modelica_integer) 1) + _level;
_t1 = omc_ExpressionDump_dumpExpStr(threadData, _start, _new_level1);
_t2 = omc_ExpressionDump_dumpExpStr(threadData, _step, _new_level2);
_t3 = omc_ExpressionDump_dumpExpStr(threadData, _stop, _new_level3);
tmpMeta77 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT51, mmc_mk_cons(_t1, mmc_mk_cons(_t2, mmc_mk_cons(_t3, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta77);
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta78;
_level = tmp4_2;
tmp4 += 9;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta79 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT52, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta79);
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_integer tmp85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta81)) goto tmp3_end;
tmpMeta82 = MMC_CAR(tmpMeta81);
tmpMeta83 = MMC_CDR(tmpMeta81);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta82,0,1) == 0) goto tmp3_end;
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta82), 2));
tmp85 = mmc_unbox_integer(tmpMeta84);
if (!listEmpty(tmpMeta83)) goto tmp3_end;
_e = tmpMeta80;
_i = tmp85;
_level = tmp4_2;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
_istr = intString(_i);
tmpMeta86 = mmc_mk_cons(_OMC_LIT53, mmc_mk_cons(_istr, mmc_mk_cons(_OMC_LIT54, MMC_REFSTRUCTLIT(mmc_nil))));
_s = stringAppendList(tmpMeta86);
tmpMeta87 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta87);
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta88;
_level = tmp4_2;
tmp4 += 7;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta89 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT56, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta89);
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta91)) goto tmp3_end;
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta91), 1));
_cr = tmpMeta90;
_dim = tmpMeta92;
_level = tmp4_2;
tmp4 += 6;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_crt = omc_ExpressionDump_dumpExpStr(threadData, _cr, _new_level1);
_dimt = omc_ExpressionDump_dumpExpStr(threadData, _dim, _new_level2);
tmpMeta93 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT57, mmc_mk_cons(_crt, mmc_mk_cons(_dimt, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta93);
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta95)) goto tmp3_end;
_cr = tmpMeta94;
_level = tmp4_2;
tmp4 += 5;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_crt = omc_ExpressionDump_dumpExpStr(threadData, _cr, _new_level1);
tmpMeta96 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT57, mmc_mk_cons(_crt, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta96);
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta99)) goto tmp3_end;
tmpMeta100 = MMC_CAR(tmpMeta99);
tmpMeta101 = MMC_CDR(tmpMeta99);
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta100), 3));
if (!listEmpty(tmpMeta101)) goto tmp3_end;
_exp = tmpMeta98;
_iterexp = tmpMeta102;
_level = tmp4_2;
tmp4 += 4;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_new_level2 = ((modelica_integer) 1) + _level;
_expt = omc_ExpressionDump_dumpExpStr(threadData, _exp, _new_level1);
_itert = omc_ExpressionDump_dumpExpStr(threadData, _iterexp, _new_level2);
tmpMeta103 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT58, mmc_mk_cons(_expt, mmc_mk_cons(_itert, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta103);
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,4) == 0) goto tmp3_end;
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta104;
_args = tmpMeta105;
_level = tmp4_2;
tmp4 += 3;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_new_level1 = ((modelica_integer) 1) + _level;
_argnodes = omc_List_map1(threadData, _args, boxvar_ExpressionDump_dumpExpStr, mmc_mk_integer(_new_level1));
_argnodes_1 = stringAppendList(_argnodes);
tmpMeta106 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT59, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_argnodes_1, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta106);
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_integer tmp109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,4) == 0) goto tmp3_end;
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp109 = mmc_unbox_integer(tmpMeta108);
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta107;
_i = tmp109;
_fs = tmpMeta110;
_tp = tmpMeta111;
_level = tmp4_2;
tmp4 += 2;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
_istr = intString(_i);
tmpMeta112 = mmc_mk_cons(_OMC_LIT53, mmc_mk_cons(_istr, mmc_mk_cons(_OMC_LIT54, MMC_REFSTRUCTLIT(mmc_nil))));
_s = stringAppendList(tmpMeta112);
_tpStr = omc_Types_unparseType(threadData, _tp);
tmpMeta113 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT60, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT61, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT46, mmc_mk_cons(_tpStr, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))))))))));
tmp1 = stringAppendList(tmpMeta113);
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,34,1) == 0) goto tmp3_end;
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta114;
_level = tmp4_2;
tmp4 += 1;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta115 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT62, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta115);
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta116;
_level = tmp4_2;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
_new_level1 = ((modelica_integer) 1) + _level;
_ct = omc_ExpressionDump_dumpExpStr(threadData, _e, _new_level1);
tmpMeta117 = mmc_mk_cons(_gen_str, mmc_mk_cons(_OMC_LIT63, mmc_mk_cons(_ct, mmc_mk_cons(_OMC_LIT0, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta117);
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
_level = tmp4_2;
_gen_str = omc_ExpressionDump_genStringNTime(threadData, _OMC_LIT20, _level);
tmpMeta119 = stringAppend(_OMC_LIT64,omc_ExpressionDump_printExpTypeStr(threadData, _inExp));
tmpMeta120 = stringAppend(tmpMeta119,_OMC_LIT6);
tmpMeta118 = mmc_mk_cons(_gen_str, mmc_mk_cons(tmpMeta120, mmc_mk_cons(_OMC_LIT12, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta118);
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
if (++tmp4 < 32) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_ExpressionDump_dumpExpStr(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inInteger)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inInteger);
_outString = omc_ExpressionDump_dumpExpStr(threadData, _inExp, tmp1);
return _outString;
}
DLLExport
modelica_metatype omc_ExpressionDump_dumpExpGraphviz(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outNode = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_string _s = NULL;
modelica_string _sym = NULL;
modelica_string _fs = NULL;
modelica_string _tystr = NULL;
modelica_string _istr = NULL;
modelica_integer _i;
modelica_metatype _c = NULL;
modelica_metatype _lt = NULL;
modelica_metatype _rt = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _tt = NULL;
modelica_metatype _ft = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _t3 = NULL;
modelica_metatype _crt = NULL;
modelica_metatype _dimt = NULL;
modelica_metatype _expt = NULL;
modelica_metatype _itert = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _t = NULL;
modelica_metatype _f = NULL;
modelica_metatype _start = NULL;
modelica_metatype _stop = NULL;
modelica_metatype _step = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _iterexp = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _op = NULL;
modelica_metatype _argnodes = NULL;
modelica_metatype _nodes = NULL;
modelica_metatype _fcn = NULL;
modelica_metatype _args = NULL;
modelica_metatype _es = NULL;
modelica_metatype _ty = NULL;
modelica_real _r;
modelica_boolean _b;
modelica_metatype _lstes = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 24; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_i = tmp7;
tmp4 += 22;
_s = intString(_i);
tmpMeta8 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT65, tmpMeta8, tmpMeta9, tmpMeta10);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_real tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp13 = mmc_unbox_real(tmpMeta12);
_r = tmp13;
tmp4 += 21;
_s = realString(_r);
tmpMeta14 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta17 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT66, tmpMeta14, tmpMeta15, tmpMeta16);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta18;
tmp4 += 20;
_s = omc_System_escapedString(threadData, _s, 1);
tmpMeta19 = mmc_mk_cons(_OMC_LIT8, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT8, MMC_REFSTRUCTLIT(mmc_nil))));
_s = stringAppendList(tmpMeta19);
tmpMeta20 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta23 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT67, tmpMeta20, tmpMeta21, tmpMeta22);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp25 = mmc_unbox_integer(tmpMeta24);
_b = tmp25;
tmp4 += 19;
_s = (_b?_OMC_LIT43:_OMC_LIT44);
tmpMeta26 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT68, tmpMeta26, tmpMeta27, tmpMeta28);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta30;
tmp4 += 18;
_s = omc_ComponentReference_printComponentRefStr(threadData, _c);
tmpMeta31 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta32 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta33 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta34 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT69, tmpMeta31, tmpMeta32, tmpMeta33);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta35;
_op = tmpMeta36;
_e2 = tmpMeta37;
tmp4 += 17;
_sym = omc_ExpressionDump_binopSymbol(threadData, _op);
_lt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e1);
_rt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e2);
tmpMeta38 = mmc_mk_cons(_sym, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta39 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta40 = mmc_mk_cons(_lt, mmc_mk_cons(_rt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta41 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT70, tmpMeta38, tmpMeta39, tmpMeta40);
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta42;
_e = tmpMeta43;
tmp4 += 16;
_sym = omc_ExpressionDump_unaryopSymbol(threadData, _op);
_ct = omc_ExpressionDump_dumpExpGraphviz(threadData, _e);
tmpMeta44 = mmc_mk_cons(_sym, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta45 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta46 = mmc_mk_cons(_ct, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta47 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT71, tmpMeta44, tmpMeta45, tmpMeta46);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta48;
_op = tmpMeta49;
_e2 = tmpMeta50;
tmp4 += 15;
_sym = omc_ExpressionDump_lbinopSymbol(threadData, _op);
_lt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e1);
_rt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e2);
tmpMeta51 = mmc_mk_cons(_sym, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta52 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta53 = mmc_mk_cons(_lt, mmc_mk_cons(_rt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta54 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT72, tmpMeta51, tmpMeta52, tmpMeta53);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta55;
_e = tmpMeta56;
tmp4 += 14;
_sym = omc_ExpressionDump_lunaryopSymbol(threadData, _op);
_ct = omc_ExpressionDump_dumpExpGraphviz(threadData, _e);
tmpMeta57 = mmc_mk_cons(_sym, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta58 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta59 = mmc_mk_cons(_ct, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta60 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT73, tmpMeta57, tmpMeta58, tmpMeta59);
tmpMeta1 = tmpMeta60;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta61;
_op = tmpMeta62;
_e2 = tmpMeta63;
tmp4 += 13;
_sym = omc_ExpressionDump_relopSymbol(threadData, _op);
_lt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e1);
_rt = omc_ExpressionDump_dumpExpGraphviz(threadData, _e2);
tmpMeta64 = mmc_mk_cons(_sym, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta65 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta66 = mmc_mk_cons(_lt, mmc_mk_cons(_rt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta67 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT74, tmpMeta64, tmpMeta65, tmpMeta66);
tmpMeta1 = tmpMeta67;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta68;
_t = tmpMeta69;
_f = tmpMeta70;
tmp4 += 12;
_ct = omc_ExpressionDump_dumpExpGraphviz(threadData, _cond);
_tt = omc_ExpressionDump_dumpExpGraphviz(threadData, _t);
_ft = omc_ExpressionDump_dumpExpGraphviz(threadData, _f);
tmpMeta71 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta72 = mmc_mk_cons(_ct, mmc_mk_cons(_tt, mmc_mk_cons(_ft, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta73 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT75, tmpMeta71, tmpMeta72);
tmpMeta1 = tmpMeta73;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta74;
_args = tmpMeta75;
tmp4 += 11;
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_argnodes = omc_List_map(threadData, _args, boxvar_ExpressionDump_dumpExpGraphviz);
tmpMeta76 = mmc_mk_cons(_fs, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta77 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta78 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT76, tmpMeta76, tmpMeta77, _argnodes);
tmpMeta1 = tmpMeta78;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,4) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_args = tmpMeta79;
tmp4 += 10;
_argnodes = omc_List_map(threadData, _args, boxvar_ExpressionDump_dumpExpGraphviz);
tmpMeta80 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta81 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT77, tmpMeta80, _argnodes);
tmpMeta1 = tmpMeta81;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_es = tmpMeta82;
tmp4 += 9;
_nodes = omc_List_map(threadData, _es, boxvar_ExpressionDump_dumpExpGraphviz);
tmpMeta83 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta84 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT78, tmpMeta83, _nodes);
tmpMeta1 = tmpMeta84;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta85;
tmp4 += 8;
_nodes = omc_List_map(threadData, _es, boxvar_ExpressionDump_dumpExpGraphviz);
tmpMeta86 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta87 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT79, tmpMeta86, _nodes);
tmpMeta1 = tmpMeta87;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lstes = tmpMeta88;
tmp4 += 7;
_s = stringDelimitList(omc_List_map1(threadData, _lstes, boxvar_ExpressionDump_printRowStr, _OMC_LIT8), _OMC_LIT48);
tmpMeta89 = mmc_mk_cons(_OMC_LIT80, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT81, MMC_REFSTRUCTLIT(mmc_nil))));
_s = stringAppendList(tmpMeta89);
tmpMeta90 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta91 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta92 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta93 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT82, tmpMeta90, tmpMeta91, tmpMeta92);
tmpMeta1 = tmpMeta93;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta95)) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_start = tmpMeta94;
_stop = tmpMeta96;
tmp4 += 6;
_t1 = omc_ExpressionDump_dumpExpGraphviz(threadData, _start);
_t2 = _OMC_LIT83;
_t3 = omc_ExpressionDump_dumpExpGraphviz(threadData, _stop);
tmpMeta97 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta98 = mmc_mk_cons(_t1, mmc_mk_cons(_t2, mmc_mk_cons(_t3, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta99 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT84, tmpMeta97, tmpMeta98);
tmpMeta1 = tmpMeta99;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta101)) goto tmp3_end;
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta101), 1));
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_start = tmpMeta100;
_step = tmpMeta102;
_stop = tmpMeta103;
tmp4 += 5;
_t1 = omc_ExpressionDump_dumpExpGraphviz(threadData, _start);
_t2 = omc_ExpressionDump_dumpExpGraphviz(threadData, _step);
_t3 = omc_ExpressionDump_dumpExpGraphviz(threadData, _stop);
tmpMeta104 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta105 = mmc_mk_cons(_t1, mmc_mk_cons(_t2, mmc_mk_cons(_t3, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta106 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT84, tmpMeta104, tmpMeta105);
tmpMeta1 = tmpMeta106;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ty = tmpMeta107;
_e = tmpMeta108;
tmp4 += 4;
_tystr = omc_Types_unparseType(threadData, _ty);
_ct = omc_ExpressionDump_dumpExpGraphviz(threadData, _e);
tmpMeta109 = mmc_mk_cons(_tystr, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta110 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta111 = mmc_mk_cons(_ct, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta112 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT85, tmpMeta109, tmpMeta110, tmpMeta111);
tmpMeta1 = tmpMeta112;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_integer tmp118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta114)) goto tmp3_end;
tmpMeta115 = MMC_CAR(tmpMeta114);
tmpMeta116 = MMC_CDR(tmpMeta114);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta115,0,1) == 0) goto tmp3_end;
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta115), 2));
tmp118 = mmc_unbox_integer(tmpMeta117);
if (!listEmpty(tmpMeta116)) goto tmp3_end;
_e = tmpMeta113;
_i = tmp118;
tmp4 += 3;
_ct = omc_ExpressionDump_dumpExpGraphviz(threadData, _e);
_istr = intString(_i);
tmpMeta119 = mmc_mk_cons(_OMC_LIT53, mmc_mk_cons(_istr, mmc_mk_cons(_OMC_LIT54, MMC_REFSTRUCTLIT(mmc_nil))));
_s = stringAppendList(tmpMeta119);
tmpMeta120 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta121 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta122 = mmc_mk_cons(_ct, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta123 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT86, tmpMeta120, tmpMeta121, tmpMeta122);
tmpMeta1 = tmpMeta123;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta125)) goto tmp3_end;
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta125), 1));
_cr = tmpMeta124;
_dim = tmpMeta126;
tmp4 += 2;
_crt = omc_ExpressionDump_dumpExpGraphviz(threadData, _cr);
_dimt = omc_ExpressionDump_dumpExpGraphviz(threadData, _dim);
tmpMeta127 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta128 = mmc_mk_cons(_crt, mmc_mk_cons(_dimt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta129 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT87, tmpMeta127, tmpMeta128);
tmpMeta1 = tmpMeta129;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta131)) goto tmp3_end;
_cr = tmpMeta130;
tmp4 += 1;
_crt = omc_ExpressionDump_dumpExpGraphviz(threadData, _cr);
tmpMeta132 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta133 = mmc_mk_cons(_crt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta134 = mmc_mk_box4(3, &Graphviz_Node_NODE__desc, _OMC_LIT87, tmpMeta132, tmpMeta133);
tmpMeta1 = tmpMeta134;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta135 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta135), 2));
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta138)) goto tmp3_end;
tmpMeta139 = MMC_CAR(tmpMeta138);
tmpMeta140 = MMC_CDR(tmpMeta138);
tmpMeta141 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta139), 3));
if (!listEmpty(tmpMeta140)) goto tmp3_end;
_fcn = tmpMeta136;
_exp = tmpMeta137;
_iterexp = tmpMeta141;
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_expt = omc_ExpressionDump_dumpExpGraphviz(threadData, _exp);
_itert = omc_ExpressionDump_dumpExpGraphviz(threadData, _iterexp);
tmpMeta142 = mmc_mk_cons(_fs, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta143 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta144 = mmc_mk_cons(_expt, mmc_mk_cons(_itert, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta145 = mmc_mk_box5(4, &Graphviz_Node_LNODE__desc, _OMC_LIT88, tmpMeta142, tmpMeta143, tmpMeta144);
tmpMeta1 = tmpMeta145;
goto tmp3_done;
}
case 23: {
tmpMeta1 = _OMC_LIT90;
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
if (++tmp4 < 24) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outNode = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outNode;
}
DLLExport
modelica_string omc_ExpressionDump_printRowStr(threadData_t *threadData, modelica_metatype _es_1, modelica_string _stringDelimiter)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = stringDelimitList(omc_List_map3(threadData, _es_1, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, mmc_mk_none(), mmc_mk_none()), _OMC_LIT14);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_integer omc_ExpressionDump_expPriority(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_integer _outInteger;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 47; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,4) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 3);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,20,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 3);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,21,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 3);
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,19,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 3);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,18,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 3);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,3,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 5);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,10,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 5);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,17,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 5);
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,16,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 5);
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 7);
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,9,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 7);
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,11,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 7);
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,14,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 7);
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,15,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 7);
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,5,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 8);
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,6,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 8);
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,0,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,7,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,12,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,1,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 32: {
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,8,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 33: {
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,13,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 9);
goto tmp3_done;
}
case 34: {
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,25,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 35: {
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,26,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 36: {
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,27,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,28,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 38: {
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,29,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 39: {
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,30,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 11);
goto tmp3_done;
}
case 40: {
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,24,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 13);
goto tmp3_done;
}
case 41: {
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,22,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 15);
goto tmp3_done;
}
case 42: {
modelica_metatype tmpMeta36;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,23,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 17);
goto tmp3_done;
}
case 43: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 19);
goto tmp3_done;
}
case 44: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 21);
goto tmp3_done;
}
case 45: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 23);
goto tmp3_done;
}
case 46: {
tmp1 = ((modelica_integer) 25);
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
_outInteger = tmp1;
_return: OMC_LABEL_UNUSED
return _outInteger;
}
modelica_metatype boxptr_ExpressionDump_expPriority(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_ExpressionDump_expPriority(threadData, _inExp);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printCase2Str(threadData_t *threadData, modelica_metatype _matchCase)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _matchCase;
{
modelica_metatype _patterns = NULL;
modelica_metatype _body = NULL;
modelica_metatype _result = NULL;
modelica_string _resultStr = NULL;
modelica_string _patternsStr = NULL;
modelica_string _bodyStr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_patterns = tmpMeta6;
_result = tmpMeta9;
tmpMeta10 = mmc_mk_box2(7, &DAE_Pattern_PAT__META__TUPLE__desc, _patterns);
_patternsStr = omc_Patternm_patternStr(threadData, tmpMeta10);
_resultStr = omc_ExpressionDump_printExpStr(threadData, _result);
tmpMeta11 = mmc_mk_cons(_OMC_LIT91, mmc_mk_cons(_patternsStr, mmc_mk_cons(_OMC_LIT92, mmc_mk_cons(_resultStr, mmc_mk_cons(_OMC_LIT93, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta11);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!optionNone(tmpMeta14)) goto tmp3_end;
_patterns = tmpMeta12;
tmpMeta15 = mmc_mk_box2(7, &DAE_Pattern_PAT__META__TUPLE__desc, _patterns);
_patternsStr = omc_Patternm_patternStr(threadData, tmpMeta15);
tmpMeta16 = mmc_mk_cons(_OMC_LIT91, mmc_mk_cons(_patternsStr, mmc_mk_cons(_OMC_LIT94, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta16);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (optionNone(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
_patterns = tmpMeta17;
_body = tmpMeta18;
_result = tmpMeta20;
tmpMeta21 = mmc_mk_box2(7, &DAE_Pattern_PAT__META__TUPLE__desc, _patterns);
_patternsStr = omc_Patternm_patternStr(threadData, tmpMeta21);
_resultStr = omc_ExpressionDump_printExpStr(threadData, _result);
_bodyStr = stringAppendList(omc_List_map1(threadData, _body, boxvar_DAEDump_ppStmtStr, mmc_mk_integer(((modelica_integer) 8))));
tmpMeta22 = mmc_mk_cons(_OMC_LIT91, mmc_mk_cons(_patternsStr, mmc_mk_cons(_OMC_LIT95, mmc_mk_cons(_bodyStr, mmc_mk_cons(_OMC_LIT96, mmc_mk_cons(_resultStr, mmc_mk_cons(_OMC_LIT93, MMC_REFSTRUCTLIT(mmc_nil))))))));
tmp1 = stringAppendList(tmpMeta22);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!optionNone(tmpMeta25)) goto tmp3_end;
_patterns = tmpMeta23;
_body = tmpMeta24;
tmpMeta26 = mmc_mk_box2(7, &DAE_Pattern_PAT__META__TUPLE__desc, _patterns);
_patternsStr = omc_Patternm_patternStr(threadData, tmpMeta26);
_bodyStr = stringAppendList(omc_List_map1(threadData, _body, boxvar_DAEDump_ppStmtStr, mmc_mk_integer(((modelica_integer) 8))));
tmpMeta27 = mmc_mk_cons(_OMC_LIT91, mmc_mk_cons(_patternsStr, mmc_mk_cons(_OMC_LIT95, mmc_mk_cons(_bodyStr, mmc_mk_cons(_OMC_LIT97, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta27);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printMatchType(threadData_t *threadData, modelica_metatype _ty)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT98;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta6)) goto tmp3_end;
tmp1 = _OMC_LIT99;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmp1 = _OMC_LIT100;
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_reductionIteratorStr(threadData_t *threadData, modelica_metatype _riter)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _riter;
{
modelica_string _id = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _gexp = NULL;
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
modelica_metatype tmpMeta10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta8)) goto tmp3_end;
_id = tmpMeta6;
_exp = tmpMeta7;
tmpMeta9 = stringAppend(_id,_OMC_LIT101);
tmpMeta10 = stringAppend(tmpMeta9,omc_ExpressionDump_printExpStr(threadData, _exp));
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 1));
_id = tmpMeta11;
_exp = tmpMeta12;
_gexp = tmpMeta14;
tmpMeta15 = stringAppend(_id,_OMC_LIT102);
tmpMeta16 = stringAppend(tmpMeta15,omc_ExpressionDump_printExpStr(threadData, _gexp));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT101);
tmpMeta18 = stringAppend(tmpMeta17,omc_ExpressionDump_printExpStr(threadData, _exp));
tmp1 = tmpMeta18;
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_printExpTypeStr(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT65;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT66;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT67;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT68;
goto tmp3_done;
}
case 8: {
tmp1 = _OMC_LIT103;
goto tmp3_done;
}
case 9: {
tmp1 = _OMC_LIT69;
goto tmp3_done;
}
case 10: {
tmp1 = _OMC_LIT70;
goto tmp3_done;
}
case 11: {
tmp1 = _OMC_LIT71;
goto tmp3_done;
}
case 12: {
tmp1 = _OMC_LIT72;
goto tmp3_done;
}
case 13: {
tmp1 = _OMC_LIT73;
goto tmp3_done;
}
case 14: {
tmp1 = _OMC_LIT74;
goto tmp3_done;
}
case 15: {
tmp1 = _OMC_LIT75;
goto tmp3_done;
}
case 16: {
tmp1 = _OMC_LIT76;
goto tmp3_done;
}
case 18: {
tmp1 = _OMC_LIT77;
goto tmp3_done;
}
case 19: {
tmp1 = _OMC_LIT78;
goto tmp3_done;
}
case 20: {
tmp1 = _OMC_LIT82;
goto tmp3_done;
}
case 21: {
tmp1 = _OMC_LIT84;
goto tmp3_done;
}
case 22: {
tmp1 = _OMC_LIT79;
goto tmp3_done;
}
case 23: {
tmp1 = _OMC_LIT85;
goto tmp3_done;
}
case 24: {
tmp1 = _OMC_LIT86;
goto tmp3_done;
}
case 25: {
tmp1 = _OMC_LIT104;
goto tmp3_done;
}
case 27: {
tmp1 = _OMC_LIT87;
goto tmp3_done;
}
case 28: {
tmp1 = _OMC_LIT105;
goto tmp3_done;
}
case 29: {
tmp1 = _OMC_LIT106;
goto tmp3_done;
}
case 30: {
tmp1 = _OMC_LIT88;
goto tmp3_done;
}
case 31: {
tmp1 = _OMC_LIT107;
goto tmp3_done;
}
case 32: {
tmp1 = _OMC_LIT108;
goto tmp3_done;
}
case 33: {
tmp1 = _OMC_LIT109;
goto tmp3_done;
}
case 34: {
tmp1 = _OMC_LIT110;
goto tmp3_done;
}
case 35: {
tmp1 = _OMC_LIT111;
goto tmp3_done;
}
case 36: {
tmp1 = _OMC_LIT112;
goto tmp3_done;
}
case 37: {
tmp1 = _OMC_LIT113;
goto tmp3_done;
}
case 38: {
tmp1 = _OMC_LIT114;
goto tmp3_done;
}
case 39: {
tmp1 = _OMC_LIT115;
goto tmp3_done;
}
case 40: {
tmp1 = _OMC_LIT116;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = _OMC_LIT117;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_printExp2Str(threadData_t *threadData, modelica_metatype _inExp, modelica_string _stringDelimiter, modelica_metatype _opcreffunc, modelica_metatype _opcallfunc)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inExp;
tmp4_2 = _opcreffunc;
tmp4_3 = _opcallfunc;
{
modelica_string _s = NULL;
modelica_string _s_1 = NULL;
modelica_string _sym = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s3 = NULL;
modelica_string _s4 = NULL;
modelica_string _fs = NULL;
modelica_string _argstr = NULL;
modelica_string _str = NULL;
modelica_string _crstr = NULL;
modelica_string _dimstr = NULL;
modelica_string _expstr = NULL;
modelica_string _iterstr = NULL;
modelica_string _s1_1 = NULL;
modelica_string _s2_1 = NULL;
modelica_string _cs = NULL;
modelica_string _ts = NULL;
modelica_string _cs_1 = NULL;
modelica_string _ts_1 = NULL;
modelica_string _fs_1 = NULL;
modelica_string _s3_1 = NULL;
modelica_integer _i;
modelica_integer _pe1;
modelica_integer _p1;
modelica_integer _p2;
modelica_integer _pc;
modelica_integer _pt;
modelica_integer _pf;
modelica_integer _p;
modelica_integer _pstop;
modelica_integer _pstart;
modelica_integer _pstep;
modelica_real _r;
modelica_metatype _c = NULL;
modelica_metatype _name = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _start = NULL;
modelica_metatype _stop = NULL;
modelica_metatype _step = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _tb = NULL;
modelica_metatype _fb = NULL;
modelica_metatype _op = NULL;
modelica_metatype _fcn = NULL;
modelica_metatype _lit = NULL;
modelica_metatype _args = NULL;
modelica_metatype _es = NULL;
modelica_fnptr _pcreffunc;
modelica_metatype _creffuncparam = NULL;
modelica_fnptr _pcallfunc;
modelica_boolean _b;
modelica_metatype _aexpl = NULL;
modelica_metatype _lstes = NULL;
modelica_metatype _matchTy = NULL;
modelica_metatype _cases = NULL;
modelica_metatype _pat = NULL;
modelica_metatype _code = NULL;
modelica_metatype _riters = NULL;
modelica_string _scope = NULL;
modelica_string _tyStr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 40; tmp4++) {
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
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_scope = tmpMeta6;
_name = tmpMeta7;
_tyStr = tmpMeta8;
tmp4 += 38;
tmpMeta9 = stringAppend(_OMC_LIT118,_scope);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT119);
tmpMeta11 = stringAppend(tmpMeta10,omc_ComponentReference_printComponentRefStr(threadData, _name));
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT120);
tmpMeta13 = stringAppend(tmpMeta12,_tyStr);
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT121);
tmp1 = tmpMeta14;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_integer tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp16 = mmc_unbox_integer(tmpMeta15);
_i = tmp16;
tmp4 += 37;
tmp1 = intString(_i);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_real tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp18 = mmc_unbox_real(tmpMeta17);
_r = tmp18;
tmp4 += 36;
tmp1 = realString(_r);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta19;
tmp4 += 35;
_s = omc_System_escapedString(threadData, _s, 0);
tmpMeta20 = mmc_mk_cons(_stringDelimiter, mmc_mk_cons(_s, mmc_mk_cons(_stringDelimiter, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta20);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta21;
modelica_integer tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp22 = mmc_unbox_integer(tmpMeta21);
_b = tmp22;
tmp4 += 34;
tmp1 = (_b?_OMC_LIT43:_OMC_LIT44);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 1));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
_c = tmpMeta23;
_pcreffunc = tmpMeta25;
_creffuncparam = tmpMeta26;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcreffunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcreffunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcreffunc), 2))), _c, _creffuncparam) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcreffunc), 1)))) (threadData, _c, _creffuncparam);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c = tmpMeta27;
tmp4 += 32;
_s = omc_ComponentReference_printComponentRefStr(threadData, _c);
if(listMember(_OMC_LIT123, omc_Flags_getConfigStringList(threadData, _OMC_LIT129)))
{
_s = omc_System_stringReplace(threadData, _s, _OMC_LIT15, _OMC_LIT122);
}
tmp1 = _s;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_lit = tmpMeta28;
tmp4 += 31;
tmp1 = omc_AbsynUtil_pathString(threadData, _lit, _OMC_LIT15, 1, 0);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmp4_1;
_e1 = tmpMeta29;
_op = tmpMeta30;
_e2 = tmpMeta31;
tmp4 += 30;
_sym = omc_ExpressionDump_binopSymbol(threadData, _op);
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_s2 = omc_ExpressionDump_printExp2Str(threadData, _e2, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_p1 = omc_ExpressionDump_expPriority(threadData, _e1);
_p2 = omc_ExpressionDump_expPriority(threadData, _e2);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _p1, _p, 0);
_s2_1 = omc_ExpressionDump_parenthesize(threadData, _s2, _p2, _p, 1);
tmpMeta32 = mmc_mk_cons(_s1_1, mmc_mk_cons(_sym, mmc_mk_cons(_s2_1, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta32);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_op = tmpMeta33;
_e1 = tmpMeta34;
tmp4 += 29;
_sym = omc_ExpressionDump_unaryopSymbol(threadData, _op);
_s = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_p1 = omc_ExpressionDump_expPriority(threadData, _e1);
_s_1 = omc_ExpressionDump_parenthesize(threadData, _s, _p1, _p, 1);
tmpMeta35 = stringAppend(_sym,_s_1);
tmp1 = tmpMeta35;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmp4_1;
_e1 = tmpMeta36;
_op = tmpMeta37;
_e2 = tmpMeta38;
tmp4 += 28;
_sym = omc_ExpressionDump_lbinopSymbol(threadData, _op);
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_s2 = omc_ExpressionDump_printExp2Str(threadData, _e2, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_p1 = omc_ExpressionDump_expPriority(threadData, _e1);
_p2 = omc_ExpressionDump_expPriority(threadData, _e2);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _p1, _p, 0);
_s2_1 = omc_ExpressionDump_parenthesize(threadData, _s2, _p2, _p, 1);
tmpMeta39 = mmc_mk_cons(_s1_1, mmc_mk_cons(_sym, mmc_mk_cons(_s2_1, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta39);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_op = tmpMeta40;
_e1 = tmpMeta41;
tmp4 += 27;
_sym = omc_ExpressionDump_lunaryopSymbol(threadData, _op);
_s = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_p1 = omc_ExpressionDump_expPriority(threadData, _e1);
_s_1 = omc_ExpressionDump_parenthesize(threadData, _s, _p1, _p, 0);
tmpMeta42 = stringAppend(_sym,_s_1);
tmp1 = tmpMeta42;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmp4_1;
_e1 = tmpMeta43;
_op = tmpMeta44;
_e2 = tmpMeta45;
tmp4 += 26;
_sym = omc_ExpressionDump_relopSymbol(threadData, _op);
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_s2 = omc_ExpressionDump_printExp2Str(threadData, _e2, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_p1 = omc_ExpressionDump_expPriority(threadData, _e1);
_p2 = omc_ExpressionDump_expPriority(threadData, _e2);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _p1, _p, 0);
_s2_1 = omc_ExpressionDump_parenthesize(threadData, _s2, _p2, _p, 1);
tmpMeta46 = mmc_mk_cons(_s1_1, mmc_mk_cons(_sym, mmc_mk_cons(_s2_1, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta46);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmp4_1;
_cond = tmpMeta47;
_tb = tmpMeta48;
_fb = tmpMeta49;
tmp4 += 25;
_cs = omc_ExpressionDump_printExp2Str(threadData, _cond, _stringDelimiter, _opcreffunc, _opcallfunc);
_ts = omc_ExpressionDump_printExp2Str(threadData, _tb, _stringDelimiter, _opcreffunc, _opcallfunc);
_fs = omc_ExpressionDump_printExp2Str(threadData, _fb, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_pc = omc_ExpressionDump_expPriority(threadData, _cond);
_pt = omc_ExpressionDump_expPriority(threadData, _tb);
_pf = omc_ExpressionDump_expPriority(threadData, _fb);
_cs_1 = omc_ExpressionDump_parenthesize(threadData, _cs, _pc, _p, 0);
_ts_1 = omc_ExpressionDump_parenthesize(threadData, _ts, _pt, _p, 0);
_fs_1 = omc_ExpressionDump_parenthesize(threadData, _fs, _pf, _p, 0);
tmpMeta50 = mmc_mk_cons(_OMC_LIT130, mmc_mk_cons(_cs_1, mmc_mk_cons(_OMC_LIT92, mmc_mk_cons(_ts_1, mmc_mk_cons(_OMC_LIT131, mmc_mk_cons(_fs_1, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta50);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
_e = tmp4_1;
_pcallfunc = tmpMeta51;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcallfunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcallfunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcallfunc), 2))), _e, _stringDelimiter, _opcreffunc) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pcallfunc), 1)))) (threadData, _e, _stringDelimiter, _opcreffunc);
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta52;
_args = tmpMeta53;
tmp4 += 23;
_fs = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_makeNotFullyQualified(threadData, _fcn), _OMC_LIT15, 1, 0);
_argstr = stringDelimitList(omc_List_map3(threadData, _args, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta54 = mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_argstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta54);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,4) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta55;
_args = tmpMeta56;
tmp4 += 22;
_fs = omc_AbsynUtil_pathString(threadData, omc_AbsynUtil_makeNotFullyQualified(threadData, _fcn), _OMC_LIT15, 1, 0);
_argstr = stringDelimitList(omc_List_map3(threadData, _args, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta57 = mmc_mk_cons(_OMC_LIT132, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_argstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta57);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_es = tmpMeta58;
tmp4 += 21;
_s = stringDelimitList(omc_List_map3(threadData, _es, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta59 = mmc_mk_cons(_OMC_LIT17, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT18, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta59);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta60;
tmp4 += 20;
_s = stringDelimitList(omc_List_map3(threadData, _es, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta61 = mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta61);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lstes = tmpMeta62;
tmp4 += 19;
_s = stringDelimitList(omc_List_map1(threadData, _lstes, boxvar_ExpressionDump_printRowStr, _stringDelimiter), _OMC_LIT48);
tmpMeta63 = mmc_mk_cons(_OMC_LIT80, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT81, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta63);
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta65)) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmp4_1;
_start = tmpMeta64;
_stop = tmpMeta66;
tmp4 += 18;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _start, _stringDelimiter, _opcreffunc, _opcallfunc);
_s3 = omc_ExpressionDump_printExp2Str(threadData, _stop, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_pstart = omc_ExpressionDump_expPriority(threadData, _start);
_pstop = omc_ExpressionDump_expPriority(threadData, _stop);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _pstart, _p, 0);
_s3_1 = omc_ExpressionDump_parenthesize(threadData, _s3, _pstop, _p, 0);
tmpMeta67 = mmc_mk_cons(_s1_1, mmc_mk_cons(_OMC_LIT9, mmc_mk_cons(_s3_1, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta67);
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta69)) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 1));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmp4_1;
_start = tmpMeta68;
_step = tmpMeta70;
_stop = tmpMeta71;
tmp4 += 17;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _start, _stringDelimiter, _opcreffunc, _opcallfunc);
_s2 = omc_ExpressionDump_printExp2Str(threadData, _step, _stringDelimiter, _opcreffunc, _opcallfunc);
_s3 = omc_ExpressionDump_printExp2Str(threadData, _stop, _stringDelimiter, _opcreffunc, _opcallfunc);
_p = omc_ExpressionDump_expPriority(threadData, _e);
_pstart = omc_ExpressionDump_expPriority(threadData, _start);
_pstop = omc_ExpressionDump_expPriority(threadData, _stop);
_pstep = omc_ExpressionDump_expPriority(threadData, _step);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _pstart, _p, 0);
_s3_1 = omc_ExpressionDump_parenthesize(threadData, _s3, _pstop, _p, 0);
_s2_1 = omc_ExpressionDump_parenthesize(threadData, _s2, _pstep, _p, 0);
tmpMeta72 = mmc_mk_cons(_s1_1, mmc_mk_cons(_OMC_LIT9, mmc_mk_cons(_s2_1, mmc_mk_cons(_OMC_LIT9, mmc_mk_cons(_s3_1, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta72);
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tp = tmpMeta73;
_e = tmpMeta74;
tmp4 += 16;
_str = omc_Types_unparseType(threadData, _tp);
_s = omc_ExpressionDump_printExp2Str(threadData, _e, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta75 = mmc_mk_cons(_OMC_LIT133, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT5, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta75);
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_e1 = tmpMeta76;
_aexpl = tmpMeta77;
tmp4 += 15;
_p = omc_ExpressionDump_expPriority(threadData, _e);
_pe1 = omc_ExpressionDump_expPriority(threadData, _e1);
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_s1_1 = omc_ExpressionDump_parenthesize(threadData, _s1, _pe1, _p, 0);
_s4 = stringDelimitList(omc_List_map3(threadData, _aexpl, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta78 = stringAppend(_s1_1,_OMC_LIT53);
tmpMeta79 = stringAppend(tmpMeta78,_s4);
tmpMeta80 = stringAppend(tmpMeta79,_OMC_LIT54);
tmp1 = tmpMeta80;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta82)) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta82), 1));
_cr = tmpMeta81;
_dim = tmpMeta83;
tmp4 += 14;
_crstr = omc_ExpressionDump_printExp2Str(threadData, _cr, _stringDelimiter, _opcreffunc, _opcallfunc);
_dimstr = omc_ExpressionDump_printExp2Str(threadData, _dim, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta84 = mmc_mk_cons(_OMC_LIT134, mmc_mk_cons(_crstr, mmc_mk_cons(_OMC_LIT14, mmc_mk_cons(_dimstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta84);
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta86)) goto tmp3_end;
_cr = tmpMeta85;
tmp4 += 13;
_crstr = omc_ExpressionDump_printExp2Str(threadData, _cr, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta87 = mmc_mk_cons(_OMC_LIT134, mmc_mk_cons(_crstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta87);
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta88), 2));
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_fcn = tmpMeta89;
_exp = tmpMeta90;
_riters = tmpMeta91;
tmp4 += 12;
_fs = omc_AbsynUtil_pathStringNoQual(threadData, _fcn, _OMC_LIT15, 0, 0);
_expstr = omc_ExpressionDump_printExp2Str(threadData, _exp, _stringDelimiter, _opcreffunc, _opcallfunc);
_iterstr = stringDelimitList(omc_List_map(threadData, _riters, boxvar_ExpressionDump_reductionIteratorStr), _OMC_LIT14);
tmpMeta92 = mmc_mk_cons(_OMC_LIT135, mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_expstr, mmc_mk_cons(_OMC_LIT136, mmc_mk_cons(_iterstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))))))));
tmp1 = stringAppendList(tmpMeta92);
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,30,1) == 0) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta93;
tmp4 += 11;
tmpMeta94 = mmc_mk_box2(22, &DAE_Exp_TUPLE__desc, _es);
tmpMeta95 = stringAppend(_OMC_LIT137,omc_ExpressionDump_printExp2Str(threadData, tmpMeta94, _stringDelimiter, _opcreffunc, _opcallfunc));
tmp1 = tmpMeta95;
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_es = tmpMeta96;
tmp4 += 10;
_s = stringDelimitList(omc_List_map3(threadData, _es, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta97 = mmc_mk_cons(_OMC_LIT138, mmc_mk_cons(_s, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta97);
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta98;
_e2 = tmpMeta99;
tmp4 += 9;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
_s2 = omc_ExpressionDump_printExp2Str(threadData, _e2, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta100 = mmc_mk_cons(_OMC_LIT139, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT14, mmc_mk_cons(_s2, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp1 = stringAppendList(tmpMeta100);
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta101;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,31,1) == 0) goto tmp3_end;
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta101)) goto tmp3_end;
tmp4 += 8;
tmp1 = _OMC_LIT140;
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,31,1) == 0) goto tmp3_end;
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta102)) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta102), 1));
_e1 = tmpMeta103;
tmp4 += 7;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta104 = mmc_mk_cons(_OMC_LIT141, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta104);
goto tmp3_done;
}
case 32: {
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,34,1) == 0) goto tmp3_end;
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta105;
tmp4 += 6;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta106 = mmc_mk_cons(_OMC_LIT142, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta106);
goto tmp3_done;
}
case 33: {
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta107;
tmp4 += 5;
_s1 = omc_ExpressionDump_printExp2Str(threadData, _e1, _stringDelimiter, _opcreffunc, _opcallfunc);
tmpMeta108 = mmc_mk_cons(_OMC_LIT143, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta108);
goto tmp3_done;
}
case 34: {
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,32,5) == 0) goto tmp3_end;
tmpMeta109 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_fcn = tmpMeta109;
_args = tmpMeta110;
tmp4 += 4;
_fs = omc_AbsynUtil_pathString(threadData, _fcn, _OMC_LIT15, 1, 0);
_argstr = stringDelimitList(omc_List_map3(threadData, _args, boxvar_ExpressionDump_printExp2Str, _stringDelimiter, _opcreffunc, _opcallfunc), _OMC_LIT14);
tmpMeta111 = mmc_mk_cons(_fs, mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_argstr, mmc_mk_cons(_OMC_LIT6, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta111);
goto tmp3_done;
}
case 35: {
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta112 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_matchTy = tmpMeta112;
_es = tmpMeta113;
_cases = tmpMeta114;
tmp4 += 3;
_s1 = omc_ExpressionDump_printMatchType(threadData, _matchTy);
tmpMeta115 = mmc_mk_box2(22, &DAE_Exp_TUPLE__desc, _es);
_s2 = omc_ExpressionDump_printExp2Str(threadData, tmpMeta115, _stringDelimiter, _opcreffunc, _opcallfunc);
_s3 = stringAppendList(omc_List_map(threadData, _cases, boxvar_ExpressionDump_printCase2Str));
tmpMeta116 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_OMC_LIT12, mmc_mk_cons(_s3, mmc_mk_cons(_OMC_LIT144, mmc_mk_cons(_s1, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp1 = stringAppendList(tmpMeta116);
goto tmp3_done;
}
case 36: {
modelica_metatype tmpMeta117;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,36,2) == 0) goto tmp3_end;
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta117;
tmp4 += 2;
tmp1 = omc_ExpressionDump_printExp2Str(threadData, _e, _stringDelimiter, _opcreffunc, _opcallfunc);
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta118;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,37,1) == 0) goto tmp3_end;
tmpMeta118 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_pat = tmpMeta118;
tmp4 += 1;
tmp1 = omc_Patternm_patternStr(threadData, _pat);
goto tmp3_done;
}
case 38: {
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,2) == 0) goto tmp3_end;
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_code = tmpMeta119;
tmpMeta120 = stringAppend(_OMC_LIT145,omc_Dump_printCodeStr(threadData, _code));
tmpMeta121 = stringAppend(tmpMeta120,_OMC_LIT6);
tmp1 = tmpMeta121;
goto tmp3_done;
}
case 39: {
tmp1 = omc_ExpressionDump_printExpTypeStr(threadData, _inExp);
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
if (++tmp4 < 40) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_printCrefsFromExpStr(threadData_t *threadData, modelica_metatype _e)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_Tpl_tplString2(threadData, boxvar_ExpressionDumpTpl_dumpExpCrefs, _e, _OMC_LIT0);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_string omc_ExpressionDump_printExpStr(threadData_t *threadData, modelica_metatype _e)
{
modelica_string _s = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_Tpl_tplString2(threadData, boxvar_ExpressionDumpTpl_dumpExp, _e, _OMC_LIT8);
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_string omc_ExpressionDump_printOptExpStr(threadData_t *threadData, modelica_metatype _oexp)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _oexp;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
tmp1 = omc_ExpressionDump_printExpStr(threadData, _e);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT0;
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_ExpressionDump_printExpListStrNoSpace(threadData_t *threadData, modelica_metatype _expl)
{
modelica_string _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = stringAppendList(omc_List_map(threadData, _expl, boxvar_ExpressionDump_printExpStr));
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_string omc_ExpressionDump_printExpListStr(threadData_t *threadData, modelica_metatype _expl)
{
modelica_string _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = stringDelimitList(omc_List_map(threadData, _expl, boxvar_ExpressionDump_printExpStr), _OMC_LIT5);
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_string omc_ExpressionDump_printSubscriptLstStr(threadData_t *threadData, modelica_metatype _inSubscriptLst)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = stringDelimitList(omc_List_map(threadData, _inSubscriptLst, boxvar_ExpressionDump_printSubscriptStr), _OMC_LIT146);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_printSubscriptStr(threadData_t *threadData, modelica_metatype _sub)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _sub;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 5: {
tmp1 = omc_ExpressionDump_printExpStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2))));
goto tmp3_done;
}
case 4: {
tmp1 = omc_ExpressionDump_printExpStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2))));
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta5;
tmpMeta5 = stringAppend(_OMC_LIT10,omc_ExpressionDump_printExpStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2)))));
tmp1 = tmpMeta5;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_debugPrintSubscriptStr(threadData_t *threadData, modelica_metatype _inSubscript)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubscript;
{
modelica_string _s = NULL;
modelica_metatype _e1 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta5;
_s = omc_ExpressionDump_dumpExpStr(threadData, _e1, ((modelica_integer) 0));
tmp1 = omc_System_stringReplace(threadData, _s, _OMC_LIT12, _OMC_LIT0);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta6;
_s = omc_ExpressionDump_dumpExpStr(threadData, _e1, ((modelica_integer) 0));
tmp1 = omc_System_stringReplace(threadData, _s, _OMC_LIT12, _OMC_LIT0);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e1 = tmpMeta7;
_s = omc_ExpressionDump_dumpExpStr(threadData, _e1, ((modelica_integer) 0));
_s = omc_System_stringReplace(threadData, _s, _OMC_LIT12, _OMC_LIT0);
tmpMeta8 = stringAppend(_OMC_LIT10,_s);
tmp1 = tmpMeta8;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_printListStr(threadData_t *threadData, modelica_metatype _inTypeALst, modelica_fnptr _inFuncTypeTypeAToString, modelica_string _inString)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = stringDelimitList(omc_List_map(threadData, _inTypeALst, ((modelica_fnptr) _inFuncTypeTypeAToString)), _inString);
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC void omc_ExpressionDump_printRow(threadData_t *threadData, modelica_metatype _es_1)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ExpressionDump_printList(threadData, _es_1, boxvar_ExpressionDump_printExp, _OMC_LIT14);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_ExpressionDump_printList(threadData_t *threadData, modelica_metatype _inTypeALst, modelica_fnptr _inFuncTypeTypeATo, modelica_string _inString)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_fnptr tmp3_2;volatile modelica_string tmp3_3;
tmp3_1 = _inTypeALst;
tmp3_2 = ((modelica_fnptr) _inFuncTypeTypeATo);
tmp3_3 = _inString;
{
modelica_metatype _h = NULL;
modelica_fnptr _r;
modelica_metatype _t = NULL;
modelica_string _sep = NULL;
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
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta5 = MMC_CAR(tmp3_1);
tmpMeta6 = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta6)) goto tmp2_end;
_h = tmpMeta5;
_r = tmp3_2;
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))), _h) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, _h);
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta7 = MMC_CAR(tmp3_1);
tmpMeta8 = MMC_CDR(tmp3_1);
_h = tmpMeta7;
_t = tmpMeta8;
_r = tmp3_2;
_sep = tmp3_3;
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))), _h) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, _h);
omc_Print_printBuf(threadData, _sep);
omc_ExpressionDump_printList(threadData, _t, ((modelica_fnptr) _r), _sep);
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
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_ExpressionDump_relopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 28: {
tmp1 = _OMC_LIT147;
goto tmp3_done;
}
case 29: {
tmp1 = _OMC_LIT148;
goto tmp3_done;
}
case 30: {
tmp1 = _OMC_LIT149;
goto tmp3_done;
}
case 31: {
tmp1 = _OMC_LIT150;
goto tmp3_done;
}
case 32: {
tmp1 = _OMC_LIT151;
goto tmp3_done;
}
case 33: {
tmp1 = _OMC_LIT152;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_lunaryopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT153;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_lbinopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT154;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT155;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_unaryopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmp1 = (omc_Config_typeinfo(threadData)?_OMC_LIT156:_OMC_LIT157);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmp1 = (omc_Config_typeinfo(threadData)?_OMC_LIT158:_OMC_LIT157);
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ExpressionDump_binopSymbol2(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
modelica_string _ts = NULL;
modelica_metatype _t = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta5;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta6 = mmc_mk_cons(_OMC_LIT159, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta6);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta7;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta8 = mmc_mk_cons(_OMC_LIT161, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta8);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta9;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta10 = mmc_mk_cons(_OMC_LIT162, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta10);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta11;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta12 = mmc_mk_cons(_OMC_LIT163, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta12);
goto tmp3_done;
}
case 7: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta13;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta14 = mmc_mk_cons(_OMC_LIT165, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta14);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta15;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta16 = mmc_mk_cons(_OMC_LIT166, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta16);
goto tmp3_done;
}
case 12: {
tmp1 = _OMC_LIT167;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_t = tmpMeta17;
_ts = omc_Types_unparseType(threadData, _t);
tmpMeta18 = mmc_mk_cons(_OMC_LIT168, mmc_mk_cons(_ts, mmc_mk_cons(_OMC_LIT160, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta18);
goto tmp3_done;
}
case 23: {
tmp1 = _OMC_LIT169;
goto tmp3_done;
}
case 24: {
tmp1 = _OMC_LIT170;
goto tmp3_done;
}
case 14: {
tmp1 = _OMC_LIT171;
goto tmp3_done;
}
case 15: {
tmp1 = _OMC_LIT172;
goto tmp3_done;
}
case 16: {
tmp1 = _OMC_LIT173;
goto tmp3_done;
}
case 22: {
tmp1 = _OMC_LIT174;
goto tmp3_done;
}
case 21: {
tmp1 = _OMC_LIT175;
goto tmp3_done;
}
case 17: {
tmp1 = _OMC_LIT176;
goto tmp3_done;
}
case 18: {
tmp1 = _OMC_LIT177;
goto tmp3_done;
}
case 20: {
tmp1 = _OMC_LIT178;
goto tmp3_done;
}
case 19: {
tmp1 = _OMC_LIT179;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_debugBinopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT180;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT183;
goto tmp3_done;
}
case 7: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 32: {
tmp1 = _OMC_LIT184;
goto tmp3_done;
}
case 10: {
tmp1 = _OMC_LIT185;
goto tmp3_done;
}
case 11: {
tmp1 = _OMC_LIT186;
goto tmp3_done;
}
case 12: {
tmp1 = _OMC_LIT187;
goto tmp3_done;
}
case 13: {
tmp1 = _OMC_LIT188;
goto tmp3_done;
}
case 23: {
tmp1 = _OMC_LIT189;
goto tmp3_done;
}
case 24: {
tmp1 = _OMC_LIT190;
goto tmp3_done;
}
case 14: {
tmp1 = _OMC_LIT191;
goto tmp3_done;
}
case 15: {
tmp1 = _OMC_LIT192;
goto tmp3_done;
}
case 16: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
case 22: {
tmp1 = _OMC_LIT193;
goto tmp3_done;
}
case 21: {
tmp1 = _OMC_LIT194;
goto tmp3_done;
}
case 17: {
tmp1 = _OMC_LIT195;
goto tmp3_done;
}
case 18: {
tmp1 = _OMC_LIT196;
goto tmp3_done;
}
case 20: {
tmp1 = _OMC_LIT197;
goto tmp3_done;
}
case 19: {
tmp1 = _OMC_LIT198;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_binopSymbol1(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT180;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT183;
goto tmp3_done;
}
case 7: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 10: {
tmp1 = _OMC_LIT180;
goto tmp3_done;
}
case 11: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
case 12: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 13: {
tmp1 = _OMC_LIT183;
goto tmp3_done;
}
case 23: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 24: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 14: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 15: {
tmp1 = _OMC_LIT180;
goto tmp3_done;
}
case 16: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
case 22: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 21: {
tmp1 = _OMC_LIT164;
goto tmp3_done;
}
case 17: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 18: {
tmp1 = _OMC_LIT182;
goto tmp3_done;
}
case 20: {
tmp1 = _OMC_LIT183;
goto tmp3_done;
}
case 19: {
tmp1 = _OMC_LIT183;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = _OMC_LIT199;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_binopSymbol(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = (omc_Config_typeinfo(threadData)?omc_ExpressionDump_binopSymbol2(threadData, _inOperator):omc_ExpressionDump_binopSymbol1(threadData, _inOperator));
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ExpressionDump_subscriptString(threadData_t *threadData, modelica_metatype _subscript)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _subscript;
{
modelica_integer _i;
modelica_metatype _enum_lit = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_i = tmp8;
tmp1 = intString(_i);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,5,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_enum_lit = tmpMeta10;
tmp1 = omc_AbsynUtil_pathString(threadData, _enum_lit, _OMC_LIT15, 1, 0);
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}

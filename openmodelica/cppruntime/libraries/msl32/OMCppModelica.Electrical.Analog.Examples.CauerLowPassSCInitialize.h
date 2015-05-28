#pragma once
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h"

/*****************************************************************************
*
* Simulation code to initialize the Modelica system
*
*****************************************************************************/

class CauerLowPassSCInitialize : virtual public CauerLowPassSC
{
public:
  CauerLowPassSCInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~CauerLowPassSCInitialize();
  virtual bool initial();
  virtual void setInitial(bool);
  virtual void initialize();
  virtual void initializeMemory();
  virtual void initializeFreeVariables();
  virtual void initializeBoundVariables();
  virtual void initEquations();
  
private:
  /*! Index of the first equation. We use this to calculate the offset of an equation in the
     equation array given the index of the equation.*/
   int first_equation_index;
    /*! Equations*/
    FORCE_INLINE void initEquation_1();
    /*! Equations*/
    FORCE_INLINE void initEquation_2();
    /*! Equations*/
    FORCE_INLINE void initEquation_3();
    /*! Equations*/
    FORCE_INLINE void initEquation_4();
    /*! Equations*/
    FORCE_INLINE void initEquation_5();
    /*! Equations*/
    FORCE_INLINE void initEquation_6();
    /*! Equations*/
    FORCE_INLINE void initEquation_7();
    /*! Equations*/
    FORCE_INLINE void initEquation_8();
    /*! Equations*/
    FORCE_INLINE void initEquation_9();
    /*! Equations*/
    FORCE_INLINE void initEquation_10();
    /*! Equations*/
    FORCE_INLINE void initEquation_11();
    /*! Equations*/
    FORCE_INLINE void initEquation_12();
    /*! Equations*/
    FORCE_INLINE void initEquation_13();
    /*! Equations*/
    FORCE_INLINE void initEquation_14();
    /*! Equations*/
    FORCE_INLINE void initEquation_15();
    /*! Equations*/
    FORCE_INLINE void initEquation_16();
    /*! Equations*/
    FORCE_INLINE void initEquation_17();
    /*! Equations*/
    FORCE_INLINE void initEquation_18();
    /*! Equations*/
    FORCE_INLINE void initEquation_19();
    /*! Equations*/
    FORCE_INLINE void initEquation_20();
    /*! Equations*/
    FORCE_INLINE void initEquation_21();
    /*! Equations*/
    FORCE_INLINE void initEquation_22();
    /*! Equations*/
    FORCE_INLINE void initEquation_23();
    /*! Equations*/
    FORCE_INLINE void initEquation_24();
    /*! Equations*/
    FORCE_INLINE void initEquation_25();
    /*! Equations*/
    FORCE_INLINE void initEquation_26();
    /*! Equations*/
    FORCE_INLINE void initEquation_27();
    /*! Equations*/
    FORCE_INLINE void initEquation_28();
    /*! Equations*/
    FORCE_INLINE void initEquation_29();
    /*! Equations*/
    FORCE_INLINE void initEquation_30();
    /*! Equations*/
    FORCE_INLINE void initEquation_31();
    /*! Equations*/
    FORCE_INLINE void initEquation_32();
    /*! Equations*/
    FORCE_INLINE void initEquation_33();
    /*! Equations*/
    FORCE_INLINE void initEquation_34();
    /*! Equations*/
    FORCE_INLINE void initEquation_35();
    /*! Equations*/
    FORCE_INLINE void initEquation_36();
    /*! Equations*/
    FORCE_INLINE void initEquation_37();
    /*! Equations*/
    FORCE_INLINE void initEquation_38();
    /*! Equations*/
    FORCE_INLINE void initEquation_39();
    /*! Equations*/
    FORCE_INLINE void initEquation_40();
    /*! Equations*/
    FORCE_INLINE void initEquation_41();
    /*! Equations*/
    FORCE_INLINE void initEquation_42();
    /*! Equations*/
    FORCE_INLINE void initEquation_43();
    /*! Equations*/
    FORCE_INLINE void initEquation_44();
    /*! Equations*/
    FORCE_INLINE void initEquation_45();
    /*! Equations*/
    FORCE_INLINE void initEquation_46();
    /*! Equations*/
    FORCE_INLINE void initEquation_47();
    /*! Equations*/
    FORCE_INLINE void initEquation_48();
    /*! Equations*/
    FORCE_INLINE void initEquation_49();
    /*! Equations*/
    FORCE_INLINE void initEquation_50();
    /*! Equations*/
    FORCE_INLINE void initEquation_51();
    /*! Equations*/
    FORCE_INLINE void initEquation_52();
    /*! Equations*/
    FORCE_INLINE void initEquation_53();
    /*! Equations*/
    FORCE_INLINE void initEquation_54();
    /*! Equations*/
    FORCE_INLINE void initEquation_55();
    /*! Equations*/
    FORCE_INLINE void initEquation_56();
    /*! Equations*/
    FORCE_INLINE void initEquation_57();
    /*! Equations*/
    FORCE_INLINE void initEquation_58();
    /*! Equations*/
    FORCE_INLINE void initEquation_59();
    /*! Equations*/
    FORCE_INLINE void initEquation_60();
    /*! Equations*/
    FORCE_INLINE void initEquation_61();
    /*! Equations*/
    FORCE_INLINE void initEquation_62();
    /*! Equations*/
    FORCE_INLINE void initEquation_63();
    /*! Equations*/
    FORCE_INLINE void initEquation_64();
    /*! Equations*/
    FORCE_INLINE void initEquation_65();
    /*! Equations*/
    FORCE_INLINE void initEquation_66();
    /*! Equations*/
    FORCE_INLINE void initEquation_67();
    /*! Equations*/
    FORCE_INLINE void initEquation_68();
    /*! Equations*/
    FORCE_INLINE void initEquation_69();
    /*! Equations*/
    FORCE_INLINE void initEquation_70();
    /*! Equations*/
    FORCE_INLINE void initEquation_71();
    /*! Equations*/
    FORCE_INLINE void initEquation_72();
    /*! Equations*/
    FORCE_INLINE void initEquation_73();
    /*! Equations*/
    FORCE_INLINE void initEquation_74();
    /*! Equations*/
    FORCE_INLINE void initEquation_75();
    /*! Equations*/
    FORCE_INLINE void initEquation_76();
    /*! Equations*/
    FORCE_INLINE void initEquation_77();
    /*! Equations*/
    FORCE_INLINE void initEquation_78();
    /*! Equations*/
    FORCE_INLINE void initEquation_79();
    /*! Equations*/
    FORCE_INLINE void initEquation_80();
    /*! Equations*/
    FORCE_INLINE void initEquation_81();
    /*! Equations*/
    FORCE_INLINE void initEquation_82();
    /*! Equations*/
    FORCE_INLINE void initEquation_83();
    /*! Equations*/
    FORCE_INLINE void initEquation_84();
    /*! Equations*/
    FORCE_INLINE void initEquation_85();
    /*! Equations*/
    FORCE_INLINE void initEquation_86();
    /*! Equations*/
    FORCE_INLINE void initEquation_87();
    /*! Equations*/
    FORCE_INLINE void initEquation_88();
    /*! Equations*/
    FORCE_INLINE void initEquation_89();
    /*! Equations*/
    FORCE_INLINE void initEquation_90();
    /*! Equations*/
    FORCE_INLINE void initEquation_91();
    /*! Equations*/
    FORCE_INLINE void initEquation_92();
    /*! Equations*/
    FORCE_INLINE void initEquation_93();
    /*! Equations*/
    FORCE_INLINE void initEquation_94();
    /*! Equations*/
    FORCE_INLINE void initEquation_95();
    /*! Equations*/
    FORCE_INLINE void initEquation_96();
    /*! Equations*/
    FORCE_INLINE void initEquation_97();
    /*! Equations*/
    FORCE_INLINE void initEquation_98();
    /*! Equations*/
    FORCE_INLINE void initEquation_99();
    /*! Equations*/
    FORCE_INLINE void initEquation_100();
    /*! Equations*/
    FORCE_INLINE void initEquation_101();
    /*! Equations*/
    FORCE_INLINE void initEquation_102();
    /*! Equations*/
    FORCE_INLINE void initEquation_103();
    /*! Equations*/
    FORCE_INLINE void initEquation_104();
    /*! Equations*/
    FORCE_INLINE void initEquation_105();
    /*! Equations*/
    FORCE_INLINE void initEquation_106();
    /*! Equations*/
    FORCE_INLINE void initEquation_107();
    /*! Equations*/
    FORCE_INLINE void initEquation_108();
    /*! Equations*/
    FORCE_INLINE void initEquation_109();
    /*! Equations*/
    FORCE_INLINE void initEquation_110();
    /*! Equations*/
    FORCE_INLINE void initEquation_111();
    /*! Equations*/
    FORCE_INLINE void initEquation_112();
    /*! Equations*/
    FORCE_INLINE void initEquation_113();
    /*! Equations*/
    FORCE_INLINE void initEquation_114();
    /*! Equations*/
    FORCE_INLINE void initEquation_115();
    /*! Equations*/
    FORCE_INLINE void initEquation_116();
    /*! Equations*/
    FORCE_INLINE void initEquation_117();
    /*! Equations*/
    FORCE_INLINE void initEquation_118();
    /*! Equations*/
    FORCE_INLINE void initEquation_119();
    /*! Equations*/
    FORCE_INLINE void initEquation_120();
    /*! Equations*/
    FORCE_INLINE void initEquation_121();
    /*! Equations*/
    FORCE_INLINE void initEquation_122();
    /*! Equations*/
    FORCE_INLINE void initEquation_123();
    /*! Equations*/
    FORCE_INLINE void initEquation_124();
    /*! Equations*/
    FORCE_INLINE void initEquation_125();
    /*! Equations*/
    FORCE_INLINE void initEquation_126();
    /*! Equations*/
    FORCE_INLINE void initEquation_127();
    /*! Equations*/
    FORCE_INLINE void initEquation_128();
    /*! Equations*/
    FORCE_INLINE void initEquation_129();
    /*! Equations*/
    FORCE_INLINE void initEquation_130();
    /*! Equations*/
    FORCE_INLINE void initEquation_131();
    /*! Equations*/
    FORCE_INLINE void initEquation_132();
    /*! Equations*/
    FORCE_INLINE void initEquation_133();
    /*! Equations*/
    FORCE_INLINE void initEquation_134();
    /*! Equations*/
    FORCE_INLINE void initEquation_135();
    /*! Equations*/
    FORCE_INLINE void initEquation_136();
    /*! Equations*/
    FORCE_INLINE void initEquation_137();
    /*! Equations*/
    FORCE_INLINE void initEquation_138();
    /*! Equations*/
    FORCE_INLINE void initEquation_139();
    /*! Equations*/
    FORCE_INLINE void initEquation_140();
    /*! Equations*/
    FORCE_INLINE void initEquation_141();
    /*! Equations*/
    FORCE_INLINE void initEquation_142();
    /*! Equations*/
    FORCE_INLINE void initEquation_143();
    /*! Equations*/
    FORCE_INLINE void initEquation_144();
    /*! Equations*/
    FORCE_INLINE void initEquation_145();
    /*! Equations*/
    FORCE_INLINE void initEquation_146();
    /*! Equations*/
    FORCE_INLINE void initEquation_147();
    /*! Equations*/
    FORCE_INLINE void initEquation_148();
    /*! Equations*/
    FORCE_INLINE void initEquation_149();
    /*! Equations*/
    FORCE_INLINE void initEquation_150();
    /*! Equations*/
    FORCE_INLINE void initEquation_151();
    /*! Equations*/
    FORCE_INLINE void initEquation_152();
    /*! Equations*/
    FORCE_INLINE void initEquation_153();
    /*! Equations*/
    FORCE_INLINE void initEquation_154();
    /*! Equations*/
    FORCE_INLINE void initEquation_155();
    /*! Equations*/
    FORCE_INLINE void initEquation_156();
    /*! Equations*/
    FORCE_INLINE void initEquation_157();
    /*! Equations*/
    FORCE_INLINE void initEquation_158();
    /*! Equations*/
    FORCE_INLINE void initEquation_159();
    /*! Equations*/
    FORCE_INLINE void initEquation_160();
    /*! Equations*/
    FORCE_INLINE void initEquation_161();
    /*! Equations*/
    FORCE_INLINE void initEquation_162();
    /*! Equations*/
    FORCE_INLINE void initEquation_163();
    /*! Equations*/
    FORCE_INLINE void initEquation_164();
    /*! Equations*/
    FORCE_INLINE void initEquation_165();
    /*! Equations*/
    FORCE_INLINE void initEquation_166();
    /*! Equations*/
    FORCE_INLINE void initEquation_167();
    /*! Equations*/
    FORCE_INLINE void initEquation_168();
    /*! Equations*/
    FORCE_INLINE void initEquation_169();
    /*! Equations*/
    FORCE_INLINE void initEquation_170();
    /*! Equations*/
    FORCE_INLINE void initEquation_171();
    /*! Equations*/
    FORCE_INLINE void initEquation_172();
    /*! Equations*/
    FORCE_INLINE void initEquation_173();
    /*! Equations*/
    FORCE_INLINE void initEquation_174();
    /*! Equations*/
    FORCE_INLINE void initEquation_175();
    /*! Equations*/
    FORCE_INLINE void initEquation_176();
    /*! Equations*/
    FORCE_INLINE void initEquation_177();
    /*! Equations*/
    FORCE_INLINE void initEquation_178();
    /*! Equations*/
    FORCE_INLINE void initEquation_179();
    /*! Equations*/
    FORCE_INLINE void initEquation_180();
    /*! Equations*/
    FORCE_INLINE void initEquation_181();
    /*! Equations*/
    FORCE_INLINE void initEquation_182();
    /*! Equations*/
    FORCE_INLINE void initEquation_183();
    /*! Equations*/
    FORCE_INLINE void initEquation_184();
    /*! Equations*/
    FORCE_INLINE void initEquation_185();
    /*! Equations*/
    FORCE_INLINE void initEquation_186();
    /*! Equations*/
    FORCE_INLINE void initEquation_187();
    /*! Equations*/
    FORCE_INLINE void initEquation_188();
    /*! Equations*/
    FORCE_INLINE void initEquation_189();
    /*! Equations*/
    FORCE_INLINE void initEquation_190();
    /*! Equations*/
    FORCE_INLINE void initEquation_191();
    /*! Equations*/
    FORCE_INLINE void initEquation_192();
    /*! Equations*/
    FORCE_INLINE void initEquation_193();
    /*! Equations*/
    FORCE_INLINE void initEquation_194();
    /*! Equations*/
    FORCE_INLINE void initEquation_195();
    /*! Equations*/
    FORCE_INLINE void initEquation_196();
    /*! Equations*/
    FORCE_INLINE void initEquation_197();
    /*! Equations*/
    FORCE_INLINE void initEquation_198();
    /*! Equations*/
    FORCE_INLINE void initEquation_199();
    /*! Equations*/
    FORCE_INLINE void initEquation_200();
    /*! Equations*/
    FORCE_INLINE void initEquation_201();
    /*! Equations*/
    FORCE_INLINE void initEquation_202();
    /*! Equations*/
    FORCE_INLINE void initEquation_203();
    /*! Equations*/
    FORCE_INLINE void initEquation_204();
    /*! Equations*/
    FORCE_INLINE void initEquation_205();
    /*! Equations*/
    FORCE_INLINE void initEquation_206();
    /*! Equations*/
    FORCE_INLINE void initEquation_207();
    /*! Equations*/
    FORCE_INLINE void initEquation_208();

  void initializeAlgVars_0();
  void initializeAlgVars_1();
  void initializeAlgVars_2();
   void initializeExternalVar();
  void initializeAlgVars();
  void initializeDiscreteAlgVars();
  
  
  void initializeIntAlgVars();
  void initializeBoolAlgVars();
  
  void initializeAliasVars_0();
  void initializeAliasVars_1();
  void initializeAliasVars_2();
  void initializeStringAliasVars();
  void initializeAliasVars();
  void initializeIntAliasVars();
  void initializeBoolAliasVars();
  
  void initializeParameterVars_0();
  void initializeParameterVars_1();
  void initializeBoolParameterVars_0();
  void initializeParameterVars();
  void initializeIntParameterVars();
  void initializeBoolParameterVars();
  void initializeStringParameterVars();
  void initializeStateVars();
  void initializeDerVars();
  
  /*extraFuncs*/
};

  
  void BouncingBallInitialize::initializeAlgVars()
  {
  }

void BouncingBallInitialize::initializeDiscreteAlgVars()
{

            setRealStartValue(_v_new,0.0);
}

void BouncingBallInitialize::initializeIntAlgVars_0()
{
              setIntStartValue(_n_bounce,0);
}

void BouncingBallInitialize::initializeIntAlgVars()
{
  BouncingBallInitialize::initializeIntAlgVars_0();
}

 void BouncingBallInitialize::initializeBoolAlgVars()
{

             setBoolStartValue(_$whenCondition1,false);

               setBoolStartValue(_$whenCondition2,false);

             setBoolStartValue(_$whenCondition3,false);

               setBoolStartValue(_flying,true);

               setBoolStartValue(_impact,false);
}
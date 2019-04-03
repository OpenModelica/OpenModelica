// name:     Philosopher2
// keywords: Example
// cflags: +std=2.x
// status:   correct
//
// This is the dining philosopher model from Peter F. book.
// Regression test for bug #1181
//

package Philosopher
  annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  model DiningTable
    parameter Integer n=5 "Number of philosophers and forks";
    parameter Real sigma=5 "Standard deviation of delay times";
    Philosopher phil[n](sigma=fill(sigma, n));
    Mutex mutex(n=n);
    Fork fork[n];
  equation
    for i in 1:n loop
      connect(phil[i].mutexPort,mutex.port[i]);
      connect(phil[i].right,fork[i].left);
      connect(fork[i].right,phil[mod(i, n) + 1].left);
    end for;
  end DiningTable;

  connector ForkPhilosopherConnection
    Boolean pickedUp(start=false);
    Boolean busy;
  end ForkPhilosopherConnection;

  model Fork
    ForkPhilosopherConnection left "Connection to the philosopher to the left of the fork";
    ForkPhilosopherConnection right "Connection to the philosopher to the right of the fork";
  equation
    right.busy=left.pickedUp;
    left.busy=right.pickedUp;
  end Fork;

  connector MutexPortOut "Application mutex port connector for access"
    output Boolean request "Set this to request ownership of the mutex";
    output Boolean release "Set this to release ownership of the mutex";
    input Boolean ok "This signals that ownership was granted";
  end MutexPortOut;

  model Philosopher "A Philosopher, connected to forks and a mutex"
    import Philosopher.Random;
    MutexPortOut mutexPort "Connection to the global mutex";
    discrete Real[3] startSeed={1,2,3};
    parameter Real mu=20.0 "mean value";
    parameter Real sigma=5 "standard dev";
    discrete Integer state "1==thinking, 2==hungry, 3==eating";
    ForkPhilosopherConnection left;
    ForkPhilosopherConnection right;
    annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected
    constant Integer thinking=0;
    constant Integer hungry=1;
    constant Integer eating=2;
    discrete Real T;
    discrete Real timeOfNextChange;
    discrete Real[3] randomSeed;
    Boolean canEat;
    Boolean timeToChangeState;
    Boolean timeToGetHungry;
    Boolean doneEating;
  equation
    timeToChangeState=timeOfNextChange <= time;
    canEat=state == hungry and not (left.busy or right.busy);
    timeToGetHungry=state == thinking and timeToChangeState;
    doneEating=state == eating and timeToChangeState;
  algorithm
    when initial() then
          state:=thinking;
      left.pickedUp:=false;
      right.pickedUp:=false;
      (T,randomSeed):=Random.normalvariate(mu, sigma, startSeed);
      timeOfNextChange:=abs(T);
    elsewhen pre(timeToGetHungry) then
      state:=hungry;
    end when;
    when pre(canEat) then
          mutexPort.release:=false;
      mutexPort.request:=true;
    end when;
    when pre(mutexPort.ok) then
          if pre(canEat) then
        left.pickedUp:=true;
        right.pickedUp:=true;
        (T,randomSeed):=Random.normalvariate(mu, sigma, pre(randomSeed));
        timeOfNextChange:=time + abs(T);
        state:=eating;
      end if;
      mutexPort.release:=true;
      mutexPort.request:=false;
    end when;
    when pre(doneEating) then
          state:=thinking;
      left.pickedUp:=false;
      right.pickedUp:=false;
      (T,randomSeed):=Random.normalvariate(mu, sigma, pre(randomSeed));
      timeOfNextChange:=time + abs(T);
    end when;
  end Philosopher;

  package Random
    annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    import Modelica.Math;
    constant Real NV_MAGICCONST=4*exp(-0.5)/sqrt(2.0);
    function random
      input Real[3] si "input random seed";
      output Real x "uniform random variate between 0 and 1";
      output Real[3] so "output random seed";
      annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}})));
    algorithm
      so[1]:=abs(rem(171*si[1], 30269));
      so[2]:=abs(rem(172*si[2], 30307));
      so[3]:=abs(rem(170*si[3], 30323));
      if so[1] <= 0 and so[1] >= 0 then
        so[1]:=1;
      end if;
      if so[2] <= 0 and so[2] >= 0 then
        so[2]:=1;
      end if;
      if so[3] <= 0 and so[3] >= 0 then
        so[3]:=1;
      end if;
      x:=rem(so[1]/30269.0 + so[2]/30307.0 + so[3]/3023.0, 1.0);
    end random;

    function normalvariate "normally distributed random variable"
      input Real mu "mean value";
      input Real sigma "standard deviation";
      input Real[3] si "input random seed";
      output Real x;
      output Real[3] so "output random seed";
    protected
      Real[3] s1,s2;
      Real z,zz,u1,u2;
      Boolean my_break=false;
    algorithm
      s1:=si;
      u2:=1;
      while (not my_break) loop
        (u1,s2):=Random.random(s1);
        (u2,s1):=Random.random(s2);
        z:=NV_MAGICCONST*(u1 - 0.5)/u2;
        zz:=z*z/4.0;
        my_break:=zz <= -log(u2);
      end while;
      x:=mu + z*sigma;
      so:=s1;
    end normalvariate;

  end Random;

  connector MutexPortIn "Mutex port connector for receiveing requests"
    input Boolean request "Set by application to request access";
    input Boolean release "Set by application to release access";
    output Boolean ok "Signal that ownership was granted";
  end MutexPortIn;

  model Mutex "Mutual exclusion of shared resource"
    parameter Integer n=5 "The number of connected ports";
    MutexPortIn[n] port;
  protected
    Boolean request[n];
    Boolean release[n];
    Boolean ok[n];
    Boolean waiting[n];
    Boolean occupied "Mutex is locked if occupied is true";
  equation
    for i in 1:n loop
      port[i].ok=ok[i];
      request[i]=port[i].request;
      release[i]=port[i].release;
    end for;
  algorithm
    for i in 1:n loop
      when request[i] then
              if not occupied then
          ok[i]:=true;
          waiting[i]:=false;
        else
          ok[i]:=false;
          waiting[i]:=true;
        end if;
        occupied:=true;
      end when;
      when pre(waiting[i]) and not occupied then
              occupied:=true;
        ok[i]:=true;
        waiting[i]:=false;
      end when;
      when pre(release[i]) then
              ok[i]:=false;
        occupied:=false;
      end when;
    end for;
  end Mutex;

  model Random1
    discrete Real y;
    parameter Real mu=20.0 "mean value";
    parameter Real sigma=5 "standard dev";
    parameter Real[3] startSeed={1,2,3};
  protected
    discrete Real[3] seed;
  algorithm
    when initial() then
          (y,seed):=Philosopher.Random.normalvariate(mu, sigma, startSeed);
    end when;
    when sample(2, 1) then
          (y,seed):=Philosopher.Random.normalvariate(mu, sigma, pre(seed));
    end when;
  end Random1;

end Philosopher;
model Philosopher_DiningTable
  extends Philosopher.DiningTable;
end Philosopher_DiningTable;

// function Philosopher.Random.random
// input Real[3] si "input random seed";
// output Real x "uniform random variate between 0 and 1";
// output Real[3] so "output random seed";
// algorithm
//   so[1] := abs(rem(171.0 * si[1],30269.0));
//   so[2] := abs(rem(172.0 * si[2],30307.0));
//   so[3] := abs(rem(170.0 * si[3],30323.0));
//   if so[1] <= 0.0 AND so[1] >= 0.0 then
//     so[1] := 1.0;
//   end if;
//   if so[2] <= 0.0 AND so[2] >= 0.0 then
//     so[2] := 1.0;
//   end if;
//   if so[3] <= 0.0 AND so[3] >= 0.0 then
//     so[3] := 1.0;
//   end if;
//   x := rem(so[1] / 30269.0 + so[2] / 30307.0 + so[3] / 3023.0,1.0);
// end Philosopher.Random.random;
//
// function Philosopher.Random.normalvariate
// input Real mu "mean value";
// input Real sigma "standard deviation";
// input Real[3] si "input random seed";
// output Real x;
// output Real[3] so "output random seed";
// protected Real[3] s1;
// protected Real[3] s2;
// protected Real z;
// protected Real zz;
// protected Real u1;
// protected Real u2;
// protected Boolean my_break = false;
// algorithm
//   s1 := {si[1],si[2],si[3]};
//   u2 := 1.0;
//   while NOT my_break loop
//     (u1, s2) := Philosopher.Random.random({s1[1],s1[2],s1[3]});
//     (u2, s1) := Philosopher.Random.random({s2[1],s2[2],s2[3]});
//     z := 1.71552776992141 * (u1 - 0.5) / u2;
//     zz := z ^ 2.0 / 4.0;
//     my_break := zz <= -log(u2);
//   end while;
//   x := mu + z * sigma;
//   so := {s1[1],s1[2],s1[3]};
// end Philosopher.Random.normalvariate;
//
// function Philosopher.Random.normalvariate
// input Real mu "mean value";
// input Real sigma "standard deviation";
// input Real[3] si "input random seed";
// output Real x;
// output Real[3] so "output random seed";
// protected Real[3] s1;
// protected Real[3] s2;
// protected Real z;
// protected Real zz;
// protected Real u1;
// protected Real u2;
// protected Boolean my_break = false;
// algorithm
//   s1 := {si[1],si[2],si[3]};
//   u2 := 1.0;
//   while NOT my_break loop
//     (u1, s2) := Philosopher.Random.random({s1[1],s1[2],s1[3]});
//     (u2, s1) := Philosopher.Random.random({s2[1],s2[2],s2[3]});
//     z := 1.71552776992141 * (u1 - 0.5) / u2;
//     zz := z ^ 2.0 / 4.0;
//     my_break := zz <= -log(u2);
//   end while;
//   x := mu + z * sigma;
//   so := {s1[1],s1[2],s1[3]};
// end Philosopher.Random.normalvariate;
//
// function Philosopher.Random.random
// input Real[3] si "input random seed";
// output Real x "uniform random variate between 0 and 1";
// output Real[3] so "output random seed";
// algorithm
//   so[1] := abs(rem(171.0 * si[1],30269.0));
//   so[2] := abs(rem(172.0 * si[2],30307.0));
//   so[3] := abs(rem(170.0 * si[3],30323.0));
//   if so[1] <= 0.0 AND so[1] >= 0.0 then
//     so[1] := 1.0;
//   end if;
//   if so[2] <= 0.0 AND so[2] >= 0.0 then
//     so[2] := 1.0;
//   end if;
//   if so[3] <= 0.0 AND so[3] >= 0.0 then
//     so[3] := 1.0;
//   end if;
//   x := rem(so[1] / 30269.0 + so[2] / 30307.0 + so[3] / 3023.0,1.0);
// end Philosopher.Random.random;
//
// Result:
// function Philosopher.Random.normalvariate "normally distributed random variable"
//   input Real mu "mean value";
//   input Real sigma "standard deviation";
//   input Real[3] si "input random seed";
//   output Real x;
//   output Real[3] so "output random seed";
//   protected Real[3] s1;
//   protected Real[3] s2;
//   protected Real z;
//   protected Real zz;
//   protected Real u1;
//   protected Real u2;
//   protected Boolean my_break = false;
// algorithm
//   s1 := {si[1], si[2], si[3]};
//   u2 := 1.0;
//   while not my_break loop
//     (u1, s2) := Philosopher.Random.random({s1[1], s1[2], s1[3]});
//     (u2, s1) := Philosopher.Random.random({s2[1], s2[2], s2[3]});
//     z := 1.715527769921414 * (-0.5 + u1) / u2;
//     zz := 0.25 * z ^ 2.0;
//     my_break := zz <= (-log(u2));
//   end while;
//   x := mu + z * sigma;
//   so := {s1[1], s1[2], s1[3]};
// end Philosopher.Random.normalvariate;
//
// function Philosopher.Random.random
//   input Real[3] si "input random seed";
//   output Real x "uniform random variate between 0 and 1";
//   output Real[3] so "output random seed";
// algorithm
//   so[1] := abs(171.0 * si[1] + (-30269.0) * div(171.0 * si[1], 30269.0));
//   so[2] := abs(172.0 * si[2] + (-30307.0) * div(172.0 * si[2], 30307.0));
//   so[3] := abs(170.0 * si[3] + (-30323.0) * div(170.0 * si[3], 30323.0));
//   if so[1] <= 0.0 and so[1] >= 0.0 then
//     so[1] := 1.0;
//   end if;
//   if so[2] <= 0.0 and so[2] >= 0.0 then
//     so[2] := 1.0;
//   end if;
//   if so[3] <= 0.0 and so[3] >= 0.0 then
//     so[3] := 1.0;
//   end if;
//   x := 3.303710066404573e-05 * so[1] + 3.299567756623883e-05 * so[2] + 0.0003307972213033411 * so[3] - div(3.303710066404573e-05 * so[1] + 3.299567756623883e-05 * so[2] + 0.0003307972213033411 * so[3], 1.0);
// end Philosopher.Random.random;
//
// class Philosopher_DiningTable
//   parameter Integer n = 5 "Number of philosophers and forks";
//   parameter Real sigma = 5.0 "Standard deviation of delay times";
//   Boolean phil[1].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean phil[1].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean phil[1].mutexPort.ok "This signals that ownership was granted";
//   discrete Real phil[1].startSeed[1];
//   discrete Real phil[1].startSeed[2];
//   discrete Real phil[1].startSeed[3];
//   parameter Real phil[1].mu = 20.0 "mean value";
//   parameter Real phil[1].sigma = sigma "standard dev";
//   discrete Integer phil[1].state "1==thinking, 2==hungry, 3==eating";
//   Boolean phil[1].left.pickedUp(start = false);
//   Boolean phil[1].left.busy;
//   Boolean phil[1].right.pickedUp(start = false);
//   Boolean phil[1].right.busy;
//   protected constant Integer phil[1].thinking = 0;
//   protected constant Integer phil[1].hungry = 1;
//   protected constant Integer phil[1].eating = 2;
//   protected discrete Real phil[1].T;
//   protected discrete Real phil[1].timeOfNextChange;
//   protected discrete Real phil[1].randomSeed[1];
//   protected discrete Real phil[1].randomSeed[2];
//   protected discrete Real phil[1].randomSeed[3];
//   protected Boolean phil[1].canEat;
//   protected Boolean phil[1].timeToChangeState;
//   protected Boolean phil[1].timeToGetHungry;
//   protected Boolean phil[1].doneEating;
//   Boolean phil[2].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean phil[2].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean phil[2].mutexPort.ok "This signals that ownership was granted";
//   discrete Real phil[2].startSeed[1];
//   discrete Real phil[2].startSeed[2];
//   discrete Real phil[2].startSeed[3];
//   parameter Real phil[2].mu = 20.0 "mean value";
//   parameter Real phil[2].sigma = sigma "standard dev";
//   discrete Integer phil[2].state "1==thinking, 2==hungry, 3==eating";
//   Boolean phil[2].left.pickedUp(start = false);
//   Boolean phil[2].left.busy;
//   Boolean phil[2].right.pickedUp(start = false);
//   Boolean phil[2].right.busy;
//   protected constant Integer phil[2].thinking = 0;
//   protected constant Integer phil[2].hungry = 1;
//   protected constant Integer phil[2].eating = 2;
//   protected discrete Real phil[2].T;
//   protected discrete Real phil[2].timeOfNextChange;
//   protected discrete Real phil[2].randomSeed[1];
//   protected discrete Real phil[2].randomSeed[2];
//   protected discrete Real phil[2].randomSeed[3];
//   protected Boolean phil[2].canEat;
//   protected Boolean phil[2].timeToChangeState;
//   protected Boolean phil[2].timeToGetHungry;
//   protected Boolean phil[2].doneEating;
//   Boolean phil[3].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean phil[3].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean phil[3].mutexPort.ok "This signals that ownership was granted";
//   discrete Real phil[3].startSeed[1];
//   discrete Real phil[3].startSeed[2];
//   discrete Real phil[3].startSeed[3];
//   parameter Real phil[3].mu = 20.0 "mean value";
//   parameter Real phil[3].sigma = sigma "standard dev";
//   discrete Integer phil[3].state "1==thinking, 2==hungry, 3==eating";
//   Boolean phil[3].left.pickedUp(start = false);
//   Boolean phil[3].left.busy;
//   Boolean phil[3].right.pickedUp(start = false);
//   Boolean phil[3].right.busy;
//   protected constant Integer phil[3].thinking = 0;
//   protected constant Integer phil[3].hungry = 1;
//   protected constant Integer phil[3].eating = 2;
//   protected discrete Real phil[3].T;
//   protected discrete Real phil[3].timeOfNextChange;
//   protected discrete Real phil[3].randomSeed[1];
//   protected discrete Real phil[3].randomSeed[2];
//   protected discrete Real phil[3].randomSeed[3];
//   protected Boolean phil[3].canEat;
//   protected Boolean phil[3].timeToChangeState;
//   protected Boolean phil[3].timeToGetHungry;
//   protected Boolean phil[3].doneEating;
//   Boolean phil[4].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean phil[4].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean phil[4].mutexPort.ok "This signals that ownership was granted";
//   discrete Real phil[4].startSeed[1];
//   discrete Real phil[4].startSeed[2];
//   discrete Real phil[4].startSeed[3];
//   parameter Real phil[4].mu = 20.0 "mean value";
//   parameter Real phil[4].sigma = sigma "standard dev";
//   discrete Integer phil[4].state "1==thinking, 2==hungry, 3==eating";
//   Boolean phil[4].left.pickedUp(start = false);
//   Boolean phil[4].left.busy;
//   Boolean phil[4].right.pickedUp(start = false);
//   Boolean phil[4].right.busy;
//   protected constant Integer phil[4].thinking = 0;
//   protected constant Integer phil[4].hungry = 1;
//   protected constant Integer phil[4].eating = 2;
//   protected discrete Real phil[4].T;
//   protected discrete Real phil[4].timeOfNextChange;
//   protected discrete Real phil[4].randomSeed[1];
//   protected discrete Real phil[4].randomSeed[2];
//   protected discrete Real phil[4].randomSeed[3];
//   protected Boolean phil[4].canEat;
//   protected Boolean phil[4].timeToChangeState;
//   protected Boolean phil[4].timeToGetHungry;
//   protected Boolean phil[4].doneEating;
//   Boolean phil[5].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean phil[5].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean phil[5].mutexPort.ok "This signals that ownership was granted";
//   discrete Real phil[5].startSeed[1];
//   discrete Real phil[5].startSeed[2];
//   discrete Real phil[5].startSeed[3];
//   parameter Real phil[5].mu = 20.0 "mean value";
//   parameter Real phil[5].sigma = sigma "standard dev";
//   discrete Integer phil[5].state "1==thinking, 2==hungry, 3==eating";
//   Boolean phil[5].left.pickedUp(start = false);
//   Boolean phil[5].left.busy;
//   Boolean phil[5].right.pickedUp(start = false);
//   Boolean phil[5].right.busy;
//   protected constant Integer phil[5].thinking = 0;
//   protected constant Integer phil[5].hungry = 1;
//   protected constant Integer phil[5].eating = 2;
//   protected discrete Real phil[5].T;
//   protected discrete Real phil[5].timeOfNextChange;
//   protected discrete Real phil[5].randomSeed[1];
//   protected discrete Real phil[5].randomSeed[2];
//   protected discrete Real phil[5].randomSeed[3];
//   protected Boolean phil[5].canEat;
//   protected Boolean phil[5].timeToChangeState;
//   protected Boolean phil[5].timeToGetHungry;
//   protected Boolean phil[5].doneEating;
//   parameter Integer mutex.n = n "The number of connected ports";
//   Boolean mutex.port[1].request "Set by application to request access";
//   Boolean mutex.port[1].release "Set by application to release access";
//   Boolean mutex.port[1].ok "Signal that ownership was granted";
//   Boolean mutex.port[2].request "Set by application to request access";
//   Boolean mutex.port[2].release "Set by application to release access";
//   Boolean mutex.port[2].ok "Signal that ownership was granted";
//   Boolean mutex.port[3].request "Set by application to request access";
//   Boolean mutex.port[3].release "Set by application to release access";
//   Boolean mutex.port[3].ok "Signal that ownership was granted";
//   Boolean mutex.port[4].request "Set by application to request access";
//   Boolean mutex.port[4].release "Set by application to release access";
//   Boolean mutex.port[4].ok "Signal that ownership was granted";
//   Boolean mutex.port[5].request "Set by application to request access";
//   Boolean mutex.port[5].release "Set by application to release access";
//   Boolean mutex.port[5].ok "Signal that ownership was granted";
//   protected Boolean mutex.request[1];
//   protected Boolean mutex.request[2];
//   protected Boolean mutex.request[3];
//   protected Boolean mutex.request[4];
//   protected Boolean mutex.request[5];
//   protected Boolean mutex.release[1];
//   protected Boolean mutex.release[2];
//   protected Boolean mutex.release[3];
//   protected Boolean mutex.release[4];
//   protected Boolean mutex.release[5];
//   protected Boolean mutex.ok[1];
//   protected Boolean mutex.ok[2];
//   protected Boolean mutex.ok[3];
//   protected Boolean mutex.ok[4];
//   protected Boolean mutex.ok[5];
//   protected Boolean mutex.waiting[1];
//   protected Boolean mutex.waiting[2];
//   protected Boolean mutex.waiting[3];
//   protected Boolean mutex.waiting[4];
//   protected Boolean mutex.waiting[5];
//   protected Boolean mutex.occupied "Mutex is locked if occupied is true";
//   Boolean fork[1].left.pickedUp(start = false);
//   Boolean fork[1].left.busy;
//   Boolean fork[1].right.pickedUp(start = false);
//   Boolean fork[1].right.busy;
//   Boolean fork[2].left.pickedUp(start = false);
//   Boolean fork[2].left.busy;
//   Boolean fork[2].right.pickedUp(start = false);
//   Boolean fork[2].right.busy;
//   Boolean fork[3].left.pickedUp(start = false);
//   Boolean fork[3].left.busy;
//   Boolean fork[3].right.pickedUp(start = false);
//   Boolean fork[3].right.busy;
//   Boolean fork[4].left.pickedUp(start = false);
//   Boolean fork[4].left.busy;
//   Boolean fork[4].right.pickedUp(start = false);
//   Boolean fork[4].right.busy;
//   Boolean fork[5].left.pickedUp(start = false);
//   Boolean fork[5].left.busy;
//   Boolean fork[5].right.pickedUp(start = false);
//   Boolean fork[5].right.busy;
// equation
//   phil[1].startSeed = {1.0, 2.0, 3.0};
//   phil[1].timeToChangeState = phil[1].timeOfNextChange <= time;
//   phil[1].canEat = phil[1].state == 1 and not (phil[1].left.busy or phil[1].right.busy);
//   phil[1].timeToGetHungry = phil[1].state == 0 and phil[1].timeToChangeState;
//   phil[1].doneEating = phil[1].state == 2 and phil[1].timeToChangeState;
//   phil[2].startSeed = {1.0, 2.0, 3.0};
//   phil[2].timeToChangeState = phil[2].timeOfNextChange <= time;
//   phil[2].canEat = phil[2].state == 1 and not (phil[2].left.busy or phil[2].right.busy);
//   phil[2].timeToGetHungry = phil[2].state == 0 and phil[2].timeToChangeState;
//   phil[2].doneEating = phil[2].state == 2 and phil[2].timeToChangeState;
//   phil[3].startSeed = {1.0, 2.0, 3.0};
//   phil[3].timeToChangeState = phil[3].timeOfNextChange <= time;
//   phil[3].canEat = phil[3].state == 1 and not (phil[3].left.busy or phil[3].right.busy);
//   phil[3].timeToGetHungry = phil[3].state == 0 and phil[3].timeToChangeState;
//   phil[3].doneEating = phil[3].state == 2 and phil[3].timeToChangeState;
//   phil[4].startSeed = {1.0, 2.0, 3.0};
//   phil[4].timeToChangeState = phil[4].timeOfNextChange <= time;
//   phil[4].canEat = phil[4].state == 1 and not (phil[4].left.busy or phil[4].right.busy);
//   phil[4].timeToGetHungry = phil[4].state == 0 and phil[4].timeToChangeState;
//   phil[4].doneEating = phil[4].state == 2 and phil[4].timeToChangeState;
//   phil[5].startSeed = {1.0, 2.0, 3.0};
//   phil[5].timeToChangeState = phil[5].timeOfNextChange <= time;
//   phil[5].canEat = phil[5].state == 1 and not (phil[5].left.busy or phil[5].right.busy);
//   phil[5].timeToGetHungry = phil[5].state == 0 and phil[5].timeToChangeState;
//   phil[5].doneEating = phil[5].state == 2 and phil[5].timeToChangeState;
//   mutex.port[1].ok = mutex.ok[1];
//   mutex.request[1] = mutex.port[1].request;
//   mutex.release[1] = mutex.port[1].release;
//   mutex.port[2].ok = mutex.ok[2];
//   mutex.request[2] = mutex.port[2].request;
//   mutex.release[2] = mutex.port[2].release;
//   mutex.port[3].ok = mutex.ok[3];
//   mutex.request[3] = mutex.port[3].request;
//   mutex.release[3] = mutex.port[3].release;
//   mutex.port[4].ok = mutex.ok[4];
//   mutex.request[4] = mutex.port[4].request;
//   mutex.release[4] = mutex.port[4].release;
//   mutex.port[5].ok = mutex.ok[5];
//   mutex.request[5] = mutex.port[5].request;
//   mutex.release[5] = mutex.port[5].release;
//   fork[1].right.busy = fork[1].left.pickedUp;
//   fork[1].left.busy = fork[1].right.pickedUp;
//   fork[2].right.busy = fork[2].left.pickedUp;
//   fork[2].left.busy = fork[2].right.pickedUp;
//   fork[3].right.busy = fork[3].left.pickedUp;
//   fork[3].left.busy = fork[3].right.pickedUp;
//   fork[4].right.busy = fork[4].left.pickedUp;
//   fork[4].left.busy = fork[4].right.pickedUp;
//   fork[5].right.busy = fork[5].left.pickedUp;
//   fork[5].left.busy = fork[5].right.pickedUp;
//   mutex.port[1].ok = phil[1].mutexPort.ok;
//   mutex.port[1].release = phil[1].mutexPort.release;
//   mutex.port[1].request = phil[1].mutexPort.request;
//   fork[1].left.busy = phil[1].right.busy;
//   fork[1].left.pickedUp = phil[1].right.pickedUp;
//   fork[1].right.busy = phil[2].left.busy;
//   fork[1].right.pickedUp = phil[2].left.pickedUp;
//   mutex.port[2].ok = phil[2].mutexPort.ok;
//   mutex.port[2].release = phil[2].mutexPort.release;
//   mutex.port[2].request = phil[2].mutexPort.request;
//   fork[2].left.busy = phil[2].right.busy;
//   fork[2].left.pickedUp = phil[2].right.pickedUp;
//   fork[2].right.busy = phil[3].left.busy;
//   fork[2].right.pickedUp = phil[3].left.pickedUp;
//   mutex.port[3].ok = phil[3].mutexPort.ok;
//   mutex.port[3].release = phil[3].mutexPort.release;
//   mutex.port[3].request = phil[3].mutexPort.request;
//   fork[3].left.busy = phil[3].right.busy;
//   fork[3].left.pickedUp = phil[3].right.pickedUp;
//   fork[3].right.busy = phil[4].left.busy;
//   fork[3].right.pickedUp = phil[4].left.pickedUp;
//   mutex.port[4].ok = phil[4].mutexPort.ok;
//   mutex.port[4].release = phil[4].mutexPort.release;
//   mutex.port[4].request = phil[4].mutexPort.request;
//   fork[4].left.busy = phil[4].right.busy;
//   fork[4].left.pickedUp = phil[4].right.pickedUp;
//   fork[4].right.busy = phil[5].left.busy;
//   fork[4].right.pickedUp = phil[5].left.pickedUp;
//   mutex.port[5].ok = phil[5].mutexPort.ok;
//   mutex.port[5].release = phil[5].mutexPort.release;
//   mutex.port[5].request = phil[5].mutexPort.request;
//   fork[5].left.busy = phil[5].right.busy;
//   fork[5].left.pickedUp = phil[5].right.pickedUp;
//   fork[5].right.busy = phil[1].left.busy;
//   fork[5].right.pickedUp = phil[1].left.pickedUp;
// algorithm
//   when initial() then
//     phil[1].state := 0;
//     phil[1].left.pickedUp := false;
//     phil[1].right.pickedUp := false;
//     (phil[1].T, phil[1].randomSeed) := Philosopher.Random.normalvariate(phil[1].mu, phil[1].sigma, {phil[1].startSeed[1], phil[1].startSeed[2], phil[1].startSeed[3]});
//     phil[1].timeOfNextChange := abs(phil[1].T);
//   elsewhen pre(phil[1].timeToGetHungry) then
//     phil[1].state := 1;
//   end when;
//   when pre(phil[1].canEat) then
//     phil[1].mutexPort.release := false;
//     phil[1].mutexPort.request := true;
//   end when;
//   when pre(phil[1].mutexPort.ok) then
//     if pre(phil[1].canEat) then
//       phil[1].left.pickedUp := true;
//       phil[1].right.pickedUp := true;
//       (phil[1].T, phil[1].randomSeed) := Philosopher.Random.normalvariate(phil[1].mu, phil[1].sigma, {pre(phil[1].randomSeed[1]), pre(phil[1].randomSeed[2]), pre(phil[1].randomSeed[3])});
//       phil[1].timeOfNextChange := time + abs(phil[1].T);
//       phil[1].state := 2;
//     end if;
//     phil[1].mutexPort.release := true;
//     phil[1].mutexPort.request := false;
//   end when;
//   when pre(phil[1].doneEating) then
//     phil[1].state := 0;
//     phil[1].left.pickedUp := false;
//     phil[1].right.pickedUp := false;
//     (phil[1].T, phil[1].randomSeed) := Philosopher.Random.normalvariate(phil[1].mu, phil[1].sigma, {pre(phil[1].randomSeed[1]), pre(phil[1].randomSeed[2]), pre(phil[1].randomSeed[3])});
//     phil[1].timeOfNextChange := time + abs(phil[1].T);
//   end when;
// algorithm
//   when initial() then
//     phil[2].state := 0;
//     phil[2].left.pickedUp := false;
//     phil[2].right.pickedUp := false;
//     (phil[2].T, phil[2].randomSeed) := Philosopher.Random.normalvariate(phil[2].mu, phil[2].sigma, {phil[2].startSeed[1], phil[2].startSeed[2], phil[2].startSeed[3]});
//     phil[2].timeOfNextChange := abs(phil[2].T);
//   elsewhen pre(phil[2].timeToGetHungry) then
//     phil[2].state := 1;
//   end when;
//   when pre(phil[2].canEat) then
//     phil[2].mutexPort.release := false;
//     phil[2].mutexPort.request := true;
//   end when;
//   when pre(phil[2].mutexPort.ok) then
//     if pre(phil[2].canEat) then
//       phil[2].left.pickedUp := true;
//       phil[2].right.pickedUp := true;
//       (phil[2].T, phil[2].randomSeed) := Philosopher.Random.normalvariate(phil[2].mu, phil[2].sigma, {pre(phil[2].randomSeed[1]), pre(phil[2].randomSeed[2]), pre(phil[2].randomSeed[3])});
//       phil[2].timeOfNextChange := time + abs(phil[2].T);
//       phil[2].state := 2;
//     end if;
//     phil[2].mutexPort.release := true;
//     phil[2].mutexPort.request := false;
//   end when;
//   when pre(phil[2].doneEating) then
//     phil[2].state := 0;
//     phil[2].left.pickedUp := false;
//     phil[2].right.pickedUp := false;
//     (phil[2].T, phil[2].randomSeed) := Philosopher.Random.normalvariate(phil[2].mu, phil[2].sigma, {pre(phil[2].randomSeed[1]), pre(phil[2].randomSeed[2]), pre(phil[2].randomSeed[3])});
//     phil[2].timeOfNextChange := time + abs(phil[2].T);
//   end when;
// algorithm
//   when initial() then
//     phil[3].state := 0;
//     phil[3].left.pickedUp := false;
//     phil[3].right.pickedUp := false;
//     (phil[3].T, phil[3].randomSeed) := Philosopher.Random.normalvariate(phil[3].mu, phil[3].sigma, {phil[3].startSeed[1], phil[3].startSeed[2], phil[3].startSeed[3]});
//     phil[3].timeOfNextChange := abs(phil[3].T);
//   elsewhen pre(phil[3].timeToGetHungry) then
//     phil[3].state := 1;
//   end when;
//   when pre(phil[3].canEat) then
//     phil[3].mutexPort.release := false;
//     phil[3].mutexPort.request := true;
//   end when;
//   when pre(phil[3].mutexPort.ok) then
//     if pre(phil[3].canEat) then
//       phil[3].left.pickedUp := true;
//       phil[3].right.pickedUp := true;
//       (phil[3].T, phil[3].randomSeed) := Philosopher.Random.normalvariate(phil[3].mu, phil[3].sigma, {pre(phil[3].randomSeed[1]), pre(phil[3].randomSeed[2]), pre(phil[3].randomSeed[3])});
//       phil[3].timeOfNextChange := time + abs(phil[3].T);
//       phil[3].state := 2;
//     end if;
//     phil[3].mutexPort.release := true;
//     phil[3].mutexPort.request := false;
//   end when;
//   when pre(phil[3].doneEating) then
//     phil[3].state := 0;
//     phil[3].left.pickedUp := false;
//     phil[3].right.pickedUp := false;
//     (phil[3].T, phil[3].randomSeed) := Philosopher.Random.normalvariate(phil[3].mu, phil[3].sigma, {pre(phil[3].randomSeed[1]), pre(phil[3].randomSeed[2]), pre(phil[3].randomSeed[3])});
//     phil[3].timeOfNextChange := time + abs(phil[3].T);
//   end when;
// algorithm
//   when initial() then
//     phil[4].state := 0;
//     phil[4].left.pickedUp := false;
//     phil[4].right.pickedUp := false;
//     (phil[4].T, phil[4].randomSeed) := Philosopher.Random.normalvariate(phil[4].mu, phil[4].sigma, {phil[4].startSeed[1], phil[4].startSeed[2], phil[4].startSeed[3]});
//     phil[4].timeOfNextChange := abs(phil[4].T);
//   elsewhen pre(phil[4].timeToGetHungry) then
//     phil[4].state := 1;
//   end when;
//   when pre(phil[4].canEat) then
//     phil[4].mutexPort.release := false;
//     phil[4].mutexPort.request := true;
//   end when;
//   when pre(phil[4].mutexPort.ok) then
//     if pre(phil[4].canEat) then
//       phil[4].left.pickedUp := true;
//       phil[4].right.pickedUp := true;
//       (phil[4].T, phil[4].randomSeed) := Philosopher.Random.normalvariate(phil[4].mu, phil[4].sigma, {pre(phil[4].randomSeed[1]), pre(phil[4].randomSeed[2]), pre(phil[4].randomSeed[3])});
//       phil[4].timeOfNextChange := time + abs(phil[4].T);
//       phil[4].state := 2;
//     end if;
//     phil[4].mutexPort.release := true;
//     phil[4].mutexPort.request := false;
//   end when;
//   when pre(phil[4].doneEating) then
//     phil[4].state := 0;
//     phil[4].left.pickedUp := false;
//     phil[4].right.pickedUp := false;
//     (phil[4].T, phil[4].randomSeed) := Philosopher.Random.normalvariate(phil[4].mu, phil[4].sigma, {pre(phil[4].randomSeed[1]), pre(phil[4].randomSeed[2]), pre(phil[4].randomSeed[3])});
//     phil[4].timeOfNextChange := time + abs(phil[4].T);
//   end when;
// algorithm
//   when initial() then
//     phil[5].state := 0;
//     phil[5].left.pickedUp := false;
//     phil[5].right.pickedUp := false;
//     (phil[5].T, phil[5].randomSeed) := Philosopher.Random.normalvariate(phil[5].mu, phil[5].sigma, {phil[5].startSeed[1], phil[5].startSeed[2], phil[5].startSeed[3]});
//     phil[5].timeOfNextChange := abs(phil[5].T);
//   elsewhen pre(phil[5].timeToGetHungry) then
//     phil[5].state := 1;
//   end when;
//   when pre(phil[5].canEat) then
//     phil[5].mutexPort.release := false;
//     phil[5].mutexPort.request := true;
//   end when;
//   when pre(phil[5].mutexPort.ok) then
//     if pre(phil[5].canEat) then
//       phil[5].left.pickedUp := true;
//       phil[5].right.pickedUp := true;
//       (phil[5].T, phil[5].randomSeed) := Philosopher.Random.normalvariate(phil[5].mu, phil[5].sigma, {pre(phil[5].randomSeed[1]), pre(phil[5].randomSeed[2]), pre(phil[5].randomSeed[3])});
//       phil[5].timeOfNextChange := time + abs(phil[5].T);
//       phil[5].state := 2;
//     end if;
//     phil[5].mutexPort.release := true;
//     phil[5].mutexPort.request := false;
//   end when;
//   when pre(phil[5].doneEating) then
//     phil[5].state := 0;
//     phil[5].left.pickedUp := false;
//     phil[5].right.pickedUp := false;
//     (phil[5].T, phil[5].randomSeed) := Philosopher.Random.normalvariate(phil[5].mu, phil[5].sigma, {pre(phil[5].randomSeed[1]), pre(phil[5].randomSeed[2]), pre(phil[5].randomSeed[3])});
//     phil[5].timeOfNextChange := time + abs(phil[5].T);
//   end when;
// algorithm
//   when mutex.request[1] then
//     if not mutex.occupied then
//       mutex.ok[1] := true;
//       mutex.waiting[1] := false;
//     else
//       mutex.ok[1] := false;
//       mutex.waiting[1] := true;
//     end if;
//     mutex.occupied := true;
//   end when;
//   when pre(mutex.waiting[1]) and not mutex.occupied then
//     mutex.occupied := true;
//     mutex.ok[1] := true;
//     mutex.waiting[1] := false;
//   end when;
//   when pre(mutex.release[1]) then
//     mutex.ok[1] := false;
//     mutex.occupied := false;
//   end when;
//   when mutex.request[2] then
//     if not mutex.occupied then
//       mutex.ok[2] := true;
//       mutex.waiting[2] := false;
//     else
//       mutex.ok[2] := false;
//       mutex.waiting[2] := true;
//     end if;
//     mutex.occupied := true;
//   end when;
//   when pre(mutex.waiting[2]) and not mutex.occupied then
//     mutex.occupied := true;
//     mutex.ok[2] := true;
//     mutex.waiting[2] := false;
//   end when;
//   when pre(mutex.release[2]) then
//     mutex.ok[2] := false;
//     mutex.occupied := false;
//   end when;
//   when mutex.request[3] then
//     if not mutex.occupied then
//       mutex.ok[3] := true;
//       mutex.waiting[3] := false;
//     else
//       mutex.ok[3] := false;
//       mutex.waiting[3] := true;
//     end if;
//     mutex.occupied := true;
//   end when;
//   when pre(mutex.waiting[3]) and not mutex.occupied then
//     mutex.occupied := true;
//     mutex.ok[3] := true;
//     mutex.waiting[3] := false;
//   end when;
//   when pre(mutex.release[3]) then
//     mutex.ok[3] := false;
//     mutex.occupied := false;
//   end when;
//   when mutex.request[4] then
//     if not mutex.occupied then
//       mutex.ok[4] := true;
//       mutex.waiting[4] := false;
//     else
//       mutex.ok[4] := false;
//       mutex.waiting[4] := true;
//     end if;
//     mutex.occupied := true;
//   end when;
//   when pre(mutex.waiting[4]) and not mutex.occupied then
//     mutex.occupied := true;
//     mutex.ok[4] := true;
//     mutex.waiting[4] := false;
//   end when;
//   when pre(mutex.release[4]) then
//     mutex.ok[4] := false;
//     mutex.occupied := false;
//   end when;
//   when mutex.request[5] then
//     if not mutex.occupied then
//       mutex.ok[5] := true;
//       mutex.waiting[5] := false;
//     else
//       mutex.ok[5] := false;
//       mutex.waiting[5] := true;
//     end if;
//     mutex.occupied := true;
//   end when;
//   when pre(mutex.waiting[5]) and not mutex.occupied then
//     mutex.occupied := true;
//     mutex.ok[5] := true;
//     mutex.waiting[5] := false;
//   end when;
//   when pre(mutex.release[5]) then
//     mutex.ok[5] := false;
//     mutex.occupied := false;
//   end when;
// end Philosopher_DiningTable;
// endResult

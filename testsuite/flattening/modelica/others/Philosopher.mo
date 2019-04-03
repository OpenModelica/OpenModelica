// name:     Philosopher
// keywords: Example
// cflags: +std=2.x
// status:   correct
//
// This is the dining philosopher model from Peter F. book.
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
  Philosopher.DiningTable t;
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
//   parameter Integer t.n = 5 "Number of philosophers and forks";
//   parameter Real t.sigma = 5.0 "Standard deviation of delay times";
//   Boolean t.phil[1].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean t.phil[1].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean t.phil[1].mutexPort.ok "This signals that ownership was granted";
//   discrete Real t.phil[1].startSeed[1];
//   discrete Real t.phil[1].startSeed[2];
//   discrete Real t.phil[1].startSeed[3];
//   parameter Real t.phil[1].mu = 20.0 "mean value";
//   parameter Real t.phil[1].sigma = t.sigma "standard dev";
//   discrete Integer t.phil[1].state "1==thinking, 2==hungry, 3==eating";
//   Boolean t.phil[1].left.pickedUp(start = false);
//   Boolean t.phil[1].left.busy;
//   Boolean t.phil[1].right.pickedUp(start = false);
//   Boolean t.phil[1].right.busy;
//   protected constant Integer t.phil[1].thinking = 0;
//   protected constant Integer t.phil[1].hungry = 1;
//   protected constant Integer t.phil[1].eating = 2;
//   protected discrete Real t.phil[1].T;
//   protected discrete Real t.phil[1].timeOfNextChange;
//   protected discrete Real t.phil[1].randomSeed[1];
//   protected discrete Real t.phil[1].randomSeed[2];
//   protected discrete Real t.phil[1].randomSeed[3];
//   protected Boolean t.phil[1].canEat;
//   protected Boolean t.phil[1].timeToChangeState;
//   protected Boolean t.phil[1].timeToGetHungry;
//   protected Boolean t.phil[1].doneEating;
//   Boolean t.phil[2].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean t.phil[2].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean t.phil[2].mutexPort.ok "This signals that ownership was granted";
//   discrete Real t.phil[2].startSeed[1];
//   discrete Real t.phil[2].startSeed[2];
//   discrete Real t.phil[2].startSeed[3];
//   parameter Real t.phil[2].mu = 20.0 "mean value";
//   parameter Real t.phil[2].sigma = t.sigma "standard dev";
//   discrete Integer t.phil[2].state "1==thinking, 2==hungry, 3==eating";
//   Boolean t.phil[2].left.pickedUp(start = false);
//   Boolean t.phil[2].left.busy;
//   Boolean t.phil[2].right.pickedUp(start = false);
//   Boolean t.phil[2].right.busy;
//   protected constant Integer t.phil[2].thinking = 0;
//   protected constant Integer t.phil[2].hungry = 1;
//   protected constant Integer t.phil[2].eating = 2;
//   protected discrete Real t.phil[2].T;
//   protected discrete Real t.phil[2].timeOfNextChange;
//   protected discrete Real t.phil[2].randomSeed[1];
//   protected discrete Real t.phil[2].randomSeed[2];
//   protected discrete Real t.phil[2].randomSeed[3];
//   protected Boolean t.phil[2].canEat;
//   protected Boolean t.phil[2].timeToChangeState;
//   protected Boolean t.phil[2].timeToGetHungry;
//   protected Boolean t.phil[2].doneEating;
//   Boolean t.phil[3].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean t.phil[3].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean t.phil[3].mutexPort.ok "This signals that ownership was granted";
//   discrete Real t.phil[3].startSeed[1];
//   discrete Real t.phil[3].startSeed[2];
//   discrete Real t.phil[3].startSeed[3];
//   parameter Real t.phil[3].mu = 20.0 "mean value";
//   parameter Real t.phil[3].sigma = t.sigma "standard dev";
//   discrete Integer t.phil[3].state "1==thinking, 2==hungry, 3==eating";
//   Boolean t.phil[3].left.pickedUp(start = false);
//   Boolean t.phil[3].left.busy;
//   Boolean t.phil[3].right.pickedUp(start = false);
//   Boolean t.phil[3].right.busy;
//   protected constant Integer t.phil[3].thinking = 0;
//   protected constant Integer t.phil[3].hungry = 1;
//   protected constant Integer t.phil[3].eating = 2;
//   protected discrete Real t.phil[3].T;
//   protected discrete Real t.phil[3].timeOfNextChange;
//   protected discrete Real t.phil[3].randomSeed[1];
//   protected discrete Real t.phil[3].randomSeed[2];
//   protected discrete Real t.phil[3].randomSeed[3];
//   protected Boolean t.phil[3].canEat;
//   protected Boolean t.phil[3].timeToChangeState;
//   protected Boolean t.phil[3].timeToGetHungry;
//   protected Boolean t.phil[3].doneEating;
//   Boolean t.phil[4].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean t.phil[4].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean t.phil[4].mutexPort.ok "This signals that ownership was granted";
//   discrete Real t.phil[4].startSeed[1];
//   discrete Real t.phil[4].startSeed[2];
//   discrete Real t.phil[4].startSeed[3];
//   parameter Real t.phil[4].mu = 20.0 "mean value";
//   parameter Real t.phil[4].sigma = t.sigma "standard dev";
//   discrete Integer t.phil[4].state "1==thinking, 2==hungry, 3==eating";
//   Boolean t.phil[4].left.pickedUp(start = false);
//   Boolean t.phil[4].left.busy;
//   Boolean t.phil[4].right.pickedUp(start = false);
//   Boolean t.phil[4].right.busy;
//   protected constant Integer t.phil[4].thinking = 0;
//   protected constant Integer t.phil[4].hungry = 1;
//   protected constant Integer t.phil[4].eating = 2;
//   protected discrete Real t.phil[4].T;
//   protected discrete Real t.phil[4].timeOfNextChange;
//   protected discrete Real t.phil[4].randomSeed[1];
//   protected discrete Real t.phil[4].randomSeed[2];
//   protected discrete Real t.phil[4].randomSeed[3];
//   protected Boolean t.phil[4].canEat;
//   protected Boolean t.phil[4].timeToChangeState;
//   protected Boolean t.phil[4].timeToGetHungry;
//   protected Boolean t.phil[4].doneEating;
//   Boolean t.phil[5].mutexPort.request "Set this to request ownership of the mutex";
//   Boolean t.phil[5].mutexPort.release "Set this to release ownership of the mutex";
//   Boolean t.phil[5].mutexPort.ok "This signals that ownership was granted";
//   discrete Real t.phil[5].startSeed[1];
//   discrete Real t.phil[5].startSeed[2];
//   discrete Real t.phil[5].startSeed[3];
//   parameter Real t.phil[5].mu = 20.0 "mean value";
//   parameter Real t.phil[5].sigma = t.sigma "standard dev";
//   discrete Integer t.phil[5].state "1==thinking, 2==hungry, 3==eating";
//   Boolean t.phil[5].left.pickedUp(start = false);
//   Boolean t.phil[5].left.busy;
//   Boolean t.phil[5].right.pickedUp(start = false);
//   Boolean t.phil[5].right.busy;
//   protected constant Integer t.phil[5].thinking = 0;
//   protected constant Integer t.phil[5].hungry = 1;
//   protected constant Integer t.phil[5].eating = 2;
//   protected discrete Real t.phil[5].T;
//   protected discrete Real t.phil[5].timeOfNextChange;
//   protected discrete Real t.phil[5].randomSeed[1];
//   protected discrete Real t.phil[5].randomSeed[2];
//   protected discrete Real t.phil[5].randomSeed[3];
//   protected Boolean t.phil[5].canEat;
//   protected Boolean t.phil[5].timeToChangeState;
//   protected Boolean t.phil[5].timeToGetHungry;
//   protected Boolean t.phil[5].doneEating;
//   parameter Integer t.mutex.n = t.n "The number of connected ports";
//   Boolean t.mutex.port[1].request "Set by application to request access";
//   Boolean t.mutex.port[1].release "Set by application to release access";
//   Boolean t.mutex.port[1].ok "Signal that ownership was granted";
//   Boolean t.mutex.port[2].request "Set by application to request access";
//   Boolean t.mutex.port[2].release "Set by application to release access";
//   Boolean t.mutex.port[2].ok "Signal that ownership was granted";
//   Boolean t.mutex.port[3].request "Set by application to request access";
//   Boolean t.mutex.port[3].release "Set by application to release access";
//   Boolean t.mutex.port[3].ok "Signal that ownership was granted";
//   Boolean t.mutex.port[4].request "Set by application to request access";
//   Boolean t.mutex.port[4].release "Set by application to release access";
//   Boolean t.mutex.port[4].ok "Signal that ownership was granted";
//   Boolean t.mutex.port[5].request "Set by application to request access";
//   Boolean t.mutex.port[5].release "Set by application to release access";
//   Boolean t.mutex.port[5].ok "Signal that ownership was granted";
//   protected Boolean t.mutex.request[1];
//   protected Boolean t.mutex.request[2];
//   protected Boolean t.mutex.request[3];
//   protected Boolean t.mutex.request[4];
//   protected Boolean t.mutex.request[5];
//   protected Boolean t.mutex.release[1];
//   protected Boolean t.mutex.release[2];
//   protected Boolean t.mutex.release[3];
//   protected Boolean t.mutex.release[4];
//   protected Boolean t.mutex.release[5];
//   protected Boolean t.mutex.ok[1];
//   protected Boolean t.mutex.ok[2];
//   protected Boolean t.mutex.ok[3];
//   protected Boolean t.mutex.ok[4];
//   protected Boolean t.mutex.ok[5];
//   protected Boolean t.mutex.waiting[1];
//   protected Boolean t.mutex.waiting[2];
//   protected Boolean t.mutex.waiting[3];
//   protected Boolean t.mutex.waiting[4];
//   protected Boolean t.mutex.waiting[5];
//   protected Boolean t.mutex.occupied "Mutex is locked if occupied is true";
//   Boolean t.fork[1].left.pickedUp(start = false);
//   Boolean t.fork[1].left.busy;
//   Boolean t.fork[1].right.pickedUp(start = false);
//   Boolean t.fork[1].right.busy;
//   Boolean t.fork[2].left.pickedUp(start = false);
//   Boolean t.fork[2].left.busy;
//   Boolean t.fork[2].right.pickedUp(start = false);
//   Boolean t.fork[2].right.busy;
//   Boolean t.fork[3].left.pickedUp(start = false);
//   Boolean t.fork[3].left.busy;
//   Boolean t.fork[3].right.pickedUp(start = false);
//   Boolean t.fork[3].right.busy;
//   Boolean t.fork[4].left.pickedUp(start = false);
//   Boolean t.fork[4].left.busy;
//   Boolean t.fork[4].right.pickedUp(start = false);
//   Boolean t.fork[4].right.busy;
//   Boolean t.fork[5].left.pickedUp(start = false);
//   Boolean t.fork[5].left.busy;
//   Boolean t.fork[5].right.pickedUp(start = false);
//   Boolean t.fork[5].right.busy;
// equation
//   t.phil[1].startSeed = {1.0, 2.0, 3.0};
//   t.phil[1].timeToChangeState = t.phil[1].timeOfNextChange <= time;
//   t.phil[1].canEat = t.phil[1].state == 1 and not (t.phil[1].left.busy or t.phil[1].right.busy);
//   t.phil[1].timeToGetHungry = t.phil[1].state == 0 and t.phil[1].timeToChangeState;
//   t.phil[1].doneEating = t.phil[1].state == 2 and t.phil[1].timeToChangeState;
//   t.phil[2].startSeed = {1.0, 2.0, 3.0};
//   t.phil[2].timeToChangeState = t.phil[2].timeOfNextChange <= time;
//   t.phil[2].canEat = t.phil[2].state == 1 and not (t.phil[2].left.busy or t.phil[2].right.busy);
//   t.phil[2].timeToGetHungry = t.phil[2].state == 0 and t.phil[2].timeToChangeState;
//   t.phil[2].doneEating = t.phil[2].state == 2 and t.phil[2].timeToChangeState;
//   t.phil[3].startSeed = {1.0, 2.0, 3.0};
//   t.phil[3].timeToChangeState = t.phil[3].timeOfNextChange <= time;
//   t.phil[3].canEat = t.phil[3].state == 1 and not (t.phil[3].left.busy or t.phil[3].right.busy);
//   t.phil[3].timeToGetHungry = t.phil[3].state == 0 and t.phil[3].timeToChangeState;
//   t.phil[3].doneEating = t.phil[3].state == 2 and t.phil[3].timeToChangeState;
//   t.phil[4].startSeed = {1.0, 2.0, 3.0};
//   t.phil[4].timeToChangeState = t.phil[4].timeOfNextChange <= time;
//   t.phil[4].canEat = t.phil[4].state == 1 and not (t.phil[4].left.busy or t.phil[4].right.busy);
//   t.phil[4].timeToGetHungry = t.phil[4].state == 0 and t.phil[4].timeToChangeState;
//   t.phil[4].doneEating = t.phil[4].state == 2 and t.phil[4].timeToChangeState;
//   t.phil[5].startSeed = {1.0, 2.0, 3.0};
//   t.phil[5].timeToChangeState = t.phil[5].timeOfNextChange <= time;
//   t.phil[5].canEat = t.phil[5].state == 1 and not (t.phil[5].left.busy or t.phil[5].right.busy);
//   t.phil[5].timeToGetHungry = t.phil[5].state == 0 and t.phil[5].timeToChangeState;
//   t.phil[5].doneEating = t.phil[5].state == 2 and t.phil[5].timeToChangeState;
//   t.mutex.port[1].ok = t.mutex.ok[1];
//   t.mutex.request[1] = t.mutex.port[1].request;
//   t.mutex.release[1] = t.mutex.port[1].release;
//   t.mutex.port[2].ok = t.mutex.ok[2];
//   t.mutex.request[2] = t.mutex.port[2].request;
//   t.mutex.release[2] = t.mutex.port[2].release;
//   t.mutex.port[3].ok = t.mutex.ok[3];
//   t.mutex.request[3] = t.mutex.port[3].request;
//   t.mutex.release[3] = t.mutex.port[3].release;
//   t.mutex.port[4].ok = t.mutex.ok[4];
//   t.mutex.request[4] = t.mutex.port[4].request;
//   t.mutex.release[4] = t.mutex.port[4].release;
//   t.mutex.port[5].ok = t.mutex.ok[5];
//   t.mutex.request[5] = t.mutex.port[5].request;
//   t.mutex.release[5] = t.mutex.port[5].release;
//   t.fork[1].right.busy = t.fork[1].left.pickedUp;
//   t.fork[1].left.busy = t.fork[1].right.pickedUp;
//   t.fork[2].right.busy = t.fork[2].left.pickedUp;
//   t.fork[2].left.busy = t.fork[2].right.pickedUp;
//   t.fork[3].right.busy = t.fork[3].left.pickedUp;
//   t.fork[3].left.busy = t.fork[3].right.pickedUp;
//   t.fork[4].right.busy = t.fork[4].left.pickedUp;
//   t.fork[4].left.busy = t.fork[4].right.pickedUp;
//   t.fork[5].right.busy = t.fork[5].left.pickedUp;
//   t.fork[5].left.busy = t.fork[5].right.pickedUp;
//   t.mutex.port[1].ok = t.phil[1].mutexPort.ok;
//   t.mutex.port[1].release = t.phil[1].mutexPort.release;
//   t.mutex.port[1].request = t.phil[1].mutexPort.request;
//   t.fork[1].left.busy = t.phil[1].right.busy;
//   t.fork[1].left.pickedUp = t.phil[1].right.pickedUp;
//   t.fork[1].right.busy = t.phil[2].left.busy;
//   t.fork[1].right.pickedUp = t.phil[2].left.pickedUp;
//   t.mutex.port[2].ok = t.phil[2].mutexPort.ok;
//   t.mutex.port[2].release = t.phil[2].mutexPort.release;
//   t.mutex.port[2].request = t.phil[2].mutexPort.request;
//   t.fork[2].left.busy = t.phil[2].right.busy;
//   t.fork[2].left.pickedUp = t.phil[2].right.pickedUp;
//   t.fork[2].right.busy = t.phil[3].left.busy;
//   t.fork[2].right.pickedUp = t.phil[3].left.pickedUp;
//   t.mutex.port[3].ok = t.phil[3].mutexPort.ok;
//   t.mutex.port[3].release = t.phil[3].mutexPort.release;
//   t.mutex.port[3].request = t.phil[3].mutexPort.request;
//   t.fork[3].left.busy = t.phil[3].right.busy;
//   t.fork[3].left.pickedUp = t.phil[3].right.pickedUp;
//   t.fork[3].right.busy = t.phil[4].left.busy;
//   t.fork[3].right.pickedUp = t.phil[4].left.pickedUp;
//   t.mutex.port[4].ok = t.phil[4].mutexPort.ok;
//   t.mutex.port[4].release = t.phil[4].mutexPort.release;
//   t.mutex.port[4].request = t.phil[4].mutexPort.request;
//   t.fork[4].left.busy = t.phil[4].right.busy;
//   t.fork[4].left.pickedUp = t.phil[4].right.pickedUp;
//   t.fork[4].right.busy = t.phil[5].left.busy;
//   t.fork[4].right.pickedUp = t.phil[5].left.pickedUp;
//   t.mutex.port[5].ok = t.phil[5].mutexPort.ok;
//   t.mutex.port[5].release = t.phil[5].mutexPort.release;
//   t.mutex.port[5].request = t.phil[5].mutexPort.request;
//   t.fork[5].left.busy = t.phil[5].right.busy;
//   t.fork[5].left.pickedUp = t.phil[5].right.pickedUp;
//   t.fork[5].right.busy = t.phil[1].left.busy;
//   t.fork[5].right.pickedUp = t.phil[1].left.pickedUp;
// algorithm
//   when initial() then
//     t.phil[1].state := 0;
//     t.phil[1].left.pickedUp := false;
//     t.phil[1].right.pickedUp := false;
//     (t.phil[1].T, t.phil[1].randomSeed) := Philosopher.Random.normalvariate(t.phil[1].mu, t.phil[1].sigma, {t.phil[1].startSeed[1], t.phil[1].startSeed[2], t.phil[1].startSeed[3]});
//     t.phil[1].timeOfNextChange := abs(t.phil[1].T);
//   elsewhen pre(t.phil[1].timeToGetHungry) then
//     t.phil[1].state := 1;
//   end when;
//   when pre(t.phil[1].canEat) then
//     t.phil[1].mutexPort.release := false;
//     t.phil[1].mutexPort.request := true;
//   end when;
//   when pre(t.phil[1].mutexPort.ok) then
//     if pre(t.phil[1].canEat) then
//       t.phil[1].left.pickedUp := true;
//       t.phil[1].right.pickedUp := true;
//       (t.phil[1].T, t.phil[1].randomSeed) := Philosopher.Random.normalvariate(t.phil[1].mu, t.phil[1].sigma, {pre(t.phil[1].randomSeed[1]), pre(t.phil[1].randomSeed[2]), pre(t.phil[1].randomSeed[3])});
//       t.phil[1].timeOfNextChange := time + abs(t.phil[1].T);
//       t.phil[1].state := 2;
//     end if;
//     t.phil[1].mutexPort.release := true;
//     t.phil[1].mutexPort.request := false;
//   end when;
//   when pre(t.phil[1].doneEating) then
//     t.phil[1].state := 0;
//     t.phil[1].left.pickedUp := false;
//     t.phil[1].right.pickedUp := false;
//     (t.phil[1].T, t.phil[1].randomSeed) := Philosopher.Random.normalvariate(t.phil[1].mu, t.phil[1].sigma, {pre(t.phil[1].randomSeed[1]), pre(t.phil[1].randomSeed[2]), pre(t.phil[1].randomSeed[3])});
//     t.phil[1].timeOfNextChange := time + abs(t.phil[1].T);
//   end when;
// algorithm
//   when initial() then
//     t.phil[2].state := 0;
//     t.phil[2].left.pickedUp := false;
//     t.phil[2].right.pickedUp := false;
//     (t.phil[2].T, t.phil[2].randomSeed) := Philosopher.Random.normalvariate(t.phil[2].mu, t.phil[2].sigma, {t.phil[2].startSeed[1], t.phil[2].startSeed[2], t.phil[2].startSeed[3]});
//     t.phil[2].timeOfNextChange := abs(t.phil[2].T);
//   elsewhen pre(t.phil[2].timeToGetHungry) then
//     t.phil[2].state := 1;
//   end when;
//   when pre(t.phil[2].canEat) then
//     t.phil[2].mutexPort.release := false;
//     t.phil[2].mutexPort.request := true;
//   end when;
//   when pre(t.phil[2].mutexPort.ok) then
//     if pre(t.phil[2].canEat) then
//       t.phil[2].left.pickedUp := true;
//       t.phil[2].right.pickedUp := true;
//       (t.phil[2].T, t.phil[2].randomSeed) := Philosopher.Random.normalvariate(t.phil[2].mu, t.phil[2].sigma, {pre(t.phil[2].randomSeed[1]), pre(t.phil[2].randomSeed[2]), pre(t.phil[2].randomSeed[3])});
//       t.phil[2].timeOfNextChange := time + abs(t.phil[2].T);
//       t.phil[2].state := 2;
//     end if;
//     t.phil[2].mutexPort.release := true;
//     t.phil[2].mutexPort.request := false;
//   end when;
//   when pre(t.phil[2].doneEating) then
//     t.phil[2].state := 0;
//     t.phil[2].left.pickedUp := false;
//     t.phil[2].right.pickedUp := false;
//     (t.phil[2].T, t.phil[2].randomSeed) := Philosopher.Random.normalvariate(t.phil[2].mu, t.phil[2].sigma, {pre(t.phil[2].randomSeed[1]), pre(t.phil[2].randomSeed[2]), pre(t.phil[2].randomSeed[3])});
//     t.phil[2].timeOfNextChange := time + abs(t.phil[2].T);
//   end when;
// algorithm
//   when initial() then
//     t.phil[3].state := 0;
//     t.phil[3].left.pickedUp := false;
//     t.phil[3].right.pickedUp := false;
//     (t.phil[3].T, t.phil[3].randomSeed) := Philosopher.Random.normalvariate(t.phil[3].mu, t.phil[3].sigma, {t.phil[3].startSeed[1], t.phil[3].startSeed[2], t.phil[3].startSeed[3]});
//     t.phil[3].timeOfNextChange := abs(t.phil[3].T);
//   elsewhen pre(t.phil[3].timeToGetHungry) then
//     t.phil[3].state := 1;
//   end when;
//   when pre(t.phil[3].canEat) then
//     t.phil[3].mutexPort.release := false;
//     t.phil[3].mutexPort.request := true;
//   end when;
//   when pre(t.phil[3].mutexPort.ok) then
//     if pre(t.phil[3].canEat) then
//       t.phil[3].left.pickedUp := true;
//       t.phil[3].right.pickedUp := true;
//       (t.phil[3].T, t.phil[3].randomSeed) := Philosopher.Random.normalvariate(t.phil[3].mu, t.phil[3].sigma, {pre(t.phil[3].randomSeed[1]), pre(t.phil[3].randomSeed[2]), pre(t.phil[3].randomSeed[3])});
//       t.phil[3].timeOfNextChange := time + abs(t.phil[3].T);
//       t.phil[3].state := 2;
//     end if;
//     t.phil[3].mutexPort.release := true;
//     t.phil[3].mutexPort.request := false;
//   end when;
//   when pre(t.phil[3].doneEating) then
//     t.phil[3].state := 0;
//     t.phil[3].left.pickedUp := false;
//     t.phil[3].right.pickedUp := false;
//     (t.phil[3].T, t.phil[3].randomSeed) := Philosopher.Random.normalvariate(t.phil[3].mu, t.phil[3].sigma, {pre(t.phil[3].randomSeed[1]), pre(t.phil[3].randomSeed[2]), pre(t.phil[3].randomSeed[3])});
//     t.phil[3].timeOfNextChange := time + abs(t.phil[3].T);
//   end when;
// algorithm
//   when initial() then
//     t.phil[4].state := 0;
//     t.phil[4].left.pickedUp := false;
//     t.phil[4].right.pickedUp := false;
//     (t.phil[4].T, t.phil[4].randomSeed) := Philosopher.Random.normalvariate(t.phil[4].mu, t.phil[4].sigma, {t.phil[4].startSeed[1], t.phil[4].startSeed[2], t.phil[4].startSeed[3]});
//     t.phil[4].timeOfNextChange := abs(t.phil[4].T);
//   elsewhen pre(t.phil[4].timeToGetHungry) then
//     t.phil[4].state := 1;
//   end when;
//   when pre(t.phil[4].canEat) then
//     t.phil[4].mutexPort.release := false;
//     t.phil[4].mutexPort.request := true;
//   end when;
//   when pre(t.phil[4].mutexPort.ok) then
//     if pre(t.phil[4].canEat) then
//       t.phil[4].left.pickedUp := true;
//       t.phil[4].right.pickedUp := true;
//       (t.phil[4].T, t.phil[4].randomSeed) := Philosopher.Random.normalvariate(t.phil[4].mu, t.phil[4].sigma, {pre(t.phil[4].randomSeed[1]), pre(t.phil[4].randomSeed[2]), pre(t.phil[4].randomSeed[3])});
//       t.phil[4].timeOfNextChange := time + abs(t.phil[4].T);
//       t.phil[4].state := 2;
//     end if;
//     t.phil[4].mutexPort.release := true;
//     t.phil[4].mutexPort.request := false;
//   end when;
//   when pre(t.phil[4].doneEating) then
//     t.phil[4].state := 0;
//     t.phil[4].left.pickedUp := false;
//     t.phil[4].right.pickedUp := false;
//     (t.phil[4].T, t.phil[4].randomSeed) := Philosopher.Random.normalvariate(t.phil[4].mu, t.phil[4].sigma, {pre(t.phil[4].randomSeed[1]), pre(t.phil[4].randomSeed[2]), pre(t.phil[4].randomSeed[3])});
//     t.phil[4].timeOfNextChange := time + abs(t.phil[4].T);
//   end when;
// algorithm
//   when initial() then
//     t.phil[5].state := 0;
//     t.phil[5].left.pickedUp := false;
//     t.phil[5].right.pickedUp := false;
//     (t.phil[5].T, t.phil[5].randomSeed) := Philosopher.Random.normalvariate(t.phil[5].mu, t.phil[5].sigma, {t.phil[5].startSeed[1], t.phil[5].startSeed[2], t.phil[5].startSeed[3]});
//     t.phil[5].timeOfNextChange := abs(t.phil[5].T);
//   elsewhen pre(t.phil[5].timeToGetHungry) then
//     t.phil[5].state := 1;
//   end when;
//   when pre(t.phil[5].canEat) then
//     t.phil[5].mutexPort.release := false;
//     t.phil[5].mutexPort.request := true;
//   end when;
//   when pre(t.phil[5].mutexPort.ok) then
//     if pre(t.phil[5].canEat) then
//       t.phil[5].left.pickedUp := true;
//       t.phil[5].right.pickedUp := true;
//       (t.phil[5].T, t.phil[5].randomSeed) := Philosopher.Random.normalvariate(t.phil[5].mu, t.phil[5].sigma, {pre(t.phil[5].randomSeed[1]), pre(t.phil[5].randomSeed[2]), pre(t.phil[5].randomSeed[3])});
//       t.phil[5].timeOfNextChange := time + abs(t.phil[5].T);
//       t.phil[5].state := 2;
//     end if;
//     t.phil[5].mutexPort.release := true;
//     t.phil[5].mutexPort.request := false;
//   end when;
//   when pre(t.phil[5].doneEating) then
//     t.phil[5].state := 0;
//     t.phil[5].left.pickedUp := false;
//     t.phil[5].right.pickedUp := false;
//     (t.phil[5].T, t.phil[5].randomSeed) := Philosopher.Random.normalvariate(t.phil[5].mu, t.phil[5].sigma, {pre(t.phil[5].randomSeed[1]), pre(t.phil[5].randomSeed[2]), pre(t.phil[5].randomSeed[3])});
//     t.phil[5].timeOfNextChange := time + abs(t.phil[5].T);
//   end when;
// algorithm
//   when t.mutex.request[1] then
//     if not t.mutex.occupied then
//       t.mutex.ok[1] := true;
//       t.mutex.waiting[1] := false;
//     else
//       t.mutex.ok[1] := false;
//       t.mutex.waiting[1] := true;
//     end if;
//     t.mutex.occupied := true;
//   end when;
//   when pre(t.mutex.waiting[1]) and not t.mutex.occupied then
//     t.mutex.occupied := true;
//     t.mutex.ok[1] := true;
//     t.mutex.waiting[1] := false;
//   end when;
//   when pre(t.mutex.release[1]) then
//     t.mutex.ok[1] := false;
//     t.mutex.occupied := false;
//   end when;
//   when t.mutex.request[2] then
//     if not t.mutex.occupied then
//       t.mutex.ok[2] := true;
//       t.mutex.waiting[2] := false;
//     else
//       t.mutex.ok[2] := false;
//       t.mutex.waiting[2] := true;
//     end if;
//     t.mutex.occupied := true;
//   end when;
//   when pre(t.mutex.waiting[2]) and not t.mutex.occupied then
//     t.mutex.occupied := true;
//     t.mutex.ok[2] := true;
//     t.mutex.waiting[2] := false;
//   end when;
//   when pre(t.mutex.release[2]) then
//     t.mutex.ok[2] := false;
//     t.mutex.occupied := false;
//   end when;
//   when t.mutex.request[3] then
//     if not t.mutex.occupied then
//       t.mutex.ok[3] := true;
//       t.mutex.waiting[3] := false;
//     else
//       t.mutex.ok[3] := false;
//       t.mutex.waiting[3] := true;
//     end if;
//     t.mutex.occupied := true;
//   end when;
//   when pre(t.mutex.waiting[3]) and not t.mutex.occupied then
//     t.mutex.occupied := true;
//     t.mutex.ok[3] := true;
//     t.mutex.waiting[3] := false;
//   end when;
//   when pre(t.mutex.release[3]) then
//     t.mutex.ok[3] := false;
//     t.mutex.occupied := false;
//   end when;
//   when t.mutex.request[4] then
//     if not t.mutex.occupied then
//       t.mutex.ok[4] := true;
//       t.mutex.waiting[4] := false;
//     else
//       t.mutex.ok[4] := false;
//       t.mutex.waiting[4] := true;
//     end if;
//     t.mutex.occupied := true;
//   end when;
//   when pre(t.mutex.waiting[4]) and not t.mutex.occupied then
//     t.mutex.occupied := true;
//     t.mutex.ok[4] := true;
//     t.mutex.waiting[4] := false;
//   end when;
//   when pre(t.mutex.release[4]) then
//     t.mutex.ok[4] := false;
//     t.mutex.occupied := false;
//   end when;
//   when t.mutex.request[5] then
//     if not t.mutex.occupied then
//       t.mutex.ok[5] := true;
//       t.mutex.waiting[5] := false;
//     else
//       t.mutex.ok[5] := false;
//       t.mutex.waiting[5] := true;
//     end if;
//     t.mutex.occupied := true;
//   end when;
//   when pre(t.mutex.waiting[5]) and not t.mutex.occupied then
//     t.mutex.occupied := true;
//     t.mutex.ok[5] := true;
//     t.mutex.waiting[5] := false;
//   end when;
//   when pre(t.mutex.release[5]) then
//     t.mutex.ok[5] := false;
//     t.mutex.occupied := false;
//   end when;
// end Philosopher_DiningTable;
// endResult

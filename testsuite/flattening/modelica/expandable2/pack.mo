within ;
package Pack
  package IFC
    expandable connector CN

    end CN;

    connector BoolIn = input Boolean;
    connector BoolOut = output Boolean;
    connector IntIn =  input Integer;
    connector IntOut =  output Integer;
    connector RealIn =  input Real;
    connector RealOut =  output Real;
  end IFC;

  package Blocks
    package Bool
      model BoolUser
        extends CN_User;
        Boolean Val;
      equation
        Val = time < 1/(2^N);
      end BoolUser;

      model BoolGen
        extends Bool.BoolUser;
      protected
        IFC.BoolOut x;
      equation
        x = Val;
        connect(x, bus.b);
      end BoolGen;

      model BoolCheck
        extends Bool.BoolUser;
      protected
        IFC.BoolIn x;
      equation
        connect(bus.b, x);
        assert(x == Val, "error");
      end BoolCheck;

      model BoolGenA
        extends Bool.BoolUser;
      protected
        IFC.BoolOut x;
      equation
        x = Val;
        connect(x, bus.ba[N]);
      end BoolGenA;

      model BoolCheckA
        extends Bool.BoolUser;
      protected
        IFC.BoolIn x;
      equation
        connect(bus.ba[N], x);
        assert(x == Val, "error");
      end BoolCheckA;

      model BoolGenPA_5
        extends Bool.BoolUser;
      protected
        IFC.BoolOut x1[5];
      equation
        x1 = {(rem(i, 2) == 0 and Val) for i in 1:5};
        connect(x1, bus.ba[1:5]);
      end BoolGenPA_5;

      model BoolCheckPA_5
        extends Bool.BoolUser;
      protected
        IFC.BoolIn x1[5];
      equation
        connect(bus.ba[1:5], x1);

        for i in 1:5 loop
          assert(x1[i] == (rem(i, 2) == 0 and Val), "error");
        end for;
      end BoolCheckPA_5;

      model BoolGenPA_N
        extends Bool.BoolUser;
        constant Boolean SliceMode = false;
      protected
        IFC.BoolOut x1[N];
      equation
        x1 = {(rem(i, 2) == 0 and Val) for i in 1:N};
        connect(x1, bus.ba[1:N]);
      end BoolGenPA_N;

      model BoolCheckPA_N
        extends Bool.BoolUser;
      protected
        IFC.BoolIn x1[N];
      equation
        connect(bus.ba[1:N], x1);

        for i in 1:N loop
          assert(x1[i] == (rem(i, 2) == 0 and Val), "error");
        end for;
      end BoolCheckPA_N;
    end Bool;

    package Int
      model IntUser
        extends CN_User;
        Integer Val;
      equation
        Val = if time < 0.5 then N else N + 1;
      end IntUser;

      model IntGen
        extends IntUser;
      protected
        IFC.IntOut x;
      equation
        x = Val;
        connect(x, bus.i);
      end IntGen;

      model IntCheck
        extends IntUser;
      protected
        IFC.IntIn x;
      equation
        connect(bus.i, x);
        assert(x == Val, "error");
      end IntCheck;

      model IntGenA
        extends IntUser;
      protected
        IFC.IntOut x;
      equation
        x = Val;
        connect(x, bus.ia[N]);
      end IntGenA;

      model IntCheckA
        extends IntUser;
      protected
        IFC.IntIn x;
      equation
        connect(bus.ia[N], x);
        assert(x == Val, "error");
      end IntCheckA;

      model IntGenPA_5
        extends IntUser;
      protected
        IFC.IntOut x1[5];
      equation
        x1 = {(Val + i) for i in 1:5};
        connect(x1, bus.ia[1:5]);
      end IntGenPA_5;

      model IntCheckPA_5
        extends IntUser;
      protected
        IFC.IntIn x1[5];
      equation
        connect(bus.ia[1:5], x1);
        for i in 1:5 loop
          assert(x1[i] == Val + i, "error");
        end for;
      end IntCheckPA_5;

      model IntGenPA_N
        extends IntUser;
        constant Boolean SliceMode = false;
      protected
        IFC.IntOut x1[N];
      equation
        x1 = {(2 * Val + i) for i in 1:N};
        connect(x1, bus.ia[1:N]);
      end IntGenPA_N;

      model IntCheckPA_N
        extends IntUser;
      protected
        IFC.IntIn x1[N];
      equation
        connect(bus.ia[1:N], x1);
        for i in 1:N loop
          assert(x1[i] == 2 * Val + i, "error");
        end for;
      end IntCheckPA_N;
    end Int;

    package Double
      model RealUser
        extends CN_User;
        Real Val;
      equation
        Val = if time < 0.5 then N else N + 1;
      end RealUser;

      model RealGen
        extends RealUser;
      protected
        IFC.RealOut x;
      equation
        x = Val;
        connect(x, bus.r);
      end RealGen;

      model RealCheck
        extends RealUser;
      protected
        IFC.RealIn x;
      equation
        connect(bus.r, x);
        assert(abs(x - Val) < 1e-7, "error");
      end RealCheck;

      model RealGenA
        extends RealUser;
      protected
        IFC.RealOut x;
      equation
        x = Val;
        connect(x, bus.ra[N]);
      end RealGenA;

      model RealCheckA
        extends RealUser;
      protected
        IFC.RealIn x;
      equation
        connect(bus.ra[N], x);
        assert(abs(x - Val) < 1e-7, "error");
      end RealCheckA;

      model RealGenPA_5
        extends RealUser;
      protected
        IFC.RealOut x1[5];
      equation
        x1 = {(Val + i) for i in 1:5};
        connect(x1, bus.ra[1:5]);
      end RealGenPA_5;

      model RealCheckPA_5
        extends RealUser;
      protected
        IFC.RealIn x1[5];
      equation
        connect(bus.ra[1:5], x1);
        for i in 1:5 loop
          assert(abs(x1[i] - (Val + i)) < 1e-7, "error");
        end for;
      end RealCheckPA_5;

      model RealGenPA_N
        extends RealUser;
        constant Boolean SliceMode = false;
      protected
        IFC.RealOut x1[N];
      equation
        x1 = {(2 * Val + i) for i in 1:N};
        connect(x1, bus.ra[1:N]);
      end RealGenPA_N;

      model RealCheckPA_N
        extends RealUser;
      protected
        IFC.RealIn x1[N];
      equation
        connect(bus.ra[1:N], x1);
        for i in 1:N loop
          assert(abs(x1[i] - (2 * Val + i)) < 1e-7, "error");
        end for;
      end RealCheckPA_N;
    end Double;

    package Eq
      connector Pin
        Real v;
        flow Real i;
      end Pin;

      expandable connector PinCN
        Pin pa[5];
      end PinCN;

      model PinUser
        constant Integer N = 1;
      protected
        outer PinCN bus;
        Real Val;
      equation
        Val = if time < 0.5 then N else N + 1;
      end PinUser;

      model PinV
        extends PinUser;
        Pin x;
      equation
        x.v = Val;
        assert(abs(x.i + Val) < 1e-7, "error");
      end PinV;

      model PinI
        extends PinUser;
        Pin x;
      equation
        x.i = Val;
        assert(abs(x.v - Val) < 1e-7, "error");
      end PinI;

      model PinV_ToBus
        extends PinUser;
      protected
        PinV v_gen(N=N);
      equation
        connect(v_gen.x, bus.p);
      end PinV_ToBus;

      model PinI_ToBus
        extends PinUser;
      protected
        PinI i_gen(N=N);
      equation
        connect(i_gen.x, bus.p);
      end PinI_ToBus;

      model PinV_ToBusA
        extends PinUser;
      protected
        PinV v_gen(N=N);
      equation
        connect(v_gen.x, bus.pa[N]);
      end PinV_ToBusA;

      model PinI_ToBusA
        extends PinUser;
      protected
        PinI i_gen(N=N);
      equation
        connect(i_gen.x, bus.pa[N]);
      end PinI_ToBusA;

    end Eq;

    model CN_User
      constant Integer N = 1;
      IFC.CN bus;
    end CN_User;
  end Blocks;

  package Tests
    package Bool
      model Test1 "[BOOL] Input to output"
        Blocks.Bool.BoolGen bg1;
        Blocks.Bool.BoolCheck bc1;
        Blocks.Bool.BoolCheck bc2;
      equation
        connect(bg1.bus, bc1.bus);
        connect(bg1.bus, bc2.bus);
      end Test1;

      model Test2 "[BOOL_A] Input to output dim1"
        Blocks.Bool.BoolGenA bg1(N=1);
        Blocks.Bool.BoolCheckA bc1(N=1);
        Blocks.Bool.BoolCheckA bc2(N=1);
      equation
        connect(bg1.bus, bc1.bus);
        connect(bg1.bus, bc2.bus);
      end Test2;

      model Test3 "[BOOL_A] Input to output dim3"
        Blocks.Bool.BoolGenA bg1(N=1);
        Blocks.Bool.BoolGenA bg2(N=2);
        Blocks.Bool.BoolGenA bg3(N=3);
        Blocks.Bool.BoolCheckA bc1(N=1);
        Blocks.Bool.BoolCheckA bc2(N=2);
        Blocks.Bool.BoolCheckA bc3(N=3);
      protected
        Pack.IFC.CN cn;
      equation
        connect(bg1.bus, cn);
        connect(bg2.bus, cn);
        connect(bg3.bus, cn);
        connect(bc1.bus, cn);
        connect(bc2.bus, cn);
        connect(bc3.bus, cn);
      end Test3;

      model Test4 "[BOOL] No output"
        Blocks.Bool.BoolGen bg;
        //
        Blocks.Bool.BoolGenA bg1(N=1);
        Blocks.Bool.BoolGenA bg3(N=3);
        Blocks.Bool.BoolGenA bg5(N=5);
      protected
        Pack.IFC.CN cn;
      equation
        connect(bg1.bus, cn);
        connect(bg3.bus, cn);
        connect(bg5.bus, cn);
      end Test4;

      model Test5 "[BOOL] Array[5] to Array[5]"
        Blocks.Bool.BoolGenPA_5 bg1;
        Blocks.Bool.BoolCheckPA_5 bc1;
        Blocks.Bool.BoolCheckPA_5 bc2;
      equation
        connect(bg1.bus, bc1.bus);
        connect(bg1.bus, bc2.bus);
      end Test5;

      model Test6 "[BOOL] Array[N] to Array[N]"
        Blocks.Bool.BoolGenPA_N bg1(N=3);
        Blocks.Bool.BoolCheckPA_N bc1(N=3);
        Blocks.Bool.BoolCheckPA_N bc2(N=3);
      equation
        connect(bg1.bus, bc1.bus);
        connect(bg1.bus, bc2.bus);
      end Test6;

      model Test7 "[BOOL] Array[1:4 + 5] to Array[?]"
        Blocks.Bool.BoolGenPA_N bg1(N=4);
        Blocks.Bool.BoolGenA bg2(N=7);
        Blocks.Bool.BoolCheckPA_N bc1(N=4);
        Blocks.Bool.BoolCheckA bc2(N=7);
      protected
        Pack.IFC.CN cn;
      equation
        connect(bg1.bus, cn);
        connect(bg2.bus, cn);
        connect(cn, bc1.bus);
        connect(cn, bc2.bus);
      end Test7;
    end Bool;

    package Int
      model Test1 "[INT] Input to output"
        Blocks.Int.IntGen ig1;
        Blocks.Int.IntCheck ic1;
        Blocks.Int.IntCheck ic2;
      equation
        connect(ig1.bus, ic1.bus);
        connect(ig1.bus, ic2.bus);
      end Test1;

      model Test2 "[INT_A] Input to output dim1"
        Blocks.Int.IntGenA ig1(N=1);
        Blocks.Int.IntCheckA ic1(N=1);
        Blocks.Int.IntCheckA ic2(N=1);
      equation
        connect(ig1.bus, ic1.bus);
        connect(ig1.bus, ic2.bus);
      end Test2;

      model Test3 "[INT_A] Input to output dim3"
        Blocks.Int.IntGenA ig1(N=1);
        Blocks.Int.IntGenA ig2(N=2);
        Blocks.Int.IntGenA ig3(N=3);
        Blocks.Int.IntCheckA ic1(N=1);
        Blocks.Int.IntCheckA ic2(N=2);
        Blocks.Int.IntCheckA ic3(N=3);
      equation
        connect(ig1.bus, ig2.bus);
        connect(ig2.bus, ig3.bus);
        connect(ig3.bus, ic1.bus);
        connect(ic1.bus, ic2.bus);
        connect(ic2.bus, ic3.bus);
      end Test3;

      model Test4 "[INT] No output"
        Blocks.Int.IntGen ig1;
        Blocks.Int.IntGenA ig2(N=1);
        Blocks.Int.IntGenA ig3(N=2);
      protected
        Pack.IFC.CN cn;
      equation
        connect(ig1.bus, cn);
        connect(ig2.bus, cn);
        connect(ig3.bus, cn);
      end Test4;

      model Test5 "[INT] Array[5] to Array[5]"
        Blocks.Int.IntGenPA_5 ig1(N=3);
        Blocks.Int.IntCheckPA_5 ic1(N=3);
        Blocks.Int.IntCheckPA_5 ic2(N=3);
      equation
        connect(ig1.bus, ic1.bus);
        connect(ig1.bus, ic2.bus);
      end Test5;

      model Test6 "[INT] Array[N] to Array[N]"
        Blocks.Int.IntGenPA_N ig1(N=3);
        Blocks.Int.IntCheckPA_N ic1(N=3);
        Blocks.Int.IntCheckPA_N ic2(N=3);
      equation
        connect(ig1.bus, ic1.bus);
        connect(ig1.bus, ic2.bus);
      end Test6;

      model Test7 "[INT] Array[1:4 + 5] to Array[?]"
        Blocks.Int.IntGenPA_N ig1(N=4);
        Blocks.Int.IntGenA ig2(N=7);
        Blocks.Int.IntCheckPA_N ic1(N=4);
        Blocks.Int.IntCheckA ic2(N=7);
      protected
        Pack.IFC.CN cn;
      equation
        connect(ig1.bus, cn);
        connect(ig2.bus, cn);
        connect(cn, ic1.bus);
        connect(cn, ic2.bus);
      end Test7;
    end Int;

    package Double
      model Test1 "[REAL] Input to output"
        Blocks.Double.RealGen rg1;
        Blocks.Double.RealCheck rc1;
        Blocks.Double.RealCheck rc2;
      equation
        connect(rg1.bus, rc1.bus);
        connect(rg1.bus, rc2.bus);
      end Test1;

      model Test2 "[REAL_A] Input to output dim1"
        Blocks.Double.RealGenA rg1(N=1);
        Blocks.Double.RealCheckA rc1(N=1);
        Blocks.Double.RealCheckA rc2(N=1);
      equation
        connect(rg1.bus, rc1.bus);
        connect(rg1.bus, rc2.bus);
      end Test2;

      model Test3 "[REAL_A] Input to output dim3"
        Blocks.Double.RealGenA rg1(N=1);
        Blocks.Double.RealGenA rg2(N=2);
        Blocks.Double.RealGenA rg3(N=3);
        Blocks.Double.RealCheckA rc1(N=1);
        Blocks.Double.RealCheckA rc2(N=2);
        Blocks.Double.RealCheckA rc3(N=3);
      equation
        connect(rg1.bus, rg2.bus);
        connect(rg2.bus, rg3.bus);
        connect(rg3.bus, rc1.bus);
        connect(rc1.bus, rc2.bus);
        connect(rc2.bus, rc3.bus);
      end Test3;

      model Test4 "[REAL] No output"
        Blocks.Double.RealGen rg1;
        Blocks.Double.RealGenA rg2(N=1);
        Blocks.Double.RealGenA rg3(N=2);
      protected
        Pack.IFC.CN cn;
      equation
        connect(rg1.bus, cn);
        connect(rg2.bus, cn);
        connect(rg3.bus, cn);
      end Test4;

      model Test5 "[REAL] Array[5] to Array[5]"
        Blocks.Double.RealGenPA_5 rg1(N=3);
        Blocks.Double.RealCheckPA_5 rc1(N=3);
        Blocks.Double.RealCheckPA_5 rc2(N=3);
      equation
        connect(rg1.bus, rc1.bus);
        connect(rg1.bus, rc2.bus);
      end Test5;

      model Test6 "[REAL] Array[N] to Array[N]"
        Blocks.Double.RealGenPA_N rg1(N=3);
        Blocks.Double.RealCheckPA_N rc1(N=3);
        Blocks.Double.RealCheckPA_N rc2(N=3);
      equation
        connect(rg1.bus, rc1.bus);
        connect(rg1.bus, rc2.bus);
      end Test6;

      model Test7 "[REAL] Array[1:4 + 7] to Array[?]"
        Blocks.Double.RealGenPA_N rg1(N=4);
        Blocks.Double.RealGenA rg2(N=7);
        Blocks.Double.RealCheckPA_N rc1(N=4);
        Blocks.Double.RealCheckA rc2(N=7);
      protected
        Pack.IFC.CN cn;
      equation
        connect(rg1.bus, cn);
        connect(rg2.bus, cn);
        connect(cn, rc1.bus);
        connect(cn, rc2.bus);
      end Test7;
    end Double;

    package Eq
      model Test1 "[PIN] Input to output"
        Blocks.Eq.PinV_ToBus pg1;
        Blocks.Eq.PinI_ToBus pc1;
      protected
        inner Pack.Blocks.Eq.PinCN bus;
      end Test1;

      model Test2 "[PIN] Input to output dim1"
        Blocks.Eq.PinV_ToBusA pg1(N=1);
        Blocks.Eq.PinI_ToBusA pc1(N=1);
      protected
        inner Pack.Blocks.Eq.PinCN bus;
      end Test2;

      model Test3 "[PIN] Input to output dim3"
        Blocks.Eq.PinV_ToBusA pg1(N=1);
        Blocks.Eq.PinV_ToBusA pg2(N=2);
        Blocks.Eq.PinV_ToBusA pg3(N=3);
        Blocks.Eq.PinI_ToBusA pc1(N=1);
        Blocks.Eq.PinI_ToBusA pc2(N=2);
        Blocks.Eq.PinI_ToBusA pc3(N=3);
      protected
        inner Pack.Blocks.Eq.PinCN bus;
      end Test3;

      model Test4 "[PIN] Input to output sparse"
        Blocks.Eq.PinV_ToBusA pg1(N=1);
        Blocks.Eq.PinV_ToBusA pg2(N=3);
        Blocks.Eq.PinV_ToBusA pg3(N=5);
        Blocks.Eq.PinI_ToBusA pc1(N=1);
        Blocks.Eq.PinI_ToBusA pc2(N=3);
        Blocks.Eq.PinI_ToBusA pc3(N=5);
      protected
        inner Pack.Blocks.Eq.PinCN bus;
      end Test4;
    end Eq;

    model TestAll
      Pack.Tests.Bool.Test1 b_test1;
      Pack.Tests.Bool.Test2 b_test2;
      Pack.Tests.Bool.Test3 b_test3;
      Pack.Tests.Bool.Test4 b_test4;
      Pack.Tests.Bool.Test5 b_test5;
      Pack.Tests.Bool.Test6 b_test6;
      Pack.Tests.Bool.Test7 b_test7;
      //
      Pack.Tests.Int.Test1 i_test1;
      Pack.Tests.Int.Test2 i_test2;
      Pack.Tests.Int.Test3 i_test3;
      Pack.Tests.Int.Test4 i_test4;
      Pack.Tests.Int.Test5 i_test5;
      Pack.Tests.Int.Test6 i_test6;
      Pack.Tests.Int.Test7 i_test7;
      //
      Pack.Tests.Double.Test1 d_test1;
      Pack.Tests.Double.Test2 d_test2;
      Pack.Tests.Double.Test3 d_test3;
      Pack.Tests.Double.Test4 d_test4;
      Pack.Tests.Double.Test5 d_test5;
      Pack.Tests.Double.Test6 d_test6;
      Pack.Tests.Double.Test7 d_test7;
      //
      Pack.Tests.Eq.Test1 eq_test1;
      Pack.Tests.Eq.Test2 eq_test2;
      Pack.Tests.Eq.Test3 eq_test3;
      Pack.Tests.Eq.Test4 eq_test4;
    end TestAll;
  end Tests;
end Pack;

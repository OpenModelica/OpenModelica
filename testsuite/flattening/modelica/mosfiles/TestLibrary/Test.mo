package Test
  function ext1
    output Real r;
    external "C" annotation(Library="ext1");
  end ext1;

  function ext2
    output Real r;
    external "C" annotation(Library="ext2",LibraryDirectory="modelica://Test/Resources/SpecialLib/");
  end ext2;

  function ext3
    output Real r;
    external "C" annotation(Include="#include \"ext3.c\"");
  end ext3;

  function ext4
    output Real r;
    external "C" annotation(Include="#include \"ext4.c\"",IncludeDirectory="modelica://Test/Resources/SpecialSources/");
  end ext4;
end Test;

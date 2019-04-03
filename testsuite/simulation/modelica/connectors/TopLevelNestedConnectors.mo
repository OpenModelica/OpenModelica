model TopLevelNestedConnectors
  connector Conn1
    input Integer foo;

    connector Conn2
      input Integer foo;
    end Conn2;
    Conn2 conn2;
  end Conn1;

  Conn1 conn1;
end TopLevelNestedConnectors;

# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}

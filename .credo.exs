# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
          {Credo.Check.Refactor.FunctionArity, [max_arity: 10]},
        ],
        disabled: [
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}

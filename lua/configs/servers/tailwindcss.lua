return {
  settings = {
    tailwindCSS = {
      -- class completion/hover inside cn("...") and cva("...") calls
      classFunctions = { "cn", "cva" },
      -- oxlint's better-tailwindcss/no-conflicting-classes already reports
      -- these; showing both would duplicate every warning
      lint = { cssConflict = "ignore" },
    },
  },
}

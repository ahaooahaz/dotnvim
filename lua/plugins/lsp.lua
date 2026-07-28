return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        buf_ls = {},
        gopls = {
          settings = {
            gopls = {
              usePlaceholders = false,
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=0",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = false,
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "buf" } },
  },
}

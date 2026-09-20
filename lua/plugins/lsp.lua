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
          cmd_env = { MALLOC_ARENA_MAX = "2" },
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

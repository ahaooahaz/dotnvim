return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, {
        ["*"] = {
          capabilities = {
            textDocument = {
              completion = {
                completionItem = { snippetSupport = false },
              },
            },
          },
        },
        buf_ls = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Disable",
                keywordSnippet = "Disable",
              },
            },
          },
        },
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
      })

      -- clangd uses this CLI flag, not init_options.usePlaceholders, for function arguments.
      -- Preserve LazyVim's other flags and replace its enabled placeholder option.
      local clangd = opts.servers.clangd
      clangd.cmd = vim.tbl_filter(function(arg)
        return not arg:match("^%-%-function%-arg%-placeholders")
      end, clangd.cmd or { "clangd" })
      table.insert(clangd.cmd, "--function-arg-placeholders=0")

      return opts
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "buf" } },
  },
}

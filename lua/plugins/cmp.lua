return {
  {
    "saghen/blink.cmp",
    opts = {
      cmdline = {
        enabled = true,
        keymap = {
          preset = "inherit",
        },
      },
      sources = {
        default = { "lsp", "path", "buffer", "snippets", "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            async = true,
            timeout_ms = 10000,
            score_offset = 100,
          },
        },
      },
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
            semantic_token_resolution = {
              enabled = false,
            },
          },
        },
      },
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = false,
        -- ["<A-y>"] = require("minuet").make_blink_map(),
      },
    },
  },
}

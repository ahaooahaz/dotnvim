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
        default = { "lsp", "path", "buffer", "snippets", "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 10000,
            score_offset = 50,
          },
        },
      },
      completion = { trigger = { prefetch_on_insert = false } },
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = false,
        ["<A-y>"] = require("minuet").make_blink_map(),
      },
    },
  },
}

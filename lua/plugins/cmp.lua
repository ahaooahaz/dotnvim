return {
  {
    "saghen/blink.cmp",
    -- Lazy.nvim 的 opts 合并策略对于 list-like table 并不是简单替换，它会把两个列表合并
    -- 需要使用 opts 函数，直接修改最终的 opts
    opts = function(_, opts)
      opts.cmdline = {
        enabled = true,
        keymap = {
          preset = "inherit",
        },
        completion = {
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          menu = {
            auto_show = true,
          },
          ghost_text = {
            enabled = true,
          },
        },
      }

      opts.sources.default = {
        "lsp",
        "path",
        "snippets",
        "copilot",
      }

      opts.sources.providers.lsp = {
        fallbacks = {},
      }

      opts.sources.providers.copilot = {
        name = "copilot",
        module = "blink-copilot",
        async = true,
        timeout_ms = 10000,
        score_offset = 100,
      }

      opts.sources.providers.buffer = {
        score_offset = -10,
      }

      opts.completion = {
        trigger = {
          show_on_keyword = true,
          show_on_trigger_character = true,
        },

        accept = {
          auto_brackets = {
            enabled = true,
            semantic_token_resolution = {
              enabled = false,
            },
          },
        },

        list = {
          max_items = 8,
        },

        documentation = {
          auto_show = false,
        },
      }

      opts.keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = false,
        -- ["<A-y>"] = require("minuet").make_blink_map(),
      }

      return opts
    end,
  },
}

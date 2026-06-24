return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
 ▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄     ▄            
█      █  █ █  █       █ █ ▄ █ █          Z
█  ▄   █  █▄█  █   ▄   █ ██ ██ █      Z    
█ █▄█  █       █  █ █  █       █   z       
█      █   ▄   █  █▄█  █       █ z         
█  ▄   █  █ █  █       █   ▄   █           
█▄█ █▄▄█▄▄█ █▄▄█▄▄▄▄▄▄▄█▄▄█ █▄▄█           
   ]],
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    lazy = false,
    opts = {
      options = {
        separator_style = { "", "" },
        indicator = {
          icon = "",
          style = "none",
        },
      },
      highlights = {
        background = { bg = "none" },
        fill = { bg = "none" },
        buffer_selected = { bg = "none", fg = "#ff0000" },
        buffer_visible = { bg = "none" },
        close_button = { bg = "none" },
        close_button_selected = { bg = "none" },
        close_button_visible = { bg = "none" },
        duplicate = { bg = "none" },
        duplicate_selected = { bg = "none" },
        duplicate_visible = { bg = "none" },
        error = { bg = "none" },
        error_selected = { bg = "none" },
        error_visible = { bg = "none" },
        hint = { bg = "none" },
        hint_selected = { bg = "none" },
        hint_visible = { bg = "none" },
        indicator_selected = { bg = "none" },
        indicator_visible = { bg = "none" },
        info = { bg = "none" },
        info_selected = { bg = "none" },
        info_visible = { bg = "none" },
        modified = { bg = "none" },
        modified_selected = { bg = "none" },
        modified_visible = { bg = "none" },
        numbers = { bg = "none" },
        numbers_selected = { bg = "none" },
        numbers_visible = { bg = "none" },
        offset_separator = { bg = "none" },
        pick = { bg = "none" },
        pick_selected = { bg = "none" },
        pick_visible = { bg = "none" },
        separator = { bg = "none" },
        separator_selected = { bg = "none" },
        separator_visible = { bg = "none" },
        tab = { bg = "none" },
        tab_close = { bg = "none" },
        tab_selected = { bg = "none" },
        tab_separator = { bg = "none" },
        tab_separator_selected = { bg = "none" },
        trunc_marker = { bg = "none" },
        warning = { bg = "none" },
        warning_selected = { bg = "none" },
        warning_visible = { bg = "none" },
      },
    },
    config = function(_, opts)
      vim.o.termguicolors = true
      require("bufferline").setup(opts)
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        require("minuet.lualine"),
        display_name = "both",
        display_on_idle = true,
      })
    end,
  },
  {
    "lukas-reineke/virt-column.nvim",
    opts = {},
    config = function()
      require("virt-column").setup({
        char = "│",
        virtcolumn = "120",
        highlight = "Comment",
      })

      local ft_columns = {
        cpp = "120",
        c = "120",
        python = "80",
        markdown = "100",
        lua = "100",
        go = "120",
      }
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local col = ft_columns[args.match]
          if col then
            require("virt-column").update({ virtcolumn = col })
          end
        end,
      })
    end,
  },
}

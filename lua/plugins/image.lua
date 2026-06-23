return {
  {
    "3rd/image.nvim",
    lazy = false,
    opts = {
      processor = "magick_cli",
      backend = "kitty",
      tmp_dir = vim.fn.tempname(),
      max_width = 100,
      max_height = 30,
    },
  },
}

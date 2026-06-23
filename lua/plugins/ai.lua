return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "InsertEnter",
    config = function()
      require("minuet").setup({
        provider = "openai_compatible",
        notify = "warn",
        request_timeout = 5,
        provider_options = {
          openai_compatible = {
            api_key = "NVIM_MINUET_AI_OPENAI_API_KEY",
            end_point = os.getenv("NVIM_MINUET_AI_OPENAI_BASE_URL"),
            model = "gpt-4o-mini",
            name = "stepcode",
            stream = true,
          },
        },
      })
    end,
  },
}

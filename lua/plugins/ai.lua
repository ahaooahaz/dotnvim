return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal_cmd = os.getenv("NVIM_CLAUDE_CODE_SETUP_CMD") or "claude",
    },
  },
}

-- fzf-lua: 文件查询支持 `foo.cpp:902` / `foo.cpp:902:15`，回车直接落到对应行
-- 依赖 fzf >= 0.59（transform 里的 search() action）
local function line_query(q)
  if not q then
    return
  end
  local lnum = q:match(":(%d+):?%d*$")
  local new_q, subs = q:gsub(":%d*:?%d*$", "")
  return lnum, (subs > 0 and new_q or nil)
end

return {
  {
    "ibhagwan/fzf-lua",
    opts = {
      files = { line_query = line_query },
      oldfiles = { line_query = line_query },
      git = { files = { line_query = line_query } },
    },
  },
}

---@mod git-firvish git-firvish
---@brief [[
---vim-fugitive, but using firvish.nvim
---@brief ]]

local jobctrl = require "firvish.lib.jobs"

local M = {}

---@tag :Git
---@brief [[
---:Git[!] {args}
---    Runs an arbitrary git command.
---    If bang ! is given, the |git-firvish-output| buffer is opened.
---@brief ]]
local function setup_git_command()
  vim.api.nvim_create_user_command("Git", function(args)
    M.run {
      args = args.fargs,
      filetype = M.filetype_for(args.fargs),
      bopen = {
        headers = M.config.headers,
        open = args.bang,
        how = M.config.bang_open,
      },
    }
  end, {
    bang = true,
    desc = "[git-firvish] Run a git command",
    nargs = "*",
  })
end

---@mod git-firvish-config Configuration
---@brief [[
---See below for configuration options. Configure git-firvish like so:
---
--->
---require("git-firvish").setup {
---  ...
---}
---<
---
---@brief ]]
M.config = {
  ---@tag git-firvish.bang_open
  ---@brief [[
  ---bang_open: string (default: vsplit)
  ---    If and how to open the git-output buffer when the |:Git| command exits.
  ---    Options are |:edit|, |:vsplit|, |:pedit| and the like.
  ---@brief ]]
  bang_open = "vsplit",
  ---@tag git-firvish.show_headers
  ---@brief [[
  ---headers: boolean (default: false)
  ---    Whether to include canonical firvish headers in the |git-firvish-output| buffer.
  ---@brief ]]
  headers = false,
  ---@tag git-firvish.keep_jobs
  ---@brief [[
  ---keep_jobs: boolean (default: true)
  ---    Whether to keep finished jobs around (in the |firvish-jobs| list).
  ---@brief ]]
  keep_jobs = true,
  ---@tag git-firvish.open_on_error
  ---@brief [[
  ---open_on_error: string
  ---    If and how to open the |git-firvish-output| buffer when the underlying command fails.
  ---    Options are |:edit|, |:vsplit|, |:pedit| and the like.
  ---@brief ]]
  open_on_error = "vsplit",
}

---@package
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_git_command()
end

---@package
function M.run(opts)
  opts = vim.tbl_deep_extend("force", M.config, opts)

  jobctrl.start_job {
    command = opts.prog or "git",
    args = opts.args,
    cwd = opts.cwd or vim.fn.getcwd(),
    filetype = opts.filetype or "text",
    keep = opts.keep_jobs,
    title = opts.title or "git-firvish",
    bopen = opts.bopen or false,
    on_exit = function(job, buffer)
      if job.exit_code == 0 then
        if opts.bopen == false or type(opts.bopen) == "table" and opts.bopen.open == false then
          vim.notify("[git-firvish] done.", vim.log.levels.INFO)
        end
      else
        if opts.open_on_error then
          if type(opts.open_on_error) == "string" then
            buffer:open(opts.open_on_error)
          else
            buffer:open "vsplit"
          end
        end
      end
    end,
  }
end

---@package
function M.filetype_for(args)
  return "text"
end

return M

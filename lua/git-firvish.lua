---@mod git-firvish git-firvish
---@brief [[
---vim-fugitive, but using firvish.nvim
---@brief ]]

local jobctrl = require "firvish.lib.jobs"

local M = {}

local CompletionContext = {}
CompletionContext.__index = CompletionContext

function CompletionContext:new(opts)
  return setmetatable(opts, CompletionContext)
end

local function parse_cmdline_raw(cmdline, pos)
  cmdline = string.sub(cmdline, 0, pos)
  local parts = {}
  for p in string.gmatch(cmdline, "%S+") do
    table.insert(parts, p)
  end
  return parts
end

local function parse_cmdline(arglead, cmdline, pos)
  local opts = {
    arglead = arglead,
    cmdline = parse_cmdline_raw(cmdline, pos),
    pos = pos,
  }

  local last = opts.cmdline[#opts.cmdline]

  if arglead == "" then
    -- This is the case after <space>.
    -- Thus we expect the most recent argument to be either a command, option or argument.
    if last == ":Git" or last == ":Git!" then
      opts.command = "git"
      opts.match = {
        partial = false,
      }
    end
  else
    -- FIXME: This is not correct.
    opts.match = {
      partial = true,
      value = arglead,
    }
    if vim.startswith(arglead, "-") then
      -- Then we are completing an option.
    end
  end

  return CompletionContext:new(opts)
end

local commands = {
  ["add"] = false,
  ["bisect"] = false,
  ["branch"] = false,
  ["clone"] = false,
  ["commit"] = false,
  ["diff"] = false,
  ["fetch"] = false,
  ["grep"] = false,
  ["init"] = false,
  ["log"] = false,
  ["merge"] = false,
  ["mv"] = false,
  ["pull"] = false,
  ["push"] = false,
  ["rebase"] = false,
  ["reset"] = false,
  ["restore"] = false,
  ["rm"] = false,
  ["show"] = false,
  ["status"] = false,
  ["switch"] = false,
  ["tag"] = false,
}

local function complete_command(context)
  -- A "partial" match implies we are still completing the command itself
  -- and so we should return completion candidates for commands themselves,
  -- as opposed to the options and arguments those commands accept.
  if context.match.partial then
    local matches = {}
    for command, _ in pairs(commands) do
      if string.match(context.match.value, command) then
        table.insert(matches, command)
      end
    end
    return matches
  else
    -- We should return completion candidates for the options and arguments
    -- that the given command accepts.
  end
  return {}
end

local function complete_option(context)
  return {}
end

local function complete_argument(context)
  return {}
end

function M.complete(arglead, cmdline, pos)
  local context = parse_cmdline(arglead, cmdline, pos)
  if context.command then
    return complete_command(context)
  elseif context.option then
    return complete_option(context)
  else
    return complete_argument(context)
  end
end

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
        open = args.bang,
      },
    }
  end, {
    bang = true,
    complete = M.complete,
    desc = "[git-firvish] Run a git command",
    nargs = "*",
  })
end

---@mod git-firvish-config Configuration
---@brief [[
---See below for configuration options.
---Configure git-firvish globally like so:
---
--->
---require("git-firvish").setup {
---  ...
---}
---<
---
---Options passed to |git-firvish.run| take precedence over those configured
---globally.
---
---@brief ]]
M.config = {
  ---@tag git-firvish.config.bopen
  ---@brief [[
  ---bopen: boolean|table
  ---    If and how to open the |git-firvish-output| buffer when the |:Git| command exits.
  ---    If a boolean, can only be false to NOT open the buffer when the command exits.
  ---    Else, should be a table with valid keys:
  ---        headers: boolean (default: false) whether to include or suppress canonical firvish
  ---                                          headers
  ---        how: string (default: vsplit) how to open the buffer; |:edit|, |:vsplit|, |:pedit| and
  ---                                      the like
  ---@brief ]]
  bopen = {
    headers = false,
    how = "vsplit",
  },
  ---@tag git-firvish.config.filetype
  ---@brief [[
  ---filetype: string (default: git-firvish)
  ---@brief ]]
  filetype = "git-firvish",
  ---@tag git-firvish.config.keep_jobs
  ---@brief [[
  ---keep_jobs: boolean (default: true)
  ---    Whether to keep finished jobs around (in the |firvish-jobs| list).
  ---@brief ]]
  keep_jobs = true,
  ---@tag git-firvish.config.open_on_error
  ---@brief [[
  ---open_on_error: string|boolean (default: false)
  ---    If and how to open the |git-firvish-output| buffer when the underlying command fails.
  ---    Options are |:edit|, |:vsplit|, |:pedit| and the like.
  ---    Pass `false` to not open the buffer on error, else MUST be a string.
  ---@brief ]]
  open_on_error = false,
  ---@tag git-firvish.config.prog
  ---@brief [[
  ---prog: string (default: git)
  ---    The git command to run.
  ---@brief ]]
  prog = "git",
  ---@tag git-firvish.config.title
  ---@brief [[
  ---title: string (default: git-firvish)
  ---    The string used for things like naming error lists.
  ---@brief ]]
  title = "git-firvish",
}

---Setup git-firvish.
---@see git-firvish-config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_git_command()
end

local function should_notify(opts)
  return opts.bopen == false or type(opts.bopen) == "table" and opts.bopen.open == false
end

---Run a git command using |firvish-jobs-api|.
---@param opts table
function M.run(opts)
  opts = vim.tbl_deep_extend("force", M.config, opts or {})

  jobctrl.start_job {
    command = opts.prog,
    args = opts.args,
    cwd = opts.cwd or vim.fn.getcwd(),
    filetype = opts.filetype,
    keep = opts.keep_jobs,
    title = opts.title,
    bopen = opts.bopen or false,
    on_exit = function(job, buffer)
      if job.exit_code == 0 then
        if should_notify(opts) then
          vim.notify("[git-firvish] done.", vim.log.levels.INFO)
        end
      else
        if opts.open_on_error then
          assert(type(opts.open_on_error == "boolean"), "[git-firvish] open_on_error must be a string if not `false`")
          buffer:open(opts.open_on_error)
        end
      end
    end,
  }
end

local filetype_by_command = {
  ["ls-files"] = "firvish-dir",
}

---@package
function M.filetype_for(args)
  for _, arg in ipairs(args) do
    if not vim.startswith(arg, "-") then
      local ft = filetype_by_command[arg]
      if ft ~= nil then
        return ft
      end
    end
  end
  return M.config.filetype
end

return M

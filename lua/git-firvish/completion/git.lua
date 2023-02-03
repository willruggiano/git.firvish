local Command = require "git-firvish.grammar.command"
local Option = require "git-firvish.grammar.option"
local types = require "git-firvish.grammar.types"

local command = Command:new {
  "git",
  {
    Option:flag { "-v", "--version" },
    Option:flag { "-h", "--help" },
    Option:new { "-C", type = types.path },
    -- Option:new("-c", { type = "keyvalue" }),
    -- Option:new("--config-env", { type = keyvalue("envvar") }),
    -- Option:new { "--exec-path", type = types.optional(types.path) },
    Option:flag "--html-path",
    Option:flag "--man-path",
    Option:flag "--info-path",
    Option:flag { "-p", "--paginate" },
    Option:flag { "-P", "--no-pager" },
    Option:new { "--git-dir", type = types.path },
    Option:new { "--work-tree", type = types.path },
    Option:new { "--namespace", type = types.path },
    Option:new { "--super-prefix", type = types.path },
    Option:flag "--bare",
    Option:flag "--no-replace-objects",
    Option:flag "--literal-pathspecs",
    Option:flag "--glob-pathspecs",
    Option:flag "--noglob-pathspecs",
    Option:flag "--icase-pathspecs",
    Option:flag "--no-optional-locks",
  },
  {
    require "git-firvish.grammar.git-add",
    -- require "git-firvish.grammar.git-am",
    -- require "git-firvish.grammar.git-archive",
    -- require "git-firvish.grammar.git-bisect",
    -- require "git-firvish.grammar.git-branch",
    -- TODO: The rest; see `git help git`
  },
}

return command

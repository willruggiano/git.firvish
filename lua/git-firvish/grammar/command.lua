local Command = {}
Command.__index = Command

function Command:new(opts)
  assert(#opts > 0, "command must at least have a name")
  local obj = {
    command = opts[1],
  }

  local options = opts[2]
  if options then
    for _, opt in ipairs(options) do
      --
    end
  end

  local subcommands = opts[3]
  if subcommands then
    for _, cmd in ipairs(subcommands) do
      --
    end
  end

  return setmetatable(obj, Command)
end

function Command:parse(str)
  local parts = {}
  for s in string.gmatch(str, "%S+") do
    table.insert(parts, s)
  end

  local context = { self }
  self:parse_(parts, context, 1)
  return context
end

function Command:parse_(parts, context, i)
  local part = parts[i]
  if part == nil then
    return context
  end

  if vim.startswith(part, "-") then
    -- Then it's an option
    -- FIXME: It could be '--'
    local opt, n = self:option(part):parse(parts, i)
    table.insert(context, opt)
    return self:parse_(parts, context, i + n)
  else
    -- Then it's an argument
    -- Note that it CANNOT be an argument-accepting-option here.
    -- We deal with that when dealing with the option itself.
    self:add_argument(part)
    return self:parse_(parts, context, i + 1)
  end
end

return Command

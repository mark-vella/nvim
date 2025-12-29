local M = {}

function M.toggle_markdown_wrap()
	if vim.bo.filetype ~= "markdown" then
		vim.notify("Word wrap toggle only works in Markdown files", vim.log.levels.WARN)
		return
	end

	local current_wrap = vim.opt_local.wrap:get()
	vim.opt_local.wrap = not current_wrap

	if vim.opt_local.wrap:get() then
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.notify("Word wrap: ON", vim.log.levels.INFO)
	else
		vim.opt_local.linebreak = false
		vim.opt_local.breakindent = false
		vim.notify("Word wrap: OFF", vim.log.levels.INFO)
	end
end

function M.get_env_variable(name)
	local env_path = vim.fn.stdpath("config") .. "/.env"
	local file = io.open(env_path, "r")
	if not file then
		return nil
	end
	for line in file:lines() do
		local key, value = line:match("^([%w_]+)%s*=%s*(.+)$")
		if key == name then
			file:close()
			return value
		end
	end
	file:close()
	return nil
end

return M

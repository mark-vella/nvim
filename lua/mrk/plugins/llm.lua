local utils = require("mrk.utils")

-- API key detection with priority order
local function get_available_provider()
        local providers = {
                {
                        key = "OPENCODE_ZEN_API_KEY",
                        name = "opencode",
                        end_point = "https://opencode.ai/zen/v1/chat/completions",
                        display_name = "OpenCode Zen",
                        default_model = "grok-code",
                },
                {
                        key = "OPENROUTER_API_KEY",
                        name = "openrouter",
                        end_point = "https://openrouter.ai/api/v1/chat/completions",
                        display_name = "OpenRouter",
                        default_model = "moonshotai/kimi-k2-0905",
                },
        }
        for _, p in ipairs(providers) do
                if utils.get_env_variable(p.key) then
                        return p
                end
        end

        return nil
end

local function build_minuet_config()
        local provider = get_available_provider()
        if not provider then
                vim.notify("[milanglacier/minuet-ai.nvim] No API keys found", vim.log.levels.WARN)
                return nil
        end

        local presets = {}

        if utils.get_env_variable("OPENCODE_ZEN_API_KEY") then
                local opencode_base = {
                        provider = "openai_compatible",
                        provider_options = {
                                openai_compatible = {
                                        api_key = function()
                                                return utils.get_env_variable(
                                                        "OPENCODE_ZEN_API_KEY"
                                                )
                                        end,
                                        end_point = "https://opencode.ai/zen/v1/chat/completions",
                                        name = "OpenCode Zen",
                                        optional = {
                                                max_tokens = 56,
                                                top_p = 0.9,
                                        },
                                },
                        },
                }

                presets["oc-grok-code"] = vim.tbl_deep_extend("force", opencode_base, {
                        provider_options = {
                                openai_compatible = { model = "grok-code" },
                        },
                })

                presets["oc-kimi-k2"] = vim.tbl_deep_extend("force", opencode_base, {
                        provider_options = {
                                openai_compatible = { model = "kimi-k2" },
                        },
                })

                presets["oc-big-pickle"] = vim.tbl_deep_extend("force", opencode_base, {
                        provider_options = {
                                openai_compatible = { model = "big-pickle" },
                        },
                })
        end

        if utils.get_env_variable("OPENROUTER_API_KEY") then
                local openrouter_base = {
                        provider = "openai_compatible",
                        provider_options = {
                                openai_compatible = {
                                        api_key = function()
                                                return utils.get_env_variable("OPENROUTER_API_KEY")
                                        end,
                                        end_point = "https://openrouter.ai/api/v1/chat/completions",
                                        name = "OpenRouter",
                                        optional = {
                                                max_tokens = 56,
                                                top_p = 0.9,
                                        },
                                },
                        },
                }

                presets["or-gemini-3-flash"] = vim.tbl_deep_extend("force", openrouter_base, {
                        provider_options = {
                                openai_compatible = { model = "google/gemini-3-flash-preview" },
                        },
                })

                presets["or-kimi-k2"] = vim.tbl_deep_extend("force", openrouter_base, {
                        provider_options = {
                                openai_compatible = { model = "moonshotai/kimi-k2-0905" },
                        },
                })
        end

        return {
                virtualtext = {
                        auto_trigger_ft = { "lua", "markdown", "typescript" },
                        keymap = {
                                accept = "<A-A>",
                                accept_line = "<A-a>",
                                accept_n_lines = "<A-n>",
                                prev = "<A-[>",
                                next = "<A-]>",
                                dismiss = "<A-d>",
                        },
                },
                provider = "openai_compatible",
                request_timeout = 2.5,
                throttle = 1500,
                debounce = 600,
                provider_options = {
                        openai_compatible = {
                                api_key = function()
                                        return utils.get_env_variable(provider.key)
                                end,
                                end_point = provider.end_point,
                                model = provider.default_model,
                                name = provider.display_name,
                                optional = {
                                        max_tokens = 56,
                                        top_p = 0.9,
                                },
                        },
                },
                presets = presets,
        }
end

return {
        {
                "folke/sidekick.nvim",
                opts = {
                        nes = { enabled = false },
                        cli = {
                                mux = {
                                        backend = "tmux",
                                        create = "terminal",
                                        enabled = true,
                                        split = {
                                                vertical = true,
                                                size = 0.75,
                                        },
                                },
                        },
                },
                keys = {
                        {
                                "<leader>ac",
                                function()
                                        require("sidekick.cli").toggle({
                                                name = "opencode",
                                                focus = true,
                                        })
                                end,
                                desc = "Sidekick Toggle CLI",
                        },
                        {
                                "<leader>af",
                                function()
                                        require("sidekick.cli").send({ msg = "{file}" })
                                end,
                                desc = "Send File",
                        },
                        {
                                "<leader>av",
                                function()
                                        require("sidekick.cli").send({ msg = "{selection}" })
                                end,
                                mode = { "x" },
                                desc = "Send Visual Selection",
                        },
                },
        },
        {
                "milanglacier/minuet-ai.nvim",
                dependencies = {
                        "nvim-lua/plenary.nvim",
                },
                config = function()
                        local config = build_minuet_config()
                        if config then
                                require("minuet").setup(config)
                        end
                end,
        },
}

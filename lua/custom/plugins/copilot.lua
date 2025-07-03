--[[
CopilotChat.nvim Configuration & Reference
==========================================

CopilotChat.nvim brings GitHub Copilot Chat to Neovim, enabling you to interact conversationally with AI, ask questions about your code, generate documentation, review, fix, and more—directly from your editor.

**Key Features**
- 🤖 Chat with Copilot (and other models/agents, including Gemini, GPT-4, Claude, etc.)
- 💻 Workspace-aware with smart context: buffers, files, diffs, URLs, etc.
- 🔒 Explicit context sharing: Only selected/explicit content is sent.
- 📝 Interactive chat UI with completions, diffs, quickfix, and sticky prompts.
- 🔄 Extensible: Custom prompts, agents, models, and context providers.

**Requirements**
- Neovim >= 0.10.0
- curl >= 8.0.0
- GitHub Copilot Chat enabled in your GitHub settings
- Optional: `tiktoken_core` for token counting (`make tiktoken` or via luarocks)
- Optional: `git`, `ripgrep`, `lynx` for advanced context features

**How to Use**
1. Open chat: `:CopilotChat` or `:CopilotChatOpen`
2. Type your question (optionally select code in visual mode for context)
3. Submit with `<C-s>` (insert) or `<CR>` (normal)
4. Close with `q` (normal) or `<C-c>` (insert)

**Default Key Mappings (in Chat Window)**
| Mode      | Key      | Action                                          |
|-----------|----------|-------------------------------------------------|
| Insert    | <Tab>    | Trigger/accept completion                       |
| Insert    | <C-c>    | Close chat window                               |
| Insert    | <C-l>    | Reset/clear chat window                         |
| Insert    | <C-s>    | Submit prompt                                   |
| Insert    | <C-y>    | Accept nearest diff                             |
| Normal    | q        | Close chat window                               |
| Normal    | <C-l>    | Reset/clear chat window                         |
| Normal    | <CR>     | Submit prompt                                   |
| Normal    | grr      | Toggle sticky prompt for line under cursor      |
| Normal    | grx      | Clear all sticky prompts                        |
| Normal    | gj       | Jump to section of nearest diff                 |
| Normal    | gqa      | Add all answers from chat to quickfix list      |
| Normal    | gqd      | Add all diffs from chat to quickfix list        |
| Normal    | gy       | Yank nearest diff                               |
| Normal    | gd       | Show diff between source and nearest diff       |
| Normal    | gi       | Show info about current chat                    |
| Normal    | gc       | Show current chat context                       |
| Normal    | gh       | Show help message                               |

**Commands**
- `:CopilotChat <input>?` — Open chat with optional input
- `:CopilotChatOpen` / `:CopilotChatClose` / `:CopilotChatToggle`
- `:CopilotChatPrompts` — Select a prompt template
- `:CopilotChatModels` — Select a model
- `:CopilotChatAgents` — Select an agent

**Models & Agents**
- List available models: `:CopilotChatModels`
- List available agents: `:CopilotChatAgents`
- Set default below via `model` and `agent` keys, or override in prompt with `$model_name` / `@agent_name`.
- For Gemini 2.5 Pro: `model = "gemini-2.5-pro-preview-06-05"`, `agent = "copilot"`

**Contexts**
- Add context via `#context[:input]`, e.g. `#buffer`, `#git:staged`, `#files:*.lua`, etc.
- Visual selection is used by default for context if active.

**Prompts**
- Use `/PromptName` in chat, or `:CopilotChat<PromptName>` (e.g., `/Explain`, `/Review`, `/Fix`)
- Define custom prompts in the config under `prompts = { ... }`

**Customization**
- All keys and options are customizable via the `opts` table.
- See https://github.com/CopilotC-Nvim/CopilotChat.nvim for full docs and advanced usage.

]]

return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- Copilot integration for chat
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- Async/shell helpers
    },
    build = 'make tiktoken', -- Only needed on MacOS/Linux for token counting
    opts = {
      -- Core chat options
      model = 'gemini-2.5-pro', -- Default Copilot Chat model (Gemini 2.5 Pro)
      agent = 'copilot', -- Default agent (GitHub Copilot)
      -- context = nil,     -- Default context (e.g., "buffer", "file:README.md", etc.)
      -- sticky = nil,      -- Sticky prompts to persist at top of each new prompt
      -- temperature = 0.1, -- Model temperature (higher = more creative)

      -- Example: Custom prompt
      -- prompts = {
      --   MyPrompt = {
      --     prompt = "Explain how this works.",
      --     description = "Explain code in detail",
      --     mapping = "<leader>cexplain",
      --   }
      -- },

      -- Example: Custom key mapping for submit
      -- mappings = {
      --   submit_prompt = {
      --     normal = "<Leader>s",
      --     insert = "<C-s>",
      --   }
      -- }
    },
  },
}

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- Map <leader>gb to git_bcommits_range
      {
        "<leader>gb",
        function()
          local builtin = require("telescope.builtin")
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")

          -- 1. Get the current line number (or range if in visual mode)
          -- Note: git_bcommits_range works best with visual selection,
          -- but we can simulate it for a single line by defaulting to the current line.
          local opts = {
            from = vim.fn.line("."),
            to = vim.fn.line("."),
            attach_mappings = function(_, map)
              map({ "i", "n" }, "<CR>", function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local sha = selection.value
                if not sha then
                  return
                end

                vim.notify("Finding PR for commit " .. sha:sub(1, 7) .. "...", vim.log.levels.INFO)

                -- 2. Find the PR
                local cmd = string.format("gh pr list --search %s --state all --json url --jq '.[0].url'", sha)
                local handle = io.popen(cmd)
                local url = handle:read("*a")
                handle:close()

                url = url and url:gsub("%s+", "") or ""

                -- 3. Fallback to commit URL
                if url == "" then
                  if package.loaded["snacks"] then
                    Snacks.git.browse({ what = "commit", hash = sha })
                  else
                    os.execute(string.format("gh browse %s", sha))
                  end
                  return
                end

                -- 4. Open PR
                local open_cmd
                if vim.fn.has("mac") == 1 then
                  open_cmd = "open"
                elseif vim.fn.has("win32") == 1 then
                  open_cmd = "start"
                else
                  open_cmd = "xdg-open"
                end
                os.execute(string.format("%s '%s'", open_cmd, url))
              end)
              return true
            end,
          }

          -- Check if we are in visual mode to pass the correct range
          -- (This requires the mapping to support visual mode, see below)
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" then
            opts.from = vim.fn.line("v")
            opts.to = vim.fn.line(".")
          end

          builtin.git_bcommits_range(opts)
        end,
        mode = { "n", "v" }, -- Enable for Normal and Visual mode
        desc = "Git Blame Line History (Open PR)",
      },
    },
  },
}

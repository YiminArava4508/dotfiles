-- Keep Snacks.words reference navigation (]] [[ <a-n> <a-p>) but hide the
-- LSP document-highlight underlay. On dense files (e.g. ent schemas) gopls
-- reports references to the symbol under the cursor all over the buffer,
-- which otherwise lights up nearly the whole page.
return {
  "folke/snacks.nvim",
  opts = {
    words = { enabled = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "LspReferenceText", {})
        vim.api.nvim_set_hl(0, "LspReferenceRead", {})
        vim.api.nvim_set_hl(0, "LspReferenceWrite", {})
      end,
    })
  end,
}

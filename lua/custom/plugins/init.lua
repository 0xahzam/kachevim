local M = {}

-- see this?
function Yacine_copy_file_path()
  local path = vim.fn.expand('%:.')
  vim.fn.setreg('+', path)
  print('File path copied to clipboard')
end

vim.api.nvim_create_user_command('CopyFilePath', Yacine_copy_file_path, {})

-- i need ot url encode the link. this is nvim config
function Yacine_copy_sg_link()
  local path = vim.fn.expand('%:.')
  local line_content = vim.fn.getline('.')
  local link = "http://go/sg/file:" .. path
  print(link)
  vim.fn.setreg('+', link)
  vim.fn.jobstart({'open', link})
  print('File link copied to clipboard and opened in browser')
end

vim.api.nvim_create_user_command('SourceGrepFile', Yacine_copy_sg_link, {})

function Yacine_copy_lldb_breakpoint()
  local path = vim.fn.expand('%:.')
  local line = vim.fn.line('.')
  local cmd = string.format("breakpoint set --file \"%s\" --line %d", path, line)
  vim.fn.setreg('+', cmd)
  print('LLDB breakpoint command copied to clipboard')
end

vim.api.nvim_create_user_command('LLDBBreakpointToClipboard', Yacine_copy_lldb_breakpoint, {})

function Yacine_comment_toggle()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    local filetype = vim.bo.filetype
    local comment_string = vim.bo.commentstring or '//%s'
    comment_string = comment_string:gsub('%%s', '')

    if comment_string == '' then
        comment_string = '//'
    end

    comment_string = comment_string:match("^%s*(.-)%s*$")

    for line = start_line, end_line do
        local current_line = vim.fn.getline(line)
        local leading_space = current_line:match("^(%s*)")
        local content = current_line:match("^%s*(.*)")

        if content:match("^" .. vim.pesc(comment_string) .. "%s") then
            content = content:gsub("^" .. vim.pesc(comment_string) .. "%s", "", 1)
        else
            content = comment_string .. " " .. content
        end

        vim.fn.setline(line, leading_space .. content)
    end
end

vim.api.nvim_set_keymap('v', '<C-/>', ':lua Yacine_comment_toggle()<CR>gv', {noremap = true, silent = true})

-- config here that avoids leaving visual selection when > or < to indent
vim.keymap.set('v', '>', '>gv', { noremap = true, silent = true })
vim.keymap.set('v', '<', '<gv', { noremap = true, silent = true })

-- folds

-- for some reason, when i paste something that's folded 
-- vim.opt.foldmethod = 'marker'
-- vim.opt.foldmarker = '{,}'
-- vim.opt.foldenable = false
-- vim.keymap.set('v', 'zc', 'zc`>gv', { noremap = true, silent = true })
-- vim.keymap.set('v', 'zo', 'zo`>gv', { noremap = true, silent = true })

function YacineYankBufferWithoutFolds()
    local view = vim.fn.winsaveview()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local folded_lines = {}
    local i = 1
    while i <= #lines do
        if vim.fn.foldclosed(i) ~= -1 then
            local start_line = lines[i]:gsub("%s+$", "")
            local end_line = lines[vim.fn.foldclosedend(i)]:gsub("^%s+", "")
            table.insert(folded_lines, start_line .. ' ... ' .. end_line)
            i = vim.fn.foldclosedend(i) + 1
        else
            table.insert(folded_lines, lines[i])
            i = i + 1
        end
    end
    local folded_text = table.concat(folded_lines, '\n')
    vim.fn.setreg('+', folded_text)
    vim.fn.winrestview(view)
end

vim.api.nvim_create_user_command('YankBufferWithoutFolds', YacineYankBufferWithoutFolds, {})


vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

function SelectCodeBlock()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local start_line, end_line

  for i = cursor_pos[1] - 1, 1, -1 do
    if lines[i]:match("^```") then
      end_line = i
      break
    end
  end

  if end_line then
    for i = end_line - 1, 1, -1 do
      if lines[i]:match("^```") then
        start_line = i
        break
      end
    end
  end

  if start_line and end_line then
    vim.api.nvim_buf_add_highlight(buffer, -1, 'Visual', start_line, 0, end_line)
    vim.api.nvim_win_set_cursor(0, {start_line + 1, 0})
    vim.cmd('normal! V')
    vim.api.nvim_win_set_cursor(0, {end_line - 1, 0})
  end
end
vim.api.nvim_set_keymap('n', '<leader>c', ':lua SelectCodeBlock()<CR>', {noremap = true, silent = true})

return M

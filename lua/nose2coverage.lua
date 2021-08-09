local xml2lua = require("ext.xml2lua")
local handler = require("ext.xmlhandler.tree")
local M = {}

local coverage
local ft
local coverage_report
local enabled

vim.fn.sign_define('Nose2CoverageHit',
                   {text = "+", texthl = '', linehl = '', numhl = ''})
vim.fn.sign_define('Nose2CoverageMissing',
                   {text = "-", texthl = '', linehl = '', numhl = ''})

function M.coverage_report_exists()
    local f = io.open(coverage_report, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function M.setup(c)
    ft = c.ft or '*.py'
    coverage_report = c.coverage_report or 'coverage.xml'
    enabled = c.enabled

    vim.api.nvim_command('autocmd BufEnter ' .. ft ..
                             ' lua require("nose2coverage").draw(0)')
    vim.api.nvim_command('autocmd InsertLeave ' .. ft ..
                             ' lua require("nose2coverage").redraw(0)')
    vim.api.nvim_command('autocmd TextChanged ' .. ft ..
                             ' lua require("nose2coverage").redraw(0)')
    vim.api.nvim_command('autocmd TextChangedI ' .. ft ..
                             ' lua require("nose2coverage").redraw(0)')
end

function M.parse_report()
    coverage = {}

    local coverage_handler = handler:new()
    local parser = xml2lua.parser(coverage_handler)
    parser:parse(xml2lua.loadFile(coverage_report))

    for _, package in pairs(coverage_handler.root.coverage.packages.package) do
        for _, class in pairs(package.classes.class) do
            if class._attr then
                coverage[class._attr.filename] = {}
                for _, lines in pairs(class.lines) do
                    for _, line in pairs(lines) do
                        coverage[class._attr.filename][line._attr["number"]] =
                            line._attr["hits"]
                    end
                end
            end
        end
    end

end

function M.draw(buf)
    if M.coverage_report_exists() and enabled then
        M.parse_report()
        local filename = M.getfilename(buf)
        if coverage[filename] then
            for line, hits in pairs(coverage[filename]) do
                if hits == "0" then
                    vim.fn.sign_place(0, "nose2coverage",
                                      "Nose2CoverageMissing",
                                      vim.api.nvim_buf_get_name(buf),
                                      {lnum = line})
                else
                    vim.fn.sign_place(0, "nose2coverage", "Nose2CoverageHit",
                                      vim.api.nvim_buf_get_name(buf),
                                      {lnum = line})
                end
            end
        end
    end
end

function M.clear(buf)
    local buffer = vim.api.nvim_buf_get_name(buf)
    for _, sign in ipairs(vim.fn.sign_getplaced(buffer,
                                                {group = "nose2coverage"})) do
        vim.fn.sign_unplace("nose2coverage", {buffer = buffer, id = sign.id})
    end
end

function M.redraw(buf)
    M.clear(buf)
    M.draw(buf)
end

function M.getfilename(buf)
    local filename = vim.api.nvim_buf_get_name(buf)
    return filename:gsub(vim.fn.getcwd():gsub("%-", ".") .. "/", "")
end

function M.total_coverage()
    local buf = vim.api.nvim_get_current_buf()
    if M.coverage_report_exists() and enabled then
        M.parse_report()
        local filename = M.getfilename(buf)
        if coverage[filename] then
            local covered = 0
            local total = 0
            for _, hits in pairs(coverage[filename]) do
                total = total + 1

                if hits ~= "0" then covered = covered + 1 end
            end
            return tostring(math.floor(covered / total * 100)) .. "%%"
        end
    end
    return "N/A"
end

function M.display()
    enabled = true
    M.redraw(vim.api.nvim_get_current_buf())
end

function M.hide()
    enabled = false
    M.redraw(vim.api.nvim_get_current_buf())
end

return M

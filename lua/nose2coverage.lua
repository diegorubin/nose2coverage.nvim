local xml2lua = require("ext.xml2lua")
local handler = require("ext.xmlhandler.tree")

local M = {}

local coverage
local ft
local coverage_report

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
end

function M.parse_report()
    local report_file = io.open(coverage_report)
    local xml = report_file:read("*a")
    report_file:close()

    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    coverage = {}

    if handler.root.coverage.packages then
        for _, package in pairs(handler.root.coverage.packages.package) do
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

end

function M.draw(buf)
    if M.coverage_report_exists() then
        M.parse_report()

        local filename = vim.api.nvim_buf_get_name(buf)
        filename = filename:gsub(vim.fn.getcwd():gsub("%-", ".") .. "/", "")

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

function M.clear(buf) end

function M.display(buf)
    M.clear(buf)
    M.draw(buf)
end

return M

local M = {}

local os_info = io.popen("cat /etc/os-release"):read("*a")

M.is_fedora = function()
    return os_info:match("ID=fedora") ~= nil
end

return M

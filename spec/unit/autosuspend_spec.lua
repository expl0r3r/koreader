describe("AutoSuspend widget tests", function()
    setup(function()
        require("commonrequire")
        package.unloadAll()
    end)

    before_each(function()
        local Device = require("device")
        stub(Device, "isKobo")
        Device.isKobo.returns(true)
        Device.input.waitEvent = function() end
        local UIManager = require("ui/uimanager")
        stub(UIManager, "suspend")
        UIManager._run_forever = true
        G_reader_settings:saveSetting("auto_suspend_timeout_seconds", 10)
        require("mock_time"):install()
    end)

    after_each(function()
        require("device").isKobo:revert()
        require("ui/uimanager").suspend:revert()
        G_reader_settings:delSetting("auto_suspend_timeout_seconds")
        require("mock_time"):uninstall()
    end)

    it("should be able to execute suspend when timing out", function()
        local mock_time = require("mock_time")
        local widget_class = dofile("plugins/autosuspend.koplugin/main.lua")
        local widget = widget_class:new()
        local UIManager = require("ui/uimanager")
        mock_time:increase(5)
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(0)
        mock_time:increase(6)
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(1)
        mock_time:uninstall()
    end)

    it("should be able to initialize several times", function()
        local mock_time = require("mock_time")
        -- AutoSuspend plugin set the last_action_sec each time it is initialized.
        local widget_class = dofile("plugins/autosuspend.koplugin/main.lua")
        local widget1 = widget_class:new()
        -- So if one more initialization happens, it won't sleep after another 5 seconds.
        mock_time:increase(5)
        local widget2 = widget_class:new()
        local UIManager = require("ui/uimanager")
        mock_time:increase(6)
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(1)
        mock_time:uninstall()
    end)

    it("should be able to deprecate last task", function()
        local mock_time = require("mock_time")
        local widget_class = dofile("plugins/autosuspend.koplugin/main.lua")
        local widget = widget_class:new()
        mock_time:increase(5)
        local UIManager = require("ui/uimanager")
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(0)
        widget:onInputEvent()
        widget:onSuspend()
        widget:onResume()
        mock_time:increase(6)
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(0)
        mock_time:increase(5)
        UIManager:handleInput()
        assert.stub(UIManager.suspend).was.called(1)
        mock_time:uninstall()
    end)
end)

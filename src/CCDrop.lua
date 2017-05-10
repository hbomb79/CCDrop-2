centrePrint("Loading CCDrop", TERM_Y - 1, colours.lightBlue)

-- Bind the custom ModemEvent to 'modem_message' events
Event.bindEvent( "modem_message", "ModemEvent" )

-- Spawn CCDrop client
_G.client = CCDrop()

-- Load UI
client:importFromTML "src/ui/master.tml"
client:addTheme( Theme.fromFile( "master", "src/ui/master.theme" ) )

-- Assign callbacks
client:query "#exit":on( "trigger", function() client:stop() end )
client:query "#initiate":on( "trigger", function() client:sendContent() end )
client:query "#settings":on( "trigger", function() client:revealSettings() end )

-- Cache important nodes
notificationContent = client:query "#notifications".result[ 1 ]
notificationView = notificationContent:query "#panel".result[ 1 ]
notificationChanger = notificationView:query "#panel_changer".result[ 1 ]
_G.notificationTiler = notificationChanger:query "#list".result[ 1 ]
pages = client:query "PageContainer#master".result[ 1 ]

notificationChanger:query "#return":on( "trigger", function() notificationChanger:selectPage "main" end )

notificationChanger:selectPage "main"

-- Let click events pass through the container if they don't collide with a child node
notificationContent.consumeAll = false

client:openNotifications()

client:schedule(function()
    client:addNotification( FileNotification {
        name = "Reactor Controller";
        sender = 10;
    } )

    client:addNotification( FileNotification {
        name = "ME Controller";
        sender = 11;
    } )

    client:schedule( function()
        client:addNotification( FileNotification {
            name = "ME Receiver";
            sender = 12;
        } )

        client:addNotification( FileNotification {
            name = "ME";
            sender = 13;
        } )

        client:addNotification( FileNotification {
            name = "IDK";
            sender = 14;
        } )
    end, 0.6 )
end, 2)

local notifs_close = client:query "#collapse_notifications".result[ 1 ]
local notifs_open = client:query "#open_notifications".result[ 1 ]

notifs_close.text = _HOST and "\30" or notifs_close.text
notifs_close:on("trigger", function() client:closeNotifications() end)

notifs_open.text = _HOST and "\31" or notifs_open.text
notifs_open:on("trigger", function() client:openNotifications() end)

-- Start the client
client.state = "root"
client:start()

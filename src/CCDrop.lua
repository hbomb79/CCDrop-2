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
notificationTiler = notificationChanger:query "#list".result[ 1 ]
pages = client:query "PageContainer#master".result[ 1 ]

notificationChanger:selectPage "main"

-- Let click events pass through the container if they don't collide with a child node
notificationContent.consumeAll = false

local notif = Notification("Test Notification", "CCDrop features a notification based alert system. Instead of abruptly changing the page to show you details regarding a new file request, the information will be shown here in a scrollable manner.", { { "accept", "Accept Transfer" }, { "deny", "Deny Transfer" } } )
notif:on("accept", function()
    error "accepted"
end)

notif:on("deny", function()
    client:removeNotification( notif )
end)

client:schedule( function()
    client:addNotification( notif )
end, 2 )

local notifs_close = client:query "#collapse_notifications".result[ 1 ]
local notifs_open = client:query "#open_notifications".result[ 1 ]

notifs_close.text = _HOST and "\30" or notifs_close.text
notifs_close:on("trigger", function() client:closeNotifications() end)

notifs_open.text = _HOST and "\31" or notifs_open.text
notifs_open:on("trigger", function() client:openNotifications() end)

-- Start the client
client.state = "root"
client:start()

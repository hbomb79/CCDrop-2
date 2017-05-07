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
pages = client:query "PageContainer#master".result[ 1 ]

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

-- Start the client
client.state = "root"
client:start()

centrePrint("Loading CCDrop", TERM_Y - 1, colours.lightBlue)

-- Bind the custom ModemEvent to 'modem_message' events
Event.bindEvent( "modem_message", "ModemEvent" )

-- Spawn CCDrop client
_G.client = CCDrop()

-- Load UI
client:addTheme( Theme.fromFile( "master", "src/ui/master.theme" ) )
client:importFromTML "src/ui/master.tml"

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

local notifs_close = client:query "#collapse_notifications".result[ 1 ]
local notifs_open = client:query "#open_notifications".result[ 1 ]

notifs_close.text = _HOST and "\30" or notifs_close.text
notifs_close:on("trigger", function() client:closeNotifications() end)

notifs_open.text = _HOST and "\31" or notifs_open.text
notifs_open:on("trigger", function() client:openNotifications() end)

local pl = select( 1, loadfile "plexus.lua" )
client:query "Terminal":set( "chunk", function() os.pullEvent( "mouse_click" ); pl() select( 1, loadfile "/rom/programs/shell" )() end )

-- Start the client
client.state = "root"
client:start()

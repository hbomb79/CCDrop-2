centrePrint "Checking Plexus for updates"
-- if not shell.run( "tpm install Plexus --silent" ) then
    -- TODO: Plexus installation media to TPM
    -- error( "Failed to install Plexus (via TPM). Cannot continue with execution." )
-- end

centrePrint "Loading CCDrop"

-- Bind the custom ModemEvent to 'modem_message' events
Event.bindEvent( "modem_message", "ModemEvent" )

-- Spawn CCDrop client
client = CCDrop( 1, 1, term.getSize() )

-- Load UI
client:addTheme( Theme.fromFile( "master", "src/ui/master.theme" ) )
client:importFromTML "src/ui/master.tml"

-- Assign callbacks
client:query "#exit":on( "trigger", function() client:stop() end )
client:query "#initiate".result[ 1 ]:on( "trigger", function() client:pickContent() end ):set( "enabled", false )
client:query "#settings":on( "trigger", function() client:revealSettings() end )

-- Cache important nodes
notificationContent = client:query "#notifications".result[ 1 ]
notificationView = notificationContent:query "#panel".result[ 1 ]
notificationChanger = notificationView:query "#panel_changer".result[ 1 ]
notificationTiler = notificationChanger:query "#list".result[ 1 ]
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

-- Start the client
client:embedPlexus()

client.state = "root"
client:addThread( Thread( function() os.pullEventRaw "PLEXUS_EMBED"; client:query "#initiate":set( "enabled", true ) end ) )

client:checkForTrouble()
client:start()

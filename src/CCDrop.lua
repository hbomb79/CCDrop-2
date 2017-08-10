centrePrint "Checking Plexus for updates"

PLEXUS_VERSION = "v0.1.0-alpha.1"
shell.run( ( "/.tpm/bin/tpm --disposable --depend %s install Plexus:%s --silent --fetch" ):format( shell.getRunningProgram(), PLEXUS_VERSION ) )

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

client:query "Page#error Button#return":on("trigger", function()
	local t = client.trouble
	client:checkForTrouble()

    local target = CCDrop.static.TROUBLE_CODES[ t ][ 3 ]
	if client.trouble == t then
		client:addNotification( Notification( "Unable to return home", "CCDrop is still experiencing the same error, so it cannot return home. Resolve this issue before attempting to return home.", { { "ok", "Okay" } } ) )
	elseif type( target ) == "string" then
        client.state = target
    end
end)

client:query "Button#cancelDiscovery":on( "trigger", function() client.state = "picking"; client.sending = false end )
client:query "Button#discoverRefresh":on( "trigger", function() if not client.discovering then client:discoverClients() end end )
client:query "Button#connectionAbort":on( "trigger", function() if client.activeConnection then client.activeConnection:terminate() end end)

-- Start the client
client:embedPlexus()

client.state = "root"
client:addThread( Thread( function() os.pullEventRaw "PLEXUS_EMBED"; client:query "#initiate":set( "enabled", true ) end ) )

client:checkForTrouble()
client:start()

-- Bind the custom ModemEvent to 'modem_message' events
Event.bindEvent( "modem_message", "ModemEvent" )

-- Spawn CCDrop client
client = CCDrop()

-- Start the client
client:start()

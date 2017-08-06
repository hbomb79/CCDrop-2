TERM_X, TERM_Y = term.getSize()

term.setBackgroundColour( colours.grey )
term.clear()

function centrePrint( text, colour, y )
    term.setCursorPos( TERM_X / 2 - #text / 2, y or TERM_Y - 1 )
    term.setTextColour( colour or colours.lightBlue )

    term.clearLine()
    term.write( text )
end

centrePrint( "CCDrop", 1, 7 )
centrePrint "Checking Titanium for updates"

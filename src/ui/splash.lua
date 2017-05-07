_G.cos = math.cos
TERM_X, TERM_Y = term.getSize()

term.setBackgroundColour( colours.grey )
term.clear()

function centrePrint( text, y, colour )
    term.setCursorPos( TERM_X / 2 - #text / 2, y )
    term.setTextColour( colour or 1 )

    term.clearLine()
    term.write( text )
end

centrePrint("CCDrop", 7)
centrePrint("Checking Titanium for updates", TERM_Y - 1, colours.lightBlue)

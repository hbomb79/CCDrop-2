local files = {
  [ "MTextDisplay.ti" ] = "local string_len, string_find, string_sub, string_gsub, string_match = string.len, string.find, string.sub, string.gsub, string.match\
\
--[[\
    This mixin is designed to be used by nodes that wish to display formatted text (e.g: Button, TextContainer).\
    The 'drawText' function should be called from the node during draw time.\
]]\
\
abstract class MTextDisplay {\
    lineConfig = {\
        lines = false;\
        alignedLines = false;\
        offsetY = 0;\
    };\
\
    verticalPadding = 0;\
    horizontalPadding = 0;\
\
    verticalAlign = \"top\";\
    horizontalAlign = \"left\";\
\
    includeNewlines = false;\
}\
\
--[[\
    @constructor\
    @desc Registers properties used by this class with the theme handler if the object mixes in 'MThemeable'\
]]\
function MTextDisplay:MTextDisplay()\
    if Titanium.mixesIn( self, \"MThemeable\" ) then\
        self:register( \"text\", \"verticalAlign\", \"horizontalAlign\", \"verticalPadding\", \"horizontalPadding\" )\
    end\
end\
\
--[[\
    @instance\
    @desc Generates a table of text lines by wrapping on newlines or when the line gets too long.\
    @param <number - width>\
]]\
function MTextDisplay:wrapText( width )\
    local text, width, lines = self.text, width or self.width, {}\
    local align, halfWidth = self.horizontalAlign, width / 2\
\
    if width == 0 then return end\
\
    local current = 1\
    while text and string_len( text ) > 0 do\
        local section, pre, post = string_sub( text, 1, width )\
        local starting = current\
        local createTrail\
\
        if string_find( section, \"\\n\" ) then\
            pre, post = string_match( text, \"(.-\\n)(.*)$\" )\
\
            current = current + string_len( pre )\
\
            if post == \"\" then createTrail = true end\
        elseif string_len( text ) <= width then\
            pre = text\
            current = current + string_len( text )\
        else\
            local lastSpace, lastSpaceEnd = string_find( section, \"%s[%S]*$\" )\
\
            pre = lastSpace and string_gsub( string_sub( text, 1, lastSpace - 1 ), \"%s+$\", \"\" ) or section\
            post = lastSpace and string_sub( text, lastSpace + 1 ) or string_sub( text, width + 1 )\
\
            local match = lastSpace and string_match( string_sub( text, 1, lastSpace - 1 ), \"%s+$\" )\
            current = current + string_len( pre ) + ( match and #match or 1 )\
        end\
\
        local offset = 0\
        if align == \"centre\" then\
            offset = math.floor( halfWidth - ( #pre / 2 ) + .5 )\
        elseif align == \"right\" then\
            offset = width - #pre\
        end\
\
        lines[ #lines + 1 ], text = { pre, starting, current - 1, #lines + 1, offset < 1 and 1 or offset }, post\
\
        if createTrail then lines[ #lines + 1 ] = { \"\", current, current, #lines + 1, align == \"centre\" and halfWidth or ( align == \"right\" and width ) or 0 } end\
    end\
\
    self.lineConfig.lines = lines\
end\
\
--[[\
    @instance\
    @desc Uses 'wrapText' to generate the information required to draw the text to the canvas correctly.\
    @param <colour - bg>, <colour - tc>\
]]\
function MTextDisplay:drawText( bg, tc )\
    local lines = self.lineConfig.lines\
    if not lines then\
        self:wrapText()\
        lines = self.lineConfig.lines\
    end\
\
    local vPadding, hPadding = self.verticalPadding, self.horizontalPadding\
\
    local yOffset, xOffset = vPadding, hPadding\
    local vAlign, hAlign = self.verticalAlign, self.horizontalAlign\
    local width, height = self.width, self.height\
\
    if vAlign == \"centre\" then\
        yOffset = math.floor( ( height / 2 ) - ( #lines / 2 ) + .5 ) + vPadding\
    elseif vAlign == \"bottom\" then\
        yOffset = height - #lines - vPadding\
    end\
\
    local canvas, line = self.canvas\
    for i = 1, #lines do\
        local line, xOffset = lines[ i ], hPadding\
        local lineText = line[ 1 ]\
        if hAlign == \"centre\" then\
            xOffset = math.floor( width / 2 - ( #lineText / 2 ) + .5 )\
        elseif hAlign == \"right\" then\
            xOffset = width - #lineText - hPadding + 1\
        end\
\
        canvas:drawTextLine( xOffset + 1, i + yOffset, lineText, tc, bg )\
    end\
end\
\
configureConstructor {\
    argumentTypes = {\
        verticalPadding = \"number\",\
        horizontalPadding = \"number\",\
\
        verticalAlign = \"string\",\
        horizontalAlign = \"string\",\
\
        text = \"string\"\
    }\
}",
  [ "GenericEvent.ti" ] = "--[[\
    @instance main - string (def. nil) - The uppercase version of the event name.\
\
    The GenericEvent class is spawned when an event that Titanium doesn't understand is caught in the Application event loop.\
\
    If you wish to spawn another sort of class when a certain event is caught, consider using `Event.static.bindEvent`.\
]]\
\
class GenericEvent extends Event\
\
--[[\
    @constructor\
    @desc Constructs the GenericEvent instance by storing all passed arguments in 'data'. The first index (1) of data is stored inside 'name'\
    @param <string - name>, [var - arg1], ...\
]]\
function GenericEvent:__init__( ... )\
    local args = { ... }\
\
    self.name = args[ 1 ]\
    self.main = self.name:upper()\
\
    self.data = args\
end",
  [ "Label.ti" ] = "--[[\
    A Label is a node which displays a single line of text. The text cannot be changed by the user directly, however the text can be changed by the program.\
]]\
\
class Label extends Node {\
    labelFor = false;\
\
    allowMouse = true;\
    active = false;\
}\
\
--[[\
    @constructor\
    @param <string - text>, [number - X], [number - Y]\
]]\
function Label:__init__( ... )\
    self:resolve( ... )\
    self.raw.width = #self.text\
\
    self:super()\
    self:register \"text\"\
end\
\
--[[\
    @instance\
    @desc Mouse click event handler. On click the label will wait for a mouse up, if found labelFor is notified\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Label:onMouseClick( event, handled, within )\
    self.active = self.labelFor and within and not handled\
end\
\
--[[\
    @instance\
    @desc If the mouse click handler has set the label to active, trigger the onLabelClicked callback\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Label:onMouseUp( event, handled, within )\
    if not self.labelFor then return end\
\
    local labelFor = self.application:getNode( self.labelFor, true )\
    if self.active and not handled and within and labelFor:can \"onLabelClicked\" then\
        labelFor:onLabelClicked( self, event, handled, within )\
    end\
\
    self.active = false\
end\
\
--[[\
    @instance\
    @desc Clears the Label's canvas and draws a line of text if the label has changed.\
    @param [boolean - force]\
]]\
function Label:draw( force )\
    local raw = self.raw\
    if raw.changed or force then\
        raw.canvas:drawTextLine( 1, 1, raw.text )\
\
        raw.changed = false\
    end\
end\
\
--[[\
    @instance\
    @desc Sets the text of a node. Once set, the nodes 'changed' status is set to true along with its parent(s)\
    @param <string - text>\
]]\
function Label:setText( text )\
    if self.text == text then return end\
\
    self.text = text\
    self.width = #text\
end\
\
configureConstructor({\
    orderedArguments = { \"text\", \"X\", \"Y\" },\
    requiredArguments = { \"text\" },\
    argumentTypes = { text = \"string\" }\
}, true)",
  [ "Checkbox.ti" ] = "--[[\
    @instance checkedMark - string (def. \"x\") - The single character used when the checkbox is checked\
    @instance uncheckedMark - string (def. \" \") - The single character used when the checkbox is not checked\
\
    The checkbox is a node that can be toggled on and off.\
\
    When the checkbox is toggled, the 'toggle' callback will be fired due to mixing in MTogglable\
]]\
\
class Checkbox extends Node mixin MActivatable mixin MTogglable {\
    checkedMark = \"x\";\
    uncheckedMark = \" \";\
\
    allowMouse = true;\
}\
\
--[[\
    @constructor\
    @desc Resolves arguments and calls super constructor\
    @param <number - X>, <number - Y>\
]]\
function Checkbox:__init__( ... )\
    self:resolve( ... )\
    self:super()\
\
    self:register(\"checkedMark\", \"uncheckedMark\")\
end\
\
--[[\
    @instance\
    @desc Sets the checkbox to 'active' when clicked\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Checkbox:onMouseClick( event, handled, within )\
    if not handled then\
        self.active = within\
\
        if within then\
            event.handled = true\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Sets the checkbox to inactive when the mouse button is released. If released on checkbox while active 'onToggle' callback is fired and the checkbox is toggled.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Checkbox:onMouseUp( event, handled, within )\
    if not handled and within and self.active then\
        self:toggle( event, handled, within )\
\
        event.handled = true\
    end\
\
    self.active = false\
end\
\
--[[\
    @instance\
    @desc If a label which specifies this node as its 'labelFor' parameter is clicked this function will be called, causing the checkbox to toggle\
    @param <Label Instance - label>, <MouseEvent - event>, <boolean - handled>, <boolean - within>\
]]\
function Checkbox:onLabelClicked( label, event, handled, within )\
    self:toggle( event, handled, within, label )\
    event.handled = true\
end\
\
--[[\
    @instance\
    @desc Draws the checkbox to the canvas\
    @param [boolean - force]\
]]\
function Checkbox:draw( force )\
    local raw = self.raw\
    if raw.changed or force then\
        local toggled, tc, bg = self.toggled\
        if not self.enabled then\
            tc, bg = raw.disabledColour, raw.disabledBackgroundColour\
        elseif toggled then\
            tc, bg = raw.toggledColour, raw.toggledBackgroundColour\
        elseif self.active then\
            tc, bg = raw.activeColour, raw.activeBackgroundColour\
        end\
\
        raw.canvas:drawPoint( 1, 1, toggled and raw.checkedMark or raw.uncheckedMark, tc, bg )\
        raw.changed = false\
    end\
end\
\
configureConstructor( {\
    orderedArguments = { \"X\", \"Y\" },\
    argumentTypes = {\
        checkedMark = \"string\",\
        uncheckedMark = \"string\"\
    }\
}, true, true )",
  [ "MouseEvent.ti" ] = "local string_sub, string_upper = string.sub, string.upper\
\
--[[\
    @instance main - string (def. \"MOUSE\") - The main type of the event, should remain unchanged\
    @instance sub - string (def. nil) - The sub type of the event (ie: mouse_up -> UP, mouse_scroll -> SCROLL, etc..)\
    @instance X - number (def. nil) - The X co-ordinate where the mouse event occurred\
    @instance Y - number (def. nil) - The Y co-ordinate where the mouse event occurred\
    @instance button - number (def. nil) - The code of the mouse button clicked (or, if mouse scroll the direction of scroll)\
    @instance isWithin - boolean (def. true) - If false, the mouse event has occurred outside of a parent.\
]]\
\
class MouseEvent extends Event {\
    main = \"MOUSE\";\
\
    isWithin = true;\
}\
\
--[[\
    @constructor\
    @desc Sets the values given in their respective instance keys. Stores all values into a table 'data'.\
    @param <string - name>, <number - button>, <number - X>, <number - Y>, [string - sub]\
]]\
function MouseEvent:__init__( name, button, X, Y, sub )\
    self.name = name\
    self.button = button\
    self.X = X\
    self.Y = Y\
\
    self.sub = sub or string_upper( string_sub( name, 7 ) )\
\
    self.data = { name, button, X, Y }\
end\
\
--[[\
    @instance\
    @desc Returns true if the mouse event was inside of the bounds provided.\
    @param <number - x>, <number - y>, <number - w>, <number - h>\
    @return <boolean - inBounds>\
]]\
function MouseEvent:within( x, y, w, h )\
    local X, Y = self.X, self.Y\
\
    return X >= x and Y >= y and X <= -1 + x + w and Y <= -1 + y + h\
end\
\
--[[\
    @instance\
    @desc Returns true if the mouse event was inside the bounds of the parent provided (x, y, width and height)\
    @param <NodeContainer - parent>\
]]\
function MouseEvent:withinParent( parent )\
    return self:within( parent.X, parent.Y, parent.width, parent.height )\
end\
\
--[[\
    @instance\
    @desc Clones 'self' and adjusts it's X & Y positions so that they're relative to 'parent'.\
    @param <NodeContainer - parent>\
    @return <MouseEvent Instance - clone>\
\
    Note: The clone's 'handle' method has been adjusted to also call 'handle' on the master event obj (self).\
]]\
function MouseEvent:clone( parent )\
    local clone = MouseEvent( self.name, self.button, self.X - parent.X + 1, self.Y - parent.Y + 1, self.sub )\
\
    clone.handled = self.handled\
    clone.isWithin = self.isWithin\
    clone.setHandled = function( clone, handled )\
        clone.handled = handled\
        self.handled = handled\
    end\
\
    return clone\
end",
  [ "DynamicValue.ti" ] = "--[[\
    @instance target - Instance (def. false) - The instance that 'property' is stored on\
    @instance property - string (def. false) - The property to control\
    @instance equation - string (def. false) - The equation to parse (DynamicEqParser)\
    @instance resolvedStacks - table (def. false) - The stacks resolved after parsing (automatically set, avoid changing manually)\
    @instance cachedValues - table (def. {}) - The values cached from all stacks (ie: the values from the instances depended on by the dynamic equation). Should not be changed manually\
    @instance attached - boolean (def. false) - When true the dynamic value has already hooked itself into all stack instances\
\
    A basic class that facilitates the use of DynamicValues across Titanium. Manages the lexing and parsing of equations, the resolution of stacks\
    and the application of the values.\
]]\
\
class DynamicValue {\
    target = false;\
\
    equation = false;\
    compiledEquation = false;\
\
    resolvedStacks = false;\
\
    cachedValues = {};\
\
    attached = false;\
}\
\
--[[\
    @constructor\
    @desc Initializes the DynamicValue instance. Set's the target (instance), property (string) and equation (string) of the\
          dynamic value, parses the equation and stores the parser on the instance (eq).\
    @param <Instance - target>, <string - property>, <string - equation>\
]]\
function DynamicValue:__init__( target, property, equation )\
    if not ( Titanium.typeOf( target, \"Node\", true ) and type( property ) == \"string\" and type( equation ) == \"string\" ) then\
        return error(\"Failed to initialise DynamicValue. Expected 'Node Instance', string, string.\", 3 )\
    end\
\
    self.target = target\
    self.property = property\
    self.equation = equation\
\
    self.eq = DynamicEqParser( equation )\
    self.compiledEquation = loadstring( self.eq.output, \"DYNAMIC_VALUE_EQUATION@\" .. self.__ID )\
end\
\
--[[\
    @instance\
    @desc Solves the equation (compiledEquation)\
]]\
function DynamicValue:solve()\
    if not self.compiledEquation then\
        return error \"Cannot solve DynamicValue. Dynamic equation has not been compiled yet, try :refresh\"\
    end\
\
    local ok, err = pcall( self.compiledEquation, self.cachedValues )\
    if ok then\
        local target = self.target\
\
        -- Stop MThemeable picking up this update and changing the mainValue to match\
        target.isUpdating = true\
        self.target[ self.property ] = XMLParser.convertArgType( err, self.propertyType )\
        target.isUpdating = false\
    else\
        printError( \"[WARNING]: Failed to solve DynamicValue. Dynamic equation failed to execute '\"..tostring( err )..\"'\" )\
        self:detach()\
    end\
end\
\
--[[\
    @instance\
    @desc Create the property links for all properties required by the dynamic value.\
]]\
function DynamicValue:attach()\
    local resolvedStacks = self.resolvedStacks\
    if not resolvedStacks then\
        return error \"Cannot attach DynamicValue. Dynamic stacks have not been resolved yet, try :refresh\"\
    end\
\
    self:detach()\
\
    local stack\
    for i = 1, #resolvedStacks do\
        stack = resolvedStacks[ i ]\
\
        stack[ 2 ]:watchProperty( stack[ 1 ], function( _, __, value )\
            self.cachedValues[ i ] = value\
            self:solve()\
        end, \"DYNAMIC_VALUE_\" .. self.__ID )\
    end\
\
    self.attached = true\
end\
\
--[[\
    @instance\
    @desc Removes the property links for all properties required by the dynamic value.\
]]\
function DynamicValue:detach()\
    local resolvedStacks = self.resolvedStacks\
    if not resolvedStacks then return end\
\
    local stack\
    for i = 1, #resolvedStacks do\
        stack = resolvedStacks[ i ]\
\
        stack[ 2 ]:unwatchProperty( stack[ 1 ], \"DYNAMIC_VALUE_\" .. self.__ID )\
    end\
\
    self.attached = false\
end\
\
--[[\
    @instance\
    @desc Invokes :detach on the dynamic value to remove all property links, before removing the DynamicValue instance from the targets MDynamic register.\
]]\
function DynamicValue:destroy()\
    if self.target then\
        self.target:removeDynamicValue( self.property )\
    end\
end\
\
--[[\
    @instance\
    @desc Refresh the dynamic value by resolving the instance stacks, removing any current property links and re-attaching the dynamic value to it's targets\
]]\
function DynamicValue:refresh()\
    local stacks, newCachedValues = self.eq:resolveStacks( self.target, true ), {}\
    if stacks then\
        self.resolvedStacks = stacks\
        self:attach()\
\
        local stack\
        for i = 1, #stacks do\
            stack = stacks[ i ]\
            newCachedValues[ i ] = stack[ 2 ][ stack[ 1 ] ]\
        end\
    end\
\
    if self.target then\
        local reg = Titanium.getClass( self.target.__type ).getRegistry().constructor.argumentTypes\
        self.propertyType = reg[ self.property ]\
    end\
\
    self.resolvedStacks, self.cachedValues = stacks, newCachedValues\
    if stacks then self:solve() end\
end",
  [ "Projector.ti" ] = "--[[\
    @static modes - table (def. {}) - The registered modes\
\
    @instance application - Application (def. false) - The application the projector belongs to. Should not be manually adjusted.\
    @instance target - string (def. false) - The target of the projection (eg: the monitors to mirror to, separated by spaces: 'monitor_5 top')\
    @instance mode - string (def. false) - The projector mode to use (eg: 'monitor')\
    @instance mirrors - table (def. {}) - The attached mirrors (the nodes being projected to the targets via the mode specified)\
    @instance name - string (def. false) - The name of the projector. Used when selecting a projector on nodes\
\
    The Projector is a powerful class allowing for entire nodes to be mirrored to other sources (eg: monitors).\
\
    By default the projector comes with a 'monitor' mode. This allows nodes to be mirrored onto connected monitors while retaining functionality. View the projector\
    tutorial for more information regarding mirroring node content to external sources.\
]]\
\
class Projector extends Component {\
    static = {\
        modes = {}\
    };\
\
    application = false;\
\
    target = false;\
    mode = false;\
    mirrors = {};\
\
    name = false;\
}\
\
--[[\
    @constructor\
    @desc Instantiates the Projector instance, resolves properties and creates a blank Canvas.\
]]\
function Projector:__init__( ... )\
    self:resolve( ... )\
\
    self.canvas = TermCanvas( self )\
end\
\
--[[\
    @instance\
    @desc Updates the projector display by resolving the target (if not already resolved), clearing the canvas and drawing the mirror content to the canvas before projecting the canvas\
          to the projector targets\
]]\
function Projector:updateDisplay()\
    if not self.mode then\
        return error \"Failed to update projector display. No mode has been set on the Projector\"\
    elseif not self.target then\
        return error \"Failed to update projector display. No target has been set on the Projector\"\
    end\
\
    local mode = Projector.static.modes[ self.mode ]\
    if not self.resolvedTarget then\
        self.resolvedTarget = mode.targetResolver and mode.targetResolver( self, self.target ) or self.target\
    end\
\
    local canvas, mirrors, mirror = self.canvas, self.mirrors\
    canvas:clear()\
\
    for i = 1, #mirrors do\
        mirror = mirrors[ i ]\
        mirror.canvas:drawTo( canvas, mirror.projectX or mirror.X, mirror.projectY or mirror.Y )\
    end\
\
    mode.draw( self )\
end\
\
--[[\
    @instance\
    @desc Handles the event by dispatching the event to the modes eventDispatcher\
    @param <Event Instance - eventObj>\
]]\
function Projector:handleEvent( eventObj )\
    if not self.mode then\
        return error \"Failed to handle event. No mode has been set on the Projector\"\
    end\
\
    local eventDispatcher = Projector.static.modes[ self.mode ].eventDispatcher\
    if eventDispatcher then\
        eventDispatcher( self, eventObj )\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the target of the projector after checking the type is correct\
    @param <Any - target>\
]]\
function Projector:setTarget( target )\
    self.target = target\
    self.resolvedTarget = nil\
end\
\
--[[\
    @instance\
    @desc Attaches a mirror (MProjectable mixer) to the Projector\
    @param <Instance - mirror>\
]]\
function Projector:attachMirror( mirror )\
    local mirrors = self.mirrors\
    for i = 1, #mirrors do\
        if mirrors[ i ] == mirror then return end\
    end\
\
    mirrors[ #mirrors + 1 ] = mirror\
end\
\
--[[\
    @instance\
    @desc Removes the mirror from the Projector\
    @param <Instance - mirror>\
    @return <Instance - removedMirror> - If a mirror is removed it is returned\
]]\
function Projector:detachMirror( mirror )\
    local mirrors = self.mirrors\
    for i = 1, #mirrors do\
        if mirrors[ i ] == mirror then\
            return table.remove( mirrors, i )\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the mode of the projector and resets the resolved target\
    @param <string - mode>\
]]\
function Projector:setMode( mode )\
    local md = Projector.modes[ mode ]\
    if not md then\
        return error(\"Projector mode '\"..tostring( mode )..\" is invalid (doesn't exist)\")\
    end\
\
    self.mode = mode\
    self.resolvedTarget = nil\
\
    if type( md.init ) == \"function\" then\
        md.init( self )\
    end\
end\
\
--[[\
    @static\
    @desc Registers a projector mode. The given argumentTypes are used when setting variable to ensure valid data is provided.\
\
          The drawFunction is called, and has access to the current buffer. This buffer can then be 'drawn' using any method, such as\
          monitor draw functions, rednet, etc...\
\
          The 'config' table MUST contain 'draw (function)' and 'argumentTypes (table)' keys.\
    @param <table - config>\
]]\
function Projector.static.registerMode( config )\
    if not type( config ) == \"table\" then\
        return error \"Failed to register projector mode. Expected argument table (config)\"\
    elseif not ( type( config.mode ) == \"string\" and type( config.draw ) == \"function\" ) then\
        return error \"Failed to register projector mode. Expected config table to contain 'mode (string)' and 'draw (function)' keys\"\
    elseif Projector.modes[ mode ] then\
        return error( \"Failed to register projector mode. Mode '\"..tostring( mode ) ..\"' has already been registered\" )\
    end\
\
    Projector.modes[ config.mode ] = config\
end\
\
configureConstructor( {\
    orderedArguments = { \"name\", \"mode\", \"target\" },\
    requiredArguments = true,\
    argumentTypes = {\
        name = \"string\",\
        mode = \"string\"\
    },\
    useProxy = { \"mode\" }\
}, true )",
  [ "KeyEvent.ti" ] = "--[[\
    @instance main - string (def. \"KEY\") - The main type of the event, should remain unchanged\
    @instance sub - string (def. false) - The sub type of the event. If the key has been released (key_up), sub will be \"UP\", otherwise it will be \"DOWN\"\
    @instance keyCode - number (def. false) - The keycode that represents the key pressed\
    @instance keyName - string (def. false) - The name that represents the key pressed (keys.getName)\
    @instance held - boolean (def. nil) - If true, the event was fired as a result of the key being held\
]]\
\
class KeyEvent extends Event {\
    main = \"KEY\";\
\
    sub = false;\
\
    keyCode = false;\
    keyName = false;\
}\
\
function KeyEvent:__init__( name, key, held, sub )\
    self.name = name\
    self.sub = sub or name == \"key_up\" and \"UP\" or \"DOWN\"\
    self.held = held\
\
    self.keyCode = key\
    self.keyName = keys.getName( key )\
\
    self.data = { name, key, held }\
end",
  [ "versionCheck.lua" ] = "-- Check if CC version supports special characters\
if _HOST then\
    _CC_SPECIAL_CHAR_SUPPORT = true\
end",
  [ "MDynamic.ti" ] = "--[[\
    WIP\
]]\
\
abstract class MDynamic {\
    dynamicValues = {};\
}\
\
--[[\
    @instance\
    @desc Set the dynamic value instance to be used for that property (the property set on the DynamicValue instance).\
\
          The dynamic value instance provided is refreshed after setting (:refresh)\
\
          If not enableOverride, exception will be raised if a dynamic value for the property has already been set.\
    @param <DynamicValue Instance - dynamicValueInstance>, [boolean - enableOveride]\
]]\
function MDynamic:setDynamicValue( dynamicValueInstance, enableOverride )\
    if not Titanium.typeOf( dynamicValueInstance, \"DynamicValue\", true ) then\
        return error \"Failed to set dynamic value. Expected DynamicValue instance as argument #2\"\
    elseif dynamicValueInstance.target ~= self then\
        return error \"Failed to set dynamic value. DynamicValue instance provided belongs to another instance (target doesn't match this instance)\"\
    end\
\
    local property = dynamicValueInstance.property\
    if self.dynamicValues[ property ] then\
        if enableOverride then\
            self.dynamicValues[ property ]:detach()\
        else\
            return error(\"Failed to add dynamic value for property '\"..property..\"'. A dynamic value for this instance already exists\")\
        end\
    end\
\
    self.dynamicValues[ property ] = dynamicValueInstance\
    dynamicValueInstance:refresh()\
\
    self:executeCallbacks( \"dynamic-instance-set\", dynamicValueInstance )\
end\
\
--[[\
    @instance\
    @desc Removes the dynamic value instance set for the property provided if one is found.\
\
          If one can be found, it is detached from the target and removed from this register.\
    @return <boolean - removed>\
]]\
function MDynamic:removeDynamicValue( property )\
    local dynamicValues = self.dynamicValues\
    local dyn = dynamicValues[ property ]\
    if dyn then\
        dyn:detach()\
        dynamicValues[ property ] = nil\
\
        self:executeCallbacks( \"dynamic-instance-unset\", property, dyn )\
\
        return true\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Iterates over every dynamic value and detaches them from their target\
]]\
function MDynamic:detachDynamicValues()\
    for _, instance in pairs( self.dynamicValues ) do\
        instance:detach()\
    end\
end\
\
--[[\
    @instance\
    @desc Finds the dynamic value instance for the property provided and detaches it from it's target\
    @param <string - property>\
]]\
function MDynamic:detachDynamicValue( property )\
    local dyn = self.dynamicValues[ property ]\
    if dyn then\
        dyn:detach()\
    end\
end\
\
--[[\
    @instance\
    @desc Iterates over every dynamic value and attaches them to their targets\
]]\
function MDynamic:refreshDynamicValues( noChildren )\
    for _, instance in pairs( self.dynamicValues ) do\
        instance:refresh()\
    end\
\
    if not noChildren and self.collatedNodes then\
        local nodes = self.collatedNodes\
\
        for i = 1, #nodes do\
            nodes[ i ]:refreshDynamicValues()\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Finds the dynamic value instance for the property provided and attached it to it's target\
    @param <string - property>\
]]\
function MDynamic:refreshDynamicValue( property )\
    local dyn = self.dynamicValues[ property ]\
    if dyn then\
        dyn:attach()\
    end\
end",
  [ "Event.ti" ] = "--[[\
    @static matrix - table (def. {}) - A table of eventName -> eventClass conversions (ie: mouse_click -> MouseEvent). Add custom events here to have them spawn a selected class.\
\
    @instance name - string (def. nil) - The name of the event\
    @instance data - table (def. nil) - A table containing all details of the event\
    @instance handled - boolean (def. false) - If true, the event has been used and should be ignored by other nodes unless they want to act on used events\
]]\
\
abstract class Event {\
    static = {\
        matrix = {}\
    }\
}\
\
--[[\
    @instance\
    @desc Returns true if the event name (index '1' of data) matches the parameter 'event' provided\
    @param <string - event>\
    @return <boolean - eq>\
]]\
function Event:is( event )\
    return self.name == event\
end\
\
--[[\
    @setter\
    @desc Sets the 'handled' parameter to true. This indicates the event has been used and should not be used.\
    @param <boolean - handled>\
]]\
function Event:setHandled( handled )\
    self.raw.handled = handled\
end\
\
--[[\
    @static\
    @desc Instantiates an event object if an entry for that event type is present inside the event matrix.\
    @param <string - eventName>, [... - eventData]\
    @return <Instance*>\
\
    *Note: The type of instance is variable. If an entry is present inside the matrix that class will be\
           instantiated, otherwise a 'GenericEvent' instance will be returned.\
]]\
function Event.static.spawn( name, ... )\
    return ( Event.matrix[ name ] or GenericEvent )( name, ... )\
end\
\
--[[\
    @static\
    @desc Adds an entry to the event matrix. When an event named 'name' is caught, the class 'clasType' will be instantiated\
    @param <string - name>, <string - classType>\
]]\
function Event.static.bindEvent( name, classType )\
    Event.matrix[ name ] = Titanium.getClass( classType ) or error( \"Class '\"..tostring( classType )..\"' cannot be found\" )\
end\
\
--[[\
    @static\
    @desc Removes an entry from the event matrix.\
    @param <string - name>\
]]\
function Event.static.unbindEvent( name )\
    Event.matrix[ name ] = nil\
end",
  [ "NodeQuery.ti" ] = "local function format( original, symbol, final )\
    local wrapper = type( original ) == \"string\" and '\"' or \"\"\
    local finalWrapper = type( final ) == \"string\" and '\"' or \"\"\
\
    return (\"return %s%s%s %s %s%s%s\"):format( wrapper, tostring( original ), wrapper, symbol, finalWrapper, tostring( final ), finalWrapper )\
end\
\
local function testCondition( node, condition )\
    local fn, err = loadstring( format( node[ condition.property ], condition.symbol, condition.value ) )\
    if fn then return fn() end\
\
    return fn()\
end\
\
local function queryScope( scope, section, results )\
    local last = {}\
\
    local node\
    for i = 1, #scope do\
        node = scope[ i ]\
\
        if ( not section.id or node.id == section.id ) and\
        ( not section.type or section.type == \"*\" or ( section.ambiguous and Titanium.typeOf( node, section.type ) or node.__type == section.type ) ) and\
        ( not section.classes or node:hasClass( section.classes ) ) then\
            local condition, failed = section.condition\
            if condition then\
                local conditionPart\
                for c = 1, #condition do\
                    if not testCondition( node, condition[ c ] ) then\
                        failed = true\
                        break\
                    end\
                end\
            end\
\
            if not failed then\
                last[ #last + 1 ] = node\
            end\
        end\
    end\
\
    return last\
end\
\
local function createScope( results, direct )\
    local scope = {}\
    for i = 1, #results do\
        local innerScope = direct and results[ i ].nodes or results[ i ].collatedNodes\
\
        for r = 1, #innerScope do\
            scope[ #scope + 1 ] = innerScope[ r ]\
        end\
    end\
\
    return scope\
end\
\
local function performQuery( query, base )\
    local lastResults, section = base\
\
    for i = 1, #query do\
        section = query[ i ]\
        lastResults = queryScope( createScope( lastResults, section.direct ), section )\
    end\
\
    return lastResults\
end\
\
--[[\
    @static supportedMethods - table (def. { ... }) - Methods inside the table are automatically implemented on NodeQuery instances at instantiation. When called, the method is executed on all nodes in the result set with all arguments being passed\
    @instance result - table (def. false) - All nodes that matched the query\
    @instance parent - Instance (def. false) - The Titanium instance that the NodeQuery will begin searching at\
]]\
\
class NodeQuery {\
    static = { supportedMethods = { \"addClass\", \"removeClass\", \"setClass\", \"set\", \"animate\", \"on\", \"off\" } };\
    result = false;\
\
    parent = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs the NodeQuery instance by parsing 'queryString' and executing the query.\
\
          Supported methods configured via NodeQuery.static.supportedMethods are then implemented on the instance.\
]]\
function NodeQuery:__init__( parent, queryString )\
    if not ( Titanium.isInstance( parent ) and type( queryString ) == \"string\" ) then\
        return error \"Node query requires Titanium instance and string query\"\
    end\
    self.parent = parent\
\
    self.parsedQuery = QueryParser( queryString ).query\
    self.result = self:query()\
\
    local sup = NodeQuery.supportedMethods\
    for i = 1, #sup do\
        self[ sup[ i ] ] = function( self, ... ) self:executeOnNodes( sup[ i ], ... ) end\
    end\
end\
\
--[[\
    @static\
    @desc Returns a table containing the nodes matching the conditions set in 'query'\
    @return <table - results>\
]]\
function NodeQuery:query()\
    local query, results = self.parsedQuery, {}\
    if type( query ) ~= \"table\" then return error( \"Cannot perform query. Invalid query object passed\" ) end\
\
    local parent = { self.parent }\
    for i = 1, #query do\
        local res = performQuery( query[ i ], parent )\
\
        for r = 1, #res do\
            results[ #results + 1 ] = res[ r ]\
        end\
    end\
\
    return results\
end\
\
--[[\
    @instance\
    @desc Returns true if the class 'class' exists on all nodes in the result set, false otherwise\
    @param <table|string - class>\
    @return <boolean - hasClass>\
]]\
function NodeQuery:hasClass( class )\
    local nodes = self.result\
    for i = 1, #nodes do\
        if not nodes[ i ]:hasClass( class ) then\
            return false\
        end\
    end\
\
    return true\
end\
\
--[[\
    @instance\
    @desc The function 'fn' will be called once for each node in the result set, with the node being passed each time (essentially iterates over each node in the result set)\
    @param <function - fn>\
]]\
function NodeQuery:each( fn )\
    local nodes = self.result\
    for i = 1, #nodes do\
        fn( nodes[ i ] )\
    end\
end\
\
--[[\
    @instance\
    @desc Iterates over each node in the result set, calling 'fnName' with arguments '...' on each\
    @param <string - fnName>, [vararg - ...]\
]]\
function NodeQuery:executeOnNodes( fnName, ... )\
    local nodes, node = self.result\
    for i = 1, #nodes do\
        node = nodes[ i ]\
\
        if node:can( fnName ) then\
            node[ fnName ]( node, ... )\
        end\
    end\
end",
  [ "QueryParser.ti" ] = "local function parseValue( val )\
    if val == \"true\" then return true\
    elseif val == \"false\" then return false end\
\
    return tonumber( val ) or error(\"Invalid value passed for parsing '\"..tostring( val )..\"'\")\
end\
\
--[[\
    @instance query - table (def. nil) - The parsed query - only holds the query once parsing is complete\
\
    Parses the tokens from QueryLexer into a table containing the query\
]]\
\
class QueryParser extends Parser\
\
--[[\
    @constructor\
    @desc Invokes the Parser constructor, passing the tokens from QueryLexer\
    @param <string - queryString>\
]]\
function QueryParser:__init__( queryString )\
    self:super( QueryLexer( queryString ).tokens )\
end\
\
--[[\
    @instance\
    @desc The main parser. Iterates over all tokens generating the table containing the query (stored in self.query)\
]]\
function QueryParser:parse()\
    local allQueries, currentQuery, currentStep = {}, {}, {}\
\
    local nextStepDirect\
    local function advanceSection()\
        if next( currentStep ) then\
            table.insert( currentQuery, currentStep )\
            currentStep = { direct = nextStepDirect }\
\
            nextStepDirect = nil\
        end\
    end\
\
    local token = self:stepForward()\
    while token do\
        if token.type == \"QUERY_TYPEOF\" then\
            if currentStep.ambiguous then self:throw \"Attempted to set query section as 'ambiguous' using typeof operator (~). Already set as ambiguous (trailing ~)\" end\
            currentStep.ambiguous = true\
        elseif token.type == \"QUERY_TYPE\" then\
            if currentStep.type then self:throw( \"Attempted to set query type to '\"..token.value..\"' when already set as '\"..currentStep.type..\"'\" ) end\
\
            currentStep.type = token.value\
        elseif token.type == \"QUERY_CLASS\" then\
            if not currentStep.classes then currentStep.classes = {} end\
\
            table.insert( currentStep.classes, token.value )\
        elseif token.type == \"QUERY_ID\" then\
            if currentStep.id then self:throw( \"Attempted to set query id to '\"..token.value..\"' when already set as '\"..currentStep.id..\"'\" ) end\
\
            currentStep.id = token.value\
        elseif token.type == \"QUERY_SEPERATOR\" then\
            if self.tokens[ self.position + 1 ].type ~= \"QUERY_DIRECT_PREFIX\" then\
                advanceSection()\
            end\
        elseif token.type == \"QUERY_END\" then\
            advanceSection()\
\
            if next( currentQuery ) then\
                table.insert( allQueries, currentQuery )\
                currentQuery = {}\
            else\
                self:throw( \"Unexpected '\"..token.value..\"' found, no left hand query\" )\
            end\
        elseif token.type == \"QUERY_COND_OPEN\" then\
            currentStep.condition = self:parseCondition()\
        elseif token.type == \"QUERY_DIRECT_PREFIX\" and not nextStepDirect then\
            nextStepDirect = true\
        else\
            self:throw( \"Unexpected '\"..token.value..\"' found while parsing query\" )\
        end\
\
        token = self:stepForward()\
    end\
\
    advanceSection()\
    if next( currentQuery ) then\
        table.insert( allQueries, currentQuery )\
    end\
\
    self.query = allQueries\
end\
\
--[[\
    @instance\
    @desc Used to parse conditions inside the query. Called from ':parse'\
    @return <table - conditions> - If a valid condition was found\
]]\
function QueryParser:parseCondition()\
    local conditions, condition = {}, {}\
\
    local token = self:stepForward()\
    while true do\
        if token.type == \"QUERY_COND_ENTITY\" and ( condition.symbol or not condition.property ) then\
            condition[ condition.symbol and \"value\" or \"property\" ] = condition.symbol and parseValue( token.value ) or token.value\
        elseif token.type == \"QUERY_COND_STRING_ENTITY\" and condition.symbol then\
            condition.value = token.value\
        elseif token.type == \"QUERY_COND_SYMBOL\" and not condition.property and token.value == \"#\" then\
            condition.modifier = token.value\
        elseif token.type == \"QUERY_COND_SYMBOL\" and ( condition.property ) then\
            condition.symbol = token.value\
        elseif token.type == \"QUERY_COND_SEPERATOR\" and next( condition ) then\
            conditions[ #conditions + 1 ] = condition\
            condition = {}\
        elseif token.type == \"QUERY_COND_CLOSE\" and ( not condition.property or ( condition.property and condition.value ) ) then\
            break\
        else\
            self:throw( \"Unexpected '\"..token.value..\"' inside of condition block\" )\
        end\
\
        token = self:stepForward()\
    end\
\
    if next( condition ) then\
        conditions[ #conditions + 1 ] = condition\
    end\
\
    return #conditions > 0 and conditions or nil\
end",
  [ "MProjectable.ti" ] = "--[[\
    A mixin used by classes that require the ability to be projected to external sources.\
\
    @instance projectX - number (def. false) - The X location to be used when displaying the projected node, instead of the 'X' property.\
    @instance projectY - number (def. false) - The Y location to be used when displaying the projected node, instead of the 'Y' property.\
    @instance projector - string (def. false) - The name of the projector to use for projection\
    @instance mirrorProjector - boolean (def. false) - If true the node will appear on the parent AND the mirror. If false it will appear only on the projector IF a projector is set, or only the parent if no projector is set.\
]]\
\
abstract class MProjectable {\
    projectX = false;\
    projectY = false;\
\
    projector = false;\
    mirrorProjector = false;\
}\
\
--[[\
    @constructor\
    @desc Resolves the projector focus automatically whenever this instance is focused\
]]\
function MProjectable:MProjectable()\
    self:on(\"focus\", function( self, application )\
        self:resolveProjectorFocus()\
    end)\
end\
\
--[[\
    @instance\
    @desc Resolves the projector by fetching the projector (by name from MProjectorManager), attaching self as a mirror and resolving the focus\
]]\
function MProjectable:resolveProjector()\
    local app, p = self.application, self.projector\
    if app and p then\
        local res = app:getProjector( p )\
        self.resolvedProjector = res\
\
        if res then\
            res:attachMirror( self )\
            self:resolveProjectorFocus()\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Gets the the caret information for this node IF globally focused for each parent (relative location), and stores it on the projectors found\
]]\
function MProjectable:resolveProjectorFocus()\
    local app = self.application\
    local f = app and app.focusedNode\
    if app and f == self then\
        local last = self\
        while last do\
            if last.resolvedProjector then\
                last.resolvedProjector.containsFocus = { f:getCaretInfo( last ) }\
                last.resolvedProjector.changed = true\
            end\
\
            last = last.parent\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the projector for this instance, after detaching it from the previous (if any) projector\
    @param [Projector Instance - projector]\
]]\
function MProjectable:setProjector( projector )\
    if self.resolvedProjector then\
        -- Detach this object as a projector mirror\
        self.resolvedProjector:detachMirror( self )\
    end\
\
    self.projector = projector\
    self:resolveProjector()\
end\
\
--[[\
    @getter\
    @desc Gets the resolved projector, resolving the projector if not already resolved\
]]\
function MProjectable:getResolvedProjector()\
    if not self.projector then return end\
\
    if not self.resolvedProjector then\
        self:resolveProjector()\
    end\
\
    return self.resolvedProjector\
end\
\
configureConstructor {\
    argumentTypes = {\
        projectX = \"number\",\
        projectY = \"number\",\
\
        projector = \"string\",\
        mirrorProjector = \"boolean\"\
    }\
}",
  [ "Application.ti" ] = "--[[\
    @instance width - number (def. 51) - The applications width, defines the width of the canvas.\
    @instance height - number (def. 19) - The applications width, defines the height of the canvas.\
    @instance threads - table (def. {}) - The threads currently stored on the Application. Includes stopped threads (due to finish, or exception).\
    @instance timers - table (def. {}) - The currently running timers. Timers that have finished are removed from the table. Repeating timers are simply re-queued via :schedule.\
    @instance running - boolean (def. false) - The current state of the application loop. If false, the application loop will stop.\
    @instance terminatable - boolean (def. false) - If true, the application will exit (running = false) when the 'terminate' event is caught inside the event loop.\
    @instance focusedNode - Node (def. nil) - If present, contains the currently focused node. This node is used to determine the application caret information using :getCaretInfo.\
\
    An Application object is the entry point to a Titanium Application. The Application derives a lot of it's functionality from\
    it's mixins. However, application-wide node focusing, threads, timers, animations and the event loop are all handled by this class.\
\
    This is why it is considered the heart of a Titanium project - without it, the project would simply not run due to the lack of a yielding\
    event-loop.\
]]\
\
class Application extends Component mixin MThemeManager mixin MKeyHandler mixin MCallbackManager mixin MAnimationManager mixin MNodeContainer mixin MProjectorManager {\
    width = 51;\
    height = 19;\
\
    threads = {};\
    timers = {};\
\
    running = false;\
    terminatable = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs an instance of the Application by setting all necessary unique properties on it\
    @param [number - width], [number - height]\
    @return <nil>\
]]\
function Application:__init__( ... )\
    self:resolve( ... )\
    self.canvas = TermCanvas( self )\
\
    self:setMetaMethod(\"add\", function( a, b )\
        local t = a ~= self and a or b\
\
        if Titanium.typeOf( t, \"Node\", true ) then\
            return self:addNode( t )\
        elseif Titanium.typeOf( t, \"Thread\", true ) then\
            return self:addThread( t )\
        end\
\
        error \"Invalid targets for application '__add'. Expected node or thread.\"\
    end)\
end\
\
--[[\
    @instance\
    @desc Focuses the node provided application wide. The node will control the application caret and will have it's 'focused' property set to true\
          Also, the 'focus' callback will be called on the application, passing the node focused.\
    @param <Node Instance - node>\
]]\
function Application:focusNode( node )\
    if not Titanium.typeOf( node, \"Node\", true ) then\
        return error \"Failed to update application focused node. Invalid node object passed.\"\
    end\
\
    self:unfocusNode()\
    self.focusedNode = node\
    node.changed = true\
\
    local ps = self.projectors\
    for i = 1, #ps do\
        ps[ i ].containsFocus = false\
    end\
\
    node:executeCallbacks( \"focus\", self )\
end\
\
--[[\
    @instance\
    @desc If called with no arguments, the currently focused node will be unfocused, and the 'unfocus' callback will be executed\
\
          If called with the targetNode argument, the currently focused node will only be unfocused if it *is* that node. If the focused node\
          is NOT the targetNode, the function will return. If it is, it will be unfocused and the 'unfocus' callback executed.\
    @param [Node Instance - targetNode]\
]]\
function Application:unfocusNode( targetNode )\
    local node = self.focusedNode\
    if not node or ( targetNode ~= node ) then return end\
\
    self.focusedNode = nil\
\
    node.raw.focused = false\
    node.changed = true\
\
    node:executeCallbacks( \"unfocus\", self )\
end\
\
--[[\
    @instance\
    @desc Adds a new thread named 'name' running 'func'. This thread will receive events caught by the Application engine\
    @param <threadObj - Thread Instance>\
    @return [threadObj | error]\
]]\
function Application:addThread( threadObj )\
    if not Titanium.typeOf( threadObj, \"Thread\", true ) then\
        error( \"Failed to add thread, object '\"..tostring( threadObj )..\"' is invalid. Thread Instance required\")\
    end\
\
    table.insert( self.threads, threadObj )\
\
    return threadObj\
end\
\
--[[\
    @instance\
    @desc Removes the thread named 'name'*\
    @param <Thread Instance - target> - Used when removing the thread provided\
    @param <string - target> - Used when removing the thread using the name provided\
    @return <boolean - success>, [node - removedThread**]\
\
    *Note: In order for the thread to be removed its 'id' field must match the 'id' parameter.\
    **Note: Removed thread will only be returned if a thread was removed (and thus success 'true')\
]]\
function Application:removeThread( target )\
    if not Titanium.typeOf( target, \"Thread\", true ) then\
        return error( \"Cannot perform search for thread using target '\"..tostring( target )..\"'.\" )\
    end\
\
    local searchID = type( target ) == \"string\"\
    local threads, thread, threadID = self.threads\
    for i = 1, #threads do\
        thread = threads[ i ]\
\
        if ( searchID and thread.id == target ) or ( not searchID and thread == target ) then\
            thread:stop()\
\
            table.remove( threads, i )\
            return true, thread\
        end\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Ships events to threads, if the thread requires a Titanium event, that will be passed instead.\
    @param <AnyEvent - eventObj>, <vararg - eData>\
]]\
function Application:handleThreads( eventObj, ... )\
    local threads = self.threads\
\
    local thread\
    for i = 1, #threads do\
        thread = threads[ i ]\
\
        if thread.titaniumEvents then\
            thread:handle( eventObj )\
        else\
            thread:handle( ... )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Queues the execution of 'fn' after 'time' seconds.\
    @param <function - fn>, <number - time>, [boolean - repeating], [string - name]\
    @return <number - timerID>\
]]\
function Application:schedule( fn, time, repeating, name )\
    local timers = self.timers\
    if name then\
        self:unschedule( name )\
    end\
\
    local ID = os.startTimer( time ) --TODO: Use timer util to re-use timer IDs\
    self.timers[ ID ] = { fn, time, repeating, name }\
\
    return ID\
end\
\
--[[\
    @instance\
    @desc Unschedules the execution of a function using the name attached. If no name was assigned when scheduling, the timer cannot be cancelled using this method.\
    @param <string - name>\
    @return <boolean - success>\
]]\
function Application:unschedule( name )\
    local timers = self.timers\
    for timerID, timerDetails in next, timers do\
        if timerDetails[ 4 ] == name then\
            os.cancelTimer( timerID )\
            timers[ timerID ] = nil\
\
            return true\
        end\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Returns the position of the application, used when calculating the absolute position of a child node relative to the term object\
    @return <number - X>, <number - Y>\
]]\
function Application:getAbsolutePosition()\
    return self.X, self.Y\
end\
\
--[[\
    @instance\
    @desc Begins the program loop\
]]\
function Application:start()\
    self:restartAnimationTimer()\
    self.running = true\
    while self.running do\
        self:draw()\
        local event = { coroutine.yield() }\
        local eName = event[ 1 ]\
\
        if eName == \"timer\" then\
            local timerID = event[ 2 ]\
            if timerID == self.timer then\
                self:updateAnimations()\
            elseif self.timers[ timerID ] then\
                local timerDetails = self.timers[ timerID ]\
                if timerDetails[ 3 ] then\
                    self:schedule( unpack( timerDetails ) )\
                end\
\
                self.timers[ timerID ] = nil\
                timerDetails[ 1 ]( self, timerID )\
            end\
        elseif eName == \"terminate\" and self.terminatable then\
            printError \"Application Terminated\"\
            self:stop()\
        end\
\
        self:handle( unpack( event ) )\
    end\
end\
\
--[[\
    @instance\
    @desc Draws changed nodes (or all nodes if 'force' is true)\
    @param [boolean - force]\
]]\
function Application:draw( force )\
    if not self.changed and not force then return end\
\
    local canvas = self.canvas\
    local nodes, node = self.nodes\
\
    for i = 1, #nodes do\
        node = nodes[ i ]\
        if force or ( node.needsRedraw and node.visible ) then\
            node:draw( force )\
\
            if node.projector then\
                if node.mirrorProjector then\
                    node.canvas:drawTo( canvas, node.X, node.Y )\
                end\
\
                node.resolvedProjector.changed = true\
            else\
                node.canvas:drawTo( canvas, node.X, node.Y )\
            end\
\
            node.needsRedraw = false\
        end\
    end\
    self.changed = false\
\
    local focusedNode, caretEnabled, caretX, caretY, caretColour = self.focusedNode\
    if focusedNode then\
        focusedNode:resolveProjectorFocus()\
\
        if focusedNode:can \"getCaretInfo\" then\
            caretEnabled, caretX, caretY, caretColour = focusedNode:getCaretInfo()\
        end\
    end\
\
    term.setCursorBlink( caretEnabled or false )\
    canvas:draw( force )\
\
    if caretEnabled then\
        term.setTextColour( caretColour or self.colour or 32768 )\
        term.setCursorPos( caretX or 1, caretY or 1 )\
    end\
\
    self:updateProjectors()\
end\
\
--[[\
    @instance\
    @desc Spawns a Titanium event instance and ships it to nodes and threads.\
    @param <table - event>\
]]\
function Application:handle( eName, ... )\
    local eventObject = Event.spawn( eName, ... )\
    if eventObject.main == \"KEY\" then self:handleKey( eventObject ) end\
\
    local nodes, node = self.nodes\
    for i = #nodes, 1, -1 do\
        node = nodes[ i ]\
        -- The node will update itself depending on the event. Once all are updated they are drawn if changed.\
        if node then node:handle( eventObject ) end\
    end\
\
    self:executeCallbacks( eName, eventObject )\
    self:handleThreads( eventObject, eName, ... )\
end\
\
--[[\
    @instance\
    @desc Stops the program loop\
]]\
function Application:stop()\
    if self.running then\
        self.running = false\
        os.queueEvent( \"ti_app_close\" )\
    else\
        return error \"Application already stopped\"\
    end\
end",
  [ "MFocusable.ti" ] = "--[[\
    @instance focused - boolean (def. false) - If true, the node is focused. Certain events will be rejected by nodes when not focused (ie: text input events)\
\
    A focusable object is an object that after a mouse_click and a mouse_up event occur on the object is 'focused'.\
\
    An 'input' is a good example of a focusable node, it is activatable (while being clicked) but it also focusable (allows you to type after being focused).\
]]\
\
abstract class MFocusable {\
    focused = false;\
    passiveFocus = false;\
}\
\
--[[\
    @constructor\
    @desc If the instance mixes in MThemeable, the \"focused\", \"focusedColour\", and \"focusedBackgroundColour\" are all registered as theme properties\
]]\
function MFocusable:MFocusable()\
    if Titanium.mixesIn( self, \"MThemeable\" ) then\
        self:register(\"focused\", \"focusedColour\", \"focusedBackgroundColour\")\
    end\
end\
\
--[[\
    @setter\
    @desc Invokes the super setter, and unfocuses the node if it is disabled\
    @param <boolean - enabled>\
]]\
function MFocusable:setEnabled( enabled )\
    self.super:setEnabled( enabled )\
\
    if not enabled and self.focused then\
        self:unfocus()\
    end\
end\
\
--[[\
    @setter\
    @desc If the node's focused property is changed, the nodes 'changed' property is set and the focused property is updated\
    @param <boolean - focused>\
]]\
function MFocusable:setFocused( focused )\
    local raw = self.raw\
    if raw.focused == focused then return end\
\
    self.changed = true\
    self.focused = focused\
end\
\
--[[\
    @instance\
    @desc The preferred way of focusing a node. Sets the 'focused' property to true and focuses the node application wide\
]]\
function MFocusable:focus()\
    if not self.enabled then return end\
\
    if self.application and not self.passiveFocus then self.application:focusNode( self ) end\
    self.focused = true\
end\
\
--[[\
    @instance\
    @desc The preferred way of un-focusing a node. Sets the 'focused' property to false and un-focuses the node application wide\
]]\
function MFocusable:unfocus()\
    if self.application and not self.passiveFocus then self.application:unfocusNode( self ) end\
    self.focused = false\
end\
\
configureConstructor {\
    argumentTypes = {\
        focusedBackgroundColour = \"colour\",\
        focusedColour = \"colour\",\
        focused = \"boolean\"\
    }\
} alias {\
    focusedColor = \"focusedColour\",\
    focusedBackgroundColor = \"focusedBackgroundColour\"\
}",
  [ "TML.ti" ] = "--[[\
    @local\
    @desc Creates a table of arguments using the classes constructor configuration. This table is then unpacked (and the result returned)\
    @param <Class Base - class>, <table - target>\
    @return [var - args...]\
]]\
local function formArguments( class, target )\
    local reg = class:getRegistry()\
    local constructor, alias, args = reg.constructor, reg.alias, target.arguments\
    local req = constructor.requiredArguments or {}\
    local returnArguments, trailingTable, dynamics = {}, {}, {}\
\
    if not constructor then return nil end\
    local argumentTypes = constructor.argumentTypes\
\
    local function handleArgument( val, target )\
        if type( val ) ~= \"string\" then\
            return false\
        end\
\
        local escaped, rest = val:match \"^(%%*)%$(.*)$\"\
        if not escaped or #escaped % 2 ~= 0 then\
            return false\
        end\
\
        dynamics[ target ] = rest\
        return true\
    end\
\
    local ordered, set, target = constructor.orderedArguments, {}\
    for i = 1, #ordered do\
        target = ordered[ i ]\
        local argType = argumentTypes[ alias[ target ] or target ]\
\
        local val = args[ target ]\
        if val then\
            if handleArgument( val, target ) then\
                returnArguments[ i ] = argType == \"string\" and \"\" or ( ( argType == \"number\" or argType == \"colour\" ) and 1 or ( argType == \"boolean\" ) ) or error \"invalid argument type\"\
            else\
                returnArguments[ i ] = XMLParser.convertArgType( val, argType )\
            end\
        end\
\
        set[ ordered[ i ] ] = true\
    end\
\
    for argName, argValue in pairs( args ) do\
        if not set[ argName ] then\
            if not handleArgument( argValue, argName ) then\
                trailingTable[ argName ] = XMLParser.convertArgType( argValue, argumentTypes[ alias[ argName ] or argName ] )\
            end\
        end\
    end\
\
    if next( trailingTable ) then\
        returnArguments[ #ordered + 1 ] = trailingTable\
    end\
\
    return class( unpack( returnArguments, 1, next(trailingTable) and #ordered + 1 or #ordered ) ), dynamics\
end\
\
--[[\
    The TML class is used to parse an XML tree into Titanium nodes.\
]]\
\
class TML {\
    tree = false;\
    parent = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs the TML instance by storing the parent and tree on 'self' and then parsing the tree.\
    @param <Class Instance - parent>, <table - tree>\
]]\
function TML:__init__( parent, source )\
    self.parent = parent\
    self.tree = XMLParser( source ).tree\
\
    self:parseTree()\
end\
\
--[[\
    @instance\
    @desc Parses 'self.tree' by creating and adding node instances to their parents.\
]]\
function TML:parseTree()\
    local queue = { { self.parent, self.tree } }\
\
    local i, toSetup, parent, tree = 1, {}\
    while i <= #queue do\
        parent, tree = queue[ i ][ 1 ], queue[ i ][ 2 ]\
\
        local target\
        for t = 1, #tree do\
            target = tree[ t ]\
\
            if parent:can \"addTMLObject\" then\
                local obj, children = parent:addTMLObject( target )\
                if obj and children then\
                    table.insert( queue, { obj, children } )\
                end\
            else\
                local classArg = target.arguments[\"class\"]\
                if classArg then target.arguments[\"class\"] = nil end\
\
                local itemClass = Titanium.getClass( target.type ) or error( \"Failed to spawn XML tree. Failed to find class '\"..target.type..\"'\" )\
                if not Titanium.typeOf( itemClass, \"Node\" ) then\
                    error(\"Failed to spawn XML tree. Class '\"..target.type..\"' is not a valid node\")\
                end\
\
                local itemInstance, dynamics = formArguments( itemClass, target )\
                if classArg then\
                    itemInstance.classes = type( itemInstance.classes ) == \"table\" and itemInstance.classes or {}\
                    for className in classArg:gmatch \"%S+\" do\
                        itemInstance.classes[ className ] = true\
                    end\
                end\
\
                if target.children then\
                    table.insert( queue, { itemInstance, target.children } )\
                end\
\
                toSetup[ #toSetup + 1 ] = { itemInstance, dynamics }\
                if parent:can \"addNode\" then\
                    parent:addNode( itemInstance )\
                else\
                    return error(\"Failed to spawn XML tree. \"..tostring( parent )..\" cannot contain nodes.\")\
                end\
            end\
        end\
\
        i = i + 1\
    end\
\
    for i = 1, #toSetup do\
        local instance = toSetup[ i ][ 1 ]\
\
        for property, expression in pairs( toSetup[ i ][ 2 ] ) do\
            instance:setDynamicValue( DynamicValue( instance, property, expression ) )\
        end\
    end\
end\
\
--[[\
    @static\
    @desc Reads the data from 'path' and creates a TML instance with the contents as the source (arg #2)\
    @param <Class Instance - parent>, <string - path>\
    @return <TML Instance - instance>\
]]\
function TML.static.fromFile( parent, path )\
    if not Titanium.isInstance( parent ) then\
        return error \"Expected Titanium instance as first argument (parent)\"\
    end\
\
    if not fs.exists( path ) then return error( \"Path \"..tostring( path )..\" cannot be found\" ) end\
\
    local h = fs.open( path, \"r\" )\
    local content = h.readAll()\
    h.close()\
\
    return TML( parent, content )\
end",
  [ "MActivatable.ti" ] = "--[[\
    @instance active - boolean (def. false) - When a node is active, it uses active colours. A node should be activated before being focused.\
    @instance activeColour - colour (def. 1) - The foreground colour of the node used while the node is active\
    @instance activeBackgroundColour - colour (def. 512) - The background colour of the node used while the node is active\
\
    A mixin to reuse code commonly written when developing nodes that can be (de)activated.\
]]\
\
abstract class MActivatable {\
    active = false;\
\
    activeColour = colours.white;\
    activeBackgroundColour = colours.lightBlue;\
}\
\
--[[\
    @constructor\
    @desc Registers properties used by this class with the theme handler if the object mixes in 'MThemeable'\
]]\
function MActivatable:MActivatable()\
    if Titanium.mixesIn( self, \"MThemeable\" ) then\
        self:register( \"active\", \"activeColour\", \"activeBackgroundColour\" )\
    end\
end\
\
--[[\
    @instance\
    @desc Sets the 'active' property to the 'active' argument passed. When the 'active' property changes the node will become 'changed'.\
    @param <boolean - active>\
]]\
function MActivatable:setActive( active )\
    local raw = self.raw\
    if raw.active == active then return end\
\
    raw.active = active\
    self:queueAreaReset()\
end\
\
configureConstructor {\
    argumentTypes = { active = \"boolean\", activeColour = \"colour\", activeBackgroundColour = \"colour\" }\
} alias {\
    activeColor = \"activeColour\",\
    activeBackgroundColor = \"activeBackgroundColour\"\
}",
  [ "XMLLexer.ti" ] = "--[[\
    @instance openTag - boolean (def. false) - If true, the lexer is currently inside of an XML tag\
    @instance definingAttribute - boolean (def. false) - If true, the lexer is currently inside an opening XML tag and is trying to find attributes (XML_ATTRIBUTE_VALUE)\
    @instance currentAttribute - boolean (def. false) - If true, the lexer will take the next token as an attribute value (after '=')\
\
    A lexer than processes XML content into tokens used by XMLParser\
]]\
\
class XMLLexer extends Lexer {\
    openTag = false;\
    definingAttribute = false;\
    currentAttribute = false;\
}\
\
--[[\
    @instance\
    @desc Searches for a XML comment closer. If one is found, all content between the opener and closer is removed from the stream.\
\
          If one cannot be found, all content after the opener is removed from the stream\
]]\
function XMLLexer:consumeComment()\
    local stream = self.stream\
\
    local found = stream:find( \"%-%-%>\", 4 )\
    if found then\
        self.stream = stream:sub( found + 3 )\
    else self.stream = \"\" end\
end\
\
--[[\
    @instance\
    @desc Converts the stream into tokens by way of pattern matching\
]]\
function XMLLexer:tokenize()\
    self:trimStream()\
    local stream, openTag, currentAttribute, definingAttribute = self:trimStream(), self.openTag, self.currentAttribute, self.definingAttribute\
    local first = stream:sub( 1, 1 )\
\
    if stream:find \"^<(%w+)\" then\
        self:pushToken({type = \"XML_OPEN\", value = self:consumePattern \"^<(%w+)\"})\
        self.openTag = true\
    elseif stream:find \"^</(%w+)>\" then\
        self:pushToken({type = \"XML_END\", value = self:consumePattern \"^</(%w+)>\"})\
        self.openTag = false\
    elseif stream:find \"^/>\" then\
        self:pushToken({type = \"XML_END_CLOSE\"})\
        self:consume( 2 )\
        self.openTag = false\
    elseif stream:find \"^%<%!%-%-\" then\
        self:consumeComment()\
    elseif openTag and stream:find \"^%w+\" then\
        self:pushToken({type = definingAttribute and \"XML_ATTRIBUTE_VALUE\" or \"XML_ATTRIBUTE\", value = self:consumePattern \"^%w+\"})\
\
        if not definingAttribute then\
            self.currentAttribute = true\
            return\
        end\
    elseif not openTag and stream:find \"^([^<]+)\" then\
        local content = self:consumePattern \"^([^<]+)\"\
\
        local newlines = select( 2, content:gsub(\"\\n\", \"\") )\
        if newlines then self:newline( newlines ) end\
\
        self:pushToken({type = \"XML_CONTENT\", value = content })\
    elseif first == \"=\" then\
        self:pushToken({type = \"XML_ASSIGNMENT\", value = \"=\"})\
        self:consume( 1 )\
\
        if currentAttribute then\
            self.definingAttribute = true\
        end\
\
        return\
    elseif first == \"'\" or first == \"\\\"\" then\
        self:pushToken({type = definingAttribute and \"XML_STRING_ATTRIBUTE_VALUE\" or \"XML_STRING\", value = self:consumeString( first )})\
    elseif first == \">\" then\
        self:pushToken({type = \"XML_CLOSE\"})\
        self.openTag = false\
        self:consume( 1 )\
    else\
        self:throw(\"Unexpected block '\"..stream:match(\"(.-)%s\")..\"'\")\
    end\
\
    if self.currentAttribute then self.currentAttribute = false end\
    if self.definingAttribute then self.definingAttribute = false end\
end",
  [ "RedirectCanvas.ti" ] = "local stringLen, stringSub = string.len, string.sub\
local isColour = term.isColour()\
\
local function testColour( col )\
    if not isColour and ( col ~= 1 or col ~= 32768 or col ~= 256 or col ~= 128 ) then\
        error \"Colour not supported\"\
    end\
\
    return true\
end\
\
--[[\
    @instance tX - number (def. 1) - The X position of the terminal redirect, controlled from inside the redirect itself\
    @instance tY - number (def. 1) - The Y position of the terminal redirect, controlled from inside the redirect itself\
    @instance tColour - number (def. 1) - The current colour of the terminal redirect, controlled from inside the redirect itself\
    @instance tBackgroundColour - number (def. 32768) - The current background colour of the terminal redirect, controlled from inside the redirect itself\
    @instance tCursor - boolean (def. false) - The current cursor state of the terminal redirect (true for blinking, false for hidden), controlled from inside the redirect itself\
\
    The RedirectCanvas is a class to be used by nodes that wish to redirect the term object. This canvas provides a terminal redirect and keeps track\
    of the terminals properties set inside the wrapped program (via the term methods).\
\
    This allows emulation of a shell program inside of Titanium without causing visual issues due to the shell program drawing directly to the terminal and not\
    through Titaniums canvas system.\
]]\
\
class RedirectCanvas extends NodeCanvas\
\
--[[\
    @constructor\
    @desc Resets the terminal redirect, before running the super constructor\
]]\
function RedirectCanvas:__init__( ... )\
    self:resetTerm()\
    self:super( ... )\
end\
\
--[[\
    @instance\
    @desc Resets the terminal redirect by setting tX, tY, tColour, tBackgroundColour, and tCursor back to default before clearing the canvas\
]]\
function RedirectCanvas:resetTerm()\
    self.tX, self.tY, self.tColour, self.tBackgroundColour, self.tCursor = 1, 1, 1, 32768, false;\
    self:clear( 32768, true )\
end\
\
--[[\
    @instance\
    @desc Returns a table compatible with `term.redirect`\
    @return <table - redirect>\
]]\
function RedirectCanvas:getTerminalRedirect()\
    local redirect = {}\
\
    function redirect.write( text )\
        text = tostring( text )\
        local tc, bg, tX, tY = self.tColour, self.tBackgroundColour, self.tX, self.tY\
        local buffer, position = self.buffer, self.width * ( tY - 1 ) + tX\
\
        for i = 1, math.min( stringLen( text ), self.width - tX + 1 ) do\
            buffer[ position ] = { stringSub( text, i, i ), tc, bg }\
            position = position + 1\
        end\
\
        self.tX = tX + stringLen( text )\
    end\
\
    function redirect.blit( text, colour, background )\
        if stringLen( text ) ~= stringLen( colour ) or stringLen( text ) ~= stringLen( background ) then\
            return error \"blit arguments must be the same length\"\
        end\
\
        local tX, hex = self.tX, TermCanvas.static.hex\
        local buffer, position = self.buffer, self.width * ( self.tY - 1 ) + tX\
\
        for i = 1, math.min( stringLen( text ), self.width - tX + 1 ) do\
            buffer[ position ] = { stringSub( text, i, i ), hex[ stringSub( colour, i, i ) ], hex[ stringSub( background, i, i ) ] }\
            position = position + 1\
        end\
\
        self.tX = tX + stringLen( text )\
    end\
\
    function redirect.clear()\
        self:clear( self.tBackgroundColour, true )\
    end\
\
    function redirect.clearLine()\
        local px = { \" \", self.tColour, self.tBackgroundColour }\
        local buffer, position = self.buffer, self.width * ( self.tY - 1 )\
\
        for i = 1, self.width do\
            buffer[ position ] = px\
            position = position + 1\
        end\
    end\
\
    function redirect.getCursorPos()\
        return self.tX, self.tY\
    end\
\
    function redirect.setCursorPos( x, y )\
        self.tX, self.tY = math.floor( x ), math.floor( y )\
    end\
\
    function redirect.getSize()\
        return self.width, self.height\
    end\
\
    function redirect.setCursorBlink( blink )\
        self.tCursor = blink\
    end\
\
    function redirect.setTextColour( tc )\
        if testColour( tc ) then\
            self.tColour = tc\
        end\
    end\
\
    function redirect.getTextColour()\
        return self.tColour\
    end\
\
    function redirect.setBackgroundColour( bg )\
        if testColour( bg ) then\
            self.tBackgroundColour = bg\
        end\
    end\
\
    function redirect.getBackgroundColour()\
        return self.tBackgroundColour\
    end\
\
    function redirect.scroll( n )\
        local offset, buffer, nL = self.width * n, self.buffer, n < 0\
        local pixelCount, blank = self.width * self.height, { \" \", self.tColour, self.tBackgroundColour }\
\
        for i = nL and pixelCount or 1, nL and 1 or pixelCount, nL and -1 or 1 do\
            buffer[ i ] = buffer[ i + offset ] or blank\
        end\
    end\
\
    function redirect.isColour()\
        return isColour\
    end\
\
    -- American spelling compatibility layer\
    redirect.isColor = redirect.isColour\
\009redirect.setBackgroundColor = redirect.setBackgroundColour\
\009redirect.setTextColor = redirect.setTextColour\
\009redirect.getBackgroundColor = redirect.getBackgroundColour\
\009redirect.getTextColor = redirect.getTextColour\
\
    return redirect\
end\
\
--[[\
    @instance\
    @desc Modified Canvas.clear. Only sets pixels that do not exist (doesn't really clear the canvas, just ensures it is the correct size).\
          This is to prevent the program running via the term redirect isn't cleared away. Call this function with 'force' and all pixels will be\
          replaced (the terminal redirect uses this method).\
\
          Alternatively, self:getTerminalRedirect().clear() will also clear the canvas entirely\
    @param [number - col], [boolean - force]\
]]\
function RedirectCanvas:clear( col, force )\
    local col = col or self.tBackgroundColour\
    local pixel, buffer = { \" \", col, col }, self.buffer\
\
    for index = 1, self.width * self.height do\
        if not buffer[ index ] or force then\
            buffer[ index ] = pixel\
        end\
    end\
end",
  [ "DynamicEqLexer.ti" ] = "--[[\
    A lexer that processes dynamic value equations into tokens used by DynamicEqParser\
]]\
\
class DynamicEqLexer extends Lexer\
\
--[[\
    @instance\
    @desc Finds a valid number in the current stream. Returns 'true' if one was found, 'nil' otherwise\
    @return <boolean - true> - Found a valid Lua number\
]]\
function DynamicEqLexer:lexNumber()\
    local stream = self:trimStream()\
    local exp, following = stream:match \"^%d*%.?%d+(e)([-+]?%d*)\"\
\
    if exp and exp ~= \"\" then\
        if following and following ~= \"\" then\
            self:pushToken { type = \"NUMBER\", value = self:consumePattern \"^%d*%.?%d+e[-+]?%d*\" }\
            return true\
        else self:throw \"Invalid number. Expected digit after 'e'\" end\
    elseif stream:find \"^%d*%.?%d+\" then\
        self:pushToken { type = \"NUMBER\", value = self:consumePattern \"^%d*%.?%d+\" }\
        return true\
    end\
end\
\
--[[\
    @instance\
    @desc The main token creator\
]]\
function DynamicEqLexer:tokenize()\
    local stream = self:trimStream()\
    local first = stream:sub( 1, 1 )\
\
    if stream:find \"^%b{}\" then\
        self:pushToken { type = \"QUERY\", value = self:consumePattern \"^%b{}\" }\
    elseif not self:lexNumber() then\
        if first == \"'\" or first == '\"' then\
            self:pushToken { type = \"STRING\", value = self:consumeString( first ), surroundedBy = first }\
        elseif stream:find \"^and\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^and\", binary = true }\
        elseif stream:find \"^or\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^or\", binary = true }\
        elseif stream:find \"^not\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^not\", unary = true }\
        elseif stream:find \"^[#]\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^[#]\", unary = true }\
        elseif stream:find \"^[/%*%%]\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^[/%*%%]\", binary = true }\
        elseif stream:find \"^%.%.\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^%.%.\", binary = true }\
        elseif stream:find \"^%=%=\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^%=%=\", binary = true }\
        elseif stream:find \"^%>\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^%>\", binary = true }\
        elseif stream:find \"^%<\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^%<\", binary = true }\
        elseif stream:find \"^[%+%-]\" then\
            self:pushToken { type = \"OPERATOR\", value = self:consumePattern \"^[%+%-]\", ambiguos = true }\
        elseif stream:find \"^[%(%)]\" then\
            self:pushToken { type = \"PAREN\", value = self:consumePattern \"^[%(%)]\" }\
        elseif stream:find \"^%.\" then\
            self:pushToken { type = \"DOT\", value = self:consumePattern \"^%.\" }\
        elseif stream:find \"^%w+\" then\
            self:pushToken { type = \"NAME\", value = self:consumePattern \"^%w+\" }\
        else\
            self:throw(\"Unexpected block '\".. ( stream:match( \"%S+\" ) or \"\" ) ..\"'\")\
        end\
    end\
end",
  [ "Image.ti" ] = "local function getFileExtension( path )\
    return path:match \".+%.(.-)$\" or \"\"\
end\
\
--[[\
    @static imageParsers - table (def. {}) - The parses available for use (extension based)\
    @instance path - string (def. false) - The image path\
\
    A basic class that will load the image at the path provided and display it\
]]\
class Image extends Node {\
    static = { imageParsers = {} };\
    path = false;\
}\
\
--[[\
    @constructor\
    @desc Resolves instance arguments\
]]\
function Image:__init__( ... )\
    self:super()\
    self:resolve( ... )\
end\
\
--[[\
    @instance\
    @desc Depending on the file extension (self.path), an image parser will be called.\
          To add support for more extensions, simply add the function to the classes static ( Image.static.addParser( extension, function ) )\
]]\
function Image:parseImage()\
    local path = self.path\
    if type( path ) ~= \"string\" then\
        return error(\"Failed to parse image, path '\"..tostring( path )..\"' is invalid\")\
    elseif not fs.exists( path ) or fs.isDir( path ) then\
        return error(\"Failed to parse image, path '\"..path..\"' is invalid and cannot be opened for parsing\")\
    end\
\
    local ext = getFileExtension( path )\
    if not Image.imageParsers[ ext ] then\
        return error(\"Failed to parse image, no image parser exists for \" .. ( ext == \"\" and \"'no ext'\" or \"'.\" .. ext .. \"'\" ) .. \" files for '\"..path..\"'\")\
    end\
\
    local f = fs.open( path, \"r\" )\
    local stream = f.readAll()\
    f.close()\
\
    local width, height, pixels = Image.imageParsers[ ext ]( stream )\
    for y = 1, height do\
        local pos = ( y - 1 ) * width\
        for x = 1, width do\
            local posX = pos + x\
            self.canvas.buffer[ posX ] = pixels[ posX ] or { \" \" }\
        end\
    end\
\
    self.width, self.height = width, height\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Sets the path of the image and parses the file\
    @param <string - path>\
]]\
function Image:setPath( path )\
    self.path = path\
    self:parseImage()\
end\
\
--[[\
    @static\
    @desc Sets the parser (function) to be used for the extension provided\
    @param <string - extension>, <function - parserFunction>\
]]\
function Image.static.setImageParser( extension, parserFunction )\
    if type( extension ) ~= \"string\" or type( parserFunction ) ~= \"function\" then\
        return error \"Failed to set image parser. Invalid arguments, expected string, function\"\
    end\
\
    Image.static.imageParsers[ extension ] = parserFunction\
\
    return Image\
end\
\
function Image:draw() end\
configureConstructor {\
    orderedArguments = { \"path\" },\
    requiredArguments = { \"path\" },\
    useProxy = { \"path\" },\
    argumentTypes = {\
        path = \"string\"\
    }\
}",
  [ "PageContainer.ti" ] = "--[[\
    The PageContainer serves as a container that shows one 'page' at a time. Preset (or completely custom) animated transitions can be used when\
    a new page is selected.\
]]\
\
class PageContainer extends Container {\
    scroll = 0;\
\
    animationDuration = 0.25;\
    animationEasing = \"outQuad\";\
    customAnimation = false;\
    selectedPage = false;\
}\
\
--[[\
    @instance\
    @desc Intercepts the draw call, adding the x scroll to the x offset\
    @param [boolean - force], [number - offsetX], [number - offsetY]\
]]\
function PageContainer:draw( force, offsetX, offsetY )\
    if not self.selectedPage then\
        self.canvas:drawTextLine( 1, 1, \"No page selected\", 16384, 1 )\
    else\
        return self.super:draw( force, ( offsetX or 0 ) - self.scroll, offsetY )\
    end\
end\
\
--[[\
    @instance\
    @desc If a MOUSE event is handled, it's X co-ordinate is adjusted using the scroll offset of the page container.\
    @param <Event Instance - eventObj>\
    @return <boolean - propagate>\
]]\
function PageContainer:handle( eventObj )\
    if not self.super.super:handle( eventObj ) then return end\
\
    local clone\
    if eventObj.main == \"MOUSE\" then\
        clone = eventObj:clone( self )\
        clone.X = clone.X + self.scroll\
        clone.isWithin = clone.isWithin and eventObj:withinParent( self ) or false\
    end\
\
    self:shipEvent( clone or eventObj )\
    if clone and clone.isWithin and ( self.consumeAll or clone.handled ) then\
        eventObj.handled = true\
    end\
    return true\
end\
\
--[[\
    @instance\
    @desc Selects the new page using the 'pageID'. If a function is given as argument #2 'animationOverride', it will be called instead of the customAnimation\
          set (or the default animation method used).\
\
          Therefore the animationOverride is given full control of the transition, allowing for easy one-off transition effects.\
\
          If 'customAnimation' is set on the instance, it will be called if no 'animationOverride' is provided, providing a more long term override method.\
\
          If neither are provided, a normal animation will take place, using 'animationDuration' and 'animationEasing' set on the instance as parameters for the animation.\
    @param <string - pageID>, [function - animationOverride]\
]]\
function PageContainer:selectPage( pageID, animationOverride )\
    local page = self:getPage( pageID )\
\
    self.selectedPage = page\
    if type( animationOverride ) == \"function\" then\
        return animationOverride( self.currentPage, page )\
    elseif self.customAnimation then\
        return self.customAnimation( self.currentPage, page )\
    end\
\
    self:animate( self.__ID .. \"_PAGE_CONTAINER_SELECTION\", \"scroll\", page.X - 1, self.animationDuration, self.animationEasing )\
end\
\
--[[\
    @instance\
    @desc Updates 'resolvedPosition' on pages without a specific 'position'.\
]]\
function PageContainer:updatePagePositions()\
    local pages, usedIndexes = self.nodes, {}\
    for i = 1, #pages do\
        local page = pages[ i ]\
\
        local pagePosition = page.position\
        if pagePosition and not page.isPositionTemporary then\
            usedIndexes[ pagePosition ] = true\
        end\
    end\
\
    local currentIndex = 0\
    for i = 1, #pages do\
        local page = pages[ i ]\
        if not page.position or page.isPositionTemporary then\
            repeat\
                currentIndex = currentIndex + 1\
            until not usedIndexes[ currentIndex ]\
\
            page.isPositionTemporary = true\
            page.raw.position = currentIndex\
        end\
\
        page:updatePosition()\
    end\
end\
\
--[[\
    @instance\
    @desc Ensures the node being added to the PageContainer is a 'Page' node because no other nodes should be added directly to this node\
    @param <Page Instance - node>\
    @return <Page Instance - node>\
]]\
function PageContainer:addNode( node )\
    if Titanium.typeOf( node, \"Page\", true ) then\
        local pgInd = self.pageIndexes\
        if self:getPage( node.id ) then\
            return error(\"Cannot add page '\"..tostring( node )..\"'. Another page with the same ID already exists inside this PageContainer\")\
        end\
\
        self.super:addNode( node )\
        self:updatePagePositions()\
        return node\
    end\
\
    return error(\"Only 'Page' nodes can be added as direct children of 'PageContainer' nodes, '\"..tostring( node )..\"' is invalid\")\
end\
\
--[[\
    @instance\
    @desc An alias for 'addNode', contextualized for the PageContainer\
    @param <Page Instance - page>\
    @return 'param1 (page)'\
]]\
function PageContainer:addPage( page )\
    return self:addNode( page )\
end\
\
--[[\
    @instance\
    @desc An alias for 'getNode', contextualized for the PageContainer\
    @param <string - id>, [boolean - recursive]\
    @return [Node Instance - node]\
]]\
function PageContainer:getPage( ... )\
    return self:getNode( ... )\
end\
\
--[[\
    @instance\
    @desc An alias for 'removeNode', contextualized for the PageContainer\
    @param <Node Instance | string - id>\
    @return <boolean - success>, [node - removedNode]\
]]\
function PageContainer:removePage( ... )\
    return self:removeNode( ... )\
end\
\
--[[\
    @instance\
    @desc Shifts requests to clear the PageContainer area to the left, depending on the scroll position of the container\
    @param <number - x>, <number - y>, <number - width>, <number - height>\
]]\
function PageContainer:redrawArea( x, y, width, height )\
    self.super:redrawArea( x - self.scroll, y, width, height, -self.scroll )\
end\
\
--[[\
    @setter\
    @desc Due to the contents of the PageContainer not actually moving (just the scroll), the content of the PageContainer must be manually cleared.\
          To fit this demand, the area of the PageContainer is cleared when the scroll parameter is changed.\
]]\
function PageContainer:setScroll( scroll )\
    self.scroll = scroll\
    self.changed = true\
    self:redrawArea( 1, 1, self.width, self.height )\
end\
\
--[[\
    @setter\
    @desc Sets the page containers width, updates the page positions and adjusts the scroll to match that of the selected page\
    @param <number - width>\
]]\
function PageContainer:setWidth( width )\
    self.super:setWidth( width )\
    self:updatePagePositions()\
\
    if self.selectedPage then self.scroll = self.selectedPage.X - 1 end\
end\
\
--[[\
    @setter\
    @desc Sets the page containers height, updates the page positions and adjusts the scroll to match that of the selected page\
    @param <number - height>\
]]\
function PageContainer:setHeight( height )\
    self.super:setHeight( height )\
    self:updatePagePositions()\
\
    if self.selectedPage then self.scroll = self.selectedPage.X - 1 end\
end\
\
configureConstructor {\
    argumentTypes = {\
        animationDuration = \"number\",\
        animationEasing = \"string\",\
        customAnimation = \"function\",\
        selectedPage = \"string\"\
    }\
}",
  [ "Slider.ti" ] = "--[[\
    @instance trackCharacter - string (def. \"\\140\") - The character used when drawing the slider track\
    @instance trackColour - colour (def. 128) - The colour used when drawing the slider track\
    @instance slideCharacter - string (def. \" \") - The character(s) used as the slider knob text\
    @instance slideBackgroundColour - colour (def. 512) - The background colour of the slider knob\
\
    @instance track - Label Instance (def. nil) - The label used to hold the slider track. Created at instantiation and can be customized at will.\
    @instance slide - Button Instance (def. nil) - The button used as the slider control knob. Created at instantiation and can be customized at will.\
\
    @instance value - number (def. 1) - The value of slider, controls the X position of the slider knob.\
\
    A basic node that provides a sliding knob on a track. The knob, when slid along the track (click and drag) will\
    change the 'value' of the slider instance.\
]]\
\
class Slider extends Container {\
    trackCharacter = _CC_SPECIAL_CHAR_SUPPORT and \"\\140\" or \"-\";\
    trackColour = 128;\
\
    slideCharacter = \" \";\
    slideBackgroundColour = colours.cyan;\
\
    value = 1;\
}\
\
--[[\
    @constructor\
    @desc Constructs the Slider instance by registering properties for theming, and creating the slider track and control. See 'Container' for instance arguments\
]]\
function Slider:__init__( ... )\
    self:super( ... )\
    self:register( \"value\", \"trackCharacter\", \"trackColour\", \"slideCharacter\", \"slideBackgroundColour\" )\
\
    self.track = self:addNode( Label( self.trackCharacter:rep( self.width ) ) ):set( \"colour\", \"$parent.trackColour\" )\
    self.slide = self:addNode( Button( self.slideCharacter ) ):set {\
        backgroundColour = \"$parent.slideBackgroundColour\";\
        X = \"$parent.value\";\
    }\
end\
\
--[[\
    @instance\
    @desc When a mouse drag occurs and the control knob is active, the value is changed to match that of the mouse drag location. This slides the control across the track.\
    @param <MouseEvent Instance - eventObj>, <boolean - handled>, <boolean - within>\
]]\
function Slider:onMouseDrag( eventObj, handled, within )\
    local slide = self.slide\
    if handled or not slide.active then return end\
\
    local value = math.max( 1, math.min( eventObj.X - self.X + 1, self.width ) )\
\
    self.value = value\
    self:executeCallbacks( \"change\", value )\
\
    eventObj.handled = true\
end\
\
--[[\
    @instance\
    @desc The slider control is moved to the click location if the mouse click falls inside the slider.\
    @param <MouseEvent Instance - eventObj>, <boolean - handled>, <boolean - within>\
]]\
function Slider:onMouseClick( eventObj, handled, within )\
    if within and not handled then\
        self.value = eventObj.X - self.X + 1\
    end\
end\
\
--[[\
    @setter\
    @desc If the width of the slider is updated, the track's text will automatically be updated to match the new width\
    @param <number - width>\
]]\
function Slider:setWidth( width )\
    self.super:setWidth( width )\
\
    self.track.text = self.trackCharacter:rep( self.width )\
end\
\
--[[\
    @setter\
    @desc If the track character of the slider is updated, the track's text will automatically be updated to match\
    @param <string - char>\
]]\
function Slider:setTrackCharacter( char )\
    self.trackCharacter = char\
    self.track.text = char:rep( self.width )\
end\
\
configureConstructor {\
    argumentTypes = {\
        trackCharacter = \"string\",\
        trackColour = \"colour\",\
\
        slideCharacter = \"string\",\
        slideBackgroundColour = \"colour\",\
\
        value = \"number\"\
    }\
}",
  [ "Lexer.ti" ] = "--[[\
    @static escapeChars - table (def. { ... }) - A table containing a special character -> escape character matrix (ie: n -> \"\\n\")\
\
    @instance stream - string (def. false) - The current stream being lexed\
    @instance tokens - table (def. {}) - The tokens currently found by the lexer\
    @instance line - number (def. 1) - A number representing the line of the string currently being lexed\
    @instance char - number (def. 1) - A number representing the character of the current line being lexed\
]]\
\
abstract class Lexer {\
    static = {\
        escapeChars = {\
            a = \"\\a\",\
            b = \"\\b\",\
            f = \"\\f\",\
            n = \"\\n\",\
            r = \"\\r\",\
            t = \"\\t\",\
            v = \"\\v\"\
        }\
    };\
\
    stream = false;\
\
    tokens = {};\
\
    line = 1;\
    char = 1;\
}\
\
--[[\
    @constructor\
    @desc Constructs the Lexer instance by providing the instance with a 'stream'.\
    @param <string - stream>, [boolean - manual]\
]]\
function Lexer:__init__( stream, manual )\
    if type( stream ) ~= \"string\" then\
        return error \"Failed to initialise Lexer instance. Invalid stream paramater passed (expected string)\"\
    end\
    self.stream = stream\
\
    if not manual then\
        self:formTokens()\
    end\
end\
\
--[[\
    @instance\
    @desc This function is used to repeatedly call 'tokenize' until the stream has been completely consumed.\
]]\
function Lexer:formTokens()\
    while self.stream and self.stream:find \"%S\" do\
        self:tokenize()\
    end\
end\
\
--[[\
    @instance\
    @desc A simple function that is used to add a token to the instances 'tokens' table.\
    @param <table - token>\
]]\
function Lexer:pushToken( token )\
    local tokens = self.tokens\
\
    token.char = self.char\
    token.line = self.line\
    tokens[ #tokens + 1 ] = token\
end\
\
--[[\
    @instance\
    @desc Consumes the stream by 'amount'.\
]]\
function Lexer:consume( amount )\
    local stream = self.stream\
    self.stream = stream:sub( amount + 1 )\
\
    self.char = self.char + amount\
    return content\
end\
\
--[[\
    @instance\
    @desc Uses the Lua pattern provided to select text from the stream that matches the pattern. The text is then consumed from the stream (entire pattern, not just selected text)\
    @param <string - pattern>, [number - offset]\
]]\
function Lexer:consumePattern( pattern, offset )\
    local cnt = self.stream:match( pattern )\
\
    self:consume( select( 2, self.stream:find( pattern ) ) + ( offset or 0 ) )\
    return cnt\
end\
\
--[[\
    @instance\
    @desc Searches for the next occurence of 'opener'. Once found all text between the first two occurences is selected and consumed resulting in a XML_STRING token.\
    @param <char - opener>\
    @return <string - consumedString>\
]]\
function Lexer:consumeString( opener )\
    local stream, closingIndex = self.stream\
\
    if stream:find( opener, 2 ) then\
        local str, c, escaped = {}\
        for i = 2, #stream do\
            c = stream:sub( i, i )\
\
            if escaped then\
                str[ #str + 1 ] = Lexer.escapeChars[ c ] or c\
                escaped = false\
            elseif c == \"\\\\\" then\
                escaped = true\
            elseif c == opener then\
                self:consume( i )\
                return table.concat( str )\
            else\
                str[ #str + 1 ] = c\
            end\
        end\
    end\
\
    self:throw( \"Failed to lex stream. Expected string end (\"..opener..\")\" )\
end\
\
--[[\
    @instance\
    @desc Removes all trailing spaces from\
]]\
function Lexer:trimStream()\
    local stream = self.stream\
\
    local newLn = stream:match(\"^(\\n+)\")\
    if newLn then self:newline( #newLn ) end\
\
    local spaces = select( 2, stream:find \"^%s*%S\" )\
\
    self.stream = stream:sub( spaces )\
    self.char = self.char + spaces - 1\
\
    return self.stream\
end\
\
--[[\
    @instance\
    @desc Advanced 'line' by 'amount' (or 1) and sets 'char' back to zero\
]]\
function Lexer:newline( amount )\
    self.line = self.line + ( amount or 1 )\
    self.char = 0\
end\
\
--[[\
    @instance\
    @desc Throws error 'e' prefixed with information regarding current position and stores the error in 'exception' for later reference\
]]\
function Lexer:throw( e )\
    self.exception = \"Lexer (\" .. tostring( self.__type ) .. \") Exception at line '\"..self.line..\"', char '\"..self.char..\"': \"..e\
    return error( self.exception )\
end",
  [ "Container.ti" ] = "--[[\
    @instance consumeAll - boolean (def. true) - If true ANY mouse event that collide with the container will be 'handled', regardless of whether or not the event collided with a contained node.\
\
    Container is a simple node that allows multiple nodes to be contained using relative positions.\
]]\
\
class Container extends Node mixin MNodeContainer {\
    allowMouse = true;\
    allowKey = true;\
    allowChar = true;\
\
    consumeAll = true;\
}\
\
--[[\
    @instance\
    @desc Constructs the Container node with the value passed. If a nodes table is passed each entry inside of it will be added to the container as a node\
    @param [number - X], [number - Y], [number - width], [number - height], [table - nodes]\
]]\
function Container:__init__( ... )\
    self:resolve( ... )\
\
    local toset = self.nodes\
    self.nodes = {}\
\
    if type( toset ) == \"table\" then\
        for i = 1, #toset do\
            self:addNode( toset[ i ] )\
        end\
    end\
\
    self:register( \"width\", \"height\" )\
    self:super()\
end\
\
--[[\
    @instance\
    @desc Returns true if the node given is visible inside of the container\
    @param <Node - node>, [number - width], [number - height]\
    @return <boolean - visible>\
]]\
function Container:isNodeInBounds( node, width, height )\
    local left, top = node.X, node.Y\
\
    return not ( ( left + node.width ) < 1 or left > ( width or self.width ) or top > ( height or self.height ) or ( top + node.height ) < 1 )\
end\
\
--[[\
    @instance\
    @desc Draws contained nodes to container canvas. Nodes are only drawn if they are visible inside the container\
    @param [boolean - force], [number - offsetX], [number - offsetY]\
]]\
function Container:draw( force, offsetX, offsetY )\
    if self.changed or force then\
        local canvas = self.canvas\
\
        local width, height = self.width, self.height\
        local nodes, node = self.nodes\
        local offsetX, offsetY = offsetX or 0, offsetY or 0\
\
        for i = 1, #nodes do\
            node = nodes[ i ]\
\
            if force or ( node.needsRedraw and node.visible ) then\
                node:draw( force )\
\
                if node.projector then\
                    if node.mirrorProjector then\
                        node.canvas:drawTo( canvas, node.X + offsetX, node.Y + offsetY )\
                    end\
\
                    node.resolvedProjector.changed = true\
                else\
                    node.canvas:drawTo( canvas, node.X + offsetX, node.Y + offsetY )\
                end\
\
                node.needsRedraw = false\
            end\
        end\
\
        self.changed = false\
    end\
end\
\
--[[\
    @instance\
    @desc Redirects all events to child nodes. Mouse events are adjusted to become relative to this container. Event handlers on Container are still fired if present\
    @param <Event - event>\
    @return <boolean - propagate>\
]]\
function Container:handle( eventObj )\
    if not self.super:handle( eventObj ) then return end\
\
    local clone\
    if eventObj.main == \"MOUSE\" then\
        clone = eventObj:clone( self )\
        clone.isWithin = clone.isWithin and eventObj:withinParent( self ) or false\
    end\
\
    self:shipEvent( clone or eventObj )\
    if clone and clone.isWithin and ( self.consumeAll or clone.handled ) then\
        eventObj.handled = true\
    end\
    return true\
end\
\
--[[\
    @instance\
    @desc Ships the 'event' provided to every direct child\
    @param <Event Instance - event>\
]]\
function Container:shipEvent( event )\
    local nodes = self.nodes\
    for i = #nodes, 1, -1 do\
        if nodes[ i ] then nodes[ i ]:handle( event ) end\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the width property on 'self', and queues a redraw on each direct child node\
    @param <number - width>\
]]\
function Container:setWidth( width )\
\009self.super:setWidth( width )\
\009local nodes = self.nodes\
\009for i = 1, #nodes do\
\009\009nodes[i].needsRedraw = true\
\009end\
end\
\
--[[\
    @setter\
    @desc Sets the height property on 'self', and queues a redraw on each direct child node\
    @param <number - height>\
]]\
function Container:setHeight( height )\
\009self.super:setHeight( height )\
\009local nodes = self.nodes\
\009for i = 1, #nodes do\
\009\009nodes[i].needsRedraw = true\
\009end\
end\
\
\
configureConstructor({\
    orderedArguments = { \"X\", \"Y\", \"width\", \"height\", \"nodes\", \"backgroundColour\" },\
    argumentTypes = {\
        nodes = \"table\";\
        consumeAll = \"boolean\";\
    }\
}, true)",
  [ "MInteractable.ti" ] = "--[[\
    @static properties - table (def. { ... }) - A table containing the different properties to manage depending on the mode used when starting interaction. For example, `move = { \"X\", \"Y\" }` so that when moving the instance the X and Y of the instance is changed\
    @static callbacks - table (def. { ... }) - A table containing the different callbacks to execute. Format: `mode = { onStart, onFinish }` where mode is the mode used when starting interaction and onStart is called when the mouse is clicked, and onFinish when the mouse is released.\
\
    @instance mouse - table (def. {}) - A table containing information about the button to be used when calculating the position to use when moving, or the size to use when re-sizing\
]]\
abstract class MInteractable {\
    static = {\
        properties = {\
            move = { \"X\", \"Y\" },\
            resize = { \"width\", \"height\" }\
        },\
\
        callbacks = {\
            move = { \"onPickup\", \"onDrop\" }\
        }\
    };\
\
    mouse = false;\
}\
\
--[[\
    @instance\
    @desc Updates the mouse information. If not mode and the instance is currently being manipulated, the current modes finish callback (if set) is executed and the mouse information is reset.\
\
          If a mode is provided, the mouse is updated ( with mode, X and Y ) and the start callback is executed (if set)\
    @param [boolean - false] - Clears mouse information\
    @param <string - mode>, <number - X>, <number - Y> - Updates the mouse information to match\
]]\
function MInteractable:updateMouse( mode, X, Y )\
    if not mode and self.mouse then\
        local cb = MInteractable.static.callbacks[ self.mouse[ 1 ] ]\
        if cb then\
            self:executeCallbacks( cb[ 2 ] )\
        end\
\
        self.mouse = false\
    else\
        self.mouse = { mode, X, Y }\
\
        local cb = MInteractable.static.callbacks[ mode ]\
        if cb then\
            self:executeCallbacks( cb[ 1 ], X, Y )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Handles the mouse drag by changing the two properties set in the 'properties' static for the current mode (mouse[1]) depending on the mouse position at the start of the interaction, and the current position\
    @param <MouseEvent Instance - eventObj>, <boolean - handled>, <boolean - within>\
]]\
function MInteractable:handleMouseDrag( eventObj, handled, within )\
    local mouse = self.mouse\
    if not mouse or handled then return end\
\
    local props = MInteractable.static.properties[ mouse[ 1 ] ]\
    if not props then return end\
\
    self[ props[ 1 ] ], self[ props[ 2 ] ] = eventObj.X - mouse[ 2 ] + 1, eventObj.Y - mouse[ 3 ] + 1\
\
    eventObj.handled = true\
end",
  [ "Node.ti" ] = "--[[\
    @static eventMatrix - table (def. {}) - Contains the event -> function name matrix. If an event name is found in the keys, the value is used as the function to call on the instance (otherwise, 'onEvent' is called)\
    @static anyMatrix - table (def. {}) - Only used when 'useAnyCallbacks' is true. If a key matching the 'main' key of the event instance is found, it's value is called (ie: MOUSE -> onMouse)\
\
    @instance Z - number (def. 1) - The nodes Z index. Objects with higher z indexes appear above others.\
    @instance enabled - boolean (def. true) - When 'true', node may receive events\
    @instance parentEnabled - boolean (def. true) - When 'true', the parent of this node is enabled\
    @instance visible - boolean (def. true) - When 'true', node is drawn to parent canvas\
    @instance allowMouse - boolean (def. false) - If 'false', mouse events shipped to this node are ignored\
    @instance allowKey - boolean (def. false) - If 'false', key events shipped to this node are ignored\
    @instance allowChar - boolean (def. false) - If 'false', key events that have a character (ie: 'a', 'b' and 'c', but not 'delete') shipped to this node are ignored\
    @instance useAnyCallbacks - boolean (def. false) - If 'true', events shipped to this node are handled through the static 'anyMatrix'\
    @instance disabledColour - colour (def. 128) - When the node is disabled (enabled 'false'), this colour should be used to draw the foreground\
    @instance disabledBackgroundColour - colour (def. 256) - When the node is disabled (enabled 'false'), this colour should be used to draw the background\
    @instance needsRedraw - boolean (def. true) - If true, the contents of the nodes canvas will be blit onto the parents canvas without redrawing the nodes canvas contents, unlike 'changed', which does both\
    @instance consumeWhenDisabled - boolean (def. true) - When true, mouse events that collide with this node while it is disabled will be consumed (handled = true). Non-mouse events are unaffected by this property\
\
    A Node is an object which makes up the applications graphical user interface (GUI).\
\
    Objects such as labels, buttons and text inputs are nodes.\
]]\
\
abstract class Node extends Component mixin MThemeable mixin MCallbackManager mixin MProjectable {\
    static = {\
        eventMatrix = {\
            mouse_click = \"onMouseClick\",\
            mouse_drag = \"onMouseDrag\",\
            mouse_up = \"onMouseUp\",\
            mouse_scroll = \"onMouseScroll\",\
\
            key = \"onKeyDown\",\
            key_up = \"onKeyUp\",\
            char = \"onChar\"\
        },\
        anyMatrix = {\
            MOUSE = \"onMouse\",\
            KEY = \"onKey\"\
        }\
    };\
\
    disabledColour = 128;\
    disabledBackgroundColour = 256;\
\
    allowMouse = false;\
    allowKey = false;\
    allowChar = false;\
    useAnyCallbacks = false;\
\
    enabled = true;\
    parentEnabled = true;\
\
    visible = true;\
\
    needsRedraw = true;\
    parent = false;\
\
    consumeWhenDisabled = true;\
\
    Z = 1;\
}\
\
--[[\
    @constructor\
    @desc Creates a NodeCanvas (bound to self) and stores it inside of `self.canvas`. This canvas is drawn to the parents canvas at draw time.\
]]\
function Node:__init__()\
    self:register( \"X\", \"Y\", \"colour\", \"backgroundColour\", \"enabled\", \"visible\", \"disabledColour\", \"disabledBackgroundColour\" )\
\
    if not self.canvas then self.raw.canvas = NodeCanvas( self ) end\
end\
\
--[[\
    @constructor\
    @desc Finishes construction by hooking the theme manager into the node.\
]]\
function Node:__postInit__()\
    self:hook()\
end\
\
--[[\
    @setter\
    @desc Sets 'parentEnabled' and sets 'changed' to true\
    @param <boolean - parentEnabled>\
]]\
function Node:setParentEnabled( parentEnabled )\
    self.parentEnabled = parentEnabled\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Sets 'needsRedraw'. If the node now needs a redraw, it's parent (if any) will also have it's 'needsRedraw' property set to true\
    @param <boolean - needsRedraw>\
]]\
function Node:setNeedsRedraw( needsRedraw )\
    self.needsRedraw = needsRedraw\
\
    if needsRedraw and self.parent then self.parent.needsRedraw = needsRedraw end\
end\
\
--[[\
    @setter\
    @desc Sets the enabled property of the node to 'enabled'. Sets node's 'changed' to true.\
    @param <boolean - enabled>\
]]\
function Node:setEnabled( enabled )\
    self.enabled = enabled\
    self.changed = true\
end\
\
--[[\
    @getter\
    @desc Returns 'enabled', unless the parent is not enabled, in which case 'false' is returned\
    @return <boolean - enabled>\
]]\
function Node:getEnabled()\
    if not self.parentEnabled then\
        return false\
    end\
\
    return self.enabled\
end\
\
--[[\
    @setter\
    @desc Sets 'parent' and sets the nodes 'changed' to true. If the node has a parent (ie: didn't set parent to false) the 'parentEnabled' property will be updated to match the parents 'enabled'\
    @param <MNodeContainer Instance - parent> - If a parent exists, this line is used\
    @param <boolean - parent> - If no parent exists, this line is used (false)\
]]\
function Node:setParent( parent )\
    self.parent = parent\
    self.changed = true\
\
    if parent then\
        self.parentEnabled = Titanium.typeOf( parent, \"Application\" ) or parent.enabled\
        self:resolveProjector()\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the node to visible/invisible depending on 'visible' parameter\
    @param <boolean - visible>\
]]\
function Node:setVisible( visible )\
    self.visible = visible\
    self.changed = true\
    if not visible then\
        self:queueAreaReset()\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the application of the node, and updates any attached projectors\
    @param <Application Instance - application>\
]]\
function Node:setApplication( application )\
    if self.application then\
        self.parent:removeNode( self )\
    end\
\
    self.application = application\
    self:resolveProjector()\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Sets the changed state of this node to 'changed'. If 'changed' then the parents of this node will also have changed set to true.\
    @param <boolean - changed>\
]]\
function Node:setChanged( changed )\
    self.changed = changed\
\
    if changed then\
        local parent = self.parent\
        if parent and not parent.changed then\
            parent.changed = true\
        end\
\
        self.needsRedraw = true\
    end\
end\
\
--[[\
    @instance\
    @desc Handles events by triggering methods on the node depending on the event object passed\
    @param <Event Instance* - eventObj>\
    @return <boolean - propagate>\
\
    *Note: The event instance passed can be of variable type, ideally it extends 'Event' so that required methods are implemented on the eventObj.\
]]\
function Node:handle( eventObj )\
    local main, sub, within = eventObj.main, eventObj.sub, false\
    local handled, enabled = eventObj.handled, self.enabled\
\
    if self.projector then\
        self.resolvedProjector:handleEvent( eventObj )\
\
        if not self.mirrorProjector and not eventObj.projectorOrigin then\
            return\
        end\
    end\
\
    if main == \"MOUSE\" then\
        if self.allowMouse then\
            within = eventObj.isWithin and eventObj:withinParent( self ) or false\
\
            if within and not enabled and self.consumeWhenDisabled then eventObj.handled = true end\
        else return end\
    elseif ( main == \"KEY\" and not self.allowKey ) or ( main == \"CHAR\" and not self.allowChar ) then\
        return\
    end\
\
    if not enabled then return end\
\
    local fn = Node.eventMatrix[ eventObj.name ] or \"onEvent\"\
    if self:can( fn ) then\
        self[ fn ]( self, eventObj, handled, within )\
    end\
\
    if self.useAnyCallbacks then\
        local anyFn = Node.anyMatrix[ main ]\
        if self:can( anyFn ) then\
            self[ anyFn ]( self, eventObj, handled, within )\
        end\
    end\
\
    return true\
end\
\
--[[\
    @instance\
    @desc Returns the absolute X, Y position of a node rather than its position relative to it's parent.\
    @return <number - X>, <number - Y>\
]]\
function Node:getAbsolutePosition( limit )\
    local parent = self.parent\
    if parent then\
        if limit and parent == limit then\
            return -1 + parent.X + self.X, -1 + parent.Y + self.Y\
        end\
\
        local pX, pY = self.parent:getAbsolutePosition()\
        return -1 + pX + self.X, -1 + pY + self.Y\
    else return self.X, self.Y end\
end\
\
--[[\
    @instance\
    @desc A shortcut method to quickly create a Tween instance and add it to the applications animations\
    @return <Tween Instance - animation> - If an application is set, the animation created is returned\
    @return <boolean - false> - If no application is set, false is returned\
]]\
function Node:animate( ... )\
    if not self.application then return end\
\
    return self.application:addAnimation( Tween( self, ... ) )\
end\
\
--[[\
    @instance\
    @desc Reorders the node inside the parents 'nodes' table depending on the nodes 'Z' position.\
]]\
function Node:updateZ()\
    if not self.parent then return end\
    local nodes, targetZ = self.parent.nodes, self.Z\
\
    for i = 1, #nodes do\
        if nodes[ i ] == self then\
            while true do\
                local before, after = nodes[ i - 1 ], nodes[ i + 1 ]\
\
                if before and before.Z > targetZ then\
                    nodes[ i ], nodes[ i - 1 ] = nodes[ i - 1 ], self\
                    i = i - 1\
                elseif after and after.X < targetZ then\
                    nodes[ i ], nodes[ i + 1 ] = nodes[ i + 1 ], self\
                    i = i + 1\
                else break end\
            end\
\
            self.changed = true\
            break\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Changes the z index of the node, and updates the z position (:updateZ)\
    @param <number - Z>\
]]\
function Node:setZ( Z )\
    self.Z = Z\
    self:updateZ()\
end\
\
configureConstructor {\
    argumentTypes = { enabled = \"boolean\", visible = \"boolean\", disabledColour = \"colour\", disabledBackgroundColour = \"colour\", consumeWhenDisabled = \"boolean\", Z = \"number\"; allowMouse = \"boolean\"; allowChar = \"boolean\"; allowKey = \"boolean\" }\
}",
  [ "MTogglable.ti" ] = "--[[\
    A small mixin to avoid rewriting code used by nodes that can be toggled on or off.\
]]\
\
abstract class MTogglable {\
    toggled = false;\
\
    toggledColour = colours.red;\
    toggledBackgroundColour = colours.white;\
}\
\
--[[\
    @constructor\
    @desc Registers properties used by this class with the theme handler if the object mixes in 'MThemeable'\
]]\
function MTogglable:MTogglable()\
    if Titanium.mixesIn( self, \"MThemeable\" ) then\
        self:register(\"toggled\", \"toggledColour\", \"toggledBackgroundColour\")\
    end\
end\
\
--[[\
    @instance\
    @desc 'toggled' to the opposite of what it currently is (toggles)\
]]\
function MTogglable:toggle( ... )\
    self:setToggled( not self.toggled, ... )\
end\
\
--[[\
    @instance\
    @desc Sets toggled to 'toggled' and changed to 'true' when the 'toggled' param doesn't match the current value of toggled.\
    @param <boolean - toggled>, [vararg - onToggleArguments]\
]]\
function MTogglable:setToggled( toggled, ... )\
    if self.toggled ~= toggled then\
        self.raw.toggled = toggled\
        self.changed = true\
\
        self:executeCallbacks( \"toggle\", ... )\
    end\
end\
\
configureConstructor {\
    argumentTypes = {\
        toggled = \"boolean\",\
        toggledColour = \"colour\",\
        toggledBackgroundColour = \"colour\"\
    }\
} alias {\
    toggledColor = \"toggledColour\",\
    toggledBackgroundColor = \"toggledBackgroundColour\"\
}",
  [ "ContextMenu.ti" ] = "--[[\
    The ContextMenu class allows developers to dynamically spawn context menus with content they can customize. This node takes the application bounds into account and ensures\
    the content doesn't spill out of view.\
]]\
\
class ContextMenu extends Container {\
    static = {\
        allowedTypes = { \"Button\", \"Label\" }\
    };\
}\
\
--[[\
    @constructor\
    @desc Resolves constructor arguments and invokes super. The canvas of this node is also marked transparent, as the canvas of this node is a rectangular shape surrounding all subframes.\
    @param <table - structure>*\
\
    Note: Ordered arguments inherited from other classes not included\
]]\
function ContextMenu:__init__( ... )\
    self:resolve( ... )\
    self:super()\
\
    self.transparent = true\
end\
\
--[[\
    @instance\
    @desc Population of the context menu requires a parent to be present. Therefore, when the parent is set on a node we will populate the\
          context menu, instead of at instantiation\
    @param <Node - parent>\
]]\
function ContextMenu:setParent( parent )\
    self.parent = parent\
\
    if parent then\
        local frame = self:addNode( ScrollContainer() )\
        frame.frameID = 1\
\
        self:populate( frame, self.structure )\
        frame.visible = true\
    end\
end\
\
--[[\
    @instance\
    @desc Populates the context menu with the options specified in the 'structure' table.\
          Accounts for application edge by positioning the menu as to avoid the menu contents spilling out of view.\
    @param <MNodeContainer* - parent>, <table - structure>\
\
    Note: The 'parent' param must be a node that can contain other nodes.\
]]\
function ContextMenu:populate( frame, structure )\
    local queue, q, totalWidth, totalHeight, negativeX = { { frame, structure } }, 1, 0, 0, 1\
\
    while q <= #queue do\
        local menu, structure, width = queue[ q ][ 1 ], queue[ q ][ 2 ], 0\
        local rules, Y = {}, 0\
\
        for i = 1, #structure do\
            Y = Y + 1\
            local part = structure[ i ]\
            local partType = part[ 1 ]:lower()\
\
            if partType == \"custom\" then\
                --TODO: Custom menu entries\
            else\
                if partType == \"menu\" then\
                    local subframe = self:addNode( ScrollContainer( nil, menu.Y + Y - 1 ) )\
                    if not menu.subframes then\
                        menu.subframes = { subframe }\
                    else\
                        table.insert( menu.subframes, subframe )\
                    end\
\
                    subframe.visible = false\
\
                    local id = #self.nodes\
                    subframe.frameID = id\
                    menu:addNode( Button( part[ 2 ], 1, Y ):on( \"trigger\", function()\
                        local subframes = menu.subframes\
                        for i = 1, #subframes do\
                            if subframes[ i ] ~= subframe and subframes[ i ].visible then\
                                self:closeFrame( subframes[ i ].frameID )\
                            end\
                        end\
\
                        if subframe.visible then\
                            self:closeFrame( id )\
                        else\
                            subframe.visible = true\
                        end\
                    end ) )\
\
                    table.insert( queue, { subframe, part[ 3 ], menu } )\
                elseif partType == \"rule\" then\
                    rules[ #rules + 1 ] = Y\
                elseif partType == \"button\" then\
                    menu:addNode( Button( part[ 2 ], 1, Y ):on( \"trigger\", part[ 3 ] ) )\
                elseif partType == \"label\" then\
                    menu:addNode( Label( part[ 2 ], 1, Y ) )\
                end\
\
                if partType ~= \"rule\" then\
                    width = math.max( width, #part[ 2 ] )\
                end\
            end\
        end\
\
        if width == 0 then error \"Failed to populate context menu. Content given has no detectable width (or zero). Cannot proceed without width greater than 0\" end\
\
        for n = 1, #menu.nodes do menu.nodes[ n ].width = width end\
        for r = 1, #rules do menu:addNode( Label( (\"-\"):rep( width ), 1, rules[ r ] ) ) end\
\
        local parentMenu, widthOffset, relX = queue[ q ][ 3 ], 0, 0\
        if parentMenu then\
            widthOffset, relX = parentMenu.width, parentMenu.X\
        end\
\
        local spill = ( relX + widthOffset + width + self.X - 1 ) - self.parent.width\
        if spill > 0 then\
            menu.X = relX - ( parentMenu and width or spill )\
        else\
            menu.X = relX + widthOffset\
        end\
        negativeX = math.min( negativeX, menu.X )\
\
        menu.width, menu.height = width, Y - math.max( menu.Y + Y - self.parent.height, 0 )\
        menu:cacheContent()\
\
        totalWidth, totalHeight = totalWidth + menu.width, totalHeight + math.max( menu.height - ( parentMenu and parentMenu.Y or 0 ), 1 )\
        q = q + 1\
    end\
\
    if negativeX < 1 then\
        local nodes = self.nodes\
        for i = 1, #nodes do\
            nodes[ i ].X = nodes[ i ].X - negativeX + 1\
        end\
\
        self.X = self.X + negativeX\
    end\
\
    self.width = totalWidth\
    self.height = totalHeight\
end\
\
--[[\
    @instance\
    @desc A modified Container.shipEvent to avoid shipping events to hidden submenus.\
    @param <Event - event>\
]]\
function ContextMenu:shipEvent( event )\
    local nodes = self.nodes\
    for i = #nodes, 1, -1 do\
        if nodes[ i ].visible then\
            nodes[ i ]:handle( event )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Invokes super (container) handle function. If event is a mouse event and it missed an open subframe the frames will be closed (if it was a CLICK) and the event will be unhandled\
          allowing further propagation and usage throughout the application.\
    @param <Event - eventObj>\
    @return <boolean - propagate>\
]]\
function ContextMenu:handle( eventObj )\
    if not self.super:handle( eventObj ) then return end\
\
    if eventObj.main == \"MOUSE\" and not self:isMouseColliding( eventObj ) then\
        if eventObj.sub == \"CLICK\" then self:closeFrame( 1 ) end\
        eventObj.handled = false\
    end\
\
    return true\
end\
\
--[[\
    @instance\
    @desc Closes the frame using 'frameID', which represents the position of the frame in the 'nodes' table\
    @param <number - frameID>\
]]\
function ContextMenu:closeFrame( frameID )\
    local framesToClose, i = { self.nodes[ frameID ] }, 1\
    while i <= #framesToClose do\
        local subframes = framesToClose[ i ].subframes or {}\
        for f = 1, #subframes do\
            if subframes[ f ].visible then\
                framesToClose[ #framesToClose + 1 ] = subframes[ f ]\
            end\
        end\
\
        framesToClose[ i ].visible = false\
        i = i + 1\
    end\
\
    self.changed = true\
end\
\
configureConstructor {\
    orderedArguments = { \"structure\" },\
    requiredArguments = { \"structure\" },\
    argumentTypes = {\
        structure = \"table\"\
    }\
}",
  [ "XMLParser.ti" ] = "--[[\
    The XMLParser class is used to handle the lexing and parsing of XMLParser source into a parse tree.\
]]\
\
class XMLParser extends Parser {\
    tokens = false;\
    tree = false;\
}\
\
--[[\
    @constructor\
    @desc Creates a 'Lexer' instance with the source and stores the tokens provided. Invokes 'parse' once lexical analysis complete.\
]]\
function XMLParser:__init__( source )\
    local lex = XMLLexer( source )\
    self:super( lex.tokens )\
end\
\
--[[\
    @instance\
    @desc Iterates through every token and constructs a tree of XML layers\
]]\
function XMLParser:parse()\
    local stack, top, token = {{}}, false, self:stepForward()\
    local isTagOpen, settingAttribute\
\
    while token do\
        if settingAttribute then\
            if token.type == \"XML_ATTRIBUTE_VALUE\" or token.type == \"XML_STRING_ATTRIBUTE_VALUE\" then\
                top.arguments[ settingAttribute ] = token.value\
                settingAttribute = false\
            else\
                self:throw( \"Unexpected \"..token.type..\". Expected attribute value following XML_ASSIGNMENT token.\" )\
            end\
        else\
            if token.type == \"XML_OPEN\" then\
                if isTagOpen then\
                    self:throw \"Unexpected XML_OPEN token. Expected XML attributes or end of tag.\"\
                end\
                isTagOpen = true\
\
                top = { type = token.value, arguments = {} }\
                table.insert( stack, top )\
            elseif token.type == \"XML_END\" then\
                local toClose = table.remove( stack )\
                top = stack[ #stack ]\
\
                if not top then\
                    self:throw(\"Nothing to close with XML_END of type '\"..token.value..\"'\")\
                elseif toClose.type ~= token.value then\
                    self:throw(\"Tried to close \"..toClose.type..\" with XML_END of type '\"..token.value..\"'\")\
                end\
\
                if not top.children then top.children = {} end\
                table.insert( top.children, toClose )\
            elseif token.type == \"XML_END_CLOSE\" then\
                top = stack[ #stack - 1 ]\
\
                if not top then\
                    self:throw(\"Unexpected XML_END_CLOSE tag (/>)\")\
                end\
\
                if not top.children then top.children = {} end\
                table.insert( top.children, table.remove( stack ) )\
            elseif token.type == \"XML_CLOSE\" then\
                isTagOpen = false\
            elseif token.type == \"XML_ATTRIBUTE\" then\
                local next = self:stepForward()\
\
                if next.type == \"XML_ASSIGNMENT\" then\
                    settingAttribute = token.value\
                else\
                    top.arguments[ token.value ] = true\
                    self.position = self.position - 1\
                end\
            elseif token.type == \"XML_CONTENT\" then\
                if not top.type then\
                    self:throw(\"Unexpected XML_CONTENT. Invalid content: \"..token.value)\
                end\
\
                top.content = token.value\
            else\
                self:throw(\"Unexpected \"..token.type)\
            end\
        end\
\
        if token.type == \"XML_END\" or token.type == \"XML_END_CLOSE\" then\
            isTagOpen = false\
        end\
\
        if top.content and top.children then\
            self:throw \"XML layers cannot contain child nodes and XML_CONTENT at the same time\"\
        end\
\
        token = self:stepForward()\
    end\
\
    if isTagOpen then\
        self:throw(\"Expected '\"..tostring( top.type )..\"' tag close, but found none\")\
    elseif top.type then\
        self:throw(\"Expected ending tag for '\"..top.type..\"', but found none\")\
    end\
\
    self.tree = stack[ 1 ].children\
end\
\
--[[\
    @static\
    @desc When lexing the XML arguments they are all stored as strings as a result of the string operations to find tokens.\
          This function converts a value to the type given (#2)\
    @param <var - argumentValue>, <string - desiredType>\
    @return <desiredType* - value>\
\
    *Note: desiredType is passed as type string, however the return is the value type defined inside the string. eg: desiredType: \"number\" will return a number, not a string.\
]]\
function XMLParser.static.convertArgType( argumentValue, desiredType )\
    local vType = type( argumentValue )\
\
    if not desiredType or not argumentValue or vType == desiredType then\
        return argumentValue\
    end\
\
    if desiredType == \"string\" then\
        return tostring( argumentValue )\
    elseif desiredType == \"number\" then\
        return tonumber( argumentValue ) and math.ceil( tonumber( argumentValue ) ) or error( \"Failed to cast argument to number. Value: \"..tostring( argumentValue )..\" is not a valid number\" )\
    elseif desiredType == \"boolean\" then\
        if argumentValue == \"true\" then return true\
        elseif argumentValue == \"false\" then return false\
        else\
            return error( \"Failed to cast argument to boolean. Value: \"..tostring( argumentValue )..\" is not a valid boolean (true or false)\" )\
        end\
    elseif desiredType == \"colour\" or desiredType == \"color\" then\
        if argumentValue == \"transparent\" or argumentValue == \"trans\" then\
            return 0\
        end\
        return tonumber( argumentValue ) or colours[ argumentValue ] or colors[ argumentValue ] or error( \"Failed to cast argument to colour (number). Value: \"..tostring( argumentValue )..\" is not a valid colour\" )\
    else\
        return error( \"Failed to cast argument. Unknown target type '\"..tostring( desiredType )..\"'\" )\
    end\
end",
  [ "Dropdown.ti" ] = "--[[\
    @instance maxHeight - number (def. false) - If set, the dropdown node may not exceed that height (meaning, the space for options to be displayed is maxHeight - 1)\
    @instance prompt - string (def. \"Please select\") - The default content of the dropdown toggle button. Will change to display selected option when an option is selected\
    @instance horizontalAlign - string (def. \"left\") - The horizontalAlign of the dropdown. The dropdown contents are linked (:linkProperties), so they will reflect the alignment property\
    @instance openIndicator - string (def. \" \\31\") - A string appended to the toggle button's text when the dropdown is open (options visible)\
    @instance closedIndicator - string (def. \" \\16\") - Identical to 'openIndicator', with the exception that this is visible when the dropdown is closed (options hidden)\
    @instance colour - colour (def. 1) - The colour of the dropdown options (not the toggle button), used when the buttons are not active\
    @instance backgroundColour - colour (def. 8) - The background colour of the dropdown options (not the toggle button), used when the buttons are not active\
    @instance activeColour - colour (def. nil) - The colour of the dropdown options (not the toggle button), used when the buttons are active\
    @instance activeBackgroundColour - colour (def. 512) - The background colour of the dropdown options (not the toggle button), when the buttons are active\
    @instance selectedColour - colour (def. 1) - The colour of the toggle button\
    @instance selectedBackgroundColour - colour (def. 256) - The background colour of the toggle button\
    @instance selectedOption - table (def. false) - The option (format: { displayName, value }) currently selected\
    @instance options - table (def. {}) - All options (format: { displayName, value }) the dropdown has registered - these can be selected (unless already selected)\
\
    The Dropdown node allows for easy multi-choice options inside of user forms. The toggle button will display the currently selected option, or, if none is selected the 'prompt' will be shown instead.\
\
    When one of the options are selected, the 'change' callback will be fired and the newly selected option is provided.\
\
    Upon instantiation, the dropdown will populate itself with buttons inside of it's 'optionContainer'. Each button representing a different option, that can be selected to select the option.\
    The button's \"colour\", \"activeColour\", \"disabledColour\", \"backgroundColour\", \"activeBackgroundColour\", \"disabledBackgroundColour\" and, \"horizontalAlign\" properties are dynamically linked to the Dropdown instance.\
    Thus, setting any of those properties on the dropdown itself will cause the setting to also be changed on all buttons. Avoid changing properties on the buttons directly, as the values will be overridden.\
\
    Similarily, the toggle button's \"horizontalAlign\", \"disabledColour\", \"disabledBackgroundColour\", \"activeColour\" and, \"activeBackgroundColour\" properties are linked to the dropdown instance. The colour, and backgroundColour\
    of the toggle button is controlled via 'selectedColour' and 'selectedBackgroundColour' respectively.\
]]\
\
class Dropdown extends Container mixin MActivatable {\
    maxHeight = false;\
\
    prompt = \"Please select\";\
    horizontalAlign = \"left\";\
\
    openIndicator = \" \\31\";\
    closedIndicator = \" \\16\";\
\
    backgroundColour = colours.lightBlue;\
    colour = colours.white;\
\
    activeBackgroundColour = colours.cyan;\
\
    selectedColour = colours.white;\
    selectedBackgroundColour = colours.grey;\
    selectedOption = false;\
    options = {};\
\
    transparent = true;\
}\
\
--[[\
    @constructor\
    @desc Creates the dropdown instance and creates the option display (button) and container (scroll container). The selectable options live inside the optionContainer, and the selected option is displayed using the optionDisplay\
    @param [number - X], [number - Y], [number - width], [number - maxHeight], [string - prompt]\
]]\
function Dropdown:__init__( ... )\
    self:super( ... )\
\
    self.optionDisplay = self:addNode( Button \"\":linkProperties( self, \"horizontalAlign\", \"disabledColour\", \"disabledBackgroundColour\", \"activeColour\", \"activeBackgroundColour\" ):on(\"trigger\", function() self:toggleOptionDisplay() end) )\
    self.optionContainer = self:addNode( ScrollContainer( 1, 2, self.width ):set{ xScrollAllowed = false, consumeWhenDisabled = false } )\
\
    self:closeOptionDisplay()\
    self.consumeAll = false --TODO: Is this really needed - I think it would almost be better to have it as 'true' (default)\
end\
\
--[[\
    @instance\
    @desc Closes the dropdown by hiding (and disabling) the options container and updates the toggle button (in order to update the open/closed indicator)\
]]\
function Dropdown:closeOptionDisplay()\
    local cont = self.optionContainer\
    cont.visible, cont.enabled = false, false\
\
    self:queueAreaReset()\
    self:updateDisplayButton()\
end\
\
--[[\
    @instance\
    @desc Opens the dropdown by showing (and enabled) the options container and updates the toggle button (in order to update the open/closed indicator)\
]]\
function Dropdown:openOptionDisplay()\
    local cont = self.optionContainer\
    cont.visible, cont.enabled = true, true\
\
    self:queueAreaReset()\
    self:updateDisplayButton()\
end\
\
--[[\
    @instance\
    @desc If the option container is already visible, it is closed (:closeOptionDisplay), otherwise it is opened (:openOptionDisplay)\
]]\
function Dropdown:toggleOptionDisplay()\
    if self.optionContainer.visible then\
        self:closeOptionDisplay()\
    else\
        self:openOptionDisplay()\
    end\
end\
\
--[[\
    @setter\
    @desc If the dropdown is disabled, the dropdowns option container is closed (:closeOptionDisplay)\
    @param <boolean - enabled>\
]]\
function Dropdown:setEnabled( enabled )\
    self.super:setEnabled( enabled )\
    if not enabled then\
        self:closeOptionDisplay()\
    end\
end\
\
--[[\
    @instance\
    @desc Updates the toggle buttons text, width, colour and backgroundColour (the colour and backgroundColour are sourced from 'selectedColour' and 'selectedBackgroundColour' respectively)\
]]\
function Dropdown:updateDisplayButton()\
    self.height = 1 + ( self.optionContainer.visible and self.optionContainer.height or 0 )\
\
    self.optionDisplay.text = ( type( self.selectedOption ) == \"table\" and self.selectedOption[ 1 ] or self.prompt ) .. ( self.optionContainer.visible and self.openIndicator or self.closedIndicator )\
    self.optionDisplay.width = #self.optionDisplay.text\
\
    self.optionDisplay:set {\
        colour = self.selectedColour,\
        backgroundColour = self.selectedBackgroundColour\
    }\
end\
\
--[[\
    @instance\
    @desc Updates the options by changing the text of each button, to match the order of the options.\
]]\
function Dropdown:updateOptions()\
    local options, buttons = self.options, self.optionContainer.nodes\
    local selected = self.selectedOption\
\
    local buttonI = 1\
    for i = 1, #options do\
        if not selected or options[ i ] ~= selected then\
            local button = buttons[ buttonI ]\
            if button then\
                button.text = options[ i ][ 1 ]\
                button:off(\"trigger\", \"dropdownTrigger\"):on(\"trigger\", function()\
                    self.selectedOption = options[ i ]\
                end, \"dropdownTrigger\")\
            end\
\
            buttonI = buttonI + 1\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Creates/removes nodes depending on the amount of options to be displayed (ie: if there are too many nodes, excess are removed).\
\
          Invokes :updateOptions before adjusting the dropdown height with respect to 'maxHeight' (if set), and the 'yScroll'\
]]\
function Dropdown:checkOptions()\
    local cont, options = self.optionContainer, self.options\
    local nodes = cont.nodes\
    local count = #nodes\
\
    local rOptionCount = #options - ( self.selectedOption and 1 or 0 )\
    if count > rOptionCount then\
        repeat\
            cont:removeNode( nodes[ #nodes ] )\
        until #nodes == rOptionCount\
    elseif count < rOptionCount then\
        repeat\
            cont:addNode(Button( \"ERR\", 1, #nodes + 1, self.width )\
                :set(\"consumeWhenDisabled\", false):linkProperties( self, \"colour\", \"activeColour\",\
                \"disabledColour\", \"backgroundColour\", \"activeBackgroundColour\",\
                \"disabledBackgroundColour\", \"horizontalAlign\" ))\
        until #nodes == rOptionCount\
    end\
    self:updateOptions()\
\
    count = #nodes\
    if self.maxHeight then\
        cont.height = math.min( count, self.maxHeight - 1 )\
    else\
        cont.height = count\
    end\
\
    self:updateDisplayButton()\
    self.optionsChanged = false\
    if #options > 0 then cont.yScroll = math.min( cont.yScroll, count ) end\
end\
\
--[[\
    @instance\
    @desc Calls ':checkOptions' if 'optionsChanged', before calling the super 'draw' function\
    @param <... - args> - Arguments passed to the super 'draw' method\
]]\
function Dropdown:draw( ... )\
    if self.optionsChanged then self:checkOptions() end\
\
    self.super:draw( ... )\
end\
\
--[[\
    @instance\
    @desc Returns the 'value' of the selected option, if an option is selected\
    @return <string - value>\
]]\
function Dropdown:getSelectedValue()\
    if type( self.selectedOption ) ~= \"table\" then return end\
\
    return self.selectedOption[ 2 ]\
end\
\
--[[\
    @instance\
    @desc Adds the option provided, with the value given. This option is then selectable.\
    @param <string - option>, <string - value>\
]]\
function Dropdown:addOption( option, value )\
    if type( option ) ~= \"string\" or value == nil then\
        return error \"Failed to add option to Dropdown node. Expected two arguments: string, val - where val is not nil\"\
    end\
\
    self:removeOption( option )\
    table.insert( self.options, { option, value } )\
\
    self.optionsChanged = true\
end\
\
--[[\
    @instance\
    @desc Removes the option given if present\
]]\
function Dropdown:removeOption( option )\
    local options = self.options\
    for i = #options, 1, -1 do\
        if options[ i ] == option then\
            table.remove( options, i )\
        end\
    end\
\
    self.optionsChanged = true\
end\
\
--[[\
    @setter\
    @desc Updates the optionDisplay text to match the new prompt\
    @param <string - prompt>\
]]\
function Dropdown:setPrompt( prompt )\
    self.prompt = prompt\
    self.optionDisplay.text = prompt\
end\
\
--[[\
    @setter\
    @desc Closes the option display and invokes the 'change' callback\
    @param <table - option>\
]]\
function Dropdown:setSelectedOption( selected )\
    self.selectedOption = selected\
    self:closeOptionDisplay()\
    self.optionsChanged = true\
\
    self:executeCallbacks( \"change\", selected )\
end\
\
--[[\
    @instance\
    @desc Handles the eventObj given. If the event is a mouse click, and it missed the dropdown, the dropdown is closed (if open)\
]]\
function Dropdown:handle( eventObj )\
    if not self.super:handle( eventObj ) then return end\
\
    if eventObj:is \"mouse_click\" and not self:isMouseColliding( eventObj ) and self.optionContainer.visible then\
        self:closeOptionDisplay()\
        eventObj.handled = true\
    end\
\
    return true\
end\
\
--[[\
    @instance\
    @desc Adds the TML object given. If the type is 'Option', the option is registered (using the tag content as the display, and it's 'value' argument as the value)\
    @param <table - TMLObj>\
]]\
function Dropdown:addTMLObject( TMLObj )\
    if TMLObj.type == \"Option\" then\
        if TMLObj.content and TMLObj.arguments.value then\
            self:addOption( TMLObj.content, TMLObj.arguments.value )\
        else\
            error \"Failed to add TML object to Dropdown object. 'Option' tag must include content (not children) and a 'value' argument\"\
        end\
    else\
        error( \"Failed to add TML object to Dropdown object. Only 'Option' tags are accepted, '\" .. tostring( TMLObj.type ) .. \"' is invalid\" )\
    end\
end\
\
configureConstructor({\
    orderedArguments = { \"X\", \"Y\", \"width\", \"maxHeight\", \"prompt\" },\
    argumentTypes = {\
        maxHeight = \"number\",\
        prompt = \"string\",\
\
        selectedColour = \"colour\",\
        selectedBackgroundColour = \"colour\"\
    }\
}, true)\
\
alias {\
    selectedColor = \"selectedColour\",\
    selectedBackgroundColor = \"selectedBackgroundColour\"\
}",
  [ "Component.ti" ] = "--[[\
    @instance width - number (def. 1) - The objects width, defines the width of the canvas.\
    @instance height - number (def. 1) - The objects width, defines the height of the canvas.\
    @instance X - number (def. 1) - The objects X position.\
    @instance Y - number (def. 1) - The objects Y position.\
    @instance changed - boolean (def. true) - If true, the node will be redrawn by it's parent. This propagates up to the application, before being drawn to the CraftOS term object. Set to false after draw.\
    @instance backgroundChar - string (def. \" \") - Defines the character used when redrawing the canvas. Can be set to \"nil\" to use no character at all.\
\
    A Component is an object that can be represented visually.\
]]\
\
abstract class Component mixin MPropertyManager {\
    width = 1;\
    height = 1;\
    X = 1;\
    Y = 1;\
\
    changed = true;\
\
    backgroundChar = \" \";\
}\
\
--[[\
    @instance\
    @desc Redraws the area that 'self' occupies inside it's parent\
]]\
function Component:queueAreaReset()\
    local parent = self.parent\
    if parent then\
        parent:redrawArea( self.X, self.Y, self.width, self.height )\
    end\
\
    self.changed = true\
end\
\
--[[\
    @instance\
    @desc Accepts either a property, or a property-value table to set on the instance\
    @param <string - property>, <any - value> - If setting just one property\
    @param <table - properties> - Setting multiple properties, using format { property = value }\
]]\
function Component:set( properties, value )\
    if type( properties ) == \"string\" then\
        self[ properties ] = value\
    elseif type( properties ) == \"table\" then\
        for property, val in pairs( properties ) do\
            self[ property ] = val\
        end\
    else return error \"Expected table or string\"end\
\
    return self\
end\
\
--[[\
    @setter\
    @desc Resets the area the node previously occupied before moving the node's X position\
    @param <number - X>\
]]\
function Component:setX( X )\
    self:queueAreaReset()\
    self.X = math.ceil( X )\
end\
\
--[[\
    @setter\
    @desc Resets the area the node previously occupied before moving the node's Y position\
    @param <number - Y>\
]]\
function Component:setY( Y )\
    self:queueAreaReset()\
    self.Y = math.ceil( Y )\
end\
\
--[[\
    @setter\
    @desc Resets the area the node previously occupied before changing the nodes width\
    @param <number - width>\
]]\
function Component:setWidth( width )\
    self:queueAreaReset()\
\
    width = math.ceil( width )\
    self.width = width\
    self.canvas.width = width\
end\
\
--[[\
    @setter\
    @desc Resets the area the node previously occupied before changing the nodes height\
    @param <number - height>\
]]\
function Component:setHeight( height )\
    self:queueAreaReset()\
\
    height = math.ceil( height )\
    self.height = height\
    self.canvas.height = height\
end\
\
--[[\
    @setter\
    @desc Changes the colour of the canvas and the node, and queues a redraw\
    @param <number - colour>\
]]\
function Component:setColour( colour )\
    self.colour = colour\
    self.canvas.colour = colour\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Changes the background colour of the canvas and the node, and queues a redraw\
    @param <number - backgroundColour>\
]]\
function Component:setBackgroundColour( backgroundColour )\
    self.backgroundColour = backgroundColour\
    self.canvas.backgroundColour = backgroundColour\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Changes the transparency of the canvas and node, and queues a redraw\
    @param <boolean - transparent>\
]]\
function Component:setTransparent( transparent )\
    self.transparent = transparent\
    self.canvas.transparent = transparent\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Changes the canvas and nodes background character, and queues a redraw\
    @param <string - backgroundChar>\
]]\
function Component:setBackgroundChar( backgroundChar )\
    if backgroundChar == \"nil\" then\
        backgroundChar = nil\
    end\
\
    self.backgroundChar = backgroundChar\
    self.canvas.backgroundChar = backgroundChar\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Changes the backgroundTextColour of the canvas and node, and queues a redraw\
    @param <number - backgroundTextColour>\
]]\
function Component:setBackgroundTextColour( backgroundTextColour )\
    self.backgroundTextColour = backgroundTextColour\
    self.canvas.backgroundTextColour = backgroundTextColour\
\
    self.changed = true\
end\
\
configureConstructor {\
    orderedArguments = { \"X\", \"Y\", \"width\", \"height\" },\
    argumentTypes = { X = \"number\", Y = \"number\", width = \"number\", height = \"number\", colour = \"colour\", backgroundColour = \"colour\", backgroundTextColour = \"colour\", transparent = \"boolean\" }\
} alias {\
    color = \"colour\",\
    backgroundColor = \"backgroundColour\"\
}",
  [ "MPropertyManager.ti" ] = "--[[\
    Tracks property changes and invokes custom callbacks when they change.\
\
    Note: Only supports watching of arguments that have had their types set via `configure`.\
]]\
\
abstract class MPropertyManager mixin MDynamic {\
    watching = {};\
    foreignWatchers = {};\
    links = {};\
}\
\
--[[\
    @constructor\
    @desc Hooks into all properties whose types have been defined. Un-hooked arguments cannot be watched.\
]]\
function MPropertyManager:MPropertyManager()\
    local properties = Titanium.getClass( self.__type ):getRegistry().constructor\
    if not ( properties or properties.argumentTypes ) then return end\
\
    for property in pairs( properties.argumentTypes ) do\
        local setterName = Titanium.getSetterName( property )\
        local oldSetter = self.raw[ setterName ]\
\
        self[ setterName ] = function( instance, value )\
            if type( value ) == \"string\" then\
                local escaped, rest = value:match \"^(%%*)%$(.*)$\"\
                if escaped and #escaped % 2 == 0 then\
                    self:setDynamicValue( DynamicValue( self, property, rest ), true )\
\
                    return\
                end\
            end\
\
            value = self:updateWatchers( property, value )\
            if oldSetter then\
                oldSetter( self, instance, value )\
            else\
                self[ property ] = value\
            end\
        end\
    end\
\
    if Titanium.mixesIn( self, \"MCallbackManager\" ) then\
        -- Destroys local and foreign watcher instructions\
        self:on(\"remove\", function( instance )\
            self:unwatchForeignProperty \"*\"\
            self:unwatchProperty( \"*\", false, true )\
        end)\
    end\
end\
\
--[[\
    @instance\
    @desc Invokes the callback function of any watching links, passing the instance and value.\
    @param <string - property>, [var - value]\
    @return [var - value]\
]]\
function MPropertyManager:updateWatchers( property, value )\
    local function updateWatchers( prop )\
        local watchers = self.watching[ prop ]\
        if watchers then\
            for i = 1, #watchers do\
                local newVal = watchers[ i ][ 1 ]( self, prop, value )\
\
                if newVal ~= nil then\
                    value = newVal\
                end\
            end\
        end\
    end\
\
    if property == \"*\" then\
        for prop in pairs( self.watching ) do updateWatchers( prop ) end\
    else\
        updateWatchers( property )\
    end\
\
    return value\
end\
\
--[[\
    @instance\
    @desc Adds a watch instruction on 'object' for 'property'. The instruction is logged in 'foreignWatchers' for future modification (ie: destruction)\
    @param <string - property>, <Instance - object>, <function - callback>, [string - name]\
]]\
function MPropertyManager:watchForeignProperty( property, object, callback, name )\
    if object == self then\
        return error \"Target object is not foreign. Select a foreign object or use :watchProperty\"\
    end\
\
    if not self.foreignWatchers[ property ] then self.foreignWatchers[ property ] = {} end\
    table.insert( self.foreignWatchers[ property ], object )\
\
    object:watchProperty( property, callback, name, self )\
end\
\
--[[\
    @instance\
    @desc Destroys the watch instruction for 'property'. If 'property' is '*', all property watchers are removed. If 'object' is given, only foreign links towards 'object' will be removed.\
    @param <string - property>, [Instance - object]\
]]\
function MPropertyManager:unwatchForeignProperty( property, object, name )\
    local function unwatchProp( prop )\
        local foreignWatchers = self.foreignWatchers[ prop ]\
\
        if foreignWatchers then\
            for i = #foreignWatchers, 1, -1 do\
                if not object or foreignWatchers[ i ] == object then\
                    foreignWatchers[ i ]:unwatchProperty( prop, name, true )\
                    table.remove( foreignWatchers, i )\
                end\
            end\
        end\
    end\
\
    if property == \"*\" then\
        for prop in pairs( self.foreignWatchers ) do unwatchProp( prop ) end\
    else\
        unwatchProp( property )\
    end\
end\
\
--[[\
    @instance\
    @desc Removes headless references of 'property' to foreign links for 'object'. Used when the foreign target (object) has severed connection and traces must be removed from the creator (self).\
    @param <string - property>, <string - object>\
]]\
function MPropertyManager:destroyForeignLink( property, object )\
    local watching = self.foreignWatchers[ property ]\
    if not watching then return end\
\
    for i = #watching, 1, -1 do\
        if watching[ i ] == object then\
            table.remove( watching, i )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Instructs this object to call 'callback' when 'property' changes\
    @param <string - property>, <function - callback>, [string - name], [boolean - foreignOrigin]\
]]\
function MPropertyManager:watchProperty( property, callback, name, foreignOrigin )\
    if name then\
        self:unwatchProperty( property, name )\
    end\
\
    if not self.watching[ property ] then self.watching[ property ] = {} end\
    table.insert( self.watching[ property ], { callback, name, foreignOrigin } )\
end\
\
--[[\
    @instance\
    @desc Removes watch instructions for 'property'. If 'name' is given, only watch instructions with that name will be removed.\
          If 'foreign' is true, watch instructions marked as originating from a foreign source will also be removed - else, only local instructions will be removed.\
          If 'preserveForeign' and 'foreign' are true, foreign links will be removed, however they will NOT be disconnected from their origin\
    @param <string - property>, [string - name], [boolean - foreign], [boolean - preserveForeign]\
]]\
function MPropertyManager:unwatchProperty( property, name, foreign, preserveForeign )\
    local function unwatchProp( prop )\
        local watching = self.watching[ prop ]\
\
        if watching then\
            for i = #watching, 1, -1 do\
                if ( not name or watching[ i ][ 2 ] == name ) and ( foreign and watching[ i ][ 3 ] or ( not foreign and not watching[ i ][ 3 ] ) ) then\
                    if foreign and not preserveForeign then\
                        watching[ i ][ 3 ]:destroyForeignLink( prop, self )\
                    end\
\
                    table.remove( watching, i )\
                end\
            end\
        end\
    end\
\
    if property == \"*\" then\
        for prop in pairs( self.watching ) do unwatchProp( prop ) end\
    else\
        unwatchProp( property )\
    end\
end\
\
--[[\
    @instance\
    @desc Links properties given to 'target'. Properties can consist of tables or string values. If table, the first index represents the name of the foreign property to link to (belonging to 'target') and the second the local property to bind (belongs to 'self')\
          If the property is a string, the foreign property and local property match and a simple bind is produced\
    @param <Instance - target>, <var - properties>\
    @return <Instance - self>\
]]\
function MPropertyManager:linkProperties( target, ... )\
    local links, ERR = self.links, \"Failed to link foreign property '\"..tostring(foreignProperty)..\"' from '\"..tostring(target)..\"' to local property '\"..tostring(localProperty)..\"'. A %s already exists for this local property, remove that link before linking\"\
\
    local function createLink( foreignProperty, localProperty )\
        localProperty = localProperty or foreignProperty\
\
        if self.links[ localProperty ] then\
            return error( ERR:format \"link\" )\
        elseif self.dynamicValues[ localProperty ] then\
            return error( ERR:format \"dynamic link\" )\
        end\
\
        self:watchForeignProperty( foreignProperty, target, function( _, __, value )\
            self[ localProperty ] = value\
        end, \"PROPERTY_LINK_\" .. self.__ID )\
\
        links[ localProperty ], self[ localProperty ] = target, target[ foreignProperty ]\
    end\
\
    local properties = { ... }\
    for i = 1, #properties do\
        local prop = properties[ i ]\
        if type( prop ) == \"table\" then createLink( prop[ 1 ], prop[ 2 ] ) else createLink( prop ) end\
    end\
\
    return self\
end\
\
--[[\
    @instance\
    @desc Removes the property link for foreign properties ..., bound to 'target'. The properties provided represent the foreign property that is bound to, not the local property.\
    @param <Instance - target>, <... - foreignProperties>\
    @return <Instance - self>\
]]\
function MPropertyManager:unlinkProperties( target, ... )\
    local properties, links, dynamics = { ... }, self.links, self.dynamicValues\
    for i = 1, #properties do\
        local prop = properties[ i ]\
        if not self:removedDynamicValue( prop )then\
            self:unwatchForeignProperty( prop, target, \"PROPERTY_LINK_\" .. self.__ID )\
\
            if links[ prop ] == target then\
                links[ prop ] = nil\
            end\
        end\
    end\
\
    return self\
end",
  [ "QueryLexer.ti" ] = "--[[\
    @instance inCondition - boolean (def. false) - If true, the lexer is currently processing a condition\
\
    A lexer that processes node queries into tokens used by QueryParser\
]]\
\
class QueryLexer extends Lexer\
\
--[[\
    @instance\
    @desc The main token creator\
]]\
function QueryLexer:tokenize()\
    if self.stream:find \"^%s\" and not self.inCondition then\
        self:pushToken { type = \"QUERY_SEPERATOR\" }\
    end\
\
    local stream = self:trimStream()\
\
    if self.inCondition then\
        self:tokenizeCondition( stream )\
    elseif stream:find \"^~\" then\
        self:pushToken { type = \"QUERY_TYPEOF\", value = self:consumePattern \"^~\" }\
    elseif stream:find \"^%b[]\" then\
        self:pushToken { type = \"QUERY_COND_OPEN\" }\
        self:consume( 1 )\
\
        self.inCondition = true\
    elseif stream:find \"^%,\" then\
        self:pushToken { type = \"QUERY_END\", value = self:consumePattern \"^%,\" }\
    elseif stream:find \"^>\" then\
        self:pushToken { type = \"QUERY_DIRECT_PREFIX\", value = self:consumePattern \"^>\" }\
    elseif stream:find \"^#[^%s%.#%[%,]*\" then\
        self:pushToken { type = \"QUERY_ID\", value = self:consumePattern \"^#([^%s%.#%[]*)\" }\
    elseif stream:find \"^%.[^%s#%[%,]*\" then\
        self:pushToken { type = \"QUERY_CLASS\", value = self:consumePattern \"^%.([^%s%.#%[]*)\" }\
    elseif stream:find \"^[^,%s#%.%[]*\" then\
        self:pushToken { type = \"QUERY_TYPE\", value = self:consumePattern \"^[^,%s#%.%[]*\" }\
    else\
        self:throw(\"Unexpected block '\"..stream:match(\"(.-)%s\")..\"'\")\
    end\
end\
\
--[[\
    @instance\
    @desc When the lexer finds a condition (isCondition = true), this function is used to lex the condition\
    @param <string - stream>\
]]\
function QueryLexer:tokenizeCondition( stream )\
    local first = stream:sub( 1, 1 )\
    if stream:find \"%b[]\" then\
        self:throw( \"Nested condition found '\"..tostring( stream:match \"%b[]\" )..\"'\" )\
    elseif stream:find \"^%b''\" or stream:find '^%b\"\"' then\
        local cnt = self:consumePattern( first == \"'\" and \"^%b''\" or '^%b\"\"' ):sub( 2, -2 )\
        if cnt:find \"%b''\" or cnt:find '%b\"\"' then\
            self:throw( \"Nested string found inside '\"..tostring( cnt )..\"'\" )\
        end\
\
        self:pushToken { type = \"QUERY_COND_STRING_ENTITY\", value = cnt }\
    elseif stream:find \"^%w+\" then\
        self:pushToken { type = \"QUERY_COND_ENTITY\", value = self:consumePattern \"^%w+\" }\
    elseif stream:find \"^%,\" then\
        self:pushToken { type = \"QUERY_COND_SEPERATOR\" }\
        self:consume( 1 )\
    elseif stream:find \"^[%p~]+\" then\
        self:pushToken { type = \"QUERY_COND_SYMBOL\", value = self:consumePattern \"^[%p~]+\" }\
    elseif stream:find \"^%]\" then\
        self:pushToken { type = \"QUERY_COND_CLOSE\" }\
        self:consume( 1 )\
        self.inCondition = false\
    else\
        self:throw(\"Invalid condition syntax. Expected property near '\"..tostring( stream:match \"%S*\" )..\"'\")\
    end\
end",
  [ "Pane.ti" ] = "--[[\
    A pane is a very simple node that simply draws a box at 'X', 'Y' with dimensions 'width', 'height'.\
]]\
\
class Pane extends Node {\
    backgroundColour = colours.black;\
\
    allowMouse = true;\
    useAnyCallbacks = true;\
}\
\
--[[\
    @instance\
    @desc Resolves arguments and calls super constructor.\
]]\
function Pane:__init__( ... )\
    self:resolve( ... )\
    self:super()\
end\
\
--[[\
    @instance\
    @desc Clears the canvas, the canvas background colour becomes 'backgroundColour' during the clear.\
    @param [boolean - force]\
]]\
function Pane:draw( force )\
    local raw = self.raw\
    if raw.changed or force then\
        raw.canvas:clear()\
        raw.changed = false\
    end\
end\
\
--[[\
    @instance\
    @desc Handles any mouse events cast onto this node to prevent nodes under it being affected by them.\
    @param <MouseEvent - event>, <boolean - handled>, <boolean - within>\
]]\
function Pane:onMouse( event, handled, within )\
    if not within or handled then return end\
\
    event.handled = true\
end\
\
configureConstructor({\
    orderedArguments = {\"X\", \"Y\", \"width\", \"height\", \"backgroundColour\"}\
}, true)",
  [ "TextContainer.ti" ] = "local string_sub = string.sub\
local function resolvePosition( self, lines, X, Y )\
    local posY = math.min( #lines, Y )\
    if posY == 0 then return 0 end\
\
    local selectedLine = lines[ posY ]\
    return math.min( selectedLine[ 3 ] - ( posY == #lines and 0 or 1 ), selectedLine[ 2 ] + X - selectedLine[ 5 ] )\
end\
\
--[[\
    The TextContainer object is a very helpful node when it comes time to display a lot of text.\
\
    The text is automatically wrapped to fit the containers width, and a vertical scrollbar will appear when the content becomes too tall.\
\
    The text can also be selected, using click and drag, and retrieved using :getSelectedText\
]]\
\
class TextContainer extends ScrollContainer mixin MTextDisplay mixin MFocusable {\
    position = 1,\
    selection = false,\
\
    text = \"\",\
\
    selectedColour = colours.blue,\
    selectedBackgroundColour = colours.lightBlue,\
\
    allowMouse = true\
}\
\
--[[\
    @instance\
    @desc Constructs the instance, and disables horizontal scrolling\
    @param [string - text], [number - x], [number - y], [number - width], [number - height]\
]]\
function TextContainer:__init__( ... )\
    self:resolve( ... )\
\
    self:super()\
    self.xScrollAllowed = false\
end\
\
--[[\
    @instance\
    @desc An overwrite of 'ScrollContainer:cacheContentSize' that sets the content height to the amount of lines, instead of performing a node check.\
]]\
function TextContainer:cacheContentSize()\
    self.cache.contentWidth, self.cache.contentHeight = self.width, self.lineConfig.lines and #self.lineConfig.lines or 0\
end\
\
--[[\
    @instance\
    @desc Calls ScrollContainer:cacheDisplaySize with 'true', allowing the TextContainer to use it's own display calculations, and re-wrap the text\
          to fit correctly (scrollbar)\
]]\
function TextContainer:cacheDisplaySize()\
    self.super:cacheDisplaySize( true )\
\
    self:wrapText( self.cache.displayWidth )\
    self:cacheContentSize()\
    self:cacheScrollbarSize()\
end\
\
--[[\
    @instance\
    @desc Draws the text lines created by 'wrapText' using the selection where appropriate\
]]\
function TextContainer:draw()\
    if self.changed then\
        local selection = self.selection\
        if selection then\
            local position = self.position\
\
            self:drawLines(\
                self.lineConfig.lines,\
                selection < position and selection or position,\
                selection < position and position or selection\
            )\
        else self:drawLines( self.lineConfig.lines ) end\
\
        self:drawScrollbars()\
\
        self.changed = false\
    end\
end\
\
--[[\
    @instance\
    @desc Draws the lines (created by wrapText) with respect to the text containers selection and the alignment options (horizontalAlign and verticalAlign)\
    @param <table - lines>, [number - selectionStart], [number - selectionStop]\
]]\
function TextContainer:drawLines( lines, selectionStart, selectionStop )\
    local vAlign, hAlign = self.verticalAlign, self.horizontalAlign\
    local width, height = self.width, self.height\
\
    local yOffset = 0\
    if vAlign == \"centre\" then\
        yOffset = math.floor( ( height / 2 ) - ( #lines / 2 ) + .5 )\
    elseif vAlign == \"bottom\" then\
        yOffset = height - #lines\
    end\
\
    local tc, bg, sTc, sBg\
    if not self.enabled then\
        tc, bg = self.disabledColour, self.disabledBackgroundColour\
    elseif self.focused then\
        tc, bg = self.focusedColour, self.focusedBackgroundColour\
        sTc, sBg = self.selectedColour, self.selectedBackgroundColour\
    end\
\
    tc, bg = tc or self.colour, bg or self.backgroundColour\
    sTc, sBg = sTc or tc, sBg or bg\
\
    local pos, sel, canvas = self.position, self.selection, self.canvas\
    local isSelection = selectionStart and selectionStop\
\
    canvas:clear( bg )\
    local cacheX, cacheY, cacheSelX, cacheSelY = ( hAlign == \"centre\" and width / 2 or ( hAlign == \"right\" and width ) or 0 ), 1, false, false\
    for i = self.yScroll + 1, #lines do\
        local Y, line = yOffset + i - self.yScroll, lines[ i ]\
        local lineContent, lineStart, lineEnd = line[ 1 ], line[ 2 ], line[ 3 ]\
        local xOffset = line[ 5 ]\
\
        if isSelection then\
            local pre, current, post\
            local lineSelectionStart, lineSelectionStop = selectionStart - lineStart + 1, lineEnd - ( lineEnd - selectionStop ) - lineStart + 1\
            if selectionStart >= lineStart and selectionStop <= lineEnd then\
                -- The selection start and end are within this line. Single line selection\
                -- This line has three segments - unselected (1), selected (2), unselected (3)\
\
                pre = string_sub( lineContent, 1, lineSelectionStart - 1 )\
                current = string_sub( lineContent, lineSelectionStart, lineSelectionStop )\
                post = string_sub( lineContent, lineSelectionStop + 1 )\
            elseif selectionStart >= lineStart and selectionStart <= lineEnd then\
                -- The selectionStart is here, but not the end. The selection is multiline.\
                -- This line has two segments - unselected (1) and selected (2)\
\
                pre = string_sub( lineContent, 1, lineSelectionStart - 1 )\
                current = string_sub( lineContent, lineSelectionStart )\
            elseif selectionStop >= lineStart and selectionStop <= lineEnd then\
                -- The selectionStop is here, but not the start. The selection is multiline\
                -- This line has two segments - selected(1) and unselected (2)\
\
                pre = \"\"\
                current = string_sub( lineContent, 1, lineSelectionStop )\
                post = string_sub( lineContent, lineSelectionStop + 1 )\
            elseif selectionStart <= lineStart and selectionStop >= lineEnd then\
                -- The selection neither starts, nor ends here - however it IS selected.\
                -- This line has one segment - selected(1)\
\
                pre = \"\"\
                current = lineContent\
            else\
                -- The selection is out of the bounds of this line - it is unselected\
                -- This line has one segment - unselected(1)\
\
                pre = lineContent\
            end\
\
            if pre then canvas:drawTextLine( xOffset, Y, pre, tc, bg ) end\
            if current then canvas:drawTextLine( xOffset + #pre, Y, current, sTc, sBg ) end\
            if post then canvas:drawTextLine( xOffset + #pre + #current, Y, post, tc, bg ) end\
        else canvas:drawTextLine( xOffset, Y, lineContent, tc, bg ) end\
\
        if pos >= lineStart and pos <= lineEnd then\
            if pos == lineEnd and self.lineConfig.lines[ i + 1 ] then\
                cacheY = i + 1\
            else\
                cacheX, cacheY = pos - lineStart + xOffset, i\
            end\
        end\
        if sel and sel >= lineStart and sel <= lineEnd then\
            if sel == lineEnd and self.lineConfig.lines[ i + 1 ] then\
                cacheSelY = i + 1\
            else\
                cacheSelX, cacheSelY = sel - lineStart + 1, i\
            end\
        end\
    end\
\
    self.cache.x, self.cache.y = cacheX, cacheY\
    self.cache.selX, self.cache.selY = cachcSelX, cacheSelY\
end\
\
--[[\
    @instance\
    @desc Returns position and selection, ordered for use in 'string.sub'\
    @return <number - selectionStart>, <number - selectionStop> - When a selection exists, the bounds are returned\
    @return <boolean - false> - When no selection is found, false is returned\
]]\
function TextContainer:getSelectionRange()\
    local position, selection = self.position, self.selection\
    return position < selection and position or selection, position < selection and selection or position\
end\
\
--[[\
    @instance\
    @desc Uses :getSelectionRange to find the selected text\
    @return <string - selection> - When a selection exists, it is returned\
    @return <boolean - false> - If no selection is found, false is returned\
]]\
function TextContainer:getSelectedText()\
    if not self.selection then return false end\
    return self.text:sub( self:getSelectionRange() )\
end\
\
--[[\
    @instance\
    @desc Handles a mouse click. If the mouse occurred on the vertical scroll bar, the click is sent to the ScrollContainer handle function.\
          Otherwise the selection is removed and the current position is changed.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function TextContainer:onMouseClick( event, handled, within )\
    if not handled and within then\
        local X = event.X - self.X + 1\
        if X == self.width and self.cache.yScrollActive then\
            self.super:onMouseClick( event, handled, within )\
            return\
        end\
\
        local isShift = self.application:isPressed( keys.leftShift ) or self.application:isPressed( keys.rightShift )\
\
        if not isShift then self.selection = false end\
        self[ isShift and \"selection\" or \"position\" ] = resolvePosition( self, self.lineConfig.lines, X + self.xScroll, event.Y - self.Y + 1 + self.yScroll )\
\
        self.changed = true\
        self:focus()\
    else\
        self:unfocus()\
    end\
end\
\
--[[\
    @instance\
    @desc Handles a mouse draw. If the vertical scrollbar is currently selected, the mouse draw is passed to the ScrollContainer and ignored by further calculations\
          Otherwise, the selection is expanded depending on the new selection positions.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function TextContainer:onMouseDrag( event, handled, within )\
    if handled or not within then return end\
    local X = event.X - self.X + 1\
    if X == self.width and self.cache.yScrollActive then self.super:onMouseDrag( event, handled, within ) end\
    if self.mouse.selected == \"v\" or not self.focused then return end\
\
    self.selection = resolvePosition( self, self.lineConfig.lines, X + self.xScroll, event.Y - self.Y + 1 + self.yScroll )\
\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Sets the node to 'changed' when the selection is updated\
    @param <number - selection>\
]]\
function TextContainer:setSelection( selection )\
    self.selection = selection and math.max( math.min( #self.text, selection ), 1 ) or false\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Sets the node to 'changed' when the position is updated\
    @param <number - position>\
]]\
function TextContainer:setPosition( position )\
    self.position = position and math.max( math.min( #self.text, position ), 0 ) or false\
    self.selection = false\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc Updates the TextContainer by re-wrapping the text, and re-aligning the scroll bars when new text is set\
]]\
function TextContainer:setText( text )\
    self.text = text\
    self:wrapText( self.cache.displayWidth or 1 )\
    self:cacheContent()\
\
    self.yScroll = math.min( self.yScroll, self.cache.contentHeight - self.cache.displayHeight )\
end\
\
\
configureConstructor({\
    orderedArguments = { \"text\", \"X\", \"Y\", \"width\", \"height\" },\
    argumentTypes = { text = \"string\" }\
}, true)",
  [ "MThemeable.ti" ] = "local function doesLevelMatch( target, criteria, noAttr )\
    local doesTypeMatch = criteria.ambiguous and Titanium.typeOf( target, criteria.type ) or target.__type == criteria.type\
    if ( criteria.type == \"*\" or not criteria.type or doesTypeMatch ) and noAttr then\
        return true\
    end\
\
    if ( criteria.type and not doesTypeMatch and criteria.type ~= \"*\" ) or ( criteria.id and target.id ~= criteria.id ) or ( criteria.classes and not target:hasClass( criteria.classes ) ) then\
        return false\
    end\
\
    return true\
end\
\
local function doParentsMatch( parents, level, criteria, noAttr )\
    for i = level, #parents do\
        local parent = parents[ i ]\
        if doesLevelMatch( parent, criteria, noAttr ) then\
            return true, i\
        end\
    end\
\
    return false\
end\
\
local function doesMatchQuery( node, queryString, noAttr )\
    -- Get a parsed version of the query\
    local query = QueryParser( queryString ).query[ 1 ]\
\
    -- Collate the nodes parents once here\
    local last, levels = node, {}\
    while true do\
        local p = last.parent\
        if p then\
            levels[ #levels + 1 ] = p\
            last = p\
        else break end\
    end\
\
\
    -- If the last part of the query (the node part) does not match the node, return false\
    if not doesLevelMatch( node, query[ #query ], noAttr ) then\
        return false\
    end\
\
\
    -- Work backwards from the end of the query (-1), to the beginning.\
    local parentLevel = 1\
    for i = #query - 1, 1, -1 do\
        local part = query[ i ]\
        if part.direct then\
            if doesLevelMatch( levels[ parentLevel ], part, noAttr ) then\
                parentLevel = parentLevel + 1\
            else return false end\
        else\
            local success, levels = doParentsMatch( levels, parentLevel, part, noAttr )\
            if success then\
                parentLevel = parentLevel + levels\
            else return false end\
        end\
    end\
\
    return true\
end\
\
--[[\
    The MThemeable mixin facilitates the use of themes on objects.\
    It allows properties to be registered allowing the object to monitor property changes and apply them correctly.\
\
    The mixin stores all properties set directly on the object in `mainValues`. These values are prioritized over values from themes unless the theme rule is designated as 'important'.\
\
    This mixin no longer handles property links as this functionality has been replaced by a more robust system 'MPropertyManager'.\
]]\
\
abstract class MThemeable {\
    isUpdating = false;\
    hooked = false;\
\
    properties = {};\
    classes = {};\
    applicableRules = {};\
    rules = {};\
\
    mainValues = {};\
    defaultValues = {};\
}\
\
--[[\
    @instance\
    @desc Registers the properties provided. These properties are monitored for changes.\
    @param <string - property>, ...\
]]\
function MThemeable:register( ... )\
    if self.hooked then return error \"Cannot register new properties while hooked. Unhook the theme handler before registering new properties\" end\
\
    local args = { ... }\
    for i = 1, #args do\
        self.properties[ args[ i ] ] = true\
    end\
end\
\
--[[\
    @instance\
    @desc Unregisters properties provided\
    @param <string - property>, ...\
]]\
function MThemeable:unregister( ... )\
    if self.hooked then return error \"Cannot unregister properties while hooked. Unhook the theme handler before unregistering properties\" end\
\
    local args = { ... }\
    for i = 1, #args do\
        self.properties[ args[ i ] ] = nil\
    end\
end\
\
--[[\
    @instance\
    @desc Hooks into the instance by creating watch instructions that inform the mixin of property changes.\
]]\
function MThemeable:hook()\
    if self.hooked then return error \"Failed to hook theme handler. Already hooked\" end\
\
    for property in pairs( self.properties ) do\
        self:watchProperty( property, function( _, __, value )\
            if self.isUpdating then return end\
\
            self.mainValues[ property ] = value\
            return self:fetchPropertyValue( property )\
        end, \"THEME_HOOK_\" .. self.__ID )\
\
        self[ self.__resolved[ property ] and \"mainValues\" or \"defaultValues\" ][ property ] = self[ property ]\
    end\
\
    self:on( \"dynamic-instance-set\", function( self, dynamicInstance )\
        if not self.isUpdating and dynamicInstance.property then\
            self.mainValues[ dynamicInstance.property ] = dynamicInstance\
        end\
    end )\
\
    self:on( \"dynamic-instance-unset\", function( self, property, dynamicInstance )\
        if not self.isUpdating and self.mainValues[ property ] == dynamicInstance then\
            self.mainValues[ property ] = nil\
        end\
    end )\
\
\
    self.hooked = true\
end\
\
--[[\
    @instance\
    @desc Removes the watch instructions originating from this mixin (identified by 'THEME_HOOK_<ID>' name)\
]]\
function MThemeable:unhook()\
    if not self.hooked then return error \"Failed to unhook theme handler. Already unhooked\" end\
    self:unwatchProperty( \"*\", \"THEME_HOOK_\" .. self.__ID )\
\
    self:off \"dynamic-instance-set\"\
    self:off \"dynamic-instance-unset\"\
\
    self.hooked = false\
end\
\
--[[\
    @instance\
    @desc Returns the value for the property given. The value is found by checking themes for property values (taking into account 'important' rules). If no rule is found in the themes, the\
          value from 'mainValues' is returned instead.\
    @param <string - property>\
    @return <any - value>, <table - rule>\
]]\
function MThemeable:fetchPropertyValue( property )\
    local newValue = self.mainValues[ property ]\
    local requireImportant = newValue ~= nil\
\
    local rules, r, usedRule = self.applicableRules\
    for i = 1, #rules do\
        r = rules[ i ]\
        if r.property == property and ( not requireImportant or r.important ) then\
            newValue = r.value\
            usedRule = r\
\
            if r.important then requireImportant = true end\
        end\
    end\
\
    return newValue, usedRule\
end\
\
--[[\
    @instance\
    @desc Fetches the value from the application by checking themes for valid rules. If a theme value is found it is applied directly (this does trigger the setter)\
    @param <string - property>\
]]\
function MThemeable:updateProperty( property )\
    if not self.properties[ property ] then\
        return error( \"Failed to update property '\"..tostring( property )..\"'. Property not registered\" )\
    end\
\
    local new, rule = self:fetchPropertyValue( property )\
    self.isUpdating = true\
    if new ~= nil then\
        if Titanium.typeOf( new, \"DynamicValue\", true ) then\
            self:setDynamicValue( new, true )\
        elseif rule and rule.isDynamic then\
            self:setDynamicValue( DynamicValue( self, property, new ), true )\
        else\
            self[ property ] = new\
        end\
    else\
        self[ property ] = self.defaultValues[ property ]\
    end\
\
    self.isUpdating = false\
end\
\
--[[\
    @instance\
    @desc Stores rules that can be applied to this node (excluding class and ids) in 'applicableRules'. These rules are then filtered by id and classes into 'applicableRules'.\
\
          If 'preserveOld', the old rules will NOT be cleared.\
    @param [boolean - preserveOld]\
]]\
function MThemeable:retrieveThemes( preserveOld )\
    if not preserveOld then self.rules = {} end\
    if not self.application then return false end\
\
    local types, aliases\
\
    local selfRules, targetRules = self.rules, self.application.rules\
\
    if not targetRules then return end\
    for _, value in pairs { targetRules.ANY, targetRules[ self.__type ] } do\
        local q = 1\
        for query, properties in pairs( value ) do\
            if doesMatchQuery( self, query, true ) then\
                if not selfRules[ query ] then selfRules[ query ] = {} end\
                local rules, prop = selfRules[ query ]\
                for i = 1, #properties do\
                    prop = properties[ i ]\
\
                    if prop.computeType then\
                        if not aliases then\
                            local reg = Titanium.getClass( self.__type ).getRegistry()\
                            aliases = reg.alias\
\
                            local constructor = reg.constructor\
                            if constructor then\
                                types = constructor.argumentTypes or {}\
                            else types = {} end\
                        end\
\
                        rules[ #rules + 1 ] = { property = prop.property, important = prop.important, value = XMLParser.convertArgType( prop.value, types[ aliases[ prop.property ] or prop.property ] ) }\
                    else\
                        rules[ #rules + 1 ] = prop\
                    end\
                end\
            end\
        end\
    end\
\
    self:filterThemes()\
\
    local nodes = self.nodes\
    if nodes then\
        for i = 1, #nodes do\
            nodes[ i ]:retrieveThemes( preserveOld )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Checks each owned rule, only applying the rules that have queries that match exactly (owned rules are not dependent on classes/ids, where as applicableRules are)\
]]\
function MThemeable:filterThemes()\
    local aRules = {}\
    for query, properties in pairs( self.rules ) do\
        if doesMatchQuery( self, query ) then\
            -- The query is an exact match, add the properties to 'applicableRules', where the node will fetch it's properties\
            for i = 1, #properties do aRules[ #aRules + 1 ] = properties[ i ] end\
        end\
    end\
\
    self.applicableRules = aRules\
    self:updateProperties()\
end\
\
--[[\
    @instance\
    @desc Updates each registered property\
]]\
function MThemeable:updateProperties()\
    for property in pairs( self.properties ) do\
        self:updateProperty( property )\
    end\
end\
\
--[[\
    @instance\
    @desc Adds class 'class' and updated TML properties\
    @param <string - class>\
]]\
function MThemeable:addClass( class )\
    self.classes[ class ] = true\
    self:filterThemes()\
end\
\
--[[\
    @instance\
    @desc Removes class 'class' and updated TML properties\
    @param <string - class>\
]]\
function MThemeable:removeClass( class )\
    self.classes[ class ] = nil\
    self:filterThemes()\
end\
\
--[[\
    @instance\
    @desc Shortcut method to set class if 'has' is truthy or remove it otherwise (updates properties too)\
    @param <string - class>, [var - has]\
]]\
function MThemeable:setClass( class, has )\
    self.classes[ class ] = has and true or nil\
    self:filterThemes()\
end\
\
--[[\
    @instance\
    @desc Returns true if:\
          - Param passed is a table and all values inside the table are set as classes on this object\
          - Param is string and this object has that class\
    @param <string|table - class>\
    @return <boolean - has>\
]]\
function MThemeable:hasClass( t )\
    if type( t ) == \"string\" then\
        return self.classes[ t ]\
    elseif type( t ) == \"table\" then\
        for i = 1, #t do\
            if not self.classes[ t[ i ] ] then\
                return false\
            end\
        end\
\
        return true\
    else\
        return error(\"Invalid target '\"..tostring( t )..\"' for class check\")\
    end\
end",
  [ "Thread.ti" ] = "--[[\
    @instance running - boolean (def. false) - Indicates whether or not the thread is running. When false, calls to :handle will be rejected.\
    @instance func - function (def. false) - The function to wrap inside of a coroutine.\
    @instance co - coroutine (def. false) - The coroutine object automatically created by the Thread instance when it is started\
    @instance filter - string (def. false) - If set, only events that match will be handled. If titanium events are enabled, the :is() function will be used.\
    @instance exception - string (def. false) - If the thread crashes, coroutine.resume will catch the error and it will be stored inside of this property.\
    @instance titaniumEvents - boolean (def. false) - If 'true', events passed to this thread will NOT be converted to CC events and will remain event instances\
    @instance crashSilently - boolean (def. false) - If 'false', errors caused by the thread will propagate out of the thread. If 'true', the error will not propagate\
\
    The Thread object is a simple class used to wrap a function (chunk) in a coroutine.\
\
    This object can then be added to Application instances, via :addThread, and removed using the :removeThread\
    counterpart. This allows for easy 'multitasking', much like the ComputerCraft parallel API.\
\
    When resuming a thread, a titanium event should be passed via ':filterHandle'. Failing to do so will cause unexpected side-effects for threads\
    that don't use 'titaniumEvents'. As a rule, ':handle' shouldn't be called manually.\
\
    Thread status can be managed with the 'finish' callback. If the thread crashes, the exception will be passed to that callback\
]]\
\
class Thread mixin MCallbackManager {\
    running = false;\
\
    func = false;\
    co = false;\
\
    filter = false;\
    exception = false;\
\
    crashSilently = false;\
\
    titaniumEvents = false;\
}\
\
--[[\
    @instance\
    @desc Constructs the instance and starts the thread by invoking ':start'\
    @param <function - func>, [boolean - titaniumEvents], [crashSilently - boolean], [string - id]\
]]\
function Thread:__init__( ... )\
    self:resolve( ... )\
    self:start()\
end\
\
--[[\
    @instance\
    @desc Starts the thread by setting 'running' to true, resetting 'filter' and wrapping 'func' in a coroutine\
]]\
function Thread:start()\
    self.co = coroutine.create( self.func )\
    self.running = true\
    self.filter = false\
end\
\
--[[\
    @instance\
    @desc Stops the thread by setting 'running' to false, preventing events from being handled\
]]\
function Thread:stop()\
    self.running = false\
end\
\
--[[\
    @instance\
    @desc The preferred way of delivering events to a thread. Processes the given event, passing relevant information to ':handle' depending on the value of 'titaniumEvents'.\
\
          If 'titaniumEvents' is true, the event will be passed as is. If 'false', the event data will be unpacked before being sent.\
    @param <Event Instance - eventObj>\
]]\
function Thread:filterHandle( eventObj )\
    if self.titaniumEvents then\
        self:handle( eventObj )\
    else\
        self:handle( unpack( eventObj.data ) )\
    end\
end\
\
--[[\
    @instance\
    @desc The raw handle method, shouldn't be called manually. Passes the given argument(s) to the coroutine. The first argument is assumed to be the event\
          itself (either the CC event name, or the event instance) and is used to determine if the event matches the filter (if set).\
    @param <Event Instance - eventObj> - Expected arguments when 'titaniumEvents' is true\
    @param <string - eventName>, <eventDetails - ...> - Expected arguments when 'titaniumEvents' is false\
]]\
function Thread:handle( ... )\
    if not self.running then return false end\
\
    local tEvents, cFilter, eMain, co, ok, filter = self.titaniumEvents, self.filter, select( 1, ... ), self.co\
    if tEvents then\
        if not cFilter or ( eMain:is( cFilter ) or eMain:is( \"terminate\" ) ) then\
            ok, filter = coroutine.resume( co, eMain )\
        else return end\
    else\
        if not cFilter or ( eMain == cFilter or eMain == \"terminate\" ) then\
            ok, filter = coroutine.resume( co, ... )\
        else return end\
    end\
\
    if ok then\
        if coroutine.status( co ) == \"dead\" then\
            self.running = false\
        end\
\
        self.filter = filter\
    else\
        self.exception = filter\
        self.running = false\
\
        if not self.crashSilently then\
            error( tostring( self ) .. \" coroutine exception: \" .. tostring( filter ) )\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Updates 'running' property and invokes the 'finish' callback. If the thread crashed, the exception is passed to the callback too.\
    @param <boolean - running>\
]]\
function Thread:setRunning( running )\
    self.running = running\
\
    if not running then\
        self:executeCallbacks( \"finish\", self.exception )\
    end\
end\
\
configureConstructor {\
    orderedArguments = { \"func\", \"titaniumEvents\", \"crashSilently\", \"id\" },\
    requiredArguments = { \"func\" }\
}",
  [ "Canvas.ti" ] = "local tableInsert, tableRemove = table.insert, table.remove\
local function range( xBoundary, xDesired, width, canvasWidth )\
    local x1 = xBoundary > xDesired and 1 - xDesired or 1\
    local x2 = xDesired + width > canvasWidth and canvasWidth - xDesired or width\
\
    return x1, x2\
end\
\
--[[\
    @instance buffer - table (def. {}) - A one-dimensional table containing all the pixels inside the canvas. Pixel format: { char, fg, bg }\
    @instance last - table (def. {}) - A copy of buffer that is used to determine if the line has changed. If a pixel in the buffer doesn't match the same pixel in 'last', the line is redrawn\
    @instance width - number (def. 51) - The width of the canvas. Determines how many pixels pass before the next line starts\
    @instance height - number (def. 19) - The height of the canvas\
    @instance backgroundColour - colour, boolean, nil (def. 32768) - The background colour of the canvas. This is only used for pixels that do not have their own bg colour. If false/nil, the bg is left blank for the next parent to resolve. If '0', the background colour of the pixel under it is used (transparent)\
    @instance colour - colour, boolean, nil (def. 32768) - The foreground colour of the canvas. This is only used for pixels that do not have their own fg colour. If false/nil, the fg is left blank for the next parent to resolve. If '0', the colour of the pixel under it is used (transparent)\
    @instance backgroundTextColour - colour, nil (def. nil) - Only used when the pixels character is nil/false. If the pixel has no character, the character of the pixel under it is used (transparent). In this case, the foreground used to draw the pixel character is this property if set. If this property is not set, the foreground colour of the pixel under it is used instead\
    @instance backgroundChar - string, nil (def. nil) - The default character used for each pixel when the canvas is cleared and NOT transparent. If nil, no character is used (transparent)\
    @instance transparent - boolean, nil (def. nil) - When true, acts very similar to using backgroundChar 'nil' with the difference that the backgroundColour of cleared pixels is '0' (transparent)\
\
    The Canvas object is used by all components. It facilitates the drawing of pixels which are stored in its buffer.\
\
    The Canvas object is abstract. If you need a canvas for your object 'NodeCanvas' and 'TermCanvas' are provided with Titanium and may suite your needs.\
]]\
\
abstract class Canvas {\
    buffer = {};\
    last = {};\
\
    width = 51;\
    height = 19;\
\
    backgroundColour = 32768;\
    colour = 1;\
\
    transparent = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs the canvas instance and binds it with the owner supplied.\
    @param <ClassInstance - owner>\
]]\
function Canvas:__init__( owner )\
    self.raw.owner = Titanium.isInstance( owner ) and owner or error(\"Invalid argument for Canvas. Expected instance owner, got '\"..tostring( owner )..\"'\")\
    self.raw.width = owner.raw.width\
    self.raw.height = owner.raw.height\
\
    self.raw.colour = owner.raw.colour\
    self.raw.backgroundChar = owner.raw.backgroundChar\
    if self.raw.backgroundChar == \"nil\" then\
        self.raw.backgroundChar = nil\
    end\
    self.raw.backgroundTextColour = owner.raw.backgroundTextColour\
    self.raw.backgroundColour = owner.raw.backgroundColour\
    self.raw.transparent = owner.raw.transparent\
\
    self:clear()\
end\
\
--[[\
    @instance\
    @desc Replaces the canvas with a blank one\
    @param [number - colour]\
]]\
function Canvas:clear( colour )\
    local pixel, buffer = { not self.transparent and self.backgroundChar, self.colour, self.transparent and 0 or colour or self.backgroundColour }, self.buffer\
\
    for index = 1, self.width * self.height do\
        buffer[ index ] = pixel\
    end\
end\
\
--[[\
    @instance\
    @desc Clears an area of the canvas defined by the arguments provided.\
    @param <number - areaX>, <number - areaY>, <number - areaWidth>, <number - areaHeight>, [number - colour]\
]]\
function Canvas:clearArea( aX, aY, aWidth, aHeight, colour )\
    local aY, aX, cWidth = aY > 0 and aY - 1 or 0, aX > 0 and aX - 1 or 0, self.width\
    local pixel, buffer = { not self.transparent and self.backgroundChar, self.colour, self.transparent and 0 or colour or self.backgroundColour }, self.buffer\
\
    local xBoundary, yBoundary = cWidth - aX, self.height\
    local effectiveWidth = xBoundary < aWidth and xBoundary or aWidth\
    for y = 0, -1 + ( aHeight < yBoundary and aHeight or yBoundary ) do\
        local pos = aX + ( y + aY ) * cWidth\
        for x = 1, effectiveWidth do\
            buffer[ pos + x ] = pixel\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Updates the transparency setting of the canvas and then clears the canvas to apply this setting\
    @param <number - colour>\
]]\
function Canvas:setTransparent( transparent )\
    self.transparent = transparent\
    self:clear()\
end\
\
--[[\
    @setter\
    @desc Updates the colour of the canvas and then clears the canvas\
    @param <number - colour>\
]]\
function Canvas:setColour( colour )\
    self.colour = colour\
    self:clear()\
end\
\
--[[\
    @setter\
    @desc Updates the background colour of the canvas and then clears the canvas\
    @param <number - backgroundColour>\
]]\
function Canvas:setBackgroundColour( backgroundColour )\
    self.backgroundColour = backgroundColour\
    self:clear()\
end\
\
--[[\
    @setter\
    @desc Updates the background character to be used when clearing the canvas. Clears the canvas to apply the change\
    @param <string/false/nil - char>\
]]\
function Canvas:setBackgroundChar( char )\
    self.backgroundChar = char\
    self:clear()\
end\
\
--[[\
    @setter\
    @desc Updates the canvas width, and then clears the canvas to apply the change\
]]\
function Canvas:setWidth( width )\
\009local pixel = { not self.transparent and self.backgroundChar, self.colour, self.transparent and 0 or colour or self.backgroundColour }\
\
    local sWidth, sHeight, buffer = self.width, self.height, self.buffer\
    while width > sWidth do\
        -- If the width is greater than the current canvas width, add the extra pixels\
        for rowIndex = 1, sHeight do\
            -- Iterate over each row, adding a new pixel to the end of each (ie: width of the row + 1)\
            tableInsert( buffer, ( sWidth + 1 ) * rowIndex, pixel )\
        end\
\
        -- Update the width to account for the new pixels\
        sWidth = sWidth + 1\
    end\
\
    while width < sWidth do\
        -- Update the width to account for the removed pixels\
        sWidth = sWidth - 1\
\
        -- If the width is less than the current canvas width, remove the excess pixels\
        for rowIndex = 1, sHeight do\
            -- Remove the last pixel on this row\
            tableRemove( buffer, sWidth * rowIndex )\
        end\
    end\
\
    -- sWidth and width are equal now. Set the canvas width property to the width specified\
    self.width = width\
end\
\
--[[\
    @setter\
    @desc Updates the canvas height, and then clears the canvas to apply the change\
]]\
function Canvas:setHeight( height )\
\009local pixel = { not self.transparent and self.backgroundChar, self.colour, self.transparent and 0 or colour or self.backgroundColour }\
\
    local sWidth, sHeight, buffer = self.width, self.height, self.buffer\
    while height > sHeight do\
        -- The new height is greater than the current height. Add the extra rows. No need for table.insert here as no pixels lie ahead\
        for i = 1, sWidth do\
            -- Add a new pixel to the end of the array for every pixel in a row (width)\
            buffer[ #buffer + 1 ] = pixel\
        end\
\
        sHeight = sHeight + 1\
    end\
\
    while height < sHeight do\
        -- The new width is less than the current height. Remove the excess rows\
        for i = 1, sWidth do\
            -- Remove the last pixel in the array for every pixel in a row (width)\
            buffer[ #buffer ] = nil\
        end\
\
        sHeight = sHeight - 1\
    end\
\
    -- sHeight and height are equal now. Set the canvas height property to the height specified\
    self.height = height\
end\
\
--[[\
    @instance\
    @desc Draws the canvas to the target 'canvas' using the X and Y offsets. Pixel character, foreground and background colours are resolved according to their property values.\
    @param <Canvas - canvas>, [number - offsetX], [number - offsetY]\
]]\
function Canvas:drawTo( canvas, offsetX, offsetY )\
    local offsetX = offsetX - 1 or 0\
    local offsetY = offsetY - 1 or 0\
\
    local sRaw, tRaw = self.raw, canvas.raw\
    local width, height, buffer = sRaw.width, sRaw.height, sRaw.buffer\
    local tWidth, tHeight, tBuffer = tRaw.width, tRaw.height, tRaw.buffer\
\
    local colour, backgroundColour, backgroundTextColour = sRaw.colour, sRaw.backgroundColour, sRaw.backgroundTextColour\
    local xStart, xEnd = range( 1, offsetX, width, tWidth )\
\
    local cache, tCache, top, tc, tf, tb, bot, bc, bf, bb, tPos = 0, offsetX + ( offsetY * tWidth )\
    for y = 1, height do\
        local cY = y + offsetY\
        if cY >= 1 and cY <= tHeight then\
            for x = xStart, xEnd do\
                top = buffer[ cache + x ]\
                tc, tf, tb, tPos = top[ 1 ], top[ 2 ], top[ 3 ], tCache + x\
                bot = tBuffer[ tPos ]\
                bc, bf, bb = bot[ 1 ], bot[ 2 ], bot[ 3 ]\
\
                if tc and ( tf and tf ~= 0 ) and ( tb and tb ~= 0 ) then\
                    tBuffer[ tPos ] = top\
                elseif not tc and tf == 0 and tb == 0 and bc and bf ~= 0 and bb ~= 0 then\
                    tBuffer[ tPos ] = bot\
                else\
                    local nc, nf, nb = tc or bc, tf or colour, tb or backgroundColour\
\
                    if not tc then\
                        nf = backgroundTextColour or bf\
                    end\
\
                    tBuffer[ tPos ] = { nc, nf == 0 and bf or nf, nb == 0 and bb or nb }\
                end\
            end\
        elseif cY > tHeight then\
            break\
        end\
\
        cache = cache + width\
        tCache = tCache + tWidth\
    end\
end",
  [ "Tween.ti" ] = "--[[\
    @static easing - table (def. {}) - If a string is provided as the easing during instantiation, instead of a function, the easing function is searched for inside this table\
\
    @instance object - Instance (def. false) - The Titanium instance on which the target property will be animated\
    @instance property - string (def. false) - The target property that will be animated on the object\
    @instance initial - number (def. false) - The initial value of the property. Automatically set during instantiation\
    @instance final - number (def. false) - The target value for the property\
    @instance duration - number (def. 0) - The amount of time the animation will take to animate the property from 'initial' to 'final'\
    @instance clock - number (def. 0) - How far through the animation the instance is\
    @instance easing - function (def. nil) - The easing function to be used during the animation\
\
    The Tween class is Titaniums animation class (tween meaning in between values (from -> to)). However, Tween should not be used\
    to create animations, using :animate (on supporting instances, like any child class of 'Node') is preferred.\
\
    When animating, an easing can be set. If this easing is a string, it is searched for in 'Tween.static.easing'. All easing functions\
    shipped with Titanium are automatically imported via the Titanium starting script (src/scripts/Titanium.lua). Custom easing\
    functions can be created using the static function Tween.static.addEasing, or by manually adding them to the static 'easing' table.\
]]\
\
class Tween {\
    static = {\
        easing = {}\
    };\
\
    object = false;\
\
    property = false;\
    initial = false;\
    final = false;\
\
    duration = 0;\
    clock = 0;\
}\
\
--[[\
    @constructor\
    @desc Constructs the tween instance, converting the 'easing' property into a function (if it's a string) and also stores the initial value of the property for later use.\
    @param <Object - object>, <string - name>, <string - property>, <number - final>, <number - duration>, [string/function - easing]\
]]\
function Tween:__init__( ... )\
    self:resolve( ... )\
    if not Titanium.isInstance( self.object ) then\
        return error(\"Argument 'object' for tween must be a Titanium instance. '\"..tostring( self.object )..\"' is not a Titanium instance.\")\
    end\
\
    local easing = self.easing or \"linear\"\
    if type( easing ) == \"string\" then\
        self.easing = Tween.static.easing[ easing ] or error(\"Easing type '\"..tostring( easing )..\"' could not be found in 'Tween.static.easing'.\")\
    elseif type( easing ) == \"function\" then\
        self.easing = easing\
    else\
        return error \"Tween easing invalid. Must be a function to be invoked or name of easing type\"\
    end\
\
    self.initial = self.object[ self.property ]\
    self.clock = 0\
end\
\
--[[\
    @instance\
    @desc Sets the 'property' of 'object' to the rounded (down) result of the easing function selected. Passes the current clock time, the initial value, the difference between the initial and final values and the total Tween duration.\
]]\
function Tween:performEasing()\
    self.object[ self.property ] = math.floor( self.easing( self.clock, self.initial, self.final - self.initial, self.duration ) + .5 )\
end\
\
--[[\
    @instance\
    @desc Updates the tween by increasing 'clock' by 'dt' via the setter 'setClock'\
    @param <number - dt>\
    @return <boolean - finished>\
]]\
function Tween:update( dt )\
    return self:setClock( self.clock + dt )\
end\
\
--[[\
    @instance\
    @desc Sets the clock time to zero\
    @param <boolean - finished>\
]]\
function Tween:reset()\
    return self:setClock( 0 )\
end\
\
--[[\
    @setter\
    @desc Sets the current 'clock'. If the clock is a boundary number, it is adjusted to match the boundary - otherwise it is set as is. Once set, 'performEasing' is called and the state of the Tween (finished or not) is returned\
    @param <number - clock>\
    @return <boolean - finished>\
]]\
function Tween:setClock( clock )\
    if clock <= 0 then\
        self.clock = 0\
    elseif clock >= self.duration then\
        self.clock = self.duration\
    else\
        self.clock = clock\
    end\
\
    self:performEasing()\
    return self.clock >= self.duration\
end\
\
--[[\
    @static\
    @desc Binds the function 'easingFunction' to 'easingName'. Whenever an animation that uses easing of type 'easingName' is updated, this function will be called to calculate the value\
    @param <string - easingName>, <function - easingFunction>\
    @return <Class Base - Tween>\
]]\
function Tween.static.addEasing( easingName, easingFunction )\
    if type( easingFunction ) ~= \"function\" then\
        return error \"Easing function must be of type 'function'\"\
    end\
\
    Tween.static.easing[ easingName ] = easingFunction\
    return Tween\
end\
\
configureConstructor {\
    orderedArguments = { \"object\", \"name\", \"property\", \"final\", \"duration\", \"easing\", \"promise\" },\
    requiredArguments = { \"object\", \"name\", \"property\", \"final\", \"duration\" },\
    argumentTypes = {\
        name = \"string\",\
        property = \"string\",\
        final = \"number\",\
        duration = \"number\",\
        promise = \"function\"\
    }\
}",
  [ "ScrollContainer.ti" ] = "--[[\
    @instance cache - table (def. {}) - Contains information cached via the caching methods\
    @instance mouse - table (def. { ... }) - Contains information regarding the currently selected scrollbar, and the origin of the mouse event\
    @instance xScroll - number (def. 0) - The horizontal scroll offset\
    @instance yScroll - number (def. 0) - The vertical scroll offset\
    @instance xScrollAllowed - boolean (def. true) - If false, horizontal scrolling is not allowed (scrollbar will not appear, and mouse events will be ignored)\
    @instance yScrollAllowed - boolean (def. true) - If false, vertical scrolling is not allowed (scrollbar will not appear, and mouse events will be ignored)\
    @instance propagateMouse - boolean (def. false) - If false, all incoming mouse events will be handled\
    @instance trayColour - colour (def. 256) - The colour of the scrollbar tray (where the scrollbar is not occupying)\
    @instance scrollbarColour - colour (def. 128) - The colour of the scrollbar itself\
    @instance activeScrollbarColour - colour (def. 512) - The colour of the scrollbar while being held (mouse)\
\
    The ScrollContainer node is a more complex version of Container, allowing for horizontal and vertical scrolling.\
]]\
\
class ScrollContainer extends Container {\
    cache = {};\
\
    xScroll = 0;\
    yScroll = 0;\
\
    xScrollAllowed = true;\
    yScrollAllowed = true;\
    propagateMouse = true;\
\
    trayColour = 256;\
    scrollbarColour = 128;\
    activeScrollbarColour = colours.cyan;\
\
    mouse = {\
        selected = false;\
        origin = false;\
    };\
}\
\
--[[\
    @constructor\
    @desc Registers 'scrollbarColour', 'activeScrollbarColour', 'trayColour' as theme properties and invokes the Container constructor with ALL properties passed to this constructor\
    @param <... - args>\
]]\
function ScrollContainer:__init__( ... )\
    self:register( \"scrollbarColour\", \"activeScrollbarColour\", \"trayColour\" )\
    self:super( ... )\
end\
\
--[[\
    @instance\
    @desc Handles a mouse click by moving the scrollbar (if click occurred on tray) or activating a certain scrollbar (allows mouse_drag manipulation) if the click was on the scrollbar.\
\
          If mouse click occurred off of the scroll bar, event is not handled and children nodes can make use of it.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function ScrollContainer:onMouseClick( event, handled, within )\
    if handled or not within then return end\
\
    local cache, mouse, key = self.cache, self.mouse\
    local X, Y = event.X - self.X + 1, event.Y - self.Y + 1\
\
    if cache.yScrollActive and X == self.width and Y <= cache.displayHeight then\
        key = \"y\"\
    elseif cache.xScrollActive and Y == self.height and X <= cache.displayWidth then\
        key = \"x\"\
    else return end\
\
    local scrollFn = self[ \"set\"..key:upper()..\"Scroll\" ]\
    local edge, size = cache[ key .. \"ScrollPosition\" ], cache[ key .. \"ScrollSize\" ]\
    local cScale, dScale = cache[ \"content\" .. ( key == \"x\" and \"Width\" or \"Height\" ) ], cache[ \"display\" .. ( key == \"x\" and \"Width\" or \"Height\" ) ]\
\
    local rel = key == \"x\" and X or Y\
    if rel < edge then\
        event.handled = scrollFn( self, math.floor( cScale * ( rel / dScale ) - .5 ) )\
    elseif rel >= edge and rel <= edge + size - 1 then\
        mouse.selected, mouse.origin = key == \"x\" and \"h\" or \"v\", rel - edge + 1\
    elseif rel > edge + size - 1 then\
        event.handled = scrollFn( self, math.floor( cScale * ( ( rel - size + 1 ) / dScale ) - .5 ) )\
    end\
\
    self:cacheScrollbarPosition()\
    self.changed = true\
end\
\
--[[\
    @instance\
    @desc Moves the scroll of the ScrollContainer depending on the scroll direction and whether or not shift is held.\
\
          Scrolling that occurs while the shift key is held (or if there is ONLY a horizontal scrollbar) will adjust the horizontal scroll. Otherwise, the vertical scroll will be affected\
          if present.\
    @param <MouseEvent - event>, <boolean - handled>, <boolean - within>\
]]\
function ScrollContainer:onMouseScroll( event, handled, within )\
    local cache, app = self.cache, self.application\
    if handled or not within or not ( cache.xScrollActive or cache.yScrollActive ) then return end\
\
    local isXScroll = ( cache.xScrollActive and ( not cache.yScrollActive or ( app:isPressed( keys.leftShift ) or app:isPressed( keys.rightShift ) ) ) )\
\
    event.handled = self[\"set\".. ( isXScroll and \"X\" or \"Y\" ) ..\"Scroll\"]( self, self[ ( isXScroll and \"x\" or \"y\" ) .. \"Scroll\" ] + event.button )\
    self:cacheScrollbarPosition()\
end\
\
--[[\
    @instance\
    @desc If a scrollbar was selected, it is deselected preventing mouse_drag events from further manipulating it.\
    @param <MouseEvent - event>, <boolean - handled>, <boolean - within>\
]]\
function ScrollContainer:onMouseUp( event, handled, within )\
    if self.mouse.selected then\
        self.mouse.selected = false\
        self.changed = true\
    end\
end\
\
--[[\
    @instance\
    @desc If a scrollbar is selected it's value is manipulated when dragged\
    @param <MouseEvent - event>, <boolean - handled>, <boolean - within>\
]]\
function ScrollContainer:onMouseDrag( event, handled, within )\
    local mouse, cache = self.mouse, self.cache\
    if handled or not mouse.selected then return end\
\
    local isV = mouse.selected == \"v\"\
    local key = isV and \"Y\" or \"X\"\
    local scaleKey = isV and \"Height\" or \"Width\"\
\
    event.handled = self[ \"set\" .. key .. \"Scroll\" ]( self, math.floor( cache[\"content\" .. scaleKey ] * ( ( ( event[ key ] - self[ key ] + 1 ) - mouse.origin ) / cache[\"display\" .. scaleKey ] ) - .5 ) )\
end\
\
--[[\
    @instance\
    @desc Calls the super :addNode with all arguments passed to the function, re-caches the content and returns the node (arg #1)\
    @param <Node Instance - node>, <... - args>\
    @return <Node Instance - node>\
]]\
function ScrollContainer:addNode( node, ... )\
    self.super:addNode( node, ... )\
    self:cacheContent()\
\
    return node\
end\
\
--[[\
    @instance\
    @desc A custom handle function that adjusts the values of incoming mouse events to work correctly with scroll offsets\
    @param <Event Instance - eventObj>\
    @return <boolean - propagate>\
]]\
function ScrollContainer:handle( eventObj )\
    local cache = self.cache\
    local cloneEv\
\
    if not self.super.super:handle( eventObj ) then return end\
\
    if self.projector and not self.mirrorProjector and not eventObj.projectorOrigin then\
        self.resolvedProjector:handleEvent( eventObj )\
        return\
    end\
\
    if eventObj.main == \"MOUSE\" then\
        -- eventObj.isWithin = eventObj:withinParent( self )\
        if ( not cache.yScrollActive or ( eventObj.X - self.X + 1 ) ~= self.width ) and ( not cache.xScrollActive or ( eventObj.Y - self.Y + 1 ) ~= self.height ) then\
            cloneEv = eventObj:clone( self )\
            cloneEv.isWithin = cloneEv.isWithin and eventObj:withinParent( self ) or false\
            cloneEv.Y = cloneEv.Y + self.yScroll\
            cloneEv.X = cloneEv.X + self.xScroll\
        end\
    else cloneEv = eventObj end\
\
    if cloneEv then self:shipEvent( cloneEv ) end\
    -- local r = self.super.super:handle( eventObj )\
\
    -- eventObj.isWithin = isWithin\
    if cloneEv and cloneEv.isWithin and ( self.consumeAll or cloneEv.handled ) then\
        eventObj.handled = true\
    end\
\
    -- return r\
end\
\
--[[\
    @instance\
    @desc Returns true if the node, with respect to the horizontal and vertical scroll is within the bounds of the container\
    @param <Node Instance - node>, [number - width], [number - height]\
    @return <boolean - inBounds>\
]]\
function ScrollContainer:isNodeInBounds( node, width, height )\
    local left, top = node.X - self.xScroll, node.Y - self.yScroll\
\
    return not ( ( left + node.width ) < 1 or left > ( width or self.width ) or top > ( height or self.height ) or ( top + node.height ) < 1 )\
end\
\
--[[\
    @instance\
    @desc Invokes the Container draw function, offsetting the draw with the horizontal/vertical scroll.\
\
          After draw, the ScrollContainers scrollbars are drawn (:drawScrollbars)\
    @param [boolean - force]\
]]\
function ScrollContainer:draw( force )\
    if self.changed or force then\
        self.super:draw( force, -self.xScroll, -self.yScroll )\
        self:drawScrollbars()\
    end\
end\
\
--[[\
    @instance\
    @desc Draws the enabled scrollbars. If both horizontal and vertical scrollbars are enabled, the bottom-right corner is filled in to prevent a single line of transparent space\
]]\
function ScrollContainer:drawScrollbars()\
    local cache, canvas = self.cache, self.canvas\
    local xEnabled, yEnabled = cache.xScrollActive, cache.yScrollActive\
\
    if xEnabled then\
        canvas:drawBox( 1, self.height, cache.displayWidth, 1, self.trayColour )\
        canvas:drawBox( cache.xScrollPosition, self.height, cache.xScrollSize, 1, self.mouse.selected == \"h\" and self.activeScrollbarColour or self.scrollbarColour )\
    end\
\
    if yEnabled then\
        canvas:drawBox( self.width, 1, 1, cache.displayHeight, self.trayColour )\
        canvas:drawBox( self.width, cache.yScrollPosition, 1, cache.yScrollSize, self.mouse.selected == \"v\" and self.activeScrollbarColour or self.scrollbarColour )\
    end\
\
    if yEnabled and xEnabled then\
        canvas:drawPoint( self.width, self.height, \" \", 1, self.trayColour )\
    end\
end\
\
--[[\
    @instance\
    @desc Invokes the super :redrawArea, offset by the scroll containers horizontal and vertical scroll\
    @param <number - x>, <number - y>, <number - width>, <number - height>\
]]\
function ScrollContainer:redrawArea( x, y, width, height )\
    self.super:redrawArea( x, y, width, height, -self.xScroll, -self.yScroll )\
end\
\
--[[\
    @setter\
    @desc Sets 'yScroll', ensuring it doesn't go out of range. The position of the scrollbars are re-cached to reflect the new scroll position.\
\
          If the new scroll value is not the same as the old value, OR 'propagateMouse' is false, 'true' will be returned\
    @param <number - yScroll>\
    @return <boolean - consume>\
]]\
function ScrollContainer:setYScroll( yScroll )\
    local oY, cache = self.yScroll, self.cache\
    self.yScroll = math.max( 0, math.min( cache.contentHeight - cache.displayHeight, yScroll ) )\
\
    self:cacheScrollbarPosition()\
    if ( not self.propagateMouse ) or oY ~= self.yScroll then\
        return true\
    end\
end\
\
--[[\
    @setter\
    @desc Sets 'xScroll', ensuring it doesn't go out of range. The position of the scrollbars are re-cached to reflect the new scroll position.\
\
          If the new scroll value is not the same as the old value, OR 'propagateMouse' is false, 'true' will be returned\
    @param <number - xScroll>\
    @return <boolean - consume>\
]]\
function ScrollContainer:setXScroll( xScroll )\
    local oX, cache = self.xScroll, self.cache\
    self.xScroll = math.max( 0, math.min( cache.contentWidth - cache.displayWidth, xScroll ) )\
\
    self:cacheScrollbarPosition()\
    if ( not self.propagateMouse ) or oX ~= self.xScroll then\
        return true\
    end\
end\
\
--[[\
    @instance\
    @desc Invokes the super setter for 'height', and caches the content information (:cacheContent)\
    @param <number - height>\
]]\
function ScrollContainer:setHeight( height )\
    self.super:setHeight( height )\
    self:cacheContent()\
\
    local cache = self.cache\
    self.yScroll = math.max( 0, math.min( cache.contentHeight - cache.displayHeight, self.yScroll ) )\
end\
\
--[[\
    @instance\
    @desc Invokes the super setter for 'width', and caches the content information (:cacheContent)\
    @param <number - width>\
]]\
function ScrollContainer:setWidth( width )\
    self.super:setWidth( width )\
    self:cacheContent()\
\
    local cache = self.cache\
    self.xScroll = math.max( 0, math.min( cache.contentWidth - cache.displayWidth, self.xScroll ) )\
end\
\
--[[ Caching Functions ]]--\
function ScrollContainer:cacheContent()\
    self:cacheContentSize()\
    self:cacheActiveScrollbars()\
end\
\
--[[\
    @instance\
    @desc Finds the width and height bounds of the content and caches it inside 'contentWidth' and 'contentHeight' respectively\
]]\
function ScrollContainer:cacheContentSize()\
    local w, h = 0, 0\
\
    local nodes, node = self.nodes\
    for i = 1, #nodes do\
        node = nodes[ i ]\
\
        w = math.max( node.X + node.width - 1, w )\
        h = math.max( node.Y + node.height - 1, h )\
    end\
\
    self.cache.contentWidth, self.cache.contentHeight = w, h\
end\
\
--[[\
    @instance\
    @desc Caches the display size of the container, with space made for the scrollbars (width - 1 if vertical scroll active, height - 1 if horizontal scroll active).\
\
          If 'single', the next cache function will not be called, allowing for other nodes to insert custom logic\
    @param [boolean - single]\
]]\
function ScrollContainer:cacheDisplaySize( single )\
    local cache = self.cache\
    cache.displayWidth, cache.displayHeight = self.width - ( cache.yScrollActive and 1 or 0 ), self.height - ( cache.xScrollActive and 1 or 0 )\
\
    if not single then self:cacheScrollbarSize() end\
end\
\
--[[\
    @instance\
    @desc Caches the active scrollbars. If the contentWidth > displayWidth then the horizontal scrollbar is active. If the contentHeight > displayHeight then the vertical scrollbar is active.\
]]\
function ScrollContainer:cacheActiveScrollbars()\
    local cache = self.cache\
    local cWidth, cHeight, sWidth, sHeight = cache.contentWidth, cache.contentHeight, self.width, self.height\
    local xAllowed, yAllowed = self.xScrollAllowed, self.yScrollAllowed\
\
    local horizontal, vertical\
    if ( cWidth > sWidth and xAllowed ) or ( cHeight > sHeight and yAllowed ) then\
        cache.xScrollActive, cache.yScrollActive = cWidth > sWidth - 1 and xAllowed, cHeight > sHeight - 1 and yAllowed\
    else\
        cache.xScrollActive, cache.yScrollActive = false, false\
    end\
\
    self:cacheDisplaySize()\
end\
\
--[[\
    @instance\
    @desc Calculates the width/height of the active scrollbar(s) using the content size, and display size\
]]\
function ScrollContainer:cacheScrollbarSize()\
    local cache = self.cache\
    cache.xScrollSize, cache.yScrollSize = math.floor( cache.displayWidth * ( cache.displayWidth / cache.contentWidth ) + .5 ), math.floor( cache.displayHeight * ( cache.displayHeight / cache.contentHeight ) + .5 )\
\
    self:cacheScrollbarPosition()\
end\
\
--[[\
    @instance\
    @desc Uses the xScroll and yScroll properties to calculate the visible position of the active scrollbar(s)\
]]\
function ScrollContainer:cacheScrollbarPosition()\
    local cache = self.cache\
    cache.xScrollPosition, cache.yScrollPosition = math.ceil( self.xScroll / cache.contentWidth * cache.displayWidth + .5 ), math.ceil( self.yScroll / cache.contentHeight * cache.displayHeight + .5 )\
\
    self.changed = true\
    self:redrawArea( 1, 1, self.width, self.height )\
end\
\
configureConstructor {\
    argumentTypes = {\
        scrollbarColour = \"colour\",\
        activeScrollbarColour = \"colour\",\
        xScrollAllowed = \"boolean\",\
        yScrollAllowed = \"boolean\"\
    }\
}",
  [ "MKeyHandler.ti" ] = "--[[\
    The key handler mixin facilitates common features of objects that utilize key events. The mixin can manage hotkeys and will check them for validity\
    when a key event is caught.\
]]\
\
abstract class MKeyHandler {\
    static = {\
        keyAlias = {}\
    };\
\
    keys = {};\
    hotkeys = {};\
}\
\
--[[\
    @instance\
    @desc 'Handles' a key by updating its status in 'keys'. If the event was a key down, it's status will be set to false if not held and true if it is.\
          If the event is a key down, the key's status will be set to nil (use this to detect if a key is not pressed).\
          The registered hotkeys will be updated every time this function is called.\
    @param <KeyEvent - event>\
]]\
function MKeyHandler:handleKey( event )\
    local keyCode = event.keyCode\
    if event.sub == \"DOWN\" then\
        self.keys[ keyCode ] = event.held\
        self:checkHotkeys( keyCode )\
    else\
        self.keys[ keyCode ] = nil\
        self:checkHotkeys()\
    end\
end\
\
--[[\
    @instance\
    @desc Returns true if a key is pressed (regardless of held state) and false otherwise\
    @param <number - keyCode>\
    @return <boolean - isPressed>\
]]\
function MKeyHandler:isPressed( keyCode )\
    return self.keys[ keyCode ] ~= nil\
end\
\
--[[\
    @instance\
    @desc Returns true if the key is pressed and held, or false otherwise\
    @param <number - keyCode>\
    @return <boolean - isHeld>\
]]\
function MKeyHandler:isHeld( keyCode )\
    return self.keys[ keyCode ]\
end\
\
--[[\
    @instance\
    @desc Breaks 'hotkey' into key names and check their status. The last element of the hotkey must be pressed last (be the active key)\
          Hotkey format \"leftCtrl-leftShift-t\" (keyName-keyName-keyName)\
    @param <string - hotkey>, [number - key]\
    @return <boolean - hotkeyMatch>\
]]\
function MKeyHandler:matchesHotkey( hotkey, key )\
    for segment in hotkey:gmatch \"(%w-)%-\" do\
\009\009if self.keys[ keys[ segment ] ] == nil then\
\009\009\009return false\
        end\
\009end\
\
\009return key == keys[ hotkey:gsub( \".+%-\", \"\" ) ]\
end\
\
--[[\
    @instance\
    @desc Registers a hotkey by adding it's callback and hotkey string to the handlers 'hotkeys'.\
    @param <string - name>, <string - hotkey>, <function - callback>\
]]\
function MKeyHandler:registerHotkey( name, hotkey, callback )\
    if not ( type( name ) == \"string\" and type( hotkey ) == \"string\" and type( callback ) == \"function\" ) then\
        return error \"Expected string, string, function\"\
    end\
\
    self.hotkeys[ name ] = { hotkey, callback }\
end\
\
--[[\
    @instance\
    @desc Iterates through the registered hotkeys and checks for matches using 'matchesHotkey'. If a hotkey matches it's registered callback is invoked\
    @param [number - key]\
]]\
function MKeyHandler:checkHotkeys( key )\
    for _, hotkey in pairs( self.hotkeys ) do\
        if self:matchesHotkey( hotkey[ 1 ], key ) then\
            hotkey[ 2 ]( self, key )\
        end\
    end\
end",
  [ "MThemeManager.ti" ] = "--[[\
    The MThemeManager mixin should be used by classes that want to manage objects which are themeable, the main example being the 'Application' class.\
]]\
\
abstract class MThemeManager {\
    themes = {}\
}\
\
--[[\
    @instance\
    @desc Adds the given theme into this objects `themes` table and re-groups the themes\
    @param <Theme Instance - theme>\
]]\
function MThemeManager:addTheme( theme )\
    self:removeTheme( theme )\
    table.insert( self.themes, theme )\
\
    self:groupRules()\
end\
\
--[[\
    @instance\
    @desc Removes the given theme from this objects `themes` table. Returns true if a theme was removed, false otherwise.\
\
          Re-groups the themes afterwards\
    @param <Instance 'Theme'/string name - target>\
    @return <boolean - success>\
]]\
function MThemeManager:removeTheme( target )\
    local searchName = ( type( target ) == \"string\" and true ) or ( not Titanium.typeOf( target, \"Theme\", true ) and error \"Invalid target to remove\" )\
    local themes = self.themes\
    for i = 1, #themes do\
        if ( searchName and themes[ i ].name == target ) or ( not searchName and themes[ i ] == target ) then\
            table.remove( themes, i )\
            self:groupRules()\
\
            return true\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Adds a theme instance named 'name' and imports the file contents from 'location' to this object\
    @param <string - name>, <string - location>\
]]\
function MThemeManager:importTheme( name, location )\
    self:addTheme( Theme.fromFile( name, location ) )\
end\
\
--[[\
    @instance\
    @desc Merges all the themes together into one theme, and groups properties by query to avoid running identical queries multiple times.\
\
          Saves grouped rules to 'rules', and calls :dispatchThemeRules\
]]\
function MThemeManager:groupRules()\
    local themes, outputRules = self.themes, {}\
    for i = 1, #themes do\
        for type, rules in pairs( themes[ i ].rules ) do\
            if not outputRules[ type ] then outputRules[ type ] = {} end\
\
            local outputRulesType = outputRules[ type ]\
            for query, rules in pairs( rules ) do\
                if not outputRulesType[ query ] then outputRulesType[ query ] = {} end\
\
                local outputRulesQuery = outputRulesType[ query ]\
                for r = 1, #rules do\
                    outputRulesQuery[ #outputRulesQuery + 1 ] = rules[ r ]\
                end\
            end\
        end\
    end\
\
    self.rules = outputRules\
    self:dispatchThemeRules()\
end\
\
--[[\
    @instance\
    @desc Calls :retrieveThemes on the child nodes, meaning they will re-fetch their rules from the manager after clearing any current ones.\
]]\
function MThemeManager:dispatchThemeRules()\
    local nodes = self.collatedNodes\
    for i = 1, #nodes do nodes[ i ]:retrieveThemes() end\
end",
  [ "Page.ti" ] = "--[[\
    @instance position - number, nil (def. nil) - If set, the page will be at that position in the container (ie: 1 = first page, 3 = 3rd page).If not set, the page will fit in whereever it can, making space for pages that\
\
    The Page node is used by PageContainer nodes to hold content.\
\
    The width and height of the page is automatically defined when setting a parent on the page.\
]]\
\
class Page extends ScrollContainer\
\
--[[\
    @setter\
    @desc Sets the parent, and adjusts the width and height of the page to match that of the parent\
    @param <Node Instance - parent>\
]]\
function Page:setParent( parent )\
    if Titanium.typeOf( parent, \"PageContainer\", true ) then\
        self:linkProperties( parent, \"width\", \"height\" )\
    else\
        self:unlinkProperties( parent, \"width\", \"height\" )\
    end\
\
    self.super:setParent( parent )\
end\
\
--[[\
    @instance\
    @desc Sets the X position of this page depending on it's position and the width of the parent.\
\
          This function is called by the parent PageContainer automatically\
]]\
function Page:updatePosition()\
    self.X = self.parent.width * ( self.position - 1 ) + 1\
end\
\
--[[\
    @setter\
    @desc Updates the position and sets 'isPositionTemporary' to nil\
    @param [number - position]\
]]\
function Page:setPosition( position )\
    self.position = position\
    self.isPositionTemporary = nil\
end\
\
function Page:getAbsolutePosition( limit )\
    local parent, application = self.parent, self.application\
    if parent then\
        if limit and parent == limit then\
            return -1 + parent.X + self.X - parent.scroll, -1 + parent.Y + self.Y\
        end\
\
        local pX, pY = self.parent:getAbsolutePosition()\
        return -1 + pX + self.X - parent.scroll, -1 + pY + self.Y\
    else return self.X, self.Y end\
end\
\
configureConstructor {\
    orderedArguments = { \"id\" },\
    argumentTypes = {\
        id = \"string\",\
        position = \"number\"\
    },\
    requiredArguments = { \"id\" }\
}",
  [ "TermCanvas.ti" ] = "local tableConcat = table.concat\
local hex = {}\
for i = 0, 15 do\
    hex[2 ^ i] = (\"%x\"):format( i ) -- %x = lowercase hexadecimal\
    hex[(\"%x\"):format( i )] = 2 ^ i\
end\
\
--[[\
    The TermCanvas is an object that draws it's buffer directly to the ComputerCraft term object, unlike the NodeCanvas.\
\
    The TermCanvas should be used by high level objects, like 'Application'. Nodes should not be drawing directly to the term object.\
    If your object needs to draw to the canvas this class should be used.\
\
    Unlike NodeCanvas, TermCanvas has no drawing functions as it's purpose is not to generate the buffer, just draw it to the term object.\
    Nodes generate their content and store it in your buffer (and theirs as well).\
]]\
\
class TermCanvas extends Canvas {\
    static = { hex = hex };\
}\
\
--[[\
    @instance\
    @desc Draws the content of the canvas to the terminal object (term.blit). If 'force' is provided, even unchanged lines will be drawn, if not 'force' only changes lines will be blit.\
\
          The canvas contents are drawn using the X and Y position of the owner as the offset\
\
          If a pixel has a missing foreground or background colour, it will use the owner colour or background colour (respectively). If the owner has no colour set, defaults will be used\
          instead (foreground = 1, backgroundColour = 32768)\
    @param [boolean - force]\
]]\
function TermCanvas:draw( force )\
    local owner = self.owner\
    local buffer, last = self.buffer, self.last\
    local X, Y, width, height = owner.X, owner.Y - 1, self.width, self.height\
    local colour, backgroundChar, backgroundTextColour, backgroundColour = self.colour, self.backgroundChar, self.backgroundTextColour, self.backgroundColour\
\
    local position, px, lpx = 1\
    for y = 1, height do\
        local changed\
\
        for x = 1, width do\
            px, lpx = buffer[ position ], last[ position ]\
\
            if force or not lpx or ( px[ 1 ] ~= lpx[ 1 ] or px[ 2 ] ~= lpx[ 2 ] or px[ 3 ] ~= lpx[ 3 ] ) then\
                changed = true\
\
                position = position - ( x - 1 )\
                break\
            end\
\
            position = position + 1\
        end\
\
        if changed then\
            local rowText, rowColour, rowBackground, pixel = {}, {}, {}\
\
            for x = 1, width do\
                pixel = buffer[ position ]\
                last[ position ] = pixel\
\
                local c, fg, bg = pixel[1], pixel[2], pixel[3]\
\
                rowColour[ x ] = hex[ type(fg) == \"number\" and fg ~= 0 and fg or colour or 1 ]\
                rowBackground[ x ] = hex[ type(bg) == \"number\" and bg ~= 0 and bg or backgroundColour or 32768 ]\
                if c then\
                    rowText[ x ] = c or backgroundChar or \" \"\
                else\
                    rowText[ x ] = backgroundChar or \" \"\
                    rowColour[ x ] = hex[ backgroundTextColour or 1 ]\
                end\
\
                position = position + 1\
            end\
\
            term.setCursorPos( X, y + Y )\
            term.blit( tableConcat( rowText ), tableConcat( rowColour ), tableConcat( rowBackground ) )\
        end\
    end\
end",
  [ "Class.lua" ] = "--[[\
    Titanium Class System - Version 1.1\
\
    Copyright (c) Harry Felton 2016\
]]\
\
local classes, classRegistry, currentClass, currentRegistry = {}, {}\
local reserved = {\
    static = true,\
    super = true,\
    __type = true,\
    isCompiled = true,\
    compile = true\
}\
\
local missingClassLoader\
\
local getters = setmetatable( {}, { __index = function( self, name )\
    self[ name ] = \"get\" .. name:sub( 1, 1 ):upper() .. name:sub( 2 )\
\
    return self[ name ]\
end })\
\
local setters = setmetatable( {}, { __index = function( self, name )\
    self[ name ] = \"set\"..name:sub(1, 1):upper()..name:sub(2)\
\
    return self[ name ]\
end })\
\
local isNumber = {}\
for i = 0, 15 do isNumber[2 ^ i] = true end\
\
--[[ Constants ]]--\
local ERROR_BUG = \"\\nPlease report this via GitHub @ hbomb79/Titanium\"\
local ERROR_GLOBAL = \"Failed to %s to %s\\n\"\
local ERROR_NOT_BUILDING = \"No class is currently being built. Declare a class before invoking '%s'\"\
\
--[[ Helper functions ]]--\
local function throw( ... )\
    return error( table.concat( { ... }, \"\\n\" ) , 2 )\
end\
\
local function verifyClassEntry( target )\
    return type( target ) == \"string\" and type( classes[ target ] ) == \"table\" and type( classRegistry[ target ] ) == \"table\"\
end\
\
local function verifyClassObject( target, autoCompile )\
    if not Titanium.isClass( target ) then\
        return false\
    end\
\
    if autoCompile and not target:isCompiled() then\
        target:compile()\
    end\
\
    return true\
end\
\
local function isBuilding( ... )\
    if type( currentRegistry ) == \"table\" or type( currentClass ) == \"table\" then\
        if not ( currentRegistry and currentClass ) then\
            throw(\"Failed to validate currently building class objects\", \"The 'currentClass' and 'currentRegistry' variables are not both set\\n\", \"currentClass: \"..tostring( currentClass ), \"currentRegistry: \"..tostring( currentRegistry ), ERROR_BUG)\
        end\
        return true\
    end\
\
    if #({ ... }) > 0 then\
        return throw( ... )\
    else\
        return false\
    end\
end\
\
local function getClass( target )\
    if verifyClassEntry( target ) then\
        return classes[ target ]\
    elseif missingClassLoader then\
        local oC, oCReg = currentClass, currentRegistry\
        currentClass, currentRegistry = nil, nil\
\
        missingClassLoader( target )\
        local c = classes[ target ]\
        if not verifyClassObject( c, true ) then\
            throw(\"Failed to load missing class '\"..target..\"'.\\n\", \"The missing class loader failed to load class '\"..target..\"'.\\n\")\
        end\
\
        currentClass, currentRegistry = oC, oCReg\
\
        return c\
    else throw(\"Class '\"..target..\"' not found\") end\
end\
\
local function deepCopy( source )\
    if type( source ) == \"table\" then\
        local copy = {}\
        for key, value in next, source, nil do\
            copy[ deepCopy( key ) ] = deepCopy( value )\
        end\
        return copy\
    else\
        return source\
    end\
end\
\
local function propertyCatch( tbl )\
    if type( tbl ) == \"table\" then\
        if tbl.static then\
            if type( tbl.static ) ~= \"table\" then\
                throw(\"Invalid entity found in trailing property table\", \"Expected type 'table' for entity 'static'. Found: \"..tostring( tbl.static ), \"\\nThe 'static' entity is for storing static variables, refactor your class declaration.\")\
            end\
\
\
            local cStatic, cOwnedStatics = currentRegistry.static, currentRegistry.ownedStatics\
            for key, value in pairs( tbl.static ) do\
                if reserved[ key ] then\
                    throw(\
                        \"Failed to set static key '\"..key..\"' on building class '\"..currentRegistry.type..\"'\",\
                        \"'\"..key..\"' is reserved by Titanium for internal processes.\"\
                    )\
                end\
\
                cStatic[ key ] = value\
                cOwnedStatics[ key ] = type( value ) == \"nil\" and nil or true\
            end\
\
            tbl.static = nil\
        end\
\
        local cKeys, cOwned = currentRegistry.keys, currentRegistry.ownedKeys\
        for key, value in pairs( tbl ) do\
            cKeys[ key ] = value\
            cOwned[ key ] = type( value ) == \"nil\" and nil or true\
        end\
    elseif type( tbl ) ~= \"nil\" then\
        throw(\"Invalid trailing entity caught\\n\", \"An invalid object was caught trailing the class declaration for '\"..currentRegistry.type..\"'.\\n\", \"Object: '\"..tostring( tbl )..\"' (\"..type( tbl )..\")\"..\"\\n\", \"Expected [tbl | nil]\")\
    end\
end\
\
local function createFunctionWrapper( fn, superLevel )\
    return function( instance, ... )\
        local oldSuper = instance:setSuper( superLevel )\
\
        local v = { fn( ... ) }\
\
        instance.super = oldSuper\
\
        return unpack( v )\
    end\
end\
\
\
--[[ Local Functions ]]--\
local function compileSupers( targets )\
    local inheritedKeys, superMatrix = {}, {}, {}\
    local function compileSuper( target, id )\
        local factories = {}\
        local targetType = target.__type\
        local targetReg = classRegistry[ targetType ]\
\
        for key, value in pairs( targetReg.keys ) do\
            if not reserved[ key ] then\
                local toInsert = value\
                if type( value ) == \"function\" then\
                    factories[ key ] = function( instance, ... )\
                        --print(\"Super factory for \"..key..\"\\nArgs: \"..( function( args ) local s = \"\"; for i = 1, #args do s = s .. \" - \" .. tostring( args[ i ] ) .. \"\\n\" end return s end )( { ... } ))\
                        local oldSuper = instance:setSuper( id + 1 )\
                        local v = { value( instance, ... ) }\
\
                        instance.super = oldSuper\
                        return unpack( v )\
                    end\
\
                    toInsert = factories[ key ]\
                end\
\
                inheritedKeys[ key ] = toInsert\
            end\
        end\
\
        -- Handle inheritance\
        for key, value in pairs( inheritedKeys ) do\
            if type( value ) == \"function\" and not factories[ key ] then\
                factories[ key ] = value\
            end\
        end\
\
        superMatrix[ id ] = { factories, targetReg }\
    end\
\
    for id = #targets, 1, -1 do compileSuper( targets[ id ], id ) end\
\
    return inheritedKeys, function( instance )\
        local matrix, matrixReady = {}\
        local function generateMatrix( target, id )\
            local superTarget, matrixTbl, matrixMt = superMatrix[ id ], {}, {}\
            local factories, reg = superTarget[ 1 ], superTarget[ 2 ]\
\
            matrixTbl.__type = reg.type\
\
            local raw, owned, wrapCache, factory, upSuper = reg.raw, reg.ownedKeys, {}\
\
            function matrixMt:__tostring()\
                return \"[\"..reg.type..\"] Super #\"..id..\" of '\"..instance.__type..\"' instance\"\
            end\
            function matrixMt:__newindex( k, v )\
                if not matrixReady and k == \"super\" then\
                    upSuper = v\
                    return\
                end\
\
                throw(\"Cannot set keys on super. Illegal action.\")\
            end\
            function matrixMt:__index( k )\
                factory = factories[ k ]\
                if factory then\
                    if not wrapCache[ k ] then\
                        wrapCache[ k ] = (function( _, ... )\
                            return factory( instance, ... )\
                        end)\
                    end\
\
                    return wrapCache[ k ]\
                else\
                    if k == \"super\" then\
                        return upSuper\
                    else\
                        return throw(\"Cannot lookup value for key '\"..k..\"' on super\", \"Only functions can be accessed from supers.\")\
                    end\
                end\
            end\
            function matrixMt:__call( instance, ... )\
                local init = self.__init__\
                if type( init ) == \"function\" then\
                    return init( self, ... )\
                else\
                    throw(\"Failed to execute super constructor. __init__ method not found\")\
                end\
            end\
\
            setmetatable( matrixTbl, matrixMt )\
            return matrixTbl\
        end\
\
        local last = matrix\
        for id = 1, #targets do\
            last.super = generateMatrix( targets[ id ], id )\
            last = last.super\
        end\
\
        martixReady = true\
        return matrix\
    end\
end\
local function mergeValues( a, b )\
    if type( a ) == \"table\" and type( b ) == \"table\" then\
        local merged = deepCopy( a ) or throw( \"Invalid base table for merging.\" )\
\
        if #b == 0 and next( b ) then\
            for key, value in pairs( b ) do merged[ key ] = value end\
        elseif #b > 0 then\
            for i = 1, #b do table.insert( merged, i, b[ i ] ) end\
        end\
\
        return merged\
    end\
\
    return b == nil and a or b\
end\
local constructorTargets = { \"orderedArguments\", \"requiredArguments\", \"argumentTypes\", \"useProxy\" }\
local function compileConstructor( superReg )\
    local constructorConfiguration = {}\
\
    local superConfig, currentConfig = superReg.constructor, currentRegistry.constructor\
    if not currentConfig and superConfig then\
        currentRegistry.constructor = superConfig\
        return\
    elseif currentConfig and not superConfig then\
        superConfig = {}\
    elseif not currentConfig and not superConfig then\
        return\
    end\
\
    local constructorKey\
    for i = 1, #constructorTargets do\
        constructorKey = constructorTargets[ i ]\
        if not ( ( constructorKey == \"orderedArguments\" and currentConfig.clearOrdered ) or ( constructorKey == \"requiredArguments\" and currentConfig.clearRequired ) ) then\
            currentConfig[ constructorKey ] = mergeValues( superConfig[ constructorKey ], currentConfig[ constructorKey ] )\
        end\
    end\
end\
local function compileCurrent()\
    isBuilding(\
        \"Cannot compile current class.\",\
        \"No class is being built at time of call. Declare a class be invoking 'compileCurrent'\"\
    )\
    local ownedKeys, ownedStatics, allMixins = currentRegistry.ownedKeys, currentRegistry.ownedStatics, currentRegistry.allMixins\
\
    -- Mixins\
    local cConstructor = currentRegistry.constructor\
    for target in pairs( currentRegistry.mixins ) do\
        allMixins[ target ] = true\
        local reg = classRegistry[ target ]\
\
        local t = { { reg.keys, currentRegistry.keys, ownedKeys }, { reg.static, currentRegistry.static, ownedStatics }, { reg.alias, currentRegistry.alias, currentRegistry.alias } }\
        for i = 1, #t do\
            local source, target, owned = t[ i ][ 1 ], t[ i ][ 2 ], t[ i ][ 3 ]\
            for key, value in pairs( source ) do\
                if not owned[ key ] then\
                    target[ key ] = value\
                end\
            end\
        end\
\
        local constructor = reg.constructor\
        if constructor then\
            if constructor.clearOrdered then cConstructor.orderedArguments = nil end\
            if constructor.clearRequired then cConstructor.requiredArguments = nil end\
\
            local target\
            for i = 1, #constructorTargets do\
                target = constructorTargets[ i ]\
                cConstructor[ target ] = mergeValues( cConstructor[ target ], constructor and constructor[ target ] )\
            end\
        end\
    end\
\
    -- Supers\
    local superKeys\
    if currentRegistry.super then\
        local supers = {}\
\
        local last, c, newC = currentRegistry.super.target\
        while last do\
            c = getClass( last, true )\
\
            supers[ #supers + 1 ] = c\
            newC = classRegistry[ last ].super\
            last = newC and newC.target or false\
        end\
\
        superKeys, currentRegistry.super.matrix = compileSupers( supers )\
\
        -- Inherit alias from previous super\
        local currentAlias = currentRegistry.alias\
        for alias, redirect in pairs( classRegistry[ supers[ 1 ].__type ].alias ) do\
            if currentAlias[ alias ] == nil then\
                currentAlias[ alias ] = redirect\
            end\
        end\
\
        for mName in pairs( classRegistry[ supers[ 1 ].__type ].allMixins ) do\
            allMixins[ mName ] = true\
        end\
\
        compileConstructor( classRegistry[ supers[ 1 ].__type ] )\
    end\
\
    -- Generate instance function wrappers\
    local instanceWrappers, instanceVariables = {}, {}\
    for key, value in pairs( currentRegistry.keys ) do\
        if type( value ) == \"function\" then\
            instanceWrappers[ key ] = true\
            instanceVariables[ key ] = createFunctionWrapper( value, 1 )\
        else\
            instanceVariables[ key ] = value\
        end\
    end\
    if superKeys then\
        for key, value in pairs( superKeys ) do\
            if not instanceVariables[ key ] then\
                if type( value ) == \"function\" then\
                    instanceWrappers[ key ] = true\
                    instanceVariables[ key ] = function( _, ... ) return value( ... ) end\
                else\
                    instanceVariables[ key ] = value\
                end\
            end\
        end\
    end\
\
    -- Finish compilation\
    currentRegistry.initialWrappers = instanceWrappers\
    currentRegistry.initialKeys = instanceVariables\
    currentRegistry.compiled = true\
\
    currentRegistry = nil\
    currentClass = nil\
\
end\
local function spawn( target, ... )\
    if not verifyClassEntry( target ) then\
        throw(\
            \"Failed to spawn class instance of '\"..tostring( target )..\"'\",\
            \"A class entity named '\"..tostring( target )..\"' doesn't exist.\"\
        )\
    end\
\
    local classEntry, classReg = classes[ target ], classRegistry[ target ]\
    if classReg.abstract or not classReg.compiled then\
        throw(\
            \"Failed to instantiate class '\"..classReg.type..\"'\",\
            \"Class '\"..classReg.type..\"' \"..(classReg.abstract and \"is abstract. Cannot instantiate abstract class.\" or \"has not been compiled. Cannot instantiate.\")\
        )\
    end\
\
    local wrappers, wrapperCache = deepCopy( classReg.initialWrappers ), {}\
    local raw = deepCopy( classReg.initialKeys )\
    local alias = classReg.alias\
\
    local instanceID = string.sub( tostring( raw ), 8 )\
\
    local supers = {}\
    local function indexSupers( last, ID )\
        while last.super do\
            supers[ ID ] = last.super\
            last = last.super\
            ID = ID + 1\
        end\
    end\
\
    local instanceObj, instanceMt = { raw = raw, __type = target, __instance = true, __ID = instanceID }, { __metatable = {} }\
    local getting, useGetters, setting, useSetters = {}, true, {}, true\
    function instanceMt:__index( k )\
        local k = alias[ k ] or k\
\
        local getFn = getters[ k ]\
        if useGetters and not getting[ k ] and wrappers[ getFn ] then\
            getting[ k ] = true\
            local v = self[ getFn ]( self )\
            getting[ k ] = nil\
\
            return v\
        elseif wrappers[ k ] then\
            if not wrapperCache[ k ] then\
                wrapperCache[ k ] = function( ... )\
                    --print(\"Wrapper for \"..k..\". Arguments: \"..( function( args ) local s = \"\"; for i = 1, #args do s = s .. \" - \" .. tostring( args[ i ] ) .. \"\\n\" end return s end )( { ... } ) )\
                    return raw[ k ]( self, ... )\
                end\
            end\
\
            return wrapperCache[ k ]\
        else return raw[ k ] end\
    end\
\
    function instanceMt:__newindex( k, v )\
        local k = alias[ k ] or k\
\
        local setFn = setters[ k ]\
        if useSetters and not setting[ k ] and wrappers[ setFn ] then\
            setting[ k ] = true\
            self[ setFn ]( self, v )\
            setting[ k ] = nil\
        elseif type( v ) == \"function\" and useSetters then\
            wrappers[ k ] = true\
            raw[ k ] = createFunctionWrapper( v, 1 )\
        else\
            wrappers[ k ] = nil\
            raw[ k ] = v\
        end\
    end\
\
    function instanceMt:__tostring()\
        return \"[Instance] \"..target..\" (\"..instanceID..\")\"\
    end\
\
    if classReg.super then\
        instanceObj.super = classReg.super.matrix( instanceObj ).super\
        indexSupers( instanceObj, 1 )\
    end\
\
    local old\
    function instanceObj:setSuper( target )\
        old, instanceObj.super = instanceObj.super, supers[ target ]\
        return old\
    end\
\
    local function setSymKey( key, value )\
        useSetters = false\
        instanceObj[ key ] = value\
        useSetters = true\
    end\
\
    local resolved\
    local resolvedArguments = {}\
    function instanceObj:resolve( ... )\
        if resolved then return false end\
\
        local args, config = { ... }, classReg.constructor\
        if not config then\
            throw(\"Failed to resolve \"..tostring( instance )..\" constructor arguments. No configuration has been set via 'configureConstructor'.\")\
        end\
\
        local configRequired, configOrdered, configTypes, configProxy = config.requiredArguments, config.orderedArguments, config.argumentTypes or {}, config.useProxy or {}\
\
        local argumentsRequired = {}\
        if configRequired then\
            local target = type( configRequired ) == \"table\" and configRequired or configOrdered\
\
            for i = 1, #target do argumentsRequired[ target[ i ] ] = true end\
        end\
\
        local orderedMatrix = {}\
        for i = 1, #configOrdered do orderedMatrix[ configOrdered[ i ] ] = i end\
\
        local proxyAll, proxyMatrix = type( configProxy ) == \"boolean\" and configProxy, {}\
        if not proxyAll then\
            for i = 1, #configProxy do proxyMatrix[ configProxy[ i ] ] = true end\
        end\
\
        local function handleArgument( position, name, value )\
            local desiredType = configTypes[ name ]\
            if desiredType == \"colour\" or desiredType == \"color\" then\
                --TODO: Check if number is valid (maybe?)\
                desiredType = \"number\"\
            end\
\
            if desiredType and type( value ) ~= desiredType then\
                return throw(\"Failed to resolve '\"..tostring( target )..\"' constructor arguments. Invalid type for argument '\"..name..\"'. Type \"..configTypes[ name ]..\" expected, \"..type( value )..\" was received.\")\
            end\
\
            resolvedArguments[ name ], argumentsRequired[ name ] = true, nil\
            if proxyAll or proxyMatrix[ name ] then\
                self[ name ] = value\
            else\
                setSymKey( name, value )\
            end\
        end\
\
        for iter, value in pairs( args ) do\
            if configOrdered[ iter ] then\
                handleArgument( iter, configOrdered[ iter ], value )\
            elseif type( value ) == \"table\" then\
                for key, v in pairs( value ) do\
                    handleArgument( orderedMatrix[ key ], key, v )\
                end\
            else\
                return throw(\"Failed to resolve '\"..tostring( target )..\"' constructor arguments. Invalid argument found at ordered position \"..iter..\".\")\
            end\
        end\
\
        if next( argumentsRequired ) then\
            local str, name = \"\"\
            local function append( cnt )\
                str = str ..\"- \"..cnt..\"\\n\"\
            end\
\
            return throw(\"Failed to resolve '\"..tostring( target )..\"' constructor arguments. The following required arguments were not provided:\\n\\n\"..(function()\
                str = \"Ordered:\\n\"\
                for i = 1, #configOrdered do\
                    name = configOrdered[ i ]\
                    if argumentsRequired[ name ] then\
                        append( name .. \" [#\"..i..\"]\" )\
                        argumentsRequired[ name ] = nil\
                    end\
                end\
\
                if next( argumentsRequired ) then\
                    str = str .. \"\\nTrailing:\\n\"\
                    for name, _ in pairs( argumentsRequired ) do append( name ) end\
                end\
\
                return str\
            end)())\
        end\
\
        resolved = true\
        return true\
    end\
    instanceObj.__resolved = resolvedArguments\
\
    function instanceObj:can( method )\
        return wrappers[ method ] or false\
    end\
\
    local locked = { __index = true, __newindex = true }\
    function instanceObj:setMetaMethod( method, fn )\
        if type( method ) ~= \"string\" then\
            throw( \"Failed to set metamethod '\"..tostring( method )..\"'\", \"Expected string for argument #1, got '\"..tostring( method )..\"' of type \"..type( method ) )\
        elseif type( fn ) ~= \"function\" then\
            throw( \"Failed to set metamethod '\"..tostring( method )..\"'\", \"Expected function for argument #2, got '\"..tostring( fn )..\"' of type \"..type( fn ) )\
        end\
\
        method = \"__\"..method\
        if locked[ method ] then\
            throw( \"Failed to set metamethod '\"..tostring( method )..\"'\", \"Metamethod locked\" )\
        end\
\
        instanceMt[ method ] = fn\
    end\
\
    function instanceObj:lockMetaMethod( method )\
        if type( method ) ~= \"string\" then\
            throw( \"Failed to lock metamethod '\"..tostring( method )..\"'\", \"Expected string, got '\"..tostring( method )..\"' of type \"..type( method ) )\
        end\
\
        locked[ \"__\"..method ] = true\
    end\
\
    setmetatable( instanceObj, instanceMt )\
    if type( instanceObj.__init__ ) == \"function\" then instanceObj:__init__( ... ) end\
\
    for mName in pairs( classReg.allMixins ) do\
        if type( instanceObj[ mName ] ) == \"function\" then instanceObj[ mName ]( instanceObj ) end\
    end\
\
    if type( instanceObj.__postInit__ ) == \"function\" then instanceObj:__postInit__( ... ) end\
\
    return instanceObj\
end\
\
\
--[[ Global functions ]]--\
\
function class( name )\
    if isBuilding() then\
        throw(\
            \"Failed to declare class '\"..tostring( name )..\"'\",\
            \"A new class cannot be declared until the currently building class has been compiled.\",\
            \"\\nCompile '\"..tostring( currentRegistry.type )..\"' before declaring '\"..tostring( name )..\"'\"\
        )\
    end\
\
    local function nameErr( reason )\
        throw( \"Failed to declare class '\"..tostring( name )..\"'\\n\", string.format( \"Class name %s is not valid. %s\", tostring( name ), reason ) )\
    end\
\
    if type( name ) ~= \"string\" then\
        nameErr \"Class names must be a string\"\
    elseif not name:find \"%a\" then\
        nameErr \"No alphabetic characters could be found\"\
    elseif name:find \"%d\" then\
        nameErr \"Class names cannot contain digits\"\
    elseif classes[ name ] then\
        nameErr \"A class with that name already exists\"\
    elseif reserved[ name ] then\
        nameErr (\"'\"..name..\"' is reserved for Titanium processes\")\
    else\
        local char = name:sub( 1, 1 )\
        if char ~= char:upper() then\
            nameErr \"Class names must begin with an uppercase character\"\
        end\
    end\
\
    local classReg = {\
        type = name,\
\
        static = {},\
        keys = {},\
        ownedStatics = {},\
        ownedKeys = {},\
\
        initialWrappers = {},\
        initialKeys = {},\
\
        mixins = {},\
        allMixins = {},\
        alias = {},\
\
        constructor = {},\
        super = false,\
\
        compiled = false,\
        abstract = false\
    }\
\
    -- Class metatable\
    local classMt = { __metatable = {} }\
    function classMt:__tostring()\
        return (classReg.compiled and \"[Compiled] \" or \"\") .. \"Class '\"..name..\"'\"\
    end\
\
    local keys, owned = classReg.keys, classReg.ownedKeys\
    local staticKeys, staticOwned = classReg.static, classReg.ownedStatics\
    function classMt:__newindex( k, v )\
        if classReg.compiled then\
            throw(\
                \"Failed to set key on class base.\", \"\",\
                \"This class base is compiled, once a class base is compiled new keys cannot be added to it\",\
                \"\\nPerhaps you meant to set the static key '\"..name..\".static.\"..k..\"' instead.\"\
            )\
        end\
\
        keys[ k ] = v\
        owned[ k ] = type( v ) == \"nil\" and nil or true\
    end\
    function classMt:__index( k )\
        if owned[ k ] then\
            throw (\
                \"Access to key '\"..k..\"' denied.\",\
                \"Instance keys cannot be accessed from a class base, regardless of compiled state\",\
                classReg.ownedStatics[ k ] and \"\\nPerhaps you meant to access the static variable '\" .. name .. \".static.\".. k .. \"' instead\" or nil\
            )\
        elseif staticOwned[ k ] then\
            return staticKeys[ k ]\
        end\
    end\
    function classMt:__call( ... )\
        return spawn( name, ... )\
    end\
\
    -- Static metatable\
    local staticMt = { __index = staticKeys }\
    function staticMt:__newindex( k, v )\
        staticKeys[ k ] = v\
        staticOwned[ k ] = type( v ) == \"nil\" and nil or true\
    end\
\
    -- Class object\
    local classObj = { __type = name }\
    classObj.static = setmetatable( {}, staticMt )\
    classObj.compile = compileCurrent\
\
    function classObj:isCompiled() return classReg.compiled end\
\
    function classObj:getRegistry() return classReg end\
\
    setmetatable( classObj, classMt )\
\
    -- Export\
    currentRegistry = classReg\
    classRegistry[ name ] = classReg\
\
    currentClass = classObj\
    classes[ name ] = classObj\
\
    _G[ name ] = classObj\
\
    return propertyCatch\
end\
\
function extends( name )\
    isBuilding(\
        string.format( ERROR_GLOBAL, \"extend\", \"target class '\"..tostring( name )..\"'\" ), \"\",\
        string.format( ERROR_NOT_BUILDING, \"extends\" )\
    )\
\
    currentRegistry.super = {\
        target = name\
    }\
    return propertyCatch\
end\
\
function mixin( name )\
    if type( name ) ~= \"string\" then\
        throw(\"Invalid mixin target '\"..tostring( name )..\"'\")\
    end\
\
    isBuilding(\
        string.format( ERROR_GLOBAL, \"mixin\", \"target class '\".. name ..\"'\" ),\
        string.format( ERROR_NOT_BUILDING, \"mixin\" )\
    )\
\
    local mixins = currentRegistry.mixins\
    if mixins[ name ] then\
        throw(\
            string.format( ERROR_GLOBAL, \"mixin class '\".. name ..\"'\", \"class '\"..currentRegistry.type)\
            \"'\".. name ..\"' has already been mixed in to this target class.\"\
        )\
    end\
\
    if not getClass( name, true ) then\
        throw(\
            string.format( ERROR_GLOBAL, \"mixin class '\".. name ..\"'\", \"class '\"..currentRegistry.type ),\
            \"The mixin class '\".. name ..\"' failed to load\"\
        )\
    end\
\
    mixins[ name ] = true\
    return propertyCatch\
end\
\
function abstract()\
    isBuilding(\
        \"Failed to enforce abstract class policy\\n\",\
        string.format( ERROR_NOT_BUILDING, \"abstract\" )\
    )\
\
    currentRegistry.abstract = true\
    return propertyCatch\
end\
\
function alias( target )\
    local FAIL_MSG = \"Failed to implement alias targets\\n\"\
    isBuilding( FAIL_MSG, string.format( ERROR_NOT_BUILDING, \"alias\" ) )\
\
    local tbl = type( target ) == \"table\" and target or (\
        type( target ) == \"string\" and (\
            type( _G[ target ] ) == \"table\" and _G[ target ] or throw( FAIL_MSG, \"Failed to find '\"..tostring( target )..\"' table in global environment.\" )\
        ) or throw( FAIL_MSG, \"Expected type table as target, got '\"..tostring( target )..\"' of type \"..type( target ) )\
    )\
\
    local cAlias = currentRegistry.alias\
    for alias, redirect in pairs( tbl ) do\
        cAlias[ alias ] = redirect\
    end\
\
    return propertyCatch\
end\
\
function configureConstructor( config, clearOrdered, clearRequired )\
    isBuilding(\
        \"Failed to configure class constructor\\n\",\
        string.format( ERROR_NOT_BUILDING, \"configureConstructor\" )\
    )\
\
    if type( config ) ~= \"table\" then\
        throw (\
            \"Failed to configure class constructor\\n\",\
            \"Expected type 'table' as first argument\"\
        )\
    end\
\
    local constructor = {\
        clearOrdered = clearOrdered or nil,\
        clearRequired = clearRequired or nil\
    }\
    for key, value in pairs( config ) do constructor[ key ] = value end\
\
    currentRegistry.constructor = constructor\
    return propertyCatch\
end\
\
--[[ Class Library ]]--\
Titanium = {}\
\
function Titanium.getGetterName( property ) return getters[ property ] end\
\
function Titanium.getSetterName( property ) return setters[ property ] end\
\
function Titanium.getClass( name )\
    return classes[ name ]\
end\
\
function Titanium.getClasses()\
    return classes\
end\
\
function Titanium.isClass( target )\
    return type( target ) == \"table\" and type( target.__type ) == \"string\" and verifyClassEntry( target.__type )\
end\
\
function Titanium.isInstance( target )\
    return Titanium.isClass( target ) and target.__instance\
end\
\
function Titanium.typeOf( target, classType, instance )\
    if not Titanium.isClass( target ) or ( instance and not Titanium.isInstance( target ) ) then\
        return false\
    end\
\
    local targetReg = classRegistry[ target.__type ]\
\
    return targetReg.type == classType or ( targetReg.super and Titanium.typeOf( classes[ targetReg.super.target ], classType ) ) or false\
end\
\
function Titanium.mixesIn( target, mixinName )\
    if not Titanium.isClass( target ) then return false end\
\
    return classRegistry[ target.__type ].allMixins[ mixinName ]\
end\
\
function Titanium.setClassLoader( fn )\
    if type( fn ) ~= \"function\" then\
        throw( \"Failed to set class loader\", \"Value '\"..tostring( fn )..\"' is invalid, expected function\" )\
    end\
\
    missingClassLoader = fn\
end\
\
local preprocessTargets = {\"class\", \"extends\", \"alias\", \"mixin\"}\
function Titanium.preprocess( text )\
    local keyword\
    for i = 1, #preprocessTargets do\
        keyword = preprocessTargets[ i ]\
\
        for value in text:gmatch( keyword .. \" ([_%a][_%w]*)%s\" ) do\
            text = text:gsub( keyword .. \" \" .. value, keyword..\" \\\"\"..value..\"\\\"\" )\
        end\
    end\
\
    for name in text:gmatch( \"abstract class (\\\".[^%s]+\\\")\" ) do\
        text = text:gsub( \"abstract class \"..name, \"class \"..name..\" abstract()\" )\
    end\
\
    return text\
end",
  [ "Terminal.ti" ] = "local function isThreadRunning( obj )\
    if not obj.thread then return false end\
\
    return obj.thread.running\
end\
\
--[[\
    The terminal class is a node designed to emulate term programs. For example, the CraftOS shell can be run inside of this\
    node, with full functionality.\
\
    This could potentially be used to embed Titanium applications, however a more sophisticated approach is in the works.\
]]\
\
class Terminal extends Node mixin MFocusable {\
    static = {\
        focusedEvents = {\
            MOUSE = true,\
            KEY = true,\
            CHAR = true\
        }\
    };\
\
    canvas = true;\
    displayThreadStatus = true;\
}\
\
\
--[[\
    @instance\
    @desc Creates a terminal instance and creating a custom redirect canvas (the program being run inside the terminal requires a term redirect)\
    @param [number - X], [number - Y], [number - width], [number - height], [function - chunk]\
]]\
function Terminal:__init__( ... )\
    self:resolve( ... )\
    self:super()\
\
    self.canvas = RedirectCanvas( self )\
    self.redirect = self.canvas:getTerminalRedirect()\
end\
\
--[[\
    @instance\
    @desc 'Wraps' the chunk (self.chunk - function) by creating a Thread instance with the chunk as its function (coroutine).\
          The embedded program is then started by resuming the coroutine with 'titanium_terminal_start'.\
\
          A chunk must be set on the terminal node for this function to succeed. This function is automatically executed\
          when a chunk is set (self.chunk = fChunk, or self:setChunk( fChunk ) ).\
]]\
function Terminal:wrapChunk()\
    if type( self.chunk ) ~= \"function\" then\
        return error \"Cannot wrap chunk. No chunk function set.\"\
    end\
\
    self.canvas:resetTerm()\
\
    self.thread = Thread( self.chunk )\
    self:resume( GenericEvent \"titanium_terminal_start\" )\
end\
\
--[[\
    @instance\
    @desc Resumes the terminal with the given event. If the event is a mouse event its co-ordinates should have been adjusted to accomodate the terminal location\
          This is done automatically if the event is delivered via 'self:handle'.\
\
          The terminal (thread) is then resumed with this event. If the thread crashes, the 'exception' callback is executed with the thread. Access the exception using\
          'thread.exception'.\
\
          If the thread finished (gracefully), the 'finish' callback will be executed, with the thread AND a boolean (true), to indicate graceful finish\
          If the thread did not finish gracefully, the above will occur, however the boolean will be false as opposed to true.\
    @param <Event Instance - event>\
]]\
function Terminal:resume( event )\
    if not isThreadRunning( self ) then return end\
\
    if not Titanium.typeOf( event, \"Event\", true ) then\
        return error \"Invalid event object passed to resume terminal thread\"\
    end\
\
    local thread, old = self.thread, term.redirect( self.redirect )\
    thread:filterHandle( event )\
    term.redirect( old )\
\
    if not thread.running then\
        if type( thread.exception ) == \"string\" then\
            if self.displayThreadStatus then\
                self:emulate(function() printError( \"Thread Crashed: \" .. tostring( thread.exception ) ) end)\
            end\
\
            self:executeCallbacks(\"exception\", thread)\
        else\
            if self.displayThreadStatus then\
                self:emulate(function() print \"Finished\" end)\
            end\
\
            self:executeCallbacks(\"finish\", thread, true)\
        end\
\
        self:executeCallbacks(\"finish\", thread, false)\
    end\
\
    self.changed = true\
end\
\
--[[\
    @instance\
    @desc Allows a custom function to be executed with the terminals redirect being used, with error catching.\
    @param <function - fn>\
]]\
function Terminal:emulate( fn )\
    if type( fn ) ~= \"function\" then\
        return error(\"Failed to emulate function. '\"..tostring( fn )..\"' is not valid\")\
    end\
\
    local old = term.redirect( self.redirect )\
    local ok, err = pcall( fn )\
    term.redirect( old )\
\
    if not ok then\
        return error(\"Failed to emulate function. Reason: \"..tostring( err ), 3)\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the chunk on the instance, and wraps the chunk using 'wrapChunk'.\
    @param <function - chunk>\
]]\
function Terminal:setChunk( chunk )\
    self.chunk = chunk\
    self:wrapChunk()\
end\
\
--[[\
    @instance\
    @desc Provides the information required by the nodes application to draw the application caret.\
    @return <boolean - caretEnabled>, <number - caretX>, <number - caretY>, <colour - caretColour>\
]]\
function Terminal:getCaretInfo()\
    local c = self.canvas\
    return isThreadRunning( self ) and c.tCursor, c.tX + self.X - 1, c.tY + self.Y - 1, c.tColour\
end\
\
--[[\
    @instance\
    @desc If a MouseEvent is received, it's position is adjusted to become relative to this node before being passed to the terminal thread.\
    @param <Event Instance - eventObj>\
]]\
function Terminal:handle( eventObj )\
    if not isThreadRunning( self ) then self:unfocus(); return end\
\
    if eventObj.main == \"MOUSE\" then\
        if not eventObj.handled and eventObj:withinParent( self ) then self:focus() else self:unfocus() end\
        eventObj = eventObj:clone( self )\
    elseif eventObj.handled then\
        return\
    end\
\
    if Terminal.focusedEvents[ eventObj.main ] and not self.focused then return end\
    self:resume( eventObj )\
end\
\
--[[\
    @instance\
    @desc The terminal node has no need to draw any custom graphics to it's canvas - the running thread does all the drawing.\
          The parent node automatically draws the node canvas to it's own, so there is no need to run any draw code here.\
]]\
function Terminal:draw() end\
\
configureConstructor({\
    orderedArguments = { \"X\", \"Y\", \"width\", \"height\", \"chunk\" },\
    argumentTypes = { chunk = \"function\" },\
    useProxy = { \"chunk\" }\
}, true)",
  [ "MAnimationManager.ti" ] = "--[[\
    @instance animations - table (def. {}) - The current animations attached to this instance\
    @instance animationTimer - number, boolean (def. false) - If false, no animation timer is set. If a number, represents the ID of the timer that will update the animations every tick\
    @instance time - number (def. false) - Represents the current time (os.clock). Used to calculate deltaTime (dt) when updating each Tween\
]]\
\
abstract class MAnimationManager {\
    animations = {};\
    animationTimer = false;\
\
    time = false;\
}\
\
--[[\
    @desc When the animation timer ticks, update animations attached to this application and re-queue the timer if more animations must occur.\
]]\
function MAnimationManager:updateAnimations()\
    local dt = os.clock() - self.time\
\
    local anims, anim = self.animations\
    for i = #anims, 1, -1 do\
        anim = anims[ i ]\
\
        if anim:update( dt ) then\
            if type( anim.promise ) == \"function\" then\
                anim:promise( self )\
            end\
\
            self:removeAnimation( anim )\
        end\
    end\
\
    self.timer = false\
    if #anims > 0 then self:restartAnimationTimer() end\
end\
\
--[[\
    @instance\
    @desc Adds an animation to this object, on update this animation will be updated\
    @param <Tween Instance - animation>\
]]\
function MAnimationManager:addAnimation( animation )\
    if not Titanium.typeOf( animation, \"Tween\", true ) then\
        return error(\"Failed to add animation to manager. '\"..tostring( animation )..\"' is invalid, Tween instance expected\")\
    end\
\
    self:removeAnimation( animation.name )\
    table.insert( self.animations, animation )\
\
    if not self.timer then\
        self:restartAnimationTimer()\
    end\
\
    return animation\
end\
\
--[[\
    @instance\
    @desc Removes an animation from this object, it will stop receiving updates from this object\
    @param <string - animation> - The name of the animation to remove\
    @param <Tween Instance - animation> - The animation instance to remove\
    @return <Tween Instance - animation> - The removed animation. If nil, no animation removed\
]]\
function MAnimationManager:removeAnimation( animation )\
    local searchName\
    if type( animation ) == \"string\" then\
        searchName = true\
    elseif not Titanium.typeOf( animation, \"Tween\", true ) then\
        return error(\"Failed to remove animation from manager. '\"..tostring( animation )..\"' is invalid, Tween instance expected\")\
    end\
\
    local anims = self.animations\
    for i = 1, #anims do\
        if ( searchName and anims[ i ].name == animation ) or ( not searchName and anims[ i ] == animation ) then\
            return table.remove( anims, i )\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc When an animation is queued the timer is created for 'time' (0.05). This replaces the currently running timer (if any).\
          The objects 'time' is then updated to the current time (os.clock)\
    @param [number - time]\
]]\
function MAnimationManager:restartAnimationTimer( time )\
    if self.timer then\
        os.cancelTimer( self.timer )\
    end\
\
    self.time = os.clock()\
    self.timer = os.startTimer( type( time ) == \"number\" and time or .05 )\
end",
  [ "RadioButton.ti" ] = "--[[\
    @static groups - table (def. {}) - The current radio button groups\
    @instance group - string (def. false) - The group the radio button belongs to\
\
    A radio button belongs to a group. Anytime a radio button in the same group is selected, all others are deselected. This means only one radio button\
    is selected at a time inside of a group. The value of the selected radio button can be retrieved using 'RadioButton.static.getValue'\
\
    When the radio button is selected, the 'select' callback is fired\
]]\
class RadioButton extends Checkbox {\
    static = {\
        groups = {}\
    };\
\
    group = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs the instance, and selects the radio button if 'toggled' is set\
    @param [number - X], [number - Y], <string - group>\
]]\
function RadioButton:__init__( ... )\
    self:super( ... )\
\
    if self.toggled then\
        RadioButton.deselectInGroup( self.group, self )\
    end\
end\
\
--[[\
    @instance\
    @desc Deselects every radio button in the group, toggles this radio button\
]]\
function RadioButton:select()\
    RadioButton.deselectInGroup( self.group )\
\
    self.toggled = true\
    self:executeCallbacks \"select\"\
end\
\
--[[\
    @instance\
    @desc If the radio button is active, and the mouse click occurred on this node, the radio button is selected (:select)\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function RadioButton:onMouseUp( event, handled, within )\
    if not handled and within and self.active then\
        self:select( event, handled, within )\
\
        event.handled = true\
    end\
\
    self.active = false\
end\
\
--[[\
    @instance\
    @desc If an assigned label (labelFor set as this nodes ID on a label) is clicked, this radio button is selected\
    @param <Label Instance - label>, <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function RadioButton:onLabelClicked( label, event, handled, within )\
    self:select( event, handled, within, label )\
    event.handled = true\
end\
\
--[[\
    @instance\
    @desc Updates the radio button group by removing the button from the old group and adding it to the new one\
    @param <string - group>\
]]\
function RadioButton:setGroup( group )\
    if self.group then\
        RadioButton.removeFromGroup( self, self.group )\
    end\
    self.group = group\
\
    RadioButton.addToGroup( self, group )\
end\
\
--[[\
    @static\
    @desc Adds the node provided to the group given\
    @param <Node Instance - node>, <string - group>\
]]\
function RadioButton.static.addToGroup( node, group )\
    local g = RadioButton.groups[ group ]\
    if type( g ) == \"table\" then\
        RadioButton.removeFromGroup( node, group )\
\
        table.insert( g, node )\
    else\
        RadioButton.groups[ group ] = { node }\
    end\
end\
\
--[[\
    @static\
    @desc Removes the node provided from the group given if present\
    @param <Node Instance - node>, <string - group>\
]]\
function RadioButton.static.removeFromGroup( node, group )\
    local index = RadioButton.isInGroup( node, group )\
    if index then\
        table.remove( RadioButton.groups[ group ], index )\
\
        if #RadioButton.groups[ group ] == 0 then\
            RadioButton.groups[ group ] = nil\
        end\
    end\
end\
\
--[[\
    @static\
    @desc Returns true if 'node' is inside 'group'\
    @param <Node Instance - node>, <string - group>\
    @return <boolean - isInsideGroup>\
]]\
function RadioButton.static.isInGroup( node, group )\
    local g = RadioButton.groups[ group ]\
    for i = 1, #g do\
        if g[ i ] == node then return i end\
    end\
\
    return false\
end\
\
--[[\
    @static\
    @desc If no 'target', deselects every node inside 'group'. If a 'target' is given, every node BUT the 'target' is deselected inside the group\
    @param <string - group>, [Node Instance - target]\
]]\
function RadioButton.static.deselectInGroup( group, target )\
    local g = RadioButton.groups[ group ]\
\
    for i = 1, #g do if ( not target or ( target and g[ i ] ~= target ) ) then g[ i ].toggled = false end end\
end\
\
--[[\
    @static\
    @desc Returns the value of the selected radio button inside of the group given (if one is selected)\
    @param <string - group>\
    @return <string - value> - If a radio button is selected, it's value is returned\
]]\
function RadioButton.static.getValue( group )\
    local g = RadioButton.groups[ group ]\
    if g then\
        local radio\
        for i = 1, #g do\
            radio = g[ i ]\
            if radio.toggled then return radio.value end\
        end\
    end\
end\
\
configureConstructor({\
    orderedArguments = { \"X\", \"Y\", \"group\" },\
    requiredArguments = { \"group\" },\
    argumentTypes = { group = \"string\" },\
    useProxy = { \"group\" }\
}, true, true )",
  [ "DynamicEqParser.ti" ] = "local TERMS = { \"NAME\", \"STRING\", \"NUMBER\", \"PAREN\", \"QUERY\" }\
local BIN_AMBIG = { \"binary\", \"ambiguos\" }\
local UNA_AMBIG = { \"unary\", \"ambiguos\" }\
\
--[[\
    @instance stacks - table (def. {{}}) - A two dimensional table, containing the stacks used by the query (ie: self.value, self.parent.value). Can be resolved to find the values using :resolveStacks\
    @instance state - string (def. \"root\") - The current state of the parser, can be 'root' or 'name'. If 'root', :parseRootState will be called, else :parseNameState\
    @instance output - string (def. \"local args = ...; return\") - The Lua equation formed while parsing.\
\
    Parses the tokens from DynamicEqLexer into a Lua equation (string) and a set of stacks\
]]\
\
class DynamicEqParser extends Parser {\
    state = \"root\";\
    stacks = {{}};\
    output = \"local args = ...; return \";\
}\
\
--[[\
    @constructor\
    @desc Invokes the Parser constructor, passing the tokens from the DynamicEqLexer (using the expression provided)\
    @param <string - expression>\
]]\
function DynamicEqParser:__init__( expression )\
    self:super( DynamicEqLexer( expression ).tokens )\
end\
\
--[[\
    @instance\
    @desc Allows precise testing of adjacent operators so that a tokens position can be validated.\
\
          If the beforeType is specified, without an afterType the token before the current token must be an operator of the type specified using 'beforeType'.\
          If the afterType is specified, without a beforeType, the same as above applies for the token after the current token.\
\
          If both before and after type are specified, both the token before and after the current must match the type specified using 'beforeType' and 'afterType' respectively.\
\
          If 'optional', the test will no fail if no token exists before/after the current token (depending on which types are specified).\
\
          If the 'beforeOffset' or 'afterOffset' is specified, the token checked before or after the current token will be offset by the amount specified.\
    @param [string, table - beforeType], [string, table - afterType], [boolean - optional], [number - beforeOffset], [number - afterOffset]\
    @return <boolean - success>\
]]\
function DynamicEqParser:testForOperator( beforeType, afterType, optional, beforeOffset, afterOffset )\
    local pass, before, after = self:testAdjacent( beforeType and \"OPERATOR\", afterType and \"OPERATOR\", false, beforeOffset, afterOffset, not optional )\
    if not pass then return false end\
\
    local function test( token, filter )\
        if not token then return true elseif not filter then return false end\
        if type( filter ) == \"table\" then\
            for i = 1, #filter do\
                if token[ filter[ i ] ] or filter[ i ] == \"*\" then return true end\
            end\
        else\
            if type == \"*\" then return true end\
            return token[ filter ]\
        end\
    end\
\
    local bT, aT = test( before, beforeType ), test( after, afterType )\
    if beforeType and afterType then return bT and aT else return ( beforeType and bT ) or ( afterType and aT ) end\
end\
\
--[[\
    @instance\
    @desc Tests for terms before the current token (if 'pre') and after the current token (if 'post'). If no token before/after current token and not 'optional', test will fail.\
\
          A term is a 'NAME', 'STRING', 'NUMBER', or 'PAREN' token from the lexer\
    @param [boolean - pre], [boolean - post], [boolean - optional]\
    @return <boolean - success>\
]]\
function DynamicEqParser:testForTerms( pre, post, optional )\
    return self:testAdjacent( pre and TERMS, post and TERMS, false, false, false, not optional )\
end\
\
--[[\
    @instance\
    @desc Resolves the current stacks found using the parser by finding the Titanium instance attached to it. Stacks are passed to MPropertyManager:dynamicallyLinkProperty as 'arguments'\
    @param <Instance - target>\
    @return <table - instances>\
]]\
function DynamicEqParser:resolveStacks( target, allowFailure )\
    local stacks, instances = self.stacks, {}\
    for i = 1, #stacks - ( #stacks[ #stacks ] == 0 and 1 or 0 ) do\
        local stack = stacks[ i ]\
        if #stack <= 1 then\
            self:throw(\"Invalid stack '\".. stack[ 1 ] ..\"'. At least 2 parts must exist to resolve\")\
        end\
\
        local stackStart, instancePoint = stack[ 1 ]\
        if stackStart == \"self\" then\
            instancePoint = target\
        elseif stackStart == \"parent\" then\
            instancePoint = target.parent\
        elseif stackStart == \"application\" then\
            instancePoint = target.application\
        elseif stackStart:sub( 1, 1 ) == \"{\" then\
            if not target.application then\
                if allowFailure then return end\
                self:throw \"Cannot resolve stacks. Resolution of node queries requires an application instance be set on the target\"\
            end\
\
            local query = NodeQuery( target.application, stackStart:sub( 2, -2 ) ).result\
            if not query then\
                if allowFailure then return end\
\
                self:throw( \"Failed to resolve stacks. Node query '\"..stackStart..\"' resolved to 0 nodes\" )\
            end\
\
            instancePoint = query[ 1 ]\
        else self:throw(\"Invalid stack start '\"..stackStart..\"'. Only self, parent and application allowed\") end\
\
        for p = 2, #stack - 1 do\
            if not instancePoint then self:throw(\"Failed to resolve stacks. Index '\"..stack[ p ]..\"' could not be accessed on '\"..tostring( instancePoint )..\"'\") end\
            instancePoint = instancePoint[ stack[ p ] ]\
        end\
\
        if not instancePoint then if allowFailure then return end self:throw \"Invalid instance\" elseif not stack[ #stack ] then self:throw \"Invalid property\" end\
        instances[ #instances + 1 ] = { stack[ #stack ], instancePoint }\
    end\
\
    return instances\
end\
\
--[[\
    @instance\
    @desc Appends 'str' to the parser output. If no 'str' is given, the 'value' of the current token is appended instead\
    @param [string - str]\
]]\
function DynamicEqParser:appendToOutput( str )\
    self.output = self.output .. ( str or self:getCurrentToken().value )\
end\
\
--[[\
    @instance\
    @desc Parses 'token' at the root state (ie: not resolving a name)\
    @param <table - token>\
]]\
function DynamicEqParser:parseRootState( token )\
    token = token or self:getCurrentToken()\
    if token.type == \"NAME\" then\
        local filter = { \"OPERATOR\", \"DOT\", \"PAREN\" }\
        if not self:testAdjacent( filter, filter ) then self:throw(\"Unexpected name '\"..token.value..\"'\") end\
\
        self:appendToStack( token.value )\
        self:setState \"name\"\
\
        self:appendToOutput( \"args[\"..#self.stacks..\"]\" )\
    elseif token.type == \"PAREN\" then\
        if token.value == \"(\" then\
            if not ( ( self:testForOperator( BIN_AMBIG, false, true ) or self:testAdjacent \"PAREN\" ) and ( self:testForTerms( false, true ) or self:testForOperator( false, UNA_AMBIG ) ) ) then\
                self:throw(\"Unexpected parentheses '\"..token.value..\"'\")\
            end\
        elseif token.value == \")\" then\
            if not ( self:testForTerms( true ) and self:testForOperator( false, BIN_AMBIG, true ) ) then\
                self:throw(\"Unexpected parentheses '\"..token.value..\"'\")\
            end\
        else self:throw(\"Invalid parentheses '\"..token.value..\"'\") end\
\
        self:appendToOutput()\
    elseif token.type == \"STRING\" then\
        local unaryOffset = self:testForOperator \"unary\" and 1 or 0\
        if not ( ( self:testForOperator( BIN_AMBIG, false, false, unaryOffset ) or self:testAdjacent( \"PAREN\", false, false, unaryOffset ) ) and ( self:testForOperator( false, BIN_AMBIG, true ) or self:testAdjacent( false, \"PAREN\" ) ) ) then\
            self:throw(\"Unexpected string '\"..token.value..\"'\")\
        end\
\
        self:appendToOutput( (\"%s%s%s\"):format( token.surroundedBy, token.value, token.surroundedBy ) )\
    elseif token.type == \"NUMBER\" then\
        if not self:testAdjacent( { \"OPERATOR\", \"PAREN\" }, { \"OPERATOR\", \"PAREN\" }, false, false, false ) then\
            self:throw(\"Unexpected number '\"..token.value..\"'\")\
        end\
\
        self:appendToOutput()\
    elseif token.type == \"OPERATOR\" then\
        if token.unary then\
            if not ( self:testForTerms( false, true ) and ( self:testForOperator( BIN_AMBIG ) or self:testAdjacent \"PAREN\" ) ) then\
                self:throw(\"Unexpected unary operator '\"..token.value..\"'. Operator must follow a binary operator and precede a term\")\
            end\
        elseif token.binary then\
            if not ( self:testForTerms( true ) and ( self:testForOperator( false, \"unary\" ) or self:testForTerms( false, true ) ) ) then\
                self:throw(\"Unexpected binary operator '\"..token.value..\"'. Expected terms before and after operator, or unary operator following\")\
            end\
        elseif token.ambiguos then\
            local trailing = self:testForTerms( false, true )\
\
            if not ( ( ( trailing or ( self:testForOperator( false, UNA_AMBIG ) and self:testForTerms( true ) ) ) and self:testForTerms( true, false, true ) ) or ( self:testForOperator( BIN_AMBIG ) and trailing ) ) then\
                self:throw(\"Unexpected ambiguos operator '\"..token.value..\"'\")\
            end\
        else self:throw(\"Unknown operator '\"..token.value..\"'\") end\
\
        self:appendToOutput( (\" %s \"):format( token.value ) )\
    elseif token.type == \"QUERY\" then\
        self:appendToStack( token.value )\
        self:setState \"name\"\
\
        self:appendToOutput( \"args[\"..#self.stacks..\"]\" )\
    else\
        self:throw(\"Unexpected block '\"..token.value..\"' of token type '\"..token.type..\"'.\")\
    end\
end\
\
--[[\
    @instance\
    @desc Resolves the name by using the token provided. If a 'DOT' is found and a 'NAME' follows, the name is appended to the parser stacks (otherwise, trailing DOT raises exception)\
\
          If no DOT is found, the parser state is reset to 'root'\
    @param <table - token>\
]]\
function DynamicEqParser:parseNameState( token )\
    token = token or self:getCurrentToken()\
    if token.type == \"DOT\" then\
        local trailing = self:peek()\
        if trailing and trailing.type == \"NAME\" then\
            self:stepForward()\
            self:appendToStack( trailing.value )\
        else\
            local last = self:getStack()\
            self:throw(\"Failed to index '\" .. table.concat( last, \".\" ) .. \"'. No name following dot.\")\
        end\
    else\
        self:setState \"root\"\
        table.insert( self.stacks, {} )\
\
        self:parseRootState( token )\
    end\
end\
\
--[[\
    @instance\
    @desc Returns the current stack if no 'offset', otherwise returns the stack using the offset (ie: offset of -1 will return the last stack)\
    @param [number - offset]\
    @return [table - stack]\
]]\
function DynamicEqParser:getStack( offset )\
    return self.stacks[ #self.stacks + ( offset or 0 ) ]\
end\
\
--[[\
    @instance\
    @desc Appends 'value' to the stack information (current stack is used if no 'stackOffset', otherwise the offset is used to find the stack)\
    @param <string - value>, [number - stackOffset]\
]]\
function DynamicEqParser:appendToStack( value, stackOffset )\
    table.insert( self:getStack( stackOffset ), value )\
end\
\
--[[\
    @setter\
    @desc Sets the state of the parser\
    @param <string - state>\
]]\
function DynamicEqParser:setState( state )\
    self.state = state\
end\
\
--[[\
    @instance\
    @desc Invokes the correct parser function (:parseRoot or Name state) depending on the parser 'state'\
\
          Token is automatically stepped forward after invoking the parser function.\
]]\
function DynamicEqParser:parse()\
    local token = self:stepForward()\
    while token do\
        if self.state == \"root\" then\
            self:parseRootState()\
        elseif self.state == \"name\" then\
            self:parseNameState()\
        else\
            self:throw(\"Invalid parser state '\"..self.state..\"'\")\
        end\
\
        token = self:stepForward()\
    end\
end",
  [ "MCallbackManager.ti" ] = "--[[\
    @instance callbacks - table (def. {}) - The callbacks set on this instance\
\
    The callback manager is a mixin that can be used by classes that want to provide an easy way for a developer to assign actions on certain conditions.\
\
    These conditions may include node specific callbacks, like a button click or input submission.\
]]\
\
abstract class MCallbackManager {\
    callbacks = {}\
}\
\
--[[\
    @instance\
    @desc Assigns a function 'fn' to 'callbackName'.\
    @param <string - name>, <function - fn>, [string - id]\
]]\
function MCallbackManager:on( callbackName, fn, id )\
    if not ( type( callbackName ) == \"string\" and type( fn ) == \"function\" ) or ( id and type( id ) ~= \"string\" ) then\
        return error \"Expected string, function, [string]\"\
    end\
\
    local callbacks = self.callbacks\
    if not callbacks[ callbackName ] then callbacks[ callbackName ] = {} end\
\
    table.insert( callbacks[ callbackName ], { fn, id } )\
\
    return self\
end\
\
--[[\
    @instance\
    @desc Removes all callbacks for a certain condition. If an id is provided only callbacks matching that id will be executed.\
    @param <string - callbackName>, [string - id]\
]]\
function MCallbackManager:off( callbackName, id )\
    if id then\
        local callbacks = self.callbacks[ callbackName ]\
\
        if callbacks then\
            for i = #callbacks, 1, -1 do\
                if callbacks[ i ][ 2 ] == id then\
                    table.remove( callbacks, i )\
                end\
            end\
        end\
    else self.callbacks[ callbackName ] = nil end\
\
    return self\
end\
\
--[[\
    @instance\
    @desc Executes all assigned functions for 'callbackName' with 'self' and the arguments passed to this function.\
    @param <string - callbackName>, [vararg - ...]\
]]\
function MCallbackManager:executeCallbacks( callbackName, ... )\
    local callbacks = self.callbacks[ callbackName ]\
\
    if callbacks then\
        for i = 1, #callbacks do callbacks[ i ][ 1 ]( self, ... ) end\
    end\
end\
\
--[[\
    @instance\
    @desc Returns true if there are any callbacks for 'target' exist\
    @param <string - target>\
    @return <boolean - callbacksExist>\
]]\
function MCallbackManager:canCallback( target )\
    local cbs = self.callbacks[ target ]\
    return cbs and #cbs > 0\
end",
  [ "Parser.ti" ] = "--[[\
    @instance position - number (def. 0) - The current token index being parsed\
    @instance tokens - table (def. {}) - The tokens found via lexing, corresponds to 'position'\
\
    The parser class should be extended by classes that are used to parser lexer token output.\
]]\
\
abstract class Parser {\
    position = 0;\
    tokens = {};\
}\
\
--[[\
    @constructor\
    @desc Sets the tokens of the parser to those passed and begins parsing\
    @param <table - tokens>\
]]\
function Parser:__init__( tokens )\
    if type( tokens ) ~= \"table\" then\
        return error \"Failed to parse. Invalid tokens\"\
    end\
\
    self.tokens = tokens\
    self:parse()\
end\
\
--[[\
    @instance\
    @desc Returns the token at 'position'\
]]\
function Parser:getCurrentToken()\
    return self.tokens[ self.position ]\
end\
\
--[[\
    @instance\
    @desc Returns the token 'amount' ahead of the current position. Defaults to one position ahead\
]]\
function Parser:peek( amount )\
    return self.tokens[ self.position + ( amount or 1 ) ]\
end\
\
--[[\
    @instance\
    @desc Tests the adjacent tokens to see if they are the correct type. Offsets can be provided and missing tokens can be configured to cause test failure\
    @param [string - before], [string - after], [boolean - optional], [number - beforeOffset], [number - afterOffset], [boolean - disallowMissing]\
\
    Note: If a token doesn't exist, it will NOT cause the test to fail unless 'disallowMissing' is set to true.\
]]\
function Parser:testAdjacent( before, after, optional, beforeOffset, afterOffset, disallowMissing )\
    local leading, leadingPass, trailing, trailingPass = false, not before, false, not after\
    local function test( token, filter )\
        if not token then return not disallowMissing end\
\
        if type( filter ) == \"table\" then\
            for i = 1, #filter do\
                if token.type == filter[ i ] then return true end\
            end\
        else return token.type == filter end\
    end\
\
    if before then\
        leading = self:peek( -1 - ( beforeOffset or 0 ) )\
        leadingPass = test( leading, before )\
    end\
\
\
    if after then\
        trailing = self:peek( 1 + ( afterOffset or 0 ) )\
        trailingPass = test( trailing, after )\
    end\
\
    return ( optional and ( trailingPass or leadingPass ) or ( not optional and trailingPass and leadingPass ) ), leading, trailing\
end\
\
--[[\
    @instance\
    @desc Advances 'position' by one and returns the token at the new position\
]]\
function Parser:stepForward( amount )\
    self.position = self.position + ( amount or 1 )\
    return self:getCurrentToken()\
end\
\
--[[\
    @instance\
    @desc Throws a error prefixed with information about the token being parsed at the time of error.\
]]\
function Parser:throw( e, token )\
    local token = token or self:getCurrentToken()\
    if not token then\
        return error( \"Parser (\"..tostring( self.__type )..\") Error: \"..e, 2 )\
    end\
\
    return error( \"Parser (\"..tostring( self.__type )..\") Error. Line \"..token.line..\", char \"..token.char .. \": \"..e, 2 )\
end",
  [ "Input.ti" ] = "--[[\
    @instance position - number (def. 0) - The position of the caret, dictates the position new characters are added\
    @instance scroll - number (def. 0) - The scroll position of the input, used when the content is longer than the width of the node\
    @instance value - string (def. \"\") - The value currently held by the input\
    @instance selection - number, boolean (def. false) - If a number, the end of the selection. If false, no selection made\
    @instance selectedColour - colour (def. false) - The colour of selected text\
    @instance selectedBackgroundColour - colour (def. false) - The background colour of selected text\
    @instance placeholder - string (def. false) - The text displayed when the input is unfocused and has no value\
    @instance placeholderColour - colour (def. 256) - The colour used when displaying the placeholder text\
    @instance limit - number (def. 0) - If greater than 0, the amount of text entered will be limited to that number. If 0, no limit is set.\
    @instance mask - string (def. \"\") - If not set to \"\", the character will be used instead of the characters displayed at draw time. Doesn't affect the actual value, only how it is displayed (ie: password forms)\
\
    When the text is changed, the 'change' callback is executed. When the 'enter' key is pressed, the 'trigger' callback will be executed.\
\
    The Input class provides the user with the ability to insert a single line of text, see EditableTextContainer for multi-line text input.\
]]\
\
local stringRep, stringSub = string.rep, string.sub\
class Input extends Node mixin MActivatable mixin MFocusable {\
    position = 0;\
    scroll = 0;\
    value = \"\";\
\
    selection = false;\
    selectedColour = false;\
    selectedBackgroundColour = colours.lightBlue;\
\
    placeholder = false;\
    placeholderColour = 256;\
\
    allowMouse = true;\
    allowKey = true;\
    allowChar = true;\
\
    limit = 0;\
    mask = \"\";\
}\
\
--[[\
    @constructor\
    @desc Constructs the instance by resolving arguments and registering used properties\
]]\
function Input:__init__( ... )\
    self:resolve( ... )\
    self:register( \"width\", \"selectedColour\", \"selectedBackgroundColour\", \"limit\" )\
\
    self:super()\
end\
\
--[[\
    @instance\
    @desc Sets the input to active if clicked on, sets active and focused to false if the mouse click was not on the input.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Input:onMouseClick( event, handled, within )\
    if within and not handled then\
        if event.button ~= 1 then return end\
        if self.focused then\
            local application, pos, width, scroll = self.application, self.position, self.width, self.scroll\
            local clickedPos = math.min( #self.value, event.X - self.X + self.scroll )\
\
            if application:isPressed( keys.leftShift ) or application:isPressed( keys.rightShift ) then\
                if clickedPos ~= pos then\
                    self.selection = clickedPos\
                else self.selection = false end\
            else self.position, self.selection = clickedPos, false end\
        end\
\
        self.active, event.handled = true, true\
    else\
        self.active = false\
        self:unfocus()\
    end\
end\
\
--[[\
    @instance\
    @desc If a mouse drag occurs while the input is focused, the selection will be moved to the mouse drag location, creating a selection between the cursor position and the drag position\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Input:onMouseDrag( event, handled, within )\
    if not self.focused or handled then return end\
    self.selection = math.min( #self.value, event.X - self.X + self.scroll )\
    event.handled = true\
end\
\
--[[\
    @instance\
    @desc If the mouse up missed the input or the event was already handled, active and false are set to false.\
          If within and not handled and input is active focused is set to true. Active is set to false on all conditions.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Input:onMouseUp( event, handled, within )\
    if ( not within or handled ) and self.focused then\
        self:unfocus()\
    elseif within and not handled and self.active and not self.focused then\
        self:focus()\
    end\
\
    self.active = false\
end\
\
--[[\
    @instance\
    @desc Catches char events and inserts the character pressed into the input's value.\
    @param <CharEvent Instance - event>, <boolean - handled>\
]]\
function Input:onChar( event, handled )\
    if not self.focused or handled then return end\
\
    local value, position, selection = self.value, self.position, self.selection\
    if selection then\
        local start, stop = math.min( selection, position ), math.max( selection, position )\
        start = start > stop and start - 1 or start\
\
        self.value, self.selection = stringSub( value, 1, start ) .. event.char .. stringSub( value, stop + ( start < stop and 1 or 2 ) ), false\
        self.position = start + 1\
        self.changed = true\
    else\
        if self.limit > 0 and #value >= self.limit then return end\
\
        self.value = stringSub( value, 1, position ) .. event.char .. stringSub( value, position + 1 )\
        self.position = self.position + 1\
    end\
\
    self:executeCallbacks \"change\"\
\
    event.handled = true\
end\
\
--[[\
    @instance\
    @desc Catches key down events and performs an action depending on the key pressed\
    @param <KeyEvent Instance - event>, <boolean - handled>\
]]\
function Input:onKeyDown( event, handled )\
    if not self.focused or handled then return end\
\
    local value, position = self.value, self.position\
    local valueLen = #value\
    if event.sub == \"DOWN\" then\
        local key, selection, position, application = event.keyName, self.selection, self.position, self.application\
        local isPressed, start, stop = application:isPressed( keys.leftShift ) or application:isPressed( keys.rightShift )\
\
        if selection then\
            start, stop = selection < position and selection or position, selection > position and selection + 1 or position + 1\
        else start, stop = position - 1, position end\
\
        if key == \"enter\" then\
            self:executeCallbacks( \"trigger\", self.value, self.selection and self:getSelectedValue() )\
        elseif selection then\
            if key == \"delete\" or key == \"backspace\" then\
                self.value = stringSub( value, 1, start ) .. stringSub( value, stop )\
                self.position = start\
                self.selection = false\
            elseif not isPressed and ( key == \"left\" or key == \"right\" ) then\
                self.position = key == \"left\" and start + 1 or key == \"right\" and stop - 2\
                self.selection = false\
            end\
        end\
\
        local cSelection = self.selection or self.position\
        local function set( offset )\
            if isPressed then self.selection = cSelection + offset\
            else self.position = self.position + offset; self.selection = false end\
        end\
\
        if key == \"left\" then set( -1 )\
        elseif key == \"right\" then set( 1 ) else\
            if key == \"home\" then\
                set( isPressed and -cSelection or -position )\
            elseif key == \"end\" then\
                set( isPressed and valueLen - cSelection or valueLen - position )\
            elseif key == \"backspace\" and isPressed then\
                self.value, self.position = stringSub( self.value, stop + 1 ), 0\
            end\
        end\
\
        if not isPressed then\
            if key == \"backspace\" and start >= 0 and not selection then\
                self.value = stringSub( value, 1, start ) .. stringSub( value, stop + 1 )\
                self.position = start\
            elseif key == \"delete\" and not selection then\
                self.value, self.changed = stringSub( value, 1, stop ) .. stringSub( value, stop + 2 ), true\
            end\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc If an assigned label (labelFor set as this nodes ID on a label) is clicked, this input is focused\
    @param <Label Instance - label>, <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Input:onLabelClicked( label, event, handled, within )\
    self:focus()\
    event.handled = true\
end\
\
--[[\
    @instance\
    @desc Draws the inputs background and text to the parent canvas\
    @param [boolean - force]\
]]\
function Input:draw( force )\
    local raw = self.raw\
    if raw.changed or force then\
        local canvas, tc, bg = raw.canvas, raw.colour, raw.backgroundColour\
        if raw.focused then tc, bg = raw.focusedColour, raw.focusedBackgroundColour\
        elseif raw.active then tc, bg = raw.activeColour, raw.activeBackgroundColour end\
\
        canvas:clear( bg )\
\
        local position, width, value, selection, placeholder = self.position, self.width, self.mask ~= \"\" and stringRep( self.mask, #self.value ) or self.value, self.selection, self.placeholder\
        if self.focused or not placeholder or #value > 0 then\
            if self.selection then\
                local start, stop = selection < position and selection or position, selection > position and selection + 1 or position + 1\
                if start < stop then stop = stop - 1 end\
\
                local startPos = -self.scroll + 1\
\
                canvas:drawTextLine( startPos, 1, stringSub( value, 1, start + 1 ), tc, bg )\
                canvas:drawTextLine( startPos + start, 1, stringSub( value, start + 1, stop ), self.focused and self.selectedColour or tc, self.focused and self.selectedBackgroundColour or bg )\
                canvas:drawTextLine( startPos + stop, 1, stringSub( value, stop + 1 ), tc, bg )\
            else\
                canvas:drawTextLine( -self.scroll + 1, 1, value, tc, bg )\
            end\
        else canvas:drawTextLine( 1, 1, stringSub( placeholder, 1, self.width ), self.placeholderColour, bg ) end\
\
        raw.changed = false\
    end\
end\
\
--[[\
    @instance\
    @desc Attempts to reposition the scroll of the input box depending on the position indicator\
    @param <number - indicator>\
]]\
function Input:repositionScroll( indicator )\
    local limit = self.limit\
    local isLimit = limit > 0\
\
    if indicator >= self.width and indicator > ( self.scroll + self.width - 1 ) then\
        self.scroll = math.min( indicator - self.width + 1, #self.value - self.width + 1 ) - ( isLimit and indicator >= limit and 1 or 0 )\
    elseif indicator <= self.scroll then\
        self.scroll = math.max( self.scroll - ( self.scroll - indicator ), 0 )\
    else self.scroll = math.max( math.min( self.scroll, #self.value - self.width + 1 ), 0 ) end\
end\
\
--[[\
    @instance\
    @desc If the given selection is a number, it will be adjusted to fit within the bounds of the input and set. If not, the value will be raw set.\
    @param <number|boolean - selection>\
]]\
function Input:setSelection( selection )\
    if type( selection ) == \"number\" then\
        local newSelection = math.max( math.min( selection, #self.value ), 0 )\
        self.selection = newSelection ~= self.position and newSelection or false\
    else self.selection = selection end\
\
    self:repositionScroll( self.selection or self.position )\
    self.changed = true\
end\
\
--[[\
    @instance\
    @desc Returns the value of the input that is selected\
    @return <string - selectedValue>\
]]\
function Input:getSelectedValue()\
    local selection, position = self.selection, self.position\
    return stringSub( self.value, ( selection < position and selection or position ) + 1, ( selection > position and selection or position ) )\
end\
\
--[[\
    @instance\
    @desc If the given position is equal to the (inputs) selection, the selection will be reset.\
          If not equal, the value will be adjusted to fit inside the bounds of the input and then set.\
    @param <number - pos>\
]]\
function Input:setPosition( pos )\
    if self.selection == pos then self.selection = false end\
    self.position, self.changed = math.max( math.min( pos, #self.value ), 0 ), true\
\
    self:repositionScroll( self.position )\
end\
\
--[[\
    @instance\
    @desc When called, returns the state of the caret, its position (absolute) and colour.\
    @return <boolean - caretEnabled>, <number - caretX>, <number - caretY>, <colour - caretColour>\
]]\
function Input:getCaretInfo( parentLimit )\
    local sX, sY = self:getAbsolutePosition( parentLimit )\
    local limit = self.limit\
\
    return not self.selection and ( limit <= 0 or self.position < limit ), sX + ( self.position - self.scroll ), sY, self.focusedColour\
end\
\
\
configureConstructor({\
    orderedArguments = { \"X\", \"Y\", \"width\" },\
    argumentTypes = { value = \"string\", position = \"number\", selection = \"number\", placeholder = \"string\", placeholderColour = \"colour\", selectedColour = \"colour\", selectedBackgroundColour = \"colour\", limit = \"number\", mask = \"string\" },\
    useProxy = { \"toggled\" }\
}, true)",
  [ "MNodeContainer.ti" ] = "local function resetNode( self, node )\
    node:queueAreaReset()\
\
    node.application = nil\
    node.parent = nil\
\
    if self.focusedNode == node then\
        node.focused = false\
    end\
\
    node:executeCallbacks \"remove\"\
\
    self.changed = true\
    self:clearCollatedNodes()\
end\
\
abstract class MNodeContainer {\
    nodes = {}\
}\
\
--[[\
    @instance\
    @desc Adds a node to the object. This node will have its object and parent (this) set\
    @param <Instance 'Node' - node>\
    @return 'param1 (node)'\
]]\
function MNodeContainer:addNode( node )\
    if not Titanium.typeOf( node, \"Node\", true ) then\
        return error( \"Cannot add '\"..tostring( node )..\"' as Node on '\"..tostring( self )..\"'\" )\
    end\
\
    node.parent = self\
    if Titanium.typeOf( self, \"Application\", true ) then\
        node.application = self\
        self.needsThemeUpdate = true\
    else\
        if Titanium.typeOf( self.application, \"Application\", true ) then\
            node.application = self.application\
            self.application.needsThemeUpdate = true\
        end\
    end\
\
    self.changed = true\
    self:clearCollatedNodes()\
\
    table.insert( self.nodes, node )\
    node:updateZ()\
    node:retrieveThemes()\
    node:refreshDynamicValues()\
\
    if node.focused then node:focus() end\
    return node\
end\
\
--[[\
    @instance\
    @desc Removes a node matching the name* provided OR, if a node object is passed the actual node. Returns false if not found or (true and node)\
    @param <Instance 'Node'/string name - target>\
    @return <boolean - success>, [node - removedNode**]\
\
    *Note: In order for the node to be removed its 'name' field must match the 'name' parameter.\
    **Note: Removed node will only be returned if a node was removed (and thus success 'true')\
]]\
function MNodeContainer:removeNode( target )\
    local searchName = type( target ) == \"string\"\
\
    if not searchName and not Titanium.typeOf( target, \"Node\", true ) then\
        return error( \"Cannot perform search for node using target '\"..tostring( target )..\"' to remove.\" )\
    end\
\
    local nodes, node, nodeName = self.nodes, nil\
    for i = 1, #nodes do\
        node = nodes[ i ]\
\
        if ( searchName and node.id == target ) or ( not searchName and node == target ) then\
            resetNode( self, node )\
\
            table.remove( nodes, i )\
            return true, node\
        end\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Resets and removes every node from the instance\
]]\
function MNodeContainer:clearNodes()\
    local nodes = self.nodes\
    for i = #nodes, 1, -1 do\
        resetNode( self, nodes[ i ] )\
        table.remove( nodes, i )\
    end\
end\
\
--[[\
    @instance\
    @desc Searches for (and returns) a node with the 'id' specified. If 'recursive' is true and a node that contains others is found, the node will also be searched.\
    @param <string - id>, [boolean - recursive]\
    @return [Node Instance - node]\
]]\
function MNodeContainer:getNode( id, recursive )\
    local nodes, node = recursive and self.collatedNodes or self.nodes\
\
    for i = 1, #nodes do\
        node = nodes[ i ]\
        if node.id == id then\
            return node\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Returns true if the mouse event passed is in bounds of a visible child node\
    @param <MouseEvent - event>\
    @return [boolean - insideBounds]\
]]\
function MNodeContainer:isMouseColliding( event )\
    local eX, eY, nodes = event.X - self.X + 1, event.Y - self.Y + 1, self.nodes\
    for i = 1, #nodes do\
        local node = nodes[ i ]\
        local nodeX, nodeY = node.X, node.Y\
\
        if node.visible and eX >= nodeX and eX <= nodeX + node.width - 1 and eY >= nodeY and eY <= nodeY + node.height - 1 then\
            return true\
        end\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Returns a 'NodeQuery' instance containing the nodes that matched the query and methods to manipulate\
    @param <string - query>\
    @return <NodeQuery Instance - Query Result>\
]]\
function MNodeContainer:query( query )\
    return NodeQuery( self, query )\
end\
\
--[[\
    @instance\
    @desc Clears the collatedNodes of all parents forcing them to update their collatedNodes cache on next retrieval\
]]\
function MNodeContainer:clearCollatedNodes()\
    self.collatedNodes = false\
\
    local parent = self.parent\
    if parent then\
        parent:clearCollatedNodes()\
    end\
end\
\
--[[\
    @getter\
    @desc If no collatedNodes (or the collateNodes are empty), the nodes are collated (:collate) and returned.\
    @return <table - collatedNodes>\
]]\
function MNodeContainer:getCollatedNodes()\
    if not self.collatedNodes or #self.collatedNodes == 0 then\
        self:collate()\
    end\
\
    return self.collatedNodes\
end\
\
--[[\
    @instance\
    @desc Caches all nodes under this container (and child containers) in 'collatedNodes'.\
          This list maybe out of date if 'collate' isn't called before usage. Caching is not automatic.\
    @param [table - collated]\
]]\
function MNodeContainer:collate( collated )\
    local collated = collated or {}\
\
    local nodes, node = self.nodes\
    for i = 1, #nodes do\
        node = nodes[ i ]\
        collated[ #collated + 1 ] = node\
\
        local collatedNode = node.collatedNodes\
        if collatedNode then\
            for i = 1, #collatedNode do\
                collated[ #collated + 1 ] = collatedNode[ i ]\
            end\
        end\
    end\
\
    self.collatedNodes = collated\
end\
\
--[[\
    @setter\
    @desc Sets the enabled property of the node to 'enabled'. Sets node's 'changed' to true.\
    @param <boolean - enabled>\
]]\
function MNodeContainer:setEnabled( enabled )\
    self.super:setEnabled( enabled )\
    if self.parentEnabled then\
        local nodes = self.nodes\
        for i = 1, #nodes do\
            nodes[ i ].parentEnabled = enabled\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Updates all direct children with the new 'parentEnabled' property (found using 'enabled')\
    @param <boolean - enabled>\
]]\
function MNodeContainer:setParentEnabled( enabled )\
    self.super:setParentEnabled( enabled )\
\
    local newEnabled, nodes = self.enabled, self.nodes\
    for i = 1, #nodes do\
        nodes[ i ].parentEnabled = newEnabled\
    end\
end\
\
\
--[[\
    @setter\
    @desc Iterates over child nodes to ensure that nodes added to this container prior to Application set are updated (with the new Application)\
    @param <Application - app>\
]]\
function MNodeContainer:setApplication( app )\
    if self.super.setApplication then\
        self.super:setApplication( app )\
    else\
        self.application = app\
    end\
\
    local nodes = self.nodes\
    for i = 1, #nodes do\
        if nodes[ i ] then\
            nodes[ i ].application = app\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc When the background colour of a node changes (and therefore, it's canvas is to be cleared in Component), the children need to be redrawn over top.\
    @param <colour - backgroundColour>\
]]\
function MNodeContainer:setBackgroundColour( backgroundColour )\
    self.super:setBackgroundColour( backgroundColour )\
\
    local nodes = self.nodes\
    for i = 1, #nodes do\
        nodes[ i ].needsRedraw = true\
    end\
end\
\
--[[\
    @instance\
    @desc Clears the area provided and queues a redraw for child nodes intersecting the area.\
          The content of the child node will not be update, it's content will only be drawn to it's parent.\
    @param <number - x>, <number - y>, <number - width>, <number - height>\
]]\
function MNodeContainer:redrawArea( x, y, width, height, xOffset, yOffset )\
    y = y > 0 and y or 1\
    x = x > 0 and x or 1\
    if y + height - 1 > self.height then height = self.height - y + 1 end\
    if x + width - 1 > self.width then width = self.width - x + 1 end\
\
    if not self.canvas then return end\
    self.canvas:clearArea( x, y, width, height )\
\
    local nodes, node, nodeX, nodeY = self.nodes\
    for i = 1, #nodes do\
        node = nodes[ i ]\
        nodeX, nodeY = node.X + ( xOffset or 0 ), node.Y + ( yOffset or 0 )\
\
        if not ( nodeX + node.width - 1 < x or nodeX > x + width or nodeY + node.height - 1 < y or nodeY > y + height ) then\
            node.needsRedraw = true\
        end\
    end\
\
    local parent = self.parent\
    if parent then\
        parent:redrawArea( self.X + x - 1, self.Y + y - 1, width, height )\
    end\
end\
\
--[[\
    @instance\
    @desc Appends nodes loaded via TML to the Applications nodes.\
    @param <string - path>\
]]\
function MNodeContainer:importFromTML( path )\
    TML.fromFile( self, path )\
    self.changed = true\
end\
\
--[[\
    @instance\
    @desc Removes all nodes from the Application and inserts those loaded via TML\
    @param <string - path>\
]]\
function MNodeContainer:replaceWithTML( path )\
    local nodes, node = self.nodes\
    for i = #nodes, 1, -1 do\
        node = nodes[ i ]\
        node.parent = nil\
        node.application = nil\
\
        table.remove( nodes, i )\
    end\
\
    self:importFromTML( path )\
end",
  [ "Window.ti" ] = "--[[\
    @static proxyMethods - table (def. { \"addNode\", ... }) - The proxy methods being automatically created by the window. See 'about' for more information regarding proxy methods.\
\
    @instance title - string (def. nil) - The windows title, displayed inside the title bar (titleBar must be true)\
    @instance titleBar - boolean (def. true) - If true a title bar will be displayed at the top of the window which can be used to drag the window. Stored in 'window.titleBarContent', or can be queried using '#titlebar'\
    @instance titleBarColour - colour (def. 256) - The colour of the title bar\
    @instance titleBarBackgroundColour - colour (def. 128) - The background colour of the title bar\
    @instance closeable - boolean (def. true) - If true a close button will be visible (and enabled) in the top right. Only available when the title bar is enabled\
    @instance closeButtonChar - string (def. \"\\7\") - The text used inside the close button\
    @instance closeButtonColour - colour (def. 16384) - The colour of the close button\
    @instance closeButtonBackgroundColour - colour (def. nil) - The background colour of the close button\
    @instance resizeable - boolean (def. true) - If true the window will be resizeable via the resize handle in the bottom right of the window\
    @instance resizeButtonChar - string (def. \"/\") - The character used when drawing the resize handle\
    @instance resizeButtonColour - colour (def. 256) - The colour of the resize handle\
    @instance resizeButtonBackgroundColour - colour (def. nil) - The background colour of the resize handle\
    @instance moveable - boolean (def. true) - When true the window can be moved around by clicking and dragging the top of the window\
    @instance shadow - boolean (def. true) - When true, a shadow will be drawn around the window\
    @instance shadowColour - colour (def. 128) - The colour of the shadow\
    @instance transparent - boolean (def. true) - The transparency value of the window. Should be kept 'true' to ensure correct functionality when using a shadow\
    @instance passiveFocus - boolean (def. true) - When true the window will not override global focus (allowing content to be focused for typing). Should be kept 'true'\
\
    The Window is a niche Titanium node that allows entire containers to be dragged and resized on the screen. Titanium does *not* provide built-in management\
    of windows. If you intend to use them for your project it is suggested you keep track of windows and automatically cycle their z-values.\
\
    The 'content' key on the window contains all the nodes INSIDE the window, excluding the window itself. However the 'nodes' key contains every node, including the title bar, the close\
    button, and the actual content scroll container.\
\
    The Window provides 'proxyMethods'. For example, by default :addNode is actually a proxy that adds the node to 'window.content'. If you intend to add the node directly to the window\
    use ':addNodeRaw'. This applies to addNode, removeNode, getNode, query, and clearNodes. Edit Window.static.proxyMethods to change which proxy methods exist.\
\
    By default windows feature a close button, and resize handle, a title bar and a shadow. These can all be adjusted using the Window property OR by\
    directly targeting the nodes.\
\
    *Every* aspect of the window can be changed directly by querying the particular part of the window via ':query' or ':queryRaw'. However, it is preferred that if possible the window\
    is configured using the instance properties provided (ie: window.backgroundColour is preferred instead of window.content.backgroundColour or window:queryRaw \"#content\":set { ... }).\
\
    However, if you must target the node completely, you can do so via 'queryRaw' and the following target:\
        - The window main content, where the user content will appear: '#content'\
        - The title bar: '#titlebar'\
        - The title content (inside the title bar): '#titlebar > #title'\
        - The close button (inside the title bar): '#titlebar > #close'\
]]\
\
class Window extends Container mixin MFocusable mixin MInteractable {\
    static = {\
        proxyMethods = { \"addNode\", \"removeNode\", \"getNode\", \"query\", \"clearNodes\" }\
    };\
\
    titleBar = true;\
    titleBarColour = 256;\
    titleBarBackgroundColour = 128;\
\
    closeable = true;\
    closeButtonChar = \"\\7\";\
    closeButtonColour = 16384;\
\
    resizeable = true;\
    resizeButtonChar = \"/\";\
    resizeButtonColour = 256;\
\
    moveable = true;\
\
    shadow = true;\
    shadowColour = 128;\
\
    transparent = true;\
\
    passiveFocus = true;\
}\
\
--[[\
    @constructor\
    @desc Creates the default window layout, complete with a title bar and content container\
]]\
function Window:__init__( ... )\
    self:resolve( ... )\
    self:super()\
\
    self.titleBarContent = self:addNode( Container():set {\
        id = \"titlebar\",\
\
        width = \"$parent.width - ( parent.shadow and 1 or 0 )\",\
\
        backgroundColour = \"$parent.titleBarBackgroundColour\",\
        colour = \"$not parent.enabled and parent.disabledColour or parent.titleBarColour\",\
\
        visible = \"$parent.titleBar\",\
        enabled = \"$self.visible\"\
    })\
\
    self.titleBarTitle = self.titleBarContent:addNode( Label( \"\" ) ):set( \"id\", \"title\" )\
\
    local b = self.titleBarContent:addNode( Button( \"\" ):set( \"X\", \"$parent.width\" ) )\
    b:set {\
        backgroundColour = \"$parent.parent.closeButtonBackgroundColour\",\
        colour = \"$parent.parent.closeButtonColour\",\
        text = \"$parent.parent.closeButtonChar\",\
        visible = \"$parent.parent.closeable\",\
        enabled = \"$self.visible\",\
        id = \"close\"\
    }\
\
    b:on(\"trigger\", function()\
        self:executeCallbacks \"close\"\
        self.parent:removeNode( self )\
    end)\
\
    self.content = self:addNode( ScrollContainer():set {\
        Y = \"$parent.titleBar and 2 or 1\",\
\
        width = \"$parent.width - ( parent.shadow and 1 or 0 )\",\
        height = \"$parent.height - ( parent.titleBar and 1 or 0 ) - ( parent.shadow and 1 or 0 )\",\
\
        backgroundColour = \"$parent.enabled and ( parent.focused and parent.focusedBackgroundColour ) or ( not parent.enabled and parent.disabledBackgroundColour ) or parent.backgroundColour\",\
        colour = \"$parent.enabled and ( parent.focused and parent.focusedColour ) or ( not parent.enabled and parent.disabledColour ) or parent.colour\",\
\
        id = \"content\"\
    } )\
\
    for _, name in pairs( Window.static.proxyMethods ) do\
        self[ name ] = function( self, ... )\
            return self.content[ name ]( self.content, ... )\
        end\
\
        self[ name .. \"Raw\" ] = function( self, ... )\
            return self.super[ name ]( self, ... )\
        end\
    end\
\
    self:watchProperty( \"width\", function( _, __, value )\
        return self:updateWidth( value )\
    end, \"WINDOW_MIN_MAX_WIDTH_CHECK\" )\
\
    self:watchProperty( \"height\", function( _, __, value )\
        return self:updateHeight( value )\
    end, \"WINDOW_MIN_MAX_HEIGHT_CHECK\" )\
end\
\
--[[\
    @constructor\
    @desc After all the instance mixins are ready, this function is called allowing the dynamic value default to be set (before post init, the MPropertyManager is not listening for property changes)\
]]\
function Window:__postInit__()\
    if not self.resizeButtonBackgroundColour then\
        -- Apply the default dynamic value\
        self.resizeButtonBackgroundColour = \"$self.content.backgroundColour\"\
    end\
\
    self.consumeAll = false\
    self.super:__postInit__()\
end\
\
--[[\
    @instance\
    @desc Handles a mouse click by checking the location of the click. Depending on the location will either move, resize, focus or unfocus the window.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Window:onMouseClick( event, handled, within )\
    if within then\
        if not handled and event.button == 1 then\
            self:focus()\
\
            local X, Y = event.X - self.X + 1, event.Y - self.Y + 1\
            if self.moveable and Y == 1 and ( X >= 1 and X <= self.titleBarContent.width - ( self.closeable and 1 or 0 ) ) then\
                self:updateMouse( \"move\", X, Y )\
                event.handled = true\
            elseif self.resizeable and Y == self.content.height + ( self.titleBar and 1 or 0 ) and X == self.content.width then\
                self:updateMouse( \"resize\", event.X - self.width + 1, event.Y - self.height + 1 )\
                event.handled = true\
            end\
        end\
    else\
        self:unfocus()\
    end\
end\
\
--[[\
    @instance\
    @desc Removes the mouse param (used when moving or resizing), preventing further manipulation of the window\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Window:onMouseUp( event, handled, within )\
    self.mouse = false\
end\
\
--[[\
    @instance\
    @desc Handles a mouse drag by passing the request to the MInteractable mixin (handleMouseDrag)\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Window:onMouseDrag( event, handled, within )\
    self:handleMouseDrag( event, handled, within )\
end\
\
--[[\
    @instance\
    @desc Updates the titleBar label to display a correctly truncated version of the windows title.\
]]\
function Window:updateTitle()\
    local title, titleContentWidth = self.title, self.titleBarContent.width - ( self.closeable and 3 or 2 )\
\
    self.titleBarTitle.text = title and #title > titleContentWidth and title:sub( 1, math.max( 1, titleContentWidth - 2 ) ) .. \"..\" or title or \"\"\
end\
\
--[[\
    @instance\
    @desc Returns a bounded (min/max width) version of 'w' (or self.width if 'w' not provided).\
    @param [number - w]\
    @return <number - boundedW>\
]]\
function Window:updateWidth( w )\
    w = w or self.width\
\
    w = self.minWidth and math.max( w, self.minWidth ) or w\
    return math.max( self.maxWidth and math.min( w, self.maxWidth ) or w, ( self.shadow and 4 or 3 ) )\
end\
\
--[[\
    @instance\
    @desc Returns a bounded (min/max height) version of 'h' (or self.height if 'h' not provided).\
    @param [number - h]\
    @return <number - boundedH>\
]]\
function Window:updateHeight( h )\
    h = h or self.height\
\
    h = self.minHeight and math.max( h, self.minHeight ) or h\
    return math.max( self.maxHeight and math.min( h, self.maxHeight ) or h, ( self.titleBar and 4 or 3 ) )\
end\
\
--[[\
    @instance\
    @desc A custom draw function that invokes the super:draw method, before drawing the shadow and resize handle over top.\
]]\
function Window:draw( force, ... )\
    if force or self.changed then\
        self.super:draw( force, ... )\
\
        if self.shadow then\
            local canvas = self.canvas\
            canvas:drawBox( self.width, 2, 1, self.height - 2, self.shadowColour )\
            canvas:drawBox( 3, self.height, self.width - 2, 1, self.shadowColour )\
        end\
\
        if self.resizeable then\
            self.canvas:drawPoint( self.content.width, self.content.height + ( self.titleBar and 1 or 0 ), self.resizeButtonChar, self.resizeButtonColour, self.resizeButtonBackgroundColour )\
        end\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the width of the window, following the min/max properties (ie: uses :updateWidth())\
    @param <number - width>\
]]\
function Window:setWidth( width )\
    self.super:setWidth( self:updateWidth( width ) )\
    self:updateTitle()\
end\
\
--[[\
    @setter\
    @desc Sets the minimum width the window can be. The current width will be increased if it falls below this limit.\
    @param <number - minWidth>\
]]\
function Window:setMinWidth( minWidth )\
    self.minWidth = minWidth\
    self:updateWidth()\
end\
\
--[[\
    @setter\
    @desc Sets the maximum width the window can be. The current width will be reduced if it exceeds this limit.\
    @param <number - maxWidth>\
]]\
function Window:setMaxWidth( maxWidth )\
    self.maxWidth = maxWidth\
    self:updateWidth()\
end\
\
--[[\
    @setter\
    @desc Sets the height of the window, following the min/max properties (ie: uses :updateHeight())\
    @param <number - height>\
]]\
function Window:setHeight( height )\
    self.super:setHeight( self:updateHeight( height ) )\
end\
\
--[[\
    @setter\
    @desc Sets the minimum height the window can be. The current height will be increased if it falls below this limit.\
    @param <number - minHeight>\
]]\
function Window:setMinHeight( minHeight )\
    self.minHeight = minHeight\
    self:updateHeight()\
end\
\
--[[\
    @setter\
    @desc Sets the maximum height the window can be. The current height will be reduced if it exceeds this limit.\
    @param <number - maxHeight>\
]]\
function Window:setMaxHeight( maxHeight )\
    self.maxHeight = maxHeight\
    self:updateHeight()\
end\
\
--[[\
    @setter\
    @desc Sets the new title of the window, and then calls :updateTitle to apply the change to the titleBar label\
    @param <string - title>\
]]\
function Window:setTitle( title )\
    self.title = title\
    self:updateTitle()\
end\
\
--[[\
    @setter\
    @desc When the shadow of the window is updated, the window is redrawn to show the change\
    @param <boolean - enabled>\
]]\
function Window:setShadow( enabled )\
    self.shadow = enabled\
    self.changed = true\
end\
\
--[[\
    @setter\
    @desc When the shadow colour of the window is updated, the window is redrawn to show the change\
    @param <colour - colour>\
]]\
function Window:setShadowColour( colour )\
    self.shadowColour = colour\
    self.changed = true\
end\
\
configureConstructor {\
    argumentTypes = {\
        title = \"string\",\
        titleBar = \"boolean\",\
        titleBarColour = \"colour\",\
        titleBarBackgroundColour = \"colour\",\
\
        closeable = \"boolean\",\
        closeButtonChar = \"string\",\
        closeButtonColour = \"colour\",\
        closeButtonBackgroundColour = \"colour\",\
\
        resizeable = \"boolean\",\
        resizeButtonChar = \"string\",\
        resizeButtonColour = \"colour\",\
        resizeButtonBackgroundColour = \"colour\",\
\
        moveable = \"boolean\",\
\
        minWidth = \"number\",\
        minHeight = \"number\",\
\
        maxWidth = \"number\",\
        maxHeight = \"number\",\
\
        shadow = \"boolean\",\
        shadowColour = \"colour\"\
    }\
}",
  [ "NodeCanvas.ti" ] = "local string_sub = string.sub\
\
--[[\
    The NodeCanvas is an object that allows classes to draw to their canvas using functions that are useful when drawing 'nodes', hence the name.\
\
    The NodeCanvas should only be used by high-level objects (Nodes). Low level objects, such as 'Application' that require the ability to draw to the CraftOS terminal object\
    should be using TermCanvas instead.\
]]\
\
class NodeCanvas extends Canvas\
\
--[[\
    @instance\
    @desc Draws a single pixel using the arguments given. Char must only be one character long (hence the name).\
\
          Foreground and background colours will fallback to the canvas colour and backgroundColour (respectively) if not provided.\
    @param <number - x>, <number - y>, <string - char>, [number - tc], [number - bg]\
]]\
function NodeCanvas:drawPoint( x, y, char, tc, bg )\
    if #char > 1 then return error \"drawPoint can only draw one character\" end\
\
    self.buffer[ ( self.width * ( y - 1 ) ) + x ] = { char, tc or self.colour, bg or self.backgroundColour }\
end\
\
--[[\
    @instance\
    @desc Draws a line of text starting at the position given.\
\
          Foreground and background colours will fallback to the canvas colour and backgroundColour (respectively) if not provided.\
    @param <number - x>, <number - y>, <stringh - text>, [number - tc], [number - bg]\
]]\
function NodeCanvas:drawTextLine( x, y, text, tc, bg )\
    local tc, bg = tc or self.colour, bg or self.backgroundColour\
\
    local buffer, start = self.buffer, ( self.width * ( y - 1 ) ) + x\
    for i = 1, #text do\
        buffer[ -1 + start + i ] = { string_sub( text, i, i ), tc, bg }\
    end\
end\
\
--[[\
    @instance\
    @desc Draws a rectangle, with it's upper left corner being dictated by the x and y positions given\
\
          If not provided, 'col' will fallback to the backgroundColour of the canvas.\
    @param <number - x>, <number - y>, <number - width>, <number - height>, [number - col]\
]]\
function NodeCanvas:drawBox( x, y, width, height, col )\
    local tc, bg = self.colour, col or self.backgroundColour\
    local buffer = self.buffer\
\
    local px = { \" \", tc, bg }\
    for y = math.max( 0, y ), y + height - 1 do\
        for x = math.max( 1, x ), x + width - 1 do\
            buffer[ ( self.width * ( y - 1 ) ) + x ] = px\
        end\
    end\
end",
  [ "Theme.ti" ] = "local function getTagDetails( rule )\
    return ( rule.arguments.id and ( \"#\" .. rule.arguments.id ) or \"\" ) .. (function( classString ) local classes = \"\"; for className in classString:gmatch(\"%S+\") do classes = classes .. \".\"..className end; return classes end)( rule.arguments[\"class\"] or \"\" )\
end\
\
local function splitXMLTheme( queue, tree )\
    for i = 1, #tree do\
        local children = tree[ i ].children\
        if children then\
            for n = 1, #children do\
                local type = tree[ i ].type\
                queue[ #queue + 1 ] = { ( tree[ i ].arguments.typeOf and \"~\" or \"\" ) .. ( type == \"Any\" and \"*\" or type ) .. getTagDetails( tree[ i ] ), children[ n ], tree[ i ] }\
            end\
        end\
    end\
\
    return queue\
end\
\
--[[\
    @instance name - string (def. false) - The name of the theme. A name should always be set on the instance, and is a required constructor argument\
    @instance rules - table (def. {}) - The rules of this theme, generated via Theme.static.parse.\
\
    The Theme class is a basic class designed to hold styling rules.\
\
    Themes are added to objects using the MThemeManager mixin (or a custom implementation). These themes then dictate the appearance of objects that utilize 'MThemeable'.\
]]\
\
class Theme {\
    name = false;\
\
    rules = {};\
}\
\
--[[\
    @constructor\
    @desc Constructs the Theme by setting the name and, if 'source' is provided, parsing it and storing the result in 'rules'\
    @param <string - name>, [string - source]\
]]\
function Theme:__init__( name, source )\
    self.name = type( name ) == \"string\" and name or error(\"Failed to initialise Theme. Name '\"..tostring( name )..\"' is invalid, expected string.\")\
\
    if source then self.rules = Theme.parse( source ) end\
end\
\
--[[\
    @static\
    @desc Parses XML source code by lexing/parsing it into an XML tree. The XML is then parsed into theme rules\
    @param <string - source>\
    @return <table - rules>\
]]\
function Theme.static.parse( source )\
    local queue, rawRules, q = splitXMLTheme( {}, XMLParser( source ).tree ), {}, 1\
\
    local function processQueueEntry( entry )\
        local queryPrefix, rule = entry[ 1 ], entry[ 2 ]\
        local children = rule.children\
\
        if children then\
            for n = 1, #children do\
                if not Titanium.getClass( rule.type ) and rule.type ~= \"Any\" then\
                    return error( \"Failed to generate theme data. Child target '\"..rule.type..\"' doesn't exist as a Titanium class\" )\
                end\
\
                local type = rule.type\
                queue[ #queue + 1 ] = { queryPrefix .. \" \" .. ( rule.arguments.direct and \"> \" or \"\" ) .. ( type == \"Any\" and \"*\" or type ) .. getTagDetails( rule ), children[ n ], rule }\
            end\
        elseif rule.content then\
            local ownerType = entry[ 3 ].type\
            local dynamic = rule.arguments.dynamic\
\
            local ruleTarget, computeType, value, ruleProperty = ownerType, false, rule.content, rule.type\
            if ownerType == \"Any\" then\
                ruleTarget, computeType = \"ANY\", true\
            elseif not dynamic then\
                local parentReg = Titanium.getClass( ownerType ).getRegistry()\
                local argumentTypes = parentReg.constructor and parentReg.constructor.argumentTypes or {}\
\
                if parentReg.alias[ rule.type ] then\
                    ruleProperty = parentReg.alias[ rule.type ]\
                end\
\
                value = XMLParser.convertArgType( value, argumentTypes[ parentReg.alias[ rule.type ] or rule.type ] )\
            end\
\
            if dynamic then\
                value = rule.content\
            end\
\
            if not rawRules[ ruleTarget ] then rawRules[ ruleTarget ] = {} end\
            if not rawRules[ ruleTarget ][ queryPrefix ] then rawRules[ ruleTarget ][ queryPrefix ] = {} end\
            table.insert( rawRules[ ruleTarget ][ queryPrefix ], {\
                computeType = not dynamic and computeType or nil,\
                property = ruleProperty,\
                value = value,\
                important = rule.arguments.important,\
                isDynamic = dynamic\
            })\
        else\
            return error( \"Failed to generate theme data. Invalid theme rule found. No value (XML_CONTENT) has been set for tag '\"..rule.type..\"'\" )\
        end\
    end\
\
    while q <= #queue do\
        processQueueEntry( queue[ q ] )\
        q = q + 1\
    end\
\
    return rawRules\
end\
\
--[[\
    @static\
    @desc Creates a Theme instance with the name passed and the source as the contents of the file at 'path'.\
    @param <string - name>, <string - path>\
    @return <Theme Instance - Theme>\
]]\
function Theme.static.fromFile( name, path )\
    if not fs.exists( path ) then\
        return error( \"Path '\"..tostring( path )..\"' cannot be found\" )\
    end\
\
    local h = fs.open( path, \"r\" )\
    local content = h.readAll()\
    h.close()\
\
    return Theme( name, content )\
end",
  [ "CharEvent.ti" ] = "--[[\
    @instance main - string (def. \"CHAR\") - The main type of the event, should remain unchanged\
    @instance char - string (def. false) - The character that has been pressed\
]]\
\
class CharEvent extends Event {\
    main = \"CHAR\";\
    char = false;\
}\
\
--[[\
    @constructor\
    @desc Constructs the instance, adding the event name and the character to 'data'\
    @param <string - name>, <string - char>\
]]\
function CharEvent:__init__( name, char )\
    self.name = name\
    self.char = char\
\
    self.data = { name, char }\
end",
  [ "EditableTextContainer.ti" ] = "local string_sub = string.sub\
\
--[[\
    The EditableTextContainer is a slightly more advanced version of TextContainer, allowing for changes to be made to the displayed text\
]]\
\
class EditableTextContainer extends TextContainer {\
    allowKey = true,\
    allowChar = true\
}\
\
--[[\
    @instance\
    @desc Calls the super 'wrapText' with a reduced width (by one) so that space is left for the caret\
    @param <number - width>\
]]\
function EditableTextContainer:wrapText( width )\
    self.super:wrapText( width - 1 )\
end\
\
--[[\
    @instance\
    @desc Inserts the content given, using the provided offsets where provided.\
\
          The 'offsetPost' (def. 1) will be added to the position when appending the remainder of the string\
\
          'offsetPre' (def. 0) is subtracted from the position when creating the section to concatenate to the start of the value. If this is >1, content\
          will be lost (ie: backspace).\
\
          If there is a selection when this method is called, the selected content will be removed.\
\
          The position will be increased by the length of the value provided.\
    @param <string - value>, [number - offsetPost], [number - offsetPre]\
]]\
function EditableTextContainer:insertContent( value, offsetPost, offsetPre )\
    if self.selection then self:removeContent() end\
\
    local text = self.text\
    self.text = string_sub( text, 1, self.position - ( offsetPre or 0 ) ) .. value .. string_sub( text, self.position + ( offsetPost or 1 ) )\
    self.position = self.position + #value\
end\
\
--[[\
    @instance\
    @desc Removes the content at the position (or if a selection is made, the selected text). The preAmount (def. 1) specifies the content\
          to be kept BEFORE the selection/position. Hence, the higher the number the more content is lost.\
\
          Likewise, 'postAmount' (def. 1) is added to the remainder, the higher the number the more content AFTER the selection/position is lost\
    @param [number - preAmount], [number - postAmount]\
]]\
function EditableTextContainer:removeContent( preAmount, postAmount )\
    preAmount = preAmount or 1\
    local text = self.text\
    if self.selection then\
        self.text = string_sub( text, 1, math.min( self.selection, self.position ) - preAmount ) .. string_sub( text, math.max( self.selection, self.position ) + ( postAmount or 1 ) )\
        self.position = math.min( self.position, self.selection ) - 1\
\
        self.selection = false\
    else\
        if self.position == 0 and preAmount > 0 then return end\
\
        self.text = string_sub( text, 1, self.position - preAmount ) .. string_sub( text, self.position + ( postAmount or 1 ) )\
        self.position = self.position - preAmount\
    end\
end\
\
--[[\
    @instance\
    @desc Handles a 'key' event by moving the cursor (arrow keys), or removing text (delete/backspace), amongst other things\
    @param <KeyEvent Instance - event>, <boolean - handled>\
]]\
function EditableTextContainer:onKeyDown( event, handled )\
    if handled or not self.focused then return end\
\
    local key, lines, position, selection = event.keyName, self.lineConfig.lines, self.position, ( self.selection or self.position )\
    local isShift = self.application:isPressed( keys.leftShift ) or self.application:isPressed( keys.rightShift )\
\
    local old_tX\
    if key == \"up\" or key == \"down\" then\
        local line = lines[ isShift and self.cache.selY or self.cache.y ]\
        if not self.cache.tX then self.cache.tX = ( isShift and selection or position ) - line[ 2 ] + line[ 5 ] - 1 end\
\
        old_tX = self.cache.tX\
    end\
\
    if key == \"up\" then\
        local previousLine = lines[ ( isShift and self.cache.selY or self.cache.y ) - 1 ]\
        if not previousLine then return end\
\
        self[ isShift and \"selection\" or \"position\" ] = math.min( previousLine[ 2 ] + self.cache.tX - previousLine[ 5 ] + 1, previousLine[ 3 ] )\
    elseif key == \"down\" then\
        local nextLine = lines[ ( isShift and self.cache.selY or self.cache.y ) + 1 ]\
        if not nextLine then return end\
\
        self[ isShift and \"selection\" or \"position\" ] = math.min( nextLine[ 2 ] + self.cache.tX - nextLine[ 5 ] + 1, nextLine[ 3 ] - 1 )\
    elseif key == \"left\" then\
        if isShift then\
            self.selection = selection - 1\
        else\
            self.position = math.min( position, selection ) - 1\
        end\
    elseif key == \"right\" then\
        if isShift then\
            self.selection = selection + 1\
        else\
            self.position = math.max( position, selection - 1 ) + 1\
        end\
    elseif key == \"backspace\" then\
        self:removeContent( ( isShift and self.position - lines[ self.cache.y ][ 2 ] or 0 ) + 1 )\
    elseif key == \"enter\" then\
        self:insertContent \"\\n\"\
    elseif key == \"home\" then\
        self[ isShift and \"selection\" or \"position\" ] = lines[ self.cache.y ][ 2 ] - 1\
    elseif key == \"end\" then\
        self[ isShift and \"selection\" or \"position\" ] = lines[ self.cache.y ][ 3 ] - ( lines[ self.cache.y + 1 ] and 1 or -1 )\
    end\
\
    self.cache.tX = old_tX or self.cache.tX\
end\
\
--[[\
    @instance\
    @desc Inserts the character pressed, replacing the selection if one is made\
    @param <CharEvent Instance - event>, <boolean - handled>\
]]\
function EditableTextContainer:onChar( event, handled )\
    if handled or not self.focused then return end\
    self:insertContent( event.char )\
end\
\
--[[\
    @instance\
    @desc Invokes the setter for selection on the super before resetting 'cache.tX'\
    @param <number - selection>\
]]\
function EditableTextContainer:setSelection( ... )\
    self.super:setSelection( ... )\
    self.cache.tX = false\
end\
\
--[[\
    @instance\
    @desc Invokes the setter for position on the super before resetting 'cache.tX'\
    @param <number - position>\
]]\
function EditableTextContainer:setPosition( ... )\
    self.super:setPosition( ... )\
    self.cache.tX = false\
end\
\
--[[\
    @instance\
    @desc Returns the information for the caret position, using cache.x and cache.y (caret only displayed when no selection is made and the node is focused)\
    @return <boolean - visible>, <number - x>, <number - y>, <number - colour> - When the x and y position of the caret is NOT out of the bounds of the node\
    @return <boolean - false> - When the x or y position of the caret IS out of bounds\
]]\
function EditableTextContainer:getCaretInfo()\
    if not ( self.cache.x and self.cache.y ) then return false end\
    local x, y = self.cache.x - self.xScroll, self.cache.y - self.yScroll\
    if x < 0 or x > self.width or y < 1 or y > self.height then return false end\
\
    local sX, sY = self:getAbsolutePosition()\
    return self.focused and not self.selection and true, x + sX, y + sY - 1, self.focusedColour or self.colour\
end",
  [ "MProjectorManager.ti" ] = "--[[\
    @instance projectors - table (def. {}) - The registered projectors\
\
    Manages connected projectors by updating their content automatically, handling registration and removal as well as fetching projectors (by name)\
]]\
abstract class MProjectorManager {\
    projectors = {};\
}\
\
--[[\
    @instance\
    @desc Iterate over every registered projector, updating them to display more relevant information\
]]\
function MProjectorManager:updateProjectors()\
    local ps, p = self.projectors\
    for i = 1, #ps do\
        p = ps[ i ]\
        if p.changed then\
            p:updateDisplay()\
            p.changed = false\
        end\
    end\
end\
\
--[[\
    @instance\
    @desc Register the projector instance provided to allow child nodes to utilize it\
    @param <Projector Instance - projector>\
]]\
function MProjectorManager:addProjector( projector )\
    local ps = self.projectors\
    for i = 1, #ps do\
        if ps[ i ].name == projector.name then\
            return error( \"Failed to register projector instance. Projector name '\"..projector.name..\"' is already in use\" )\
        end\
    end\
\
    ps[ #ps + 1 ] = projector\
    projector.application = self\
\
    if self.focusedNode then\
        self.focusedNode:resolveProjectorFocus()\
    end\
end\
\
--[[\
    @instance\
    @desc Removes the projector specified\
    @param <Projector Instance - projector> - Remove the projector instance provided\
    @param <string - name> - Remove the projector instance named 'name'\
    @return <boolean - success>, [Projector Instance - removedProjector]\
]]\
function MProjectorManager:removeProjector( projector )\
    local searchName = type( projector ) == \"string\"\
\
    if not searchName and not Titanium.typeOf( projector, \"Projector\", true ) then\
        return error( \"Cannot perform search for projector using target '\"..tostring( projector )..\"' to remove.\" )\
    end\
\
    local ps, p = self.projectors\
    for i = 1, #ps do\
        p = ps[ i ]\
\
        if ( searchName and p.name == projector ) or ( not searchName and p == projector ) then\
            p.application = false\
            table.remove( ps, i )\
            return true, p\
        end\
    end\
\
    return false\
end\
\
--[[\
    @instance\
    @desc Returns the projector named 'name'\
    @param <string - name>\
    @return <Projector Instance - projector>\
]]\
function MProjectorManager:getProjector( name )\
    local ps = self.projectors\
    for i = 1, #ps do\
        if ps[ i ].name == name then\
            return ps[ i ]\
        end\
    end\
end",
  [ "Button.ti" ] = "--[[\
    @instance buttonLock - number (def. 1) - If 1 or 2, only mouse events with that button code will be handled. If 0, any mouse events will be handled\
\
    A Button is a node that can be clicked to trigger a callback.\
    The button can contain text which can span multiple lines, however if too much text is entered it will be truncated to fit the button dimensions.\
\
    When the Button is clicked, the 'trigger' callback will be executed.\
]]\
\
class Button extends Node mixin MTextDisplay mixin MActivatable {\
    allowMouse = true;\
    buttonLock = 1;\
}\
\
--[[\
    @constructor\
    @desc Accepts button arguments and resolves them.\
    @param <string - text>, [number - X], [number - Y], [number - width], [number - height]\
]]\
function Button:__init__( ... )\
    self:resolve( ... )\
    self:super()\
\
    self:register(\"width\", \"height\", \"buttonLock\")\
end\
\
--[[\
    @instance\
    @desc Sets the button to 'active' when the button is clicked with the valid mouse button (self.buttonLock)\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Button:onMouseClick( event, handled, within )\
    if not handled and within and ( self.buttonLock == 0 or event.button == self.buttonLock ) then\
        self.active, event.handled = true, true\
    end\
end\
\
--[[\
    @instance\
    @desc Sets the button to inactive when the mouse button is released. If released on button while active 'onTrigger' callback is fired.\
    @param <MouseEvent Instance - event>, <boolean - handled>, <boolean - within>\
]]\
function Button:onMouseUp( event, handled, within )\
    if within and not handled and self.active then\
        event.handled = true\
        self:executeCallbacks \"trigger\"\
    end\
\
    self.active = false\
end\
\
--[[\
    @instance\
    @desc Draws the text to the node canvas\
    @param [boolean - force]\
]]\
function Button:draw( force )\
    local raw = self.raw\
    if raw.changed or force then\
        local tc, bg\
        if not self.enabled then\
            bg, tc = raw.disabledBackgroundColour, raw.disabledColour\
        elseif self.active then\
            bg, tc = raw.activeBackgroundColour, raw.activeColour\
        end\
\
        raw.canvas:clear( bg )\
        self:drawText( bg, tc )\
\
        raw.changed = false\
    end\
end\
\
--[[\
    @setter\
    @desc Sets the text of the button and then wraps the new text for display.\
    @param <string - text>\
]]\
function Button:setText( text )\
    if self.text == text then return end\
\
    self.text = text\
    self.changed = true\
    self:wrapText()\
end\
\
--[[\
    @setter\
    @desc Sets the width of the button and then re-wraps the text to fit in the dimensions.\
    @param <number - width>\
]]\
function Button:setWidth( width )\
    self.super:setWidth( width )\
    self:wrapText()\
end\
\
configureConstructor {\
    orderedArguments = { \"text\" },\
    requiredArguments = { \"text\" },\
    argumentTypes = {\
        buttonLock = \"number\"\
    }\
}",
  [ "Titanium.lua" ] = "--[[\
    Event declaration\
    =================\
\
    Titanium needs to know what class types to spawn when an event is spawned, for flexibility this can be edited whenever you see fit. The matrix\
    starts blank, so we define basic events here. (on event type 'key', spawn instance of type 'value')\
]]\
Event.static.matrix = {\
    mouse_click = MouseEvent,\
    mouse_drag = MouseEvent,\
    mouse_up = MouseEvent,\
    mouse_scroll = MouseEvent,\
\
    key = KeyEvent,\
    key_up = KeyEvent,\
\
    char = CharEvent\
}\
\
--[[\
    Image Parsing\
    =============\
\
    Titaniums Image class parses image files based on their extension, two popular formats (nfp and default) are supported by default, however this can be expanded like you see here.\
    These functions are expected to return the dimensions of the image and, a buffer (2D table) of pixels to be drawn directly to the images canvas. Pixels that do not exist in the image\
    need not be accounted for, Titanium will automatically fill those as 'blank' pixels by setting them as 'transparent'.\
\
    See the default functions below for good examples of image parsing.\
]]\
\
Image.setImageParser(\"\", function( stream ) -- Default CC images, no extension\
    -- Break image into lines, find the maxwidth of the image (the length of the longest line)\
    local hex = TermCanvas.static.hex\
    width, lines, pixels = 1, {}, {}\
    for line in stream:gmatch \"([^\\n]*)\\n?\" do\
        width = math.max( width, #line )\
        lines[ #lines + 1 ] = line\
    end\
\
    -- Iterate each line, forming a buffer of pixels with missing information (whitespace) being left nil\
    for l = 1, #lines do\
        local y, line = width * ( l - 1 ), lines[ l ]\
\
        for i = 1, width do\
            local colour = hex[ line:sub( i, i ) ]\
            pixels[ y + i ] = { \" \", colour, colour }\
        end\
    end\
\
    return width, #lines, pixels\
end).setImageParser(\"nfp\", function( stream ) -- NFP images, .nfp extension\
    --TODO: Look into nfp file format and write parser\
end)\
\
--[[\
    Projector Setup\
    ===============\
\
    Before projectors can be used, modes for them must be registered. For example in order to project/mirror a container to a monitor a mode\
    specifically designed to project content to a monitor must be created (see below for the monitor projector mode).\
\
    Every projector mode must be registered via 'Projector.registerMode', passing a table of configuration keys. The table has to contain:\
        - mode (string) - The name of the 'mode' used when creating a projector\
        - init (function) - Executed automatically when this mode is selected inside a projector\
        - draw (function) - Executed when any of the mirrors have changed, requiring a redraw of the projector\
\
    Optional configuration keys:\
        - eventDispatcher (function) - Executed automatically when an event is caught by an attached mirror.\
        - targetResolver (function) - Executed automatically when the mode is changed, or the target is changed. Can be used to parse the target value (return the new target [becomes resolvedTarget])\
\
]]\
\
Projector.registerMode {\
    mode = \"monitor\",\
    draw = function( self )\
        local targets, t = self.resolvedTarget\
        local focused = self.application and self.application.focusedNode and self.containsFocus\
\
        local scale = self.textScale and XMLParser.convertArgType( self.textScale, \"number\" ) or 1\
\
        local blink, X, Y, colour\
        if focused then\
            blink, X, Y, colour = focused[ 1 ], focused[ 2 ], focused[ 3 ], focused[ 4 ]\
        end\
\
        local old = term.current()\
        for i = 1, #targets do\
            t = targets[ i ]\
            t.setTextScale( scale )\
\
            term.redirect( t )\
\
            self.canvas:draw( true )\
\
            term.setCursorBlink( blink or false )\
            if blink then\
                term.setCursorPos( X or 1, Y or 1 )\
                term.setTextColour( colour or 32768 )\
            end\
        end\
\
        term.redirect( old )\
    end,\
    eventDispatcher = function( self, event )\
        if event.handled or not self.resolvedTarget[ event.data[ 2 ] ] or event.main ~= \"MONITOR_TOUCH\" then return end\
\
        local function dispatch( event )\
            event.projectorOrigin = true\
\
            local mirrors = self.mirrors\
            local oX, oY = event.X, event.Y\
            for i = 1, #mirrors do\
                local mirror = mirrors[ i ]\
                local pX, pY = mirror.projectX, mirror.projectY\
                local offset = pX or pY\
\
                if offset then event.X, event.Y = oX + ( mirror.X - ( pX or 0 ) ), oY + ( mirror.Y - ( pY or 0 ) ) end\
                mirror:handle( event )\
                if offset then event.X, event.Y = oX, oY end\
            end\
        end\
\
        local X, Y = event.data[ 3 ], event.data[ 4 ]\
        dispatch( MouseEvent( \"mouse_click\", 1, X, Y ) )\
        self.application:schedule( function()\
            dispatch( MouseEvent( \"mouse_up\", 1, X, Y ) )\
        end, 0.1 )\
    end,\
    targetResolver = function( self, target )\
        if not type( target ) == \"string\" then\
            return error( \"Failed to resolve target '\"..tostring( target )..\"' for monitor projector mode. Expected number, got '\"..type( target )..\"'\")\
        end\
\
        local targets = {}\
        for t in target:gmatch \"%S+\" do\
            if not targets[ t ] then\
                targets[ #targets + 1 ] = peripheral.wrap( t ) or error(\"Failed to resolve targets for projector '\"..self.name..\"'. Invalid target '\"..t..\"'\")\
                targets[ t ] = true\
            end\
        end\
\
        self.width, self.height = targets[ 1 ].getSize()\
\
        return targets\
    end\
}\
\
--[[\
    Tween setup\
    ===========\
\
    The following blocks of code define the functions that will be invoked when an animation that used that type of easing is updated. These functions\
    are adjusted versions (the algorithm has remained the same, however code formatting and variable names are largely changed to match Titanium) of\
    the easing functions published by kikito on GitHub. Refer to 'LICENSE' in this project root for more information (and Enrique's license).\
\
    The functions are passed 4 arguments, these arguments are listed below:\
    - clock: This argument contains the current clock time of the Tween being updated, this is used to tell how far through the animation we are (in seconds)\
    - initial: The value of the property being animated at the instantiation of the tween. This is usually added as a Y-Axis transformation.\
    - change: The difference of the initial and final property value. ie: How much the value will have to change to match the final from where it was as instantiation.\
    - duration: The total duration of the running Tween.\
\
    Certain functions are passed extra arguments. The Tween class doesn't pass these in, however custom animation engines could invoke these easing functions\
    through `Tween.static.easing.<easingType>`.\
]]\
\
local abs, pow, asin, sin, sqrt, pi = math.abs, math.pow, math.asin, math.sin, math.sqrt, math.pi\
local easing = Tween.static.easing\
-- Linear easing function\
Tween.addEasing(\"linear\", function( clock, initial, change, duration )\
    return change * clock / duration + initial\
end)\
\
-- Quad easing functions\
Tween.addEasing(\"inQuad\", function( clock, initial, change, duration )\
    return change * pow( clock / duration, 2 ) + initial\
end).addEasing(\"outQuad\", function( clock, initial, change, duration )\
    local clock = clock / duration\
    return -change * clock * ( clock - 2 ) + initial\
end).addEasing(\"inOutQuad\", function( clock, initial, change, duration )\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return change / 2 * pow( clock, 2 ) + initial\
    end\
\
    return -change / 2 * ( ( clock - 1 ) * ( clock - 3 ) - 1 ) + initial\
end).addEasing(\"outInQuad\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outQuad( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inQuad( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration)\
end)\
\
-- Cubic easing functions\
Tween.addEasing(\"inCubic\", function( clock, initial, change, duration )\
    return change * pow( clock / duration, 3 ) + initial\
end).addEasing(\"outCubic\", function( clock, initial, change, duration )\
    return change * ( pow( clock / duration - 1, 3 ) + 1 ) + initial\
end).addEasing(\"inOutCubic\", function( clock, initial, change, duration )\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return change / 2 * clock * clock * clock + initial\
    end\
\
    clock = clock - 2\
    return change / 2 * (clock * clock * clock + 2) + initial\
end).addEasing(\"outInCubic\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outCubic( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inCubic( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Quart easing functions\
Tween.addEasing(\"inQuart\", function( clock, initial, change, duration )\
    return change * pow( clock / duration, 4 ) + initial\
end).addEasing(\"outQuart\", function( clock, initial, change, duration )\
    return -change * ( pow( clock / duration - 1, 4 ) - 1 ) + initial\
end).addEasing(\"inOutQuart\", function( clock, initial, change, duration )\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return change / 2 * pow(clock, 4) + initial\
    end\
\
    return -change / 2 * ( pow( clock - 2, 4 ) - 2 ) + initial\
end).addEasing(\"outInQuart\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outQuart( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inQuart( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Quint easing functions\
Tween.addEasing(\"inQuint\", function( clock, initial, change, duration )\
    return change * pow( clock / duration, 5 ) + initial\
end).addEasing(\"outQuint\", function( clock, initial, change, duration )\
    return change * ( pow( clock / duration - 1, 5 ) + 1 ) + initial\
end).addEasing(\"inOutQuint\", function( clock, initial, change, duration )\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return change / 2 * pow( clock, 5 ) + initial\
    end\
\
    return change / 2 * (pow( clock - 2, 5 ) + 2 ) + initial\
end).addEasing(\"outInQuint\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outQuint( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inQuint( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Sine easing functions\
Tween.addEasing(\"inSine\", function( clock, initial, change, duration )\
    return -change * cos( clock / duration * ( pi / 2 ) ) + change + initial\
end).addEasing(\"outSine\", function( clock, initial, change, duration )\
    return change * sin( clock / duration * ( pi / 2 ) ) + initial\
end).addEasing(\"inOutSine\", function( clock, initial, change, duration )\
    return -change / 2 * ( cos( pi * clock / duration ) - 1 ) + initial\
end).addEasing(\"outInSine\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outSine( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inSine( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Expo easing functions\
Tween.addEasing(\"inExpo\", function( clock, initial, change, duration )\
    if clock == 0 then\
        return initial\
    end\
    return change * pow( 2, 10 * ( clock / duration - 1 ) ) + initial - change * 0.001\
end).addEasing(\"outExpo\", function( clock, initial, change, duration )\
    if clock == duration then\
        return initial + change\
    end\
\
    return change * 1.001 * ( -pow( 2, -10 * clock / duration ) + 1 ) + initial\
end).addEasing(\"inOutExpo\", function( clock, initial, change, duration )\
    if clock == 0 then\
        return initial\
    elseif clock == duration then\
        return initial + change\
    end\
\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return change / 2 * pow( 2, 10 * ( clock - 1 ) ) + initial - change * 0.0005\
    end\
\
    return change / 2 * 1.0005 * ( -pow( 2, -10 * ( clock - 1 ) ) + 2 ) + initial\
end).addEasing(\"outInExpo\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outExpo( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inExpo( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Circ easing functions\
Tween.addEasing(\"inCirc\", function( clock, initial, change, duration )\
    return -change * ( sqrt( 1 - pow( clock / duration, 2 ) ) - 1 ) + initial\
end).addEasing(\"outCirc\", function( clock, initial, change, duration )\
    return change * sqrt( 1 - pow( clock / duration - 1, 2 ) ) + initial\
end).addEasing(\"inOutCirc\", function( clock, initial, change, duration )\
    local clock = clock / duration * 2\
    if clock < 1 then\
        return -change / 2 * ( sqrt( 1 - clock * clock ) - 1 ) + initial\
    end\
\
    clock = clock - 2\
    return change / 2 * ( sqrt( 1 - clock * clock ) + 1 ) + initial\
end).addEasing(\"outInCirc\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outCirc( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inCirc( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)\
\
-- Elastic easing functions\
local function calculatePAS(p,a,change,duration)\
  local p, a = p or duration * 0.3, a or 0\
  if a < abs( change ) then\
      return p, change, p / 4 -- p, a, s\
  end\
\
  return p, a, p / ( 2 * pi ) * asin( change / a ) -- p,a,s\
end\
\
Tween.addEasing(\"inElastic\", function( clock, initial, change, duration, amplitude, period )\
    if clock == 0 then return initial end\
\
    local clock, s = clock / duration\
    if clock == 1 then\
        return initial + change\
    end\
\
    clock, p, a, s = clock - 1, calculatePAS( p, a, change, duration )\
    return -( a * pow( 2, 10 * clock ) * sin( ( clock * duration - s ) * ( 2 * pi ) / p ) ) + initial\
end).addEasing(\"outElastic\", function( clock, initial, change, duration, amplitude, period )\
    if clock == 0 then\
        return initial\
    end\
    local clock, s = clock / duration\
\
    if clock == 1 then\
        return initial + change\
    end\
\
    local p,a,s = calculatePAS( period, amplitude, change, duration )\
    return a * pow( 2, -10 * clock ) * sin( ( clock * duration - s ) * ( 2 * pi ) / p ) + change + initial\
end).addEasing(\"inOutElastic\", function( clock, initial, change, duration, amplitude, period )\
    if clock == 0 then return initial end\
\
    local clock = clock / duration * 2\
    if clock == 2 then return initial + change end\
\
    local clock, p, a, s = clock - 1, calculatePAS( period, amplitude, change, duration )\
    if clock < 0 then\
        return -0.5 * ( a * pow( 2, 10 * clock ) * sin( ( clock * duration - s ) * ( 2 * pi ) / p ) ) + initial\
    end\
\
    return a * pow( 2, -10 * clock ) * sin( ( clock * duration - s ) * ( 2 * pi ) / p ) * 0.5 + change + initial\
end).addEasing(\"outInElastic\", function( clock, initial, change, duration, amplitude, period )\
    if clock < duration / 2 then\
        return easing.outElastic( clock * 2, initial, change / 2, duration, amplitude, period )\
    end\
\
    return easing.inElastic( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration, amplitude, period )\
end)\
\
-- Back easing functions\
Tween.addEasing(\"inBack\", function( clock, initial, change, duration, s )\
    local s, clock = s or 1.70158, clock / duration\
\
    return change * clock * clock * ( ( s + 1 ) * clock - s ) + initial\
end).addEasing(\"outBack\", function( clock, initial, change, duration, s )\
    local s, clock = s or 1.70158, clock / duration - 1\
\
    return change * ( clock * clock * ( ( s + 1 ) * clock + s ) + 1 ) + initial\
end).addEasing(\"inOutBack\", function( clock, initial, change, duration, s )\
    local s, clock = ( s or 1.70158 ) * 1.525, clock / duration * 2\
    if clock < 1 then\
        return change / 2 * ( clock * clock * ( ( s + 1 ) * clock - s ) ) + initial\
    end\
\
    clock = clock - 2\
    return change / 2 * ( clock * clock * ( ( s + 1 ) * clock + s ) + 2 ) + initial\
end).addEasing(\"outInBack\", function( clock, initial, change, duration, s )\
    if clock < duration / 2 then\
        return easing.outBack( clock * 2, initial, change / 2, duration, s )\
    end\
\
    return easing.inBack( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration, s )\
end)\
\
-- Bounce easing functions\
Tween.addEasing(\"inBounce\", function( clock, initial, change, duration )\
    return change - easing.outBounce( duration - clock, 0, change, duration ) + initial\
end).addEasing(\"outBounce\", function( clock, initial, change, duration )\
    local clock = clock / duration\
    if clock < 1 / 2.75 then\
        return change * ( 7.5625 * clock * clock ) + initial\
    elseif clock < 2 / 2.75 then\
        clock = clock - ( 1.5 / 2.75 )\
        return change * ( 7.5625 * clock * clock + 0.75 ) + initial\
    elseif clock < 2.5 / 2.75 then\
        clock = clock - ( 2.25 / 2.75 )\
        return change * ( 7.5625 * clock * clock + 0.9375 ) + initial\
    end\
\
    clock = clock - (2.625 / 2.75)\
    return change * (7.5625 * clock * clock + 0.984375) + initial\
end).addEasing(\"inOutBounce\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.inBounce( clock * 2, 0, change, duration ) * 0.5 + initial\
    end\
\
    return easing.outBounce( clock * 2 - duration, 0, change, duration ) * 0.5 + change * .5 + initial\
end).addEasing(\"outInBounce\", function( clock, initial, change, duration )\
    if clock < duration / 2 then\
        return easing.outBounce( clock * 2, initial, change / 2, duration )\
    end\
\
    return easing.inBounce( ( clock * 2 ) - duration, initial + change / 2, change / 2, duration )\
end)",
}
local scriptFiles = {
  [ "versionCheck.lua" ] = true,
  [ "Class.lua" ] = true,
  [ "Titanium.lua" ] = true,
}
local preLoad = {
  "versionCheck.lua",
}
local loaded = {}
local function loadFile( name, verify )
    if loaded[ name ] then return end

    local content = files[ name ]
    if content then
        local output, err = loadstring( Titanium and not scriptFiles[ name ] and Titanium.preprocess( content ) or content, name )
        if not output or err then return error( "Failed to load Lua chunk. File '"..name.."' has a syntax error: "..tostring( err ), 0 ) end

        local ok, err = pcall( output )
        if not ok or err then return error( "Failed to execute Lua chunk. File '"..name.."' crashed: "..tostring( err ), 0 ) end

        if verify then
            local className = name:gsub( "%..*", "" )
            local class = Titanium.getClass( className )

            if class then
                if not class:isCompiled() then class:compile() end
            else return error( "File '"..name.."' failed to create class '"..className.."'" ) end
        end

        loaded[ name ] = true
    else return error("Failed to load Titanium. File '"..tostring( name ).."' cannot be found.") end
end

-- Load our class file
loadFile( "Class.lua" )

Titanium.setClassLoader(function( name )
    local fName = name..".ti"

    if not files[ fName ] then
        return error("Failed to find file '"..fName..", to load missing class '"..name.."'.", 3)
    else
        loadFile( fName, true )
    end
end)

-- Load any files specified by our config file
for i = 1, #preLoad do loadFile( preLoad[ i ], not scriptFiles[ preLoad[ i ] ] ) end

-- Load all class files
for name in pairs( files ) do
    if not scriptFiles[ name ] then
        loadFile( name, true )
    end
end

-- Load all script files
for name in pairs( scriptFiles ) do
    loadFile( name, false )
end

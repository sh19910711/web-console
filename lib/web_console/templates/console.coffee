#
# Constructor for command storage.
# It uses localStorage if available. Otherwise fallback to normal JS array.
#
class CommandStorage

  previousCommands: []
  previousCommandOffset = 0
  hasLocalStorage = typeof window.localStorage != 'undefined'
  STORAGE_KEY = "web_console_previous_commands"
  MAX_STORAGE = 100

  constructor: ->
    if hasLocalStorage
      @previousCommands = JSON.parse(localStorage.getItem(STORAGE_KEY)) || []
      previousCommandOffset = @previousCommands.length

  addCommand: (command)->
    previousCommandOffset = @previousCommands.push(command)

    if previousCommandOffset > MAX_STORAGE
      @previousCommands.splice(0, 1)
      previousCommandOffset = MAX_STORAGE
   

    if hasLocalStorage
      localStorage.setItem(STORAGE_KEY, JSON.stringify(@previousCommands))
   
 

  navigate: (offset)->
    previousCommandOffset += offset

    if previousCommandOffset < 0
      previousCommandOffset = -1
      return null
   

    if previousCommandOffset >= @previousCommands.length
      previousCommandOffset = @previousCommands.length
      return null
   

    @previousCommands[previousCommandOffset]
 
# HTML strings for dynamic elements.
consoleInnerHtml = <%= render_inlined_string '_inner_console_markup.html' %>
promptBoxHtml = <%= render_inlined_string '_prompt_box_markup.html' %>
# CSS
consoleStyleCss = <%= render_inlined_string 'style.css' %>
# Insert a style element with the unique ID
styleElementId = 'sr02459pvbvrmhco'

# REPLConsole
class REPLConsole

  constructor: (config)->
    @commandStorage = new CommandStorage()
    @prompt = config && if config.promptLabel then config.promptLabel else ' >>'
    @commandHandle = config && if config.commandHandle then config.commandHandle else -> @

  install: (container)->
    _this = this

    document.onkeydown = (ev)->
      if _this.focused
        _this.onKeyDown(ev)
   

    document.onkeypress = (ev)->
      if _this.focused
        _this.onKeyPress(ev)
   

    document.addEventListener 'mousedown', (ev)->
      el = ev.target || ev.srcElement

      if el
        loop
          if el == container
            _this.focus()
            return
         
          break unless el = el.parentNode

        _this.blur()

    # Render the console.
    container.innerHTML = consoleInnerHtml

    # Make the console resizable.
    document.getElementById('resizer').addEventListener 'mousedown', (ev)->
      startY                   = ev.clientY
      startHeight              = parseInt(document.defaultView.getComputedStyle(container).height, 10)
      consoleInner             = document.getElementsByClassName('console-inner')[0]
      innerScrollTopStart      = consoleInner.scrollTop
      innerClientHeightStart   = consoleInner.clientHeight

      doDrag = (e)->
        container.style.height = (startHeight + startY - e.clientY) + 'px'
        consoleInner.scrollTop = innerScrollTopStart + (innerClientHeightStart - consoleInner.clientHeight)
     

      stopDrag = (e)->
        document.documentElement.removeEventListener('mousemove', doDrag, false)
        document.documentElement.removeEventListener('mouseup', stopDrag, false)
     

      document.documentElement.addEventListener('mousemove', doDrag, false)
      document.documentElement.addEventListener('mouseup', stopDrag, false)

    # Initialize
    @inner = container.getElementsByClassName('console-inner')[0]
    @clipboard = document.getElementById('clipboard')
    @remotePath = container.dataset.remotePath
    @newPromptBox()
    @insertCss()


  # Add CSS styles dynamically. This probably doesnt work for IE <8.
  insertCss: ->
    if document.getElementById(styleElementId)
      return # already inserted
   
    style = document.createElement('style')
    style.type = 'text/css'
    style.innerHTML = consoleStyleCss
    style.id = styleElementId
    document.getElementsByTagName('head')[0].appendChild(style)


  focus: ->
    unless @focused
      @focused = true
      unless hasClass(@inner, "console-focus")
        addClass(@inner, "console-focus")
     
      @scrollToBottom()
 


  blur: ->
    @focused = false
    removeClass(@inner, "console-focus")

  #
  # Add a new empty prompt box to the console.
  #
  newPromptBox: ->
    # Remove the caret from previous prompt display if any.
    if @promptDisplay
      @removeCaretFromPrompt()
   

    promptBox = document.createElement('div')
    promptBox.className = "console-prompt-box"
    promptBox.innerHTML = promptBoxHtml
    @promptLabel = promptBox.getElementsByClassName('console-prompt-label')[0]
    @promptDisplay = promptBox.getElementsByClassName('console-prompt-display')[0]
    # Render the prompt box
    @setInput("")
    @promptLabel.innerHTML = @prompt
    @inner.appendChild(promptBox)
    @scrollToBottom()


  #
  # Remove the caret from the prompt box,
  # mainly before adding a new prompt box.
  # For simplicity, just re-render the prompt box
  # with caret position -1.
  #
  removeCaretFromPrompt: ->
    @setInput(@_input, -1)


  setInput: (input, caretPos)->
    @_caretPos = if caretPos == undefined then input.length else caretPos
    @_input = input
    @renderInput()


  #
  # Add some text to the existing input.
  #
  addToInput: (val, caretPos)->
    caretPos = caretPos || @_caretPos
    before = @_input.substring(0, caretPos)
    after = @_input.substring(caretPos, @_input.length)
    newInput =  before + val + after
    @setInput(newInput, caretPos + val.length)


  #
  # Render the input prompt. This is called whenever
  # the user input changes, sometimes not very efficient.
  #
  renderInput: ->
    # Clear the current input.
    removeAllChildren(@promptDisplay)

    promptCursor = document.createElement('span')
    promptCursor.className = "console-cursor"
    before = current = after = null

    if @_caretPos < 0
      before = @_input
      current = after = ""
    else if @_caretPos == @_input.length
      before = @_input
      current = "\u00A0"
      after = ""
    else
      before = @_input.substring(0, @_caretPos)
      current = @_input.charAt(@_caretPos)
      after = @_input.substring(@_caretPos + 1, @_input.length)
   

    @promptDisplay.appendChild(document.createTextNode(before))
    promptCursor.appendChild(document.createTextNode(current))
    @promptDisplay.appendChild(promptCursor)
    @promptDisplay.appendChild(document.createTextNode(after))


  writeOutput: (output)->
    consoleMessage = document.createElement('pre')
    consoleMessage.className = "console-message"
    consoleMessage.innerHTML = escapeHTML(output)
    @inner.appendChild(consoleMessage)
    @newPromptBox()


  onEnterKey: ->
    input = @_input

    if input != "" && input != undefined
      @commandStorage.addCommand(input)

    @commandHandle(input)


  onNavigateHistory: (offset)->
    command = @commandStorage.navigate(offset) || ""
    @setInput(command)


  #
  # Handle control keys like up, down, left, right.
  #
  onKeyDown: (ev)->
    switch ev.keyCode
      when 13
        # Enter key
        @onEnterKey()
        ev.preventDefault()
        break
      when 80
        # Ctrl-P
        unless ev.ctrlKey
          break
      when 38
        # Up arrow
        @onNavigateHistory(-1)
        ev.preventDefault()
        break
      when 78
        # Ctrl-N
        unless ev.ctrlKey
          break
      when 40
        # Down arrow
        @onNavigateHistory(1)
        ev.preventDefault()
        break
      when 37
        # Left arrow
        caretPos = if @_caretPos > 0 then @_caretPos - 1 else @_caretPos
        @setInput(@_input, caretPos)
        ev.preventDefault()
        break
      when 39
        # Right arrow
        length = @_input.length
        caretPos = if @_caretPos < length then @_caretPos + 1 else @_caretPos
        @setInput(@_input, caretPos)
        ev.preventDefault()
        break
      when 8
        # Delete
        @deleteAtCurrent()
        ev.preventDefault()
        break
      else
        break
   

    if ev.ctrlKey || ev.metaKey
      # Set focus to our clipboard in case they hit the "v" key
      @clipboard.focus()
      if ev.keyCode == 86
        # Pasting to clipboard doesn't happen immediately,
        # so we have to wait for a while to get the pasted text.
        _this = this
        setTimeout(
          ->
            _this.addToInput(_this.clipboard.value)
            _this.clipboard.value = ""
            _this.clipboard.blur()
          10
        )

    ev.stopPropagation()

  # ok here

  #
  # Handle input key press.
  #
  onKeyPress: (ev)->
    # Only write to the console if it's a single key press.
    if ev.ctrlKey || ev.metaKey
      return
    keyCode = ev.keyCode || ev.which
    @insertAtCurrent(String.fromCharCode(keyCode))
    ev.stopPropagation()
    ev.preventDefault()

  #
  # Delete a character at the current position.
  #
  deleteAtCurrent: ->
    if @_caretPos > 0
      caretPos = @_caretPos - 1
      before = @_input.substring(0, caretPos)
      after = @_input.substring(@_caretPos, @_input.length)
      @setInput(before + after, caretPos)
 
  #
  # Insert a character at the current position.
  #
  insertAtCurrent: (char)->
    before = @_input.substring(0, @_caretPos)
    after = @_input.substring(@_caretPos, @_input.length)
    @setInput(before + char + after, @_caretPos + 1)


  scrollToBottom: ->
    @inner.scrollTop = @inner.scrollHeight


  # Change the binding of the console
  switchBindingTo: (frameId, callback)->
    url = @remotePath + "/trace"
    params = "frame_id=" + encodeURIComponent(frameId)
    postRequest(url, params, callback)


  #
  # Install the console into the element with a specific ID.
  # Example: REPLConsole.installInto("target-id")
  #
  @installInto: (id)->
    consoleElement = document.getElementById(id)
    remotePath = consoleElement.dataset.remotePath
    replConsole = new REPLConsole
      promptLabel: consoleElement.dataset.initialPrompt,
      commandHandle: (line)->
        _this = this
        url = remotePath
        params = "input=" + encodeURIComponent(line)
        putRequest url, params, (xhr)->
          response = JSON.parse(xhr.responseText)
          _this.writeOutput(response.output)

    replConsole.install(consoleElement)
    REPLConsole.session[remotePath] = replConsole
    replConsole

# Store instances with the remote paths
REPLConsole.session = {}

# DOM helpers
hasClass = (el, className)->
  regex = new RegExp('(?:^|\\s)' + className + '(?!\\S)', 'g')
  el.className.match(regex)


addClass = (el, className)->
  el.className += " " + className


removeClass = (el, className)->
  regex = new RegExp('(?:^|\\s)' + className + '(?!\\S)', 'g')
  el.className = el.className.replace(regex, '')


removeAllChildren = (el)->
  while (el.firstChild)
    el.removeChild(el.firstChild)
 


escapeHTML = (html)->
  html
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/`/g, '&#x60;')


# XHR helpers
request = (method, url, params, callback)->
  xhr = new XMLHttpRequest()

  xhr.open(method, url, true)
  xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
  xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest")
  xhr.send(params)

  xhr.onreadystatechange = ->
    if xhr.readyState == 4
      callback(xhr)

postRequest = (url, params, callback)->
  request("POST", url, params, callback)


putRequest = (url, params, callback)->
  request("PUT", url, params, callback)


window.REPLConsole = REPLConsole

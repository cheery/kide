window.addEventListener 'load', () ->
    window.env = env = {}
    env.editor = editor = ace.edit("editor")
    editor.setTheme("ace/theme/monokai")
    editor.getSession().setMode("ace/mode/python")

    socket = io.connect("http://localhost")
    socket.on 'init', (data) ->
        editor.setValue(data)
    socket.on 'button', ({title, name}) ->
        btn = document.createElement('button')
        btn.innerText = title
        btn.onclick = () ->
            box = {name, source:editor.getValue()}
            socket.emit('button', box)
        sidebar = document.getElementById('sidebar')
        sidebar.appendChild btn
    socket.on "inject", (code) ->
        CoffeeScript.run(code)

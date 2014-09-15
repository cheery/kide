spawn = require('child_process').spawn
path = require('path')
fs = require('fs')
express = require('express')
app = express()
server = require('http').Server(app)
io = require('socket.io')(server)
gate = require('./gate')
CoffeeScript = require('coffee-script')

GLOBAL.env = env = {}
gate __dirname + '/client.sock', (code) -> io.to("editor").emit("inject", code)
gate __dirname + '/server.sock', (code) -> CoffeeScript.run(code)

env.io = io
env.app = app

env.projectdir = process.argv[2] or ""

app.use '/', express.static(__dirname + '/www')

io.on 'connection', (socket) ->
    socket.join('editor')
    mainfile = path.join(env.projectdir, "main.py")
    if fs.existsSync(mainfile)
        src = fs.readFileSync(mainfile)
        socket.emit('init', src.toString())
    else
        console.log 'no file'
        socket.emit('init', '')
    socket.emit 'button', {name: 'save', title: 'save'}
    socket.emit 'button', {name: 'run', title: 'run'}

    socket.on 'button', ({name, source}) ->
        fs.writeFileSync(mainfile, source)
        if name == 'run'
            proc = spawn('python', [mainfile])
            proc.stdout.pipe(process.stdout)
            proc.stderr.pipe(process.stderr)
            proc.on 'close', (code) ->
                console.log 'child exited: ' + code

#app.get '/', (req, res) ->
#    res.send 'hi'

server.listen(3000)

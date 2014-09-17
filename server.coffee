crypto  = require 'crypto'
express = require 'express'
fs      = require 'fs'
https   = require 'https'
spawn   = (require 'child_process').spawn
websock = require 'socket.io'
path    = require('path')

options = {
    server: {
        key: fs.readFileSync('ssl/server.key')
        cert: fs.readFileSync('ssl/server.crt')
        port: 3000 # would be 443 on gcw system
    }
    develop: true
    projectdir: path.resolve(process.argv[2] or ".")
    systemdir: path.resolve(__dirname)
}

GLOBAL.env = env = {}

env.options = options
env.app     = app     = express()
env.server  = server  = https.createServer(options.server, app)
env.io      = io      = websock(server)

if options.develop
    CoffeeScript = require 'coffee-script'
    gate         = require './gate'
    gate path.resolve(options.systemdir, 'client.sock'), (source) ->
        io.sockets.emit("source", source)
    gate path.resolve(options.systemdir, 'server.sock'), (source) ->
        CoffeeScript.run(source)

app.use '/', express.static(path.resolve(options.systemdir, 'www'))

env.newPid = () ->
    return crypto.randomBytes(3).toString('hex')

env.init = () ->
    env.pid = env.newPid()
    console.log "project", options.projectdir
    console.log "Server address https:// [not implemented]"
    console.log "PID: #{env.pid}"

services = {}

env.register = (name, service) ->
    services[name] = service
    if env.socket?
        env.socket.on name, service

env.connect = (socket) ->
    env.socket = socket
    socket.on 'disconnect', () ->
        env.socket = null
        env.init()
        for name, service of services
            socket.on name, service

io.on 'connection', (socket) ->
    socket.on 'pid', (pid, response) ->
        if pid == env.pid and not env.socket?
            env.connect(socket)
            response(true)
        else
            response(false)

env.init()

servicesdir = path.resolve(options.systemdir, "services")
for service in fs.readdirSync(servicesdir)
    if /.coffee$/.test(service)
        require(path.resolve(servicesdir, service))

server.listen(options.server.port)

#options = {
#    ca: fs.readFileSync('ssl/ca.crt')
#    requestCert: true
#    rejectUnauthorized: false
#}
#
#app.use '*', (req, res, next) ->
#    if req.client.authorized or true
#        next()
#    else
#        res.status(401).send("denied")
#
#io.use (socket, next) ->
#    if socket.request.client.authorized
#        next()
#    else
#        next(new Error("not authorized"))
#
#io.on 'connection', (socket) ->
#    mainfile = path.join(env.projectdir, "main.py")
#    if fs.existsSync(mainfile)
#        src = fs.readFileSync(mainfile)
#        socket.emit('init', src.toString())
#    else
#        console.log 'no file'
#        socket.emit('init', '')
#    socket.emit 'button', {name: 'save', title: 'save'}
#    socket.emit 'button', {name: 'run', title: 'run'}
#
#    socket.on 'button', ({name, source}) ->
#        fs.writeFileSync(mainfile, source)
##        if name == 'run'
##            proc = spawn('python', [mainfile])
##            proc.stdout.pipe(process.stdout)
##            proc.stderr.pipe(process.stderr)
##            proc.on 'close', (code) ->
##                console.log 'child exited: ' + code
#
#    socket.on 'hello', (data) ->
#        console.log "hello", data

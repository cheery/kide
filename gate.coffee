net = require('net')
fs = require('fs')

# to use the gate:
# map <C-Enter> :w !nc -U client.sock<CR><CR>
module.exports = (path, callback) ->
    if fs.existsSync(path)
        fs.unlinkSync(path)
    server = net.createServer (c) ->
        cache = ''
        c.on 'data', (data) ->
            cache += data.toString()
        c.on 'end', () ->
            callback(cache)
    server.listen(path)

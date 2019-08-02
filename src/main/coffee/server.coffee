# server.coffee
# Copyright 2019 Patrick Meade.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#----------------------------------------------------------------------

cookieParser = require "cookie-parser"
cookieSession = require "cookie-session"
crypto = require "crypto"
express = require "express"
fs = require "fs"
https = require "https"
mongoose = require "mongoose"
ms = require "ms"
{updateIfCurrentPlugin} = require "mongoose-update-if-current"
uuidv4 = require "uuid/v4"

{COOKIE_SECRET, MONGO_URI, PORT} = process.env

create = ->
    app = express()

    # configure the application
    app.locals.pretty = true  # https://stackoverflow.com/a/11812841
    app.set "views", "./views"
    app.set "view engine", "pug"

    # parse cookie headers into req.cookies and req.signedCookies
    app.use cookieParser()

    # parse session cookies into req.session
    app.use cookieSession
        name: "session"
        keys: [COOKIE_SECRET]
        maxAge: ms "1d"

    # set a session identifier if necessary
    app.use (req, res, next) ->
        if req.session?
            if not req.session.uuid?
                req.session.uuid = uuidv4()
        next()

    # parse supplied JSON into req.body
    app.use express.json()

    # parse supplied browser forms into req.body
    app.use express.urlencoded
        extended: true

    # GET /
    app.get "/", (req, res) ->
        res.render "geoForm",
            name: "World"
            session: req.session

    app.post "/wu-geotag", (req, res) ->
        # extract information from the POST request
        {latitude, longitude, type} = req.body
        session = req.session.uuid
        # save the information to our database
        db = app.get "db"
        GeoTag = db.model "GeoTag"
        result = await GeoTag.create
            remoteAddress: req.connection.remoteAddress
            session: session
            latitude: latitude
            longitude: longitude
            tagType: type
        # show the geotag to the caller
        res.render "showGeoTag",
            timestamp: new Date().toISOString()
            session: session
            latitude: latitude
            longitude: longitude
            tagType: type

    return app

# istanbul ignore next
run = ->
    # connect to MongoDB via Mongoose
    db = await mongoose.connect MONGO_URI,
        bufferCommands: false
        useCreateIndex: true
        useNewUrlParser: true

    # configure Mongoose to use optimistic concurrency control
    db.plugin updateIfCurrentPlugin

    # describe our document Schemas to Mongoose
    {Schema} = db
    geoTagSchema = new Schema
        _geoTagId: Schema.Types.ObjectId
        created:
            type: Date
            default: Date.now
        updated:
            type: Date
            default: Date.now
        remoteAddress:
            type: String
        session:
            type: String
        latitude:
            type: String
        longitude:
            type: String
        tagType:
            type: String

    # create Models to interact with MongoDB via Mongoose
    db.model "GeoTag", geoTagSchema

    # create and start the web service
    options =
        key: fs.readFileSync 'key.pem'
        cert: fs.readFileSync 'cert.pem'
    app = create()
    app.set "db", db
    https.createServer(options, app).listen PORT, ->
        console.log "Express server listening on port #{PORT}!"

exports.create = create
exports.run = run

#----------------------------------------------------------------------
# end of server.coffee

# Using moment for date formatting.
moment = require('moment')
# for computing the md5 for gravtar url.
crypto = require('crypto')
path = require('path')

srcPath = (args...) ->
	paths = [__dirname, 'src'].concat(args)
	return path.join.apply(null, paths)

# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {

	ignorePaths: [srcPath("files", "vendor", "twitter-bootstrap")]

	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		# Specify some site properties
		site:
			# The production url of our website
			url: "http://js-montreal.org"

			# Here are some old site urls that you would like to redirect from
			oldUrls: []

			# The default title of our website
			title: "js-montreal : JavaScript User Group in Montreal, Quebec"

			# The website description (for SEO)
			description: """
				Montreal (Canada) Javascript User Group
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				montreal,javascript,js,usergroup,user group
				"""

			# The website author's name
			author: "Bruno Carriere"

			# The website author's email
			email: "contact@js-montreal.org"

			# Styles
			styles: [
				"/styles/twitter-bootstrap.css"
				"/styles/js-mtl.css"
			]

			# Scripts
			scripts: [
				"//cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min.js",
				"//cdnjs.cloudflare.com/ajax/libs/modernizr/2.6.2/modernizr.min.js"
			]



		# -----------------------------
		# Helper Functions

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

		getMeetups: ->
			#sort reverse chronologically
			meetups = JSON.parse(@include('/data/meetups.json')).sort((a, b)-> b.num - a.num)
			return meetups

		gravaturl: (email) ->
			hash = crypto.createHash 'md5'
			hash.update email, 'utf8'
			"http://www.gravatar.com/avatar/#{hash.digest('hex')}"

		specialevent: (meetup) ->
			return !!meetup.specialevent

		booked: (meetup) ->
			return if meetup.speakers.length > 1 then meetup else 0


		past: (date) ->
      		return if (moment(date).unix() < new Date().getTime()) then true else false

		future: (date) ->
      		return !past(date)

		parseDate: (date) ->
			date = date.split(/(\d{4})(\d{2})(\d{2})/).join('-')
			new Date(date)

		formatDate: (date, fmtStr) ->
			return moment(date).format(fmtStr)

		startTime: (meetup) ->
			return if this.specialevent(meetup) then " @ 18:00" else " @ 18:45"

	# =================================
	# Collections
	# These are special collections that our website makes available to us

	collections:
		pages: (database) ->
			database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])

		posts: (database) ->
			database.findAllLive({tags:$has:'post'}, [date:-1])


	# =================================
	# Plugins

	plugins:
		downloader:
			downloads: [
				{
					name: 'Twitter Bootstrap'
					path: 'src/files/vendor/twitter-bootstrap'
					url: 'https://codeload.github.com/twbs/bootstrap/tar.gz/v3.0.3'
					tarExtractClean: true
				}
			]


	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()
}


# Export our DocPad Configuration
module.exports = docpadConfig
#touching for testing.
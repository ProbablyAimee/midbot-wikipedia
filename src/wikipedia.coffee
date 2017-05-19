# Description:
#   Wikipedia Public API
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot wiki <query> - Returns the first 5 Wikipedia articles matching the search <query>
#   hubot tell me about <article> - Returns a one-line description about <article>

WIKI_API_URL = "https://en.wikipedia.org/w/api.php"
WIKI_EN_URL = "https://en.wikipedia.org/wiki"

module.exports = (robot) ->
    robot.respond /wiki (.+)/i, id: "wikipedia.search", (res) ->
        search = res.match[1].trim()
        params =
            action: "opensearch"
            format: "json"
            limit: 5
            search: search

        wikiRequest res, params, (object) ->
            if object[1].length is 0
                res.reply "Sorry Boss, no articles were found using search query: \"#{search}\". Try a different query."
                return

            for article in object[1]
                res.send "#{article}: #{createURL(article)}"

    robot.respond /tell me about (.+)/i, id: "wikipedia.summary", (res) ->
        target = res.match[1].trim()
        params =
            action: "query"
            exintro: true
            explaintext: true
            format: "json"
            redirects: true
            prop: "extracts"
            titles: target

        wikiRequest res, params, (object) ->
            for id, article of object.query.pages
                if id is "-1"
                    res.reply "Sorry Boss, looks like (\"#{target}\") doesn't exist. Try a different article."
                    return

                if article.extract is ""
                    summary = "Sorry Boss, no summary available"
                else
                    summary = article.extract.split(". ")[0..1].join ". "

                res.send "#{article.title}: #{summary}."
                res.reply "Original article: #{createURL(article.title)}"
                return

createURL = (title) ->
    "#{WIKI_EN_URL}/#{encodeURIComponent(title)}"

wikiRequest = (res, params = {}, handler) ->
    res.http(WIKI_API_URL)
        .query(params)
        .get() (err, httpRes, body) ->
            if err
                res.reply "An error occurred while attempting to process your request: #{err}"
                return robot.logger.error err

            handler JSON.parse(body)
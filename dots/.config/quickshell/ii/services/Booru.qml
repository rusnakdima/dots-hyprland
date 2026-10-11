pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import qs.services.booru
import Quickshell;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 * Thin dispatcher that delegates to provider strategies.
 */
Singleton {
    id: root

    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"

    // Provider instances
    property Provider yandereProvider: YandereProvider {}
    property Provider konachanProvider: KonachanProvider {}
    property Provider zerochanProvider: ZerochanProvider {}
    property Provider danbooruProvider: DanbooruProvider {}
    property Provider gelbooruProvider: GelbooruProvider {}
    property Provider waifuProvider: WaifuProvider {}
    property Provider alcyProvider: AlcyProvider {}

    // Provider registry
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": yandereProvider,
        "konachan": konachanProvider,
        "zerochan": zerochanProvider,
        "danbooru": danbooruProvider,
        "gelbooru": gelbooruProvider,
        "waifu.im": waifuProvider,
        "t.alcy.cc": alcyProvider,
    }

    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    property var currentProvider: Persistent.states.booru.provider

    function getWorkingImageSource(url) {
        if (url?.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }

    function getProvider(id) {
        return providers[id] || null
    }

    function setProvider(provider) {
        provider = provider.toLowerCase()
        if (providerList.indexOf(provider) !== -1) {
            Persistent.states.booru.provider = provider
            var providerObj = providers[provider]
            root.addSystemMessage(Translation.tr("Provider set to ") + providerObj.name
                + (provider == "zerochan" ? Translation.tr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `sidebar.booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else {
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = []
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        return provider.constructUrl(tags, nsfw, limit, page)
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        var provider = providers[currentProvider]
        var url = provider.constructUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let response
                    if (provider.usesManualParsing()) {
                        response = provider.manualParse(xhr.responseText)
                    } else {
                        response = JSON.parse(xhr.responseText)
                        response = provider.mapResponse(response, getWorkingImageSource)
                    }
                    newResponse.images = response
                    newResponse.message = response.length > 0 ? "" : root.failMessage

                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                    newResponse.message = root.failMessage
                } finally {
                    root.runningRequests--
                    root.responses = [...root.responses, newResponse]
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
                newResponse.message = root.failMessage
                root.runningRequests--
                root.responses = [...root.responses, newResponse]
            }
            root.responseFinished()
        }

        try {
            if (provider.requiresUserAgent) {
                xhr.setRequestHeader("User-Agent", provider.getUserAgent(defaultUserAgent, Config.options))
            }
            root.runningRequests++
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        }
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort()
        }

        var provider = providers[currentProvider]

        // Check for fixed tags first
        var fixedTags = provider.getFixedTags()
        if (fixedTags) {
            root.tagSuggestion(query, fixedTags)
            return fixedTags
        }

        var tagTemplate = provider.getTagSearchTemplate()
        if (!tagTemplate) {
            return
        }

        var url = tagTemplate.replace("{{query}}", encodeURIComponent(query))

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    var response = JSON.parse(xhr.responseText)
                    response = provider.mapTagResponse(response)
                    root.tagSuggestion(query, response)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            if (provider.requiresUserAgent) {
                xhr.setRequestHeader("User-Agent", provider.getUserAgent(defaultUserAgent, Config.options))
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        }
    }
}

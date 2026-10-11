pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for Zerochan API.
 * Note: Zerochan doesn't support NSFW filtering and requires username in User-Agent.
 */
Provider {
    id: root

    property string pid: "zerochan"
    property string pname: "Zerochan"
    property string purl: "https://www.zerochan.net"
    property string papi: "https://www.zerochan.net/?json"
    property string pdescription: Translation.tr("Clean stuff | Excellent quality, no NSFW")

    providerId: root.pid
    name: root.pname
    url: root.purl
    api: root.papi
    description: root.pdescription
    supportsNsfwFiltering: false
    requiresUserAgent: true

    function constructUrl(tags, nsfw, limit, page) {
        var baseUrl = root.papi
        var tagString = tags.join(" ")
        var params = [
            "c=" + tagString,  // zerochan uses 'c' for color search
            "l=" + limit,
            "s=fav",
            "t=1",
            "p=" + page
        ]
        return baseUrl + "&" + params.join("&")
    }

    function mapResponse(response, getWorkingImageSource) {
        response = response.items
        return response.map(item => {
            return {
                "id": item.id,
                "width": item.width,
                "height": item.height,
                "aspect_ratio": item.width / item.height,
                "tags": item.tags.join(" "),
                "rating": "safe",
                "is_nsfw": false,
                "md5": item.md5,
                "preview_url": item.thumbnail,
                "sample_url": item.thumbnail,
                "file_url": item.thumbnail,
                "file_ext": "avif",
                "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                "character": item.tag
            }
        })
    }

    // Zerochan doesn't have a tag search API

    function getUserAgent(defaultAgent, configOptions) {
        var username = configOptions?.sidebar?.booru?.zerochan?.username
        if (username) {
            return `Desktop sidebar booru viewer - username: ${username}`
        }
        return defaultAgent
    }
}

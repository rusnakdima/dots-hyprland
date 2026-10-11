pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for Alcy (t.alcy.cc) API.
 * Note: Returns image links directly (non-JSON), has fixed tag list, no NSFW.
 */
Provider {
    id: root

    property string pid: "t.alcy.cc"
    property string pname: "Alcy"
    property string purl: "https://t.alcy.cc"
    property string papi: "https://t.alcy.cc/"
    property string pdescription: Translation.tr("Large images | God tier quality, no NSFW.")

    property var pfixedTags: [
        {"name": "ycy", "count": "General"},
        {"name": "moez", "count": "Moe"},
        {"name": "ysz", "count": "Genshin Impact"},
        {"name": "fj", "count": "Landscape"},
        {"name": "bd", "count": "Girl on white background"},
        {"name": "xhl", "count": "Shiggy"},
    ]

    providerId: root.pid
    name: root.pname
    url: root.purl
    api: root.papi
    description: root.pdescription
    supportsNsfwFiltering: false
    requiresUserAgent: false

    function constructUrl(tags, nsfw, limit, page) {
        var tagString = tags.join(" ")
        return root.papi + tagString + "?json&quantity=" + limit
    }

    function mapResponse(response, getWorkingImageSource) {
        // This shouldn't be called since we use manual parsing
        return []
    }

    function usesManualParsing() {
        return true
    }

    function manualParse(responseText) {
        // Alcy returns image links, each on a new line
        const lines = responseText.trim().split('\n')
        return lines.map(line => {
            return {
                "id": Qt.md5(line),
                "width": 1000,  // Alcy doesn't provide dimensions
                "height": 1000,
                "aspect_ratio": 1,
                "tags": "[no tags]",
                "rating": "s",
                "is_nsfw": false,
                "md5": Qt.md5(line),
                "preview_url": line,
                "sample_url": line,
                "file_url": line,
                "file_ext": line.split('.').pop(),
                "source": "",
            }
        })
    }

    function getFixedTags() {
        return root.pfixedTags
    }
}

pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for waifu.im API.
 * Note: Only supports waifus and doesn't support traditional NSFW filtering.
 */
Provider {
    id: root

    property string pid: "waifu.im"
    property string pname: "waifu.im"
    property string purl: "https://waifu.im"
    property string papi: "https://api.waifu.im/images"
    property string pdescription: Translation.tr("Waifus only | Excellent quality, limited quantity")

    providerId: root.pid
    name: root.pname
    url: root.purl
    api: root.papi
    description: root.pdescription
    supportsNsfwFiltering: false
    requiresUserAgent: false

    function constructUrl(tags, nsfw, limit, page) {
        var baseUrl = root.papi
        var tagsArray = tags.join(" ").split(" ")
        var params = []
        tagsArray.forEach(tag => {
            params.push("IncludedTags=" + encodeURIComponent(tag.toLowerCase()))
        })
        params.push("PageSize=" + Math.min(limit, 30))  // Only admin can do > 30
        params.push("IsNsfw=" + (nsfw ? "All" : "False"))
        return baseUrl + "?" + params.join("&")
    }

    function mapResponse(response, getWorkingImageSource) {
        response = response.items
        return response.map(item => {
            return {
                "id": item.id,
                "width": item.width,
                "height": item.height,
                "aspect_ratio": item.width / item.height,
                "tags": item.tags.map(tag => tag.name).join(" "),
                "rating": item.isNsfw ? "e" : "s",
                "is_nsfw": item.isNsfw,
                "md5": item.md5,
                "preview_url": item.sample_url ?? item.url,
                "sample_url": item.url,
                "file_url": item.url,
                "file_ext": item.extension,
                "source": getWorkingImageSource(item.source) ?? item.url,
            }
        })
    }

    function getTagSearchTemplate() {
        return "https://api.waifu.im/tags?Name={{query}}"
    }

    function mapTagResponse(response) {
        return response.items.map(item => {
            return {"name": item.name}
        })
    }
}

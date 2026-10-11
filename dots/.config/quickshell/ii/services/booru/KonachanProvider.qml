pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for Konachan API.
 */
Provider {
    id: root

    property string pid: "konachan"
    property string pname: "Konachan"
    property string purl: "https://konachan.net"
    property string papi: "https://konachan.net/post.json"
    property string pdescription: Translation.tr("For desktop wallpapers | Good quality")

    providerId: root.pid
    name: root.pname
    url: root.purl
    api: root.papi
    description: root.pdescription
    supportsNsfwFiltering: true
    requiresUserAgent: true

    function constructUrl(tags, nsfw, limit, page) {
        var baseUrl = root.papi
        var tagString = tags.join(" ")
        if (!nsfw) {
            tagString += " rating:safe"
        }
        var params = [
            "tags=" + encodeURIComponent(tagString),
            "limit=" + limit,
            "page=" + page
        ]
        return baseUrl + "?" + params.join("&")
    }

    function mapResponse(response, getWorkingImageSource) {
        return response.map(item => {
            return {
                "id": item.id,
                "width": item.width,
                "height": item.height,
                "aspect_ratio": item.width / item.height,
                "tags": item.tags,
                "rating": item.rating,
                "is_nsfw": (item.rating != 's'),
                "md5": item.md5,
                "preview_url": item.preview_url,
                "sample_url": item.sample_url ?? item.file_url,
                "file_url": item.file_url,
                "file_ext": item.file_ext,
                "source": getWorkingImageSource(item.source) ?? item.file_url,
            }
        })
    }

    function getTagSearchTemplate() {
        return "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*"
    }

    function mapTagResponse(response) {
        return response.map(item => {
            return {
                "name": item.name,
                "count": item.count
            }
        })
    }

}

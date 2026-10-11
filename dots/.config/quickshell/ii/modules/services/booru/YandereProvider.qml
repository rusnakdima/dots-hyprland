pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for yande.re (Yandere) API.
 */
Provider {
    id: root

    property string pid: "yandere"
    property string pname: "yande.re"
    property string purl: "https://yande.re"
    property string papi: "https://yande.re/post.json"
    property string pdescription: Translation.tr("All-rounder | Good quality, decent quantity")

    providerId: root.pid
    name: root.pname
    url: root.purl
    api: root.papi
    description: root.pdescription
    supportsNsfwFiltering: true
    requiresUserAgent: false

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
        return "https://yande.re/tag.json?order=count&limit=10&name={{query}}*"
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

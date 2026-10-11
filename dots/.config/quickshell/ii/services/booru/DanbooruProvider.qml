pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for Danbooru API.
 */
Provider {
    id: root

    property string pid: "danbooru"
    property string pname: "Danbooru"
    property string purl: "https://danbooru.donmai.us"
    property string papi: "https://danbooru.donmai.us/posts.json"
    property string pdescription: Translation.tr("The popular one | Best quantity, but quality can vary wildly")

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
                "width": item.image_width,
                "height": item.image_height,
                "aspect_ratio": item.image_width / item.image_height,
                "tags": item.tag_string,
                "rating": item.rating,
                "is_nsfw": (item.rating != 's'),
                "md5": item.md5,
                "preview_url": item.preview_file_url,
                "sample_url": item.file_url ?? item.large_file_url,
                "file_url": item.large_file_url,
                "file_ext": item.file_ext,
                "source": getWorkingImageSource(item.source) ?? item.file_url,
            }
        })
    }

    function getTagSearchTemplate() {
        return "https://danbooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*"
    }

    function mapTagResponse(response) {
        return response.map(item => {
            return {
                "name": item.name,
                "count": item.post_count
            }
        })
    }

}

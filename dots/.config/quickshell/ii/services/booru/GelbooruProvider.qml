pragma ComponentBehavior: Bound

import qs.services.booru

/**
 * Provider for Gelbooru API.
 */
Provider {
    id: root

    property string pid: "gelbooru"
    property string pname: "Gelbooru"
    property string purl: "https://gelbooru.com"
    property string papi: "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1"
    property string pdescription: Translation.tr("The hentai one | Great quantity, a lot of NSFW, quality varies wildly")

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
            tagString += " rating:general"
        }
        var params = [
            "tags=" + encodeURIComponent(tagString),
            "limit=" + limit,
            "pid=" + page  // Gelbooru uses 'pid' for page
        ]
        return baseUrl + "&" + params.join("&")
    }

    function mapResponse(response, getWorkingImageSource) {
        response = response.post
        return response.map(item => {
            return {
                "id": item.id,
                "width": item.width,
                "height": item.height,
                "aspect_ratio": item.width / item.height,
                "tags": item.tags,
                "rating": item.rating.replace('general', 's').charAt(0),
                "is_nsfw": (item.rating != 's'),
                "md5": item.md5,
                "preview_url": item.preview_url,
                "sample_url": item.sample_url ?? item.file_url,
                "file_url": item.file_url,
                "file_ext": item.file_url.split('.').pop(),
                "source": getWorkingImageSource(item.source) ?? item.file_url,
            }
        })
    }

    function getTagSearchTemplate() {
        return "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%"
    }

    function mapTagResponse(response) {
        return response.tag.map(item => {
            return {
                "name": item.name,
                "count": item.count
            }
        })
    }
}

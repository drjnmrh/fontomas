#include "fontomas/fallback/graph.h"

#include <algorithm>
#include <cstring>

#include "fontomas/debug.h"
#include "fontomas/macros.h"


using namespace fontomas;
using namespace fontomas::fallback;


static constexpr uint16_t sTagsReserved = 16;
static constexpr uint16_t sFallbacksReserved = 16;


namespace {


    template <typename T>
    bool resize(T** pArr, std::size_t curSize, std::size_t newSize) noexcept {
        T* resized = new T[newSize];
        std::memcpy(resized, *pArr, curSize * sizeof(T));
        std::swap(resized, *pArr);
        delete[] resized;
        return true;
    }


}


Graph::~Graph() noexcept {
    for (auto& entry : _nodesTable)
        release(entry.second);
}


Graph::Result Graph::addNode(nodeid_t nodeId, tagid_t tagId) noexcept {
    fontomas__try {
        auto foundIt = _nodesTable.find(nodeId);
        if (foundIt != _nodesTable.end())
            return eExists;
    } fontomas__catchall {
        fontomas__hardbreak;
        return eFailed;
    }

    NodeInfo info;
    info.routes = new TagRoutes[sTagsReserved];
    std::memset(info.routes, 0, sTagsReserved * sizeof(TagRoutes));
    info.nbtags = 0;
    info.sztags = sTagsReserved;

    if (!attach_tag(info, tagId)) {
        release(info);
        return eFailed;
    }

    bool ok = false;
    fontomas__safe_call(ok = _nodesTable.insert(std::make_pair(nodeId, info)).second);
    if (!ok) {
        release(info);
        return eFailed;
    }

    if (_nodesTable.size() == 1)
        _maxNodeId = nodeId;
    else
        _maxNodeId = std::max(_maxNodeId, nodeId);

    return ok ? eOk : eFailed;
}


Graph::Result Graph::addRoute(nodeid_t nodeId, nodeid_t fallbackId, tagid_t tagId) noexcept {
    auto nodeIt = _nodesTable.end();

    fontomas__try {
        nodeIt = _nodesTable.find(nodeId);
        if (_nodesTable.end() == nodeIt)
            return eNotExists;
    } fontomas__catchall {
        fontomas__hardbreak;
        return eFailed;
    }

    NodeInfo& info = nodeIt->second;

    if (has_route(info, fallbackId, tagId))
        return eExists;

    if (is_looped(nodeId, info, fallbackId, tagId))
        return eNotAllowed;

    if (!attach_route(info, fallbackId, tagId))
        return eFailed;

    auto fallbackIt = _nodesTable.end();

    fontomas__try {
        fallbackIt = _nodesTable.find(fallbackId);
        if (_nodesTable.end() == fallbackIt) {
            info.routes[tagId].nbfallbacks -= 1;
            return eNotExists;
        }
    } fontomas__catchall {
        fontomas__hardbreak;
        info.routes[tagId].nbfallbacks -= 1;
        return eFailed;
    }

    if (!attach_tag(fallbackIt->second, tagId)) {
        info.routes[tagId].nbfallbacks -= 1;
        return eFailed;
    }

    return eOk;
}


uint16_t Graph::fallbacks(nodeid_t nodeId, tagid_t tagId,
                          nodeid_t* buffer, uint16_t szbuffer) const noexcept
{
    auto nodeIt = _nodesTable.end();

    fontomas__try {
        nodeIt = _nodesTable.find(nodeId);
    } fontomas__catchall {
        fontomas__hardbreak;
    }

    if (_nodesTable.end() == nodeIt)
        return 0;

    const NodeInfo& info = nodeIt->second;

    if (tagId >= info.sztags)
        return 0;

    const TagRoutes& route = info.routes[tagId];

    uint16_t nbcopied = std::min(route.nbfallbacks, szbuffer);
    std::memcpy(buffer, route.fallbacks, sizeof(nodeid_t) * nbcopied);

    return nbcopied;
}


bool Graph::is_looped(nodeid_t nodeId, const NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) const noexcept {
    if (fallbackId >= _maxNodeId) {
        fontomas__hardbreak;
        return false;
    }

    if (info.sztags <= tagId || !info.routes[tagId].fallbacks)
        return false; // tag is not attached

    const TagRoutes& nodeRoute = info.routes[tagId];

    std::unique_ptr<Color[]> colors = std::make_unique<Color[]>(_maxNodeId);
    std::memset(colors.get(), eWhite, _maxNodeId * sizeof(Color));

    std::unique_ptr<nodeid_t[]> buffer = std::make_unique<nodeid_t[]>(_maxNodeId);
    std::memcpy(buffer.get(), nodeRoute.fallbacks, nodeRoute.nbfallbacks);
    buffer[nodeRoute.nbfallbacks] = fallbackId;

    TagRoutes route;
    route.fallbacks = buffer.get();
    route.nbfallbacks = nodeRoute.nbfallbacks + 1;
    route.szfallbacks = _maxNodeId;

    return has_backedge(nodeId, tagId, colors.get(), route);
}


bool Graph::has_backedge(nodeid_t nodeId, tagid_t tagId,
                         Color* colors, const TagRoutes& route) const noexcept
{
    colors[nodeId] = eGray;

    for (uint16_t i = 0; i < route.nbfallbacks; ++i) {
        nodeid_t fallbackId = route.fallbacks[i];
        if (eGray == colors[fallbackId])
            return true;

        auto fallbackIt = _nodesTable.end();
        fontomas__try {
            fallbackIt = _nodesTable.find(fallbackId);
        } fontomas__catchall {
            fontomas__hardbreak;
        }
        if (fallbackIt == _nodesTable.end()) {
            // Graph is inconsistent!
            fontomas__hardbreak;
            return true; // return true to quickly stop the algorithm
        }
        const NodeInfo& fallbackInfo = fallbackIt->second;
        if (fallbackInfo.sztags <= tagId || !fallbackInfo.routes[tagId].fallbacks)
            continue; // tag is not attached

        if (eWhite == colors[fallbackId] && has_backedge(fallbackId, tagId, colors, fallbackInfo.routes[tagId]))
            return true;
    }

    colors[nodeId] = eBlack;
    return false;
}


/*static*/
void Graph::release(Graph::NodeInfo& info) noexcept {
    if (!info.routes)
        return;

    for (uint16_t i = 0; i < info.nbtags; ++i) {
        if (info.routes[i].fallbacks)
            delete[] info.routes[i].fallbacks;
    }

    delete[] info.routes;
}


/*static*/
bool Graph::has_route(const NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept {
    if (tagId >= info.sztags)
        return false; // tag is not attached

    const TagRoutes& tag = info.routes[tagId];

    if (!tag.fallbacks)
        return false; // tag is not attached

    for (uint16_t i = 0; i < tag.nbfallbacks; ++i) {
        if (tag.fallbacks[i] == fallbackId)
            return true;
    }

    return false;
}


/*static*/
bool Graph::attach_route(NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept {
    bool needDetachOnError = false;

    if (tagId >= info.sztags || !info.routes[tagId].fallbacks) {
        if (!attach_tag(info, tagId))
            return false;
        needDetachOnError = true;
    }

    TagRoutes& route = info.routes[tagId];
    if (route.szfallbacks <= route.nbfallbacks) {
        if (!resize(&route.fallbacks, route.szfallbacks, fallbackId + sFallbacksReserved)) {
            if (needDetachOnError)
                detach_tag(info, tagId);
            return false;
        }
    }

    route.fallbacks[route.nbfallbacks++] = fallbackId;

    return true;
}


/*static*/
bool Graph::attach_tag(NodeInfo& info, tagid_t tagId) noexcept {
    if (tagId < info.sztags && !!info.routes[tagId].fallbacks)
        // tag is already attached
        return true;

    if (tagId >= info.sztags) {
        resize(&info.routes, info.sztags, tagId + sTagsReserved);
    }

    info.routes[tagId].fallbacks = new nodeid_t[sFallbacksReserved];
    info.routes[tagId].nbfallbacks = 0;
    info.routes[tagId].szfallbacks = sFallbacksReserved;

    ++info.nbtags;

    return true;
}


/*static*/
void Graph::detach_tag(NodeInfo& info, tagid_t tagId) noexcept {
    if (tagId >= info.sztags || !info.routes[tagId].fallbacks)
        return; // already detached

    delete[] info.routes[tagId].fallbacks;
    info.routes[tagId].fallbacks = nullptr;
}


// fallback/graph.cpp

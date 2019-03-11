#include "fontomas/fallback/graph.h"

#include <algorithm>
#include <cstring>
#include <memory>

#include "fontomas/debug.h"
#include "fontomas/macros.h"


using namespace fontomas;
using namespace fontomas::fallback;


static constexpr nodeid_t sNodesReserved = 16;
static constexpr uint16_t sTagsReserved = 16;
static constexpr uint16_t sFallbacksReserved = 16;


namespace {


    template <typename T, typename SzT>
    inline SzT resize(T** pArr, SzT curSize, SzT newSize) noexcept {
        T* resized = new T[newSize];

        std::memcpy(resized, *pArr, sizeof(T) * curSize);
        std::memset(resized, 0, sizeof(T) * (newSize - curSize));

        std::swap(resized, *pArr);
        delete[] resized;

        return newSize;
    }


}


// GRAPH PUBLICS


Graph::Graph() noexcept
    : _nodes(nullptr)
    , _szNodes(0), _maxNodeId(std::numeric_limits<nodeid_t>::min())
{}


Graph::~Graph() noexcept {
    if (!_nodes)
        return;

    for (nodeid_t i = 0; i < _maxNodeId; ++i)
        release(_nodes[i]);
    delete[] _nodes;
}


Graph::Result Graph::addNode(nodeid_t nodeId, tagid_t tagId) noexcept {
    if (nodeId < _szNodes && nodeId <= _maxNodeId && exists(_nodes[nodeId]))
        return eExists;

    allocNodes(nodeId);

    NodeInfo& info = _nodes[nodeId];
    info.routes = new TagRoutes[sTagsReserved];
    std::memset(info.routes, 0, sTagsReserved * sizeof(TagRoutes));
    info.nbtags = 0;
    info.sztags = sTagsReserved;

    attach(info, tagId);

    _maxNodeId = std::max(_maxNodeId, nodeId);

    return eOk;
}


Graph::Result Graph::addRoute(nodeid_t nodeId, nodeid_t fallbackId, tagid_t tagId) noexcept {
    if (nodeId > _maxNodeId || !exists(_nodes[nodeId]))
        return eNotExists;

    if (fallbackId > _maxNodeId || !exists(_nodes[fallbackId]))
        return eNotExists;

    NodeInfo& info = _nodes[nodeId];
    NodeInfo& fallback = _nodes[fallbackId];

    if (has_route(info, fallbackId, tagId))
        return eExists;

    if (is_looped(nodeId, info, fallbackId, tagId))
        return eNotAllowed;

    attach(info, tagId);
    attach(fallback, tagId);

    connect(info, fallbackId, tagId);

    return eOk;
}


uint16_t Graph::fallbacks(nodeid_t nodeId, tagid_t tagId,
                          nodeid_t* buffer, uint16_t szbuffer) const noexcept
{
    if (nodeId > _maxNodeId || !exists(_nodes[nodeId]))
        return 0;

    const NodeInfo& info = _nodes[nodeId];

    if (detached(info, tagId))
        return 0;

    const TagRoutes& route = info.routes[tagId];

    uint16_t nbcopied = std::min(route.nbfallbacks, szbuffer);
    std::memcpy(buffer, route.fallbacks, sizeof(nodeid_t) * nbcopied);

    return nbcopied;
}


// GRAPH PRIVATES


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

        if (fallbackId > _szNodes || !exists(_nodes[fallbackId])) {
            // Graph is inconsistent!
            fontomas__hardbreak;
            return true; // return true to quickly stop the algorithm
        }
        const NodeInfo& fallbackInfo = _nodes[fallbackId];
        if (detached(fallbackInfo, tagId))
            continue; // tag is not attached

        if (eWhite == colors[fallbackId] && has_backedge(fallbackId, tagId, colors, fallbackInfo.routes[tagId]))
            return true;
    }

    colors[nodeId] = eBlack;
    return false;
}


/*static*/
bool Graph::has_route(const NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept {
    if (detached(info, tagId))
        return false; // tag is not attached

    const TagRoutes& tag = info.routes[tagId];

    for (uint16_t i = 0; i < tag.nbfallbacks; ++i) {
        if (tag.fallbacks[i] == fallbackId)
            return true;
    }

    return false;
}


// GRAPH INLINES


/*inline*/
void Graph::allocNodes(nodeid_t maxNodeId) noexcept {
    if (!_nodes || maxNodeId >= _szNodes) {
        _szNodes = resize<NodeInfo, nodeid_t>(&_nodes, _szNodes, maxNodeId + sNodesReserved);
    }
}


/*static inline*/
bool Graph::exists(const NodeInfo& info) noexcept {
    return info.routes != nullptr && info.nbtags > 0;
}


/*static inline*/
bool Graph::attached(const NodeInfo &info, tagid_t tagId) noexcept {
    return tagId < info.sztags && !!info.routes[tagId].fallbacks;
}


/*static inline*/
bool Graph::detached(const NodeInfo &info, tagid_t tagId) noexcept {
    return tagId >= info.sztags || !info.routes[tagId].fallbacks;
}


/*static inline*/
void Graph::attach(NodeInfo& info, tagid_t tagId) noexcept {
    if (attached(info, tagId))
        return;

    if (tagId >= info.sztags) {
        info.sztags = resize<TagRoutes, uint16_t>(&info.routes, info.sztags, tagId + sTagsReserved);
    }

    info.routes[tagId].fallbacks = new nodeid_t[sFallbacksReserved];
    info.routes[tagId].nbfallbacks = 0;
    info.routes[tagId].szfallbacks = sFallbacksReserved;

    ++info.nbtags;

    return;
}


/*static inline*/
void Graph::detach(NodeInfo& info, tagid_t tagId) noexcept {
    if (detached(info, tagId))
        return;

    delete[] info.routes[tagId].fallbacks;
    info.routes[tagId].fallbacks = nullptr;
}


/*static inline*/
void Graph::connect(NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept {
    TagRoutes& route = info.routes[tagId];
    if (route.szfallbacks <= route.nbfallbacks) {
        route.szfallbacks = resize<nodeid_t, uint16_t>(&route.fallbacks, route.szfallbacks, fallbackId + sFallbacksReserved);
    }

    route.fallbacks[route.nbfallbacks++] = fallbackId;
}


/*static inline*/
void Graph::release(Graph::NodeInfo& info) noexcept {
    if (!info.routes)
        return;

    for (uint16_t i = 0; i < info.sztags; ++i) {
        if (info.routes[i].fallbacks)
            delete[] info.routes[i].fallbacks;
    }

    delete[] info.routes;
}



// fallback/graph.cpp

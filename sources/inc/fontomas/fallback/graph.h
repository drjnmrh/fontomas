#pragma once
#ifndef FONTOMAS_FALLBACK_GRAPH_H_
#define FONTOMAS_FALLBACK_GRAPH_H_


#include <cinttypes>
#include <limits>
#include <list>
#include <unordered_map>
#include <vector>

#include <fontomas/exports.h>
#include <fontomas/types.h>


namespace fontomas { ;
namespace fallback { ;



class fontomas_public Graph final {
public:
    enum Result { eOk = 0, eExists, eNotExists, eNotAllowed, eFailed };

    ~Graph() noexcept;

    bool empty() const noexcept;

    Result addNode(nodeid_t nodeId, tagid_t tagId) noexcept;
    Result addRoute(nodeid_t nodeId, nodeid_t fallbackId, tagid_t tagId) noexcept;

    uint16_t fallbacks(nodeid_t nodeId, tagid_t tagId,
                       nodeid_t* buffer, uint16_t szbuffer) const noexcept;

private:
    friend class Tester;

    struct TagRoutes {
        nodeid_t* fallbacks; // if fallbacks is null, the tag is not attached
        uint16_t nbfallbacks, szfallbacks;
    };

    struct NodeInfo {
        TagRoutes* routes; // tag id is an index in this array
        uint16_t nbtags, sztags;
    };

    enum Color { eWhite = 0, eGray, eBlack };
    bool is_looped(nodeid_t nodeId, const NodeInfo& info,
                   nodeid_t fallbackId, tagid_t tagId) const noexcept;
    bool has_backedge(nodeid_t nodeId, tagid_t tagId,
                      Color* colors, const TagRoutes& route) const noexcept;

    static void release(NodeInfo& info) noexcept;
    static bool has_route(const NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept;
    static bool attach_route(NodeInfo& info, nodeid_t fallbackId, tagid_t tagId) noexcept;
    static bool attach_tag(NodeInfo& info, tagid_t tagId) noexcept;
    static void detach_tag(NodeInfo& info, tagid_t tagId) noexcept;

    std::unordered_map<nodeid_t, NodeInfo> _nodesTable;
    nodeid_t _maxNodeId;
};



}
}


#endif//FONTOMAS_FALLBACK_FONTSGRAPH_H_

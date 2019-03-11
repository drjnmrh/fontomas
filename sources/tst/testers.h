#pragma once
#ifndef FONTOMAS_TESTING_TESTERS_H_
#define FONTOMAS_TESTING_TESTERS_H_


#include <cstring>
#include <vector>

#include <fontomas/debug.h>
#include <fontomas/macros.h>

#include <fontomas/fallback/consts.h>
#include <fontomas/fallback/graph.h>


namespace fontomas { ;
namespace fallback { ;


class Tester final {
public:
    static nodeid_t maxNodeId(const Graph& g) noexcept {
        return g._maxNodeId;
    }
    
    static nodeid_t szNodes(const Graph& g) noexcept {
        return g._szNodes;
    }
    
    static nodeid_t nbNodes(const Graph& g) noexcept {
        if (!g._nodes)
            return 0;
        nodeid_t counter = 0;
        for (nodeid_t i = 0; i < g._szNodes; ++i) {
            if (g._nodes[i].routes)
                counter += 1;
        }
        return counter;
    }

    static bool initWithNodes(Graph& g, std::initializer_list<std::pair<nodeid_t, tagid_t>> nodes) noexcept {
        if (g._szNodes > 0) {
            g.~Graph();
            g._szNodes = g._maxNodeId = 0;
            g._nodes = nullptr;
        }

        for (const auto& p : nodes) {
            if (Graph::eOk != g.addNode(p.first, p.second))
                return false;
        }

        return true;
    }

    static bool hasRoute(const Graph& g, nodeid_t nodeId, nodeid_t fallbackId, tagid_t tagId) noexcept {
        if (nodeId > g._maxNodeId || !g._nodes[nodeId].routes)
            return false;
        
        return Graph::has_route(g._nodes[nodeId], fallbackId, tagId);
    }
};



}
}


#endif//FONTOMAS_TESTING_TESTERS_H_

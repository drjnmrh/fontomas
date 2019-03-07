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

    static const std::unordered_map<nodeid_t, Graph::NodeInfo>& nodesTable(const Graph& g) noexcept {
        return g._nodesTable;
    }

    static bool initWithNodes(Graph& g, std::initializer_list<std::pair<nodeid_t, tagid_t>> nodes) noexcept {
        if (g._nodesTable.size() > 0) {
            g.~Graph();
            g._nodesTable.clear();
        }

        for (const auto& p : nodes) {
            if (Graph::eOk != g.addNode(p.first, p.second))
                return false;
        }

        return true;
    }

    static bool hasRoute(const Graph& g, nodeid_t nodeId, nodeid_t fallbackId, tagid_t tagId) noexcept {
        auto nodeIt = g._nodesTable.end();
        fontomas__safe_call(nodeIt = g._nodesTable.find(nodeId));
        if (g._nodesTable.end() == nodeIt)
            return false;
        return Graph::has_route(nodeIt->second, fallbackId, tagId);
    }
};



}
}


#endif//FONTOMAS_TESTING_TESTERS_H_

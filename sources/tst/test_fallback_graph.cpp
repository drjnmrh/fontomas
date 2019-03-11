#include "fontomas/fallback/consts.h"
#include "fontomas/fallback/graph.h"

#include <list>
#include <limits>
#include <memory>

#include "testers.h"
#include "testsglobals.h"


bool test__fallback__graph_addnode();
bool test__fallback__graph_addroute();
bool test__fallback__graph_fallbacks();

fontomas__tests_suit_begin(FallbackGraph)
    fontomas__test(test__fallback__graph_addnode),
    fontomas__test(test__fallback__graph_addroute),
    fontomas__test(test__fallback__graph_fallbacks),
fontomas__tests_suit_end(FallbackGraph);


#define NC fontomas::fallback::sNotConnected

static fontomas::tagid_t sEtalonMatrix[7][7] = {
    { NC, 0 , 3 , 1 , NC, NC, NC },
    { NC, NC, NC, NC, NC, NC, NC },
    { NC, NC, NC, 1 , NC, 1 , NC },
    { NC, NC, NC, NC, 1 , 1 , NC },
    { NC, NC, NC, NC, NC, NC, NC },
    { NC, NC, NC, NC, 2 , NC, NC },
    { NC, NC, NC, NC, NC, NC, 10 }
};


#define graph_maxNodeId(GraphVar) \
    fontomas::fallback::Tester::maxNodeId((GraphVar))

#define graph_nodesTable(GraphVar) \
    fontomas::fallback::Tester::nodesTable((GraphVar))

#define graph_init(GraphVar, ...) \
    fontomas::fallback::Tester::initWithNodes((GraphVar), { __VA_ARGS__ })

#define graph_node(NodeId, TagId) \
    std::pair<nodeid_t, tagid_t>(NodeId, TagId)

#define graph_hasroute(GraphVar, NodeId, FallbackId, TagId) \
    fontomas::fallback::Tester::hasRoute((GraphVar), (NodeId), (FallbackId), (TagId))


bool test__fallback__graph_addnode() {
    using namespace fontomas;
    using namespace fontomas::fallback;

    Graph graph;

    Graph::Result res = graph.addNode(11, 0);
    fontomas__check_equal(res, Graph::eOk);
    fontomas__check_equal(graph_maxNodeId(graph), 11);
    fontomas__check_equal(graph_nodesTable(graph).size(), 1);

    for (nodeid_t id = 0; id < 10; ++id) {
        res = graph.addNode(id, id % 3);
        fontomas__check_equal(res, Graph::eOk);
        fontomas__check_equal(graph_maxNodeId(graph), 11);
        fontomas__check_equal(graph_nodesTable(graph).size(), id + 2);
    }

    for (nodeid_t id = 12; id < 20; ++id) {
        res = graph.addNode(id, id % 6);
        fontomas__check_equal(res, Graph::eOk);
        fontomas__check_equal(graph_maxNodeId(graph), id);
        fontomas__check_equal(graph_nodesTable(graph).size(), id);
    }

    res = graph.addNode(0, 4);
    fontomas__check_equal(res, Graph::eExists);
    fontomas__check_equal(graph_maxNodeId(graph), 19);
    fontomas__check_equal(graph_nodesTable(graph).size(), 19);

    res = graph.addNode(20, 10);
    fontomas__check_equal(res, Graph::eOk);
    fontomas__check_equal(graph_maxNodeId(graph), 20);
    fontomas__check_equal(graph_nodesTable(graph).size(), 20);

    return true;
}


bool test__fallback__graph_addroute() {
    using namespace fontomas;
    using namespace fontomas::fallback;

    //
    //                     (0, 0)
    //                       X
    //              (1, 0)<_0/\
    //                 X       \______3_______>(2, 1)
    //                          \                X
    //                           \__1_>(3, 1)<_1/|
    //                                   X       |
    //                   (6, 10)         |\      |
    //                      X            | \     |
    //                                   |  1    1
    //                                   1   \   |
    //                                   |    \  |
    //                                   |     \ |
    //                                   v       v
    //                                (4, 2)<--(5, 2)
    //                                   X        X
    //

    struct Route {
        nodeid_t from, to;
        tagid_t tag;
    };

    static const Route sRoutes[8] = {
        Route{0, 1, 0},
        Route{0, 2, 3},
        Route{0, 3, 1},
        Route{2, 3, 1},
        Route{2, 5, 1},
        Route{3, 5, 1},
        Route{3, 4, 1},
        Route{5, 4, 2}
    };

    std::size_t nbRoutes = sizeof(sRoutes) / sizeof(sRoutes[0]);
    std::vector<std::size_t> routesOrder(nbRoutes);
    for (std::size_t i = 0; i < nbRoutes; ++i)
        routesOrder[i] = i;

    static constexpr int sAttemptsNumber = 16;

    for (int attemptNo = 0; attemptNo < sAttemptsNumber; ++attemptNo) {
        Graph g;
        bool ok = graph_init(g, graph_node(0, 0), graph_node(1, 0),
                                graph_node(2, 1), graph_node(3, 1),
                                graph_node(4, 2), graph_node(5, 2),
                                graph_node(6, 10));
        fontomas__check_equal(ok, true);
        fontomas__check_equal(graph_maxNodeId(g), 6);
        fontomas__check_equal(graph_nodesTable(g).size(), 7);

        for (std::size_t i = 0; i < routesOrder.size(); ++i) {
            const Route& route = sRoutes[routesOrder[i]];
            Graph::Result res = g.addRoute(route.from, route.to, route.tag);
            fontomas__check_equal(res, Graph::eOk);
            fontomas__check_true(graph_hasroute(g, route.from, route.to, route.tag));
        }

        Graph::Result res = g.addRoute(4, 0, 1);
        fontomas__check_equal(res, Graph::eNotAllowed);

        res = g.addRoute(5, 4, 2);
        fontomas__check_equal(res, Graph::eExists);

        res = g.addRoute(4, 0, 3);
        fontomas__check_equal(res, Graph::eOk);
        fontomas__check_true(graph_hasroute(g, 4, 0, 3));

        testing::shuffle(routesOrder);
    }

    return true;
}


bool test__fallback__graph_fallbacks() {
    using namespace fontomas;
    using namespace fontomas::fallback;

    //
    //                     (0, 0)
    //                       X
    //              (1, 0)<_0/\
    //                 X       \______3_______>(2, 1)
    //                          \                X
    //                           \__1_>(3, 1)<_1/|
    //                                   X       |
    //                   (6, 10)         |\      |
    //                      X            | \     |
    //                                   |  1    1
    //                                   1   \   |
    //                                   |    \  |
    //                                   |     \ |
    //                                   v       v
    //                                (4, 2)<--(5, 2)
    //                                   X        X
    //

    struct Route {
        nodeid_t from, to;
        tagid_t tag;
    };

    static const Route sRoutes[8] = {
        Route{0, 1, 0},
        Route{0, 2, 3},
        Route{0, 3, 1},
        Route{2, 3, 1},
        Route{2, 5, 1},
        Route{3, 5, 1},
        Route{3, 4, 1},
        Route{5, 4, 2}
    };

    std::size_t nbRoutes = sizeof(sRoutes) / sizeof(sRoutes[0]);
    std::vector<std::size_t> routesOrder(nbRoutes);
    for (std::size_t i = 0; i < nbRoutes; ++i)
        routesOrder[i] = i;

    Graph g;
    bool ok = graph_init(g, graph_node(0, 0), graph_node(1, 0),
                            graph_node(2, 1), graph_node(3, 1),
                            graph_node(4, 2), graph_node(5, 2),
                            graph_node(6, 10));

    fontomas__check_equal(ok, true);
    fontomas__check_equal(graph_maxNodeId(g), 6);
    fontomas__check_equal(graph_nodesTable(g).size(), 7);

    for (std::size_t i = 0; i < routesOrder.size(); ++i) {
        const Route& route = sRoutes[routesOrder[i]];
        Graph::Result res = g.addRoute(route.from, route.to, route.tag);
        fontomas__check_equal(res, Graph::eOk);
        fontomas__check_true(graph_hasroute(g, route.from, route.to, route.tag));
    }

    std::unique_ptr<nodeid_t[]> buffer = std::make_unique<nodeid_t[]>(7);
    std::memset(buffer.get(), std::numeric_limits<nodeid_t>::max(), 7 * sizeof(nodeid_t));

    for (nodeid_t n = 0; n < 7; ++n) {
        for (tagid_t t = 0; t < 10; ++t) {
            uint16_t res = g.fallbacks(n, t, buffer.get(), 7);

            std::list<nodeid_t> ref = testing::collect_all(sEtalonMatrix[n], (nodeid_t)7, t,
                [n](nodeid_t v) -> bool { return n != v; }
            );
            fontomas__check_equal(res, ref.size());

            bool areEqual = testing::equal_unordered(buffer.get(), ref);
            fontomas__check_true(areEqual);
        }
    }

    // not attached tag
    uint16_t res = g.fallbacks(0, 10, buffer.get(), 7);
    fontomas__check_equal(res, 0);

    // too small buffer
    res = g.fallbacks(3, 1, buffer.get(), 1);
    fontomas__check_equal(res, 1);
    fontomas__check_equal(buffer[0], 5);

    // zero sized buffer
    res = g.fallbacks(3, 1, buffer.get(), 0);
    fontomas__check_equal(res, 0);

    return true;
}


// tst/test_fallback_graph.cpp

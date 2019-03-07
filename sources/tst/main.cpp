#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <vector>

#include <fontomas/version.h>

#include "testsglobals.h"


using namespace fontomas::testing;


int main(int argc, char** argv) {
    std::srand(unsigned(std::time(0)));

    std::list<Test> allTests;
    fontomas__enable_suit(DI, allTests);
    fontomas__enable_suit(FallbackGraph, allTests);

    LOG << "----------------------------------------\n";
    LOG << "fontomas v" << fontomas::VersionInfo::toString() << " tester\n";
    LOG << "----------------------------------------\n";

    std::vector<Test> tests;
    tests.reserve(allTests.size());
    std::copy(allTests.begin(), allTests.end(), std::back_inserter(tests));

    if (argc > 1) {
        for (int i = 0; i < tests.size(); ++i) {
            const char* fltr = argv[1];
            if (std::string(tests[i].name) == std::string(fltr))
                return tests[i].func() ? 0 : 1;
        }
    }

    std::size_t nb_tests = tests.size();
    LOG << "running " << nb_tests << " tests: ";
    std::vector<std::size_t> failed;
    failed.reserve(nb_tests);
    Sandbox sb;
    for (std::size_t i = 0; i < nb_tests; ++i) {
        bool result = false;

        fontomas__try {
            result = sb.execute(tests[i].func);
        } fontomas__catch(std::exception, e) {
            LOG << "\n unhandled exception " << e.what()
                << " in " << tests[i].name << "\n";
        } fontomas__catchall {
            LOG << "\n unknown exception in " << tests[i].name << "\n";
        }

        if (result) {
            LOG << ".";
        } else {
            fontomas__safe_call(failed.push_back(i));
            LOG << "e";
        }
    }

    if (failed.size() > 0) {
        LOG << "\n----------------------------------------\n";
        LOG << "failed " << failed.size() << " tests:\n";
        for (std::size_t i = 0; i < failed.size(); ++i)
            LOG << "\t" << tests[failed[i]].name << "\n";
        LOG << "FAILURE" << "\n";
        return 1;
    } else {
        LOG << "\n----------------------------------------\n";
        LOG << "SUCCESS" << "\n";
        return 0;
    }

    return 0;
}

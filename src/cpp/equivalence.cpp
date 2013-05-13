/*
 * Copyright (c) 2012, TU Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of the TU Berlin nor the
 *     names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL TU Berlin BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **/

#include "equivalence.hpp"

#include <map>
#include <boost/pending/disjoint_sets.hpp>
#include <boost/property_map/property_map.hpp>

using namespace std;
using namespace boost;

typedef associative_property_map<map<string, int> > rank_pm;
typedef associative_property_map< map<string, string> > parent_pm ;


class EquivalenceCtxt {

private:
  map<string, int> rank_map;
  map<string, string> p_map;

  map<string, double> values;

  disjoint_sets<rank_pm, parent_pm> dsets;

public:
  bool setup;

  EquivalenceCtxt() : setup(false), dsets(rank_pm(rank_map), parent_pm(p_map)) {}

  void equivate(const string& left_reference, const string& right_reference) {
    dsets.link(left_reference, right_reference);
  }
  
  double get(const string& reference) {
    return values.at(dsets.find_set(reference));
  }
  
  void set(const string& reference, double value) {
    values[dsets.find_set(reference)] = value;
  }  
  
};

extern "C" {

  void* allocNewEquivalenceCtxt() {
    return (void*) new EquivalenceCtxt();
  }

  void freeEquivalenceCtxt(void* ctxt) {
    delete (EquivalenceCtxt*) ctxt;
  }

  void equivate(void* ctxt, const char* left_reference, const char* right_reference) {
    EquivalenceCtxt* eq = (EquivalenceCtxt*) ctxt;
    eq->equivate(left_reference, right_reference);
  }

  void setParameter(void* ctxt, const char* reference, const double val) {
    EquivalenceCtxt* eq = (EquivalenceCtxt*) ctxt;
    eq->set(reference, val);
  }

  double getParameter(void* ctxt, const char* reference) {
    EquivalenceCtxt* eq = (EquivalenceCtxt*) ctxt;
    return eq->get(reference);  
  }

  int markSetupDone(void* ctxt) {
    EquivalenceCtxt* eq = (EquivalenceCtxt*) ctxt;
    if (eq->setup) 
      return false;

    eq->setup = true;
    return true;
  }

  int isSetupDone(void* ctxt) {
    EquivalenceCtxt* eq = (EquivalenceCtxt*) ctxt;
    return eq->setup;
  }
}

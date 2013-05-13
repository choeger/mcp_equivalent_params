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

within de.tuberlin.uebb;
package equivalence 


  class EquivalenceCtxt
    extends ExternalObject;

    function constructor
      output EquivalenceCtxt ctxt;
      external "C" ctxt = allocNewEquivalenceCtxt()  annotation(Library="equivalence");
    end constructor;

    function destructor
      input EquivalenceCtxt ctxt;
      external "C" freeEquivalenceCtxt(ctxt)  annotation(Library="equivalence");
    end destructor;
  end EquivalenceCtxt;


  function equivate
    input EquivalenceCtxt ctxt1;
    input String key1;
    input String key2;
    external "C" equivate(ctxt1, key1, key2)  annotation(Library="equivalence");
  end equivate;


  function setParameter
    input EquivalenceCtxt ctxt;
    input String key;
    input Real val;
    external "C" setParameter(ctxt, key, val)  annotation(Library="equivalence");
  end setParameter;


  function getParameter
    input EquivalenceCtxt ctxt;
    input String key;
    output Real val;
    external "C" val=  getParameter(ctxt, key) annotation(Library="equivalence");
  end getParameter;

  function isSetupDone
    input EquivalenceCtxt ctxt;
    output Boolean r;
    external "C" r = isSetupDone(ctxt) annotation(Library="equivalence");
  end isSetupDone;

  function markSetupDone
    input EquivalenceCtxt ctxt;
    output Boolean r;
    external "C" r = markSetupDone(ctxt) annotation(Library="equivalence");
  end markSetupDone;

end equivalence;

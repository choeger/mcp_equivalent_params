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
 * */
within de.tuberlin.uebb.equivalence;
package examples 


  model CircuitWithFloatingResistance

    import de.tuberlin.uebb.equivalence.{EquivalenceCtxt, getParameter, setParameter, equivate};
    import Modelica.Electrical.Analog.Basic.{Capacitor, Ground};
    import Modelica.Electrical.Analog.Sources.{SineVoltage};

    model Wire
      extends Modelica.Electrical.Analog.Interfaces.OnePort;

      outer EquivalenceCtxt ctxt;
      outer Boolean wiringDone;

      discrete Real R(start = 1.0);

    equation
      when wiringDone then
        R = getParameter(ctxt, getInstanceName() + ".R");
      end when;

      v = R*i;
    end Wire;

    function wireUp
      input EquivalenceCtxt ctxt;
      input String name;
      output Real r;
    algorithm

      if (not isSetupDone(ctxt)) then
        equivate(ctxt, name + "w1.R", name + "w2.R");
        setParameter(ctxt, name + "w2.R", 0.1);
        markSetupDone(ctxt);
      end if;

      r := getParameter(ctxt, name + "w1.R");
    end wireUp;

    inner EquivalenceCtxt ctxt =  EquivalenceCtxt();
    inner Boolean wiringDone(start = false);

    SineVoltage src;
    Wire w1, w2;
    Capacitor c;
    Ground g;

  algorithm
    when initial() then
      wireUp(ctxt, getInstanceName());
      wiringDone := true;
    end when;

  equation
    connect(src.n, w1.p);
    connect(src.n, g.p);
    connect(w1.n, c.p);
    connect(c.n, w2.p);
    connect(w2.n, src.p);

  end CircuitWithFloatingResistance;

end examples;

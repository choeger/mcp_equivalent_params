# Equivalent Parameters

**MCP**: Work-in-progress

**Author**: Christoph Höger <christoph.hoeger@tu-berlin.de>

## Abstract

This MCP proposes the addition of _equivalent parameters_ to Modelica. 
Equivalent parameters are a convenient way to define e.g. properties shared 
between models because of some physical connection. They free the modeler
from copying properties manually along the connection path and allow to
define the actual _value_ of the parameters at any point of the connected set
of components.

## Copyright

Copyright (c) 2012, TU Berlin
All rights reserved.
 
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions 
are met:
 
   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
   * Neither the name of the TU Berlin nor the
     names of its contributors may be used to endorse or promote products
     derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TU Berlin BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
## Rationale

Modelica currently gives the user two distinct modeling facilities:

 * Graphical composition of model instances using the **```connect```**-equation
 * Free Parameterization of models just before simulation

Those two features are not integrated. It is currently tedious to 
"pass around" a set of model parameters along the lines of the connection graph. 
Although in models like closed fluid system this "passing-around" is a quite
natural system behaviour.

More formally, a modeler sometimes wants to _abstract_ some parameters from the 
components. Yet, when composed, all composed components shall share _the same_
parameters. Additionally, the user shall not be forced to provide the same 
parameters for every instanceof the connected graph, as this is obvioulsy tedious 
and error prone. Instead, the library author should be able to express the 
constraints while the user should only provide a unique set of parameters.

To achieve this, we propose a two-step solution:

 * First, we describe a mechanism on how to express equivalence constraints on
   parameters.
 * Second, we enrich the current connection semantics in a natural way to derive
   those constraints automatically where possible.

### Equivalence Relation

The equivalence of two parameters (or parameter-records) shall be expressed by an 
_equivalence-equation_:

```Modelica
model M
  parameter Real a, b;
...

equation
  equivalent(a, b);
...
end M;
```

By providing an equivalence-equation, the modeler indicates two things:

 * If one of these parameters is set to a value (e.g. by modification), all equivalent 
   parameters share the _same_ value
 * It is an error, if both equivalent parameters are either set to non-equal values, or 
   set to a value which can not be compared for equality (i.e. functions) 

After instantiation, the equivalence-relation **~** over all parameters shall be build as
the reflexive, transitive, symmetric closure over all equivalence-equations. With this
relation, we can formalize the semantics of the equivalence-equations:

 * If a ~ b, then a and b are guaranteed to have the same value during simulation

### Equivalence from Connections

The main motivation for this proposal is to simplify the propagation of parameters through
networks of connected components. Consider the following sketch:

```Modelica
model Element
  parameter Properties properties;
  SomeConnector left, right;
end Element;

model Network
  parameter Properties properties;
  Element elem1(properties=properties), elem2(properties=properties);
  
  equation
  if someCondition then
    connect(elem1.right, elem2.left); 
  end if;

end Network;

```

Here, the equality of some (e.g. media-) properties is enforced (or better: advised) by a 
connection and expressed manually at the instantiation site. This imposes two problems:

  * If the connection was defined in a sub- or superclass it might be non-trivial to
    figure out where to pass which properties.
  * If the connection was actually not present, it might be plain wrong to pass the 
    properties.

Via equivalence-equations, the above model can be simplified:

```Modelica
model Network
  Element elem1, elem2;
  
  equation
  if someCondition then
    connect(elem1.right, elem2.left); 
    equivalent(elem1.properties, elem2.properties);
  end if;

end Network;

```

Yet, the model author still has to explicitly maintain the set of equivalence-equations
in the global model. Therefore, we propose another rule for convenience:

 * If a connector contains a parameter, every **```connect```**-equation on that connector
   also leads to a **```equivalent```**-equation on the parameter.
   
i.e., if we enhance the _connector_ from above:

```Modelica
connector SomeConnector
  parameter Properties properties;
  ...
end SomeConnector;
``` 

We can use this inside the Element model:

```Modelica
model Element
  SomeConnector left, right;
  
  equation
  equivalent(left.properties, right.properties);
end Element;
``` 

And the network author does not need to formulate any explicit equivalences:

```
model Network
  Element elem1, elem2;
  
  equation
  if someCondition then
    connect(elem1.right, elem2.left); 
    /* implies:
       equivalent(elem1.left.properties, elem2.right.properties);
    */
  end if;

end Network;

```

### Distinction From Equations

One could argue, that the equivalence-equations could be expressed more generally by
allowing equations over parameters. Although this is certainly possible, it would 
introduce some fundamental complexities (e.g. algebraic loops). Therefore a restricted, 
yet powerful solution seems to be favourable.

Additionally, the equivalence approach allows for higher-order functions to be passed 
through the network: While systems of equations cannot be defined over functions, the
equivalence relation can be used to determine a single "defined" function out of a set
of "potentially defined" functions. The state of "defined" or "undefined" values simply
requires the addition of something like a "null" or "Option" value to Modelica (yet this
is not part fof this MCP).

### Order of Evaluation

It is important to note that equivalence classes impose a certain evaluation order into
a Modelica implementation: Since the value of parameters defined inside connectors is 
only defined, _after_ inspection of the connected sets of components, conditional 
connections need to be evaluated _before_ the parameters in the involved connectors are
read.

This avoids problems like the above:

```Modelica
model Network
  Element elem1, elem2(param = true);
  
  equation
  if elem1.param then
    connect(elem1.right, elem2.left); 
  end if;

end Network;

```

In such a case the evaluation of the conditional connect statement depends on a 
parameter declared inside a (potentially) involved connector. As the set of all
potentially involved connectors can be calculated easily (simply assuming every 
condition evaluates to true), we can simply rule out any infinite computation by 
forbidding the dependency of a conditional connection on a parameter declared inside
a potentially involved connector. Any other parameter can be used (if its own 
equivalence class can be computed).

### Prototype Mockup Implementation

To demonstrate the feasibility of implementation and study the modeling implications, 
we implemented a small C/C++ library that allows to emulate the behaviour in Modelica.

This demo library currently is only tested with OpenModelica (1.9beta4) but should be 
compatible to any standard (3.3) compliant Modelica implementation.

As the features proposed in this MCP are not (yet) part of Modelica, the mockup library 
is not a full prototype implementation. Instead it provides means to create and manage
equivalence classes manually. 

The following example demonstrates the usage of the library in a circuit where the wire has
the same resistance:

```Modelica
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
```

The library works as follows:

 * There needs to be exactly one equivalence context for the whole model
 * Equivalences are described along component names
 * The equivalence equations can be created anywhere in the model, but in current Modelica it
is hard to manage the execution order of external functions. Thus, one has to fiddle with signals.
 * Currently only real-valued parameters are supported 

## Proposed Changes in the Specification

The specification should be changed as follows:

### Section 4.4.5

Add a reference to the evaluation-order of parameters.

### Section 4.6 

Add the following sentence to the entry **connector**: 

> Any parameter components are subject to equivalence class handling as described in 
> chapter 8.

### Section 8.3

Add reference to ```equivalence_clause```  

### Section 8.3.4

Add reference to the evaluation-order of parameters.

### Section 8.3.10 Equivalence-Equations (new section)

Add the following section to the specification:

> An equivalence-equation has the following syntax:

> **```equivalent```** ```"(" component_reference "," component_reference ")" ";" ```

> The component references inside an equivalence-equation may only refer to _parameters_. 
> By defining an equivalence, the modeler demands that the equivalent parameters always 
> have the same value. I.e. all modifications, binding equations etc. have the _same_
> effect on equivalent parameters.

> The equivalence-relation **~** over all parameters is defined as the reflexive, 
> transitive, symmetric closure over all equivalence-equations. If a ~ b, then a and b
> are guaranteed to have the same value during simulation.

> If there are multiple bindings or modifications to the parameters of the same 
> equivalence class, it is an error if the value of those bindings cannot be compared
> for equality (i.e. in case of higher-order functions) or is not equal.

> Before a parameter can be used during model instantiation (i.e. it is a _structural_ 
> parameter), its equivalence class has to be evaluated. If this is not possible (e.g. 
> because of cyclic dependency in case of conditional equations), the model is errnous
> and instantiation shall be aborted.

### Section 9.5 Parameters in Connectors (new section)

Add the following section to the specification:

> If a connector contains parameters, every **```connect```**-equation involving the connector
> implies an equivalence-equation containing the parameters. The following model:

```Modelica
      connector Port
        parameter Real prop;
        Real p;
        flow Real f;
      end Port;

      model M
        Port p, n;
        equation
        connect(p, n);
      end M;
```

> implicitly contains an equivalence-equation:

```Modelica
      model M
        Port p, n;
        equation
        connect(p, n);
        equivalent(p.prop, n.prop);
      end M;
```

> This technique together with some explicitely defined equivalence equations allows for comfortable
> parameter passing along connections.

### Changes to the Syntax

The syntax of equations is slightly extended:

```
equation : ... | connect_clause | equivalence_clause | ...
```

```equivalence_clause : ```  **```equivalent ```**  ```"(" component_reference "," component_reference ")" ";" ```

Section **2.3.3** shall note the new keyword **```equivalent```**.

## Backwards Compatibility

The extension is not completely backwards-compatible:
The identifier ```equivalent``` becomes a reserved token. Parameters declared inside 
connectors cannot be defined separately.

## Implementation Effort

Creating the equivalence relation and checking for unique parameter bindings should be
rather simple. The most implementation effort should be expected for the implementation
of the evaluation order. 


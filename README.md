# Priority Queue — SKY130

This repository contains the development of an algorithmic and hardware-oriented implementation of a priority queue based on the work:

Collinson, S., Bai, A., & Sinnen, O. A Fast Scalable Hardware Priority Queue and Optimizations for Multi-Pushes. Parallel and Reconfigurable Computing Lab, Department of Electrical, Computer, and Software Engineering, University of Auckland, New Zealand.

The project aims to study and reproduce the algorithmic ideas presented in this work, beginning with a functional C++ reference model and progressively moving toward an RTL implementation and eventual physical implementation targeting the SKY130 technology.

The development follows a deliberately staged methodology:


```text
C++ baseline
      ↓
C++ Multi-Push reference
      ↓
Functional validation
      ↓
Algorithmic characterization
      ↓
RTL implementation
      ↓
RTL verification
      ↓
Synthesis
      ↓
SKY130 physical implementation


The central rule of the project is:

CORRECTNESS
     ↓
ALGORITHM
     ↓
HARDWARE
```

No hardware conclusions are drawn until the C++ reference implementation has been demonstrated to be functionally equivalent to the conventional priority-queue baseline.

#Current Status

The project currently contains:

A conventional binary-heap C++ baseline.

Workload generators and reproducible test workloads.

Functional verification scripts.

Baseline performance and operation-count characterization.

A C++ reference model for the Multi-Push optimization.

Functional comparison infrastructure between the baseline and Multi-Push implementations.

Reproducibility records for the development environment.

Documentation and experimental runbooks.

The principal characterization workloads use:

N = 8, 16, 32, 64, 128
seed = 12345


The current work is focused on establishing functional equivalence and understanding the algorithmic behavior before moving to RTL.

#Hardware Status

RTL implementation is not yet complete.

The following stages are therefore considered future work:

[ ] RTL implementation
[ ] RTL testbench
[ ] RTL verification against C++ reference
[ ] Synthesis
[ ] Area characterization
[ ] Timing characterization
[ ] Frequency characterization
[ ] Power characterization
[ ] SKY130 place and route
[ ] Physical results


The current project state should therefore be understood as:

algorithmic reference
+
functional verification
+
algorithmic characterization


rather than as a completed hardware implementation.

#Project Structure

```text
priority-queue-sky130/
│
├── README.md
├── RUNBOOK.md
│
├── cpp/
│   ├── reference/
│   │   ├── heap.cpp
│   │   ├── heap_runner.cpp
│   │   ├── heap_drain.cpp
│   │   ├── heap_stats.cpp
│   │   ├── heap_phase_stats.cpp
│   │   ├── multipush_reference.cpp
│   │   └── ...
│   │
│   ├── workloads/
│   │   ├── generator.cpp
│   │   ├── generated/
│   │   └── ...
│   │
│   ├── analysis/
│   │   ├── baseline/
│   │   ├── multipush/
│   │   ├── check_baseline.py
│   │   ├── compare_output.py
│   │   └── summarize_phase_stats.py
│   │
│   └── reproducibility/
│
├── docs/
├── paper/
├── rtl/
├── tb/
├── sim/
├── sky130/
└── scripts/
```

Main Components
Path	Purpose
cpp/reference/	C++ reference implementations
cpp/workloads/	Workload generator and input workloads
cpp/analysis/	Functional verification and characterization
cpp/reproducibility/	Environment and reproducibility evidence
docs/	Technical project documentation
paper/	Research paper and related material
rtl/	Future RTL implementation
tb/	Future RTL testbenches
sim/	Simulation infrastructure
sky130/	SKY130-specific implementation flow
scripts/	Project and environment scripts
RUNBOOK.md	Reproducible experimental procedure
Experimental Methodology

The same workload is used as input to the different reference implementations.

The intended comparison is:

                    same workload
                         │
              ┌──────────┴──────────┐
              ↓                     ↓
       Binary Heap             Multi-Push
          baseline              reference
              │                     │
              └──────────┬──────────┘
                         ↓
                 output comparison
                         ↓
                functional equivalence
                         ↓
                algorithmic comparison


Functional equivalence is evaluated before comparing internal operation counts.

The relevant measurements include:

Push comparisons

Push swaps

Pop comparisons

Pop swaps

Total comparisons

Total swaps

Heapify-up operations

An important distinction is maintained between functional correctness and internal algorithmic cost.

Two implementations may produce exactly the same sequence of priority-queue results while performing different numbers of comparisons or swaps.

Reproducibility

The principal characterization uses a fixed random seed:

seed = 12345


with workload sizes:

8
16
32
64
128


Using a fixed seed allows different implementations to receive exactly the same inputs:

C++ baseline
      ↓
C++ Multi-Push
      ↓
RTL


This makes functional comparison and subsequent hardware verification reproducible.

The detailed procedure for regenerating workloads, executing the reference implementations, checking outputs, and collecting statistics is documented in:

RUNBOOK.md

##Golden Rule

The project deliberately follows this order:

1. Same input
        ↓
2. Same output
        ↓
3. Functional verification
        ↓
4. Compare algorithmic cost
        ↓
5. Design RTL architecture
        ↓
6. Implement RTL
        ↓
7. Verify RTL against C++
        ↓
8. Synthesis
        ↓
9. SKY130


Never invert this order.

Hardware metrics such as area, timing, frequency, power, or PPA should not be inferred from the current C++ results.

What Has Been Learned So Far

The baseline experiments established several important properties.

The Priority Queue Is Functionally Correct

The baseline produces elements in the expected priority order while preserving the identity of each entry.

Functional verification checks:

Expected number of elements.

Correct priority ordering.

No lost values.

No duplicated values.

Input Pattern Matters

Different input patterns can result in different internal heap costs even when they contain the same number of elements.

For example, the measured push costs for eight elements were:

ordered    → 0 comparisons/swaps during upward movement
reverse    → 13
unordered  → 3


Therefore:

same N ≠ same internal cost

Problem Size Matters

The baseline characterization showed that increasing the workload size increases the number of internal heap operations.

For the measured workloads:

N = 8     →  27 total comparisons
N = 128   → 1412 total comparisons


and:

N = 8     →  16 total swaps
N = 128   → 697 total swaps

Push and Pop Have Different Costs

For the N = 128 workload:

push comparisons = 255
pop comparisons  = 1157


This shows that the two phases have significantly different algorithmic behavior and should therefore be characterized separately.

Multi-Push Objective

The next algorithmic step is the Multi-Push optimization.

The C++ reference model explicitly separates:

push_location


from:

heap_size


where:

push_location identifies the next free position where an incoming PUSH is accepted.

heap_size identifies the number of entries already incorporated into heap ordering.

Therefore:

push_location > heap_size


means that accepted PUSH entries are pending heap maintenance.

Conceptually:

PUSH
  ↓
write at push_location
  ↓
increment push_location
  ↓
pending entry
  ↓
HeapifyUp
  ↓
increment heap_size


A POP synchronizes pending PUSH operations before removing the root:

POP
 │
 ▼
finish pending PUSH
 │
 ▼
read root
 │
 ▼
replace root with last entry
 │
 ▼
HeapifyDown
 │
 ▼
update heap_size
 │
 ▼
update push_location


The Multi-Push reference is intentionally sequential at this stage. Its purpose is to establish functional equivalence and characterize the algorithm before designing hardware.

Validation Principle

For every workload:

same input
     ↓
┌───────────────┐
│ Binary Heap   │
└───────┬───────┘
        │
        │ same output
        │
┌───────▼───────┐
│ Multi-Push    │
└───────────────┘


The required condition is:

baseline output == Multi-Push output


Equality must preserve:

Priority

Value

Extraction order

Number of extracted entries

Matching only the number of elements is not sufficient.

Acceptance Criteria

The Multi-Push C++ reference is considered ready for the next stage only when:

[PASS] Workloads are reproducible
[PASS] Baseline is functionally correct
[PASS] Multi-Push compiles
[PASS] Multi-Push processes all workloads
[PASS] Outputs coincide
[PASS] No elements are lost
[PASS] No elements are duplicated
[PASS] Priorities maintain the expected ordering
[PASS] Statistics are recorded


If any condition fails:

STOP


The problem must be investigated before continuing toward RTL.

What This Project Does Not Claim Yet

The current C++ results do not establish:

Hardware area

Timing

Maximum frequency

Power consumption

PPA

RTL performance

SKY130 physical performance

Place-and-route results

Layout results

Those properties can only be evaluated after the corresponding hardware implementation and physical-design stages have been completed.

Transition to RTL

Once the Multi-Push C++ model has been functionally validated, the intended transition is:

C++ baseline
      │
      │ same input/output
      ▼
C++ Multi-Push
      │
      │ algorithm validated
      ▼
RTL
      │
      ▼
RTL verification
      │
      ▼
Synthesis
      │
      ▼
SKY130


The C++ model therefore acts as an executable algorithmic specification for the future hardware implementation.

References
Target Research Work

Collinson, S., Bai, A., & Sinnen, O. (n.d.). A fast scalable hardware priority queue and optimizations for multi-pushes. Parallel and Reconfigurable Computing Lab, Department of Electrical, Computer, and Software Engineering, University of Auckland, New Zealand.

Algorithms and Data Structures

Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press.

Linux and Command-Line Environment

Shotts, W. E., Jr. (2019). The Linux command line: A complete introduction (2nd ed.). No Starch Press.

Queueing Theory

Kleinrock, L. (1976). Queueing systems: Volume II: Computer applications. John Wiley & Sons.

Documentation

For the reproducible execution procedure, see:

RUNBOOK.md


For the technical development notes and experimental documentation, see:

docs/


The repository is intended to maintain a traceable progression from:

algorithm
    ↓
C++ reference
    ↓
workloads
    ↓
verification
    ↓
characterization
    ↓
RTL
    ↓
SKY130


with correctness established before hardware optimization.

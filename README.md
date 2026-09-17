# 🚀 Priority Queue — SKY130

[![PDK](https://img.shields.io/badge/PDK-SKY130-blue.svg)](https://github.com/google/skywater-pdk)
[![Tools](https://img.shields.io/badge/Environment-IIC%2FOSIC--TOOLS-green.svg)](https://github.com/iic-jku/IIC-OSIC-TOOLS)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)

Este repositorio contiene la especificación ejecutable, modelo de referencia algorítmico y caracterización experimental para una **Cola de Prioridad Hardware Rápida y Escalable (HybridQ)** con optimización para ráfagas de inserción (**Multi-Push**). El proyecto está basado en el trabajo de investigación de **Collinson, Bai & Sinnen** (*Parallel and Reconfigurable Computing Lab, Universidad de Auckland*) y se desarrolla dentro del entorno open-source **IIC/OSIC-TOOLS** con objetivo de implementación física en la tecnología **SKY130**.

---

## 📌 Metodología y Regla de Oro del Proyecto

El desarrollo del proyecto sigue una metodología rigurosa y deliberada por etapas:

```text
               C++ Baseline (Binary Min-Heap)
                             │
                             ▼
              C++ Multi-Push Reference (FSM)
                             │
                             ▼
              Validación de Equivalencia Funcional
                             │
                             ▼
              Caracterización Algorítmica (Comparaciones/Swaps)
                             │
                             ▼
              Implementación RTL (SystemVerilog)
                             │
                             ▼
              Verificación RTL & Testbenches (Verilator)
                             │
                             ▼
              Síntesis Lógica & Physical Design (SKY130 / OpenLane)
```

> [!IMPORTANT]
> **LA REGLA DE ORO DEL PROYECTO:**  
> $$\text{CORRECTNESS} \longrightarrow \text{ALGORITHM} \longrightarrow \text{HARDWARE}$$  
> *Nunca se invierte este orden.* No se infieren conclusiones de hardware ni se inicia el desarrollo RTL hasta que el modelo de referencia C++ haya demostrado una **equivalencia funcional estricta** frente al baseline convencional.

---

## 🚫 Deslinde de Alcance (Non-Claims Boundary)

> [!WARNING]  
> **Límite de Interpretación de los Resultados:**  
> Los datos experimentales presentados corresponden a la **referencia algorítmica en software (C++)**. Las métricas numéricas de trabajo (comparaciones y *swaps*) **NO** representan directamente:
> * Área de silicio, número de compuertas lógicas, LUTs o registros.
> * Tiempos de propagación o retardo de ruta crítica.
> * Frecuencia máxima de reloj ($F_{\text{max}}$).
> * Consumo de potencia dinámica o estática (PPA).
> * Resultados de ubicación y ruteo (Place & Route) o trazado de celdas en SKY130.
>
> Dichas métricas físicas se evaluarán exclusivamente tras completar las etapas de diseño RTL, verificación en testbenches y síntesis física en OpenLane.

---

## 🔬 Fundamentos Teóricos y Caracterización del Baseline

El baseline algorítmico consiste en un *Binary Min-Heap* en C++ donde cada elemento está definido por la estructura:

```cpp
struct Entry {
    int priority; // Rige el orden de extracción (min-priority)
    int value;    // Garantiza la preservación de la identidad del dato
};
```

### 1️⃣ Comparación Lexicográfica Determinista
Para evitar ambigüedades con prioridades duplicadas, la relación de orden se define como:

$$a < b \iff (a.\text{priority} < b.\text{priority}) \lor (a.\text{priority} == b.\text{priority} \land a.\text{value} < b.\text{value})$$

### 2️⃣ Representación Secuencial en Vector
El árbol binario se almacena implícitamente en un `std::vector<Entry>`, empleando la aritmética de navegación por índices:
* **Hijo izquierdo:** $\text{left}(i) = 2i + 1$
* **Hijo derecho:** $\text{right}(i) = 2i + 2$
* **Padre:** $\text{parent}(i) = \lfloor (i - 1) / 2 \rfloor$

### 3️⃣ Asimetría entre Inserción y Extracción
En los experimentos aleatorios con semilla determinista (`seed = 12345`), se observa que la fase de extracción (`Pop`) concentra la gran mayoría del trabajo algorítmico total (representando el **81.9%** de las comparaciones para $N=128$):

```text
Workload N = 128 (seed = 12345):
  Push Comparisons : [████████░░░░░░░░░░░░░░░░░░░░] 255  (18.1%)
  Pop Comparisons  : [████████████████████████████] 1,157 (81.9%)
```

| Tamaños ($N$) | $C_{\text{push}}$ | $S_{\text{push}}$ | $C_{\text{pop}}$ | $S_{\text{pop}}$ | Total Comparaciones ($C_{\text{total}}$) | Total Swaps ($S_{\text{total}}$) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **8** | 11 | 8 | 16 | 8 | **27** | **16** |
| **16** | 21 | 10 | 56 | 28 | **77** | **38** |
| **32** | 55 | 30 | 175 | 84 | **230** | **114** |
| **64** | 116 | 59 | 452 | 223 | **568** | **282** |
| **128** | 255 | 135 | 1157 | 562 | **1,412** | **697** |

### 4️⃣ Sensibilidad al Patrón de Entrada
Para una cantidad fija de elementos ($N=8$), el costo interno varía significativamente según el orden de llegada:

| Patrón de Entrada | $C_{\text{push}}$ | $S_{\text{push}}$ | $C_{\text{pop}}$ | $S_{\text{pop}}$ | Comportamiento del Heap |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Ordered** (Creciente) | 7 | **0** | 17 | 9 | **Mínimo:** Sin *swaps* en ascenso (`sift_up`) |
| **Reverse** (Decreciente) | 13 | **13** | 15 | 6 | **Máximo:** Cada elemento asciende hasta la raíz |
| **Unordered** (Desordenado) | 9 | **3** | 17 | 9 | **Intermedio:** Trabajo promedio de inserción |

$$\text{Mismo } N \neq \text{Mismo Costo Algorítmico}$$

---

## ⚡ Arquitectura Hardware y Optimización Multi-Push

La arquitectura de Collinson et al. resuelve el dilema entre las colas de registro de desplazamiento de 1 ciclo ($O(N)$ comparadores, no escalables) y las colas en memoria BlockRAM ($O(\log N)$ ciclos).

### 1. Cola Híbrida (HybridQ)
Integra una pequeña cola de registros de desplazamiento como buffer frontal de ciclo único. Cuando este buffer se llena, los elementos de menor prioridad se desbordan (*spill*) de forma transparente hacia el heap en BlockRAM.

### 2. Optimización para Memorias Dual-Port en FPGA/ASIC
Para evitar escrituras intermedias redundantes durante los intercambios (*swaps*) en memoria Dual-Port, se utiliza un registro de trabajo (`working_reg`). Esto reduce el costo de intercambio a solo **1 ciclo de escritura por nivel del árbol**, realizando las lecturas del siguiente padre en paralelo.

### 3. Mecanismo Multi-Push (Sección VI)
Diseñado para workloads con ráfagas de inserción consecutivas (trazado de rayos o búsqueda $A^*$). Separa el puntero de escritura del tamaño del heap ordenado:

* **`push_location`**: Registro de dirección al final de la cola (tail). Permite la escritura incondicional de cualquier `push` entrante en **1 ciclo de reloj**.
* **`heap_size`**: Elementos efectivamente ordenados bajo la propiedad de heap.
* **Mantenimiento Diferido en `IDLE`**: En reposo, si `push_location > heap_size`, la FSM ejecuta `HeapifyUp` en segundo plano e incrementa `heap_size`.
* **Sincronización de `Pop`**: Las operaciones `pop` se bloquean temporalmente si `push_location > heap_size` o `busy == 1`, garantizando la validez de la raíz.

```text
PUSH(data) ──────► Write heap[push_location] ──► push_location++ (1 Ciclo Incondicional)

IDLE FSM   ──────► If push_location > heap_size ──► Execute HeapifyUp() ──► heap_size++

POP()      ──────► Wait while (push_location > heap_size || busy) ──► Extract Root
```

---

## 📋 Criterios de Aceptación (Go / No-Go Gate)

El modelo C++ de Multi-Push debe superar la totalidad de los criterios antes de iniciar el diseño RTL en SystemVerilog:

- [x] **Reproducibilidad:** Workloads deterministas con semilla `12345`.
- [x] **Baseline Correcto:** Min-heap convencional verificado.
- [x] **Compilación Limpia:** Ejecutable de referencia C++ sin advertencias.
- [ ] **Equivalencia Funcional Estricta:** Stream de salida $R_{\text{baseline}} \equiv R_{\text{multipush}}$ exacto en `priority` y `value`.
- [ ] **Conservación de Datos:** Cero elementos perdidos, cero elementos duplicados.
- [ ] **Registro de Estadísticas:** Conteo de comparaciones, swaps y ciclos diferidos.

---

## 🛠️ Estructura del Repositorio

```text
priority-queue-sky130/
├── README.md               # Especificación general y documentación principal
├── RUNBOOK.md              # Procedimiento experimental reproducible
├── cpp/
│   ├── reference/          # Baselines y modelos C++ (heap.cpp, multipush_reference.cpp)
│   ├── workloads/          # Generadores deterministas y escenarios de prueba (.txt)
│   └── analysis/           # Scripts Python de verificación (check_baseline.py, compare_output.py)
├── docs/                   # Guías de estudio teóricas y documentación técnica
├── paper/                  # Artículos académicos de referencia (Collinson et al.)
├── rtl/                    # [Futuro] Módulos SystemVerilog
├── tb/                     # [Futuro] Testbenches y co-simulación Verilator
├── sim/                    # [Futuro] Infraestructura de simulación
└── sky130/                 # [Futuro] Flujo de síntesis física OpenLane
```

---

## ⚙️ Guía de Ejecución Rápida

Para reproducir los experimentos de caracterización y verificación funcional:

```bash
# 1. Ingresar al directorio del código C++
cd cpp

# 2. Generar workload determinista (N=16, seed=12345)
./workloads/generator 16 12345 > workloads/generated/workload_16_seed12345.txt

# 3. Procesar workload con el baseline
./reference/heap_drain workloads/generated/workload_16_seed12345.txt

# 4. Validar la corrección funcional automáticamente
python3 analysis/check_baseline.py

# 5. Consolidar el resumen de estadísticas en CSV
python3 analysis/summarize_phase_stats.py
```

---

## 📚 Referencias Bibliográficas

1. **Collinson, S., Bai, A., & Sinnen, O.** *A Fast Scalable Hardware Priority Queue and Optimizations for Multi-Pushes*. Parallel and Reconfigurable Computing Lab, Department of Electrical, Computer, and Software Engineering, University of Auckland.
2. **Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009).** *Introduction to Algorithms* (3rd ed.). MIT Press.
3. **Kleinrock, L. (1976).** *Queueing Systems: Volume II: Computer Applications*. John Wiley & Sons.
4. **Shotts, W. E., Jr. (2019).** *The Linux Command Line: A Complete Introduction* (2nd ed.). No Starch Press.
5. **Guevara Kalil, C. (2026).** *Guía del Mochilero Intergaláctico a la Microelectrónica Open Source: Priority Queues en SKY130*.

---
*Proyecto preparado para el ecosistema de microelectrónica open-source **SKY130 / IIC/OSIC-TOOLS**.*



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
7. Verify RTL against
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


me
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

Number of 

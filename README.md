# CoreSched – CPU Scheduling Simulator in x86 Assembly

A menu-driven CPU scheduling simulator written in **32-bit x86 assembly (MASM)** with the **Irvine32** library.
It simulates **FCFS**, **non-preemptive SJF** and **Round Robin**, draws a text Gantt chart and calculates
the waiting and turnaround time of every process.

Course project for **EL-2003 Computer Organization and Assembly Language Lab**, FAST-NUCES Karachi, Fall 2026 (BCS-3A).

| Member | Roll No. | Role |
|---|---|---|
| Abuzar Mehdi | 24K-0630 | Group Leader |
| Muhammad Bilal Ansari | 22K-4365 | Member |

## Files

| File | Description |
|---|---|
| `CoreSched.asm` | Complete source code (single file) |
| `COAL_FinalReport_BCS-3A.docx` | Final project report |
| `README.md` | This file |

## Features

- Enter 1–5 processes with burst times from 1 to 99, or load a built-in sample data set
- First Come, First Served (FCFS)
- Shortest Job First, non-preemptive (SJF) – equal bursts keep their entry order
- Round Robin with a time quantum from 1 to 99
- Coloured text Gantt chart that wraps onto new rows when it is long
- Table of burst, completion, waiting and turnaround times, with totals and averages (two decimals)
- Total CPU time and number of context switches
- Comparison of all three algorithms on the same data
- Full input validation: letters, negative numbers, decimals, empty input and out-of-range values are rejected

All processes are assumed to arrive at time 0.

## Requirements

- Windows
- Visual Studio 2022 with the **Desktop development with C++** workload (installs MASM)
- [Irvine32 library](http://asmirvine.com/) installed in `C:\Irvine`

## How to run (Visual Studio 2022)

**Using the lab Project32 template**

1. Open the Project32 solution.
2. Remove its existing `.asm` file from the project.
3. Right-click **Source Files → Add → Existing Item…** and choose `CoreSched.asm`.
4. Select **Debug** and **x86** in the toolbar.
5. Build with **Ctrl+Shift+B** and run with **Ctrl+F5**.

**Using a new Empty Project**

1. Create an **Empty Project (C++)** and add `CoreSched.asm` to *Source Files*.
2. **Project → Build Dependencies → Build Customizations** – tick **masm**.
3. In **Project Properties** (All Configurations, Win32) set:

   | Setting | Value |
   |---|---|
   | Microsoft Macro Assembler → General → Include Paths | `C:\Irvine` |
   | Linker → General → Additional Library Directories | `C:\Irvine` |
   | Linker → Input → Additional Dependencies | add `Irvine32.lib;` at the start |
   | Linker → System → SubSystem | Console |
   | Linker → Advanced → Image Has Safe Exception Handlers | No |

4. Select **x86**, build and run with **Ctrl+F5**.

## Menu

```
1. Enter new process data
2. Load sample data set (P1=6, P2=8, P3=7, P4=3)
3. Run First Come, First Served (FCFS)
4. Run Shortest Job First (non-preemptive SJF)
5. Run Round Robin (RR)
6. Compare all three algorithms
7. Instructions and formulas
8. Exit
```

## Formulas

- Turnaround time = Completion time − Arrival time (0)
- Waiting time = Turnaround time − Burst time

## Quick check (sample data, option 2)

| Algorithm | Avg waiting | Avg turnaround |
|---|---|---|
| FCFS | 10.25 | 16.25 |
| SJF | 7.00 | 13.00 |
| Round Robin (q = 4) | 13.25 | 19.25 |

## Assembly concepts used

Loops and conditional jumps, arrays with scaled-index addressing, 41 procedures with the stack
(USES / PUSH / POP), a jump table of procedure addresses, macros, string instructions
(`REP MOVSD`, `REP STOSD`), integer arithmetic (`IMUL`, `MUL`, `DIV`) and Irvine32 / Win32 console calls.

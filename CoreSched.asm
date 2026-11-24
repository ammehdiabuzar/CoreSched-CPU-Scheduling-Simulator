TITLE CoreSched - CPU Scheduling Simulator (FCFS, SJF, Round Robin)
; EL-2003 COAL Lab, Fall 2026, BCS-3A
; Abuzar Mehdi (24K-0630), Muhammad Bilal Ansari (22K-4365)

INCLUDE Irvine32.inc

MAX_PROC      = 5
MIN_BURST     = 1
MAX_BURST     = 99
MIN_QUANTUM   = 1
MAX_QUANTUM   = 99
MAX_SEG       = 512
MAX_DIGITS    = 4
CELL_WIDTH    = 7
CELLS_PER_ROW = 10
MENU_ITEMS    = 8
SAMPLE_COUNT  = 4
CMP_COL1      = 26

ALG_FCFS      = 0
ALG_SJF       = 1
ALG_RR        = 2
ALG_COUNT     = 3

CLR_DEFAULT   = lightGray  + (black * 16)
CLR_TITLE     = yellow     + (black * 16)
CLR_HEAD      = lightCyan  + (black * 16)
CLR_ERROR     = lightRed   + (black * 16)
CLR_OK        = lightGreen + (black * 16)
CLR_BEST      = black      + (lightGreen * 16)

mPrint MACRO strLabel
    push edx
    mov  edx, OFFSET strLabel
    call WriteString
    pop  edx
ENDM

mPrintLn MACRO strLabel
    mPrint strLabel
    call Crlf
ENDM

mColor MACRO attr
    push eax
    mov  eax, attr
    call SetTextColor
    pop  eax
ENDM

.data

; process data
procCount   DWORD 0
quantum     DWORD 0
burst       DWORD MAX_PROC DUP(0)
remaining   DWORD MAX_PROC DUP(0)       ; remaining burst (Round Robin only)
completion  DWORD MAX_PROC DUP(0)
waiting     DWORD MAX_PROC DUP(0)
turnaround  DWORD MAX_PROC DUP(0)
order       DWORD MAX_PROC DUP(0)       ; execution order (process indexes)

sampleBursts DWORD 6, 8, 7, 3

; Gantt chart
segProc     DWORD MAX_SEG DUP(0)        ; process index of each segment
segEnd      DWORD MAX_SEG DUP(0)        ; end time of each segment
segCount    DWORD 0

; statistics
totalBurst  DWORD 0
totalWait   DWORD 0
totalTurn   DWORD 0
avgWait100  DWORD 0                     ; average waiting time * 100
avgTurn100  DWORD 0                     ; average turnaround time * 100

cmpWait100  DWORD ALG_COUNT DUP(0)
cmpTurn100  DWORD ALG_COUNT DUP(0)
cmpSwitch   DWORD ALG_COUNT DUP(0)

; misc
inputBuf    BYTE 64 DUP(0)
procColors  DWORD lightCyan, lightGreen, yellow, lightMagenta, lightRed

; jump table of menu options 1..7 (option 8 = exit)
menuHandlers DWORD OFFSET InputProcesses, OFFSET LoadSampleData
             DWORD OFFSET DoFCFS, OFFSET DoSJF, OFFSET DoRoundRobin
             DWORD OFFSET CompareAll, OFFSET ShowInstructions

algTitles   DWORD OFFSET strTitleFCFS, OFFSET strTitleSJF, OFFSET strTitleRR
algNames    DWORD OFFSET strNameFCFS,  OFFSET strNameSJF,  OFFSET strNameRR

; strings
strBanLine  BYTE "  ==================================================================",0
strBan1     BYTE "     C O R E S C H E D   -   CPU Scheduling Simulator in x86 Assembly",0
strBan2     BYTE "     FCFS  |  SJF (non-preemptive)  |  Round Robin      MASM + Irvine32",0
strMenuHead BYTE "  ------------------------- MAIN MENU -------------------------",0
strMenu1    BYTE "   1. Enter new process data",0
strMenu2    BYTE "   2. Load sample data set (P1=6, P2=8, P3=7, P4=3)",0
strMenu3    BYTE "   3. Run First Come, First Served (FCFS)",0
strMenu4    BYTE "   4. Run Shortest Job First (non-preemptive SJF)",0
strMenu5    BYTE "   5. Run Round Robin (RR)",0
strMenu6    BYTE "   6. Compare all three algorithms",0
strMenu7    BYTE "   7. Instructions and formulas",0
strMenu8    BYTE "   8. Exit",0
strPromptChoice BYTE "  Enter your choice (1-8): ",0
strCurData  BYTE "  Current data set : ",0
strNoData   BYTE "none  (choose option 1 or 2 first)",0
strProcsIn  BYTE " process(es)   ",0

strInTitle  BYTE "  ===================== ENTER PROCESS DATA =====================",0
strInNote   BYTE "  All processes are assumed to arrive at time 0.",0
strPromptCount BYTE "  Number of processes (1-5): ",0
strPromptBurst BYTE "  Burst time for P"
burstDigit     BYTE "1"
               BYTE " (1-99): ",0
strPromptQuantum BYTE "  Enter Round Robin time quantum (1-99): ",0
strDataSaved BYTE "  Process data saved successfully.",0
strSampleOk  BYTE "  Sample data loaded (4 processes, Silberschatz SJF example).",0
strNeedData  BYTE "  No process data yet - please enter the processes first.",0
strErrNum    BYTE "  [!] Invalid input. Please type a whole number (digits only).",0
strErrRange1 BYTE "  [!] Out of range. Please enter a value from ",0
strErrRange2 BYTE " to ",0
strDot       BYTE ".",0

strTitleFCFS BYTE "  ============ FIRST COME, FIRST SERVED (FCFS) ============",0
strTitleSJF  BYTE "  ========= SHORTEST JOB FIRST (NON-PREEMPTIVE) ==========",0
strTitleRR   BYTE "  ====================== ROUND ROBIN ======================",0
strNameFCFS  BYTE "  FCFS",0
strNameSJF   BYTE "  SJF (non-preemptive)",0
strNameRR    BYTE "  Round Robin",0
strInfoProc  BYTE "  Processes    : ",0
strInfoArr   BYTE "   (all arrive at time 0)",0
strInfoQ     BYTE "  Time quantum : ",0
strGantt     BYTE "  Gantt Chart:",0
strIndent    BYTE "  ",0
strCellTop   BYTE "+------",0
strCellLeft  BYTE "|  ",0
str2sp       BYTE "  ",0
str3sp       BYTE "   ",0
strPlus      BYTE "+",0
strBar       BYTE "|",0
strCellP     BYTE "    ",0
strTblHead   BYTE "  Process","   Burst","   Completion","   Waiting","   Turnaround",0
strTblLine   BYTE "  ",51 DUP('-'),0
strTotal     BYTE "  Total  ",0
strAverage   BYTE "  Average",0
strSumTime   BYTE "  Total CPU time          : ",0
strSumSwitch BYTE "  Context switches        : ",0
strSumAvgW   BYTE "  Average waiting time    : ",0
strSumAvgT   BYTE "  Average turnaround time : ",0
strUnits     BYTE " time units",0

strCmpTitle  BYTE "  =============== COMPARISON OF ALL ALGORITHMS ===============",0
strCmpAlg    BYTE "  Algorithm",0
strCmpHead2  BYTE "   Avg Waiting","   Avg Turnaround","   Switches",0
strCmpLine   BYTE "  ",66 DUP('-'),0
strBestTag   BYTE "  <- best",0
strCmpBest   BYTE "  Lowest average waiting time: ",0
strCmpNote1  BYTE "  Note: when every process arrives at time 0, SJF always gives the",0
strCmpNote2  BYTE "  minimum possible average waiting time.",0

strHelp BYTE "  ======================= INSTRUCTIONS =======================",0dh,0ah,0dh,0ah
        BYTE "  HOW TO USE",0dh,0ah
        BYTE "  1. Choose option 1 to type your own processes (1 to 5 processes,",0dh,0ah
        BYTE "     burst time 1-99 each) or option 2 to load a ready-made sample.",0dh,0ah
        BYTE "  2. Choose an algorithm (options 3, 4 or 5). Round Robin also asks",0dh,0ah
        BYTE "     for a time quantum (1-99).",0dh,0ah
        BYTE "  3. Read the Gantt chart and the result table, then press a key",0dh,0ah
        BYTE "     to return to the menu and try another algorithm or data set.",0dh,0ah
        BYTE "  4. Option 6 runs all three algorithms on the same data and",0dh,0ah
        BYTE "     compares their average waiting and turnaround times.",0dh,0ah,0dh,0ah
        BYTE "  FORMULAS  (every process arrives at time 0)",0dh,0ah
        BYTE "  Completion time = time at which the process finishes on the CPU",0dh,0ah
        BYTE "  Turnaround time = completion time - arrival time (= completion)",0dh,0ah
        BYTE "  Waiting time    = turnaround time - burst time",0dh,0ah
        BYTE "  Average         = sum of the values / number of processes",0dh,0ah,0dh,0ah
        BYTE "  ALGORITHMS",0dh,0ah
        BYTE "  FCFS : processes run to completion in the order they were entered.",0dh,0ah
        BYTE "  SJF  : the process with the shortest burst runs first; equal bursts",0dh,0ah
        BYTE "         keep their entry order. A process is never interrupted.",0dh,0ah
        BYTE "  RR   : processes take turns in a cycle; each turn lasts at most one",0dh,0ah
        BYTE "         time quantum, then the CPU moves to the next unfinished one.",0dh,0ah,0
strPressKey BYTE "  Press any key to continue...",0
strBye  BYTE "  Thank you for using CoreSched. Goodbye!",0

.code

; Program entry: shows the menu and calls the chosen option
main PROC
    mColor CLR_DEFAULT
MenuLoop:
    call ShowMenu
    mov  edx, OFFSET strPromptChoice
    mov  ebx, 1
    mov  ecx, MENU_ITEMS
    call ReadIntInRange
    cmp  eax, MENU_ITEMS
    je   Quit
    call menuHandlers[eax*4 - 4]        ; indirect call through the table
    jmp  MenuLoop
Quit:
    call Crlf
    mColor CLR_TITLE
    mPrintLn strBye
    mColor CLR_DEFAULT
    exit
main ENDP

;============================================================
; INPUT AND VALIDATION
;============================================================

; Reads a line and converts it to a number. Out: EAX = value, CF = 1 if invalid
ReadNumber PROC USES ebx ecx edx esi
    mov  edx, OFFSET inputBuf
    mov  ecx, SIZEOF inputBuf - 1
    call ReadString
    mov  ecx, eax
    mov  esi, OFFSET inputBuf
    xor  eax, eax
    xor  edx, edx

SkipLead:
    jecxz CheckEnd
    mov  bl, [esi]
    cmp  bl, ' '
    je   NextLead
    cmp  bl, 9
    jne  Digits
NextLead:
    inc  esi
    dec  ecx
    jmp  SkipLead

Digits:
    jecxz CheckEnd
    movzx ebx, BYTE PTR [esi]
    cmp  bl, '0'
    jb   Trailing
    cmp  bl, '9'
    ja   Trailing
    cmp  edx, MAX_DIGITS
    jae  Invalid
    imul eax, eax, 10                   ; value = value * 10 + digit
    sub  bl, '0'
    add  eax, ebx
    inc  edx
    inc  esi
    dec  ecx
    jmp  Digits

Trailing:
    jecxz CheckEnd
    mov  bl, [esi]
    cmp  bl, ' '
    je   NextTrail
    cmp  bl, 9
    jne  Invalid
NextTrail:
    inc  esi
    dec  ecx
    jmp  Trailing

CheckEnd:
    test edx, edx
    jz   Invalid
    clc
    ret
Invalid:
    stc
    ret
ReadNumber ENDP

; Asks until a number from EBX to ECX is typed. In: EDX = prompt. Out: EAX
ReadIntInRange PROC USES edx esi
    mov  esi, edx
AskAgain:
    mov  edx, esi
    call WriteString
    call ReadNumber
    jc   NotANumber
    cmp  eax, ebx
    jb   OutOfRange
    cmp  eax, ecx
    ja   OutOfRange
    ret

NotANumber:
    mColor CLR_ERROR
    mPrintLn strErrNum
    mColor CLR_DEFAULT
    jmp  AskAgain

OutOfRange:
    mColor CLR_ERROR
    mPrint strErrRange1
    mov  eax, ebx
    call WriteDec
    mPrint strErrRange2
    mov  eax, ecx
    call WriteDec
    mPrintLn strDot
    mColor CLR_DEFAULT
    jmp  AskAgain
ReadIntInRange ENDP

; Reads the number of processes and their burst times
InputProcesses PROC USES eax ebx ecx edx esi
    call Clrscr
    mColor CLR_TITLE
    mPrintLn strInTitle
    mColor CLR_DEFAULT
    mPrintLn strInNote
    call Crlf

    mov  edx, OFFSET strPromptCount
    mov  ebx, 1
    mov  ecx, MAX_PROC
    call ReadIntInRange
    mov  procCount, eax
    call Crlf

    xor  esi, esi
NextBurst:
    cmp  esi, procCount
    jae  InputDone
    mov  eax, esi
    add  al, '1'
    mov  burstDigit, al                 ; patch "P?" inside the prompt
    mov  edx, OFFSET strPromptBurst
    mov  ebx, MIN_BURST
    mov  ecx, MAX_BURST
    call ReadIntInRange
    mov  burst[esi*4], eax
    inc  esi
    jmp  NextBurst

InputDone:
    call Crlf
    mColor CLR_OK
    mPrintLn strDataSaved
    mColor CLR_DEFAULT
    call ShowCurrentData
    call Crlf
    call PressAnyKey
    ret
InputProcesses ENDP

; Loads the sample data set P1=6, P2=8, P3=7, P4=3
LoadSampleData PROC USES ecx esi edi
    cld
    mov  esi, OFFSET sampleBursts
    mov  edi, OFFSET burst
    mov  ecx, SAMPLE_COUNT
    rep  movsd                          ; burst[i] = sampleBursts[i]
    mov  procCount, SAMPLE_COUNT

    call Clrscr
    mColor CLR_OK
    mPrintLn strSampleOk
    mColor CLR_DEFAULT
    call Crlf
    call ShowCurrentData
    call Crlf
    call PressAnyKey
    ret
LoadSampleData ENDP

; Reads the Round Robin time quantum
AskQuantum PROC USES eax ebx ecx edx
    call Crlf
    mov  edx, OFFSET strPromptQuantum
    mov  ebx, MIN_QUANTUM
    mov  ecx, MAX_QUANTUM
    call ReadIntInRange
    mov  quantum, eax
    ret
AskQuantum ENDP

; Asks for process data if none has been entered yet
EnsureData PROC
    cmp  procCount, 0
    jne  HaveData
    call Crlf
    mColor CLR_ERROR
    mPrintLn strNeedData
    mColor CLR_DEFAULT
    call PressAnyKey
    call InputProcesses
HaveData:
    ret
EnsureData ENDP

;============================================================
; SCHEDULING ALGORITHMS
;============================================================

; Clears the result arrays and the Gantt chart
ResetResults PROC USES eax ecx edi
    cld
    xor  eax, eax
    mov  edi, OFFSET completion
    mov  ecx, MAX_PROC
    rep  stosd
    mov  edi, OFFSET waiting
    mov  ecx, MAX_PROC
    rep  stosd
    mov  edi, OFFSET turnaround
    mov  ecx, MAX_PROC
    rep  stosd
    mov  segCount, 0
    ret
ResetResults ENDP

; Adds a Gantt segment. In: EAX = process, EDX = end time
AddSegment PROC USES ebx
    mov  ebx, segCount
    test ebx, ebx
    jz   NewSegment
    cmp  segProc[ebx*4 - 4], eax        ; same process as last segment?
    jne  NewSegment
    mov  segEnd[ebx*4 - 4], edx
    ret
NewSegment:
    cmp  ebx, MAX_SEG
    jae  SegFull
    mov  segProc[ebx*4], eax
    mov  segEnd[ebx*4], edx
    inc  segCount
SegFull:
    ret
AddSegment ENDP

; order[i] = i (entry order)
BuildFifoOrder PROC USES ecx
    xor  ecx, ecx
FillLoop:
    cmp  ecx, procCount
    jae  FillDone
    mov  order[ecx*4], ecx
    inc  ecx
    jmp  FillLoop
FillDone:
    ret
BuildFifoOrder ENDP

; Stable insertion sort of order[] by burst time (SJF)
SortOrderByBurst PROC USES eax ebx ecx esi edi
    mov  ecx, 1
OuterLoop:
    cmp  ecx, procCount
    jae  SortDone
    mov  eax, order[ecx*4]
    mov  ebx, burst[eax*4]
    mov  edi, ecx
InnerLoop:
    test edi, edi
    jz   PlaceKey
    mov  esi, order[edi*4 - 4]
    cmp  burst[esi*4], ebx
    jbe  PlaceKey                       ; stop when burst[j-1] <= key
    mov  order[edi*4], esi
    dec  edi
    jmp  InnerLoop
PlaceKey:
    mov  order[edi*4], eax
    inc  ecx
    jmp  OuterLoop
SortDone:
    ret
SortOrderByBurst ENDP

; Runs the processes in order[] without preemption (FCFS, SJF)
RunInOrder PROC USES eax ebx edx esi
    xor  edx, edx
    xor  esi, esi
RunLoop:
    cmp  esi, procCount
    jae  RunDone
    mov  ebx, order[esi*4]
    mov  waiting[ebx*4], edx
    add  edx, burst[ebx*4]
    mov  completion[ebx*4], edx
    mov  turnaround[ebx*4], edx
    mov  eax, ebx
    call AddSegment
    inc  esi
    jmp  RunLoop
RunDone:
    ret
RunInOrder ENDP

; Round Robin simulation with time slice [quantum]
RunRoundRobin PROC USES eax ebx ecx edx esi
    xor  esi, esi
CopyLoop:
    cmp  esi, procCount
    jae  CopyDone
    mov  eax, burst[esi*4]
    mov  remaining[esi*4], eax
    inc  esi
    jmp  CopyLoop
CopyDone:
    xor  edx, edx
    xor  ecx, ecx

CycleLoop:
    cmp  ecx, procCount
    jae  RRDone
    xor  esi, esi
ScanLoop:
    cmp  esi, procCount
    jae  CycleLoop
    mov  eax, remaining[esi*4]
    test eax, eax
    jz   NextProc
    mov  ebx, quantum                   ; slice = min(quantum, remaining)
    cmp  eax, ebx
    jae  UseSlice
    mov  ebx, eax
UseSlice:
    add  edx, ebx
    sub  remaining[esi*4], ebx
    mov  eax, esi
    call AddSegment
    cmp  remaining[esi*4], 0
    jne  NextProc
    mov  completion[esi*4], edx
    mov  turnaround[esi*4], edx
    mov  eax, edx
    sub  eax, burst[esi*4]              ; waiting = turnaround - burst
    mov  waiting[esi*4], eax
    inc  ecx
NextProc:
    inc  esi
    jmp  ScanLoop
RRDone:
    ret
RunRoundRobin ENDP

; Runs one algorithm. In: EAX = ALG_FCFS, ALG_SJF or ALG_RR
RunAlgorithm PROC USES eax
    call ResetResults
    cmp  eax, ALG_RR
    je   DoRR
    call BuildFifoOrder
    cmp  eax, ALG_SJF
    jne  DoOrder
    call SortOrderByBurst
DoOrder:
    call RunInOrder
    ret
DoRR:
    call RunRoundRobin
    ret
RunAlgorithm ENDP

; Computes the totals and the averages (x 100)
ComputeAverages PROC USES eax ebx ecx edx esi
    xor  eax, eax
    mov  totalBurst, eax
    mov  totalWait, eax
    mov  totalTurn, eax
    xor  esi, esi
SumLoop:
    cmp  esi, procCount
    jae  SumDone
    mov  eax, burst[esi*4]
    add  totalBurst, eax
    mov  eax, waiting[esi*4]
    add  totalWait, eax
    mov  eax, turnaround[esi*4]
    add  totalTurn, eax
    inc  esi
    jmp  SumLoop
SumDone:
    mov  eax, totalWait
    call ScaledAverage
    mov  avgWait100, eax
    mov  eax, totalTurn
    call ScaledAverage
    mov  avgTurn100, eax
    ret
ComputeAverages ENDP

; In: EAX = total. Out: EAX = round(total * 100 / procCount)
ScaledAverage PROC USES ebx ecx edx
    mov  ebx, 100
    mul  ebx                            ; EDX:EAX = total * 100
    mov  ecx, procCount
    mov  ebx, ecx
    shr  ebx, 1                         ; + n/2 for rounding
    add  eax, ebx
    adc  edx, 0
    div  ecx
    ret
ScaledAverage ENDP

;============================================================
; MENU OPTIONS
;============================================================

; Menu option 3
DoFCFS PROC USES eax
    call EnsureData
    mov  eax, ALG_FCFS
    call RunAlgorithm
    call ComputeAverages
    call ShowResults
    ret
DoFCFS ENDP

; Menu option 4
DoSJF PROC USES eax
    call EnsureData
    mov  eax, ALG_SJF
    call RunAlgorithm
    call ComputeAverages
    call ShowResults
    ret
DoSJF ENDP

; Menu option 5
DoRoundRobin PROC USES eax
    call EnsureData
    call AskQuantum
    mov  eax, ALG_RR
    call RunAlgorithm
    call ComputeAverages
    call ShowResults
    ret
DoRoundRobin ENDP

; Menu option 6: runs all three algorithms and compares them
CompareAll PROC USES eax ebx ecx edx esi
    call EnsureData
    call AskQuantum

    xor  esi, esi
CmpRun:
    cmp  esi, ALG_COUNT
    jae  CmpShow
    mov  eax, esi
    call RunAlgorithm
    call ComputeAverages
    mov  eax, avgWait100
    mov  cmpWait100[esi*4], eax
    mov  eax, avgTurn100
    mov  cmpTurn100[esi*4], eax
    mov  eax, segCount
    dec  eax                            ; switches = segments - 1
    mov  cmpSwitch[esi*4], eax
    inc  esi
    jmp  CmpRun

CmpShow:
    call Clrscr
    mColor CLR_TITLE
    mPrintLn strCmpTitle
    mColor CLR_DEFAULT
    call ShowCurrentData
    mPrint strInfoQ
    mov  eax, quantum
    call WriteDec
    mPrintLn strInfoArr
    call Crlf

    mColor CLR_HEAD
    mov  edx, OFFSET strCmpAlg
    mov  ebx, CMP_COL1
    call WritePaddedStr
    mPrintLn strCmpHead2
    mColor CLR_DEFAULT
    mPrintLn strCmpLine

    xor  ecx, ecx
    mov  esi, 1
FindBest:
    cmp  esi, ALG_COUNT
    jae  PrintRows
    mov  eax, cmpWait100[esi*4]
    cmp  eax, cmpWait100[ecx*4]
    jae  NotBetter
    mov  ecx, esi
NotBetter:
    inc  esi
    jmp  FindBest

PrintRows:
    xor  esi, esi
CmpRow:
    cmp  esi, ALG_COUNT
    jae  CmpFooter
    mov  edx, algNames[esi*4]
    mov  ebx, CMP_COL1
    call WritePaddedStr
    mov  eax, cmpWait100[esi*4]
    mov  ebx, 14
    call WriteFixed2Right
    mov  eax, cmpTurn100[esi*4]
    mov  ebx, 17
    call WriteFixed2Right
    mov  eax, cmpSwitch[esi*4]
    mov  ebx, 11
    call WriteRight
    cmp  esi, ecx
    jne  RowEnd
    mColor CLR_BEST
    mPrint strBestTag
    mColor CLR_DEFAULT
RowEnd:
    call Crlf
    inc  esi
    jmp  CmpRow

CmpFooter:
    mPrintLn strCmpLine
    call Crlf
    mPrint strCmpBest
    mColor CLR_OK
    mov  edx, algNames[ecx*4]
    add  edx, 2
    call WriteString
    mColor CLR_DEFAULT
    call Crlf
    call Crlf
    mPrintLn strCmpNote1
    mPrintLn strCmpNote2
    call Crlf
    call PressAnyKey
    ret
CompareAll ENDP

; Menu option 7
ShowInstructions PROC
    call Clrscr
    mColor CLR_HEAD
    mPrint strHelp
    mColor CLR_DEFAULT
    call Crlf
    call PressAnyKey
    ret
ShowInstructions ENDP

;============================================================
; OUTPUT
;============================================================

; Prints the title banner
ShowBanner PROC
    mColor CLR_TITLE
    mPrintLn strBanLine
    mPrintLn strBan1
    mPrintLn strBan2
    mPrintLn strBanLine
    mColor CLR_DEFAULT
    call Crlf
    ret
ShowBanner ENDP

; Prints the main menu
ShowMenu PROC
    call Clrscr
    call ShowBanner
    mColor CLR_HEAD
    mPrintLn strMenuHead
    mColor CLR_DEFAULT
    mPrintLn strMenu1
    mPrintLn strMenu2
    mPrintLn strMenu3
    mPrintLn strMenu4
    mPrintLn strMenu5
    mPrintLn strMenu6
    mPrintLn strMenu7
    mPrintLn strMenu8
    call Crlf
    call ShowCurrentData
    call Crlf
    ret
ShowMenu ENDP

; Prints the current process data
ShowCurrentData PROC USES eax esi
    mPrint strCurData
    cmp  procCount, 0
    jne  HasData
    mColor CLR_ERROR
    mPrintLn strNoData
    mColor CLR_DEFAULT
    ret
HasData:
    mov  eax, procCount
    call WriteDec
    mPrint strProcsIn
    xor  esi, esi
ShowLoop:
    cmp  esi, procCount
    jae  ShowDone
    mov  eax, esi
    call WriteProcName
    mov  al, '='
    call WriteChar
    mov  eax, burst[esi*4]
    call WriteDec
    mov  al, ' '
    call WriteChar
    inc  esi
    jmp  ShowLoop
ShowDone:
    call Crlf
    ret
ShowCurrentData ENDP

; Result screen. In: EAX = algorithm id
ShowResults PROC USES eax edx
    call Clrscr
    mColor CLR_TITLE
    mov  edx, algTitles[eax*4]
    call WriteString
    call Crlf
    mColor CLR_DEFAULT
    call Crlf

    push eax
    mPrint strInfoProc
    mov  eax, procCount
    call WriteDec
    mPrintLn strInfoArr
    pop  eax
    cmp  eax, ALG_RR
    jne  NoQuantum
    mPrint strInfoQ
    mov  eax, quantum
    call WriteDec
    call Crlf
NoQuantum:
    call Crlf
    call DrawGantt
    call DrawResultTable
    call ShowSummary
    call Crlf
    call PressAnyKey
    ret
ShowResults ENDP

; Draws the Gantt chart, CELLS_PER_ROW cells per row
DrawGantt PROC USES ecx esi edi
    mColor CLR_HEAD
    mPrintLn strGantt
    mColor CLR_DEFAULT
    xor  esi, esi
RowLoop:
    cmp  esi, segCount
    jae  GanttDone
    mov  edi, segCount
    sub  edi, esi
    cmp  edi, CELLS_PER_ROW
    jbe  RowSizeOk
    mov  edi, CELLS_PER_ROW
RowSizeOk:
    mov  ecx, edi
    call GanttBorder
    call GanttLabels
    call GanttBorder
    call GanttTimes
    call Crlf
    add  esi, edi
    jmp  RowLoop
GanttDone:
    ret
DrawGantt ENDP

; Prints "+------+...+". In: ECX = cells
GanttBorder PROC USES ecx
    mPrint strIndent
BorderLoop:
    mPrint strCellTop
    loop BorderLoop
    mPrintLn strPlus
    ret
GanttBorder ENDP

; Prints "|  P1  |...|". In: ESI = first segment, ECX = cells
GanttLabels PROC USES eax ebx ecx
    mPrint strIndent
    mov  ebx, esi
LabelLoop:
    mPrint strCellLeft
    mov  eax, segProc[ebx*4]
    call WriteProcName
    mPrint str2sp
    inc  ebx
    loop LabelLoop
    mPrintLn strBar
    ret
GanttLabels ENDP

; Prints the time line. In: ESI = first segment, ECX = cells
GanttTimes PROC USES eax ebx ecx edx
    mPrint strIndent
    xor  eax, eax
    test esi, esi
    jz   FirstTime
    mov  eax, segEnd[esi*4 - 4]
FirstTime:
    mov  ebx, CELL_WIDTH
    call WriteLeft
    mov  edx, esi
TimeLoop:
    mov  eax, segEnd[edx*4]
    call WriteLeft
    inc  edx
    loop TimeLoop
    call Crlf
    ret
GanttTimes ENDP

; Prints the table of results with totals and averages
DrawResultTable PROC USES eax ebx ecx esi
    mColor CLR_HEAD
    mPrintLn strTblHead
    mColor CLR_DEFAULT
    mPrintLn strTblLine
    xor  esi, esi
TableRow:
    cmp  esi, procCount
    jae  TableTotals
    mPrint strCellP
    mov  eax, esi
    call WriteProcName
    mPrint str3sp
    mov  eax, burst[esi*4]
    mov  ebx, 8
    call WriteRight
    mov  eax, completion[esi*4]
    mov  ebx, 13
    call WriteRight
    mov  eax, waiting[esi*4]
    mov  ebx, 10
    call WriteRight
    mov  eax, turnaround[esi*4]
    mov  ebx, 13
    call WriteRight
    call Crlf
    inc  esi
    jmp  TableRow

TableTotals:
    mPrintLn strTblLine
    mPrint strTotal
    mov  eax, totalBurst
    mov  ebx, 8
    call WriteRight
    mov  ecx, 13
    call WriteSpaces
    mov  eax, totalWait
    mov  ebx, 10
    call WriteRight
    mov  eax, totalTurn
    mov  ebx, 13
    call WriteRight
    call Crlf

    mPrint strAverage
    mov  ecx, 8 + 13
    call WriteSpaces
    mov  eax, avgWait100
    mov  ebx, 10
    call WriteFixed2Right
    mov  eax, avgTurn100
    mov  ebx, 13
    call WriteFixed2Right
    call Crlf
    mPrintLn strTblLine
    ret
DrawResultTable ENDP

; Prints averages, total CPU time and context switches
ShowSummary PROC USES eax ebx
    call Crlf
    mPrint strSumAvgW
    mColor CLR_OK
    mov  eax, avgWait100
    call WriteFixed2
    mColor CLR_DEFAULT
    mPrintLn strUnits

    mPrint strSumAvgT
    mColor CLR_OK
    mov  eax, avgTurn100
    call WriteFixed2
    mColor CLR_DEFAULT
    mPrintLn strUnits

    mPrint strSumTime
    mov  ebx, segCount
    mov  eax, segEnd[ebx*4 - 4]
    call WriteDec
    mPrintLn strUnits

    mPrint strSumSwitch
    mov  eax, segCount
    dec  eax
    call WriteDec
    call Crlf
    ret
ShowSummary ENDP

; Waits for a key and clears any left-over input
PressAnyKey PROC USES eax
    call FlushInput
    mColor CLR_HEAD
    mPrint strPressKey
    mColor CLR_DEFAULT
    call ReadChar
    call FlushInput
    call Crlf
    ret
PressAnyKey ENDP

; Discards pending keyboard input (Win32 API)
FlushInput PROC USES eax ecx edx
    INVOKE GetStdHandle, STD_INPUT_HANDLE
    INVOKE FlushConsoleInputBuffer, eax
    ret
FlushInput ENDP

;============================================================
; FORMATTING HELPERS
;============================================================

; Prints "P<n>" in the colour of the process. In: EAX = index
WriteProcName PROC USES eax
    push eax
    mov  eax, procColors[eax*4]
    call SetTextColor
    mov  al, 'P'
    call WriteChar
    pop  eax
    inc  eax
    call WriteDec
    mColor CLR_DEFAULT
    ret
WriteProcName ENDP

; In: EAX = value. Out: ECX = number of digits
CountDigits PROC USES eax ebx edx
    xor  ecx, ecx
    mov  ebx, 10
DigitLoop:
    xor  edx, edx
    div  ebx
    inc  ecx
    test eax, eax
    jnz  DigitLoop
    ret
CountDigits ENDP

; Prints ECX spaces
WriteSpaces PROC USES eax ecx
    cmp  ecx, 0
    jle  NoSpaces
    mov  al, ' '
SpaceLoop:
    call WriteChar
    loop SpaceLoop
NoSpaces:
    ret
WriteSpaces ENDP

; Prints EAX right-aligned in a field of EBX characters
WriteRight PROC USES ecx
    call CountDigits
    neg  ecx
    add  ecx, ebx
    call WriteSpaces
    call WriteDec
    ret
WriteRight ENDP

; Prints EAX left-aligned in a field of EBX characters
WriteLeft PROC USES ecx
    call WriteDec
    call CountDigits
    neg  ecx
    add  ecx, ebx
    call WriteSpaces
    ret
WriteLeft ENDP

; Prints EAX / 100 with two decimals (1025 -> 10.25)
WriteFixed2 PROC USES eax ebx edx
    xor  edx, edx
    mov  ebx, 100
    div  ebx                            ; EAX = integer part, EDX = fraction
    call WriteDec
    mov  al, '.'
    call WriteChar
    cmp  edx, 10
    jae  TwoDigits
    mov  al, '0'
    call WriteChar
TwoDigits:
    mov  eax, edx
    call WriteDec
    ret
WriteFixed2 ENDP

; Right-aligned WriteFixed2. In: EAX = value, EBX = width
WriteFixed2Right PROC USES eax ecx edx
    push eax
    xor  edx, edx
    mov  ecx, 100
    div  ecx
    call CountDigits
    add  ecx, 3
    neg  ecx
    add  ecx, ebx
    call WriteSpaces
    pop  eax
    call WriteFixed2
    ret
WriteFixed2Right ENDP

; Prints the string at EDX padded to EBX characters
WritePaddedStr PROC USES eax ecx
    call WriteString
    INVOKE Str_length, edx
    mov  ecx, ebx
    sub  ecx, eax
    call WriteSpaces
    ret
WritePaddedStr ENDP

END main

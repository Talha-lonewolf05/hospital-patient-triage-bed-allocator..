# viva notes in simple roman urdu

## one line project explanation

yeh project hospital emergency room ka simulator hai. patient triage script se aata hai, priority milti hai, scheduler usay bed allocate karta hai, patient process treatment simulate karta hai, aur nurse thread discharge ke baad bed free karti hai.


## group members and contribution

- Muhammad Talha (23F-0511): scheduling, threads, synchronization, semaphores, report finalization, and demo video explanation.
- Abdul Rafay (23F-0591): shell scripts, makefile, process management, fifo/shared-memory ipc, and patient process lifecycle.
- Masooma Mirza (23F-0876): memory allocator, coalescing, fragmentation reporting, paging simulation, testing notes, and readme support.

## important files

- `triage.sh`: input validation aur priority mapping
- `admissions.c`: main process, threads, ipc, scheduling, fork, exec
- `patient_simulator.c`: child process jo treatment sleep karta hai
- `bed_allocator.c`: best-fit, first-fit, worst-fit, coalescing, fragmentation
- `common.h`: shared structs and constants

## fork and execv

scheduler thread patient admit karte waqt `fork()` call karta hai. child process `execv()` se `patient_simulator` program ban jata hai. parent pid active patient table mein save karta hai.

## sigchld

jab child process finish hota hai to parent ko `sigchld` signal milta hai. handler `waitpid(-1, null, wnohang)` use karta hai taake zombie process na bane.

## ipc

- arrivals: `/tmp/triage_fifo`
- discharge: `/tmp/discharge_fifo`
- bed data: posix shared memory `/hospital_bed_shm`

## threads

- receptionist producer hai
- scheduler consumer hai
- nurses discharge handle karti hain
- discharge listener fifo se discharge id read karta hai

## mutex

`bed_lock` shared ward memory ko protect karta hai. agar scheduler allocate kar raha ho aur nurse free kar rahi ho to race condition avoid hoti hai.

## condition variable

jab bed available nahi hota to scheduler `bed_freed_cond` par wait karta hai. nurse bed free karne ke baad broadcast karti hai.

## semaphores

icu semaphore max 4 icu patients allow karta hai. isolation semaphore max 4 isolation patients allow karta hai. queue semaphores bounded producer-consumer pattern show karte hain.

## best-fit

best-fit smallest free partition select karta hai jo patient ke care units ko fit kar sake.

## coalescing

jab patient discharge hota hai to uska partition free hota hai. agar left ya right neighbor bhi free ho to merge kar dete hain.

## fragmentation

external fragmentation formula:

```text
(1 - largest_free_block / total_free_units) * 100
```

## paging

page size 2 units hai. agar patient ko 3 units chahiye to 2 pages use hongay aur 1 unit waste hogi, ye internal fragmentation hai.

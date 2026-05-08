#!/bin/bash
# ============================================================
# project : hospital patient triage and bed allocator
# script  : view_logs.sh
# purpose : show project logs in clean readable format
# usage   : ./scripts/view_logs.sh [schedule|memory|records|runtime|all]
# ============================================================

set -u

mode="${1:-all}"

print_line() {
    printf '%*s\n' 95 '' | tr ' ' '-'
}

show_schedule_log() {
    echo
    echo "schedule log"
    print_line

    if [[ ! -f logs/schedule_log.txt ]]; then
        echo "schedule log not found"
        return
    fi

    grep -E "fcfs simulation|priority scheduling simulation|gantt|average waiting time|average turnaround time" \
        logs/schedule_log.txt

    echo
    print_line
    echo "recent admissions"
    print_line

    printf "%-10s %-12s %-12s %-14s %-14s\n" \
        "patient" "priority" "partition" "type" "wait"

    print_line

    grep "admitted patient=" logs/schedule_log.txt | tail -n 12 | awk '
    {
        patient="";
        priority="";
        partition="";
        type="";
        wait="";

        for(i=1;i<=NF;i++){

            if($i ~ /^patient=/){
                patient=substr($i,9)
            }

            if($i ~ /^priority=/){
                priority=substr($i,10)
            }

            if($i ~ /^partition=/){
                partition=substr($i,11)
            }

            if($i ~ /^type=/){
                type=substr($i,6)
            }

            if($i ~ /^waiting_time=/){
                wait=substr($i,14)
            }
        }

        printf "%-10s %-12s %-12s %-14s %-14s\n",
            patient, priority, partition, type, wait;
    }'
}
show_memory_log() {
    echo
    echo "memory log"
    print_line

    if [[ ! -f logs/memory_log.txt ]]; then
        echo "memory log not found"
        return
    fi

    printf "%-22s %-24s %-10s %-14s %-18s %-10s\n" \
        "time" "event" "free" "largest_free" "fragmentation" "active"

    print_line

    awk '
    {
        time=$1" "$2;
        event="";
        free="";
        largest="";
        frag="";
        active="";

        for(i=3;i<=NF;i++){
            if($i ~ /^event=/){
                event=substr($i,7)
            }

            if($i ~ /^total_free=/){
                free=substr($i,12)
            }

            if($i ~ /^largest_free=/){
                largest=substr($i,14)
            }

            if($i ~ /^external_fragmentation=/){
                frag=substr($i,24)
            }

            if($i ~ /^active_patients=/){
                active=substr($i,17)
            }
        }

        printf "%-22s %-24s %-10s %-14s %-18s %-10s\n", time, event, free, largest, frag, active;
    }' logs/memory_log.txt | head -n 30
}

show_patient_records() {
    echo
    echo "patient records"
    print_line

    if [[ ! -f logs/patient_records.dat ]]; then
        echo "patient records file not found"
        return
    fi

    printf "%-10s %-12s %-14s %-10s %-12s %-10s\n" \
        "event" "patient_id" "name/type" "priority" "bed/part" "pid"

    print_line

    strings logs/patient_records.dat | awk '
    {
        event=$1;
        patient="";
        name="";
        priority="";
        bed="";
        type="";
        pid="";
        partition="";

        for(i=1;i<=NF;i++){
            if($i ~ /^patient=/){
                patient=substr($i,9)
            }

            if($i ~ /^name=/){
                name=substr($i,6)
            }

            if($i ~ /^priority=/){
                priority=substr($i,10)
            }

            if($i ~ /^bed=/){
                bed=substr($i,5)
            }

            if($i ~ /^type=/){
                type=substr($i,6)
            }

            if($i ~ /^pid=/){
                pid=substr($i,5)
            }

            if($i ~ /^partition=/){
                partition=substr($i,11)
            }
        }

        if(event=="admit"){
            printf "%-10s %-12s %-14s %-10s %-12s %-10s\n", event, patient, name, priority, bed, pid;
        } else if(event=="discharge"){
            printf "%-10s %-12s %-14s %-10s %-12s %-10s\n", event, patient, type, "-", partition, "-";
        }
    }' | head -n 30
}

show_runtime_log() {
    echo
    echo "runtime log"
    print_line

    if [[ ! -f logs/hospital_runtime.log ]]; then
        echo "runtime log not found"
        return
    fi

    grep -E "admitted|discharged|nurse|coalescing|fragmentation|page table|semaphore" logs/hospital_runtime.log | tail -n 45
}

case "$mode" in
    schedule)
        show_schedule_log
        ;;
    memory)
        show_memory_log
        ;;
    records)
        show_patient_records
        ;;
    runtime)
        show_runtime_log
        ;;
    all)
        show_schedule_log
        show_memory_log
        show_patient_records
        show_runtime_log
        ;;
    *)
        echo
        echo "usage:"
        echo "  ./scripts/view_logs.sh schedule"
        echo "  ./scripts/view_logs.sh memory"
        echo "  ./scripts/view_logs.sh records"
        echo "  ./scripts/view_logs.sh runtime"
        echo "  ./scripts/view_logs.sh all"
        echo
        exit 1
        ;;
esac

echo

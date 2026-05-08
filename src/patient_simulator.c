#define _POSIX_C_SOURCE 200809L

/*
 * ============================================================
 * project : hospital patient triage and bed allocator
 * file    : patient_simulator.c
 * group   : group xx
 * members : Muhammad Talha (23F-0511), Abdul Rafay (23F-0591),
 *           Masooma Mirza (23F-0876)
 * purpose : patient lifecycle process launched using execv
 * ============================================================
 */

#include "common.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

static int parse_int(const char *text, int fallback)
{
    char *end = NULL;
    long value;

    if (text == NULL) {
        return fallback;
    }

    errno = 0;
    value = strtol(text, &end, 10);

    if (errno != 0 || end == text || *end != '\0') {
        return fallback;
    }

    return (int)value;
}

static int random_between(int low, int high)
{
    int range;

    if (high <= low) {
        return low;
    }

    range = high - low + 1;
    return low + (rand() % range);
}

static int treatment_seconds_for_bed(const char *bed_type)
{
    if (bed_type != NULL && strcmp(bed_type, bed_type_icu) == 0) {
        return random_between(5, 15);
    }

    if (bed_type != NULL && strcmp(bed_type, bed_type_isolation) == 0) {
        return random_between(3, 10);
    }

    return random_between(2, 8);
}

static void sleep_seconds(int seconds)
{
    struct timespec request;
    struct timespec remaining;

    request.tv_sec = seconds;
    request.tv_nsec = 0;

    while (nanosleep(&request, &remaining) == -1 && errno == EINTR) {
        request = remaining;
    }
}

static void inspect_shared_bed(int partition_id)
{
    int shm_fd;
    SharedWardState *ward;
    int i;

    shm_fd = shm_open(shm_name, O_RDONLY, 0666);
    if (shm_fd == -1) {
        printf("patient simulator: shared memory not available for inspection\n");
        return;
    }

    ward = mmap(NULL, sizeof(*ward), PROT_READ, MAP_SHARED, shm_fd, 0);
    close(shm_fd);

    if (ward == MAP_FAILED) {
        printf("patient simulator: shared memory attach failed\n");
        return;
    }

    for (i = 0; i < ward->partition_count; i++) {
        if (ward->partitions[i].partition_id == partition_id) {
            printf("patient simulator: shared bed check -> partition=%d start=%d size=%d type=%s\n",
                   ward->partitions[i].partition_id,
                   ward->partitions[i].start_unit,
                   ward->partitions[i].size,
                   ward->partitions[i].bed_type);
            break;
        }
    }

    munmap(ward, sizeof(*ward));
}

static void notify_discharge(int patient_id)
{
    int fifo_fd;
    char message[64];
    ssize_t bytes_written;

    snprintf(message, sizeof(message), "%d\n", patient_id);

    fifo_fd = open(discharge_fifo_path, O_WRONLY | O_NONBLOCK);
    if (fifo_fd == -1) {
        printf("patient simulator: could not open discharge fifo: %s\n", strerror(errno));
        return;
    }

    bytes_written = write(fifo_fd, message, strlen(message));
    if (bytes_written == -1) {
        printf("patient simulator: discharge write failed: %s\n", strerror(errno));
    }

    close(fifo_fd);
}

int main(int argc, char *argv[])
{
    int patient_id;
    int priority;
    int partition_id;
    int care_units;
    int treatment_seconds;
    const char *bed_type;

    if (argc < 6) {
        fprintf(stderr, "usage: %s <patient_id> <priority> <partition_id> <bed_type> <care_units>\n", argv[0]);
        return 1;
    }

    patient_id = parse_int(argv[1], -1);
    priority = parse_int(argv[2], 5);
    partition_id = parse_int(argv[3], -1);
    bed_type = argv[4];
    care_units = parse_int(argv[5], 1);

    srand((unsigned int)(time(NULL) ^ (unsigned int)getpid()));

    printf("patient %d arrived in simulator | priority=%d | bed=%d | type=%s | care_units=%d\n",
           patient_id,
           priority,
           partition_id,
           bed_type,
           care_units);

    inspect_shared_bed(partition_id);

    treatment_seconds = treatment_seconds_for_bed(bed_type);

    printf("patient %d treatment started for %d seconds\n", patient_id, treatment_seconds);
    fflush(stdout);

    sleep_seconds(treatment_seconds);

    printf("patient %d discharged from %s bed\n", patient_id, bed_type);
    fflush(stdout);

    notify_discharge(patient_id);

    return 0;
}

/*----------------------------------------------------------------*
 *                            Threads                             *
 *----------------------------------------------------------------*/

#include "Spawn.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>
#include "Locks.h"

#include "Region.h"
#include "String.h"

//#define PARALLEL_DEBUG

#ifdef PARALLEL_DEBUG
#define tdebug(s) printf(s);
#define tdebug1(s1,s2) printf(s1,s2);
#define tdebug2(s1,s2,s3) printf(s1,s2,s3);
#else
#define tdebug(s)
#define tdebug1(s1,s2)
#define tdebug2(s1,s2,s3)
#endif

// Region page free-list mutex
pthread_mutex_t rp_freelist_mutex;

pthread_mutex_t self_mutex;

// lock rp_freelist_mutex
void
mutex_lock(int id) {
  if (id == FREELISTMUTEX) {
    pthread_mutex_lock(&rp_freelist_mutex);
  } else {
    printf("mutex_lock: got id %d; supporting only FREELISTMUTEX", id);
    exit(-1);
  }
}

void
mutex_unlock(int id) {
  if (id == FREELISTMUTEX) {
    pthread_mutex_unlock(&rp_freelist_mutex);
  } else {
    printf("mutex_unlock: got id %d; supporting only FREELISTMUTEX", id);
    exit(-1);
  }
}

// Initialize thread handling
void
thread_init_all(void) {
  tdebug("[Entering thread_init_all]\n");
  ThreadInfo* ti = (ThreadInfo*)malloc(sizeof(ThreadInfo));   // ti struct for main thread
  ti->arg = NULL;
  ti->tid = 0;
  ti->top_region = NULL;
  ti->freelist = NULL;
  ti->thread = (pthread_t)NULL;
  ti->retval = NULL;
  ti->joined = 0;
  ti->message[0] = 0;
  pthread_cond_init(&(ti->condition), NULL);
  if(pthread_mutex_init(&(ti->condition_mutex), NULL) != 0) {
    printf("ERROR: thread_init_all: condition_mutex init has failed\n");
    exit(-1);
  }
  pthread_key_create(&threadinfo_key, NULL);
  thread_init(ti);
  if (pthread_mutex_init(&rp_freelist_mutex, NULL) != 0) {
    printf("ERROR: thread_init_all: mutex init has failed\n");
    exit(-1);
  }
  if (pthread_mutex_init(&self_mutex, NULL) != 0) {
    printf("ERROR: thread_init_all: mutex init has failed\n");
    exit(-1);
  }
  tdebug("[Exiting thread_init_all]\n");
}

void send(ThreadInfo* ti, int msg) {
  pthread_mutex_lock(&(ti->condition_mutex));

  if(ti->message[0]) {
    pthread_cond_wait(&(ti->condition), &(ti->condition_mutex));
  }

  convertStringToC((StringDesc*)msg, ti->message, MSG_SIZE, 0);
  pthread_cond_signal(&(ti->condition));

  pthread_mutex_unlock(&(ti->condition_mutex));
}

int recv(Region stringRho, int exn) {
  ThreadInfo* ti = (ThreadInfo*)pthread_getspecific(threadinfo_key);
  pthread_mutex_lock(&(ti->condition_mutex));

  if(!(ti->message[0])) {
    pthread_cond_wait(&(ti->condition), &(ti->condition_mutex));
  }

  int res = (int) convertStringToML(stringRho, ti->message);
  ti->message[0] = 0;
  pthread_cond_signal(&(ti->condition));

  pthread_mutex_unlock(&(ti->condition_mutex));
  return res;
}

/*
 * self
 */
ThreadInfo* self() {
  pthread_mutex_lock(&(self_mutex));
  ThreadInfo* ti = (ThreadInfo*)pthread_getspecific(threadinfo_key);
  pthread_mutex_unlock(&(self_mutex));
  return ti;
}

ThreadInfo*
thread_init(ThreadInfo* ti) {
  tdebug("[Entering thread_init]\n");
  pthread_setspecific(threadinfo_key, ti);
  tdebug("[Exiting thread_init]\n");
  return ti;
}

ThreadInfo*
thread_info(void) {
  tdebug("[Entering thread_info]\n");
  ThreadInfo* ti = (ThreadInfo*)pthread_getspecific(threadinfo_key);
  tdebug("[Exiting thread_info]\n");
  return ti;
}

void
thread_new(void* (*f)(ThreadInfo*), ThreadInfo* ti) {
  int rc;
  tdebug("[Entering thread_new]\n");
  /* Initialize and set thread detached attribute */
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

  rc = pthread_create(&(ti->thread), &attr, (void* (*)(void*))f, (void*)ti);
  if (rc) {
    printf("ERROR; return code from pthread_create() is %d\n", rc);
    exit(-1);
  }
  pthread_attr_destroy(&attr);
  tdebug("[Exiting thread_new]\n");
  return;
}

void *
thread_join(pthread_t t) {
  void *value;
  int rc;
  tdebug("[Entering thread_join]\n");
  rc = pthread_join(t, &value);
  if (rc) {
    printf("ERROR; return code from pthread_join() is %d; EINVAL=%d, ESRCH=%d, EDEADLK=%d\n", rc, EINVAL, ESRCH, EDEADLK);
    exit(-1);
  }
  tdebug2("[Exiting thread_join: completed join with thread %ld having a value of %ld]\n",(long)0,(long)value);
  return value;
}

// append_pages(pages1,pages2) assumes that pages1 is non-empty
Rp *
append_pages(Rp *pages1, Rp *pages2) {
  Rp *tmp = pages1;
  if (tmp == NULL) {
    printf("ERROR: Spawn.c: append_pages; expecting pages\n");
  }
  while ( tmp->n ) {
    tmp = tmp->n;
  }
  tmp->n = pages2;
  return pages1;
}

// thread_get(ti) blocks until the given thread terminates and returns
// the value computed by the thread. The first time thread_get is
// called on a thread, it makes a call to pthread_join and stores the
// thread's return value in the retval field in the supplied ti
// argument (for later retrieval). It is an error to call thread_get
// on a ti value that was not returned by thread_create.
void *
thread_get(ThreadInfo *ti)
{
  if (ti->joined) {      // return without taking the lock if
    return ti->retval;   // ti->joined is true; it is incremental..
  }
  pthread_mutex_lock(&(ti->mutex));  // use a mutex; different threads
  if (ti->joined == 0) {             // may call get on a thread
    ti->retval = thread_join(ti->thread);
    ti->joined = 1;
    if (ti->freelist) {
      // take freelist lock and add pages to global freelist
      LOCK_LOCK(FREELISTMUTEX);
      freelist = append_pages(ti->freelist,freelist);
      LOCK_UNLOCK(FREELISTMUTEX);
      ti->freelist = NULL;
    }
  }
  pthread_mutex_unlock(&(ti->mutex));
  return ti->retval;
}

static int thread_counter;

// thread_create(f,a) spawns a new thread that executes the function
// f, applied to the argument a, and returns a threadinfo struct,
// which can be used for joining the thread and accessing the result
// of the function call.
ThreadInfo *
thread_create(void* (*f)(ThreadInfo*), void* arg)
{
  tdebug("[Entering thread_create]\n");
  ThreadInfo* ti = (ThreadInfo*)malloc(sizeof(ThreadInfo));
  ti->arg = arg;
  ti->retval = NULL;
  ti->joined = 0;
  ti->tid = ++thread_counter;   // atomic?
  ti->top_region = NULL;
  ti->freelist = NULL;
  ti->message[0] = 0;
  pthread_cond_init(&(ti->condition), NULL);
  if(pthread_mutex_init(&(ti->condition_mutex), NULL) != 0) {
    printf("ERROR: thread_create: condition_mutex init has failed\n");
    exit(-1);
  }
  if (pthread_mutex_init(&(ti->mutex), NULL) != 0) {
    printf("ERROR: thread_create: mutex init has failed\n");
    exit(-1);
  }
  thread_new(f,ti);
  tdebug("[Exiting thread_create]\n");
  return ti;
}

void
function_test(void* f) {
  #ifdef PARALLEL_DEBUG
  long int fp = *((long int*)f);
  #endif
  tdebug1("function pointer value: %lx\n", fp);
  return;
}

void
thread_free(ThreadInfo* t) {
  pthread_mutex_destroy(&(t->mutex));
  pthread_detach(t->thread);
  free((void*)t);
}

// TEST CODE

void *BusyWork(ThreadInfo *ti)
{
   int i;
   double result = 0.0;
   long tid = (long)(ti->arg);
   printf("Thread %ld starting...\n",tid);
   for (i=0; i<1000000; i++)
   {
      result = result + sin(i) * tan(i);
   }
   printf("Thread %ld done. Result = %e\n",tid, result);
   pthread_exit(ti->arg);
}

int test_main (int argc, char *argv[])
{
  ThreadInfo* threads[NUM_THREADS];
  long int t;
  for(t=0; t<NUM_THREADS; t++) {
    printf("Main: creating thread %ld\n", t);
    threads[t] = thread_create(BusyWork,(void *)t);
  }
  for(t=0; t<NUM_THREADS; t++) {
    void *value = thread_get(threads[t]);
    thread_free(threads[t]);
    threads[t] = NULL;
    printf("Main: thread %ld returned %ld\n", t, (long)value);
  }
  printf("Main: program completed. Exiting.\n");
  pthread_exit(NULL);
}

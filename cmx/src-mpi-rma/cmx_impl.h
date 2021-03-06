#ifndef CMX_IMPL_H_
#define CMX_IMPL_H_

#include <semaphore.h>

#include <stdio.h>

#include <mpi.h>

#define SHM_NAME_SIZE 20

typedef int cmxInt;


typedef struct {
  MPI_Comm world_comm;
  int rank;
  int size;
} local_state;

typedef struct win_link {
  struct win_link *next;
  struct win_link *prev;
  MPI_Win win;
} win_link_t;

typedef struct group_link {
  struct group_link *next;
  MPI_Comm comm;
  MPI_Group group;
  win_link_t *win_list;
} _cmx_group;

typedef _cmx_group cmx_igroup_t;

typedef struct {
  MPI_Win win;
  MPI_Comm comm;
  cmx_igroup_t *group;
  cmxInt bytes;
  int rank;
  void *buf;
} _cmx_handle;

typedef struct {
  MPI_Request request;
  MPI_Win win;
  int active;
  /* Last element is only needed by the win_flush_local implementation */
  int remote_proc;
} _cmx_request;

typedef cmx_igroup_t* cmx_group_t;

extern local_state l_state;

extern cmx_group_t CMX_GROUP_WORLD;

#define DEBUG 0
#define CMX_STRINGIFY(x) #x
#ifdef NDEBUG
#define CMX_ASSERT(WHAT) ((void) (0))
#else
#define CMX_ASSERT(WHAT) \
  ((WHAT) \
   ? (void) (0) \
   : cmx_assert_fail (CMX_STRINGIFY(WHAT), __FILE__, __LINE__, __func__))
#endif
/* TODO: Problem with this function since cmx_error is defined in cmx.h
 * On the other hand, this function is currently not used */
#endif /* CMX_IMPL_H_ */

/*
#define printf(...) fprintf(stderr, __VA_ARGS__); fflush(stderr)
*/

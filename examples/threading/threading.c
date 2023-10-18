#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
//#define DEBUG_LOG(msg,...)
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    struct thread_data *data = (struct thread_data*)thread_param;
    int rc;

    DEBUG_LOG("waiting %dms before obtaining mutex", data->wait_to_obtain_ms);
    usleep(data->wait_to_obtain_ms * 1000);

    rc = pthread_mutex_lock(data->mutex);
    if (rc != 0)
    {
        ERROR_LOG("pthread_mutex_lock failed with return code %d", rc);
        data->thread_complete_success = false;
    }
    else
    {
        DEBUG_LOG("waiting %dms before releasing mutex", data->wait_to_release_ms);
        usleep(data->wait_to_release_ms * 1000);

        rc = pthread_mutex_unlock(data->mutex);
        if (rc != 0)
        {
            ERROR_LOG("pthread_mutex_unlock failed with return code %d", rc);
            data->thread_complete_success = false;
        }
        else
        {
            data->thread_complete_success = true;
        }
    }
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data *data = malloc(sizeof(struct thread_data));
    int rc;
    if (data == NULL)
    {
        ERROR_LOG("out of memory");
        return false;
    }
    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;
    data->mutex = mutex;
    data->thread_complete_success = false;
    
    rc = pthread_create(thread, NULL, threadfunc, data);
    if (rc != 0)
    {
        ERROR_LOG("pthread_create failed with return code %d", rc);
        return false;
    }
    return true;
}


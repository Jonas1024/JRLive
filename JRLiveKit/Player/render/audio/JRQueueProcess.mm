//
//  JRQueueProcess.m
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import "JRQueueProcess.h"
#import <pthread.h>

#pragma mark - Queue Size   设置队列的长度，不可过长
const int JRCustomQueueSize = 80;
extern int kJRBufferSize;


#pragma mark - Init
JRCustomQueueProcess::JRCustomQueueProcess() {
    m_free_queue = (JRCustomQueue *)malloc(sizeof(struct JRCustomQueue));
    m_work_queue = (JRCustomQueue *)malloc(sizeof(struct JRCustomQueue));
    
    InitQueue(m_free_queue, JRCustomFreeQueue);
    InitQueue(m_work_queue, JRCustomWorkQueue);
    
    for (int i = 0; i < JRCustomQueueSize; i++) {
        JRCustomQueueNode *node = (JRCustomQueueNode *)malloc(sizeof(struct JRCustomQueueNode));
        node->data = malloc(kJRBufferSize);
        memset(node->data, 0, kJRBufferSize);
        node->size = 0;
        node->index= 0;
        node->userData = NULL;
        this->EnQueue(m_free_queue, node);
    }
    
    pthread_mutex_init(&free_queue_mutex, NULL);
    pthread_mutex_init(&work_queue_mutex, NULL);
    
    NSLog(@"Init finish !");
}

void JRCustomQueueProcess::InitQueue(JRCustomQueue *queue, JRCustomQueueType type) {
    if (queue != NULL) {
        queue->type  = type;
        queue->size  = 0;
        queue->front = 0;
        queue->rear  = 0;
    }
}

#pragma mark - Main Operation
void JRCustomQueueProcess::EnQueue(JRCustomQueue *queue, JRCustomQueueNode *node) {
    if (queue == NULL) {
        NSLog(@"current queue is NULL");
        return;
    }
    
    if (node==NULL) {
        NSLog(@"current node is NUL");
        return;
    }
    
    node->next = NULL;
    
    if (JRCustomFreeQueue == queue->type) {
        pthread_mutex_lock(&free_queue_mutex);
        
        if (queue->front == NULL) {
            queue->front = node;
            queue->rear  = node;
        }else {
            /*
             // tail in,head out
             freeQueue->rear->next = node;
             freeQueue->rear = node;
             */
            
            // head in,head out
            node->next = queue->front;
            queue->front = node;
        }
        queue->size += 1;
        NSLog(@"free queue size=%d", queue->size);
        pthread_mutex_unlock(&free_queue_mutex);
    }
    
    if (JRCustomWorkQueue == queue->type) {
        pthread_mutex_lock(&work_queue_mutex);
        //TODO
        static long nodeIndex = 0;
        node->index=(++nodeIndex);
        if (queue->front == NULL) {
            queue->front = node;
            queue->rear  = node;
        }else {
            queue->rear->next   = node;
            queue->rear         = node;
        }
        queue->size += 1;
        NSLog(@"work queue size=%d", queue->size);
        pthread_mutex_unlock(&work_queue_mutex);
    }
}

JRCustomQueueNode* JRCustomQueueProcess::DeQueue(JRCustomQueue *queue) {
    if (queue == NULL) {
        NSLog(@"current queue is NULL");
        return NULL;
    }
    
    const char *type = queue->type == JRCustomWorkQueue ? "work queue" : "free queue";
    pthread_mutex_t *queue_mutex = ((queue->type == JRCustomWorkQueue) ? &work_queue_mutex : &free_queue_mutex);
    JRCustomQueueNode *element = NULL;
    
    pthread_mutex_lock(queue_mutex);
    element = queue->front;
    if(element == NULL) {
        pthread_mutex_unlock(queue_mutex);
        NSLog(@"The node is NULL");
        return NULL;
    }
    
    queue->front = queue->front->next;
    queue->size -= 1;
    pthread_mutex_unlock(queue_mutex);
    
    NSLog(@"type=%s size=%d", type, queue->size);
    return element;
}

void JRCustomQueueProcess::ResetFreeQueue(JRCustomQueue *workQueue, JRCustomQueue *freeQueue) {
    if (workQueue == NULL) {
        NSLog(@"The WorkQueue is NULL");
        return;
    }
    
    if (freeQueue == NULL) {
        NSLog(@"The FreeQueue is NULL");
        return;
    }
    
    int workQueueSize = workQueue->size;
    if (workQueueSize > 0) {
        for (int i = 0; i < workQueueSize; i++) {
            JRCustomQueueNode *node = DeQueue(workQueue);
            node->index = 0;
            node->size = 0;
            memset(node->data, 0, kJRBufferSize);
            EnQueue(freeQueue, node);
        }
    }
    NSLog(@"ResetFreeQueue : The work queue size is %d, free queue size is %d",workQueue->size, freeQueue->size);
}


void JRCustomQueueProcess::ClearJRCustomQueue(JRCustomQueue *queue) {
    while (queue->size) {
        JRCustomQueueNode *node = this->DeQueue(queue);
        this->FreeNode(node);
    }

    NSLog(@"Clear JRCustomQueueProcess queue");
}

void JRCustomQueueProcess::FreeNode(JRCustomQueueNode* node) {
    if(node != NULL){
        free(node->data);
        free(node);
    }
}

int JRCustomQueueProcess::GetQueueSize(JRCustomQueue *queue) {
    pthread_mutex_t *queue_mutex = ((queue->type == JRCustomWorkQueue) ? &work_queue_mutex : &free_queue_mutex);
    int size;
    pthread_mutex_lock(queue_mutex);
    size = queue->size;
    pthread_mutex_unlock(queue_mutex);
    
    return size;
}

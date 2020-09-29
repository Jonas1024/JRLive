//
//  JRQueueProcess.h
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import <Foundation/Foundation.h>

typedef enum {
    JRCustomWorkQueue,
    JRCustomFreeQueue
} JRCustomQueueType;

typedef struct JRCustomQueueNode {
    void    *data;
    size_t  size;  // data size
    long    index;
    void    *userData;
    int64_t pts;
    struct  JRCustomQueueNode *next;
} JRCustomQueueNode;

typedef struct JRCustomQueue {
    int size;
    JRCustomQueueType type;
    JRCustomQueueNode *front;
    JRCustomQueueNode *rear;
} JRCustomQueue;

class JRCustomQueueProcess {
    
private:
    pthread_mutex_t free_queue_mutex;
    pthread_mutex_t work_queue_mutex;
    
public:
    JRCustomQueue *m_free_queue;
    JRCustomQueue *m_work_queue;
    
    JRCustomQueueProcess();
    ~JRCustomQueueProcess();
    
    // Queue Operation
    void InitQueue(JRCustomQueue *queue,
                   JRCustomQueueType type);
    void EnQueue(JRCustomQueue *queue,
                 JRCustomQueueNode *node);
    JRCustomQueueNode *DeQueue(JRCustomQueue *queue);
    void ClearJRCustomQueue(JRCustomQueue *queue);
    void FreeNode(JRCustomQueueNode* node);
    void ResetFreeQueue(JRCustomQueue *workQueue, JRCustomQueue *FreeQueue);
    
    int  GetQueueSize(JRCustomQueue *queue);
};

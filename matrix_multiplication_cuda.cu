#include <cuda.h>
#include <cuda_runtime.h>
#include <random>
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>

void fillMatrix(int* matrix, int N)
{
    for (int i = 0; i < N * N; i++)
    {
        matrix[i] = rand() % 100; // Fill with random numbers between 0 and 99
    }
}

void printMatrix(int* matrix, int N)
{
    for (int i = 0; i < N * N; i++)
    {
        printf("%d ", matrix[i]);
        if ((i + 1) % N == 0)
        {
            printf("\n");
        }
    }
}
__global__ void matrixMul(int* a, int* b, int* c, int N)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    int temp_sum = 0;
    if (row < N && col < N)
    {
        for (int i = 0; i < N; i++)
        {
            temp_sum += a[row * N + i] * b[i * N + col];
        }
        c[row * N + col] = temp_sum;
    }
}

void cpuMatrixMul(int* a, int* b, int* c, int N)
{
    int i, j, k;
    for (i = 0; i < N; i++)
    {
        for (j = 0; j < N; j++)
        {
            int sum = 0;
            for (k = 0; k < N; k++)
            {
                sum += a[i * N + k] * b[k * N + j];
            }
            c[i * N + j] = sum;
        }
    }
}

void checkError(int* A, int* B, int* C, int N)
{
    int i, j, k;
    for (i = 0; i < N; i++)
    {
        for (j = 0; j < N; j++)
        {
            int sum = 0;
            for (k = 0; k < N; k++)
            {
                sum += A[i * N + k] * B[k * N + j];
            }
            if (C[i * N + j] != sum)
            {
                printf("Error at C[%d][%d] = %d\n", i, j, C[i * N + j]);
            }
        }
    }
    printf("Check complete\n");
}

int main()
{
    // Initialize matrices a, b and c on the host and device
    int N = 1024;
    int size = N * N * sizeof(int);
    int* h_a, * h_b, * h_c;
    int* d_a, * d_b, * d_c;

    h_a = (int*)malloc(size);
    h_b = (int*)malloc(size);
    h_c = (int*)malloc(size);

    cudaMalloc(&d_a, size);
    cudaMalloc(&d_b, size);
    cudaMalloc(&d_c, size);

    fillMatrix(h_a, N);
    fillMatrix(h_b, N);

    /*
    printf("Matrix A:\n");
    printMatrix(h_a, N);
    printf("Matrix B:\n");
    printMatrix(h_b, N);
    */

    clock_t start1, end1;
    double cpu_time_used;
    start1 = clock();
    // Perform matrix multiplication on the CPU
    cpuMatrixMul(h_a, h_b, h_c, N);
    end1 = clock();
    cpu_time_used = ((double)(end1 - start1)) / CLOCKS_PER_SEC;
    printf("The elapsed time in cpu was %.2f ms\n", cpu_time_used * 1000);
    checkError(h_a, h_b, h_c, N);

    cudaMemcpy(d_a, h_a, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);

    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((N + threadsPerBlock.x - 1) / threadsPerBlock.x, (N + threadsPerBlock.y - 1) / threadsPerBlock.y);

    // Create CUDA events for timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Record the start event
    cudaEventRecord(start, NULL);

    matrixMul << <numBlocks, threadsPerBlock >> > (d_a, d_b, d_c, N);

    // Record the stop event
    cudaEventRecord(stop, NULL);
    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    printf("The elapsed time in gpu was %.2f ms\n", milliseconds);

    // Copy the result back to the host
    cudaMemcpy(h_c, d_c, size, cudaMemcpyDeviceToHost);

    // Check for errors
    checkError(h_a, h_b, h_c, N);

    /*
    printf("Matrix C:\n");
    printMatrix(h_c, N);
    */

    // Cleanup
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(h_a);
    free(h_b);
    free(h_c);

    return 0;
}

#include <iostream>
#include <vector>
#include <omp.h>
#include <random>
#include <ctime>

void matrix_multiply_with_vecotorized_loop(std::vector<int> &A, std::vector<int> &B, std::vector<int> &C, int N)
{
#pragma omp parallel for collapse(2)
    for (int i = 0; i < N; ++i)
    {
        for (int j = 0; j < N; ++j)
        {
            int sum = 0;
#pragma omp simd reduction(+ : sum)
            for (int k = 0; k < N; ++k)
            {
                sum += A[i * N + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}

void matrix_multiply(std::vector<int> &A, std::vector<int> &B, std::vector<int> &C, int N)
{
    for (int i = 0; i < N; ++i)
    {
        for (int j = 0; j < N; ++j)
        {
            int sum = 0;
            for (int k = 0; k < N; ++k)
            {
                sum += A[i * N + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}

int fillMatrix(std::vector<int> &matrix, int N)
{
    for (int i = 0; i < N * N; i++)
    {
        matrix[i] = rand() % 100; // Fill with random numbers between 0 and 99
    }
    return 0;
}

int main()
{
    const int N = 1024; // Size of matrices

    // Initialize matrices
    std::vector<int> A(N * N);
    std::vector<int> B(N * N);
    fillMatrix(A, N);
    fillMatrix(B, N);
    std::vector<int> C(N * N, 0);

    clock_t start, end;
    double cpu_time_used;
    start = clock();
    // Perform matrix multiplication
    matrix_multiply_with_vecotorized_loop(A, B, C, N);

    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC * 1000;
    std::cout << "Time taken for matrix multiplication with vectorization: " << cpu_time_used << " ms" << std::endl;

    fillMatrix(A, N);
    fillMatrix(B, N);
    start = clock();
    // Perform matrix multiplication
    matrix_multiply(A, B, C, N);

    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC * 1000;
    std::cout << "Time taken for matrix multiplication without vectorization: " << cpu_time_used << " ms" << std::endl;

    return 0;
}

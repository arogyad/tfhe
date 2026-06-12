from typing import List

# will implement NTT for this, currently just for testing tFHE
def poly_mul(p1: List[int], p2: List[int], N: int, q: int) -> List[int]:
    result: List[int] = [0] * N
    
    for i in range(N):
        for j in range(N):
            if i + j >= N:
                result[(i + j) - N] -= (p1[i] * p2[j])
            else:
                result[(i + j)] += (p1[i] * p2[j])
    
    return [result[i] % q for i in range(N)]
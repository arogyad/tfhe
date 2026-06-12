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

def gadget_decomposition(poly: List[int], N: int, base: int, levels: int, q: int) -> List[List[int]]:
    result = [ [ 0 ] * len(poly) for i in range(levels)] 

    for i in range(N):
        t = poly[i]
        for l in reversed(range(levels)):
            result[l][i] = t % base
            t = t // base 
    return result

if __name__ == "__main__":
    poly = [6, 3, 14, 7]
    print(gadget_decomposition(poly, 4, 4, 2, 16))
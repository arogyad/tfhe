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
    return result


def gadget_decomposition(poly: List[int], N: int, base: int, levels: int) -> List[List[int]]:
    result = [ [ 0 ] * N for _ in range(levels)] 

    for i in range(N):
        t = poly[i]
        
        for l in reversed(range(levels)):
            result[l][i] = t % base
            t = t // base 
    return result

def glwe_sub(C1, C2, q: int):
    A1, B1 = C1
    A2, B2 = C2

    A3 = [[(a1 - a2) % q for a1, a2 in zip(p1, p2)] for p1, p2 in zip(A1, A2)]
    B3 = [(b1 - b2) % q for b1, b2 in zip(B1, B2)]

    return (A3, B3)

def glwe_add(C1, C2, q: int):
        A1, B1 = C1
        A2, B2 = C2

        A3 = [[(a1 + a2) % q for a1, a2 in zip(p1, p2)] for p1, p2 in zip(A1, A2)]
        B3 = [(b1 + b2) % q for b1, b2 in zip(B1, B2)]

        return (A3, B3)

def glwe_mul(C, poly, N, q):
    A, B = C
    A_new = [poly_mul(a, poly, N, q) for a in A]
    B_new = poly_mul(B, poly, N, q)
    return (A_new, B_new)

def external_product(C_glwe, C_ggsw, base: int, levels: int, N: int, q: int):
    A, B = C_glwe
    k = len(A)
    
    result = ([[0] * N for _ in range(k)], [0] * N)
    
    for i in range(k):
        decomp_A = gadget_decomposition(A[i], N, base, levels)
        for j in range(levels):
            term = glwe_mul(C_ggsw[i][j], decomp_A[j], N, q)
            result = glwe_add(result, term, q)
            
    decomp_B = gadget_decomposition(B, N, base, levels)
    for j in range(levels):
        term = glwe_mul(C_ggsw[-1][j], decomp_B[j], N, q)
        result = glwe_add(result, term, q)
        
    return result

def cmux(b_ggsw, d1_glwe, d0_glwe, base: int, levels: int, N: int, q: int):
    diff = glwe_sub(d1_glwe, d0_glwe, q)
    
    prod = external_product(diff, b_ggsw, base, levels, N, q)
    
    return glwe_add(prod, d0_glwe, q)

if __name__ == "__main__":
    poly = [27, 0, 0, 0]
    print(gadget_decomposition(poly, 4, 4, 3))
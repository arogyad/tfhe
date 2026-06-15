from typing import List
import random

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

def poly_rotate(poly: List[int], rot: int, N: int, q: int) -> List[int]:
    rot = rot % (2 * N)
    sign = 1
    
    if rot >= N:
        sign = -1
        rot -= N
        
    if rot == 0:
        return [(x * sign) % q for x in poly]
        
    part1 = [(-x * sign) % q for x in poly[-rot:]]
    part2 = [(x * sign) % q for x in poly[:-rot]]
    
    return part1 + part2

# this c is LWE
def modulus_switch(c, N: int, q: int):
    a, b = c
    
    a_ = [round((2 * N * a_i) / q) % (2 * N) for a_i in a]
    b_ = round((2 * N * b) / q) % (2 * N)

    return (a_, b_)

# c is GLWE
def sample_extract(c):
    A, B = c
    N = len(B)
    
    b = B[0]
    
    a = []
    for poly in A:
        a.append(poly[0])
        for j in range(1, N):
            a.append(-poly[N - j])
            
    return (a, b)

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

def glwe_rotate(C, rot: int, N: int, q: int):
    A, B = C
    A_new = [poly_rotate(a, rot, N, q) for a in A]
    B_new = poly_rotate(B, rot, N, q)
    
    return (A_new, B_new)

def blind_rotation(V, a_, b_, s_ggsws, base, levels, N, q):
    V0 = glwe_rotate(V, -b_, N, q)

    for i in range(len(a_)):
        d1 = glwe_rotate(V0, a_[i], N, q)
        d0 = V0

        sel = s_ggsws[i]

        V0 = cmux(sel, d1, d0, base, levels, N, q)
    
    return V0

def generate_ksk(extracted_key, target_key, base, levels, q):
    k_target = len(target_key)
    ksk = []
    
    for s_bit in extracted_key:
        ksk_i = []
        for j in range(1, levels + 1):
            a = [random.randint(0, q - 1) for _ in range(k_target)]
            e = round(random.gauss(0, 1))
            
            gadget_val = round(q / (base ** j))
            message = (s_bit * gadget_val) % q
            
            b = (sum(a[x] * target_key[x] for x in range(k_target)) + e + message) % q
            ksk_i.append((a, b))
            
        ksk.append(ksk_i)
        
    return ksk

def key_switch(LWE_c, KSK, base, levels, q):
    a, b = LWE_c
    k = len(a)
    n_out = len(KSK[0][0][0]) 
    
    a_out = [0] * n_out
    b_out = b
    
    a_scaled = [round((a_i * (base ** levels)) / q) % (base ** levels) for a_i in a]
    decomp_a = gadget_decomposition(a_scaled, k, base, levels)

    for i in range(k):
        for j in range(levels):
            digit = decomp_a[j][i]
            a_ksk, b_ksk = KSK[i][j]
            
            a_out = [(x - digit * y) % q for x, y in zip(a_out, a_ksk)]
            b_out = (b_out - digit * b_ksk) % q
            
    return (a_out, b_out)

if __name__ == "__main__":
    poly = [2, 3, -4, -1]
    print(poly_rotate(poly, -1, 4, 8)) # [3, 4, 7, 6] = [3, -4, -1, -2] mod q
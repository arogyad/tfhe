import numpy as np
import numpy.typing as npt
from const import *

Zq = np.uint32

# [a, b] so size of (n + 1, )
LWE = npt.NDArray[np.uint32]
SecretLWE = npt.NDArray[np.uint32]

# [[A], [B]] where A, B = poly of size N, so size of (2, N)
RLWE = npt.NDArray[np.uint32]
SecretRLWE = npt.NDArray[np.uint32]

# this is for KSK
LeV = npt.NDArray[np.uint32]

# for BSK, size of (k + 1) * l, 2, N), our k = 1, so (2 * l, 2, N)
RGSW = npt.NDArray[np.uint32]

Polynomial = npt.NDArray[np.uint32]

def encrypt_lwe(s: SecretLWE, m: np.uint32) -> LWE:
    a = np.random.randint(0, q, n, dtype=np.uint32)
    e = np.random.normal(0.0, sg_lwe * float(q))
    e = np.round(e).astype(np.int64).astype(np.uint32)
    b = np.dot(s, a) + (delta * m) + e

    return np.append(a, b)

def decrypt_lwe(s: SecretLWE, c: LWE) -> np.ndarray:
    a = c[:-1]
    b = c[-1]
    dm_e = (b - np.dot(a, s))
    return np.uint32(((dm_e + (delta / 2)) // delta) % p)

def add_lwe(c0: LWE, c1: LWE) -> LWE:
    return c0 + c1

def mul_lwe(c0: LWE, const: np.uint32) -> LWE:
    return np.multiply(c0, const)

def poly_rotate(poly: Polynomial, rot: np.int64) -> Polynomial:
    rot = rot % (2 * N) 
    poly = poly.astype(np.int64)
    sign = np.int64(1)

    if rot >= N:
        sign = -1
        rot -= N
    
    if rot == 0:
        return (poly * sign).astype(np.uint32)
    
    first = -sign * poly[-rot:]
    second = sign * poly[:-rot]
    return np.append(first, second).astype(np.uint32)

def rlwe_rotate(C: RLWE, rot: np.int64) -> RLWE:
    A_rot = poly_rotate(C[0], rot)
    B_rot = poly_rotate(C[1], rot)

    return np.vstack((A_rot, B_rot))

# Decomposes a RLWE, which is size (2, N) into (2, L, N)
# The decomposition goes from MSB to LSB, so L = i is decomp at q/B^(i + 1)
# I have to make this function take more than just RLWE so that I can do decomp later on for ksk
def gadget_decomp(C: RLWE) -> np.ndarray:
    shifts = 32 - (np.arange(1, l + 1, dtype=np.uint32) * np.uint32(beta_bits))

    C_expand = np.expand_dims(C, 1) # (2, 1, N)
    shifts = shifts.reshape(1, l, 1) # (1, l, 1)

    mask = B - np.uint32(1)
    C_decomposed = ((C_expand >> shifts) & mask).astype(np.int64)
    half_B = np.int64(B // 2)

    for i in range(l - 1, 0, -1):
        carry = ( C_decomposed[:, i, :] >= half_B ).astype(np.int64)
        C_decomposed[:, i, :] -= carry * np.int64(B)
        C_decomposed[:, i - 1, :] += carry

    carry = ( C_decomposed[:, 0, :] >= half_B ).astype(np.int64)
    C_decomposed[:, 0, :] -= carry * np.int64(B)

    return C_decomposed

# I could simplify the above decomposition to use this but I think the above one is faster for the given dimension
def gadget_decomp_1d(val: np.ndarray) -> np.ndarray:
    shifts = 32 - (np.arange(1, k_levels + 1, dtype=np.uint32) * np.uint32(k_base_bits))

    shifts = shifts.reshape(k_levels, 1) # (l, 1)

    mask = B - np.uint32(1)
    val_decomposed = ((val >> shifts) & mask).astype(np.int64) # (l, 1)
    half_B = np.int64(B // 2)

    for i in range(k_levels - 1, 0, -1):
        carry = ( val_decomposed[i] >= half_B ).astype(np.int64)
        val_decomposed[i] -= carry * np.int64(B)
        val_decomposed[i - 1] += carry

    carry = ( val_decomposed[0] >= half_B ).astype(np.int64)
    val_decomposed[0] -= carry * np.int64(B)

    return val_decomposed

# this generates the BSK by encrypting each bit in s with s_rlwe
def generate_bsk(s: SecretLWE, s_rlwe: SecretRLWE) -> RGSW:
    s_rlwe_ftt = np.fft.fft(s_rlwe * twst)
    shifts = 32 - (np.arange(1, l + 1, dtype=np.uint32) * np.uint32(beta_bits))
    g = np.uint32(1) << shifts

    # we have n 0, 1 in s, and each of this is decomposed into a GGSW that is of size (2 * l, 2, N)
    # this is done in the same way as the SoK book by calculating Z + m . transpose(G)
    bsk = np.zeros((n, 2 * l, 2, N))
    
    for i in range(n):
        # these are the a for [TLWE(0),..,TLWE(0)] which is of size (k + 1) * l our k = 1
        a = np.random.randint(0, int(q), size=(2 * l, N), dtype=np.uint32)
        e = np.random.normal(0.0, sg_rlwe * float(q), size=(2 * l, N))
        e = np.round(e).astype(np.int64).astype(np.uint32)
        
        a_ftt = np.fft.fft(a * twst, axis = 1)
        temp = a_ftt * s_rlwe_ftt
        b = np.round((np.fft.ifft(temp, axis=1) * itwst).real)

        b = b.astype(np.int64).astype(np.uint32) + e

        # m . transpose(G), so adding these G here now
        # we have g = (q/b    0)
        #             (q/b^2  0)
        #             (0    q/b)
        #             (0    q/b^2)
        # when i have k = 1, and l = 2
        # so when i do z + m . g, i am only adding on a till l and for b from l to end
        if s[i]:
            a[:l, 0] += g
            b[l:, 0] += g
        
        bsk[i, :, 0, :] = a
        bsk[i, :, 1, :] = b

    # i am keeping bsk as fft so I can just multiply later in external product, similar to hardware implementation paper
    return np.fft.fft(bsk * twst, axis=-1)

def external_product(c: RLWE, bsk_i: RGSW) -> np.ndarray:
    c_decomp = gadget_decomp(c).reshape(2 * l, 1, N)
    c_decomp_fft = np.fft.fft(c_decomp * twst, axis = -1)

    # this broadcasts the (2 * l, 1, N) across the (2 * l, 2, N) of bsk_i
    # this gives us (2 * l, 2, N) values which are then summed over the levels
    # giving us (2, N), which is the same matrix multiplication as G^-1(c) * C_1 (RGSW)
    product_fft = np.sum(c_decomp_fft * bsk_i, axis=0)
    # have to change this to int64 -> uint32 otherwise I get clipping of -ve values
    return np.round((np.fft.ifft(product_fft, axis = 1) * itwst).real).astype(np.int64).astype(np.uint32)

# c0: acc_{j - 1}
# c1: acc_{j - 1} * X^{a_i}
# sel: rgsw of s_i or bsk[i]
def cmux(c0: RLWE, c1: RLWE, sel: RGSW) -> RLWE:
    sub_rlwe = c1 - c0
    prod = external_product(sub_rlwe, sel)
    return prod + c0

# computing the decryption in the encrypted polynomial power so we rotate to the correct coefficient
def blind_rotation(V: RLWE, C_lwe: LWE, bsk: RGSW) -> RLWE:
    V0 = rlwe_rotate(V, -np.int64(C_lwe[-1]))

    for i in range(n):
        V1 = rlwe_rotate(V0, np.int64(C_lwe[i]))
        V0 = cmux(V0, V1, bsk[i])
    
    return V0

def bootstrap(C_lwe: LWE, V: RLWE, bsk: RGSW) -> LWE:
    # we need to convert the LWE from q -> 2N so
    # we can compute the decryption in the power of polynomial V
    def modulus_switch(C: LWE) -> LWE:
        shift = np.uint32(32 - int(np.log2(2 * N)))
        rounding_bit = np.uint32(1) << (shift - np.uint32(1))
        C_2N = (C + rounding_bit) >> shift
        return C_2N

    # taking B[0] as the b and simpler case for a_{iN+j}
    def sample_extract(C: RLWE) -> LWE:
        A = C[0]
        b = C[1][0]
        a_neg = -(A[1:].astype(np.int64)[::-1])
        a = np.append(A[0].astype(np.int64), a_neg).astype(np.uint32)
        return np.append(a, b)

    C_2N = modulus_switch(C_lwe)
    V_me = blind_rotation(V, C_2N, bsk)

    return sample_extract(V_me)

def generate_ksk(s_rlwe: SecretRLWE, s: SecretLWE) -> LeV:
    # similar to gadget decomp it creates B^-j at different levels
    shifts = 32 - (np.arange(1, k_levels + 1, dtype=np.uint32) * np.uint32(k_base_bits))
    g = np.uint32(1) << shifts

    ksk = np.zeros((N, k_levels, n + 1), dtype=np.uint32)

    # i could do a outer product to calculate this but this is clearer
    for i in range(N):
        for j in range(k_levels):
            a = np.random.randint(0, int(q), size=n, dtype=np.uint32)
            e = np.random.normal(0.0, sg_lwe * float(q))
            e = np.round(e).astype(np.int64).astype(np.uint32)

            # encrypting s_rlwe_i * B^{-j}
            m = s_rlwe[i] * g[j]

            b = np.dot(a, s) + m + e

            ksk[i, j, :-1] = a
            ksk[i, j, -1] = b
    
    # size of [N, k_levels, n + 1]
    return ksk
    
def key_switch(C_lwe: LWE, ksk: LeV) -> LWE:
    c_ = np.zeros(n + 1, dtype=np.uint32)
    c_[-1] = C_lwe[-1] # initializing (0, ..., 0, b)

    a_ = C_lwe[:-1]
    # this gives us (k_levels, N)
    # since I am multiplying each N at k_levels to same level N in ksk
    # I can just reduce the entire sum_{1 -> N} sum_{1 -> k_levels} (a_i)_l ksk[i, j]
    # to matrix multiplication
    a_decomp = gadget_decomp_1d(a_) 
    
    # multiply and then sum over n level
    final_ = np.einsum("ji, ijk -> k", a_decomp, ksk)

    return c_ - final_
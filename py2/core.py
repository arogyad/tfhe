import numpy as np
import numpy.typing as npt
from const import *

Zq = np.uint64

# [a, b] so size of (n + 1, )
LWE = npt.NDArray[np.uint64]
SecretLWE = npt.NDArray[np.uint64]

# [[A], [B]] where A, B = poly of size N, so size of (2, N)
RLWE = npt.NDArray[np.uint64]
SecretRLWE = npt.NDArray[np.uint64]

# this is for KSK
LeV = npt.NDArray[np.uint64]

# for BSK, size of (k + 1) * l, 2, N), our k = 1, so (2 * l, 2, N)
RGSW = npt.NDArray[np.uint64]

Polynomial = npt.NDArray[np.uint64]

def encrypt_lwe(s: SecretLWE, m: np.uint64):
    a = np.random.randint(0, q, n, dtype=np.uint64)
    e = np.random.normal(0.0, sg_lwe * float(q))
    e = np.round(e).astype(np.uint64)
    b = np.dot(s, a) + (delta * m) + e

    return np.append(a, b)

def decrypt_lwe(s: SecretLWE, c: LWE):
    a = c[:-1]
    b = c[-1]
    dm_e = (b - np.dot(a, s))
    return np.uint64(((dm_e + (delta / 2)) // delta) % p)

def add_lwe(c0: LWE, c1: LWE):
    return c0 + c1

def mul_lwe(c0: LWE, const: np.uint64):
    return np.multiply(c0, const)

# Decomposes a RLWE, which is size (2, N) into (2, L, N)
# The decomposition goes from MSB to LSB, so L = i is decomp at q/B^(i + 1)
def gadget_decomp(C: RLWE):
    shifts = 64 - (np.arange(1, l + 1, dtype=np.uint64) * np.uint64(beta_bits))

    C_expand = np.expand_dims(C, 1) # (2, 1, N)
    shifts = shifts.reshape(1, l, 1) # (1, l, 1)

    mask = B - np.uint64(1)
    C_decomposed = ((C_expand >> shifts) & mask).astype(np.int64)
    half_B = np.int64(B // 2)

    for i in range(l - 1, 0, -1):
        carry = ( C_decomposed[:, i, :] >= half_B ).astype(np.int64)
        C_decomposed[:, i, :] -= carry * np.int64(B)
        C_decomposed[:, i - 1, :] += carry

    carry = ( C_decomposed[:, 0, :] >= half_B ).astype(np.int64)
    C_decomposed[:, 0, :] -= carry * np.int64(B)

    return C_decomposed

# this generates the BSK by encrypting each bit in s with s_rlwe
def generate_bsk(s: SecretLWE, s_rlwe: SecretRLWE):
    j_idx = np.arange(N, dtype=np.float64)
    twst = np.exp(-1j * np.pi * j_idx / N) # numpy seems to run ftt for X^{n} - 1, but i need X^{n} + 1
    itwst = np.exp(1j * np.pi * j_idx / N)

    s_rlwe_ftt = np.fft.fft(s_rlwe * twst)
    shifts = 64 - (np.arange(1, l + 1, dtype=np.int64) * np.uint64(beta_bits))
    g = np.uint64(1) << shifts

    # we have n 0, 1 in s, and each of this is decomposed into a GGSW that is of size (2 * l, 2, N)
    # this is done in the same way as the SoK book by calculating Z + m . transpose(G)
    bsk = np.zeros((n, 2 * l, 2, N))
    
    for i in range(n):
        # these are the a for [TLWE(0),..,TLWE(0)] which is of size (k + 1) * l our k = 1
        a = np.random.randint(0, int(q), size=(2 * l, N), dtype=np.uint64)
        e = np.random.normal(0.0, sg_rlwe * float(q), size=(2 * l, N))
        e = np.round(e).astype(np.uint64)
        
        a_ftt = np.fft.fft(a * twst, axis = 1)
        temp = a_ftt * s_rlwe_ftt
        b = np.round((np.fft.ifft(temp, axis=1) * itwst).real).astype(np.uint64) + e

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

    return bsk 

if __name__ == "__main__":
    s = np.random.randint(0, 2, n, dtype=np.uint64)

    # 0
    c0 = encrypt_lwe(s, 0)
    c2 = mul_lwe(c0, np.uint64(1))
    m = decrypt_lwe(s, c2)
    print(m)
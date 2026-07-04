import numpy as np
import warnings
from const import *
from core import *

# the overflow error is very annoying
warnings.filterwarnings("ignore", category=RuntimeWarning)

s = np.random.randint(0, 2, n, dtype=np.uint32)
s_rlwe = np.random.randint(0, 2, N, dtype=np.uint32)
bsk = generate_bsk(s, s_rlwe)
ksk = generate_ksk(s_rlwe, s)

mu_val = np.uint32(1 << 29)
V = np.zeros((2, N), dtype=np.uint32)
# fill all array with mu_val or q/8
V[1, :] = np.uint32(mu_val)

def AND(m1, m2):
    c1 = encrypt_lwe(s, m1)
    c2 = encrypt_lwe(s, m2)
    c_comb = np.zeros_like(c1)

    c_comb[:] = add_lwe(c1, c2)
    c_comb[-1] = c_comb[-1] + np.uint32(5 * mu_val) # -3q/8 == 5q/8

    extracted_lwe = bootstrap(c_comb, V, bsk)
    final_lwe = key_switch(extracted_lwe, ksk)
    # the values come out in -mu or mu, so the left over bit was causing error here
    # so recenter here
    final_lwe[-1] = final_lwe[-1] + mu_val
    return decrypt_lwe(s, final_lwe)

def OR(m1, m2):
    c1 = encrypt_lwe(s, m1)
    c2 = encrypt_lwe(s, m2)
    c_comb = np.zeros_like(c1)

    c_comb[:] = add_lwe(c1, c2)
    c_comb[-1] = c_comb[-1] + np.uint32(7 * mu_val) # -q/8 == 7q/8

    extracted_lwe = bootstrap(c_comb, V, bsk)
    final_lwe = key_switch(extracted_lwe, ksk)
    final_lwe[-1] = final_lwe[-1] + mu_val
    return decrypt_lwe(s, final_lwe)

def NAND(m1, m2):
    c1 = encrypt_lwe(s, m1)
    c2 = encrypt_lwe(s, m2)
    c_comb = np.zeros_like(c1)

    c_comb[:] = c_comb - add_lwe(c1, c2)
    c_comb[-1] = c_comb[-1] + np.uint32(3 * mu_val) # 3q/8

    extracted_lwe = bootstrap(c_comb, V, bsk)
    final_lwe = key_switch(extracted_lwe, ksk)
    final_lwe[-1] = final_lwe[-1] + mu_val
    return decrypt_lwe(s, final_lwe)

if __name__ == "__main__":
    print("AND:")
    print("0 & 0: ", AND(0, 0))
    print("0 & 1: ", AND(0, 1))
    print("1 & 0: ", AND(1, 0))
    print("1 & 1: ", AND(1, 1))

    print("OR:")
    print("0 & 0: ", OR(0, 0))
    print("0 & 1: ", OR(0, 1))
    print("1 & 0: ", OR(1, 0))
    print("1 & 1: ", OR(1, 1))

    print("NAND:")
    print("0 & 0: ", NAND(0, 0))
    print("0 & 1: ", NAND(0, 1))
    print("1 & 0: ", NAND(1, 0))
    print("1 & 1: ", NAND(1, 1))
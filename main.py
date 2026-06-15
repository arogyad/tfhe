from glwe import GLWE
from ggsw import GGSW
from glev import GleV
from lwe import LWE
from helper import *
from bootstrap import bootstrap

def error_0_nobootstrapping():
    q = 64
    t = 4 
    k = 4
    N = 4
    base = 4
    levels = 3

    glwe = GLWE(q, t, k, N)
    glev = GleV(glwe, base, levels)
    ggsw = GGSW(glev)

    S = glwe.key_gen()

    M_glwe = [1, 1, 0, 0]
    M_ggsw = [1, 1, 0, 0]

    C_glwe = glwe.encrypt(S, M_glwe)
    C_ggsw = ggsw.encrypt(S, M_ggsw)

    print(f"With length: {len(C_glwe)}")
    print(f"With length: {len(C_ggsw)}")

    C_result = external_product(C_glwe, C_ggsw, base, levels, N, q)

    # i had fixed error = 0 in this case
    print(glwe.decrypt(S, C_result)) # [1, 2, 1, 0], correct? (1 + x) . (1 + x) = 1 + 2x + x^2

def modulus_switch_test():
    q = 64
    t = 4
    k = 4
    N = 4

    lwe = LWE(q, t, k)
    S = lwe.key_gen()
    m = 2

    c = lwe.encrypt(S, m)
    c_2n = modulus_switch(c, N, q)
    delta = (lwe.delta * (2 * N)) // q
    lwe.delta = delta
    lwe.q = 2 * N
    print(lwe.decrypt(S, c_2n))

# pain to test
def blind_rotation_test():
    def coefficient_vx(delta):
        V_poly = [0, delta, delta, 2*delta, 2*delta, 3*delta, 3*delta, 4*delta]
        masks = [[0] * N for _ in range(k)]
        return (masks, V_poly) 

    q = 4096   
    t = 16 
    k = 4
    N = 8
    base = 8
    levels = 4 # 8^4 = 4096

    lwe = LWE(q, t, k)
    glwe = GLWE(q, t, k, N)
    glev = GleV(glwe, base, levels)
    ggsw = GGSW(glev)

    s = lwe.key_gen()
    s_bk = glwe.key_gen()

    # need to "expand" the bit of the key so that the dimensions match
    s_ggsws = [ggsw.encrypt(s_bk, [bit] + [0]*(N-1)) for bit in s]
    
    c = lwe.encrypt(s, 15)
    a_, b_ = modulus_switch(c, N, q)

    delta = q // t
    V = coefficient_vx(delta)

    Vk = blind_rotation(V, a_, b_, s_ggsws, base, levels, N, q)
    extracted_lwe = sample_extract(Vk)
    
    extracted_key = [coeff for poly in s_bk for coeff in poly]
    
    extracted_a, extracted_b = extracted_lwe
    decrypted_lwe = (extracted_b - sum(a * s for a, s in zip(extracted_a, extracted_key))) % q
    
    print("Decrypted Extracted LWE:", round(decrypted_lwe / delta))

# no keyswitching
def gate_test(m1, m2, const, v = 1):
    q = 4096   
    t = 8
    k = 4
    N = 8      
    base = 8
    levels = 4 
    delta = q // t

    lwe = LWE(q, t, k)
    glwe = GLWE(q, t, k, N)
    glev = GleV(glwe, base, levels)
    ggsw = GGSW(glev)

    s = lwe.key_gen()
    s_bk = glwe.key_gen()
    
    s_ggsws = [ggsw.encrypt(s_bk, [bit] + [0] * ( N - 1 )) for bit in s]
    extracted_key = [coeff for poly in s_bk for coeff in poly]

    c1 = lwe.encrypt(s, m1)
    c2 = lwe.encrypt(s, m2)

    c_comb = lwe.add_cp(lwe.add_cc(c1, c2), const)

    V_poly = [v * delta] * N 
    masks = [[0] * N for _ in range(k)]
    V = (masks, V_poly)

    extracted_lwe = bootstrap(c_comb, V, s_ggsws, base, levels, N, q)

    extracted_a, extracted_b = extracted_lwe
    # cheating here with the extracted_key, will have to implement keyswitching
    decrypted_lwe = (extracted_b - sum(a * sk for a, sk in zip(extracted_a, extracted_key))) % q

    if decrypted_lwe > q // 2:
        decrypted_lwe -= q

    result = round(decrypted_lwe / delta)
        
    print(f"Gate Output for ({m1}, {m2}): {result}")


# with keyswitching
def gate_test_key(m1, m2, const, v = 1):
    q = 4096   
    t = 8
    k = 4
    N = 8      
    base = 8
    levels = 4 
    delta = q // t

    k_base = 2
    k_levels = 8

    lwe = LWE(q, t, k)
    glwe = GLWE(q, t, k, N)
    glev = GleV(glwe, base, levels)
    ggsw = GGSW(glev)

    s = lwe.key_gen()
    s_bk = glwe.key_gen()
    
    s_ggsws = [ggsw.encrypt(s_bk, [bit] + [0] * ( N - 1 )) for bit in s]
    extracted_key = [coeff for poly in s_bk for coeff in poly]
    KSK = generate_ksk(extracted_key, s, k_base, k_levels, q)

    c1 = lwe.encrypt(s, m1)
    c2 = lwe.encrypt(s, m2)

    c_comb = lwe.add_cp(lwe.add_cc(c1, c2), const)

    V_poly = [v * delta] * N 
    masks = [[0] * N for _ in range(k)]
    V = (masks, V_poly)

    extracted_lwe = bootstrap(c_comb, V, s_ggsws, base, levels, N, q)

    final_lwe = key_switch(extracted_lwe, KSK, k_base, k_levels, q)
    result = lwe.decrypt(s, final_lwe)
    print(f"Gate Output for ({m1}, {m2}): {result}")


if __name__ == "__main__":
    and_gate = lambda m1, m2: gate_test_key(m1, m2, -1)
    or_gate = lambda m1, m2: gate_test_key(m1, m2, 1)
    nand_gate = lambda m1, m2: gate_test_key(m1, m2, -1, -1)

    print("AND:")
    and_gate(-1, -1) # -1
    and_gate(-1, 1) # -1
    and_gate(1, -1) # -1
    and_gate(1, 1) # 1 !!

    print("OR:")
    or_gate(-1, -1) # -1
    or_gate(-1, 1) # 1
    or_gate(1, -1) # 1
    or_gate(1, 1) # 1 !!

    print("NAND:")
    nand_gate(-1, -1) # 1
    nand_gate(-1, 1) # 1
    nand_gate(1, -1) # 1
    nand_gate(1, 1) # -1 !!




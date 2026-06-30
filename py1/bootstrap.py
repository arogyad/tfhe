from helper import modulus_switch, blind_rotation, sample_extract

def bootstrap(LWE_c, V_glwe, BK_ggsw, base, levels, N, q):
    a_tilde, b_tilde = modulus_switch(LWE_c, N, q)
    V_rotated = blind_rotation(V_glwe, a_tilde, b_tilde, BK_ggsw, base, levels, N, q)
    LWE_out = sample_extract(V_rotated)
    
    return LWE_out
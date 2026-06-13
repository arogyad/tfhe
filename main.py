from glwe import GLWE
from ggsw import GGSW
from glev import GleV
from helper import *

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


    C_result = external_product(C_glwe, C_ggsw, base, levels, N, q)

    # i had fixed error = 0 in this case
    print(glwe.decrypt(S, C_result)) # [1, 2, 1, 0], correct? (1 + x) . (1 + x) = 1 + 2x + x^2
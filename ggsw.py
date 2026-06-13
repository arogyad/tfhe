from typing import List
from glev import GleV
from helper import poly_mul

class GGSW:
    def __init__(self, glev: GleV):
        self.glev = glev
        self.q = self.glev.glwe.q
        self.k = self.glev.glwe.k
        self.N = self.glev.glwe.N
    
    def encrypt(self, S: List[List[int]], M: List[int]):
        result = []
        for i in range(self.k):
            val = poly_mul([-j for j in S[i]], M, self.N, self.q)
            result.append(self.glev.encrypt(S, val))
            
        result.append(self.glev.encrypt(S, M))
        return result

if __name__ == "__main__":
    from glwe import GLWE
    glwe = GLWE(64, 4, 4, 4)
    glev = GleV(glwe, 4, 2)
    ggsw = GGSW(glev)
    S = glwe.key_gen()
    e = ggsw.encrypt(S, [1, 2, 2, 1])
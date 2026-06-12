from typing import List
from glev import GleV
from helper import poly_mul

class GGSW:
    def __init__(self, glev: GleV):
        self.glev = glev
        self.q = self.glev.glwe.q
    
    def encrypt(self, S: List[List[int]], M: List[int]):
        result = []
        for i in range(len(S)):
            val = poly_mul([-j for j in S[i]], M, len(M), self.q) # taking that q is rough
            result.append(self.glev.encrypt(S, val))
            
        result.append(self.glev.encrypt(S, M))
        return result
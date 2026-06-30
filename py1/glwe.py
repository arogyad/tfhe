import random
from typing import List, Tuple
from helper import *

CipherTextGLWE = Tuple[List[List[int]], List[int]]

class GLWE:
    def __init__(self, q: int, t: int, k: int, N: int):
        self.delta = round(q / t)
        self.q: int = q
        self.t: int = t
        self.k: int = k
        self.N = N
    
    def key_gen(self) -> List[List[int]]:
        return [[random.randint(0, 1) for _ in range(self.N)] for _ in range(self.k)]

    def encrypt(self, S: List[List[int]], M: List[int]) -> CipherTextGLWE:
        A = [[random.randint(0, self.q - 1) for _ in range(self.N)] for _ in range(self.k)]
        E = [round(random.gauss(0, 1)) for _ in range(self.N)]
        # E = [0 for _ in range(self.N)] # during testing w/o bootstrapping

        B = [0] * self.N

        for i in range(self.k):
            as_i = poly_mul(A[i], S[i], self.N, self.q)

            for j in range(self.N):
                B[j] = (B[j] + as_i[j]) % self.q

        for j in range(self.N):
            B[j] = (B[j] + self.delta * M[j] + E[j]) % self.q
        
        return (A, B)
    
    def decrypt(self, S: List[List[int]], C) -> List[int]:
        noisy = list(C[1])

        for i in range(self.k):
            AS_i = poly_mul(C[0][i], S[i], self.N, self.q)
            for j in range(self.N):
                noisy[j] = (noisy[j] - AS_i[j]) % self.q
        
        M = [0] * self.N
        for i in range(self.N):
            if noisy[i] > self.q // 2:
                noisy[i] -= self.q # changing to center orientation
            
            M[i] = round(noisy[i] / self.delta) % self.t
        
        return M


if __name__ == "__main__":
    glwe = GLWE(64, 4, 4, 4)
    S = glwe.key_gen()
    e1 = glwe.encrypt(S, [1, 2, 2, 1])
    print(glwe.decrypt(S, e1))
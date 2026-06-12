from typing import Tuple, List
import random

CipherText = Tuple[List[int], int]
PlainText = int

class LWE:
    def __init__(self, q: int, t: int, k: int):
        self.delta: int = round(q / t)
        self.q: int = q
        self.t: int = t
        self.k: int = k
    
    def key_gen(self) -> List[int]:
        return [random.randint(0, 1) for _ in range(self.k)]
    
    def encrypt(self, S: List[int], m: int) -> CipherText:
        a = [random.randint(0, self.q - 1) for _ in range(self.k)]
        e = round(random.gauss(0, 1))
        b = sum([a[i] * S[i] for i in range(self.k)]) + self.delta * m + e

        return (a, b % self.q) # will have this as bit manipulation later

    def decrypt(self, S: List[int], c: CipherText) -> int:
        a, b = c
        temp = (b - sum(a[i] * S[i] for i in range(self.k))) % self.q

        if temp > (self.q // 2):
            temp -= self.q
        
        return round(temp / self.delta) % self.t

    def add_cc(self, c1: CipherText, c2: CipherText) -> CipherText:
        return ([(c1[0][i] + c2[0][i]) % self.q for i in range(self.k)], (c1[1] + c2[1]) % self.q)

    def add_cp(self, c: CipherText, p: int) -> CipherText:
        return (c[0], (c[1] + self.delta * p) % self.q)

    def mul_cp(self, c: CipherText, p: int) -> CipherText:
        return ([(p * c[0][i]) % self.q for i in range(self.k)], (c[1] * p) % self.q)

if __name__ == "__main__":
    lwe = LWE(64, 4, 4)
    S = lwe.key_gen()
    e1 = lwe.encrypt(S, 1)
    e2 = lwe.encrypt(S, 1)
    e3 = lwe.add(e1, e2)
    print(lwe.decrypt(S, e3))


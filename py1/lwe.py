from typing import Tuple, List
import random

CipherTextLWE = Tuple[List[int], int]
PlainText = int

class LWE:
    def __init__(self, q: int, t: int, k: int):
        self.delta: int = round(q / t)
        self.q: int = q
        self.t: int = t
        self.k: int = k
    
    def key_gen(self) -> List[int]:
        return [random.randint(0, 1) for _ in range(self.k)]
    
    def encrypt(self, S: List[int], m: int) -> CipherTextLWE:
        a = [random.randint(0, self.q - 1) for _ in range(self.k)]
        e = round(random.gauss(0, 0.5))
        b = sum([a[i] * S[i] for i in range(self.k)]) + self.delta * m + e

        return (a, b % self.q) # will have this as bit manipulation later

    def decrypt(self, S: List[int], c: CipherTextLWE) -> int:
        a, b = c
        temp = (b - sum(a[i] * S[i] for i in range(self.k))) % self.q

        if temp > (self.q // 2):
            temp -= self.q
        
        return round(temp / self.delta) % self.t

    # i began with thinking maybe i should implement these functions as static method
    # then i forgot about these declared in class and wrote other mul, sub in helper
    # so this needs to be moved to helper for consistency
    def add_cc(self, c1: CipherTextLWE, c2: CipherTextLWE) -> CipherTextLWE:
        return ([(c1[0][i] + c2[0][i]) % self.q for i in range(self.k)], (c1[1] + c2[1]) % self.q)

    def add_cp(self, c: CipherTextLWE, p: int) -> CipherTextLWE:
        return (c[0], (c[1] + self.delta * p) % self.q)

    def mul_cp(self, c: CipherTextLWE, p: int) -> CipherTextLWE:
        return ([(p * c[0][i]) % self.q for i in range(self.k)], (c[1] * p) % self.q)

if __name__ == "__main__":
    lwe = LWE(64, 4, 4)
    S = lwe.key_gen()
    e1 = lwe.encrypt(S, 1)
    e2 = lwe.encrypt(S, 1)
    e3 = lwe.add(e1, e2)
    print(lwe.decrypt(S, e3))


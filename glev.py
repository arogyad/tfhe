from typing import List
from glwe import GLWE

debug = False

class GleV:
    def __init__(self, glwe: GLWE, base: int, levels: int):
        self.base = base
        self.levels = levels
        self.glwe = glwe
    
    def encrypt(self, S: List[List[int]], M: List[int]):
        result = []
        original_delta = self.glwe.delta
        delta = []

        for l in range(1, self.levels + 1):
            self.glwe.delta = round(self.glwe.q / (self.base ** l))
            delta.append(self.glwe.delta)
            result.append(self.glwe.encrypt(S, M))
            
        self.glwe.delta = original_delta
        return (delta,result) if debug else result
            

if __name__ == "__main__":
    glwe = GLWE(64, 4, 4, 4)
    glev = GleV(glwe, 4, 2)
    S = glwe.key_gen()
    (delta, e1) = glev.encrypt(S, [1, 2, 3, 1])
    for d, c in zip(delta, e1):
        glwe.delta = d
        print(glwe.decrypt(S, c))
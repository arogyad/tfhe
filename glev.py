from typing import List
from glwe import GLWE, CipherText
from helper import gadget_decomposition

class GleV:
    def __init__(self, glwe: GLWE, base: int, levels: int):
        self.base = base
        self.levels = levels
        self.glwe = glwe
    
    def encrypt(self, S: List[List[int]], M: List[int]) -> List[CipherText]:
        result: List[CipherText] = []
        original_delta = self.glwe.delta
        
        for l in range(1, self.levels + 1):
            self.glwe.delta = self.glwe.q // (self.base ** l)
            result.append(self.glwe.encrypt(S, M))
            
        self.glwe.delta = original_delta
        return result 
            

if __name__ == "__main__":
    glwe = GLWE(64, 4, 4, 4)
    glev = GleV(glwe, 4, 4)
    S = glwe.key_gen()
    e1 = glev.encrypt(S, [1, 2, 3, 1])
    print(glwe.decrypt(S, e1[0])) # this test is just for poc, delta just so happens to match with my q / base
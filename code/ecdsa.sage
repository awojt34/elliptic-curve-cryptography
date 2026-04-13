import random
import hashlib 
from sage.all import GF, inverse_mod, mod

class Curve:
    def __init__(self, a, b, p):
        self.p = p
        self.F = GF(p)
        self.a = self.F(a)
        self.b = self.F(b)
        self.inf = "O"

    def dodawanie(self, P, Q):
        if P == self.inf: return Q
        if Q == self.inf: return P
        
        x1, y1 = self.F(P[0]), self.F(P[1])
        x2, y2 = self.F(Q[0]), self.F(Q[1])

        if x1 == x2 and y1 == -y2:
            return self.inf
        
        if P != Q:
            if x1 == x2: return self.inf
            lam = (y2 - y1) / (x2 - x1)
        else:
            if y1 == 0: return self.inf
            lam = (3 * x1**2 + self.a) / (2 * y1)
        
        x3 = lam**2 - x1 - x2
        y3 = lam * (x1 - x3) - y1
        return (x3, y3)

    def punkt_przeciwny(self, P):
        if P == self.inf: return self.inf
        return (self.F(P[0]), -self.F(P[1]))

    def montgomery(self, t, P):
        if t == 0: return self.inf
        if t == 1: return P
        if t < 0: return self.montgomery(-t, self.punkt_przeciwny(P)) 
            
        R0, R1 = self.inf, P
        for bit in bin(int(t))[2:]:  
            if bit == '0':
                R1 = self.dodawanie(R0, R1)
                R0 = self.dodawanie(R0, R0)
            else:
                R0 = self.dodawanie(R0, R1)
                R1 = self.dodawanie(R1, R1)
        return R0


def gen_keys(E, G, r):
    private_key = random.randint(1, (r-1))
    public_key = E.montgomery(private_key, G)
    return private_key, public_key


def sign(E, G, r, message, private_key):
    e_hex = hashlib.sha512(message).hexdigest()
    e = int(e_hex, 16)

    t = 0
    s = 0
    while (t == 0) or (s == 0):
        d = random.randint(2, (r - 2))
        P = E.montgomery(d, G)
        if P == E.inf: 
            continue
        x = int(P[0])
        t = mod(x, r)
        if t == 0:
            continue
        
        try:
            d_inv = inverse_mod(d, r)
            s = (d_inv * (e + private_key * t)) % r
        except ZeroDivisionError:
            continue 
    
    return (int(t), int(s))


def verify(E, G, r, podpis, message, public_key):
    t, s = podpis
    
    if not (1 <= t < r) or not (1 <= s < r):
        print("Błąd: t lub s niepoprawne")
        return False 

    e = int(hashlib.sha512(message).hexdigest(), 16)

    w = inverse_mod(s, r)
    u1 = mod((e*w), r)
    u2 = mod((t*w), r)

    x1 = E.montgomery(u1, G)
    x2 = E.montgomery(u2, public_key)

    X = E.dodawanie(x1, x2)

    if (X == E.inf):
        print("Podpis niepoprawny (punkt w nieskończoności)")
        return False

    v = mod(int(X[0]), r)
    
    if (v == t):
        print("Podpis poprawny")
        return True
    else:
        print("Podpis niepoprawny")
        return False



q = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA703308717D4D9B009BC66842AECDA12AE6A380E62881FF2F2D82C68528AA6056583A48F3",16)
a = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA703308717D4D9B009BC66842AECDA12AE6A380E62881FF2F2D82C68528AA6056583A48F0", 16)
b = int("7CBBBCF9441CFAB76E1890E46884EAE321F70C0BCB4981527897504BEC3E36A62BCDFA2304976540F6450085F2DAE145C22553B465763689180EA2571867423E", 16)
x_G = int("640ECE5C12788717B9C1BA06CBC2A6FEBA85842458C56DDE9DB1758D39C0313D82BA51735CDB3EA499AA77A7D6943A64F7A3F25FE26F06B51BAA2696FA9035DA", 16)
y_G = int("5B534BD595F5AF0FA2C892376C84ACE1BB4E3019B71634C01131159CAE03CEE9D9932184BEEF216BD71DF2DADF86A627306ECFF96DBB8BACE198B61E00F8B332", 16)
G = (x_G, y_G)
r = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA70330870553E5C414CA92619418661197FAC10471DB1D381085DDADDB58796829CA90069", 16)

E = Curve(a, b, q)

m = random.randbytes(64)
print(f"Wylosowana wiadomość (512 bit): {m.hex()}")

k, Q = gen_keys(E, G, r)
print(f"Wygenerowano klucze:\nKlucz prywatny k: {k}\nKlucz publiczny Q: {Q}")

signature = sign(E, G, r, m, k)
print(f"Wygenerowano podpis:\nt={signature[0]}\ns={signature[1]}\n")

# Test a) dane poprawne
print("TEST A: Sprawdzenie weryfikacji dla danych poprawnych")
print("Oczekiwany wynik: poprawny")
result_a = verify(E, G, r, signature, m, Q)

# Test b) niepoprawna wiadomość
print("\nTEST B: Weryfikacja dla innej wiadomości")
false_m = random.randbytes(64) 
print(f"Nowa wiadomość: {false_m.hex()}")
print("Oczekiwany wynik: niepoprawny")
result_b = verify(E, G, r, signature, false_m, Q)

# Test c) Niepoprawny podpis
print("\nTEST C: Weryfikacja podpisu ze zmieniona wartością t")
false_signature = ((signature[0] + 23) % r, signature[1])
print(f"Oryginalne t: {signature[0]}")
print(f"Zmienione t: {false_signature[0]}")
print("Oczekiwany wynik: niepoprawny")
result_c = verify(E, G, r, false_signature, m, Q)

# Test d) Niepoprawny klucz publiczny
print("\nTEST D: Weryfikacja złym kluczem publicznym")
false_k, false_Q = gen_keys(E, G, r)
print(f"Poprzedni klucz publiczany: {Q}")
print(f"Nowy klucz publiczny: {false_Q}")
print("Oczekiwany wynik: niepoprawny")
result_d = verify(E, G, r, signature, m, false_Q)

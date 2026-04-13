import random
import hashlib
import hmac
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

def verify_silent(E, G, r, podpis, message, public_key):
    t, s = podpis
    
    if not (1 <= t < r) or not (1 <= s < r):
        return False
    e = int(hashlib.sha512(message).hexdigest(), 16)
    w = inverse_mod(s, r)
    u1 = mod((e*w), r)
    u2 = mod((t*w), r)
    x1 = E.montgomery(u1, G)
    x2 = E.montgomery(u2, public_key)
    X = E.dodawanie(x1, x2)
    if (X == E.inf):
        return False
    v = mod(int(X[0]), r)
    
    return (v == t)

def point_to_bytes(point, p):
    if point == "O":
        return b'\x00'
    x = int(point[0])
    y = int(point[1])
    byte_len = (p.bit_length() + 7) // 8
    return x.to_bytes(byte_len, 'big') + y.to_bytes(byte_len, 'big')

def kdf_sha512(shared_secret, salt, key_length):
    key_material = b''
    counter = 1
    
    while len(key_material) < key_length:
        h = hmac.new(salt, shared_secret + counter.to_bytes(4, 'big'), hashlib.sha512)
        key_material += h.digest()
        counter += 1
    
    return key_material[:key_length]

p = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA703308717D4D9B009BC66842AECDA12AE6A380E62881FF2F2D82C68528AA6056583A48F3",16)
a = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA703308717D4D9B009BC66842AECDA12AE6A380E62881FF2F2D82C68528AA6056583A48F0", 16)
b = int("7CBBBCF9441CFAB76E1890E46884EAE321F70C0BCB4981527897504BEC3E36A62BCDFA2304976540F6450085F2DAE145C22553B465763689180EA2571867423E", 16)
x_G = int("640ECE5C12788717B9C1BA06CBC2A6FEBA85842458C56DDE9DB1758D39C0313D82BA51735CDB3EA499AA77A7D6943A64F7A3F25FE26F06B51BAA2696FA9035DA", 16)
y_G = int("5B534BD595F5AF0FA2C892376C84ACE1BB4E3019B71634C01131159CAE03CEE9D9932184BEEF216BD71DF2DADF86A627306ECFF96DBB8BACE198B61E00F8B332", 16)
r = int("AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA70330870553E5C414CA92619418661197FAC10471DB1D381085DDADDB58796829CA90069", 16)

E = Curve(a, b, p)
G = (E.F(x_G), E.F(y_G))

    
def ec_sts_protocol(wypisz=True):
    h, A = gen_keys(E, G, r) 
    h_B, B = gen_keys(E, G, r)  
    
    if wypisz:
        print("Inicjalizacja:")
        print(f"Alice - długoterminowy klucz prywatny h: {h}")
        print(f"Alice - długoterminowy klucz publiczny A: {A}")
        print(f"Bob - długoterminowy klucz prywatny h_B: {h_B}")
        print(f"Bob - długoterminowy klucz publiczny B: {B}")
        print()
    
    d_A = random.randint(2, (r-2))
    R_A = E.montgomery(d_A, G)
    
    if wypisz:
        print("-" * 80)
        print(f"Alice wybiera losowo d_A: {d_A}")
        print(f"Alice oblicza R_A: {R_A}")
        print(f"Alice wysyła do B: R_A")
        print()
        print("-" * 80)
    
    if R_A == E.inf:
        if wypisz:
            print("R_A jest punktem w nieskończoności")
        return False

    d_B = random.randint(2, (r-2))
    R_B = E.montgomery(d_B, G)
    
    if wypisz:
        print(f"Bob wybiera losowo d_B: {d_B}")
        print(f"Bob oblicza R_B: {R_B}")
    
    K_bob = E.montgomery(d_B, R_A)
    shared_secret_bob = point_to_bytes(K_bob, p)
    
    if K_bob == E.inf:
        if wypisz:
            print("K jest punktem w nieskończoności")
        return False
    
    if wypisz:
        print(f"Bob oblicza K = [d_B]R_A: {K_bob}")

    salt = b'EC-STS'
    keys_B = kdf_sha512(shared_secret_bob, salt, 128)
    k1_B = keys_B[:64]
    k2_B = keys_B[64:128]
    
    if wypisz:
        print(f"Bob wyznacza (k1, k2)")
        print(f"  k1: {k1_B.hex()}")
        print(f"  k2: {k2_B.hex()}")

    message_B = point_to_bytes(R_B, p) + point_to_bytes(R_A, p)
    s_B = sign(E, G, r, message_B, h_B)
    sig_bytes_B = str(s_B[0]).encode() + str(s_B[1]).encode()
    t_B = hmac.new(k1_B, sig_bytes_B, hashlib.sha512).digest()
    
    if wypisz:
        print(f"Bob wyznacza podpis s_B : {s_B}")
        print(f"Bob wyznacza MAC t_B: {t_B.hex()}")
        print(f"Bob wysyła do A: B, R_B, s_B, t_B")
        print()

    if R_B == E.inf:
        if wypisz:
            print("R_B jest punktem w nieskończoności!")
        return False
    
    K_alice = E.montgomery(d_A, R_B)
    shared_secret_alice = point_to_bytes(K_alice, p)
    
    if K_alice == E.inf:
        if wypisz:
            print("K jest punktem w nieskończoności!")
        return False
    
    if wypisz:
        print(f"Alice oblicza K = [d_A]R_B: {K_alice}")
    
    keys_A = kdf_sha512(shared_secret_alice, salt, 128)
    k1_A = keys_A[:64]
    k2_A = keys_A[64:128]
    
    if wypisz:
        print(f"Alice wyznacza (k1, k2)")
        print(f"  k1: {k1_A.hex()}")
        print(f"  k2: {k2_A.hex()}")
    
    message_B_verify = point_to_bytes(R_B, p) + point_to_bytes(R_A, p)
    if wypisz:
        s_B_valid = verify(E, G, r, s_B, message_B_verify, B)
    else:
        s_B_valid = verify_silent(E, G, r, s_B, message_B_verify, B)
    
    if not s_B_valid:
        if wypisz:
            print(" niepoprawny podpis s_B")
        return False
    
    sig_bytes_B_check = str(s_B[0]).encode() + str(s_B[1]).encode()
    t_A_verify = hmac.new(k1_A, sig_bytes_B_check, hashlib.sha512).digest()
    
    if wypisz:
        print(f"Alice oblicza t")
        print(f"  Obliczony t: {t_A_verify.hex()}")
        print(f"  Otrzymany t_B: {t_B.hex()}")
    
    if t_A_verify != t_B:
        if wypisz:
            print("t różne od t_B")
        return False
    
    message_A = point_to_bytes(R_A, p) + point_to_bytes(R_B, p)
    s_A = sign(E, G, r, message_A, h)
    sig_bytes_A = str(s_A[0]).encode() + str(s_A[1]).encode()
    t_A = hmac.new(k1_A, sig_bytes_A, hashlib.sha512).digest()
    
    if wypisz:
        print(f"Alice oblicza s_A: {s_A}")
        print(f"Alice oblicza t_A: {t_A.hex()}")
        print(f"Alice wysyła do B: s_A, t_A")
    
    message_A_verify = point_to_bytes(R_A, p) + point_to_bytes(R_B, p)
    if wypisz:
        s_A_valid = verify(E, G, r, s_A, message_A_verify, A)
    else:
        s_A_valid = verify_silent(E, G, r, s_A, message_A_verify, A)
    
    if not s_A_valid:
        if wypisz:
            print("niepoprawny podpis s_A")
        return False
    
    sig_bytes_A_check = str(s_A[0]).encode() + str(s_A[1]).encode()
    t_B_verify = hmac.new(k1_B, sig_bytes_A_check, hashlib.sha512).digest()
    
    if wypisz:
        print(f"Bob oblicza t")
        print(f"  Obliczony t: {t_B_verify.hex()}")
        print(f"  Otrzymany t_A: {t_A.hex()}")
    
    if t_B_verify != t_A:
        if wypisz:
            print("t nierowne t_A")
        return False

    if wypisz:
        print("=" * 80)
        print(f"Alice k2: {k2_A.hex()}")
        print(f"Bob k2:   {k2_B.hex()}")
        print()
        print(f"Klucze zgodne: {k2_A == k2_B}")
        print()
        print(f"Protokół - poprawnie zakończony.")
        print("=" * 80)
        print()
    
    return k2_A == k2_B


def multiple_ec_sts(l=20):
    successes = 0
    
    for i in range(l):
        if ec_sts_protocol(wypisz=False):
            successes += 1
        
    print()
    print("=" * 80)
    print("PODSUMOWANIE")
    print("=" * 80)
    print(f"Liczba przebiegów: {l}")
    print(f"Liczba sukcesów (identyczne klucze k2): {successes}")
    print(f"Liczba niepowodzeń: {l - successes}")
    print("=" * 80)


if __name__ == "__main__":
    print("\nCZĘŚĆ 1: POJEDYNCZY PRZEBIEG PROTOKOŁU EC-STS\n")
    ec_sts_protocol(wypisz=True)
    
    print("\nCZĘŚĆ 2: 20 PRZEBIEGÓW\n")
    multiple_ec_sts(l=20)

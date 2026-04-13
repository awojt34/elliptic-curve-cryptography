import random
from sage.all import GF, factor, crt, Integer, EllipticCurve

#CZĘŚĆ I: Inicjalizacja krzywej i działania na krzywych

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

#CZĘŚĆ II: Algorytm Rho Pollarda 

def znajdz_podgrupe(w, k, E):
    if w == E.inf: return 0
    return int(w[0]) % k

def parametry_poczatkowe(E, G, Q, n, k):
    M, m_s, n_s = [], [], []
    for s in range(k):
        ms = random.randint(1, n-1)
        ns = random.randint(1, n-1)
        Ms = E.dodawanie(E.montgomery(ms, G), E.montgomery(ns, Q))
        m_s.append(ms); n_s.append(ns); M.append(Ms)
    return M, m_s, n_s

def funkcja_phi(w, m, n, E, k, M, m_s, n_s, q):
    v = znajdz_podgrupe(w, k, E)
    w_nowy = E.dodawanie(w, M[v])
    m_nowy = (m + m_s[v]) % q
    n_nowy = (n + n_s[v]) % q
    return w_nowy, m_nowy, n_nowy

def metoda_pollarda(E, G, Q, q, k):
    M, m_s, n_s = parametry_poczatkowe(E, G, Q, q, k)
    
    m = random.randint(1, q-1)
    n = random.randint(1, q-1)
    m_i, n_i = m, n
    
    x = E.dodawanie(E.montgomery(m, G), E.montgomery(n, Q))
    y = x
    
    iteracja = 0
    while True:
        iteracja += 1
        x, m, n = funkcja_phi(x, m, n, E, k, M, m_s, n_s, q)
        
        y, m_i, n_i = funkcja_phi(y, m_i, n_i, E, k, M, m_s, n_s, q)
        y, m_i, n_i = funkcja_phi(y, m_i, n_i, E, k, M, m_s, n_s, q)

        if x == y:
            delta_m = (m - m_i) % q
            delta_n = (n_i - n) % q
            
            if delta_n == 0:
                continue
            
            else:
                inv_delta_n = pow(delta_n, -1, q)  
                alpha = (delta_m * inv_delta_n) % q
            
            test_Q = E.montgomery(alpha, G)
            if test_Q == Q:
                return alpha, iteracja


#CZĘŚĆ III: Atak Brute force 

def brute_force(E, G, Q, limit):
    if Q == E.inf: return 0 
    temp = G
    if  temp == Q: return 1
    for k in range(2, limit + 2):
        temp = E.dodawanie(temp, G)
        if  temp == Q: return k
    return None


# CZĘŚĆ IV: Metoda Pohliga-Hellmana 

def pohlig_hellman(E, G, Q, group_order, limit_brute_force=200):
    factors = list(factor(group_order))
    podgrupy_wyniki = []
    podgrupy_rzad = []
    
    for p, s in factors:
        p = int(p)
        s = int(s)
        p_s = p**s
        x_i = 0
        Gi = E.montgomery(group_order // p, G) 
        Q_current = Q 
        
        for k in range(s): 
            exponent = group_order // (p**(k+1))
            H = E.montgomery(exponent, Q_current)
            
            if p <= limit_brute_force:
                z_k = brute_force(E, Gi, H, p)
            else:
                w_k = metoda_pollarda(E, Gi, H, p, k=10)
                z_k = w_k[0]
                           
            temp = z_k * (p**k)
            x_i = x_i + temp
            
            S = E.montgomery(x_i, G)
            Q_current = E.dodawanie(Q, E.punkt_przeciwny(S)) 
            
        podgrupy_wyniki.append(Integer(x_i))
        podgrupy_rzad.append(Integer(p_s))
        print(f"Podgrupa rzędu {p}^{s} ({p_s}): {x_i}")

    print("Układ kongruencji:")
    for reszta, modul in zip(podgrupy_wyniki, podgrupy_rzad):
        print(f"  x ≡ {reszta} (mod {modul})")
        
    return crt(podgrupy_wyniki, podgrupy_rzad)


def main():
    test_cases = [
        { "id": 1, "p": 18446744073709551557, "a": 10360570120156452726, "b": 13472007041981648858, "order": 18446744071287940408 },
        { "id": 2, "p": 18446744073709551557, "a": 10637060820562282868, "b": 15336594976413292011, "order": 18446744073413935025 },
        { "id": 3, "p": 18446744073709551557, "a": 10143809665884772522, "b": 3372321031220716306, "order": 18446744073682524600 },
        { "id": 4, "p": 18446744073709551557, "a": 14598031033956693498, "b": 15798886845080940012, "order": 18446744079817311160 },
        { "id": 5, "p": 18446744073709551557, "a": 10918554872137618913, "b": 2876897266513471570, "order": 18446744071319512130 },
        { "id": 6, "p": 79228162514264337593543950319, "a": 25145737178062423098272190510, "b": 13049641691491044446381039410, "order": 79228162514264450131434645206 },
        { "id": 7, "p": 79228162514264337593543950319, "a": 54909290900704502549451797336, "b": 70800022451506523466401415295, "order": 79228162514264830965150388024 }
    ]

    for case in test_cases:
        p = case['p']
        a = case['a']
        b = case['b']
        n_curve = case['order'] 
        
        print(f"KRZYWA {case['id']}")
        
        E_sage = EllipticCurve(GF(p), [a, b])
        

        generators = E_sage.gens()
        G_sage = max(generators, key=lambda g: g.order())
        
        G_order = Integer(G_sage.order())
        G = (Integer(G_sage[0]), Integer(G_sage[1]))
        E = Curve(a, b, p)
            
        print(f"Generator G = {G}")
        print(f"Rząd punktu G = {G_order}")
        
        alpha_secret = random.randint(2, n_curve - 2)
        print(f"Wylosowana wartość alfa: {alpha_secret}")

        Q = E.montgomery(alpha_secret, G)
        
        alpha_recovered = pohlig_hellman(E, G, Q, G_order, limit_brute_force=200)
        
        print(f"Odzyskane alfa (mod G_order): {alpha_recovered}")
        

        Q_check = E.montgomery(alpha_recovered, G)
        
        if Q_check == Q:
            print("WYNIK POPRAWNY")
        else:
            print("BŁĄD")
        
        print("-" * 50)

if __name__ == "__main__":
    main()

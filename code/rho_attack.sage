import random
from sage.all import GF

class Curve:
    def __init__(self, a, b, p):
        self.p = p
        self.F = GF(p)
        self.a = self.F(a)
        self.b = self.F(b)
        self.inf = "O"
    
    def dodawanie(self, P, Q):
        if P == self.inf:
            return Q
        if Q == self.inf:  
            return P
        
        x1 = self.F(P[0])
        y1 = self.F(P[1])
        x2 = self.F(Q[0])
        y2 = self.F(Q[1])

        if x1 == x2 and y1 == -y2:
            return self.inf
        
        if P != Q:
            lam = (y2 - y1) / (x2 - x1)
        else:
            lam = (3 * x1**2 + self.a) / (2 * y1)
        
        x3 = lam**2 - x1 - x2
        y3 = lam * (x1 - x3) - y1
        
        return (x3, y3)
    
    def punkt_przeciwny(self, P):
        if P == self.inf:
            return self.inf
        x = self.F(P[0])
        y = self.F(P[1])
        return (x, -y)
    
    def montgomery(self, t, P):
        if t == 0:
            return self.inf
        if t == 1:
            return P
        
        R0 = self.inf
        R1 = P
        
        for bit in bin(t)[2:]:  
            if bit == '0':
                R1 = self.dodawanie(R0, R1)
                R0 = self.dodawanie(R0, R0)
            else:
                R0 = self.dodawanie(R0, R1)
                R1 = self.dodawanie(R1, R1)
        
        return R0


def znajdz_podgrupe(w, k, E):
    if w == E.inf:
        return 0
    else:
        w_x = int(w[0])  
        return w_x % k


def parametry_poczatkowe(E, G, Q, n, k):
    M = []      
    m_s = [] 
    n_s = [] 
    
    for s in range(k):
        ms = random.randint(1, n-1)
        ns = random.randint(1, n-1)
        
        Ms = E.dodawanie(E.montgomery(ms, G), E.montgomery(ns, Q))
        
        m_s.append(ms)
        n_s.append(ns)
        M.append(Ms)
    
    return M, m_s, n_s


def funkcja_phi(w, m, n, E, k, M, m_s, n_s, q):
    v = znajdz_podgrupe(w, k, E)
    
    M_v = M[v]
    m_v = m_s[v]
    n_v = n_s[v]
    
    w_nowy = E.dodawanie(w, M_v)
    
    m_nowy = (m + m_v) % q
    n_nowy = (n + n_v) % q
    
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


def test(a, b, p, G, G_order):
    E = Curve(a, b, p)
    s_alpha = (random.randint(2, G_order - 2)) 
    print(f"\nWylosowano {s_alpha} jako rozwiązanie logarytmu log_G(Q).")
    Q = E.montgomery(s_alpha, G)

    wynik, iteracje = metoda_pollarda(E, G, Q, G_order, k=10)
    
    if wynik is not None:
        print(f"Znaleziono kolizje po {iteracje} iteracjach.")
        print(f"Znaleziono: α = {wynik}")
        if wynik == s_alpha:
            print(f"Wynik poprawny.")
            return True
        else:
            print(f"Błędny wynik.")
            return False
    else:
        print(f"\nNie znaleziono rozwiązania po {iteracje} iteracjach.")
        return False


def test_wyswietlanie():
    krzywe = [
        {
            "p": 1073741789,
            "a": 382183198,
            "b": 410736703,
            "G": (431583365, 858920426),
            "order_G": 1073759053
        },
        {
            "p": 1099511627689,
            "a": 937626108435,
            "b": 666042130277,
            "G": (30009621022, 215563891949),
            "order_G": 1099512159103
        }
        ]
    
    for i, param in enumerate(krzywe, 1):
        print(f"\nTest {i}")
        print(f"Parametry krzywej:")
        print(f"p = {param['p']}")
        print(f"a = {param['a']}")
        print(f"b = {param['b']}")
        print(f"G = {param['G']}")
        print(f"rząd G = {param['order_G']}")
        a, b, p, G, G_order = param["a"], param["b"], param["p"], param["G"], param["order_G"]
        test(a, b, p, G, G_order)


def main():
    print("Algorytm Rho-Pollarda przeprowadzono dla dwóch krzywych eliptycznych")
    print("_" * 70)
    test_wyswietlanie()


if __name__ == "__main__":
    main()

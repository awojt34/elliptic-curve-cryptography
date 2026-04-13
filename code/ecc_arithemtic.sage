
class Curve:
    def __init__(self, a, b, p):
        self.p = p
        self.F = GF(p)
        self.a = self.F(a)
        self.b = self.F(b)
        self.inf = "O"
	
	#Zadanie 1: implementacja dodawania punktów
    def dodawanie(self, P, Q):
        if P == self.inf:
            return Q
        if Q == self.inf:  
            return P
        
        x1 = self.F(P[0]) if not isinstance(P, Punkt) else P.x
        y1 = self.F(P[1]) if not isinstance(P, Punkt) else P.y
        x2 = self.F(Q[0]) if not isinstance(Q, Punkt) else Q.x
        y2 = self.F(Q[1]) if not isinstance(Q, Punkt) else Q.y

        if x1 == x2 and y1 == -y2:
            return self.inf
        
        if P != Q:
            lam = (y2 - y1) / (x2 - x1)
        else:
            lam = (3 * x1**2 + self.a) / (2 * y1)
        
        x3 = lam**2 - x1 - x2
        y3 = lam * (x1 - x3) - y1
        
        return (x3, y3)
    
	#Funkcja pomocnicza do zrealizowania arytmetyki dla krzywych
    def punkt_przeciwny(self, P):
        if P == self.inf:
            return self.inf
        x = self.F(P[0]) if not isinstance(P, Punkt) else P.x
        y = self.F(P[1]) if not isinstance(P, Punkt) else P.y
        return (x, -y)
    
	#Zadanie 2: Implementacja liczenia krotności punktu
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
	
	#Zadanie 3: Wykonanie testów dla t=10 dla liczenia krotności punktów oraz sprawdzenie przypadku granicznego (dla wyniku = punktowi w nieskończoności)
    def test(self, G, order_G):
        poprawne = 0
        print(f"Generator: G = ({G[0]}, {G[1]})")
        print(f"Rząd generatora: #G = {order_G}")

        print("\nTest 1: Obliczenie losowych krotności [s]G")
        t = 10

        for i in range(t):
            s = randint(2, order_G - 2)
            implementacja = self.montgomery(s, G)
            
            E_sage = EllipticCurve(self.F, [self.a, self.b])
            G_sage = E_sage(G[0], G[1])
            sage_wynik = s * G_sage
            sage_wspolrzedne = (sage_wynik[0], sage_wynik[1])
            
            if implementacja == self.inf:
                implementacja_print = "O"
                sage_print = "O" if sage_wynik == E_sage(0) else f"({sage_wspolrzedne[0]}, {sage_wspolrzedne[1]})"
            else:
                implementacja_print = f"({int(implementacja[0])}, {int(implementacja[1])})"
                sage_print = f"({int(sage_wspolrzedne[0])}, {int(sage_wspolrzedne[1])})"
            
            zgodnosc = implementacja == sage_wspolrzedne or (implementacja == self.inf and sage_wynik == E_sage(0))
            
            print(f"Krotnosc ([{s}]G)")
            print(f"Implementacja: {implementacja_print}")
            print(f"Sage:          {sage_print}")
            
            if zgodnosc:
                poprawne += 1
        
        print(f"Wynik: {poprawne}/{t} poprawnych")
        
        print("\nTest 2: Obliczenie [#<G>]G == 'O'")
        wynik_order = self.montgomery(order_G, G)
        
        E_sage = EllipticCurve(self.F, [self.a, self.b])
        G_sage = E_sage(G[0], G[1])
        sage_order = order_G * G_sage
        
        print(f"Implementacja: {'O' if wynik_order == self.inf else wynik_order}")
        print(f"Sage:          {'O' if sage_order == E_sage(0) else sage_order}")
        print(f"Poprawność: {'spelnione' if wynik_order == self.inf else 'nie spelnione'}")
        
        return poprawne == t and wynik_order == self.inf
    
	#Sprawdzenie poprawności zaimplementowanego dodawania punktów z funkcjami wbudowanymi 
    def test_dodawania(self, P, Q):
        
        dodawanie_implementacja = self.dodawanie(P, Q)
        print(f"Wynik dodawania przy pomocy implementacji = {dodawanie_implementacja}")
        
        E_sage = EllipticCurve(self.F, [self.a, self.b])
        P_sage = E_sage(P[0], P[1])
        Q_sage = E_sage(Q[0], Q[1])
        dodawanie_sage = P_sage + Q_sage
        print(f"Wynik dodawania przy pomocy wbudowanych funkcji SAGE = {dodawanie_sage}")
           

#Klasa Punkt - własna reprezentacja punktu na krzywej 
class Punkt:
    def __init__(self, curve, P):
        self.curve = curve
        if P == "O":
            self.x = None
            self.y = None
            self.inf = True
        else:
            x, y = P
            self.x = curve.F(x)
            self.y = curve.F(y)
            self.inf = False
            
    def __str__(self):
        if self.inf:
            return "O"
        else:
            return f"({int(self.x)}, {int(self.y)})"


def test_wszystkie_krzywe():
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
        },
        {
            "p": 1125899906842597,
            "a": 514617658328474,
            "b": 865963734954572,
            "G": (559300734191994, 352862582522159),
            "order_G": 1125899925928763
        },
        {
            "p": 1152921504606846883,
            "a": 133449192748674296,
            "b": 309339390958398819,
            "G": (71033071733169680, 537574381573531526),
            "order_G": 1152921505819822451
        },
        {
            "p": 1180591620717411303389,
            "a": 984829373352706197321,
            "b": 1172503213559279140726,
            "G": (712933212623311168095, 448008101342349699238),
            "order_G": 1180591620733222285993
        },
        {
            "p": 1208925819614629174706111,
            "a": 225354284526360528563023,
            "b": 3764050222503696695444,
            "G": (296587682754061319950495, 277682525629637456378157),
            "order_G": 1208925819614729757302087
        },
        {
            "p": 1237940039285380274899124191,
            "a": 876614849831021940581906029,
            "b": 57055954074522725758222550,
            "G": (1133011678734820124222260756, 913987897928984057367899527),
            "order_G": 1237940039285432637833556673
        },
        {
            "p": 1267650600228229401496703205361,
            "a": 674423269691373715791761682647,
            "b": 734338331506318254542896260584,
            "G": (1209986394144692376486654159140, 196194362409422914656559162883),
            "order_G": 1267650600228229857210281585449
        }
    ]
    
    wyniki = []

    for i, param in enumerate(krzywe, 1):
        print(f"\nKrzywa {i}")
        print(f"p = {param['p']}")
        print(f"a = {param['a']}")
        print(f"b = {param['b']}")

        E = Curve(param["a"], param["b"], param["p"])
       
        
        sukces = E.test(param["G"], param["order_G"])
        wyniki.append((i, sukces))

    print("\nPodsumowanie wynikow testow")
    
    for i, sukces in wyniki:
        status = "test poprawny" if sukces else "test niepoprawny"
        print(f"Krzywa {i}: {status}")

def test_dodawania_glowny():
    print("\nSprawdzenie poprawnosci dodawania")
    krzywa_test = Curve(6, 7, 11)
    print(f"Krzywa dla sprawdzenia dodawania: y² = x³ + 6x + 7 nad GF(11) ")
    
    punkty = []
    for x in range(13):
        for y in range(13):
            if krzywa_test.F(y)**2 == krzywa_test.F(x)**3 + krzywa_test.a*krzywa_test.F(x) + krzywa_test.b:
                punkty.append((x, y))
    
    print(f"Wszystkie punkty na krzywej: {punkty}")
    
    if len(punkty) >= 2:
        P = punkty[0]
        Q = punkty[3]
        K = punkty[2]
        
        print(f"\nTest 1: Dodawanie różnych punktów")
        print(f"P = {P}")
        print(f"Q = {Q}")
        krzywa_test.test_dodawania(P, Q)
        
        print(f"\nTest 2: Podwojenie punktu")
        print(f"P = {K}")
        krzywa_test.test_dodawania(K, K)
        
        print(f"\nTest 3: Punkt przeciwny")
        print(f"P = {P}")
        minusP = krzywa_test.punkt_przeciwny(P)
        print(f"-P = {minusP}")

if __name__ == "__main__":
    test_dodawania_glowny()
    test_wszystkie_krzywe()
    


# Program przyjmuje na wejsciu parametr p, czyli charakterystyke ciala F podany
# przez uzytkownika (p  rozne od 2 i 3). 
# Klasa izomorfizmu to zbiór wszystkich krzywych eliptycznych izomorficznych z daną krzywą.
# Reprezentant to dowolna krzywa z danej klasy.

p = int(input("Podaj charakterystyke ciala p = "))
F = GF(p)

# Znalezienie krzywych gładkich 
krzywe_gladkie = []
for a in F:
    for b in F:
        if (4 * a**3 + 27 * b**2) != 0:
            krzywe_gladkie.append((a, b))

# Znalezienie klas izomorfizmu
klasy = []
sprawdzone = set() 

# Wybor klasy z F (krzywej), ktora nie zostala jeszcze sprawdzona
for a, b in krzywe_gladkie:
    if (a, b) in sprawdzone:
        continue 
    
    klasa_znaleziona = []

    # Przeszukanie pozostalych niesprawdzonych krzywych        
    for aprim, bprim in krzywe_gladkie:
        if (aprim, bprim) in sprawdzone:
            continue

        # Sprawdzenie izomorfizmu miedzy krzywymi            
        reprezentant = False
        for u in F:
            if u == 0:
                continue
                    
            if u**4 * a == aprim and u**6 * b == bprim:
                reprezentant = True
                break
                    
        if reprezentant:
            klasa_znaleziona.append((aprim, bprim))
            sprawdzone.add((aprim, bprim))
    
    if klasa_znaleziona:
        klasy.append(klasa_znaleziona)

print("\nZnalezione klasy:")
for i, klasa in enumerate(klasy):
    print(f"Klasa {i+1}: {klasa}")

print(f"\nLiczba klas: {len(klasy)}")

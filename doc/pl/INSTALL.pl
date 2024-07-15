openarmor HIDS 0.8
Copyright (c) 2004-2006 Daniel B. Cid  	<daniel.cid@gmail.com>
		                        <dcid@theopenarmor.org>


= Informacje o openarmor HIDS =

Zobacz http://www.theopenarmor.org


= Zalecana instalacja =

Instalacja openarmor HIDS jest bardzo prosta. Może być przeprowadzona
w szybki sposób (przy użyciu skryptu install.sh z domyślnymi
wartościami) lub dostosowana do użytkownika (ręcznie lub poprzez
zmianę domyślnych wartości w skrypcie install.sh). POLECAM KAŻDEMU
używanie SZYBKIEGO SPOSOBU! Tylko developerzy i zaawansowani
użytkownicy powinni używać innych metod.

Kroki szybkiego sposobu:

1- Uruchom skrypt ./install.sh. Poprowadzi Cie on przez proces
   instalacji.

2- Skrypt zainstaluje wszystko do katalogu /var/openarmor oraz
   spróbuje stworzyć w systemie skrypt inicjujący (w katalogu
   /etc/rc.local lub /etc/rc.d/init.d/openarmor). Jeśli skrypt nie
   zostanie utworzony, można postępując zgodnie z instrukcjami
   z install.sh spowodować uruchamianie openarmor HIDS podczas
   startu systemu. Aby wystartować ręcznie wystarczy uruchomić
   /var/openarmor/bin/openarmor-control start

3- Jeśli zamierzasz używać kilku klientów, powinieneś najpierw
   zainstalowac serwer. Do stworzenia odpowiednich kluczy użyj
   narzędzia manage_agents.

4- Miłego użytkowania.


= Instalacja i uruchmienie (99,99% powinieneś przeczytać POWYŻEJ) =


Kroki ręcznej instalacji:

1- Utwórz potrzebne katalogi (domyślnie /var/openarmor).
2- Przenieś odpowiednie pliki do katalogu openarmor.
3- Skompiluj wszystko.
4- Przenieś binaria do katalodu domyślnego.
5- Dodaj odpowiednich użytkowników.
6- Ustaw odpowiednie prawa dla plików.


Powyższe 5 (bez 5) kroków jest wykonywane w Makefile (zobasz make server).

Makefile czyta opcje z pliku LOCATION. Możesz w nim zmienić 
wszystko co potrzebujesz.

Aby skompilować wszystko samemu:

	% make clean
	% make all (step 3)
	% su
	# make server (odpowiada za kroki 1,2,4 oraz 6)

*Przed uruchomieniem make server, upewnij się, że masz utworzonych
odpowiednich użytkowników. Makefile nie utworzy ich.

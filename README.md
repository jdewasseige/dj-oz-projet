Projet DJ' Oz 
=============

Projet d'informatique dans le cadre du cours FSAB1402 à l'[EPL](http://www.uclouvain.be/epl.html). 

Le projet consiste à écrire deux fonctions dans le langage [Oz](https://en.wikipedia.org/wiki/Oz_(programming_language)). 
L’une sera capable de transformer une partition musicale en un fichier audio et 
l’autre de mixer et transformer une ou plusieurs musiques.

TO DO :
-------
Reminder :
* \’
* mettre un signe à coté des commentaires qu'on doit supprimer
* ne pas oublier de vérifier que les fonctions déclarées dans code.oz correspondent à celles de interprete et mix (même si cela semble évident)
* vérifier ECHO 
* meilleurs commentaires dans le code
* faire une fonction Duree dans Interprete? (lisibilité)
* meilleurs commentaires dans le code (input output)
* Rapport
* Instruments et/ou effets dans le hobbit
* Tester effets sur le hobbit ou sur joie
* à la fin de MixVoix (et peut-être dans d'autres fonctions), rajouter un else
qui renverrait nil 
* à la fin de MixVoix (et peut-être dans d'autres fonctions), rajouter un else
qui renverrait nil ?
* changer le nom de GivesH en GetHauteur
* instrument : si duree échantillon pas la même que celle du morceau + lissage
* réorganiser le code (GetNote à coté de ToNote) ?

Code :
* Interprete : DONE
* Mix :
	* voix() : Tests
	* merge() : Tests
	* Fondu : Tests hardores DONE
	* Echo : Tests
	* Couper : Tests
	* FonduE : Code + tests DONE
* Extensions
    * Lissage : DONE
    * Instruments
       * Changer l'instrument dans un échantillon :
       * Charger le vecteur audio correspondant à l'instrument et à la note :
       * Couper/Fondu du vecteur audio pour qu'il correspondent à la durée de la note :
    * Créativité OSEF
    * Effets complexes OSEF
* Partition Lord of the Rings OU Let It Go DONE
* Perfectionnisme :
	* Asserts DONE
	* Robustesse float int
	* Variables globales beauté lisibilité COMPRIS (environnement contextuel) (voir Fondu et FonduE)
	* Commenter
	* Normes, unifier noms
	* Optimisation



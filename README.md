Projet DJ' Oz 
=============

Projet d'informatique dans le cadre du cours FSAB1402 à l'[EPL](http://www.uclouvain.be/epl.html). 

Le projet consiste à écrire deux fonctions dans le langage [Oz](https://en.wikipedia.org/wiki/Oz_(programming_language)). 
L’une sera capable de transformer une partition musicale en un fichier audio et 
l’autre de mixer et transformer une ou plusieurs musiques.

TO DO dans l’ordre:
-------

* Nettoyer code pour 1ère soumission
	* réorganiser le code (GetNote à coté de ToNote) ?
	* changer le nom de GivesH en GetHauteur
	* à la fin de MixVoix (et peut-être dans d'autres fonctions), rajouter un else
	* meilleurs commentaires dans le code (input output)
	* faire une fonction Duree dans Interprete? (lisibilité)
	* meilleurs commentaires dans le code (input output)
	* Régler les questions mises en commentaire dans le code
qui renverrait nil ?
* 1ère version du rapport
* 1ère soumission

* Tests : tester les effets avec le hobbit et/ou sur joie (surtt écho, couper et merge)
* Improve Hobbit :
	* Effets
	* Instruments
	* Note trop haute ?
	* Mixer hobbit
* Improve Rapport
* instrument : si duree échantillon pas la même que celle du morceau + lissage
* 2ème soumission

* Perfectionnisme :
	* Asserts
	* Robustesse float int
	* Variables globales beauté lisibilité (environnement contextuel) (voir Fondu et FonduE)
	* Commenter mieux
	* Normes, unifier noms
	* Optimisation
* Autres extensions
* 3ème soumission


Autres… :
* \’
* mettre un signe à coté des commentaires qu'on doit supprimer
* ne pas oublier de vérifier que les fonctions déclarées dans code.oz correspondent à celles de interprete et mix (même si cela semble évident)



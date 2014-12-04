% The Lord of The Rings - Concerning Hobbits - Howard Shore
local
   Ro = 2.0 % Ronde
   Bl = 1.0 % Blanche
   No = 0.5 % Noire
   Cr = 0.25 % Croche
   Dc = 0.125 % Double-croche

   
   Mesure1 = 
   Tune = [b b c5 d5 d5 c5 b a g g a b]
   End1 = [etirer(facteur:1.5 b) etirer(facteur:0.5 a) etirer(facteur:2.0 a)]
   End2 = [etirer(facteur:1.5 a) etirer(facteur:0.5 g) etirer(facteur:2.0 g)]
   Interlude = [a a b g a etirer(facteur:0.5 [b c5])
                    b g a etirer(facteur:0.5 [b c5])
                b a g a etirer(facteur:2.0 d) ]

   % Ceci n'est pas une musique
   Partition = [Tune End1 Tune End2 Interlude Tune End2]
in
   % Ceci est une musique :-)
   [partition(Partition)]
end

% DJ'Oz - LFSAB1402 - Projet 2014
% Antoine LEGAT    4776-1300
% John DE WASSEIGE 5224-1300


local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd'
	  '/Users/Antoine/Dropbox/FSA12BA/Q3/Info_2/dj-oz-projet/47761300-52241300/'}

   % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
   % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
   %
   % Projet fournit quatre fonctions :
   % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
   % {Projet.readFile FileName} = AudioVector OR error(...)
   % {Projet.writeFile FileName AudioVector} = ok OR error(...)
   % {Projet.load 'music_file.dj.oz'} = La valeur oz contenue dans le fichier chargé (normalement une <musique>).
   %
   % et une constante :
   % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}

   local
      ToNote GetHauteur Etirer Bourdon Transpose Instrument GivesDureeTot
      RepeteN RepeteD Clip Echo CalcFirstIntensity Couper Fondu FonduE
      MixVoix MixSilence MixEch UseWav GetNote Merge MergeAux Assert EnveloppeADSR
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      \insert 'Mix.oz'

      % Interprete doit interpréter une partition
      \insert 'Interprete.oz'
   end

   local
      Tbegin = {Time.time}
      Music = {Projet.load CWD#'example.dj.oz'}
   in
      % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
      % vous devez mixer une musique qui démontre les fonctionalités de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validité de votre implémentation.

      {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
      {Browse {VirtualString.toAtom 'temps ecoule: '#{Time.time}-Tbegin#' secondes'}}
   end
end

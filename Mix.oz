declare % /!\ ne pas oublier d’enlever ‘declare’
fun {Mix Interprete Music}
   case Music
   of nil then nil
   [] Morceau|Rest then % Pas oublier Rest !!!
      case Morceau
      of voix( Voix ) then
	 {Flatten {MixVoix Voix}|{Mix Interprete Rest}}
      [] partition( Part ) then
	 {Flatten {MixVoix {Interprete Part}}|{Mix Interprete Rest}}
      [] wave( FileName ) then
	 nil
	 %{Projet.readFile FileName}
      [] merge( MusicInt ) then
	 case {MergeHelper MusicInt nil 0.0}
	 of values(audiosMatrix:M sumF:S) then
	    {List.map {SumMatrix M nil} fun {$ N} N/S end}
	    % This line adds up the audios and divides them
	    % by S, the sum of the factors
	 end  
      [] renverser( Music ) then
	 {Reverse {Mix Interprete Music}} 
      [] repetition( nombre:N Music ) then
	 {RepeteN N {Mix Interprete Music}}
      [] repetition( duree:Sec Music ) then
	 {RepeteD Sec {Mix Interprete Music}}
      [] clip( bas:Bas haut:Haut Music ) then
	 {Clip Bas Haut {Mix Interprete Music}}
      [] echo(delai:Del Music) then
	 {Mix Interprete [merge({Echo Del 1.0 1 Music})]}
      [] echo(delai:Del decadence:Dec Music) then
	 {Mix Interprete [merge({Echo Del Dec 1 Music})]}
      [] echo(delai:Del decadence:Dec repetition:N Music) then
	 {Mix Interprete [merge({Echo Del Dec N Music})]}
      [] fondu( ouverture:Ouv fermeture:Fer Music ) then
	 {Fondu Ouv Fer {Mix Interprete Music}}
      %[] fondu_enchaine( duree:D M1 M2 ) then
	 %{FonduE D {Mix Interprete M1} {Mix Interprete M2}}
      [] couper(debut:Debut fin:Fin Music) then
	 {Couper Debut Fin {Mix Interprete Music}}
      else % Music est un filtre pas encore fait
	 nil
      end
   end
end

%%%%%%%%%%%%%%%
%%% FILTRES %%%
%%%%%%%%%%%%%%%

fun {RepeteN N Vec}
   local Nr in
      % Les cas où N n'est pas un naturel sont gérés
      if {IsFloat N} then Nr = {Abs {FloatToInt N}}
      else Nr = {Abs N} end
      local
	 fun {RepeteNAcc N Vec Acc}
	    if N =< 0 then Acc
	    else
	       {RepeteNAcc N-1 Vec {Append Vec Acc}}
	       % A ton avis c'est mieux de faire Append ici
	       % et pas de Flatten en-dessous ou pas?
	       % A mon avis Flatten sans Append c'est mieux.
	    end
	 end
      in
	 {RepeteNAcc N Vec Vec}
         % Si N = 0, on joue la musique une fois
      end
   end
end


% Gérer cas où Duree est un int, et où c'est négatif
fun {RepeteD Duree Vec}
   local DureeF DureeS L N R CompleteAcc in
      % Les cas où N n'est pas un float positif sont gérés
      if {IsInt Duree} then DureeF = {Abs {IntToFloat Duree}}
      else DureeF = {Abs Duree} end
      DureeS = {FloatToInt DureeF*44100.0}
      L = {Length Vec}
      N = DureeS div L
      R = DureeS mod L
      fun {CompleteAcc Count Vec Acc}
	 if Count =< 0 then {Reverse Acc}
	 else
	    case Vec
	    of nil then {Reverse Acc} % ça ne devrait pas arriver si la
	                              % fonction est correctement utilisée
	    [] H|T then
	       {CompleteAcc Count-1 T H|Acc}
	    end
	 end
      end
      if N == 0 then
	 {CompleteAcc R Vec nil}
      else
	 {Append {RepeteN N Vec} {CompleteAcc R Vec nil}}
      end
   end
end


fun {Clip Bas Haut Vec} % erreur si H < B ??
   local
      fun {ClipAcc Bas Haut Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    if H < Bas then {ClipAcc Bas Haut T Bas|Acc}
	    elseif H > Haut then {ClipAcc Bas Haut T Haut|Acc} % J'AI MIS T AU HASARD
	    else {ClipAcc Bas Haut T H|Acc}  % J'AI MIS T AU HASARD
	    end
	 end
      end
   in
      {ClipAcc Bas Haut Vec nil}
   end
end


fun {Echo Del Dec Rep Music} % Del delai Dec decadence Rep repetition
   local
      C1 = {CalcFirstIntensity Dec Rep}
      fun {ListsToMerge C Delai Dec Rep Music Count Acc} 
	 if Rep==0 then {Reverse Acc} 
	 else
	    local Mus MusInt in
	       Mus = [voix([silence(duree:(Delai*Count))]) Music]
	       MusInt = (C*Dec)#Mus % on calcule les intensite suivantes en les * a chaque iteration par d
	       {ListsToMerge C*Dec Delai Dec Rep-1 Music Count+1.0 MusInt|Acc}
	    end
	 end
      end
   in
      {Append [C1#Music] {ListsToMerge C1 Del Dec Rep-1 Music 1.0 nil}}
   end
end


% Permet de calculer la premiere intensite qui vaut 1/(1+d^1+d^2+...+d^k) si on repete k fois  
fun {CalcFirstIntensity Dec Rep} % Dep decadence Rep repetition
   local SumDec Rr
      if {IsFloat Rep} then Rr = {FloatToInt Rep} % peut etre pas necessaire
      else Rr = Rep end
      fun {SumDec D R Count Acc}
	    if R == 0 then Acc
	    else
	       {SumDec D R-1 Count+1.0 Acc+{Pow D Count}}
	    end
      end
   in
      1.0/(1.0 + {SumDec Dec Rr 1.0 0.0})
   end
end


% {Assert Ouv=<L 'L\'ouverture est plus longue que la musique'}
% Ouv*44100 ... int float ...
% Add robustesse si Open ou Close int
%declare
fun {Fondu Open Close Vec}
   local 
      OpenV = Open*44100.0
      CloseV = Close*44100.0
      L0 = {IntToFloat {Length Vec}}
      fun {FonduAcc OpenV CloseV L0 Count Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    if Count < OpenV andthen Count > L0-CloseV then {FonduAcc OpenV CloseV L0 Count+1.0 T (Count/OpenV)*(L0-Count/CloseV)*H|Acc}
	    elseif Count < OpenV then {FonduAcc OpenV CloseV L0 Count+1.0 T (Count/OpenV)*H|Acc}
	    elseif Count > L0-CloseV then {FonduAcc OpenV CloseV L0 Count+1.0 T (L0-Count/CloseV)*H|Acc}
	    else
	       {FonduAcc OpenV CloseV L0 Count+1.0 T H|Acc}
	    end
	 end
      end
   in
      {FonduAcc OpenV CloseV L0 1.0 Vec nil}
   end
end
%Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
%{Browse {Fondu 0.000025 0.000025 Music1}}


fun {Couper Debut Fin Vec}
   local
      Init = Debut*44100.0
      End  = Fin*44100.0
      L = {IntToFloat {Length Vec}}
      fun {CouperAcc Init End Count L0 Vec Acc}
	 if Count >= End then {Reverse Acc}
	 elseif Count < 0.0 orelse Count > L0 then {CouperAcc Init End Count+1.0 L0 Vec 0.0|Acc}
	 else  
	    case Vec
	    of nil then {CouperAcc Init End Count+1.0 Vec L0 0.0|Acc}
	    [] H|T then
	       if Count < Init then {CouperAcc Init End Count+1.0 L0 T Acc}
	       else {CouperAcc Init End Count+1.0 L0 T H|Acc}
	       end
	    end
	 end
      end
   in
      {CouperAcc Init End Init L Vec nil}
   end
end



   


%%%%%%%%%%%
%%% MIX %%% 
%%%%%%%%%%%
fun {MixVoix Voix}
   local F N K Pi in
      case Voix
      of nil then nil
      [] silence(duree:D)|Rest then
	 N = {FloatToInt D*44100.0}
	 K = 0.0
	 {Flatten {MixEch K 1 N}|{MixVoix Rest}}
      [] echantillon( hauteur:H duree:D instrument:I )|Rest then
	 N = {FloatToInt D*44100.0}
	 F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
	 Pi = 3.14159
	 K = 2.0*Pi*F/44100.0
	 {MixEch K 1 N}|{MixVoix Rest}
      end
   end
end


fun {MixEch K I Max}
   if I > Max then nil
   else
      0.5*{Sin K*{IntToFloat I}}|{MixEch K I+1 Max}
   end
end



%%%%%%%%%%%%%
%%% MERGE %%%
%%%%%%%%%%%%%

fun {MergeHelper MusicInt M S}
   % Petit mot d'explication sur M :
   % C'est un vecteur contenant les vecteurs audios calculés
   % jusqu'à présent. C'est un vecteur de vecteurs, on peut donc
   % le voir comme une matrice.
   case MusicInt
   of nil then values(audiosMatrix:M sumF:S)
   [] (F#Music)|Rest then % selon moi ça marche avec et sans les ()
                          % autour de F#Music, une préférence ?
      local Fr in
	 if {IsInt F} then % Pour la robustesse
	    Fr = {IntToFloat F}
	 else
	    Fr = F
	 end
	 { MergeHelper Rest
	   {Append M [{List.map {Mix Interprete Music} fun {$ N} Fr*N end}]}
	   S+Fr }
      % John si tu arrives à faire sans le Append c'est mieux mais
      % c'est un truc à se rendre fou
      %
      % cette ligne incompréhensible appelle MergeHelper avec Rest
      % comme MusicInt, en adjoignant à M le vecteur audio
      % correspondant à Music multiplié par F (c'est le rôle de
      % List.map) et en additionnant F à S.
      end
   end
end


fun {SumMatrix M Acc}
   % blabla description
   case M
   of nil then Acc
   [] Vec|Rest then
      {SumMatrix Rest {Sum Acc Vec}}
   end
end


fun {Sum L1 L2}
   % This function adds up the elements of the lists L1 and L2
   % one by one. If they don't have the same length, the one
   % with smaller length is extended with zeros.
   local Lbig Lshort SumAcc
      if {Length L1} > {Length L2} then
	 Lbig = L1
	 Lshort = L2
      else
	 Lbig = L2
	 Lshort = L1
      end
      fun {SumOpt Lshort Lbig}
	 case Lshort
	 of nil then
	    case Lbig
	    of nil then nil
	    [] Hb|Tb then
	       Hb|{SumOpt nil Tb}
	    end
	 [] Hs|Ts then
	    (Hs+Lbig.1)|{SumOpt Ts Lbig.2}
	 end
      end
   in
      {SumOpt Lshort Lbig}
   end
end







% partition() : DONE OK
% voix() : DONE
% merge() : DONE
%   Sum : DONE OK
%   SumMatrix : DONE OK
%   MergeHelper : DONE OK
% filtres
%   Reverse : DONE OK
%   RepeteN : DONE OK
%   RepeteD : DONE OK
%   Clip    : DONE OK
%   Echo    : DONE
%   Fondu   : DONE OK rajouter des tests hardcore (+ assert)
%   Fondu_e : 
%   Couper  : DONE


%%%%%%%%%%%%%
%%% TESTS %%%
%%%%%%%%%%%%%
\insert '/Users/john/dj-oz-projet/Interprete.oz' %/Users/john/dj-oz-projet/Interprete.oz
declare
Music0 = [ voix( [ echantillon( hauteur:0 duree:1.0 instrument:none) ] ) ]
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.0001 [silence b2] ) ) ]
Music2bis = [ partition( duree(secondes:0.001 [a1 b2 c3] ) ) ]
Music3 = partition (Partition1)
Music4 = partition (Partition2)
%{Browse {Mix Interprete Music2}}
MusicInt = [(2.0#Music1) (60.0#Music2)]
%{Browse {MergeHelper MusicInt nil 0.0}}
Music5 = [ merge( MusicInt ) ]
%{Browse {Mix Interprete Music5}}
Music6 = [ renverser( Music2bis ) ]
Music7 = [ repetition(nombre:2 Music2bis) ]
Music8 = [ repetition( duree:0.00015 Music2) ]
Music9 = [ clip(bas:~0.001 haut:0.09242 Music2bis) ]
Music10= [ clip(bas:0.042 haut:0.00942 Music2bis) ]
Music11= [ echo(delai:1.0 decadence:0.5 Music2bis) ]
Music12= [ couper(bas:0.0005 haut:0.0007 Music2bis) ]
Music13= [ fondu(ouverture:0.0001 fermeture:0.0001 Music2bis) ]
%{Browse {Mix Interprete Music13}}
%{Browse {Mix Interprete Music8}}
%{Browse {Mix Interprete Music0}}

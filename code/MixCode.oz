fun {Mix Interprete Music}
   case Music
   of nil then nil
   [] Morceau|Rest then % Pas oublier Rest !!!
      case Morceau
      of voix( Voix ) then
	 {Flatten {MixVoix Voix}|{Mix Interprete Rest}} % APPEND à LA PLACE DE FLATTEN ???
      [] partition( Part ) then
	 {Flatten {MixVoix {Interprete Part}}|{Mix Interprete Rest}}
      [] wave( FileName ) then
	 nil
	 %{Projet.readFile FileName}
      [] merge( MusicInt ) then
	 case {MergeHelper MusicInt nil nil}
	 of sumsVectors(sumAudios:SumAud sumF:SumF) then
	    {Flatten SumAud|{Mix Interprete Rest}}
	    %{Flatten {DivideVectors SumAud SumF}|{Mix Interprete Rest}}
	    % Cette ligne divise le vecteur audio résultant par le vecteur
            % résultant des facteurs (et concatène le résultat avec la suite...).
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
      [] fondu_enchaine( duree:Duree Music1 Music2 ) then
	 {FonduE Duree {Mix Interprete Music1} {Mix Interprete Music2}}
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
      % Les cas où N n'est pas un naturel positif sont gérés
      if {IsFloat N} then Nr = {Abs {FloatToInt N}}
      else Nr = {Abs N} end
      local
	 fun {RepeteNAcc N Vec Acc}
	    if N == 0 then Acc
	    else
	       {RepeteNAcc N-1 Vec {Append Vec Acc}}
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
	 if Count == 0 then {Reverse Acc} 
	 else
	    case Vec
	    of nil then {Reverse Acc} % ça ne devrait pas arriver si la fonction est correctement utilisée
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


fun {Clip Bas Haut Vec}
   {Assert Bas=<Haut 'CLIP : $bas est inférieur à $haut'}
   local ClipAcc in
      fun {ClipAcc Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    if H < Bas then {ClipAcc T Bas|Acc}
	    elseif H > Haut then {ClipAcc T Haut|Acc} 
	    else {ClipAcc T H|Acc} 
	    end
	 end
      end
      {ClipAcc Vec nil}
   end
end


fun {Echo DelN Dec RepN Music} % Del delai Dec decadence Rep repetition
   local C1 ListsToMerge Del Rep in
      if {IsInt DelN} then Del = {IntToFloat {Abs DelN}}
      else Del = {Abs DelN} end
      if {IsFloat RepN} then Rep = {FloatToInt {Abs RepN}}
      else Rep = {Abs RepN} end
      C1 = {CalcFirstIntensity Dec Rep}
      fun {ListsToMerge C Rep Count Acc} 
	 if Rep==0 then {Reverse Acc} 
	 else
	    local Mus MusInt in
	       Mus = [voix([silence(duree:(Del*Count))]) Music] % Delai c'est Del ????
	       MusInt = (C*Dec)#Mus % on calcule les intensite suivantes en les * a chaque iteration par d
	       {ListsToMerge C*Dec Rep-1 Count+1.0 MusInt|Acc}
	    end
	 end
      end
      {Append [C1#Music] {ListsToMerge C1 Rep-1 1.0 nil}}
   end
end


% Permet de calculer la premiere intensite qui vaut 1/(1+d^1+d^2+...+d^k) si on repete k fois  
fun {CalcFirstIntensity Dec Rep} % Dep decadence Rep repetition
   local SumDec Rr in 
      if {IsFloat Rep} then Rr = {FloatToInt {Abs Rep}} 
      else Rr = {Abs Rep} end
      fun {SumDec R Count Acc}
	    if R == 0 then Acc
	    else
	       {SumDec R-1 Count+1.0 Acc+{Pow Dec Count}}
	    end
      end
      1.0/(1.0 + {SumDec Rr 1.0 0.0})
   end
end


fun {Fondu Open Close Vec}
   local OpenV CloseV L0 FonduAcc in
      if {IsInt Open} then OpenV = {IntToFloat Open}*44100.0
      else OpenV = Open*44100.0 end
      if {IsInt Close} then CloseV = {IntToFloat Close}*44100.0
      else CloseV = Close*44100.0 end
      L0 = {IntToFloat {Length Vec}}
      {Assert OpenV<L0 'FONDU : $ouverture est plus longue que la musique'}
      {Assert CloseV<L0 'FONDU : $fermeture est plus longue que la musique'}
      fun {FonduAcc Count Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    if Count < OpenV andthen Count > L0-CloseV then
	       {FonduAcc Count+1.0 T (Count / OpenV)*((L0-Count) / CloseV)*H|Acc}
	    elseif Count < OpenV then {FonduAcc Count+1.0 T (Count / OpenV)*H|Acc}
	    elseif Count > L0-CloseV then {FonduAcc Count+1.0 T ((L0-Count) / CloseV)*H|Acc}
	    else
	       {FonduAcc Count+1.0 T H|Acc}
	    end
	 end
      end
      {FonduAcc 1.0 Vec nil}
   end
end
%Vec1 = [1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0]
%Vec2 = [2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0]
%Vec3 = [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]
%Vec4 = {Append Vec2 Vec2}
%{Browse {Fondu 0.0003 0.0001 Vec4}}
%Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0004 instrument:none) ] ) ]
%Audio1 = {Mix Interprete Music1}
%{Browse Audio1}
%{Browse {Fondu 0.1 0.03 Audio1}}
%{Browse {Fondu 0.000025 0.0003 Audio1}}


%declare
%proc {Assert Cond Exception}
%   if {Not Cond} then raise Exception end end
%end
fun {FonduE Duree Vec1 Vec2}
   local DureeV L1 L2 FonduEAcc in
      if {IsInt Duree} then DureeV = {IntToFloat Duree}*44100.0
      else DureeV = Duree*44100.0 end
      L1 = {IntToFloat {Length Vec1}}
      L2 = {IntToFloat {Length Vec2}}
      {Assert DureeV<L1 'FONDU ENCHAINE : $duree du fondu est plus longue que la musique 1'}
      {Assert DureeV<L2 'FONDU ENCHAINE : $duree du fondu est plus longue que la musique 2'}
      fun {FonduEAcc Count V1 V2 Acc}
	 if Count<L1-DureeV then % Avant fondu
	    {FonduEAcc Count+1.0 V1.2 V2 V1.1|Acc}
	 else
	    case V1
	    of nil then
	       case V2
	       of nil then % Fin
		  {Reverse Acc}
	       [] H|T then % Après fondu
		  {FonduEAcc Count+1.0 nil T H|Acc}
	       end
	    [] H|T then % Dans fondu
	       {FonduEAcc Count+1.0 T V2.2
		((H*(L1-Count) + V2.1*(Count+DureeV-L1))/DureeV)|Acc}
	    end
	 end
      end
      {FonduEAcc 1.0 Vec1 Vec2 nil}
   end
end
%Vec1 = [1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0]
%Vec2 = [2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0]
%Vec3 = [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]
%{Browse {FonduE 0.0002 Vec3 Vec2}}


fun {Couper Debut Fin Vec}
   local Init End L0 CouperAcc in
      Init = Debut*44100.0
      End  = Fin*44100.0
      L0 = {IntToFloat {Length Vec}}
      fun {CouperAcc Count Vec Acc}
	 if Count >= End then {Reverse Acc}
	 elseif Count < 0.0 orelse Count > L0 then {CouperAcc Count+1.0 Vec 0.0|Acc}
	 else  
	    case Vec
	    of nil then {CouperAcc Count+1.0 Vec 0.0|Acc}
	    [] H|T then
	       if Count < Init then {CouperAcc Count+1.0 T Acc}
	       else {CouperAcc Count+1.0 T H|Acc}
	       end
	    end
	 end
      end
      {CouperAcc Init Vec nil}
   end
end



   


%%%%%%%%%%%
%%% MIX %%% 
%%%%%%%%%%%
fun {MixVoix Voix}
   local F N K Pi FactLissage in
      Pi = 3.14159
      FactLissage = 0.2
      case Voix
      of nil then nil
      [] silence(duree:D)|Rest then
	 N = {FloatToInt D*44100.0}
	 K = 0.0
	 {Flatten {MixEch K 1 N}|{MixVoix Rest}}
      [] echantillon( hauteur:H duree:D instrument:I )|Rest then
	 N = {FloatToInt D*44100.0}
	 F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
	 K = 2.0*Pi*F/44100.0
	 {Fondu FactLissage*D FactLissage*D {MixEch K 1 N}}|{MixVoix Rest}
	 % Ce fondu lisse chaque note
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

fun {MergeHelper MusicInt SumAud SumF}
   % Petit mot d'explication sur M :
   % C'est un vecteur contenant les vecteurs audios calculés
   % jusqu'à présent. C'est un vecteur de vecteurs, on peut donc
   % le voir comme une matrice.
   case MusicInt
   of nil then sumsVectors(sumAudios:SumAud sumF:SumF)
   [] (F#Music)|Rest then % selon moi ça marche avec et sans les ()
                          % autour de F#Music, une préférence ?
      local Fr Audio AudioMult in
	 % Pour la robustesse
	 if {IsInt F} then Fr = {IntToFloat F}
	 else Fr = F end
	 Audio = {Mix Interprete Music}
	 AudioMult =  {List.map Audio fun {$ N} Fr*N end}
	 { MergeHelper Rest
	   {Sum AudioMult SumAud}
	   {Sum SumF {MakeVector Fr {Length Audio}}} }
      % Cette ligne incompréhensible appelle MergeHelper avec Rest
      % comme MusicInt, en additionnant AudioMult à SumAud et en
      % additionnant un vecteur de la même taille qu'Audio mais
      % "rempli" du facteur à SumF.
      end
   end
end


fun {MakeVector Value Length}
   % Retourne un vecteur (une liste) de taille $Length
   % et exclusivement composé de valeurs $Value
   fun {MakeVectorAcc I Acc}
      if I==0 then Acc
      else
	 {MakeVectorAcc I-1 Value|Acc}
      end
   end
in
   {MakeVectorAcc Length nil}
end


fun {DivideVectors V1 V2}
   % Retourne le résultat de la division élément par élément de
   % V1 par V2. V1 et V2 doivent avoir la même taille.
   case V1
   of nil then nil
   [] H|T then
      H/V2.1|{DivideVectors T V2.2}
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
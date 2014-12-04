% DJ'Oz - LFSAB1402 - Projet 2014
% Antoine LEGAT    4776-1300
% John DE WASSEIGE 5224-1300

declare % /!\ ne pas oublier d’enlever ‘declare’
fun {Mix Interprete Music}
   case Music
   of nil then nil
   [] Morceau|Rest then
      local Audio in
	 case Morceau
	 of voix( Voix ) then
	    Audio = {MixVoix Voix}
	 [] partition( Part ) then
	    Audio = {MixVoix {Interprete Part}}
	 [] wave( FileName ) then
	    Audio = nil % pour que ça compile
	    %Audio = {Projet.readFile FileName}
	 [] merge( MusicInt ) then
	    Audio = {Merge MusicInt}  
	 [] renverser( Music ) then
	    Audio = {Reverse {Mix Interprete Music}} 
	 [] repetition( nombre:N Music ) then
	    Audio = {RepeteN N {Mix Interprete Music}}
	 [] repetition( duree:Sec Music ) then
	    Audio = {RepeteD Sec {Mix Interprete Music}}
	 [] clip( bas:Bas haut:Haut Music ) then
	    Audio = {Clip Bas Haut {Mix Interprete Music}}
	 [] echo(delai:Del Music) then
	    Audio = {Mix Interprete [merge({Echo Del 1.0 1 Music})]}
	 [] echo(delai:Del decadence:Dec Music) then
	    Audio = {Mix Interprete [merge({Echo Del Dec 1 Music})]}
	 [] echo(delai:Del decadence:Dec repetition:N Music) then
	    Audio = {Mix Interprete [merge({Echo Del Dec N Music})]}
	 [] fondu( ouverture:Ouv fermeture:Fer Music ) then
	    Audio = {Fondu Ouv Fer {Mix Interprete Music}}
	 [] fondu_enchaine( duree:Duree Music1 Music2 ) then
	    Audio = {FonduE Duree {Mix Interprete Music1} {Mix Interprete Music2}}
	 [] couper(debut:Debut fin:Fin Music) then
	    Audio = {Couper Debut Fin {Mix Interprete Music}}
	 else
	    raise 'MIX : $Morceau ne possede pas le bon format' end
	 end
	 {Flatten Audio|{Mix Interprete Rest}}
      end
   else
      raise 'MIX : $Music doit etre une liste' end
   end
end

%%%%%%%%%%%%%%%
%%% FILTRES %%%
%%%%%%%%%%%%%%%

fun {RepeteN N Vec}
   local Nr in
      % Les cas ou N n'est pas un naturel positif sont geres
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
	 {RepeteNAcc Nr Vec Vec}
         % Si N = 0, on joue la musique une fois
      end
   end
end


fun {RepeteD Duree Vec}
   local DureeF DureeS L N R CompleteAcc in
      % Les cas ou N n'est pas un float positif sont geres
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
	    of nil then {Reverse Acc} % ça ne devrait pas arriver si
	                              % la fonction est correctement utilisee
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
   {Assert Bas=<Haut 'CLIP : $bas est inferieur a $haut'}
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

declare
fun {Echo DelN Dec RepN Music} % Del:delai Dec:decadence Rep:repetition
   local C1 ListsToMerge Del Rep MusicMult in
      if {IsInt DelN} then Del = {IntToFloat {Abs DelN}}
      else Del = {Abs DelN} end
      if {IsFloat RepN} then Rep = {FloatToInt {Abs RepN}}
      else Rep = {Abs RepN} end
      C1 = {CalcFirstIntensity Dec Rep}
      fun {ListsToMerge C Rep Count Acc} 
	 if Rep==0 then {Reverse Acc} 
	 else
	    local Mus MusInt in
	       Mus = [voix([silence(duree:(Del*Count))]) Music]
	       MusInt = (C*Dec)#Mus % on calcule les intensite suivantes en
	                            % les * a chaque iteration par d
	       {ListsToMerge C*Dec Rep-1 Count+1.0 MusInt|Acc}
	    end
	 end
      end
      {Append (C1#Music) {ListsToMerge C1 Rep-1 1.0 nil}}
   end
end


% Permet de calculer la premiere intensite qui
% vaut 1/(1+d^1+d^2+...+d^k) si on repete k fois  
fun {CalcFirstIntensity Dec Rep} % Dec:decadence Rep:repetition
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
	       [] H|T then % Apres fondu
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


fun {EnveloppeADSR A D S R Vec} % A - attack , D - decay , S - sustain , R - release
   local L0 EnvADSRaux in
      L0 = {IntToFloat {Length Vec}}
      fun {EnvADSRaux Count A D S R L0 Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    local Fact
	       if Count < A then
		  Fact = Count/A
	       elseif (Count - A) < D then
		  Fact = 1.0 - (Count-A)*(1.0-S)/D
	       elseif Count < (L0 - R) then
		  Fact = S
	       else
		  Fact = S*(L0-Count)/R
	       end
	    in
	       {EnvADSRaux Count+1.0 A D S R L0 T H*Fact|Acc}
	    end
	 end
      end
      {EnvADSRaux 1.0 A*L0 D*L0 S R*L0 L0 Vec nil}   
   end
end

	    
	    

      

%%%%%%%%%%%
%%% MIX %%% 
%%%%%%%%%%%
fun {MixVoix Voix}
   local F N K Pi FactLissage in
      Pi = 3.14159
      FactLissage = 0.1
      case Voix
      of nil then nil
      [] silence(duree:D)|Rest then
	 N = {FloatToInt D*44100.0}
	 {Flatten {MixSilence 1 N}|{MixVoix Rest}}
      [] echantillon( hauteur:H duree:D instrument:none )|Rest then
	 N = {FloatToInt D*44100.0}
	 F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
	 K = 2.0*Pi*F/44100.0
	 {EnveloppeADSR 0.04 0.02 0.8 0.05 {MixEch K 1 N}}|{MixVoix Rest} % Enveloppe ADSR 
         %{Fondu FactLissage*D FactLissage*D {MixEch K 1 N}}|{MixVoix Rest} % Envelopppe Trapeze
      %[] echantillon( hauteur:H duree:D instrument:I )|Rest then
	% local Ech 
	 %   Ech = echantillon(hauteur:H duree:D instrument:I)
	 %in
	  %  {Flatten {UseWav Ech}|{MixVoix Rest}}
	% end
      end
   end
end

fun {MixSilence I Max}
   if I > Max then nil
   else
      0.0|{MixSilence I+1 Max}
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
fun {Merge MusInt}
   case MusInt
   of H|T then
      case H
      of Intensity#Mus then
	 {MergeAux {Mix Interprete Mus} Intensity {Merge T} 1.0}
      else nil end
   else nil end
end

fun {MergeAux Vec1 Int1 Vec2 Int2}
   case Vec1
   of H1|T1 then
      case Vec2
      of H2|T2 then
	 (H1*Int1 + H2*Int2)|{MergeAux T1 Int1 T2 Int2}
      else
	 (H1*Int1)|{MergeAux T1 Int1 Vec2 Int2}
      end
   else
      case Vec2
      of H2|T2 then
	 (H2*Int2)|{MergeAux Vec1 Int1 T2 Int2}
      else
	 nil
      end
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
%   Fondu   : DONE OK rajouter des tests hardcore
%   Fondu_e : 
%   Couper  : DONE


%%%%%%%%%%%%%
%%% TESTS %%%
%%%%%%%%%%%%%
\insert '/Users/john/dj-oz-projet/code/Interprete.oz' % /Users/john/dj-oz-projet/code/Interprete.oz
declare
Music0 = [ voix( [ echantillon( hauteur:1 duree:0.0001 instrument:none) ] ) ]
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.0001 [silence b2] ) ) ]
Music2bis = [ partition( duree(secondes:0.001 [a1 b2 c3] ) ) ]
Music3 = partition (Partition1)
Music4 = partition (Partition2)
%{Browse {Mix Interprete Music2}}
MusicInt = [(0.4#Music1) (0.6#Music2)]
%{Browse {MergeHelper MusicInt nil 0.0}}
Music5 = [ merge( MusicInt ) ]
%{Browse {Mix Interprete Music5}}
Music6 = [ renverser( Music2bis ) ]
Music7 = [ repetition(nombre:2 Music2bis) ]
Music8 = [ repetition( duree:0.00015 Music2) ]
Music9 = [ clip(bas:~0.001 haut:0.09242 Music2bis) ]
Music10= [ clip(bas:0.042 haut:0.00942 Music2bis) ]
Music11= [ echo(delai:1.0 decadence:0.5 Music2bis) ]
Music12= [ couper(debut:0.0 fin:0.0005 Music2bis) ]
Music13= [ fondu(ouverture:0.0001 fermeture:0.0001 Music2bis) ]
%{Browse {Mix Interprete Music2bis}}
%{Browse {EnveloppeADSR 0.04 0.02 0.8 0.05 {Mix Interprete Music2bis}}}
%{Browse {Mix Interprete Music0}}
%{Browse {Mix Interprete Music5}}
%{Browse {Mix Interprete Music8}}
%{Browse {Mix Interprete Music0}}
Music14 = {Append Music0 {Append Music1 Music0}}
Music15 = [partition([instrument(nom:drums [c4 d4 d4 c4])])]
%{Browse {Mix Interprete Music12}}
%{Browse {Mix Interprete Music14}}
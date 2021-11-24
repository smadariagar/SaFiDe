% Recibe una matriz de datos por columna correspondientes a:
%       [tiempo; posXOjo; posYOjo]
% 
% Entrega como salida un vector correspondiente a los tiempos de las
% sacadas para cada ojo (por ahora solo el ojo derecho) el cual se calculó
% con los siguientes parámetros:
%       39.38 pixeles    = 1 grado visual [°]
%       amplitud sacada >= 0.1 grados visuales [°]
%       aceleración     >= 4000°/s^2
%       velocidad       >= 30°/s
%       tiempo sacada   >= 4 ms
%
%       output = [matrizSacadas, matrizFijacion, matrizBlink] 
%       
% Laboratorio de Neurosistemas
% Christ Devia & Samuel Madariaga
% Febrero 2019
 
function [tpoSac, tpoFix, tpoBlink, vel, acc] = SaFiDe(sam, cfg)

%% PARTE 0: Calculo de los tiempos de parpadeos con script
try
    if cfg.getPupilBlinks
        blinks_data_positions = based_noise_blinks_detection(sam(:,4), cfg.sampling_rate);	% get blink positions using the noise-based approach
        tpoBlink = reshape(blinks_data_positions',2,[])';
        tpoBlink = index2time(tpoBlink/2,sam(:,1));
    else
        tpoBlink = [0 1];
    end
catch
    tpoBlink = [0 1];
    disp('WARNING: no se midió la pestañeos por pupuila')
end

    

%% PARTE 1: Calcula la velocidad y la aceleracion
nsam = size(sam,1);
cal = zeros(nsam-2,5); % [timestamp dist vel acc sacc?]
try
    pix2grad = cfg.pix2grad;
catch
    pix2grad = 1;
    disp('WARNING: no pixle2 grad');
end

for i = 1:nsam-1
    
    % distancia total recorrida en grados visuales
    DTgr(i+1) = sqrt((sam(i+1,2)-sam(i,2)).^2 + (sam(i+1,3)-sam(i,3)).^2) / pix2grad;
    
    % velocidad en grados/segundos
    vel(i+1) = DTgr(i+1)/( (sam(i+1,1)-sam(i,1) )*10^-3);
    
end
vel(1) = vel(3);


for i = 2:length(vel)-1 
    
    % aceleracion en grados/seg^2
    acc(i+1) = (vel(i+1)-vel(i))/( (sam(i+1,1)-sam(i,1) )*10^-3);
    
    % Aceleracion y velocidad
    if  acc(i+1) <= cfg.acce1Thld(1) || acc(i+1) >= cfg.acce1Thld(2) || vel(i+1) >= cfg.velThld
        cal(i+1,5) = 1; % marca con un 1 los periodos de sacada
    end

end


%% PARTE 2: Detecta los tiempos de inicio y termino de sacada
dife = diff(cal(:,5));
T1 = find(dife>0); % Onset of saccades
T2 = find(dife<0)+1; % Offset of saccades

% Limpia las sacadas al inicio y final del registro
if T2(1) <= T1(1)
    T2 = T2(2:end);
end
T1 = T1(1:length(T2));

% Calcula la DURACION de la sacada en samples
Dsac = T2-T1;

% Verifica que no exitan las sacadas negativas
if any(Dsac)<0
    disp('Existe una sacada negativa')
    T1(Dsac<0) = [];
    T2(Dsac<0) = [];
end


%% PARTE 3: Solo deja las sacadas con amplitud mayor a 0.1 grados visuales
% Calcula la amplitud total por sacada
Asac = zeros(size(T1,1),1);
for i = 1:size(T1,1)
    Asac(i) = sum(DTgr(T1(i):T2(i))); % si hay un NaN dara NaN
end

%%%%%%%%%%%%%%%%%%%%%%%%%% Ojo 0.5 segun paper de los monkeys
% Verifica cuales son mayores al umbral de deteccion, en este caso > 0.1
cond = Asac > cfg.ampliSaccThld;

% Flag de que esa sacada no es un blink (por que su amplitud es NaN) y debe dejarlo
fgbli = ~isnan(Asac);

% Mantiene los que son NaN pues indican que esa sacada es un blink, fuerza
% a que cond sea 0 solo cuando la amplitud es menor que 0.1
cond2 = cond==1 & fgbli==1;
aT1 = T1(cond2);
aT2 = T2(cond2);

% Cálculo de la velocidad peak
for i = 1:length(aT1)
    velPeak(i) = max(vel(aT1:aT2));
end

% Se generan los tiempos de las sacadas
tpoSac = [sam(aT1,1) sam(aT2,1) Asac(cond2>0) sam(aT2,1)-sam(aT1,1) velPeak'...
    sam(aT1,2) sam(aT1,3) sam(aT2,2) sam(aT2,3) zeros(size(sam(aT2,3)))];


%% PARTE 4: Con los tiempos de los pestañeos elimina las sacadas insertas entre estos
contB = 1;
aux = zeros(size(tpoSac(:,1)));

for i = 2:size(tpoSac,1)
    
    % Actualiza el blink
    if tpoSac(i,1) > tpoBlink(contB,2) && contB < size(tpoBlink,1)
        contB = contB + 1;
    end
    
    % marca las sacadas menores al tiempo límite
    if tpoSac(i,2)-tpoSac(i,1) <= cfg.lengthSaccThld
        aux(i) = 1;
    end
    
    % Busca las sacadas antes y despues del blink (wd = 60)
    if tpoSac(i,2) > tpoBlink(contB,1) && tpoSac(i,1) < tpoBlink(contB,2)
        aux(i) = 1;
    end
    
    % Marca los overshoot
    if tpoSac(i,1)-tpoSac(i-1,2) <= 16 && tpoSac(i,3) <= 1.5 
        tpoSac(i-1,2) = tpoSac(i,2);
        tpoSac(i-1,3) = tpoSac(i,3) + tpoSac(i-1,3);
        tpoSac(i-1,4) = tpoSac(i,4) + tpoSac(i-1,4);
        tpoSac(i-1,7) = tpoSac(i,7);
        tpoSac(i-1,8) = tpoSac(i,8); 
        tpoSac(i-1,9) = 1;
        aux(i) = 1;
    end
    
end
 
% Eliminina los blink de tamaño cero o negativo y los de mas de 10s
tpoBlink(tpoBlink(:,2)-tpoBlink(:,1)<=0,:) = [];
tpoBlink(tpoBlink(:,2)-tpoBlink(:,1)>=10000,:) = [];
 
% modifica la matriz de sacadas y los inicio y finales de sacadas
tpoSac(logical(aux),:) = [];
aT1(logical(aux)) = []; aT2(logical(aux)) = [];


%% PARTE 5: Genera la matriz de fijaciones a partir de los datos de sac
tf1 = aT2(1:end-1)+1; tf2 = aT1(2:end)-1;
tpoFix = [sam(tf1,1) sam(tf2,1) sam(tf2,1)-sam(tf1,1) ...
    sam(tf1,2) sam(tf2,3) zeros(size(sam(tf2,3)))];
 
contB = 1; 
aux = zeros(size(tpoFix(:,1)));

i=1;
while  i <= size(tpoFix,1)
    
    % marca las fijaciones menores a 10 ms
    if tpoFix(i,2)-tpoFix(i,1) <= 10
        aux(i) = 1;
    end
    
    % marca las fijaciones con un blink ente medio
    if  tpoFix(i,2) > tpoBlink(contB,1) && tpoFix(i,1) < tpoBlink(contB,2)
        tpoFix(i,6) = 1;
        tpoFix = [tpoFix(1:i,:); tpoFix(i:end,:)];
        tpoFix(i,2) = tpoBlink(contB,1);
        tpoFix(i+1,1) = tpoBlink(contB,2);
        
        % Actualiza el blink
        if contB < size(tpoBlink,1)
            contB = contB + 1;
        end
        
    end
    i=i+1;
    
end
 
% modifica la matriz de fix
tpoFix(logical(aux),:) = [];
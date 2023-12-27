%Entrega histogramas SaFiDe

function [ths_vel, ths_acc] = SaFiDe_thresholds(sam,color)


%% PARTE 1: Calcula la velocidad y la aceleracion
nsam = size(sam,1);
cal = zeros(nsam-2,5); % [timestamp dist vel acc sacc?]

for i = 1:nsam-1
    % distancia total recorrida en grados visuales
    DTgr(i+1) = sqrt((sam(i+1,2)-sam(i,2)).^2 + (sam(i+1,3)-sam(i,3)).^2);

    % velocidad en grados/segundos
    vel(i+1) = DTgr(i)/( (sam(i+1,1)-sam(i,1) )*10^-3);

end

for i = 1:length(vel)-1 %%
    % aceleracion en grados/seg^2
    acc(i+1) = (vel(i+1)-vel(i))/( (sam(i+1,1)-sam(i,1) )*10^-3);

end

%% PARTE 2: C?lculo de umbrales

[fv,xv] = ecdf(vel);
[fa,xa] = ecdf(acc);
fa = (fa-.5)*2;

% Threshold
ths_vel = xv(find(fv>=.85,1,'first'));
thsa_inf = xa(find(fa<=-.9,1,'last'));
thsa_sup = xa(find(fa>=.9,1,'first'));

ths_acc = [thsa_inf thsa_sup];

%% PARTE 3: Histogramas

fig = figure('Renderer', 'painters', 'Position', [10 10 600 300],'color','w');
subplot(2,1,1)
hold on
[counts,centers] = hist(xv(find(fv<=.9)),50);
bar(centers(1:end),counts(1:end),'LineWidth',1,'EdgeColor',[0 0 0],'FaceColor',color);
plot([ths_vel ths_vel],[0 max(counts)],'k--','LineWidth',1.4);
xlabel('Velocity [u.a./s]');
ylabel('Frequency');
set(gca,'FontWeight','bold','FontSize',10,'FontName','Arial','Visible','on');

subplot(2,1,2)
hold on
[counts,centers] = hist(xa(find(fa<=.93 & fa>=-.93)),50);
bar(centers(1:end),counts(1:end),'LineWidth',1,'EdgeColor',[0 0 0],'FaceColor',color);
plot([thsa_sup thsa_sup],[0 max(counts)],'k--','LineWidth',1.4);
plot([thsa_inf thsa_inf],[0 max(counts)],'k--','LineWidth',1.4);
xlabel('Acceleration [u.a./s^2]');
ylabel('Frequency');
set(gca,'FontWeight','bold','FontSize',10,'FontName','Arial','Visible','on');

%title('Empirical (Kaplan-Meier) cumulative distribution function')




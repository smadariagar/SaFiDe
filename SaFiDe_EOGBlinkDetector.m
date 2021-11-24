% Recibe una matriz de datos por columna correspondientes a:
%       [tiempo; posXOjo; posYOjo]
% 

 
function [matSac, idx] = SaFiDe_EOGBlinkDetector(matSac, cfg)
%% unión pseudo sacadas
i=2;
for c = 2:size(matSac,1)
    
    % une y borra la pseudo sacada
    if matSac(i,1)-matSac(i-1,2) <= 40
        matSac(i-1,2) = matSac(i,2);
        matSac(i-1,3) = matSac(i,3) + matSac(i-1,3);
        matSac(i-1,4) = matSac(i,4) + matSac(i-1,4);
        matSac(i-1,7) = matSac(i,7);
        matSac(i-1,8) = matSac(i,8);
        matSac(i-1,9) = 1;
        matSac(i,:) = [];
        i = i-1;
    end
    i = i+1;
end


%% kmeans
[idx,~] = kmeans((matSac(:,[3 4])),2);

fig = figure('Renderer', 'painters', 'Position', [10 10 400 300],'color','w');
hold on

plot(matSac(idx==1,3), matSac(idx==1,4),'.','MarkerSize',18,'Color',cfg.color1);
plot(matSac(idx==2,3), matSac(idx==2,4),'.','MarkerSize',18,'Color',cfg.color2);

% grid
xlabel('Amplitude (deg)');
ylabel('Duration (ms)');
legend({'Group 1','Group 2'}, 'FontWeight','bold','FontSize',11,'FontName','Arial','Box','off','Location','southeast')

set(gca,'FontWeight','bold','FontSize',10,'FontName','Arial','Visible','on');



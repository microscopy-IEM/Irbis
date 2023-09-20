function txt = p2star(p)
    
%     if p<= 0.0001
%         txt = '***';
%     elseif p<= 0.001
%         txt = '***';
%     elseif p <= 0.01
%         txt = '**';
%     elseif p <= 0.05
%         txt = '*';
%     elseif p <= 0.1
%         txt = ['+ p= ' num2str(round(p,4)) ];
%     else
%         txt = 'n.s.';
%     end
% 
%      txt = {'+',['p = ' num2str(round(p,4))]};
% 
%      txt

roundN = 4;

     if p<= 0.0001
        txt = {'***',['p < 10^-^4']};
    elseif p<= 0.001
        txt = {'***',['p = ' num2str(round(p,roundN))]};
    elseif p <= 0.01
        txt = {'**',['p = ' num2str(round(p,roundN))]};
    elseif p <= 0.05
        txt = {'*',['p = ' num2str(round(p,roundN))]};
    elseif p <= 0.1
        txt = {'+' ['p= ' num2str(round(p,roundN))]};
    else
        txt = {'n.s.', ['p= ' num2str(round(p,roundN)) ]};
    end
end
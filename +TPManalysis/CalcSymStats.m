function [sigx, sigy, SymRatio] = CalcSymStats(X,Y)
    sigx = std(X);
    sigy = std(Y);
    lambda = eig(cov(X,Y));
    lambda = sort(lambda,'descend');
    SymRatio = sqrt(lambda(1)/lambda(2));
end
function outIm = flatField (inIm, DFim, invFFim);

%Flatfields inIm by calculating (inIm-DFim).*invFFim;
%returns output image in range [0,1] - outliers are truncated.

outIm = (double(inIm) - DFim) .* invFFim;
outIm = max(outIm, 0);
outIm = min(outIm, 1);
function phosphorFunction = crtPhosphorActivationFunction(refreshRate) 
    alpha = 1.9; t_50 = 0.05/1000; n = 2;
    samplesPerRefreshCycle = round(2*1000/refreshRate);
    phosphorFunction.timeInSeconds = linspace(0,1.0/refreshRate, samplesPerRefreshCycle);
    phosphorFunction.timeInSeconds = phosphorFunction.timeInSeconds(2:end);
    phosphorFunction.activation = (phosphorFunction.timeInSeconds.^n)./(phosphorFunction.timeInSeconds.^(alpha*n) + t_50^(alpha*n));
    phosphorFunction.activation = phosphorFunction.activation - phosphorFunction.activation(end);
    phosphorFunction.activation(phosphorFunction.activation<0) = 0;
    phosphorFunction.activation = phosphorFunction.activation / max(phosphorFunction.activation);
end


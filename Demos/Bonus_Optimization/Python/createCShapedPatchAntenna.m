function ant = createCShapedPatchAntenna(Lmm, Wmm, lmm, wmm, dmm, hmm, eR, feedparams, options)
    % Validate inputs
    fprintf('Inputs received: Lmm=%f, Wmm=%f, lmm=%f, wmm=%f, dmm=%f, hmm=%f, eR=%f\n', Lmm, Wmm, lmm, wmm, dmm, hmm, eR);
    
    if Lmm <= 0 || Wmm <= 0 || lmm <= 0 || wmm <= 0 || hmm <= 0
        error('All dimension inputs must be positive.');
    end

    % Convert dimensions to meters
    L = Lmm * 1e-3;
    W = Wmm * 1e-3;
    l = lmm * 1e-3;
    w = wmm * 1e-3;
    d = dmm * 1e-3;
    h = hmm * 1e-3;

    fprintf('Converted to meters: L=%f, W=%f, l=%f, w=%f, d=%f, h=%f\n', L, W, l, w, d, h);

    % Ground plane dimensions (1.15 times patch dimensions)
    GPL = 1.15 * L;
    GPW = 1.15 * W;

    fprintf('Computed ground plane dimensions: GPL=%f, GPW=%f\n', GPL, GPW);

    if GPL <= 0 || GPW <= 0
        error('Computed ground plane dimensions must be positive. Check inputs: L=%f, W=%f', L, W);
    end

    % Create components
    groundplane = antenna.Rectangle(Length=GPL, Width=GPW, Center=[L/2, W/2], Name="Ground Plane");
    patch = antenna.Rectangle(Length=L, Width=W, Center=[L/2, W/2]);
    slot = antenna.Rectangle(Length=l, Width=w, Center=[L-l/2, W-d-w/2]);

    radiator = patch - slot;
    radiator.Name = "Radiator";
    substrate = dielectric(Name=sprintf("eR = %g", eR), EpsilonR=eR, Thickness=h);

    ant = pcbStack(BoardShape=groundplane, BoardThickness=h, ...
                   FeedLocations=[feedparams.x0, feedparams.y0, 1, 3], FeedVoltage=feedparams.V, ...
                   Layers={radiator, substrate, groundplane});

    if islogical(options) && options
        figure;
        show(ant);
        title('C-Shaped Microstrip Patch Antenna');
    end
end




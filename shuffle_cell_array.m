function shuffled = shuffle_cell_array(ca)
    n = numel(ca);
    shuffled = ca(randperm(n));
end


function [action] = act_denormalize(config, action_normalized)
    action_normalized = min([1.0 1.0], max([-1.0 -1.0], action_normalized));
    lower = config.input_range(:,1)';
    upper = config.input_range(:,2)';
    middle = (lower + upper)/2.0;
    action = (action_normalized .* (upper - middle) + middle);
end

